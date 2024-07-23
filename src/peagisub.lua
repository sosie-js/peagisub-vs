#!/usr/bin/env lua

-----------------------------------------------------------------------------
--  This is the wrapper to our lua library trigger it as a command
--  
--  Part of https://github.com/sosie-js/peagisub-vs
--  Discussion on https://github.com/luarocks/luarocks/issues/1694
--  (c) 2024 Sosie (sosie@sos-productions.com)
--
--  License: MIT/X, 
-----------------------------------------------------------------------------


require("os")

-- Detect os to adjust api
local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
if BinaryFormat == "dll" then
   --windows
   -- luarocks install winapi ADVAPI32_DIR=c:\windows\system32 ?
   
   stdlib=require("winapi")
   
    function execute(cmd)
        result= stdlib.execute(cmd)
        return result
   end
   
elseif BinaryFormat == "so" or BinaryFormat == "dylib" then
  --[[Install posix.lib so stdlib.setenv is avaiable
   from sources (in /usr/local/lib/lua/5.1)
      wget https://codeload.github.com/luaposix/luaposix/tar.gz/refs/tags/v36.2.1
      tar xvzf luaposix-36.2.1.tar.gz
      cd luaposix-36.2.1
     ./build-aux/luke lukefile install all
   or from apt
      sudo apt install lua-posix
]]
  posix=require("posix")
  stdlib=posix.stdlib
  
  
  
  function execute_io(cmd)
        local handle = io.popen(cmd)
      
         -- reads command output.
        local output = handle:read('*a')
        -- replaces any newline with a space
        local result= output:gsub('[\n\r]', ' ')
        handle:close()
        return result
  end
  
  

   function popen_nonblock(cmd)
       local files = {}
       local tmpfile = '/tmp/stmp.txt'
       os.execute(cmd..' > '..tmpfile)
        local f = io.open(tmpfile)
       if not f then return files end  
       local k = 1
       for line in f:lines() do
          files[k] = line
          k = k + 1
       end
        f:close()
        return files
     end
   
   function execute(cmd)
        local lines =popen_nonblock(cmd)
        local result=table.concat(lines,"\n")
        return result
    end
   
else
   print("Unsupported OS")
end


--[[
  Wrapper to run a lua command with luarocks env available
  cmd : str  command to run 
]]---
function run_luarocks_cmd(cmd)

    local cmd_rock_path='luarocks path --lr-path'
    local LUA_PATH = assert(execute(cmd_rock_path))
    local LUA_PATH2=execute_io(cmd_rock_path)
    assert(LUA_PATH,LUA_PATH2)
    
    stdlib.setenv("LUA_PATH", LUA_PATH)
    assert( os.getenv("LUA_PATH") == LUA_PATH)
    --package.path = package.path .. ';' .. LUA_PATH
    --package.cpath = package.cpath .. ';' .. LUA_CPATH
    return execute(cmd)
end


print(run_luarocks_cmd('lua -l peagisub'))
os.exit(0)
