
// upgrade configuration interface to be a virtual server

#include <module.h>
inherit Caudium.UpgradeTask;

// some support functionality
class dummyConfig(string name)
{}

void setconfigvar(string sect, string var, mixed value)
{
  mapping v;
  object c = dummyConfig("ConfigurationInterface");
  v = caudium->retrieve(sect, c);
  v[var] = value;
  caudium->store(sect, v, 1, c);
}

// the meat of the upgrade task
int upgrade_server()
{
  // if we already have a configuration interface virtual server, we don't need to 
  // continue.
  foreach(caudium->configurations;; object c)
  {
    if(c->name == "ConfigurationInterface") return;
  }

   setconfigvar("spider#0", "Ports", GLOBVAR(ConfigPorts));
   setconfigvar("spider#0", "MyWorldLocation", GLOBVAR(ConfigurationURL));
   setconfigvar("spider#0", "name", "Configuration Interface");
   setconfigvar("spider#0", "netcraft_done", 1);
   setconfigvar("filesystem#0", "mountpoint", "/config_interface");
   setconfigvar("filesystem#0", "searchpath", "config_interface");
   setconfigvar("configure#0", "mountpoint", "/");
   setconfigvar("auth_master#0", "name", "Master Authentication Handler");
   setconfigvar("auth_configdefault#0", "username", GLOBVAR(ConfigurationUser));
   setconfigvar("auth_configdefault#0", "password", GLOBVAR(ConfigurationPassword));
   setconfigvar("EnabledModules", "configure#0", 1);
   setconfigvar("EnabledModules", "auth_master#0", 1);
   setconfigvar("EnabledModules", "auth_configdefault#0", 1);
   setconfigvar("EnabledModules", "filesystem#0", 1);

   caudium->save_it("ConfigurationInterface");

  return 1;
}
