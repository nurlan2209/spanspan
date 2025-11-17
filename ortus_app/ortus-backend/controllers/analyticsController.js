const Payment = require("../models/Payments");
const Order = require("../models/Order");
const User = require("../models/User");
const Group = require("../models/Group");
const Attendance = require("../models/Attendance");
const PhotoReport = require("../models/PhotoReport");
const { Parser } = require("json2csv");

// Финансовая аналитика
const getFinancialAnalytics = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { startDate, endDate } = req.query;
    const filter = {};

    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    // Доход от абонементов
    const paymentsRevenue = await Payment.aggregate([
      { $match: { ...filter, status: "paid" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // Доход от магазина
    const ordersRevenue = await Order.aggregate([
      {
        $match: {
          ...filter,
          status: { $in: ["paid", "ready", "completed"] },
        },
      },
      { $group: { _id: null, total: { $sum: "$totalAmount" } } },
    ]);

    // Доход по месяцам (абонементы)
    const revenueByMonth = await Payment.aggregate([
      { $match: { status: "paid" } },
      {
        $group: {
          _id: { year: "$year", month: "$month" },
          total: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      { $sort: { "_id.year": -1, "_id.month": -1 } },
      { $limit: 12 },
    ]);

    // ТОП товары
    const topProducts = await Order.aggregate([
      { $match: { status: { $in: ["paid", "ready", "completed"] } } },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.productId",
          name: { $first: "$items.name" },
          totalSold: { $sum: "$items.quantity" },
          revenue: {
            $sum: { $multiply: ["$items.price", "$items.quantity"] },
          },
        },
      },
      { $sort: { totalSold: -1 } },
      { $limit: 10 },
    ]);

    // Статистика заказов
    const totalOrders = await Order.countDocuments(filter);
    const pendingOrders = await Order.countDocuments({
      ...filter,
      status: "pending",
    });
    const completedOrders = await Order.countDocuments({
      ...filter,
      status: "completed",
    });

    // Средний чек магазина
    const avgOrderValue = await Order.aggregate([
      {
        $match: {
          ...filter,
          status: { $in: ["paid", "ready", "completed"] },
        },
      },
      { $group: { _id: null, avg: { $avg: "$totalAmount" } } },
    ]);

    res.json({
      paymentsRevenue: paymentsRevenue[0]?.total || 0,
      ordersRevenue: ordersRevenue[0]?.total || 0,
      totalRevenue:
        (paymentsRevenue[0]?.total || 0) + (ordersRevenue[0]?.total || 0),
      revenueByMonth,
      topProducts,
      orders: {
        total: totalOrders,
        pending: pendingOrders,
        completed: completedOrders,
      },
      avgOrderValue: avgOrderValue[0]?.avg || 0,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Аналитика студентов
const getStudentsAnalytics = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    // Всего студентов
    const totalStudents = await User.countDocuments({
      userType: { $in: ["student"] },
    });

    // Студенты с группами
    const studentsWithGroup = await User.countDocuments({
      userType: { $in: ["student"] },
      groupId: { $ne: null },
    });

    // Студенты без группы
    const studentsWithoutGroup = totalStudents - studentsWithGroup;

    // Всего тренеров
    const totalTrainers = await User.countDocuments({
      userType: { $in: ["trainer"] },
    });

    // Всего групп
    const totalGroups = await Group.countDocuments();

    // Распределение студентов по группам
    const studentsByGroup = await Group.aggregate([
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "groupId",
          as: "students",
        },
      },
      {
        $project: {
          name: 1,
          studentsCount: { $size: "$students" },
        },
      },
      { $sort: { studentsCount: -1 } },
    ]);

    res.json({
      totalStudents,
      studentsWithGroup,
      studentsWithoutGroup,
      totalTrainers,
      totalGroups,
      studentsByGroup,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Детальная аналитика платежей
const getPaymentsAnalytics = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { month, year } = req.query;
    const filter = {};

    if (month) filter.month = parseInt(month);
    if (year) filter.year = parseInt(year);

    // Статистика платежей
    const totalPayments = await Payment.countDocuments(filter);
    const paidPayments = await Payment.countDocuments({
      ...filter,
      status: "paid",
    });
    const unpaidPayments = await Payment.countDocuments({
      ...filter,
      status: "unpaid",
    });

    // Сумма оплаченных
    const totalPaidAmount = await Payment.aggregate([
      { $match: { ...filter, status: "paid" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // Сумма неоплаченных
    const totalUnpaidAmount = await Payment.aggregate([
      { $match: { ...filter, status: "unpaid" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // Процент оплаченных
    const paymentRate =
      totalPayments > 0 ? ((paidPayments / totalPayments) * 100).toFixed(2) : 0;

    // Платежи по группам
    const paymentsByGroup = await Payment.aggregate([
      { $match: filter },
      {
        $group: {
          _id: "$groupId",
          total: { $sum: 1 },
          paid: {
            $sum: { $cond: [{ $eq: ["$status", "paid"] }, 1, 0] },
          },
          revenue: {
            $sum: {
              $cond: [{ $eq: ["$status", "paid"] }, "$amount", 0],
            },
          },
        },
      },
      {
        $lookup: {
          from: "groups",
          localField: "_id",
          foreignField: "_id",
          as: "group",
        },
      },
      { $unwind: "$group" },
      {
        $project: {
          groupName: "$group.name",
          total: 1,
          paid: 1,
          revenue: 1,
        },
      },
      { $sort: { revenue: -1 } },
    ]);

    res.json({
      totalPayments,
      paidPayments,
      unpaidPayments,
      totalPaidAmount: totalPaidAmount[0]?.total || 0,
      totalUnpaidAmount: totalUnpaidAmount[0]?.total || 0,
      paymentRate: parseFloat(paymentRate),
      paymentsByGroup,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Экспорт финансовых данных
const exportAnalytics = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { startDate, endDate, format = "csv" } = req.query;
    const dateFilter = {};

    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }

    const paymentsRevenue = await Payment.aggregate([
      { $match: { status: "paid", ...dateFilter } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    const ordersRevenue = await Order.aggregate([
      {
        $match: {
          status: { $in: ["paid", "ready", "completed"] },
          ...dateFilter,
        },
      },
      { $group: { _id: null, total: { $sum: "$totalAmount" } } },
    ]);

    const revenueByMonth = await Payment.aggregate([
      { $match: { status: "paid", ...dateFilter } },
      {
        $group: {
          _id: { year: "$year", month: "$month" },
          total: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      { $sort: { "_id.year": -1, "_id.month": -1 } },
      { $limit: 12 },
    ]);

    const topProducts = await Order.aggregate([
      {
        $match: {
          status: { $in: ["paid", "ready", "completed"] },
          ...dateFilter,
        },
      },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.productId",
          name: { $first: "$items.name" },
          totalSold: { $sum: "$items.quantity" },
          revenue: {
            $sum: { $multiply: ["$items.price", "$items.quantity"] },
          },
        },
      },
      { $sort: { totalSold: -1 } },
      { $limit: 10 },
    ]);

    const rows = [];
    const payments = paymentsRevenue[0]?.total || 0;
    const orders = ordersRevenue[0]?.total || 0;
    const total = payments + orders;

    rows.push(
      { section: "Overview", name: "Доход абонементы", value: payments },
      { section: "Overview", name: "Доход магазин", value: orders },
      { section: "Overview", name: "Доход общий", value: total }
    );

    revenueByMonth.forEach((item) => {
      rows.push({
        section: "Месяцы",
        name: `${item._id.month}.${item._id.year}`,
        value: item.total,
      });
    });

    topProducts.forEach((product) => {
      rows.push({
        section: "ТОП товары",
        name: product.name,
        value: product.revenue,
      });
    });

    if (format !== "csv") {
      return res
        .status(400)
        .json({ message: "Only CSV export is supported right now." });
    }

    const parser = new Parser({ fields: ["section", "name", "value"] });
    const csv = parser.parse(rows);

    res.header("Content-Type", "text/csv");
    res.attachment(`financial_export_${Date.now()}.csv`);
    res.send(csv);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Аналитика посещаемости всех групп
const getAttendanceAnalytics = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director") &&
      !req.user.userType.includes("trainer")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { startDate, endDate } = req.query;
    const filter = {};

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    // Общая статистика посещаемости
    const totalAttendance = await Attendance.countDocuments(filter);
    const presentCount = await Attendance.countDocuments({
      ...filter,
      status: "present",
    });
    const absentCount = await Attendance.countDocuments({
      ...filter,
      status: "absent",
    });

    const overallRate =
      totalAttendance > 0
        ? ((presentCount / totalAttendance) * 100).toFixed(2)
        : 0;

    // Посещаемость по группам
    const attendanceByGroup = await Attendance.aggregate([
      { $match: filter },
      {
        $group: {
          _id: "$groupId",
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
          absent: {
            $sum: { $cond: [{ $eq: ["$status", "absent"] }, 1, 0] },
          },
          sick: {
            $sum: { $cond: [{ $eq: ["$status", "sick"] }, 1, 0] },
          },
        },
      },
      {
        $lookup: {
          from: "groups",
          localField: "_id",
          foreignField: "_id",
          as: "group",
        },
      },
      { $unwind: "$group" },
      {
        $lookup: {
          from: "users",
          localField: "group.trainerId",
          foreignField: "_id",
          as: "trainer",
        },
      },
      { $unwind: "$trainer" },
      {
        $project: {
          groupId: "$_id",
          groupName: "$group.name",
          trainerName: "$trainer.fullName",
          total: 1,
          present: 1,
          absent: 1,
          sick: 1,
          attendanceRate: {
            $cond: [
              { $gt: ["$total", 0] },
              {
                $multiply: [{ $divide: ["$present", "$total"] }, 100],
              },
              0,
            ],
          },
        },
      },
      { $sort: { attendanceRate: -1 } },
    ]);

    const absentByGroup = await Attendance.aggregate([
      { $match: { ...filter, status: "absent" } },
      {
        $group: {
          _id: { groupId: "$groupId", studentId: "$studentId" },
          total: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "_id.studentId",
          foreignField: "_id",
          as: "student",
        },
      },
      { $unwind: "$student" },
      {
        $project: {
          groupId: "$_id.groupId",
          studentId: "$_id.studentId",
          studentName: "$student.fullName",
          absences: "$total",
        },
      },
    ]);

    // Динамика посещаемости по дням
    const attendanceByDay = await Attendance.aggregate([
      { $match: filter },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$date" },
          },
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
        },
      },
      { $sort: { _id: 1 } },
      { $limit: 30 },
    ]);

    // Студенты с низкой посещаемостью
    const lowAttendanceStudents = await Attendance.aggregate([
      { $match: filter },
      {
        $group: {
          _id: "$studentId",
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
        },
      },
      {
        $match: {
          total: { $gte: 4 }, // Минимум 4 тренировки
        },
      },
      {
        $project: {
          studentId: "$_id",
          total: 1,
          present: 1,
          attendanceRate: {
            $multiply: [{ $divide: ["$present", "$total"] }, 100],
          },
        },
      },
      {
        $match: {
          attendanceRate: { $lt: 70 }, // Меньше 70%
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "studentId",
          foreignField: "_id",
          as: "student",
        },
      },
      { $unwind: "$student" },
      {
        $lookup: {
          from: "groups",
          localField: "student.groupId",
          foreignField: "_id",
          as: "group",
        },
      },
      { $unwind: { path: "$group", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          studentName: "$student.fullName",
          studentPhone: "$student.phoneNumber",
          groupName: "$group.name",
          total: 1,
          present: 1,
          attendanceRate: 1,
        },
      },
      { $sort: { attendanceRate: 1 } },
      { $limit: 20 },
    ]);

    // Лучшие студенты по посещаемости
    const topAttendanceStudents = await Attendance.aggregate([
      { $match: filter },
      {
        $group: {
          _id: "$studentId",
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
        },
      },
      {
        $match: {
          total: { $gte: 8 }, // Минимум 8 тренировок
        },
      },
      {
        $project: {
          studentId: "$_id",
          total: 1,
          present: 1,
          attendanceRate: {
            $multiply: [{ $divide: ["$present", "$total"] }, 100],
          },
        },
      },
      {
        $match: {
          attendanceRate: { $gte: 90 }, // 90% и выше
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "studentId",
          foreignField: "_id",
          as: "student",
        },
      },
      { $unwind: "$student" },
      {
        $lookup: {
          from: "groups",
          localField: "student.groupId",
          foreignField: "_id",
          as: "group",
        },
      },
      { $unwind: { path: "$group", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          studentName: "$student.fullName",
          groupName: "$group.name",
          total: 1,
          present: 1,
          attendanceRate: 1,
        },
      },
      { $sort: { attendanceRate: -1, present: -1 } },
      { $limit: 10 },
    ]);

    res.json({
      overall: {
        total: totalAttendance,
        present: presentCount,
        absent: absentCount,
        attendanceRate: parseFloat(overallRate),
      },
      byGroup: attendanceByGroup.map((group) => {
        const absences = absentByGroup.filter((a) =>
          a.groupId.equals(group.groupId)
        );
        return { ...group, absences };
      }),
      byDay: attendanceByDay,
      lowAttendanceStudents,
      topAttendanceStudents,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Сравнение групп
const compareGroups = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { startDate, endDate } = req.query;

    // Получаем все группы с их статистикой
    const groups = await Group.find().populate("trainerId", "fullName");

    const groupsComparison = await Promise.all(
      groups.map(async (group) => {
        const filter = { groupId: group._id };

        if (startDate || endDate) {
          filter.date = {};
          if (startDate) filter.date.$gte = new Date(startDate);
          if (endDate) filter.date.$lte = new Date(endDate);
        }

        // Посещаемость
        const totalAttendance = await Attendance.countDocuments(filter);
        const presentCount = await Attendance.countDocuments({
          ...filter,
          status: "present",
        });

        // Платежи
        const paymentsFilter = { groupId: group._id };
        if (startDate || endDate) {
          paymentsFilter.createdAt = {};
          if (startDate) paymentsFilter.createdAt.$gte = new Date(startDate);
          if (endDate) paymentsFilter.createdAt.$lte = new Date(endDate);
        }

        const totalPayments = await Payment.countDocuments(paymentsFilter);
        const paidPayments = await Payment.countDocuments({
          ...paymentsFilter,
          status: "paid",
        });
        const revenue = await Payment.aggregate([
          { $match: { ...paymentsFilter, status: "paid" } },
          { $group: { _id: null, total: { $sum: "$amount" } } },
        ]);

        // Количество студентов
        const studentsCount = await User.countDocuments({
          groupId: group._id,
          userType: { $in: ["student"] },
        });

        return {
          groupId: group._id,
          groupName: group.name,
          trainerName: group.trainerId.fullName,
          studentsCount,
          attendance: {
            total: totalAttendance,
            present: presentCount,
            rate:
              totalAttendance > 0
                ? ((presentCount / totalAttendance) * 100).toFixed(2)
                : 0,
          },
          payments: {
            total: totalPayments,
            paid: paidPayments,
            rate:
              totalPayments > 0
                ? ((paidPayments / totalPayments) * 100).toFixed(2)
                : 0,
          },
          revenue: revenue[0]?.total || 0,
        };
      })
    );

    // Сортируем по доходу
    groupsComparison.sort((a, b) => b.revenue - a.revenue);

    res.json(groupsComparison);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Общий дашборд
const getDashboard = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("director")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    // Быстрая статистика
    const totalStudents = await User.countDocuments({
      userType: { $in: ["student"] },
    });
    const totalGroups = await Group.countDocuments();
    const totalTrainers = await User.countDocuments({
      userType: { $in: ["trainer"] },
    });

    // Финансы за текущий месяц
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const monthRevenue = await Payment.aggregate([
      {
        $match: {
          status: "paid",
          paidAt: { $gte: startOfMonth, $lte: endOfMonth },
        },
      },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // Посещаемость за последние 7 дней
    const last7Days = new Date(now);
    last7Days.setDate(last7Days.getDate() - 7);

    const recentAttendance = await Attendance.aggregate([
      { $match: { date: { $gte: last7Days } } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
        },
      },
    ]);

    // Неоплаченные платежи
    const unpaidPayments = await Payment.countDocuments({ status: "unpaid" });

    // Ожидающие заказы
    const pendingOrders = await Order.countDocuments({ status: "pending" });

    // Pending студентов
    const pendingStudents = await User.countDocuments({
      userType: { $in: ["student"] },
      status: "pending",
    });

    // ТОП-3 группы по посещаемости (последние 30 дней)
    const last30Days = new Date(now);
    last30Days.setDate(last30Days.getDate() - 30);

    const topGroupsByAttendance = await Attendance.aggregate([
      { $match: { date: { $gte: last30Days } } },
      {
        $group: {
          _id: "$groupId",
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] },
          },
        },
      },
      {
        $lookup: {
          from: "groups",
          localField: "_id",
          foreignField: "_id",
          as: "group",
        },
      },
      { $unwind: "$group" },
      {
        $project: {
          groupId: "$_id",
          groupName: "$group.name",
          attendanceRate: {
            $cond: [
              { $gt: ["$total", 0] },
              {
                $multiply: [{ $divide: ["$present", "$total"] }, 100],
              },
              0,
            ],
          },
        },
      },
      { $sort: { attendanceRate: -1 } },
      { $limit: 3 },
    ]);

    const topTrainersByPhotoReports = await PhotoReport.aggregate([
      {
        $match: {
          createdAt: { $gte: last30Days },
          type: { $in: ["training_before", "training_after"] },
        },
      },
      {
        $group: {
          _id: "$authorId",
          reports: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "trainer",
        },
      },
      { $unwind: "$trainer" },
      {
        $project: {
          trainerId: "$_id",
          trainerName: "$trainer.fullName",
          reports: 1,
        },
      },
      { $sort: { reports: -1 } },
      { $limit: 3 },
    ]);

    // Последние 5 фотоотчётов
    const latestPhotoReportsRaw = await PhotoReport.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate("authorId", "fullName userType");

    const latestPhotoReports = latestPhotoReportsRaw.map((report) => {
      const typeLabels = {
        training_before: "Фото ДО тренировки",
        training_after: "Фото ПОСЛЕ тренировки",
        cleaning: "Уборка",
      };
      const doc = report.toObject({ getters: true });
      return {
        ...doc,
        typeLabel: typeLabels[report.type] || report.type,
      };
    });

    res.json({
      overview: {
        totalStudents,
        totalGroups,
        totalTrainers,
        unpaidPayments,
        pendingOrders,
        pendingStudents,
      },
      currentMonth: {
        revenue: monthRevenue[0]?.total || 0,
        startDate: startOfMonth,
        endDate: endOfMonth,
      },
      recentAttendance: {
        total: recentAttendance[0]?.total || 0,
        present: recentAttendance[0]?.present || 0,
        rate:
          recentAttendance[0]?.total > 0
            ? (
                (recentAttendance[0].present / recentAttendance[0].total) *
                100
              ).toFixed(2)
            : 0,
      },
      highlights: {
        topGroupsByAttendance,
        topTrainersByPhotoReports,
        latestPhotoReports,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getFinancialAnalytics,
  getStudentsAnalytics,
  getPaymentsAnalytics,
  exportAnalytics,
  getAttendanceAnalytics, // НОВОЕ
  compareGroups, // НОВОЕ
  getDashboard,
};
