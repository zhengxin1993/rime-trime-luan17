# 乱序 17 键双拼 · Trime / Rime 配置

基于 [白霜拼音 rime-frost](https://github.com/gaboolic/rime-frost) 的「小鹤双拼」配置外壳，改成百度输入法「新 17 乱（右删版）」乱序 17 键双拼，并加上**重码音节选码**功能；另附一套带浅色 / 深色自动切换的 [同文输入法 Trime](https://github.com/osfans/trime) 主题。

简单说：17 个编码键，每键输出一个字母，首键作声母码、次键作韵母码，两键一音节；词库、语法模型、标点、辅助码、简繁切换等全部沿用上游白霜拼音，本仓库只提供**增量配置**。

主题另带一套**中英文符号键盘**：3 页共 180 个符号，中文标点可一键切成英文半角。

---

## 一、依赖（必读）

### 1. 上游方案：白霜拼音 rime-frost

> **https://github.com/gaboolic/rime-frost**（默认分支 `master`，GPL-3.0）
> 上游本身派生自 [雾凇拼音 rime-ice](https://github.com/iDvel/rime-ice) 的 `af2480b` commit。

**本仓库不包含任何词库**，只有 6 个增量文件。必须先把白霜拼音**整套**部署到 Rime 用户目录，让它能正常工作，再覆盖本仓库的文件。

`double_pinyin_luan.schema.yaml` 的第一行就是：

```yaml
__include: rime_frost_double_pinyin_flypy.schema.yaml:/
```

也就是说，编译时 Rime 会去读上游的 `rime_frost_double_pinyin_flypy.schema.yaml`，以及它连带引用的 `cn_dicts*` / `cn_dicts_cell*` 词库、`lua/`、`melt_eng`、`radical_pinyin`、`rime_frost_aux`、`symbols_v.yaml`、语言模型等。**只拷词库或部分文件会导致 `__include` 编译失败、方案直接不可用。**

推荐直接用上游打好的整包：

```text
https://github.com/gaboolic/rime-frost/releases/download/nightly/rime-frost-schemas.zip
```

或按上游 README 用 `git clone --depth 1 https://github.com/gaboolic/rime-frost Rime` 全量安装。

### 2. 运行环境

| 依赖 | 要求 | 说明 |
| --- | --- | --- |
| Rime 前端 | Android 同文 Trime 3.x（`config_version: "3.0"`） | 其它支持 `lua_processor` / `lua_filter` 的 Rime 前端也能用输入方案，但主题文件是 Trime 专用 |
| librime-lua | 必须启用 | 4 个 Lua 文件全部依赖；Trime / 白霜整包一般已自带 |
| 白霜拼音 | 完整一套 | 见上 |
| 深色自动切换 | 同文设置里打开「跟随系统夜间模式」 | 默认关闭；配色用 `light_scheme` / `dark_scheme` 双向链接 |

---

## 二、文件清单

| 文件 | 放到哪里 | 作用 |
| --- | --- | --- |
| `double_pinyin_luan.schema.yaml` | Rime 用户目录**根** | 输入方案：`__include` 继承白霜小鹤双拼，只替换 `speller/algebra`、translator 的 prism / preedit，并重列 `engine` 以插入 3 个 Lua 组件 |
| `luan17.trime.yaml` | Rime 用户目录**根**（Trime 会扫描 `*.trime.yaml`） | 主题：3×6 乱序 17 键键盘 + 新增选码行 + 三页中英文符号键盘 + 浅色 / 深色两套配色 |
| `lua/luan17_syllables.lua` | `lua/` | 音节 ↔ 17 键编码对照表、共享状态、`Segment.prompt` 写入辅助 |
| `lua/luan17_processor.lua` | `lua/` | 按键处理器：只拦 F5~F10，其余按键一律放行 |
| `lua/luan17_filter.lua` | `lua/` | 按候选的 `［全拼］` 注释过滤出指定音节（必须排在 `corrector` 之前） |
| `lua/luan17_tags.lua` | `lua/` | 把同码音节写进编码提示行（`filters` 最后一个，不碰候选） |
| `luan17-bundle.zip` | 手机端可直接下载覆盖 | 上面 6 个文件的打包副本，与仓库内容一致 |

> 4 个 Lua 文件**必须一起覆盖**。留一个旧版（旧版会往候选栏塞「假候选」、还调用了已删除的 `data.setup`），Lua 加载就会报错、方案失效。

---

## 三、键盘布局

```text
第 0 行（新增，选码）：   1      2      3      4     全部
第 1 行：              HP     Sh     Zh     B      X      MS
第 2 行：              L      D      Y      WZ     JK     NR
第 3 行：              Ch     Q      G      CF     T      ⌫
功能行：              123  |  符  |  ，  |    空格    |  。  |  ⏎
```

- 17 个编码键分别输出 `h s z b x m / l d y w j n / c q g f t`，右下角一格让给退格。
- 零声母音节以 `Q` 键起头，例如「安」= `Q + NR` = `qn`。
- 第 0 行是**新增**的一行，原来的 17 个编码键、退格、功能行以及所有上滑手势一格未动；数字 `1~9` 选字、空格上屏、翻页、继续打字的行为完全不变。

主题 `style` 里 `keyboard_height: 296`（横屏 236）已为新增行留出高度；不需要选码行时可以把这 5 个键删掉，改用物理键盘 F5~F10。

符号键盘的扩展见下一节，主键盘（含功能行与上滑手势）一字未动。

---

## 四、符号键盘（中英文）

点主键盘功能行的「符」进入。原版只有 20 个中文标点，现在扩成 **3 页 × 60 键 = 180 个符号键**，每页底部是同一条功能行：

```text
中/En | 中符 | En符 | 更多 | ⌫ | 空格 | ⏎ | 返回
```

| 页 | 内容 | 数量 |
| --- | --- | --- |
| 中符（默认，`symbols`） | 中文标点：逗号句号问号叹号、分号冒号顿号、省略号破折号、各类引号与括号、书名号、全角运算符、单位与货币 | 60 |
| En符（`symbols_en`） | 数字 + 全部 ASCII 半角标点 + 常用数学 / 货币 / 版权符号 | 60 |
| 更多（`symbols_more`） | 圈号、罗马数字、希腊字母、箭头、单位、几何与标记符号 | 60 |

En 页第二行起的半角标点：

```text
~ ` ! @ # $ % ^ & *      ( ) - _ = + [ ] { }
\ | ; : ' " , . / ?      < > ± × ÷ ≠ ≈ ≤ ≥ ∞
§ ¶ • ¢ £ € ¥ © ® ™
```

**中英文怎么共存**

- 中文页每个键写 `click: 中文标点` 加 `ascii: 英文半角`，共 46 组对应，例如 `，→ ,`、`《→ <`、`（→ (`、`＄→ $`。按功能行的「中/En」切换 `ascii_mode` 后，**同一套键位整页输出英文半角标点**；再按一次切回中文。
- 需要纯英文 / 编程符号时切到「En符」，那一页始终输出半角字符，不受中西文状态影响。
- 15 个中文标点键另有 `long_click` 变体（`“` 长按 `‘`、`【` 长按 `〖`、`《` 长按 `〈`、`￥` 长按 `¢` 等），不额外占键位。
- **长按「En符」** 打开 Trime 自带的液体键盘「更多」页（主题用 `__include: trime:/liquid_keyboard` 继承官方，内含中文、西文、数学、单位、Emoji、颜文字等 20+ 分类）。需要海量符号时走这里，里面的「返回」可退回符号键盘。
- 三页都设 `ascii_mode: 0` + `reset_ascii_mode: true`：进入时保证是中文状态；返回主键盘时由 `default` 页自动恢复中文，不会把西文状态带回去。

**实现依据**（核对 Trime 3.3.x 源码）：`TextKey.ascii` 在 `Key.checkKeyAction()` 中于 `ascii_mode` 为真时替换 `CLICK`；`long_click` / `select` 分别对应 `KeyBehavior.LONG_CLICK` 与 `PresetKey.select`；页签键的 `send: Eisu_toggle` 在 `CommonKeyboardActionListener` 的 `KEYCODE_EISU` 分支只用于 `switchKeyboard(select)`，**不会误翻 Rime 的中西文状态**（真正切换的是 `Luan17_Mode` 的 `send: SWITCH_CHARSET` + `toggle: ascii_mode`）。新增页通过 `select` 直接按名字切换，不加入 `style/keyboards` 循环列表，因此不影响「切换键盘」手势。

---

## 五、安装（以 Android + 同文 Trime 为例）

1. **先装上游**：把白霜拼音整包解压 / clone 到同文的 Rime 用户目录（`/rime`），重新部署，确认「白霜·小鹤双拼」能正常打字。
2. **覆盖这 6 个文件**：两个 `*.yaml` 放根目录，4 个 `*.lua` 放 `lua/`（用 `luan17-bundle.zip` 解压覆盖最省事）。
3. **启用输入方案**：在 `default.custom.yaml` 里把方案加进 `schema_list`：

   ```yaml
   patch:
     schema_list:
       - schema: double_pinyin_luan
       # 注意：Rime 的 list 是「整体替换」而不是追加，
       # 想保留白霜全拼 / 其它双拼，把它们的 schema 一并写在这里。
   ```

   然后到同文的输入方案选择里勾「双拼」（`double_pinyin_luan`）。
4. **启用主题**：同文设置 → 主题 / 配色，选「乱序17键双拼」（配色名为「乱17·浅色（自动）」/「乱17·深色（自动）」）；再到设置里打开「跟随系统夜间模式」以启用自动深浅切换。
5. **重新部署**，然后打 `NR` + `HP`（即 `nh`）验证：编码提示行应出现 `〔1 na  2 rua  3 nia〕`。

桌面端（鼠须管 / 小狼毫 / fcitx5-rime）只需第 1~3 步，主题文件用不上；选码按键可用物理键盘 F5~F10。

---

## 六、选码怎么用

以 `nh` 为例，这个编码对应 `na / rua / nia` 三个音节：

```text
第 1 行  编码提示行：  nh 〔1 na  2 rua  3 nia〕
第 2 行  候选栏：      拿  挼  㑚  那  …          ← 混合候选

按键盘第 0 行的「1」：
第 1 行  编码提示行：  nh 〔✓ na  2 rua  3 nia  0 全部〕
第 2 行  候选栏：      拿  那  …                  ← 只剩 na 的字词

按「全部」：           恢复混合候选
不选：                 和以前完全一样，不做任何过滤
```

- 第 0 行五个键分别发送 `F6 / F7 / F8 / F9 / F10`，对应选第 1~4 个音节 / 恢复全部；`F5` 是循环键（全部 → 1 → … → N → 全部），主题未绑定，供物理键盘或自定义 `key_binder` 用。
- **第一行是只读提示，拼音本身不能点**——Trime 的编码提示行不是按钮。这是 Trime 能做到的、最接近「拼音一行、候选字一行且拼音可选」的形式。

### 为什么不把拼音做成「可点的候选」

旧版曾把音节塞进候选列表当按钮，结果点一下就上屏拼音 / 数字、或把输入清空。核对 Trime 3.3.14、librime、librime-lua 源码后确认，这不是版本差异，而是 **librime 的核心语义**：

```text
RimeSelectCandidate → Context::Select() → ConcreteEngine::OnSelect()
    → 无条件 seg.Close()，把覆盖到输入串末尾的段标记 kConfirmed（或 Forward）
```

即「点候选 = 确认并上屏该候选」，与候选 `text` 是不是空串无关。另外 `comment_position: top` 只是**每个候选格内部**的上注释下文字，候选栏本身是一条一维列表，做不出整栏两条独立行。

现在的做法：

- 用 Trime 原生的两行结构 —— 键盘上方的**编码提示行**（preedit）+ 下面的**候选栏**；
- `luan17_tags.lua` 把同码音节写进 `Segment.prompt`。librime 的 `Composition::GetPreedit()` 会显示它，而 `GetCommitText()` 完全不含 prompt，**这行字永远不会上屏**；
- `luan17_filter.lua` 按候选的 `［全拼］` 注释过滤。没有注释的候选（英文、Emoji、自定义短语、计算器等）、音节数与编码段数不符的候选（补全、整句联想）一律放行，宁可少筛也不误删；
- 候选列表一个都不增、一个都不删，点候选永远走正常的选字上屏。

滤镜顺序是关键：`is_in_user_dict → luan17_filter → corrector → … → uniquifier → luan17_tags`。`corrector` 会改写 / 清空 `［全拼］`，所以过滤必须排在它之前；`luan17_tags` 放最后是为了读到最终候选状态。

---

## 七、配置开关

在 `double_pinyin_luan.schema.yaml` 的 `luan17_select` 段：

| 项 | 默认 | 说明 |
| --- | --- | --- |
| `prompt_style` | `"on"` | 改 `"none"` 关掉编码行的音节提示，选码功能仍可用 |
| `number_keys` | `"off"` | 应急开关。某些机型若把 F5~F10 吃掉了，改成 `"on"` 即可用数字 `1~4` 选音节、`0` 恢复全部；开启后重码编码下的数字键不再用于选第 n 个候选字 |
| `keys.cycle` | `F5` | 循环切换 |
| `keys.s1` ~ `s4` | `F6`~`F9` | 直接选第 1~4 个音节 |
| `keys.clear` | `F10` | 恢复全部候选 |

Lua 里另内置一组别名（`*` / `!` / `@` / `#` / `$` / `%` 及对应键名），供物理键盘或自定义 `key_binder` 使用，主题未绑定，不占用任何按键。

在 `luan17.trime.yaml` 里：`style/comment_position: right`（回到默认，不再依赖旧版的两行 hack）、`style/keyboard_height: 296`、`preset_color_schemes.default/dark` 的 `light_scheme` / `dark_scheme` 双向链接。

---

## 八、音节表与统计

`lua/luan17_syllables.lua` 由脚本生成，请勿手工改键位。数据来源是上游 `cn_dicts*` / `cn_dicts_cell*` 的注音列，套用本方案 `speller/algebra` 全量运算（含 `derive` 派生，故一个音节可能对应多个编码）：

- 420 个音节 → 275 个两字母编码，其中 120 个是重码，单个编码最多对应 4 个音节；
- `code_of[音节]` 用于把候选注释的全拼还原成编码，`by_code[编码]` 按字频降序用于列出同码音节；
- 排除 4 个算不出两字母编码、prism 里只有三字母码的音节：`eh→qeh`、`lvan→lvn`、`lve→lvw`、`nve→nvw`。

---

## 九、排错

| 现象 | 原因 / 处理 |
| --- | --- |
| 部署失败、方案不出现 | 上游白霜拼音没装全，`__include` 找不到 `rime_frost_double_pinyin_flypy.schema.yaml` 或其依赖词库；先按上游 README 整包安装 |
| 按键打出无意义字母串 | 只换了皮肤，没切换到 `double_pinyin_luan` 方案 |
| 编码提示行不显示音节 | `prompt_style` 是否为 `"on"`；或该编码不是重码（同码音节不足 2 个时不显示）；或前端未启用 librime-lua |
| 按第 0 行没反应 | 把 `number_keys` 改成 `"on"`，改用数字 `1~4` / `0` 选码 |
| Lua 报错 / 候选栏出现「假按钮」 | 4 个 Lua 里有旧版残留，必须全部覆盖后重新部署 |
| 深色不自动切换 | 同文设置里打开「跟随系统夜间模式」 |
| 符号页还是只有一页 / 点页签没反应 | 只覆盖了部分文件；`luan17.trime.yaml` 要整体覆盖后重新部署。三页与四个页签键都在这个文件里 |
| 按「中/En」符号没变化 | 只有「中符」页带 `ascii` 对应（46 个），En / 更多两页本来就输出固定字符；另外确认该页标签是否已变成「西文」 |
| 升级白霜拼音后功能异常 | `engine.processors` / `filters` 是 **list 整体替换**，升级上游后需核对这两份列表是否仍与新版 `rime_frost_double_pinyin_flypy` 一致 |

---

## 十、致谢与许可

- 词库与配置外壳：[白霜拼音 rime-frost](https://github.com/gaboolic/rime-frost)（gaboolic），上游为 [雾凇拼音 rime-ice](https://github.com/iDvel/rime-ice)（iDvel）
- 前端：[同文输入法 Trime](https://github.com/osfans/trime)、[librime](https://github.com/rime/librime)、[librime-lua](https://github.com/hchunhui/librime-lua)
- 键位：百度输入法「新 17 乱（右删版）」；Rime 映射参考 Momo 默默 2015 年同文 `double_pinyin_luan`

> 上游 rime-frost 采用 **GPL-3.0**。本仓库是在其之上派生的增量配置，本身不含词库；使用、修改、分发时请一并遵守上游许可证与雾凇拼音的相关条款。
