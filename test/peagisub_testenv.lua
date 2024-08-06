#!/usr/bin/env lua

----------------------------------------------------------
--  peagisub_testenv.lua
--
-- Dealing with luarock env can produce a nightmare 
-- of quotes when luarock ignore your local tree 
-- even if luarock is installed in local. Here is the demo
-- that took me a week to isolate. Hope you will cherish it
-------------------------------------------------------

require("os")

do
  local loadedModules = {} -- local so it won't leak to _G
  function loadModule(name, source)
    if loadedModules[name] then return loadedModules[name] end
    loadedModules[name] = assert(loadstring(source))() or true
  end
  function unloadModule(name)
    loadedModules[name] = nil
  end
end

local test=false

---Execute a command and handle errors
-- This add stderr support to io.popen, 
-- i tried many but none worked
--@param cmd string shell command
--@return  output  
--@return  err   where output is stdout and err is stderr message
local function os_execute(cmd)

    local _stdout, _stderr
    local file_stdout=os.tmpname()
    local file_stderr=os.tmpname()

    mask_stdout=true
    mask_stderr=true

    --io.stdout:setvbuf 'no' 
    --io.stderr:setvbuf 'no'

    local out=' > '..file_stdout
    local err= ' 2> '..file_stderr

    --local pipe =  io.popen(cmd.. out.. err)  
    --local exe = tonumber(pipe:read())
    --pipe:close()
    
    os.execute(cmd.. out.. err)
    
    --io.stdout:flush()
    --io.stderr:flush()
    
    _stdout,err=io.open(file_stdout,"r")
    if not _stdout then 
        os.remove(file_stdout)
        os.remove(file_stderr)
        return nil,"Could not open stdout: "..err
    else
        out=tostring(_stdout:read("*all"))
        out= (out:gsub("\r\n", "\n"):gsub("\n$", "")) -- remove final newline
        io.close(_stdout)
        os.remove(file_stdout)
    end
  
    _stderr,err=io.open(file_stderr,"r")
    if not _stderr then 
        os.remove(file_stderr)
        return nil, "Could not open stderr: "..err
    else
        _stderr:flush()
        err=tostring(_stderr:read("*all"))
        err= (err:gsub("\r\n", "\n"):gsub("\n$", "")) -- remove final newline
        io.close(_stderr)
        os.remove(file_stderr)
    end

    return out, err

end

--============ VERSION 1 ================================= 


---Call the a method of the luarocks module by their name
--should be equivalent to module.method(param)
--@param module module name installed with luarock install module
--@param method module method
--@param params stringified params separated by a comma
--@param env the famous command that loads the luarocks env using trees in the config
--@return 
function  run_luarocks_module_method(module, method,params,env)
    local cmd='print('..module..'.'..method..'("'.. params..'")); os.exit()'
    cmd=env.."lua -lluarocks.loader -l".. module .. " -e '"..cmd.."'"
    local out, err= os_execute(cmd)
    if(err~="") then
        error("Error ".. module.. ".".. method.."'"..tostring(err).."'")
    end
    return out
end


--- Get the content of a variable from the config file (vsvars.conf) 
-- @param name of the variable
--@param env the famous command that loads the luarocks env using trees in the config
-- @return string content
function vsvar_revisited(name,env)
    --should be equivalent to peagisub.vsvar(name)
    return run_luarocks_module_method('peagisub','vsvar',name,env)
end



--- Get the content of a variable from the config file (vsvars.conf) 
-- @param name of the variable
--@param env the famous command that loads the luarocks env using trees in the config
-- @return string content
function vsvar(name,env)
    --should be equivalent to peagisub.vsvar(name)
    --but not unless you set the env !
    cmd='print(peagisub.vsvar("'..name..'")); os.exit()'
    env=env or ''
    cmd=env.."lua -lluarocks.loader -lpeagisub -e '"..cmd.."'"
    local out, err= os_execute(cmd)
    if(err~="") then
        error("Error vsvar'"..tostring(err).."'")
    end
    return out
end

--Just a test..that initially failed because local tree is not loaded by the luarock.loader. eval "$(luarocks path --bin)" added solved this.
if(test) then
    local env='eval "$(luarocks path --bin)";'
    print(assert(vsvar('luadir',env) ==  vsvar_revisited('luadir',env)))
end
    
--============ VERSION 2 =================================    


--[[We could have used require "luarocks.loader"
 but it is *NOT* recognized in aegisub/luajit at least
     when luarock is installed as user so we have 
     to built our own loader by hand using monkey patching technique]]
-- @return nothing
local luarocks_loader=function() 

    local ok, mymod = pcall(require, "luarocks.loader")
    
    -- Debug helpers
    
    --dump locals
    --for x, v in pairs(locals()) do print(x, v) end
    function locals()
      local variables = {}
      local idx = 1
      while true do
        local ln, lv = debug.getlocal(2, idx)
        if ln ~= nil then
          variables[ln] = lv
        else
          break
        end
        idx = 1 + idx
      end
      return variables
    end

    --dump globals
    --for x, v in pairs(globals()) do print(x, v) end
    --for x, v in pairs(getfenv()) do print(x, v) end
    function globals()
        return _G
    end
    
     function dump(someuserdata)
        local report=getmetatable(someuserdata)
        if report  ~=nil then
            print(inspect(report))
        else
            print(tostring(report))
        end
    end
    
    local executable=function(cmd)
      --[[local bindir = debug.getinfo(2, "S").source:sub(2):gsub("peagisub","")
       local f=io.open(bindir..cmd,"r")
       if f~=nil then io.close(f) return true else return false end]]
       out, err= os_execute('type '..cmd)
       return not string.find(err,"not found") 
    end
    
    if(not ok and not executable('luarocks') and aegisub == nil) then
        error("Module luarock is missing install it with the install.sh script")
    end

    --LUA_LIBEXT = package.cpath:match("%p[\\|/]?%p(%a+)$")
    LUA_LIBEXT = package.cpath:match("\.(%a+)$")
    --local 
    IS_LINUX= false
    IS_MACOSX = false
    if LUA_LIBEXT== "dll" then
        -- IS_WINDOWS is set later by require "lua-path"
        -- luarocks working direcory
        LUAROCKS_BASE = os.getenv( "APPDATA" ) ..   "\\luarocks" --not sure
    elseif LUA_LIBEXT == "so" then
        IS_LINUX=true
        LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks"
    elseif LUA_LIBEXT == "dylib" then
        IS_MACOSX=true
        LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks" --not sure
    else
        --for x, v in pairs(globals()) do print(x, v) end
        error("luarocks_loader error: unsupported LUA_LIBEXT '"..LUA_LIBEXT.."' read from package.cpath '".. package.cpath.."'")
    end

    -- Declares local path in case of lua-path was installed as user in local
    LUA_VERSION=tostring(_VERSION:gsub("Lua ", ""))
    

    
    function script_path()
       local str = debug.getinfo(2, "S").source:sub(2)
       return str -- str:match("(.*[/\\])")
    end
    
    --Lightweight version cfg.init_package_paths()
    --of https://github.com/luarocks/luarocks/blob/master/src/luarocks/core/cfg.lua
    --limited to the user tree where all is installed in local
    if not ok then  
        --LUA_PATH
        package.path = package.path .. ';' .. LUAROCKS_BASE .. "/share/lua/" .. LUA_VERSION.."/?.lua".. ';' .. LUAROCKS_BASE .. "/share/lua/".. LUA_VERSION .."/?/init.lua" 
        --LUA_CPATH
        package.cpath = package.cpath .. ';' .. LUAROCKS_BASE.. "/lib/lua/"..LUA_VERSION .."/?."..LUA_LIBEXT .. ';' .. LUAROCKS_BASE .. "/lib/lua/"..LUA_VERSION .."/?/init."..LUA_LIBEXT
    else
        --print(package.path)
        --print(package.cpath)
    end
end

if(test) then
    luarocks_loader() 
    require "peagisub"
    print(peagisub.vsvar('luadir'))   

-- reset 
for k, v in pairs(package.loaded) do
    print(k,v)
end
--package.loaded=nil
for k, v in pairs(package.loaded) do
    --print(k,v)
    if(k == 'peagisub') then
        for k1, v1 in pairs(v) do
            --print(k1,v1)
        end
    end
     if(k == 'luarocks.loader') then
        for k1, v1 in pairs(v) do
            if k1 =='context' then
                print("== Context")
                for k2, v2 in pairs(v1) do
                    print(k2,v2)
                end
            end
            print("== which")
            if k1 =='which' then
                print(k1,v1)
            end
        end
    end
end
package.path=''
package.cpath=''
end
--============= VERSION 3 =================================
function mysplit (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end 


------ path stuff from luarocks/core/path.lua

local dir={}
local dir_sep = package.config:sub(1, 1) 

local function unquote(c)
   local first, last = c:sub(1,1), c:sub(-1)
   if (first == '"' and last == '"') or
      (first == "'" and last == "'") then
      return c:sub(2,-2)
   end
   return c
end

--- Describe a path in a cross-platform way.
-- Use this function to avoid platform-specific directory
-- separators in other modules. Removes trailing slashes from
-- each component given, to avoid repeated separators.
-- Separators inside strings are kept, to handle URLs containing
-- protocols.
-- @param ... strings representing directories
-- @return string: a string with a platform-specific representation
-- of the path.
function dir.path(...)
   local t = {...}
   while t[1] == "" do
      table.remove(t, 1)
   end
   for i, c in ipairs(t) do
      t[i] = unquote(c)
   end
   return dir.normalize(table.concat(t, "/"))
end

--- Split protocol and path from an URL or local pathname.
-- URLs should be in the "protocol://path" format.
-- For local pathnames, "file" is returned as the protocol.
-- @param url string: an URL or a local pathname.
-- @return string, string: the protocol, and the pathname without the protocol.
function dir.split_url(url)
   assert(type(url) == "string")

   url = unquote(url)
   local protocol, pathname = url:match("^([^:]*)://(.*)")
   if not protocol then
      protocol = "file"
      pathname = url
   end
   return protocol, pathname
end

--- Normalize a url or local path.
-- URLs should be in the "protocol://path" format.
-- Removes trailing and double slashes, and '.' and '..' components.
-- for 'file' URLs, the native system's slashes are used.
-- @param url string: an URL or a local pathname.
-- @return string: Normalized result.
function dir.normalize(name)
   local protocol, pathname = dir.split_url(name)
   pathname = pathname:gsub("\\", "/"):gsub("(.)/*$", "%1"):gsub("//", "/")
   local pieces = {}
   local drive = ""
   if pathname:match("^.:") then
      drive, pathname = pathname:match("^(.:)(.*)$")
   end
   pathname = pathname .. "/"
   for piece in pathname:gmatch("(.-)/") do
      if piece == ".." then
         local prev = pieces[#pieces]
         if not prev or prev == ".." then
            table.insert(pieces, "..")
         elseif prev ~= "" then
            table.remove(pieces)
         end
      elseif piece ~= "." then
         table.insert(pieces, piece)
      end
   end
   if #pieces == 0 then
      pathname = drive .. "."
   elseif #pieces == 1 and pieces[1] == "" then
      pathname = drive .. "/"
   else
      pathname = drive .. table.concat(pieces, "/")
   end
   if protocol ~= "file" then
      pathname = protocol .. "://" .. pathname
   else
      pathname = pathname:gsub("/", dir_sep)
   end
   return pathname
end

------search_in_path stuff from luarocks/fs/(unix+win32).lua

local DIR_SEP = package.config:sub(1,1)
local IS_WINDOWS = DIR_SEP == '\\'
    
local search_in_path=(function(program)

    if(IS_WINDOWS) then

        --- from luarocks/fs/win32.lua
         return function (program)
           if program:match("\\") then
              local fd = io.open(dir.path(program), "r")
              if fd then
                 fd:close()
                 return true, program
              end

              return false
           end

           if not program:lower():match("exe$") then
              program = program .. ".exe"
           end

           for d in (os.getenv("PATH") or ""):gmatch("([^;]+)") do
              local fd = io.open(dir.path(d, program), "r")
              if fd then
                 fd:close()
                 return true, d
              end
           end
           return false
        end
    
    else
        --- from luarocks/fs/unix.lua
        --[[We could have used shell type too like this:
          function unix.search_in_path(program)
            -- type is an internal shell command
           local cmd="type "..program
            local out, err= os_execute(cmd)
            if(err~="") then
                print("Error search in path: '"..tostring(err).."'")
                return ""
            end
           return out:gsub(program.." is ","")
         end 
        ]]
        return function (program)
           if program:match("/") then
              local fd = io.open(dir.path(program), "r")
              if fd then
                 fd:close()
                 return true, program
              end

              return false
           end

           for d in (os.getenv("PATH") or ""):gmatch("([^:]+)") do
              local fd = io.open(dir.path(d, program), "r")
              if fd then
                 fd:close()
                 return true, d
              end
           end
           return false
        end
    end
end)()

--- Now comes the beast

function luarocks_loader()

    --Fetch the content of the wrap_script to extract package.path and package.cpath
    --We will be able to recreate the ENV needed by luarocks without need of eval that
    --fail in some protected env such as luajit in Aegisub
    local success, peagisub_path=search_in_path('peagisub')
    if not success then
        return false
    else
        peagisub_path=dir.path(peagisub_path,"peagisub")
        _stdout,err=assert(io.open(peagisub_path,"r"))
        if(err~=nill) then
            print("Error getcfg'"..tostring(err).."': '"..peagisub_path.."'")
            return false
        end
        out=tostring(_stdout:read("*all"):gsub("package.path","#"):gsub("package.cpath","#"):gsub('#="',"#"):gsub(';"..#',"#"):gsub("-e '","#"))
        local chunks=mysplit(out, "#")
        for k, v in pairs(chunks) do
            --k==1 indicates LUAROCKS_SYSCONFDIR='/etc/luarocks' this is wrong imho but
            --home/.luarock is where the config files resides is taken fortunately  into account
            if k==2 then package.path=v end
            if k==4 then package.cpath=v end
        end
    end
    require 'luarocks.loader'
    return true
end 
   

if luarocks_loader() then
    require "peagisub"
    print(peagisub.vsvar('luadir'))   
end

--When luarocks list (all are in user tree) and env='' (No luarocks env set):
-- reset 

if(test) then
    package.loaded=nil
    package.path=''
    package.cpath=''
    require 'luarocks.loader'
    require "peagisub"
    print(peagisub.vsvar('luadir'))   
end

--[[
Rocks installed for Lua 5.1
---------------------------

bit32
   5.3.5.1-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

dkjson
   2.8-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

ldoc
   1.5.0-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

lua-path
   0.3.1-2 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

luafilesystem
   1.8.0-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

luaposix
   36.2.1-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

luarocks
   3.11.1-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

luasec
   1.3.2-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

luasocket
   3.1.0-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

markdown
   0.33-1 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

optparse
   1.5-2 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

peagisub
   1.0.0-5 (installed) - /home/pi/.luarocks/lib/luarocks/rocks-5.1

...

]]

--and ~/.luarocks/config-5.1.lua

--[[
--https://github.com/luarocks/luarocks/wiki/Config-file-format
rocks_trees = {
   {
       name= "user",
       root = home..[\[/.luarocks]\],
       bin_dir = home.."/.local/bin"
       --lib_dir = home.."/.local/lib/lua/5.1", 
       --lua_dir = home.."/.local/share/lua/5.1
   },
   {  
       name="system",
       root = [\[/usr/local]\],
       bin_dir = [\[/usr/local/bin]\]
       --lib_dir = [\[/usr/local/lua/5.1]\], 
       --lua_dir = [\[/usr/local/share/lua/5.1]\]
   },
]]
--giving luarocks config:
--[[...
rocks_trees = {
   {
      bin_dir = "/home/pi/.local/bin",
      name = "user",
      root = "/home/pi/.luarocks"
   },
   {
      bin_dir = "/usr/local/bin",
      name = "system",
      root = "/usr/local"
   }
}
...]]

--it will throws
--[[
lua5.1: peagisub_test.lua:74: Error vsvar'lua: module 'luarocks.loader' not found:
	no field package.preload['luarocks.loader']
	no file './luarocks/loader.lua'
	no file '/usr/local/share/lua/5.1/luarocks/loader.lua'
	no file '/usr/local/share/lua/5.1/luarocks/loader/init.lua'
	no file '/usr/local/lib/lua/5.1/luarocks/loader.lua'
	no file '/usr/local/lib/lua/5.1/luarocks/loader/init.lua'
	no file '/usr/share/lua/5.1/luarocks/loader.lua'
	no file '/usr/share/lua/5.1/luarocks/loader/init.lua'
	no file './luarocks/loader.so'
	no file '/usr/local/lib/lua/5.1/luarocks/loader.so'
	no file '/usr/lib/x86_64-linux-gnu/lua/5.1/luarocks/loader.so'
	no file '/usr/lib/lua/5.1/luarocks/loader.so'
	no file '/usr/local/lib/lua/5.1/loadall.so'
	no file './luarocks.so'
	no file '/usr/local/lib/lua/5.1/luarocks.so'
	no file '/usr/lib/x86_64-linux-gnu/lua/5.1/luarocks.so'
	no file '/usr/lib/lua/5.1/luarocks.so'
	no file '/usr/local/lib/lua/5.1/loadall.so'
stack traceback:
	[C]: ?
	[C]: ?'
stack traceback:
	[C]: in function 'error'
	peagisub_test.lua:74: in function 'vsvar'
	peagisub_test.lua:80: in main chunk
	[C]: ?
>Exit code: 1
]]
--==CONCLUSION ==
--user tree containing peagisub buitlin is ignored 
--that means rockstrees are not loaded from config files as it should be
--
-- -> see how luarocks_loader() fixed it as well

--============= VERSION 4: parsing config file to generate  =================================

util= {}

--- Clean up a path-style string ($PATH, $LUA_PATH/package.path, etc.),
-- removing repeated entries and making sure only the relevant
-- Lua version is used.
-- Example: given ("a;b;c;a;b;d", ";"), returns "a;b;c;d".
-- @param list string: A path string (from $PATH or package.path)
-- @param sep string: The separator
-- @param lua_version (optional) string: The Lua version to use.
-- @param keep_first (optional) if true, keep first occurrence in case
-- of duplicates; otherwise keep last occurrence. The default is false.
function util.cleanup_path(list, sep, lua_version, keep_first)
   assert(type(list) == "string")
   assert(type(sep) == "string")

   list = list:gsub(dir_sep, "/")

   local parts = util.split_string(list, sep)
   local final, entries = {}, {}
   local start, stop, step

   if keep_first then
      start, stop, step = 1, #parts, 1
   else
      start, stop, step = #parts, 1, -1
   end

   for i = start, stop, step do
      local part = parts[i]:gsub("//", "/")
      if lua_version then
         part = part:gsub("/lua/([%d.]+)/", function(part_version)
            if part_version:sub(1, #lua_version) ~= lua_version then
               return "/lua/"..lua_version.."/"
            end
         end)
      end
      if not entries[part] then
         local at = keep_first and #final+1 or 1
         table.insert(final, at, part)
         entries[part] = true
      end
   end

   return (table.concat(final, sep):gsub("/", dir_sep))
end

-- from http://lua-users.org/wiki/SplitJoin
-- by Philippe Lhoste
function util.split_string(str, delim, maxNb)
   -- Eliminate bad cases...
   if string.find(str, delim) == nil then
      return { str }
   end
   if maxNb == nil or maxNb < 1 then
      maxNb = 0    -- No limit
   end
   local result = {}
   local pat = "(.-)" .. delim .. "()"
   local nb = 0
   local lastPos
   for part, pos in string.gmatch(str, pat) do
      nb = nb + 1
      result[nb] = part
      lastPos = pos
      if nb == maxNb then break end
   end
   -- Handle the last field
   if nb ~= maxNb then
      result[nb + 1] = string.sub(str, lastPos)
   end
   return result
end

-- Declares local path in case of lua-path was installed as user in local
    LUA_VERSION=tostring(_VERSION:gsub("Lua ", ""))
    
    local cfg = {}
    cfg.lua_version= LUA_VERSION
    
    --LUA_LIBEXT = package.cpath:match("%p[\\|/]?%p(%a+)$")
    LUA_LIBEXT = package.cpath:match("\.(%a+)$")
    cfg.lib_extension= LUA_LIBEXT
     
    --local 
    IS_LINUX= false
    IS_MACOSX = false
    if LUA_LIBEXT== "dll" then
        -- IS_WINDOWS is set later by require "lua-path"
        -- luarocks working direcory
        --cfg.home = os.getenv("APPDATA") or "c:"
        --cfg.home_tree = dir.path(cfg.home, "luarocks")
        --cfg.sysconfdir = sysconfdir or dir.path((os.getenv("PROGRAMFILES") or "c:"), "luarocks")
        LUAROCKS_BASE = os.getenv( "APPDATA" ) ..   "\\luarocks" --not sure
    elseif LUA_LIBEXT == "so" then
        IS_LINUX=true
        LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks"
    elseif LUA_LIBEXT == "dylib" then
        IS_MACOSX=true
        LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks" --not sure
    else
        --for x, v in pairs(globals()) do print(x, v) end
        error("luarocks_loader error: unsupported LUA_LIBEXT '"..LUA_LIBEXT.."' read from package.cpath '".. package.cpath.."'")
    end

    local config_file_name = "config-"..cfg.lua_version..".lua"
    
    cfg.project_dir=LUAROCKS_BASE
    local project_config_file = dir.path(cfg.project_dir, config_file_name)
 
    cfg.lua_modules_path = dir.path("share", "lua", cfg.lua_version)
    cfg.lib_modules_path = dir.path("lib", "lua", cfg.lua_version)
    rocks_subdir = dir.path("lib", "luarocks", "rocks-"..cfg.lua_version)
     

    local function load_config(config_file)
        home = os.getenv( "HOME" ) 
        dofile(config_file)
        home = nil
        cfg.rocks_trees={}
        for k, tree in pairs(rocks_trees) do
            if type(tree) == 'table' then
                for k1, v1 in pairs(tree) do
                    print(k1,v1)
                end
                 table.insert(cfg.rocks_trees,tree)
            end
        end
    end
    load_config(project_config_file)
     
   do
      local function make_paths_from_tree(tree)
         local lua_path, lib_path, bin_path
         if type(tree) == "string" then
            lua_path = dir.path(tree, cfg.lua_modules_path)
            lib_path = dir.path(tree, cfg.lib_modules_path)
            bin_path = dir.path(tree, "bin")
         else
            lua_path = tree.lua_dir or dir.path(tree.root, cfg.lua_modules_path)
            lib_path = tree.lib_dir or dir.path(tree.root, cfg.lib_modules_path)
            bin_path = tree.bin_dir or dir.path(tree.root, "bin")
         end
         return lua_path, lib_path, bin_path
      end

      function cfg.package_paths(current)
         local new_path, new_cpath, new_bin = {}, {}, {}
         local function add_tree_to_paths(tree)
            local lua_path, lib_path, bin_path = make_paths_from_tree(tree)
            table.insert(new_path,  dir.path(lua_path, "?.lua"))
            table.insert(new_path,  dir.path(lua_path, "?", "init.lua"))
            table.insert(new_cpath, dir.path(lib_path, "?."..cfg.lib_extension))
            table.insert(new_bin, bin_path)
         end
         if current then
            add_tree_to_paths(current)
         end
         for _,tree in ipairs(cfg.rocks_trees) do
            add_tree_to_paths(tree)
         end
         return table.concat(new_path, ";"), table.concat(new_cpath, ";"), table.concat(new_bin, cfg.export_path_separator)
      end
   end

   function cfg.init_package_paths()
      local lr_path, lr_cpath, lr_bin = cfg.package_paths()
      package.path = util.cleanup_path(package.path .. ";" .. lr_path, ";", cfg.lua_version, true)
      package.cpath = util.cleanup_path(package.cpath .. ";" .. lr_cpath, ";", cfg.lua_version, true)
   end
   
   --test
    package.path = ""
    package.cpath = ""
   cfg.init_package_paths()
   print(package.path)
    print(package.cpath)
