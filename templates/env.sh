#!/bin/bash
# FileCodeBox 环境配置模板
# 
# 使用方法：
# 1. 复制此文件到用户目录：cp templates/env.sh ~/.filecodebox.env
# 2. 编辑 ~/.filecodebox.env 填入您的实际配置
# 3. 在 ~/.bashrc 或 ~/.zshrc 中添加：source ~/.filecodebox.env

# =============================================================================
# 必填配置
# =============================================================================

# FileCodeBox 服务地址
# 默认直接访问后端服务，用 http://127.0.0.1:12345
# 如果使用 Nginx 反代，用 http://127.0.0.1:1001 或您配置的端口
# 如果是远程服务器，用 http://your-server-ip:port
export FILECODEBOX_URL="http://127.0.0.1:12345"

# =============================================================================
# 可选配置
# =============================================================================

# 管理后台密码（用于访问 /admin 路径）
# export FILECODEBOX_ADMIN_PASSWORD=""

# API密钥（如果服务端配置了API Key验证）
# export FILECODEBOX_API_KEY=""

# 默认过期时间值
# export FILECODEBOX_DEFAULT_EXPIRE_VALUE="7"

# 默认过期类型 (day/hour/minute/forever/count)
# export FILECODEBOX_DEFAULT_EXPIRE_STYLE="day"

# =============================================================================
# 验证配置（取消注释以启用）
# =============================================================================

# echo "FileCodeBox 配置已加载"
# echo "服务地址: $FILECODEBOX_URL"
