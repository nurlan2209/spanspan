const Product = require("../models/Product");

const isAdmin = (user) => user.userType.includes("admin");

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

const createProduct = async (req, res) => {
  try {
    if (!isAdmin(req.user)) {
      return res
        .status(403)
        .json({ message: "Only admins can create products" });
    }

    const { name, description, category, price } = req.body;

    const images = req.files ? req.files.map((file) => file.path) : [];

    const product = await Product.create({
      name,
      description,
      category,
      price: parseFloat(price),
      images,
      sizes: [],
    });

    res.status(201).json(product);
  } catch (error) {
    console.error("❌ Create product error:", error);
    res.status(500).json({ message: error.message });
  }
};

const updateProduct = async (req, res) => {
  try {
    if (!isAdmin(req.user)) {
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

const deleteProduct = async (req, res) => {
  try {
    if (!isAdmin(req.user)) {
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

const updateStock = async (req, res) => {
  try {
    console.log("📦 updateStock вызван");
    console.log("Product ID:", req.params.id);
    console.log("Body:", req.body);
    console.log("User:", req.user.userType);

    if (!isAdmin(req.user)) {
      console.log("❌ Access denied");
      return res.status(403).json({ message: "Only admins can update stock" });
    }

    const { size, stock } = req.body;

    if (!size || stock === undefined) {
      console.log("❌ Missing size or stock");
      return res.status(400).json({ message: "Size and stock are required" });
    }

    const product = await Product.findById(req.params.id);

    if (!product) {
      console.log("❌ Product not found");
      return res.status(404).json({ message: "Product not found" });
    }

    console.log("✅ Product found:", product.name);
    console.log("Current sizes:", product.sizes);

    const sizeIndex = product.sizes.findIndex((s) => s.size === size);

    if (sizeIndex === -1) {
      console.log("➕ Adding new size:", size);
      product.sizes.push({ size, stock });
    } else {
      console.log("✏️ Updating existing size:", size);
      product.sizes[sizeIndex].stock = stock;
    }

    await product.save();
    console.log("✅ Product saved");
    console.log("New sizes:", product.sizes);

    res.json(product);
  } catch (error) {
    console.error("❌ Update stock error:", error);
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
