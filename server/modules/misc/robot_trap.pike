/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2003 The Caudium Group
 * Copyright � 199?-1997 Roxen Internet Software
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
/*
 * $Id$
 */
//! module: Robot Trap
//!  A module to get robots/download scripts/spam harvesters trapped in an 
//!  endless maze of links. Can also provide phoney email addresses, to 
//!  trick scripts collecting addresses for spamming purposes.
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_LOCATION
//! cvs_version: $Id$

#include <module.h>
inherit "module";
inherit "caudiumlib";

constant cvs_version  = "$Id$";
constant thread_safe  = 1;
constant module_type  = MODULE_LOCATION;
constant module_name  = "Robot Trap";
constant module_doc   = "A module to get robots/download scripts/spam "
                        "harvesters trapped in an endless maze of links. "
                        "Can also provide phoney email addresses, to trick "
                        "scrupts collection addresses for spamming purposes.";
constant module_unique= 1;

constant rnd="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.";

string random_string()
{
  return
    `+(@map(map(map(allocate(10), lambda(int x){return strlen(rnd);}), random),
	    lambda(int x){return rnd[x..x];}));
}

string query_location()
{
  return query( "mountpoint" );
}

object|mapping find_file( string f, object id )
{
  string body="";
  int cnt;

  if(id->method != "GET")
    return 0;

  if((f=="" || f[0]!='/') && query_location()[-1] != '/')
    return http_redirect( query_location()+"/"+f, id );

//  sucker_clients[id->client[0]]++;
//  sucker_hosts[id->remoteaddr]++;
  
  for(cnt=(int)query( "num_links" ); cnt>0; --cnt)
    body+="<a href=\""+random_string()+"\">"+random_string()+"</a><br>\n";

  body+="<br>\n";

  for(cnt=(int)query( "num_emails" ); cnt>0; --cnt)
    body+="<a href=\"mailto:"+random_string()+"@"+random_string()+".com\">"+
      random_string()+"</a><br>\n";

  return http_string_answer("<html><head><title>"+random_string()+
			    "</title><head>\n<body>"+body+
			    "</body>\n</html>\n", "text/html");
}

void create()
{
  defvar( "mountpoint", "/trap/", "Mount point", TYPE_LOCATION, 
	  "This is where the module will be inserted in the "
	  "namespace of your server." );

  defvar( "num_links", 10, "Number of links per page", TYPE_INT,
	  "This is the number of random links that will be "
	  "generated on each page." );

  defvar( "num_emails", 10, "Number of addresses per page", TYPE_INT,
	  "This is the number of random email addresses that will be "
	  "generated on each page." );
 
  defvar( "tld", ".com,.net,.org,.info,.biz","TLD used for emails", TYPE_STRING,
          "Comma separated TLD used for email generator.");
}

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: mountpoint
//! This is where the module will be inserted in the namespace of your server.
//!  type: TYPE_LOCATION
//!  name: Mount point
//
//! defvar: num_links
//! This is the number of random links that will be generated on each page.
//!  type: TYPE_INT
//!  name: Number of links per page
//
//! defvar: num_emails
//! This is the number of random email addresses that will be generated on each page.
//!  type: TYPE_INT
//!  name: Number of addresses per page
//
//! defvar: tld
//! Comma separated TLD used for email generator.
//!  type: TYPE_STRING
//!  name: TLD used for emails
//

/*
 * If you visit a file that doesn't contain these lines at its end, please
 * cut and paste everything from here to that file.
 */

/*
 * Local Variables:
 * c-basic-offset: 2
 * End:
 *
 * vim: softtabstop=2 tabstop=2 expandtab autoindent formatoptions=croqlt smartindent cindent shiftwidth=2
 */

