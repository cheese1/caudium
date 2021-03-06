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

//! Storage Client (eg disk/mem/sql cache)

/*
 * The Storage module and the accompanying code is Copyright � 2002 James Tyson.
 * This code is released under the GPL license and is part of the Caudium
 * WebServer.
 *
 * Authors:
 *   James Tyson	<jnt@caudium.net>
 *
 */


protected function _store;
protected function _retrieve;
protected function _unlink;
protected function _unlink_regexp;
protected function _size;
protected function _list;
protected function _stop;
protected string namespace;

//!
void create(string _namespace, mapping callbacks) {
  _store = callbacks->store;
  _retrieve = callbacks->retrieve;
  _unlink = callbacks->unlink;
  _unlink_regexp = callbacks->unlink_regexp;
  _size = callbacks->size;
  _list = callbacks->list;
  _stop = callbacks->stop;
  namespace = _namespace;
}

//!
public void store(string key, mixed val) {
  _store(namespace, key, val);
}

//!
public mixed retrieve(string key) {
  return _retrieve(namespace, key);
}

//!
public void unlink(void|string key) {
   _unlink(namespace, key);
}

//!
public void unlink_regexp(void|string regexp) {
  _unlink_regexp(namespace, regexp);
}

//!
public int size() {
 return _size(namespace);
}

//!
public array list() {
  return _list(namespace);
}

//!
public void stop() {
  _stop(namespace);
}
