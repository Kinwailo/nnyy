const String html = r"""<!DOCTYPE html>
<html>

<head>
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <style type="text/css" rel="stylesheet">
        body {
            margin: 0px;
            width: 100%;
            height: 100%;
            overflow: hidden;
        }

        #container,
        #video {
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            border: 0;
            width: 100%;
            height: 100%;
        }

        #controls {
            display: none;
            position: fixed;
            bottom: 0px;
            left: 0px;
            right: 0px;
            padding: 12px 8px 0px 8px;
            opacity: 0.0;
            transition: opacity 0.5s;
            background-image: linear-gradient(#0000, #000c);
            -webkit-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        #controls:hover {
            opacity: 0.8;
        }

        #controls div {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 14px;
        }

        .button-bar {
            width: 100%;
            height: 26px;
        }

        .button-bar>* {
            color: #fff;
        }

        .button-bar>div {
            float: left;
            margin: 0px 4px;
            padding: 5px 0px;
        }

        .button-bar>button {
            float: left;
            cursor: pointer;
            padding: 4px;
            border: none;
            border-radius: 50%;
            background-color: inherit;
            transition: opacity 0s;
        }

        .button-bar #speed {
            padding: 4px 8px;
            border-radius: 16px !important;
        }

        .button-bar button:hover {
            background-color: #888 !important;
        }

        .button-bar button:active {
            opacity: 0.5;
        }

        .button-bar .right {
            float: right !important;
        }

        .button-bar .material-icons {
            vertical-align: -14%;
            font-size: 18px !important;
        }

        #progress {
            position: relative;
            cursor: pointer;
            margin: 0px 8px;
            width: calc(100% - 16px);
            height: 16px;
        }

        #volume {
            position: relative;
            cursor: pointer;
            width: 60px;
            height: 16px;
        }

        .tooltip {
            position: relative;
        }

        .tooltip .tooltiptext {
            position: absolute;
            cursor: default;
            visibility: hidden;
            padding: 4px;
            left: 0%;
            bottom: 116%;
            width: fit-content;
            background-color: #0008;
            color: #fff;
            text-align: center;
            border-radius: 4px;
            z-index: 1;
        }

        .tooltip:hover .tooltiptext {
            visibility: visible;
        }

        .progress {
            position: absolute;
            margin-top: 6px;
            margin-bottom: 6px;
            width: 100%;
            height: 4px;
            border-radius: 4px;
        }

        .progress.bg {
            color: #000;
            background-color: #808080;
            box-shadow: 0 2px 5px #0004 inset;
        }

        .progress.buffer {
            opacity: 0.5;
            color: #000;
            background-color: #fffcd6;
        }

        .progress.value {
            color: #000;
            background-color: #f8e80a;
        }

        #loading {
            visibility: hidden;
            position: absolute;
            left: 50%;
            top: 50%;
            margin: -24px 0 0 -24px;
            z-index: 1;
            width: 48px;
            height: 48px;
            border: 5px solid #FFF;
            border-bottom-color: transparent;
            border-radius: 50%;
            display: inline-block;
            box-sizing: border-box;
            animation: rotation 1s linear infinite;
        }

        @keyframes rotation {
            0% {
                transform: rotate(0deg);
            }

            100% {
                transform: rotate(360deg);
            }
        }
    </style>
</head>

<body>
    <div id="container" oncontextmenu="return false;">
        <video id="video" controls preload></video>
        <span id="loading"></span>
        <div id="controls">
            <div class="button-bar">
                <button id="play">
                    <i class="material-icons">play_arrow</i>
                </button>
                <button id="pause" style="display:none">
                    <i class="material-icons">pause</i>
                </button>
                <div></div>
                <button id="previous">
                    <i class="material-icons">skip_previous</i>
                </button>
                <button id="rewind">
                    <i class="material-icons">fast_rewind</i>
                </button>
                <button id="forward">
                    <i class="material-icons">fast_forward</i>
                </button>
                <button id="next">
                    <i class="material-icons">skip_next</i>
                </button>
                <div></div>
                <div id="time"></div>
                <button id="fullscreen_exit" class="right">
                    <i class="material-icons">fullscreen</i>
                </button>
                <button id="fullscreen" class="right" style="display:none">
                    <i class="material-icons">fullscreen_exit</i>
                </button>
                <button id="save_image" class="right">
                    <i class="material-icons">camera_alt</i>
                </button>
                <button id="mute" class="tooltip right">
                    <div class="tooltiptext"></div>
                    <i class="material-icons">volume_up</i>
                </button>
                <button id="unmute" class="right" style="display:none">
                    <i class="material-icons">volume_mute</i>
                </button>
                <div id="volume" class="tooltip right">
                    <div class="tooltiptext" style="bottom:100%"></div>
                    <div class="progress bg"></div>
                    <div class="progress value" style="width:0%"></div>
                </div>
                <div class="right"></div>
                <button id="speed_up" class="right">
                    <i class="material-icons">add</i>
                </button>
                <button id="speed" class="right">
                    <div></div>
                </button>
                <button id="speed_down" class="right">
                    <i class="material-icons">remove</i>
                </button>
            </div>
            <div id="progress" class="tooltip">
                <div class="tooltiptext"></div>
                <div class="progress bg"></div>
                <div class="progress buffer" style="width:0%"></div>
                <div class="progress value" style="width:0%"></div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@1"></script>
    <script type="text/javascript">
        const hls = new Hls();
        const video = document.getElementById("video");
        const container = document.getElementById("container");

        hls.on(Hls.Events.ERROR, function (event, data) {
            // console.log("on hls error", event, data, data.details);
            if (data.fatal) { dartCallback("error"); }
        });

        var filename = "image";
        var time = 0;
        var length = 0;
        var lastSpeed = 1.0;
        video.controls = false;

        video.onplay = (e) => dartCallback("play");
        video.onpause = (e) => dartCallback("pause");
        video.onended = (e) => dartCallback("ended");
        video.onwaiting = (e) => document.getElementById("loading").style.visibility = "visible";
        video.onplaying = (e) => document.getElementById("loading").style.visibility = "hidden";
        video.onvolumechange = (e) => {
            updateVolume();
            dartCallback("volume:" + video.volume.toString());
        }
        video.onratechange = (e) => {
            updateSpeed();
            dartCallback("speed:" + video.playbackRate.toString());
        }
        video.ontimeupdate = (e) => {
            updateTime(Math.floor(video.currentTime));
        };
        video.onloadedmetadata = (e) => {
            document.getElementById("loading").style.visibility = "hidden";
            length = Math.floor(video.duration);
            updateTime(Math.floor(video.currentTime));
            updateVolume();
            updateSpeed();
            dartCallback("meta:" + length.toString());
        };
        video.onprogress = (e) => {
            var buffered = Math.floor(Math.max(...Array.from(video.buffered, (_, i) => video.buffered.end(i))));
            updateBuffered(buffered);
            dartCallback("buffered:" + buffered.toString());
        }

        container.onclick = (e) => playVideo();
        container.ondblclick = (e) => toggleFullscreen();
        document.onkeydown = (e) => dartCallback(`key:${e.code},${e.ctrlKey},${e.shiftKey},${e.altKey}`);

        setupButtonEvent("play", (e) => playVideo());
        setupButtonEvent("pause", (e) => playVideo());
        setupButtonEvent("previous", (e) => dartCallback("next:-1"));
        setupButtonEvent("next", (e) => dartCallback("next:1"));
        setupButtonEvent("rewind", (e) => offsetVideo(-2));
        setupButtonEvent("forward", (e) => offsetVideo(2));
        setupButtonEvent("speed_down", (e) => changeSpeed(video.playbackRate - 0.25));
        setupButtonEvent("speed", (e) => resetSpeed());
        setupButtonEvent("speed_up", (e) => changeSpeed(video.playbackRate + 0.25));
        setupButtonEvent("mute", (e) => muteVideo(!video.muted));
        setupButtonEvent("unmute", (e) => muteVideo(!video.muted));
        setupButtonEvent("save_image", (e) => saveImage());
        setupButtonEvent("fullscreen", (e) => toggleFullscreen());
        setupButtonEvent("fullscreen_exit", (e) => toggleFullscreen());

        function setupButtonEvent(id, onclick) {
            var element = document.getElementById(id);
            element.onclick = (e) => {
                onclick(e);
                e.stopPropagation();
            };
            element.ondblclick = (e) => e.stopPropagation();
        }

        setupProgressBar("progress", (v) => video.currentTime = v * video.duration, (v) => timeString(Math.trunc(v * video.duration)));
        setupProgressBar("volume", (v) => video.volume = v, (v) => `${Math.trunc(v * 100)}%`);

        function setupProgressBar(id, ondown, ontooltip) {
            var element = document.getElementById(id);
            element.onclick = (e) => e.stopPropagation();
            element.ondblclick = (e) => e.stopPropagation();
            element.onmousedown = (e) => {
                element.setAttribute("mousedown", true);
                ondown(getProgressBarValue(element, e.pageX));
            }
            element.onmousemove = (e) => {
                var value = getProgressBarValue(element, e.pageX);
                var tooltip = element.getElementsByClassName("tooltiptext")[0];
                tooltip.textContent = ontooltip(value);
                var width = parseFloat(getComputedStyle(tooltip).getPropertyValue("width"));
                width += 8;
                tooltip.style.left = `${value * 100}%`;
                tooltip.style.marginLeft = `-${width / 2 + width * (value - 0.5)}px`;
                if (element.hasAttribute("mousedown"))
                    ondown(value);
            }
            element.onmouseup = (e) => element.removeAttribute("mousedown");
            element.onmouseleave = (e) => element.removeAttribute("mousedown");
        }

        function getProgressBarValue(element, x) {
            const rect = element.getBoundingClientRect();
            return pos = (x - rect.left) / (element.offsetWidth - 1);
        }

        document.onfullscreenchange = (e) => {
            var fullscreen = !!document.fullscreenElement;
            document.getElementById("controls").style.display = fullscreen ? "block" : "none";
            document.getElementById("fullscreen_exit").style.display = !fullscreen ? "block" : "none";
            document.getElementById("fullscreen").style.display = fullscreen ? "block" : "none";
            updateMute();
            dartCallback("fullscreen:" + fullscreen.toString());
        };

        function offsetVideo(offset) { video.currentTime += offset; }
        function changeVolume(volume) { video.volume = Math.min(Math.max(volume, 0.0), 1.00); }
        function changeSpeed(speed) { video.playbackRate = Math.min(Math.max(speed, 0.25), 3.00); }

        function loadVideo(src) {
            document.getElementById("loading").style.visibility = "visible";
            src = decodeURIComponent(src);
            time = 0;
            length = 0;
            hls.loadSource(src);
            hls.attachMedia(video);
        }

        function playVideo() {
            var play = video.paused || video.ended;
            play ? video.play() : video.pause();
            document.getElementById("play").style.display = !play ? "block" : "none";
            document.getElementById("pause").style.display = play ? "block" : "none";
        }

        function seekVideo(seek) {
            var seek = parseFloat(seek);
            video.currentTime = seek;
            updateTime(Math.floor(seek));
        }

        function updateMute() {
            var tooltip = document.getElementById("mute").getElementsByClassName("tooltiptext")[0];
            tooltip.textContent = `${Math.trunc(video.volume * 100)}%`;
            var width = parseFloat(getComputedStyle(tooltip).getPropertyValue("width"));
            width += 8;
            tooltip.style.left = "50%";
            tooltip.style.marginLeft = `-${width / 2}px`;
        }

        function updateVolume() {
            var progress = document.getElementById("volume").getElementsByClassName("value")[0];
            progress.style.width = `${video.volume * 100}%`;
            updateMute();
        }

        function updateBuffered(buffered) {
            var progress = document.getElementById("progress").getElementsByClassName("buffer")[0];
            progress.style.width = `${buffered * 100 / length}%`;
        }

        function updateTime(currentTime) {
            if (time != currentTime) {
                time = currentTime;
                document.getElementById("time").textContent = `${timeString(time)} / ${timeString(length)}`;
                var progress = document.getElementById("progress").getElementsByClassName("value")[0];
                progress.style.width = `${time * 100 / length}%`;
                dartCallback(`current:${time.toString()},${length.toString()}`);
            }
        }

        function resetSpeed() {
            if (video.playbackRate == 1.0) {
                video.playbackRate = lastSpeed;
            }
            else {
                lastSpeed = video.playbackRate;
                video.playbackRate = 1.0;
            }
        }

        function updateSpeed() {
            var speed = document.getElementById("speed").getElementsByTagName("div")[0];
            speed.textContent = `${video.playbackRate.toFixed(2)}x`;
        }

        function timeString(time) {
            var min = Math.trunc(time / 60);
            var hr = Math.trunc(min / 60);
            var hrText = hr > 0 ? `${hr}:` : "";
            min %= 60;
            var minText = min < 10 ? `0${min}` : `${min}`;
            var sec = time % 60;
            var secText = sec < 10 ? `0${sec}` : `${sec}`;
            return `${hrText}${minText}:${secText}`;
        }

        function muteVideo(mute) {
            video.muted = mute;
            document.getElementById("mute").style.display = !mute ? "block" : "none";
            document.getElementById("unmute").style.display = mute ? "block" : "none";
            dartCallback("mute:" + mute.toString());
        }

        function toggleFullscreen() {
            if (!document?.fullscreenEnabled) return;
            var fullscreen = !!document.fullscreenElement;
            fullscreen ? document.exitFullscreen() : container.requestFullscreen();
            container.setAttribute("data-fullscreen", !fullscreen);
        }

        function setFilename(name) {
            filename = name;
        }

        function saveImage() {
            var canvas = document.createElement("canvas");
            var context = canvas.getContext("2d");
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            context.drawImage(video, 0, 0, canvas.width, canvas.height);
            var a = document.createElement("a");
            a.href = canvas.toDataURL();
            a.download = `${filename}-${timeString(time)}.png`;
            a.click();
        }
    </script>
</body>

</html>""";
