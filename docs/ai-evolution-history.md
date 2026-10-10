# AI 技术演进史：从机器学习到 Claude Code

本文按时间线完整梳理 AI 技术的六个大阶段：传统机器学习 → Transformer → LLM 多模态 → RAG → Agent（MCP / Skill / Harness）→ Claude Code。每个阶段都按同一套结构讲解：**背景故事 → 原理拆解 → 完整 Demo → 使用场景与现状 → 与上一阶段的区别 → 局限性（引出下一代技术）**。

## 阅读指南

- 想快速看懂主线：只读每章开头的故事和结尾的对比表。
- 想动手实践：每章的 Demo 都可独立运行，建议按顺序跑一遍。
- 每章末尾"局限性"一节是理解下一代技术"为什么必然出现"的关键，不要跳过。

## 0. 全景图：一条主线看懂 70 年演进

```text
1950s      2012       2017        2020        2022      2023        2024        2025
  |          |          |           |           |          |           |           |
规则系统 → 深度学习  → Transformer → LLM涌现  → ChatGPT   → RAG成熟    → MCP/Skill  → Agent
(写死if-else) (CNN/RNN)  (注意力机制)   (GPT-3)    (RLHF对齐)  (外挂知识)   (标准化生态)  Harness爆发
                                              (多模态GPT-4) (Function     (Claude Code)
                                                             Calling/Agent)
```

每一代技术的出现，都是为了解决上一代的致命缺陷：

```text
传统ML：手工特征太贵、只会算不会"理解"
    ↓ 深度学习：自动学特征，但 RNN 长句子会"失忆"
        ↓ Transformer：长程依赖解决，但一个任务要微调一个模型
            ↓ LLM/ICL：写提示词就能用，但会幻觉、知识过期
                ↓ RAG：外挂知识库，但只会"查着答"不会"动手做"
                    ↓ Function Calling/Agent：能调工具了，但每个工具接入都是体力活
                        ↓ MCP/Skill：工具和能力标准化，但缺少工程化运行时
                            ↓ Harness：完整运行时，垂直场景引爆 → Claude Code
```

一句话主线：

> **ML 学特征 → Transformer 学表示 → LLM 学知识 → RAG 借知识 → Agent 借工具 → MCP/Skill 标准化能力 → Harness 工程化 → Claude Code 垂直引爆**

---

## 1. 传统机器学习时代（1950s - 2017）

### 1.1 背景：规则系统的困境

在机器学习出现之前，让计算机"智能"的方式是**手写规则**。例如垃圾邮件过滤：

```python
# 规则系统的写法：人把所有判断逻辑写成 if-else
def is_spam(email):
    if "中奖" in email.content:
        return True
    if email.sender in BLACK_LIST:
        return True
    if "点此链接" in email.content:
        return True
    return False
```

规则系统的致命问题：

- 规则永远写不完：垃圾邮件换个说法（"恭喜您被抽中"）就绕过了规则。
- 规则会互相冲突：维护成本随规则数量指数增长。
- 无法泛化：换一个国家、换一种语言，全部重写。

于是人们换了一个思路：**与其教机器"规则"，不如给机器"例子"，让它自己从数据中总结规律**。这就是机器学习。

### 1.2 机器学习的本质：从数据中拟合函数

所有监督学习都在干一件事——找一个函数 `y = f(x)`，使得它在没见过的数据上也能预测准确。

```text
训练数据（历史邮件 + 是否垃圾的标注）
        │
        ▼
  学习算法调整 f 的内部参数
        │
        ▼
得到模型 f：输入新邮件 → 输出 0.93（93% 概率是垃圾邮件）
```

三大学习范式：

| 范式 | 输入 | 典型问题 | 例子 |
|------|------|---------|------|
| 监督学习 | 数据 + 标准答案 | 分类、回归 | 垃圾邮件分类 |
| 无监督学习 | 只有数据，无答案 | 聚类、降维 | 用户分群 |
| 强化学习 | 环境 + 奖励信号 | 决策序列 | AlphaGo 下棋（这一支后来成为 RLHF 的基础） |

### 1.3 特征工程：手工时代的命门

传统机器学习 80% 的工作量在**特征工程**——把原始数据（一张图、一段文字）转换成模型能吃的数字向量，而且这个转换完全靠人的经验。

以"识别图片里是不是猫"为例：

```text
原始图片（百万像素）
    ↓ 人工设计特征提取器
HOG 特征（边缘方向直方图，256 维向量）
    ↓
SIFT 特征（局部关键点描述子）
    ↓
SVM 分类器 → 是猫 / 不是猫
```

特征工程的痛点：

- **极度依赖领域专家**：图像特征要懂 CV 的人设计，文本特征要懂 NLP 的人设计。
- **天花板低**：人能想到的特征就那几种，复杂模式（比如"猫的耳朵和胡须的组合关系"）很难手工描述。
- **换任务就作废**：猫的特征提取器不能用于识别车牌。

### 1.4 经典模型直观原理

**决策树——一串嵌套的 if-else，但让机器自己学：**

```text
判断是否放贷（机器从历史数据中自动学出这棵树）：
收入 > 2万？
├── 是 → 征信有逾期？
│        ├── 是 → 拒绝
│        └── 否 → 放款
└── 否 → 工龄 > 5年？
         ├── 是 → 人工审核
         └── 否 → 拒绝
```

**SVM——找一个"最胖"的分隔线：**

```text
二维平面上有两类点（比如：逾期客户○ vs 正常客户×）：

○ ○ ○                  ┃ 分隔线
  ○  ○         ┃         × ×
   ○   ○     ┃    ×   × ×
○     ○  ○   ┃   × × ×
           └──┴──┘
        "安全边距"：SVM 就是要让这条边距最宽
        边距越宽，新数据分错的概率越小（泛化越好）
```

**GBDT/XGBoost——一群"弱鸡"决策树接力纠错：**

```text
第1棵树：预测偏差大（只对了一半）
第2棵树：专门学第1棵树的"错误残差"
第3棵树：专门学前两棵叠加后的残差
...
最终预测 = 树1 + 树2 + 树3 + ...  （每棵树都很弱，加起来很强）
```

XGBoost 为什么至今流行：训练快（支持并行）、防过拟合内置、对缺失值不敏感、表格数据上经常吊打深度学习。

### 1.5 Demo：表格数据分类（可运行）

```python
# pip install xgboost scikit-learn
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

# 数据：乳腺癌肿瘤的 30 个测量指标（半径、纹理、周长……），标签：良性/恶性
data = load_breast_cancer()
X, y = data.data, data.target  # X 是 (569, 30) 的特征矩阵 —— 特征已由数据集提供

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = xgb.XGBClassifier(n_estimators=100, max_depth=3, learning_rate=0.1)
model.fit(X_train, y_train)
print(f"测试集准确率: {model.score(X_test, y_test):.3f}")  # 通常 0.95+

# 传统 ML 的王牌优势：可解释性 —— 每个预测都能说清楚依据
for name, score in sorted(zip(data.feature_names, model.feature_importances_),
                          key=lambda t: -t[1])[:5]:
    print(f"  {name}: {score:.3f}")
# 输出示例：worst perimeter (最差周长) 是最重要的判断依据 —— 医生能看懂、能复核
```

### 1.6 使用场景与现状

**至今仍是首选的场景（没有被深度学习取代）：**

- 推荐系统的排序层：CTR 预估的第一版基线几乎都是 XGBoost/LightGBM。
- 金融风控评分卡：逻辑回归 + XGBoost，因为监管要求模型可解释。
- 一切"表格型"数据：行是样本、列是字段的业务数据，GBDT 系经常优于神经网络。
- 小数据集（几千条以内）：深度学习样本不足会过拟合，传统 ML 反而稳。

### 1.7 与下一代的分界：局限性

| 局限 | 具体表现 | 导致了什么 |
|------|---------|-----------|
| 手工特征 | 图像/文本的复杂模式人描述不了 | 催生深度学习：让机器自己学特征 |
| 任务单一 | 一个模型只干一件事 | （后来 LLM 用"一个模型干所有事"解决） |
| 不理解语义 | "苹果很好吃"和"苹果发布会"被当成同一个"苹果" | （后来 Word Embedding/Transformer 解决） |

**关键转折**：2012 年，ImageNet 图像识别大赛上，深度学习方案 AlexNet 把错误率从 26% 一举干到 15%，碾压所有手工特征方案。深度学习时代开始。

---

## 2. 深度学习前夜：神经网络时代（2012 - 2017）

这一章是理解 Transformer 的必要铺垫——**Transformer 的每一块零件都来自这个时代的积累**。

### 2.1 神经网络的基本原理：可微分的万能函数拟合器

一个"神经元" = 一次加权求和 + 一次非线性：

```text
输出 = 激活函数(w1·x1 + w2·x2 + w3·x3 + b)

例：判断"是否给贷款"
输出 = relu(0.7×收入 + 0.2×工龄 - 0.9×逾期次数 - 0.5)
```

训练过程就是不断微调权重，让预测误差变小（反向传播 + 梯度下降）。多层堆叠后，神经网络理论上能拟合任何函数——这就是"深度"学习的含义：**特征不再由人设计，而是由网络层逐层自动学出**：

```text
输入图片像素
  ↓ 第1层学到：边缘、色块
  ↓ 第2层学到：角点、纹理
  ↓ 第3层学到：眼睛、耳朵等部件
  ↓ 第4层学到：整只猫
（每一层都以上一层的输出为"原料"—— 这就是"自动特征学习"）
```

### 2.2 CNN：处理图像的专用架构

CNN 的核心是**卷积核**——一个 3x3 的小窗口在图片上滑动扫描，每个位置问一遍"这里有没有我负责的特征？"

```text
图片（224x224）
  ↓ [卷积层1] 学边缘 → [池化层] 图片缩小一半
  ↓ [卷积层2] 学纹理 → [池化] 再缩小
  ↓ [卷积层3] 学部件
  ↓ [全连接层] 综合判断 → "是猫，置信度 0.87"
```

**成功原因**：卷积核在整张图上共享同一套权重（猫在左上角和右下角用同一个检测器），参数量暴减，且天然符合图像的局部性。

**代表时刻**：2012 AlexNet（错误率 26%→15%）→ 2014 VGG/GoogLeNet → 2015 ResNet（错误率 3.6%，超过人类）。

### 2.3 RNN/LSTM：处理文本的专用架构（以及它的致命缺陷）

文本是**序列**："我/爱/北京/天安门"，词的顺序变了意思就变了。RNN 的思路是**逐词阅读，边读边更新记忆**：

```text
RNN 处理"我不喜欢这个电影"：
读"我"    → 记忆 h1 = [对主语的印象]
读"不"    → h2 = f(h1, "不")   ← 记忆被更新
读"喜欢"  → h3 = f(h2, "喜欢")
...
读完全部  → 最终记忆 hn → 分类"负面情感"
```

**致命缺陷：长程依赖（梯度消失）**

处理"这个电影，尽管开头很无聊，但后半段的剧情非常精彩"时：

```text
读到句尾"精彩"时，模型需要"回忆起"开头出现了"尽管"（转折关系）
但 RNN 的记忆每一步都要乘以权重矩阵：
    h1 × W → h2 × W → h3 × W → ... × W → h20
信息经过 20 次连乘后：
    - 若 W < 1 → 信息衰减为接近 0（梯度消失，开头全忘了）
    - 若 W > 1 → 信息爆炸（梯度爆炸，训练发散）
LSTM 加了"门控"（遗忘门/输入门/输出门）来选择性保留记忆，
把可处理的长度从 ~10 词延长到 ~100 词，但治标不治本。
```

另一个问题：RNN 必须**逐词串行计算**，第 2 步依赖第 1 步的输出，无法并行——训练大规模模型速度太慢。

### 2.4 这个时代留下的遗产与缺口

| 遗产 | 被谁继承 |
|------|---------|
| 词向量 Word2Vec（"国王-男人+女人≈女王"） | Embedding（RAG 向量检索的地基） |
| Seq2Seq + Attention（机器翻译中先试用注意力） | Transformer（注意力机制直接源自这里） |
| 梯度下降、反向传播 | 所有深度学习 |

**缺口**：RNN 管不好长序列且不能并行 → 2017 年，Google 论文《Attention Is All You Need》说：既然注意力机制才是真正干活的，那把 RNN 整个删掉如何？

---

## 3. Transformer 革命（2017 - 2020）

### 3.1 核心：Self-Attention 让每个词直接"看到"所有词

RNN 是逐词传话，Transformer 是**开会**——每个词把自己的含义广播给全场，同时听取其他所有词的信息，一次计算全部完成。

**手推一遍（用真实数字）：**

句子"猫 追 老鼠"，每个词先变成向量（此处用 4 维示意）：

```text
"猫"  = [1, 0, 1, 0]      ← 这些是词的 Embedding（Word2Vec 的后代）
"追"  = [0, 1, 0, 1]
"老鼠" = [1, 1, 0, 0]
```

每个词通过三个可学习的矩阵，生成三种角色：

```text
Query (Q)：我想找什么信息？
Key   (K)：我能提供什么信息？
Value (V)：我实际携带的内容

简化示意（真实矩阵是模型学出来的，维度 512/1024 等）：
"猫"的 Q = [1, 0]   ← 「猫」在找：谁跟我有关系？
"追"的 K = [1, 1]   ← 「追」提供的信息：动作
```

**第 1 步：打分（谁的 Key 和我的 Query 最匹配？）**

```text
"猫"的注意力得分（Q·K 点积）：
  对"猫"：  [1,0]·[1,0] = 1
  对"追"：  [1,0]·[1,1] = 1
  对"老鼠"：[1,0]·[1,1] = 1
```

**第 2 步：Softmax 归一化成注意力权重**

```text
真实训练中权重会有区分（这里取示意值）：
  对"猫"：0.2    对"追"：0.5    对"老鼠"：0.3
```

**第 3 步：加权求和 Value，得到"猫"的新表示**

```text
新"猫" = 0.2×V(猫) + 0.5×V(追) + 0.3×V(老鼠)
       = "猫"的原始含义 + "追"这个动作的语境 + "追的对象是老鼠"
```

这一步的威力：**"猫"的新向量已经融合了整句话的语境**。而 RNN 要"传话"传到最后一个词才有这个效果，且传话会失真，Transformer 直接一次到位、且任意两个词之间的距离都是 1（不管相隔多远）。

**复杂度对比：**

```text
RNN 处理 n 个词：必须串行 n 步，第 i 词依赖第 i-1 词
Self-Attention：n 个词一次性并行计算（GPU 最爱）
代价：任意两词都要两两打分，计算量 O(n²) —— 这是后来长上下文优化的主战场
```

### 3.2 三大架构分支：同一底座，三种用法

| 分支 | 结构 | 擂主 | 天生擅长 | 典型任务 |
|------|------|------|---------|---------|
| Encoder-only（双向） | 只用编码器，每个词同时看左右 | BERT | **理解**类任务 | 分类、搜索、实体识别 |
| Decoder-only（单向） | 只用解码器，只许看左边 | GPT | **生成**类任务 | 写作、对话、代码 |
| Encoder-Decoder | 两个都要 | T5 | 输入和输出都是序列 | 翻译、摘要 |

为什么 BERT 不能用来写文章：它是双向的（写每个词时偷看了后文），训练方式是"完形填空"，天生是"阅读理解型选手"。GPT 用"预测下一个词"训练，天生是"写作选手"——**这个当时不被看好的分支，最终长成了 LLM**。

### 3.3 预训练 + 微调范式：NLP 工业界的工作流

这个时代做 NLP 任务的标准流程（2019-2021 年所有公司的做法）：

```text
第 1 步：下载 BERT（已在 40GB 文本上预训练过，"读过全世界"）
第 2 步：准备你自己的标注数据（如 5000 条"评论+情感标签"）
第 3 步：在 BERT 顶部加一个小分类头，用你的数据微调
第 4 步：得到一个专用情感分类模型
（换任务？换一批数据，重复第 2-4 步 —— 每个任务一个模型）
```

### 3.4 Demo：BERT 文本分类 + 语义检索（可运行）

```python
# pip install transformers torch sentence-transformers

# ── Demo 1：BERT 情感分类（预训练+微调范式的"使用侧"）──
from transformers import pipeline

# 直接加载微调好的情感分类模型（生产中你会用自己的数据微调一个）
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")
print(classifier("The service at this hotel was terrible!"))
# [{'label': 'NEGATIVE', 'score': 0.9998}]
# 注意：这个模型只会情感分类这一件事 —— 换任务必须换模型

# ── Demo 2：Sentence-BERT 语义检索（RAG 的前身）──
from sentence_transformers import SentenceTransformer, util

# 把句子变成向量：语义相近 → 向量距离相近
model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
docs = ["K8s Pod 是最小调度单元",
        "Ingress 负责七层路由",
        "Docker 镜像是分层只读结构"]
query = "k8s 最小的调度单元是什么"

vecs = model.encode(docs + [query])          # 4 个向量
scores = util.cos_sim(vecs[-1], vecs[:-1])[0]  # 问题 vs 3 条文档的余弦相似度
best = scores.argmax().item()
print(f"最相关: {docs[best]} (相似度 {scores[best]:.3f})")
# 输出: 最相关: K8s Pod 是最小调度单元 (相似度 ~0.8)
# ← 这就是"语义"检索：哪怕没有一个字精确匹配（"最小"≠"最小的"）也能找到
#    关键词检索（BM25）做不到这一点
```

**记住 Demo 2，它是第 5 章 RAG 的核心零件。**

### 3.5 使用场景与现状

- 产业界仍有大量 BERT 系小模型在线上跑：成本低（CPU 可推理）、延迟低、效果好。
- 情感分类、命名实体识别、搜索召回等单任务场景，微调小模型依然是性价比之王。
- 微调技术本身进化为 LoRA/QLoRA（只训练少量增量参数），在后面 LLM 时代继续用。

### 3.6 局限性：为什么必然走向 LLM

| 局限 | 具体表现 | 导致了什么 |
|------|---------|-----------|
| 一任务一模型 | 做 10 个任务要微调 10 个模型，维护噩梦 | 催生 In-context Learning：写提示词直接用 |
| 任务间不共享能力 | 文本摘要模型不会翻译，浪费重复训练 | 催生"通用模型"：能力集中在一次预训练里 |
| 小数据微调易过拟合 | 标注 500 条以下的任务效果差 | 大模型零样本/少样本直接解决 |

转折点：2020 年，OpenAI 发布 GPT-3（1750 亿参数），人们惊讶地发现——**不给任何微调数据，只在提示词里给几个示例，它就能做翻译、写代码、做摘要**。

---

## 4. LLM 与多模态时代（2020 - 2023）

### 4.1 GPT-3 与"涌现"：参数量从"量变"到"质变"

GPT-2 只有 15 亿参数，还只是个"高级补全器"。GPT-3 干到 1750 亿，训练数据从 40GB 变成 570GB。学界发现一件诡异的事：

```text
参数规模        简单任务(分类)   复杂任务(推理/代码)
1B  (10亿)      缓慢提升        几乎为零 —— 纯属乱猜
10B (100亿)     缓慢提升        接近零
100B(1000亿)    稳定提升        突然跳升 ← "涌现"（Emergent Ability）
```

**涌现**：某些能力（多位数加减法、代码生成、思维链推理）在小模型上完全不存在，规模跨过某个阈值后突然出现。这是"大力出奇迹"的理论依据，也是各家疯狂堆参数的原因。

### 4.2 In-context Learning：提示词代替微调

同一个情感分类任务，两种范式的直接对比：

```text
【旧范式：微调】
准备 5000 条标注 → 微调 BERT 2 小时 → 得到专用模型
换任务？再来一遍。

【新范式：In-context Learning（GPT-3 起）】
写一段提示词：

    将评论分类为正面或负面：
    评论：这部电影太无聊了 → 负面
    评论：演员演技炸裂 → 正面
    评论：服务太差了 →

模型直接输出：负面

零训练、零微调、秒级切换任务。5000 条标注数据 → 变成提示词里 2 个示例。
```

这就是为什么 GPT 论文标题是 "Language Models are Few-Shot Learners"（语言模型是少样本学习者）。

### 4.3 ChatGPT 时刻：RLHF 让模型"听话"（2022.11）

GPT-3 其实早就有了，为什么直到 2022 年底全世界才炸锅？中间差的正是**对齐（Alignment）**：

```text
原始 GPT-3：你问"怎么煮咖啡"它可能反问"什么是咖啡？"（纯补全机器）
    ↓
第 1 步：指令微调（SFT）—— 人工写 1 万+ 条高质量问答对，
         教模型"用户提问 → 就该好好回答"
    ↓
第 2 步：RLHF（人类反馈强化学习）
         - 让模型对同一问题生成 4 个回答
         - 人类标注员排序：哪个回答最好
         - 训练"奖励模型"学会给回答打分
         - 用强化学习（PPO）让 LLM 朝高分方向优化
    ↓
ChatGPT：会聊天、会认错、懂分寸、拒绝不当请求
```

RLHF 的技术底子正是第 1 章讲过的**强化学习**——70 年代的老技术在 2022 年完成了最出圈的回归。

### 4.4 多模态：从 CLIP 到 GPT-4V/Sora

多模态的两条技术路线：

```text
路线 A（对比学习，2021 CLIP）—— 让"图"和"文"对齐到同一向量空间：
  4 亿张"图片-文字描述"对
  训练目标：猫的图片向量 ≈ "一张猫的照片"的文字向量
  结果：搜索/零样本分类能力强（RAG 多模态检索的地基）

路线 B（统一序列建模，2023 GPT-4V 起）—— 把图变成"另一语言的 token"：
  图像切块 → 每块转成向量 → 当作"外语词"混进文本序列
  Transformer 不在乎输入是文字还是图片，统一用 Attention 处理
  结果：能看图答题、看图写代码、看图讲笑话

Sora（2024）：把视频当"时空补丁序列"生成 → 路线 B 的视频版
```

### 4.5 Demo：提示工程实战（可运行）

```python
# pip install openai
from openai import OpenAI

client = OpenAI()  # 需设置 OPENAI_API_KEY

# ── 技巧 1：角色设定 + 输出格式约束 ──
resp = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": "你是 K8s 运维专家，回答不超过 3 句话，必须给出可执行命令。"},
        {"role": "user", "content": "怎么查看 Pod 的实时日志？"},
    ],
)
print(resp.choices[0].message.content)
# → "使用 kubectl logs -f <pod-name> ..."（约束生效：简短+带命令）

# ── 技巧 2：Few-shot 示例（In-context Learning 实操）──
resp = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": """把告警翻译成一句话人话：

示例：
输入: CPU 使用率 95%，持续 5 分钟 → 输出: 服务快被压垮了，5 分钟内满负荷
输入: 内存 92%，OOMKilled 3 次 → 输出: 内存不够，容器已经因内存不足被杀过 3 次
输入: 磁盘 85% → 输出:"""}],
)
print(resp.choices[0].message.content)

# ── 技巧 3：多模态输入（路线 B 的使用面）──
resp = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": [
        {"type": "text", "text": "这张架构图有什么问题？"},
        {"type": "image_url", "image_url": {"url": "https://example.com/arch.png"}},
    ]}],
)
```

### 4.6 局限性：LLM 的三大原罪

| 原罪 | 表现 | 催生的技术 |
|------|------|-----------|
| **幻觉** | 一本正经编造不存在的 API、论文、历史事件 | → RAG（第 5 章） |
| **知识截止** | 训练数据截止日之后的事一概不知；私有数据没读过 | → RAG |
| **没有双手** | 只会"说"不会"做"：不能查数据库、发邮件、执行代码 | → Function Calling/Agent（第 6 章） |

幻觉实例（跑一次就能体会）：

```text
问：介绍一下 kubectl get-node-status 这个命令
LLM：kubectl get-node-status 用于查看节点状态……（编造！根本没有这个命令，
     但语气无比自信，参数、flag、示例全都"煞有介事"）
```

原因：LLM 的本质是"预测最像答案的下一个词"，它没有"事实"和"编造"的边界。

---

## 5. RAG：给 LLM 外挂知识库（2023）

**RAG = Retrieval-Augmented Generation（检索增强生成）**：回答问题前先查资料，再基于查到的资料作答——就是"开卷考试"。

### 5.1 为什么 RAG 是刚需

LLM 幻觉的另一种解法是"微调"或"等下一代模型"，但都不现实：

| 方案 | 问题 |
|------|------|
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
|------|------|---------|-----------|
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
|---------|---------|
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
|------|------|------|------|
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

**Demo：一个"周报生成" Skill 的完整定义**

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
|------|-----------------|-----|-------|
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
|----------------------|---------------------------|
| 无限循环，烧钱失控 | 步数上限 + 熔断 + 预算控制 |
| 工具报错照走不误 | 报错作为观察结果回喂，自动修正 |
| 上下文无限增长直到截断 | 自动压缩、子 Agent 分流 |
| 危险命令直接执行 | 审批/沙箱/白名单 |
| 黑盒，不知道它要干嘛 | Plan Mode + 轨迹可视化 |

### 8.3 代表性 Harness 产品格局

| 产品 | 形态 | 定位 |
|------|------|------|
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
|-----------|---------|------------------------|
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
|------|------|
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
|------|-----------|------------|
| **推理模型** | o1/o3、Claude 思考模式：生成前先"长思考"（测试时计算 Test-time Compute） | 思维链（CoT）的工程化 |
| **A2A 协议**（Google） | Agent 之间互相通信的标准——MCP 连"工具"，A2A 连"Agent" | MCP 的横向扩展 |
| **Agentic RAG** | 检索成为 Agent 的动态工具 | 第 5、6 章的合流 |
| **多 Agent 协作** | 规划者/执行者/评审者分工（本仓库日常使用的 Task/Subagent 即此类） | Harness 的子 Agent 延伸 |
| **Computer Use / GUI Agent** | 直接看屏幕、点鼠标操作任何软件，绕过"没有 API"的限制 | 多模态 + 工具使用的合流 |

---

## 11. 四条 AI 开发路线：算子开发 / 框架开发 / 模型开发 / Agent 开发

学完前 10 章自然会问：**"我想吃 AI 这碗饭，该从哪一层入手？"** 行业内其实是四条完全不同的职业，技术栈几乎不重叠。本章把四者的工作内容、技术实现、学习路径彻底讲清——其中算子层覆盖英伟达 CUDA 与昇腾 Ascend C 两条栈，框架层以 PyTorch 技术内幕与国产框架（torch_npu/MindSpore）为主线。

本章不止于"讲清楚是什么"，四条路线各附一张**分阶段学习路线图**：阶段目标 → 具体动手任务 → 验收标准，并给出"没有 GPU / 没有昇腾卡也能起步"的替代环境方案；11.8 给出通用的"学会的标准"。目标是让你照着走能真正学会，而不是看完只记得几个名词。

### 11.1 四层技术栈全景：它们各自站在哪一层

```text
┌──────────────────────────────────────────────┐
│  ④ Agent 开发（应用层）—— 造"产品"             │
│  在现成模型 API 之上搭建能完成任务的系统         │
│  产出：Claude Code / Cursor / 客服机器人 / RAG  │
│  ← 本教程第 5-9 章全部内容都是这一层            │
├──────────────────────────────────────────────┤
│  ③ 模型开发（模型层）—— 造"大脑"               │
│  训练模型本身：预训练 / 微调 / 对齐             │
│  产出：Claude / GPT / Qwen / Llama 的权重文件   │
│  ← 本教程第 3-4 章讲的是"用"，这一层是"造"      │
├──────────────────────────────────────────────┤
│  ② 框架开发（框架层）—— 造"神经系统"           │
│  开发 PyTorch 这类框架本身：算子调度、自动求导、 │
│  分布式、图编译；以及把新芯片接入框架生态         │
│  产出：PyTorch / MindSpore / torch_npu         │
│  ← 大脑离开神经传导，肌肉再强也是瘫痪            │
├──────────────────────────────────────────────┤
│  ① 算子开发（系统层）—— 造"肌肉"               │
│  让模型在 GPU/NPU 上跑得快、跑得省：CUDA /      │
│  Ascend C 算子、推理引擎、量化                  │
│  产出：FlashAttention / vLLM / CANN 算子库      │
│  ← 没有这一层，模型只是硬盘里的大文件           │
└──────────────────────────────────────────────┘

依赖关系：① 造硬件原语 → ② 封装成框架 → ③ 用框架训模型 → ④ 拿 API 组装成产品
分工类比：① 造发动机  ② 造变速箱与线束  ③ 造"驾照考试"（教练）
          ④ 赛车运营（比赛拿名次）
```

### 11.2 算子开发：榨干 GPU/NPU 的系统层

**干什么**：写 GPU 上运行的底层计算函数（算子 = Kernel），优化推理引擎，让同一个模型推理速度翻倍、成本减半。这是纯高性能计算（HPC）工作，本质是**体系结构问题而非 AI 问题**。

**为什么需要它（一个数字看懂）**：

```text
朴素实现的 Self-Attention 有多贵？
序列长度 N=4096，注意力矩阵 N² = 1600 万个元素
用 FP16 存：1600万 × 2字节 × 3(权重) ≈ 100MB+，且每层都要算
瓶颈根本不在"算"（GPU 算力过剩），而在"搬"（显存带宽 HBM 只有几个 TB/s）
—— 这种情况叫 memory-bound（访存受限），优化思路 = 减少显存读写次数

FlashAttention（2022，目前一切推理引擎的标配）三板斧：
① Tiling 分块：把 Q/K/V 切成小块装进片上 SRAM（比 HBM 快 10 倍+）
② 在线 Softmax：块与块之间不落盘，边算边更新，中间结果不回写 HBM
③ Kernel Fusion：多个算子融合成一次 GPU 调用，减少读写往返
结果：显存从 O(N²) 降到 O(N)，速度 2-4 倍 —— 这就是一个算子工程师的价值
```

**推理引擎的四大核心技术（算子开发的集大成产物）**：

```text
1. KV Cache：解码"我爱北京"的第 5 个词时，前 4 个词的 K/V 向量缓存复用，
   避免每生成一个词就重算全部历史 —— 没有它，生成速度慢 N 倍

2. PagedAttention（vLLM 核心创新，借鉴 OS 虚拟内存分页思想）：
   朴素 KV Cache 按最大长度预留显存 → 严重碎片浪费（就像不分段直接分配内存）
   PagedAttention 把 KV Cache 切成固定"页"按需分配 → 显存利用率 60%→95%+，
   服务吞吐直接翻 2-4 倍 —— 注意：这是 OS 的分页思想在 GPU 上的复刻！

3. Continuous Batching：请求级动态组批——新请求随时插入、完成的随时退出，
   而不是等一批全部跑完（静态批处理的 GPU 利用率可能只有 30%）

4. 量化：FP16 权重 → INT8/INT4 存储与计算
   GPTQ/AWQ（训练后量化，剪掉"不重要"的精度位）
   效果：显存减半再减半，INT4 时 70B 模型可塞进单卡消费级显卡
```

**Demo：Triton 写一个最简单的 GPU 算子（可运行）**

```python
# pip install triton torch
import triton
import triton.language as tl
import torch

@triton.jit  # ← Triton：不用写 C++/CUDA，用 Python 语法写 GPU 算子
def add_kernel(x_ptr, y_ptr, out_ptr, n, BLOCK: tl.constexpr):
    pid = tl.program_id(0)                       # 当前是第几个程序块
    offs = pid * BLOCK + tl.arange(0, BLOCK)      # 本块负责的元素下标
    mask = offs < n                              # 边界保护（n 不整除 BLOCK 时）
    tl.store(out_ptr + offs,                     # 结果写回显存
             tl.load(x_ptr + offs, mask=mask) + tl.load(y_ptr + offs, mask=mask),
             mask=mask)

def gpu_add(x, y):
    out = torch.empty_like(x)
    n = x.numel()
    grid = lambda meta: (triton.cdiv(n, meta["BLOCK"]),)  # 并行块数
    add_kernel[grid](x, y, out, n, BLOCK=1024)
    return out

x, y = torch.rand(1_000_000, device="cuda"), torch.rand(1_000_000, device="cuda")
assert torch.allclose(gpu_add(x, y), x + y)
# 这就是算子开发的日常：把一个数学操作编译成 GPU 并行程序
# 真实的 FlashAttention/RMSNorm/RoPE 就是这种 kernel 的复杂版
```

**国产平行世界：昇腾 Ascend C 算子开发（同一个问题，另一套硬件）**

CUDA 是英伟达世界的算子语言；在华为昇腾 NPU 的世界里，对应物叫 **Ascend C**。两者解决的问题一模一样——把数学运算变成芯片上的并行程序——但硬件设计思路不同，写法随之分叉。国产芯片放量后，这套技能在昇腾生态里被完整复刻：

```text
达芬奇（Davinci）架构 —— NPU 与 GPU 的根本分歧：
  GPU 思路：数千个通用小核（SM），靠海量线程填满芯片（SIMT 模型）
  NPU 思路：少量 AI Core，每核内"专用单元分工"：
    ① Cube 单元：矩阵乘专用电路（一次算完一整块矩阵乘，天生为 AI 而生）
    ② Vector 单元：向量运算（Softmax / 激活 / 逐元素操作）
    ③ Scalar 单元：标量控制（循环 / 地址 / 分支）
  记忆层次与 GPU 同构：Global Memory(HBM) → 片上 Unified Buffer → 寄存器

CANN 软件栈 —— 与 CUDA 全栈逐层对标：
  驱动固件        ↔  Ascend HDK（含驱动/固件）
  运行时          ↔  ACL Runtime（对标 CUDA Runtime）
  算子语言        ↔  CUDA C++（nvcc） ↔ Ascend C（CANN 编译器）
  基础算子库      ↔  cuBLAS/cuDNN ↔ CANN 内置融合算子库
  框架            ↔  PyTorch ↔ torch_npu / MindSpore
  推理引擎        ↔  vLLM ↔ vllm-ascend

Ascend C 编程范式 —— 与 CUDA 的三大差异：
  ① 并行主体：CUDA 一个线程算一个元素；Ascend C 一个 AI Core 算一块数据
  ② 内存搬运显式化：GM↔UB 的数据用「队列 TQue + DataCopy(DMA)」显式搬运，
     配合双缓冲实现"搬运与计算流水重叠"（思想同 FlashAttention 的 tiling）
  ③ 固定三段式：CopyIn(GM→UB) → Compute(硬件指令) → CopyOut(UB→GM)
```

**Demo：Ascend C 版向量加法（需昇腾卡 + CANN 工具链，看结构与 CUDA 的对照为主）**

```cpp
// 开发流程：写 .cpp 算子 → msopgen 生成工程骨架 → 编译成 .run 部署
//           → Host 侧经 aclnn 接口调用（对标 torch.ops 调用 kernel）
#include "kernel_operator.h"   // Ascend C 核心头文件：TPipe/TQue/Tensor 都在这里

using namespace AscendC;

constexpr int32_t BUFFER_NUM = 2;  // 双缓冲：上一块在算时下一块已在搬（流水线）

class KernelAdd {
public:
    __aicore_inline__ void Init(GM_ADDR x, GM_ADDR y, GM_ADDR z,
                                uint32_t totalLength, uint32_t tileNum) {
        // ① 三条队列各申请一块片上内存（Unified Buffer），长度 = 一个 tile
        pipe.InitBuffer(inQueueX, BUFFER_NUM, tileLength * sizeof(float));
        pipe.InitBuffer(inQueueY, BUFFER_NUM, tileLength * sizeof(float));
        pipe.InitBuffer(outQueueZ, BUFFER_NUM, tileLength * sizeof(float));
        // ② 绑定全局内存（HBM 侧）—— 对标 CUDA kernel 的裸指针参数
        xGm.SetGlobalBuffer(x, totalLength * sizeof(float));
        yGm.SetGlobalBuffer(y, totalLength * sizeof(float));
        zGm.SetGlobalBuffer(z, totalLength * sizeof(float));
        // ③ 切分参数由 host 侧算好传入（tiling）—— 对标 CUDA 的 grid 计算逻辑
        this->tileNum = tileNum;
    }
    __aicore_inline__ void Process() {
        for (int32_t i = 0; i < tileNum; i++) {  // ← CUDA 的"线程网格"被压进这个循环
            CopyIn(i);    // GM → 片上 UB（DMA 搬运，不占计算单元）
            Compute(i);   // Vector 硬件指令计算
            CopyOut(i);   // UB → GM
        }
    }
private:
    __aicore_inline__ void CopyIn(int32_t i) {
        LocalTensor<float> xLocal = inQueueX.AllocTensor<float>();  // 从队列领片上内存
        DataCopy(xLocal, xGm[i * tileLength], tileLength);        // 对标异步 memcpy
        inQueueX.EnQue(xLocal);    // 入队 = 声明"这块数据搬运中"
    }
    __aicore_inline__ void Compute(int32_t i) {
        LocalTensor<float> xLocal = inQueueX.DeQue<float>();  // 出队 = 等待搬运完成
        LocalTensor<float> yLocal = inQueueY.DeQue<float>();
        LocalTensor<float> zLocal = outQueueZ.AllocTensor<float>();
        Add(zLocal, xLocal, yLocal, tileLength);  // ← 注意：这不是普通 C++ 函数，
                                                  //   是编译器识别的 NPU 向量指令
        outQueueZ.EnQue(zLocal);
        inQueueX.FreeTensor(xLocal);   // 片上内存极小（~256KB），必须手工归还
        inQueueY.FreeTensor(yLocal);
    }
    __aicore_inline__ void CopyOut(int32_t i) {
        LocalTensor<float> zLocal = outQueueZ.DeQue<float>();
        DataCopy(zGm[i * tileLength], zLocal, tileLength);
        outQueueZ.FreeTensor(zLocal);
    }
    TPipe pipe;                                       // 片上内存管理器（内存池）
    TQue<QuePosition::VECIN, BUFFER_NUM> inQueueX;    // 「队列」解耦搬运与计算
    TQue<QuePosition::VECIN, BUFFER_NUM> inQueueY;
    TQue<QuePosition::VECOUT, BUFFER_NUM> outQueueZ;
    GlobalTensor<float> xGm, yGm, zGm;                // HBM 侧张量
    static constexpr int32_t tileLength = 128;       // 一个 tile 128 个元素
    uint32_t tileNum = 0;
};

// NPU kernel 统一入口签名（workspace / tiling 由 host 侧框架层传入）
extern "C" __global__ __aicore__ void add_custom(GM_ADDR x, GM_ADDR y, GM_ADDR z,
                                                 GM_ADDR workspace, GM_ADDR tiling) {
    __gm__ uint32_t* tilingGm = (__gm__ uint32_t*)tiling;
    KernelAdd op;
    op.Init(x, y, z, tilingGm[0], tilingGm[1]);  // tilingGm[0]=totalLength [1]=tileNum
    op.Process();
}
// 读懂「队列 + 三段式」就读懂了 Ascend C 的灵魂：
// 它把 CUDA 中靠线程调度器隐式完成的「搬数与计算重叠」变成了显式编程模型
```

同一个算子（向量加）在两条技术栈上的概念逐项对照：

| 概念 | CUDA（英伟达） | Ascend C（昇腾） |
|------|--------------|----------------|
| 并行主体 | 海量 Thread（SIMT） | AI Core（核内分块 + 流水） |
| 片上内存 | shared memory | Unified Buffer（UB） |
| 全局内存 | global memory（HBM） | Global Memory（HBM） |
| 搬数方式 | `__shared__` 手写循环 / cp.async | TQue 队列 + DataCopy（DMA） |
| 计算指令 | intrinsics / PTX / Triton | Vector/Cube 硬件指令 |
| 矩阵乘 | mma 指令组（软件编排） | Cube 单元（一步到位） |
| 编译器 | nvcc | CANN 编译器 |
| Python 调用入口 | torch.ops / vLLM | torch_npu / MindSpore / aclnn |

**技能画像与学习路径**：

| 项目 | 内容 |
|------|------|
| 核心语言 | CUDA / Triton / Ascend C / C++ / Python |
| 知识内核 | GPU/NPU 架构（SM/AI Core/SRAM/HBM/寄存器）、roofline 模型（判读 compute-bound 还是 memory-bound）、并行归约、warp 调度、双缓冲流水 |
| 数学要求 | 数值优化、矩阵分块策略（线代必须极扎实） |
| 入门路径 | ①《CUDA Programming Guide》 → ② Triton 官方教程改写 fused kernel → ③ 读 FlashAttention 源码 → ④ 给 vLLM/SGLang 提 PR |
| 国产路径 | ① 昇腾社区《Ascend C 开发教程》+ 跑通 CANN samples 的 Add/Softmax → ② 精读达芬奇架构（Cube/Vector/UB/双缓冲） → ③ 改写融合算子（如 RMSNorm+量化） → ④ 给 CANN / vllm-ascend 提 PR |
| 岗位现实 | 全球极少数精英岗位，芯片公司（NVIDIA/昇腾/寒武纪）+ 头部推理引擎团队；国产芯片生态扩张期，昇腾算子岗需求逆势增长 |

**从零到能干活——算子开发分阶段路线图**（每阶段都有验收标准，过不了不进下一阶段）：

```text
阶段 0：前置自检（1-2 周，不达标先回炉，别硬闯）
  ① C++ 关：能解释 RAII / 右值引用 / std::move，写带智能指针的类不裸 new/delete
  ② 数学关：手推 softmax 的雅可比矩阵，说清反向为什么要先减 max（数值稳定）
  ③ PyTorch 关：说清 stride / view / reshape 三者区别（为什么 view 要求内存连续）
  ④ 工具关：会 gdb 单步，会用 nsys / nvprof 看时间线
  达标线：四关全过。任何一关卡住 → 先回炉，跳过这步后面全是空中楼阁

阶段 1：GPU 执行模型（2-4 周，Colab 免费 T4 即可）
  目标：理解"一个 Kernel 如何被调度到成千上万个线程上执行"
  材料：《Programming Massively Parallel Processors》(PMPP) 第 1-5 章——公认的 CUDA 圣经
  动手任务：
    ① 写 4 版向量加法：单线程 → 分块 → grid-stride loop → float4 向量化访存
    ② 每版用 cudaEvent 计时，画出"线程组织 → 数据下标"的映射图
    ③ 手算 T4 理论带宽（约 320 GB/s），对比实测带宽算出利用率 %
  验收标准：不看书写出 grid-stride 版；能指出利用率上不去的原因（访存没合并？）

阶段 2：优化三板斧（1-2 个月）
  目标：掌握 shared memory / 并行归约 / 向量化三大套路
  动手任务：
    ① 矩阵转置：naive 版 vs shared memory 版，用 nvprof 对比 bank conflict 数量
    ② 并行归约：照 Mark Harris《Optimizing Parallel Reduction in CUDA》
       逐版实现全部 7 个版本，每版计时画柱状图，能说出每版快在哪、瓶颈搬去了哪
    ③ 用 Triton 写一个 fused_add_relu，体会"比 CUDA 好写但控制力弱一档"
  验收标准：7 版归约的加速曲线能讲成一个小故事；能画图解释 bank conflict

阶段 3：精读工业级算子——FlashAttention-2（1-2 个月）
  材料：论文 Algorithm 1 + 仓库 csrc/flash_fwd_kernel.cu，带着五个问题读：
    ① 为什么按块（Br/Bc）切？块大小怎么和 SM 的 SRAM 容量对应？
    ② 在线 softmax 的 m/l 滚动更新公式，running max 起什么作用？
    ③ 减去 running max 为什么就不数值溢出了？
    ④ causal mask 怎么用"块级粗筛 + 元素级细筛"两步剪掉无用计算？
    ⑤ 反向为什么选择重算 QK^T 而不是存中间矩阵？省下的显存在哪？
  验收标准：合上论文能在白纸上写出 m/l 更新伪代码；
            能回答"为什么 FA 是 memory-bound 优化的教科书案例"

阶段 4：进入社区（长期）
  动手任务：vLLM / SGLang 挑 good first issue；昇腾路线给 vllm-ascend 提 PR
  验收标准：一个被 merge 的 PR（修文档错字 → 修小 bug → 性能优化，逐级升级）

没有 GPU / 没有昇腾卡怎么办：
  ① Colab T4 / Kaggle P100：阶段 1-2 的全部任务都够用
  ② 昇腾：MindStudio 云端 / 昇腾社区在线实验，免装环境跑通 CANN samples
  ③ 一张卡都没有：先纸面推——给每个 kernel 画"线程-数据映射图 + 双缓冲时序图"，
     有环境后再验证（上面那两段 CUDA / Ascend C Demo 就是为纸面推准备的）
```

### 11.3 框架开发：PyTorch 的技术内幕（框架层）

**干什么**：开发/维护 AI 框架本身（PyTorch / MindSpore / PaddlePaddle），以及把新芯片"接进"框架生态（如华为 torch_npu 把昇腾挂进 PyTorch）。模型开发者写 `y = model(x)` 时丝般顺滑，背后是这一层把 C++ 算子、自动求导、分布式通信、图编译全部缝合好——**AI 软件栈里的"操作系统"层**。

**PyTorch 从一行代码到硬件的四层结构**：

```text
你写的：y = torch.add(x, 1)
  ↓
④ Python API 层（torch / torch.nn）：你接触的部分，动态语言体验全在这
  ↓
③ ATen 算子库（C++）：add/matmul/conv2d 的真正实现
   注意：每个算子不是一份代码，而是 N 份实现注册成"多重人格"——
        CPU 版 / CUDA 版 / NPU 版 / 自动求导版 / 稀疏版 / 量化推理版 ...
  ↓
② Dispatcher 调度器：运行时根据「设备? dtype? 需要梯度?」查注册表，
   决定这次调用落到哪份实现 —— PyTorch 的心脏
  ↓
① c10 核心库：Tensor 存储 / Device 抽象 / 引用计数
  ↓
硬件算子：CPU(OpenMP) / GPU(cuBLAS+cuDNN+自定义CUDA) / NPU(CANN)
```

**核心技术一：Dispatcher —— "一套 API 跑遍所有芯片"的秘密**

```python
# Demo：亲眼看一次算子分发（可运行，纯 CPU 即可）
import torch

print(torch._C._dispatch_dump("aten::add"))
# 输出一张按优先级排列的 dispatch key 表：
#   AutogradCUDA → AutogradCPU → ... → CUDA → CPU → CompositeImplicit...
# 含义：x 在 GPU 就命中 CUDA kernel，在 CPU 就命中 CPU kernel，
#       需要 backward 就先经过 Autograd 键"录音"计算图
# 关键洞察：新芯片厂商不改 PyTorch 一行代码，只需"往表里注册自己的算子"
```

**核心技术二：自定义算子注册（torch.library）—— 框架扩展的标准姿势**

vLLM 把 PagedAttention kernel 挂进 PyTorch、torch_npu 把昇腾算子挂进 PyTorch、FlashAttention 变成 `torch.ops.flash_attn`——全部走这一个入口：

```python
# Demo：注册一个 PyTorch 里没有的自定义算子（可运行，纯 CPU）
import torch

# ① 定义 CPU 实现（真实场景这里挂的是 C++/CUDA/Ascend C kernel）
def square_add_cpu(x: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
    return x * x + y

# ② 建命名空间 + 声明 schema（类型签名，dispatcher 靠它做检查）
my_lib = torch.library.Library("myops", "DEF")
my_lib.define("square_add(Tensor x, Tensor y) -> Tensor")

# ③ 把实现挂到某个分发键上（这里是 CPU 键）
my_lib.impl("square_add", square_add_cpu, "CPU")

# ④ 现在它享受原生算子待遇：走 dispatcher、可序列化、torch.compile 可追踪
x = torch.tensor([1.0, 2.0, 3.0])
y = torch.tensor([10.0, 20.0, 30.0])
print(torch.ops.myops.square_add(x, y))   # tensor([11., 24., 39.])

# 框架工程师的日常就是这一套的三种变体：
#   torch_npu：impl 的 "CPU" 换成 "NPU"，实现换成 CANN 算子 → 昇腾跑 PyTorch 代码
#   vLLM：    实现换成 Triton/CUDA 写的 PagedAttention kernel
#   用户：    训练代码一行不改 —— 这就是框架层的核心价值：解耦
```

**核心技术三：autograd 自动微分 —— 框架的灵魂**

```text
模型开发者"只写 forward，不写 backward"，谁在替他求导？
  ① 每个 ATen 算子都附带一条"求导规则"，注册在 dispatcher 的 Autograd 键下：
       z = x + y   →  dz/dx = 1,       dz/dy = 1
       z = x @ y   →  dz/dx = dz @ yᵀ, dz/dy = xᵀ @ dz
  ② 前向执行时，autograd 引擎把"参与运算的张量 + 算子"录成一张动态计算图
  ③ loss.backward() 触发：按拓扑序反向遍历，逐算子查表套链式法则
  数千条求导规则 + 运行时录音 + 反向回放 = 反向传播的全自动化
  ← 这正是第 3 章手推 Attention 的意义：框架替你做的每一步，你都亲手验证过
```

**核心技术四：分布式训练的框架侧实现（DDP / FSDP）**

```text
DDP（数据并行的教科书实现，面试必背）：
  ① 每卡持完整模型副本，各吃不同 mini-batch
  ② 反向传播时，梯度经 AllReduce 跨卡求平均（ring 算法，带宽最优）
  ③ 妙笔"梯度分桶"：反向算完一桶参数立刻异步发通信 → 通信与计算重叠
  → 框架工程师的活：把这套逻辑 hook 进 autograd 的每个反向节点

FSDP（单卡放不下整个模型时的完全分片方案）：
  参数 / 梯度 / 优化器状态全部切片（shard）分布到所有卡上
  前向走到某层：AllGather 现场拼出该层完整权重 → 用完立刻释放
  → 本质是"用通信换显存"：8×A100 放不下的 70B，现在能训了
  ← 11.4 模型开发里的 ZeRO/FSDP 概念，在框架层就是这样落地的
```

**核心技术五：torch.compile / Inductor —— PyTorch 2.0 的编译革命**

```text
动态图（eager 模式）好写但慢：每次算子都过一遍 Python + Dispatcher，无法全局优化
torch.compile(model) 一行开启三段流水：
  ① TorchDynamo：抓取 Python 字节码 → 转成 FX 计算图
  ② AOTAutograd：把自动微分图提前展开成显式的前向图 + 反向图
  ③ Inductor：把图翻译成 Triton（GPU）/ C++（CPU）代码再 JIT 编译
效果：训练提速 30-80%，模型开发者零改动
趋势：算子内部是 HPC（11.2），算子之间的"胶水"正从 Python 走向编译器
```

**国产框架与芯片适配（框架层的"中国战场"）**

```text
路线一：寄居 PyTorch 生态 —— 芯片公司的主流打法
  torch_npu（华为昇腾）/ torch_mlu（寒武纪）/ torch_musa（摩尔线程）
  原理：Dispatcher 开放注册 → 自家算子注册为 aten 后端 →
        复用 PyTorch 百万级存量代码，用户迁移成本 ≈ 0
路线二：自研框架
  MindSpore（华为）：主打自动并行 + 静态图，昇腾"亲儿子"
  PaddlePaddle（百度）：产业落地最多、中文文档最全
岗位现实：国产芯片公司的"框架适配岗"长期缺人（C++ 功底 > AI 理论），
         是 DevOps / 后端背景切入 AI 基础软件最平滑的入口
```

**技能画像与学习路径**：

| 项目 | 内容 |
|------|------|
| 核心语言 | C++（主力）/ Python（API 层与测试） |
| 知识内核 | C++ 工程（模板/RAII/智能指针）、编译原理基础、PyTorch 源码结构（ATen/Dispatcher/autograd/Tensor 内存模型）、通信原语（NCCL/HCCL） |
| 入门路径 | ① PyTorch 官方教程 "Custom C++ and CUDA Operators" → ② 用 torch.library 复刻融合算子（如 fused RMSNorm） → ③ 读 torch.compile/Inductor 源码 → ④ 读 torch_npu / MindSpore 源码 → ⑤ 给 PyTorch / vllm-ascend 提 PR |
| 岗位现实 | 岗位少于应用层、多于算子层；集中在芯片公司与框架团队；国产化浪潮下需求稳定，C++ 系统工程功底可从后端/嵌入式平滑迁移 |

**从零到能干活——框架开发分阶段路线图**（以 PyTorch 解剖为主线，阶段 0-3 一台 CPU 笔记本就够）：

```text
阶段 0：C++ 系统工程自检（1-2 周）
  目标：PyTorch 本体是 C++ 工程，进门先验底子
  自检四关：
    ① 徒手写一个 CMake 管理、含 pybind11 导出的最小项目（Python 侧能 import）
    ② 模板 / RAII / 移动语义过关（能解释 unique_ptr 为什么不能拷贝）
    ③ 懂动态库：-fPIC、符号可见性、运行时查找路径（rpath）
    ④ 会用 gdb 调 C++ 侧代码（而不是只会调 Python 侧）
  达标线：四关全过；差什么补什么（《C++ Primer》+ CMake 官方 tutorial）

阶段 1：打通 Python → C++ 调用链（2 周）
  材料：PyTorch 官方教程 "Custom C++ and CUDA Operators"
  动手任务：
    ① 用 torch.utils.cpp_extension.load_inline 写 C++ 版 my_add，Python 侧调通
    ② torch._C._dispatch_dump("aten::add") 观察注册表，对照上面四层结构图
    ③ 亲手敲一遍 torch.library Demo：define → impl("CPU") → torch.ops.myops.square_add
  验收标准：白纸上画出 torch.add 从 Python 到 ATen kernel 的完整调用链并讲清

阶段 2：复刻框架两大机制——算子注册 + 自动求导（1-2 个月）
  动手任务：
    ① 跟 karpathy/micrograd 手写 100 行自动求导引擎（Value 类 + backward 逆拓扑排序）
    ② 用 torch.library 注册自定义算子并写自定义反向（自己推导求导公式）
    ③ torch.autograd.gradcheck 数值检验你的反向公式——必须全绿
  验收标准：gradcheck 全绿；能解释动态图的反向如何沿 autograd graph 逆拓扑序传播

阶段 3：深潜二选一（2-3 个月）
  路线 A：分布式——gloo 后端单机 4 进程 DDP（不需要多卡），
          故意去掉 AllReduce 观察 loss 发散，理解梯度同步的必要性；
          再看 FSDP 参数分片后显存曲线的变化
  路线 B：图编译——设 TORCH_LOGS=output_code，
          追一个函数经 torch.compile 后 Inductor 生成的 Triton kernel，
          数一数比 eager 少了几次 kernel launch
  验收标准：A 线画出 DDP 梯度分桶 + AllReduce 的时序图；
            B 线指出 Inductor 做了哪些算子融合

阶段 4：接上国产栈 + 社区（长期）
  动手任务：clone torch_npu，找算子注册宏，
            追"同一个 aten 算子如何路由到 NPU 实现"
            （对照上面 Dispatcher 讲解 + 寄居式 vs 自研两条路线）
  验收标准：能回答"华为为什么做 torch_npu 插件而不是 fork PyTorch"；
            给 MindSpore / vllm-ascend / CANN 提一个 PR

环境说明：阶段 0-3 全程 CPU 即可（load_inline / gloo / gradcheck 都不要 GPU）；
         只有查看 Inductor 生成的 GPU 代码时才需要 Colab T4
```

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
                        （技术上是 4.3 章讲过的微调，但只调对话格式）
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
  Dispatcher、torch_npu、MindSpore）——
  足够你在选型时看懂 vLLM 配置参数、评估国产芯片适配方案、
  和推理团队对话；深入只在转 HPC 或进芯片公司时再学
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

---

## 12. 全书总览：三张表带走全部结论

### 表 1：各阶段技术现状（"还在用吗"终极回答）

| 技术 | 当前状态 | 演进去向 |
|------|---------|---------|
| 传统 ML（XGBoost 等） | ✅ 活跃，表格数据首选 | 与深度学习长期共存 |
| Transformer 微调（BERT 系） | ✅ 产业界常驻 | 成本敏感场景独占；微调进化为 LoRA |
| LLM + 多模态 | ✅ 主流标配 | 原生多模态统一架构 |
| RAG | ✅ 企业落地第一刚需 | → Agentic RAG / GraphRAG |
| Function Calling | ✅ 使用中 | 底层被 MCP 覆盖，概念仍通用 |
| MCP | ✅ 行业标准，生态爆发期 | 与 A2A 互补 |
| Skill | ✅ 主流机制，广泛使用 | 团队知识资产的载体 |
| Harness | ✅ 当前竞争主战场 | 从编码走向通用 |
| Claude Code 类产品 | ✅ 高速增长 | 引领 Agent 产品范式 |

### 表 2：各阶段"怎么用"的直观对比

| 阶段 | 交互方式 | 一句话 |
|------|---------|--------|
| 传统 ML | `model.fit(X, y)` | 人定特征，机器学参数 |
| Transformer 微调 | 标注数据 + `Trainer.train()` | 人定任务，机器学任务 |
| LLM/ICL | 写 Prompt | 人描述任务，机器直接做 |
| RAG | 建知识库 + 提问 | 人备资料，机器查着答 |
| Function Calling | 定义工具 schema | 人定义工具，机器选用 |
| MCP | 写一个 Server | 人写一次工具，所有 Agent 通用 |
| Skill | 写 SKILL.md | 人沉淀方法，机器照流程做 |
| Harness/Claude Code | 一句话目标 | 人只说目标，机器全流程闭环 |

### 表 3：每个阶段解决上一代的什么问题

| 阶段切换 | 解决的上一代痛点 |
|---------|----------------|
| ML → 深度学习 | 手工特征太贵、天花板低 |
| RNN → Transformer | 长程依赖丢失、无法并行 |
| 微调 → LLM/ICL | 一任务一模型的维护噩梦 |
| 裸 LLM → RAG | 幻觉、知识过期、私有数据不可用 |
| RAG → Agent | 只会"查着说"不会"动手做" |
| Agent → MCP/Skill | 工具接入 N×M 重复劳动、经验无法沉淀 |
| 裸 Agent → Harness | 循环失控、无护栏、上下文失忆 |
| Harness → Claude Code | 通用能力在"编码"这一反馈最明确的场景集中引爆 |

---

## 结语

回头看，整个 70 年的演进只有一个母题：**不断把"人的手工"换成"机器的自动"**——

- 特征：手工设计 → 机器自学（深度学习）
- 任务适配：手工微调 → 提示词（LLM）
- 知识：手工重训 → 外挂数据库（RAG）
- 行动：手工编排 → 自主循环（Agent）
- 集成：手工胶水 → 标准协议（MCP/Skill）
- 保障：手工盯梢 → 工程护栏（Harness）

而 Claude Code 的火爆证明了一件事：当模型、协议、生态、工程同时成熟，70 年的技术积累会在一个场景里瞬间合流。理解了这份演进史，也就理解了如何判断下一个"瞬爆点"会在哪里出现。




