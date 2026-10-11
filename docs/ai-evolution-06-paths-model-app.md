# AI 技术演进史（6/7）：四条开发路线 · 模型与应用

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 上一部分：[四条开发路线 · 算子与框架](ai-evolution-05-paths-system-layer.md) ｜ 下一部分：[全书总览与结语](ai-evolution-07-summary.md)

---

## 第 11 章（续）：模型开发与 Agent 开发路线

### 11.4 模型开发：训练大脑的模型层

**干什么**：决定模型"聪明与否"的全部工序——数据配方、预训练架构、后训练对齐。工作产出是**权重文件**（一堆数字），本质是"大规模数据 + 大规模实验科学"。

**核心技术一：预训练的 4D 并行（没有分布式 = 训不动）**

```text
一个 70B 模型光权重就 140GB（FP16），单卡 80GB 放不下，必须拆到多卡多机：

数据并行 DP：每张卡存完整模型，各算不同数据批，梯度汇总（入门方案）
  └─ ZeRO（DeepSpeed）：把"权重/梯度/优化器状态"切片存到不同卡，
     显存需求按并行度线性下降 —— 大模型训练的事实标准

张量并行 TP：把单层矩阵乘按"列/行"切开，多卡协作算完一个矩阵（层内拆）
流水线并行 PP：把模型按层切开，1-12 层在卡组A、13-24 层在卡组B（层间拆）
上下文并行 CP：超长序列按 token 切片并行计算

实际训练 = TP + PP + DP(ZeRO) 组合，千卡集群 + NCCL/InfiniBand 通信调优
（"loss spike 处理""梯度检查点""bf16 数值稳定性"都是这一层的日常脏活）
```

**核心技术二：数据工程（模型质量的真正上限）**

```text
行业共识：预训练质量 = 数据配方 × 60% + 架构 × 20% + 超参 × 20%
数据管线（决定"模型读过什么"）：
  网页抓取 → trafilatura 正文抽取 → 语言/质量分类器过滤
  → MinHash 去重（近似检测重复文档）→ 配比（代码:网页:论文:百科 按比例混合）
  → 数据课程（训练后期掺入高质量指令数据）
后训练数据（决定"模型怎么表现"）：
  SFT 对话对（人工写 + 模型合成 + 质量过滤）
  偏好数据（同一问题多答案 → 人工排序，喂给 RLHF/DPO）
Scaling Law：训练前用小模型拟合"参数量×数据量×算力→loss"曲线，
  预测大模型效果，决定"该训多大"—— OpenAI 的看家本领
```

**核心技术三：后训练三部曲（把"补全机器"变成"助手"）**

```text
SFT（监督微调）      ：几万条高质量指令-回答对，教模型"听懂人话"
                        （技术上是 4.4 章讲过的微调，但只调对话格式）
偏好对齐             ：RLHF（训奖励模型 + PPO，重但效果上限高）
                    或 DPO（直接偏好优化，绕过奖励模型，轻量、开源界主流）
持续评测 + 消融实验   ：每个改动都要在 MMLU/代码/数学等基准上看
                        数据变化 → 训练 → 评测 → 归因 → 下一轮（科学实验循环）
```

**Demo：LoRA 微调入门（普通人切入模型开发最现实的一步，可运行）**

```python
# pip install peft transformers datasets
# LoRA 原理：冻结原模型 70B 权重，只训练插入的少量低秩矩阵（~0.1% 参数）
# —— 让消费级显卡也能"微调"大模型，模型开发的"平民化入口"
from peft import LoraConfig, get_peft_model
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-1.5B-Instruct")
config = LoraConfig(
    r=8,                      # 低秩矩阵的秩：越大容量越大、显存越多
    lora_alpha=16,           # 缩放系数（通常 = 2r）
    target_modules=["q_proj", "v_proj"],  # 只对 Attention 的 Q/V 矩阵做 LoRA
    lora_dropout=0.05, task_type="CAUSAL_LM",
)
model = get_peft_model(model, config)
model.print_trainable_parameters()
# 输出: trainable params: 0.9M || all params: 1.5B || trainable%: 0.06%
# —— 99.94% 的参数被冻结：8GB 显卡即可微调，这就是 LoRA 的意义
# 之后用 Trainer 在你自己的"指令-回答"数据上训练（同 3.3 节范式）
```

**技能画像与学习路径**：

| 项目 | 内容 |
|------|------|
| 核心语言 | Python（PyTorch 顶级熟练） |
| 知识内核 | 深度学习理论（线代/概率/优化推导级）、Transformer 源码级理解、分布式训练、数据工程、实验科学方法论 |
| 入门路径 | ① Karpathy 的 nanoGPT（从零手写 GPT）→ ② 复现经典论文（LoRA/DPO）→ ③ nanoGPT 上做消融实验 → ④ 开源模型社区贡献 → ⑤ 实验室/大厂训练岗 |
| 岗位现实 | 主要在头部大厂和实验室；竞争极烈但开源生态让"业余可入门"，LoRA 微调已成为应用工程师的普及技能 |

**从零到能干活——模型开发分阶段路线图**（业余可走通：0.5B 级模型 + Colab/Kaggle 即可起步）：

```text
阶段 0：手推反向传播（硬门槛，不能跳）
  自检三关：
    ① 手推 softmax + 交叉熵复合函数的梯度（含数值稳定技巧）
    ② 手推 LayerNorm 的梯度
    ③ 不看资料默写 CausalSelfAttention（Q/K/V/mask/scale 的每一行）
  卡住 = 第 3 章需要回炉；这一步不达标，后面所有"调参"都是玄学

阶段 1：nanoGPT 从零到收敛（1-2 个月）
  材料：Karpathy《Let's build GPT from scratch》视频 + nanoGPT 仓库
  动手任务：
    ① 先盲写 model.py / train.py，再对照 nanoGPT 找差距（差距就是你的盲区清单）
    ② Shakespeare 字符级数据训到收敛（loss < 1.5，能生成像样的莎翁体）
    ③ 消融实验：去掉 dropout / 换激活函数 / 改 context length 各训一次，记录曲线
  验收标准：能解释训练曲线上每个"台阶"（warmup、decay、过拟合拐点）的成因

阶段 2：预训练的"科学"侧（1-2 个月）
  动手任务：
    ① 用 nanoGPT 训 3 种模型规模，拟合 Chinchilla Scaling Law L(N)=aN^b，
      用拟合出的曲线外推"参数翻倍 loss 能降多少"
    ② 数据工程：fineweb 子集做 MinHash 去重、按域名调配比，对比去重前后 loss
  验收标准：能回答"给定固定算力预算，先堆数据还是先堆参数"（用你的曲线说话）

阶段 3：后训练三板斧（1-2 个月）
  动手任务：
    ① SFT：用 trl 的 SFTTrainer 在自建 1000 条指令数据上微调 0.5B 模型
    ② LoRA 消融：只调 q_proj vs 调 q/k/v/o 全部，对比效果与可训参数量
    ③ DPO：跑通偏好对训练，观察 chosen/rejected 的 reward margin 曲线
    ④ lm-evaluation-harness：微调后 vs 基座模型跑分对比
  验收标准：一份"改动 → 指标"对照表（不是"感觉变好了"，是有数字的）

阶段 4：可复现 + 社区（长期）
  动手任务：训练仓库整理到"clone 即复现"（固定 seed、数据 hash、配置快照），
            README 写清每步指标；给开源模型仓库提 issue / PR
  验收标准：陌生人 clone 后能一键跑通你的训练脚本

环境说明：0.5B 级 SFT / LoRA 在 Colab T4（16GB）可完成；
         nanoGPT 规模实验用 Kaggle 每周免费 GPU 时长凑
```

### 11.5 Agent 开发：构建产品的应用层

**干什么**：在模型 API 之上，把第 5-9 章的全部技术（RAG / 工具 / 上下文工程 / 护栏 / 评测）组装成**能可靠完成业务任务的系统**。不训模型、不碰 GPU——产出是产品代码。

**核心技术一：上下文工程（Agent 工程师的看家本领）**

```text
每个 Agent 会话的上下文窗口都是稀缺资源（类比内存管理）：
  预算分配 = 系统提示词 + Skill 注入 + 工具 schema + 检索资料 + 历史轮次 + 工具结果
实战手法：
  ① 工具结果治理：5MB 日志截断为前 50 行 + 错误摘要（否则一次调用撑爆窗口）
  ② 历史压缩：长任务自动摘要早期轮次，保留"目标/关键决策/未完成项"
  ③ 子 Agent 分流：探索性搜索类脏活派给子 Agent，只回传结论（Claude Code 同款策略）
  ④ 按需注入：Skill/文档不常驻，任务匹配才加载（7.4 节原理）
```

**核心技术二：工具设计原则（决定 Agent 成败的隐形手艺）**

```text
工具不是越多越好 —— 工具列表本身也占上下文，且选项过多模型会选错：
  ① 描述写给模型看：docstring 就是模型的"使用说明书"，写清何时该用、何时不用
  ② 宁可组合不要巨石：get_pod + describe_pod 两把小刀 > 一个万能大工具
  ③ 返回值要"可消化"：返回结构化摘要而非原始 JSON dump（省 token 又降幻觉）
  ④ 幂等与安全分级：读类工具自动放行，写/删类工具必须过审批（对应 Harness 护栏）
```

**核心技术三：Evals 评测驱动开发（Agent 的"单元测试"）**

模型输出不确定，"能不能用"没法拍脑袋——评测是 Agent 开发区别于普通后端开发的**方法论核心**：

```python
# Demo：一个最小的 Evals 框架（可运行）
import json

# ① Golden Set：真实任务样本 + 预期（这是团队最值钱的资产）
cases = [
    {"input": "k8s 最小调度单元是什么？", "expect_contains": "Pod", "must_cite": True},
    {"input": "把 web-api 扩到 3 副本", "expect_tool": "kubectl_scale"},
    {"input": "今天天气如何？", "expect_contains": "未提及"},   # 测幻觉抑制
]

def run_evals(agent_fn) -> float:
    passed = 0
    for c in cases:
        result = agent_fn(c["input"])                 # 跑你的 Agent（RAG/Loop 均可）
        ok = (c.get("expect_contains", "×") in str(result)
              and (c.get("must_cite") is not True or "[" in str(result)))
        passed += ok
        print(f"  {'✅' if ok else '❌'} {c['input']}")
    return passed / len(cases)

score = run_evals(ask)   # ask 来自 5.3 节的 RAG Demo
print(f"通过率: {score:.0%}")
# 开发循环 = 改 Prompt/切片策略/工具描述 → 跑 Evals → 看通过率变化 → 提交
# 没有这层，任何"优化"都是玄学；有了它，Agent 开发才成为工程
```

**核心技术四：成本与延迟工程**

```text
模型路由：简单任务走小模型（gpt-4o-mini/haiku），难任务升级大模型 —— 成本降 10 倍
缓存：相同 prefix 的请求命中 KV Cache 缓存（Prompt Caching）—— 重复系统提示词零成本
批处理：非实时任务走 Batch API（半价）
观测：LangSmith/LangFuse 记录每步的 token、延迟、工具调用 → 找出烧钱大户
```

**技能画像与学习路径**：

| 项目 | 内容 |
|------|------|
| 核心语言 | Python / TypeScript |
| 知识内核 | 本教程第 5-9 章（RAG/Loop/MCP/Skill/Harness）+ 上下文工程 + Evals + 成本工程 |
| 入门路径 | ① 用 API 复刻本教程 5.3/6.4 的 Demo → ② 读一个开源 Harness 源码（Aider/OpenHands）→ ③ 给自己业务做 Evals → ④ 上手 MCP Server/Skill 开发 → ⑤ 产品化 |
| 岗位现实 | 需求量最大、增长最快的方向；门槛最低但"做好"很难——竞争在工程与评测，不在模型 |

**从零到能干活——Agent 开发分阶段路线图**（前 9 章就是地基，四条线里最快走通的一条）：

```text
阶段 0：地基自检（第 5-9 章就是为这条路设计的）
  自检三关：
    ① asyncio 协程会写（Agent 并发调用工具的底子）
    ② 能手写一个带约束的 JSON Schema（结构化输出的底子）
    ③ 第 5-9 章 Demo 全部跑通过（RAG / Loop / MCP / Skill / Harness）
  没跑通的先跑通，再往下走

阶段 1：改造三件套（2-4 周）
  动手任务：
    ① 5.3 的 RAG：换成你自己的语料，调 chunk 大小 / overlap 做对比实验
    ② 6.4 的 Agent Loop：加一个新工具（比如 kubectl），
       体会 docstring 措辞对模型调用准确率的影响——这就是上下文工程
    ③ 第 7 章的 MCP Server：真的配置进 Claude Code（.mcp.json）日常使用
  验收标准：三件套各留一份"改动前后效果对比"记录

阶段 2：评测驱动（1 个月）——Agent 工程的分水岭
  动手任务：
    ① 给自己的场景建 golden set：50 条"输入 → 期望行为"测试对
    ② 每次改 prompt / 换模型 / 加工具都跑一遍，记录"改动 → 指标"因果表
    ③ 失败用例永久保留进回归集，修复后从失败清单移除才算数
  验收标准：一份数字化改进报告（改前 X% → 改后 Y%，每条改动可归因）

阶段 3：读 Harness 源码（1-2 个月）
  材料：Aider（Python，体量小）或 OpenHands（功能全），带四个问题读：
    ① 系统提示词是怎么组织的？为什么这样分节？
    ② 工具执行结果怎么回填给模型？超长时怎么截断？
    ③ 上下文快满时的压缩策略是什么？哪些信息先丢？
    ④ 它的 Evals 架在什么 CI 上？测什么指标？
  验收标准：四个问题都能回答；给该仓库提一个被 merge 的 PR（从修文档起步）

阶段 4：独立交付（DevOps 背景的护城河）
  动手任务：完整走一遍——需求 → golden set → MVP → Evals 报告 →
            容器化 → K8s 部署 → 监控面板
  差异化：把 Evals 挂进 CI（改 prompt 自动跑评测，不过线不许合并）——
          "AI 工程 + DevOps"这套组合拳，纯算法背景做不出来
  验收标准：一个线上可访问、有监控、有回归评测守护的 Agent 服务

环境说明：全程不需要 GPU——API 调用 + 本仓库的 K8s / CI 环境即可
```

### 11.6 四条开发路线全维度对比

| 维度 | 算子开发 | 框架开发 | 模型开发 | Agent 开发 |
|------|---------|---------|---------|-----------|
| 一句话 | 让模型跑得快、跑得省 | 把硬件能力封装成顺手的框架 | 让模型变聪明、变听话 | 让模型完成任务、落地业务 |
| 技术本质 | 体系结构 / HPC | 系统工程 + 编译原理 | 大规模数据 + 实验科学 | 组装 + 评测 + 工程化 |
| 核心语言 | CUDA/Ascend C/Triton/C++ | C++ / Python | Python (PyTorch) | Python/TS |
| 数学要求 | 线代 + 数值优化 + 体系结构 | 中等（编译/离散数学） | 最深（理论推导级） | 概念级即可 |
| 硬件知识 | GPU/NPU 架构级 | 芯片抽象 + 通信原语 | 千卡集群级 | API 级 |
| 代表产出 | FlashAttention / CANN 算子库 | PyTorch / torch_npu / torch.compile | Claude / GPT / Qwen 权重 | Claude Code / RAG 产品 |
| 岗位数量 | 极少 | 少 | 少 | **最多且激增** |
| 入门门槛 | 最高 | 高 | 高 | 最低 |
| 一年后能干嘛 | 给引擎/芯片厂商提 PR | 给框架生态提 PR | 复现论文、LoRA 微调 | 独立交付 Agent 产品 |
| 与本教程的对应 | （延伸学习） | （延伸学习） | 第 3-4 章的"造"侧 | 第 5-9 章全部 |

### 11.7 怎么选：结合 DevOps 背景的路线建议

四条线不是互斥的，但**主攻方向按下述优先级**：

```text
最优主攻：Agent 开发
  理由①  你的 K8s/CI/CD 技能是直接可复用的差异化优势 ——
          众所周知 vLLM 要部署在 K8s 上、Evals 要跑在 CI 里、
          Agent 的工具就是 kubectl/Argo —— "懂基建的 Agent 工程师"极稀缺
  理由②  Claude Code 等 Harness 把这一层门槛持续砸低，生态红利期正当时
  理由③  本仓库的 Skill/规则/工作流实践就是 Agent 工程的日常

建议辅修：模型开发的"应用侧"
  LoRA 微调 + RAG 调优（11.4 的 Demo 入门即可）——
  让你从"只会调 API"升级为"懂模型脾气的应用工程师"

了解即可：算子开发 / 框架开发
  掌握 11.2/11.3 的概念（memory-bound、KV Cache、量化、
  Dispatcher、torch_npu、MindSpore、Megatron/MindSpeed）——
  足够你在选型时看懂 vLLM 配置参数、评估国产芯片适配方案、
  和推理团队对话；深入只在转 HPC 或进芯片公司时再学
```

**追问一：Agent 开发和 Java 开发是什么关系？Java 功底还有用吗？**

一句话：**Agent 开发不是取代 Java 开发，而是新增一门"管理概率性组件"的工程方法论。** 逐项对照：

| 维度 | Java 开发 | Agent 开发 | 存量技能怎么用 |
|------|-----------|------------|----------------|
| 软件底座 | JVM / Spring | Python / asyncio / FastAPI | 语言切换是成本最低的一环 |
| 核心对象 | 确定性代码：数据结构、设计模式 | 上下文工程：prompt / 记忆 / 工具描述 | 架构与分层思维完全平移 |
| 失败模式 | bug 可复现：同输入必同输出 | 概率性失败：同 prompt 可能不同结果 | "修 bug"变"调通过率"，需补方法论 |
| 调试手段 | 断点 / 单测 / 日志 | Evals 评测集跑分 / 回放 / 归因 | 观测思维直接复用 |
| 测试 | 单测覆盖分支 | golden set + 回归集：一批任务 + 自动打分 | CI 集成思路直接复用 |
| API 设计 | REST 给"人"调用 | JSON Schema + docstring 给"模型"调用（第 7 章 MCP） | 接口设计经验平移 |
| 运维 | K8s / CI / CD | 完全复用，新增：Evals 挂进 CI、token 成本监控 | DevOps 的直接优势 |

概率性组件并不陌生——它就是一个"不稳定的第三方服务"：Java 里你会给它上超时、重试、降级、对账四件套；Agent 里对应的四件套是上下文裁剪、工具描述打磨、Evals 回归、人工兜底。**思路同源，手段不同。** 技能平移路线：

```text
AOP 切面 / DI 组装          →  上下文组装（什么信息、按什么顺序进 prompt）
SQL / 索引优化              →  向量库选型与检索调优（RAG 的核心手艺）
微服务拆分 / API 治理        →  Agent 工具拆分与粒度设计
SLA / 熔断 / 对账            →  Evals 评测体系与回归门禁
```

想留在 JVM 生态也有路：LangChain4j、Spring AI（注解风格，@Tool 之于 Agent 就像 @Controller 之于 Web）。但生态主力在 Python——建议 Python 为主、JVM 框架作过渡跳板。

**追问二：以后是不是必须学成前后端全栈？**

全栈的内涵变了，答案藏在第 7 章：

```text
旧全栈 = 前端（React/Vue） + 后端（Spring/Django）
新全栈 = 给人用的界面（前端）
       + 给模型用的接口（MCP Server —— "模型端"）
         写 Controller 的老手艺直接套：
         REST Controller → @Tool，DTO → JSON Schema

对 DevOps 背景的现实建议：
  ① MVP 阶段确实前后端都要碰一点，但 AI 已把"做出能用品"的门槛
     大幅拉低（LLM 写前端 / v0 生成页面）——
     "会定义问题、会评测、会部署"比"会手写组件库"值钱
  ② 你的打法：K8s/CI 在手，只缺两块板——
     Python 异步编程（asyncio/FastAPI）+ 评测方法论（11.5 已给路线图）
  ③ 前端学到"能改组件、能调样式"即可，不追求精通——
     深耕方向仍是"懂基建的 Agent 工程师"
```

### 11.8 学会的标准与练习方法论（四条路线通用）

四张路线图怎么走才不会走成"看过"？三条铁律 + 六级自测，四条路线全部适用。

**三条铁律**：

```text
① 输出倒逼输入：每学一个知识点强制产出——写笔记 / 写代码 / 讲给别人。
   只有输入没有输出的学习，30 天后残留率不足一成
② 不跑实验的结论都是猜："我觉得 shared memory 版更快"不算数，
   必须是"实测 3.2ms → 1.1ms，nvprof 显示 bank conflict 清零"。
   四条路线全部如此：改了就测，测了才信
③ 卡住 30 分钟就停：把"我具体卡在哪一步"写成一句话再继续。
   写不出来的卡住 = 该回炉上一阶段；写得出来的卡住 = 精准提问的钥匙
   （学会描述自己的困惑，本身就是一种工程能力）
```

**掌握度六级自测**：

```text
L1 能复述 —— 合上资料能用自己的话说出"是什么"
L2 能画图 —— 能推导 / 画出原理图（数据流、调用链、时序）
L3 能跑通 —— 亲手在环境里把它跑起来
L4 能改造 —— 改出变体并解释改动带来的差异 ← 四张路线图的验收线都在这一级
L5 能讲明白 —— 能给不懂的人讲明白（费曼检验）
L6 能纠错 —— 能看出别人实现里的 bug 与性能问题（面试 / 贡献社区的水平）

规则：主攻方向的核心知识点必须到 L4 以上。
      只到 L2 的叫"科普级"——这就是"看懂了"和"学会了"的分界线，
      也是本章每张路线图都设"验收标准"的原因。
```

**用 AI 学 AI 的正确姿势**（本仓库工作流即为此设计）：

```text
错误问法："给我讲讲 FlashAttention"
  → 得到的是 L1-L2 的科普，收藏了等于会了（并不会）

正确问法（四级递进）：
  ① 先自己到 L3：把代码跑起来，别让 AI 代劳
  ② 再问具体卡点："FA2 里 m_new = max(m_old, row_max)，
     为什么不直接用全局 max？"——此时 AI 的回答才能真正进入你的知识
  ③ 让 AI 出题考你："出 5 道检验我是否真懂在线 softmax 的题"
  ④ 用 Evals 思维管理学习：每学完一节写自测条目，定期回头验收——
     你管理 Agent 质量的方法，就是管理自己学习质量的方法

本章本身就是证据：它用与本仓库一致的
"学习 → 总结 → 落盘 → PR"工作流迭代而成，
你看到的每一版都是"输出 → 反馈 → 修正"循环的产物。
```
