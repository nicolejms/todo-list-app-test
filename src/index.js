const express = require('express');
const app = express();
const db = require('./persistence');
const cache = require('./cache');
const getItems = require('./routes/getItems');
const addItem = require('./routes/addItem');
const updateItem = require('./routes/updateItem');
const deleteItem = require('./routes/deleteItem');

app.use(express.json());
app.use(express.static(__dirname + '/static'));

app.get('/items', getItems);
app.post('/items', addItem);
app.put('/items/:id', updateItem);
app.delete('/items/:id', deleteItem);

db.init()
    .then(() => cache.init().catch((err) => console.warn('Redis unavailable, running without cache:', err.message)))
    .then(() => {
        app.listen(3000, () => console.log('Listening on port 3000'));
    }).catch((err) => {
        console.error(err);
        process.exit(1);
    });

const gracefulShutdown = () => {
    Promise.all([db.teardown(), cache.teardown()])
        .catch(() => {})
        .then(() => process.exit());
};

process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);
process.on('SIGUSR2', gracefulShutdown); // Sent by nodemon
