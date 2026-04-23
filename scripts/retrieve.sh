#!/bin/bash
# FileCodeBox 取件脚本
# 用法：bash scripts/retrieve.sh <取件码>
#
# 示例：
#   bash scripts/retrieve.sh 80053

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 参数
CODE="$1"

# 检查环境变量
if [ -z "$FILECODEBOX_URL" ]; then
    echo -e "${RED}❌ 错误：未设置 FILECODEBOX_URL 环境变量${NC}"
    echo "请运行: export FILECODEBOX_URL=http://your-server:port"
    exit 1
fi

# 检查取件码
if [ -z "$CODE" ]; then
    echo -e "${RED}❌ 错误：请指定取件码${NC}"
    echo "用法: bash scripts/retrieve.sh <取件码>"
    echo ""
    echo "示例:"
    echo "  bash scripts/retrieve.sh 80053"
    exit 1
fi

echo -e "${BLUE}📥 正在取件...${NC}"
echo "  取件码: $CODE"
echo ""

# 取件（POST方式，不消耗下载次数）
response=$(curl -s -X POST "${FILECODEBOX_URL}/share/select/" \
  -H "Content-Type: application/json" \
  -d "{\"code\":\"$CODE\"}")

# 检查curl结果
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 取件失败：网络错误${NC}"
    exit 1
fi

# 解析响应
if command -v jq &> /dev/null; then
    api_code=$(echo "$response" | jq -r '.code // empty')
    message=$(echo "$response" | jq -r '.message // empty')
    
    if [ "$api_code" != "200" ]; then
        echo -e "${RED}❌ 取件失败: $message${NC}"
        echo "$response" | jq '.'
        exit 1
    fi
    
    detail_code=$(echo "$response" | jq -r '.detail.code // empty')
    detail_name=$(echo "$response" | jq -r '.detail.name // empty')
    detail_text=$(echo "$response" | jq -r '.detail.text // empty')
    detail_size=$(echo "$response" | jq -r '.detail.size // empty')
else
    # 简单解析
    if echo "$response" | grep -q '"code":200'; then
        detail_text=$(echo "$response" | grep -o '"text":"[^"]*"' | head -1 | cut -d'"' -f4)
        detail_name=$(echo "$response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    else
        echo -e "${RED}❌ 取件失败${NC}"
        echo "服务器返回: $response"
        exit 1
    fi
fi

# 判断类型并显示
if [ "$detail_name" = "Text" ]; then
    # 文本类型
    echo -e "${GREEN}✅ 取件成功！${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  📄 类型: 文本"
    echo ""
    echo -e "  ${YELLOW}$detail_text${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    # 文件类型
    echo -e "${GREEN}✅ 取件成功！${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  📁 类型: 文件"
    echo -e "  📄 文件名: ${YELLOW}$detail_name${NC}"
    if [ -n "$detail_size" ]; then
        echo -e "  📊 大小: $(numfmt --to=iec $detail_size 2>/dev/null || echo $detail_size bytes)"
    fi
    echo ""
    echo -e "  🔗 下载链接:"
    echo -e "  ${BLUE}$detail_text${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "下载命令:"
    echo -e "  ${YELLOW}curl -s -o \"$detail_name\" \"$detail_text\"${NC}"
    echo ""
    
    # 询问是否下载
    read -p "是否立即下载? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在下载..."
        if curl -s -o "$detail_name" "$detail_text"; then
            echo -e "${GREEN}✅ 下载完成: $detail_name${NC}"
        else
            echo -e "${RED}❌ 下载失败${NC}"
            exit 1
        fi
    fi
fi
