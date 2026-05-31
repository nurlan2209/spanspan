const pool = require("../config/db");

const Cart = {
  async getOrCreate(userId) {
    let { rows } = await pool.query(
      "SELECT * FROM carts WHERE user_id = $1",
      [userId]
    );
    if (!rows[0]) {
      const ins = await pool.query(
        "INSERT INTO carts (user_id, items) VALUES ($1, '[]') ON CONFLICT (user_id) DO NOTHING RETURNING *",
        [userId]
      );
      rows = ins.rows[0] ? ins.rows : (await pool.query("SELECT * FROM carts WHERE user_id = $1", [userId])).rows;
    }
    return rows[0];
  },

  async setItems(userId, items) {
    await pool.query(
      "UPDATE carts SET items = $1, updated_at = NOW() WHERE user_id = $2",
      [JSON.stringify(items), userId]
    );
  },

  // Used in order creation inside a transaction.
  // Atomically clears cart; returns old items array or null if cart was empty.
  async clearAndGetItems(txClient, userId) {
    const { rows } = await txClient.query(
      "SELECT items FROM carts WHERE user_id = $1 FOR UPDATE",
      [userId]
    );
    if (!rows[0] || !rows[0].items.length) return null;
    const items = rows[0].items;
    await txClient.query(
      "UPDATE carts SET items = '[]', updated_at = NOW() WHERE user_id = $1",
      [userId]
    );
    return items;
  },

  async restoreItems(userId, items) {
    await pool.query(
      "UPDATE carts SET items = $1, updated_at = NOW() WHERE user_id = $2",
      [JSON.stringify(items), userId]
    );
  },
};

module.exports = Cart;
