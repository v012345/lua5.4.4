const { createApp, ref } = Vue
axios.get('./h5.json')
    .then(res => console.log(res.data))
    .catch(err => console.log(err))
createApp({
    setup() {
        const message = ref('Top level function!')
        return {
            message
        }
    }
}).mount('#app')


