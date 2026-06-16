const { createClient } = require('redis');

const CACHE_TTL = 30; // seconds
const ITEMS_KEY = 'todo:items';

let client;

async function init() {
    const host = process.env.REDIS_HOST || 'localhost';
    const port = process.env.REDIS_PORT || 6379;

    client = createClient({ url: `redis://${host}:${port}` });
    client.on('error', (err) => console.warn('Redis cache error:', err.message));
    await client.connect();
    console.log(`Redis cache connected at ${host}:${port}`);
}

async function getItems() {
    try {
        const cached = await client.get(ITEMS_KEY);
        if (cached) return JSON.parse(cached);
    } catch (err) {
        console.warn('Redis get failed, falling through to DB:', err.message);
    }
    return null;
}

async function setItems(items) {
    try {
        await client.set(ITEMS_KEY, JSON.stringify(items), { EX: CACHE_TTL });
    } catch (err) {
        console.warn('Redis set failed:', err.message);
    }
}

async function invalidate() {
    try {
        await client.del(ITEMS_KEY);
    } catch (err) {
        console.warn('Redis invalidate failed:', err.message);
    }
}

async function teardown() {
    if (client) await client.quit().catch(() => {});
}

module.exports = { init, getItems, setItems, invalidate, teardown };
