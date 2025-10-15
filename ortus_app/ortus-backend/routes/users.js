const express = require("express");
const {
  getProfile,
  updateProfile,
  addChild,
  createUserByDirector,
} = require("../controllers/userController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.get("/profile", protect, getProfile);
router.put("/profile", protect, updateProfile);
router.post("/add-child", protect, addChild);
router.post("/create-user", protect, createUserByDirector);

module.exports = router;
