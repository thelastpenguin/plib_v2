local SysTime = SysTime

benchmark = {}

local benchmarks_running = {}

local stack_time = {}
local stack_mem = {}

function benchmark.start()
	stack_time[#stack_time+1] = SysTime()
end

function benchmark.start_memory()
	stack_mem[#stack_mem+1] = collectgarbage('count')
end

function benchmark.stop()
	local t = SysTime() - stack_time[#stack_time]
	stack_time[#stack_time] = nil
	return t
end

function benchmark.stop_memory()
	local m = (collectgarbage('count') - stack_mem[#stack_mem]) * 1024
	stack_mem[#stack_mem] = nil
	return m - m % 1
end