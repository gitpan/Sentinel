/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#define streq(a,b) (strcmp((a),(b)) == 0)

typedef struct {
  SV *get_cb;
  SV *set_cb;
} sentinel_ctx;

static int magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  sentinel_ctx *ctx = (void *)mg->mg_ptr;

  if(ctx->get_cb) {
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    PUTBACK;

    count = call_sv(ctx->get_cb, G_SCALAR);
    assert(count == 1);

    SPAGAIN;
    sv_setsv_nomg(sv, POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return 1;
}

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  sentinel_ctx *ctx = (void *)mg->mg_ptr;

  if(ctx->set_cb) {
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    PUSHs(sv);
    PUTBACK;

    call_sv(ctx->set_cb, G_VOID);

    SPAGAIN;

    FREETMPS;
    LEAVE;
  }

  return 1;
}

static int magic_free(pTHX_ SV *sv, MAGIC *mg)
{
  sentinel_ctx *ctx = (void *)mg->mg_ptr;

  if(ctx->get_cb)
    SvREFCNT_dec(ctx->get_cb);
  if(ctx->set_cb)
    SvREFCNT_dec(ctx->set_cb);

  Safefree(ctx);

  return 1;
}

static MGVTBL vtbl = {
  &magic_get,
  &magic_set,
  NULL, /* len   */
  NULL, /* clear */
  &magic_free,
};

MODULE = Sentinel    PACKAGE = Sentinel

SV *
sentinel(...)
  PREINIT:
  int i;
    SV *value = NULL;
    SV *get_cb = NULL;
    SV *set_cb = NULL;

  CODE:
    /* Parse name => value argument pairs */
    for(i = 0; i < items; i += 2) {
      char *argname  = SvPV_nolen(ST(i));
      SV   *argvalue = ST(i+1);

      if(streq(argname, "value")) {
        value = argvalue;
      }
      else if(streq(argname, "get")) {
        get_cb = SvREFCNT_inc(argvalue);
      }
      else if(streq(argname, "set")) {
        set_cb = SvREFCNT_inc(argvalue);
      }
      else {
        fprintf(stderr, "Argument %s at %p\n", argname, argvalue);
      }
    }

    RETVAL = newSV(0);

    if(value)
      sv_setsv(RETVAL, value);

    if(get_cb || set_cb) {
      sentinel_ctx *ctx;
      Newx(ctx, 1, sentinel_ctx);

      ctx->get_cb = get_cb;
      ctx->set_cb = set_cb;

      sv_magicext(RETVAL, NULL, PERL_MAGIC_ext, &vtbl, (char *)ctx, 0);
    }

  OUTPUT:
    RETVAL

BOOT:
  CvLVALUE_on(get_cv("Sentinel::sentinel", 0));
