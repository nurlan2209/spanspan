const mongoose = require("mongoose");

const attendanceSchema = new mongoose.Schema({
  scheduleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Schedule",
    required: true,
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Group",
    required: true,
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  date: { type: Date, required: true },
  status: {
    type: String,
    enum: ["present", "absent", "sick", "competition", "excused"],
    default: "absent",
  },
  note: { type: String },
  markedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

// Уникальный индекс: одна запись на студента на дату
attendanceSchema.index({ studentId: 1, date: 1 }, { unique: true });

attendanceSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model("Attendance", attendanceSchema);
