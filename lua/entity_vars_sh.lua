nw = {}

local ent_count = 0

local key_to_id = {}
local id_to_key = {}

if SERVER then
	util.AddNetworkString('nw.datapack')
	util.AddNetworkString('nw.keyPool')
	util.AddNetworkString('nw.entIds')
	net.Receive('nw.datapack', function(_, pl)
		net.Start('nw.keyPool')
			net.WriteUInt(#id_to_key, 16)
			for k,v in ipairs(id_to_key)
				net.WriteString(v)
			end
		net.Send(pl)
	end)


end

if CLIENT then

	local function addKey(key, id)
		id_to_key[id] = key
		key_to_id[key] = id
	end

	net.Receive('nw.keyPool', function()
		for i = 1, net.ReadUInt(16) do
			addKey(net.ReadString(), id)
		end
	end)

end