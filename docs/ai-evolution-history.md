# AI 技术演进史：从机器学习到 Claude Code

本系列按时间线完整梳理 AI 技术的六个大阶段：传统机器学习 → Transformer → LLM 多模态 → RAG → Agent（MCP / Skill / Harness）→ Claude Code。每个阶段都按同一套结构讲解：**背景故事 → 原理拆解 → 完整 Demo → 使用场景与现状 → 与上一阶段的区别 → 局限性（引出下一代技术）**。

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

## 系列目录

全文共 7 个部分，建议按序阅读；每个部分开头的导航条可随时跳转：

| 部分 | 内容 | 文件 |
| --- | --- | --- |
| 第 1-3 章 | 传统机器学习 → 神经网络时代 → Transformer 革命 | [ai-evolution-01-ml-to-transformer.md](ai-evolution-01-ml-to-transformer.md) |
| 第 4 章 | LLM 与多模态时代（GPT-3 / ChatGPT / HF 与多模态辨析） | [ai-evolution-02-llm-multimodal.md](ai-evolution-02-llm-multimodal.md) |
| 第 5-6 章 | RAG 外挂知识库 / Agent 时代（Function Calling / ReAct） | [ai-evolution-03-rag-agent.md](ai-evolution-03-rag-agent.md) |
| 第 7-10 章 | MCP 与 Skill / Agent Harness / Claude Code / 前沿方向 | [ai-evolution-04-mcp-harness-claude-code.md](ai-evolution-04-mcp-harness-claude-code.md) |
| 第 11 章 · 上 | 四条开发路线：技术栈全景 + 算子开发 + 框架开发 | [ai-evolution-05-paths-system-layer.md](ai-evolution-05-paths-system-layer.md) |
| 第 11 章 · 下 | 四条开发路线：模型开发 + Agent 开发 + 对比与选择建议 | [ai-evolution-06-paths-model-app.md](ai-evolution-06-paths-model-app.md) |
| 第 12 章 + 结语 | 全书总览：三张表带走全部结论 | [ai-evolution-07-summary.md](ai-evolution-07-summary.md) |
