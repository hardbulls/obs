function Ensure-FFmpegInstalled {
    if (-not (Test-Path $ffmpegExe)) {
        Write-Host "FFmpeg not found at $ffmpegExe"
        Write-Host "Downloading FFmpeg..."

        # Define paths
        $ffmpegZipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        $zipPath = Join-Path $PSScriptRoot '..\..\ffmpeg.zip'
        $extractPath = Join-Path $PSScriptRoot '..\..\ffmpeg_tmp'
        $targetDir = $ffmpegDir

        # Download the FFmpeg zip file
        Invoke-WebRequest -Uri $ffmpegZipUrl -OutFile $zipPath

        # Extract the zip file
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Locate the extracted folder containing ffmpeg.exe
        $subfolder = Get-ChildItem $extractPath | Where-Object {
            $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName 'bin\ffmpeg.exe'))
        } | Select-Object -First 1

        if ($null -eq $subfolder) {
            Write-Host "Could not locate ffmpeg.exe after extraction."
            exit
        }

        # Move the contents to the target directory
        Move-Item -Path $subfolder.FullName -Destination $targetDir

        # Clean up the temporary extraction directory
        Remove-Item -Recurse -Force $extractPath

        # Update the ffmpegExe path
        $ffmpegExe = Join-Path $targetDir 'bin\ffmpeg.exe'

        if (-not (Test-Path $ffmpegExe)) {
            Write-Host "ffmpeg.exe not found in expected location."
            exit
        }

        # Clean up any existing directories
        if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }
        if (Test-Path $targetDir) { Remove-Item -Recurse -Force $targetDir }
        Remove-Item -Path $zipPath

        Write-Host "FFmpeg installed at $ffmpegExe"
    }
}
