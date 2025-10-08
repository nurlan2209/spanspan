const express = require("express");
const {
  createGroup,
  getAllGroups,
  getJoinRequests,
  handleJoinRequest,
} = require("../controllers/groupController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/create", protect, createGroup);
router.get("/", getAllGroups);
router.get("/requests", protect, getJoinRequests);
router.post("/requests/handle", protect, handleJoinRequest);

module.exports = router;
