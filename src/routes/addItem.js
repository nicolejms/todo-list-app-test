const db = require('../persistence');
const cache = require('../cache');
const {v4 : uuid} = require('uuid');

module.exports = async (req, res) => {
    const item = {
        id: uuid(),
        name: req.body.name,
        completed: false,
    };

    await db.storeItem(item);
    await cache.invalidate();
    res.send(item);
};
