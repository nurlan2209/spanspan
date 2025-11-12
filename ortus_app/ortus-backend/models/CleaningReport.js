const mongoose = require("mongoose");

const cleaningReportSchema = new mongoose.Schema(
  {
    staffId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: { type: Date, required: true },
    zones: [
      {
        type: String,
        enum: ["hall", "locker_room", "shower", "corridor"],
      },
    ],
    photos: [{ type: String, required: true }],
    comment: { type: String, default: "" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("CleaningReport", cleaningReportSchema);
