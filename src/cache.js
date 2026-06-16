const redis = require('redis');

const {
    REDIS_HOST: HOST = 'localhost',
    REDIS_PORT: PORT = '6379',
} = process.env;

let client;

const CACHE_TTL = 60; // seconds
const ALL_ITEMS_KEY = 'todo:all';
const ITEM_KEY_PREFIX = 'todo:item:';

async function init() {
    client = redis.createClient({
        socket: {
            host: HOST,
            port: parseInt(PORT, 10),
        },
    });

    client.on('error', (err) => {
        console.error('Redis error:', err.message);
    });

    await client.connect();
    console.log(`Connected to Redis at ${HOST}:${PORT}`);
}

async function teardown() {
    if (client) {
        await client.quit();
    }
}

async function get(key) {
    try {
        const data = await client.get(key);
        return data ? JSON.parse(data) : null;
    } catch {
        return null;
    }
}

async function set(key, value) {
    try {
        await client.set(key, JSON.stringify(value), { EX: CACHE_TTL });
    } catch {
        // Cache write failures are non-fatal
    }
}

async function invalidate() {
    try {
        await client.del(ALL_ITEMS_KEY);
    } catch {
        // Cache invalidation failures are non-fatal
    }
}

async function invalidateItem(id) {
    try {
        await client.del([ALL_ITEMS_KEY, `${ITEM_KEY_PREFIX}${id}`]);
    } catch {
        // Non-fatal
    }
}

module.exports = {
    init,
    teardown,
    get,
    set,
    invalidate,
    invalidateItem,
    ALL_ITEMS_KEY,
    ITEM_KEY_PREFIX,
};
