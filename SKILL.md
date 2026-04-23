---
name: filecodebox
description: FileCodeBox 文件快递柜 API — 通过命令行发送文件和取件，无需打开浏览器
category: productivity
requirements:
  env:
    - FILECODEBOX_URL    # FileCodeBox 服务地址，如 http://127.0.0.1:12345
  commands:
    - curl
    - jq    # 可选，用于美化JSON输出
setup: |
  ## 快速配置
  
  1. 复制配置模板：
     ```bash
     cp templates/env.sh ~/.filecodebox.env
     ```
  
  2. 编辑配置填入您的服务器地址：
     ```bash
     nano ~/.filecodebox.env
     ```
  
  3. 加载配置：
     ```bash
     source ~/.filecodebox.env
     ```
  
  4. 验证配置：
     ```bash
     bash scripts/check-config.sh
     ```

quick_start: |
  ```bash
  # 设置环境变量
  export FILECODEBOX_URL=http://127.0.0.1:12345
  
  # 发送文本（1天后过期）
  bash scripts/upload-text.sh "Hello World" 1 day
  
  # 发送文件（7天后过期）
  bash scripts/upload-file.sh /path/to/file.pdf 7 day
  
  # 取件
  bash scripts/retrieve.sh 80053
  ```
---

# FileCodeBox 文件快递柜 API 技能

FileCodeBox 是一个自建的文件快递柜服务（类似 WeTransfer/奶牛快传），支持设置过期时间和下载次数。

## 环境要求

- **curl** - 用于HTTP请求
- **jq** (可选) - 用于美化JSON输出

## 环境变量

| 变量名 | 必填 | 说明 |
|--------|------|------|
| `FILECODEBOX_URL` | ✅ | FileCodeBox服务地址，如 `http://127.0.0.1:12345` |
| `FILECODEBOX_ADMIN_PASSWORD` | ❌ | 管理后台密码（可选） |

## 配置方法

### 方法1：直接设置环境变量

```bash
export FILECODEBOX_URL=http://127.0.0.1:12345
```

### 方法2：使用配置模板（推荐）

```bash
# 复制模板到用户目录
cp templates/env.sh ~/.filecodebox.env

# 编辑配置
nano ~/.filecodebox.env

# 在 ~/.bashrc 或 ~/.zshrc 中添加
source ~/.filecodebox.env
```

### 方法3：验证配置

```bash
bash scripts/check-config.sh
```

## 过期类型说明

| 值 | 说明 | expire_value 含义 |
|----|------|-------------------|
| `day` | 天数 | 数字（如 7 表示7天） |
| `hour` | 小时 | 数字 |
| `minute` | 分钟 | 数字 |
| `forever` | 永久 | 传 1 即可 |
| `count` | 下载次数 | 数字（如 5 表示最多下载5次） |

## 使用方法

### 1️⃣ 获取配置信息

```bash
curl -s -X POST "${FILECODEBOX_URL}/"
```

返回系统名称、上传大小限制、可用过期类型等。

### 2️⃣ 发送文本

**使用脚本（推荐）：**
```bash
bash scripts/upload-text.sh "要发送的文字内容" 1 day
```

**使用curl：**
```bash
curl -s -X POST "${FILECODEBOX_URL}/share/text/" \
  -F "text=要发送的文字内容" \
  -F "expire_value=1" \
  -F "expire_style=day" | jq .
```

**返回示例：**
```json
{
  "code": 200,
  "message": "ok",
  "detail": {"code": "80053"}
}
```

`detail.code` 就是**取件码**，把这个码发给对方。

### 3️⃣ 发送文件

**使用脚本（推荐）：**
```bash
bash scripts/upload-file.sh /path/to/file.pptx 7 day
```

**使用curl：**
```bash
curl -s -X POST "${FILECODEBOX_URL}/share/file/" \
  -F "file=@/path/to/file.pptx" \
  -F "expire_value=7" \
  -F "expire_style=day" | jq .
```

**返回示例：**
```json
{
  "code": 200,
  "message": "ok",
  "detail": {"code": "80053", "name": "文件.pptx"}
}
```

### 4️⃣ 取件

**使用脚本（推荐）：**
```bash
bash scripts/retrieve.sh 80053
```

**使用curl（POST方式，不消耗次数）：**
```bash
curl -s -X POST "${FILECODEBOX_URL}/share/select/" \
  -H "Content-Type: application/json" \
  -d '{"code":"80053"}' | jq .
```

**文本类型返回示例：**
```json
{
  "code": 200,
  "message": "ok",
  "detail": {
    "code": "80053",
    "name": "Text",
    "text": "要发送的文字内容"
  }
}
```

**文件类型返回示例：**
```json
{
  "code": 200,
  "message": "ok",
  "detail": {
    "code": "80053",
    "name": "文档.pptx",
    "text": "http://127.0.0.1:12345/share/data/2026/04/22/xxx/文档.pptx"
  }
}
```

### 5️⃣ 下载文件

如果是文件类型，`detail.text` 包含下载链接：

```bash
# 获取文件信息
curl -s -X POST "${FILECODEBOX_URL}/share/select/" \
  -H "Content-Type: application/json" \
  -d '{"code":"80053"}' | jq -r '.detail.text'

# 下载文件
curl -s -o output.pptx "http://127.0.0.1:12345/share/data/2026/04/22/xxx/文档.pptx"
```

## 常用场景示例

### 场景1：发一段文字给朋友（1天后过期）

```bash
# 发送
bash scripts/upload-text.sh "明天下午3点开会别忘了" 1 day
# → ✅ 上传成功！取件码: 95271

# 取件
bash scripts/retrieve.sh 95271
# → 明天下午3点开会别忘了
```

### 场景2：发一个文件（7天后过期）

```bash
bash scripts/upload-file.sh /data/report.pdf 7 day
# → ✅ 上传成功！取件码: 86241
```

### 场景3：发一个文件（最多下载5次后过期）

```bash
bash scripts/upload-file.sh /data/secret.docx 5 count
```

### 场景4：永久保存一段文字

```bash
bash scripts/upload-text.sh "重要信息备份" 1 forever
```

## 历史记录

所有上传操作会自动记录到历史中，默认存储在 `~/.filecodebox-history.json`。

```bash
# 查看所有记录
bash scripts/history.sh

# 查看最后一条
bash scripts/history.sh --last

# 查找特定取件码
bash scripts/history.sh --code 80053

# 导出历史
bash scripts/history.sh --export backup.json

# 清空历史
bash scripts/history.sh --clean
```

**禁用历史记录**
```bash
export FILECODEBOX_DISABLE_HISTORY=1
```

### 检查配置

```bash
bash scripts/check-config.sh
```

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| `未设置 FILECODEBOX_URL` | 运行 `export FILECODEBOX_URL=http://your-server:port` |
| 连接失败 | 检查FileCodeBox服务是否启动，Nginx反代是否配置正确 |
| 文件太大 | 在管理后台修改上传大小限制，或使用分卷压缩 |
| 取件码无效 | 检查是否已过期或超过下载次数 |

## 批量操作

### 批量上传文件

```bash
# 基本用法
bash scripts/batch-upload.sh file1.pdf file2.txt image.jpg

# 指定过期设置
bash scripts/batch-upload.sh *.pdf -e 30 -s minute

# 通配符支持
bash scripts/batch-upload.sh docs/*
```

### 批量取件

创建一个文件（每行一个取件码）：
```bash
echo "80053
80054
80055" > codes.txt
```

然后批量取件：
```bash
# 只查看信息
bash scripts/batch-retrieve.sh codes.txt

# 自动下载到指定目录
bash scripts/batch-retrieve.sh codes.txt --download-dir ./downloads
```

## 部署自己的 FileCodeBox

如果你想自己部署 FileCodeBox 服务，请参考相关部署技能：
- `filecodebox-deployment` - 从源码部署 FileCodeBox
- `nginx-service-setup` - 配置 Nginx 反向代理

## 管理后台

- 地址：`${FILECODEBOX_URL}/admin`
- 默认密码：`FileCodeBox2023`（部署后可修改）

## 注意事项

1. 取件码 `code` 是上传后返回的，需要记录下来发给对方
2. **没有取件密码功能**——提取码本身就是密码
3. POST 方式取件不消耗下载次数，GET 方式会消耗
4. 文件下载链接有时效性，请尽快下载