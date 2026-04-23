---
name: filecodebox-deployment
category: devops
description: Deploy FileCodeBox (文件快递柜) from source without Docker. Build Vue3 frontend themes and set up reverse proxy.
tags: [filecodebox, file-sharing, fastapi, vue3, nginx, reverse-proxy, nodejs]
---

# FileCodeBox (文件快递柜) Deployment

Deploy FileCodeBox from source without Docker. Upload files, get a pickup code, share with others. Supports password protection, expiration time, download limits, and auto-cleanup.

## Trigger Conditions
- User wants a file sharing service like a "快递柜" (express locker)
- User needs password-protected + time-expiring file sharing
- Docker is NOT available

## Architecture
Nginx (port 1001) reverse proxies to FastAPI backend (port 12345) which serves SQLite DB + static themes.

## Steps

### 1. Extract backend
```bash
mkdir -p /data/filecodebox
unzip -q /path/to/FileCodeBox-master.zip -d /data/filecodebox/backend
```

### 2. Build 2024 theme (Vue3 frontend)
```bash
unzip -q /path/to/FileCodeBoxFronted-main.zip -d /data/filecodebox/
cd /data/filecodebox/FileCodeBoxFronted-main
npm install
npm run build
mkdir -p /data/filecodebox/backend/FileCodeBox-master/themes
cp -r dist /data/filecodebox/backend/FileCodeBox-master/themes/2024
```

### 3. Build 2023 theme (Element Plus Vue3 frontend)
```bash
git clone --depth 1 https://github.com/vastsa/FileCodeBoxFronted2023.git /tmp/fronted-2023
cd /tmp/fronted-2023
npm install --legacy-peer-deps
npm run build
cp -r dist /data/filecodebox/backend/FileCodeBox-master/themes/2023
```

### 4. Install Python deps and start
```bash
cd /data/filecodebox/backend/FileCodeBox-master
pip3 install -r requirements.txt
python3 main.py
```
Server starts on port 12345.

### 5. Configure Nginx reverse proxy

Write a server block listening on port 1001 that proxies requests to localhost:12345. Key settings:
- `client_max_body_size 0` (no upload limit)
- Long timeouts (300s) for large file uploads
- `proxy_buffering off` and `proxy_request_buffering off`
- Forward client IP via proxy headers

Save to `/etc/nginx/sites-available/filecodebox`, symlink to `sites-enabled/`, test config, then reload nginx. Use a Python helper script to write the file if direct shell commands are blocked.

### 6. Verify
```bash
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:1001/
# Expected: 200
```

## Default Settings
- Admin password: FileCodeBox2023 (configured in core/settings.py)
- Upload size: 10MB default
- Theme: themes/2024

## Pitfalls
- Backend repo lacks themes/ directory — must build frontend separately
- 2023 theme needs `--legacy-peer-deps` for npm install
- Set large upload limits and timeouts for big files
- Process runs as foreground — use background mode for persistence
