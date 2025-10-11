const express = require("express");
const {
  createOrder,
  getUserOrders,
  getOrderById,
  getAllOrders,
  updateOrderStatus,
  cancelOrder,
} = require("../controllers/orderController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/", protect, createOrder);
router.get("/my-orders", protect, getUserOrders);
router.get("/all", protect, getAllOrders);
router.get("/:id", protect, getOrderById);
router.patch("/:id/status", protect, updateOrderStatus);
router.patch("/:id/cancel", protect, cancelOrder);

module.exports = router;
