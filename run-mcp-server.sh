#!/bin/bash

# Interactive Feedback MCP 啟動腳本
# 此腳本用於在 Cursor 中啟動 MCP 伺服器

set -e

# 獲取腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 確保 Docker 映像存在
if ! docker images | grep -q "interactive-feedback-mcp"; then
    echo "Docker 映像不存在，正在構建..." >&2
    cd "$SCRIPT_DIR"
    docker build -t interactive-feedback-mcp .
fi

# 確保資料目錄存在
mkdir -p "$SCRIPT_DIR/data" "$SCRIPT_DIR/logs"

# 運行 MCP 伺服器
exec docker run --rm -i \
    --name "interactive-feedback-mcp-cursor-$$" \
    -v "$SCRIPT_DIR/data:/app/data" \
    -v "$SCRIPT_DIR/logs:/app/logs" \
    -e PYTHONUNBUFFERED=1 \
    interactive-feedback-mcp \
    uv run server.py 