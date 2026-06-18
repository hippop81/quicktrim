# Quick Trim

DaVinci Resolve に渡す**前**の粗編集（不要部分の削除・無音区間の選別・粗つなぎ）を高速化する、
ブラウザ完結の補助ツール。DaVinci の代替ではない。

## プロダクト原則（実装時の判断基準）

優先順位は **1) 編集時間短縮 → 2) 操作回数削減 → 3) 安定動作**。
「高機能」よりも「30分の粗編集を10分で終わらせる」ことを重視する。機能追加は優先しない。
テロップ・BGM・カラグレ・本格編集は DaVinci 側の役割で、本ツールのスコープ外。

## 構成

- `claude_quicktrim.html` … 本流（main）のアプリ本体。単一HTMLファイル（依存パッケージ・ビルド不要）。
  動画読み込み → タイムライン → 分割/区間削除 → 無音検出＋レビュー → 書き出し。
- `start_quicktrim.command` … macOS用ランチャー。ダブルクリックで `python3 -m http.server 8765`
  を起動し `http://localhost:8765/claude_quicktrim.html` を開く。
- 動画書き出しは **FFmpeg.wasm**（CDN: unpkg）を実行時に読み込む方式。

## Cursor Cloud specific instructions

- **依存ゼロの静的アプリ**。パッケージマネージャ・ビルド・自動テストは無い。唯一の実行要件は
  静的配信用の Python 3 と Chromium 系ブラウザ。テストは基本ブラウザ手動。
- **起動**：`python3 -m http.server 8765` → `http://localhost:8765/claude_quicktrim.html`。
  `start_quicktrim.command` が macOS でこれを自動化（ポート `8765`）。
- **必ず `http://` で配信し、`file://` で直接開かないこと。** ブラウザが `file://` では
  `<input type=file>` のメディアデコードや `AudioContext.decodeAudioData`（無音検出の核）を
  制限するため。ランチャーが存在する理由はこれ。
- **無音検出**は Web Audio の `decodeAudioData` で音声をデコードしてRMS解析するため、入力は
  Chrome がデコードできる形式（mp4 H.264/AAC, webm 等）である必要がある。古いコンデジの
  Motion JPEG AVI 等はデコードできず無音検出が使えない場合がある。
- **動画書き出し（FFmpeg.wasm）は外部CDN（unpkg）への通信が必要**。オフラインや外部通信が
  塞がれた環境では「この内容で書き出す」は失敗しうる。書き出しの自動テストはCDN依存のため
  不安定。判断結果の確認には CDN 不要の **EDL(JSON) 書き出し**を使うのが手軽。
- **無音候補レビュー**：検出後に「無音候補 N/総数」を1件ずつ確認。前へ/次へ/試聴/採用して削除/
  スキップ（キーボード: ← → / Space / Enter / X）。候補を選ぶと再生ヘッドが「前余白」分だけ手前へ
  移動し、タイムライン上で当該区間を強調表示する。**採用した候補だけが削除対象**になり、自動削除は
  しない。採用は「削除区間リスト」の✕、または再度「採用を取り消す」/スキップで取り消せる。
- ブラウザ自動テスト用にサンプル動画が必要なときは ffmpeg で生成できる（無音ギャップ入り）：
  `ffmpeg -f lavfi -i "testsrc2=size=640x360:rate=30:duration=20" -f lavfi -i "aevalsrc='0.4*sin(2*PI*440*t)*lt(mod(t,2),1)':d=20" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest sample_silence.mp4`
  ネイティブのファイル選択ダイアログを避けたい場合は、一時的な自動読込フックを足してから外すこと
  （サンプル動画や一時フックはコミットしない）。
