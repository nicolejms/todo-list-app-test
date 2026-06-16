const waitPort = require('wait-port');
const fs = require('fs');
const mysql = require('mysql2');
const cache = require('../cache');

const {
    MYSQL_HOST: HOST,
    MYSQL_HOST_FILE: HOST_FILE,
    MYSQL_USER: USER,
    MYSQL_USER_FILE: USER_FILE,
    MYSQL_PASSWORD: PASSWORD,
    MYSQL_PASSWORD_FILE: PASSWORD_FILE,
    MYSQL_DB: DB,
    MYSQL_DB_FILE: DB_FILE,
} = process.env;

let pool;

async function init() {
    const host = HOST_FILE ? fs.readFileSync(HOST_FILE) : HOST;
    const user = USER_FILE ? fs.readFileSync(USER_FILE) : USER;
    const password = PASSWORD_FILE ? fs.readFileSync(PASSWORD_FILE) : PASSWORD;
    const database = DB_FILE ? fs.readFileSync(DB_FILE) : DB;

    await waitPort({ 
        host, 
        port: 3306,
        timeout: 10000,
        waitForDns: true,
    });

    pool = mysql.createPool({
        connectionLimit: 5,
        host,
        user,
        password,
        database,
        charset: 'utf8mb4',
    });

    return new Promise((acc, rej) => {
        pool.query(
            'CREATE TABLE IF NOT EXISTS todo_items (id varchar(36), name varchar(255), completed boolean) DEFAULT CHARSET utf8mb4',
            async err => {
                if (err) return rej(err);

                console.log(`Connected to mysql db at host ${HOST}`);
                await cache.init();
                acc();
            },
        );
    });
}

async function teardown() {
    await cache.teardown();
    return new Promise((acc, rej) => {
        pool.end(err => {
            if (err) rej(err);
            else acc();
        });
    });
}

async function getItems() {
    const cached = await cache.get(cache.ALL_ITEMS_KEY);
    if (cached) return cached;

    return new Promise((acc, rej) => {
        pool.query('SELECT * FROM todo_items', async (err, rows) => {
            if (err) return rej(err);
            const items = rows.map(item =>
                Object.assign({}, item, {
                    completed: item.completed === 1,
                }),
            );
            await cache.set(cache.ALL_ITEMS_KEY, items);
            acc(items);
        });
    });
}

async function getItem(id) {
    const cacheKey = `${cache.ITEM_KEY_PREFIX}${id}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    return new Promise((acc, rej) => {
        pool.query('SELECT * FROM todo_items WHERE id=?', [id], async (err, rows) => {
            if (err) return rej(err);
            const item = rows.map(item =>
                Object.assign({}, item, {
                    completed: item.completed === 1,
                }),
            )[0];
            if (item) await cache.set(cacheKey, item);
            acc(item);
        });
    });
}

async function storeItem(item) {
    return new Promise((acc, rej) => {
        pool.query(
            'INSERT INTO todo_items (id, name, completed) VALUES (?, ?, ?)',
            [item.id, item.name, item.completed ? 1 : 0],
            async err => {
                if (err) return rej(err);
                await cache.invalidate();
                acc();
            },
        );
    });
}

async function updateItem(id, item) {
    return new Promise((acc, rej) => {
        pool.query(
            'UPDATE todo_items SET name=?, completed=? WHERE id=?',
            [item.name, item.completed ? 1 : 0, id],
            async err => {
                if (err) return rej(err);
                await cache.invalidateItem(id);
                acc();
            },
        );
    });
}

async function removeItem(id) {
    return new Promise((acc, rej) => {
        pool.query('DELETE FROM todo_items WHERE id = ?', [id], async err => {
            if (err) return rej(err);
            await cache.invalidateItem(id);
            acc();
        });
    });
}

module.exports = {
    init,
    teardown,
    getItems,
    getItem,
    storeItem,
    updateItem,
    removeItem,
};
