--[[
README:

Export Aegisub vars to a config file to be used by vapoursynth

Exports all the vars path from aegisub to make it availaible under python

]]

--Script properties
script_name="Generate Aegisub config file"
script_description="Export paths specifiers to a config file to be used by python"
script_author="SoSie-js / github"
script_version="1.0"


-- Detect os name
local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
if BinaryFormat == "dll" then
    function os.name()
        return "Windows"
    end
elseif BinaryFormat == "so" then
    function os.name()
        return "Linux"
    end
elseif BinaryFormat == "dylib" then
    function os.name()
        return "MacOS"
    end
end
BinaryFormat = nil

-- Write a entry,  file:write(",\n") should normally be done before
function  write_vsvars_entry(file, key, value)
    file:write('  "'..key..'" : "'..value..'"')
end

-- see if the file exists (from http://lua-users.org/wiki/FileInputOutput)
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

--Minimal aegisub.decode_path  replacement when aegisub is closed or not availaible
-- can not fully decode full pathnames only one isolated specifier at a time
function aegisub_decode_path(spec)
    local path = "?"
    if spec == "?data" then
        --[The location where application data are stored. On Windows this is the installation directory (the location of the .exe). On Mac OS X this is inside the application bundle. On other POSIX-like systems this is $prefix/share/aegisub/]]
    end
    if spec == "?user" then
        --[[
        The location for user data files, such as configuration files, automatic back-ups and some additional things. On Windows this %APPDATA%\Aegisub\, on Mac OS X this is $HOME/Library/Application Support/Aegisub/ and on other POSIX-like systems this is $HOME/.aegisub/. In portable mode this is changed to ?data.
        ]]
        if os.name() == "Windows" then
            path=os.getenv("APPDATA").."\\Aegisub\\"
        end
        if os.name() == "MacOS" then
            path=os.getenv("HOME") .."/Application Support/Aegisub/"
        end
        if os.name() == "Linux"  then
            path="/home/"..os.getenv("USER") .. "/.aegisub"
        end
    end
    
    if spec == "?temp" then
        --[[The system temp directory. Audio cache and any required temporary subtitle files are stored here.
        ]]
        path="/tmp"
    end
    
    if spec == "?local" then
        --[[
        The local user settings directory. Cache files which should be persisted across runs, such as FFMS2 indexes and the fontconfig cache are stored here. %LOCALAPPDATA%\Aegisub on recent versions of Windows, and equal to ?user everywhere else.
        ]]
        if os.name() == "Windows" then
            path=os.getenv("APPDATA").."\\Aegisub\\"
        else
            path=aegisub_decode_path("?user")
        end
    end
    
    if spec == "?script" then
        --[[Only defined if a subtitles file is open and saved somewhere, in which case it points to the directory the script is in.
        ]]
    end
    
    if spec == "?video" then
        --[[Only defined if a video file is loaded. Points to the directory the video file in is. Do note that this is not a good place to save things with dummy video loaded.
        ]]
    end
    
    if spec == "?audio" then
        --[[Only defined if an audio file is loaded. Points to the directory the audio file in is. Do note that this is not a good place to save things with dummy audio loaded.
        ]]
    end
   
    -- extra for aegisub_vs's cache dir, maybe ?temp/.aegisub_vscache 
    -- would be better as /tmp this is on tmpfs on SBCs..
    if  spec == "?cache" then
        path=aegisub_decode_path("?local") .. "/vscache"
    end
   
    return path 
end

--export key=value entry (UserPluginDir SystemPluginDir) of vapoursynth.conf 
--as json entry in the vsvars config file
function process_vapoursynth_conf_to_vsvars(file, root_pluging)
  if file_exists(root_plugin)  then
        for line in io.lines(root_plugin) do
            local save=false
            local key, value
            for i in string.gmatch(line, "[^=%s]+") do
               if not save then
                    key= i
                    save = true
                else
                    value= i
                    file:write(",\n")
                    write_vsvars_entry(file, key, value)
                    save = false
                end
            end
        end
    end
end


        --=============== Determines where vapoursynth.conf resides ======================

function locate_vapoursynth_conf()        
        --[[ According to https://vapoursynth.com/doc/installation.html
        Linux:
        Autoloading can be configured using the file $XDG_CONFIG_HOME/vapoursynth/vapoursynth.conf, or $HOME/.config/vapoursynth/vapoursynth.conf if XDG_CONFIG_HOME is not defined.
        ]]

        if os.name() == "Linux" then
            root_plugin=os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME").."/.config"
            root_plugin= root_plugin .. "/vapoursynth/vapoursynth.conf"
            root_plugin=os.getenv("VAPOURSYNTH_CONF_PATH") or root_plugin
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
        if os.name() == "Windows" then
           --TODO: fixe me I am lazy here because windows has karma
           root_pluging=nil
        end
        
        --[[
        
## OS X ###

Autoloading can be configured using the file $HOME/Library/Application Support/VapourSynth/vapoursynth.conf. Everything else is the same as in Linux.

Like on linux, you can use $VAPOURSYNTH_CONF_PATH to provide your own configuration.

        ]]
        if os.name() == "MacOS" then
            root_plugin=os.getenv("HOME") 
            root_plugin= root_plugin .. "/Library/Application Support/VapourSynth/vapoursynth.conf"
            root_plugin=os.getenv("VAPOURSYNTH_CONF_PATH") or root_plugin
        end
        return root_pluging
end

-- Dumps vars to a config file so aegisub-vs.py script can retrieve them after
function write_vsvars_configfile()
  
  if aegisub ~= nil then
    scriptpath=aegisub.decode_path("?user")
  else
    scriptpath=aegisub_decode_path("?user")
  end
  
  scriptname="vsvars.txt" --aegisub.file_name()
  filename=scriptname:gsub("%.%w+$",".json")
	
  filename= scriptpath.."/"..filename 
  
  local file = io.open(filename, "w")
  --https://aegisub.org/docs/latest/aegisub_path_specifiers/
  local pathspecs ={"data","user","temp","local"} --"script","video","audio" are unresolved
  
  -- extra for aegisub_vs's cache dir
  table.insert(pathspecs,"cache")
  
  if file ~= nil then
  
		--file:write(";This is aegisub config path vars, do not edit")
		first=true
		file:write("{\n")
        
         --======= retrieves aegisub path specifiers ==========
         
		for k, v in pairs(pathspecs) do
			-- We use the internal path specifier decoding function available in lua 
			    if aegisub ~= nil and v ~= "cache" then
                    pathspec=aegisub.decode_path("?"..v)
			    else --our failsafe replacement
                    pathspec=aegisub_decode_path("?"..v)
			    end
			-- Backlash need to be escaped to be json valid
			pathspec=pathspec:gsub("\\","\\\\")
			-- Save the config file in the ?user directory
			if not first then
				file:write(",\n")
			end
			first=false
			write_vsvars_entry(file, v, pathspec)
		end
        
        --======= retrieves vpoursynth plugin path  ==========
        root_plugin=locate_vapoursynth_conf()
        if root_plugin ~= nil then
            process_vapoursynth_conf_to_vsvars(file, root_pluging)
        end
        
        file:write("\n}")
		file:close()
	   --aegisub.debug.out("\nSaving config file " ..filename)
   end
   
   return filename
   
end


function build_configfile()

	-- Process is done when Aegisub is opened or tiggered by user
	
	local msg="Aegisub configfile updated and saved into:"
    
    filename= write_vsvars_configfile()
    
    msg= msg .. "\n".. filename
	
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
	local result, _ = aegisub.dialog.display(config, MSG_OK.btn)
	

end

-- autoupdated when Aegisub starts 
write_vsvars_configfile()

-- if we are inside of aegisub, this is triggered as macro matching script_name value
if aegisub ~= nil then
    --Register macro (no validation function required)
    aegisub.register_macro(script_name,script_description,build_configfile)
end
