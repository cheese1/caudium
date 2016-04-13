/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2005 The Caudium Group
 * Copyright � 2000-2001 Roxen Internet Software
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
//! module: robots.txt generator
//!  Generates a robots.txt on demand from various information.
//!  If there is a robots.txt file in the server root its information will be included
//!  in the final robots.txt file. Other information incorporated is location modules
//!  that does not support directory listings and paths entered under the settings tab.
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_LOCATION
//! cvs_version: $Id$

#include <module.h>;
inherit "module";

constant cvs_version  = "$Id$";
constant thread_safe  = 1;
constant module_type  = MODULE_FIRST;
constant module_name  = "robots.txt generator";
constant module_doc   = "Generates a robots.txt on demand from various information. "
  "If there is a robots.txt file in the server root its information will be included "
  "in the final robots.txt file. Other information incorporated is location modules "
  "that does not support directory listings and paths entered under the settings tab.";
constant module_unique= 1;

// TODO:
// - Incorporate security information, e.g. paths requiring autharization should be in
//   the robots.txt file.
// - Dependency on the real robots.txt file appears to be broken.

void create() {

  defvar("disallow", "/cgi-bin/\n/trap/","Disallow paths", TYPE_TEXT_FIELD,
         "Disallow search engine access to the "
         "listed paths in addition to what is said in the robots.txt "
         "and what this module derives automatically." );

  defvar("locmodules", 0, "Add location modules", TYPE_FLAG,
         "Add <b>ALL</b> location modules into <b>Disallow</b> rule.");

  defvar("internallocs", 0, "Add internal location", TYPE_FLAG,
         "Add Caudium internal location path into <b>Disallow</b> rule.");

  defvar("cache", 1, "Cache generated robots.txt", TYPE_FLAG,
         "If set all generated data will be cached into this module.");
}

// The cache and it's dependencies.
private string _robots;
private string _internal_location;
private array(array(string|function)) _loc_mods;
private int _stat;

string make_rules(mapping forbidden) {
  string ret="";
  foreach(indices(forbidden), string path) {
    ret += "Disallow: "+path+"\n";
    m_delete(forbidden, path);
  }
  return ret;
}

mapping first_try(object id) {

  if(id->misc->internal_get)
    return 0;

  // Should we only intercept /robots.txt or continue
  // to intercept it in all paths?
  int size=sizeof(id->not_query);
  if(id->not_query[size-11..size-1]!="/robots.txt")
    return 0;

  // Disable caching if we don't want it.
  if(QUERY(cache)) _robots = 0;

  // Handle our cache, which depends on several different things.
  array(array(string|function)) loc_mods;
  if(QUERY(locmodules)) {
    loc_mods = id->conf->location_modules();
    if(!_robots || !equal(_loc_mods, loc_mods)) {
      _robots = 0;
      _loc_mods = loc_mods;
    }
  }
   
  string internal_location = replace(id->conf->query_internal_location(""),"\/\/","\/");
  if(!_robots || _internal_location != internal_location) {
    _robots = 0;
    _internal_location = internal_location;
  }
  
  mixed stat = id->conf->stat_file("/robots.txt",id);
  if(stat) stat = stat[3];
  if(!_robots || stat != _stat) {
    _robots = 0;
    _stat = stat;
  }
  if(_robots && QUERY(cache))
    return (["data":_robots]);

  string robots="# This robots file is generated by Caudium WebServer \n#\n";

  array paths = ({ });
  if(QUERY(internallocs))
    paths += ({ internal_location });
  paths += QUERY(disallow) / "\n";
  mapping forbidden = ([ ]); 
  foreach (paths, string foo) 
    forbidden += ([ foo:1 ]);

  if(QUERY(locmodules)) {
    foreach(loc_mods, array(string|function) x) {
      catch {
         if(!function_object(x[1])->find_dir || !x[1](x[0],id))
           forbidden[x[0]] = 1;
      };
    }
  }

  string file = id->conf->try_get_file("/robots.txt", id);
  if(file) {
    array lines = file/"\n" - ({""});
    int in_common, common_found;
    foreach(lines, string line) {

      int type=0;
      if(has_prefix(lower_case(line), "disallow"))
	type=1;
      if(has_prefix(lower_case(line), "user-agent"))
	type=2;

      // Correct keywords with wrong case
      if(type==1 && !has_prefix(line, "Disallow"))
	line = "Disallow" + line[8..];
      if(type==2 && !has_prefix(line, "User-agent"))
	line = "User-agent" + line[10..];

      // Find the first section that applies to all user agents. Note that
      // the module does not collapse several sections with the same user
      // agent to one. If you do have more than one section with
      // User-agent: * the outcome might be a little strange, although it
      // will probably work for any decent robots.txt parser. Don't bet
      // that all robots have a decent robots.txt-parser though.
      if(type==2) {
	string star;
	sscanf(line+" ", "User-agent:%*[ \t]%s%*[ \t#]", star);
	if(star=="*")
	  in_common = 1;
	else
	  in_common = 0;
      }
      if(in_common && !common_found)
	common_found = 1;

      if(type==1) {
	string path;
	sscanf(line+" ", "Disallow:%*[ \t]%s%*[ \t#]", path);
	if(in_common && path && forbidden[path])
	  m_delete(forbidden, path);
      }

      if(common_found && !in_common && forbidden)
	robots += make_rules(forbidden);

      if(type==2) robots += "\n";
      robots += line + "\n";
    }
    if(sizeof(forbidden))
      robots += make_rules(forbidden);
  }
  else if(sizeof(forbidden)) {
    robots += "\nUser-agent: *\n";
    robots += make_rules(forbidden);
  }

  _robots = robots;

  return (["data":robots]);
}

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: disallow
//! Disallow search engine access to the listed paths in addition to what is said in the robots.txt and what this module derives automatically.
//!  type: TYPE_TEXT_FIELD
//!  name: Disallow paths
//
//! defvar: locmodules
//! Add <b>ALL</b> location modules into <b>Disallow</b> rule.
//!  type: TYPE_FLAG
//!  name: Add location modules
//
//! defvar: internallocs
//! Add Caudium internal location path into <b>Disallow</b> rule.
//!  type: TYPE_FLAG
//!  name: Add internal location
//
//! defvar: cache
//! If set all generated data will be cached into this module.
//!  type: TYPE_FLAG
//!  name: Cache generated robots.txt
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

