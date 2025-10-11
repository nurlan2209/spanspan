const express = require("express");
const {
  getFinancialAnalytics,
  getStudentsAnalytics,
  getPaymentsAnalytics,
  exportAnalytics,
  getAttendanceAnalytics, // НОВОЕ
  compareGroups, // НОВОЕ
  getDashboard, // НОВОЕ
} = require("../controllers/analyticsController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.get("/financial", protect, getFinancialAnalytics);
router.get("/students", protect, getStudentsAnalytics);
router.get("/payments", protect, getPaymentsAnalytics);
router.get("/attendance", protect, getAttendanceAnalytics); // НОВОЕ
router.get("/compare-groups", protect, compareGroups); // НОВОЕ
router.get("/dashboard", protect, getDashboard); // НОВОЕ
router.get("/export", protect, exportAnalytics);

module.exports = router;
