let Tetris = {
    id: "Tetris",
    lastUpdateAt: 0,
    canvas: null,
    context: null,
    speed: 3,
    max: 6,
    Tetromino: {
        "I": [
            [[1], [1], [1], [1]],
            [[1, 1, 1, 1]],
            [[1], [1], [1], [1]],
            [[1, 1, 1, 1]],
        ],
        "L": [[[2, 0], [2, 0], [2, 2]], [[2, 2, 2], [2, 0, 0]], [[2, 2], [0, 2], [0, 2]], [[0, 0, 2], [2, 2, 2]]],
        "J": [],
        "O": [[[4, 4], [4, 4]], [[4, 4], [4, 4]], [[4, 4], [4, 4]], [[4, 4], [4, 4]]],
        "S": [],
        "T": [],
        "Z": [],
    },
    current: {
        type: "L",
        direction: 3,
        // 0 <= x <= 9 , -1 <= y <= 19
        position: {
            x: 5,
            y: -1
        },
        displacement: 0,
    },
    correctPosition: (current) => {
        let currentTetromino = Tetris.Tetromino[current.type][current.direction]
        if (current.position.x + currentTetromino[0].length > 10) {
            current.position.x = 10 - currentTetromino[0].length
        }
        if (current.position.y > 19) {
            current.position.y = 19
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
                if (row_number == 0) {
                    Tetris.context.font = '18px serif';
                    Tetris.context.fillStyle = 'black';
                    Tetris.context.fillText(column_number, column_number * 30 + 8, 20);
                }
            })
            Tetris.context.font = '18px serif';
            Tetris.context.fillStyle = 'black';
            Tetris.context.fillText(row_number, 8, row_number * 30 + 20);
        })
        let currentTetromino = Tetris.Tetromino[Tetris.current.type][Tetris.current.direction]
        Tetris.current.displacement += delta * Tetris.speed
        if (Tetris.current.displacement >= 1000) {
            Tetris.current.displacement = 0
            Tetris.current.position.y += 1
        }
        Tetris.correctPosition(Tetris.current)
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