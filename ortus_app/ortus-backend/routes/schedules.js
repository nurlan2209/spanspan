const express = require("express");
const {
  createSchedule,
  getScheduleByGroup,
  getAllSchedules,
  deleteSchedule,
} = require("../controllers/scheduleController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/", protect, createSchedule);
router.get("/", getAllSchedules);
router.get("/group/:groupId", getScheduleByGroup);
router.delete("/:id", protect, deleteSchedule);

module.exports = router;
