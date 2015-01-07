pstruct = pstruct or { }
pstruct.Stack = function()
  local values = { }
  local top = 0
  return {
    push = function(self, val)
      top = top + 1
      values[top] = val
    end,
    pop = function(self)
      local val = values[top]
      values[top] = nil
      top = top - 1
      return val
    end,
    peek = function(self)
      return values[top]
    end,
    getValues = function()
      return values
    end
  }
end
