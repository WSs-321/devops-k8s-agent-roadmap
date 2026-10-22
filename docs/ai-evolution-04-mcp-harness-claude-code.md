# AI 技术演进史（4/7）：MCP、Harness 与 Claude Code

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 上一部分：[RAG 与 Agent 时代](ai-evolution-03-rag-agent.md) ｜ 下一部分：[四条开发路线 · 算子与框架](ai-evolution-05-paths-system-layer.md)

---

## 7. MCP 与 Skill：能力标准化生态（2024）

### 7.1 N×M 集成问题：MCP 之前的世界有多乱

Function Calling 没有统一协议。每家 AI 应用（ChatGPT、Claude、Cursor、自研应用……）接入每个数据源（GitHub、飞书、数据库、浏览器……）都要单独写胶水代码：

```text
MCP 之前（N×M 问题）：
  5 个 AI 应用 × 5 个数据源 = 25 套定制集成代码
  新出一个 AI 应用？5 个数据源全部重新对接一遍

MCP 之后（N+M 问题）：
  每个数据源写 1 个 MCP Server（共 5 个）
  每个应用实现 1 个 MCP Client（共 5 个）
  = 10 份代码，且新应用接入零成本（自动发现全部工具）
```

MCP 的官方类比：**AI 世界的 USB-C**。鼠标、硬盘、显示器（工具/数据）都做成 USB-C 接口（MCP Server），笔记本（AI 应用）只要有 USB-C 口（MCP Client），插什么都能用。

### 7.2 MCP 协议架构（Anthropic 2024.11 发布）

```text
┌─────────────── Host（宿主应用）───────────────┐
│  Claude Code / Cursor / Claude Desktop       │
│  ┌────────────┐  ┌────────────┐              │
│  │ MCP Client │  │ MCP Client │   ← 每个连接对应一个 Server
│  └─────┬──────┘  └─────┬──────┘              │
└────────┼───────────────┼──────────────────────┘
         │ JSON-RPC      │ JSON-RPC
   ┌─────▼─────┐   ┌─────▼─────┐
   │ MCP Server│   │ MCP Server│   ← 工具/数据的提供方
   │  GitHub   │   │  飞书     │
   └───────────┘   └───────────┘
```

MCP Server 向 Host 暴露三类能力（协议原语）：

| 原语 | 方向 | 类比 | 例子 |
| ------ | ------ | ------ | ------ |
| **Tools** | 模型可调用（有副作用） | "手" | 创建 issue、发消息、执行 SQL |
| **Resources** | 应用可读取（只读数据） | "资料" | 读取文件内容、数据库 schema |
| **Prompts** | 用户可触发的模板 | "剧本" | "代码审查"提示词模板 |

**现状**：2025 年 OpenAI、Google 相继宣布支持 MCP，行业事实标准确立。GitHub、Playwright、飞书等官方 Server 生态爆发。

### 7.3 Demo：写一个 MCP Server 并接入 Claude Code（可运行）

```python
# pip install "mcp[cli]"
# 文件名：k8s_ops_server.py

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("k8s-ops")  # Server 名称

@mcp.tool()  # ← 装饰器一挂，自动生成工具 schema，无需手写 JSON Schema
def get_pod_status(namespace: str, pod: str) -> str:
    """查询指定命名空间下某个 Pod 的运行状态"""  # ← docstring 自动成为工具描述
    # 生产中：subprocess 调 kubectl，或调 K8s API
    return f"{namespace}/{pod}: Running, restarts=1, age=3d"

@mcp.tool()
def list_deployments(namespace: str = "default") -> str:
    """列出指定命名空间下的所有 Deployment"""
    return "web-api(3副本), worker(2副本), nginx-ingress(1副本)"

if __name__ == "__main__":
    mcp.run()  # 以 stdio 模式启动，等待 Host 连接
```

接入 Claude Code（一行命令）：

```bash
claude mcp add k8s-ops -- python k8s_ops_server.py
```

之后在 Claude Code 里直接说："看看 default 下有哪些 Deployment，web-api 有几个副本"——Claude 会**自动发现并串行调用** `list_deployments` → `get_pod_status`，你不需要写任何编排代码。

**对比第 6 章 Demo**：同样的"先查再查"多步任务，第 6 章我们手写了 60 行循环；现在 Loop 由 Claude Code（Harness）提供，你只写 10 行工具实现——**这就是标准化的意义**。

### 7.4 Skill：知识型能力的模块化（Anthropic 2025 推出 Agent Skills）

MCP 解决"工具"标准化，Skill 解决"方法/知识"标准化：

```text
MCP = 给 Agent"手"：让它能操作外部系统
Skill = 给 Agent"脑补"：教它一套做事的流程和经验
```

**Skill 本质**：一个文件夹 + 一个 SKILL.md，包含流程、模板、约束、示例。Agent 平时不需要加载它，**当任务匹配到 Skill 描述时才注入上下文**——这就是它相对"把所有规则塞进系统提示词"的核心优势：**不占常驻上下文预算，按需加载**。

#### Demo：一个"周报生成" Skill 的完整定义

```text
.github/skills/weekly-report/
└── SKILL.md
```

```markdown
---
name: weekly-report
description: 生成周报。当用户要求"写周报 / 总结本周工作"时使用。
---

# 周报生成技能

## 执行流程
1. 读取 `logs/week-*/day-*.md`，提取本周所有学习记录
2. 按主题归类（K8s / CI/CD / Agent 等）
3. 按"输出模板"生成周报

## 输出模板
- 本周完成：{3-5 条要点}
- 遇到的问题：{1-2 条}
- 下周计划：{2-3 条}

## 约束
- 每条不超过 30 字
- 必须基于 logs 目录真实记录，禁止编造
```

**使用效果**：用户说"写个周报" → Agent 读取 SKILL.md → 按里面的流程逐步执行。周报"怎么写"的知识被沉淀成可复用资产，团队所有人共享，不依赖每个人都会写提示词。

**为什么 Skill 现在很普遍**：它把"提示词工程"从个人手艺升级为团队资产管理——写一次，所有会话/所有人生效；版本化、可评审、可分享。Trae、Cursor 等主流 Agent IDE 均采用类似机制。

### 7.5 四种能力机制对比（最易混淆处，务必分清）

| 维度 | Function Calling | MCP | Skill |
| ------ | ----------------- | ----- | ------- |
| 解决什么 | 模型怎么调工具 | 工具怎么标准化接入 | 经验怎么沉淀复用 |
| 类比 | 会伸手拿东西 | USB-C 统一接口 | 师傅留下来的操作手册 |
| 形态 | API 参数约定 | 开放协议（JSON-RPC） | Markdown 文件（SKILL.md） |
| 谁维护 | 每个应用各自实现 | 工具提供方写一次 | 团队沉淀，按需加载 |
| 关系 | 被 MCP 覆盖/兼容 | 生态基础 | 与 MCP 互补：手 + 脑补 |

一句话：**MCP 给 Agent 插手，Skill 给 Agent 塞锦囊**。

---

## 8. Agent Harness：把"能用的模型"变成"可靠的产品"（2024-2025）

### 8.1 什么是 Harness：大脑与身体

第 6 章末尾说过：模型 + 工程 + 生态 = Harness。如果说 LLM 是大脑，**Harness 就是让大脑可靠运转的身体**——一套围绕模型构建的工程化运行时。

第 6 章 Demo 里那个 40 行的 `agent_loop` 是"裸循环"；把裸循环加上各种工程保障，就是 Harness：

```text
┌─────────────────────── Agent Harness ───────────────────────┐
│                                                              │
│  1. 主循环 Agentic Loop                                       │
│     探索 → 行动 → 观察 → 反思 → 行动……（含步数熔断/错误重试）    │
│                                                              │
│  2. 上下文工程 Context Engineering（新核心竞争力）             │
│     ├─ 上下文预算管理：系统提示词/Skill/工具结果/历史 各占多少    │
│     ├─ 压缩：任务太长时自动摘要旧轮次，保住关键信息              │
│     └─ 注入：按需检索注入项目文档（RAG 复活为 Harness 零件）      │
│                                                              │
│  3. 工具编排 Tool Orchestration                               │
│     ├─ MCP Client 管理 + 工具自动发现                          │
│     ├─ 子 Agent：把"全库搜索"类脏活外包出去，保护主上下文         │
│     └─ 工具结果截断/去噪（工具吐 5MB 日志会撑爆上下文）          │
│                                                              │
│  4. 反馈回路 Feedback                                         │
│     ├─ 执行后自检（编译/测试/lint 结果回喂模型）                 │
│     └─ 失败自动修正，N 次失败后求助人类                         │
│                                                              │
│  5. 安全护栏 Guardrails                                       │
│     ├─ 危险命令审批（rm/force push 必须人确认）                  │
│     ├─ 沙箱：代码在隔离环境执行                                 │
│     └─ Plan Mode：先出方案，人批准后才动手                       │
│                                                              │
│  6. 可观测性 Observability                                    │
│     └─ Hooks：任务前/后钩子，记录轨迹、注入规范（如 commit 规则） │
└──────────────────────────────────────────────────────────────┘
```

**"上下文工程"为什么是 2025 年的热词取代"提示词工程"**：Agent 的成败越来越取决于"每一轮往上下文窗口里放什么、扔什么"——同样的模型，上下文管理差的 Harness 会 10 步就"失忆"，好的能稳定跑 50 步完成任务。

### 8.2 为什么 Harness 是 2024 年的分水岭

| AutoGPT（2023，失败） | Harness 产品（2024，可用） |
| ---------------------- | --------------------------- |
| 无限循环，烧钱失控 | 步数上限 + 熔断 + 预算控制 |
| 工具报错照走不误 | 报错作为观察结果回喂，自动修正 |
| 上下文无限增长直到截断 | 自动压缩、子 Agent 分流 |
| 危险命令直接执行 | 审批/沙箱/白名单 |
| 黑盒，不知道它要干嘛 | Plan Mode + 轨迹可视化 |

### 8.3 代表性 Harness 产品格局

| 产品 | 形态 | 定位 |
| ------ | ------ | ------ |
| Claude Code | 终端 CLI | 编码 Agent 标杆（下一章主角） |
| Cursor / Windsurf | IDE | IDE 内置 Agent Harness |
| OpenHands（原 OpenDevin） | 开源 | 自主软件工程 Agent |
| Aider | 开源 CLI | 终端结对编程 |
| Devin（Cognition） | 云服务 | "全自主软件工程师" |

**共同点**：都是"模型 + Loop + 上下文工程 + 工具生态 + 护栏"的打包品——**模型是租来的（调 API），Harness 才是产品**。

---

## 9. Claude Code 与编码 Agent 爆发（2024-2025）

### 9.1 发展脉络

```text
2024.06  Claude 3.5 Sonnet 发布 —— 代码能力登顶，编码 Agent 的"模智力"前提达成
2024.10  Computer Use 发布 —— AI 直接操作屏幕（GUI Agent 起点）
2025 初  Claude Code 发布（Anthropic 官方，终端形态）—— 数周内引爆开发者圈
2025     持续进化：Subagent / Hooks / Skill 支持 / MCP 深度集成 / Plan Mode
```

### 9.2 Claude Code 是什么：前面 8 章技术的集大成者

Claude Code 不是一个新发明，而是**把本教程前 8 章的技术全部打包**的产品：

| 用到的技术 | 来自哪章 | 在 Claude Code 中的角色 |
| ----------- | --------- | ------------------------ |
| 强力 LLM + 长上下文 | 第 4 章 | 理解整个代码库的"大脑" |
| 代码库语义检索 | 第 5 章 RAG | 快速定位相关文件 |
| Agentic Loop（探索→改→跑测试→修） | 第 6 章 | 核心工作循环 |
| MCP | 第 7 章 | 接入 GitHub/飞书/浏览器等外部系统 |
| Skill | 第 7 章 | 团队规范/工作流沉淀（如本仓库的提交规则） |
| Harness 全家桶 | 第 8 章 | 子 Agent 上下文保护、Plan Mode 审批、Hooks |

### 9.3 实战：Claude Code 的真实工作流

```bash
# 首次使用：让 Agent 理解项目约定（生成 CLAUDE.md —— 类似团队 Skill）
claude init

# ── 日常模式：一句话任务，Agent 自主闭环 ──
claude "修复 Ingress 404 问题，跑通测试后汇报"
```

上面那条命令背后，Agent 自主完成的完整轨迹（Harness 的 Agentic Loop 落地）：

```text
用户: "修复 Ingress 404 问题"
  → [Read]   docs/ingress-config.md          # 自主探索：先看文档
  → [Grep]   "pathType"                      # 定位关键词
  → [Bash]   kubectl describe ingress xxx    # 集群取证（MCP/工具调用）
  → [分析]   发现 pathType: ImplementationSpecific 导致路径不匹配
  → [Edit]   ingress.yaml                    # 修改
  → [Bash]   kubectl apply -f ingress.yaml && curl -I https://xxx  # 验证
  → [自检]   HTTP 200 ✅
  → 汇报结果 + 建议提交
# 整个过程无需人工编排 —— 这就是第 6 章手写 agent_loop 的工业级版本
```

其他关键能力（对应 Harness 组件）：

```bash
claude --permission-mode plan   # Plan Mode：先出方案，人批准才动手（护栏）
claude "让子 agent 全库搜 deprecated API 调用点"  # Subagent：脏活外包，保护主上下文
```

### 9.4 为什么"编码"成了 Agent 第一个爆发场景

这是理解整个 Agent 时代的钥匙——不是偶然：

| 条件 | 说明 |
| ------ | ------ |
| **反馈信号天然明确** | 编译通过/测试通过/报错信息——客观、机器可读、可回喂（第 8 章 Feedback 组件的前提） |
| **环境天然闭环** | 改码 → 运行 → 看结果 → 修，全部发生在同一台机器，无需人工干预 |
| **与既有工程栈无缝融合** | Git/CI/CD/测试本来就是自动化的，Agent 直接接入 |
| **可量化** | SWE-bench 等基准让进步清晰可见，倒逼模型迭代 |

反过来说：没有客观反馈的领域（开放式战略决策），Agent 依然难以可靠工作——**反馈信号存在与否，是判断"这个场景 Agent 能不能落地"的第一问**。

### 9.5 竞品格局（2025）

OpenAI Codex CLI / Gemini CLI / Cursor Agent / GitHub Copilot Agent——形态各异，内核同构（全是 Harness）。编码 Agent 成为整个 AI 行业 PMF（产品市场契合）最清晰的赛道。

---

## 10. 进行中的前沿方向（2025+）

| 方向 | 一句话说明 | 与前文的衔接 |
| ------ | ----------- | ------------ |
| **推理模型** | o1/o3、Claude 思考模式：生成前先"长思考"（测试时计算 Test-time Compute） | 思维链（CoT）的工程化 |
| **A2A 协议**（Google） | Agent 之间互相通信的标准——MCP 连"工具"，A2A 连"Agent" | MCP 的横向扩展 |
| **Agentic RAG** | 检索成为 Agent 的动态工具 | 第 5、6 章的合流 |
| **多 Agent 协作** | 规划者/执行者/评审者分工（本仓库日常使用的 Task/Subagent 即此类） | Harness 的子 Agent 延伸 |
| **Computer Use / GUI Agent** | 直接看屏幕、点鼠标操作任何软件，绕过"没有 API"的限制 | 多模态 + 工具使用的合流 |
