const db = require('../persistence');
const cache = require('../cache');

module.exports = async (req, res) => {
    await db.removeItem(req.params.id);
    await cache.invalidate();
    res.sendStatus(200);
};
