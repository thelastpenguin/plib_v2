export async
async or= {}

p = p

async.parallel = (tasks, onFinish = p.fn.noop) ->
	todo = #tasks
	for task in *tasks
		canRun = true
		task ->
			if canRun
				canRun = false
				todo -= 1

async.series = (tasks, onFinish = p.fn.noop) ->
	if #tasks > 0
		canCall = true

		run = ->
			i += 1
			tasks[i] ->
				if canCall
					canCall = false
					run!
				else
					error 'async series fn called back more than once'
	else
		onFinish()

async.eachParallel = (tasks, work, onFinish = p.fn.noop) ->
	todo = #tasks
	for task in *tasks
		canRun = true
		work task, ->
			if canRun
				canRun = false
				todo -= 1

async.eachSeries = (tasks, work, onFinish = p.fn.noop) ->
	if #tasks > 0
		i = 1
		fn = ->
			i += 1
			if tasks[i]
				work(tasks[i], fn)
			else
				onFinish!
				onFinish = p.fn.noop
		work(tasks[1], fn)
	else
		onFinish!

async.worker = (data, rate, work, onFinish = p.fn.noop) ->
	if #tasks > 0
		i = 1
		fn = ->
			i += 1
			if tasks[i]
				work(tasks[i], fn)
			else
				onFinish!
				onFinish = p.fn.noop
		for i = 1, math.min(#data, rate)
			work(tasks[1], fn)
	else
		onFinish!