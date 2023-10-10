function GUID() {
    Math.random()
    let id = "";
    for (let i = 0; i < 2; i++) {
        let rand = Math.floor(Math.random() * 1000000)
        id += rand
        id += "-"
    }
    id += Math.floor(Math.random() * 1000000)
    return id
}