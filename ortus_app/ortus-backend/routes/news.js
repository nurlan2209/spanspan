const express = require("express");
const {
  createNews,
  getAllNews,
  getNewsById,
  updateNews,
  deleteNews,
  togglePinNews,
} = require("../controllers/newsController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.post("/", protect, createNews);
router.get("/", getAllNews);
router.get("/:id", getNewsById);
router.put("/:id", protect, updateNews);
router.delete("/:id", protect, deleteNews);
router.patch("/:id/pin", protect, togglePinNews);

module.exports = router;
