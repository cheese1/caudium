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
/*
 * $Id$
 */

//! Storage Module : SQL Method

/*
 * The Storage module and the accompanying code is Copyright � 2002 James Tyson.
 * This code is released under the GPL license and is part of the Caudium
 * WebServer.
 *
 * Authors:
 *   James Tyson	<jnt@caudium.net>
 *
 */

//!
constant storage_type    = "SQL";

//!
constant storage_doc     = "Please enter the SQL URL for the database you would like "
                            "to store data in.";

//!
constant storage_default = "mysql://localhost/caudium";

#define DB get_database

//!
protected string sqlurl;

//!
protected string version = sprintf("%d.%d.%d", __MAJOR__, __MINOR__, __BUILD__); 

//!
protected object db;

//!
void create(string _sqlurl) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->create(%O)\n", _sqlurl);
#endif
  sqlurl = _sqlurl;
  if (catch(Sql.Sql(sqlurl)))
    throw(Error.Generic("Unable to connect to database\n"));
  init_tables();
}

//!
void store(string namespace, string key, string value) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->store(%O)\n", key);
#endif
  object db = DB();
  db->query("replace into storage values (%s, %s, %s, %s)", version, namespace, key, value);
}

//!
mixed retrieve(string namespace, string key) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->retrieve(%O, %O)\n", namespace, key);
#endif
  object db = DB();
  array result = db->query("select value from storage where namespace = %s and dkey = %s", namespace, key);
  if (sizeof(result))
    return result[0]->value;
  else
    return 0;
}

//!
void unlink(string namespace, void|string key) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->unlink(%O, %O)\n", namespace, key);
#endif
  object db = DB();
  if (stringp(key))
    db->query("delete from storage where namespace = %s and dkey = %s", namespace, key);
  else
    db->query("delete from storage where namespace = %s", namespace);
}

//!
void unlink_regexp(string namespace, string regexp) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->unlink_regexp(%O, %O)\n", namespace, regexp);
#endif
  object db = DB();
  db->query("delete from storage where namespace = %s and dkey regexp %s", namespace, regexp);
}

//!
protected object get_database() {
  if (!objectp(db))
    db = Sql.Sql(sqlurl);
  return db;
}

//!
protected object init_tables() {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->init_tables()\n");
#endif
  object db = DB();
  multiset tables = (multiset)db->list_tables();
  if (!tables->storage)
    switch((db->server_info() / "/")[0]) {
    case "SQLite":
    case "Postgres":
      db->query(
        "create table storage(\n"
        "  pike_version character varying(255),\n"
	"  namespace character varying(250),\n"
	"  dkey character varying(250),\n"
	"  value bytea,\n"
	"  UNIQUE (namespace, dkey )\n"
	")"
      );
      break;
    default:
      /* MySQL is assumed to be the default, for better or worse */
      db->query(
	"create table storage(\n"
	"  pike_version varchar(255),\n"
	"  namespace varchar(250),\n"
	"  dkey varchar(250),\n"
	"  value longblob,\n"
	"  UNIQUE (namespace, dkey)\n"
	")"
      );
      break;
    }
}

//!
int size(string namespace) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->size(%O)\n", namespace);
#endif
  object db = DB();
  int total;
  array result = db->query("select length(value) as size from storage where namespace = %s", namespace);
  if (!sizeof(result))
    return 0;
  else
    foreach(result, mapping row) {
      total += (int)row->size;
    }
  return total;
}

//!
array list(string namespace) {
#ifdef STORAGE_DEBUG
  werror("Storage.Methods.SQL->list(%O)\n", namespace);
#endif

  object db = DB();
  return db->query("select dkey from storage where namespace = %s", namespace)->dkey;
}

void stop()
{
  // we don't have to do anything!
}
