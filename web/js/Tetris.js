let Tetris = {
    id: "Tetris",
    lastUpdateAt: 0,
    canvas: null,
    context: null,
    start: () => {
        console.log("start")
        Tetris.canvas = document.getElementById("ground");
        if (Tetris.canvas) {
            Tetris.context = Tetris.canvas.getContext("2d");
        }
    },
    update: (delta) => {
        // console.log(Tetris.id, delta)
        Tetris.context.fillStyle = "rgb(200,0,0)";
        Tetris.context.fillRect(0, 0, 30, 30);
    },
    destroy: () => {
        console.log("destroy")
    }
}
Owl.register(Tetris)
// return Tetris