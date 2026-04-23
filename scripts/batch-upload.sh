#!/bin/bash
# FileCodeBox 批量上传脚本
# 用法: bash scripts/batch-upload.sh <文件1> [文件2] [文件3] ... [选项]
#
# 选项:
#   -e, --expire-value <n>    过期值 (默认: 7)
#   -s, --expire-style <type> 过期类型 (默认: day)
#
# 示例:
#   bash scripts/batch-upload.sh file1.pdf file2.txt
#   bash scripts/batch-upload.sh *.jpg -e 30 -s minute

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认值
EXPIRE_VALUE="7"
EXPIRE_STYLE="day"

# 解析参数
FILES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--expire-value)
            EXPIRE_VALUE="$2"
            shift 2
            ;;
        -s|--expire-style)
            EXPIRE_STYLE="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}未知选项: $1${NC}"
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# 检查环境变量
if [ -z "$FILECODEBOX_URL" ]; then
    echo -e "${RED}❌ 错误: 未设置 FILECODEBOX_URL 环境变量${NC}"
    echo "请运行: export FILECODEBOX_URL=http://your-server:port"
    exit 1
fi

# 检查文件
if [ ${#FILES[@]} -eq 0 ]; then
    echo -e "${RED}❌ 错误: 请指定要上传的文件${NC}"
    echo ""
    echo "用法: bash scripts/batch-upload.sh <文件1> [文件2] ... [选项]"
    echo ""
    echo "选项:"
    echo "  -e, --expire-value <n>    过期值 (默认: 7)"
    echo "  -s, --expire-style <type> 过期类型 (默认: day)"
    echo ""
    echo "示例:"
    echo "  bash scripts/batch-upload.sh file1.pdf file2.txt"
    echo "  bash scripts/batch-upload.sh *.jpg -e 30 -s minute"
    exit 1
fi

# 检查文件是否存在
VALID_FILES=()
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        VALID_FILES+=("$file")
    else
        echo -e "${YELLOW}⚠ 跳过不存在的文件: $file${NC}"
    fi
done

if [ ${#VALID_FILES[@]} -eq 0 ]; then
    echo -e "${RED}❌ 错误: 没有有效的文件${NC}"
    exit 1
fi

echo -e "${BLUE}📦 批量上传文件${NC}"
echo "  文件数量: ${#VALID_FILES[@]}"
echo "  过期设置: $EXPIRE_VALUE $EXPIRE_STYLE"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 记录结果
declare -a RESULTS=()

# 上传文件
for i in "${!VALID_FILES[@]}"; do
    file="${VALID_FILES[$i]}"
    num=$((i + 1))
    
    echo -e "${BLUE}[$num/${#VALID_FILES[@]}] 上传: $(basename "$file")${NC}"
    
    response=$(curl -s -X POST "${FILECODEBOX_URL}/share/file/" \
      -F "file=@$file" \
      -F "expire_value=$EXPIRE_VALUE" \
      -F "expire_style=$EXPIRE_STYLE")
    
    if command -v jq &> /dev/null; then
        code=$(echo "$response" | jq -r '.detail.code // empty')
        name=$(echo "$response" | jq -r '.detail.name // empty')
    else
        code=$(echo "$response" | grep -o '"code":"[0-9]*"' | head -1 | cut -d'"' -f4)
    fi
    
    if [ -n "$code" ]; then
        echo -e "  ${GREEN}✓ 成功 - 取件码: $code${NC}"
        RESULTS+=("$code|$(basename "$file")")
        
        # 记录到历史
        if [ -f "$SCRIPT_DIR/history.sh" ]; then
            bash "$SCRIPT_DIR/history.sh" --add "file" "$code" "$(basename "$file")" "" "$EXPIRE_STYLE" "$EXPIRE_VALUE" 2>/dev/null || true
        fi
    else
        echo -e "  ${RED}✗ 失败${NC}"
        RESULTS+=("FAILED|$(basename "$file")")
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 批量上传完成${NC}"
echo ""

# 显示结果汇总
echo -e "${CYAN}📋 取件码列表:${NC}"
echo ""
for result in "${RESULTS[@]}"; do
    IFS='|' read -r code filename <<< "$result"
    if [ "$code" = "FAILED" ]; then
        echo -e "  ${RED}✗ $filename - 失败${NC}"
    else
        echo -e "  ${GREEN}✓${NC} ${YELLOW}$code${NC} - $filename"
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "提示: 可以将取件码保存到文件："
echo "  bash scripts/batch-upload.sh ${VALID_FILES[@]} > codes.txt"
