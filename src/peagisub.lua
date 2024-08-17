--[[
peagisub.lua aka aegisub-vs.lua for aegisub
 Copyright (C) 2024 SoSie-js / sos-productions.com
]]
--- Export Aegisub vars to a config file to be used by vapoursynth with python
-- @module peagisub

--Script properties
script_name="Generate Aegisub config file"
script_description="Exports paths specifiers to a config file to be used by python"
script_author="SoSie-js / github"
script_version="1.6"

-- ============== Debug stuff ==================

--Dump into dump.txt in the same directory of this script for debug purposes
dump=false

if aegisub ==nil then
    --use our private mock with scite
    --require "aegisub"
end

--- Serializes a table as a string
-- reproduce python pprint.pprint
--@param me a table object
--@param tab starting tabulation
--@param depth interger max depth, 5 levels per default
--@return string the string representation of the table 
function serialize(me,tab,depth)
    tab=tab or ""
    depth=depth or 5
    local tb={}
    local prevtab=tab
    if depth > 0 then
        table.insert(tb,prevtab.."{")
        tab=tab.."  "
        for x, v in pairs(me) do 
            if type(v) =="string" then
                table.insert(tb,tab..tostring(x).."="..tostring(v))
            end
            if type(v) =="table" then
                table.insert(tb,tab..tostring(x).."= "..serialize(v,tab,depth-1))
            end
        end
        table.insert(tb,prevtab.."}")
    end
    depth =depth-1
    return table.concat(tb,"\n")
end    

---Returns locals as table
--print(serialize(locals()))
--@return table 
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

--Returns globals as table
--print(serialize(globals()))
--@return table 
function globals()
    return _G
end

---Returns the current script path per default
--@param dironly a boolean if set to true return the directory of the current script
--@return string the string pathname of directory path 
function script_path(dironly)
       local str = debug.getinfo(2, "S").source
       
       --This occurs when this script is called by lua interpreter or inside scite
       -- we have just the @filename, not the directory
       if str:sub(1,1) == '@' then
            --local dbg= require 'debugger'
            --dbg()
            str=str:sub(2)
       end
       dironly= dironly or false
       if dironly then
            str=str:match("(.*[/\\])")
            if str == nil then
                str=""
            end
       end
       return str 
end
    

if(dump) then
    
    dump = {}
    dump.file=io.open(script_path(true)..'dump.txt', "a")
    dump.write=function (msg)
        if dump.file== nil then
             dump.file=io.open(script_path(true)..'dump.txt', "a")
        end
        dump.file:write(msg)
    end
    dump.close=function ()
         dump.file:close()
    end
    --dump.write("\nscript_dir="..script_path(true))
    
else
    dump={}
    dump.write=function(foo)
        --mock
    end
     dump.close=function ()
        --mock
    end
end  



require("os")
LUA_LIBEXT = package.cpath:match("[.](%a+)$")

--local 
IS_LINUX= false
IS_MACOSX = false
if LUA_LIBEXT== "dll" then
    -- Set also by lua-path
    IS_WINDOWS=true
    -- luarocks working direcory
    LUAROCKS_BASE = os.getenv( "APPDATA" ) ..   "\\luarocks" --not sure
elseif LUA_LIBEXT == "so" then
    IS_LINUX=true
    LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks"
elseif LUA_LIBEXT == "dylib" then
    IS_MACOSX=true
    LUAROCKS_BASE = os.getenv( "HOME" )  .. "/.luarocks" --not sure
else
    error("Unsupported OS with LIBEXT '".. LUA_LIBEXT .."'")
end

-- Declares local path in case of lua-path was installed as user in local
LUA_VERSION=tostring(_VERSION:gsub("Lua ", ""))

--- Minimal aegisub.decode_path  replacement when aegisub is closed or not availaible
-- can not fully decode full pathnames only one isolated specifier at a time
-- @param spec a sing specifier one of ?user,?data,?temp, ?local or ?cacher other are not supported
-- @return path
function aegisub_decode_path(spec)
    local path ="?"
    if spec == "?data" then
        --[The location where application data are stored. On Windows this is the installation directory (the location of the .exe). On Mac OS X this is inside the application bundle. On other POSIX-like systems this is $prefix/share/aegisub/]]
        return "?"
    end
    if spec == "?user" then
        --[[
        The location for user data files, such as configuration files, automatic back-ups and some additional things. On Windows this %APPDATA%\Aegisub\, on Mac OS X this is $HOME/Library/Application Support/Aegisub/ and on other POSIX-like systems this is $HOME/.aegisub/. In portable mode this is changed to ?data.
        ]]
        if IS_WINDOWS then
            path=os.getenv("APPDATA").."\\Aegisub"
        end
        if   IS_MACOSX then
            path=os.getenv("HOME") .."/Application Support/Aegisub"
        end
        if   IS_LINUX  then
            path=os.getenv("HOME") .. "/.aegisub"
        end
        return path
    end
    
    if spec == "?temp" then
        --[[The system temp directory. Audio cache and any required temporary subtitle files are stored here.
        ]]
        return PATH:tmpdir()
    end
    
    if spec == "?local" then
        --[[
        The local user settings directory. Cache files which should be persisted across runs, such as FFMS2 indexes and the fontconfig cache are stored here. %LOCALAPPDATA%\Aegisub on recent versions of Windows, and equal to ?user everywhere else.
        ]]
        if IS_WINDOWS then
            path=os.getenv("APPDATA").."\\Aegisub"
        else
            path=aegisub_decode_path("?user")
        end
        return path
    end
    
    if spec == "?script" then
        --[[Only defined if a subtitles file is open and saved somewhere, in which case it points to the directory the script is in.
        ]]
        return "?"
    end
    
    if spec == "?video" then
        --[[Only defined if a video file is loaded. Points to the directory the video file in is. Do note that this is not a good place to save things with dummy video loaded.
        ]]
        return "?"
    end
    
    if spec == "?audio" then
        --[[Only defined if an audio file is loaded. Points to the directory the audio file in is. Do note that this is not a good place to save things with dummy audio loaded.
        ]]
        return "?"
    end
   
    -- extra for aegisub_vs's cache dir, maybe ?temp/.aegisub_vscache 
    -- would be better as /tmp this is on tmpfs on SBCs..
    if  spec == "?cache" then
        return aegisub_decode_path("?local") .. "/vscache"
    end
   
   return path
end


--- Executes a command and handle errors
-- This add stderr support to io.popen, 
-- i tried many but none worked
-- @param cmd string shell command
-- @return  output the stdout string output
-- @return  err  the stderr string message
local function os_execute(cmd)

   
    local _stdout, _stderr
    local file_stdout=os.tmpname()
    local file_stderr=os.tmpname()

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
        out=(out:gsub("\r\n", "\n"):gsub("\n$", "")) -- remove final newline
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
        err=(err:gsub("\r\n", "\n"):gsub("\n$", "")) -- remove final newline
        io.close(_stderr)
        os.remove(file_stderr)
    end

    return out, err

end




--- Get the path of the vsvars config file (vsvars.json)
-- @return path
function vsvarsfile() 
    local scriptdir
    if aegisub ~= nil then
        scriptdir=aegisub.decode_path("?user")
    else
        scriptdir=aegisub_decode_path("?user")
    end
    
    if IS_WINDOWS then
        return scriptdir.."\\".."vsvars.json"
    else
        return scriptdir.."/".."vsvars.json"
    end
end

--- Custom luarocks loader compatible with aegisub
--
-- We could have used require "luarocks.loader"
-- but it is *NOT* recognized in aegisub/luajit at least when luarock is installed in user tree so we have 
--     to built our own loader by hand calling the command to complete the correct env 
--     package.path and package.cpath)]]
-- @return success boolean
local luarocks_loader=function() 

    local ok, mymod = pcall(require, "luarocks.loader")
    
    --When built in is triggered directly without using the command
    --it prevents loop when peagisub.options is polled from the command
    if not ok then 
    
        --Add the user tree, this is needed in aegisub as rocks_trees are not declared.
        --Of course, we can have built this from the config files which is equal to
        --reproduce luarocks config load, complex detection if we want to keep compatibiiity
        ---we will use instead peagisub --config-(path|cpath) that can restore thanks 
        -- to the wrap_script peagisub the correct package.path and package.path we need.
    
        --Fix LUA_PATH
        local ok, err= os_execute("peagisub --config-path")
        if( err ~= "") then
            --in case of luarocks, the wrap_script depend on is missing or is corrupted
            error("Peagisub installation is broken please reinstall them,\nluarocks install --local peagisub \n\n Error encountered is:"..err)
        end
        package.path = package.path .. ';'.. ok
        
        --Fix LUA_CPATH
        ok, err= os_execute("peagisub --config-cpath")
        package.cpath = package.cpath .. ';' .. ok 
        
    end
    
    if dump then
        dump.write("\n=== STARTING DUMP ===")
        dump.write("\nscript_path="..script_path(false))
        dump.write("\nscript_dir="..script_path(true))
        dump.write("\n===============\n")
        dump.write("package.path="..package.path)
        dump.write("\npackage.cpath="..package.cpath)
        --dump.write(serialize(globals()))
    end
    
    --Now this should work and _G("luarocks") available
    local ok, loader = pcall(require, "luarocks.loader")
    return ok
end

local LUAROCKS_LOADED=luarocks_loader()

-- Dialogs 

  --- Popup OK dialog box in aegisub with the given message
    --  The user has no choice other than cliking on the OK button to close
    -- @param msg text message for the dialog box, an information given to the user
    -- @return nothing
    function dialog_ok(msg)

        local MSG_OK = {
            btn = {"OK"},
            res = {
                ["OK"] = true
            }
        }
        
        local config = {
            {
                class = "label",
                x = 0, y = 0, width = 3, height = 3,
                label = msg
            }
        }

        -- display dialog
        if aegisub ~= nil then
            if aegisub.dialog ~= nil then
                local result, _ = aegisub.dialog.display(config, MSG_OK.btn)
            else
                print('dialog_ok '..msg)
            end
        else
            print('dialog_ok '..msg)
        end
    end

    --- Popup YES - NO dialog box in aegisub with the given message
    --  The user has no choice to answer than cliking on the NO or YES button t
    -- @param msg text message for the dialog box, a question in this case
    -- @return choice string matching the button clicked 'YES' or 'NO' 
    function dialog_yesno(msg)

        local MSG_YESNO = {
            btn = {"NO","YES"},
            res = {
                ["YES"] = true,
                ["NO"] = true
            }
        }
        
        local config = {
            {
                class = "label",
                x = 0, y = 0, width = 3, height = 3,
                label = msg
            }
        }

        -- display dialog
        if aegisub ~= nil then
            if aegisub.dialog ~= nil then
                local result, _ = aegisub.dialog.display(config, MSG_YESNO.btn)
                return tostring(result)
            else
                print('dialog_yesno '..msg)
            end
        else
            print('dialog_yes '..msg)
            return 'YES' --For debug, simulate click on button 'YES'
        end
       
    end

    --- Popup DEBUG dialog box in aegisub with the given message
    --  The user has no choice to click OK after seing the message in a textarea
    -- @param msg text message for the textarea
    -- @return nothing
    function dialog_debug(msg)
      if aegisub ~= nil then
        aegisub.debug.out(msg)
      else
        print("Debug:"..msg)
      end
    end

    --- Popup INFO dialog box in aegisub with the given message
    --  The user has no choice to click OK after seing the message in a textarea
    -- @param msg text message for the textarea
    -- @return nothing
    function dialog_info(msg)
      if aegisub ~= nil then
        aegisub.debug.out(msg)
      else
        print("Info:"..msg)
      end
    end

    --- Popup ERROR dialog box in aegisub with the given message
    --  The user has no choice to click OK after seing the message in a textarea
    -- @param msg text message for the textarea
    -- @return nothing
    function dialog_error(msg)
      if aegisub ~= nil then
        aegisub.debug.out(msg)
      else
        print("Error:"..msg)
      end
    end


if(LUAROCKS_LOADED) then

    --- NOW THE LUAROCKS ENV IS SET 

    local ok
   ok,  PATH = pcall(require, "path")
   
    if not ok then
        error("lua-path module is missing, please install it with luarocks:\nluarocks install --local lua-path")
    end
     
     
    ---Guess vapoursynth userplugin directory
    --LUA port of
    --  def _get_vapoursynth_user_plugin(self):
    --        #we dont use ?data/vapoursynth, because cannot be easily located of vspreview
    --        #as the Appimage change on every fuse, mount and content cannot be patched
    --        return str(Path.joinpath(Path(self.userdir),"vapoursynth"))
    -- @return dir the directory
    function _get_vapoursynth_user_plugin()
       local userdir
       
       if aegisub ~= nil then
        userdir=aegisub.decode_path("?user")
      else
        userdir=aegisub_decode_path("?user")
      end
        local userplugins=tostring(PATH:join(userdir,'vapoursynth'))
        if(PATH:exists(userplugins)) then
              return userplugins
        else
              dialog_error("The vapoursynth user plugins directory defined in vapoursynth.conf "..userplugins.." does not exits either move your plugins (bestsource,lsmash,..) to "..userplugins)
        end
    end


    ---Guess vapoursynth systemplugin directory
    -- LUA Port of:
    --  def _get_vapoursynth_system_plugin():
    --        import vapoursynth
    --        vapoursynth_lib= Path.joinpath(Path(vapoursynth.__file__).parent,"vapoursynth."+Vsvars.ext)
    --        symlink= os.readlink(vapoursynth_lib)
    --        if "dist-packages" in symlink:
    --            #/usr/local/lib/pythonX.Y/dist-packages/vapoursynth.cython*.so -> /usr/local/vapoursynth
    --            return str(Path.joinpath(Path(symlink).parent.parent.parent.parent,"vapoursynth"))
    --        else:
    --            return "?"
    --@return dir the directory
    function _get_vapoursynth_system_plugin()

        local PYTHON_VERSION, err
        --Retrieve version of python 3.\d+
        local cmd="python3 -c 'import sys; v=sys.version_info[:2]; print(str(v[0])+chr(46)+str(v[1]));'"
        PYTHON_VERSION, err= os_execute(cmd)
        if string.find(err,"not found") then
             dialog_error("Please install python3, it is required by get_vapoursynth_system_plugin(): sudo apt get install python3")
        else
        
           cmd="python3 -c 'import vapoursynth;print(vapoursynth.__file__)'"
           result , err= os_execute(cmd)
           local vapoursynth_lib=result
           
          if string.find(err,"ModuleNotFoundError") then
             dialog_error("Vapoursynth seems not to be installed: sudo pip3 install vapoursynth")
          else
            
            --Resolves the link, extract the dirname
            cmd='dirname `ls -l '..vapoursynth_lib ..' | cut -d" " -f12`'
            result, err= os_execute(cmd)
            
            if string.find(err,"dirname") then
                
               dialog_error("No symlink found " ..vapoursynth_lib ..") please create it:\n"..'# make Python find the Vapoursynth module \n sudo ln -s /usr/local/lib/python'..PYTHON_VERSION..'/site-packages/vapoursynth.so /usr/lib/python'..PYTHON_VERSION..'/lib-dynload/vapoursynth.so')
            else
              local symlink = result
              if  symlink == vapoursynth_lib then
                 dialog_error("The file "..vapoursynth_lib .." is not a symlink, please fix or create it:\n"..'# make Python find the Vapoursynth module \nsudo ln -s /usr/local/lib/python'..PYTHON_VERSION..'/site-packages/vapoursynth.so /usr/lib/python'..PYTHON_VERSION..'/lib-dynload/vapoursynth.so')
              elseif symlink:gmatch("dist-packages") then
                --str(Path.joinpath(Path(symlink).parent.parent.parent.parent,"vapoursynth"))
                local sysplugins=tostring(PATH:join(tostring(PATH.normalize(symlink..'/../../../')),'vapoursynth'))
                if(PATH:exists(sysplugins)) then
                  return sysplugins
                else
                   dialog_error("The vapoursynth sys plugins directory defined in vapoursynth.conf "..sysplugins.." does not exits either move your core plugins (ffms2 at least) or symlink "..sysplugins.." to /usr/local/lib/vapoursynth/")
                end
              else
                 dialog_error("Symlink "..vapoursynth_lib .." does not point to a cython version of vapoursynth in site-packages. Did you do sudo pip3 install vapoursynth for the current python version?")
              end
            end  
          end
        end
    end

    
    --- Writes a entry in the given file  
    --  An entry consists of a line "key" : "value"
    --  note file:write(",\n") should normally be done before
    -- @param file file stream
    -- @param key string
    -- @param value string
    -- @return nothing
    function  write_vsvars_entry(file, key, value)
        if (dump) then
            dump.write("\n[CONFIG] Write new entry '"..key.."' with value '"..value.."'")
        end
        file:write('  "'..key..'" : "'..value..'"')
    end
    
    --- Read the current vapoursynth config file 
    -- it will generate the vsvars conf entries UserPluginDir and SystemPluginDir
    -- @param vsvars file stream to the vsvars.json file
    -- @param vsconf_file string / pathname to vapoursynth.conf file
    function read_vapoursynth_conf(vsvars, vsconf_file)
    
        for line in io.lines(vsconf_file) do
            local save=false
            local key, value
            for i in string.gmatch(line, "[^=%s]+") do
               if not save then
                    key= i
                    save = true
                else
                    value= i
                    vsvars:write(",\n")
                    write_vsvars_entry(vsvars, key, value)
                    save = false
                end
            end
        end
    end
    
    --- generate the dummy vapoursynth config file
    -- we will generate the dummy one of http://www.vapoursynth.com/doc/installation.html
    --  it will generate the vsvars conf entries UserPluginDir and SystemPluginDir
    -- @param vsvars file stream to the vsvars.json file
    -- @param vsconf_file string / pathname to vapoursynth.conf file
    function create_dummy_vapoursynth_conf(vsvars, vsconf_file)
    
        local cfile,  userHome, UserPluginDir, SystemPluginDir
     
        cfile = io.open(vsconf_file, "w")
        userHome = PATH:user_home()
        UserPluginDir= userHome .. path.DIR_SEP .."vapoursynth".. path.DIR_SEP.."plugins"
        SystemPluginDir= "/special/non/default/location"
        cfile:write("UserPluginDir = "..UserPluginDir)
        write_vsvars_entry(vsvars, "UserPluginDir", UserPluginDir)
        cfile:write("\n")
        vsvars:write(",\n")
        cfile:write("SystemPluginDir = "..SystemPluginDir)
        write_vsvars_entry(vsvars, "SystemPluginDir", SystemPluginDir)
        dialog_ok("Warning Dummy vapoursynth.conf generated, \nplease fix it using '"..script_name.."' script from automation menu")
        cfile:close()
    end
    
    --- Fix or Create vapoursynth config file
    -- uses _get_vapoursynth_user_plugin() and _get_vapoursynth_system_plugin()
    --  it will generate the vsvars conf entries UserPluginDir and SystemPluginDir
    -- @param vsvars file stream to the vsvars.json file
    -- @param vsconf_file string / pathname to vapoursynth.conf file
    function update_vapoursynth_conf(vsvars, vsconf_file)
    
        local cfile,  userHome, UserPluginDir, SystemPluginDir
        
        cfile = io.open(vsconf_file, "w")
        UserPluginDir=  _get_vapoursynth_user_plugin()
        SystemPluginDir= _get_vapoursynth_system_plugin()
        cfile:write("UserPluginDir = "..UserPluginDir)
        write_vsvars_entry(vsvars, "UserPluginDir", UserPluginDir)
        cfile:write("\n")
        vsvars:write(",\n")
        cfile:write("SystemPluginDir = "..SystemPluginDir)
        write_vsvars_entry(vsvars, "SystemPluginDir", SystemPluginDir)
        cfile:close()
    
    end
    
    ---Build the vsvars.json config file
    -- It glues aegisub paths with vapoursynth ones from vapoursynth.conf
    -- export key=value entry (UserPluginDir SystemPluginDir) of vapoursynth.conf 
    -- as json entry in the vsvars config file
    -- @param vsvars file stream to the vsvars.json file
    -- @param vsconf_file string / pathname to vapoursynth.conf file
    -- @param fix boolean indicating if vapoursynth.conf should be created or fixed 
    -- @return fix boolean the final choice after user has been asked for agreement 
    function process_vapoursynth_conf_to_vsvars(vsvars, vsconf_file, fix)
        
        --print(vsconf_file)
  
        if PATH:exists(vsconf_file) and not fix  then
        
            if (dump) then
                dump.write("\n[INFO] Read "..vsconf_file)
            end
        
            read_vapoursynth_conf(vsvars, vsconf_file)
          
        else
           
            if not fix then
            
                if (dump) then
                    dump.write("\n[INFO]  generate the dummy one of http://www.vapoursynth.com/doc/installation.html")
                end
            
                create_dummy_vapoursynth_conf(vsvars, vsconf_file)
         
            else
                --[[Harmonize vapoursynth.conf with paths reachable in aegisub's world.
                This is imho the best combination  to do to have a gui and an auto configuration system at the same time. 
                When path are set up correctly, both aegisub and eternal viewers such as vspreview or vapoursynth-editors are usable.
                This makes vapoursynth scripting with subtitles automation much much easier.      ]]    
                local action
                if PATH:exists(vsconf_file) then
                    action="Fix"
                else
                    action="Create"
                end
                local choice=dialog_yesno(action.." "..vsconf_file.."?")
      
                if choice == "YES" then
                
                    if (dump) then
                        dump.write("\n[INFO]  Ask to "..action.. " " ..vsconf_file)
                    end
                
                    update_vapoursynth_conf(vsvars, vsconf_file)
             
                    dialog_info("\nNew '"..vsconf_file.."':\n" .."UserPluginDir = "..UserPluginDir.. "\n".."SystemPluginDir = "..SystemPluginDir.."\n\n".."Aegisub configfile vsvars.json updated")
                else
                
                    if (dump) then
                        dump.write("\n[INFO]  Let ".. vsconf_file .." unchanged ")
                    end
                
                    read_vapoursynth_conf(vsvars, vsconf_file)
                
                    fix=false
                end
            end
        end
        return fix
    end


    --- Determines where vapoursynth.conf resides 
    -- @return path to the vapoursynth.conf
    function locate_vapoursynth_conf()        
            --[[ According to https://vapoursynth.com/doc/installation.html
            Linux:
            Autoloading can be configured using the file $XDG_CONFIG_HOME/vapoursynth/vapoursynth.conf, or $HOME/.config/vapoursynth/vapoursynth.conf if XDG_CONFIG_HOME is not defined.
            ]]

            if IS_LINUX then
                vsconf_file=os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME").."/.config"
                vsconf_file= vsconf_file .. "/vapoursynth/vapoursynth.conf"
                return os.getenv("VAPOURSYNTH_CONF_PATH") or vsconf_file
            end
            --[[
            
    ###Windows###

    Windows has in total 3 different autoloading directories: user plugins, core plugins and global plugins. They are searched in that order. User plugins are always loaded first so that the current user can always decide which exact version of a plugin is used. Core plugins follow. Global plugins are placed last to prevent them from overriding any of the included plugins by accident.

    The searched paths are:

        <AppData>\VapourSynth\plugins32 or <AppData>\VapourSynth\plugins64

        <VapourSynth path>\core\plugins

        <VapourSynth path>\plugins

    Note that the per user path is not created by default. On modern Windows versions the AppData directory is located in <user>\AppData\Roaming by default.

    Shortcuts to the global autoload directory are located in the start menu.

    Avisynth plugins are never autoloaded. Support for this may be added in the future.

    User plugins should never be put into the core\plugins directory.

    ###Windows Portable###

    The searched paths are:

        <base path (portable.vs location)>\vs-plugins

    User plugins should never be put into the vs-coreplugins directory.
            
            ]]
            if IS_WINDOWS then
               --TODO: fixe me I am lazy here because windows has karma
               --os.environ['HOME'] = os.path.join(os .environ['HOMEDRIVE'],os.environ['HOMEPATH'])
               return nil
            end
            
            --[[
            
    ## OS X ###

    Autoloading can be configured using the file $HOME/Library/Application Support/VapourSynth/vapoursynth.conf. Everything else is the same as in Linux.

    Like on linux, you can use $VAPOURSYNTH_CONF_PATH to provide your own configuration.

            ]]
            if IS_MACOSX then
                vsconf_file=os.getenv("HOME") 
                vsconf_file= vsconf_file .. "/Library/Application Support/VapourSynth/vapoursynth.conf"
                return os.getenv("VAPOURSYNTH_CONF_PATH") or vsconf_file
            end
    end

    --- Dumps vars to a config file so aegisub-vs.py script can retrieve them after
    -- @param fix boolan if true create/fix vapoursynth.conf whose params belongs to vsvars
    -- @return filename path to the vsvars.conf 
    -- @return boolean fix the final choixe of the user
    function write_vsvars_configfile(fix)

      local filename = vsvarsfile()
      
      local tmp_vsvars_name=os.tmpname()
      local tmp_vsvars_file = io.open(tmp_vsvars_name, "w")
      
      --https://aegisub.org/docs/latest/aegisub_path_specifiers/
      local pathspecs ={"data","user","temp","local"} --"script","video","audio" are unresolved
      
      -- extra for aegisub_vs's cache dir
      table.insert(pathspecs,"cache")
      
        --file:write(";This is aegisub config path vars, do not edit")
        local first=true
        tmp_vsvars_file:write("{\n")
        
        local pathspec, userpath
        
         --======= retrieves aegisub path specifiers ==========
         
        if (dump) then
            dump.write("\n[INFO] retrieves aegisub path specifiers .")
        end
         
        for k, v in pairs(pathspecs) do
            -- We use the internal path specifier decoding function available in lua 
            if aegisub ~= nil and v ~= "cache" then
                pathspec=aegisub.decode_path("?"..v)
            else --our failsafe replacement
                pathspec=aegisub_decode_path("?"..v)
            end
            if v == "user" then
                userpath=pathspec
            end
            -- Backslash need to be escaped to be json valid
            pathspec=pathspec:gsub("\\","\\\\")
            -- Save the config file in the ?user directory
            if not first then
                tmp_vsvars_file:write(",\n")
            end
            first=false
            write_vsvars_entry(tmp_vsvars_file, v, pathspec)
        end
        --==== Extra dirs luadir and vsdir ==================
        
        if (dump) then
            dump.write("\n[INFO] retrieves extra dirs luadir and vsdir .")
        end
        
        tmp_vsvars_file:write(",\n")

        if IS_WINDOWS then
            pathspec=userpath.."\\automation\\autoload"
        else
            pathspec=userpath.."/automation/autoload"
        end
        pathspec=pathspec:gsub("\\","\\\\")
        write_vsvars_entry(tmp_vsvars_file, "luadir", pathspec)
        
        tmp_vsvars_file:write(",\n")

        if IS_WINDOWS then
            pathspec=userpath.."\\automation\\vapoursynth"
        else
            pathspec=userpath.."/automation/vapoursynth"
        end
        pathspec=pathspec:gsub("\\","\\\\")
        write_vsvars_entry(tmp_vsvars_file, "vsdir", pathspec)
        
        --======= retrieves vapoursynth plugin paths  ==========
        if (dump) then
            dump.write("\n[INFO] retrieves vapoursynth plugin paths  .")
        end
        
        vsconf_file=locate_vapoursynth_conf()
        if vsconf_file ~= nil then
            fix=process_vapoursynth_conf_to_vsvars(tmp_vsvars_file, vsconf_file, fix)
        else
            error("vapoursynth.conf file cannot be located!")
        end
        
        tmp_vsvars_file:write("\n}")
        tmp_vsvars_file:close()
        
       --aegisub.debug.out("\nSaving config file " ..filename)
        if (dump) then
            dump.write("\n[INFO] Saving config file " ..filename)
        end
        
        local vsvars_file = io.open(filename, "w")
        if vsvars_file ~= nil then
            tmp_vsvars_file = io.open(tmp_vsvars_name, "r")
            vsvars_file:write(tmp_vsvars_file:read("*all"))
            vsvars_file:close()
            tmp_vsvars_file:close()
            os.remove(tmp_vsvars_name)
        end
        
       return filename, fix
       
    end

    --- Gui for aegisub to build both vsvars.json and if agreed vapoursynth.conf
    -- @return nothing
    function build_configfile()

        local dump=_G["dump"]
        -- Process is done when Aegisub is opened or tiggered by user
        if(dump) then
            dump.write("\nWe are in Aegisub and script started.")
        end
            
        local filename, fix = write_vsvars_configfile(true)
        
        if not fix then
           
            local msg="Aegisub configfile updated without fixing vapoursynth.conf and saved into:"
            msg= msg .. "\n".. filename
             
           dialog_ok(msg)
        end 
        
        if(dump) then
            dump.write("\n=========\n")
            --dump.close()
        end
        
    end
    
else

    --luarocks is missing
    function build_configfile()
            if(dump) then
                dump.write("\nWe are in Aegisub and script crashed.")
            end
            
            local msg="Lurocks is missing, please install it, on linux you can use sudo apt install luarocks"
           dialog_ok(msg)
           
            if(dump) then
                dump.write("\n=========\n")
                --dump.close()
            end
    end
    
end

-- if we are inside of aegisub, this is triggered as macro which entry name matching script_name value
if aegisub ~= nil then

    -- autoupdated when Aegisub starts 
    --io.stdout:setvbuf("no")
    --print(write_vsvars_configfile())
    if(LUAROCKS_LOADED) then
        write_vsvars_configfile(false)
    end
    
    --Register macro (no validation function required)
    aegisub.register_macro(script_name,script_description,build_configfile)
    
else
   
   -- Luarocks 'peagisub' module needed by 'peagisub' command
    peagisub= {}
    
    peagisub.version=script_version
   
    --Options for the peagisub command
    peagisub.options={}
    
    if(LUAROCKS_LOADED) then
    
        if(dump) then
            dump.write("\nstep1")
        end
     
        peagisub.options= {     
            vsvars={
                userplugin="retrieve the userplugin path from vsvar config file",
                systemplugin="retrieve the systemplugin path from vsvars config file",
                cache="retrieve the cache path where lwi indexes are saved",
                luadir="retrieve the automation lua dir where aegisub-vs.lua is stored",
                vsdir="retrieve the vapoursynth dir where aegisub-vs.py is stored"
            },
            vscmds={
                createconfigfile="creates the vsvars config file that stores all the useful paths to set up vapoursynth on python side.",
                fixconfigfile="Fix vsvars.json configfile and vapoursynth.conf it depends on"
            },
            status={
            }
        }
       
        --- Get the content of a variable from the config file (vsvars.conf) 
        -- @param name of the variable
        -- @return string content
        function peagisub.vsvar(name)
            local json =require("dkjson")
            local filename = vsvarsfile()
           
            --remap some
            if name == 'userplugin' then
               name="UserPluginDir"
            end
            if name == 'systemplugin' then
                name="SystemPluginDir"
            end
            local cfile, err= io.open(filename, "r")
            local vsvars=json.decode (cfile:read("*all"), null, nil)
            cfile:close()
            return vsvars[name]
        end
        
        -- Executes a given command
        -- @param cmd a command such as 'createconfigfile' or 'fixconfigfile'
        -- @return output of the command
        function  peagisub.vscmd(cmd)
            if cmd == 'createconfigfile' then
                return write_vsvars_configfile(false)
            end
            if cmd == 'fixconfigfile' then
                return  write_vsvars_configfile(true)
            end
        end
    else

        if(dump) then
            dump.write("\nstep2")
        end
        
        peagisub.options= {     
            vsvars={
            },
            vscmds={
            },
            status={
                backend_script=script_path(),
                error= "Luarocks loader failed to be loaded!"
            }
        }
       
    end
    
    if(dump) then
        dump.write("\n=========\n")
        --dump.close()
    end
    
   return peagisub
   
end