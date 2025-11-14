const User = require("../models/User");
const Group = require("../models/Group");

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select("-password")
      .populate("groupId")
      .populate("children", "fullName phoneNumber groupId dateOfBirth")
      .populate("parentId", "fullName phoneNumber")
      .populate("parents", "fullName phoneNumber");
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createUserByDirector = async (req, res) => {
  try {
    if (!req.user.userType.includes("director")) {
      return res
        .status(403)
        .json({ message: "Only directors can create users" });
    }

    const {
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      userType,
      password,
      status,
    } = req.body;

    const userExists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const normalizedRoles = Array.isArray(userType) ? userType : [userType];
    const allowedRoles = ["trainer", "manager", "tech_staff", "admin"];
    if (normalizedRoles.some((role) => !allowedRoles.includes(role))) {
      return res
        .status(400)
        .json({ message: "Directors can create only staff roles" });
    }

    const derivedStatus = status || "active";

    const user = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      userType: normalizedRoles,
      status: derivedStatus,
      password,
    });

    const userObject = user.toObject();
    delete userObject.password;

    res.status(201).json(userObject);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { groupId } = req.body;
    const user = await User.findById(req.user._id);

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
      $addToSet: { parents: req.user._id },
    });

    res.json({ message: "Child added successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createParentForStudent = async (req, res) => {
  try {
    if (!req.user.userType.includes("manager")) {
      return res
        .status(403)
        .json({ message: "Only managers can create parents for students" });
    }

    const { id } = req.params;
    const student = await User.findById(id);

    if (!student || !student.userType.includes("student")) {
      return res.status(404).json({ message: "Student not found" });
    }

    if (student.parentId) {
      return res
        .status(400)
        .json({ message: "Parent already attached to this student" });
    }

    const { phoneNumber, iin, fullName, dateOfBirth, password } = req.body;

    if (!phoneNumber || !iin || !fullName || !dateOfBirth || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const exists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (exists) {
      return res
        .status(400)
        .json({ message: "Parent with provided phone or IIN already exists" });
    }

    const parent = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      userType: ["parent"],
      status: "active",
      password,
      children: [student._id],
    });

    student.parentId = parent._id;
    student.parents = [parent._id];
    await student.save();

    const parentSafe = await User.findById(parent._id)
      .select("-password")
      .populate("children", "fullName");

    const updatedStudent = await User.findById(id)
      .select("-password")
      .populate("parentId", "fullName phoneNumber iin");

    res.status(201).json({
      message: "Parent created and attached",
      parent: parentSafe,
      student: updatedStudent,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const attachExistingParent = async (req, res) => {
  try {
    if (!req.user.userType.includes("manager")) {
      return res
        .status(403)
        .json({ message: "Only managers can attach parents" });
    }

    const { id } = req.params;
    const { parentPhone, parentIin, parentId } = req.body;

    const student = await User.findById(id);
    if (!student || !student.userType.includes("student")) {
      return res.status(404).json({ message: "Student not found" });
    }

    let parent;
    if (parentId) {
      parent = await User.findById(parentId);
    } else {
      if (!parentPhone && !parentIin) {
        return res
          .status(400)
          .json({ message: "parentPhone or parentIin is required" });
      }
      const parentQuery = {
        userType: { $in: ["parent"] },
      };
      if (parentPhone) parentQuery.phoneNumber = parentPhone;
      if (parentIin) parentQuery.iin = parentIin;
      parent = await User.findOne(parentQuery);
    }

    if (!parent) {
      return res
        .status(404)
        .json({ message: "Parent with provided data not found" });
    }

    student.parentId = parent._id;
    student.parents = student.parents || [];
    if (!student.parents.map(String).includes(parent._id.toString())) {
      student.parents.push(parent._id);
    }
    await student.save();

    await User.findByIdAndUpdate(parent._id, {
      $addToSet: { children: student._id },
    });

    const updatedStudent = await User.findById(id)
      .select("-password")
      .populate("parentId", "fullName phoneNumber iin");

    res.json({
      message: "Parent attached successfully",
      student: updatedStudent,
      parent: parent,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getParentsList = async (req, res) => {
  try {
    const canView =
      req.user.userType.includes("manager") ||
      req.user.userType.includes("director");

    if (!canView) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { search } = req.query;
    const filter = { userType: { $in: ["parent"] } };

    if (search) {
      const regex = new RegExp(search, "i");
      filter.$or = [{ fullName: regex }, { phoneNumber: regex }];
    }

    const parents = await User.find(filter)
      .select("_id fullName phoneNumber iin userType status")
      .sort({ fullName: 1 })
      .limit(20);

    res.json(parents);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getPendingStudents = async (req, res) => {
  try {
    const canManage =
      req.user.userType.includes("manager") ||
      req.user.userType.includes("director");

    if (!canManage) {
      return res
        .status(403)
        .json({ message: "Only managers or directors can view pending students" });
    }

    const { period } = req.query;
    const filter = {
      userType: { $in: ["student"] },
      status: "pending",
    };

    if (period === "day" || period === "week") {
      const now = new Date();
      const startDate = new Date(now);
      if (period === "day") {
        startDate.setDate(now.getDate() - 1);
      } else if (period === "week") {
        startDate.setDate(now.getDate() - 7);
      }
      filter.createdAt = { $gte: startDate };
    }

    const students = await User.find(filter)
      .select("-password")
      .populate("parentId", "fullName phoneNumber")
      .sort({ createdAt: -1 });

    res.json(students);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const assignStudentToGroup = async (req, res) => {
  try {
    const canManage =
      req.user.userType.includes("manager") ||
      req.user.userType.includes("director");

    if (!canManage) {
      return res
        .status(403)
        .json({ message: "Only managers or directors can assign students" });
    }

    const { id } = req.params;
    const { groupId } = req.body;

    if (!groupId) {
      return res.status(400).json({ message: "groupId is required" });
    }

    const student = await User.findById(id);

    if (!student || !student.userType.includes("student")) {
      return res.status(404).json({ message: "Student not found" });
    }

    const group = await Group.findById(groupId).populate(
      "trainerId",
      "fullName phoneNumber"
    );

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const previousGroupId = student.groupId
      ? student.groupId.toString()
      : null;

    student.groupId = groupId;
    student.status = "active";
    await student.save();

    if (previousGroupId && previousGroupId !== groupId) {
      await Group.findByIdAndUpdate(previousGroupId, {
        $pull: { students: student._id },
      });
    }

    await Group.findByIdAndUpdate(groupId, {
      $addToSet: { students: student._id },
    });

    const updatedStudent = await User.findById(id)
      .select("-password")
      .populate("groupId", "name")
      .populate("parentId", "fullName phoneNumber");

    res.json({
      message: "Student assigned successfully",
      student: updatedStudent,
      trainer: group.trainerId,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createStudentByManager = async (req, res) => {
  try {
    if (!req.user.userType.includes("manager")) {
      return res
        .status(403)
        .json({ message: "Only managers can create students or parents" });
    }

    const {
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      userType,
      password,
      groupId,
    } = req.body;

    if (!["student", "parent"].includes(userType)) {
      return res
        .status(400)
        .json({ message: "Managers can create only students or parents" });
    }

    const userExists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const status =
      userType === "student" ? (groupId ? "active" : "pending") : "active";

    const user = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      userType: [userType],
      status,
      password,
      groupId: userType === "student" ? groupId || null : null,
    });

    if (userType === "student" && groupId) {
      await Group.findByIdAndUpdate(groupId, {
        $addToSet: { students: user._id },
      });
    }

    const userObject = user.toObject();
    delete userObject.password;

    res.status(201).json(userObject);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllStudents = async (req, res) => {
  try {
    const canView =
      req.user.userType.includes("director") ||
      req.user.userType.includes("manager") ||
      req.user.userType.includes("admin");
    const isTrainer = req.user.userType.includes("trainer");
    const { search, status, groupId } = req.query;

    if (!canView) {
      if (!isTrainer || !groupId) {
        return res.status(403).json({ message: "Access denied" });
      }
      const group = await Group.findById(groupId).select("trainerId");
      if (
        !group ||
        group.trainerId?.toString() !== req.user._id.toString()
      ) {
        return res.status(403).json({ message: "Access denied" });
      }
    }

    const filter = {
      userType: { $in: ["student"] },
    };

    if (status && ["pending", "active", "inactive"].includes(status)) {
      filter.status = status;
    }

    if (groupId) {
      filter.groupId = groupId;
    }

    if (search) {
      const regex = new RegExp(search, "i");
      filter.$or = [{ fullName: regex }, { phoneNumber: regex }];
    }

    const students = await User.find(filter)
      .select("-password")
      .populate("groupId", "name")
      .populate("parentId", "fullName phoneNumber")
      .populate("parents", "fullName phoneNumber")
      .sort({ fullName: 1 });

    res.json(students);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const staffRoles = ["trainer", "manager", "tech_staff", "admin"];

const getStaff = async (req, res) => {
  try {
    const canView =
      req.user.userType.includes("director") ||
      req.user.userType.includes("admin");

    if (!canView) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { role, search } = req.query;
    const filter = {};

    if (role) {
      if (!staffRoles.includes(role)) {
        return res.status(400).json({ message: "Invalid role filter" });
      }
      filter.userType = role;
    } else {
      filter.userType = { $in: staffRoles };
    }

    if (search) {
      const regex = new RegExp(search, "i");
      filter.$or = [{ fullName: regex }, { phoneNumber: regex }];
    }

    const staff = await User.find(filter)
      .select("-password")
      .populate("groupId", "name")
      .sort({ fullName: 1 });

    res.json(staff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateUserStatus = async (req, res) => {
  try {
    const canManage =
      req.user.userType.includes("director") ||
      req.user.userType.includes("admin");

    if (!canManage) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { id } = req.params;
    const { status } = req.body;

    if (!["pending", "active", "inactive"].includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    user.status = status;
    await user.save();

    const updatedUser = await User.findById(id)
      .select("-password")
      .populate("groupId", "name");

    res.json(updatedUser);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getActiveTrainers = async (req, res) => {
  try {
    const canView =
      req.user.userType.includes("manager") ||
      req.user.userType.includes("director") ||
      req.user.userType.includes("admin");

    if (!canView) {
      return res.status(403).json({ message: "Access denied" });
    }

    const trainers = await User.find({
      userType: { $in: ["trainer"] },
      status: "active",
    })
      .select("_id fullName phoneNumber iin dateOfBirth userType status")
      .sort({ fullName: 1 });

    res.json(trainers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  addChild,
  createParentForStudent,
  attachExistingParent,
  getParentsList,
  createUserByDirector,
  getPendingStudents,
  assignStudentToGroup,
  createStudentByManager,
  getAllStudents,
  getStaff,
  updateUserStatus,
  getActiveTrainers,
};
