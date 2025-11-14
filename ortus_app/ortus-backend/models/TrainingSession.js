const mongoose = require("mongoose");

const trainingSessionSchema = new mongoose.Schema(
  {
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
    trainerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    sessionDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ["not_started", "started", "finished"],
      default: "not_started",
    },
    startedAt: { type: Date },
    finishedAt: { type: Date },
    beforePhotoReportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PhotoReport",
    },
    afterPhotoReportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PhotoReport",
    },
  },
  { timestamps: true }
);

trainingSessionSchema.index({ scheduleId: 1, sessionDate: 1 }, { unique: true });

module.exports = mongoose.model("TrainingSession", trainingSessionSchema);
