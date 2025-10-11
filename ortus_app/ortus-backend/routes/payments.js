const express = require("express");
const {
  createPayment,
  getStudentPayments,
  getGroupPayments,
  getUnpaidPayments,
  markAsPaid,
  getPaymentStats,
} = require("../controllers/paymentController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/", protect, createPayment);
router.get("/student/:studentId", protect, getStudentPayments);
router.get("/group/:groupId", protect, getGroupPayments);
router.get("/unpaid", protect, getUnpaidPayments);
router.patch("/:id/mark-paid", protect, markAsPaid);
router.get("/stats", protect, getPaymentStats);

module.exports = router;
