# AI 技术演进史（5/7）：四条开发路线 · 算子与框架

> 系列导航：[返回目录](ai-evolution-history.md) ｜ 上一部分：[MCP、Harness 与 Claude Code](ai-evolution-04-mcp-harness-claude-code.md) ｜ 下一部分：[四条开发路线 · 模型与应用](ai-evolution-06-paths-model-app.md)

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

#### Demo：Triton 写一个最简单的 GPU 算子（可运行）

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

#### 国产平行世界：昇腾 Ascend C 算子开发（同一个问题，另一套硬件）

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

#### Demo：Ascend C 版向量加法（需昇腾卡 + CANN 工具链，看结构与 CUDA 的对照为主）

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

#### 核心技术一：Dispatcher —— "一套 API 跑遍所有芯片"的秘密

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

#### 核心技术二：自定义算子注册（torch.library）—— 框架扩展的标准姿势

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

#### 核心技术三：autograd 自动微分 —— 框架的灵魂

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

#### 核心技术四：分布式训练的框架侧实现（DDP / FSDP）

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

#### 核心技术五：torch.compile / Inductor —— PyTorch 2.0 的编译革命

```text
动态图（eager 模式）好写但慢：每次算子都过一遍 Python + Dispatcher，无法全局优化
torch.compile(model) 一行开启三段流水：
  ① TorchDynamo：抓取 Python 字节码 → 转成 FX 计算图
  ② AOTAutograd：把自动微分图提前展开成显式的前向图 + 反向图
  ③ Inductor：把图翻译成 Triton（GPU）/ C++（CPU）代码再 JIT 编译
效果：训练提速 30-80%，模型开发者零改动
趋势：算子内部是 HPC（11.2），算子之间的"胶水"正从 Python 走向编译器
```

#### 国产框架与芯片适配（框架层的"中国战场"）

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

**从 Megatron-LM 到 MindSpeed：昇腾为什么要给每个大模型"专门适配"？**

torch_npu 解决的只是"单卡能跑"（算子路由）；而千亿参数模型的训练是**集群问题**——单卡根本放不下，必须多卡多机协同：

```text
千亿模型怎么拆到集群？五维并行（彼此正交、可叠加）：
张量并行 TP   ：一层权重矩阵切成 N 份，N 张卡各算一块再拼结果
流水并行 PP   ：第 1-8 层放 A 机、9-16 层放 B 机，像流水线传半成品
上下文并行 CP ：超长序列切成几段，Attention 分段并行算
专家并行 EP   ：MoE 模型的几十个专家分布到不同机器
数据并行 DP   ：各机吃不同 batch、同步梯度；叠加 ZeRO 把
               优化器状态 / 梯度 / 参数也切片省显存
千卡训练 = 五种并行同时开 —— 这是一套与硬件无关的数学
```

这套方法学的标准实现是 **Megatron-LM**（NVIDIA 出品，TP/PP 并行论文的出处）——Qwen、DeepSeek、LLaMA 的训练代码都基于它改（DeepSeek 的 HAI-LLM 框架就是基于 Megatron 打造）。问题在于：Megatron 的融合算子、集合通信（NCCL）、注意力加速（FlashAttention）全部深度绑定 CUDA，照搬代码在昇腾上跑不起来。

于是昇腾侧出现了一对仓库：**MindSpeed-LLM**（文本模型训练）/ **MindSpeed-MM**（多模态模型训练），思路与 torch_npu 一脉相承——寄居生态、只换底层：

```text
层次         GPU 生态                    昇腾生态
─────────  ─────────────────────   ──────────────────────────────
训练方法学   Megatron-LM                MindSpeed-LLM / MindSpeed-MM
            （TP/PP/模型定义）         （保留 Megatron 并行方法学与
                                        gpt/llama/qwen/deepseek 模型定义）
推理引擎     vLLM                       vllm-ascend
框架层      PyTorch                    torch_npu（算子路由）
运行时      CUDA + NCCL                 CANN + HCCL
融合加速     FlashAttention              昇腾亲和版 FA：Cube/Vector 双引擎
                                         内存优化 + 计算/通信重叠
硬件        H100 / GB200               Atlas 800T A2（昇腾 910B）
```

**为什么是"适配"而不是重造？** 因为并行方法学是与硬件无关的数学，而 Megatron 是被论文和生产（Qwen/DeepSeek 全家桶）反复验证过的参考实现——新模型发布几天内，照着官方代码"搬运 + 换底层"就能跟上生态。这是"寄居生态"策略从推理侧（vllm-ascend）到训练侧的延续。

**实际适配工作就四件事**（这类岗位的日常）：

```text
① 模型搬运：把新模型结构（如 DeepSeek-V3 的 MLA 注意力）的定义代码
           移植进 MindSpeed 的模型目录
② 算子补齐：新结构需要而昇腾侧还没有的算子 → 基于 CANN 补实现
③ 精度对齐：GPU 与 NPU 浮点路径不同 → 逐层比对 loss 曲线定位偏差
④ 性能调优：融合算子重写、计算/通信重叠、内存复用 → 提升 MFU
           （MFU = 模型算力利用率，训练效率的核心指标）
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
