const express = require("express");
const multer = require("multer");
const {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
} = require("../controllers/productController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { files: 6 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === "image/jpeg" || file.mimetype === "image/png") {
      cb(null, true);
    } else {
      cb(new Error("Only jpeg/png images are allowed"));
    }
  },
});

router.get("/", getAllProducts);
router.get("/:id", getProductById);
router.post("/", protect, upload.array("images", 6), createProduct);
router.put("/:id", protect, upload.array("images", 6), updateProduct);
router.delete("/:id", protect, deleteProduct);

module.exports = router;
