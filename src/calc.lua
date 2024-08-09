local stdout = io.stdout
local stdin = io.stdin

--lightweight version of https://raw.githubusercontent.com/uriid1/lua-calc/main/calc

-- Class calc
--
local calc = {
  console_output = false;
  to_integer = false;
}


-- Availible func
--
local avalaible_function = {
  abs = math.abs;
  acos = math.acos;
  asin = math.asin;
  atan = math.atan;
  ceil = math.ceil;
  cos = math.cos;
  deg = math.deg;
  exp = math.exp;
  floor = math.floor;
  log = math.log;
  max = math.max;
  min = math.min;
  pi = math.pi;
  rad = math.rad;
  random = math.random;
  sin = math.sin;
  sqrt = math.sqrt;
  tan = math.tan;

  round = function (x)
    return (x >= 0) and math.floor(x + 0.5) or math.ceil(x - 0.5)
  end;
  
  sign = function (x)
    return (x > 0) and 1 or (x == 0 and 0 or -1)
  end;

  pow = math.pow;
  log10 = math.log10;
}


function calc:check_error(val)
  if (val ~= val) or (val == 1/0) or (val == -1/0) then
    return "Error. You are trying to divide a number by 0."
  end
end


function calc:check_func(source)
  for s in string.gmatch(source, "%a+") do
    if not avalaible_function[s] then
      return "Unfortunately, the '"..s.."' function is not available in this calculator."
    end
  end
end

function calc:eval(source)
  local err = self:check_func(source)

  if err then
    return stdout:write(err, '\n')
  end

  -- Exec
  local res
  local fn_res = (loadstring or load)("return " .. source, nil, nil, avalible_function)
  
  -- Protected call
  do
    local ok, err = pcall(fn_res)

    if ok then
      res = fn_res()
    else
      stdout:write(
        err, '\n', 
        "Failed to evaluate your expression. You may be using invalid characters.", '\n'
      )
      return
    end
  end
    --
  local err = self:check_error(res)

  if err then
    stdout:write(err, '\n')
    return
  end

  -- Return
  
  if self.to_integer then
    res = math.floor(res)
  end

  return res
end
  
--  fps_ratio="30000 / 1001"
--  print(calc:eval(fps_ratio))

return calc