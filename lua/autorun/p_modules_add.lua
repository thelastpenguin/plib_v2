if SERVER then
	local blacklist = {
		-- Ex: pdraw.lua = true, // No extension needed
	}
	
	MsgN( "[plib] Adding files!" )
	
	local files = file.Find( "includes/modules" .. "/*", "LUA" )
	
	for _, file in pairs( files ) do
		local extension = string.GetExtensionFromFilename( file )
		if ( ( not blacklist[ file ] ) and extension == "lua" ) then
			AddCSLuaFile( "includes/modules/" .. file )
		end
	end
end
