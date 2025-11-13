const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema({
  phoneNumber: { type: String, required: true, unique: true },
  iin: { type: String, required: true, unique: true, length: 12 },
  fullName: { type: String, required: true },
  dateOfBirth: { type: Date, required: true },
  userType: {
    type: [String],
    enum: [
      "student",
      "trainer",
      "parent",
      "admin",
      "tech_staff",
      "director",
      "manager",
    ],
    required: true,
  },
  status: {
    type: String,
    enum: ["pending", "active", "inactive"],
    default: "active",
  },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Group",
    default: null,
  },
  children: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
  },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model("User", userSchema);
