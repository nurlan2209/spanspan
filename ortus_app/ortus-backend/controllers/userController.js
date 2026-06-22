const User = require("../models/User");

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { fullName, phoneNumber, password, age } = req.body;
    const user = await User.update(req.user._id, { fullName, phoneNumber, password, age: age != null ? parseInt(age) : undefined });
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") return res.status(403).json({ message: "Access denied" });
    const { phoneNumber, fullName, password, role } = req.body;
    if (!phoneNumber || !fullName || !password || !role) {
      return res.status(400).json({ message: "Заполните все обязательные поля" });
    }
    if (!["trainer", "manager"].includes(role)) {
      return res.status(400).json({ message: "Invalid staff role" });
    }
    if (await User.findByPhone(phoneNumber)) {
      return res.status(400).json({ message: "Пользователь с таким телефоном уже существует" });
    }
    const staff = await User.create({ phoneNumber, fullName, password, role, status: "active" });
    res.status(201).json(staff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const listStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") return res.status(403).json({ message: "Access denied" });
    const { role, status } = req.query;
    const filter = { role: ["trainer", "manager"] };
    if (role && ["trainer", "manager"].includes(role)) filter.role = role;
    if (status && ["active", "inactive"].includes(status)) filter.status = status;
    const staff = await User.findMany(filter);
    res.json(staff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateStaffStatus = async (req, res) => {
  try {
    if (req.user.role !== "director") return res.status(403).json({ message: "Access denied" });
    const { id } = req.params;
    const { status } = req.body;
    if (!["active", "inactive"].includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }
    const staff = await User.findById(id);
    if (!staff || !["trainer", "manager"].includes(staff.role)) {
      return res.status(404).json({ message: "Staff not found" });
    }
    const updated = await User.update(id, { status });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") return res.status(403).json({ message: "Access denied" });
    const { id } = req.params;
    const staff = await User.findById(id);
    if (!staff || !["trainer", "manager"].includes(staff.role)) {
      return res.status(404).json({ message: "Staff not found" });
    }
    await User.deleteById(id);
    res.json({ message: "Staff deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getProfile, updateProfile, createStaff, listStaff, updateStaffStatus, deleteStaff };
