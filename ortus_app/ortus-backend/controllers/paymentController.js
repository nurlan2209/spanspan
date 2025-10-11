const Payment = require("../models/Payment");
const User = require("../models/User");
const Group = require("../models/Group");

// Создать платёж (admin/trainer создаёт для студента)
const createPayment = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("trainer")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { studentId, amount, month, year } = req.body;

    const student = await User.findById(studentId);
    if (!student || !student.userType.includes("student")) {
      return res.status(404).json({ message: "Student not found" });
    }

    if (!student.groupId) {
      return res
        .status(400)
        .json({ message: "Student is not assigned to any group" });
    }

    const payment = await Payment.create({
      studentId,
      groupId: student.groupId,
      amount,
      month,
      year,
    });

    await payment.populate("studentId", "fullName phoneNumber");
    await payment.populate("groupId", "name");

    res.status(201).json(payment);
  } catch (error) {
    if (error.code === 11000) {
      return res
        .status(400)
        .json({ message: "Payment for this month already exists" });
    }
    res.status(500).json({ message: error.message });
  }
};

// Получить все платежи студента (студент/родитель/админ)
const getStudentPayments = async (req, res) => {
  try {
    const { studentId } = req.params;

    // Проверка доступа
    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).json({ message: "Student not found" });
    }

    const isOwner = req.user._id.toString() === studentId;
    const isParent =
      student.parentId &&
      student.parentId.toString() === req.user._id.toString();
    const isAdmin = req.user.userType.includes("admin");

    if (!isOwner && !isParent && !isAdmin) {
      return res.status(403).json({ message: "Access denied" });
    }

    const payments = await Payment.find({ studentId })
      .populate("groupId", "name")
      .sort({ year: -1, month: -1 });

    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить все платежи группы (trainer/admin)
const getGroupPayments = async (req, res) => {
  try {
    const { groupId } = req.params;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    // Проверка доступа
    const isTrainer = group.trainerId.toString() === req.user._id.toString();
    const isAdmin = req.user.userType.includes("admin");

    if (!isTrainer && !isAdmin) {
      return res.status(403).json({ message: "Access denied" });
    }

    const payments = await Payment.find({ groupId })
      .populate("studentId", "fullName phoneNumber")
      .sort({ year: -1, month: -1 });

    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить все неоплаченные платежи (admin/trainer)
const getUnpaidPayments = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("trainer")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    let filter = { status: "unpaid" };

    // Если тренер - только его группы
    if (
      req.user.userType.includes("trainer") &&
      !req.user.userType.includes("admin")
    ) {
      const groups = await Group.find({ trainerId: req.user._id });
      const groupIds = groups.map((g) => g._id);
      filter.groupId = { $in: groupIds };
    }

    const payments = await Payment.find(filter)
      .populate("studentId", "fullName phoneNumber")
      .populate("groupId", "name")
      .sort({ year: -1, month: -1 });

    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Отметить платёж как оплаченный
const markAsPaid = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("trainer")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { paymentMethod } = req.body;

    const payment = await Payment.findByIdAndUpdate(
      req.params.id,
      {
        status: "paid",
        paidAt: Date.now(),
        paymentMethod: paymentMethod || "manual",
      },
      { new: true }
    )
      .populate("studentId", "fullName phoneNumber")
      .populate("groupId", "name");

    if (!payment) {
      return res.status(404).json({ message: "Payment not found" });
    }

    res.json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить статистику платежей (admin)
const getPaymentStats = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { month, year } = req.query;
    const filter = {};

    if (month) filter.month = parseInt(month);
    if (year) filter.year = parseInt(year);

    const total = await Payment.countDocuments(filter);
    const paid = await Payment.countDocuments({ ...filter, status: "paid" });
    const unpaid = await Payment.countDocuments({
      ...filter,
      status: "unpaid",
    });

    const totalAmount = await Payment.aggregate([
      { $match: { ...filter, status: "paid" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    res.json({
      total,
      paid,
      unpaid,
      totalAmount: totalAmount[0]?.total || 0,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createPayment,
  getStudentPayments,
  getGroupPayments,
  getUnpaidPayments,
  markAsPaid,
  getPaymentStats,
};
