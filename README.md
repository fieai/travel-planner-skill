> ⚠️ **本仓库已归档（read-only）。** travel-planner 已迁入 monorepo **[fieai/lifekit](https://github.com/fieai/lifekit)**（`plugins/travel-planner`）。
> 安装：`/plugin marketplace add fieai/lifekit` → `/plugin install travel-planner@lifekit`。后续更新只在 lifekit 进行。

<div align="center">

# travel-planner

**一个面向中文用户的旅行行程规划 skill**

[中文](#中文) · [English](#english)

</div>

---

## 中文

一个为 Claude Code、Codex 等 Agent Skill 环境设计的旅行行程规划 skill，面向中文用户的出境与国内自由行、亲子游、蜜月、自驾、转机停留等场景。

它不是"把 prompt 写得长一点"。

它是把一整套行程规划工作流写下来：什么时候停下来问用户、什么时候并行调研、什么时候不能猜、怎么处理国内网络环境、怎么把最终行程交付成微信可直发的 PDF。

主体约 1200 行，没有一行是关于"具体怎么排某一天"的——行程怎么排，模型本身就会；什么时候问、什么时候停、什么时候按住自己，才是 skill 要替模型想清楚的部分。

### 能做什么

- **出境 / 国内自由行**：规划 X 天 Y 城行程，输出每日表格 + 地图按钮 + 来源附录
- **签证 / 入境**：基于中国领事服务网 + 目的地国大使馆做实时核验
- **目的地速览**：天气、治安、货币、插头、SIM、常用药品、急诊医院、紧急联系
- **机票对比**：Google Flights / Skyscanner / 携程 / 去哪儿（按网络环境自动降级）
- **酒店编排**：用户已订酒店时，把泳池、儿童俱乐部、SPA 等设施纳入行程
- **预约方式调研**：Klook / KKday / 官网 / 礼宾代订，按渠道分档
- **交付**：HTML（默认）+ MD（群里复制）+ **PDF（微信文件传输助手直发）**

### 三个设计判断

不是花哨功能。每一条都是为了避开一类真实的失败模式。

1. **把工作流的停顿点写明**
   主流程拆成 5 个断点（启动 / 背景核验 / 骨架确认 / 餐饮预算 / 交付前），每个断点用结构化追问把决定权交回用户。不让 AI 一路猜到底——它一定会在某个点猜错，然后基于错的猜测继续猜下一层。

2. **划清 AI 能做和不能做的边界**
   用户没明说的字段不能猜（"4 大 2 小"不能脑补成"8 岁双胞胎"）；用户给的偏好是**硬约束**不是参考意见（"不吃辣"就不能推辣菜，哪怕是当地招牌）；外部链接没核验过就不写进最终交付物。

3. **降级要降，但不能偷偷降**
   第一次联网前先探测国内/海外网络环境，只能国内就切到携程、马蜂窝、中国领事服务网——但**显式告诉用户**切了，并标注"机票可能高 5-15%"这类差异。

### 安装

**推荐：通过 xman marketplace 一键安装（Claude Code）**

```
/plugin marketplace add fieai/xman
/plugin install travel-planner@xman
```

**或者直接软链 skill（任何 Agent Skill 宿主）**

skill 本体在 `skills/travel-planner/` 子目录下。

Claude Code 用户级：

```bash
git clone https://github.com/fieai/travel-planner-skill.git
ln -s "$(pwd)/travel-planner-skill/skills/travel-planner" ~/.claude/skills/travel-planner
```

Claude Code 项目级：

```bash
ln -s /path/to/travel-planner-skill/skills/travel-planner /path/to/your-project/.claude/skills/travel-planner
```

Codex 等其他 Agent Skill 宿主：按各自约定把 `skills/travel-planner/` 软链或复制到对应的 skill 目录。skill 内部已经做了能力探测，会按宿主环境自动 fallback（追问退化为编号选项、并行子任务退化为串行等）。

### 触发场景

skill metadata 里声明的触发条件：

- 用户要规划某地 X 天 Y 城行程
- 用户要查签证、入境政策、免签停留期
- 用户要目的地速览：天气、治安、货币、插头、SIM
- 用户提亲子游 / 蜜月 / 自驾 / 转机停留 / 主题游（极光 / 演唱会 / 潜水 …）
- 用户说"帮我规划一下"、"安排个行程"、"去 X 玩几天怎么走"

只想找酒店时让位给 `hotel-search` skill；本 skill 在交付阶段会主动 call out。

### 文件结构

```
travel-planner-skill/
├── .claude-plugin/
│   └── plugin.json                 Claude Code plugin manifest
├── skills/
│   └── travel-planner/
│       ├── SKILL.md                主入口
│       └── references/
│           ├── orchestration.md    5 个断点 + 子 agent prompt 模板
│           ├── data-sources.md     一手数据源清单
│           ├── template.html       HTML 交付模板
│           └── site-patterns/      域名级别的操作经验
├── LICENSE                         MIT
└── README.md
```

### 一个示例

输入：

> 帮我规划暑假带 6 岁娃去日本，2 大 1 小，从上海出发，10 天左右。

skill 走的流程：

1. **断点 A**：把"暑假"换算成绝对日期；问节奏档位（特种兵/紧凑/标准/度假/休养，不从"带娃"反推）；问必去和忌讳
2. **并行调研**：签证 + 暑期天气台风季 + 亲子向景点候选池
3. **断点 B**：如果日期不够办签证 → 提醒；台风季 → 提醒
4. **断点 C**：粗骨架（如 D1-D3 东京迪士尼 → D4-D6 富士山箱根 → D7-D10 大阪环球），让用户调
5. **断点 D**：餐饮（口味边界硬约束）+ 用户主动问预算时再给
6. **断点 E**：地图用 Google Maps，提示是否调 hotel-search 找亲子酒店，PDF 导出

每个断点 AI 会**停下来**，不会一路猜到底。

### 局限

- **中文用户视角**：默认中国大陆普通护照基线，签证 / 治安 / 货币 / SIM 都按中文用户最常用的源安排。海外用户能用，但不是最优解。
- **不写爬虫**：所有联网请求通过支持 CDP 的联网 skill 处理，避免反爬。
- **不保证价格准确**：机票、票价随时变。每份交付物末尾都写明"以本次查询时为准"，出发前请以官方页面为准。
- **不支持完全离线**：网络全断时直接停止，不硬撑。

### License

[MIT](./LICENSE)

---

## English

A travel planning skill for Agent Skill environments (Claude Code, Codex, and others), tailored to Chinese-speaking users planning international or domestic trips — family travel, honeymoons, road trips, transit stopovers, themed trips, and more.

It's not "a longer prompt."

It's a written-down workflow: when to stop and ask the user, when to research in parallel, when to refuse to guess, how to handle restricted network environments in mainland China, and how to deliver the final itinerary as a PDF you can drop into a WeChat chat.

The body is about 1,200 lines. None of them describe how to plan a specific day. Models can already plan days. What this skill writes down is when to ask, when to stop, and when to hold itself back.

### What it does

- **Itinerary planning** for X days across Y cities, with daily tables, map buttons, and a sources appendix
- **Visa / entry verification** against China's official consular site and destination embassies
- **Destination briefs**: weather, safety, currency, plug types, SIM, basic medication, ER hospitals, emergency contacts
- **Flight comparison** across Google Flights / Skyscanner / Ctrip / Qunar, with automatic source degradation when the user's network can't reach overseas sites
- **Hotel integration**: when the user has already booked a hotel, fold its facilities (pool, kids' club, spa) into the daily plan
- **Booking channel research**: Klook / KKday / official sites / concierge, ranked by reliability for Chinese users
- **Delivery**: HTML (default), Markdown (for group chat), and **PDF** (the only format that previews inline in WeChat)

### Three design calls

Not features. Each one exists to avoid a specific class of failure.

1. **Make every pause in the workflow explicit.**
   The main flow is broken into five checkpoints — kickoff, background verification, skeleton confirmation, food/budget, pre-delivery. Each one stops and hands the decision back to the user via a structured question. Don't let the model guess all the way through; it will be wrong somewhere, then keep guessing on top of the wrong guess.

2. **Draw a clear line between what the model may invent and what it may not.**
   Fields the user didn't specify (a child's exact age, a family's relationship structure) must not be fabricated. User preferences are **hard constraints**, not hints — "no spicy food" means no spicy food, even if it's the local signature dish. External URLs that haven't been verified this run don't go into the final document.

3. **When degrading, degrade visibly.**
   Before the first network call, probe whether overseas and domestic endpoints are reachable. If only domestic ones are, route to Ctrip / Mafengwo / the consular site — but **tell the user explicitly** and flag the cost (e.g. "flight prices may be 5–15% higher than overseas aggregators").

### Install

**Recommended: install via the xman marketplace (Claude Code)**

```
/plugin marketplace add fieai/xman
/plugin install travel-planner@xman
```

**Or symlink the skill directly (any Agent Skill host)**

The skill itself lives in `skills/travel-planner/`.

Claude Code (user-level):

```bash
git clone https://github.com/fieai/travel-planner-skill.git
ln -s "$(pwd)/travel-planner-skill/skills/travel-planner" ~/.claude/skills/travel-planner
```

Claude Code (project-level):

```bash
ln -s /path/to/travel-planner-skill/skills/travel-planner /path/to/your-project/.claude/skills/travel-planner
```

Codex and other Agent Skill hosts: symlink or copy `skills/travel-planner/` into your host's skill directory. The skill probes its environment at runtime and falls back gracefully (structured-question UI degrades to numbered prompts, parallel subagent spawns degrade to sequential execution, and so on).

### When it triggers

Declared in the skill metadata:

- Requests to plan an X-day trip to Y city/cities
- Visa / entry policy / visa-free stay lookups
- Destination briefs (weather, safety, currency, plug, SIM)
- Family trips, honeymoons, self-drive, transit stopovers, themed trips (aurora, concerts, diving …)
- Phrases like "help me plan a trip", "put together an itinerary", "what should I do for N days in X"

If the user only wants hotel search, the skill hands off to `hotel-search` rather than competing with it.

### File layout

```
travel-planner-skill/
├── .claude-plugin/
│   └── plugin.json                 Claude Code plugin manifest
├── skills/
│   └── travel-planner/
│       ├── SKILL.md                main entry
│       └── references/
│           ├── orchestration.md    five checkpoints + subagent prompt templates
│           ├── data-sources.md     primary-source catalogue
│           ├── template.html       HTML delivery template
│           └── site-patterns/      per-domain operational notes
├── LICENSE                         MIT
└── README.md
```

### One example

Input:

> Plan a summer trip to Japan with my 6-year-old. Two adults, one child, departing from Shanghai, around 10 days.

The skill's flow:

1. **Checkpoint A**: convert "summer" into absolute dates; ask for pace tier (commando / packed / standard / relaxed / wellness — **don't** infer from "child"); ask must-do's and dealbreakers
2. **Parallel research**: visa + typhoon-season weather + family-friendly attraction pool
3. **Checkpoint B**: if visa processing is too tight → flag it; typhoon overlap → flag it
4. **Checkpoint C**: rough skeleton (e.g. D1–D3 Tokyo Disney → D4–D6 Mt. Fuji/Hakone → D7–D10 Osaka Universal); user adjusts
5. **Checkpoint D**: food (taste preferences as hard constraints) + budget only if the user asks
6. **Checkpoint E**: Google Maps for international destinations, optional `hotel-search` handoff, PDF export

The model **stops** at every checkpoint. It does not guess to the end.

### Limitations

- **Chinese-user defaults**: assumes a PRC ordinary passport baseline; visa, safety, currency, and SIM advice draws on sources Chinese travellers actually use. Usable from elsewhere, but not optimised for it.
- **No scraping**: all network calls go through a CDP-capable companion skill, not raw fetches.
- **No price guarantees**: airfares and ticket prices change constantly. Every deliverable states the query timestamp; verify against official pages before booking.
- **No offline mode**: if all networks are down, the skill stops cleanly rather than hallucinate.

### License

[MIT](./LICENSE)
