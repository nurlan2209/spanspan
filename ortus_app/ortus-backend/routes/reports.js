const express = require("express");
const multer = require("multer");
const {
  createReport,
  getMyReports,
  deleteReport,
  getReports,
} = require("../controllers/reportController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

const storage = multer.memoryStorage();
const allowedReportMime = new Set([
  "image/jpeg",
  "image/png",
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);
const maxAttachmentSizeBytes = 10 * 1024 * 1024;
const upload = multer({
  storage,
  limits: { files: 4, fileSize: maxAttachmentSizeBytes },
  fileFilter: (req, file, cb) => {
    if (allowedReportMime.has(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Unsupported file type"));
    }
  },
});

router.post("/", protect, upload.array("attachments", 4), createReport);
router.get("/my", protect, getMyReports);
router.get("/", protect, getReports);
router.delete("/:id", protect, deleteReport);

module.exports = router;
