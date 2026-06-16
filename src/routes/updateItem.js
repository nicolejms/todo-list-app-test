const db = require('../persistence');
const cache = require('../cache');

module.exports = async (req, res) => {
    await db.updateItem(req.params.id, {
        name: req.body.name,
        completed: req.body.completed,
    });
    await cache.invalidate();
    const item = await db.getItem(req.params.id);
    res.send(item);
};
