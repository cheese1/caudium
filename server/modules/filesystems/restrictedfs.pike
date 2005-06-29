/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2005 The Caudium Group
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
 *
 */

//
//! module: Restricted file system
//!  This is a restricted filesystem, use it to make users home
//!  directories available to them if they login.
//!  Usable for eg ftp-servers.
//! inherits: filesystem
//! type: MODULE_LOCATION
//! cvs_version: $Id$
//

/*
 * $Id$
 *
 * $Author$
 *
 * Implements a restricted filesystem.
 * This filesystem only allows accesses to files that are a prefix of
 * id->get_user()->home_directory (ie the users home-directory).
 * Usable for eg ftp-servers allowing named ftp.
 *
 * Thanks to Zsolt Varga <redax@agria.hu> for the idea.
 */

inherit "filesystem";

constant cvs_version = "$Id$";

#include <module.h>
#include <caudium.h>

constant module_type = MODULE_LOCATION;
constant module_name = "Restricted filesystem";
constant module_doc  = "This is a restricted filesystem, use it to make users home "
	      "directories available to them if they login.<br>\n"
	      "Usable for eg ftp-servers.";
constant module_unique = 0;

// import Array;

void create()
{
  ::create();
  defvar("remap_home", 0, "Hide path to the home-directory",
	 TYPE_FLAG, "Hides the path to the homedirectory if enabled.<br>\n"
	 "E.g.<br>\n<ul>\n"
	 "If the user <i>foo</i> has the homedirectory <i>/home/foo</i> and "
	 "this is enabled, he will see his files in <b>/</b>.<br>\n"
	 "If this is not enabled, he would see them in <b>/home/foo</b>\n"
	 "</ul>\n");
}

mixed stat_file(string f, object id)
{
  string home;
  if(id->get_user() && id->get_user()->home_directory)
    home = id->get_user()->home_directory;
  if (!stringp(home)) {
    // No home-directory
    return(0);
  }
  if (QUERY(remap_home)) {
    if (home[0] == '/') {
      home = home[1..];
    }
    if (home[-1] != '/') {
      home += "/";
    }
    return(::stat_file(id->misc->_real_file = home + f, id));
  } else {
    if (search("/" + f, home)) {
      // Not a prefix, or short.
      if ((home[1..sizeof(f)] != f) ||
	  ((home[sizeof(f)] != '/') && (home[sizeof(f)+1] != '/'))) {
	return(0);
      }
      // Short.
    }
    return(::stat_file(id->misc->_real_file = f, id));
  }
}

string real_file( mixed f, mixed id ) 
{ 
  string home;
  if(id->get_user() && id->get_user()->home_directory)
    home = id->get_user()->home_directory;

  if (!stringp(home)) { 
    return(0); 
  } 
  
  if(stat_file( f, id )) 
    return path + id->misc->_real_file;
}

array find_dir(string f, object id)
{
  string home;
  if(id->get_user() && id->get_user()->home_directory)
    home = id->get_user()->home_directory;

  if (!stringp(home)) {
    // No home-directory
    return(0);
  }
  if (QUERY(remap_home)) {
    if (home[0] == '/') {
      home = home[1..];
    }
    if (home[-1] != '/') {
      home += "/";
    }
    return(::find_dir(home + f, id));
  } else {
    if (search("/" + f, home)) {
      // Not a prefix, or short
      if (home[1..sizeof(f)] == f) {
	// Short - return the next part of the path.
	return(Array.filter(({ ".", "..", (home[sizeof(f)+1..]/"/")[0] }),
		      dir_filter_function));
      }
    }
    return(::find_dir(f, id));
  }
}

mixed find_file(string f, object id)
{
  string home;
  if(id->get_user() && id->get_user()->home_directory)
    home = id->get_user()->home_directory;

  if (!stringp(home)) {
    // No home-directory
    return(0);
  }
  if (QUERY(remap_home)) {
    if (home[0] == '/') {
      home = home[1..];
    }
    if (home[-1] != '/') {
      home += "/";
    }
    return(::find_file(home + f, id));
  } else {
    if (search("/" + f, home)) {
      // Not a prefix, or short.
      return(0);
    }
    return(::find_file(f, id));
  }
}

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: remap_home
//! Hides the path to the homedirectory if enabled.<br />
//!E.g.<br />
//!<ul>
//!If the user <i>foo</i> has the homedirectory <i>/home/foo</i> and this is enabled, he will see his files in <b>/</b>.<br />
//!If this is not enabled, he would see them in <b>/home/foo</b>
//!</ul>
//!
//!  type: TYPE_FLAG
//!  name: Hide path to the home-directory
//
