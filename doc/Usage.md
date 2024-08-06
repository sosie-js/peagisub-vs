
# Documentation

## Usage

Modify the python bridge between aegisub and vapoursynth [aegisub-vs.py](https://raw.githubusercontent.com/arch1t3cht/Aegisub/vapoursynth/automation/vapoursynth/aegisub_vs.py) so that the ensure_plugin function can work after set_path being called.


 ```python
 """
File name: aegisub-vs.py
Author: sosie-js / github 
Created: 31.07.2024
Version: 1.5
Description: Bridge to vapoursynth using lua config helper 
peagisub (luarocks install --local peagisub-vs 1.0.5)
"""

from dataclasses import dataclass, field
import os, sys

import pexpect
import subprocess
import shlex


"""
  Wrapper to run a peagisub command 
  cmd: str  command to append to peagisub call 
"""
def run_peagisub(cmd:str):
    result=subprocess.run(shlex.split('peagisub '+cmd), capture_output=True)
    return result.stdout.decode('utf-8').replace('\n','')

"""
  Wrapper to run a lua command with luarocks env available
  name : str  name of the variable 
"""
def vsvar(name : str):
    if  name=="UserPluginDir":
        return run_peagisub('--userplugin')
    elif name=="SystemPluginDir":
        return run_peagisub('--systemplugin')
    else:
        return  run_peagisub('--'+name)

def list_files_in_dir(mypath):
    from os import listdir
    from os.path import isfile, join
    onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]
    return onlyfiles

#Now we have what we wanted

#.vpy scripts
if __name__ == "__vapoursynth__":
    
    import aegisub_vs as a
    __aegi_vscache =  vsvar("cache")
    __aegi_vsplugins =  vsvar("UserPluginDir")
    a.set_paths(locals())
		#do what you need with the video you
		#can take inspiration from arch1t3cht
		
#.py scripts
if __name__ == "__main__":    
    
    __aegi_vscache =  vsvar("cache")
    __aegi_vsplugins =  vsvar("UserPluginDir")
    vsplugins=vsvar("SystemPluginDir")
    
    print("-Vapoursynth Aegisub User Plugin dir is:"+__aegi_vsplugins )
    #example: ['libwwxd.so', 'libscxvid.so', 'libassrender.so', 'libvslsmashsource.so', 'bestsource.so']
    print(list_files_in_dir(__aegi_vsplugins))
    print("-Vapoursynth Aegisub System Plugin dir is:"+vsplugins)
    #at least ffms2.so like
    #['deblockpp7.so', 'scale2.0x_model.json', 'convo2d.so', '.tmp', 'delogo.so', 'bifrost.so', 'dctfilter.so', 'awarpsharp2.so', 'combmask.so', 'deblock.so', 'd2vsource.so', 'libsubtext.so', 'dfttest.so', 'ctmf.so', 'addgrain.so', 'eedi2.so', 'bilateral.so', 'ffms2.so', 'depan.so', 'noise3_model.json', 'noise1_model.json', 'd2vscan.pl', 'bm3d.so', 'eedi3.so', 'cnr2.so', 'noise2_model.json', 'damb.so', 'degrainmedian.so']
    print(list_files_in_dir(vsplugins))
		
 ```
   
## API

It shows the internals covering a command 'peagisub' to trigger functions in Luarock module 'peagisub.lua' or from Aegisub automation menu entry handled by script 'aegisub-vs.lua' an alias name for 'peagisub.lua'. The 'aegisub.lua' collect the paths into the the vsvars config file whereas the 'aegisub' read behind it mainly two params 'UserPluginDir' and 'SystemPluginDir' found in Vapoursynth.conf . When there is no Vapoursynth.conf , it creates a dummy one during the creation of vsvars.json configfile that can be fixed behind with  the 'Fixing vsvars.json configfile' call.

There is a [LDOC](index.html) documentation for the API Lovers that was generated fro mthe sources files
using the command `ldoc -c config.ld src/peagisub.lua`

### Using peagisub command

**Retrieving Help with**  

In shell : `   peagisub --help`
Flow:
```mermaid  
sequenceDiagram  
peagisub --help ->> peagisub:parseopt(--help)
peagisub ->> peagisub --help: print(help)
```

**Retrieving Version with**  

In shell : `   peagisub --version`
Flow:
```mermaid  
sequenceDiagram  
peagisub --help ->> peagisub:parseopt(--version)
peagisub ->> peagisub --help: print(version)
```

**Retrieving UserPluginDir**

This gives the path to the  vapoursynth user plugin directory where plugins such as bestsource and lsmas resides.
userplugin is a shortcut for UserPluginDir

In shell : `   peagisub --userplugin`
In Lua:  `vsvar('userplugin')`

Flow:
```mermaid  
sequenceDiagram  
peagisub --userplugin ->> peagisub.lua: lua -lluarocks.loader -lpeagisub -e 'print(peagisub.vsvar('userplugin') os.exit()
peagisub.lua ->> vsvar.json: read config file 
vsvar.json ->> peagisub.lua: extract var 'UserPluginDir'
 peagisub.lua ->> peagisub --userplugin: vsvar('userplugin')
```

**Retrieving SystemPluginDir**

This gives the path to the  vapoursynth system plugin directory where core plugins are installed such as ffms2.
systemplugin is a shortcut for SystemPluginDir

In shell : `   peagisub --systemplugin`
In Python `vsvar('systemplugin')`

Flow:
```mermaid  
sequenceDiagram  
peagisub --systemplugin ->> peagisub.lua: lua -lluarocks.loader -lpeagisub -e 'print(peagisub.vsvar('systemplugin') os.exit()
peagisub.lua ->> vsvar.json: read config file 
vsvar.json ->> peagisub.lua: extract var 'SystemPluginDir'
 peagisub.lua ->> peagisub --systemplugin: vsvar('systemplugin')
```

**Retrieving Vapoursynth automation dir for aegisub**

This gives the path to the  vapoursynth directory where you put vpy or py custom scripts

In shell : `   peagisub --vsdir`
In Python `vsvar('vsdir')`

Flow:
```mermaid  
sequenceDiagram  
peagisub --systemplugin ->> peagisub.lua: lua -lluarocks.loader -lpeagisub -e 'print(peagisub.vsvar('vsdir') os.exit()
peagisub.lua ->> vsvar.json: read config file 
vsvar.json ->> peagisub.lua: extract var 'vsdir'
 peagisub.lua ->> peagisub --systemplugin: vsvar('vsdir')
 
 
```

**Retrieving lua automation dir of aegisub**

This gives the path to the  lua directory where you put all lua automation scripts

In shell : `   peagisub --luadir`
In Python `vsvar('luadir')`

Flow:
```mermaid  
sequenceDiagram  
peagisub --systemplugin ->> peagisub.lua: lua -lluarocks.loader -lpeagisub -e 'print(peagisub.vsvar('luadir') os.exit()
peagisub.lua ->> vsvar.json: read config file 
vsvar.json ->> peagisub.lua: extract var 'luadir'
 peagisub.lua ->> peagisub --systemplugin: vsvar('luadir')

### Using peagisub.lua builtin

**Creation vsvars.json configfile**

This creates the vsvars config file that stores all the useful
paths to set up vapoursynth on python side.

In shell : `   peagisub --createconfigfile`
In Lua: `peagisub.createconfigfile()`
In Aegisub:  this is done on each opening if the symlink
peagisub.lua is done to automation folder aegisub-vs.lua

```mermaid
sequenceDiagram  
 aegisub-vs.lua ->> peagisub.lua:symlink 
peagisub.lua ->> vsvars.conf:peagisub.createconfigfile
vsvars.conf ->> aegisub: read ?user, ?data, ...
aegisub ->> vsvars.conf:write_vsvars_entry("xxx")
vsvars.conf ->> vapoursynth.conf: read UserPlugindir
vapoursynth.conf ->> vsvars.conf:write_vsvars_entry("vapoursynth.conf") 
vsvars.conf ->> vapoursynth.conf: read SystemPlugindir
vapoursynth.conf ->> vsvars.conf:write_vsvars_entry ("SystemPlugindir")
```

**Fixing vsvars.json configfile**

The vsvars config file may have some inexistants directories
such as in the dummy  vapoursynth config file, here is my
harmonize it. 

In shell : `   peagisub --fixconfigfile`
In Lua : `peagisub.fixconfigfile()`
In Aegisub:  this is done graphically from the entry "Generate Aegisub config file" in the Automation menu if the symlink peagisub.lua is done to automation folder aegisub-vs.lua. In this case vapoursynth.conf is fixed if user agreed with YES to the question "Fix...Vapoursynth.conf?".

```mermaid
sequenceDiagram  
 aegisub-vs.lua ->> peagisub.lua:symlink 
peagisub.lua ->> vsvars.conf:peagisub.fixconfigfile
vsvars.conf ->> aegisub: read ?user, ?data, ...
aegisub ->> vsvars.conf:write_vsvars_entry("/xxx")
vsvars.conf ->> vapoursynth.conf: _get_vapoursynth_system_plugin()
vapoursynth.conf ->> vsvars.conf:write_vsvars_entry ("UserPlugindir")
vsvars.conf ->> vapoursynth.conf: _get_vapoursynth_system_plugin()
vapoursynth.conf ->> vsvars.conf:write_vsvars_entry("SystemPlugindir")

