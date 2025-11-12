const mongoose = require("mongoose");

const newsSchema = new mongoose.Schema({
  title: { type: String, required: true },
  content: { type: String, required: true },
  newsType: {
    type: String,
    enum: ["group", "general"],
    default: "group",
  },
  category: {
    type: String,
    enum: ["general", "tournament", "event", "announcement"],
    default: "general",
  },
  images: [{ type: String }],
  targetGroups: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Group",
    },
  ], // Если пусто - для всех
  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  isPinned: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

newsSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model("News", newsSchema);
