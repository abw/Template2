/*=====================================================================
*
* Template::Stash::XS (Stash.xs)
*
* DESCRIPTION
*   This is an XS implementation of the Template::Stash module.
*   It is an alternative version of the core Template::Stash methods
*   ''get'' and ''set'' (the ones that should benefit most from a
*   speedy C implementation), along with some virtual methods (like
*   first, last, reverse, etc.)
*
* AUTHORS
*   Andy Wardley   <abw@kfs.org>
*   Doug Steinwand <dsteinwand@citysearch.com>
*
* COPYRIGHT
*   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
*   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
*
*   This module is free software; you can redistribute it and/or
*   modify it under the same terms as Perl itself.
*
* NOTE
*   Be very familiar with the perlguts, perlxs, perlxstut and 
*   perlapi manpages before digging through this code.
*
*---------------------------------------------------------------------
*
* $Id$
*
*=====================================================================*/


/* #define TT_PERF_ENABLE    <--- enables profiling code, 
				  but hurts performance some. */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef TT_PERF_ENABLE
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#endif /* TT_PERF_ENABLE */

#ifdef __cplusplus
}
#endif

#define TT_STASH_PKG	"Template::Stash::XS"
#define TT_LIST_OPS	"Template::Stash::LIST_OPS"
#define TT_HASH_OPS	"Template::Stash::HASH_OPS"
#define TT_SCALAR_OPS	"Template::Stash::SCALAR_OPS"

#define TT_LVALUE_FLAG	1
#define TT_DEBUG_FLAG	2
#define TT_DEFAULT_FLAG	4

typedef enum tt_ret { TT_RET_UNDEF, TT_RET_OK, TT_RET_CODEREF } TT_RET;

static TT_RET	hash_op(SV*, char*, AV*, SV**);
static TT_RET	list_op(SV*, char*, AV*, SV**);
static TT_RET	scalar_op(SV*, char*, AV*, SV**);
static TT_RET	tt_fetch_item(SV*, SV*, AV*, SV**);
static SV*	dotop(SV*, SV*, AV*, int);
static SV* 	call_coderef(SV*, AV*);
static SV*	fold_results(I32);
static SV*	find_perl_op(char*, char*);
static AV*	mk_mortal_av(SV*, AV*, SV*);
static SV*	do_getset(SV*, AV*, SV*, int);
static AV*	convert_dotted_string(const char*, I32);
static int	get_debug_flag(SV*);
static int	cmp_arg(const void *, const void *);
static void   	die_object(SV *);
static struct xs_arg *find_xs_op(char *);
static SV*	list_dot_first(AV*, AV*);
static SV*	list_dot_join(AV*, AV*);
static SV*	list_dot_last(AV*, AV*);
static SV*	list_dot_max(AV*, AV*);
static SV*	list_dot_reverse(AV*, AV*);
static SV*	list_dot_size(AV*, AV*);
static SV*	hash_dot_each(HV*, AV*);
static SV*	hash_dot_keys(HV*, AV*);
static SV*	hash_dot_values(HV*, AV*);
static SV*	scalar_dot_defined(SV*, AV*);
static SV*	scalar_dot_length(SV*, AV*);

static char rcsid[] = 
	"$Id$";

/* dispatch table for XS versions of special "virtual methods",
 * names must be in alphabetical order 		
 */
static const struct xs_arg {
	const char *name;
	SV* (*list_f)   (AV*, AV*);
	SV* (*hash_f)   (HV*, AV*);
	SV* (*scalar_f) (SV*, AV*);
} xs_args[] = {
    /* name	 list (AV) ops.	   hash (HV) ops.   scalar (SV) ops.
       --------	 ----------------  ---------------  ------------------  */
    { "defined", NULL,		   NULL,	    scalar_dot_defined	},
    { "each",	 NULL,		   hash_dot_each,   NULL		},
    { "first",	 list_dot_first,   NULL,	    NULL		},
    { "join",	 list_dot_join,    NULL,	    NULL		}, 
    { "keys",	 NULL,		   hash_dot_keys,   NULL		},
    { "last",	 list_dot_last,	   NULL,	    NULL		},
    { "length",	 NULL,		   NULL,	    scalar_dot_length	},
    { "max",	 list_dot_max,	   NULL,	    NULL		},
    { "reverse", list_dot_reverse, NULL,	    NULL		},
    { "size",	 list_dot_size,	   NULL,	    NULL		},
    { "values",	 NULL,		   hash_dot_values, NULL		},
};


#ifdef TT_PERF_ENABLE

/* performance data gathering structures and code */

int	hv_op_cnt, hv_op_cnt_xs, hv_op_cnt_pl,
	av_op_cnt, av_op_cnt_xs, av_op_cnt_pl,
	sv_op_cnt, sv_op_cnt_xs, sv_op_cnt_pl = 0;

typedef enum perf_status_type { 
	perf_av_hit_xs, perf_av_hit_pl, perf_av_miss,
	perf_hv_hit_xs, perf_hv_hit_pl, perf_hv_miss,
	perf_sv_hit_xs, perf_sv_hit_pl, perf_sv_miss,
	perf_func, 	perf_method,	max_perf_status_type } 
	perf_status_type;

/* Note: 
 *	vrt = virtual: in ''foo.bar.last'', ''last'' is a virtual method 
 */
char *perf_status_string[] = { 
	"vrt XS AV",	"vrt PL AV",	"vrt ?? AV",
	"vrt XS HV",	"vrt PL HV",	"vrt ?? HV",
	"vrt XS SV",	"vrt PL SV",	"vrt ?? SV",
	"*Function",	"Method   " };

struct perf_rec {
	char	key[24];
	int 	count[max_perf_status_type];
	double	cpu_time[max_perf_status_type];
	struct	perf_rec *next_lt;
	struct	perf_rec *next_gr;
} *perf_hist = NULL;

struct perf_out_rec {
	SV	*outsv;
	double	cpu_time;
} perf_out;


/* returns user CPU time and optionally
 * system CPU time and max rss for this process 
 * time measured in seconds, rss in kilobytes */
static double get_cpu_usage (double *sys_time, long *max_rss) {
    struct rusage rusage;
    getrusage(RUSAGE_SELF, &rusage);

    if (sys_time)
	*sys_time = (double) rusage.ru_stime.tv_sec + 
			(double) rusage.ru_stime.tv_usec / 1000000.0;

    if (max_rss)
	*max_rss = rusage.ru_maxrss;

    return (double) rusage.ru_utime.tv_sec + 
		(double) rusage.ru_utime.tv_usec / 1000000.0;
}

/* stores performance data (key, status) in a binary tree */
static double *record_key_perf(char *key, perf_status_type status) {
    struct perf_rec *p = perf_hist;
    struct perf_rec **lp = &perf_hist;
    int i;

    /* look for existing node */
    while (p) {
	i = strcmp(key, p->key);
	if (i < 0) {
	    /* left branch */
	    lp = &(p->next_lt);
	    p = p->next_lt;

	} else if (i > 0) {
	    /* right branch */
	    lp = &(p->next_gr);
	    p = p->next_gr;

	} else {
	    /* found matching key */
	    p->count[status]++;
	    p->cpu_time[status] -= get_cpu_usage(NULL, NULL);
	    return &(p->cpu_time[status]);
	}
    }

    /* create new node */
    Newz(0, p, 1, struct perf_rec);
    if (p) {
	p->count[status] = 1;
	strncpy(p->key, key, sizeof(p->key));
	*lp = p;
	p->cpu_time[status] -= get_cpu_usage(NULL, NULL);
	return &(p->cpu_time[status]);

    } else {
	croak(TT_STASH_PKG ": Newz() failed for %s in record_key_perf\n", key);
    }

    return NULL;
}

/* dumps one row of performance data */
static void dump_perf_rec(p, out, status) 
    struct perf_rec *p; 
    struct perf_out_rec *out;
    perf_status_type status; 
{

    sv_catpvf(out->outsv, 
	"%-24s %s%9d", p->key, perf_status_string[status], p->count[status]);

    if (p->count[status] && p->cpu_time[status] && out->cpu_time > 0.0)
	sv_catpvf(out->outsv, 
		"%10.3f%9.6f %4.1f\n", 
		p->cpu_time[status],
		p->cpu_time[status] / (double) p->count[status],
		100.0 * p->cpu_time[status] / out->cpu_time);
    else
	sv_catpvf(out->outsv, "         -        -    -\n");
}

/* recursively dumps entire performance table ''p'' */
static void dump_all_perf(p, out)
    struct perf_rec *p; 
    struct perf_out_rec *out;
{
    perf_status_type i;

    if (!p)
	return;

    /* left branch */
    if (p->next_lt) 
	dump_all_perf(p->next_lt, out);

    /* this node */
    for(i = 0; i < max_perf_status_type; i++)
	if(p->count[i])
	    dump_perf_rec(p, out, i);

    /* right branch */
    if (p->next_gr) 
	dump_all_perf(p->next_gr, out);

    return;
}

#define TT_PERF_INIT					\
    double  *tt_perf_tmr

#define TT_PERF_START(x, y, key, status_type)		\
    (x)++;						\
    (y)++;						\
    tt_perf_tmr = record_key_perf((key), (status_type))

#define TT_PERF_START_FUNC(key)				\
    tt_perf_tmr = record_key_perf((key), perf_func)

#define TT_PERF_START_METHOD(key)			\
    tt_perf_tmr = record_key_perf((key), perf_method)

#define TT_PERF_END	 				\
    *tt_perf_tmr += get_cpu_usage(NULL, NULL)

#define TT_PERF_MISS(x, key, status_type)		\
    (x)++;						\
    tt_perf_tmr = record_key_perf("*", status_type);	\
    *tt_perf_tmr += get_cpu_usage(NULL, NULL)
	
#else 

/* no-ops when no performance code is wanted */

#define TT_PERF_INIT
#define TT_PERF_START(w,x,y,z)
#define TT_PERF_START_FUNC(x)
#define TT_PERF_START_METHOD(x)
#define TT_PERF_END
#define TT_PERF_MISS(x,y,z)

#endif /* TT_PERF_ENABLE */



/* retrieves an item from the given hash or array ref.
 * if found:
 *   if a coderef, the coderef will be called and passed args
 *   returns TT_RET_CODEREF or TT_RET_OK and sets result
 * otherwise, returns TT_RET_UNDEF and result is undefined 
 */
static TT_RET tt_fetch_item(SV *root, SV *key_sv, AV *args, SV **result) {
    STRLEN key_len;
    char *key = SvPV(key_sv, key_len);
    SV **value = NULL;

    if (!SvROK(root)) 
	return TT_RET_UNDEF;

    switch (SvTYPE(SvRV(root))) {
    case SVt_PVHV:
	value = hv_fetch((HV *) SvRV(root), key, key_len, FALSE);
	break;

    case SVt_PVAV:
	if (looks_like_number(key_sv)) {
	    value = av_fetch((AV *) SvRV(root), SvIV(key_sv), FALSE);
	}
	break;
    }

    if (value) {
	if (SvROK(*value) 
	    && (SvTYPE(SvRV(*value)) == SVt_PVCV) 
	    && !sv_isobject(*value)) {
	    *result = call_coderef(*value, args);
	    return TT_RET_CODEREF;

	} else if (*value != &PL_sv_undef) {
	    *result = *value;
	    return TT_RET_OK;
	}
    } 

    *result = &PL_sv_undef;
    return TT_RET_UNDEF;
}


/* Resolves dot operations of the form root.key, where 'root' is a
 * reference to the root item, 'key_sv' is an SV containing the
 * operation key (e.g. hash key, list index, first, last, each, etc),
 * 'args' is a list of additional arguments and 'TT_LVALUE_FLAG' is a 
 * flag to indicate if, for certain operations (e.g. hash key), the item
 * should be created if it doesn't exist. Also, 'TT_DEBUG_FLAG' is the 
 * debug flag.
 */
static SV *dotop(SV *root, SV *key_sv, AV *args, int flags) {
    dSP;
    STRLEN item_len;
    char *item = SvPV(key_sv, item_len);
    SV *result = &PL_sv_undef;
    TT_PERF_INIT;

    /* ignore _private or .private members */
    if (!root || !item_len || *item == '_' || *item == '.') {
	return &PL_sv_undef;
    }

    if (SvROK(root) && ((sv_derived_from(root, TT_STASH_PKG) ||
	((SvTYPE(SvRV(root)) == SVt_PVHV) && !sv_isobject(root))))) {

	/* if root is a regular HASH or a Template::Stash kinda HASH (the
	   *real* root of everything).  We first lookup the named key
	   in the hash, or create an empty hash in its place if undefined
	   and the lvalue flag is set.  Otherwise, we check the HASH_OPS
	   pseudo-methods table, calling the code if found. If that fails, 
	   we'll try a hash slice or return undef. */

	switch(tt_fetch_item(root, key_sv, args, &result)) {
	case TT_RET_OK:
	    /* return immediately */
	    return result;
	    break;

	case TT_RET_CODEREF:
	    /* fall through */
	    break;

	default:
	    /* for lvalue, create an intermediate hash */
	    if (flags & TT_LVALUE_FLAG) {
		SV *newhash;
		HV *roothv = (HV *) SvRV(root);

		newhash = SvREFCNT_inc((SV *) newRV_noinc((SV *) newHV()));
		if (hv_store(roothv, item, item_len, newhash, 0)) {
		    return sv_2mortal(newhash);
		} else {
		    /* something went horribly wrong */
		    SvREFCNT_dec(newhash);
		    return &PL_sv_undef;
	    	}
	    }

	    /* try hash pseudo-method */
	    if (hash_op(root, item, args, &result) == TT_RET_UNDEF) {
		/* try hash slice */ 
		if (SvROK(key_sv) && SvTYPE(SvRV(key_sv)) == SVt_PVAV) {
		    AV *a_av = newAV();
		    AV *k_av = (AV *) SvRV(key_sv);
		    HV *r_hv = (HV *) SvRV(root);
		    char *t;
		    I32 i;
		    STRLEN tlen;
		    SV **svp;

		    for (i = 0; i <= av_len(k_av); i++) {
			if ((svp = av_fetch(k_av, i, 0))) {
			    t = SvPV(*svp, tlen);
			    if((svp = hv_fetch(r_hv, t, tlen, FALSE)))
				av_push(a_av, SvREFCNT_inc(*svp));
			}
		    }

		    return sv_2mortal(newRV_noinc((SV *) a_av));
	    	}
	    }
	}

    } else if (SvROK(root) && (SvTYPE(SvRV(root)) == SVt_PVAV) 
		&& !sv_isobject(root)) {

	/* if root is an ARRAY, check for a LIST_OPS pseudo-method
	   (except for l-values for which it doesn't make any sense)
	   or return the numerical index into the array, or undef */

	if ((flags & TT_LVALUE_FLAG) ||
	    (list_op(root, item, args, &result) == TT_RET_UNDEF)) {
	    switch (tt_fetch_item(root, key_sv, args, &result)) {
	    case TT_RET_OK:
		return result;
		break;

	    case TT_RET_CODEREF:
		break;

	    default:
		/* try array slice */ 
		if (SvROK(key_sv) && SvTYPE(SvRV(key_sv)) == SVt_PVAV) {
		    AV *a_av = newAV();
		    AV *k_av = (AV *) SvRV(key_sv);
		    AV *r_av = (AV *) SvRV(root);
		    I32 i;
		    SV **svp;

		    for (i = 0; i <= av_len(k_av); i++) {
			if ((svp = av_fetch(k_av, i, FALSE))) {
			    if (looks_like_number(*svp) && 
				(svp = av_fetch(r_av, SvIV(*svp), FALSE)))
				av_push(a_av, SvREFCNT_inc(*svp));
			}
		    }

		    return sv_2mortal(newRV_noinc((SV *) a_av));
		}
	    }
	}

    /* do the can-can because UNIVSERAL::isa($something, 'UNIVERSAL')
       doesn't appear to work with CGI, returning true for the first 
       call and false for all subsequent calls. 

       *** I'm using sv_isobject() here instead *** */

    } else if (SvROK(root) && sv_isobject(root)) {

        /* if $root is a blessed reference (i.e. inherits from the
           UNIVERSAL object base class) then we call the item as a method.
           If that fails then we try to fallback on HASH behaviour if
           possible. */

	I32 n, i;
	SV **svp;
	HV *stash = SvSTASH((SV *) SvRV(root));
	GV *gv;
	result = NULL;

	if ((gv = gv_fetchmethod_autoload(stash, item, 1))) {

	    /* eval { @result = $root->$item(@$args); }; */

	    TT_PERF_START_METHOD(item);
	    PUSHMARK(SP);
	    XPUSHs(root);
	    n = (args && args != Nullav) ? av_len(args) : -1;
	    for (i = 0; i <= n; i++)
	        if ((svp = av_fetch(args, i, 0))) XPUSHs(*svp);
	    PUTBACK;
	    n = perl_call_method(item, G_ARRAY | G_EVAL);
	    TT_PERF_END;
	    SPAGAIN;

	    if (SvTRUE(ERRSV)) {
		(void) POPs;		/* remove undef from stack */
		PUTBACK;
		result = NULL;

		/* temporary hack - required to propogate errors thrown
	           by views; if $@ is a ref (e.g. Template::Exception)
	           object then we assume it's a real error that needs
	           real throwing */

		if (SvROK(ERRSV) || !strstr(SvPV(ERRSV, PL_na), 
			"Can't locate object method")) {
		    die_object(ERRSV);
		}
	    } else {
		result = fold_results(n);
	    }
	}

	if (!result) {
	    /* failed to call object method, so try some fallbacks */
	    if ((SvTYPE(SvRV(root)) == SVt_PVHV)
		 && ((n = tt_fetch_item(root, key_sv, args, &result)) 
			!= TT_RET_UNDEF)) {
		if (n == TT_RET_OK) {
		    return result;
		}

	    } else if ((SvTYPE(SvRV(root)) == SVt_PVAV)
	    	&& (list_op(root, item, args, &result) == TT_RET_UNDEF)) {
		if (flags & TT_DEBUG_FLAG)
		    result = (SV *) mk_mortal_av(&PL_sv_undef, NULL, ERRSV);
	    }
	}
    }

    /* at this point, it doesn't look like we've got a reference to
       anything we know about, so we try the SCALAR_OPS pseudo-methods
       table (but not for l-values) */

    else if (!(flags & TT_LVALUE_FLAG) 
	     && (scalar_op(root, item, args, &result) == TT_RET_UNDEF)) {
	if (flags & TT_DEBUG_FLAG)
	    croak("don't know how to access [ %s ].%s\n", 
		SvPV(root, PL_na), item);
    }

    /* if we have an arrayref:
	and first element of result is defined, everything is peachy.
        otherwise some gross error may have occurred */

    if (SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVAV) {
	SV **svp;
	AV *array = (AV *) SvRV(result);
	I32 len = (array == Nullav) ? 0 : (av_len(array) + 1);

	if (len) {
	    svp = av_fetch(array, 0, FALSE);
	    if (svp && (*svp != &PL_sv_undef)) {
		return result;
	    } else if (len > 1 && (svp = av_fetch(array, 1, FALSE)) &&
			(*svp != &PL_sv_undef)) {
		die_object(*svp);
	    }
	}
    } 

    if ((flags & TT_DEBUG_FLAG) 
	&& (!result || !SvOK(result) || (result == &PL_sv_undef)))
	croak("%s is undefined\n", item);

    return result;
}


/* Resolves the final assignment element of a dotted compound variable
 * of the form "root.key(args) = value".  'root' is a reference to
 * the root item, 'key_sv' is an SV containing the operation key
 * (e.g. hash key, list item, object method), 'args' is a list of user
 * provided arguments (passed only to object methods), 'value' is the
 * assignment value to be set (appended to args) and 'deflt' (default)
 * is a flag to indicate that the assignment should only be performed
 * if the item is currently undefined/false.
 */
static SV *assign(SV *root, SV *key_sv, AV *args, SV *value, int flags) {
    dSP;
    SV **svp, *newsv;
    HV *roothv;
    AV *rootav;
    STRLEN key_len;
    char *key = SvPV(key_sv, key_len);
    TT_PERF_INIT;

    if (!root || !key_len || *key == '_' || *key == '.') {
	/* ignore _private or .private members */
	return &PL_sv_undef;

    } else if (SvROK(root)) {			    /* OBJECT */

	if (sv_isobject(root) && !sv_derived_from(root, TT_STASH_PKG)) {
	    HV *stash = SvSTASH((SV *) SvRV(root));
	    GV *gv;

	    /* look for the named method, or an AUTOLOAD method */
	    if ((gv = gv_fetchmethod_autoload(stash, key, 1))) {
		I32 count = (args && args != Nullav) ? av_len(args) : -1;
		I32 i;

		/* push args and value onto stack, then call method */
	        TT_PERF_START_METHOD(key);
		PUSHMARK(SP);
		XPUSHs(root);
		for (i = 0; i <= count; i++) {
		    if ((svp = av_fetch(args, i, FALSE)))
			XPUSHs(*svp);
		}
		XPUSHs(value);
		PUTBACK;
		count = perl_call_method(key, G_ARRAY);
	        TT_PERF_END;
		SPAGAIN;
		return fold_results(count);		
	    }
	}

	/* drop-through if not an object or method not found  */

        switch SvTYPE(SvRV(root)) {

	case SVt_PVHV:				    /* HASH */
	    roothv = (HV *) SvRV(root);

	    /* check for any existing value if ''default'' flag set */
	    if ((flags & TT_DEFAULT_FLAG)
		&& (svp = hv_fetch(roothv, key, key_len, FALSE))
		&& SvTRUE(*svp))
		return &PL_sv_undef;

	    /* avoid 'modification of read-only value' error */
	    newsv = newSVsv(value); 
	    if (!hv_store(roothv, key, key_len, newsv, 0))
	        SvREFCNT_dec(newsv);
	    return value;
	    break;

	case SVt_PVAV:				    /* ARRAY */
	    rootav = (AV *) SvRV(root);

	    /* check for any existing value if default flag set */
	    if ((flags & TT_DEFAULT_FLAG)
		&& looks_like_number(key_sv)
		&& (svp = av_fetch(rootav, SvIV(key_sv), FALSE))
		&& SvTRUE(*svp))
		return &PL_sv_undef;

	    if (looks_like_number(key_sv) 
		&& av_store(rootav, SvIV(key_sv), value))
		return SvREFCNT_inc(value);
	    else
		return &PL_sv_undef;

	    break;

	default:				    /* BARF */
	    /* TODO: fix [ %s ] */
	    croak("don't know how to assign to [ %s ].%s", 
		SvPV(SvRV(root), PL_na), key);
	}
    }
    else {					    /* SCALAR */
	/* TODO: fix [ %s ] */
	croak("don't know how to assign to [ %s ].%s", 
		SvPV(SvRV(root), PL_na), key);
    }

    /* not reached */
    return &PL_sv_undef;			    /* just in case */
}


/* dies and passes back a blessed object,  
 * or just a string if it's not blessed 
 */
static void die_object (SV *err) {

    if (sv_isobject(err)) {
	/* throw object via ERRSV ($@) */
	SV *errsv = perl_get_sv("@", TRUE);
	sv_setsv(errsv, err);
	(void) die(Nullch);
    }

    /* error string sent back via croak() */
    croak("%s", SvPV(err, PL_na));
}


/* pushes any arguments in 'args' onto the stack then calls the code ref
 * in 'code'.  Calls fold_results() to return a listref or die.
 */
static SV *call_coderef(SV *code, AV *args) {
    dSP;
    SV **svp;
    I32 count = (args && args != Nullav) ? av_len(args) : -1;
    I32 i;

    PUSHMARK(SP);
    for (i = 0; i <= count; i++)
	if ((svp = av_fetch(args, i, FALSE))) 
	    XPUSHs(*svp);
    PUTBACK;
    count = perl_call_sv(code, G_ARRAY);
    SPAGAIN;

    return fold_results(count);
}


/* pops 'count' items off the stack, folding them into a list reference
 * if count > 1, or returning the sole item if count == 1.  
 * Returns undef if count == 0. 
 * Dies if first value of list is undef
 */
static SV* fold_results(I32 count) {
    dSP;
    SV *retval = &PL_sv_undef;

    if (count > 1) {
	/* convert multiple return items into a list reference */
	AV *av = newAV();
	SV *last_sv = &PL_sv_undef;
	SV *sv = &PL_sv_undef;
	I32 i;

	av_extend(av, count - 1);
	for(i = 1; i <= count; i++) {
	    last_sv = sv;
	    sv = POPs; 
	    if (SvOK(sv) && !av_store(av, count - i, SvREFCNT_inc(sv))) 
		SvREFCNT_dec(sv);
	}
        PUTBACK;

	retval = sv_2mortal((SV *) newRV_noinc((SV *) av));

	if (!SvOK(sv) || sv == &PL_sv_undef) {
	    /* if first element was undef, die */
	    die_object(last_sv);
	} 
	return retval;

    } else { 
	if (count)
	    retval = POPs; 
	PUTBACK;
	return retval;
    }
}


/* Iterates through array calling dotop() to resolve all items
 * Skips the last if ''value'' is non-NULL.
 * If ''value'' is non-NULL, calls assign() to do the assignment.
 */
static SV *do_getset(root, ident_av, value, flags)
    SV *root; 
    AV *ident_av; 
    SV *value; 
    int flags;
{
    AV *key_args;
    SV *key;
    SV **svp;
    I32 end_loop, i, size = av_len(ident_av);

    if (value) {
	/* make some adjustments for assign mode */
	end_loop = size - 1;
	flags |= TT_LVALUE_FLAG;
    } else {
	end_loop = size;
    }

    for(i = 0; i < end_loop; i += 2) {

	if (!(svp = av_fetch(ident_av, i, FALSE)))
	    croak(TT_STASH_PKG " %cet: bad element %d", value ? 's' : 'g', i);

	key = *svp;

	if (!(svp = av_fetch(ident_av, i + 1, FALSE)))
	    croak(TT_STASH_PKG " %cet: bad arg. %d", value ? 's' : 'g', i + 1);

	if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
	    key_args = (AV *) SvRV(*svp);
	else
	    key_args = Nullav;
		
	root = dotop(root, key, key_args, flags);

	if (!root || !SvOK(root))
	    return root;
    }

    if (value && SvROK(root)) {
	/* call assign() to resolve the last item */
	if (!(svp = av_fetch(ident_av, size - 1, FALSE)))
	    croak(TT_STASH_PKG ": set bad ident element at %d", i);

	key = *svp;

	if (!(svp = av_fetch(ident_av, size, FALSE)))
	    croak(TT_STASH_PKG ": set bad ident argument at %d", i + 1);

	if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
	    key_args = (AV *) SvRV(*svp);
	else
	    key_args = Nullav;

	return assign(root, key, key_args, value, flags);
    }

    return root;
}


/* return [ map { s/\(.*$//; ($_, 0) } split(/\./, $str) ];
 */
static AV *convert_dotted_string(const char *str, I32 len) {
    AV *av = newAV();
    char *buf, *b;
    int b_len = 0;

    New(0, buf, len + 1, char);
    if (!buf) 
	croak(TT_STASH_PKG ": New() failed for convert_dotted_string");

    for(b = buf; len >= 0; str++, len--) {
	if (*str == '(') {
	    for(; (len > 0) && (*str != '.'); str++, len--) ;
	} 
	if ((len < 1) || (*str == '.')) {
	    *b = '\0';
	    av_push(av, newSVpv(buf, b_len));
	    av_push(av, newSViv((IV) 0));
	    b = buf;
	    b_len = 0;
	} else {
	    *b++ = *str;
	    b_len++;
	}
    }

    Safefree(buf);
    return (AV *) sv_2mortal((SV *) av);
}


/* performs a generic hash operation identified by 'key' 
 * (e.g. keys, * values, each) on 'hash'.
 * returns TT_RET_CODEREF if successful, TT_RET_UNDEF otherwise.
 */
static TT_RET hash_op(SV *root, char *key, AV *args, SV **result) {
    struct xs_arg *a;
    SV *code;
    TT_PERF_INIT;

    /* look for XS version first */
    if ((a = find_xs_op(key)) && a->hash_f) {
	TT_PERF_START(hv_op_cnt, hv_op_cnt_xs, key, perf_hv_hit_xs);
	*result = a->hash_f((HV *) SvRV(root), args);
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* look for perl version in Template::Stash module */
    if ((code = find_perl_op(key, TT_HASH_OPS))) {
	TT_PERF_START(hv_op_cnt, hv_op_cnt_pl, key, perf_hv_hit_pl);
	*result = call_coderef(code, mk_mortal_av(root, args, NULL)); 
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* not found */
    TT_PERF_MISS(hv_op_cnt, key, perf_hv_miss);
    *result = &PL_sv_undef;
    return TT_RET_UNDEF;
}


/* performs a generic list operation identified by 'key' on 'list'.  
 * Additional arguments may be passed in 'args'. 
 * returns TT_RET_CODEREF if successful, TT_RET_UNDEF otherwise.
 */
static TT_RET list_op(SV *root, char *key, AV *args, SV **result) {
    struct xs_arg *a;
    SV *code;
    TT_PERF_INIT;

    /* look for and execute XS version first */
    if ((a = find_xs_op(key)) && a->list_f) {
	TT_PERF_START(av_op_cnt, av_op_cnt_xs, key, perf_av_hit_xs);
	*result = a->list_f((AV *) SvRV(root), args);
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* look for and execute perl version in Template::Stash module */
    if ((code = find_perl_op(key, TT_LIST_OPS))) {
	TT_PERF_START(av_op_cnt, av_op_cnt_pl, key, perf_av_hit_pl);
	*result = call_coderef(code, mk_mortal_av(root, args, NULL));
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* not found */
    TT_PERF_MISS(av_op_cnt, key, perf_av_miss);
    *result = &PL_sv_undef;
    return TT_RET_UNDEF;
}


/* Performs a generic scalar operation identified by 'key' 
 * on 'sv'.  Additional arguments may be passed in 'args'. 
 * returns TT_RET_CODEREF if successful, TT_RET_UNDEF otherwise.
 */
static TT_RET scalar_op(SV *sv, char *key, AV *args, SV **result) {
    struct xs_arg *a;
    SV *code;
    TT_PERF_INIT;

    /* look for a XS version first */
    if ((a = find_xs_op(key)) && a->scalar_f) {
	TT_PERF_START(sv_op_cnt, sv_op_cnt_xs, key, perf_sv_hit_xs);
	*result = a->scalar_f(sv, args);
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* look for perl version in Template::Stash module */
    if ((code = find_perl_op(key, TT_SCALAR_OPS))) {
	TT_PERF_START(sv_op_cnt, sv_op_cnt_pl, key, perf_sv_hit_pl);
	*result = call_coderef(code, mk_mortal_av(sv, args, NULL));
	TT_PERF_END;
	return TT_RET_CODEREF;
    }

    /* not found */
    TT_PERF_MISS(sv_op_cnt, key, perf_sv_miss);
    *result = &PL_sv_undef;
    return TT_RET_UNDEF;
}


/* xs_arg comparison function */
static int cmp_arg(const void *a, const void *b) {
    return (strcmp(((const struct xs_arg *)a)->name,
		   ((const struct xs_arg *)b)->name));
}


/* Searches the xs_arg table for key */
static struct xs_arg *find_xs_op(char *key) {
    struct xs_arg *ap, tmp;

    tmp.name = key;
    if ((ap = (struct xs_arg *) 
		bsearch(&tmp, 
			xs_args,
			sizeof(xs_args)/sizeof(struct xs_arg), 
			sizeof(struct xs_arg),
			cmp_arg)))
	return ap;

    return NULL;
}


/* Searches the perl Template::Stash.pm module for ''key'' in the
 * hashref named ''perl_var''. Returns SV if found, NULL otherwise.
 */
static SV *find_perl_op(char *key, char *perl_var) {
    SV *tt_ops;
    SV **svp;

    if ((tt_ops = perl_get_sv(perl_var, FALSE)) 
	&& SvROK(tt_ops) 
	&& (svp = hv_fetch((HV *) SvRV(tt_ops), key, strlen(key), FALSE)) 
	&& SvROK(*svp) 
	&& SvTYPE(SvRV(*svp)) == SVt_PVCV)
	return *svp;

    return NULL;
}


/* Returns: @a = ($sv, @av, $more) */
static AV *mk_mortal_av(SV *sv, AV *av, SV *more) {
    SV **svp;
    AV *a;
    I32 i = 0, size;

    a = newAV();
    av_push(a, SvREFCNT_inc(sv));

    if (av && (size = av_len(av)) > -1) {
	av_extend(a, size + 1);
	for (i = 0; i <= size; i++)
	    if ((svp = av_fetch(av, i, FALSE))) 
    		if(!av_store(a, i + 1, SvREFCNT_inc(*svp)))
		    SvREFCNT_dec(*svp);
    }

    if (more && SvOK(more))
	if (!av_store(a, i + 1, SvREFCNT_inc(more)))
	    SvREFCNT_dec(more);

    return (AV *) sv_2mortal((SV *) a);
}


/* Returns TT_DEBUG_FLAG if _DEBUG key is true in hashref ''sv''. */
static int get_debug_flag (SV *sv) {
    const char *key = "_DEBUG";
    const I32 len = 6;
    SV **debug;
    
    if (SvROK(sv) 
	&& (SvTYPE(SvRV(sv)) == SVt_PVHV) 
	&& (debug = hv_fetch((HV *) SvRV(sv), (char *) key, len, FALSE))
	&& SvOK(*debug)
	&& SvTRUE(*debug)) 
	return TT_DEBUG_FLAG;
    
    return 0;
}


/* XS versions of some common dot operations 
 * ----------------------------------------- */

/* list.first */
static SV *list_dot_first(AV *list, AV *args) {
    SV **svp;
    if ((svp = av_fetch(list, 0, FALSE))) {
	/* entry fetched from arry may be code ref */
	if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
	    return call_coderef(*svp, args);
	} else {
	    return *svp;
	}
    }
    return &PL_sv_undef;
}


/* list.join */
static SV *list_dot_join(AV *list, AV *args) {
    SV **svp;
    SV *item, *retval;
    I32 size, i;
    STRLEN jlen;
    char *joint;

    if ((svp = av_fetch(args, 0, FALSE)) != NULL) {
	joint = SvPV(*svp, jlen);
    } else {
	joint = " ";
	jlen = 1;
    }

    retval = newSVpvn("", 0);
    size = av_len(list);
    for (i = 0; i <= size; i++) {
	if ((svp = av_fetch(list, i, FALSE)) != NULL) {
	    item = *svp;
	    if (SvROK(item) && SvTYPE(SvRV(item)) == SVt_PVCV) {
		item = call_coderef(*svp, args);
		sv_catsv(retval, item);
	    } else {
		sv_catsv(retval, item);
	    }
	    if (i != size)
		sv_catpvn(retval, joint, jlen);
	}
    }
    return sv_2mortal(retval);
}


/* list.last */
static SV *list_dot_last(AV *list, AV *args) {
    SV **svp;
    if ((av_len(list) > -1)
	&& (svp = av_fetch(list, av_len(list), FALSE))) {
	/* entry fetched from arry may be code ref */
	if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
	    return call_coderef(*svp, args);
	} else {
	    return *svp;
	}
    }
    return &PL_sv_undef;
}
 

/* list.max */
static SV *list_dot_max(AV *list, AV *args) {
    return sv_2mortal(newSViv((IV) av_len(list)));
}


/* list.reverse */
static SV *list_dot_reverse(AV *list, AV *args) {
    SV **svp;
    AV *result = newAV();
    I32 size, i;
	    
    if ((size = av_len(list)) >= 0) {
	av_extend(result, size + 1);
	for (i = 0; i <= size; i++) {
	    if ((svp = av_fetch(list, i, FALSE)) != NULL)
		if (!av_store(result, size - i, SvREFCNT_inc(*svp)))
		    SvREFCNT_dec(*svp);
	}
    }
    return sv_2mortal((SV *) newRV_noinc((SV *) result));
}


/* list.size */
static SV *list_dot_size(AV *list, AV *args) {
    return sv_2mortal(newSViv((IV) av_len(list) + 1));
}


/* hash.each */
static SV *hash_dot_each(HV *hash, AV *args) {
    AV *result = newAV();
    HE *he;
    hv_iterinit(hash);
    while ((he = hv_iternext(hash))) {
	av_push(result, SvREFCNT_inc((SV *) hv_iterkeysv(he)));
	av_push(result, SvREFCNT_inc((SV *) hv_iterval(hash, he)));
    }
    return sv_2mortal((SV *) newRV_noinc((SV *) result));
}


/* hash.keys */
static SV *hash_dot_keys(HV *hash, AV *args) {
    AV *result = newAV();
    HE *he;

    hv_iterinit(hash);
    while ((he = hv_iternext(hash)))
	av_push(result, SvREFCNT_inc((SV *) hv_iterkeysv(he)));

    return sv_2mortal((SV *) newRV_noinc((SV *) result));
}


/* hash.values */
static SV *hash_dot_values(HV *hash, AV *args) {
    AV *result = newAV();
    HE *he;

    hv_iterinit(hash);
    while ((he = hv_iternext(hash)))
	av_push(result, SvREFCNT_inc((SV *) hv_iterval(hash, he)));

    return sv_2mortal((SV *) newRV_noinc((SV *) result));
}


/* scalar.defined */
static SV *scalar_dot_defined(SV *sv, AV *args) {
    return &PL_sv_yes;
}


/* scalar.length */
static SV *scalar_dot_length(SV *sv, AV *args) {
    STRLEN length;
    SvPV(sv, length);

    return sv_2mortal(newSViv((IV) length));
}


/*====================================================================
 * XS SECTION                                                     
 *====================================================================*/

MODULE = Template::Stash::XS		PACKAGE = Template::Stash::XS

PROTOTYPES: DISABLED


#-----------------------------------------------------------------------
# get(SV *root, SV *ident, SV *args)
#-----------------------------------------------------------------------
SV *
get(root, ident, ...)
    SV *root
    SV *ident
    CODE:
    AV *args;
    int flags = get_debug_flag(root);
    STRLEN len;
    char *str;

    /* look for a list ref of arguments, passed as third argument */
    args = 
	(items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) 
	? (AV *) SvRV(ST(2)) : Nullav;

    if (SvROK(ident) && (SvTYPE(SvRV(ident)) == SVt_PVAV)) {
	RETVAL = do_getset(root, (AV *) SvRV(ident), NULL, flags);

    } else if (SvROK(ident)) {
	croak(TT_STASH_PKG ": get (arg 2) must be a scalar or listref");

    } else if ((str = SvPV(ident, len)) && memchr(str, '.', len)) {
	/* convert dotted string into an array */
	AV *av = convert_dotted_string(str, len);
	RETVAL = do_getset(root, av, NULL, flags);
	av_undef(av);

    } else {
	/* otherwise ident is a scalar so we call dotop() just once */
	RETVAL = dotop(root, ident, args, flags);
    }

    if (!SvOK(RETVAL))
	RETVAL = newSVpvn("", 0);	/* new empty string */
    else
	RETVAL = SvREFCNT_inc(RETVAL);

    OUTPUT:
    RETVAL



#-----------------------------------------------------------------------
# set(SV *root, SV *ident, SV *value, SV *deflt)
#-----------------------------------------------------------------------
SV *
set(root, ident, value, ...)
    SV *root
    SV *ident
    SV *value
    CODE:
    int flags = get_debug_flag(root);
    STRLEN len;
    char *str;

    /* check default flag passed as fourth argument */
    flags |= ((items > 3) && SvTRUE(ST(3))) ? TT_DEFAULT_FLAG : 0;

    if (SvROK(ident) && (SvTYPE(SvRV(ident)) == SVt_PVAV)) {
	RETVAL = do_getset(root, (AV *) SvRV(ident), value, flags);

    } else if (SvROK(ident)) {
	croak(TT_STASH_PKG ": set (arg 2) must be a scalar or listref");

    } else if ((str = SvPV(ident, len)) && memchr(str, '.', len)) {
	/* convert dotted string into a temporary array */
	AV *av = convert_dotted_string(str, len);
	RETVAL = do_getset(root, av, value, flags);
	av_undef(av);

    } else {
	/* otherwise a simple scalar so call assign() just once */
	RETVAL = assign(root, ident, Nullav, value, flags);
    }

    if (!SvOK(RETVAL))
	RETVAL = newSVpvn("", 0);	/* new empty string */
    else
	RETVAL = SvREFCNT_inc(RETVAL);
	
    OUTPUT:
    RETVAL


#-----------------------------------------------------------------------
# performance() - returns a summary of Stash & method call performance
#-----------------------------------------------------------------------
SV *
performance(verbose)
    SV *verbose
    CODE:
#ifdef TT_PERF_ENABLE
    I32 a, b, c;
    double total_time, sys_time;
    long max_rss;

    perf_out.cpu_time = get_cpu_usage(&sys_time, &max_rss);
    total_time = sys_time + perf_out.cpu_time;

    perf_out.outsv = newSVpvf(
      TT_STASH_PKG " " XS_VERSION " - Performance Summary for PID %d\n"
      "===================================================================\n"
      "CPU: User: %.2fs + System: %.2fs = Total: %.2fs, RSS: %ldKB\n\n",
      (int) getpid(), perf_out.cpu_time, sys_time, total_time, max_rss);

    if (SvTRUE(verbose)) {
	sv_catpvf(perf_out.outsv, 
	"Method/Virtual Method      Type    # Calls  User CPU  sec/Call %CPU\n"
	"------------------------ --------- -------- --------- -------- ----\n"
	);

	/* avoid division by 0 */
	if (perf_out.cpu_time < 0.0001) perf_out.cpu_time = 1.0;

	dump_all_perf(perf_hist, &perf_out);

	sv_catpvf(perf_out.outsv, "\n\n");
    }

    a = hv_op_cnt    + av_op_cnt    + sv_op_cnt;
    b = hv_op_cnt_xs + av_op_cnt_xs + sv_op_cnt_xs;
    c = hv_op_cnt_pl + av_op_cnt_pl + sv_op_cnt_pl;

    sv_catpvf(perf_out.outsv, 
	"Virtual Method         XS +       PL +  Missing = Total Calls\n"
	"--------------   --------   --------   --------   -----------\n"
	"Array  (AV)    %10d %10d %10d  %12d\n"
	"Hash   (HV)    %10d %10d %10d  %12d\n"
	"Scalar (SV)    %10d %10d %10d  %12d\n"
	"TOTAL          %10d %10d %10d  %12d\n\n",

	av_op_cnt_xs, 
		av_op_cnt_pl, 
		av_op_cnt - (av_op_cnt_xs + av_op_cnt_pl), 
		av_op_cnt,
	hv_op_cnt_xs, 
		hv_op_cnt_pl, 
		hv_op_cnt - (hv_op_cnt_xs + hv_op_cnt_pl), 
		hv_op_cnt,
	sv_op_cnt_xs, 
		sv_op_cnt_pl, 
		sv_op_cnt - (sv_op_cnt_xs + sv_op_cnt_pl), 
		sv_op_cnt,
	b, 
		c, 
		a - (b + c), 
		a);

    RETVAL = perf_out.outsv;
#else
    char *msg = "Profiling was not enabled in " TT_STASH_PKG 
		"(Stash.xs)\n#define TT_PERF_ENABLE and rebuild.\n";
    verbose = verbose; 		/* avoid compiler warning */
    RETVAL = newSVpvn(msg, strlen(msg));
#endif /* TT_PERF_ENABLE */
    OUTPUT:
    RETVAL


#-----------------------------------------------------------------------
# cvsid() - returns cvs id tag for this file
#-----------------------------------------------------------------------
SV *
cvsid()
    CODE:
    RETVAL = newSVpvn(rcsid, strlen(rcsid));
    OUTPUT:
    RETVAL

