const express = require("express");
const multer = require("multer");
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const cloudinary = require("../config/cloudinary");
const {
  createPhotoReport,
  getPhotoReports,
  getPhotoReportById,
} = require("../controllers/photoReportController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "ortus-photo-reports",
    allowed_formats: ["jpg", "jpeg", "png", "webp"],
  },
});

const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

router.post("/", protect, upload.array("photos", 10), createPhotoReport);
router.get("/", protect, getPhotoReports);
router.get("/:id", protect, getPhotoReportById);

module.exports = router;
