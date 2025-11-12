const express = require("express");
const { exportStudents } = require("../controllers/exportController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

router.get("/students", protect, exportStudents);

module.exports = router;
