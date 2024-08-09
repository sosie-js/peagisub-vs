#!/usr/bin/lua

--[[
aegisub.lua Aegisub Mock system
 Copyright (C) 2024 SoSie-js / sos-productions.com
]]

if include == nil then
   
   local loaded_chunk
   
    function file_exists(name)
       local f=io.open(name,"r")
       if f~=nil then io.close(f) return true else return false end
    end


    function include(file)
      dofile(file)
    end

    function doFile(filename)
      loaded_chunk = assert(loadfile(filename))
      loaded_chunk()
    end
    
    function script_path()
       local str = debug.getinfo(2, "S").source:sub(2)
       print(debug.getinfo(2, "S").source)
       return str:match("(.*/)")
    end
    
end


local calc=require('calc')

-- Mock aegisub
--

--An attempt to mimick https://aegi.vmoe.info/docs/3.0/Automation/Lua/Subtitle_file_interface/
--AN example of json of it
--{
--  __init_clipboard = "<function 1>",
--  active = 7,
--  cancel = "<function 2>",
--  debug = {
--    out = "<function 3>"
--  },
--  decode_path = "<function 4>",
--  dialog = {
--    display = "<function 5>",
--    open = "<function 6>",
--    save = "<function 7>"
--  },
--  dialogue = { 1, 2, 3, 4, 5, 6, 7 },
--  file_name = "<function 8>",
--  frame_from_ms =  "<function 9=aegisub.frame_from_ms(ms) > -- https://aegi.vmoe.info/docs/3.0/Automation/Lua/Miscellaneous_APIs/
--  get_audio_selection = "<function 10>",
--  gettext = "<function 11>",
--  info = { 1, 2, 3, 4, 5, 6, 7 },
--  keyframes = "<function 12>",
--  log = "<function 13>",
--  lua_automation_version = 4,
--  ms_from_frame = "<function 14 = aegisub.ms_from_frame(frame) https://aegi.vmoe.info/docs/3.0/Automation/Lua/Miscellaneous_APIs/
--  parse_karaoke_data = "<function 15>",
--  progress = {
--    is_cancelled = "<function 16>",
--   set = "<function 17>",
--    task = "<function 18>",
--    title = "<function 19>"
--  },
--  project_properties = "<function 20>",
--  register_filter = "<function 21>",
--  register_macro = "<function 22>",
--  selection = { 7 },
--  set_undo_point = "<function 23>",
--  style = { 1, 2, 3, 4, 5, 6, 7 },
--  text_extents = "<function 24>",
--  video_size = "<function 25>" -- https://aegi.vmoe.info/docs/3.0/Automation/Lua/Miscellaneous_APIs/
--}


    

-- == Aegisub / Automation / Lua / Progress reporting  ==
-- == https://aegi.vmoe.info/docs/3.0/Automation/Lua/Progress_reporting/ ==

--[[Debug output

The primary support for script debugging in Automation 4 Lua is through sending debug messages to the message log integrated in the progress window.

If a script shows a debug or other message, the progress window stays open after the script has finished running until the user clicks the Close button. Please consider whether it's really that important that the user sees your messages. Blocking other input to the program to display something that might be irrelevant to the user can create a bad experience.
		]]


--[[

		]]

--debug = setmetatable( debug , {} )

aegisub = {}
aegisub.version = "aegisubmock-lua"
aegisub.debug = {}

--[[
aegisub.debug.out

Synopsis:

    aegisub.debug.out(msg, ...)
    aegisub.debug.out(level, msg, ...)
    aegisub.log(msg, ...)
    aegisub.log(level, msg, ...)

The two names are synonymous; you can use either name depending on your preference.

Sends a message to the message log, optionally with a specific severity level. The user can control in Aegisub's options the highest level messages that will be shown.

level (number)
    Severity level of the message. This parameter is optional. If you leave it out (by entirely skipping it) the message will always be shown.

**'msg** (string) : A format string specifying the message. See the Lua standard string library string.format` function for details on format strings.

...
    Parameters to the format string.

The following severity levels are suggested:

0: "fatal"
    Something really bad happened and the script can't continue. Level 0 messages are always shown. Note that Aegisub does not automatically terminate your script. Call aegisub.cancel() afterwards if you want it to.
1: "error"
    A real error occurred so the user should expect something to have gone wrong even though you tried to recover. A fatal error might happen later.
2: "warning"
    It looks like something is wrong and the user ought to know because it might mean something needs to be fixed.
3: "hint"
    A tip or otherwise on how the user can improve things, or hints that something might cause a warning or error later on.
4: "debug"
    Information meant to help fix errors in the script, such as dumps of variable contents.
5: "trace"
    Extremely verbose information about what the script is doing, such as a message for each single step done with lots of variable dumps. 

		]]
aegisub.debug.out= function (msg) 
  print(msg)
end


aegisub.file_name=function ()
  return scriptname
end




--[[

		]]
    -- == Aegisub / Automation / Lua / Registration ==
-- == https://aegi.vmoe.info/docs/3.0/Automation/Lua/ ==

--[[A script can set a few global variables to provide metadata about the script to Aegisub. The information given with these variables are displayed in the Manager dialogue and the Script Info dialogue.

    script_name (string) - Name of the script. This should be short.
    script_description (string) - Description of the purpose of the script. Shouldn't be too long either.
    script_version (string or number) - Version number/name of the script. This is freeform; no specific meaning is assigned to this.
    script_author (string) - Author credits for the script.

All of these are optional; a script does not have to provide any of these. If no script name is given, the file name is used instead for display purposes.
]]

--[[Registration functions

The registration functions are the functions provided by Automation 4 Lua you can call to make a feature available to Aegisub. You will usually call these in the top level, at the very bottom of your script.
]]

--[[aegisub.register_macro

Synopsis: aegisub.register_macro(name, description, processing_function, validation_function)

Register a macro feature.

    name (string) - The name displayed on the Automation menu. This should be very short, try three words or less, and should be in command tense.
    description (string) - The description displayed on the status bar when the user hovers the mouse over the menu item. This should be a concise description of what the macro does. Try to keep it at most 60 characters.
    processing_function (function) - The function that is called when the user selects the menu item. This must be a function with the macro processing function API.
    validation_function (function, optional) - This function is called to determine whether the menu item should be available to the user or not. (Grayed out or not.) If no validation function is provided the macro is always available. This function must follow the macro validation function API.


		]]
aegisub.register_macro = function(name, description, processing_function, validation_function)
   scriptpath=aegisub.decode_path("?script")
   scriptname=aegisub.file_name()
   include("asstoolbox.lua")
   if(scriptname ~=nil) then
        subtitles=import_ass(scriptpath.."/"..scriptname)
    else
        --default ass
        subtitles=import_ass(scriptpath.."/".."Untitled.ass")
    end
    selected_lines={}
    active_line=-1
    processing_function(subtitles, selected_lines, active_line)
end
    
--[[aegisub.register_filter

Synopsis: aegisub.register_filter(name, description, priority, processing_function, configuration_panel_provider)

Register an export filter feature.

    name (string) - The name displayed in the export filters list. The name should be rather short.

    description (string) - The description displayed in the description box when the user highlights the export filter in the Export dialogue.

    priority (number) - Determines the initial ordering of export filter application. Filters with higher priority are applied earlier than filters with lower priority. The user can change the filter application order in the Export dialogue. Priorities of the Aegisub built in export filters:

    Transform Framerate = 1000 (karaoke effects should have higher priority than this)

    Clean Script Info = 0 (your script might depend on the information cleaned by this)

    Fix Styles = -5000 (should almost always run last)

    processing_function (function) - The function that is called when the user initiates the export operation. This must be a function with the export filter processing function API.

    configuration_panel_provider (function, optional) - A function that provides a configuration panel for the export filter. If this function is not provided the export filter will not have a configuration panel. This function must follow the export filter configuration panel provider API.


		]]
    
--[[Feature callback functions

These are the callback functions you provide to the registration functions.

		]]
    
--[[Macro processing function

Signature: process_macro(subtitles, selected_lines, active_line)

Macro processing functions passed to aegisub.register macro must have this signature. The name process_macro is a placeholder for your own function name.

    subtitles (user data) - The subtitles object you use to manipulate the subtitles with.
    selected_lines (table) - An array with indexes of the selected lines. The values in this table are line indexes in the subtitles object at its initial state. Only dialogue class lines can ever be selected.
    active_line (number) - The line that is currently available for editing in the subtitle editing area. This is an index into the subtitles object. This line will usually also be selected, but this is not a strict requirement.

Return value: The macro processing function can return up to two values: a new selected_lines table containing indices of the lines to select after the macro returns, and an index of the line to make the new active_line. If set, the new active line index must be one of the lines in the new selected_lines table.

		]]
    
--[[Macro validation function

Signature: validate_macro(subtitles, selected_lines, active_line)

Macro validation functions passed to aegisub.register macro must have this signature. The name validate_macro is a placeholder for your own function name.

Important, execution time: Validation functions should always run very fast. Do as little work as possible inside this function, because it is run every time the user pulls open the Automation menu, and every millisecond you spend in validate_macro is one millisecond delay in opening the menu. Consider that the user might have very large files open. Don't block the UI.

    subtitles (user data) - The subtitles object for the current subtitle file. This is read-only. You cannot modify the subtitles in the validation function, and attempting to do so will cause a run-time error.
    selected_lines (table) - An array with indexes of the selected lines. The values in this table are line indexes in the subtitles object at its initial state. Only dialogue class lines can ever be selected.
    active_line (number) - The line that is currently available for editing in the subtitle editing area. This is an index into the subtitles object.

Return value: Boolean, true if the macro can run given the current state of subtitles, selected_lines and active_line, false if it can not.

In addition to the primary return value, the validation function can return a string. If it does, the description of the macro is set to the string. This is intended for reporting information to the user about why the macro cannot be run, but there may be more uses for it.

		]]
    
--[[Export filter processing function

Signature: process_filter(subtitles, settings)

Export filter processing functions passed to aegisub.register filter must have this signature. The name process_filter is a placeholder for your own function name.

You do not have to worry about undo issues with export filters. You always work on a copy of the subtitle file.

    subtitles (user data) - The subtitles object you use to manipulate the subtitles with. This is a copy of the open subtitles file, so modifying this subtitles object does not modify the open file and will only affect the exported file.
    settings (table) - Configuration settings entered into the configuration panel or an empty table if there is no configuration panel. See the page on configuration dialogues for more information on the format of this table.

Return value: Nothing.

		]]

--[[Export filter configuration panel provider

Signature: get_filter_configuration_panel(subtitles, old_settings)

Export filter configuration panel providers passed to aegisub.register filter must have this signature. The name get_filter_configuration_panel is a placeholder for your own function name.

Important, execution time: This function is called automatically when the user opens the Export dialogue, and Aegisub blocks until it returns with a configuration panel. Consider that the user might have a very large file open, and that every millisecond spent creating your configuration dialogue is one more millisecond the user has to wait for the Export dialogue to open. Don't block the UI.

    subtitles (user data) - The subtitles object for the current subtitle file. This is read-only. You cannot modify the subtitles in the filter configuration provider. Attempting to modify the subtitles will cause a run-time error.
    old_settings (table) - Previous configuration settings entered into the configuration panel, if any. When an Automation 4 export filter is run, any configuration settings are automatically stored to the original file. If any stored settings exist for this filter, they are passed as old_settings so you can use them as a base for filling in defaults.

Return value: A configuration dialogue table. See the page on configuration dialogues for more information on the format of this table.

		]]



  -- ============================================================================================
  
--[[Dialogs

These functions are used to display dialogs for the user to interact with.
Display dialog functions

		]]
    
 aegisub.dialog={}   
    
  --[[
aegisub.dialog.display

Synopsis: button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

This function displays a configuration dialog to the user and waits for it to close. It then returns whether the user accepted or cancelled the dialog, and what values were input.

@dialog (table)
    A Dialog Definition table containing the controls to be in the dialog.
@buttons (table)
    Optional. This is an array of strings defining the buttons that appear in the dialog. If this is left out, empty or is otherwise not a table, the standard Ok and Cancel buttons appear. The strings in this table are used as labels on the buttons, and for identifying them in the return values of the function.
@button_ids (table)
    Optional. A table which specifies which buttons in the dialog correspond to which platform button IDs, making it possible to specify which button will be triggered if the user hits Enter or ESC.
button (boolean or string)
    If no custom buttons were specified, this is a boolean telling whether Ok (true) or Cancel (false) were clicked in the dialog. If custom buttons were specified, this is the text on the button clicked by the user. Even if custom buttons were specified, this can still be boolean false if the user closes the dialog without pressing any button.
result_table (table)
    The Dialog Result table corresponding to the values the user input in the dialog.

Example

config = {
    {class="label", text="Times to frobulate", x=0, y=0},
    {class="intedit", name="times", value=20, x=0, y=1}
}
btn, result = aegisub.dialog.display(config,
        {"Frobulate", "Nevermind"},
        {"ok"="Frobulate", "cancel"="Nevermind"})
if btn then
    frobulate(result.times)
end

		]]
    
  function aegisub.dialog.display(dialog, buttons, button_ids)
    
  end
     
     
  --[[
aegisub.dialog.open

Synopsis: file_name = aegisub.dialog.open(title, default_file, default_dir, wildcards, allow_multiple=false, must_exist=true)

Open a standard file open dialog to ask the user for a filename. Returns the path to the selected file(s), or nil if the user canceled.

@title (string)
    Title of the dialog
@default_file (string)
    Default filename to preselect. May be empty.
@default_dir (string)
    Initial directory to show in the open dialog. If empty, the last used directory is shown.
@wildcards (string)
    File filters to show. If empty, a sane default will be used. E.g. “All Files (.)|.|XYZ files (.xyz)|.xyz”
@allow_multiple (boolean)
    Let the user select multiple files. If this is true, a table of filenames will be returned rather than a single string, even if only one file is selected by the user.
@must_exist (boolean)
    Only let the user select files that actually exist.
file_name (nil, string, or table)
    nil if the user cancelled. A string containing the path to the selected file if allow_multiple is false, or a table containing the paths to all selected files if allow_multiple is true.

Example

filename = aegisub.dialog.open('Select file to read', '', '',
                               'Text files (.txt)|*.txt', false, true)
if not filename then aegisub.cancel() end

file = io.open(filename, 'rb')
....

		]]
function aegisub.dialog.open(title, default_file, default_dir, wildcards, ...)
  allow_multiple=false 
  must_exist=true
  return default_dir..aegisub.file_name()
end

  --[[
aegisub.dialog.save

Synopsis: file_name = aegisub.dialog.save(title, default_file, default_dir, wildcards, dont_prompt_for_overwrite=false)

Open a standard file save dialog to ask the user for a filename. Returns the path to the selected file, or nil if the user canceled.

@title (string)
    Title of the dialog
@default_file (string)
    Default filename to preselect. May be empty.
@default_dir (string)
    Initial directory to show in the open dialog. If empty, the last used directory is shown.
@wildcards (string)
    File filters to show. If empty, a sane default will be used. E.g. “All Files (.)|.|XYZ files (.xyz)|.xyz”
@dont_prompt_for_overwrite (boolean)
    Don’t ask the user to confirm that they wish to overwrite the file if they select a filename that already exists.
file_name (nilor string)
    nil if the user cancelled, and a string containing the path to the selected file otherwise.
		]]
    
function aegisub.dialog.save(title, default_file, default_dir, wildcards, ...)
  dont_prompt_for_overwrite=false

end


  -- ============================================================================================

--[[ == Aegisub / Automation / Lua / Miscellaneous APIs                    

This page documents miscellaneous APIs useful for working with subtitles. These can’t be clearly placed into any of the other main categories and there’s too few of each kind to warrant a separate category.]] 

--[[
aegisub.cancel

Synopsis: aegisub.cancel()

Immediately end execution of the current script, rolling back any changes that have been made in it.

This function never returns.
		]]
aegisub.cancel = function()

end

--[[

		]]


--[[
aegisub.text_extents

Synopsis: width, height, descent, ext_lead = aegisub.text_extents(style, text)

Obtain system font metrics and determine the rendered size in pixels of the given text when using the style.

@style (table)
    A style table as defined by the subtitle interface. The font name, size, weight, style, spacing and encoding is used to determine the size of the text.
@text (string)
    The text the extents should be determined for. This should not contain line breaks (\n or \r\n) nor should it contain formatting codes of any kind. Formatting codes are not interpreted and will be taken as verbatim text.
width (number)
    Width in pixels of text. This may be non-integer.
height (number)
    Height in pixels of the text. This may be non-integer.
descent (number)
    Length of descenders in the font. This may be non-integer.
ext_lead (number)
    External leading for the font. This may be non-integer.

You should only feed plain text strings without line breaks into this function. It cannot handle any kind of formatting codes or text layout. Rather, it is intended as a helper to create text layouts by determining rendered sizes of bits and pieces of a longer text, which can then be laid out by the script.
		]]
aegisub.text_extents = function(style, text)

end
    
    
--[[
aegisub.gettext

Synopsis: translation = aegisub.gettext(untranslated)

Get the translation for a string. This is mostly only intended for scripts bundled with Aegisub (as there's no way for you to add your own translations), but if you happen to be using strings that are present in Aegisub it may be useful.

Note that in the bundled macros this is always aliased to tr for the sake of the string extractor.
		]]


-- === Getting information on the video ===

--[[aegisub.frame_from_ms

Synopsis: frame = aegisub.frame_from_ms(ms)

Use loaded frame rate data to convert an absolute time given in milliseconds into a frame number.

@ms (number)
    Absolute time from the beginning of the video, for which to determine the frame number.
frame (number)
    Frame number corresponding to the time in ms, or nil if there is no frame rate data loaded.

If the time is in the middle of the frame it is "rounded down" to the frame number that contains the given time.

		]]
aegisub.frame_from_ms=function(ms)
  local frame=calc:eval(fps_ratio.." * "..tostring(ms) .." / 1000")     --(fps*ms)/1000
  frame=math.ceil(frame)                               
  if(DEBUG_CUE) then
    aegisub.debug.out("\naegisub_frame_from_ms("..tostring(ms)..") gives "..tostring(frame))
  end
  return frame
end
      
      
--[[
aegisub.ms_from_frame

Synopsis: ms = aegisub.ms_from_frame(frame)

Use loaded frame rate data to convert a frame number of the video into an absolute time in milliseconds.

@frame (number)
    Frame to obtain the beginning time of.
ms (number)
    First integer millisecond time stamp to lie within the frame, or nil if there is no frame rate data loaded.

Because beginning times of frames can have better precision than one millisecond this function rounds up and returns the first whole millisecond that is guaranteed to be within the frame.
		]]
aegisub.ms_from_frame = function(frame)
  local fps=aegisub.frame_from_ms(1000)
  --Fix local ms=aegisub.ms_from_frame(frame) that for frame 0 give -0.02!
  local ms=frame/fps
  if(DEBUG_CUE) then
    aegisub.debug.out("\naegisub_ms_from_frame("..tostring(frame)..") at "..fps.."fps gives "..tostring(ms))
  end
  return ms
end
    
--[[
aegisub.video_size

Synopsis: xres, yres, ar, artype = aegisub.video_size()

Get information about the resolution and aspect-ratio of the loaded video, if any.

xres (number)
    Coded width of the video in pixels, or nil if there is no video loaded.
yres (number)
    Coded height of the video in pixels, or nil if there is no video loaded.
ar (number)
    Custom display aspect ratio override. Meaningless unless artype is 4.
artype (number)

    There are 5 values that artype can take:

        0: The video has square pixels, i.e. PAR is 1.00 and DAR is xres/yres.
        1: The video is 4:3, i.e. DAR is 1.33.
        2: The video is 16:9, i.e. DAR is 1.78.
        3: The video is 2.35 format, i.e. DAR is 2.35.
        4: The DAR is whatever the ar return value contains.



		]]
aegisub.video_size= function()
  xres=0
  yres=0
  ar=0
  artype=0
  return xres, yres, ar, artype
end
    
--[[aegisub.keyframes

Synopsis keyframes = aegisub.keyframes()

Get a list of what video frames are keyframes.

keyframes (table)
    A sorted table where each entry is the frame number of a keyframe. If no keyframe data is loaded, the table will be empty. 

		]]
    
--[[aegisub.decode_path

Synopsis path = aegisub.decode_path(encoded_path)

Convert a path beginning with a path specifier to an absolute path.

@encoded_path (string)
    A string which may optionally begin with an Aegisub path specifier.
@path (string)
    If encoded_path began with a valid path specifier, an absolute path. If it began with an invalid path specifier (such as if ?video was used when no video is open), a string that is unlikely to be useful in any way. Any other strings are passed through untouched. 

		]]
function aegisub.decode_path(encoded_path)

    local BinaryFormat = package.cpath:match("[.](%a+)$")
    local user_dir

     if isWindows and BinaryFormat == "dll" then 
        osname = "Windows" 
        appdata = os.getenv('appdata')
        user_dir= appdata.."\\Aegisub"
     end 
      
    local isLinux=(BinaryFormat == "so")
    if isLinux then
        osname = "Unix"
        home = os.getenv('HOME')
        user_dir= home.."/.aegisub"
    end
    
    local isMax=(BinaryFormat == "dylib")
    if isMac then
        osname = "Macintosh"
        home = os.getenv('HOME')
        user_dir= home.."/Library/Application Support/Aegisub"
    end
    BinaryFormat = nil
    
    local autoload_dir = user_dir.."/automation/autoload"

     -- https://aegisub.org/docs/latest/aegisub_path_specifiers/
   encoded_path=string.gsub(encoded_path, "?script", autoload_dir)
   encoded_path=string.gsub(encoded_path, "?data", "\\usr\\share\\aegisub")
   encoded_path=string.gsub(encoded_path, "?user",  user_dir)
   encoded_path=string.gsub(encoded_path, "\\","/") 
  return encoded_path
end

--[[
aegisub.project_properties

Synopsis properties = aegisub.project_properties()

Get a table containing information about what files the user currently has open. The exact contents of this table are deliberately undocumented, and may change without warning.
		]]
    
aegisub.project_properties = function() 
    project={}
    project.video_file = video_file
    project.audio_file = audio_file
    return project
end
    
  -- ============================================================================================
  
--[[

		]]
    
    
--[[

		]]
aegisub = setmetatable(aegisub, {})

 --Register macro (no validation function required)


--vid_x,vid_y=aegisub.video_size()
--Progress report
--aegisub.progress.task("Processing line "..si.."/"..#sel)
--aegisub.progress.set(100*si/#sel)
--Registration
--aegisub.set_undo_point(script_name)
--aegisub.register_macro(script_name,script_description,script_handler)
--local project=aegisub.project_properties()
--local video_file=project.video_file



--[[ rPrint(struct, [limit], [indent])   Recursively print arbitrary data. 
	Set limit (default 100) to stanch infinite loops.
	Indents tables as [KEY] VALUE, nested tables as [KEY] [KEY]...[KEY] VALUE
	Set indent ("") to prefix each line:    Mytable [KEY] [KEY]...[KEY] VALUE
--]]
function rPrint(s, l, i) -- recursive Print (structure, limit, indent)
	l = (l) or 1000; i = i or "";	-- default item limit, indent string
	if (l<1) then aegisub.debug.out(tostring("ERROR: Item limit reached.")); return l-1 end;
	local ts = type(s);
	if (ts ~= "table") then  aegisub.debug.out(tostring(i)..","..tostring(ts)..","..tostring(s)); return l-1 end
	aegisub.debug.out(tostring(i)..","..tostring(ts));           -- print "table"
	for k,v in pairs(s) do  -- print "[KEY] VALUE"
		l = rPrint(v, l, i.."\t["..tostring(k).."]");
		if (l < 0) then break end
	end
	return l
end	


function ptab ( tabx )
    if type ( tabx ) == "table" then
        for ii = 1, #tabx do
            if type ( tabx [ ii ] ) ~= "table" then
                print ( "entry " 
                            .. ii .. 
                        ", type = " 
                            .. type ( tabx [ ii ] ) .. 
                        ", value = "
                            .. tostring ( tabx [ ii ] )
                      )
            else
                print ( "entry " .. ii .. " is a table" )
                ptab ( tabx [ ii ] ) 
                print ( "end of entry " .. ii )
            end
        end
    end
end

--split a string using separator
--function mysplit(inputstr, sep)
--  if sep == nil then
--    sep = "%s"
--  end
--  local t = {}
--  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
--    table.insert(t, str)
--  end
--  return t
--end

function apply_filter_line(no,text) 
		chunks=mysplit(text, " ",10)
		ptab (chunks)
		section= tostring(chunks[1])
		text=section
		return text
end




-- Original script from https://github.com/daxliar/submerger
--9.08.2019 - set_basetime support added by Oli

-- Default colors to use when writing the merged values
-- they have to be valid html color codes as used inside the <font> tag
local default_color_a = "white"
local default_color_b = "yellow"

-- Utility to covert from a srt timestamp in the format "00:00:00,000" to a number
function str_timestamp_to_seconds( timestamp )
  hours, minutes, seconds, milliseconds = string.match( timestamp, "(%d+):(%d+):(%d+),(%d+)")
  hours = tonumber(hours) * 3600
  minutes = tonumber(minutes) * 60
  seconds = tonumber(seconds)
  milliseconds = tonumber(milliseconds) * 0.001
  return hours + minutes + seconds + milliseconds
end

-- Utility to covert from a number in seconds to an srt timestamp in the format "00:00:00,000"
function seconds_to_str_timestamp( seconds )
  local total_seconds, fractinal_part = math.modf( tonumber(seconds) )
  local total_hours = math.floor(total_seconds / 3600)
  local total_minutes = math.floor(total_seconds / 60) % 60
  total_seconds = total_seconds % 60
  return string.format("%02.f:%02.f:%02.f,%03.f", total_hours, total_minutes, total_seconds, fractinal_part * 1000 )
end

-- Tiny utility function to trim a string
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- This function checks if a given line contains the string what
--
-- @param line The line of text to use
-- @param what The needle to look
-- @return boolean True if the line contains the string, false otherwise
function has_string(line, what)
  -- Use string.find to check if the string "[V4 Styles]" exists in the line
  return string.find(line, what) ~= nil
end



-- Generate an subtitle entry matching aegisub table
--[1],table
--	[1]	[layer],number,1
--	[1]	[margin_l],number,0
--	[1]	[margin_r],number,0
--	[1]	[margin_t],number,0
--	[1]	[margin_b],number,0
--	[1]	[raw],string,Dialogue: 1,0:00:00.00,0:00:18.17,document,,0,0,0,,9_0 - Nine Commentaries Pt 9 - On the Unscupulous Nature\Nof the Chinese Communist Party
--	[1]	[style],string,document
--	[1]	[comment],boolean,false
--	[1]	[actor],string,
--	[1]	[effect],string,
--	[1]	[extra],table
--	[1]	[section],string,[Events]
--	[1]	[class],string,dialogue
--	[1]	[end_ffmpeg],string,00:00:18,167
--	[1]	[start_time],number,0
--	[1]	[start_ffmpeg],string,00:00:00,000
--	[1]	[start_frame],number,0
--	[1]	[end_frame],number,545
--	[1]	[end_time],number,18170
--	[1]	[text],string,9_0 - Nine Commentaries Pt 9 - On the Unscupulous Nature\Nof the Chinese Communist Party
function generate_entry( in_start_time, in_end_time, in_text )
  
  --local insert_start_time = 0
  --local insert_end_time = 0
  --if type(in_start_time) == "number" then
  --  insert_start_time = in_start_time
  --else
  --  insert_start_time = str_timestamp_to_seconds(in_start_time)
  --end
  --if type(in_end_time) == "number" then
  --  insert_end_time = in_end_time
  --else
  --  insert_end_time = str_timestamp_to_seconds(in_end_time)
  --end
  --return { start_time=insert_start_time, end_time=insert_end_time, text=in_text, translated={} }
end


local inspect = require('inspect')

--[[function aegisub.open()
    scriptpath=aegisub.decode_path("?script")
    scriptname=aegisub.file_name()
    filename=scriptname:gsub("%.%w+$",".time")

	  write_timings(scriptpath.."/"..filename, subs )
    file_name="Pt9.ass"
      
      aegisub.debug.out(inspect(me))
      return sub
    --end
    
 end]]
 
--ass=import_ass()


function get_fps(video_file)
  
  --local video_file = aegisub.project_properties().video_file
  local result
  local command = format_python_command(
    video_file
  )

  --- check directory path via command line
  local check_directory_path_handle = io.popen('cd')
  if check_directory_path_handle ~= nil then
    result = check_directory_path_handle:read('*a')
    check_directory_path_handle:close()
    --aegisub.log('directory: ' .. result .. '\n') --- find the directory
  end

  --aegisub.log('command: ' .. command .. '\n') --- copy this when debugging the Python script
  local run_python_handle = io.popen(command)
  if run_python_handle ~= nil then
    result = run_python_handle:read('*a')
    run_python_handle:close()
    --aegisub.log('result: ' .. result .. '\n')
  end

  local n= #result-2
  result=string.sub(result,2,n) -- washes [ and ]\n
  result=string.gsub(result, ", ", " / ")
  return result
end


function format_python_command(
  absolute_filepath_to_source_video
)

	if wx ~= nil then
	
    osname = wx.wxPlatformInfo.Get():GetOperatingSystemFamilyName()
	   
	else

		local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
		 local isWindows = os.getenv('WINDIR') or (os.getenv('OS') or ''):match('[Ww]indows')
		 if isWindows and BinaryFormat == "dll" then 
			osname = "Windows" 
		 end 
		  
		local isLinux=(BinaryFormat == "so")
		if isLinux then
			osname = "Unix"
		end
		
		local isMax=(BinaryFormat == "dylib")
		if isMac then
			osname = "Macintosh"
		end
		BinaryFormat = nil
	end

	 if osname == "Windows" then 
		appdata = os.getenv('appdata')
		autoload_dir= appdata.."\\Aegisub"
	 end
	 
	 if osname == "Unix" then
	 
    local inspect = require('inspect')
		--aegisub.log(inspect(os))
		home = os.getenv('HOME')
		autoload_dir= home.."/.aegisub"
	 end

	if osname == "Macintosh" then
		home = os.getenv('HOME')
		autoload_dir= home.."/Library/Application Support/Aegisub"
	end

  return 'python '..autoload_dir..'/automation/autoload/get_fps.py'
    .. ' ' .. absolute_filepath_to_source_video
end


return aegisub
