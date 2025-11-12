const CleaningReport = require("../models/CleaningReport");
const PhotoReport = require("../models/PhotoReport");

const allowedZones = ["hall", "locker_room", "shower", "corridor"];

const createCleaningReport = async (req, res) => {
  try {
    const isTechStaff = req.user.userType.includes("tech_staff");
    const isAdminOrDirector =
      req.user.userType.includes("admin") ||
      req.user.userType.includes("director");

    if (!isTechStaff && !isAdminOrDirector) {
      return res
        .status(403)
        .json({ message: "Only tech staff can create cleaning reports" });
    }

    const { date, zones, comment } = req.body;
    const normalizedZones = Array.isArray(zones)
      ? zones
      : zones
      ? [zones]
      : [];

    if (!normalizedZones.length) {
      return res.status(400).json({ message: "At least one zone is required" });
    }

    const invalidZone = normalizedZones.find(
      (zone) => !allowedZones.includes(zone)
    );
    if (invalidZone) {
      return res.status(400).json({ message: `Invalid zone: ${invalidZone}` });
    }

    const photos = req.files?.map((file) => file.path) || [];
    if (!photos.length) {
      return res
        .status(400)
        .json({ message: "At least one photo is required" });
    }

    const cleaningReport = await CleaningReport.create({
      staffId: req.user._id,
      date: date ? new Date(date) : new Date(),
      zones: normalizedZones,
      photos,
      comment,
    });

    await PhotoReport.create({
      type: "cleaning",
      authorId: req.user._id,
      relatedId: cleaningReport._id,
      relatedModel: "CleaningReport",
      photos,
      comment,
    });

    await cleaningReport.populate("staffId", "fullName phoneNumber");

    res.status(201).json(cleaningReport);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getCleaningReports = async (req, res) => {
  try {
    const isTechStaff = req.user.userType.includes("tech_staff");
    const isAdminOrDirector =
      req.user.userType.includes("admin") ||
      req.user.userType.includes("director");
    const isManager = req.user.userType.includes("manager");

    if (!isTechStaff && !isAdminOrDirector && !isManager) {
      return res
        .status(403)
        .json({ message: "Access denied to cleaning reports" });
    }

    const { dateFrom, dateTo, staffId } = req.query;
    const filter = {};

    if (dateFrom || dateTo) {
      filter.date = {};
      if (dateFrom) filter.date.$gte = new Date(dateFrom);
      if (dateTo) filter.date.$lte = new Date(dateTo);
    }

    if (isTechStaff && !isAdminOrDirector && !isManager) {
      filter.staffId = req.user._id;
    } else if (staffId) {
      filter.staffId = staffId;
    }

    const reports = await CleaningReport.find(filter)
      .populate("staffId", "fullName phoneNumber")
      .sort({ date: -1, createdAt: -1 });

    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createCleaningReport,
  getCleaningReports,
};
