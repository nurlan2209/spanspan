const Product = require("../models/Product");

// Получить все активные товары (для всех)
const getAllProducts = async (req, res) => {
  try {
    const { category } = req.query;
    const filter = { isActive: true };
    if (category) filter.category = category;

    const products = await Product.find(filter).sort({ createdAt: -1 });
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить товар по ID
const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Создать товар (только admin)
const createProduct = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res
        .status(403)
        .json({ message: "Only admins can create products" });
    }

    const { name, description, category, price, images, sizes } = req.body;

    const product = await Product.create({
      name,
      description,
      category,
      price,
      images: images || [],
      sizes: sizes || [],
    });

    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Обновить товар (только admin)
const updateProduct = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res
        .status(403)
        .json({ message: "Only admins can update products" });
    }

    const product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Удалить товар (только admin, мягкое удаление)
const deleteProduct = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res
        .status(403)
        .json({ message: "Only admins can delete products" });
    }

    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    res.json({ message: "Product deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Обновить остатки размера (только admin)
const updateStock = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Only admins can update stock" });
    }

    const { size, stock } = req.body;
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const sizeIndex = product.sizes.findIndex((s) => s.size === size);
    if (sizeIndex === -1) {
      return res.status(404).json({ message: "Size not found" });
    }

    product.sizes[sizeIndex].stock = stock;
    await product.save();

    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock,
};
