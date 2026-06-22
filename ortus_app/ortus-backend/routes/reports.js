const express = require("express");
const multer = require("multer");
const {
  createReport,
  getMyReports,
  deleteReport,
  getReports,
} = require("../controllers/reportController");
const { protect, authorizeRoles } = require("../middlewares/authMiddleware");
const { normalizeReportMime } = require("../utils/reportMime");

const router = express.Router();

const storage = multer.memoryStorage();
const maxAttachmentSizeBytes = 10 * 1024 * 1024;
const upload = multer({
  storage,
  limits: { files: 4, fileSize: maxAttachmentSizeBytes },
  fileFilter: (req, file, cb) => {
    if (normalizeReportMime(file)) {
      cb(null, true);
    } else {
      cb(new Error("Unsupported file type"));
    }
  },
});

router.post("/", protect, authorizeRoles("trainer"), upload.array("attachments", 4), createReport);
router.get("/my", protect, authorizeRoles("trainer"), getMyReports);
router.get("/", protect, authorizeRoles("manager", "director"), getReports);
router.delete("/:id", protect, authorizeRoles("trainer"), deleteReport);

module.exports = router;
