#!/usr/bin/env lua


require("os")

-- Detect os name
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
   stdlib=require("posix.stdlib")

   function execute(cmd)
        local handle = assert(io.popen(cmd, 'r'))
         -- reads command output.
        local output = handle:read('*a')
        -- replaces any newline with a space
        local result= output:gsub('[\n\r]', ' ')
        handle:close()
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
    local LUA_PATH = assert(execute('luarocks path --lr-path'))
    stdlib.setenv("LUA_PATH", LUA_PATH)
    assert( os.getenv("LUA_PATH") == LUA_PATH)
    return execute(cmd)
end

print(run_luarocks_cmd('lua -l peagisub'))