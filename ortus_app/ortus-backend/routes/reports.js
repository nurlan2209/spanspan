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
const upload = multer({
  storage,
  limits: { files: 4 },
});

router.post("/", protect, upload.array("attachments", 4), createReport);
router.get("/my", protect, getMyReports);
router.get("/", protect, getReports);
router.delete("/:id", protect, deleteReport);

module.exports = router;
