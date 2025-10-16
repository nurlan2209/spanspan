const mongoose = require("mongoose");

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  category: {
    type: String,
    required: true,
    enum: ["tshirt", "patch", "bottle", "mug", "cap"], // ✅ ДОБАВИТЬ ВСЕ ТИПЫ
  },
  price: { type: Number, required: true },
  images: [{ type: String }], // массив URL изображений
  sizes: [
    {
      size: {
        type: String,
        enum: ["XS", "S", "M", "L", "XL", "XXL", "OneSize"],
        required: true,
      },
      stock: { type: Number, required: true, default: 0 },
    },
  ],
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Product", productSchema);
