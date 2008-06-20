/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2008 The Caudium Group
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
#include <caudium.h>
#include <stat.h>

inherit "module";
inherit "caudiumlib";
inherit "socket";

constant module_type = MODULE_LOCATION|MODULE_EXPERIMENTAL;
constant module_name = "Filesystem v2";
constant module_doc  = "This is a virtual filesystem, use it to make files available to "
"the users of your WWW-server. If you want to serve any 'normal' "
"files from your server, you will have to have at least one filesystem."
"A file system mounted on '/' is what other servers generally call "
"<b>DOCUMENT ROOT</b>. The whole concept is somewhat different in "
"Caudium however, since you can have any number of file systems mounted in "
"different locations. ";
constant module_unique = 0;
constant cvs_version= "$Id: filesystem2.pike,v 1.5 2008-04-23 04:55:54 bertrand Exp $";
constant thread_safe=1;


#if DEBUG_LEVEL > 20
# ifndef FILESYSTEM_DEBUG
#  define FILESYSTEM_DEBUG
# endif
#endif

#define FILE_SIZE(X) (Stdio.file_size(X))

#define TRACE_ENTER(A,B) do{if(id->misc->trace_enter)id->misc->trace_enter((A),(B));}while(0)
#define TRACE_LEAVE(A) do{if(id->misc->trace_leave)id->misc->trace_leave((A));}while(0)


// Global variables

int redirects, accesses, errors, dirlists;
int puts, deletes, mkdirs, moves, chmods, appes;
int dirperm, fileperm, default_umask;
static int do_stat = 1;

mapping putting = ([]);



/*****************************************************************************
 * Caudium API
 *****************************************************************************/

void start(int count, object conf)
{
#ifdef THREADS
  if(QUERY(access_as_user))
    report_warning("When running in threaded mode,  'Access as user' will only "
		   "be used for requests that do some kind of modification. "
		   "If you want reading to be done as the user as well, you "
		   "need to run with threads disabled.");
#endif
  sscanf(QUERY(dirperm),  "%o", dirperm);
  sscanf(QUERY(fileperm), "%o", fileperm);
  sscanf(QUERY(umask),    "%o", default_umask);
  
#ifdef FILESYSTEM_DEBUG
  perror("FILESYSTEM: Online at "+QUERY(mountpoint)+"\n");
#endif
}



void create(object conf)
{
  defvar("mountpoint", "/", "Paths: Mount point", TYPE_LOCATION, 
	 "This is where the module will be inserted in the "+
	 "namespace of your server.");

  defvar("searchpath", "NONE", "Paths: Search path", TYPE_DIR,
	 "This is where the module will find the files in the real "
	 "file system and is equivalent to what is normally referred to as "
	 "the <b>document root</b>.");

  defvar("fileperm", "0666", "Permissions: Default mode for uploaded files",
	 TYPE_STRING, "This is the default mode, specified as an octal "
	 "integer, for uploaded files. The default or specified umask "
	 "will modify the actual permission of uploaded files.");
  
  defvar("dirperm", "0777", "Permissions: Default for created directories",
	 TYPE_STRING, "This is the default mode, specified in octal "
	 "integer, for created files. The default or specified umask "
	 "will modify the actual permission of uploaded files.");
  
  defvar("umask", "022", "Permissions: Default umask",
	 TYPE_STRING, "This is the default umask for creating files and is "
	 "used as a modified for the default file and directory "
	 "modes. It can be overridden by using the 'SITE UMASK' "
	 "command in FTP.");
  
#ifdef COMPAT
  defvar("html", 0, "All files are really HTML files", TYPE_FLAG|VAR_EXPERT,
	 "If you set this variable, the filesystem will _know_ that all files "
	 "are really HTML files. This might be useful now and then.");
#endif

  defvar(".files", 0, "Directory Settings: Show hidden files", TYPE_FLAG|VAR_MORE,
	 "If set, hidden files will be shown in dirlistings and you "
	 "will be able to retrieve them.");

  defvar("dir", 1, "Directory Settings: Enable directory listings per default", TYPE_FLAG|VAR_MORE,
	 "If set, you have to create a file named .www_not_browsable ("
	 "or .nodiraccess) in a directory to disable directory listings."
	 " If unset, a file named .www_browsable in a directory will "
	 "_enable_ directory listings.\n");

  defvar("tilde", 0, "Directory Settings: Show backup files", TYPE_FLAG|VAR_MORE,
	 "If set, files ending with '~', '#', '.old' or '.bak' will "+
	 "be shown in directory listings");


  /* Methods to allow */
  defvar("put", 0, "Allowed Access Methods: PUT", TYPE_FLAG,
	 "If set, allow use of the PUT method, which is used for file "
	 "uploads. ");
  
  defvar("appe", 0, "Allowed Access Methods: APPE", TYPE_FLAG,
         "If set and if PUT method too, APPEND method can be used on "
         "file uploads.");
  
  defvar("delete", 0, "Allowed Access Methods: DELETE", TYPE_FLAG,
	 "If set, allow use of the DELETE method, which is used for file "
	 "deletion.");
  
  defvar("copy", 0, "Allowed Access Methods: COPY", TYPE_FLAG,
	 "If set, allow use of the COPY method, which is used for file "
	 "copy by WebDAV.");
  
  defvar("method_mkdir", 0, "Allowed Access Methods: MKDIR", TYPE_FLAG,
	 "If set, allow use of the MKDIR method, enabling the ability to "
	 "the create new directories.");
  
  defvar("method_mv", 0, "Allowed Access Methods: MV", TYPE_FLAG,
	 "If set, allow use of the MV method, which is used for renaming "
	 "files and directories.");
  
  defvar("method_chmod", 0, "Allowed Access Methods: CHMOD", TYPE_FLAG,
	 "If set, allow use of the CHMOD command, which is used to change "
	 "file permissions.");

  defvar("keep_old_perms", 1, "Permissions: Keep old file mode",
	 TYPE_FLAG, "If true, existing files replaced by an FTP or HTTP "
	 "upload will keep their previous file mode instead of using the "
	 "default one. When enabled, the default mode and umask settings "
	 "(default or specified by the client) won't apply. Pleae note that "
	 "the user and group won't be retained by setting this flag. ");
  
  defvar("check_auth", 1, "Permissions: Require authentication for modification",
	 TYPE_FLAG,
	 "Only allow authenticated users to use methods other than "
	 "GET and POST. If unset, this filesystem will be a _very_ "
	 "public one (anyone can edit files located on it)");

  defvar("access_as_user", 0, "Permissions: Access file as the logged in user",
	 TYPE_FLAG|VAR_MORE,
	 "Accesses to a file will be made  as the logged in user.\n"
	 "This is useful for named ftp, or if you want higher security.<br>\n"
	 "NOTE: When running a threaded server requests that don't do any "
	 "modification will be done as the server uid/gid.");

  defvar("no_symlinks", 0, "Permissions: Forbid access to symlinks", TYPE_FLAG|VAR_MORE,
	 "EXPERIMENTAL.\n"
	 "Forbid access to paths containing symbolic links.<br>\n"
	 "NOTE : This can cause *alot* of lstat system-calls to be performed "
	 "and can make the server much slower.");
}


string status()
{
  return ("<h2>Accesses to this filesystem</h2>"+
	  (redirects?"<b>Redirects</b>: "+redirects+"<br>":"")+
	  (accesses?"<b>Normal files</b>: "+accesses+"<br>"
	   :"No file accesses<br>")+
	  (QUERY(put)&&puts?"<b>Puts</b>: "+puts+"<br>":"")+
	  (QUERY(put)&&QUERY(appe)&&appes?"<b>Appends</b>: "+appes+"<br>":"")+
	  (QUERY(method_mkdir)&&mkdirs?"<b>Mkdirs</b>: "+mkdirs+"<br>":"")+
	  (QUERY(method_mv)&&moves?
	   "<b>Moved files</b>: "+moves+"<br>":"")+
	  (QUERY(method_chmod)&&chmods?"<b>CHMODs</b>: "+chmods+"<br>":"")+
	  (QUERY(delete)&&deletes?"<b>Deletes</b>: "+deletes+"<br>":"")+
	  (errors?"<b>Permission denied</b>: "+errors
	   +" (not counting .htaccess)<br>":"")+
	  (dirlists?"<b>Directories</b>:"+dirlists+"<br>":""));
}


string query_name()
{
  return sprintf("<i>%s</i> mounted on <i>%s</i>", query("searchpath"),
		 query("mountpoint"));
}


/*****************************************************************************
 * Caudium MODULE_LOCATION API
 *****************************************************************************/

array find_dir( string f, object id )
{
  mixed ret;
  array dir;
  object privs;

#ifdef FILESYSTEM_DEBUG
  roxen_perror("FILESYSTEM: Request for dir \""+f+"\"\n");
#endif /* FILESYSTEM_DEBUG */

#ifndef THREADS
  if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
      (QUERY(access_as_user))) {
    // NB: Root-access is prevented.
    privs=Privs("Getting dir", (int)id->get_user()->uid, (int)id->get_user()->gid );
  }
#endif

  if(!(dir = get_dir( file_path(f, id) ))) {
    privs = 0;
    return 0;
  }
  privs = 0;

  if (QUERY(no_symlinks) && contains_symlinks(base_root(f, id), f))
  {
     errors++;
     return 0;
  }

  if(!QUERY(dir))
    // Access to this dir is allowed.
    if(search(dir, ".www_browsable") == -1)
    {
      errors++;
      return 0;
    }

  // Access to this dir is not allowed.
  if(sizeof(dir & ({".nodiraccess",".www_not_browsable",".nodir_access"})))
  {
    errors++;
    return 0;
  }

  dirlists++;

  // Pass _all_ files, hide none.
  if(QUERY(tilde) && QUERY(.files)) /* This is quite a lot faster */
    return dir;

  return Array.filter(dir, dir_filter_function);
}


mixed find_file( string f, object id )
{
  TRACE_ENTER("find_file(\""+f+"\")", 0);

  object o;
  int size, code;
  string tmp;
  string oldf = f;
  object privs;
  Stdio.Stat st;

#ifdef FILESYSTEM_DEBUG
  roxen_perror("FILESYSTEM: Request for file \""+f+"\"\n");
#endif /* FILESYSTEM_DEBUG */

  f = file_path(f, id);

  size = FILE_SIZE( f );

  /*
   * FIXME: Should probably move path-info extraction here.
   * 	/grubba 1998-08-26
   */

  switch(id->method)
  {
   case "GET":
   case "HEAD":
   case "POST":
  
    switch(-size)
    {
     case 1:
     case 3:
     case 4:
      TRACE_LEAVE("No file");
      return 0; /* Is no-file */

     case 2:
      TRACE_LEAVE("Is directory");
      return -1; /* Is dir */

     default:
      if(f[ -1 ] == '/') /* Trying to access file with '/' appended */
      {
	/* Neotron was here. I changed this to always return 0 since
	 * CGI-scripts with path info = / won't work otherwise. If
	 * someone accesses a file with "/" appended, a 404 no such
	 * file isn't that weird. Both Apache and Netscape return the
	 * accessed page, resulting in incorrect links from that page.
	 *
	 * FIXME: The proper way to do this would probably be to set path info
	 *   here, and have the redirect be done by the extension modules,
	 *   or by the protocol module if there isn't any extension module.
	 *	/grubba 1998-08-26
	 */
	return 0; 
      }

      if(!id->misc->internal_get && !QUERY(.files)
	 && (tmp = (id->not_query/"/")[-1])
	 && tmp[0] == '.') {
	TRACE_LEAVE("Is .-file");
	return 0;
      }
#ifndef THREADS
      if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
	  (QUERY(access_as_user))) {
	// NB: Root-access is prevented.
	privs=Privs("Getting file", (int)id->get_user()->uid, (int)id->get_user()->gid 
);
      }
#endif

      TRACE_ENTER("Opening file \"" + f + "\"", 0);
      o = open( f, "r" );

#ifndef THREADS
      privs = 0;
#endif

      if(!o || (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))))
      {
         errors++;
         report_error("Open of " + f + " failed. Permission denied.\n");

         TRACE_LEAVE("");
         TRACE_LEAVE("Permission denied.");
         return Caudium.HTTP.error_answer (id, 403, 0, 
                  "File exists, but access forbidden by user");
      }

      id->realfile = f;
      TRACE_LEAVE("");
      accesses++;
#ifdef COMPAT
      if(QUERY(html)) {/* Not very likely, really.. */
	TRACE_LEAVE("Compat return");
	return ([ "type":"text/html", "file":o, ]);
      }
#endif
      TRACE_LEAVE("Normal return");
      return o;
    }
    break;
  
   case "MKDIR":
    if(!QUERY(method_mkdir))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MKDIR disallowed (method disabled)");
      return 0;
    }    

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("MKDIR: Permission denied");
      return Caudium.HTTP.auth_required("foo",
				"<h1>Permission to 'MKDIR' denied</h1>");
    }
    mkdirs++;

    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
	(QUERY(access_as_user))) {
      // NB: Root-access is prevented.
      privs=Privs("Creating directory",
		  (int)id->get_user()->uid, (int)id->get_user()->gid );
    }

    if (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))) {
      privs = 0;
      errors++;
      report_error("Creation of " + f + " failed. Permission denied.\n");
      TRACE_LEAVE("MKDIR: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer(id, 403, 0, "Permission denied.");
    }

    TRACE_ENTER("MKDIR: Accepted", 0);

    int code = mkdir( f );

    privs = 0;
    if (code) {
      chmod(f, dirperm & ~(id->misc->umask || default_umask));
      TRACE_LEAVE("MKDIR: Success");
      TRACE_LEAVE("Success");
      return Caudium.HTTP.string_answer("Ok");
    } else {
      TRACE_LEAVE("MKDIR: Failed");
      TRACE_LEAVE("Failure");
      return 0;
    }

    break;

   case "PUT":
    if(!QUERY(put))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("PUT disallowed");
      return 0;
    }    

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("PUT: Permission denied");
      return Caudium.HTTP.auth_required("foo",
				"<h1>Permission to 'PUT' files denied</h1>");
    }
    puts++;
    

    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
	(QUERY(access_as_user))) {
      // NB: Root-access is prevented.
      privs=Privs("Saving file", (int)id->get_user()->uid, (int)id->get_user()->gid );
    }

    if (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))) {
      privs = 0;
      errors++;
      report_error("Creation of " + f + " failed. Permission denied.\n");
      TRACE_LEAVE("PUT: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    TRACE_ENTER("PUT: Accepted", 0);
    if(QUERY(keep_old_perms))
      st = file_stat(f);
    rm( f );
    Stdio.mkdirhier( dirname(f) );
    
    object to = open(f, "wct");
    
    privs = 0;

    if(!to)
    {
      id->misc->error_code = 403;
      TRACE_LEAVE("PUT: Open failed");
      TRACE_LEAVE("Failure");
      return 0;
    }
    /* Set permission or use the previous permissions */
    if(st) chmod(f, st[0]);
    else   chmod(f, fileperm & ~(id->misc->umask || default_umask));
    putting[id->my_fd]=id->misc->len;
    if(id->data && strlen(id->data))
    {
      putting[id->my_fd] -= strlen(id->data);
      to->write( id->data );
    }
    if(!putting[id->my_fd]) {
      TRACE_LEAVE("PUT: Just a string");
      TRACE_LEAVE("Put: Success");
      return Caudium.HTTP.string_answer("Ok");
    }

    if(id->clientprot == "HTTP/1.1") {
      id->my_fd->write("HTTP/1.1 100 Continue\r\n\r\n");
    }
    id->my_fd->set_id( ({ to, id->my_fd }) );
    id->my_fd->set_nonblocking(got_put_data, 0, done_with_put);
    TRACE_LEAVE("PUT: Pipe in progress");
    TRACE_LEAVE("PUT: Success so far");
    return Caudium.HTTP.pipe_in_progress();
    break;

  case "APPE":
    if(!QUERY(put)&&!QUERY(appe))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("APPE disallowed");
      return 0;
    }    

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("APPE: Permission denied");
      return Caudium.HTTP.auth_required("foo",
				"<h1>Permission to 'APPE' files denied</h1>");
    }
    appes++;
    
    object privs;

// #ifndef THREADS // Ouch. This is is _needed_. Well well...
    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
      (QUERY(access_as_user))) {
      // NB: Root-access is prevented.
      privs=Privs("Saving file", (int)id->get_user()->uid, (int)id->get_user()->gid );
    }
// #endif

    if (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))) {
      privs = 0;
      errors++;
      report_error("Creation of " + f + " failed. Permission denied.\n");
      TRACE_LEAVE("PUT: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    TRACE_ENTER("APPE: Accepted", 0);

    Stdio.mkdirhier( f );

    to = open(f, "arw");
    
    privs = 0;

    if(!to)
    {
      id->misc->error_code = 403;
      TRACE_LEAVE(sprintf("APPE: Open (%s, wa) failed",f));
      TRACE_LEAVE("Failure");
      return 0;
    }
    chmod(f, 0666 & ~(id->misc->umask || 022));
    putting[id->my_fd]=id->misc->len;
    if(id->data && strlen(id->data))
    {
      putting[id->my_fd] -= strlen(id->data);
      to->write( id->data );
    }
    if(!putting[id->my_fd]) {
      TRACE_LEAVE("PUT: Just a string");
      TRACE_LEAVE("Put: Success");
      return Caudium.HTTP.string_answer("Ok");
    }

    if(id->clientprot == "HTTP/1.1") {
      id->my_fd->write("HTTP/1.1 100 Continue\r\n");
    }
    id->my_fd->set_id( ({ to, id }) );
    id->my_fd->set_nonblocking(got_put_data, 0, done_with_put);
    TRACE_LEAVE("APPE: Pipe in progress");
    TRACE_LEAVE("APPE: Success so far");
    return Caudium.HTTP.pipe_in_progress();
    break;

   case "CHMOD":
    // Change permission of a file. 
    
    if(!QUERY(method_chmod))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("CHMOD disallowed");
      return 0;
    }    

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("CHMOD: Permission denied");
      return Caudium.HTTP.auth_required("foo",
				"<h1>Permission to 'CHMOD' files denied</h1>");
    }
    
    // #ifndef THREADS // Ouch. This is is _needed_. Well well...
    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid)) {
      // NB: Root-access is prevented.
      privs=Privs("CHMODing file", (int)id->get_user()->uid, (int)id->get_user()->gid);
    }
    // #endif
    
    if (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))) {
      privs = 0;
      errors++;
      TRACE_LEAVE("CHMOD: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    chmods++;

    TRACE_ENTER("CHMOD: Accepted", 0);

#ifdef DEBUG
    report_notice(sprintf("CHMODing file "+f+" to 0%o\n", id->misc->mode));
#endif
    array err = catch(chmod(f, id->misc->mode & 0777));
    privs = 0;
    
    if(err)
    {
      id->misc->error_code = 403;
      TRACE_LEAVE("CHMOD: Failure");
      TRACE_LEAVE("Failure");
      return 0;
    }
    TRACE_LEAVE("CHMOD: Success");
    TRACE_LEAVE("Success");
    return Caudium.HTTP.string_answer("Ok");
    
   case "MV":
    // This little kluge is used by ftp2 to move files. 
    
    if(!QUERY(method_mv))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MV disallowed");
      return 0;
    }    
    if(!QUERY(delete) && size != -1)
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MV disallowed (DELE disabled, can't overwrite file)");
      return 0;
    }

    if(size < -1)
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MV: Cannot overwrite directory");
      return 0;
    }

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("MV: Permission denied");
      return Caudium.HTTP.auth_required("foo",
				"<h1>Permission to 'MV' files denied</h1>");
    }
    string movefrom;
    if(!id->misc->move_from ||
       !(movefrom = id->conf->real_file(id->misc->move_from, id))) {
      id->misc->error_code = 405;
      errors++;
      TRACE_LEAVE("MV: No source file");
      return 0;
    }
    moves++;
    
    // #ifndef THREADS // Ouch. This is is _needed_. Well well...
    if ((id->get_user() && (int)id->get_user()->uid) && ((int)id->get_user()->gid)) {
      // NB: Root-access is prevented.
      privs=Privs("Moving file", (int)id->get_user()->uid, (int)id->get_user()->gid );
    }
    // #endif
    
    if (QUERY(no_symlinks) &&
	((contains_symlinks(base_root(oldf, id), oldf)) ||
	 (contains_symlinks(base_root(id->misc->move_from, id), id->misc->move_from)))) {
      privs = 0;
      errors++;
      TRACE_LEAVE("MV: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    TRACE_ENTER("MV: Accepted", 0);

    /* Clear the stat-cache for this file */

#ifdef DEBUG
    report_notice("Moving file "+movefrom+" to "+ f+"\n");
#endif /* DEBUG */

    code = mv(movefrom, f);
    privs = 0;

    if(!code)
    {
      id->misc->error_code = 403;
      TRACE_LEAVE("MV: Move failed");
      TRACE_LEAVE("Failure");
      return 0;
    }
    TRACE_LEAVE("MV: Success");
    TRACE_LEAVE("Success");
    return Caudium.HTTP.string_answer("Ok");

   case "MOVE":
    // This little kluge is used by NETSCAPE 4.5
     
    if(!QUERY(method_mv))
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MOVE disallowed");
      return 0;
    }    
    if(size == -1)
    {
      id->misc->error_code = 404;
      TRACE_LEAVE("MOVE failed (no such file)");
      return 0;
    }

    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("MOVE: Permission denied");
      return Caudium.HTTP.auth_required("foo",
                                "<h1>Permission to 'MOVE' files denied</h1>");
    }

    if(!sizeof(id->misc["new-uri"] || "")) { 
      id->misc->error_code = 405;
      errors++;
      TRACE_LEAVE("MOVE: No dest file");
      return 0;
    }
    string mountpoint = QUERY(mountpoint);
    string moveto = combine_path(mountpoint + "/" + oldf + "/..",
				 id->misc["new-uri"]);

    if (moveto[..sizeof(mountpoint)-1] != mountpoint) {
      id->misc->error_code = 405;
      TRACE_LEAVE("MOVE: Dest file on other filesystem.");
      return(0);
    }
    moveto = base_root(moveto[sizeof(mountpoint)..], id) + moveto[sizeof(mountpoint)..];

    size = FILE_SIZE(moveto);

    if(!QUERY(delete) && size != -1)
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MOVE disallowed (DELE disabled, can't overwrite file)");
      return 0;
    }
 
    if(size < -1)
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("MOVE: Cannot overwrite directory");
      return 0;
    }

    // #ifndef THREADS // Ouch. This is is _needed_. Well well...
    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid)) {
      // NB: Root-access is prevented.
      privs=Privs("Moving file", (int)id->get_user()->uid, (int)id->get_user()->gid );
    }
    // #endif

    if (QUERY(no_symlinks) &&
        ((contains_symlinks(base_root(f, id), f)) ||
         (contains_symlinks(base_root(moveto, id), moveto)))) {
      privs = 0;
      errors++;
      TRACE_LEAVE("MOVE: Contains symlinks. Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    TRACE_ENTER("MOVE: Accepted", 0);

    moves++;

    /* Clear the stat-cache for this file */
#ifdef DEBUG
    report_notice("Moving file " + f + " to " + moveto + "\n");
#endif /* DEBUG */

    code = mv(f, moveto);

    if(!code)
    {
      id->misc->error_code = 403;
      TRACE_LEAVE("MOVE: Move failed");
      TRACE_LEAVE("Failure");
      return 0;
    }
    TRACE_LEAVE("MOVE: Success");
    TRACE_LEAVE("Success");
    return Caudium.HTTP.string_answer("Ok");

   case "COPY":
    if(!QUERY(copy) )
	return Caudium.HTTP.error_answer(id, 405, "Copy disallowed");
    id->misc->destination = base_root(id->misc->destination, id) + id->misc->destination;
    size = FILE_SIZE(id->misc->destination);
    if ( size != -1 && id->misc->overwrite != "T" )
	return Caudium.HTTP.error_answer(id, 403, "Forbidden");
    if(QUERY(check_auth) && (!id->get_user()))
	return Caudium.HTTP.auth_required("copy", "Permission to 'COPY' files denied");
    if(QUERY(no_symlinks) && 
       (contains_symlinks(base_root(f, id), f) || 
	contains_symlinks(base_root(id->misc->destination, id),id->misc->destination)))
	return Caudium.HTTP.error_answer(id, 403, "Forbidden");
    if ( !stringp(id->misc->destination) ) 
	return Caudium.HTTP.error_answer(id, 403, "No destination");
	
    accesses++;
    report_notice("COPYING the file "+f+" to " + id->misc->destination + "\n");
    if ( id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) ) 
	privs = Privs("Copying file", (int)id->get_user()->uid,(int) id->get_user()->gid);
    if ( f == id->misc->destination || !Stdio.cp(f, id->misc->destination) ) {
	privs = 0;
	return Caudium.HTTP.error_answer(id, 403, "Forbidden");
    }
    privs = 0;
    TRACE_LEAVE("COPY: Success");
    return Caudium.HTTP.error_answer(id, 201, "Created"); // hmm, error answer ?
    break;
	
   case "DELETE":
    if(!QUERY(delete) || size==-1)
    {
      id->misc->error_code = 405;
      TRACE_LEAVE("DELETE: Disabled");
      return 0;
    }
    if(QUERY(check_auth) && (!id->get_user())) {
      TRACE_LEAVE("DELETE: Permission denied");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission to DELETE file denied");
    }

    if (QUERY(no_symlinks) && (contains_symlinks(base_root(oldf, id), oldf))) {
      errors++;
      report_error("Deletion of " + f + " failed. Permission denied.\n");
      TRACE_LEAVE("DELETE: Contains symlinks");
      return Caudium.HTTP.error_answer (id, 403, 0, "Permission denied.");
    }

    report_notice("DELETING the file "+f+"\n");
    accesses++;

    if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
	(QUERY(access_as_user))) {
      // NB: Root-access is prevented.
      privs=Privs("Deleting file", id->get_user()->uid, id->get_user()->gid );
    }

    /* Clear the stat-cache for this file */

    if(!rm(f))
    {
      privs = 0;
      id->misc->error_code = 405;
      TRACE_LEAVE("DELETE: Failed");
      return 0;
    }
    privs = 0;
    deletes++;
    TRACE_LEAVE("DELETE: Success");
    return Caudium.HTTP.low_answer(200,(f+" DELETED from the server"));

   default:
    TRACE_LEAVE("Not supported");
    return 0;
  }
  report_error("Not reached..\n");
  TRACE_LEAVE("Not reached");
  return 0;
}


string query_location()
{
  return QUERY(mountpoint);
}


string real_file( mixed f, mixed id )
{
  if(this->stat_file( f, id )) 
/* This filesystem might be inherited by other filesystem, therefore
   'this'  */
    return file_path(f, id); 
}


mixed stat_file( mixed f, mixed id )
{
  array fs;
#ifndef THREADS
  object privs;
  if (id->get_user() && ((int)id->get_user()->uid) && ((int)id->get_user()->gid) &&
      (QUERY(access_as_user))) {
    // NB: Root-access is prevented.
    privs=Privs("Statting file", (int)id->get_user()->uid, (int)id->get_user()->gid );
  }
#endif

  fs = file_stat(file_path(f, id));  /* No security currently in this function */
#ifndef THREADS
  privs = 0;
#endif

  return fs;
}




/*****************************************************************************
 * Module-specific code
 *****************************************************************************/

int dir_filter_function(string f)
{
  if(f[0]=='.' && !QUERY(.files))           return 0;
  if(!QUERY(tilde) && Caudium.backup_extension(f))  return 0;
  return 1;
}


void done_with_put( array(object) id )
{
//  perror("Done with put.\n");
  id[0]->close();
  id[1]->send_result(Caudium.HTTP.low_answer(201,""));
  m_delete(putting, id[1]->my_fd);
  destruct(id[0]);
  destruct(id[1]->my_fd);
}


void got_put_data( array (object) id, string data )
{
// perror(strlen(data)+" .. ");
  id[0]->write( data );
  putting[id[1]] -= strlen(data);
  if(putting[id[1]->my_fd] <= 0)
    done_with_put( id );
}


int contains_symlinks(string root, string path)
{
  array arr = path/"/";
  Stdio.Stat stat;

  foreach(arr - ({ "" }), path) {
    root += "/" + path;
    if (stat = file_stat(root, 1)) {
      if (stat[1] == -3) {
	return(1);
      }
    } else {
      return(0);
    }
  }
  return(0);
}


//! Returns the base root for the current request.
//!
//! Any module inheriting this one can override this method to do fancy things
//! like live changing the base root given information found in the request id
//! object.
//!
//! @param id
//! The request id object
//!
//! @returns
//! The base root for the current request as a string
string base_root(string f, object id)
{
  return QUERY(searchpath);
}


//! Returns the filesystem file path for the current request.
//!
//! Any module inheriting this one can override this method to do fancy things
//! like live changing the file path given information found in the request id
//! object.
//!
//! @param f
//! The path to the object, in the modules name space.
//!
//! @param id
//! The request id object
//!
//! @returns
//! The absolute file path in the real filesystem.
string file_path(string f, object id)
{
  return combine_path(base_root(f, id), f);
}


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

