/*============================================================= -*-Perl-*-
*
* Template::Stash::XS
*
* DESCRIPTION
*   XS implementation of the core Template::Stash methods. 
*
* AUTHOR
*   Andy Wardley   <abw@kfs.org>
*
* COPYRIGHT
*   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
*   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
*
*   This module is free software; you can redistribute it and/or
*   modify it under the same terms as Perl itself.
*
* TODO
*   - list.sort
*   - scalar.split
*   - have list_op, hash_op and scalar_op extensible via Perl hash arrays?
*
*------------------------------------------------------------------------
*
* $Id$
*
*========================================================================*/


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


#define TT_STASH_PKG	"Template::Stash"
#define TT_LIST_OPS	"Template::Stash::LIST_OPS"
#define TT_HASH_OPS	"Template::Stash::HASH_OPS"
#define TT_LIST_OPS	"Template::Stash::LIST_OPS"
#define TT_SCALAR_OPS   "Template::Stash::SCALAR_OPS"


SV *dotop(SV *root, SV *key_sv, AV *args, int lvalue);
SV *call_coderef(SV *code, AV *args);
SV *fold_results(I32 count);
SV *hash_op(HV *hash, char *key);
SV *list_op(AV *list, char *key, U32 klen, AV *args);
SV *scalar_op(SV *sv, char *key, AV *args);


/*------------------------------------------------------------------------
 * dotop(SV *root, SV *key_sv, AV *args, int lvalue)
 *
 * Resolves dot operations of the form root.key, where 'root' is a
 * reference to the root item, 'key_sv' is an SV containing the
 * operation key (e.g. hash key, list index, first, last, each, etc),
 * 'args' is a list of additional arguments and 'lvalue' is a flag to
 * indicate if, for certain operations (e.g. hash key), the item
 * should be created if it doesn't exist.
 *------------------------------------------------------------------------*/

SV *
dotop(SV *root, SV *key_sv, AV *args, int lvalue)
{
    dSP;
    SV **svp;
    HV *roothv;
    AV *rootav;
    SV *newhash;
    STRLEN keylen;
    char *key = SvPV(key_sv, keylen);
    char *s;

    if (*key == '_' || *key == '.') {
	/* ignore _private or .private members */
	return &PL_sv_undef;
    }
    else if (SvROK(root)) {			    /* OBJECT */
	if (sv_isobject(root) && ! sv_derived_from(root, TT_STASH_PKG)) {
	    HV *stash = SvSTASH((SV *) SvRV(root));
	    GV *gv;

	    /* look for the named method, or an AUTOLOAD method */
	    if ((gv = gv_fetchmethod_autoload(stash, key, 1))) {
		I32 count = (args && args != Nullav) ? av_len(args) : 0;
		I32 i;

		/* push args onto stack and call object method */
		PUSHMARK(SP);
		XPUSHs(root);
		for (i = 0; i <= count; i++) {
		    if ((svp = av_fetch(args, i, 0)) != NULL) {
			XPUSHs(*svp);
		    }
		}
		PUTBACK;
		count = perl_call_method(key, G_ARRAY);
		SPAGAIN;
		return fold_results(count);		
	    }
	}

	/* drop-through if not an object or method not found  */

        switch SvTYPE(SvRV(root)) {

	case SVt_PVHV:				    /* HASH */
	    roothv = (HV *) SvRV(root);
	    if ((svp = hv_fetch(roothv, key, keylen, FALSE)) != NULL) {
		/* entry fetched from hash may be code ref */
	        if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
		    return call_coderef(*svp, args);
		}
		else {
		    return *svp;
		}
	    }
	    else if (lvalue) {
		/* add new namespace hash if lvalue flag set */
		newhash = SvREFCNT_inc((SV *) newRV_noinc((SV *) newHV()));
		if (hv_store(roothv, key, keylen, newhash, 0)) {
		    return newhash;
		}
		else {
		    SvREFCNT_dec(newhash);
		    return &PL_sv_undef;
		}
	    }
	    else {
		return hash_op(roothv, key);
	    }
	    break;

	case SVt_PVAV:				    /* ARRAY */
	    rootav = (AV *) SvRV(root);

	    /* examine the key to see if it looks like an integer */
	    s = key;
	    while (isDIGIT(*s))
		s++;
	    if (*s)
		return list_op(rootav, key, keylen, args);
	    
	    /* reached end of string so key must be an integer */
	    if ((svp = av_fetch(rootav, (I32) atol(key), FALSE)) != NULL) {
		/* entry fetched from arry may be code ref */
	        if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
		    return call_coderef(*svp, args);
		}
		else {
		    return *svp;
		}
	    }
	    else {
		/* no such entry (e.g. exceeded bounds) */
		return &PL_sv_undef;
	    }
	    break;

	default:				    /* BARF */
	    // TODO: [ %s ] doesn't work
	    croak("don't know how to access [ %s ].%s", 
		  SvPV(SvRV(root), PL_na), key);
	}
    }
    else {					    /* SCALAR */
	return scalar_op(root, key, args);	    
    }

    /* not reached */
    return &PL_sv_undef;			    /* just in case */
}


/*------------------------------------------------------------------------
 * assign(SV *root, SV *key_sv, AV *args, SV *value, int deflt)
 *
 * Resolves the final assignment element of a dotted compound variable
 * of the form "root.key(args) = value)".  'root' is a reference to
 * the root item, 'key_sv' is an SV containing the operation key
 * (e.g. hash key, list item, object method), 'args' is a list of user
 * provided arguments (passed only to object methods), 'value' is the
 * assignment value to be set (appended to args) and 'deflt' (default)
 * is a flag to indicate that the assignment should only be performed
 * if the item is currently undefined/false.
 *------------------------------------------------------------------------*/

SV *
assign(SV *root, SV *key_sv, AV *args, SV *value, int deflt)
{
    dSP;
    SV **svp;
    HV *roothv;
    AV *rootav;
    SV *newhash;
    STRLEN keylen;
    char *key = SvPV(key_sv, keylen);
    char *s;

    if (*key == '_' || *key == '.') {
	/* ignore _private or .private members */
	return &PL_sv_undef;
    }
    else if (SvROK(root)) {			    /* OBJECT */
	if (sv_isobject(root) && ! sv_derived_from(root, TT_STASH_PKG)) {
	    HV *stash = SvSTASH((SV *) SvRV(root));
	    GV *gv;

	    /* look for the named method, or an AUTOLOAD method */
	    if ((gv = gv_fetchmethod_autoload(stash, key, 1))) {
		I32 count = (args && args != Nullav) ? av_len(args) : 0;
		I32 i;

		/* push args and value onto stack and call object method */
		PUSHMARK(SP);
		XPUSHs(root);
		for (i = 0; i <= count; i++) {
		    if ((svp = av_fetch(args, i, 0)) != NULL) {
			XPUSHs(*svp);
		    }
		}
		XPUSHs(value);
		PUTBACK;
		count = perl_call_method(key, G_ARRAY);
		SPAGAIN;
		return fold_results(count);		
	    }
	}

	/* drop-through if not an object or method not found  */

        switch SvTYPE(SvRV(root)) {

	case SVt_PVHV:				    /* HASH */
	    roothv = (HV *) SvRV(root);

	    /* check for any existing value if default flag set */
	    if (deflt
		    && (svp = hv_fetch(roothv, key, keylen, FALSE)) != NULL
		    && SvTRUE(*svp))
		return &PL_sv_undef;
		    
	    if (hv_store(roothv, key, keylen, value, 0))
		return SvREFCNT_inc(value);
	    else
		return &PL_sv_undef;

	    break;

	case SVt_PVAV:				    /* ARRAY */
	    rootav = (AV *) SvRV(root);

	    /* examine the key to see if it looks like an integer */
	    s = key;
	    while (isDIGIT(*s))
		s++;
	    if (*s)
		croak("can't assign to item '%s' in a list", key);
	    
	    /* check for any existing value if default flag set */
	    if (deflt
		    && (svp = av_fetch(rootav, atol(key), FALSE)) != NULL
		    && SvTRUE(*svp))
		return &PL_sv_undef;

	    if (av_store(rootav, atol(key), value))
		return SvREFCNT_inc(value);
	    else
		return &PL_sv_undef;

	    break;

	default:				    /* BARF */
	    // TODO: fix [ %s ]
	    croak("don't know how to assign to [ %s ].%s", SvRV(root), key);
	}
    }
    else {					    /* SCALAR */
	// TODO: fix [ %s ]
	croak("don't know how to assign to [ %s ].%s", SvRV(root), key);
    }

    /* not reached */
    return &PL_sv_undef;			    /* just in case */
}



/*------------------------------------------------------------------------
 * call_coderef(SV *code, AV *args)
 *
 * Pushes any arguments in 'args' onto the stack then calls the code ref
 * in 'code'.  Calls fold_results() to massage the return value(s).
 *------------------------------------------------------------------------*/

SV *
call_coderef(SV *code, AV *args)
{
    dSP;
    SV **svp;
    AV *results;
    SV *retval;
    I32 count = (args && args != Nullav) ? av_len(args) : 0;
    I32 i;

    PUSHMARK(SP);
    for (i = 0; i <= count; i++) {
	if ((svp = av_fetch(args, i, 0)) != NULL) {
	    XPUSHs(*svp);
	}
    }
    PUTBACK;
    count = perl_call_sv(code, G_ARRAY);
    SPAGAIN;

    return fold_results(count);
}


/*------------------------------------------------------------------------
 * fold_results(I32 count)
 *
 * Pops 'count' items off the stack, folding them into a list reference
 * if count > 1, or returning the sole item if count == 1.  Returns undef
 * if count == 0.
 *------------------------------------------------------------------------*/

SV *
fold_results(I32 count)
{
    dSP;
    SV *retval;
    I32 ax;

    SP -= count ;
    ax = (SP - PL_stack_base) + 1 ;

    if (! count) {
	retval = &PL_sv_undef;
    }
    else if (SvOK(ST(0))) {
	if (count > 1) {
	    /* fold multiple return values into a list reference */
	    AV *results = newAV();
	    av_unshift(results, count);
	    while(--count >= 0) {
		retval = ST(count);
		if (!av_store(results, count, SvREFCNT_inc(retval))) 
		    SvREFCNT_dec(retval);
	    }
	    retval = sv_2mortal((SV *) newRV_noinc((SV *) results));
	}
	else 
	    retval = ST(0);
    }
    else if (count > 1 && SvOK(ST(1))) {
	PUTBACK;
	if (sv_isobject(ST(1))) {
	    /* throw object via ERRSV ($@) */
	    SV *error = ERRSV;
	    (void) SvUPGRADE(error, SVt_PV);
	    SvSetSV(error, ST(1));
	    (void) die(Nullch);  
	}
	else {
	    /* regular error message thrown via croak() */
	    croak("%s", SvPV(ST(1), PL_na));
	}
    }
    else {
	retval = &PL_sv_undef;
    }
    PUTBACK;

    return retval;
}


/*------------------------------------------------------------------------
 * hash_op(HV *hash, char *key)
 *
 * Performs a generic hash operation on identified by 'key' (e.g. keys, 
 * values, each) on 'hash'.
 *------------------------------------------------------------------------*/

SV *
hash_op(HV *hash, char *key)
{
    AV *result = newAV();
    HE *he;

    switch (*key) {
    case 'e':
	if (strEQ(key, "each")) {		    /* hash.each */
	    hv_iterinit(hash);
	    while ((he = hv_iternext(hash)) != NULL) {
		av_push(result, SvREFCNT_inc((SV *) hv_iterkeysv(he)));
		av_push(result, SvREFCNT_inc((SV *) hv_iterval(hash, he)));
	    }
	    return sv_2mortal((SV *) newRV_noinc((SV *) result));
	}
	break;

    case 'k':
	if (strEQ(key, "keys")) {		    /* hash.keys */
	    hv_iterinit(hash);
	    while ((he = hv_iternext(hash)) != NULL)
		av_push(result, SvREFCNT_inc((SV *) hv_iterkeysv(he)));

	    return sv_2mortal((SV *) newRV_noinc((SV *) result));
	}
	break;

    case 'v':
	if (strEQ(key, "values")) {		    /* hash.values */
	    hv_iterinit(hash);
	    while ((he = hv_iternext(hash)) != NULL) {
		av_push(result, SvREFCNT_inc((SV *) hv_iterval(hash, he)));
	    }
	    return sv_2mortal((SV *) newRV_noinc((SV *) result));
	}
	break;
    }
    return &PL_sv_undef;;
}


/*------------------------------------------------------------------------
 * list_op(AV *list, char *key, U32 keylen, AV *args)
 *
 * Performs a generic list operation identified by 'key' (e.g. keys, 
 * values, each) on 'list'.  Additional arguments may be passed in 'args'.
 *------------------------------------------------------------------------*/
    
SV *
list_op(AV *list, char *key, U32 keylen, AV *args)
{
    SV **svp;
    SV *sv;

    switch (*key) {
    case 'f':
	if (strEQ(key, "first")) {		    /* list.first */
	    if ((svp = av_fetch(list, 0, FALSE)) != NULL) {
		/* entry fetched from arry may be code ref */
	        if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
		    return call_coderef(*svp, args);
		}
		else {
		    return *svp;
		}
	    }
	}
	break;

    case 'j':
	if (strEQ(key, "join")) {		    /* list.join */
	    SV *item, *retval;
	    I32 size, i;
	    STRLEN jlen;
	    char *joint;

	    if ((svp = av_fetch(args, 0, FALSE)) != NULL) {
		joint = SvPV(*svp, jlen);
	    }
	    else {
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
		    }
		    else {
			sv_catsv(retval, item);
		    }
		    if (i != size)
			sv_catpvn(retval, joint, jlen);
		}
	    }
	    return retval;
	}
	break;

    case 'l':
	if (strEQ(key, "last")) {		    /* list.last */
	    if ((svp = av_fetch(list, av_len(list), FALSE)) != NULL) {
		/* entry fetched from arry may be code ref */
	        if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
		    return call_coderef(*svp, args);
		}
		else {
		    return *svp;
		}
	    }
	}
	break;

    case 'm':
	if (strEQ(key, "max")) {		    /* list.max */
	    return sv_2mortal(newSViv((IV) av_len(list)));
	}
	break;

    case 'r':
	if (strEQ(key, "reverse")) {		    /* list.reverse */
	    AV *result = newAV();
	    I32 size, i;
	    
	    if ((size = av_len(list))) {
		av_extend(result, size + 1);
		for (i = 0; i <= size; i++) {
		    if ((svp = av_fetch(list, i, FALSE)) != NULL)
			if (!av_store(result, size - i, SvREFCNT_inc(*svp)))
			    SvREFCNT_dec(*svp);
		}
	    }
	    return sv_2mortal((SV *) newRV_noinc((SV *) result));
	}
	break;

    case 's':
	if (strEQ(key, "size")) {		    /* list.size */
	    return sv_2mortal(newSViv((IV) av_len(list) + 1));
	}

	if (strEQ(key, "sort")) {		    /* TODO: list.sort */
	    /* TODO */
	    return sv_2mortal(newSVpv("list.sort not yet implemented", 0));
	}
	break;
    }

    return &PL_sv_undef;;
}


/*------------------------------------------------------------------------
 * scalar_op(SV *sv, char *key, AV *args)
 *
 * Performs a generic scalar operation identified by 'key' (e.g. defined, 
 * length, split) on 'sv'.  Additional arguments may be passed in 
 * 'args'.
 *------------------------------------------------------------------------*/
    
SV *
scalar_op(SV *sv, char *key, AV *args)
{
    STRLEN length;
    char *str = SvPV(sv, length);

    switch (*key) {
    case 'd':
	if (strEQ(key, "defined")) {		    /* string.defined */
	    return &PL_sv_yes;
	}
	break;

    case 'l':
	if (strEQ(key, "length")) {		    /* string.length */
	    return sv_2mortal(newSViv((IV) length));
	}
	break;

    case 's':
	if (strEQ(key, "split")) {		    /* TODO: string.split */
	    /* TODO */
	    return sv_2mortal(newSVpv("scalar.split not yet implemented", 0));
	}
	break;
    }
    return &PL_sv_undef;
}
    
 
/*========================================================================
 * XS SECTION                                                     
 *========================================================================*/

MODULE = Template::Stash::XS		PACKAGE = Template::Stash

PROTOTYPES: DISABLED


#------------------------------------------------------------------------
# get(SV *root, SV *ident, SV *args)
#------------------------------------------------------------------------

SV *
get(root, ident, ...)
    SV *root
    SV *ident
    CODE:
    AV *args, *key_args, *ident_av;
    SV *key;
    SV **svp;
    I32 size, i;

    /* look for a list ref of arguments, passed as third argument */
    if (items > 2 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
	args = (AV *) SvRV(ST(2));
    }
    else {
	args = Nullav;
    }

    if (SvROK(ident)) {

	/* if ident is a reference to a list then we iterate through it
	 * calling dotop() to resolve each (key, args) item
         */

	if (SvTYPE(SvRV(ident)) == SVt_PVAV) {
	    ident_av = (AV *) SvRV(ident);
	    size = av_len(ident_av);
	    for(i = 0; i < size; i += 2) {
		if ((svp = av_fetch(ident_av, i, FALSE)) == NULL)
		    croak("bad ident element at position %d", i);
		key = *svp;
		if ((svp = av_fetch(ident_av, i + 1, FALSE)) == NULL)
		    croak("bad ident arguments at position %d", i + 1);
		if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
		    key_args = (AV *) SvRV(*svp);
		else
		    key_args = Nullav;
		
		root = dotop(root, key, key_args, FALSE);
		if (!SvOK(root))
		    break;
	    }
	    RETVAL = root;
	}
	else {
	    croak("stash ident (arg 2) must be a scalar or list ref");
	}
    }
    else {
	/* otherwise ident is a scalar so we call dotop() just once */
	RETVAL = dotop(root, ident, args, FALSE);
    }

    if (!SvOK(RETVAL)) {
	RETVAL = newSVpvn("", 0);
    }
    else {
	RETVAL = SvREFCNT_inc(RETVAL);
    }
	

    OUTPUT:
    RETVAL


#------------------------------------------------------------------------
# set(SV *root, SV *ident, SV *value, SV *deflt)
#------------------------------------------------------------------------

SV *
set(self, ident, value, ...)
    SV *self
    SV *ident
    SV *value
    CODE:
    int deflt;
    AV *key_args, *ident_av;
    SV *root = self;
    SV *key;
    SV **svp;
    I32 size, i;

    /* look for the default flag passed as fourth argument */
    deflt = items > 3 ? SvTRUE(ST(3)) : FALSE;

    if (SvROK(ident)) {

	/* if ident is a reference to a list then we iterate through it
	 * calling dotop() to resolve all but the last item 
         */
	if (SvTYPE(SvRV(ident)) == SVt_PVAV) {
	    ident_av = (AV *) SvRV(ident);
	    size = av_len(ident_av);
	    for(i = 0; i < size - 1; i += 2) {
		if ((svp = av_fetch(ident_av, i, FALSE)) == NULL)
		    croak("bad ident element at position %d", i);
		key = *svp;
		if ((svp = av_fetch(ident_av, i + 1, FALSE)) == NULL)
		    croak("bad ident arguments at position %d", i + 1);
		if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
		    key_args = (AV *) SvRV(*svp);
		else
		    key_args = Nullav;
		
		root = dotop(root, key, key_args, TRUE);
		if (!SvOK(root)) {
		    RETVAL = root;
		    goto done;
		}
	    }
	    /* call assign() to resolve the last item */
	    if ((svp = av_fetch(ident_av, size - 1, FALSE)) == NULL)
		    croak("bad ident element at position %d", i);
	    key = *svp;
	    if ((svp = av_fetch(ident_av, size, FALSE)) == NULL)
		croak("bad ident arguments at position %d", i + 1);
	    if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
		key_args = (AV *) SvRV(*svp);
	    else
		key_args = Nullav;

#	    printf("doing assign %s.%s = %s\n", SvPV(root, PL_na),
#		   SvPV(key, PL_na), SvPV(value, PL_na));

	    RETVAL = assign(root, key, key_args, value, deflt);
	}
	else {
	    croak("stash ident (arg 2) must be a scalar or list ref");
	}
    }
    else {
	/* otherwise ident is a scalar so we call assign() just once */
	RETVAL = assign(root, ident, Nullav, value, deflt);
    }

    done:

    if (!SvOK(RETVAL)) {
	RETVAL = newSVpvn("", 0);
    }
    else {
	RETVAL = SvREFCNT_inc(RETVAL);
    }
	
    OUTPUT:
    RETVAL
