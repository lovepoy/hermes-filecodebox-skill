#!/bin/bash
# FileCodeBox 文本上传脚本
# 用法：bash scripts/upload-text.sh "文本内容" [过期值] [过期类型]
#
# 示例：
#   bash scripts/upload-text.sh "Hello World"
#   bash scripts/upload-text.sh "Hello World" 1 day
#   bash scripts/upload-text.sh "Hello World" 30 minute

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 参数
TEXT="$1"
EXPIRE_VALUE="${2:-1}"      # 默认1
EXPIRE_STYLE="${3:-day}"    # 默认day

# 检查环境变量
if [ -z "$FILECODEBOX_URL" ]; then
    echo -e "${RED}❌ 错误：未设置 FILECODEBOX_URL 环境变量${NC}"
    echo "请运行: export FILECODEBOX_URL=http://your-server:port"
    exit 1
fi

# 检查文本
if [ -z "$TEXT" ]; then
    echo -e "${RED}❌ 错误：请指定要发送的文本${NC}"
    echo "用法: bash scripts/upload-text.sh \"文本内容\" [过期值] [过期类型]"
    echo ""
    echo "过期类型: day, hour, minute, forever, count"
    echo ""
    echo "示例:"
    echo "  bash scripts/upload-text.sh \"明天下午开会\""
    echo "  bash scripts/upload-text.sh \"明天下午开会\" 1 day"
    echo "  bash scripts/upload-text.sh \"验证码123456\" 30 minute"
    exit 1
fi

TEXT_LENGTH=${#TEXT}

echo -e "${BLUE}📤 准备发送文本${NC}"
echo "  长度: $TEXT_LENGTH 字符"
echo "  过期: $EXPIRE_VALUE $EXPIRE_STYLE"
echo ""

# 上传
response=$(curl -s -X POST "${FILECODEBOX_URL}/share/text/" \
  -F "text=$TEXT" \
  -F "expire_value=$EXPIRE_VALUE" \
  -F "expire_style=$EXPIRE_STYLE")

# 检查curl结果
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 发送失败：网络错误${NC}"
    exit 1
fi

# 解析响应
if command -v jq &> /dev/null; then
    code=$(echo "$response" | jq -r '.detail.code // empty')
    message=$(echo "$response" | jq -r '.message // empty')
else
    code=$(echo "$response" | grep -o '"code":"[0-9]*"' | head -1 | cut -d'"' -f4)
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$code" ]; then
    echo -e "${GREEN}✅ 发送成功！${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  📋 ${YELLOW}取件码: $code${NC}"
    echo -e "  📝 预览: ${TEXT:0:50}"
    if [ ${#TEXT} -gt 50 ]; then
        echo -e "      ..."
    fi
    echo -e "  🔗 取件链接: ${FILECODEBOX_URL}/?code=$code"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "提示：把取件码发给对方即可"
    
    # 记录到历史
    if [ -f "$SCRIPT_DIR/history.sh" ] && [ -z "$FILECODEBOX_DISABLE_HISTORY" ]; then
        bash "$SCRIPT_DIR/history.sh" --add "text" "$code" "${TEXT:0:30}..." "" "$EXPIRE_STYLE" "$EXPIRE_VALUE" 2>/dev/null || true
    fi
else
    echo -e "${RED}❌ 发送失败${NC}"
    if command -v jq &> /dev/null; then
        echo "$response" | jq '.'
    else
        echo "服务器返回: $response"
    fi
    exit 1
fi