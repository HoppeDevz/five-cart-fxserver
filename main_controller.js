const axios = require("axios");
const { server_identifier, client_domain, verify_timeout } = require("./config");
const { Wait } = require("./lib/utils");
const net_events = require("./net_events");

setTick(async () => {
    axios.default.get(
        `http://${client_domain}/v1/queue/${server_identifier}`
        /*"http://localhost:40120/fake"*/
    )
    .then(response => {
        const products = response.data;

        products.map(product => {
            const { id, type, user_id, argument, amount, temporary } = product;

            console.log(`Trigger ${net_events[type]}`);
            emit(net_events[type], user_id, argument, amount);

            // remove from list;
            axios.get(`http://${client_domain}/v1/execute/${server_identifier}?ids[]=${id}`);
        })
    })
    .catch(err => {
        throw err;
    })

    await Wait(verify_timeout)
});