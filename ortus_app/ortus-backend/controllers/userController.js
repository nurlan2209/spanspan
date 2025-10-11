const User = require("../models/User");

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select("-password")
      .populate("groupId")
      .populate("children", "fullName phoneNumber groupId weight dateOfBirth")
      .populate("parentId", "fullName phoneNumber");
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { weight, groupId } = req.body;
    const user = await User.findById(req.user._id);

    if (weight) user.weight = weight;
    if (groupId && user.userType.includes("student")) user.groupId = groupId;

    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addChild = async (req, res) => {
  try {
    const { childId } = req.body;

    if (!req.user.userType.includes("parent")) {
      return res.status(403).json({ message: "Only parents can add children" });
    }

    const child = await User.findById(childId);
    if (!child || !child.userType.includes("student")) {
      return res.status(404).json({ message: "Student not found" });
    }

    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { children: childId },
    });

    await User.findByIdAndUpdate(childId, {
      parentId: req.user._id,
    });

    res.json({ message: "Child added successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getProfile, updateProfile, addChild };
