#!/bin/bash
set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 初始化函數
init_directories() {
    log_info "初始化目錄結構..."
    mkdir -p /app/data /app/logs
    chmod 755 /app/data /app/logs
    log_success "目錄結構初始化完成"
}

# 檢查依賴
check_dependencies() {
    log_info "檢查 Python 依賴..."
    
    if ! command -v python &> /dev/null; then
        log_error "Python 未安裝"
        exit 1
    fi
    
    if ! command -v uv &> /dev/null; then
        log_error "uv 套件管理器未安裝"
        exit 1
    fi
    
    log_success "依賴檢查完成"
}

# 設定環境
setup_environment() {
    log_info "設定環境變數..."
    
    # 設定 Qt 環境變數
    export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-xcb}
    export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:-1}
    
    # 設定 Python 環境變數
    export PYTHONUNBUFFERED=1
    export PYTHONDONTWRITEBYTECODE=1
    
    log_success "環境設定完成"
}

# 健康檢查
health_check() {
    log_info "執行健康檢查..."
    
    # 檢查 Python 模組
    python -c "
import sys
import importlib.util

modules = ['fastmcp', 'psutil', 'PySide6']
for module in modules:
    spec = importlib.util.find_spec(module)
    if spec is None:
        print(f'模組 {module} 未找到')
        sys.exit(1)
    else:
        print(f'模組 {module} 已安裝')

print('所有必要模組都已安裝')
"
    
    if [ $? -eq 0 ]; then
        log_success "健康檢查通過"
    else
        log_error "健康檢查失敗"
        exit 1
    fi
}

# 主函數
main() {
    log_info "啟動 Interactive Feedback MCP..."
    
    # 執行初始化步驟
    init_directories
    check_dependencies
    setup_environment
    health_check
    
    log_info "準備啟動應用程式..."
    
    # 根據傳入的參數決定啟動模式
    if [ "$1" = "dev" ]; then
        log_info "以開發模式啟動..."
        exec uv run fastmcp dev server.py
    elif [ "$1" = "test" ]; then
        log_info "執行測試..."
        exec python -m pytest
    else
        log_info "以生產模式啟動..."
        exec uv run server.py
    fi
}

# 信號處理
trap 'log_warning "收到終止信號，正在關閉..."; exit 0' SIGTERM SIGINT

# 執行主函數
main "$@" 