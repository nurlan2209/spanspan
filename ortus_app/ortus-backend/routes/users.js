const express = require("express");
const {
  getProfile,
  updateProfile,
  addChild,
  createUserByDirector,
  getPendingStudents,
  assignStudentToGroup,
  createStudentByManager,
  getAllStudents,
  getStaff,
  updateUserStatus,
} = require("../controllers/userController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.get("/profile", protect, getProfile);
router.put("/profile", protect, updateProfile);
router.post("/add-child", protect, addChild);
router.post("/create-user", protect, createUserByDirector);
router.post("/create-student", protect, createStudentByManager);
router.get("/pending", protect, getPendingStudents);
router.patch("/:id/assign-group", protect, assignStudentToGroup);
router.get("/students", protect, getAllStudents);
router.get("/staff", protect, getStaff);
router.patch("/:id/status", protect, updateUserStatus);

module.exports = router;
