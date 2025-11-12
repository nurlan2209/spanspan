const mongoose = require("mongoose");

const photoReportSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ["training_before", "training_after", "cleaning"],
      required: true,
    },
    authorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    relatedId: {
      type: mongoose.Schema.Types.ObjectId,
      refPath: "relatedModel",
      default: null,
    },
    relatedModel: {
      type: String,
      enum: ["Schedule", "CleaningReport", null],
      default: null,
    },
    photos: [
      {
        type: String,
        required: true,
      },
    ],
    comment: { type: String, default: "" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("PhotoReport", photoReportSchema);
