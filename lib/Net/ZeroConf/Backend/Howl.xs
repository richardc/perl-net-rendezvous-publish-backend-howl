/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <rendezvous/rendezvous.h>

#define MY_DEBUG 1
#if MY_DEBUG
#  define DS(x) (x)
#else
#  define DS(x)
#endif


static sw_string
status_text[] = {
    "success",
    "Stopped",
    "Name Collision",
    "Invalid"
};


static sw_result
publish_reply(  
    sw_rendezvous_publish_handler handler,
    sw_rendezvous                 rendezvous,
    sw_rendezvous_publish_status  status,
    sw_rendezvous_publish_id      id,
    sw_opaque                     extra
    )
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    DS( warn( "publish reply: %s %x\n", status_text[status], extra) );

    XPUSHs( (SV*) extra );
    XPUSHs( sv_2mortal( newSVpv(status_text[status], 0) ) );
    PUTBACK;

    call_method("_publish_callback", G_DISCARD);

    return SW_OKAY;
}

static
sw_result
browse_reply( 
    sw_rendezvous_browse_handler  handler,
    sw_rendezvous                 rendezvous,
    sw_rendezvous_browse_id       id,
    sw_rendezvous_browse_status   status,
    sw_const_string               name,
    sw_const_string               type,
    sw_const_string               domain,
    sw_opaque                     extra
    )
{
    sw_rendezvous_resolve_id rid;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs( (SV*) extra);
    XPUSHs(sv_2mortal(newSVpv(name, 0)));
    XPUSHs(sv_2mortal(newSVpv(type, 0)));
    XPUSHs(sv_2mortal(newSVpv(domain, 0)));

    switch (status) {
    case SW_RENDEZVOUS_BROWSE_INVALID:
	DS( warn("browse reply: Invalid\n") );
	break;
    case SW_RENDEZVOUS_BROWSE_RELEASE:
	DS( warn("browse reply: Release\n") );
	break;
    case SW_RENDEZVOUS_BROWSE_ADD_DOMAIN:
	DS( warn("browse reply: Add Domain\n") );
	break;
    case SW_RENDEZVOUS_BROWSE_ADD_DEFAULT_DOMAIN:
	DS( warn("browse reply: Add Default Domain\n") );
	break;
    case SW_RENDEZVOUS_BROWSE_REMOVE_DOMAIN:
	DS( warn("browse reply: Remove Domain\n") );
	break;
    case SW_RENDEZVOUS_BROWSE_ADD_SERVICE:
	DS( warn("browse reply: Add Service %s %s %s\n", name, type, domain) );
/*	if (sw_rendezvous_resolve(rendezvous, name, type, domain, NULL, my_resolver, NULL, &rid) != SW_OKAY)
	DS( warn("resolve failed\n"); */
	XPUSHs(sv_2mortal(newSVpv("add", 0)));
	break;
    case SW_RENDEZVOUS_BROWSE_REMOVE_SERVICE:
	DS( warn("browse reply: Remove Service\n") );
	DS( warn("remove service: %s %s %s\n", name, type, domain) );
	XPUSHs(sv_2mortal(newSVpv("remove", 0)));

	break;
    case SW_RENDEZVOUS_BROWSE_RESOLVED:
	DS( warn("browse reply: Resolved\n") );
	break;
    }

    XPUSHs(sv_2mortal(newSViv(0)));

    PUTBACK;
    call_method("_browse_callback", G_DISCARD);
    FREETMPS;
    LEAVE;
}
 

MODULE = Net::ZeroConf::Backend::Howl		PACKAGE = Net::ZeroConf::Backend::Howl		

sw_rendezvous
init_rendezvous()
CODE:
{
    if (sw_rendezvous_init( &RETVAL ) != SW_OKAY) {
	croak("init failed");
    }
}
OUTPUT:
    RETVAL

sw_rendezvous_publish_id
xs_publish( self, object, name, type, domain, host, port, text )
sw_rendezvous self;
SV* object;
sw_const_string name;
sw_const_string type;
sw_const_string domain;
sw_const_string host;
sw_port port;
SV *text;
CODE:
{
    sw_rendezvous_publish_id id;
    sw_result result;
    STRLEN len;
    char *str = SvPV( text, len );
    DS( warn("publish %s %s %d %x\n", name, type, port, object ) );
    if ((result = sw_rendezvous_publish( 
	     self, name, type, *domain ? domain : NULL, host, port, 
	     str, len,
	     NULL, publish_reply, SvREFCNT_inc( object), &id 
	     )) != SW_OKAY)
    {
	croak("publish failed: %d\n", result);
    }
    RETVAL = id;
}
OUTPUT: RETVAL

sw_rendezvous_browse_id
xs_browse( self, object, type, domain )
sw_rendezvous self;
SV *object;
char *type;
char *domain;
CODE:
{
    sw_rendezvous_browse_id id;
    sw_result result;
    DS( warn("browse %s %s\n", type, domain ) );
    if ((result = sw_rendezvous_browse_services( 
	     self, type, *domain ? domain : NULL, 
	     NULL,  browse_reply, SvREFCNT_inc( object ), &id
	     )) != SW_OKAY)
    {
	croak("browse failed: %d\n", result);
    }
    DS( warn("browser started with id %x\n", id ) );
    RETVAL = id;
}
OUTPUT: RETVAL

sw_result
sw_rendezvous_stop_browse_services(self, id)
	sw_rendezvous	self
	sw_rendezvous_browse_id	id
CODE:
{
    DS( warn("stop browse %x\n", id ) );
    if ((RETVAL = sw_rendezvous_stop_browse_services( self, &id )) != SW_OKAY)
    {
	croak("browse stop failed: %d\n", RETVAL);
    }
}
OUTPUT: RETVAL

sw_result
sw_rendezvous_stop_publish(self, id)
	sw_rendezvous	self
	sw_rendezvous_publish_id	id

sw_result
sw_rendezvous_fina(self)
	sw_rendezvous	self

sw_salt
get_salt( session );
sw_rendezvous session;
CODE:
{
    if (sw_rendezvous_salt( session, &RETVAL ) != SW_OKAY) {
	croak("salt failed");
    }
}
OUTPUT: RETVAL

void
run_step( salt, time )
sw_salt salt;
sw_long time;
CODE:
    sw_salt_step( salt, &time );
