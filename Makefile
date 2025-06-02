# Interactive Feedback MCP - Docker 管理 Makefile
# 作者：根據 Fábio Ferreira 的專案改編

# 變數定義
DOCKER_IMAGE_NAME = interactive-feedback-mcp
DOCKER_CONTAINER_NAME = interactive-feedback-mcp
DOCKER_COMPOSE_FILE = docker-compose.yml
PROJECT_DIR = $(shell pwd)
PLATFORM = linux/amd64

# 顏色定義
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# 預設目標
.DEFAULT_GOAL := help

# 幫助資訊
.PHONY: help
help: ## 顯示此幫助資訊
	@echo "$(GREEN)Interactive Feedback MCP - Docker 管理命令$(NC)"
	@echo ""
	@echo "$(YELLOW)可用命令：$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# 構建相關
.PHONY: build
build: ## 構建 Docker 映像
	@echo "$(GREEN)構建 Docker 映像...$(NC)"
	docker build --platform $(PLATFORM) -t $(DOCKER_IMAGE_NAME) .

.PHONY: build-no-cache
build-no-cache: ## 無快取構建 Docker 映像
	@echo "$(GREEN)無快取構建 Docker 映像...$(NC)"
	docker build --platform $(PLATFORM) --no-cache -t $(DOCKER_IMAGE_NAME) .

# 運行相關
.PHONY: run
run: ## 運行容器（生產模式）
	@echo "$(GREEN)啟動容器（生產模式）...$(NC)"
	docker compose up -d

.PHONY: run-dev
run-dev: ## 運行容器（開發模式）
	@echo "$(GREEN)啟動容器（開發模式）...$(NC)"
	docker compose --profile dev up interactive-feedback-mcp-dev

.PHONY: run-interactive
run-interactive: ## 以互動模式運行容器
	@echo "$(GREEN)以互動模式啟動容器...$(NC)"
	docker run -it --rm --platform $(PLATFORM) \
		--name $(DOCKER_CONTAINER_NAME)-interactive \
		-e DISPLAY=$$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
		-v $(PROJECT_DIR)/data:/app/data \
		-v $(PROJECT_DIR)/logs:/app/logs \
		$(DOCKER_IMAGE_NAME) /bin/bash

# 停止和清理
.PHONY: stop
stop: ## 停止所有容器
	@echo "$(GREEN)停止容器...$(NC)"
	docker compose down

.PHONY: restart
restart: stop run ## 重啟容器

.PHONY: clean
clean: ## 清理停止的容器和未使用的映像
	@echo "$(GREEN)清理 Docker 資源...$(NC)"
	docker container prune -f
	docker image prune -f

.PHONY: clean-all
clean-all: ## 清理所有相關的 Docker 資源
	@echo "$(RED)清理所有相關 Docker 資源...$(NC)"
	docker compose down --rmi all --volumes --remove-orphans
	docker system prune -f

# 日誌和監控
.PHONY: logs
logs: ## 查看容器日誌
	@echo "$(GREEN)查看容器日誌...$(NC)"
	docker compose logs -f

.PHONY: logs-dev
logs-dev: ## 查看開發容器日誌
	@echo "$(GREEN)查看開發容器日誌...$(NC)"
	docker compose logs -f interactive-feedback-mcp-dev

.PHONY: status
status: ## 查看容器狀態
	@echo "$(GREEN)容器狀態：$(NC)"
	docker compose ps

# 進入容器
.PHONY: shell
shell: ## 進入運行中的容器
	@echo "$(GREEN)進入容器 shell...$(NC)"
	docker exec -it $(DOCKER_CONTAINER_NAME) /bin/bash

.PHONY: shell-dev
shell-dev: ## 進入開發容器
	@echo "$(GREEN)進入開發容器 shell...$(NC)"
	docker exec -it $(DOCKER_CONTAINER_NAME)-dev /bin/bash

# 測試相關
.PHONY: test
test: ## 在容器中運行測試
	@echo "$(GREEN)運行測試...$(NC)"
	docker run --rm --platform $(PLATFORM) \
		-v $(PROJECT_DIR):/app/workspace \
		$(DOCKER_IMAGE_NAME) test

# 開發工具
.PHONY: setup-dev
setup-dev: ## 設定開發環境
	@echo "$(GREEN)設定開發環境...$(NC)"
	mkdir -p data logs
	chmod 755 data logs
	@echo "$(GREEN)開發環境設定完成$(NC)"

.PHONY: lint
lint: ## 執行程式碼檢查
	@echo "$(GREEN)執行程式碼檢查...$(NC)"
	docker run --rm --platform $(PLATFORM) \
		-v $(PROJECT_DIR):/app/workspace \
		$(DOCKER_IMAGE_NAME) \
		sh -c "cd /app/workspace && python -m flake8 *.py"

# X11 相關（用於 GUI 顯示）
.PHONY: setup-x11
setup-x11: ## 設定 X11 轉發（Linux/macOS）
	@echo "$(GREEN)設定 X11 轉發...$(NC)"
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "$(YELLOW)macOS 檢測到，請確保已安裝 XQuartz$(NC)"; \
		echo "$(YELLOW)執行：xhost +localhost$(NC)"; \
	else \
		echo "$(YELLOW)Linux 檢測到，執行：xhost +local:docker$(NC)"; \
		xhost +local:docker; \
	fi

# 備份和還原
.PHONY: backup
backup: ## 備份資料目錄
	@echo "$(GREEN)備份資料...$(NC)"
	tar -czf backup-$$(date +%Y%m%d-%H%M%S).tar.gz data/ logs/

.PHONY: info
info: ## 顯示系統資訊
	@echo "$(GREEN)系統資訊：$(NC)"
	@echo "Docker 版本：$$(docker --version)"
	@echo "Docker Compose 版本：$$(docker compose version)"
	@echo "專案目錄：$(PROJECT_DIR)"
	@echo "映像名稱：$(DOCKER_IMAGE_NAME)"
	@echo "容器名稱：$(DOCKER_CONTAINER_NAME)"
	@echo "平台：$(PLATFORM)" 