/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <rendezvous/rendezvous.h>

#define MY_DEBUG 0
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


MODULE = Net::Rendezvous::Publish::Backend::Howl		PACKAGE = Net::Rendezvous::Publish::Backend::Howl		

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
