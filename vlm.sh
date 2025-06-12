
#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <image_file> <instruction_text> [base_url]"
  exit 1
fi

IMAGE_FILE="$1"
INSTRUCTION="$2"
BASE_URL="${3:-http://localhost:8080}"

if [[ ! -f "$IMAGE_FILE" ]]; then
  echo "Image file '$IMAGE_FILE' does not exist."
  exit 1
fi

# 轉成 base64 並放到 temp file
TMPFILE=$(mktemp)
echo -n "data:image/jpeg;base64," > "$TMPFILE"
base64 -w 0 "$IMAGE_FILE" >> "$TMPFILE"

# 計算開始時間（毫秒）
START_TIME=$(date +%s%3N)

# 發送請求
jq -n --arg instruction "$INSTRUCTION" --rawfile img "$TMPFILE" '
{
  max_tokens: 100,
  messages: [
    {
      role: "user",
      content: [
        { type: "text", text: $instruction },
        { type: "image_url", image_url: { url: $img } }
      ]
    }
  ]
}
' | curl -s -X POST "$BASE_URL/v1/chat/completions" \
       -H "Content-Type: application/json" \
       -d @-

# 計算結束時間
END_TIME=$(date +%s%3N)
COST_MS=$((END_TIME - START_TIME))

echo -e "\n⏱️ Time cost: ${COST_MS} ms"

# 清理 temp file
rm "$TMPFILE"
