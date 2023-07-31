const { createApp, ref } = Vue

createApp({
    setup() {
        const message = ref('Top level function!')
        return {
            message
        }
    }
}).mount('#app')