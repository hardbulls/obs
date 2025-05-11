# === Static Config ===
$audioDelay = 5
$leftGain = 0.5
$rightGain = 0.5
$audioDeviceName = "Analogue 1 + 2 (Focusrite USB Audio)"
$enableAudio = $false
$ffmpegDir = Join-Path $PSScriptRoot "..\ffmpeg"
$ffmpegExe = Join-Path $ffmpegDir "bin\ffmpeg.exe"
$resourcesDir = Join-Path $PSScriptRoot "..\resources"
$testRtsp = "rtsp://127.0.0.1:8554/test"