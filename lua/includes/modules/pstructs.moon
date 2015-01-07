export pstruct
pstruct or= {}

pstruct.Stack = () ->
	values = {}
	top = 0
	return {
		push: (val) =>
			top += 1
			values[top] = val
		pop: () =>
			val = values[top]
			values[top] = nil
			top -= 1
			val
		peek: () =>
			values[top]
		getValues: () ->
			return values
	}