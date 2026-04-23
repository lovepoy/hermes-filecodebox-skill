#!/bin/bash
# FileCodeBox 历史记录管理脚本
# 用法: bash scripts/history.sh [options]
#
# 选项:
#   --last           查看最后一条记录
#   --code <code>    查找特定取件码
#   --clean          清空历史记录
#   --export <file>  导出历史到文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 历史文件路径
HISTORY_FILE="${FILECODEBOX_HISTORY_FILE:-$HOME/.filecodebox-history.json}"

# 初始化历史文件
init_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        echo '{"records":[]}' > "$HISTORY_FILE"
    fi
}

# 添加记录
add_record() {
    local type="$1"
    local code="$2"
    local name="$3"
    local size="$4"
    local expire_style="$5"
    local expire_value="$6"
    
    init_history
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local record=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "type": "$type",
    "code": "$code",
    "name": "$name",
    "size": "$size",
    "expire_style": "$expire_style",
    "expire_value": "$expire_value"
}
EOF
)
    
    if command -v jq &> /dev/null; then
        # 使用 jq 添加记录
        jq ".records += [$record]" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    else
        # 简单追加（可能不是标准JSON）
        echo "[警告] 未安装 jq，历史记录功能受限"
    fi
}

# 显示所有记录
show_all() {
    init_history
    
    if command -v jq &> /dev/null; then
        local count=$(jq '.records | length' "$HISTORY_FILE")
        
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}暂无历史记录${NC}"
            return
        fi
        
        echo -e "${BLUE}📚 历史记录（共 $count 条）${NC}"
        echo ""
        
        # 递反序显示
        for i in $(seq $(($count - 1)) -1 0); do
            local record=$(jq ".records[$i]" "$HISTORY_FILE")
            local timestamp=$(echo "$record" | jq -r '.timestamp')
            local type=$(echo "$record" | jq -r '.type')
            local code=$(echo "$record" | jq -r '.code')
            local name=$(echo "$record" | jq -r '.name')
            local size=$(echo "$record" | jq -r '.size // "-"')
            local expire_style=$(echo "$record" | jq -r '.expire_style')
            local expire_value=$(echo "$record" | jq -r '.expire_value')
            
            # 根据类型显示图标
            local icon="📁"
            [ "$type" = "text" ] && icon="📝"
            
            echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "  $icon ${YELLOW}取件码: $code${NC}"
            echo -e "  📄 名称: $name"
            [ "$size" != "-" ] && echo -e "  📊 大小: $size"
            echo -e "  ⏰ 过期: $expire_value $expire_style"
            echo -e "  📅 时间: $timestamp"
        done
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${YELLOW}请安装 jq 以使用历史记录功能${NC}"
        cat "$HISTORY_FILE"
    fi
}

# 显示最后一条记录
show_last() {
    init_history
    
    if command -v jq &> /dev/null; then
        local count=$(jq '.records | length' "$HISTORY_FILE")
        
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}暂无历史记录${NC}"
            return
        fi
        
        local record=$(jq ".records[$((count - 1))]" "$HISTORY_FILE")
        local timestamp=$(echo "$record" | jq -r '.timestamp')
        local type=$(echo "$record" | jq -r '.type')
        local code=$(echo "$record" | jq -r '.code')
        local name=$(echo "$record" | jq -r '.name')
        local expire_style=$(echo "$record" | jq -r '.expire_style')
        local expire_value=$(echo "$record" | jq -r '.expire_value')
        
        local icon="📁"
        [ "$type" = "text" ] && icon="📝"
        
        echo -e "${BLUE}🔄 最后一条记录${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  $icon ${YELLOW}取件码: $code${NC}"
        echo -e "  📄 名称: $name"
        echo -e "  ⏰ 过期: $expire_value $expire_style"
        echo -e "  📅 时间: $timestamp"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "取件命令: bash scripts/retrieve.sh $code"
    else
        echo -e "${YELLOW}请安装 jq 以使用此功能${NC}"
    fi
}

# 查找特定取件码
find_code() {
    local search_code="$1"
    init_history
    
    if command -v jq &> /dev/null; then
        local record=$(jq ".records[] | select(.code == \"$search_code\")" "$HISTORY_FILE")
        
        if [ -z "$record" ] || [ "$record" = "null" ]; then
            echo -e "${RED}未找到取件码: $search_code${NC}"
            return 1
        fi
        
        local timestamp=$(echo "$record" | jq -r '.timestamp')
        local type=$(echo "$record" | jq -r '.type')
        local code=$(echo "$record" | jq -r '.code')
        local name=$(echo "$record" | jq -r '.name')
        local expire_style=$(echo "$record" | jq -r '.expire_style')
        local expire_value=$(echo "$record" | jq -r '.expire_value')
        
        local icon="📁"
        [ "$type" = "text" ] && icon="📝"
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  $icon ${YELLOW}取件码: $code${NC}"
        echo -e "  📄 名称: $name"
        echo -e "  ⏰ 过期: $expire_value $expire_style"
        echo -e "  📅 时间: $timestamp"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "取件命令: bash scripts/retrieve.sh $code"
    else
        echo -e "${YELLOW}请安装 jq 以使用此功能${NC}"
    fi
}

# 清空历史
clean_history() {
    read -p "确定要清空所有历史记录吗? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo '{"records":[]}' > "$HISTORY_FILE"
        echo -e "${GREEN}✅ 已清空历史记录${NC}"
    else
        echo -e "${YELLOW}已取消${NC}"
    fi
}

# 导出历史
export_history() {
    local output_file="$1"
    init_history
    
    cp "$HISTORY_FILE" "$output_file"
    echo -e "${GREEN}✅ 已导出到: $output_file${NC}"
}

# 主逻辑
case "${1:-}" in
    --last)
        show_last
        ;;
    --code)
        if [ -z "$2" ]; then
            echo -e "${RED}错误: 请指定取件码${NC}"
            exit 1
        fi
        find_code "$2"
        ;;
    --clean)
        clean_history
        ;;
    --export)
        if [ -z "$2" ]; then
            echo -e "${RED}错误: 请指定输出文件路径${NC}"
            exit 1
        fi
        export_history "$2"
        ;;
    --add)
        # 内部使用，由上传脚本调用
        add_record "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    *)
        show_all
        ;;
esac
