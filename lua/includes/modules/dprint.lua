--[[LICENSE:
_p_modules\lua\includes\modules\dprint.luasrc

Copyright 08/24/2014 thelastpenguin
]]
local col_grey = Color(100,100,100);
local HSVToColor = HSVToColor ;
local incr = SERVER and 72 or 0;
local fileColors = {};
local fileAbbrev = {};
local MsgC , print = _G.MsgC , _G.print

-- auto benchmark
function dprint(...)
	local info = debug.getinfo(2)
	local fname = info.short_src;
	if fileAbbrev[fname] then
		fname = fileAbbrev[fname];
	else
		local oldfname = fname;
		fname = string.Explode('/', fname);
		fname = fname[#fname];
		fileAbbrev[oldfname] = fname;
	end
	
	if not fileColors[fname] then
		incr = incr + 1;
		fileColors[fname] = HSVToColor(incr * 100 % 255, 1, 1)
	end
	
	MsgC(fileColors[fname], fname..':'..info.linedefined);
	print( '  ', ... )
end

local last;
function dbench_start()
	last = os.clock();
end
function dbench_print()
	print('[benchmark] '..(os.clock()-last));
end

function fdebug(name)
	local col = Color(math.random(1,255), math.random(1,255), math.random(1, 255));
	return function(...)
		MsgC(col, name .. ' - ');
		dprint(...);
	end
end