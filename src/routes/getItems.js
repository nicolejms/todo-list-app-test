const db = require('../persistence');
const cache = require('../cache');

module.exports = async (req, res) => {
    const cached = await cache.getItems();
    if (cached) return res.send(cached);

    const items = await db.getItems();
    await cache.setItems(items);
    res.send(items);
};
