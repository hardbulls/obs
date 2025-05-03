# === CONFIGURATION ===
$audioDelay = 5
$leftGain   = 0.5
$rightGain  = 0.5
$rtspUrl    = "rtsp://xxx:xxxx!@192.168.0.124:554/h265Preview_01_main"
$srtUrl     = "srt://127.0.0.1:1234?pkt_size=1316"
$ffmpegDir  = "$PSScriptRoot\ffmpeg"
$audioDeviceName = "Analogue 1 + 2 (Focusrite USB Audio)"  # Set your real device name here
$enableAudio = $false  # Set to $false to disable audio completely


# === Detect platform ===
$IsWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$ffmpegExe = if ($IsWindows) { "$ffmpegDir\bin\ffmpeg.exe" } else { "ffmpeg" }

# === Ensure FFmpeg exists or install it (Windows only) ===
if ($IsWindows -and -Not (Test-Path $ffmpegExe)) {
    Write-Host "FFmpeg not found at $ffmpegExe"
    Write-Host "Downloading FFmpeg..."

    $ffmpegZipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $zipPath = "$PSScriptRoot\ffmpeg.zip"

    Invoke-WebRequest -Uri $ffmpegZipUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $ffmpegDir -Force
    Remove-Item -Path $zipPath

    $subfolder = Get-ChildItem $ffmpegDir | Where-Object { $_.PSIsContainer -and (Test-Path "$($_.FullName)\bin\ffmpeg.exe") } | Select-Object -First 1
    if ($null -eq $subfolder) {
        Write-Host "Could not locate ffmpeg.exe after extraction."
        exit
    }

    $ffmpegExe = "$($subfolder.FullName)\bin\ffmpeg.exe"
    Write-Host "FFmpeg installed at $ffmpegExe"
}

# === List audio devices if "list" is passed ===
if ($args.Count -gt 0 -and $args[0].ToLower() -eq "list") {
    if ($IsWindows) {
        Write-Host "Available DirectShow Devices:`n"
        & $ffmpegExe -list_devices true -f dshow -i dummy 2>&1 | ForEach-Object {
            Write-Host $_
        }
    } else {
        Write-Host "Available ALSA Devices:`n"
        & $ffmpegExe -f alsa -i hw:0,0 -t 1 2>&1 | ForEach-Object {
            if ($_ -match "Input device" -or $_ -match "audio") {
                Write-Host $_
            }
        }
    }
    exit
}

# === Confirm config ===
Write-Host "Launching stream with:"
Write-Host "  Video: $rtspUrl"
Write-Host "  Audio: $audioDeviceName"
Write-Host "  Delay: ${audioDelay}s"
Write-Host "  Output: $srtUrl"

# === Build pan filter for mono mix ===
$panFilter = "pan=mono|c0=${leftGain}*c0+${rightGain}*c1"

# === Start streaming ===
if ($IsWindows) {
    $ffmpegArgs = @()

    if ($enableAudio) {
        $ffmpegArgs += @(
            "-itsoffset", "$audioDelay",
            "-f", "dshow",
            "-i", "audio=$audioDeviceName"
        )
    }

    $ffmpegArgs += @(
        "-rtsp_transport", "tcp",
        "-fflags", "nobuffer",
        "-i", "$rtspUrl",
        "-map", "0:v:0"
    )

    if ($enableAudio) {
        $ffmpegArgs += @(
            "-map", "1:a:0",
            "-af", "$panFilter",   # Mix to mono
            "-c:a", "aac",
            "-b:a", "128k"
        )
    }

    $ffmpegArgs += @(
        "-c:v", "copy",  # No video re-encoding
        # Optional hardware encoder: "-c:v", "hevc_qsv"
        "-f", "mpegts",
        "$srtUrl"
    )
}


while ($true) {
    Write-Host "`n[INFO] Starting FFmpeg process..."
    & $ffmpegExe @ffmpegArgs

    $exitCode = $LASTEXITCODE
    Write-Host "[WARN] FFmpeg exited with code $exitCode at $(Get-Date). Restarting in 5 seconds..."

    Start-Sleep -Seconds 5
}
