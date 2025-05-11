param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("list", "stream", "test-stream", IgnoreCase = $true)]
    [string]$Mode,

    [string]$RtspUrl,

    [string]$SrtUrl
)

# === Entry Script ===
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\dependencies\ffmpeg.ps1"
. "$PSScriptRoot\audio.ps1"
. "$PSScriptRoot\filesystem.ps1"
. "$PSScriptRoot\stream.ps1"
. "$PSScriptRoot\rtsp-test.ps1"

Ensure-FFmpegInstalled

switch ($Mode) {
    "list" {
        List-AudioDevices
        exit
    }
    "stream" {
        if (-not $RtspUrl) {
            Write-Host "Missing RTSP URL. Use -RtspUrl argument."
            exit 1
        }
        Start-Stream -RtspUrl $RtspUrl -SrtUrl $SrtUrl
    }
    "test-stream" {
        # $job = Start-Job -ScriptBlock {
            Rtsp-Test
        # }
        # Write-Host "Rtsp-Test job started in the background with ID: $($job.Id)"
        # Start-Stream -RtspUrl $testRtsp -SrtUrl $SrtUrl
    }
    default {
        Write-Host "Unknown mode: $Mode"
        exit 1
    }
}
