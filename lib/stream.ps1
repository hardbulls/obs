
function Start-Stream {
    param (
        [string]$RtspUrl,
        [string]$SrtUrl
    )

    if (-not $RtspUrl) {
        Write-Host "Missing RTSP URL. Use -rtsp argument."
        exit 1
    }

    if (-not $SrtUrl) {
        Write-Host "Missing SRT URL. Use -srt argument."
        exit 1
    }

    Write-Host "Launching stream:"
    Write-Host "  Video: $RtspUrl"
    Write-Host "  Audio: $audioDeviceName"
    Write-Host "  Delay: ${audioDelay}s"
    Write-Host "  Output: $SrtUrl"

    $panFilter = "pan=mono|c0=${leftGain}*c0+${rightGain}*c1"

    $argsList = @()
    if ($enableAudio) {
        $argsList += @("-itsoffset", "$audioDelay", "-f", "dshow", "-i", "audio=$audioDeviceName")
    }

    $argsList += @("-rtsp_transport", "tcp", "-fflags", "nobuffer", "-i", "$RtspUrl", "-map", "0:v:0")

    if ($enableAudio) {
        $argsList += @("-map", "1:a:0", "-af", "$panFilter", "-c:a", "aac", "-b:a", "128k")
    }

    $argsList += @("-c:v", "copy", "-f", "mpegts", "$SrtUrl")

    while ($true) {
        Write-Host "`n[INFO] Starting FFmpeg process..."
        & $ffmpegExe @argsList
        $code = $LASTEXITCODE
        Write-Host "[WARN] FFmpeg exited with code $code at $(Get-Date). Restarting in 5 seconds..."
        Start-Sleep -Seconds 5
    }
}