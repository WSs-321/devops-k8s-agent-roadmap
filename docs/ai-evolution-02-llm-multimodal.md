# AI 技术演进史（2/7）：LLM 与多模态时代

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 上一部分：[从机器学习到 Transformer](ai-evolution-01-ml-to-transformer.md) ｜ 下一部分：[RAG 与 Agent 时代](ai-evolution-03-rag-agent.md)

---

## 4. LLM 与多模态时代（2020 - 2023）

### 4.1 先把三个高频名词摆正：大语言模型 / 多模态 / HuggingFace

初学者最容易被这三个词绕晕，因为它们根本不在同一层——一个是模型，一类是"模型加上感官"，一个既不是模型也不是算法，而是平台：

```text
大语言模型（LLM，Large Language Model）
  纯文本进、纯文本出的巨型 Transformer（GPT-3 / Qwen / DeepSeek / Llama）
  本质：超大规模的"下一个 token 预测器" —— 相当于"大脑"

多模态模型（Multimodal）
  不是取代 LLM，而是给 LLM "挂上感官"，记忆口诀：
  多模态 = LLM（大脑） + 编码器（眼睛 / 耳朵）
  理解系（CLIP / GPT-4V / Qwen-VL）：ViT 把图像切块 → 视觉 token
         拼进文本序列 → 复用同一个 Transformer 大脑（见 4.5 节路线 B）
  生成系（Stable Diffusion / Sora）：扩散模型栈，与 LLM 是两套技术

HuggingFace（HF）
  不是模型、不是算法！它是"模型界的 GitHub + Maven Central"
  三重身份：① 模型托管平台（150 万+ 模型的发布渠道）
           ② 统一 API 库（transformers：一行代码换模型）
           ③ 事实格式标准（config.json + tokenizer.json + safetensors）
```

三者关系一张图：

```text
      ┌──────────── HuggingFace（仓库与标准层）────────────┐
      │  Llama / Qwen / DeepSeek 的权重都发布在这里，      │
      │  下载只需 from_pretrained("模型名")               │
      └───────────────┬────────────────────┬─────────────┘
                      ↓                    ↓
         ┌───────────────────┐  ┌─────────────────────┐
         │ LLM（纯文本）      │  │ 多模态 = ViT + LLM  │
         │ GPT/Qwen/DeepSeek │  │ GPT-4V / Qwen-VL    │
         └───────────────────┘  └─────────────────────┘
                      ↓                    ↓
         你的应用（第 5-9 章：RAG / Agent / Claude Code 实战）
```

**为什么全世界都拿 HF 当标准？** 不是因为 HF 技术最强，而是网络效应三部曲：

```text
① 统一 API：换模型的成本约等于零
   AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-7B-Instruct")
   换 DeepSeek？只改引号里的字符串 —— 像换数据库只改 JDBC URL

② 发布渠道的事实垄断
   Llama / Qwen / DeepSeek-R1 官方权重的"第一落点"都是 HF；
   国内魔搭 ModelScope 也直接兼容 HF 格式 —— 跟随者反向确认了标准

③ 格式成为事实标准
   "HF 格式"目录（config.json + tokenizer.json + *.safetensors）
   被 vLLM / llama.cpp / TGI / PEFT / trl 等全生态工具直接消费
   —— 类比 Docker 镜像格式：模型只要导出成它，全生态立刻可用

飞轮闭环：模型发到 HF → 工具链围绕 HF 格式构建 → 新模型为了
触达工具链必须发 HF 格式 → 标准自我强化，后来者无法翻盘
```

**Java/DevOps 翻译**：HF 之于模型 = Maven Central 之于 jar 包 = Docker Hub 之于镜像 = GitHub 之于源码。你不需要专门"学 HuggingFace"，把它当 maven 仓库用即可：`pip install transformers`，`from_pretrained("模型名")`，剩下的交给生态。本教程后面的 Demo 反复出现的 `from_pretrained`，现在你知道它为什么"一行就能换模型"了。

### 4.2 GPT-3 与"涌现"：参数量从"量变"到"质变"

GPT-2 只有 15 亿参数，还只是个"高级补全器"。GPT-3 干到 1750 亿，训练数据从 40GB 变成 570GB。学界发现一件诡异的事：

```text
参数规模        简单任务(分类)   复杂任务(推理/代码)
1B  (10亿)      缓慢提升        几乎为零 —— 纯属乱猜
10B (100亿)     缓慢提升        接近零
100B(1000亿)    稳定提升        突然跳升 ← "涌现"（Emergent Ability）
```

**涌现**：某些能力（多位数加减法、代码生成、思维链推理）在小模型上完全不存在，规模跨过某个阈值后突然出现。这是"大力出奇迹"的理论依据，也是各家疯狂堆参数的原因。

### 4.3 In-context Learning：提示词代替微调

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

### 4.4 ChatGPT 时刻：RLHF 让模型"听话"（2022.11）

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

### 4.5 多模态：从 CLIP 到 GPT-4V/Sora

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

### 4.6 Demo：提示工程实战（可运行）

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

### 4.7 局限性：LLM 的三大原罪

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
