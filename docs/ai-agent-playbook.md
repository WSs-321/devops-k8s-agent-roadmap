# AI Agent 实战手册：Subagent、多 Agent 协作与高效使用技巧

> 系列关联：[AI 技术演进史目录](ai-evolution-history.md)（第 7-9 章讲了 MCP、Harness 与 Agent 的来龙去脉，本文是它们的落地操作篇）

## 1. 演进脉络：从单兵作战到 AI 团队

Agent 的使用形态过去四年走了五个台阶，每一级都是"上一级的痛点"催生的：

| 阶段 | 形态 | 痛点与解法 | 代表 |
| --- | --- | --- | --- |
| L1 | 单轮对话 | 人工复制粘贴上下文，模型只能"说"不能"做" | ChatGPT（2022） |
| L2 | 工具调用 Agent | 模型学会调函数/读写文件，能"做"了，但所有事挤在一个上下文里 | Function Calling、ReAct（2023） |
| L3 | Subagent 子代理 | 上下文爆炸 → 干脆开"分身"：独立窗口、独立人设、受限工具 | Claude Code Task 工具（2024） |
| L4 | 多 Agent 编排 | 单主控编排一群分身：并行开发、生成-评审、流水线 | AutoGen、LangGraph、Claude Code 多 Agent |
| L5 | 全 AI 流水线 | 人只写需求单，spec → 计划 → 编码 → 审查 → 合并全自动 | headless agent + CI + 自动合并（2025 起） |

一句话总结：**L2 解决"能不能动手"，L3 解决"上下文装不下"，L4 解决"一个人干不完"，L5 解决"人要不要在场"**。

## 2. 核心机制：Subagent（子代理）是什么

### 2.1 定义

Subagent 是主 Agent 派生出的"分身"：

- 独立的上下文窗口：与主对话完全隔离，干完活只把摘要带回主上下文；
- 独立的 system prompt：可以给它一个完全不同的人设和领域知识；
- 受限的工具集：只给该岗位需要的工具（例如审查员只读不写）；
- 可并行：多个 subagent 同时干活，互不干扰。

### 2.2 用"招聘"来理解

把配置一个 subagent 想成写一份 JD（岗位说明）：

| JD 要素 | Subagent 对应字段 |
| --- | --- |
| 岗位名称 | name |
| 什么时候找他 | description（写得越像"何时用"，主 Agent 自动委派越准） |
| 岗位职责与方法论 | prompt 正文（system prompt） |
| 权限范围 | tools 白名单 |
| 汇报要求 | prompt 里规定输出格式（只回摘要，不倒垃圾进主上下文） |

### 2.3 为什么有效

1. 上下文隔离：大规模检索、读长文件这类"脏活"在子窗口里完成，主对话保持干净；
2. 专业分工：窄而深的 prompt 比万能 prompt 准确率高；
3. 权限最小化：reviewer 型 subagent 只发只读工具，从机制上杜绝误改代码；
4. 并行提速：三个互不依赖的任务，三个分身同时跑。

## 3. Claude Code 配置体系与技巧

### 3.1 配置文件全景

| 文件/目录 | 作用 |
| --- | --- |
| `CLAUDE.md` | 项目记忆：规范、约定、常用命令，每轮自动注入 |
| `.claude/agents/*.md` | 项目级 subagent 定义（`~/.claude/agents/` 为全局） |
| `.claude/commands/*.md` | 自定义斜杠命令，模板化重复任务 |
| `.claude/settings.json` | 权限白名单、hooks、环境变量 |
| `.mcp.json` | MCP 服务器接入配置（项目级，可提交进 git） |

### 3.2 Subagent 定义示例

`.claude/agents/k8s-reviewer.md`：

```markdown
---
name: k8s-reviewer
description: K8s manifest 审查专家。检查 YAML 安全性与最佳实践时主动使用
tools: Read, Grep, Glob
model: sonnet
---

你是资深 K8s 工程师，只做代码审查，不修改任何文件。

审查清单（逐项核对并给出结论）：
1. 镜像是否固定 tag，是否非 root
2. 是否声明 resources 与 probe
3. Secret 是否明文出现在 YAML 中
4. Service 端口与 containerPort 是否对得上

输出格式：按条列出问题，每条给文件与行号；无问题则明确说"通过"。
```

要点：

- frontmatter 的 `description` 是自动委派的触发器，要写"什么场景该找我"，而不是"我是谁"；
- `tools` 不写的字段默认继承主会话工具，审查类岗位务必显式收窄；
- 用 `/agents` 命令可以交互式创建、编辑、查看已加载的 subagent。

### 3.3 常用技巧清单

| 场景 | 技巧 |
| --- | --- |
| 项目规则 | `CLAUDE.md` 用规则化短句（"commit message 用中文 ≤10 字"），别写散文；它每轮都注入，长度就是 token 成本 |
| 先看方案再动手 | Plan Mode（Shift+Tab 切换）：只读分析、出方案，点头后才落盘 |
| 上下文快满了 | `/compact` 压缩历史；切换到不相关的新任务用 `/clear`，别硬续 |
| 断点续传 | `claude --continue` 续最近会话，`claude --resume` 从列表挑选 |
| 并行多任务 | `git worktree add ../repo-task7 task-branch`，每个 worktree 开一个 agent 终端，互不踩文件 |
| 重复流程模板化 | `.claude/commands/deploy-check.md` 里写 `$ARGUMENTS` 占位，之后 `/deploy-check 生产环境` 一键触发 |
| 自动格式化 | hooks：`PostToolUse` 编辑文件后自动跑 `ruff format` / `npx prettier` |
| 接入 CI | `claude -p "审查这个 PR" --output-format json --max-turns 5`，headless 单次执行，结果喂给脚本 |
| MCP 取舍 | 服务器宁缺毋滥：每个都注入工具描述，装多了污染上下文、扩大攻击面 |

### 3.4 自定义斜杠命令示例

`.claude/commands/pr-review.md`：

```markdown
审查当前分支相对 main 的改动：$ARGUMENTS

步骤：
1. 运行 git diff main 获取改动
2. 逐文件评估正确性、安全性、可维护性
3. 按严重程度输出：blocker / warn / nitpick 三档
```

## 4. Codex CLI 配置与技巧

### 4.1 配置体系

| 文件 | 作用 |
| --- | --- |
| `AGENTS.md` | 项目说明（地位同 CLAUDE.md），Codex 按"全局 → 仓库根 → 当前目录"逐级读取并拼接 |
| `~/.codex/config.toml` | 模型、审批策略、沙箱、profile 等全局配置 |
| `~/.codex/prompts/*.md` | 自定义提示词模板 |

### 4.2 两个关键开关

```toml
# ~/.codex/config.toml
model = "gpt-5-codex"

# 审批策略：untrusted(每条命令都问) / on-failure / on-request / never
approval_policy = "on-failure"

# 沙箱：read-only / workspace-write / danger-full-access
sandbox_mode = "workspace-write"
```

- `approval_policy` 控制命令执行的"确认粒度"，`on-failure` 是效率与安全的平衡点；
- `sandbox_mode` 控制文件与网络边界：日常开发用 `workspace-write`，跑完即弃的实验用 `read-only`；
- `danger-full-access` 只该出现在一次性容器里。

### 4.3 与 Claude Code 的差异速览

| 维度 | Claude Code | Codex CLI |
| --- | --- | --- |
| 项目记忆 | CLAUDE.md | AGENTS.md |
| 子代理 | .claude/agents，机制成熟 | 以单 Agent + 工具为主，编排能力较新 |
| 权限模型 | 权限模式 + 白名单 + hooks | 审批策略 + 沙箱双开关 |
| 非交互模式 | `claude -p --output-format json` | `codex exec "任务描述"` |
| 配置格式 | Markdown + JSON | Markdown + TOML |

## 5. 其他主流工具速览

| 工具 | 项目规则文件 | 特点 |
| --- | --- | --- |
| Cursor | `.cursor/rules/*.mdc` | IDE 深度集成，规则可按 glob 条件触发 |
| Windsurf | `.windsurf/rules/` | flows 工作流编排 |
| Gemini CLI | `GEMINI.md` | 免费额度大，`--yolo` 自动确认模式 |
| Aider | `CONVENTIONS.md` + 启动参数 | git 原生，每步自动提交，擅长精准改码 |
| Trae | `.trae/rules/*.md` | 内置多 subagent 协作面板 |

规律：**几乎所有工具都收敛到"一个项目级 Markdown 规则文件 + 若干可版本化的配置文件"这套模式**。写好这两个东西，换个工具也能快速迁移。

## 6. 多 Agent 协作编排模式

### 6.1 四种主流拓扑

```text
1) 编排者-工人 (Orchestrator-Worker)     2) 流水线 (Pipeline)
   ┌─────────┐                          ┌──────┐ ┌──────┐ ┌──────┐
   │ 主 Agent │──┬─→ subA               │ 计划 │→│ 实现 │→│ 审查 │
   └─────────┘  ├─→ subB                 └──────┘ └──────┘ └──────┘
                └─→ subC（并行）

3) 生成-评审 (Generator-Critic)          4) 黑板 (Blackboard)
   ┌──────┐ 产出 ┌──────┐               所有 agent 读写同一批文件
   │ 写码 │ ←─── │ 挑刺 │               plans/xxx.md、notes/*.md
   └──────┐ 轮次 └──────┘               通过文件系统交换状态
```

| 模式 | 适用场景 | 风险 |
| --- | --- | --- |
| 编排者-工人 | 多个独立子任务（多模块改造、批量迁移） | 工人产出冲突，需主 Agent 集成 |
| 流水线 | 强顺序依赖（计划→实现→测试→评审） | 任何一环翻车即整体返工 |
| 生成-评审 | 质量敏感（安全审查、文案打磨） | 两个 agent 互相客套，需要 prompt 逼真挑刺 |
| 黑板 | 长周期项目、人类也参与其中 | 文件成为隐式契约，格式要提前约定 |

### 6.2 什么时候不要用多 Agent

- 单文件小改动：直接单 Agent，编排开销 > 收益；
- 任务强顺序依赖：并行无意义，还引入等待与合并成本；
- 上下文装得下：能一个窗口解决的事，拆了反而丢失全局视野；
- 没有验证手段：多 Agent 并行产出大量代码，没有测试/lint 兜底就是灾难放大器。

经验值：**并行收益成立的两个前提——子任务接口清晰 + 有客观验证**（测试、lint、编译）。

### 6.3 编排实操守则

1. 主 Agent 只做拆解与集成，具体检索与实现下放 subagent；
2. 每个 subagent 的产出物落成文件（如 `plans/api.md`），别只存在于对话里；
3. 输出格式在 prompt 里写死（模板化），方便主 Agent 程序化合并；
4. 给 subagent 限定目录边界：你只改 `src/auth/`，越界即报错。

## 7. 全 AI 式合作：端到端流水线

### 7.1 一条最小可用流水线

人的唯一输入是一份需求单 `spec.md`，之后全自动：

```text
spec.md ──→ 计划 Agent（产 plan.md，人工过目一次）
        ──→ 实现 Agent（开 feature 分支写码，自跑测试）
        ──→ 审查 Agent（headless 审 PR diff，输出 JSON 结论）
        ──→ 传统 CI（markdownlint / 编译 / 单测，客观门禁）
        ──→ 全绿 → gh pr merge --squash --auto
```

### 7.2 GitHub Actions 里的 headless 审查（片段）

```yaml
- name: AI Review
  run: |
    claude -p "审查 PR ${{ github.event.number }} 的 diff，只报告正确性与安全问题，输出 JSON: {verdict, issues[]}" \
      --output-format json > review.json
    # verdict != pass 则后续步骤 exit 1
```

### 7.3 角色分工表

| 角色 | 承担者 | 输出物 |
| --- | --- | --- |
| 需求 | 人类 | spec.md（唯一必须人写的） |
| 计划 | 计划 Agent | plan.md（人审一次，最高杠杆环节） |
| 实现 | 实现 Agent | 分支 + 代码 + 测试 |
| 审查 | 审查 Agent + 传统 CI | 结构化审查报告 + lint/test 结果 |
| 合并 | 策略 | 全绿自动 squash merge |

定位变化：**人从"写代码的人"变成"写需求单和验收方案的人"**。评审人审 plan 比审几千行 diff 划算得多——方向错了，后面全白干。

## 8. 跨工具通用技巧十条

1. 需求写验收标准："完成"必须可判定——给出测试命令、lint 命令，让 Agent 自己证明自己；
2. 小步快跑：一个任务一个分支一个 PR，别让 Agent 一口气改二十个文件；
3. 让 Agent 自验证：改完自己跑测试、自己跑 lint，红了先自己修；
4. 上下文极简：大文件按需读片段，无关文件不读；上下文不是越多越好，是越准越好；
5. 规则文件分层：全局（个人偏好）→ 项目（团队规范）→ 目录（模块特例），越靠近代码的优先级越高；
6. 危险操作白名单 + 人工确认：`git push --force`、`rm -rf`、删分支类操作永远留在确认清单里；
7. 并行先隔离再开火：多 Agent 并行改同一仓库，用 git worktree 或容器隔离工作区，事后合并；
8. 产出落盘：重要结论让 Agent 写进文件（`docs/`、`plans/`），对话里的东西会随 `/clear` 消失；
9. 配置进 git：`.claude/`、`.codex/` 下的 agents/commands/rules 全部版本化，团队共享同一套"AI 员工"；
10. 记录翻车日志：每次 Agent 干砸的原因记进规则文件（比如"不要让它直接操作 main"），这是喂给下一轮最好的上下文。

## 9. 配置文件速查表

| 工具 | 项目记忆 | 自定义命令 | 子代理 | 非交互模式 |
| --- | --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` | `.claude/commands/` | `.claude/agents/` | `claude -p` |
| Codex CLI | `AGENTS.md` | `~/.codex/prompts/` | -（较新） | `codex exec` |
| Cursor | `.cursor/rules/` | - | - | `cursor-agent` |
| Gemini CLI | `GEMINI.md` | `.gemini/commands/` | - | `gemini -p` |
| Trae | `.trae/rules/` | - | 内置多 subagent | - |

互操作趋势：MCP 统一了"Agent 接工具"，ACP（Agent Client Protocol）、A2A 等协议正在统一"Agent 接 Agent"；长期看，subagent 配置与编排会像 Dockerfile 一样成为可移植资产。

## 10. 结语：渐进式上车路线

按这个顺序演进，每一步站稳了再上下一步：

1. 先把单 Agent 用透：规则文件写好、plan 模式用熟、自验证跑通；
2. 再模板化：斜杠命令固化重复流程；
3. 然后拆分身：把检索、审查这类"脏活重活"下放 subagent；
4. 最后才编排：接口清晰 + 验证齐备的任务交给多 Agent 并行；
5. 终局是流水线：人只保留两件事——写 spec、审 plan。

一句话：**多 Agent 不是用来炫技的，是用来还上下文债的**。哪里上下文爆了、哪里并行有收益、哪里有客观验收，就在哪里拆。
