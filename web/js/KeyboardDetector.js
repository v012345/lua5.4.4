Owl.KeyboardDetector = function () {
    document.onkeydown = function (k) {
        console.log("onkeydown " + k)
    }
    document.onkeyup = function (k) {
        console.log("onkeyup " + k)
    }
}
