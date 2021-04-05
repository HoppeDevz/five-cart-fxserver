const axios = require("axios");
const { server_identifier, client_domain, verify_timeout, api_protocol } = require("./config");
const { Wait } = require("./lib/utils");
const net_events = require("./net_events");

setTick(async () => {
    axios.default.get(
        `${api_protocol}://${client_domain}/v1/queue/${server_identifier}`
        /*"http://localhost:40120/fake"*/
    )
    .then(response => {
        const products = response.data.data;

        products.map(product => {
            const { id, type, user_id, argument, amount, temporary } = product;

            console.log(`Trigger ${net_events[type]}`);
            emit(net_events[type], user_id, argument, amount);
            emit("fxserver_events:user-notify", user_id, argument, amount, temporary);
            emit("fxserver_events:global_chat_message", user_id, argument, amount, temporary);

            // remove from list;
            axios.default.get(`${api_protocol}://${client_domain}/v1/execute/${server_identifier}?ids[]=${id}`);
        })
    })
    .catch(err => {
        throw err;
    })

    await Wait(verify_timeout);
});

async function start() {
    console.log(`
    _____                               __ 
    / __(_)   _____     _________ ______/ /_
   / /_/ / | / / _ \\   / ___/ __ / ___/ __/
  / __/ /| |/ /  __/  / /__/ /_/ / /  / /_  
 /_/ /_/ |___/\\___/   \\___/\\__,_/_/   \\__/ 
                                         
    `);
}

start();