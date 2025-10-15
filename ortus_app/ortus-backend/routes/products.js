// ortus-backend/routes/products.js
const express = require("express");
const multer = require("multer");
const path = require("path");
const {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock,
} = require("../controllers/productController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const cloudinary = require("../config/cloudinary");

// Настройка multer для загрузки фото
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "ortus-products",
    allowed_formats: ["jpg", "png", "jpeg", "webp"],
  },
});

const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

router.get("/", getAllProducts);
router.get("/:id", getProductById);
router.post("/", protect, upload.array("images", 5), createProduct);
router.put("/:id", protect, updateProduct);
router.delete("/:id", protect, deleteProduct);
router.put("/:id/stock", protect, updateStock);

module.exports = router;
