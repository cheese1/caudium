/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2004 The Caudium Group
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

#include <module.h>
inherit "modules/scripting/fastcgi.pike": fastcgi;

//! module: Universal script parser (FastCGI)
//!  This module provides extensions handling by misc script interpreters. 
//!  Scripts can be run as choosen user, or by owner. Module is based on
//!  the FastCGI module.
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_FILE_EXTENSION
//! cvs_version: $Id$
//

constant cvs_version = "$Id$";

constant module_type = MODULE_FILE_EXTENSION|MODULE_EXPERIMENTAL;
constant module_name = "Universal script parser - FastCGI";
constant module_doc  = "This module provides extensions handling by miscellaneous script interpreters. "
			"Scripts can be run as choosen user, or by owner. This module uses FastCGI "
                        "to communicate with the script interpreter.";
constant module_unique = 0;

#ifdef CGI_DEBUG
#define DWERROR(X)      report_debug(X)
#else /* !CGI_DEBUG */
#define DWERROR(X)
#endif /* CGI_DEBUG */

class CGIScript
{
  inherit fastcgi::CGIScript;

  CGIScript run()
  {
    DWERROR("CGI:CGIScript::run()\n");
    fcgi = do_fcgiscript( this_object() );
    fcgi->set_done_callback( done );
    ready = 1;
    stdin = fcgi->stdin;
    stdout= fcgi->stdout;
    pid   = fcgi->fake_pid();
    return this_object( );

  }


  void create( object id )
  {
    DWERROR("CGI:CGIScript()\n");
    ::create(id);

    if(!id->realfile)
    {
      id->realfile = id->conf->real_file( id->not_query, id );
      if(!id->realfile)
        error("No real file associated with "+id->not_query+
              ", thus it's not possible to run it as a FCGI script.\n");
    }
    command = QUERY(interpreter);
//    arguments = ({id->real_file}) + (arguments || ({}));

    // I assume that all scripts are internal redirected.
    // Is this good idea ? Without this PHP4 CGI version won't work
    // if(id->misc->is_redirected)
      environment["REDIRECT_STATUS"] = "1";
      environment["PATH_TRANSLATED"] = environment["SCRIPT_FILENAME"];

  }
}

mapping handle_file_extension(object o, string e, object id)
{
  DWERROR("CGI:handle_file_extension()\n");

  return Caudium.HTTP.stream( CGIScript( id )->run()->get_fd() );
}

void create(object conf)
{
  ::create(conf);
  killvar("rxml");

  defvar("rxml", 0, "Parse RXML in uni-scripts", TYPE_FLAG,
         "If this is set, the output from uni-scripts handled by this "
         "module will be RXML parsed. NOTE: No data will be returned to the "
         "client until the uni-script is fully parsed.",0,getuid);

  killvar("location");
  killvar("searchpath");
  killvar("ls");
  killvar("ex");
  killvar("ext");
//  killvar("fcgi_tag");
  killvar("noexec");

  defvar("interpreter", "/usr/bin/php3", "Interpreter path", TYPE_LOCATION, 
	 "Path to interpreter executable");

  defvar("ext", ({"php",}), "Script extensions", TYPE_STRING_LIST,
         "All files ending with these extensions, will be parsed by " +
	 "given interpreter.");

  defvar("runowner", 1, "Run scripts as owner", TYPE_FLAG,
	 "If enabled, scripts are run as owner.", 0, getuid);

  defvar("nproc", 10, "Limits: Max procs", TYPE_INT,
	 "Maximum nuber of user process.");

}


/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: rxml
//! If this is set, the output from uni-scripts handled by this module will be RXML parsed. NOTE: No data will be returned to the client until the uni-script is fully parsed.
//!  type: TYPE_FLAG
//!  name: Parse RXML in uni-scripts
//
//! defvar: interpreter
//! Path to interpreter executable
//!  type: TYPE_LOCATION
//!  name: Interpreter path
//
//! defvar: ext
//! All files ending with these extensions, will be parsed by 
//!  type: TYPE_STRING_LIST
//!  name: Script extensions
//
//! defvar: runowner
//! If enabled, scripts are run as owner.
//!  type: TYPE_FLAG
//!  name: Run scripts as owner
//
//! defvar: nproc
//! Maximum nuber of user process.
//!  type: TYPE_INT
//!  name: Limits: Max procs
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

