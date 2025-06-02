# Interactive Feedback MCP - Docker 部署指南

這是 Interactive Feedback MCP 的 Docker 化版本，基於 [Fábio Ferreira](https://x.com/fabiomlferreira) 的原始專案開發。

## 📋 目錄

- [系統需求](#系統需求)
- [快速開始](#快速開始)
- [詳細配置](#詳細配置)
- [使用方式](#使用方式)
- [開發模式](#開發模式)
- [故障排除](#故障排除)
- [進階配置](#進階配置)

## 🔧 系統需求

### 基本需求
- Docker 20.10+ 
- Docker Compose 2.0+
- 至少 2GB 可用記憶體
- 至少 1GB 可用磁碟空間

### GUI 支援需求
- **Linux**: X11 伺服器
- **macOS**: XQuartz
- **Windows**: VcXsrv 或 Xming

## 🚀 快速開始

### 1. 克隆專案
```bash
git clone https://github.com/crmado/interactive-feedback-mcp.git
cd interactive-feedback-mcp
```

### 2. 設定開發環境
```bash
make setup-dev
```

### 3. 構建 Docker 映像
```bash
make build
```

### 4. 設定 GUI 支援（可選）
```bash
# Linux
make setup-x11

# macOS（需要先安裝 XQuartz）
xhost +localhost

# Windows（需要先啟動 X 伺服器）
# 在 X 伺服器設定中允許來自 localhost 的連接
```

### 5. 啟動服務
```bash
# 生產模式
make run

# 開發模式
make run-dev
```

## ⚙️ 詳細配置

### 環境變數

在 `docker-compose.yml` 中可以配置以下環境變數：

```yaml
environment:
  - PYTHONUNBUFFERED=1          # Python 輸出不緩衝
  - DISPLAY=${DISPLAY:-:0}      # X11 顯示設定
  - QT_QPA_PLATFORM=xcb         # Qt 平台設定
  - QT_X11_NO_MITSHM=1         # 禁用 MIT-SHM 擴展
```

### 卷掛載

```yaml
volumes:
  - ./data:/app/data            # 資料持久化
  - ./logs:/app/logs            # 日誌持久化
  - /tmp/.X11-unix:/tmp/.X11-unix:rw  # X11 socket
  - .:/app/workspace:ro         # 專案目錄（唯讀）
```

## 📖 使用方式

### 基本命令

```bash
# 查看所有可用命令
make help

# 構建映像
make build

# 啟動服務
make run

# 查看日誌
make logs

# 停止服務
make stop

# 重啟服務
make restart

# 進入容器
make shell

# 查看狀態
make status
```

### 進階命令

```bash
# 無快取構建
make build-no-cache

# 互動模式運行
make run-interactive

# 執行測試
make test

# 程式碼檢查
make lint

# 備份資料
make backup

# 清理資源
make clean

# 完全清理
make clean-all
```

## 🔧 開發模式

開發模式提供了額外的功能，包括：

- FastMCP 開發伺服器
- 即時程式碼重載
- Web 介面測試工具
- 詳細的除錯資訊

### 啟動開發模式

```bash
# 使用 Docker Compose profile
make run-dev

# 或直接使用 docker-compose
docker-compose --profile dev up interactive-feedback-mcp-dev
```

### 存取開發介面

開發模式啟動後，可以透過以下方式存取：

- **Web 介面**: http://localhost:8000
- **MCP 工具測試**: 在 Web 介面中測試 MCP 工具
- **即時日誌**: `make logs-dev`

## 🐛 故障排除

### 常見問題

#### 1. GUI 無法顯示

**Linux**:
```bash
# 檢查 X11 轉發
echo $DISPLAY
xhost +local:docker

# 檢查 X11 socket 權限
ls -la /tmp/.X11-unix/
```

**macOS**:
```bash
# 確保 XQuartz 正在運行
ps aux | grep XQuartz

# 允許網路連接
xhost +localhost
```

**Windows**:
- 確保 X 伺服器（VcXsrv/Xming）正在運行
- 在 X 伺服器設定中啟用「Disable access control」

#### 2. 容器無法啟動

```bash
# 檢查 Docker 狀態
docker info

# 檢查映像是否存在
docker images | grep interactive-feedback-mcp

# 查看詳細錯誤
docker-compose logs

# 重新構建映像
make build-no-cache
```

#### 3. 權限問題

```bash
# 檢查目錄權限
ls -la data/ logs/

# 修復權限
sudo chown -R $USER:$USER data/ logs/
chmod 755 data/ logs/
```

#### 4. 記憶體不足

```bash
# 檢查 Docker 記憶體限制
docker system df
docker system prune

# 增加 Docker 記憶體限制（Docker Desktop）
# 在 Docker Desktop 設定中調整記憶體分配
```

### 除錯技巧

```bash
# 進入容器進行除錯
make shell

# 查看容器資源使用情況
docker stats interactive-feedback-mcp

# 檢查容器網路
docker network ls
docker network inspect bridge

# 查看容器詳細資訊
docker inspect interactive-feedback-mcp
```

## 🔧 進階配置

### 自訂 Dockerfile

如果需要自訂 Docker 映像，可以修改 `Dockerfile`：

```dockerfile
# 添加額外的系統套件
RUN apt-get update && apt-get install -y \
    your-additional-package \
    && rm -rf /var/lib/apt/lists/*

# 添加額外的 Python 套件
RUN pip install your-python-package
```

### 自訂 Docker Compose

創建 `docker-compose.override.yml` 來覆蓋預設配置：

```yaml
version: '3.8'

services:
  interactive-feedback-mcp:
    environment:
      - CUSTOM_ENV_VAR=value
    volumes:
      - ./custom-data:/app/custom-data
    ports:
      - "8080:8000"
```

### 生產環境部署

對於生產環境，建議：

1. **使用具體的映像標籤**：
```yaml
image: interactive-feedback-mcp:1.0.0
```

2. **設定資源限制**：
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

3. **配置健康檢查**：
```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import sys; sys.exit(0)"]
  interval: 30s
  timeout: 10s
  retries: 3
```

4. **使用外部卷**：
```yaml
volumes:
  - app_data:/app/data
  - app_logs:/app/logs
```

### 監控和日誌

```bash
# 即時監控容器狀態
watch docker stats interactive-feedback-mcp

# 設定日誌輪轉
# 在 docker-compose.yml 中添加：
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 📝 授權

本專案基於 MIT 授權條款。原始專案由 [Fábio Ferreira](https://x.com/fabiomlferreira) 開發。

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 📞 支援

如有問題，請：

1. 查看本文件的故障排除章節
2. 檢查 [GitHub Issues](https://github.com/crmado/interactive-feedback-mcp/issues)
3. 聯繫原作者 [@fabiomlferreira](https://x.com/fabiomlferreira)

---

**注意**: 這是一個 Docker 化的版本，專注於提高部署的便利性和一致性。所有原始功能都被保留，並增加了容器化的優勢。 