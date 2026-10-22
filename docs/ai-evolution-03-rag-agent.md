# AI 技术演进史（3/7）：RAG 与 Agent 时代

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 上一部分：[LLM 与多模态时代](ai-evolution-02-llm-multimodal.md) ｜ 下一部分：[MCP、Harness 与 Claude Code](ai-evolution-04-mcp-harness-claude-code.md)

---

## 5. RAG：给 LLM 外挂知识库（2023）

**RAG = Retrieval-Augmented Generation（检索增强生成）**：回答问题前先查资料，再基于查到的资料作答——就是"开卷考试"。

### 5.1 为什么 RAG 是刚需

LLM 幻觉的另一种解法是"微调"或"等下一代模型"，但都不现实：

| 方案 | 问题 |
| ------ | ------ |
| 把知识微调进模型 | ① 贵（一次几十万起）② 慢（几周）③ 知识一更新就作废 ④ 模型不保证精确记忆，还是会编 |
| 换更大的模型 | 贵，且解决不了私有数据（你的 Confluence 它没读过） |
| **RAG** | 把知识放在**模型外面**的数据库里，回答时检索注入——增删改查文档即可，模型本身不动 |

### 5.2 RAG 流水线六步全解

**离线阶段（建知识库）：**

```text
第 1 步：加载文档
  Confluence 页面 / PDF / Markdown / 数据库 → 纯文本

第 2 步：切片（Chunking）—— 最容易被忽视、最影响效果的一步
  为什么切片？① Embedding 模型有输入长度限制（512 token 左右）
             ② 切太大 → 检索不精准（一段 3000 字里找一句话）
             ③ 切太小 → 上下文丢失（"它支持 200K 上下文"里的"它"丢了）
  常用策略：按标题切 / 512 token + 15% 重叠（overlap 保证边界句子不丢）

第 3 步：向量化（Embedding）
  每个切片 → 1536 维向量（第 3 章的 Sentence-BERT 同款技术）
  语义相近的切片 → 空间中相邻的点

第 4 步：入库（向量数据库）
  Milvus / Pinecone / Weaviate / Qdrant / pgvector
  向量库的核心能力：给定一个查询向量，毫秒级找出"最近"的 K 个向量（ANN 近似最近邻索引，如 HNSW）
```

**在线阶段（回答问题）：**

```text
第 5 步：检索
  用户问题 → 同一个 Embedding 模型 → 查询向量 → 向量库 Top-K 相似切片
  进阶：混合检索 = 向量检索（语义） + BM25（关键词） → 两路结果合并
        （专有名词、报错码这类"必须字面匹配"的场景，BM25 吊打向量）

  第 5.5 步：重排（Rerank）
  粗排取回 Top-50 → 交叉编码器精排出 Top-5
  （粗排快但糙：向量是"各算各的"；Rerank 慢但准：把"问题+切片"成对送入模型精细打分）

第 6 步：生成
  Prompt = "根据以下资料回答，资料没有的内容就说不知道：
            【资料】{检索到的 5 个切片}
            【问题】{用户问题}"
  LLM 基于资料作答 → 附引用来源（可溯源，这是 RAG 的可解释性红利）
```

### 5.3 Demo：30 行实现一个能跑的 RAG（可运行）

```python
# pip install openai numpy
from openai import OpenAI
import numpy as np

client = OpenAI()
EMB_MODEL = "text-embedding-3-small"

def embed(texts):
    resp = client.embeddings.create(input=texts, model=EMB_MODEL)
    return [d.embedding for d in resp.data]

# ═══ 离线阶段：把"私有知识"变成向量 ═══
docs = [  # 模拟你公司内部文档切片
    "Ingress 是 K8s 的七层路由入口，把外部 HTTP/HTTPS 流量按 Host/Path 规则转发到不同 Service。",
    "Service 是 K8s 的四层负载均衡，通过 kube-proxy 和标签选择器为一组 Pod 提供稳定访问入口。",
    "Pod 是 K8s 最小调度单元，一个 Pod 可包含多个共享网络栈和存储卷的容器。",
    "kubectl port-forward 可以把本地端口转发到集群内 Pod，常用于临时调试单个服务。",
]
doc_vecs = embed(docs)  # 生产中这一步之后要写入 Milvus/pgvector

# ═══ 在线阶段：检索 + 生成 ═══
def ask(question, top_k=2):
    q_vec = embed([question])[0]

    # 第 5 步：向量检索 —— 余弦相似度取 Top-K
    scores = [np.dot(q_vec, dv) for dv in doc_vecs]     # 归一化后点积=余弦
    top_idx = np.argsort(scores)[-top_k:][::-1]        # 分数从高到低
    context = "\n".join(f"[{i}] {docs[i]}" for i in top_idx)

    # 第 6 步：把资料塞进 Prompt 让 LLM"开卷作答"
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": f"""根据资料回答问题。要求：
1. 只依据资料内容，资料没有就回答"资料中未提及"
2. 末尾标注引用的资料编号

资料：
{context}

问题：{question}"""}],
    )
    return resp.choices[0].message.content

print(ask("k8s 里 https 流量怎么进来？"))
# 输出示例：
# "外部 HTTPS 流量通过 Ingress 进入集群……（基于资料 [0]）
#  Ingress 按 Host/Path 规则把流量转发给对应 Service [1]。"

print(ask("今天上海天气怎么样？"))
# 输出："资料中未提及。" ← 幻觉被消除了：没有资料时它不会瞎编
```

**和第 4 章的对比**：同样的问题问裸 LLM，第一个问题可能答对（公网知识），第二个问题它一定会编一个天气。RAG 把"回答边界"框在了你的资料里。

### 5.4 RAG 的四代演进

| 代际 | 时间 | 核心改进 | 解决的问题 |
| ------ | ------ | --------- | ----------- |
| Naive RAG | 2023 初 | 切片→向量→检索→生成，一条直线 | 幻觉、知识时效 |
| Advanced RAG | 2023 中 | 查询重写（把口语问题改写成检索友好的表述）、混合检索、Rerank | 检索不准、召回噪声 |
| Modular RAG | 2023 末 | 流水线模块化可编排（检索路由/多路召回/迭代检索） | 不同场景灵活组装 |
| GraphRAG（微软） | 2024 | 知识图谱 + 向量：把实体关系抽成图，支持"多跳"问题 | 关联推理（"A 项目用过哪些 B 团队的库"需要跨多份文档串联） |
| **Agentic RAG** | 2024-至今 | 检索变成 Agent 的一个工具：Agent 自主决定"查什么、查几轮、要不要换关键词" | 复杂问题需要动态检索策略 |

**Agentic RAG 示意**（这是 RAG 与第 6 章 Agent 的融合点）：

```text
用户："对比一下我们 Ingress 方案和 Nginx 直连方案的成本"
  ↓
Agent 思考：这个问题需要查 2 类资料 → 发起检索①（Ingress 资料）
  ↓ 拿到结果，发现缺 Nginx 数据 → 自主发起检索②（Nginx 资料）
  ↓ 信息够了 → 对比生成答案
（Naive RAG 只会拿原始问题去检索一次，多半查不齐）
```

### 5.5 使用场景与现状

**RAG 至今仍是企业落地 LLM 的第一刚需场景**（没有之一）：

- 企业知识库问答（Confluence/飞书文档/SharePoint）——最普遍的落地形态
- 客服机器人——回答必须可溯源，出错能定位到是哪篇文档的问题
- 法律/医疗/合规咨询——高风险场景必须引用原文
- 代码库问答（如 Cursor 的 codebase 索引，本质是针对代码的 RAG）
- 结合向量数据库（Milvus/pgvector）做语义搜索

**局限 → 引出 Agent**：RAG 只解决了"知识"问题，LLM 依旧没有"行动力"——你让 RAG 机器人"把这份报告发到群里"，它只能给你贴一段"如何发消息"的文档。

---

## 6. Agent 时代：让 LLM 长出手（2023）

### 6.1 Function Calling：模型学会"点菜"

2023 年 6 月 OpenAI 发布 Function Calling，第一次把"调用工具"做成了 API 原生能力。工作原理：

```text
① 开发者用 JSON Schema 声明可用工具（像写菜单）：
   "get_pod_status"：查询 Pod 状态，参数：namespace(str), pod_name(str)

② 用户提问："default 命名空间的 nginx-abc pod 活着吗"

③ 模型内部决策：这个问题需要事实数据 → 我没法凭空知道 Pod 状态
   → 输出：{"name": "get_pod_status",
           "arguments": "{\"namespace\": \"default\", \"pod_name\": \"nginx-abc\"}"}
   注意：模型不执行任何东西，它只是"写出要点哪个菜、加什么料"

④ 开发者代码真正执行 kubectl，把结果回传

⑤ 模型基于工具结果生成最终回答："nginx-abc 正在 Running，已重启 1 次"
```

### 6.2 ReAct 范式：推理与行动交替（Agent 的灵魂）

ReAct = **Rea**son + **Act**。让 LLM 像人一样"想一步、做一步、看结果、再想"：

```text
问题："订单 9527 为什么还没发货？"

Thought（想）：我需要先查这个订单的状态
Action（做）：query_order(order_id="9527")
Observation（看）：状态=待发货，缺货标记=true，商品=机械键盘

Thought（想）：缺货了，查一下库存什么时候补
Action（做）：query_inventory(sku="mech-kb")
Observation（看）：预计 3 天后到货

Thought（想）：信息够了，可以回答用户了
Answer：您的订单因商品缺货暂缓，预计 3 天后补货并发出。
```

这个"想-做-看"循环就是后来一切 Agent 的骨架。

### 6.3 Agent 四大件（完整能力图）

```text
┌───────────────────────────── Agent ─────────────────────────────┐
│                                                                   │
│  规划 Planning          工具 Tools           记忆 Memory          │
│  ├─ 任务分解            ├─ 搜索/API          ├─ 短期：对话上下文   │
│  ├─ 思维链 CoT          ├─ 代码执行器         ├─ 长期：向量库回忆   │
│  └─ 反思重规划          ├─ 文件/数据库        └─ （RAG 就是记忆）  │
│                        └─ （RAG 是其中一种工具）                  │
│                    反思 Reflection                                  │
│                    ├─ 自检：刚才那步做对了吗                        │
│                    └─ 修正：错了就回滚重来                          │
└───────────────────────────────────────────────────────────────────┘
```

**关键认知**：RAG 和 Agent 不是竞争关系——RAG 是 Agent 的一个"记忆/知识工具"，Agent 是 LLM 能力的超集。

### 6.4 Demo：手写一个最小 Agent Loop（可运行）

下面 40 行代码就是一个真正可用的 Agent——也是理解 Claude Code 内核的最佳途径：

```python
# pip install openai
from openai import OpenAI
import json

client = OpenAI()

# ① 工具实现层：Agent 的"手"
def get_pod_status(namespace: str, pod: str) -> str:
    """（演示用假实现，生产中换成 kubectl 调用）"""
    return json.dumps({"status": "Running", "restarts": 1, "age": "3d"})

def kubectl_scale(deployment: str, replicas: int, namespace: str = "default") -> str:
    """（演示用假实现）"""
    return json.dumps({"result": "scaled", "deployment": deployment,
                       "replicas": replicas, "namespace": namespace})

TOOLS_IMPL = {"get_pod_status": get_pod_status, "kubectl_scale": kubectl_scale}

# ② 工具声明层：Agent 的"菜单"（Function Calling）
TOOLS_SCHEMA = [
    {"type": "function", "function": {
        "name": "get_pod_status",
        "description": "查询 K8s 指定命名空间下某个 Pod 的运行状态",
        "parameters": {"type": "object", "properties": {
            "namespace": {"type": "string"},
            "pod": {"type": "string"}},
            "required": ["namespace", "pod"]}}},
    {"type": "function", "function": {
        "name": "kubectl_scale",
        "description": "把指定 Deployment 扩缩容到目标副本数",
        "parameters": {"type": "object", "properties": {
            "deployment": {"type": "string"},
            "replicas": {"type": "integer"},
            "namespace": {"type": "string"}}},
            "required": ["deployment", "replicas"]}},
]

# ③ Agent 主循环（Agentic Loop）：一切 Agent 产品的内核
def agent_loop(goal: str, max_steps: int = 8) -> str:
    messages = [
        {"role": "system", "content": "你是 SRE 助手。先诊断，再行动。"},
        {"role": "user", "content": goal},
    ]
    for step in range(max_steps):                    # 护栏①：步数上限防失控
        resp = client.chat.completions.create(
            model="gpt-4o-mini", messages=messages, tools=TOOLS_SCHEMA)
        msg = resp.choices[0].message

        if not msg.tool_calls:                        # 模型认为任务完成
            return msg.content                        # → 输出最终答案，退出循环

        messages.append(msg)                          # 把"决策"记入历史
        for call in msg.tool_calls:                   # 可能一口气调多个工具
            fn_name = call.function.name
            args = json.loads(call.function.arguments)
            result = TOOLS_IMPL[fn_name](**args)      # 真正执行工具
            messages.append({"role": "tool",          # 结果回填，进入下一轮
                             "tool_call_id": call.id,
                             "content": str(result)})
            print(f"  step{step}: {fn_name}({args}) → {result[:50]}...")
    return "达到最大步数，任务未完成"                    # 护栏②：强制熔断

# ④ 一次多步任务：模型自主"诊断 → 行动"
print(agent_loop("帮我看看 web-abc 这个 pod 的状态，如果它只有 1 个副本就扩到 3 个"))
# 执行轨迹（模型自主决策，非人工编排）：
#   step0: get_pod_status({'namespace': 'default', 'pod': 'web-abc'}) → Running
#   step1: kubectl_scale({'deployment': 'web-abc', 'replicas': 3}) → scaled
#   最终回答："web-abc 运行正常，原副本数偏少，已扩容至 3 副本。"
```

**这段代码里藏着 Agent 的全部秘密：** 没有写任何流程编排——"先查再扩"的策略是模型自己根据结果决定的。代码只是提供了工具和循环。

### 6.5 AutoGPT 的失败与教训（为什么 2023 年的 Agent 火不起来）

2023 年 3 月，开源项目 AutoGPT 爆火（GitHub 增速第一）：让 GPT-4 自主设定子任务、循环执行。但用户很快发现它**基本干不成事**：

| 失败原因 | 具体表现 |
| --------- | --------- |
| 模型太弱 | 当时最强 GPT-4 在多步任务上错误会累积，第 3 步错后面全错 |
| 循环失控 | 无限重复某一步、陷入死循环烧 token，没有步数熔断 |
| 无反馈机制 | 工具报错了也不看错误信息，继续按幻觉走 |
| 上下文溢出 | 任务一长，前文被截断，忘了自己在干嘛 |
| 无权限管控 | 自主执行 `rm` 类危险命令，没人敢真用 |

**转机（2024）**：三个条件同时成熟，Agent 才真正可用——

```text
① 模智力升级：Claude 3.5 Sonnet / o1 等推理能力大增（SWE-bench 分数飙升）
② 工程补课：上面 5 个坑逐一被修复（步数熔断、错误重试、上下文压缩、权限审批）
③ 生态补全：工具接入标准化（MCP）+ 能力模块化（Skill）
   —— 这套"模型+工程+生态"的组合，就叫 Harness（第 8 章）
```

### 6.6 使用场景与局限

**Agent 适用**（有明确反馈信号的场景）：

- 编码（编译/测试通过与否是天然反馈）← Claude Code 的机会
- 数据分析（跑出结果对不对看得见）
- 自动化运维（命令执行结果可见）
- 多源信息调研→汇总报告

**不适用**：开放式创意、无验证手段的"自主决策"。

**局限 → 引出 MCP**：Function Calling 每接一个工具都要为每个应用写一遍胶水代码。100 个模型 × 100 个工具 = 10000 份集成——生态被"孤岛"卡住了。
