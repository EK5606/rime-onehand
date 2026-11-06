-- 右 Ctrl/Shift 直接切换到下一个 Rime 方案。
-- key_binder 把 Control+Shift_R 转成 F24，再在这里处理，
-- 避免 ascii_composer / 其它处理器先吃掉组合键。
local ACCEPT, NOOP = 1, 2
local TRIGGER = 0xFFD5 -- XK_F24

-- 按这个顺序循环；新增/删除方案时改这里
local SCHEMAS = { "one_hand", "moran", "wanxiang_t9" }

local function process(key, env)
  if key:release() or key.keycode ~= TRIGGER then
    return NOOP
  end

  local current = env.engine.schema.schema_id
  local idx = 0
  for i, id in ipairs(SCHEMAS) do
    if id == current then
      idx = i
      break
    end
  end

  local next_id = SCHEMAS[(idx % #SCHEMAS) + 1]
  local schema = Schema(next_id)
  if schema then
    env.engine:apply_schema(schema)
  end
  return ACCEPT
end

return { func = process }
