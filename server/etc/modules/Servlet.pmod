/*
 * Caudium - An extensible World Wide Web server
 * Copyright © 2003 The Caudium Group
 * Copyright © 1999-2001 Roxen Internet Software
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

//! Java Servlet interface for Caudium
//! @fixme
//!   Not documented.

#if constant(Java.machine)

protected constant jvm = Java.machine;

#define FINDCLASS(X) (jvm.find_class(X)||(jvm.exception_describe(),jvm.exception_clear(),error("Failed to load class " X ".\n"),0))

protected object servlet_ifc = FINDCLASS("javax/servlet/Servlet");
protected object singlethread_ifc = FINDCLASS("javax/servlet/SingleThreadModel");
protected object class_class = FINDCLASS("java/lang/Class");
protected object classloader_class = FINDCLASS("java/lang/ClassLoader");
protected object classloader2_class = FINDCLASS("java/net/URLClassLoader");
protected object config_class = FINDCLASS("net/caudium/servlet/ServletConfig");
protected object context_class = FINDCLASS("net/caudium/servlet/CaudiumServletContext");
protected object request_class = FINDCLASS("net/caudium/servlet/ServletRequest");
protected object response_class = FINDCLASS("net/caudium/servlet/ServletResponse");
protected object stream_class = FINDCLASS("net/caudium/servlet/HTTPOutputStream");
protected object session_context_class = FINDCLASS("net/caudium/servlet/CaudiumSessionContext");
protected object dictionary_class = FINDCLASS("java/util/Dictionary");
protected object hashtable_class = FINDCLASS("java/util/Hashtable");
protected object throwable_class = FINDCLASS("java/lang/Throwable");
protected object unavailable_class = FINDCLASS("javax/servlet/UnavailableException");
protected object servlet_exc_class = FINDCLASS("javax/servlet/ServletException");
protected object stringwriter_class = FINDCLASS("java/io/StringWriter");
protected object printwriter_class = FINDCLASS("java/io/PrintWriter");
protected object vector_class = FINDCLASS("java/util/Vector");
protected object file_class = FINDCLASS("java/io/File");
protected object url_class = FINDCLASS("java/net/URL");
protected object string_class = FINDCLASS("java/lang/String");
protected object jarutil_class = FINDCLASS("net/caudium/caudium/JarUtil");

protected object new_instance = class_class->get_method("newInstance", "()Ljava/lang/Object;");
protected object file_init = file_class->get_method("<init>", "(Ljava/lang/String;)V");
protected object file_tourl = file_class->get_method("toURL", "()Ljava/net/URL;");
protected object load_class = classloader_class->get_method("loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
protected object cl_init = classloader2_class->get_method("<init>", "([Ljava/net/URL;)V");
protected object servlet_init = servlet_ifc->get_method("init", "(Ljavax/servlet/ServletConfig;)V");
protected object servlet_destroy = servlet_ifc->get_method("destroy", "()V");
protected object servlet_getservletinfo = servlet_ifc->get_method("getServletInfo", "()Ljava/lang/String;");
protected object servlet_service = servlet_ifc->get_method("service", "(Ljavax/servlet/ServletRequest;Ljavax/servlet/ServletResponse;)V");
protected object cfg_init = config_class->get_method("<init>", "(Ljavax/servlet/ServletContext;Ljava/lang/String;)V");
protected object context_init = context_class->get_method("<init>", "(ILjava/lang/String;)V");
protected object context_id_field = context_class->get_field("id", "I");
protected object context_initpars_field = context_class->get_field("initparameters", "Ljava/util/Hashtable;");
protected object context_set_attribute = context_class->get_method("setAttribute", "(Ljava/lang/String;Ljava/lang/Object;)V");
protected object request_init = request_class->get_method("<init>", "(Lnet/caudium/servlet/CaudiumServletContext;Lnet/caudium/servlet/CaudiumSessionContext;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
protected object response_init = response_class->get_method("<init>", "(Lnet/caudium/servlet/HTTPOutputStream;)V");
protected object dic_field = config_class->get_field("dic", "Ljava/util/Dictionary;");
protected object params_field = request_class->get_field("parameters", "Ljava/util/Dictionary;");
protected object attrs_field = request_class->get_field("attributes", "Ljava/util/Dictionary;");
protected object headers_field = request_class->get_field("headers", "Ljava/util/Dictionary;");
protected object set_response_method = request_class->get_method("setResponse", "(Lnet/caudium/servlet/ServletResponse;)V");
protected object dic_put = dictionary_class->get_method("put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
protected object hash_clear = hashtable_class->get_method("clear", "()V");
protected object stream_id_field = stream_class->get_field("id", "I");
protected object stream_init = stream_class->get_method("<init>", "(I)V");
protected object throwable_printstacktrace = throwable_class->get_method("printStackTrace", "(Ljava/io/PrintWriter;)V");
protected object throwable_getmessage = throwable_class->get_method("getMessage", "()Ljava/lang/String;");
protected object unavailable_ispermanent = unavailable_class->get_method("isPermanent", "()Z");
protected object unavailable_getunavailableseconds = unavailable_class->get_method("getUnavailableSeconds", "()I");
protected object servlet_exc_getrootcause = servlet_exc_class->get_method("getRootCause", "()Ljava/lang/Throwable;");
protected object stringwriter_init = stringwriter_class->get_method("<init>", "()V");
protected object printwriter_init = printwriter_class->get_method("<init>", "(Ljava/io/Writer;)V");
protected object printwriter_flush = printwriter_class->get_method("flush", "()V");
protected object wrapup_method = response_class->get_method("wrapUp", "()V");
protected object session_context_init = session_context_class->get_method("<init>", "()V");
protected object vector_init = vector_class->get_method("<init>", "()V");
protected object vector_add = vector_class->get_method("add", "(Ljava/lang/Object;)Z");
protected object jarutil_expand = jarutil_class->get_static_method("expand", "(Ljava/lang/String;Ljava/lang/String;)V");


protected object natives_bind1, natives_bind2, natives_bind3;

protected void check_exception()
{
  object e = jvm.exception_occurred();
  if(e) {
    jvm.exception_clear();
    object sw = stringwriter_class->alloc();
    stringwriter_init(sw);
    object pw = printwriter_class->alloc();
    printwriter_init(pw, sw);
    if (e->is_instance_of(servlet_exc_class))
      {
        object re = servlet_exc_getrootcause(e);
        if (re)
          throwable_printstacktrace(re, pw);
      }
    throwable_printstacktrace(e, pw);
    printwriter_flush(pw);
    array bt = backtrace();
    // FIXME: KLUDGE: Sometimes the cast fails for some reason.
    string s = "Unknown Java exception (StringWriter failed)";
    catch {
      s = (string)sw;
    };
    throw(({s, bt[..sizeof(bt)-2]}));
  }
}

protected void check_unavailable_exception()
{
  object e = jvm.exception_occurred();
  if(e) {
    if (e->is_instance_of(unavailable_class))
      {
        jvm.exception_clear();
        array bt = backtrace();
        throw(
              ({ "UnavailableException\n",
                 (string)throwable_getmessage(e),
                 (int)unavailable_ispermanent(e),
                 (int)unavailable_getunavailableseconds(e)
              })
              );
      }
    else
      check_exception();
  }
}


//!
class jarutil {

  //!
  void expand(string dir, string jar)
  {
    jarutil_expand(dir, jar);
    check_exception();
  }

}

//!
class servlet {

  protected object s, d;
  protected object context;
  protected string classname;
  int singlethreaded = 0;
#if constant(thread_create)
  protected object lock;
#endif

  //!
  void destroy()
  {
    if(s && d) {
      d(s);
      s = 0;
    }
  }

  //!
  void service(object req, object|void res)
  {
    if(!res) {
      res = response(req->my_fd);
      req = request(context, req);
    }
    set_response_method(req, res);
#if constant(thread_create)
    if(singlethreaded) {
      object key = lock->lock();
      servlet_service(s, req, res);
      key = 0;
    } else
#endif
      servlet_service(s, req, res);
    check_exception();
    wrapup_method(res);
    check_exception();
  }

  //!
  string info()
  {
    object i = servlet_getservletinfo(s);
    check_exception();
    return i && (string)i;
  }

  //!
  void init(object cfgctx, mapping(string:string)|void params, string|void nam)
  {
    context = cfgctx;
    if(params)
      cfgctx = config(cfgctx, params, nam||classname);
    servlet_init(s, cfgctx->cfg);
    check_unavailable_exception();
    d = servlet_destroy;
  }

  //!
  void create(string|object name, string|array(string)|object|void dir)
  {
    report_notice("Servlet.servlet()\n");
    if(stringp(name)) {
      classname = name;
      if(!objectp(dir))
	dir = loader(dir||".");
      name = dir->low_load(name);
    }

    if(!name) {
      destruct(this_object());
      return;
    }
    s = new_instance(name);
    check_exception();
    if(!s->is_instance_of(servlet_ifc))
      error("class does not implement javax.servlet.Servlet\n");
    if(s->is_instance_of(singlethread_ifc)) {
#if constant(thread_create)
      lock = Thread.Mutex();
#endif
      singlethreaded = 1;
    }
  }

};

//!
class loader {

  protected object cl;

  //!
  object low_load(string name)
  {
    object c = load_class(cl, name);
    check_exception();
    return c;
  }

  //!
  object load(string name)
  {
    return servlet(name, this_object());
  }

  //!
  void create(string|array(string) codedirs)
  {
    if(stringp(codedirs))
      codedirs = ({ codedirs });
    object urls = url_class->new_array(sizeof(codedirs));
    check_exception();
    int i=0;
    foreach(codedirs, string codedir) {
      object f = file_class->alloc();
      check_exception();
      file_init->call_nonvirtual(f, combine_path(getcwd(), codedir));
      check_exception();
      object url = file_tourl(f);
      check_exception();
      urls[i++] = url;
      check_exception();
    }
    cl = classloader2_class->alloc();
    check_exception();
    cl_init->call_nonvirtual(cl, urls);
    check_exception();
  }

};

//!
class config {

  object cfg;

  //!
  void create(object context, mapping(string:string)|void params,
	      string|void name)
  {
    cfg = config_class->alloc();
    check_exception();
    cfg_init(cfg, context->ctx, name);
    check_exception();
    if(params) {
      object dic = dic_field->get(cfg);
      foreach(indices(params), string key)
	dic_put(dic, key, params[key]);
    }
  }

};

protected int context_id = 1;
protected mapping(int:object) contexts = ([]);
protected mapping(object:object) context_for_conf = ([]);

protected object ctx_object(object ctx)
{
  return contexts[context_id_field->get(ctx)];
}


//!
class context {

  object ctx, sctx, conf;
  object parent_module;
  protected int id;
  protected string dir;

  //!
  string gettempdir()
  {
    if (parent_module)
      dir += "conf_mod/" + parent_module->module_identifier() + "/";
    else if(conf)
      dir += "conf/" + conf->name + "/";
    else
      dir += "unbound/";
    if(!file_stat(dir))
      Stdio.mkdirhier(dir);
    return dir;
  }

  //!
  void create(object|void c, object|void mod, string|void _tmpdir)
  {
    dir = _tmpdir || "servlettmp/";
    parent_module = mod;
    id = context_id++;
    conf = c;
    ctx = context_class->alloc();
    check_exception();
    context_init(ctx, id, gettempdir());
    check_exception();
    sctx = session_context_class->alloc();
    check_exception();
    session_context_init(sctx);
    contexts[id] = this_object();
    if(conf && !parent_module) {
      if(context_for_conf[conf])
	destruct(context_for_conf[conf]);
      context_for_conf[conf] = this_object();
    }
    if(c)
    {
      set_attribute("caudium_configuration", c->name);
      check_exception();
    }
  }

  //!
  void destroy()
  {
    m_delete(contexts, id);
    if(conf)
      m_delete(context_for_conf, conf);
    ctx=0;
  }

  //!
  object make_dummy_id()
  {
     object req=RequestID(Stdio.File(), conf);
    return req;
  }

  //!
  void log(string msg)
  {
    report_notice(msg+"\n");
  }

  //!
  string get_real_path(string path)
  {
    string loc;
    string real_loc;
    if (parent_module) {
      loc = parent_module->query_location();
      real_loc = conf->real_file(loc, make_dummy_id());
    }
    else if (conf) {
      foreach(conf->location_modules(), array tmp) {
        loc = tmp[0];
        if (has_prefix(path, loc)) {
          real_loc = conf->real_file(loc, make_dummy_id());
        }
      }
    } 

    if (real_loc) {
      if (real_loc[-1] != '/')
        real_loc += "/";
      if (path[0] == '/')
        path = path[1..];
      real_loc = combine_path(real_loc + path);
      return real_loc;
    }

    return 0;
  }
  
  //!
  string get_mime_type(string file)
  {
    return conf && conf->type_from_filename(file);
  }

  //!
  string get_server_info()
  {
    return caudium->version();
  }

  //!
  object get_request_dispatcher(string path)
  {
    // FIXME
    return 0;
  }

  //!
  string get_resource(string path)
  {
    string rp;
    rp = get_real_path(path);
    return rp && ("file:"+rp);
  }

  //!
  void set_init_parameters(mapping(string:string) pars)
  {
    object f = context_initpars_field->get(ctx);
    hash_clear(f);
    foreach(indices(pars), string key)
      dic_put(f, key, pars[key]);
    check_exception();
  }

  //!
  void set_attribute(string name, mixed attribute)
  {
    context_set_attribute(ctx, name, attribute);
  }
};

//!
object conf_context(object conf)
{
  return context_for_conf[conf]||context(conf);
}

//!
object request(object context, mapping(string:array(string))|object id,
	       mapping(string:string|object)|void attrs,
	       mapping(string:array(string)|string)|void headers, mixed ... rest)
{
  if(objectp(id)) {
    string tmp = id->url_base();
    sscanf(tmp, "%*s//%s", tmp);
    sscanf(tmp, "%s:", tmp);
    sscanf(tmp, "%s/", tmp);
    string addr = id->remoteaddr || "Internal";
    string host = caudium->quick_ip_to_host(addr);
    string uri, query, pathtrans;
    if(id->raw) {
      if(sscanf(id->raw, "%[^?\r\n]?%s%*[ \t\n]", uri, query)>1)
	sscanf(query, "%[^\r\n]", query);
      else {
	query="";
	sscanf(uri, "%[^\r\n]", uri);
      }
      uri = (uri/" "+({"",""}))[1];
      if(!strlen(query))
	query = 0;
    } else {
      uri = id->not_query;
      query = id->query;
    }

    if(id->misc->path_info && strlen(id->misc->path_info) && context) {
      pathtrans = context->get_real_path(id->misc->path_info);
    }

    return request(context||conf_context(id->conf), id->variables, attrs,
		   (id->raw && MIME.parse_headers(id->raw)[0])||id->request_headers,
		   (zero_type(id->misc->len)? -1:id->misc->len),
		   id->misc["content-type"], id->prot,
                   (id && id->port_obj && lower_case(id->port_obj->prot_name))||
		   lower_case((id->prot/"/")[0]), tmp,		   
		   (id->my_fd&&id->my_fd->query_address&&
                    (int)((id->my_fd->query_address(1)||"0 0")/" ")[1]),
		   addr, (host != addr)&&host, id->data,
		   id->misc->mountpoint, id->misc->servlet_path,
                   id->misc->path_info, id->method,
                   id->misc->authenticated_user &&
                   id->misc->authenticated_user->name &&
                   id->misc->authenticated_user->name(),
		   uri, query, pathtrans);
  }
  object r = request_class->alloc();
  check_exception();
  request_init(r, context->ctx, context->sctx, @rest);
  check_exception();
  object pa = params_field->get(r);
  foreach(indices(id), string v) {
//    array(string) vals = id[v]/"";
    object sa = string_class->new_array(1);
    sa[0]=id[v];
//    foreach(indices(vals), int vi)
//      sa[vi] = vals[vi];
    dic_put(pa, v, sa);
  }
  if(attrs) {
    object at = attrs_field->get(r);
    foreach(indices(attrs), string a)
      dic_put(at, a, attrs[a]);
  }
  object hh = headers_field->get(r);
  if(headers)
    foreach(indices(headers), string h)
      if(stringp(headers[h]))
	dic_put(hh, h, headers[h]);
      else {
	object v = vector_class->alloc();
	vector_init(v);
	foreach(headers[h], string hx)
	  vector_add(v, hx);
	dic_put(hh, h, v);
      }
  else
    headers_field->put(r, 0);
  check_exception();
  return r;
}

protected int stream_id = 0;
mapping(int:object) streams = ([]);

//!
object response(object file)
{
  int id = stream_id++;
  object s = stream_class->alloc();
  check_exception();
  if(!s) return 0;
  stream_init(s, id);
  check_exception();
  object r = response_class->alloc();
  check_exception();
  if(!r) return 0;
  response_init(r, s);
  destruct(s);
  check_exception();
  streams[id] = file;
  return r;
}

//!
protected void native_log(object ctx, object msg)
{
  if (ctx_object(ctx))
    ctx_object(ctx)->log((string)msg);
  else
    report_notice((string)msg + "\n");
}

//!
protected string native_getRealPath(object ctx, object path)
{
  return ctx_object(ctx)->get_real_path((string)path);
}

//!
protected string native_getMimeType(object ctx, object file)
{
  return ctx_object(ctx)->get_mime_type((string)file);
}

//!
protected string native_getServerInfo(object ctx)
{
  return ctx_object(ctx)->get_server_info();
}

//!
protected object native_getRequestDispatcher(object ctx, object path1, object path2)
{
  return ctx_object(ctx)->get_request_dispatcher(combine_path((string)path1,
							      (string)path2));
}

//!
protected string native_getResourceURL(object ctx, object path)
{
  return ctx_object(ctx)->get_resource((string)path);
}

//!
protected void native_forgetfd(object str)
{
  int id = stream_id_field->get(str);
  object f = streams[id];
  m_delete(streams, id);
  if(f)
    destruct(f);
}

//!
protected void native_close(object str)
{
  int id = stream_id_field->get(str);
  object f = streams[id];
  if(f) {
    m_delete(streams, id);
    f->close();
  }
}

//!
protected void native_writeba(object str, object b, int off, int len)
{
  object f = streams[stream_id_field->get(str)];
  if(f)
    f->write(((string)values(b[off..off+len-1]))&("\xff"*len));
}

//!
protected string native_blockingIPToHost(object n)
{
  return caudium->blocking_ip_to_host((string)n);
}

//!
void create()
{
  natives_bind1 = context_class->register_natives(({
    ({"log", "(Ljava/lang/String;)V", native_log}),
    ({"getRealPath", "(Ljava/lang/String;)Ljava/lang/String;",
      native_getRealPath}),
    ({"getMimeType", "(Ljava/lang/String;)Ljava/lang/String;",
      native_getMimeType}),
    ({"getServerInfo", "()Ljava/lang/String;", native_getServerInfo}),
    ({"getRequestDispatcher", "(Ljava/lang/String;Ljava/lang/String;)Ljavax/servlet/RequestDispatcher;", native_getRequestDispatcher}),
    ({"getResourceURL", "(Ljava/lang/String;)Ljava/lang/String;", native_getResourceURL})}));
  natives_bind2 = stream_class->register_natives(({
    ({"low_close", "()V", native_close}),
    ({"low_write", "([BII)V", native_writeba}),
    ({"forgetfd", "()V", native_forgetfd})}));

  natives_bind3 = request_class->register_natives(({
    ({"blockingIPToHost", "(Ljava/lang/String;)Ljava/lang/String;",
      native_blockingIPToHost})}));
}

#endif /* constant(Java.machine) */
