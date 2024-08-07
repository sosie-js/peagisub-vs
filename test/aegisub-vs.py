"""
File name: aegisub-vs.py
Author: sosie-js / github 
Created: 3.08.2024
Version: 1.5
Description: Bridge to vapoursynth using lua config helper (luarocks install --local peagisub-vs 1.0.5)
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
    try:
        result=subprocess.run(shlex.split('peagisub '+cmd), capture_output=True)
    except OSError as e:
        if e.errno == 2:
            raise OSError("Peagisub command is required , please install with luarocks. You can use install scripts provided by the peagisub package or simply use luarocks install --local peagisub 1.0.5")
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

if __name__ == "__vapoursynth__":
    
    import aegisub_vs as a
    __aegi_vscache =  vsvar("cache")
    __aegi_vsplugins =  vsvar("UserPluginDir")
    a.set_paths(locals())

if __name__ == "__main__":    
    
    __aegi_vscache =  vsvar("cache")
    __aegi_vsplugins =  vsvar("UserPluginDir")
    print( __aegi_vsplugins)
    print("Finished")
