// Create Owl
const Owl = {
    Entities: new Map(),
    register: (entity) => {
        entity.id = GUID()
        entity.lastUpdateAt = Date.now()
        entity.start()
        entity.update(0)
        Owl.Entities.set(entity.id, entity)
    },
    unregister: (entity) => {

    },
    fire: (fps) => {
        Owl.KeyboardDetector()
        fps = fps ? fps : 33
        setInterval(function () {
            Owl.Entities.forEach((entity) => {
                let lastUpdateAt = entity.lastUpdateAt
                let updateAt = Date.now()
                entity.lastUpdateAt = updateAt
                entity.update(updateAt - lastUpdateAt)
            });
        }, fps)
    },
    stop: () => {

    },
    loadKeyBoard: (keyBoard) => {

    },
    inputQueue: [],
    KeyboardDetector: () => {
        document.onkeydown = function (k) {
            Owl.inputQueue.push(k)
            // console.log("onkeydown " + k)
        }
        document.onkeyup = function (k) {
            Owl.inputQueue.push(k)
            // console.log("onkeyup " + k)
        }
    }
}
Owl.fire()
