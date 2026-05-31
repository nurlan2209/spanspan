const pool = require("../config/db");

const toOrder = (row) => {
  if (!row) return null;
  return {
    _id: row.id,
    userId: row.user_id,
    clientName: row.client_name,
    clientPhone: row.client_phone,
    items: row.items || [],
    totalAmount: Number(row.total_amount),
    status: row.status,
    clientComment: row.client_comment,
    managerNote: row.manager_note,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

const ALLOWED_STATUSES = ["new", "contacted", "paid", "delivering", "completed", "canceled"];

const Order = {
  allowedStatuses: ALLOWED_STATUSES,

  async create({ userId, clientName, clientPhone, items, totalAmount, clientComment = "" }, txClient) {
    const db = txClient || pool;
    const { rows } = await db.query(
      `INSERT INTO orders (user_id, client_name, client_phone, items, total_amount, client_comment)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [userId, clientName, clientPhone, JSON.stringify(items), totalAmount, clientComment]
    );
    return toOrder(rows[0]);
  },

  async findByUserId(userId) {
    const { rows } = await pool.query(
      "SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC",
      [userId]
    );
    return rows.map(toOrder);
  },

  async findAll({ status } = {}) {
    const params = [];
    const where = status ? (params.push(status), "WHERE status = $1") : "";
    const { rows } = await pool.query(
      `SELECT * FROM orders ${where} ORDER BY created_at DESC`,
      params
    );
    return rows.map(toOrder);
  },

  async findById(id) {
    const { rows } = await pool.query("SELECT * FROM orders WHERE id = $1", [id]);
    return toOrder(rows[0]);
  },

  async update(id, { status, managerNote }) {
    const sets = [];
    const params = [];
    if (status !== undefined) { params.push(status); sets.push(`status = $${params.length}`); }
    if (managerNote !== undefined) { params.push(managerNote); sets.push(`manager_note = $${params.length}`); }
    if (!sets.length) return Order.findById(id);
    sets.push("updated_at = NOW()");
    params.push(id);
    const { rows } = await pool.query(
      `UPDATE orders SET ${sets.join(", ")} WHERE id = $${params.length} RETURNING *`,
      params
    );
    return toOrder(rows[0]);
  },
};

module.exports = Order;
