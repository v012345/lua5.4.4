const { createApp, ref } = Vue
createApp({
    setup() {
        const message = ref('Top level function!')
        return {
            message
        }
    }
}).mount('#app')

axios.get('./h5.json')
    .then(res => console.log(res.data))
    .catch(err => console.log(err))
