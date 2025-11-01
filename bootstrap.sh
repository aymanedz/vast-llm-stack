#!/usr/bin/env bash
set -e

# تحديث النظام وتثبيت الأدوات الأساسية
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-plugin git rclone

# تشغيل Docker تلقائيًا
sudo systemctl enable docker
sudo systemctl start docker

# إنشاء مجلد العمل
sudo mkdir -p /workspace && sudo chown -R $USER:$USER /workspace
cd /workspace

# استنساخ المستودع (بدّل YOUR_USER باسم مستخدمك في GitHub)
if [ ! -d "/workspace/vast-llm-stack/.git" ]; then
  git clone --depth=1 https://github.com/aymanedz/vast-llm-stack.git
else
  cd vast-llm-stack && git pull --ff-only && cd ..
fi

cd vast-llm-stack

# إنشاء مجلد المشروع (سيُستخدم لاحقًا للمزامنة مع الكلاود)
mkdir -p project

# تشغيل الخدمات (Ollama + OpenWebUI)
docker compose up -d

# سحب النماذج مرة واحدة (لن تتكرر إذا كانت مثبتة)
docker exec ollama ollama pull deepseek-r1:7b || true
docker exec ollama ollama pull qwen2.5-vl || true

echo "✅ جاهز. افتح المتصفح على: http://<IP>:3000"
