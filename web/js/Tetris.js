let Tetris = {
    id: "Tetris",
    lastUpdateAt: 0,
    canvas: null,
    context: null,
    speed: 0.5,
    max: 6,
    Tetromino: {
        "I": [
            [[1], [1], [1], [1]],
            [[1, 1, 1, 1]],
            [[1], [1], [1], [1]],
            [[1, 1, 1, 1]],
        ],
        "L": [],
        "J": [],
        "O": [[[4, 4], [4, 4]], [[4, 4], [4, 4]], [[4, 4], [4, 4]], [[4, 4], [4, 4]]],
        "S": [],
        "T": [],
        "Z": [],
    },
    current: {
        type: "O",
        direction: 0,
        // 0 <= x <= 9 , 0 <= y <= 19
        position: {
            x: 8,
            y: 19
        }
    },
    correctPosition: (current) => {
        let currentTetromino = Tetris.Tetromino[current.type][current.direction]
        if (current.position.x + currentTetromino[0].length > 10) {
            current.position.x = 10 - currentTetromino[0].length
        }
    },
    start: () => {
        console.log("start")
        Tetris.canvas = document.getElementById("ground");
        if (Tetris.canvas) {
            Tetris.context = Tetris.canvas.getContext("2d");
        }
        for (let i = 0; i < 20; i++) {
            Tetris.ground.push([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        }
    },
    update: (delta) => {
        Tetris.context.fillStyle = "rgb(255,255,255)";
        Tetris.context.fillRect(0, 0, 300, 600);
        // let x = Math.floor(Math.random() * 10) * 30
        // let y = Math.floor(Math.random() * 20) * 30
        Tetris.ground.forEach((row, row_number) => {
            row.forEach((column, column_number) => {
                if (column > 0) {
                    Tetris.context.fillStyle = Tetris.color[column];
                    let x = column_number * 30
                    let y = row_number * 30
                    Tetris.context.fillRect(x, y, 30, 30);
                    Tetris.context.beginPath();
                    Tetris.context.moveTo(x, y);
                    Tetris.context.lineTo(x + 30, y);
                    Tetris.context.lineTo(x + 30, y + 30);
                    Tetris.context.lineTo(x, y + 30);
                    Tetris.context.lineTo(x, y);
                    // // set strokecolor
                    // ctx.strokeStyle = stroke;
                    // // set lineWidht 
                    // ctx.lineWidth = width;
                    Tetris.context.stroke();

                }
            })
        })
        Tetris.correctPosition(Tetris.current)
        let currentTetromino = Tetris.Tetromino[Tetris.current.type][Tetris.current.direction]
        currentTetromino.forEach((row, row_number) => {
            row.forEach((column, column_number) => {
                // console.log(row_number, column_number)
                Tetris.context.fillStyle = Tetris.color[column];
                if (column > 0) {
                    let vx = (column_number + Tetris.current.position.x)
                    let x = vx * 30
                    let vy = (Tetris.current.position.y - row_number)
                    let y = vy * 30
                    Tetris.context.fillRect(x, y, 30, 30);
                    Tetris.context.beginPath();
                    Tetris.context.moveTo(x, y);
                    Tetris.context.lineTo(x + 30, y);
                    Tetris.context.lineTo(x + 30, y + 30);
                    Tetris.context.lineTo(x, y + 30);
                    Tetris.context.lineTo(x, y);
                    // // set strokecolor
                    // ctx.strokeStyle = stroke;
                    // // set lineWidht 
                    // ctx.lineWidth = width;
                    Tetris.context.stroke();
                }

            })
        })
    },
    destroy: () => {
        console.log("destroy")
    },
    color: [
        "rgb(255,255,255)",
        "rgb(0, 240, 240)",
        "rgb(0, 0, 240)",
        "rgb(240, 160, 0)",
        "rgb(240, 240, 0)",
        "rgb(0, 240, 0)",
        "rgb(160, 0, 240)",
        "rgb(240, 0, 0)",
    ],
    ground: [],
}
Owl.register(Tetris)
// return Tetris