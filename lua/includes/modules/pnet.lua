if SERVER then
	AddCSLuaFile()
end

require 'pnet_player'

--TYPE_END = 0x00
--TYPE_POINTER = 0x01
--TYPE_ARRAY = 0x02 -- simple array
--TYPE_ASSOC = 0x03 -- associative array
--TYPE_TABLE = 0x04 -- simple array followed by associative
--TYPE_STRING = 0x05
--TYPE_NEGATIVE = 0x06
--TYPE_USHORT = 0x07
--TYPE_UINT = 0x08
--TYPE_DOUBLE = 0x09
--TYPE_BOOLEAN_TRUE = 0x0A
--TYPE_BOOLEAN_FALSE = 0x0B
--TYPE_VECTOR = 0x0C
--TYPE_ANGLE = 0x0D
--TYPE_ENTITY = 0x0E
--TYPE_NIL = 0x0F

do
	local type, count = type, table.Count ;
	local encode = {};
	
	local cacheSize = 0;

	local net_WriteInt, net_WriteUInt = net.WriteInt, net.WriteUInt ;
	local net_WriteFloat, net_WriteDouble = net.WriteFloat, net.WriteDouble ;
	local net_WriteString = net.WriteString ;

	
	encode['table'] = function( self, tbl, cache )
		
		if( cache[ tbl ] )then
			net_WriteUInt(0x01 --[[TYPE_POINTER]], 8); -- 0x01 --[[TYPE_POINTER]]
			net_WriteUInt(cache[tbl], 32);
			return ;
		else
			cacheSize = cacheSize + 1;
			cache[ tbl ] = cacheSize;
		end

		-- CALCULATE COMPONENT SIZES
		local nSize = #tbl;
		local kvSize = count( tbl ) - nSize;
		
		-- write the type
		net_WriteUInt(
				nSize > 0 and (kvSize == 0 and 0x02 --[[TYPE_ARRAY]] or 0x04 --[[TYPE_TABLE]]) or 0x03 --[[TYPE_ASSOC]],
			8 );

		if nSize > 0 then
			for i = 1, nSize do
				local v = tbl[ i ];
				if not v then continue end
				local tv = type( v );
				-- HANDLE POINTERS
				if( tv == 'string' )then
					local pid = cache[ v ];
					if( pid )then
						net_WriteUInt(0x01 --[[TYPE_POINTER]], 8) -- 0x01 --[[TYPE_POINTER]]
						net_WriteUInt(pid, 32);
					else
						cacheSize = cacheSize + 1;
						cache[ v ] = cacheSize;
						
						self.string( self, v, output, cache );
					end
				else
					self[ tv ]( self, v, output, cache );
				end
			end

			-- end this block of data
			net_WriteUInt(0x00 --[[TYPE_END]], 8);

			-- if no key value pairs segment we're done so we can just return
			if kvSize == 0 then
				return ;
			end
		end
		
		-- taken care of by if kvSize == 0 then return end above
		-- if( kvSize > 0 )then -- no longer needed.
			for k,v in next, tbl do
				if( type( k ) ~= 'number' or k < 1 or k > nSize )then
					local tk, tv = type( k ), type( v );
					
					-- THE KEY
					if( tk == 'string' )then
						local pid = cache[ k ];
						if( pid )then
							net_WriteUInt(0x01 --[[TYPE_POINTER]], 8);
							net_WriteUInt(pid, 32);
						else
							cacheSize = cacheSize + 1;
							cache[ k ] = cacheSize;
							
							self.string( self, k, output, cache );
						end
					else
						self[ tk ]( self, k, output, cache );
					end
					
					-- THE VALUE
					if( tv == 'string' )then
						local pid = cache[ v ];
						if( pid )then
							net_WriteUInt(0x01 --[[TYPE_POINTER]], 8);
							net_WriteUInt(pid, 32);
						else
							cacheSize = cacheSize + 1;
							cache[ v ] = cacheSize;
							
							self.string( self, v, output, cache );
						end
					else
						self[ tv ]( self, v, output, cache );
					end
					
				end
			end
		-- end

		net_WriteUInt(0x00 --[[TYPE_END]], 8);
	end
	--    ENCODE STRING
	local gsub = string.gsub ;
	encode['string'] = function( self, str, output )
		net_WriteUInt(0x05 --[[TYPE_STRING]], 8);
		net_WriteString(str);
	end

	encode['number'] = function(self, num)
		if num % 1 == 0 then
			if num < 0 then
				net_WriteUInt(0x06 --[[TYPE_NEGATIVE]], 8); -- 0x06 --[[TYPE_NEGATIVE]]
				net_WriteInt(num, 32);
			else
				if num < 65536 then
					net_WriteUInt(0x07 --[[TYPE_USHORT]], 8)
					net_WriteUInt(num, 16);
				else
					net_WriteUInt(0x08 --[[TYPE_UINT]], 8);
					net_WriteUInt(num, 32);
				end
			end
		else
			net_WriteUInt(0x09 --[[TYPE_DOUBLE]], 8);
			net_WriteDouble(num);
		end
	end

	--    ENCODE BOOLEAN
	encode['boolean'] = function(self, val)
		if val then
			net_WriteUInt(0x0A --[[TYPE_BOOLEAN_TRUE]], 8); -- 0x0A --[[TYPE_BOOLEAN_TRUE]]
		else
			net_WriteUInt(0x0B --[[TYPE_BOOLEAN_FALSE]], 8); -- 0x0B --[[TYPE_BOOLEAN_FALSE]]
		end
	end
	--    ENCODE VECTOR
	encode['Vector'] = function( self, val )
		net_WriteUInt(0x0C --[[TYPE_VECTOR]], 8);
		net_WriteFloat(val.x);
		net_WriteFloat(val.y);
		net_WriteFloat(val.z);
	end
	--    ENCODE ANGLE
	encode['Angle'] = function( self, val )
		net_WriteUInt(0x0D --[[TYPE_ANGLE]], 8);
		net_WriteFloat(val.p);
		net_WriteFloat(val.y);
		net_WriteFloat(val.r);
	end
	encode['Entity'] = function( self, val )
		net_WriteUInt(0x0E --[[TYPE_ENTITY]], 8);
		net_WriteUInt(IsValid(val) and val:EntIndex() or 0xFFFF); -- largest uint we can send, ent indexes will never hit this.
	end
	encode['Player']  = encode['Entity'];
	encode['Vehicle'] = encode['Entity'];
	encode['Weapon']	= encode['Entity'];
	encode['NPC']     = encode['Entity'];
	encode['NextBot'] = encode['Entity'];

	encode['nil'] = function(self, val)
		net_WriteUInt(0x0F --[[TYPE_NIL]], 8);
	end
	
	setmetatable(encode, {
		__index = function(self, key)
			error('Could not network type '..key..'!');
		end
	});
	
	function net.xWriteTable( tbl )
		cacheSize = 0;
		encode['table'](encode, tbl, {});
	end

	function net.WriteVar(var)
		local t = type(var);
		if t == 'table' then
			encode['table']( self, var, {});
		else
			encode[t]( self, var);
		end
	end

end

do
	local Vector, Angle, Entity = Vector, Angle, Entity ;
	
	local decode = {};

	local net_ReadUInt, net_ReadInt = net.ReadUInt, net.ReadInt ;
	local net_ReadFloat, net_ReadDouble = net.ReadFloat, net.ReadDouble ;
	local net_ReadString = net.ReadString ;

	local function decode_array( self, cur, cache)
		local k, tv = 1, nil;
		while( true )do
			tv = net_ReadUInt(8);
			if tv == 0x00 --[[TYPE_END]] then
				break ;
			end
			
			-- READ THE VALUE
			cur[ k ] = self[ tv ]( self, cache );
			
			k = k + 1;
		end
	end
	
	local function decode_assoc(self, cur, cache)
		local k, v, tk, tv = nil, nil, nil, nil;
		while( true )do
			tk = net_ReadUInt(8);
			if( tk == 0x00 --[[TYPE_END]] )then
				break ;
			end
			
			-- READ THE KEY
			k = self[ tk ]( self, cache );
			if not k then continue end
			
			-- READ THE VALUE
			tv = net_ReadUInt(8);
			v = self[ tv ]( self, cache );
			
			cur[ k ] = v;
		end
	end

	decode[0x02 --[[TYPE_ARRAY]]] = function( self, cache )
		local cur = {};
		cache[#cache+1] = cur;
		decode_array(self, cur, cache);
		return cur;
	end
	decode[0x03 --[[TYPE_ASSOC]]] = function( self, cache )
		local cur = {};
		cache[#cache+1] = cur;
		decode_assoc(self, cur, cache);
		return cur;
	end

	decode[0x04 --[[TYPE_TABLE]]] = function(self, cache)
		local cur = {};
		cache[#cache+1] = cur;
		decode_array(self, cur, cache);
		decode_assoc(self, cur, cache);
		return cur;
	end

	
	-- STRING
	decode[0x05 --[[TYPE_STRING]]] = function( self, cache )
		local res = net_ReadString()
		cache[#cache + 1] = res;
		return res;
	end
	
	decode[0x06 --[[TYPE_NEGATIVE]]] = function(self, cache)
		return net_ReadInt(32);
	end
	decode[0x07 --[[TYPE_USHORT]]] = function(self, cache)
		return net_ReadUInt(16);
	end
	decode[0x08 --[[TYPE_UINT]]] = function(self, cache)
		return net_ReadUInt(32);
	end
	decode[0x09 --[[TYPE_DOUBLE]]] = function(self, cache)
		return net_ReadDouble();
	end

	-- POINTER
	decode[0x01 --[[TYPE_POINTER]]] = function( self, cache )
		return cache[net_ReadUInt(32)]		
	end
	
	-- BOOLEAN. ONE DATA TYPE FOR YES, ANOTHER FOR NO.
	decode[0x0B --[[TYPE_BOOLEAN_FALSE]]] = function( self )
		return false;
	end
	decode[0x0A --[[TYPE_BOOLEAN_TRUE]]] = function( self )
		return true
	end
	
	-- VECTOR
	decode[0x0C --[[TYPE_VECTOR]]] = function( self )
		return Vector(net_ReadFloat(), net_ReadFloat(), net_ReadFloat());
	end
	
	-- ANGLE
	decode[0x0D --[[TYPE_ANGLE]]] = function( self, cache )
		return Angle(net_ReadFloat(), net_ReadFloat(), net_ReadFloat());
	end

	-- ENTITY
	decode[0x0E --[[TYPE_ENTITY]]] = function( self, cache )
		local ind = net_ReadUInt();
		if ind == 0xFFFF then
			return NULL
		else
			return Entity(ind);
		end
	end

	-- NIL
	decode[0x0F --[[TYPE_NIL]]] = function( self )
		return nil;
	end
	
	function net.xReadTable(data)
		return decode[net_ReadUInt(8)](decode, {});
	end

	function net.ReadVar()
		return decode[net_ReadUInt(8)](decode, {});
	end
end


