async = async or { }
local p = p
async.parallel = function(tasks, onFinish)
  if onFinish == nil then
    onFinish = p.fn.noop
  end
  local todo = #tasks
  for _index_0 = 1, #tasks do
    local task = tasks[_index_0]
    local canRun = true
    task(function()
      if canRun then
        canRun = false
        todo = todo - 1
      end
    end)
  end
end
async.series = function(tasks, onFinish)
  if onFinish == nil then
    onFinish = p.fn.noop
  end
  if #tasks > 0 then
    local canCall = true
    local run
    run = function()
      local i = i + 1
      return tasks[i](function()
        if canCall then
          canCall = false
          return run()
        else
          return error('async series fn called back more than once')
        end
      end)
    end
  else
    return onFinish()
  end
end
async.eachParallel = function(tasks, work, onFinish)
  if onFinish == nil then
    onFinish = p.fn.noop
  end
  local todo = #tasks
  for _index_0 = 1, #tasks do
    local task = tasks[_index_0]
    local canRun = true
    work(task, function()
      if canRun then
        canRun = false
        todo = todo - 1
      end
    end)
  end
end
async.eachSeries = function(tasks, work, onFinish)
  if onFinish == nil then
    onFinish = p.fn.noop
  end
  if #tasks > 0 then
    local i = 1
    local fn
    fn = function()
      i = i + 1
      if tasks[i] then
        return work(tasks[i], fn)
      else
        onFinish()
        onFinish = p.fn.noop
      end
    end
    return work(tasks[1], fn)
  else
    return onFinish()
  end
end
async.worker = function(data, rate, work, onFinish)
  if onFinish == nil then
    onFinish = p.fn.noop
  end
  if #tasks > 0 then
    local i = 1
    local fn
    fn = function()
      i = i + 1
      if tasks[i] then
        return work(tasks[i], fn)
      else
        onFinish()
        onFinish = p.fn.noop
      end
    end
    for i = 1, math.min(#data, rate) do
      work(tasks[1], fn)
    end
  else
    return onFinish()
  end
end
