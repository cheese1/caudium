/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000 The Caudium Group
 * Copyright � 1994-2000 Roxen Internet Software
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

inherit "module";
inherit "caudiumlib";

// import Array;

constant cvs_version = "$Id$";

void create()
{
  defvar("location", "/demo/", "Mount point", TYPE_LOCATION, 
	 "This is where the module will be inserted in the "+
	 "namespace of your server.");
}


mixed *register_module()
{
  return ({ 
    MODULE_LOCATION, 
    "Demo module", 
    "This module makes it possible to develop, RXML code interactively." });
}

#define FOO "<title>Demo</title>\n" \
"<body bgcolor=white>\n" \
"<form action=%d>\n" \
"<input type=submit name=_submit value=Clear>\n" \
"</form>\n" \
"<p><br><p><br><p>\n" \
"%s" \
"<p><br><p><br><p>\n" \
"<form>\n" \
"<textarea name=_data cols=60 rows=14>%s</textarea>\n" \
"<br><input type=submit name=_submit value=Clear> " \
"<input type=submit value=Show>\n" \
"</form>\n" \
"<table><tr><td>"\
"<form action=%d>" \
"<input type=submit value=' <-- previous '>" \
"</form>" \
"</td><td>"\
"<form>Position: <input size=4 type=string name=pos value='"+(int)f+"'>"\
"<input type=submit name=go value='Go!'></form>"\
"</td><td>"\
"</td><td>"\
"<form action=%d>" \
"<input type=submit value=' next --> '>" \
"</form>" \
"</td></tr></table>" \
"</body>"

object mdb;

mixed find_file( string f, object id )
{
  if(id->variables->go)
    return http_redirect(query("location")+id->variables->pos,id);
  if (!mdb) {
    mdb = Yabu.db(".demo-bookmarks", "wcCr")["demo"];
    if(!mdb[42])
      mdb[42]=
#"<for variable=i from=99 to=1 step=-1>
  <if not variable=\"i is 1\">
    <set variable=s value=\"s\">
  </if>
  <else>
    <set variable=s value=\"\">
  </else>
  <formoutput>
    #i# bottle#s# of beer on the wall,<br><br>
    #i# bottle#s# of beer on the wall,<br>
    #i# bottle#s# of beer,<br>
    Take one down, pass it around,<br><br>
  </formoutput>
</for>
No more bottles of beer on the wall";
  }
  string data = mdb[ (int)f ];

  if (id->variables->_submit == "Clear")
    mdb[ id->not_query ] = data = "";
  else if (id->variables->_data)
  {
    data = id->variables->_data;

    data = data / "\r\n" * "\n";
    data = data / "\r" * "\n";
    mdb[ (int)f ] = data;
  }
  if (!stringp( data ))
    data = "";
  return http_string_answer( parse_rxml( sprintf( FOO, (int)f,
						  data,
						  replace(data, ({ "<", ">", "&" }),
							  ({"&lt;","&gt;","&amp;"})),
						  ((int)f)-1,
						  ((int)f)+1), id));
}
