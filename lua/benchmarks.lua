require 'pon'
include 'pon_v2.lua'
include 'von.lua'
include 'willox.lua'


local serializers = {}
local testData = {}

local function addLibrary(name, encoder, decoder)
	table.insert(serializers, {
		name = name,
		encode = encoder,
		decode = decoder,
		times = {}
	})
end

local function addTestData(name, data)
	table.insert(testData, {
		name = name,
		desc = desc,
		data = data
	})
end

addLibrary('pon v2', pon2.encode, pon2.decode)
addLibrary('pon', pon.encode, pon.decode)
addLibrary('von', von.serialize, von.deserialize)

addTestData('int array', {
	1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,
	1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10
})
addTestData('float array', {
	1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,
	1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589,1.5,-1.3,3.141592653589
})

local stringArray = {}
for i = 1, 10 do table.insert(stringArray, 'string string string '..i) end
for i = 1, 10 do table.insert(stringArray, 'string string string '..i..' string string string string string string string string string string string string string string') end

addTestData('string array', stringArray)

local pl = player.GetAll()[1]
addTestData('entity array', {
	pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,
	pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl,pl
})

addTestData('Vector array', {
	Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),
	Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),
	Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5),Vector(1,1,1), Vector(1.2,1.4,1.5)
})

for i = 1, 1 do
	for _, testCase in ipairs(testData)do
		collectgarbage('stop')
		
		MsgC(Color(0,200,0), '\nUsing test data: ' .. testCase.name .. '\n')
		local data = testCase.data

		for j = 1, 3 do
			for k,serializer in ipairs(serializers)do
				
				if not serializer.times[testCase] then
					serializer.times[testCase] = {
					 	encode = 0,
					 	encodeTimes = 0,
					 	decode = 0,
					 	decodeTimes = 0,
					}
				end

				local encode = serializer.encode
				local decode = serializer.decode
				print('serializer: ' .. serializer.name)

				Msg('encoding 2000 times... ')
				local s = SysTime()
				for e = 1, 2000 do
					encode(data)
				end
				local dt = SysTime() - s
				MsgN('took '..dt..' seconds.')
				serializer.times[testCase].encode = serializer.times[testCase].encode + dt
				serializer.times[testCase].encodeTimes = serializer.times[testCase].encodeTimes + 2000

				Msg('decoding 2000 times... ')
				local sdata = encode(data)
				local s = SysTime()
				for e = 1, 2000 do
					decode(sdata)
				end
				local dt = SysTime() - s
				MsgN('took '..dt..' seconds.')
				serializer.times[testCase].decode = serializer.times[testCase].decode + dt
				serializer.times[testCase].decodeTimes = serializer.times[testCase].decodeTimes + 2000

			end
		end

		collectgarbage('restart')
	end
end

MsgC(Color(255,255,255), '\n\nDONE RUNNING TESTS!!!\n\n')

for k,serializer in pairs(serializers)do
	MsgC(Color(0,200,200), '\nSerializer: ' .. serializer.name .. '\n')

	for testData, times in pairs(serializer.times)do
		MsgC(Color(220,220,220),'\tData Set: ' .. testData.name .. '\n')
		MsgC(Color(170,170,170),'\t\tencode: ' .. times.encode .. '\n')
		MsgC(Color(170,170,170),'\t\tdecode: ' .. times.decode .. '\n')
	end
end



