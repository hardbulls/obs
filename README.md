# obs
OBS Studio assets and settings for live streams


# Plugins

## obs-gstreamer

* https://github.com/fzwoch/obs-gstreamer
* https://obsproject.com/forum/threads/rtsp-stream-from-ip-camera-delay-in-input-in-preview.112518/page-4

## obs-multi-rtmp

* https://github.com/sorayuki/obs-multi-rtmp


## obs-browser-transition

* https://github.com/exeldro/obs-browser-transition

# IP Cameras in OBS

URI: `rtsp://(user):(password)@(ip):554/h265Preview_01_main`

Gstreamer pipeline rtspsrc (best for low latency): `rtspsrc location="(rtsp uri)" latency=0 buffer-mode=auto ! rtph265depay ! h265parse ! avdec_h265  ! video.`

Gstreamer pipeline auto: `uridecodebin uri=(rtsp uri) ! queue ! video.`

Set camera Bitrate lower to avoid latency

Uncheck all Gstreamer Source options. Only set the pipeline.
