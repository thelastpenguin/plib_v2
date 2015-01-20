--[[
LICENSE:
_p_modules\lua\includes\modules\xfn.luasrc

Copyright 08/24/2014 thelastpenguin
]]
xfn = {};
local xfn = xfn;
local pairs , ipairs , unpack = pairs , ipairs , unpack ;

function xfn.filter( tbl, func )
	local ir, iw = 1, 1;
	local v ;
	while( tbl[ir] )do
		v = tbl[ir];
		if( func( v ) )then
			tbl[iw] = v;
			iw = iw + 1;
		end
		ir = ir + 1;
	end
	while( iw < ir )do
		tbl[iw] = nil;
		iw = iw + 1;
	end
	return tbl;
end

function xfn.filterStack(...)
  local helper = function(a, ...)
    if fn(a) then
      return a, helper(...)
    else
      return helper(...)
    end
  end
  return helper(...)
end

function xfn.unique( tbl )
	local cache = {};
	return xfn.filter(tbl, function(el)
		if cache[el] then
			return false;
		else
			cache[el] = true;
			return true;
		end
	end);
end

function xfn.forEach( tbl, func )
	for k,v in pairs( tbl )do
		func( v, k );
	end
end

function xfn.map( tbl, func )
	for k,v in pairs( tbl )do
		tbl[k] = func( v, k );
	end
	return tbl;
end

function xfn.nothing() end
xfn.noop = xfn.nothing;

function xfn.fn_forEach( func )
	return function( tbl )
		for k,v in pairs(tbl)do
			func( v, k );
		end
	end
end

function xfn.fn_deafen( func )
	return function() func() end
end

xfn.table = {}
function xfn.table.inherit(parent, new) 
	setmetatable({}, {
		__index = parent
	})
end

function xfn.table.inheritCopy(parent, new) 
	for k,v in pairs(parent)do
		if not new[k] then
			new[k] = v
		end
	end
end

function xfn.table.indexOf(tbl, value)
	for k,v in pairs(tbl)do
		if v == value then
			return k
		end
	end
end

function xfn.fn_const(val)
	return function()
		return val
	end
end