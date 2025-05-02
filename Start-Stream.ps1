# === CONFIGURATION ===
$audioDelay = 0.5
$rtspUrl    = "rtsp://xxx:xxx!@192.168.0.124:554/h265Preview_01_main"
$srtUrl     = "srt://127.0.0.1:1234?pkt_size=1316"
$ffmpegDir  = "$PSScriptRoot/ffmpeg"
$leftGain   = 0.5

# === Detect platform ===
$ffmpegExe = if ($IsWindow) { "$ffmpegDir/bin/ffmpeg.exe" } else { "ffmpeg" }

# === Ensure FFmpeg exists or install it (Windows only) ===
if ($IsWindow -and -Not (Test-Path $ffmpegExe)) {
    Write-Host "⚠️  FFmpeg not found at $ffmpegExe"
    Write-Host "⬇️  Downloading FFmpeg..."

    $ffmpegZipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $zipPath = "$PSScriptRoot/ffmpeg.zip"

    Invoke-WebRequest -Uri $ffmpegZipUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $ffmpegDir -Force
    Remove-Item -Path $zipPath

    $subfolder = Get-ChildItem $ffmpegDir | Where-Object { $_.PSIsContainer -and (Test-Path "$($_.FullName)/bin/ffmpeg.exe") } | Select-Object -First 1
    if ($null -eq $subfolder) {
        Write-Host "❌ Could not locate ffmpeg.exe after extraction."
        exit
    }

    $ffmpegExe = "$($subfolder.FullName)/bin/ffmpeg.exe"
    Write-Host "✅ FFmpeg installed at $ffmpegExe"
}

# === List available audio devices ===
if ($IsWindows) {
    # Windows-specific: List DirectShow devices
    Write-Host "`n🔍 Scanning for available DirectShow input devices..."
    & $ffmpegExe -f dshow -list_devices true -i dummy 2>&1 | ForEach-Object {
        if ($_ -match 'Alternative name "audio=') {
            Write-Host $_
        }
    }

    # Prompt for audio device on Windows
    Write-Host "`n✏️  Enter the **exact** audio device name as shown (without quotes):"
    $audioDeviceName = Read-Host "Audio Device Name"
} else {
    # Linux-specific: List ALSA devices
    Write-Host "`n🔍 Scanning for available ALSA input devices..."
    & $ffmpegExe -f alsa -i hw:0,0 -t 1 2>&1 | ForEach-Object {
        if ($_ -match 'Input device' -or $_ -match 'audio') {
            Write-Host $_
        }
    }

    # Prompt for audio device on Linux
    Write-Host "`n✏️  Enter the **exact** ALSA audio device name as shown (e.g., hw:0,0, default):"
    $audioDeviceName = Read-Host "Audio Device Name"
}

# === Confirm config ===
Write-Host "`n🎬 Launching stream with:"
Write-Host "  ▶ Video: $rtspUrl"
Write-Host "  ▶ Audio: $audioDeviceName"
Write-Host "  ▶ Delay: ${audioDelay}s"
Write-Host "  ▶ Output: $srtUrl`n"

# === Build pan filter for mono mix ===
$panFilter = "pan=mono|c0=${leftGain}*c0+${rightGain}*c1"

# === Start streaming ===
if ($IsWindow) {
    & $ffmpegExe `
        -itsoffset $audioDelay `
        -f dshow -i "audio=$audioDeviceName" `
        -i "$rtspUrl" `
        -map 1:v:0 -map 0:a:0 `
        -af $panFilter `
        -c:v libx264 -preset ultrafast -tune zerolatency `
        -c:a aac -b:a 128k `
        -f mpegts "$srtUrl"
} else {
    & $ffmpegExe `
        -itsoffset $audioDelay `
        -f alsa -i "$audioDeviceName" `
        -i "$rtspUrl" `
        -map 1:v:0 -map 0:a:0 `
        -af $panFilter `
        -c:v libx264 -preset ultrafast -tune zerolatency `
        -c:a aac -b:a 128k `
        -f mpegts "$srtUrl"
}

