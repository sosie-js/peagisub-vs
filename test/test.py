#!/usr/bin/env python3
from dataclasses import dataclass, field
import os, sys

import pexpect
import subprocess


"""
  Wrapper to run a lua command with luarocks env available
  cmd : str  command to run 
"""
def run_luarocks_cmd(cmd : str):
    
    #Load luarocks path  so we can reach the module
    child = pexpect.spawn('luarocks path --bin')
    LUA_PATH=child.readline()
    os.environ['LUA_PATH']=LUA_PATH.decode().split("'")[1]
    LUA_CPATH=child.readline()
    os.environ['LUA_CPATH']=LUA_CPATH.decode().split("'")[1]
    PATH=child.readline()
    os.environ['PATH']=PATH.decode().split("'")[1]
    child.close()
    
    cmd=cmd.split(" ")
    
    #force quit interactive mode, enabled by default 
    #even if -i is not set. This is a bug imho
    cmd.append("-e")
    cmd.append('os.exit()')
    
    result = subprocess.check_output(cmd)
    return result
    

### Config path detection  ########################

import re

def get_osname():
    
    import platform

    system=platform.system()

    osname = "Unix"

    if system== 'Windows':
        osname = "Windows" 
    
    if system== 'Darwin':
        osname = "Macintosh"
    return osname
    
def get_library_extension():
        
    osname=get_osname()

    if osname == "Windows" :
        ext = "dll"

    if osname == "Unix":
        ext = "so"

    if osname == "Macintosh" :
        ext="dylib"
    return ext
        
#Get ?user specifier path saved in config vsvars.json generated from lua
def get_aegisub_userdir():
    
    osname=get_osname()

    if osname == "Windows" :
        home = os.getenv('appdata')
        user_dir= "Aegisub"

    if osname == "Unix":
        home = os.getenv('HOME')
        user_dir=".aegisub"

    if osname == "Macintosh" :
        home = os.getenv('HOME')
        user_dir= "Library/Application Support/Aegisub"
        
    return str(os.path.join(home, user_dir))



from pathlib import Path


@dataclass 
class Vsvars():
    
    _vars = None
    
    userdir=get_aegisub_userdir()
    ext=get_library_extension()
    
    def get_config_file(self):
        userdir=self.userdir
        return str(os.path.join(userdir,"vsvars.json"))   
    
    def _get_datadir(self) :
        json_file_path=self.get_config_file(self)
        dirs={}
        
        force_regenerate_conf=True
        if force_regenerate_conf or not os.path.exists(json_file_path):
            #Aegisub config vsvars.json is missing, we will call our luarock module peagisub to generate it =)
            #the src/main.lua module could have been copied into aegisub  ?user/automation/autoload 
            #as aegisub-vs.lua automation script to trigger it from menu giving more accurate results when aegisub runs
            vapoursynth_conf_file = run_luarocks_cmd('lua -l peagisub')
            
            #it will have also generated thedummy vapoursynth.conf file 
            #if none normally but we check behind just in case of
            if vapoursynth_conf_file and  not os.path.exists(vapoursynth_conf_file.decode()):
                os.error("FATAL: Can not read vapoursynth config file "+vapoursynth_conf_file.decode())
            
            
        if os.path.exists(json_file_path):
            with open(json_file_path, 'r') as file:
                json = file.read() #json.loads(j.read())
                p = re.compile('\s+"([^"]+)"\s+:\s+"([^"]+)"')
                paths=p.findall(json)
                for k, v in paths:
                    dirs[k] = v
        else:
            os.error("FATAL: Can not find config file in '"+ json_file_path+"'")
           
        
        #debug            
        #print(json_file_path)
        #print(dirs)
        
        #extra to keep a track
        dirs["config"] = json_file_path
        return dirs
    
    
    def _get_vapoursynth_user_plugin(self):
        #we dont use ?data/vapoursynth, because cannot be easily located of vspreview
        #as the Appimage change on every fuse, mount and content cannot be patched
        return str(Path.joinpath(Path(self.userdir),"vapoursynth"))
    
    def _get_vapoursynth_system_plugin(self):
        import vapoursynth
        vapoursynth_lib= Path.joinpath(Path(vapoursynth.__file__).parent,"vapoursynth."+Vsvars.ext)
        symlink= os.readlink(vapoursynth_lib)
        if "dist-packages" in symlink:
            #/usr/local/lib/pythonX.Y/dist-packages/vapoursynth.cython*.so -> /usr/local/vapoursynth
            return str(Path.joinpath(Path(symlink).parent.parent.parent.parent,"vapoursynth"))
        else:
            return "?"
    
    @classmethod        
    def get(self, name):
        if self._vars is None:
             self._vars=self._get_datadir(self)
        try:
            json_file_path=self._vars[name]
            if not os.path.exists(json_file_path):
                #import web_pdb; web_pdb.set_trace()
                raise os.error("Missing directory")
            return json_file_path
        except OSError as error : 
            ##Call our smart detectors
            if  name=="UserPluginDir":
                return self._get_vapoursynth_user_plugin(self)
            elif name=="SystemPluginDir":
                return self._get_vapoursynth_system_plugin(self)
            else:
                return  "?"

#Now we have what we wanted
"""
if __name__ == "__vapoursynth__":
    
    import aegisub_vs as a
    a.set_paths(locals())
"""

if __name__ == "__main__":    

    __aegi_vscache =  Vsvars.get("cache")
    __aegi_vsplugins =  Vsvars.get("UserPluginDir")
    
    print("Vapoursynth Aegisub User Plugin dir is:"+__aegi_vsplugins )
    print("Vapoursynth Aegisub System Plugin dir is:"+Vsvars.get("SystemPluginDir"))

