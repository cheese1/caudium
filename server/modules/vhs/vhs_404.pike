/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2001-2005 The Caudium Group
 * Copyright � 2001 Davies, Inc
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
/*
 * $Id$
 */
/*
 * Based on 404file.pike from Chris Davies
 */

#include <module.h>

inherit "module";
inherit "caudiumlib";

//#define DEBUG

#ifdef DEBUG
# define DEBUGLOG(X) werror("REFER: "+X+"\n")
#else
# define DEBUGLOG(X)
#endif

//! module: VHS 404 file
//!  VHS Error 404 file: simple MODULE_LAST that presents and parses a file
//!  when no modules can handle the request.<br />Based on Chris Davies 
//!  <a href="http://www.daviesinc.com/modules/">module.</a>
//! type: MODULE_LAST
//! inherits: module
//! inherits: caudiumlib
//! cvs_version: $Id$

constant module_type = MODULE_LAST;
constant module_name = "VHS 404 File";
constant module_doc  = "VHS Error 404 file: simple MODULE_LAST that presents "
                       "and parses a file when no modules can handle the request. "
                       "<br/>Based on Chris Davies <a href=\"" 
                       "http://www.daviesinc.com/modules/\">module.</a>";
constant module_unique = 1;
constant cvs_version   = "$Id$";
constant thread_safe   = 1;

void create() {
  defvar ("error404document", "NONE/", "Filename",
          TYPE_STRING,
          "The filename to use in the virtual filesystem.",
          );

  defvar("msie", 1, "Return a 200 to MSIE", TYPE_FLAG,
         "Returns a 200 response to Microsoft Internet Explorer browser "
         "instead of 404.");
}

//! method: string|int readvfsfile(string file, object id)
//!  Get the contents of a file located in the VFS or int 0 if 
//!  the file is not accessible.
//! arg: string file
//!  The file in the VFS (relative or not)
//! arg: object id
//!  Caudium object id
string|int readvfsfile(string file, object id) {
  string s;
  string f = fix_relative(file, id);
  id = id->clone_me();
  if(sscanf(file, "%*s?%s", s) == 2) {
    mapping oldvars = id->variables;
    id->variables = ([ ]);
    if(id->scan_for_query) 
      f = id->scan_for_query( f );
    id->variables = oldvars | id->variables;
    id->misc->_temporary_query_string = s;
  }
  s = id->conf->try_get_file(f, id);

  if (!s) {
    if ((sizeof(f)>2) && (f[sizeof(f)-2..] == "--"))
    {
       // Might be a compat. <!--#include file=foo.html -->
       s = id->conf->try_get_file(f[..sizeof(f)-3], id);
    }
    if (!s)
    {
       // Might be a PATH_INFO type url
       if(id->misc->avoid_path_info_recursion++ < 5)
       {
         array a = id->conf->open_file(f, "r",id);
         if(a && a[0])
         {
           s = a[0]->read();
           if(a[1]->raw)
           {
             s -= "\r";
             if(!sscanf(s, "%*s\n\n%s", s))
                sscanf(s, "%*s\n%s", s);
           }
         }
       }
    }
  } else return 0;
  return s;
}

mapping|int last_resort(object id)
{ 
  string|int html;

  html = readvfsfile(QUERY(error404document), id);


  if(intp(html)) return 0;		// We don't handle the 404file.

  if(QUERY(msie)) {
    if(id->supports->msie404)
      return http_string_answer(parse_rxml(html,id),"text/html");
    else
      return http_low_answer(404, parse_rxml(html,id));
  }
  // If we do not support MSIE hell, then fail back to old system.
  return http_string_answer(parse_rxml(html,id),"text/html");
}

/*
 * Local Variables:
 * c-basic-offset: 2
 * End:
 *
 * vim: softtabstop=2 tabstop=2 expandtab autoindent formatoptions=croqlt smartindent cindent shiftwidth=2
 */

