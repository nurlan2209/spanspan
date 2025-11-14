const PhotoReport = require("../models/PhotoReport");
const Schedule = require("../models/Schedule");
const CleaningReport = require("../models/CleaningReport");
const TrainingSession = require("../models/TrainingSession");
const { normalizeDate } = require("../utils/dateUtils");

const allowedTypes = ["training_before", "training_after", "cleaning"];

const canManageReports = (user) =>
  user.userType.some((role) =>
    ["admin", "director", "manager"].includes(role)
  );

const createPhotoReport = async (req, res) => {
  try {
    const { type, relatedId, comment } = req.body;

    if (!type || !allowedTypes.includes(type)) {
      return res.status(400).json({ message: "Invalid report type" });
    }

    const uploadedPhotos = req.files?.map((file) => file.path) || [];
    const bodyPhotos = req.body.photos
      ? Array.isArray(req.body.photos)
        ? req.body.photos
        : [req.body.photos]
      : [];
    const photos = uploadedPhotos.length ? uploadedPhotos : bodyPhotos;
    if (!photos.length) {
      return res
        .status(400)
        .json({ message: "At least one photo is required" });
    }

    const isTrainer = req.user.userType.includes("trainer");
    const isTechStaff = req.user.userType.includes("tech_staff");
    const isAdminOrDirector =
      req.user.userType.includes("admin") ||
      req.user.userType.includes("director");

    if (
      !isTrainer &&
      !isTechStaff &&
      !isAdminOrDirector
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    if (
      ["training_before", "training_after"].includes(type) &&
      !isTrainer &&
      !isAdminOrDirector
    ) {
      return res
        .status(403)
        .json({ message: "Only trainers can submit training photo reports" });
    }

    if (type === "cleaning" && !isTechStaff && !isAdminOrDirector) {
      return res
        .status(403)
        .json({ message: "Only tech staff can submit cleaning reports" });
    }

    if (
      ["training_before", "training_after"].includes(type) &&
      !relatedId
    ) {
      return res
        .status(400)
        .json({ message: "relatedId (scheduleId) is required" });
    }

    if (type === "cleaning" && !relatedId) {
      return res
        .status(400)
        .json({ message: "relatedId (cleaningReportId) is required" });
    }

    let relatedModel = null;

    let scheduleDocument = null;

    if (relatedId) {
      relatedModel = type === "cleaning" ? "CleaningReport" : "Schedule";
      if (relatedModel === "Schedule") {
        const schedule = await Schedule.findById(relatedId).populate({
          path: "groupId",
          select: "trainerId",
        });
        if (!schedule) {
          return res.status(404).json({ message: "Schedule not found" });
        }

        if (!schedule.groupId || !schedule.groupId.trainerId) {
          return res.status(400).json({
            message:
              "Schedule is missing trainer information. Обратитесь к администратору.",
          });
        }

        scheduleDocument = schedule;

        if (
          schedule.groupId.trainerId &&
          !isAdminOrDirector &&
          schedule.groupId.trainerId.toString() !== req.user._id.toString()
        ) {
          return res.status(403).json({
            message: "Cannot submit photo report for another trainer",
          });
        }
      } else if (relatedModel === "CleaningReport") {
        const cleaningReport = await CleaningReport.findById(relatedId);
        if (!cleaningReport) {
          return res.status(404).json({ message: "Cleaning report not found" });
        }
        if (
          !isAdminOrDirector &&
          cleaningReport.staffId.toString() !== req.user._id.toString()
        ) {
          return res.status(403).json({
            message: "Cannot submit photo report for another staff member",
          });
        }
      }
    }

    const report = await PhotoReport.create({
      type,
      authorId: req.user._id,
      relatedId: relatedId || null,
      relatedModel,
      photos,
      comment,
    });

    await report.populate("authorId", "fullName userType");

    if (
      scheduleDocument &&
      ["training_before", "training_after"].includes(type)
    ) {
      const sessionDate = normalizeDate(report.createdAt || new Date());
      if (sessionDate) {
        await TrainingSession.findOneAndUpdate(
          {
            scheduleId: scheduleDocument._id,
            sessionDate,
          },
          {
            $setOnInsert: {
              groupId: scheduleDocument.groupId._id,
              trainerId: scheduleDocument.groupId.trainerId,
            },
            ...(type === "training_before"
              ? { beforePhotoReportId: report._id }
              : { afterPhotoReportId: report._id }),
          },
          { upsert: true }
        );
      }
    }

    res.status(201).json(report);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getPhotoReports = async (req, res) => {
  try {
    if (
      !canManageReports(req.user) &&
      !req.user.userType.includes("trainer") &&
      !req.user.userType.includes("tech_staff")
    ) {
      return res
        .status(403)
        .json({ message: "Access denied for photo reports" });
    }

    const { type, userId, dateFrom, dateTo } = req.query;
    const filter = {};

    if (type) filter.type = type;
    if (userId) filter.authorId = userId;
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }

    if (
      !canManageReports(req.user) &&
      !userId
    ) {
      filter.authorId = req.user._id;
    }

    const reports = await PhotoReport.find(filter)
      .populate("authorId", "fullName userType")
      .sort({ createdAt: -1 });

    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getPhotoReportById = async (req, res) => {
  try {
    const report = await PhotoReport.findById(req.params.id).populate(
      "authorId",
      "fullName userType"
    );

    if (!report) {
      return res.status(404).json({ message: "Photo report not found" });
    }

    const isOwner = report.authorId._id
      ? report.authorId._id.toString() === req.user._id.toString()
      : report.authorId.toString() === req.user._id.toString();

    if (!isOwner && !canManageReports(req.user)) {
      return res.status(403).json({ message: "Access denied" });
    }

    res.json(report);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createPhotoReport,
  getPhotoReports,
  getPhotoReportById,
};
