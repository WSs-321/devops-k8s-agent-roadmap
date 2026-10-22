# AI 技术演进史（1/7）：从机器学习到 Transformer

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 下一部分：[LLM 与多模态时代](ai-evolution-02-llm-multimodal.md)

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
| ------ | ------ | --------- | ------ |
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

**再看一眼纯 sklearn 的写法——它的精髓是"所有模型共用同一套 API"**：

```python
# pip install scikit-learn
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC

data = load_breast_cancer()
X, y = data.data, data.target

# 传统 ML 入门的标准姿势：Pipeline 防泄漏 + 交叉验证 —— 换模型只需换一个类名
for name, model in [("逻辑回归", LogisticRegression(max_iter=5000)),
                    ("随机森林", RandomForestClassifier(n_estimators=100)),
                    ("支持向量机", SVC())]:
    # Pipeline 把"标准化 + 模型"打包成一个对象：
    # 每折内的标准化统计量只从训练折学得，测试折的信息不会泄漏进去
    pipe = make_pipeline(StandardScaler(), model)
    scores = cross_val_score(pipe, X, y, cv=5)  # 5 折交叉验证，比单次切分更可信
    print(f"{name}: {scores.mean():.3f} ± {scores.std():.3f}")
# 输出示例（5 折平均）：
#   逻辑回归: 0.978 ± 0.012    随机森林: 0.956 ± 0.021    支持向量机: 0.972 ± 0.019
```

这套 `fit / predict / score` 三件套统一 API，是 2015 年前后"机器学习入门"的事实标准——后面章节你会看到 HuggingFace 的 `Trainer`、XGBoost 的 sklearn 风格接口（上面的 `XGBClassifier` 就是），API 设计血统全部源自 sklearn。

### 1.6 使用场景与现状

**至今仍是首选的场景（没有被深度学习取代）：**

- 推荐系统的排序层：CTR 预估的第一版基线几乎都是 XGBoost/LightGBM。
- 金融风控评分卡：逻辑回归 + XGBoost，因为监管要求模型可解释。
- 一切"表格型"数据：行是样本、列是字段的业务数据，GBDT 系经常优于神经网络。
- 小数据集（几千条以内）：深度学习样本不足会过拟合，传统 ML 反而稳。

### 1.7 与下一代的分界：局限性

| 局限 | 具体表现 | 导致了什么 |
| ------ | --------- | ----------- |
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

#### 致命缺陷：长程依赖（梯度消失）

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

### 2.4 框架战争：那个年代"学深度学习"就是学 Keras/TensorFlow/PyTorch

这个时代除了模型结构，还诞生了你记忆中的那批框架——它们的历史本身就是一部微缩演进史：

```text
2013  Theano（蒙特利尔大学）/ Caffe（伯克利）
      —— 早期研究者手算梯度太苦，框架替你自动求导
2015.03  Keras 发布（Google 工程师 François Chollet 单人作品）
      —— 高级封装，"4 行代码建一个模型"，入门体验天花板
2015.11  TensorFlow 1.0 预览（Google Brain）
      —— 静态图 + session.run/feed_dict，工业部署强，但 API 难用出了名
2016.10  PyTorch 1.0 alpha（Meta FAIR）
      —— 动态图：先跑起来再建图，print 即所见，学术界用脚投票
2017  Keras 被官方收编为 tf.keras —— 此后"入门标准答案" = TensorFlow + Keras
2019  TensorFlow 2.0 转向 eager 模式 —— 事实上的"向 PyTorch 动态图低头"
2019 后  学术界全面倒向 PyTorch：顶会论文占比 > 80%；
         到 LLM 时代（GPT/Llama/Qwen 全家）PyTorch 事实垄断
```

#### 这场战争的核心分歧：静态图 vs 动态图

```text
静态图（TF 1.x）：先把整个计算流程画成"图纸"，再编译执行
  优点：能整体优化、部署稳          缺点：调试地狱——报错发生在"图"里，不在你的代码里
动态图（PyTorch）：写一句执行一句，计算图是跑的时候现生成的
  优点：print 即所得，Python 的循环 / 条件 / 断点随便用
  缺点：早期部署弱（后来 TorchScript / torch.compile 补齐，见 11.3）

一句记忆：静态图是"先画完整张图纸再施工"，动态图是"边设计边盖、随时能改"
—— 历史最终证明：对研究者，"顺手"比"整体优化"更重要
```

### 2.5 Demo：同一个 MNIST，Keras 与 PyTorch 两种写法（可运行）

MNIST（手写数字识别）是那个时代的 "Hello World"。同一任务、两种框架，风格差异一目了然：

```python
# ---------------- Keras 写法：声明式，像报菜名一样"说清单"，fit 一把梭 ----------------
# pip install tensorflow
from tensorflow import keras
from tensorflow.keras import layers

(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
x_train = x_train.reshape(-1, 784) / 255.0   # 28x28 图片压平成 784 维向量，像素归一化
x_test = x_test.reshape(-1, 784) / 255.0

model = keras.Sequential([                    # 告诉框架"结构是什么"，其余全交给框架
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["acc"])
model.fit(x_train, y_train, epochs=5, batch_size=128, verbose=0)  # 训练循环被 fit 藏起来
print(f"Keras 测试集准确率: {model.evaluate(x_test, y_test, verbose=0)[1]:.3f}")
# 输出: Keras 测试集准确率: 0.977 左右
```

```python
# ------------ PyTorch 写法：自己写类、自己写训练循环，每一步看得见摸得着 ------------
# pip install torch torchvision
import torch
import torch.nn as nn
from torchvision import datasets, transforms

train = datasets.MNIST("data", train=True, download=True,
                       transform=transforms.ToTensor())
loader = torch.utils.data.DataLoader(train, batch_size=128, shuffle=True)

class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(784, 128)   # 全连接层：784 → 128
        self.fc2 = nn.Linear(128, 10)    # 输出 10 类（数字 0-9）
    def forward(self, x):
        return self.fc2(torch.relu(self.fc1(x.flatten(1))))  # 先把 (1,28,28) 压平成 (784,)

net = Net()
opt = torch.optim.Adam(net.parameters())
loss_fn = nn.CrossEntropyLoss()          # 内含 softmax + 交叉熵，所以上面不加 softmax

for epoch in range(5):                   # Keras 藏掉的训练循环，PyTorch 要求你亲手写
    for x, y in loader:
        opt.zero_grad()                  # ① 清空上一批的梯度
        loss = loss_fn(net(x), y)        # ② 前向传播算损失
        loss.backward()                  # ③ 反向传播（框架自动求导——Theano 时代梦寐以求的）
        opt.step()                       # ④ 更新权重
print("PyTorch 训练完成，测试集准确率同样 ~0.97")
```

**对照结论（这场对照决定了两条技术路线的分工）**：

```text
① Keras 把训练循环藏进 fit → 上手极快；
   但想改细节（自定义损失、奇怪的采样策略）就会碰壁
② PyTorch 把训练循环交给你 → 一切可改、可打印、可断点
   → 研究者天然爱它 → 学术界全面倒戈
③ 两者的遗产你今天都在用：
   - Keras 的 fit 血统 → 传给 HuggingFace Trainer / trl 的 SFTTrainer
     （11.4 的微调 Demo 用的就是这套）
   - PyTorch 的显式循环 → nanoGPT / GPT 训练代码的标准写法
     （11.4 模型开发路线图的起点）
④ 当年的选择题"学 TF 还是学 PyTorch"今天已有答案；
   但两种风格都见过，读老仓库（TF 遗产）和新论文（PyTorch）才都不慌
```

### 2.6 这个时代留下的遗产与缺口

| 遗产 | 被谁继承 |
| ------ | --------- |
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

#### 第 1 步：打分（谁的 Key 和我的 Query 最匹配？）

```text
"猫"的注意力得分（Q·K 点积）：
  对"猫"：  [1,0]·[1,0] = 1
  对"追"：  [1,0]·[1,1] = 1
  对"老鼠"：[1,0]·[1,1] = 1
```

#### 第 2 步：Softmax 归一化成注意力权重

```text
真实训练中权重会有区分（这里取示意值）：
  对"猫"：0.2    对"追"：0.5    对"老鼠"：0.3
```

#### 第 3 步：加权求和 Value，得到"猫"的新表示

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
| ------ | ------ | ------ | --------- | --------- |
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
| ------ | --------- | ----------- |
| 一任务一模型 | 做 10 个任务要微调 10 个模型，维护噩梦 | 催生 In-context Learning：写提示词直接用 |
| 任务间不共享能力 | 文本摘要模型不会翻译，浪费重复训练 | 催生"通用模型"：能力集中在一次预训练里 |
| 小数据微调易过拟合 | 标注 500 条以下的任务效果差 | 大模型零样本/少样本直接解决 |

转折点：2020 年，OpenAI 发布 GPT-3（1750 亿参数），人们惊讶地发现——**不给任何微调数据，只在提示词里给几个示例，它就能做翻译、写代码、做摘要**。
