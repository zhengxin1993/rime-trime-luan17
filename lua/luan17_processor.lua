--[[
  乱序 17 键「重码选码」—— 按键处理器（唯一的选择通道）

  默认只处理 F5~F10（和一组别名），其他按键一律放行，所以：
    * 数字 1~9 选字、空格上屏、翻页、继续打字全部保持原样；
    * 候选栏里不再有任何「假按钮」，点候选永远是正常的选字上屏；
    * 「不选」和以前完全一样，不会有任何副作用。

  按键从哪来：luan17.trime.yaml 的中文键盘第 0 行（新增行，不占用任何
  原有键位），五个键 send: F6 / F7 / F8 / F9 / F10，标签 1 / 2 / 3 / 4 /
  全部。Trime 3.x 的 KeyCode.parse(send) 会把它们转成 keycode，经
  processKey 送进 Rime，lua_processor 收到的 repr 就是 "F6" 等；
  hookKeyboard 只在 Ctrl 组合键时拦截，不会吃掉功能键。

  动作：
    F6~F9  选第 1~4 个同码音节（该编码不足 N 个时忽略）
    F5     循环：全部 → 1 → … → N → 全部
    F10    回到「全部」，恢复混合候选
  每次动作后调用 Context::RefreshNonConfirmedComposition() 重新翻译，
  luan17_filter.lua 按新状态筛掉其它音节的候选，luan17_tags.lua 同步刷新
  上方编码行的提示。

  应急通道：把 luan17_select/number_keys 设为 "on"，则重码场景下数字
    1~4 / 0 也能选码（仅在这时接管，其余情况数字选字照常）。用于极少数
    机型把功能键吃掉的情况，默认关闭。

  别名（物理键盘 / 自定义 key_binder 用，主题未绑定，故不占用任何按键）：
    cycle  * - minus asterisk
    s1     ! = exclam equal
    s2     @ [ at bracketleft
    s3     # ] numbersign bracketright
    s4     $ \\ dollar backslash
    clear  %  percent
--]]

local data = require("luan17_syllables")

local P = {}

local kAccepted = 1
local kNoop = 2

local DEFAULTS = {
  cycle = "F5",
  s1 = "F6",
  s2 = "F7",
  s3 = "F8",
  s4 = "F9",
  clear = "F10",
}

local ALIASES = {
  cycle = { "*", "asterisk", "minus", "-" },
  s1 = { "!", "exclam", "equal", "=" },
  s2 = { "@", "at", "bracketleft", "[" },
  s3 = { "#", "numbersign", "bracketright", "]" },
  s4 = { "$", "dollar", "backslash", "\\" },
  clear = { "%", "percent" },
}

function P.init(env)
  local config = env.engine.schema.config
  local key_map = {}
  for action, default in pairs(DEFAULTS) do
    local configured = config:get_string("luan17_select/keys/" .. action)
    local names = { configured or default }
    for _, a in ipairs(ALIASES[action] or {}) do
      names[#names + 1] = a
    end
    for _, n in ipairs(names) do
      if n and #n > 0 then key_map[n] = action end
    end
  end
  env.key_map = key_map
  env.number_keys = (config:get_string("luan17_select/number_keys") == "on")
end

function P.func(key, env)
  local repr = key:repr()
  if key:release() then return kNoop end

  local action = env.key_map[repr]
  if not action and repr and repr:sub(1, 6) == "Shift+" then
    action = env.key_map[repr:sub(7)]
  end

  local ctx = env.engine.context
  if ctx:get_option("ascii_mode") or not ctx:is_composing() then
    return kNoop
  end

  local list, bare = data.current_list(ctx)

  -- 应急通道（默认关闭）：只在确实是重码场景时才接管数字 0~4。
  -- 不重码时数字键原样放行，数字选字完全不受影响。
  if not action and env.number_keys and repr and list then
    local digit = repr:match("^([0-4])$")
    if digit then
      local n = tonumber(digit)
      action = (n == 0) and "clear" or ("s" .. n)
    end
  end
  if not action then return kNoop end

  if not list then
    data.reset()
    return kAccepted
  end

  local st = data.state
  if st.code ~= bare or st.list ~= list then
    data.reset()
    st = data.state
  end
  st.code, st.seg, st.list = bare, bare:sub(-2), list

  if action == "clear" then
    data.apply(ctx, 0)
  elseif action == "cycle" then
    data.apply(ctx, (st.index + 1) % (#list + 1))
  else
    local n = tonumber(action:sub(2))
    if not (n and n <= #list) then return kAccepted end
    data.apply(ctx, n)
  end

  data.refresh(ctx)
  return kAccepted
end

return P
