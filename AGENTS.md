# Quick Trim

ブラウザだけで動く、無音検出つきの動画トリマー（静的サイト）。

## Cursor Cloud specific instructions

- This is a **dependency-free static web app**. The whole app is `quicktrim.html` (self-contained
  HTML + CSS + vanilla JS, no external CDNs, no build step, no package manager, no test suite).
  The only runtime requirement is Python 3 (used purely as a static file server) and a Chromium-based
  browser.
- **Run it** by serving the folder and opening the page over `http://`:
  `python3 -m http.server 8765` then open `http://localhost:8765/quicktrim.html`.
  `start_quicktrim.command` is the macOS double-click launcher that does exactly this (port `8765`).
- **Must be served over `http://`, never opened via `file://`.** Browsers block `<input type=file>`
  media decoding / `AudioContext.decodeAudioData` behavior needed for silence detection under
  `file://`, which is the whole reason the launcher exists.
- **Testing is manual in the browser** (no lint/unit tests exist). For automated browser testing the
  app exposes `window.__qt` (live editor state). During setup a temporary `?test=<video-url>`
  auto-load hook was added to `quicktrim.html` and removed before commit — re-add a similar hook if you
  need to bypass the native file picker, and serve a sample clip from the same directory. Do not commit
  sample media or the temp hook.
- Generate a quick test clip with silence gaps via ffmpeg, e.g.:
  `ffmpeg -f lavfi -i "testsrc2=size=640x360:rate=30:duration=20" -f lavfi -i "aevalsrc='0.4*sin(2*PI*440*t)*lt(mod(t,2),1)':d=20" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest sample_silence.mp4`
- **Silence detection** decodes audio with Web Audio `decodeAudioData`, so the input must be a format
  Chrome can decode (mp4/H.264+AAC or webm). **Export** uses `MediaRecorder` + `video.captureStream()`
  and re-plays the kept segments in real time, so exporting is roughly as long as the kept duration and
  outputs `webm` (VP9/Opus). `duration=N/A` in `ffprobe` for the exported webm is normal for
  MediaRecorder output and not a defect.
- Only candidates the user **採用 (adopt)** are added to the deletion set; detection never deletes
  automatically.
