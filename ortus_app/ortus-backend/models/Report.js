const pool = require("../config/db");

const toReport = (row) => {
  if (!row) return null;
  return {
    _id: row.id,
    trainerId: row.trainer_id,
    trainingDate: row.training_date,
    slot: row.slot,
    comment: row.comment,
    attachments: row.attachments || [],
    isLate: row.is_late,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

const toReportPopulated = (row) => {
  if (!row) return null;
  const r = toReport(row);
  if (row.trainer_full_name !== undefined) {
    r.trainerId = {
      _id: row.trainer_id,
      fullName: row.trainer_full_name,
      phoneNumber: row.trainer_phone,
    };
  }
  return r;
};

const Report = {
  async create({ trainerId, trainingDate, slot, comment = "", attachments = [], isLate = false }) {
    const { rows } = await pool.query(
      `INSERT INTO reports (trainer_id, training_date, slot, comment, attachments, is_late)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [trainerId, trainingDate, slot, comment, JSON.stringify(attachments), isLate]
    );
    return toReport(rows[0]);
  },

  async findByTrainerId(trainerId) {
    const { rows } = await pool.query(
      "SELECT * FROM reports WHERE trainer_id = $1 ORDER BY created_at DESC",
      [trainerId]
    );
    return rows.map(toReport);
  },

  async findAll({ trainerId, dateFrom, dateTo, isLate } = {}) {
    const conds = [];
    const params = [];
    if (trainerId) { params.push(trainerId); conds.push(`r.trainer_id = $${params.length}`); }
    if (dateFrom) { params.push(dateFrom); conds.push(`r.training_date >= $${params.length}`); }
    if (dateTo) { params.push(dateTo); conds.push(`r.training_date <= $${params.length}`); }
    if (isLate !== undefined) { params.push(isLate); conds.push(`r.is_late = $${params.length}`); }
    const where = conds.length ? `WHERE ${conds.join(" AND ")}` : "";
    const { rows } = await pool.query(
      `SELECT r.*, u.full_name AS trainer_full_name, u.phone_number AS trainer_phone
       FROM reports r
       JOIN users u ON u.id = r.trainer_id
       ${where}
       ORDER BY r.training_date DESC, r.created_at DESC`,
      params
    );
    return rows.map(toReportPopulated);
  },

  async findById(id) {
    const { rows } = await pool.query("SELECT * FROM reports WHERE id = $1", [id]);
    return toReport(rows[0]);
  },

  async deleteById(id) {
    await pool.query("DELETE FROM reports WHERE id = $1", [id]);
  },
};

module.exports = Report;
