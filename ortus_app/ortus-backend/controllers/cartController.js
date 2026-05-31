const Cart = require("../models/Cart");
const Product = require("../models/Product");

const buildCartResponse = async (rawItems) => {
  if (!rawItems || !rawItems.length) return { items: [], totalAmount: 0 };
  const productIds = [...new Set(rawItems.map((i) => i.productId))];
  const products = await Product.findByIds(productIds);
  const productMap = new Map(products.map((p) => [p._id, p]));
  const items = rawItems.map((item) => {
    const p = productMap.get(item.productId) || {};
    const price = p.price || 0;
    return {
      productId: item.productId,
      name: p.name || "",
      image: (p.images || [])[0] || "",
      size: item.size,
      quantity: item.quantity,
      price,
      totalPrice: price * item.quantity,
    };
  });
  return { items, totalAmount: items.reduce((s, i) => s + i.totalPrice, 0) };
};

const getCart = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    const cart = await Cart.getOrCreate(req.user._id);
    res.json(await buildCartResponse(cart.items));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addToCart = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    const { productId, size, quantity } = req.body;
    const qty = Math.max(Number(quantity) || 1, 1);

    const product = await Product.findById(productId);
    if (!product) return res.status(404).json({ message: "Product not found" });
    const sizeEntry = product.sizes.find((s) => s.label === size);
    if (!sizeEntry) return res.status(400).json({ message: "Invalid size" });

    const cart = await Cart.getOrCreate(req.user._id);
    const items = [...cart.items];
    const idx = items.findIndex((i) => i.productId === productId && i.size === size);
    if (idx !== -1) {
      items[idx] = { ...items[idx], quantity: Math.min(items[idx].quantity + qty, sizeEntry.stock) };
    } else {
      items.push({ productId, size, quantity: Math.min(qty, sizeEntry.stock) });
    }

    await Cart.setItems(req.user._id, items);
    res.json(await buildCartResponse(items));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateCartItem = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    const { productId, size, quantity } = req.body;
    const qty = Number(quantity) || 0;

    const cart = await Cart.getOrCreate(req.user._id);
    let items = [...cart.items];
    const idx = items.findIndex((i) => i.productId === productId && i.size === size);
    if (idx === -1) return res.status(404).json({ message: "Item not found" });

    if (qty <= 0) {
      items.splice(idx, 1);
    } else {
      const product = await Product.findById(productId);
      if (!product) return res.status(404).json({ message: "Product not found" });
      const sizeEntry = product.sizes.find((s) => s.label === size);
      if (!sizeEntry) return res.status(400).json({ message: "Invalid size" });
      items[idx] = { ...items[idx], quantity: Math.min(qty, sizeEntry.stock) };
    }

    await Cart.setItems(req.user._id, items);
    res.json(await buildCartResponse(items));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const removeCartItem = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    const { productId, size } = req.body;
    const cart = await Cart.getOrCreate(req.user._id);
    const items = cart.items.filter((i) => !(i.productId === productId && i.size === size));
    await Cart.setItems(req.user._id, items);
    res.json(await buildCartResponse(items));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const clearCart = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    await Cart.setItems(req.user._id, []);
    res.json({ items: [], totalAmount: 0 });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getCart, addToCart, updateCartItem, removeCartItem, clearCart };
