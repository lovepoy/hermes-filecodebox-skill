#!/bin/bash
# FileCodeBox 配置检查脚本
# 用法：bash scripts/check-config.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  FileCodeBox 配置检查"
echo "=========================================="
echo ""

# 检查环境变量
if [ -z "$FILECODEBOX_URL" ]; then
    echo -e "${RED}❌ 错误：未设置 FILECODEBOX_URL 环境变量${NC}"
    echo ""
    echo "请按以下步骤配置："
    echo ""
    echo "方法1 - 临时设置："
    echo "  export FILECODEBOX_URL=http://127.0.0.1:12345"
    echo ""
    echo "方法2 - 永久设置："
    echo "  1. cp templates/env.sh ~/.filecodebox.env"
    echo "  2. 编辑 ~/.filecodebox.env 填入您的服务器地址"
    echo "  3. 在 ~/.bashrc 中添加: source ~/.filecodebox.env"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ FILECODEBOX_URL: $FILECODEBOX_URL${NC}"

# 检查可选配置
if [ -n "$FILECODEBOX_ADMIN_PASSWORD" ]; then
    echo -e "${GREEN}✓ FILECODEBOX_ADMIN_PASSWORD: 已设置${NC}"
else
    echo -e "${YELLOW}⚠ FILECODEBOX_ADMIN_PASSWORD: 未设置（可选）${NC}"
fi

echo ""
echo "=========================================="
echo "  连接测试"
echo "=========================================="
echo ""

# 测试依赖命令
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ 错误：未安装 curl${NC}"
    exit 1
fi
echo -e "${GREEN}✓ curl 已安装${NC}"

if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓ jq 已安装（可选）${NC}"
else
    echo -e "${YELLOW}⚠ jq 未安装（可选，用于美化输出）${NC}"
    echo "  安装: sudo apt install jq  # Debian/Ubuntu"
    echo "        brew install jq       # macOS"
fi

echo ""
echo "正在测试 FileCodeBox 连接..."
echo ""

# 测试连接
response=$(curl -s -X POST "${FILECODEBOX_URL}/" 2>/dev/null) || {
    echo -e "${RED}❌ 连接失败${NC}"
    echo ""
    echo "可能的原因："
    echo "  - FileCodeBox 服务未启动"
    echo "  - FILECODEBOX_URL 地址错误"
    echo "  - 网络连接问题"
    echo ""
    echo "请检查："
    echo "  1. FileCodeBox 服务是否正在运行"
    echo "  2. 地址是否正确: $FILECODEBOX_URL"
    echo "  3. 防火墙/网络配置"
    exit 1
}

if [ -n "$response" ]; then
    echo -e "${GREEN}✓ 连接成功！${NC}"
    echo ""
    echo "服务器信息："
    
    # 尝试解析JSON
    if command -v jq &> /dev/null; then
        echo "$response" | jq '.'
    else
        echo "$response"
    fi
    
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  配置检查通过！可以正常使用。${NC}"
    echo -e "${GREEN}==========================================${NC}"
else
    echo -e "${RED}❌ 连接异常：服务器返回空响应${NC}"
    exit 1
fi