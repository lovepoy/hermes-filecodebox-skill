#!/bin/bash
# FileCodeBox 批量取件脚本
# 用法: bash scripts/batch-retrieve.sh <取件码文件>
#
# 取件码文件格式（每行一个取件码）:
# 80053
# 80054
# 80055
#
# 示例:
#   bash scripts/batch-retrieve.sh codes.txt
#   bash scripts/batch-retrieve.sh codes.txt --download-dir ./downloads

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认下载目录
DOWNLOAD_DIR=""

# 解析参数
CODES_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --download-dir)
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}未知选项: $1${NC}"
            exit 1
            ;;
        *)
            CODES_FILE="$1"
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
if [ -z "$CODES_FILE" ]; then
    echo -e "${RED}❌ 错误: 请指定取件码文件${NC}"
    echo ""
    echo "用法: bash scripts/batch-retrieve.sh <取件码文件> [选项]"
    echo ""
    echo "选项:"
    echo "  --download-dir <dir>  指定下载目录"
    echo ""
    echo "示例:"
    echo "  bash scripts/batch-retrieve.sh codes.txt"
    echo "  bash scripts/batch-retrieve.sh codes.txt --download-dir ./downloads"
    echo ""
    echo "取件码文件格式（每行一个取件码）:"
    echo "  80053"
    echo "  80054"
    echo "  80055"
    exit 1
fi

if [ ! -f "$CODES_FILE" ]; then
    echo -e "${RED}❌ 错误: 文件不存在: $CODES_FILE${NC}"
    exit 1
fi

# 创建下载目录
if [ -n "$DOWNLOAD_DIR" ]; then
    mkdir -p "$DOWNLOAD_DIR"
fi

# 读取取件码列表
mapfile -t CODES < "$CODES_FILE"

# 过滤空行和注释
VALID_CODES=()
for code in "${CODES[@]}"; do
    code=$(echo "$code" | tr -d '[:space:]')
    if [ -n "$code" ] && [[ ! "$code" =~ ^# ]]; then
        VALID_CODES+=("$code")
    fi
done

if [ ${#VALID_CODES[@]} -eq 0 ]; then
    echo -e "${RED}❌ 错误: 文件中没有有效的取件码${NC}"
    exit 1
fi

echo -e "${BLUE}📥 批量取件${NC}"
echo "  取件码数量: ${#VALID_CODES[@]}"
echo "  文件来源: $CODES_FILE"
[ -n "$DOWNLOAD_DIR" ] && echo "  下载目录: $DOWNLOAD_DIR"
echo ""

# 记录结果
declare -a RESULTS=()

# 处理每个取件码
for i in "${!VALID_CODES[@]}"; do
    code="${VALID_CODES[$i]}"
    num=$((i + 1))
    
    echo -e "${BLUE}[$num/${#VALID_CODES[@]}] 取件码: $code${NC}"
    
    # 查询信息
    response=$(curl -s -X POST "${FILECODEBOX_URL}/share/select/" \
      -H "Content-Type: application/json" \
      -d "{\"code\":\"$code\"}")
    
    if command -v jq &> /dev/null; then
        api_code=$(echo "$response" | jq -r '.code // empty')
        detail_name=$(echo "$response" | jq -r '.detail.name // empty')
        detail_text=$(echo "$response" | jq -r '.detail.text // empty')
    else
        if echo "$response" | grep -q '"code":200'; then
            api_code="200"
            detail_text=$(echo "$response" | grep -o '"text":"[^"]*"' | head -1 | cut -d'"' -f4)
            detail_name=$(echo "$response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        else
            api_code=""
        fi
    fi
    
    if [ "$api_code" != "200" ]; then
        echo -e "  ${RED}✗ 取件失败${NC}"
        RESULTS+=("$code|FAILED|取件失败")
        continue
    fi
    
    # 判断类型
    if [ "$detail_name" = "Text" ]; then
        # 文本类型
        echo -e "  ${GREEN}✓ 文本内容:${NC}"
        echo -e "  ${CYAN}$detail_text${NC}"
        RESULTS+=("$code|TEXT|$detail_text")
    else
        # 文件类型
        echo -e "  ${GREEN}✓ 文件: $detail_name${NC}"
        
        # 下载文件
        if [ -n "$DOWNLOAD_DIR" ]; then
            output_path="$DOWNLOAD_DIR/$detail_name"
            if curl -s -o "$output_path" "$detail_text"; then
                echo -e "  ${GREEN}  ↓ 已下载: $output_path${NC}"
                RESULTS+=("$code|FILE|$detail_name|已下载")
            else
                echo -e "  ${RED}  ✗ 下载失败${NC}"
                RESULTS+=("$code|FILE|$detail_name|下载失败")
            fi
        else
            echo -e "  ${YELLOW}  → 下载链接: $detail_text${NC}"
            RESULTS+=("$code|FILE|$detail_name|未下载")
        fi
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 批量取件完成${NC}"
echo ""

# 统计
SUCCESS_COUNT=0
FAILED_COUNT=0
for result in "${RESULTS[@]}"; do
    IFS='|' read -r code status info extra <<< "$result"
    if [ "$status" = "FAILED" ]; then
        ((FAILED_COUNT++))
    else
        ((SUCCESS_COUNT++))
    fi
done

echo -e "统计: ${GREEN}成功 $SUCCESS_COUNT${NC} | ${RED}失败 $FAILED_COUNT${NC} | 共 ${#RESULTS[@]}"

# 如果有失败，列出失败的取件码
if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo -e "${RED}失败的取件码:${NC}"
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r code status info extra <<< "$result"
        if [ "$status" = "FAILED" ]; then
            echo -e "  ${RED}✗ $code - $info${NC}"
        fi
    done
fi
