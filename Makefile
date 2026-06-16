.DEFAULT_GOAL := help

.PHONY: serve build new clean help

serve: ## 本地预览（含草稿），浏览器开 http://localhost:1313
	hugo server --buildDrafts --baseURL http://localhost:1313/

build: ## 生产构建到 public/（部署由 GitHub Actions 自动完成，一般不用手跑）
	hugo --gc --minify

new: ## 新建文章： make new slug=my-post
	@test -n "$(slug)" || { echo "用法: make new slug=my-post"; exit 1; }
	hugo new content posts/$(slug).md

clean: ## 清理构建产物
	rm -rf public resources/_gen .hugo_build.lock

help: ## 显示此帮助
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'
