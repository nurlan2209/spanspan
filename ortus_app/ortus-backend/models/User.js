const pool = require("../config/db");
const bcrypt = require("bcryptjs");

const toUser = (row, withPassword = false) => {
  if (!row) return null;
  const u = {
    _id: row.id,
    phoneNumber: row.phone_number,
    fullName: row.full_name,
    role: row.role,
    status: row.status,
    birthDate: row.birth_date ?? null,
    createdAt: row.created_at,
  };
  if (withPassword) u.password = row.password;
  return u;
};

const User = {
  async findByPhone(phoneNumber) {
    const { rows } = await pool.query(
      "SELECT * FROM users WHERE phone_number = $1",
      [phoneNumber]
    );
    return toUser(rows[0], true);
  },

  async findById(id) {
    const { rows } = await pool.query("SELECT * FROM users WHERE id = $1", [id]);
    return toUser(rows[0]);
  },

  async findMany({ role, status } = {}) {
    const conds = [];
    const params = [];
    if (role) {
      if (Array.isArray(role)) {
        params.push(role);
        conds.push(`role = ANY($${params.length})`);
      } else {
        params.push(role);
        conds.push(`role = $${params.length}`);
      }
    }
    if (status) {
      params.push(status);
      conds.push(`status = $${params.length}`);
    }
    const where = conds.length ? `WHERE ${conds.join(" AND ")}` : "";
    const { rows } = await pool.query(
      `SELECT * FROM users ${where} ORDER BY created_at DESC`,
      params
    );
    return rows.map((r) => toUser(r));
  },

  async create({ phoneNumber, fullName, password, birthDate, role = "client", status = "active" }) {
    const hashed = await bcrypt.hash(password, 10);
    const { rows } = await pool.query(
      `INSERT INTO users (phone_number, full_name, password, birth_date, role, status)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [phoneNumber, fullName, hashed, birthDate ?? null, role, status]
    );
    return toUser(rows[0]);
  },

  async update(id, { fullName, phoneNumber, password, status }) {
    const sets = [];
    const params = [];
    if (fullName !== undefined) { params.push(fullName); sets.push(`full_name = $${params.length}`); }
    if (phoneNumber !== undefined) { params.push(phoneNumber); sets.push(`phone_number = $${params.length}`); }
    if (password !== undefined) {
      const hashed = await bcrypt.hash(password, 10);
      params.push(hashed);
      sets.push(`password = $${params.length}`);
    }
    if (status !== undefined) { params.push(status); sets.push(`status = $${params.length}`); }
    if (!sets.length) return User.findById(id);
    params.push(id);
    const { rows } = await pool.query(
      `UPDATE users SET ${sets.join(", ")} WHERE id = $${params.length} RETURNING *`,
      params
    );
    return toUser(rows[0]);
  },

  async deleteById(id) {
    await pool.query("DELETE FROM users WHERE id = $1", [id]);
  },

  checkPassword(hashed, entered) {
    return bcrypt.compare(entered, hashed);
  },
};

module.exports = User;
