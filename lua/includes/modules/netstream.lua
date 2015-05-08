local txnid = 0

if SERVER then 
	util.AddNetworkString('pns')
end

function net.WriteStream(data, targs)
	-- generate a unique id for this txn
	txnid = (txnid + 1) % 0xFFFF

	-- iterate over the data to send
	local count = 0
	local iter = function()
		local seg = data:sub(count, count + 0x7FFF)
		count = count + 0x8000

		return seg
	end

	-- send a chunk of data
	local function send()
		local block = iter()
		local size = block:len()
		if block and block:len() > 0 then
			net.Start('pns')
				net.WriteUInt(txnid, 16)
				net.WriteUInt(size, 16)
				net.WriteData(block, size)
			if SERVER then
			net.Send(targs)
			else
			net.SendToServer()
			end
		end
		timer.Simple(0.001, send)
	end

	-- write txnid and chunks to be expected
	net.WriteUInt(txnid, 16)
	net.WriteUInt(math.ceil(data:len()/ 0x8000), 16)
	
	timer.Simple(0.001, send)
end

local buckets = {}
if SERVER then
	function net.ReadStream(src, callback)
		if not src then
			error('stream source must be provided to receive a stream from a player')
		end
		if not callback then
			error('callback must be provided for stream read completion')
		end
		if not buckets[src] then buckets[src] = {} end
		buckets[src][net.ReadUInt(16)] = {len=net.ReadUInt(16), callback=callback}
	end
	net.Receive('pns', function(_,pl)
		local txnid = net.ReadUInt(16)
		if not buckets[pl] or not buckets[pl][txnid] then
			dprint('could not receive stream from client. player bucket does not exist or txnid invalid')
		end

		local bucket = buckets[pl][txnid]

		local size = net.ReadUInt(16)
		local data = net.ReadData(size)
		bucket[#bucket+1] = data

		if #bucket == bucket.len then
			buckets[pl][txnid] = nil
			bucket.callback(table.concat(bucket))
		end
	end)
else
	
	function net.ReadStream(callback)
		if not callback then
			error('callback must be provided for stream read completion')
		end
		buckets[net.ReadUInt(16)] = {len=net.ReadUInt(16), callback=callback}
	end

	net.Receive('pns', function(_)
		local txnid = net.ReadUInt(16)
		if not buckets[txnid] then
			dprint('could not receive stream from server. txnid invalid.')
		end

		local bucket = buckets[txnid]

		local size = net.ReadUInt(16)
		local data = net.ReadData(size)
		bucket[#bucket+1] = data

		if #bucket == bucket.len then
			buckets[txnid] = nil
			bucket.callback(table.concat(bucket))
		end
	end)
end
