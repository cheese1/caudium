/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2003 The Caudium Group
 * Copyright � 1994-2001 Roxen Internet Software
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
//! module: Java Servlet bridge
//!  An interface to Java Servlets
//! inherits: module
//! inherits: caudiumlib
//! inherits: http
//! type: MODULE_LOCATION
//! cvs_version: $Id$
//
/* Implements java servlets */

#include <module.h>

constant cvs_version = "$Id$";
int thread_safe=1;

inherit "module";
inherit "caudiumlib";
static inherit "http";

constant module_type = MODULE_LOCATION;
constant module_name = "Java Servlet bridge";
constant module_doc  = "An interface to Java <a href=\"http://jserv.javasoft.com/"
    "products/java-server/servlets/index.html\">Servlets</a>.";
constant module_unique = 0;

/* Doesn't work on NT yet */
#if constant(Java.machine)

object servlet;

string status_info="";

void stop()
{
  if(servlet) {
    destruct(servlet);
    servlet = 0;
  }
}

static mapping(string:string) make_initparam_mapping()
{
  mapping(string:string) p = ([]);
  string n, v;
  foreach(QUERY(parameters)/"\n", string s)
    if(2==sscanf(s, "%[^=]=%s", n, v))
      p[n]=v;
  return p;
}

void start(int x, object conf)
{
  if(x == 2)
    stop();
  else if(x != 0)
    return;

  mixed exc = catch(servlet = Servlet.servlet(QUERY(classname),
					      QUERY(codebase)));
  status_info="";
  if(exc)
  {
    werror(exc[0]);
    status_info=sprintf("<pre>%s</pre>",exc[0]);
  }
  else
    if(servlet)
      servlet->init(Servlet.conf_context(conf), make_initparam_mapping());
}

string status()
{
  return (servlet?
	  servlet->info() || "<i>No servlet information available</i>" :
	  "<font color=red>Servlet not loaded</font>"+"<br>"+
	  status_info);
}

string query_location()
{
  return QUERY(mountpoint);
}

string query_name()
{
  return sprintf("<i>%s</i> mounted on <i>%s</i>", query("classname"),
		 query("mountpoint"));
}

void create()
{
  defvar("mountpoint", "/servlet/NONE", "Servlet location", TYPE_LOCATION,
	 "This is where the servlet will be inserted in the "
	 "namespace of your server.");

  defvar("codebase", "servlets", "Code directory", TYPE_DIR,
	 "This is the base directory for the servlet class files.");

  defvar("classname", "NONE", "Class name", TYPE_STRING,
	 "The name of the servlet class to use.");

  defvar("parameters", "", "Parameters", TYPE_TEXT,
	 "Parameters for the servlet on the form "
	 "<tt><i>name</i>=<i>value</i></tt>, one per line.");
  defvar("debugmode", "Log", "Error messages", TYPE_STRING_LIST | VAR_MORE,
	 "How to report errors (e.g. backtraces generated by the Pike code):\n"
	 "\n"
	 "<p><ul>\n"
	 "<li><i>Off</i> - Silent.</li>\n"
	 "<li><i>Log</i> - System debug log.</li>\n"
	 "<li><i>HTML comment</i> - Include in the generated page as an HTML comment.</li>\n"
	 "<li><i>HTML text</i> - Include in the generated page as normal text.</li>\n"
	 "</ul></p>\n",
	 ({"Off", "Log", "HTML comment", "HTML text"}));

}

string reporterr (string header, string dump)
{
  if (QUERY (debugmode) == "Off") return "";

  report_error (header + dump + "\n");

  switch (QUERY (debugmode)) {
    case "HTML comment":
      return "\n<!-- " + header + dump + "\n-->\n";
    case "HTML text":
      return "\n<br><font color=red><b>" + _Roxen.html_encode_string (header) +
	"</b></font><pre>\n" + _Roxen.html_encode_string (dump) + "</pre><br>\n";
    default:
      return "";
  }
}

mixed find_file( string f, object id )
{
  if(!servlet)
    return http_string_answer(reporterr("Servlet loading failed",status_info));
  
  id->my_fd->set_read_callback(0);
  id->my_fd->set_close_callback(0);
  id->my_fd->set_blocking();
  id->misc->path_info = f;
  id->misc->mountpoint = QUERY(mountpoint);
  servlet->service(id);

  return http_pipe_in_progress();
}


#else

array register_module() {
  // Little hack to allow warning :)
  return ({ module_type,
            module_name,
            module_doc + status(),
            0, 0
  });
}

string status() {
  return "<p><font color=\"red\">The JAVA Virtual Machine is not available"
         " please double check that Pike did correctly detected</font></p>";
}

#endif

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: mountpoint
//! This is where the servlet will be inserted in the namespace of your server.
//!  type: TYPE_LOCATION
//!  name: Servlet location
//
//! defvar: codebase
//! This is the base directory for the servlet class files.
//!  type: TYPE_DIR
//!  name: Code directory
//
//! defvar: classname
//! The name of the servlet class to use.
//!  type: TYPE_STRING
//!  name: Class name
//
//! defvar: parameters
//! Parameters for the servlet on the form <tt><i>name</i>=<i>value</i></tt>, one per line.
//!  type: TYPE_TEXT
//!  name: Parameters
//
//! defvar: debugmode
//! How to report errors (e.g. backtraces generated by the Pike code):
//!
//!<p><ul>
//!<li><i>Off</i> - Silent.</li>
//!<li><i>Log</i> - System debug log.</li>
//!<li><i>HTML comment</i> - Include in the generated page as an HTML comment.</li>
//!<li><i>HTML text</i> - Include in the generated page as normal text.</li>
//!</ul></p>
//!
//!  type: TYPE_STRING_LIST|VAR_MORE
//!  name: Error messages
//
