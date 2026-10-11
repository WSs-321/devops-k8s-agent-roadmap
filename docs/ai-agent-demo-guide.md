# AI Agent 实现入门：从最小 Demo 到小程序落地

> 系列关联：[AI Agent 实战手册](ai-agent-playbook.md)（讲怎么"用好"现成 Agent 工具，本文讲怎么"实现"自己的 Agent，并落地成小程序小工具）

## 1. Agent 的本质：一个带工具的循环

普通聊天机器人是"一问一答"：人给输入，模型给输出，结束。Agent 的区别在于中间多了一个循环——模型可以决定"我需要先调个工具"，拿到结果后继续思考，直到它认为可以收尾。所有 Agent 框架，剥开抽象层，内核都是下面这个循环：

```python
messages = [系统提示, 用户输入]
while True:
    resp = 调用 LLM(messages, tools=工具集)   # 每轮都把全部历史发给模型
    if 模型没有再请求工具:
        输出 resp 最终回答
        break                                # 循环结束，任务完成
    for 每一个工具调用请求:
        result = 执行工具(工具名, 参数)        # 真正干活的是你的代码
        把 result 追加进 messages            # 关键：把结果"喂回"对话
```

流程图视角：

```text
用户输入
   ↓
┌────────────────── Agent 循环 ──────────────────┐
│ LLM 思考：直接回答，还是先调用工具？              │
│   ├── 直接回答 → 输出结果，循环结束              │
│   └── 要用工具 → 返回工具名 + 参数（JSON）       │
│         ↓                                      │
│       你的代码执行工具，拿到结果                 │
│         ↓                                      │
│       结果回填进对话历史，进入下一轮思考          │
└────────────────────────────────────────────────┘
```

两个关键认知：

- 模型从不"执行"任何东西，它只输出"我想调用哪个工具、传什么参数"的意图，执行永远发生在你的代码里——这是理解一切安全问题的前提；
- 这个模式就是 ReAct（Reason + Act）：推理一步、行动一步、看结果、再推理，模型把工具结果当作新的观察继续思考。

## 2. Demo 一：客服助手（RAG 检索型）

### 2.1 场景与架构

需求：用户问"怎么退货"，助手只依据官方知识库回答，绝不瞎编。模型本身不知道你的退货政策，所以要把知识在提问时"喂"给它——这就是 RAG（Retrieval-Augmented Generation，检索增强生成）。

```text
用户提问 ──→ 问题转向量 ──→ 向量库里检索最相似的 top-k 条知识
                                        ↓
              拼装 Prompt（系统角色 + 检索到的知识 + 用户原问题）
                                        ↓
                                 LLM 生成回答
                  （提示词约束：只允许基于给定知识回答）
```

### 2.2 实现流程五步

| 步骤 | 做什么 | 产出 |
| --- | --- | --- |
| 1. 知识准备 | 把 FAQ/文档清洗成干净的"问题-答案"对或短段落 | `faq.json` |
| 2. 向量化 | 调 Embedding 接口，把每条知识转成向量 | 向量数组 |
| 3. 建索引 | 全量向量存入向量库（demo 阶段用 numpy 即可） | 知识库索引 |
| 4. 检索 | 用户问题也转向量，按余弦相似度取 top-k | 命中的知识片段 |
| 5. 生成 | 检索结果拼进提示词，约束模型只依据它回答 | 最终回答 |

### 2.3 最小可跑实现

不依赖任何向量库和框架，`pip install openai numpy` 装依赖，再备好下面的 `faq.json`（12 条样例已够跑通全部演示，之后整体替换成自己的知识即可）：

```json
[
  {"q": "怎么申请退货退款？", "a": "签收后 7 天内，在「我的订单」选择对应订单点「申请售后-退货退款」，填写原因并寄回商品。商品需保持吊牌完整、未洗涤使用。"},
  {"q": "退货的运费由谁承担？", "a": "7 天无理由退货，寄回运费由买家承担；商品存在质量问题或发错货，运费由卖家承担，可先垫付后凭运费单据报销。"},
  {"q": "退货多久能收到退款？", "a": "仓库签收并验收通过后，1 个工作日内原路退回；银行卡到账一般再需 1-7 天，以银行处理时间为准。"},
  {"q": "支持换货吗？", "a": "质量问题支持 15 天内换货：在「我的订单」申请售后选择「换货」，同款优先补发；无货时协调退货退款。"},
  {"q": "怎么申请开发票？", "a": "下单页可勾选电子发票，订单完成后 24 小时内发送到预留邮箱；漏开的可联系客服凭订单号补开，支持补开的有效期为 1 年。"},
  {"q": "下单后什么时候发货？", "a": "现货商品 48 小时内发货；预售商品以下单页标注的发货时间为准；大促期间可能延迟 1-2 天，延迟会在订单页通知。"},
  {"q": "怎么修改收货地址？", "a": "未发货前可在「我的订单-订单详情-修改地址」自助修改；已发货订单无法修改地址，可联系快递员协商转寄。"},
  {"q": "怎么查询物流信息？", "a": "在「我的订单-查看物流」实时展示快递公司与轨迹；发货后超 48 小时无物流更新，可联系客服催查。"},
  {"q": "商品有质量问题怎么办？", "a": "签收后 15 天内拍照上传问题凭证，在订单页申请「质量问题」售后；审核通过后免费退货退款或换货，运费由卖家承担。"},
  {"q": "支持货到付款吗？", "a": "暂不支持货到付款，支持微信、支付宝及主流银行卡在线支付。"},
  {"q": "怎么联系人工客服？", "a": "APP 内「我的-客服中心」输入「转人工」接入；服务时间 9:00-21:00，其余时间可留言，客服上班后 2 小时内回复。"},
  {"q": "怎么取消订单？", "a": "未发货前可在「我的订单-订单详情」点「取消订单」，款项原路秒退；已发货订单需拒收或签收后走退货流程。"}
]
```

主程序：

```python
import json
import numpy as np
from openai import OpenAI

# OpenAI 兼容端点均可；注意 DeepSeek 官方暂不提供 embedding 接口，而 RAG 必须要
# embedding，故这里用阿里百炼一家配齐"聊天 + 向量"两件套；换平台只改这三行
client = OpenAI(api_key="sk-xxx",
                base_url="https://dashscope.aliyuncs.com/compatible-mode/v1")
CHAT_MODEL = "qwen-plus"
EMBED_MODEL = "text-embedding-v3"

faq = json.load(open("faq.json", encoding="utf-8"))  # [{"q": "...", "a": "..."}]

def embed(texts):
    r = client.embeddings.create(model=EMBED_MODEL, input=texts)
    return np.array([d.embedding for d in r.data])

faq_vecs = embed([f["q"] for f in faq])  # 启动时建一次索引

def answer(question, top_k=3):
    q_vec = embed([question])[0]
    # 余弦相似度：点积除以两个模长
    sims = faq_vecs @ q_vec / (np.linalg.norm(faq_vecs, axis=1) * np.linalg.norm(q_vec))
    hits = [faq[i] for i in sims.argsort()[-top_k:][::-1]]
    context = "\n\n".join(f"问：{h['q']}\n答：{h['a']}" for h in hits)
    resp = client.chat.completions.create(
        model=CHAT_MODEL,
        temperature=0.1,  # 客服场景要"稳"，不要发散
        messages=[
            {"role": "system",
             "content": "你是官方客服。只依据下面的知识回答；知识里没有的就明确说不知道，禁止编造。\n\n" + context},
            {"role": "user", "content": question},
        ],
    )
    return resp.choices[0].message.content

print(answer("买了东西想退货怎么办"))
```

填上自己的 key 后 `python chat.py`：输出应是 `faq.json` 第 1 条的退货流程，而不是模型的自由发挥——检索命中它，回答就只基于它。

### 2.4 多轮对话：自动识别追问所指

单轮版跑通后马上会撞上多轮问题：用户先问"买了东西想退货怎么办"，接着追问"那运费谁出"——把这句直接拿去向量检索必然失败，"那"在向量空间里没有语义，命中不了任何知识。所谓"自动识别追问所指"，标准解法是**检索前先改写**：让 LLM 结合最近历史，把追问改写成一个独立完整的问题，再去检索。

以下代码基于 2.3 的 `client`、`embed`、`faq_vecs` 继续写：

```python
def rewrite(question, history):
    """结合历史把追问改写成独立完整的问题——多轮检索的关键"""
    if not history:
        return question                          # 第一轮没有指代，直接检索
    resp = client.chat.completions.create(
        model=CHAT_MODEL,
        messages=[
            {"role": "system",
             "content": "结合对话历史，把用户最新问题改写成独立完整、不含指代词（这/那/它）的问题。只输出改写后的问题。"},
            *history[-6:],                       # 只带最近 3 轮：指代一般就在近处
            {"role": "user", "content": question},
        ],
    )
    return resp.choices[0].message.content

def retrieve(question, top_k=3):                 # 检索逻辑从 2.3 的 answer() 抽出
    q_vec = embed([question])[0]
    sims = faq_vecs @ q_vec / (np.linalg.norm(faq_vecs, axis=1) * np.linalg.norm(q_vec))
    return [faq[i] for i in sims.argsort()[-top_k:][::-1]]

def chat(question, history):
    """多轮版客服：history 由调用方维护，格式同 OpenAI 的 messages"""
    search_q = rewrite(question, history)        # ① "那运费谁出" → "退货的运费谁出"
    context = "\n\n".join(f"问：{h['q']}\n答：{h['a']}" for h in retrieve(search_q))
    resp = client.chat.completions.create(
        model=CHAT_MODEL,
        temperature=0.1,
        messages=[
            {"role": "system",
             "content": "你是官方客服。只依据下面的知识回答；知识里没有的就明确说不知道，禁止编造。\n\n" + context},
            *history,                            # ② 生成时带上完整原历史
            {"role": "user", "content": question},  # ③ 注意用原始问题，不用改写版
        ],
    )
    return resp.choices[0].message.content

history = []
for q in ["买了东西想退货怎么办", "那运费谁出呢"]:   # 追问带指代，单轮版在这里必然翻车
    a = chat(q, history)
    history += [{"role": "user", "content": q}, {"role": "assistant", "content": a}]
    print("用户：", q, "\n客服：", a, "\n")
```

四个要点：

- 为什么不把历史直接拼进检索词？长拼接会稀释语义，向量检索对"独立完整的问题"最敏感——改写是给检索器看的，不是给生成器看的；
- 生成时要用原始问题而不是改写版：改写只服务于检索，回答时靠原历史保住语气、上下文和用户真正的问法；
- 改写只带最近 3 轮（`history[-6:]`）：长会话全量带进去 token 爆炸，而指代一般只出现在最近几轮；
- 这套"先改写再检索"各框架都已内置：LangChain 的 CondenseQuestionChain、LlamaIndex 的 CondenseQuestionChatEngine 干的就是这件事——手写一遍，用框架时才知道它内部发生了什么。

### 2.5 生产化要点

- 提示词里写死"没有依据就说不知道"，这是客服场景防幻觉的生死线；
- 高频问题可以只检索 top-1、相似度超过阈值就直接返回，跳过 LLM——省钱、零幻觉、毫秒级响应；
- 生产还差三件事：检索质量优化（分段、重排）、转人工兜底、敏感词过滤。

## 3. Demo 二：查阅工具助手（Function Calling 型）

### 3.1 机制：模型不执行，只"点菜"

RAG 解决"知识在模型外面"，Function Calling 解决"能力在模型外面"（查实时天气、查订单、调内部系统）。流程是严格的四步：

```text
① 你在请求里声明可用工具（JSON Schema 描述）
        ↓
② 模型判断需要某工具，返回 tool_calls：工具名 + 参数
        ↓
③ 你的代码真正执行（调天气 API、查数据库……）
        ↓
④ 把执行结果以 role=tool 的消息回填，模型拿到结果继续生成
```

### 3.2 工具定义与主循环

```python
import json
from openai import OpenAI

client = OpenAI(api_key="sk-xxx", base_url="https://api.example.com/v1")
CHAT_MODEL = "deepseek-chat"

TOOLS = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        # description 决定模型调用准确率：写"什么时候该用"，不是"它是什么"
        "description": "查询指定城市的实时天气。用户问天气、温度、是否下雨时必须调用",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {"type": "string", "description": "城市名，如：上海"},
            },
            "required": ["city"],
        },
    },
}]

def get_weather(city):
    # 真实场景里这里调天气 API；demo 用假数据
    return json.dumps({"city": city, "temp": "22℃", "cond": "晴"}, ensure_ascii=False)

TOOL_IMPL = {"get_weather": get_weather}  # 工具白名单：模型点名的菜，只做这里有的

def ask(question):
    messages = [
        {"role": "system", "content": "你是查询助手。需要实时信息时调用工具，不要编造。"},
        {"role": "user", "content": question},
    ]
    while True:
        resp = client.chat.completions.create(
            model=CHAT_MODEL, messages=messages, tools=TOOLS)
        msg = resp.choices[0].message
        if not msg.tool_calls:               # 模型不再要工具 = 可以收尾
            return msg.content
        messages.append(msg)                 # 模型的"点菜单"也要进历史
        for call in msg.tool_calls:
            result = TOOL_IMPL[call.function.name](**json.loads(call.function.arguments))
            messages.append({"role": "tool", "tool_call_id": call.id, "content": result})

print(ask("上海今天天气怎么样，适合跑步吗"))
```

运行后能观察到模型先返回 `get_weather(city="上海")`，拿到 `22℃ 晴` 后才组织出"适合跑步"的最终回答——这就是第 1 章循环的真实发生过程。

一个生产级细节：`json.loads(call.function.arguments)` 没人保证是合法 JSON，`TOOL_IMPL[...]` 也没人保证工具名一定存在——模型偶发抽风时上面这段会直接崩。生产要 try/catch 兜底，捕获后回填一条"参数格式错误"的 role=tool 消息让模型自我纠正，demo 从简不做。

### 3.3 工具设计三原则

- 单一职责：一个工具只做一件事，宁可多定义几个；
- description 写"何时用"：它就是给模型看的说明书，模型全靠它决定调不调；
- 参数越少越好：每多一个参数，模型填错的概率就多一分。

### 3.4 两个 Demo 的对比与组合

| 维度 | 客服助手（RAG） | 工具助手（Function Calling） |
| --- | --- | --- |
| 解决什么 | 知识在模型外 | 能力在模型外 |
| 知识/数据存哪 | 向量库 | 各类 API、数据库 |
| 核心机制 | 检索 + 拼提示词 | 工具调用循环 |
| 典型场景 | FAQ、文档问答 | 查天气、查订单、控制设备 |

生产中两者经常组合：给工具助手注册一个 `search_knowledge_base` 工具，工具内部做的就是 RAG 检索——这就成了"能查知识库的 Agent"，也是各类客服系统的标准形态。

## 4. 常用实现手段速查

| 手段 | 一句话说明 | 适用 | 门槛 |
| --- | --- | --- | --- |
| 提示词模板 | 固定角色、边界、输出格式，一切场景的地基 | 所有 | 零 |
| 长上下文直塞 | 知识直接放进 prompt | 知识量小且固定 | 零 |
| Function Calling | 模型按需调用你定义的函数 | 查数据、执行动作 | 低 |
| RAG | 向量检索 + 生成 | 知识库问答 | 中 |
| 会话记忆 | 保存多轮历史，超长做摘要压缩 | 多轮对话产品 | 中 |
| 工作流编排 | 把多步骤固化成状态机 | 流程固定的业务 | 中 |
| 多 Agent 协作 | 分角色分工（详见实战手册） | 复杂开放任务 | 高 |

两个反模式提醒：

- 能用确定性规则解决的（查表、if-else、正则），不要上 LLM，更不要上 Agent；
- 能用单 Agent 解决的，不要上多 Agent——编排的复杂度增长远快于收益。

## 5. 框架与技术栈选型

### 5.1 分层视图

```text
┌────────────────────────────────────────────────┐
│ 应用层：小程序 / Web / CLI / 机器人               │
├────────────────────────────────────────────────┤
│ 编排层：裸 SDK / LangChain / LangGraph /        │
│         LlamaIndex / CrewAI / Dify / Coze       │
├────────────────────────────────────────────────┤
│ 工具协议层：Function Calling / MCP             │
├────────────────────────────────────────────────┤
│ 模型层：DeepSeek / Qwen / GLM / Kimi / GPT ...  │
│   + Embedding 模型 + 向量库                     │
└────────────────────────────────────────────────┘
```

### 5.2 框架选型表

| 框架/工具 | 定位 | 适合谁 |
| --- | --- | --- |
| 原生 SDK（OpenAI 兼容） | 零抽象直调 API | 学原理、写小工具，首选入门 |
| LangChain | 组件全家桶：链、工具、记忆 | 快速搭原型 |
| LangGraph | 图状态机编排，精确控制流程 | 流程复杂的严肃 Agent |
| LlamaIndex | 数据接入 + RAG 专精 | 文档问答为主的应用 |
| CrewAI / AutoGen 系 | 多 Agent 角色协作 | 多角色流水线 |
| OpenAI Agents SDK | 官方轻量 Agent 循环 + handoff | 简洁的单/多 Agent |
| Dify / Coze（扣子） | 低代码平台，可视化搭建、一键发布 | 不写代码快速上线验证 |

选型建议：先用裸 SDK 把第 2、3 章的 demo 写一遍（一天就能懂原理），之后再按需上框架——接数据源多上 LlamaIndex，流程复杂上 LangGraph，多 Agent 上 CrewAI；低代码平台适合快速验证产品，不适合学原理。

### 5.3 模型、Embedding 与向量库（国内可用）

- 聊天模型：DeepSeek、Qwen（百炼）、GLM、Kimi 等，全部提供 OpenAI 兼容接口，代码几乎零改动换模型——只换 `base_url` 和模型名；
- Embedding：各平台自带 embedding 接口（如百炼 text-embedding 系列），同样兼容调用；
- 向量库选型随规模走：几千条以内 numpy 手搓就够 → 十万级用 Chroma / FAISS → 生产级用 pgvector（跟 PostgreSQL 一鱼两吃）或 Milvus；
- 面向国内用户的小程序，建议全链路使用国内模型 + 完成合规动作（见第 7 章），避免网络与监管双重坑。

## 6. 小程序落地：架构与实现流程

### 6.1 为什么小程序不能直连 LLM API

- API key 会泄露：小程序前端包可被解包反编译，任何写进前端的密钥等于公开；
- 域名白名单：`wx.request` 只能请求在平台后台配置过的域名，且要求 HTTPS + ICP 备案；
- 控制能力缺失：限流、计费、内容安全、会话管理都必须在服务端做。

结论：小程序前端只连自己的后端，由后端代理 LLM。这不是可选项，是硬约束。

### 6.2 整体架构

```text
微信小程序（前端：聊天 UI、流式渲染）
   │ wx.request / wx.cloud.callFunction
   ↓
自建后端 或 微信云函数
   │ 鉴权 · 限流 · 会话管理 · 内容安全 · key 托管
   ↓
LLM API（DeepSeek / Qwen / ...）
   ↕
工具与数据：天气 API、订单库、向量知识库 ...
```

### 6.3 实现流程六步

| 步骤 | 做什么 | 说明 |
| --- | --- | --- |
| 1. 需求收敛 | 选一个"小而具体"的工具 | 快递查询、菜谱问答、健身计划，比"通用聊天机器人"成功率高一个量级 |
| 2. 技术选型 | 前端：小程序原生或 Taro/uni-app；后端：云函数或自建服务 | 见 6.4 两个方案的取舍 |
| 3. 后端开发 | `/chat` 接口：鉴权 → 限流 → 拼 prompt → 调 LLM → 回传 | key 只放环境变量/密钥管理 |
| 4. 前端开发 | 聊天 UI + 流式渲染 + 异常兜底 | 核心是 6.5 的流式接收 |
| 5. 测试联调 | 真机预览、弱网、超长输入、并发 | 重点测超时与断流 |
| 6. 上线合规 | 备案、AIGC 标识、平台类目审核 | 周期最长的一步，提前启动 |

### 6.4 后端最小实现：两个方案

方案 A——微信云函数（最快上线）：

```javascript
// 云函数 chat/index.js：请求-响应模式，不能长时间流式，等生成完一次性返回
const cloud = require("wx-server-sdk");
const OpenAI = require("openai");
const client = new OpenAI({ apiKey: process.env.LLM_KEY }); // key 只存在于后端

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });
const db = cloud.database();
const MAX_TURNS = 10;                             // 会话只留最近 10 轮，防上下文爆掉

// 会话存云数据库集合 sessions：{ _id: sessionId, messages: [...] }
async function loadHistory(sessionId) {
  const res = await db.collection("sessions").doc(sessionId).get()
    .catch(() => null);                            // 查不到文档 = 新会话
  return res?.data?.messages ?? [];
}

async function saveHistory(sessionId, question, answer) {
  const messages = await loadHistory(sessionId);
  messages.push({ role: "user", content: question },
                { role: "assistant", content: answer });
  if (messages.length > MAX_TURNS * 2) messages.splice(0, messages.length - MAX_TURNS * 2);
  await db.collection("sessions").doc(sessionId).set({ data: { messages } }); // 有则覆盖
}

exports.main = async (event) => {
  const { question, sessionId } = event;
  const history = await loadHistory(sessionId);   // 会话存云数据库
  const resp = await client.chat.completions.create({
    model: "deepseek-chat",                       // 云函数只做纯聊天，DeepSeek 即可
    messages: [...history, { role: "user", content: question }],
  });
  await saveHistory(sessionId, question, resp.choices[0].message.content);
  return { answer: resp.choices[0].message.content };
};
```

部署要点：云函数目录内 `npm install wx-server-sdk openai`；key 配在云函数环境变量 `LLM_KEY`，不要写进代码；`config.json` 把超时设到平台允许的最大值（生成动辄 5-20 秒，默认超时根本不够）。

- 优点：免域名、免备案、免服务器，前端 `wx.cloud.callFunction` 直连，周末就能上线；
- 代价：无法真流式（云函数是请求-响应模式，超时上限也有限），等待 5-20 秒只能转圈。

前端对应调用（对照 6.5 的流式版，这里是一次性返回）：

```javascript
wx.cloud.callFunction({ name: "chat", data: { question, sessionId: "demo-user" } })
  .then((res) => this.setData({ answer: res.result.answer })); // 等待后整段出现
```

方案 B——自建服务（真流式体验）：

```javascript
// server.js —— 依赖安装后直接启动，跑通后是第 8 章路线的第 3 步产出
const express = require("express");
const OpenAI = require("openai");
const client = new OpenAI({ apiKey: process.env.LLM_KEY }); // key 只在环境变量里

const app = express();
app.use(express.json());

// 内存版会话存储：重启即清空，demo/自用足够；生产换 Redis 或数据库
const sessions = new Map();
const MAX_TURNS = 10;

function buildMessages(sessionId, question) {
  const history = sessions.get(sessionId) ?? [];
  history.push({ role: "user", content: question });
  if (history.length > MAX_TURNS * 2) history.splice(0, history.length - MAX_TURNS * 2);
  return history;                                 // 引用同一数组，流完回填一次即可
}

app.post("/chat", async (req, res) => {
  res.set({
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  try {
    const { question = "", sessionId = "default" } = req.body;
    const messages = buildMessages(sessionId, question); // 生产在此步前加鉴权与限流
    const stream = await client.chat.completions.create({
      model: "deepseek-chat", stream: true, messages,
    });
    let full = "";                                // 累积全文，流完才有完整答案
    for await (const chunk of stream) {
      const text = chunk.choices[0]?.delta?.content ?? "";
      if (text) full += text;
      res.write(`data: ${JSON.stringify({ text })}\n\n`); // SSE 格式：data: 开头
    }
    messages.push({ role: "assistant", content: full }); // 本轮答案进历史
    sessions.set(sessionId, messages);
    res.write("data: [DONE]\n\n");
  } catch (e) {                                   // 错误也走 SSE 通道，前端才能收到
    res.write(`data: ${JSON.stringify({ error: String(e) })}\n\n`);
  } finally {
    res.end();
  }
});

app.listen(3000, () => console.log("http://localhost:3000 就绪"));
```

跑起来三步：`npm install express openai` → 设置环境变量 `LLM_KEY`（PowerShell 用 `$env:LLM_KEY="sk-xxx"`，bash 用 `export LLM_KEY=sk-xxx`）→ `node server.js`，再用下面的命令验证 SSE 是否逐段吐字。注意请在 Git Bash / macOS / Linux 终端执行——PowerShell 里 `curl` 是 `Invoke-WebRequest` 的别名，且 JSON 引号规则完全不同，别在 PowerShell 里折腾：

```bash
curl -N -X POST localhost:3000/chat -H "content-type: application/json" -d '{"question":"你好"}'
```

取舍：要快速验证用 A，要产品级体验用 B。B 的前提是已备案的 HTTPS 域名（流程一至数周，尽早启动）。

### 6.5 前端流式接收

`wx.request` 不支持浏览器式的 EventSource，需要用 `enableChunked`（基础库 2.20.2+）分块接收。下面是聊天页完整核心代码（`pages/chat/chat.js`），本节末尾两个坑已在代码里直接解决：

```javascript
// pages/chat/chat.js —— 与 6.4 方案 B 的 server.js 联调
const API = "https://api.example.com"; // 本地联调改 http://localhost:3000，见本节末

function utf8Decode(bytes) {           // 手写 UTF-8 解码：iOS 端没有 TextDecoder
  let out = "", i = 0;
  while (i < bytes.length) {
    const b = bytes[i];
    let len, cp;
    if (b < 0x80)                 { len = 1; cp = b; }
    else if ((b & 0xe0) === 0xc0) { len = 2; cp = b & 0x1f; }
    else if ((b & 0xf0) === 0xe0) { len = 3; cp = b & 0x0f; }
    else                          { len = 4; cp = b & 0x07; }
    for (let j = 1; j < len; j++) cp = (cp << 6) | (bytes[i + j] & 0x3f);
    out += String.fromCodePoint(cp);
    i += len;
  }
  return out;
}

Page({
  data: { question: "", answer: "" },
  onInput(e) { this.setData({ question: e.detail.value }); },

  onSend() {
    const question = this.data.question.trim();
    if (!question) return;
    this.setData({ answer: "" });                 // 新一轮，清空打字机区域
    let pending = new Uint8Array(0);              // 字节缓冲：应对坑 2 的残段
    const task = wx.request({
      url: `${API}/chat`,
      method: "POST",
      enableChunked: true,                        // 关键开关：分块接收响应
      header: { "content-type": "application/json" },
      data: { question, sessionId: "demo-user" },
      fail: () => this.setData({ answer: "网络异常，请重试" }),
    });
    task.onChunkReceived((res) => {
      const incoming = new Uint8Array(res.data);
      const merged = new Uint8Array(pending.length + incoming.length);
      merged.set(pending);
      merged.set(incoming, pending.length);
      let start = 0;
      for (let i = 0; i < merged.length; i++) {
        if (merged[i] !== 0x0a) continue;         // 0x0A 即换行符：一行的完整边界
        const line = utf8Decode(merged.slice(start, i)).trim();
        start = i + 1;
        if (!line.startsWith("data:")) continue;
        const payload = line.slice(5).trim();
        if (payload === "[DONE]") return;         // 流结束
        const { text, error } = JSON.parse(payload);
        if (error) { this.setData({ answer: "服务异常：" + error }); return; }
        this.setData({ answer: this.data.answer + text }); // 打字机效果
      }
      pending = merged.slice(start);              // 不完整的残段留到下一块
    });
  },
});
```

页面结构（`pages/chat/chat.wxml`，不写样式也能跑）：

```xml
<view style="padding: 24rpx;">
  <view style="min-height: 300rpx;">{{answer || "向 AI 助手提问…"}}</view>
  <textarea value="{{question}}" bindinput="onInput" placeholder="输入问题" />
  <button bindtap="onSend">发送</button>
</view>
```

本地联调：微信开发者工具「详情 → 本地设置」勾选「不校验合法域名」，`API` 改为 `http://localhost:3000` 即可直连 6.4 方案 B 的 server.js 看到打字机效果；上线前必须换回备案过的 HTTPS 域名，并在小程序后台配置 request 合法域名。

两个必踩的坑（上面代码里的对应解法）：

- 坑 1（解码）：微信 iOS 端的 JavaScriptCore 运行时没有 `TextDecoder`（安卓的 V8 才有）——跨端统一用 `utf8Decode` 手写实现，或引入 fast-text-encoding polyfill；
- 坑 2（截断）：chunk 边界可能把一个多字节汉字切成两半，逐块 decode 必然乱码——正确做法是按**字节**缓冲（不能转字符串），找到换行符（0x0A）切出完整行再整体解码，残段留到下一块。

## 7. 小程序落地：技术难点与合规清单

### 7.1 十大技术难点速查

| 难点 | 根因 | 解法 |
| --- | --- | --- |
| API key 泄露 | 前端包可反编译 | key 只存后端环境变量/密钥管理服务，前端只传 sessionId |
| 域名白名单 | 必须备案过的 HTTPS 域名 | 提前备案；验证期用云函数（免域名）绕过 |
| 流式响应 | wx.request 无 EventSource | `enableChunked` + `onChunkReceived`；云函数则一次性返回或分片轮询 |
| UTF-8 截断乱码 | chunk 边界切断多字节字符 | 缓冲字节流，按完整 SSE 行解析（见 6.5） |
| 云函数不能长连接 | 请求-响应模式 + 超时上限 | 简单场景接受转圈；体验要求高则换自建服务 |
| 会话记忆 | 前端不该存全量历史，上下文有长度上限 | 后端存会话（Redis/数据库），超长做摘要压缩，前端只传 sessionId |
| 成本失控 | 用户可以无限刷 | 按用户限流 + token 上限 + 高频问题缓存 + 简单问题用小模型 |
| 首响应慢 | 首 token 延迟数秒 | 流式 + 打字机 + 骨架屏；规则能答的别走模型 |
| 工具执行安全 | 模型可能被提示词诱导调危险接口 | 工具白名单、参数强校验、超时熔断、高危操作需二次确认 |
| 跨端适配 | 支付宝/抖音小程序 API 略异 | 用 Taro / uni-app 一套代码编译多端 |

### 7.2 合规备忘（以监管与平台最新规则为准）

- 生成式 AI 备案：面向境内公众提供生成式 AI 服务，按《生成式人工智能服务管理暂行办法》（2023 年 8 月施行）完成相应备案与安全评估；
- 内容标识：按《人工智能生成合成内容标识办法》（2025 年 9 月施行），生成内容需显式标识（界面上标明"AI 生成"）与隐式标识（文件元数据）；
- 平台类目：微信小程序涉及 AI 生成内容需选择对应类目并提交资质；医疗、金融、法律等垂直领域资质要求更严；
- 数据合规：隐私政策明示收集范围，会话数据最小化存储、明确保留期限与存储地域。

## 8. 渐进式上车路线

| 步骤 | 目标 | 关键产出 | 验收标准 |
| --- | --- | --- | --- |
| 1. 本地脚本 Agent | 跑通工具循环（第 3 章代码） | 单文件 Python 脚本 | 命令行能"先查天气再回答" |
| 2. 加知识库 | RAG 客服 demo（第 2 章代码） | faq.json + 检索问答 | 库内问题答得准，库外明确拒答 |
| 3. 上后端 | 把 demo 包成 HTTP 接口 | `/chat` 接口 + 会话 + 限流 | curl 流式跑通 |
| 4. 小程序壳 | 聊天 UI + 流式渲染 | 可真机预览的小程序 | 弱网/断流/超时都有兜底 |
| 5. 上线 | 合规与审核 | 备案、AIGC 标识、类目资质 | 通过平台审核 |

一句话总结：**Agent 是循环，RAG 和 Function Calling 是两大积木，小程序落地的胜负手在后端代理与合规——先在本地把循环跑通，再谈一切框架与产品**。
