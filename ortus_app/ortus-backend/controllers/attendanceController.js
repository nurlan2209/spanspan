const Attendance = require("../models/Attendance");
const Schedule = require("../models/Schedule");
const Group = require("../models/Group");
const User = require("../models/User");
const PhotoReport = require("../models/PhotoReport");

// Создать записи посещаемости для группы на дату (тренер)
const createAttendanceForGroup = async (req, res) => {
  try {
    if (!req.user.userType.includes("trainer")) {
      return res
        .status(403)
        .json({ message: "Only trainers can mark attendance" });
    }

    const { groupId, scheduleId, date } = req.body;

    let group = await Group.findById(groupId).populate("students");
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    // Проверка, что тренер владеет группой
    if (group.trainerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not your group" });
    }

    const schedule = await Schedule.findById(scheduleId);
    if (!schedule) {
      return res.status(404).json({ message: "Schedule not found" });
    }

    let students = group.students || [];
    if (students.length === 0) {
      students = await User.find({ groupId: groupId }).select("_id");
    }
    if (students.length === 0) {
      return res
        .status(400)
        .json({ message: "В группе нет студентов для отметки" });
    }

    const attendanceDate = new Date(date);
    const records = [];

    for (const student of students) {
      try {
        const attendance = await Attendance.create({
          scheduleId,
          groupId,
          studentId: student._id,
          date: attendanceDate,
          status: "absent",
          markedBy: req.user._id,
        });
        records.push(attendance);
      } catch (error) {
        // Если запись уже существует, пропускаем
        if (error.code !== 11000) {
          throw error;
        }
      }
    }

    const populatedRecords = await Attendance.find({
      groupId,
      date: attendanceDate,
    })
      .populate("studentId", "fullName phoneNumber")
      .populate("scheduleId");

    res.status(201).json(populatedRecords);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Отметить посещаемость студента (тренер)
const markAttendance = async (req, res) => {
  try {
    if (!req.user.userType.includes("trainer")) {
      return res
        .status(403)
        .json({ message: "Only trainers can mark attendance" });
    }

    const { status, note } = req.body;

    const attendance = await Attendance.findById(req.params.id).populate(
      "groupId"
    );

    if (!attendance) {
      return res.status(404).json({ message: "Attendance record not found" });
    }

    // Проверка, что тренер владеет группой
    if (attendance.groupId.trainerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not your group" });
    }

    attendance.status = status;
    if (note) attendance.note = note;
    attendance.markedBy = req.user._id;

    if (
      attendance.scheduleId &&
      ["present", "absent", "sick"].includes(status)
    ) {
      const hasAfterPhoto = await PhotoReport.exists({
        type: "training_after",
        relatedId: attendance.scheduleId,
      });

      if (!hasAfterPhoto) {
        return res.status(400).json({
          message:
            "Загрузите фото ПОСЛЕ тренировки в разделе фотоотчётов прежде чем закрывать посещаемость.",
        });
      }
    }

    await attendance.save();
    await attendance.populate("studentId", "fullName phoneNumber");

    res.json(attendance);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить посещаемость группы на дату
const getGroupAttendanceByDate = async (req, res) => {
  try {
    const { groupId, date } = req.params;

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

    const attendanceDate = new Date(date);
    const records = await Attendance.find({
      groupId,
      date: attendanceDate,
    })
      .populate("studentId", "fullName phoneNumber")
      .populate("scheduleId")
      .sort({ "studentId.fullName": 1 });

    res.json(records);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить посещаемость студента
const getStudentAttendance = async (req, res) => {
  try {
    const { studentId } = req.params;
    const { startDate, endDate } = req.query;

    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).json({ message: "Student not found" });
    }

    // Проверка доступа
    const isOwner = req.user._id.toString() === studentId;
    const isParent =
      student.parentId &&
      student.parentId.toString() === req.user._id.toString();
    const isAdmin = req.user.userType.includes("admin");
    const isTrainer =
      student.groupId &&
      (await Group.findOne({
        _id: student.groupId,
        trainerId: req.user._id,
      }));

    if (!isOwner && !isParent && !isAdmin && !isTrainer) {
      return res.status(403).json({ message: "Access denied" });
    }

    const filter = { studentId };

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    const records = await Attendance.find(filter)
      .populate("groupId", "name")
      .populate("scheduleId")
      .sort({ date: -1 });

    res.json(records);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить статистику посещаемости студента
const getStudentAttendanceStats = async (req, res) => {
  try {
    const { studentId } = req.params;
    const { startDate, endDate } = req.query;

    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).json({ message: "Student not found" });
    }

    // Проверка доступа (аналогично getStudentAttendance)
    const isOwner = req.user._id.toString() === studentId;
    const isParent =
      student.parentId &&
      student.parentId.toString() === req.user._id.toString();
    const isAdmin = req.user.userType.includes("admin");

    if (!isOwner && !isParent && !isAdmin) {
      return res.status(403).json({ message: "Access denied" });
    }

    const filter = { studentId };

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    const total = await Attendance.countDocuments(filter);
    const present = await Attendance.countDocuments({
      ...filter,
      status: "present",
    });
    const absent = await Attendance.countDocuments({
      ...filter,
      status: "absent",
    });
    const sick = await Attendance.countDocuments({ ...filter, status: "sick" });
    const competition = await Attendance.countDocuments({
      ...filter,
      status: "competition",
    });
    const excused = await Attendance.countDocuments({
      ...filter,
      status: "excused",
    });

    res.json({
      total,
      present,
      absent,
      sick,
      competition,
      excused,
      attendanceRate: total > 0 ? ((present / total) * 100).toFixed(2) : 0,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить статистику по группе
const getGroupAttendanceStats = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { startDate, endDate } = req.query;

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

    const filter = { groupId };

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    const total = await Attendance.countDocuments(filter);
    const present = await Attendance.countDocuments({
      ...filter,
      status: "present",
    });
    const absent = await Attendance.countDocuments({
      ...filter,
      status: "absent",
    });
    const sick = await Attendance.countDocuments({ ...filter, status: "sick" });

    res.json({
      total,
      present,
      absent,
      sick,
      attendanceRate: total > 0 ? ((present / total) * 100).toFixed(2) : 0,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createAttendanceForGroup,
  markAttendance,
  getGroupAttendanceByDate,
  getStudentAttendance,
  getStudentAttendanceStats,
  getGroupAttendanceStats,
};
