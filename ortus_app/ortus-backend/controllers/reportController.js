const Report = require("../models/Report");
const { saveFile } = require("../utils/localUpload");
const { slots, canSubmitAt, isLateAt } = require("../utils/reportTiming");

const allowedMime = new Set([
  "image/jpeg",
  "image/png",
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);

const createReport = async (req, res) => {
  try {
    const { trainingDate, slot, comment } = req.body;
    if (!trainingDate || !slot) return res.status(400).json({ message: "Дата и слот обязательны" });
    if (!slots.includes(slot)) return res.status(400).json({ message: "Invalid slot" });

    const dateValue = new Date(trainingDate);
    if (Number.isNaN(dateValue.getTime())) return res.status(400).json({ message: "Invalid date" });

    const files = req.files || [];
    if (!files.length) return res.status(400).json({ message: "Добавьте вложения" });
    if (files.length > 4) return res.status(400).json({ message: "Максимум 4 вложения" });

    const now = new Date();
    if (!canSubmitAt(dateValue, slot, now)) {
      return res.status(400).json({ message: "Отправка доступна за 60 минут до тренировки" });
    }

    const attachments = [];
    for (const file of files) {
      if (!allowedMime.has(file.mimetype)) return res.status(400).json({ message: "Unsupported file type" });
      const resourceType = file.mimetype.startsWith("image/") ? "image" : "raw";
      const uploaded = saveFile(file.buffer, "reports", file.originalname);
      attachments.push({
        url: uploaded.secure_url,
        publicId: uploaded.public_id,
        resourceType,
        fileType: file.mimetype,
        originalName: file.originalname,
      });
    }

    const report = await Report.create({
      trainerId: req.user._id,
      trainingDate: dateValue,
      slot,
      comment: comment || "",
      attachments,
      isLate: isLateAt(dateValue, slot, now),
    });
    res.status(201).json(report);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getMyReports = async (req, res) => {
  try {
    const reports = await Report.findByTrainerId(req.user._id);
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteReport = async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    if (!report) return res.status(404).json({ message: "Report not found" });
    if (report.trainerId !== req.user._id) return res.status(403).json({ message: "Access denied" });
    await Report.deleteById(req.params.id);
    res.json({ message: "Report deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getReports = async (req, res) => {
  try {
    const { dateFrom, dateTo, trainerId, isLate } = req.query;
    const filter = {};
    if (trainerId) filter.trainerId = trainerId;
    if (dateFrom) filter.dateFrom = dateFrom;
    if (dateTo) filter.dateTo = dateTo;
    if (isLate === "true") filter.isLate = true;
    else if (isLate === "false") filter.isLate = false;
    const reports = await Report.findAll(filter);
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createReport, getMyReports, deleteReport, getReports, slots };
