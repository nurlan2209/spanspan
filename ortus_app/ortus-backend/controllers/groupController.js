const Group = require("../models/Group");

const calcAge = (birthDate) => {
  if (!birthDate) return null;
  return new Date().getFullYear() - new Date(birthDate).getFullYear();
};

// GET /api/groups — список подходящих групп (клиент)
const listGroups = async (req, res) => {
  try {
    const age = calcAge(req.user.birthDate);
    const groups = await Group.findAll({ clientAge: age });
    res.json(groups);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// GET /api/groups/trainer — мои группы (тренер)
const trainerGroups = async (req, res) => {
  try {
    const groups = await Group.findByTrainer(req.user._id);
    res.json(groups);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// POST /api/groups — создать группу (тренер)
const createGroup = async (req, res) => {
  try {
    const { title, description, scheduleDays, scheduleTime, maxParticipants, ageMin, ageMax } = req.body;
    if (!title || !scheduleTime || !Array.isArray(scheduleDays) || scheduleDays.length === 0 || ageMin == null || ageMax == null) {
      return res.status(400).json({ message: "Заполните все обязательные поля" });
    }
    if (ageMin > ageMax) {
      return res.status(400).json({ message: "Минимальный возраст не может быть больше максимального" });
    }
    const group = await Group.create({
      title,
      description,
      trainerId: req.user._id,
      scheduleDays,
      scheduleTime,
      maxParticipants: maxParticipants ?? 20,
      ageMin,
      ageMax,
    });
    res.status(201).json(group);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// PATCH /api/groups/:id/confirm — подтвердить набор (тренер)
const confirmGroup = async (req, res) => {
  try {
    const group = await Group.updateStatus(req.params.id, req.user._id, "confirmed");
    if (!group) return res.status(404).json({ message: "Группа не найдена" });
    res.json(group);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// PATCH /api/groups/:id/cancel — отменить (тренер)
const cancelGroup = async (req, res) => {
  try {
    const group = await Group.updateStatus(req.params.id, req.user._id, "cancelled");
    if (!group) return res.status(404).json({ message: "Группа не найдена" });
    res.json(group);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// GET /api/groups/:id/members — список участников (тренер)
const getMembers = async (req, res) => {
  try {
    const members = await Group.getMembers(req.params.id);
    res.json(members);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// POST /api/groups/:id/enroll — записаться (клиент)
const enroll = async (req, res) => {
  try {
    await Group.enroll(req.params.id, req.user._id);
    res.json({ message: "Вы записаны" });
  } catch (e) {
    const status = e.message === "Мест нет" ? 409 : 400;
    res.status(status).json({ message: e.message });
  }
};

// DELETE /api/groups/:id/enroll — отписаться (клиент)
const unenroll = async (req, res) => {
  try {
    await Group.unenroll(req.params.id, req.user._id);
    res.json({ message: "Вы отписались" });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

// GET /api/groups/my-enrollments — мои записи (клиент)
const myEnrollments = async (req, res) => {
  try {
    const groups = await Group.myEnrollments(req.user._id);
    res.json(groups);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
};

module.exports = { listGroups, trainerGroups, createGroup, confirmGroup, cancelGroup, getMembers, enroll, unenroll, myEnrollments };
