-- 把输入码里的数字显示成笔画；由 schema 的 stroke_display 开关控制
local STROKE = {
  ["0"] = "乛", ["1"] = "一", ["2"] = "丨", ["3"] = "丿", ["4"] = "丶",
  ["5"] = "乛", ["6"] = "丶", ["7"] = "一", ["8"] = "丨", ["9"] = "丿",
}

local function to_stroke(s)
  return (s:gsub("%d", function(d) return STROKE[d] end))
end

local function filter(input, env)
  local ctx = env.engine.context
  local enabled = ctx:get_option("stroke_display")

  for cand in input:iter() do
    if enabled then
      local start = cand.start or 0
      local finish = cand._end or #ctx.input
      local code = ctx.input:sub(start + 1, finish)
      if code ~= "" then
        cand.preedit = to_stroke(code)
      end
    end
    yield(cand)
  end
end

return { func = filter }
