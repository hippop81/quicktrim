#!/bin/bash
# Quick Trim launcher for macOS.
# Double-click this file in Finder to start a local web server and open the app.
# (file:// cannot be used because browsers restrict media / AudioContext features there.)

# Move to the folder that contains this script so the server serves the app files.
cd "$(dirname "$0")" || exit 1

PORT=8765
PAGE="claude_quicktrim.html"
URL="http://localhost:${PORT}/${PAGE}"

# Pick an available Python 3 interpreter.
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python 3 が見つかりません。https://www.python.org/ からインストールしてください。"
  read -r -p "Enterキーで終了します..." _
  exit 1
fi

echo "Quick Trim を起動します..."
echo "サーバー: ${URL}"
echo "（このウィンドウを閉じるとサーバーが停止します）"

# Start the static file server in the background.
"$PY" -m http.server "$PORT" >/dev/null 2>&1 &
SERVER_PID=$!

# Make sure the server is stopped when this window/script exits.
cleanup() {
  echo ""
  echo "サーバーを停止します (pid ${SERVER_PID})..."
  kill "$SERVER_PID" >/dev/null 2>&1
}
trap cleanup EXIT INT TERM

# Give the server a moment to come up, then open the app in the default browser.
sleep 1
if command -v open >/dev/null 2>&1; then
  open "$URL"
else
  echo "ブラウザで次のURLを開いてください: ${URL}"
fi

# Keep the server running in the foreground until the user closes the window
# or presses Ctrl-C.
wait "$SERVER_PID"
