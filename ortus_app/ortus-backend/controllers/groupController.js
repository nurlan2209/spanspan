const Group = require("../models/Group");
const JoinRequest = require("../models/JoinRequest");
const User = require("../models/User");

const createGroup = async (req, res) => {
  try {
    const { name } = req.body;

    if (req.user.userType !== "trainer") {
      return res
        .status(403)
        .json({ message: "Only trainers can create groups" });
    }

    const group = await Group.create({ name, trainerId: req.user._id });
    res.status(201).json(group);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllGroups = async (req, res) => {
  try {
    const groups = await Group.find().populate("trainerId", "fullName");
    res.json(groups);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getJoinRequests = async (req, res) => {
  try {
    const groups = await Group.find({ trainerId: req.user._id });
    const groupIds = groups.map((g) => g._id);

    const requests = await JoinRequest.find({
      groupId: { $in: groupIds },
      status: "pending",
    })
      .populate("studentId", "fullName phoneNumber")
      .populate("groupId", "name");

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const handleJoinRequest = async (req, res) => {
  try {
    const { requestId, action } = req.body;

    const request = await JoinRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    if (action === "approve") {
      request.status = "approved";
      await User.findByIdAndUpdate(request.studentId, {
        groupId: request.groupId,
      });
      await Group.findByIdAndUpdate(request.groupId, {
        $push: { students: request.studentId },
      });
    } else {
      request.status = "rejected";
    }

    await request.save();
    res.json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createGroup,
  getAllGroups,
  getJoinRequests,
  handleJoinRequest,
};
