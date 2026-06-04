# Publish To GitHub

当前仓库已经在本地初始化并完成提交。路径：

```text
D:\tmp\devops-k8s-agent-roadmap
```

## 方式一：使用 GitHub 网页创建远程仓库

1. 打开 GitHub。
2. 创建一个新仓库，建议名称：

```text
devops-k8s-agent-roadmap
```

3. 建议先选择 Private。
4. 不要勾选自动生成 README、`.gitignore` 或 license，因为本地仓库已经有这些内容。
5. 创建后复制仓库地址。

如果使用 HTTPS 地址：

```powershell
cd D:\tmp\devops-k8s-agent-roadmap
git remote add origin https://github.com/<your-name>/devops-k8s-agent-roadmap.git
git push -u origin main
```

如果使用 SSH 地址：

```powershell
cd D:\tmp\devops-k8s-agent-roadmap
git remote add origin git@github.com:<your-name>/devops-k8s-agent-roadmap.git
git push -u origin main
```

## 方式二：安装 GitHub CLI 后创建仓库

安装并登录 GitHub CLI 后，可以执行：

```powershell
cd D:\tmp\devops-k8s-agent-roadmap
gh auth login
gh repo create devops-k8s-agent-roadmap --private --source . --remote origin --push
```

## 后续每日学习流程

每天学习完成后：

```powershell
git status
git add .
git commit -m "Day 01 learning log"
git push
```

建议 commit message 使用：

```text
Day 01: initialize learning log
Day 02: add hello GitHub Actions workflow
Week 01: complete GitHub Actions basics
Project 01: complete CI baseline
```

## 推荐仓库可见性

早期建议 Private，因为里面可能包含学习记录、失败日志、配置草稿。等内容成熟后，可以再改成 Public，用作个人作品集。

