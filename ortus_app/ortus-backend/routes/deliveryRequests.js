const express = require("express");
const {
  createDeliveryRequest,
  getAllRequests,
  updateRequestStatus,
} = require("../controllers/deliveryRequestController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

router.post("/", protect, createDeliveryRequest);
router.get("/", protect, getAllRequests);
router.patch("/:id/status", protect, updateRequestStatus);

module.exports = router;
