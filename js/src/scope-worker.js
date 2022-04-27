'use strict'
console.log("hi from workder")
var canvas;
var ctxWorker;
var analyserL;

self.onmessage = function(e) {
    console.log(e)
    // canvas = e.data.canvas;
    // analyserL = e.data.analyserL;
    // ctxWorker = canvas.getContext("2d");
    // let bufferLength = analyserL.fftSize;
    // let dataArray = new Uint8Array(bufferLength);
    // ctxWorker.clearRect(0, 0, canvas.width, canvas.height);

    // start();
};

function start() {
  setInterval(function() {
    render();
  }, 1000/60);
}

function render() {

//   ctxWorker.clearRect(0, 0, canvas.width, canvas.height);
//   ctxWorker.font = "16px Verdana";
//   ctxWorker.textAlign = "center";
//   ctxWorker.fillText(
//     "Counting: " + 111,
//     canvas.width / 2,
//     canvas.height / 2
//   );
}