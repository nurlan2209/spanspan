const express = require("express");
const multer = require("multer");
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const cloudinary = require("../config/cloudinary");
const {
  createCleaningReport,
  getCleaningReports,
} = require("../controllers/cleaningReportController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "ortus-cleaning-reports",
    allowed_formats: ["jpg", "jpeg", "png", "webp"],
  },
});

const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

router.post("/", protect, upload.array("photos", 5), createCleaningReport);
router.get("/", protect, getCleaningReports);

module.exports = router;
