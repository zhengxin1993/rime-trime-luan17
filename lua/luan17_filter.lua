--[[
  乱序 17 键「重码选码」—— 按音节过滤真实候选（必须排在 corrector 之前）

  filters 链顺序（见 double_pinyin_luan.schema.yaml）：
    is_in_user_dict → 【本文件】 → corrector → … → uniquifier → luan17_tags

  本文件只做过滤，不生成任何候选、不改动任何候选的显示。过滤依据：
  雾凇主翻译器开了 spelling_hints / always_show_comments，comment_format
  把全拼提示包成「［na］」「［na rua］」。corrector 会改写这种注释
  （默认清空），所以必须排在它之前才能读到原始全拼。

  被选中的音节来自共享状态（luan17_syllables.lua），唯一写入者是
  luan17_processor.lua（键盘新增行的 F5~F10）。候选栏里没有任何假按钮，
  点候选永远走正常的选字上屏，不会经过这里。

  保留策略（宁可少筛、不可误删）：
    - 没有全拼注释的候选（英文、自定义短语、Emoji、计算器等）一律放行
    - 音节数与编码段数不符的候选（补全、整句联想）一律放行
    - 只有「音节数吻合 + 每一段编码都对得上」的候选才参与音节筛选

  筛的是「最后一个编码段」对应的音节，也就是刚打完的那个字。
--]]

local data = require("luan17_syllables")

local F = {}

-- 若同一批候选对象被再次送入过滤链，注释可能已被 corrector 改写；
-- 用弱键表缓存解析结果，避免二次读取时丢失全拼。
local pinyin_cache = setmetatable({}, { __mode = "k" })

local function pinyin_of(cand)
  local cached = pinyin_cache[cand]
  if cached ~= nil then
    return cached or nil
  end
  local comment = cand.comment or ""
  local pinyin = comment:match("^［(.-)］$")
  if not pinyin and comment:match("^[a-z][a-z ]*$") then
    pinyin = comment -- 兼容 keep_comments 打开时的裸拼音
  end
  pinyin = pinyin or false
  pinyin_cache[cand] = pinyin
  return pinyin or nil
end

local function normalize(input)
  if not input then return "" end
  return (input:gsub("[ ']", ""))
end

local function split_syllables(pinyin)
  local out = {}
  for s in pinyin:gmatch("[^ ']+") do
    out[#out + 1] = s
  end
  return out
end

-- 状态由 luan17_syllables.lua 的模块单例共享，无需连接任何 notifier。
function F.init(_env)
end

function F.func(input, env)
  local ctx = env.engine.context
  local bare = normalize(ctx.input)
  local st = data.state

  -- 输入码一变（继续打字、退格、上屏清空），选码状态立即失效
  if st.code ~= bare then
    data.reset()
    st = data.state
  end

  local seg_count = ((#bare % 2) == 0) and (#bare / 2) or 0
  local last_seg = (seg_count > 0) and bare:sub(-2) or nil
  local list = last_seg and data.by_code[last_seg] or nil
  local enabled = seg_count > 0
    and list and #list >= 2
    and not bare:match("[^a-z]")
    and not ctx:get_option("ascii_mode")

  if not enabled then
    for cand in input:iter() do yield(cand) end
    return
  end

  st.code = bare
  st.seg = last_seg
  st.list = list
  if st.index > 0 and st.index <= #list then
    st.syllable = list[st.index]
  else
    st.index = 0
    st.syllable = nil
  end
  local target = st.index > 0 and st.syllable or nil

  for cand in input:iter() do
    local keep = true
    -- 无论当前是否选码都先解析并缓存：corrector 会改写 comment，
    -- 重翻译时若复用了同一批候选对象就再也读不到 ［全拼］。
    local pinyin = pinyin_of(cand)
    if target then
      if pinyin and #pinyin > 0 then
        local syls = split_syllables(pinyin)
        if #syls == seg_count then
          local matched = true
          for i = 1, seg_count do
            local codes = data.code_of[syls[i]]
            if not codes or not codes[bare:sub(2 * i - 1, 2 * i)] then
              matched = false
              break
            end
          end
          if matched then
            -- 词库里 ü 有 u/v 两种注音，提示行只列规范拼写；比较前归一，
            -- 选「lue」时 lve 注音的字词也一起留下（见 M.alias）。
            local last = data.alias[syls[seg_count]] or syls[seg_count]
            keep = (last == target)
          end
        end
      end
    end
    if keep then yield(cand) end
  end
end

return F
