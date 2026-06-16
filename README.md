# 我的技术博客

基于 [Hugo](https://gohugo.io/) + [PaperMod](https://github.com/adityatelange/hugo-PaperMod) 主题，通过 GitHub Actions 自动部署到 GitHub Pages。

- **线上**：<https://gonglei-hw.github.io/blog/>
- **仓库**：<https://github.com/GongLei-HW/blog>

## 环境要求

- Hugo extended ≥ 0.163 —— 安装：`brew install hugo`
- Git

## 常用命令（Makefile）

| 命令 | 作用 |
| --- | --- |
| `make serve` | 本地预览（含草稿），浏览器打开 <http://localhost:1313> |
| `make new slug=my-post` | 新建文章 `content/posts/my-post.md` |
| `make build` | 生产构建到 `public/`（部署是自动的，一般不用手跑） |
| `make clean` | 清理构建产物 |

## 启动 / 停掉本地服务

```bash
# 启动
make serve
# 等价于（带 baseURL 是为了避免 hugo server 裸跑时根路径 404）：
# hugo server --buildDrafts --baseURL http://localhost:1313/

# 停掉：在该终端按 Ctrl+C
# 如果忘了在哪个终端跑 / 后台跑挂了，一键关闭：
pkill -f "hugo.*server"
```

## 写一篇新文章

```bash
make new slug=my-next-post          # 生成 content/posts/my-next-post.md
make serve                          # 本地预览
```

frontmatter 已由模板（`archetypes/default.md`）填好，照着改即可：

```markdown
+++
title = 'My Next Post'
date = 2026-06-16
draft = true          # ⚠️ 发布前改成 false，否则不会上线
description = '一句话摘要，用于列表页和 SEO'
tags = ['llm', 'rust']
categories = ['推理系统']
toc = true
+++

正文用 Markdown 写。第一段（或 `<!--more-->` 之前）会作为首页摘要。
```

要点：

- **发布前把 `draft` 改成 `false`**——部署时不构建草稿。
- **文件名用英文连字符**，会直接变成 URL（`/posts/my-next-post/`）。
- 代码块自带高亮 + 复制按钮，文章页自带目录 / 阅读时长 / 标签 / 归档 / 搜索。

## 部署

push 到 `main` 分支即自动部署：

```bash
git add -A && git commit -m "post: 文章标题" && git push
```

GitHub Actions（`.github/workflows/hugo.yml`）会构建并发布到 GitHub Pages。
**`baseURL` 按仓库名自动推断**（项目站 → `owner.github.io/repo/`，根站 → `owner.github.io/`），无需手动改。

## 目录结构

```
myblog/
├── content/
│   ├── posts/                 # 文章（Markdown）
│   ├── archives.md            # 归档页
│   └── search.md              # 搜索页
├── archetypes/default.md      # 新文章模板
├── themes/PaperMod/           # 主题（git submodule，勿直接改）
├── static/                    # 图片等静态资源
├── hugo.toml                  # 站点配置（标题/作者/菜单/主题参数）
├── Makefile                   # 常用命令
└── .github/workflows/hugo.yml # 自动部署
```

## 自定义

站点标题、作者、菜单、主题参数都在 `hugo.toml`，注释齐全：

- 亮/暗模式：`[params] defaultTheme`（`auto` / `light` / `dark`）
- 社交链接：`[[params.socialIcons]]`
- 代码高亮风格：`[markup.highlight] style`
- 首页简介：`[params.homeInfoParams]`

> 改主题参数前先看一眼 `themes/PaperMod/`，需要覆盖样式时在项目里建 `layouts/` 或 `assets/` 同名文件，不要直接改 submodule。
