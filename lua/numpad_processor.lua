-- 返回值
local ACCEPT, NOOP, REJECT = 1, 2, 0

local KP = {
  [0xFFB0] = "0", [0xFFB1] = "1", [0xFFB2] = "2",
  [0xFFB3] = "3", [0xFFB4] = "4", [0xFFB5] = "5",
  [0xFFB6] = "6", [0xFFB7] = "7", [0xFFB8] = "8",
  [0xFFB9] = "9",
}

-- 兼容“数字键码 + Shift”的前端；XKB 通常直接发 exclam/at/... 的独立 keysym
local SHIFT_DIGIT = {
  ["0"] = ")", ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$",
  ["5"] = "%", ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(",
}

local PUNCT = {
  [0x2c] = ",", [0x2e] = ".", [0x2f] = "/", [0x3b] = ";", [0x27] = "'",
  [0x5b] = "[", [0x5d] = "]", [0x5c] = "\\", [0x60] = "`",
  [0x2d] = "-", [0x3d] = "=",

  -- Shift 后的独立 keysym
  [0x3c] = "<", [0x3e] = ">", [0x3f] = "?", [0x3a] = ":", [0x22] = '"',
  [0x7b] = "{", [0x7d] = "}", [0x7c] = "|", [0x7e] = "~",
  [0x5f] = "_", [0x2b] = "+",

  -- Shift + 数字的独立 keysym
  [0x21] = "!", [0x40] = "@", [0x23] = "#", [0x24] = "$", [0x25] = "%",
  [0x5e] = "^", [0x26] = "&", [0x2a] = "*", [0x28] = "(", [0x29] = ")",
}


-- 兼容“基础键码 + Shift”的前端；XKB 通常直接发 0x3c 等独立 keysym
local SHIFT_PUNCT = {
  [0x2c] = "<", [0x2e] = ">", [0x2f] = "?", [0x3b] = ":", [0x27] = '"',
  [0x5b] = "{", [0x5d] = "}", [0x5c] = "|", [0x60] = "~",
  [0x2d] = "_", [0x3d] = "+",
}

local last_mode = "en" -- 上一次输入状态

local function process(key, env)
  local ctx = env.engine.context
  local kc = key.keycode

  -- 忽略 release 事件，否则 press/release 会各上屏一次
  if key:release() then
    return NOOP
  end

  -- ASCII 模式交给 ascii_composer
  if ctx:get_option("ascii_mode") then
    return NOOP
  end

  -- Ctrl/Alt/Super 组合交给系统或后续组件
  if key:ctrl() or key:alt() or key:super() then
    return NOOP
  end

  -- 小键盘数字：只进编码
  local d = KP[kc]
  if d then
    last_mode = "zh"
    if key:shift() then return REJECT end
    ctx:push_input(d)   -- 官方 Objects 文档：会触发 Compose
    return ACCEPT
  end

  -- 主键盘数字：有候选时选词，没有候选时是普通数字
  if kc >= 0x30 and kc <= 0x39 then
    local n = kc - 0x30

    -- Shift+数字：保持 ASCII 符号（! @ # ...）
    if key:shift() then
      local ch = SHIFT_DIGIT[tostring(n)] or tostring(n)
      if ctx:is_composing() then ctx:clear() end
      last_mode = "en"
      env.engine:commit_text(ch)
      return ACCEPT
    end

    -- 有候选菜单：1-9 选当前页，0 选第 10 个
    if ctx:has_menu() then
      local comp = ctx.composition
      local seg = nil
      if comp and not comp:empty() then
        seg = comp:back()
      end
      local menu = seg and seg.menu
      if menu and not menu:empty() then
        local size = env.engine.schema.config:get_int("menu/page_size")
        if not size or size <= 0 then size = 10 end
        local idx = (n + 9) % 10  -- 1->0, ..., 9->8, 0->9
        if idx < size then
          local sel = seg.selected_index or 0
          local page_start = math.floor(sel / size) * size
          ctx:select(page_start + idx)
          last_mode = "zh"
          return ACCEPT
        end
        -- 超出当前页，消费掉这个数字，避免它又被当成普通数字
        return ACCEPT
      end
    end

    -- 没有候选：普通数字；组码中按下则放弃当前编码
    last_mode = "en"
    if ctx:is_composing() then ctx:clear() end
    env.engine:commit_text(tostring(n))
    return ACCEPT
  end

  -- 主键盘字母：英文；组码中按下则取消编码后透传
  if (kc >= 0x41 and kc <= 0x5a) or (kc >= 0x61 and kc <= 0x7a) then
    last_mode = "en"
    if ctx:is_composing() then ctx:clear() end
    return NOOP
  end

  -- 主键盘标点
  local p = PUNCT[kc]
  if p then
    if ctx:is_composing() then
      last_mode = "zh"
      return NOOP -- 组码中，交给 punctuator 出中文
    end

    if last_mode == "zh" then
      if kc == 0x2e then
        env.engine:commit_text("。")  -- "." 是分隔符，不能交给 speller
        return ACCEPT
      end
      return NOOP                     -- 交给 punctuator 出中文
    end

    local ch = key:shift() and (SHIFT_PUNCT[kc] or p) or p
    env.engine:commit_text(ch)
    return ACCEPT
  end

  return NOOP
end

return { func = process }
