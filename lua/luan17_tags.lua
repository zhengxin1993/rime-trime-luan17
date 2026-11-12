--[[
  乱序 17 键「重码选码」—— 第一行（编码提示行）显示同码音节

  文件名沿用 luan17_tags.lua，方便手机端直接覆盖旧文件；但角色已彻底改变：
  旧版往候选列表里塞「假候选」当按钮，这一版一个候选都不加、一个都不删。

  为什么必须改（与 Trime 版本无关，是 librime 的核心语义）：
    Trime 点候选 → RimeSelectCandidate → Context::Select()
    → ConcreteEngine::OnSelect() 无条件 seg.Close()，并把覆盖到输入串末尾
      的段标记 kConfirmed（_auto_commit 打开时直接 Commit()，否则 Forward()）。
    所以「点候选」= 确认并上屏这个候选，候选里塞什么 text 都挡不住：
    text 非空就上屏拼音/数字，text 为空就把 composition 关掉/清空。
    这正是之前「点选拼音却上屏数字、候选栏乱掉」的根因，换更新的
    Trime 也一样，因为逻辑在 librime，不在前端。

  现在的做法：
    * 候选列表原样放行（真实候选一个不少，点击行为完全正常）。
    * 把同码音节写进 Segment.prompt。librime-lua 的 SegmentReg.vars_set
      暴露了 prompt；Composition::GetPreedit() 把它插进编码行，而
      Composition::GetCommitText() 不含 prompt → 永远不会上屏。
    * Trime 的 InputView 把 preedit.ui.root 放在键盘上方、候选栏在键盘
      顶部，于是「上排 = 拼音选项、下排 = 候选字」是 Trime 原生的两行
      结构，不依赖 style/comment_position，也不需要给候选挂注释。

  选码入口在键盘新增的一行按键（send: F5~F10），由 luan17_processor.lua
  处理；本文件只负责显示，永远不参与点击。
--]]

local data = require("luan17_syllables")

local T = {}

local function normalize(input)
  if not input then return "" end
  return (input:gsub("[ ']", ""))
end

local function build_prompt(list, index)
  local parts = {}
  for i, syl in ipairs(list) do
    local mark = (i == index) and "✓" or tostring(i)
    parts[#parts + 1] = mark .. " " .. syl
  end
  if index > 0 then
    parts[#parts + 1] = "0 全部"
  end
  return " 〔" .. table.concat(parts, "  ") .. "〕"
end

function T.init(env)
  local style = env.engine.schema.config:get_string("luan17_select/prompt_style")
  env.show_prompt = (style ~= "none")
end

function T.func(input, env)
  local ctx = env.engine.context
  local bare = normalize(ctx and ctx.input)
  local st = data.state

  -- 输入码一变（继续打字 / 退格 / 上屏清空），选码状态立即失效
  if st.code ~= bare then
    data.reset()
    st = data.state
  end

  local list = data.current_list(ctx)
  if list then
    st.code, st.seg, st.list = bare, bare:sub(-2), list
    if st.index > 0 and st.index <= #list then
      st.syllable = list[st.index]
    else
      st.index, st.syllable = 0, nil
    end
    data.set_prompt(ctx, env.show_prompt and (" " .. build_prompt(list, st.index)) or "")
  else
    data.set_prompt(ctx, "")
  end

  -- 关键：候选一个都不动、一个都不加。点候选永远是正常的选字上屏。
  for cand in input:iter() do
    yield(cand)
  end
end

return T
