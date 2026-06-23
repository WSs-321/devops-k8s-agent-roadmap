# Daily Log

Date: 20260623
Day: Tuesday

## 今日目标

- 学习 GHCR 登录：`GITHUB_TOKEN` 权限、PAT 区别、登录方式、常见报错
- 输出 `docs/ghcr-login.md` 作为 Week 4 起点
- 提交并开 PR

## 实际完成

- 理解 GHCR 定位：GitHub 官方容器仓库，地址 `ghcr.io`，与 GitHub Packages 同源
- 理解 `GITHUB_TOKEN` 特性：临时、自动注入、受 `permissions:` 控制、日志自动 mask
- 对比 PAT：fine-grained vs classic，scope 显式优先
- 掌握三种登录方式：Actions（docker/login-action）、本地（gh / docker login）、跨平台 CI
- 学会镜像可见性切换：默认 private，public 需手动在 Packages 设置或调 API
- 整理典型报错表：`unauthorized` / `denied` / `Name unknown` / `toomanyrequests`
- 写出最小可用 push workflow（登录 + 构建 + 推送）
- 输出 `docs/ghcr-login.md`，含权限、报错、安全 checklist、自测清单

## 遇到的问题

- 一开始把 "继续学习 k8s 入门" 误判为 Week 7 主题，跳过了 Week 4
  - 用户提醒后纠正：Week 4 是 GHCR，K8s 基础在 Week 7
- 本机未装 docker / gh auth，本节只能做概念 + YAML 笔记，没法实操 push
- `gh` 路径 tail 命令在 PowerShell 不可用的小报错（已忽略）

## 解决方式

- 严守 [75-day-plan.md](file:///d:/project/devops-k8s-agent-roadmap/timetable/75-day-plan.md) 的 Week 主题划分，不再凭直觉猜
- 概念阶段允许只读不跑；Day 23 写 build-push-action workflow 时会真跑一次
- 本地非 GNU 工具链的小报错一律忽略或换写法

## 明日计划

- Day 23：build-push-action。在 workflow 中自动构建并推送镜像到 GHCR
- 配套文档 `docs/build-push-action.md`，把 tag 策略、缓存、metadata 衔接起来

## Commit

- 待提交：新增 Day 22 日志 + `docs/ghcr-login.md`
