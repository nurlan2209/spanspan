const express = require("express");
const {
  createAttendanceForGroup,
  markAttendance,
  getGroupAttendanceByDate,
  getStudentAttendance,
  getStudentAttendanceStats,
  getGroupAttendanceStats,
} = require("../controllers/attendanceController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/", protect, createAttendanceForGroup);
router.patch("/:id", protect, markAttendance);
router.get("/group/:groupId/:date", protect, getGroupAttendanceByDate);
router.get("/student/:studentId", protect, getStudentAttendance);
router.get("/student/:studentId/stats", protect, getStudentAttendanceStats);
router.get("/group/:groupId/stats", protect, getGroupAttendanceStats);

module.exports = router;
