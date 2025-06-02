# 使用官方 Python 3.11 slim 映像作為基礎
FROM python:3.11-slim

# 設定工作目錄
WORKDIR /app

# 設定環境變數
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DISPLAY=:0

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    # Qt 和 GUI 相關依賴
    libqt6gui6 \
    libqt6widgets6 \
    libqt6core6 \
    qt6-qpa-plugins \
    # X11 相關依賴（用於 GUI 顯示）
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    # 其他必要工具
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安裝 uv（Python 套件管理器）
RUN pip install uv

# 複製專案檔案
COPY pyproject.toml uv.lock ./
COPY .python-version ./

# 使用 uv 安裝依賴
RUN uv sync --frozen

# 複製應用程式原始碼
COPY server.py feedback_ui.py ./
COPY README.md LICENSE ./

# 創建必要的目錄
RUN mkdir -p /app/data /app/logs

# 設定權限
RUN chmod +x server.py feedback_ui.py

# 暴露預設埠（如果需要）
EXPOSE 8000

# 設定健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

# 預設命令
CMD ["uv", "run", "server.py"] 