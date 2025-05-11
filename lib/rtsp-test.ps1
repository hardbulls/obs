function Rtsp-Test {
    $inputFile = Join-Path $resourcesDir "\test.mp4"
    Write-Host "Attempting to serve RTSP stream from: $inputFile to $testRtsp"
    Write-Host "ffmpeg executable path: $ffmpegExe"

    if (-not (Test-Path -Path $inputFile -PathType Leaf)) {
        Write-Error "Error: Input file not found at '$inputFile'"
        return
    }
    if (-not (Test-Path -Path $ffmpegExe -PathType Leaf)) {
        Write-Error "Error: ffmpeg executable not found at '$ffmpegExe'"
        return
    }

    $argsList = @(
        "-re",
        "-stream_loop", "-1",
        "-an",
        "-i", "`"$inputFile`"",
        "-c:v", "copy",
        "-f", "rtsp",
        "$testRtsp"
    )

    Write-Host "Executing ffmpeg with arguments: $($argsList -join ' ')"
    & $ffmpegExe @argsList
}