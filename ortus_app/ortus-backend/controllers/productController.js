const Product = require("../models/Product");
const { saveFile } = require("../utils/localUpload");

const parseSizes = (raw) => {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
};

const getAllProducts = async (req, res) => {
  try {
    const products = await Product.findAll({ category: req.query.category });
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") return res.status(403).json({ message: "Access denied" });
    const { name, description, category, price } = req.body;
    const sizes = parseSizes(req.body.sizes);
    if (!name || !price) return res.status(400).json({ message: "Название и цена обязательны" });
    const images = (req.files || []).map(
      (f) => saveFile(f.buffer, "products", f.originalname).secure_url
    );
    const product = await Product.create({ name, description, category, price: Number(price), sizes, images });
    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") return res.status(403).json({ message: "Access denied" });
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });

    const { name, description, category, price } = req.body;
    const fields = {};
    if (name) fields.name = name;
    if (description !== undefined) fields.description = description;
    if (category) fields.category = category;
    if (price !== undefined) fields.price = Number(price);
    if (req.body.sizes !== undefined) fields.sizes = parseSizes(req.body.sizes);
    if (req.files && req.files.length) {
      fields.images = req.files.map(
        (f) => saveFile(f.buffer, "products", f.originalname).secure_url
      );
    }

    const updated = await Product.update(req.params.id, fields);
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteProduct = async (req, res) => {
  try {
    if (req.user.role !== "manager") return res.status(403).json({ message: "Access denied" });
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    await Product.deleteById(req.params.id);
    res.json({ message: "Product deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getAllProducts, getProductById, createProduct, updateProduct, deleteProduct };
