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

## 11. 全书总览：三张表带走全部结论

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




