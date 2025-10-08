const mongoose = require("mongoose");

const scheduleSchema = new mongoose.Schema({
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Group",
    required: true,
  },
  dayOfWeek: { type: Number, required: true, min: 0, max: 6 }, // 0=Пн, 6=Вс
  startTime: { type: String, required: true }, // "18:00"
  endTime: { type: String, required: true }, // "20:00"
  location: { type: String, default: "Зал ORTUS" },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Schedule", scheduleSchema);
