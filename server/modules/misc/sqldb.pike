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

/*
 * Associates a name with an SQL-database.
 */

#include <module.h>

inherit "module";

constant module_type = 0;
constant module_name = "SQL Databases";
constant module_doc  = "Associates names with SQL Database URLs.";
constant module_unique = 1;

array register_module()
{
  return (({ 0, "SQL Databases",
	     "Associates names with SQL Database URLs.", ({}), 1 }));
}

void create()
{
  defvar("table", "", "Table", TYPE_TEXT_FIELD,
	 "Associates names with SQL Database URLs.<br>\n"
	 "Format:<br>\n"
	 "<pre>Name1\tSQLURL1\n"
	 "Name2\tSQLURL2</pre><br>\n"
	 "An \"SQL-URL\" is specified on the following format:<br><ul>\n"
	 "<pre>[<i>sqlserver</i>://][[<i>user</i>][:<i>password</i>]@]"
	 "[<i>host</i>[:<i>port</i>]]/<i>database</i></pre><br>\n"
	 "</ul>Valid values for \"sqlserver\" depend on which "
	 "sql-servers your pike has support for, but the following "
	 "might exist: <tt>msql</tt>, <tt>mysql</tt>, <tt>odbc</tt>, "
	 "<tt>oracle</tt>, <tt>postgres</tt>.<br>\n");
}

mapping(string:string) parse_table(string tab)
{
  mapping(string:string) res = ([]);

  tab = replace(tab||"", "\r", "\n");

  foreach(tab/"\n", string line) {
    string line2 = replace(line, "\t", " ");
    array(string) arr = (line2/" ") - ({ "" });
    if ((sizeof(arr) >= 2) && (arr[0][0] != '#')) {
      string name = arr[0];
      string infix = arr[1];
      string suffix = ((line/name)[1..])*name;
      suffix = infix + ((suffix/infix)[1..])*infix;
      res[name] = suffix;
    }
  }
  return(res);
}

void start(int level, object conf)
{
  conf->sql_urls = parse_table(QUERY(table));
}

string status()
{
  mapping sql_urls = parse_table(QUERY(table));

  string res = "";

  if (sizeof(sql_urls)) {
    res += "<table border=0>\n";
    foreach(sort(indices(sql_urls)), string s) {
      object o;

      catch {
	o = Sql.sql(sql_urls[s]);
      };

      if (o) {
	res += sprintf("<tr><td>Connection OK</td>"
		       "<td><tt>%s</tt></td><td><tt>%s</tt></td></tr>\n",
		       s, sql_urls[s]);
      } else {
	res += sprintf("<tr><td><font color=red>Connection Failed</font></td>"
		       "<td><tt>%s</tt></td><td><tt>%s</tt></td></tr>\n",
		       s, sql_urls[s]);
      }
    }
    res += "</table>\n";
  } else {
    res += "No associations defined.<br>\n";
  }
  return(res);
}



