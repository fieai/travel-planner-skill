# travel-planner

一个为 Claude Code / Codex 等支持 Agent Skills 的环境设计的 **旅行行程规划 skill**，面向中文用户的出境与国内自由行、亲子游、蜜月、自驾、转机停留等场景。

它不是“把 prompt 写得长一点”，而是把一整套**可靠的行程规划工作流**写出来：什么时候停下来问用户、什么时候并行调研、什么时候不能猜、怎么处理国内网络环境、怎么把最终行程交付成微信可直发的 PDF。

主体逻辑约 1200 行，没有一行是关于“具体怎么排某一天”的——行程怎么排，模型本身就会；什么时候问、什么时候停、什么时候按住自己，才是 skill 要替模型想清楚的部分。

---

## 它能做什么

- **出境 / 国内自由行**：规划 X 天 Y 城行程，输出每日表格 + 地图按钮 + 来源附录
- **签证 / 入境**：基于中国领事服务网 + 目的地国大使馆做实时核验
- **目的地速览**：天气、治安、货币、插头、SIM、常用药品、急诊医院、紧急联系
- **机票对比**：Google Flights / Skyscanner / 携程 / 去哪儿（按网络环境降级）
- **酒店编排**：用户提供已订酒店时，把酒店设施（泳池、儿童俱乐部、SPA）纳入行程
- **预约方式调研**：Klook / KKday / 官网 / 礼宾代订，三档可选
- **交付**：HTML（默认）+ MD（群里复制）+ **PDF（微信文件传输助手直发）**

主流程下面还可以挂一个 `hotel-search` skill 做酒店检索，本 skill 不重复造这块的轮子。

---

## 核心设计取舍

这些是 skill 里写死的判断，不是花哨功能。每一条都解决了一类真实的失败模式：

### 1. 5 个断点，不一口气拍完

主流程被拆成 A（启动）→ B（背景核验）→ C（骨架确认）→ D（预算+餐饮）→ E（交付前）五个断点。每个断点用结构化追问一次性把问题抛给用户，让用户选。

不让 AI 一口气把整个行程做完再给你看——那样它一定会在某个点猜错，再基于错的猜测继续猜下一层，等你看到时整个行程已经长歪。

### 2. 不编造未提供的字段

用户给“4 大 2 小”就是“4 大 2 小”，不要脑补成“8 岁双胞胎”或“两户都是同年龄孩子”。任何用户没明确说的字段（孩子具体年龄、性别、家庭关系结构、病史）必须先问，不要猜出一个“合理”假设直接写进交付物。

这是 skill 里最重要的一条硬规则。AI 太想给你一个看起来像样的答案，于是把不知道的部分全用合理猜测填了。

### 3. 用户的约束是约束，不是参考

“我们家不吃辣”不是“风格倾向”，是**硬约束**。子 agent 的 prompt 里写死：哪怕辣菜是当地招牌，也不能推。

### 4. 网络环境探测 + 降级

第一次联网前先打 `google.com` 和 `baidu.com`（5s 超时），结果分四种：海外通 / 仅国内 / 仅海外 / 全断。

如果只能访问国内站点，自动切到携程、飞猪、马蜂窝、中国领事服务网——但**显式告诉用户**“当前为降级模式，机票价格可能比海外平台高 5-15%，小众目的地攻略可能找不到”。降级要降，但不能偷偷降。

### 5. 链接必须核验

不把子 agent 给的具体活动 URL 直接抄进交付物——子 agent 经常给“看起来对”但实际失效的 Klook 活动 ID。安全做法：给搜索页 + 关键词形式（如 `klook.com/search?keyword=烹饪课`），让用户站内点选。

### 6. PDF 兜底

HTML 在微信里点开是直接下载，MD 复制到群里样式全没。PDF 是真正能在微信里直接预览的格式。所以 E 阶段默认推荐生成 PDF——一行 Chrome headless 命令从 HTML 导出，发文件传输助手就完事了。

---

## 安装

skill 在 `skill/` 子目录下。安装就是把 `skill/` 软链或复制到你的 skill 目录。

### Claude Code（用户级）

```bash
git clone https://github.com/fieai/travel-planner-skill.git
ln -s "$(pwd)/travel-planner-skill/skill" ~/.claude/skills/travel-planner
```

### Claude Code（项目级）

```bash
ln -s /path/to/travel-planner-skill/skill /path/to/your-project/.claude/skills/travel-planner
```

### Codex 等无 Skill 概念的环境

在 prompt 里指明：

```
请加载并遵循 /path/to/travel-planner-skill/skill/SKILL.md 中的工作流，
所有联网请求走 web-access 子任务，最终输出 HTML + MD + PDF。
```

skill 本身已经处理了 Codex 的 fallback（追问退化为编号选项、子任务串行执行）。

---

## 依赖

| Skill | 作用 | 是否必需 |
|------|------|--------|
| [`web-access`](#) | 所有联网（CDP / WebFetch / curl 统一入口）| 必需 |
| [`hotel-search`](#) | 酒店检索（E 断点交接） | 可选，没有就跳过 |
| Chrome | PDF 导出 | 可选，没有就只输出 HTML+MD |

把 `web-access` 替换成你自己的联网 skill 也可以，只要它接收“目标导向 + 强一手要求 + 结构化返回”的 prompt 即可。

---

## 触发场景

skill metadata 里声明的触发条件：

- 用户要规划某地 X 天 Y 城行程
- 用户要查签证、入境政策、免签停留期
- 用户要目的地速览：天气、治安、货币、插头、SIM
- 用户提亲子游 / 蜜月 / 自驾 / 转机停留 / 主题游（极光 / 演唱会 / 潜水 …）
- 用户说“帮我规划一下”“安排个行程”“去 X 玩几天怎么走”

只想找酒店时让位给 `hotel-search`；本 skill 在 E 阶段主动 call out。

---

## 文件结构

```
travel-planner-skill/
├── skill/                          # 这是真正的 skill，链到 ~/.claude/skills/travel-planner
│   ├── SKILL.md                    # 主入口，约 400 行
│   └── references/
│       ├── orchestration.md        # 5 个断点 + 子 agent prompt 模板（约 420 行）
│       ├── data-sources.md         # 一手数据源清单（约 200 行）
│       ├── template.html           # HTML 交付模板（约 400 行）
│       └── site-patterns/          # 域名级别的操作经验（按需积累）
├── scripts/
│   └── sync-from-source.sh         # 如果你 fork 后维护本地版本，可用此脚本从上游拉
├── LICENSE                         # MIT
└── README.md
```

---

## 一个简单示例

输入：

> 帮我规划暑假带 6 岁娃去日本，2 大 1 小，从上海出发，10 天左右。

skill 走的流程：

1. **A 断点**：日期“暑假”要换算成 `YYYY-MM-DD`；问节奏档位（特种兵/紧凑/标准/度假/休养，**不从“带娃”反推**）；问必去 / 忌讳
2. **并行调研**：签证（中国普通护照赴日单次签证、办证时长）+ 速览（暑期天气、台风季、SIM）+ 景点候选池（亲子向）
3. **B 断点**：日期 < 标准受理时长 → 提醒；台风季 → 提醒
4. **C 骨架**：D1-D3 东京迪士尼 → D4-D6 富士山+箱根 → D7-D8 名古屋乐高 → D9-D10 大阪环球，让用户调
5. **D**：餐饮（口味边界）+ 用户主动问预算
6. **E**：地图按 Google Maps，提示 hotel-search 找亲子酒店，PDF 导出

每个断点 AI 会**停下来**，不会一路猜到底。

---

## 局限

- **中文用户视角**：默认中国大陆普通护照基线，签证 / 治安 / 货币 / SIM 都按中文用户最常用的源（中国领事服务网、携程、马蜂窝、小红书）安排。海外用户能用，但不是最优解。
- **不写爬虫**：所有联网交给 `web-access`。CDP 走 web-access、curl 走 web-access、Jina 也走 web-access。
- **不保证价格准确**：机票、票价随时变。skill 在每份交付物末尾都写明“以本次查询时为准”，但请用户出发前一律以官方页面为准。
- **不支持完全离线**：网络全断时主流程直接告诉用户停止，不硬撑。

---

## 维护方式

如果你 fork 了这个仓库并想跟上游同步：

```bash
./scripts/sync-from-source.sh
```

脚本会把 `skill/` 下的文件覆盖为上游最新版本（保留你自己 fork 的 README / LICENSE / scripts）。

---

## License

MIT — 见 [LICENSE](./LICENSE)。

---

## 贡献

issue / PR 都欢迎。重点关注：

- 新增的目的地国大使馆 URL（`skill/references/data-sources.md`）
- 新发现的站点反爬模式（`skill/references/site-patterns/{domain}.md`）
- 在某个失败模式上的新硬规则（`skill/SKILL.md` 核心原则节）

不接受的改动：

- 把 skill 拆得更小（5 个断点是核心设计，不要打散）
- 把 web-access 内联进 skill（要走 web-access skill）
- 把“强一手”降级到“攻略文章为主”
