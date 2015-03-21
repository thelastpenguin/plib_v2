nw 				= nw 			or {}
nw.Stored 		= nw.Stored 	or {}
nw.VarFuncs		= nw.VarFuncs 	or {}

local nw 		= nw
local net 		= net
local pairs 	= pairs
local Entity 	= Entity
local player 	= player

local ENTITY 	= FindMetaTable('Entity')

local ReadType
local GetFilter
if (SERVER) then
	util.AddNetworkString('nw.var')
	util.AddNetworkString('nw.clear')
	util.AddNetworkString('nw.ping')
	util.AddNetworkString('nw.delete')


	function GetFilter(ent, var, value)
		return (nw.VarFuncs[var] ~= nil and nw.VarFuncs[var].Filter ~= nil) and nw.VarFuncs[var].Filter(ent, var, value) or nil
	end

	function ENTITY:SetNetVar(var, value)
		local index = self:EntIndex()
		
		if (nw.Stored[index] == nil) then
			nw.Stored[index] = {}
		end

		nw.Stored[index][var] = value

		if (nw.VarFuncs[var] ~= nil) and (nw.VarFuncs[var].Send ~= nil) then
			nw.VarFuncs[var].Send(self, index, value)
			return
		end

		MsgC(Color(255,0,0), 'UNREGISTERED VAR: ' .. var)

		net.Start('nw.var')
			net.WriteUInt(index, 16)
			net.WriteString(var)
			WriteVar(var, value)
		net.Send(GetFilter(self, var, value) or player.GetAll())
	end

	net.Receive('nw.ping', function(len, pl)
		hook.Call('PlayerEntityCreated', GAMEMODE, pl)
	end)

	hook.Add('PlayerEntityCreated', 'nw.PlayerEntityCreated', function(pl)
		for index, vars in pairs(nw.Stored) do
			local ent = Entity(index)
			for var, value in pairs(vars) do
				local filter = GetFilter(ent, var, value)
				if (filter == pl) or (filter == nil) then
					net.Start('nw.var')
						net.WriteUInt(index, 16)
						net.WriteString(var)
						net.WriteType(value)
					net.Send(pl)
				end
			end
		end
	end)

	hook.Add('EntityRemoved', 'nw.EntityRemoved', function(ent)
		local index = ent:EntIndex()
		if (nw.Stored[index] ~= nil) then
			net.Start('nw.clear')
				net.WriteUInt(index, 16)
			net.Broadcast()
			nw.Stored[index] = nil
		end
	end)
elseif (CLIENT) then
	function ReadType()
		local t = net.ReadUInt(8)
		return net.ReadType(t)
	end

	net.Receive('nw.var', function()
		local index = net.ReadUInt(16)
		local var 	= net.ReadString()
		local value = ReadType()

		if (nw.Stored[index] == nil) then
			nw.Stored[index] = {}
		end

		nw.Stored[index][var] = value
	end)

	net.Receive('nw.clear', function()
		nw.Stored[net.ReadUInt(16)] = nil
	end)

	net.Receive('nw.delete', function()
		local index = net.ReadUInt(16)
		if (nw.Stored[index] ~= nil) then
			nw.Stored[index][net.ReadString()] = nil
		end
	end)

	hook.Add('InitPostEntity', 'nw.InitPostEntity', function()
		net.Start('nw.ping')
		net.SendToServer()
	end)
end

function ENTITY:GetNetVar(var)
	local index = self:EntIndex()
	if (nw.Stored[index] ~= nil) then
		return nw.Stored[index][var]
	end
	return nil
end

function nw.Register(var, funcs) -- always call this shared
	if (SERVER) then
		util.AddNetworkString('nw_' ..  var)
	elseif (CLIENT) then
		local ReadFunc = ((funcs and funcs.Read) and funcs.Read or ReadType)

		net.Receive('nw_' ..  var, function()
			local index = net.ReadUInt(16)
			local value = ReadFunc()

			if (nw.Stored[index] == nil) then
				nw.Stored[index] = {}
			end

			nw.Stored[index][var] = value
		end)
	end

	local WriteFunc = ((funcs and funcs.Write) and funcs.Write or net.WriteType)

	nw.VarFuncs[var] = {
		Send 	= function(ent, index, value)
			if (value == nil) then
				net.Start('nw.delete')
					net.WriteUInt(index, 16)
					net.WriteString(var)
				net.Send(GetFilter(ent, var, value) or player.GetAll())
				return
			end

			net.Start('nw_' ..  var)
				net.WriteUInt(index, 16)
				WriteFunc(value)
			net.Send(GetFilter(ent, var, value) or player.GetAll())
		end,
		Filter 	= (funcs and funcs.Filter or nil)
	}
end