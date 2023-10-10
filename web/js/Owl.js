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

    }
}
Owl.fire(1000)
