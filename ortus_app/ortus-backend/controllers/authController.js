const User = require("../models/User");
const JoinRequest = require("../models/JoinRequest");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  try {
    const {
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      weight,
      userType,
      groupId,
      password,
    } = req.body;

    const userExists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const user = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      weight,
      userType,
      password,
    });

    if (userType === "student" && groupId) {
      await JoinRequest.create({
        studentId: user._id,
        groupId,
        status: "pending",
      });
    }

    const token = generateToken(user._id);
    res.status(201).json({ user, token });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    const user = await User.findOne({ phoneNumber }).populate("groupId");
    if (user && (await user.matchPassword(password))) {
      const token = generateToken(user._id);
      res.json({ user, token });
    } else {
      res.status(401).json({ message: "Invalid credentials" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { register, login };
