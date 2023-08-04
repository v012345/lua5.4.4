const { createApp, ref } = Vue
axios.get('./lua.json')
    .then(res => console.log(res.data))
    .catch(err => console.log(err))
console.log(ElementPlus)
const app = createApp({
    setup() {
        const message = ref('Top level function!')
        return {
            message
        }
    }
})
app.use(ElementPlus)
app.mount('#app')


