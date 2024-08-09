--#! /usr/bin/env lua

-- Default colors to use when writing the merged values
-- they have to be valid html color codes as used inside the <font> tag
local default_color_a = "white"
local default_color_b = "yellow"

-- A function to clean up ASS tags in a line
--include("cleantags.lua")

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

-- Generate an subtitle entry with line text
function generate_ass_entry(in_text )
  return string2line(in_text)
end


-- Generate an subtitle entry with times and text. Trnslated inserted to be used later on
-- It takes timestamps in both formats
--[[ 
   function generate_ass_entry( in_start_time, in_end_time, in_text )
  local insert_start_time = 0
  local insert_end_time = 0
  if type(in_start_time) == "number" then
    insert_start_time = in_start_time
  else
    insert_start_time = str_timestamp_to_seconds(in_start_time)
  end
  if type(in_end_time) == "number" then
    insert_end_time = in_end_time
  else
    insert_end_time = str_timestamp_to_seconds(in_end_time)
  end
  return { start_time=insert_start_time, end_time=insert_end_time, text=in_text, translated={} }
end
]]

-- adapted from https://stackoverflow.com/questions/19907916/split-a-string-using-string-gmatch-in-lua
function mysplit(sep, inputstr, limit,trimvalues)

  if sep == nil then
          sep = "%s"
  end
  local t={}

	local s = inputstr
	if s == nil then
		s =""
	end
  
  if limit == nil then
    limit=40
  end

        --for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	for str in (s .. sep):gmatch("([^"..sep.."]*)"..sep) do 
		if(trimvalues) then
			str=trim(str)
		end
		 aegisub.debug.out("( "..str..")")
		if(limit >0) then
	                table.insert(t, str)
			limit=limit-1;
		end
        end
        return t
end

function count(table_cols)

	return table.getn(table_cols)

end

-- USAGE:
-- string.strpos("mystring", "my")
do
	local function regexEscape(str)
		return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
	end
	-- you can use return and set your own name if you do require() or dofile()
	
	-- like this: str_replace = require("string-replace")
	-- return function (str, this, that) -- modify the line below for the above to work
	string.replace = function (str, this, that)
		return str:gsub(regexEscape(this), that:gsub("%%", "%%%%")) -- only % needs to be escaped for 'that'
	end


  string.starts_with = function(str, start)
    return str:sub(1, #start) == start
  end


	--string.contains("mystring", "my")
	string.contains = function(str,this)
		 s=regexEscape(this)
		 test=str:match(s)
		 aegisub.debug.out("##"..s.."##"..tostring(test))
		 return test
	end
end


function setContains(set, key)
    return set[key] ~= nil
end

function hasprop(line,prop) 
	return (setContains(line,prop))
end



--[[
function video_file()
    --return ass.script_info.get('Video File').value
    return aegisub.project_properties.video_file
end
]]

-- This function should be called before seconds_to_str_timestamp/ str_timestamp_to_seconds
function set_basetime(srt) 
	local basetime=1 -- Normaly basetime for srt is the second
	if(#srt) then
	   line=srt[1]
	   if(hasprop(line,"layer")) then --but for the line object of a selected line in aegisub
		basetime=1000    --times are in ms so we have to adjust basetime
	   end
	end
       return basetime
end


-- Main loop to open an ASS file and return a table with all the elements from the file
-- generate_entry is used for every block created
function import_ass( filename )
  local srts = {}
  local file,error = io.open(filename, "r")
  if not error then

    local open_comment=false
    video_file=""
    audio_file=""
    
    --Affiche toutes les lignes avec les numeros de ligne			
    local buffer_script={}
    local buffer_styles={}
    local buffer_subs={}


    local line_type = "script"
    local last_index = -1
    local current_text = ""
    local current_index = 0
    
    local current_start_time = nil
    local current_end_time = nil
    while true do
      local line = file:read()
      if line == nil then
        break
      end
      local line_num=current_index+1

      aegisub.debug.out("\n[ANALYSING "..tostring(line_num).." ]") --":"..line..

      if(line ~= "") then	

        parsed_line= mysplit (",", line, 10,true)
        -- aegisub.debug.out(tostring())
        tokens_count=count(parsed_line) 
        if((tokens_count== 10) and (line_type=='subs'))  then

        --if((strpos($line, 'Format:') === false)) {
          if(not string.contains(line,'Format:')) then
           --if((strpos($line, 'Dialogue:') === false)) {
          if(not string.contains(line,'Dialogue:')) then
            if(trim(line) == '') then
              table.insert(buffer_subs,"")
            else 
              aegisub.debug.out("SUB: Error(Invalid def):"..line.."\n")
            end
          else 
            --list($Format,$Start,$End,$Style,$Name,$MarginL,$MarginR,$MarginV,$Effect,$Text)=$parsed_line;
            Format,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text = parsed_line[1],parsed_line[2],parsed_line[3],parsed_line[4],parsed_line[5],parsed_line[6],parsed_line[7],parsed_line[8],parsed_line[9],parsed_line[10]

            --parsed_Text=split ($this->sep, $Text, $nb_lang+1); //Voici le separateur /// entre les differentes langues
            --nb_elem=count(parsed_Text);
            --if(nb_elem ==nb_lang+1)) { // le perso compte en plus

            --sr='list($Perso,'.$this->map.')=$parsed_Text;';
            --echo "<font color='green'>Sub Ok </font>:\n";
            --eval(sr); //le mapping doit prendre en compte le perso

            --$Style=trim($Perso);

            --$Style_def="Style: $Style,MachineScript,24,16777215,4194368,4194368,12632256,-1,0,1,1,1,6,30,30,10,0,0"; //dummy style à adapter apres
            --if(!in_array($Style_def,$buffer_styles)){
            --	table.insert(buffer_styles,Style_def)
            --}

            --$Text_Sub=trim("${$this->lang}");
            --Sub= "$Format,$Start,$End,$Style,$Name,$MarginL,$MarginR,$MarginV,$Effect,$Text_Sub";
            Sub=string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",Format,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text)

            --else 
            --	echo "<font color='red'>SUB Warning (Incomplete def):"..line.."</font><br>";
            --	Sub=line;
            --end
          end
        else 
          Sub=line
        end
      else
        if(line_type=='script') then
			--if(!(strpos(line,'[V4 Styles]') === false)) then
          if not string.starts_with(line, ";") then
            if(string.contains(line,":")) then
              param = mysplit (":", line, 2,true)
              aegisub.debug.out(param)
              param_name=trim(param[1])
              param_value=trim(param[2])
              if(param_name == "Video File") then
                video_file=param_value
                fps_ratio=get_fps(scriptpath.."/"..video_file)
              end
              if(param_name == "Audio File") then
                audio_file=param_value
              end
            end
          end
          if(string.contains(line,"[V4 Styles]")) then
            line_type='styles'
            aegisub.debug.out("\n!YES4:"..line.."!")
          elseif(string.contains(line,"[V4+ Styles]")) then
            line_type='styles'
            aegisub.debug.out("\n!YES4+:"..line.."!")
          else
            aegisub.debug.out("\n!NO:"..line.."!")
          end
          Sub=line
      
        elseif(line_type=='styles') then
          if(string.contains(line, '[Events]')) then
            line_type='subs'
          end
          Sub=line         
        elseif(line_type=='subs') then
          Sub=''
          aegisub.debug.out("SUB: Warning(line ignored):"..line.."\n")
        end
      end
      aegisub.debug.out("\n=>#"..line_type.."#: "..Sub.."\n")
      Sub=trim(Sub)
      if (Sub ~= "") then
        if(line_type == 'script') then
          table.insert(buffer_script,Sub)
        elseif(line_type=='styles') then
          table.insert(buffer_styles,Sub)
        elseif(line_type=='subs') then
          table.insert(buffer_subs,Sub)
        else
          --default:
      end
    end
  else
    aegisub.debug.out("EMPTY LINE")
  end
  --aegisub.debug.out(tostring(parse_line))
  if line_type == "subs" then
    if not(string.contains(line, '[Events]')) and not (string.contains(line, 'Format:')) then
      table.insert(srts, generate_ass_entry(line))
    end
  end
      
      -- first read the index
      --[[
      if line_type == "index" then
          last_index = current_index
          trimmed_line = trim(line)
          current_index = tonumber(trimmed_line)
          line_type = "time"
          current_text = ""
      -- then get the time interval
      elseif line_type == "time" then
        current_start_time, current_end_time = string.match( line, "(%d+:%d+:%d+,%d+) --.* (%d+:%d+:%d+,%d+)")
        line_type = "text"
      -- and finally get all the lines of text
      elseif line_type == "text" then
        -- until we get an empty line, in this case we restart
        local trimmed_text = trim(string.gsub(line, "\n", ""))
        if trimmed_text == "" then
          line_type = "index"
          --table.insert(srts, generate_ass_entry(current_start_time, current_end_time, current_text ) )
          generate_ass_entry(line)
        else
          if current_text == "" then
            current_text = trimmed_text
          else
            current_text = current_text .. " " .. trimmed_text
          end
        end
       
      end 
      
      
      ]]
      
      current_index=current_index+1
    end
    file:close()
    print("Imported " .. tostring(#srts) .. " blocks from \"" .. tostring(filename) .. "\"")
  else
    print("Error: Can't import file \"" .. tostring(filename) .. "\" for writing!")
  end
  return srts
end

-- STUFF from https://unanimated.github.io/ts/luapaste.htm


-- add tag to the end of the initial block of tags	tag should be backslash+type+value, eg "\\blur0.6"
-- use:   text=addtag("\\blur0.6",text)

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

-- convert a "Dialogue: 0,0:00..." string to a "line" table	(uses string2time below)

function string2line(str)
		local ltype,layer,s_time,e_time,style,actor,margl,margr,margv,eff,txt=str:match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
		l2={}
		l2.class="dialogue"
		if ltype=="Comment" then l2.comment=true else l2.comment=false end
		l2.layer=layer
		l2.start_time=string2time(s_time)
		l2.end_time=string2time(e_time)
		l2.style=style
		l2.actor=actor
		l2.margin_l=margl
		l2.margin_r=margr
		l2.margin_t=margv
		l2.effect=eff
		l2.text=txt
	return l2
end


-- convert a line to a "Dialogue: 0,0:00..." string	(uses time2string below)	(apparently useless because: line.raw)

function line2string(lain)
	if lain.comment==false then ltype="Dialogue: " else ltype="Comment: " end
	layer=lain.layer..","
	s_time=lain.start_time
	e_time=lain.end_time
	s_time=time2string(s_time)
	e_time=time2string(e_time)
	style=lain.style..","
	actor=lain.actor..","
	margl=lain.margin_l..","
	margr=lain.margin_r..","
	margv=lain.margin_t..","
	effect=lain.effect..","
	txt=lain.text
	linetext=ltype..layer..s_time..","..e_time..","..style..actor..margl..margr..margv..effect..txt
	return linetext
end


-- convert string timecode to time in ms (and vice versa)

function string2time(timecode)
	timecode=timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)",function(a,b,c,d) return d*10+c*1000+b*60000+a*3600000 end)
	return timecode
end

function time2string(num)
	timecode=math.floor(num/1000)
	tc0=math.floor(timecode/3600)
	tc1=math.floor(timecode/60)
	tc2=timecode%60+1
	numstr="00"..num
	tc3=numstr:match("(%d%d)%d$")
	if tc1==60 then tc1=0 tc0=tc0+1 end
	if tc2==60 then tc2=0 tc1=tc1+1 end
	if tc1<10 then tc1="0"..tc1 end
	if tc2<10 then tc2="0"..tc2 end
	tc0=tostring(tc0)
	tc1=tostring(tc1)
	tc2=tostring(tc2)
	timestring=tc0..":"..tc1..":"..tc2.."."..tc3
	return timestring
end


-- check style values (instead of using karaskel)	
-- use: styleref=stylechk(subs,line.style)

function stylechk(subs,stylename)
  for i=1, #subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if stylename==st.name then styleref=st end
    end
  end
  return styleref
end


function export_data_ass(subs)

	local line, index, lines_index
        lines_index ={}
	
	local line_break     = ""
	local content        = {
		info          = {},
		styles        = {},
		lines         = {},
		styles_format = "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
		events_format = "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
	}

     
	--local meta       = karaskel.collect_head(subs)
	--local width      = meta.res_x
	--local height     = meta.res_y


	for i = 1, #subs do
	
		index = i
		line  = subs[index]
		if line.class == "dialogue" then
			table.insert(lines_index,index)
		else
			if line.class == "info" then
				table.insert(content.info, line_break..line.raw)
			elseif line.class == "style" then
				table.insert(content.styles, line_break..line.raw)
			end
			line_break = "\n"
		end
	end
	line_break = ""

	for i = 1, #lines_index do
		index  = lines_index[i]
		line   = subs[index]
		table.insert(content.lines, line) --We will postpone conversion to line.raw because we need preprocessing 
		line_break = "\n"
	end

	return content
end

function asscontent2string(content) 
	return string.format("[Script Info]\n%s\n\n[V4+ Styles]\n%s%s\n\n[Events]\n%s\n%s", table.concat(content.info), content.styles_format, table.concat(content.styles), content.events_format, table.concat(content.lines))
end

-- Writes ass data to a file
function write_ass( filename, srt , subtitles)
  if srt ~= nil then

   --content hold info and styles we will reuse
   content=export_data_ass(subtitles)

    local file = io.open(filename, "w")

    if file ~= nil then

       -- but text and times is in ass lines
        i=1
        line_break = ""

        for k,v in pairs(srt) do
	  
          line=content.lines[i]

	  line.text= v["text"]
	  --line.start_time=v["start_time"]
	  --line.end_time=v["end_time"]

           content.lines[i]=line_break..line.raw
	   line_break = "\n"

           i=i+1
        end

        if #content.lines > 0 then
		file:write(asscontent2string(content))
	else
		return nil
	end
      file:close()
      print("Written " .. tostring(#srt) .. " blocks to \"" .. tostring(filename) .. "\"")
    else
      print("Error: Can't open file \"" .. tostring(filename) .. "\" for writing!")
    end
  else
    print("Error: Nothing to write in the output srt file!")
  end
end





-- Check if running as library or as a program
--if pcall(debug.getlocal, 4, 1) then
--  print("You are using " .. arg[0] .. " as a library")
--else
--  local num_args = #arg
--  if num_args >= 3 or num_args <= 5 then
--
--    default_color_a = arg[4] or default_color_a
--    default_color_b = arg[5] or default_color_b
--
--    write_srt( arg[3], merge_srts( import_srt(arg[1]), import_srt(arg[2]) ) )
--  else
--    print( "Usage: " .. arg[0] .. " <input srt file 1> <input srt file 2> <output srt file> [html color code 1] [html color code 2]")
--  end
--end
