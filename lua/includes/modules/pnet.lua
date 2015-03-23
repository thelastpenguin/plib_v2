if SERVER then
  util.AddNetworkString('pnet_Ready')
  local ready = { }
  hook.Add('PlayerDisconnected', 'pnet.PlayerDisconnected', function(pl)
    ready[pl] = nil
  end)
  net.waitForPlayer = function(pl, func)
    if ready[pl] == true then
      func()
    else
      if not (ready[pl]) then
        ready[pl] = { }
      end
      table.insert(ready[pl], func)
    end
  end
  return net.Receive('pnet_Ready', function(_, pl)
    if ready[pl] == true or ready[pl] == nil then
      return 
    end
    local _list_0 = ready[pl]
    for _index_0 = 1, #_list_0 do
      local func = _list_0[_index_0]
      func()
    end
    ready[pl] = true
  end)
else
  return hook.Add('Think', 'pnet.waitForPlayer', function()
    if IsValid(LocalPlayer()) then
      hook.Remove('Think', 'pnet.waitForPlayer')
      net.Start('pnet_Ready')
      net.SendToServer()
    end
  end)
end
