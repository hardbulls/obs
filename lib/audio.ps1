
function List-AudioDevices {
    Write-Host "Available DirectShow Devices:"
    & $ffmpegExe -list_devices true -f dshow -i dummy 2>&1 | ForEach-Object {
        Write-Host $_
    }
}
