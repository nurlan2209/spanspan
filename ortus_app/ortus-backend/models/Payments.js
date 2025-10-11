const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Group",
    required: true,
  },
  amount: { type: Number, required: true },
  month: { type: Number, required: true, min: 1, max: 12 }, // месяц (1-12)
  year: { type: Number, required: true }, // год (2025)
  status: {
    type: String,
    enum: ["unpaid", "paid"],
    default: "unpaid",
  },
  paymentMethod: {
    type: String,
    enum: ["card", "kaspi", "cash", "manual"],
    default: "manual",
  },
  paidAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
});

// Уникальный индекс: один платёж на студента на месяц
paymentSchema.index({ studentId: 1, month: 1, year: 1 }, { unique: true });

module.exports = mongoose.model("Payment", paymentSchema);
