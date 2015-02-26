local opcode_whitelist = {}

do
	local bcnames = "ISLT  ISGE  ISLE  ISGT  ISEQV ISNEV ISEQS ISNES ISEQN ISNEN ISEQP ISNEP ISTC  ISFC  IST   ISF   MOV   NOT   UNM   LEN   ADDVN SUBVN MULVN DIVVN MODVN ADDNV SUBNV MULNV DIVNV MODNV ADDVV SUBVV MULVV DIVVV MODVV POW   CAT   KSTR  KCDATAKSHORTKNUM  KPRI  KNIL  UGET  USETV USETS USETN USETP UCLO  FNEW  TNEW  TDUP  GGET  GSET  TGETV TGETS TGETB TSETV TSETS TSETB TSETM CALLM CALL  CALLMTCALLT ITERC ITERN VARG  ISNEXTRETM  RET   RET0  RET1  FORI  JFORI FORL  IFORL JFORL ITERL IITERLJITERLLOOP  ILOOP JLOOP JMP   FUNCF IFUNCFJFUNCFFUNCV IFUNCVJFUNCVFUNCC FUNCCW"

	local opname_whitelist = {
		TNEW = true,
		TDUP = true,

		UNM = true,
		
		TSETV = true,
		TSETS = true,
		TSETB = true,
		TSETM = true,

		KSTR = true,
		KCDATA = true,
		KSHORT = true,
		KNUM = true,
		KPRI = true,
		KNIL = true,

		GGET = true,

		CALL = true,

		RET = true,
		RET0 = true,
		RET1 = true
	}

	local opcode = 0

	for opname in bcnames:gmatch "......" do
		opname = opname:gsub("%s", "")

		if opname_whitelist[opname] then
			opcode_whitelist[opcode] = true
		end

		opcode = opcode + 1
	end
end

local function is_safe(func)
	for pc = 1, math.huge do
		local ins = jit.util.funcbc(func, pc)

		if not ins then
			break
		end

		local opcode = bit.band(ins, 0xFF)

		if not opcode_whitelist[opcode] then
			local info = jit.util.funcinfo(func, pc)

			return false, ("Invalid operation on line %d (OPCODE: %d)"):format(info.currentline, opcode)
		end
	end

	return true
end


local fenv = {
	Angle = Angle,
	Color = Color,
	Vector = Vector
}


local function deserialize(code)
	local func = CompileString("return " .. code, "Deserialize", false)

	//local safe, err = is_safe(func)

	if not safe then
		return false, err
	end

	setfenv(func, fenv)

	local success, ret = pcall(func)

	if not success then
		return false, ret
	end

	return ret
end

willox = {}
willox.deserialize = deserialize