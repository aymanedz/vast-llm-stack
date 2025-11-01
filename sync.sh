#!/usr/bin/env bash
set -e

# إعدادات عامة
BUCKET="vast-ai-storage"                 # اسم الـ bucket الذي أنشأته في R2 (عدّله إذا كان مختلف)
REMOTE="r2:${BUCKET}/project"            # مجلد المشروع على R2
LOCAL="/workspace/vast-llm-stack/project" # مجلد المشروع على السيرفر

# نستخدم ملف إعداد rclone الذي وضعناه داخل المستودع
RCLONE_CFG="/workspace/vast-llm-stack/rclone.conf"

mkdir -p "$LOCAL"

# 1) مزامنة أولية من السحابة إلى المحلي (تجلب آخر نسخة)
rclone sync "$REMOTE" "$LOCAL" \
  --config "$RCLONE_CFG" --fast-list --transfers 8 --checkers 16 --checksum --progress || true

# 2) تشغيل الخدمات (لو ما كانت شغالة)
docker compose -f /workspace/vast-llm-stack/docker-compose.yml up -d

echo "✅ Initial pull done. Starting continuous two-way sync (bisync)..."

# 3) مزامنة ثنائية الاتجاه متكررة
# أول مرة نحتاج --resync لبناء حالة المزامنة. بعد ذلك نفس الأمر بدون --resync.
# سنحاول مرة بـ --resync، وإن نجحت ننتقل للدوري بدونها.
if rclone bisync "$LOCAL" "$REMOTE" \
  --config "$RCLONE_CFG" \
  --create-empty-src-dirs --check-access --conflict-resolve newer \
  --filters-file "" --verbose --progress --resync; then
  echo "✅ Bisync initialized."
fi

# حلقة مزامنة كل 15 ثانية (اتجاهين) — خفيفة وسريعة لأنها ترفع/تنزل التغييرات فقط
while true; do
  rclone bisync "$LOCAL" "$REMOTE" \
    --config "$RCLONE_CFG" \
    --create-empty-src-dirs --check-access --conflict-resolve newer \
    --verbose --progress || true
  sleep 15
done
