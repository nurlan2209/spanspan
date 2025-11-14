const express = require("express");
const {
  startSession,
  finishSession,
  getSessionStatuses,
} = require("../controllers/trainingSessionController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

router.get("/status", protect, getSessionStatuses);
router.post("/start", protect, startSession);
router.post("/finish", protect, finishSession);

module.exports = router;
