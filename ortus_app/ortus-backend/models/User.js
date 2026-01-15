const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema({
  phoneNumber: { type: String, required: true, unique: true },
  fullName: { type: String, required: true },
  role: {
    type: String,
    enum: ["director", "manager", "trainer", "client"],
    default: "client",
  },
  status: {
    type: String,
    enum: ["active", "inactive"],
    default: "active",
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
