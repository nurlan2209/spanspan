const TrainingSession = require("../models/TrainingSession");
const Schedule = require("../models/Schedule");
const PhotoReport = require("../models/PhotoReport");
const { getDayRange, normalizeDate } = require("../utils/dateUtils");

const hasTrainerPrivileges = (user) =>
  user.userType.includes("admin") ||
  user.userType.includes("director") ||
  user.userType.includes("trainer");

const ensureScheduleAccess = async (scheduleId, user) => {
  const schedule = await Schedule.findById(scheduleId).populate({
    path: "groupId",
    select: "trainerId",
  });

  if (!schedule) {
    return { error: { status: 404, message: "Schedule not found" } };
  }

  if (
    !schedule.groupId ||
    !schedule.groupId.trainerId ||
    schedule.groupId.trainerId.toString() !== user._id.toString()
  ) {
    const isAdminOrDirector =
      user.userType.includes("admin") || user.userType.includes("director");

    if (!isAdminOrDirector) {
      return { error: { status: 403, message: "Not authorized for this schedule" } };
    }
  }

  return { schedule };
};

const startSession = async (req, res) => {
  try {
    if (!hasTrainerPrivileges(req.user)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { scheduleId, date } = req.body;
    if (!scheduleId) {
      return res.status(400).json({ message: "scheduleId is required" });
    }

    const sessionDate = normalizeDate(date || new Date());
    if (!sessionDate) {
      return res
        .status(400)
        .json({ message: "Invalid session date provided" });
    }

    const { schedule, error } = await ensureScheduleAccess(scheduleId, req.user);
    if (error) {
      return res.status(error.status).json({ message: error.message });
    }

    const { startOfDay, endOfDay } = getDayRange(sessionDate);
    const beforePhoto = await PhotoReport.findOne({
      type: "training_before",
      relatedId: scheduleId,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    }).sort({ createdAt: -1 });

    if (!beforePhoto) {
      return res.status(400).json({
        message:
          "Сначала загрузите фото ДО тренировки. Сделайте это в разделе фотоотчётов.",
      });
    }

    const existingSession = await TrainingSession.findOne({
      scheduleId,
      sessionDate,
    });

    if (existingSession && existingSession.status === "finished") {
      return res
        .status(400)
        .json({ message: "Эта тренировка уже завершена." });
    }

    const session = await TrainingSession.findOneAndUpdate(
      { scheduleId, sessionDate },
      {
        $set: {
          groupId: schedule.groupId._id,
          trainerId: schedule.groupId.trainerId,
          status: "started",
          startedAt: new Date(),
          beforePhotoReportId: beforePhoto._id,
        },
        $setOnInsert: { sessionDate },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.json({ session });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const finishSession = async (req, res) => {
  try {
    if (!hasTrainerPrivileges(req.user)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { scheduleId, date } = req.body;
    if (!scheduleId) {
      return res.status(400).json({ message: "scheduleId is required" });
    }

    const sessionDate = normalizeDate(date || new Date());
    if (!sessionDate) {
      return res
        .status(400)
        .json({ message: "Invalid session date provided" });
    }

    const { schedule, error } = await ensureScheduleAccess(scheduleId, req.user);
    if (error) {
      return res.status(error.status).json({ message: error.message });
    }

    const session = await TrainingSession.findOne({
      scheduleId,
      sessionDate,
    });

    if (!session) {
      return res.status(400).json({
        message: "Тренировка ещё не начата. Сначала начните её через расписание.",
      });
    }

    if (session.status === "finished") {
      return res
        .status(200)
        .json({ session, message: "Тренировка уже завершена." });
    }

    const { startOfDay, endOfDay } = getDayRange(sessionDate);
    const afterPhoto = await PhotoReport.findOne({
      type: "training_after",
      relatedId: scheduleId,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    }).sort({ createdAt: -1 });

    if (!afterPhoto) {
      return res.status(400).json({
        message:
          "Сначала загрузите фото ПОСЛЕ тренировки. Сделайте это в разделе фотоотчётов.",
      });
    }

    session.status = "finished";
    session.finishedAt = new Date();
    session.afterPhotoReportId = afterPhoto._id;
    await session.save();

    res.json({ session });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getSessionStatuses = async (req, res) => {
  try {
    if (!hasTrainerPrivileges(req.user)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { scheduleIds, date } = req.query;
    if (!scheduleIds) {
      return res
        .status(400)
        .json({ message: "scheduleIds query parameter is required" });
    }

    const ids = scheduleIds
      .split(",")
      .map((id) => id.trim())
      .filter(Boolean);

    if (!ids.length) {
      return res.status(400).json({ message: "No valid scheduleIds provided" });
    }

    const sessionDate = normalizeDate(date || new Date());
    if (!sessionDate) {
      return res
        .status(400)
        .json({ message: "Invalid session date provided" });
    }

    const schedules = await Schedule.find({ _id: { $in: ids } }).populate({
      path: "groupId",
      select: "trainerId",
    });

    if (schedules.length !== ids.length) {
      return res.status(404).json({ message: "One or more schedules not found" });
    }

    const unauthorized = schedules.some((schedule) => {
      if (!schedule.groupId || !schedule.groupId.trainerId) {
        return true;
      }
      const isOwner =
        schedule.groupId.trainerId.toString() === req.user._id.toString();
      const isAdminOrDirector =
        req.user.userType.includes("admin") ||
        req.user.userType.includes("director");
      return !isOwner && !isAdminOrDirector;
    });

    if (unauthorized) {
      return res.status(403).json({ message: "Not authorized for some schedules" });
    }

    const sessions = await TrainingSession.find({
      scheduleId: { $in: ids },
      sessionDate,
    }).lean();

    const statuses = {};
    ids.forEach((id) => {
      statuses[id] = "not_started";
    });

    sessions.forEach((session) => {
      statuses[session.scheduleId.toString()] = session.status;
    });

    res.json({ date: sessionDate, statuses });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  startSession,
  finishSession,
  getSessionStatuses,
};
