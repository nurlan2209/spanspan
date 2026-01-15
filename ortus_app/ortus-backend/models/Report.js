const mongoose = require("mongoose");

const attachmentSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, required: true },
    resourceType: { type: String, required: true },
    fileType: { type: String, required: true },
    originalName: { type: String, default: "" },
  },
  { _id: false }
);

const reportSchema = new mongoose.Schema(
  {
    trainerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    trainingDate: { type: Date, required: true },
    slot: { type: String, required: true },
    comment: { type: String, default: "" },
    attachments: { type: [attachmentSchema], default: [] },
    isLate: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Report", reportSchema);
