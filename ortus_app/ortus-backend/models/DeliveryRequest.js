const mongoose = require("mongoose");

const deliveryRequestSchema = new mongoose.Schema(
  {
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true,
      unique: true,
    },
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    studentName: { type: String, required: true },
    phoneNumber: { type: String, required: true },
    summary: { type: String, default: "" },
    pickupAddress: { type: String, default: "Зал ORTUS" },
    desiredMethod: { type: String, default: "delivery" },
    status: {
      type: String,
      enum: ["new", "in_progress", "delivered", "cancelled"],
      default: "new",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("DeliveryRequest", deliveryRequestSchema);
