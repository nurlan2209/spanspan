const pool = require("../config/db");

const toGroup = (row) => {
  if (!row) return null;
  return {
    _id: row.id,
    title: row.title,
    description: row.description,
    trainerId: row.trainer_id,
    trainerName: row.trainer_name ?? null,
    scheduleDays: row.schedule_days ?? [],
    scheduleTime: row.schedule_time ?? '',
    maxParticipants: row.max_participants,
    ageMin: row.age_min,
    ageMax: row.age_max,
    status: row.status,
    enrolledCount: row.enrolled_count ? parseInt(row.enrolled_count) : 0,
    isEnrolled: row.is_enrolled ?? false,
    createdAt: row.created_at,
  };
};

const Group = {
  async findAll({ clientAge } = {}) {
    const params = [];
    let ageFilter = "";
    if (clientAge != null) {
      params.push(clientAge);
      ageFilter = `AND g.age_min <= $${params.length} AND g.age_max >= $${params.length}`;
    }
    const { rows } = await pool.query(
      `SELECT g.*,
              u.full_name AS trainer_name,
              COUNT(e.id) AS enrolled_count
       FROM groups g
       LEFT JOIN users u ON u.id = g.trainer_id
       LEFT JOIN group_enrollments e ON e.group_id = g.id
       WHERE g.status = 'recruiting' ${ageFilter}
       GROUP BY g.id, u.full_name
       ORDER BY g.schedule_time ASC`,
      params
    );
    return rows.map(toGroup);
  },

  async findByTrainer(trainerId) {
    const { rows } = await pool.query(
      `SELECT g.*,
              COUNT(e.id) AS enrolled_count
       FROM groups g
       LEFT JOIN group_enrollments e ON e.group_id = g.id
       WHERE g.trainer_id = $1
       GROUP BY g.id
       ORDER BY g.created_at DESC`,
      [trainerId]
    );
    return rows.map(toGroup);
  },

  async findById(id, clientId) {
    const { rows } = await pool.query(
      `SELECT g.*,
              u.full_name AS trainer_name,
              COUNT(e.id) AS enrolled_count,
              EXISTS(
                SELECT 1 FROM group_enrollments
                WHERE group_id = g.id AND client_id = $2
              ) AS is_enrolled
       FROM groups g
       LEFT JOIN users u ON u.id = g.trainer_id
       LEFT JOIN group_enrollments e ON e.group_id = g.id
       WHERE g.id = $1
       GROUP BY g.id, u.full_name`,
      [id, clientId ?? null]
    );
    return toGroup(rows[0]);
  },

  async create({ title, description, trainerId, scheduleDays, scheduleTime, maxParticipants, ageMin, ageMax }) {
    const { rows } = await pool.query(
      `INSERT INTO groups (title, description, trainer_id, schedule_days, schedule_time, max_participants, age_min, age_max)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [title, description ?? "", trainerId, scheduleDays, scheduleTime, maxParticipants, ageMin, ageMax]
    );
    return toGroup(rows[0]);
  },

  async updateStatus(id, trainerId, status) {
    const { rows } = await pool.query(
      `UPDATE groups SET status = $1
       WHERE id = $2 AND trainer_id = $3 RETURNING *`,
      [status, id, trainerId]
    );
    return toGroup(rows[0]);
  },

  async getMembers(groupId) {
    const { rows } = await pool.query(
      `SELECT u.id, u.full_name, u.phone_number, u.birth_date, e.enrolled_at
       FROM group_enrollments e
       JOIN users u ON u.id = e.client_id
       WHERE e.group_id = $1
       ORDER BY e.enrolled_at ASC`,
      [groupId]
    );
    return rows.map((r) => ({
      _id: r.id,
      fullName: r.full_name,
      phoneNumber: r.phone_number,
      birthDate: r.birth_date,
      enrolledAt: r.enrolled_at,
    }));
  },

  async enroll(groupId, clientId) {
    const { rows: [group] } = await pool.query(
      `SELECT g.max_participants, COUNT(e.id) AS enrolled_count
       FROM groups g
       LEFT JOIN group_enrollments e ON e.group_id = g.id
       WHERE g.id = $1 AND g.status = 'recruiting'
       GROUP BY g.id`,
      [groupId]
    );
    if (!group) throw new Error("Группа не найдена или набор закрыт");
    if (parseInt(group.enrolled_count) >= group.max_participants) {
      throw new Error("Мест нет");
    }
    const { rows } = await pool.query(
      `INSERT INTO group_enrollments (group_id, client_id) VALUES ($1, $2) RETURNING *`,
      [groupId, clientId]
    );
    return rows[0];
  },

  async unenroll(groupId, clientId) {
    await pool.query(
      `DELETE FROM group_enrollments WHERE group_id = $1 AND client_id = $2`,
      [groupId, clientId]
    );
  },

  async myEnrollments(clientId) {
    const { rows } = await pool.query(
      `SELECT g.*,
              u.full_name AS trainer_name,
              COUNT(e2.id) AS enrolled_count,
              true AS is_enrolled
       FROM group_enrollments e
       JOIN groups g ON g.id = e.group_id
       LEFT JOIN users u ON u.id = g.trainer_id
       LEFT JOIN group_enrollments e2 ON e2.group_id = g.id
       WHERE e.client_id = $1
       GROUP BY g.id, u.full_name, e.enrolled_at
       ORDER BY e.enrolled_at DESC`,
      [clientId]
    );
    return rows.map(toGroup);
  },
};

module.exports = Group;
