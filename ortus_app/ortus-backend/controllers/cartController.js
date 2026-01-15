const Cart = require("../models/Cart");
const Product = require("../models/Product");

const getOrCreateCart = async (userId) => {
  let cart = await Cart.findOne({ userId }).populate("items.productId");
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
    cart = await cart.populate("items.productId");
  }
  return cart;
};

const buildCartResponse = (cart) => {
  const items = cart.items.map((item) => {
    const product = item.productId;
    const image = product?.images?.[0] || "";
    const price = product?.price || 0;
    const totalPrice = price * item.quantity;
    return {
      productId: product?._id,
      name: product?.name || "",
      image,
      size: item.size,
      quantity: item.quantity,
      price,
      totalPrice,
    };
  });
  const totalAmount = items.reduce((sum, item) => sum + item.totalPrice, 0);
  return { items, totalAmount };
};

const getCart = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const cart = await getOrCreateCart(req.user._id);
    res.json(buildCartResponse(cart));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addToCart = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { productId, size, quantity } = req.body;
    const qty = Math.max(Number(quantity) || 1, 1);

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const sizeEntry = product.sizes.find((s) => s.label === size);
    if (!sizeEntry) {
      return res.status(400).json({ message: "Invalid size" });
    }

    const cart = await getOrCreateCart(req.user._id);
    const existing = cart.items.find(
      (item) =>
        item.productId._id.toString() === productId && item.size === size
    );

    const maxAllowed = sizeEntry.stock;
    if (existing) {
      existing.quantity = Math.min(existing.quantity + qty, maxAllowed);
    } else {
      cart.items.push({
        productId,
        size,
        quantity: Math.min(qty, maxAllowed),
      });
    }

    await cart.save();
    await cart.populate("items.productId");
    res.json(buildCartResponse(cart));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateCartItem = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { productId, size, quantity } = req.body;
    const qty = Number(quantity) || 0;

    const cart = await getOrCreateCart(req.user._id);
    const itemIndex = cart.items.findIndex(
      (item) =>
        item.productId._id.toString() === productId && item.size === size
    );
    if (itemIndex === -1) {
      return res.status(404).json({ message: "Item not found" });
    }

    if (qty <= 0) {
      cart.items.splice(itemIndex, 1);
    } else {
      const product = await Product.findById(productId);
      if (!product) {
        return res.status(404).json({ message: "Product not found" });
      }
      const sizeEntry = product.sizes.find((s) => s.label === size);
      if (!sizeEntry) {
        return res.status(400).json({ message: "Invalid size" });
      }
      cart.items[itemIndex].quantity = Math.min(qty, sizeEntry.stock);
    }

    await cart.save();
    await cart.populate("items.productId");
    res.json(buildCartResponse(cart));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const removeCartItem = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { productId, size } = req.body;
    const cart = await getOrCreateCart(req.user._id);

    cart.items = cart.items.filter(
      (item) =>
        item.productId._id.toString() !== productId || item.size !== size
    );

    await cart.save();
    await cart.populate("items.productId");
    res.json(buildCartResponse(cart));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const clearCart = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const cart = await getOrCreateCart(req.user._id);
    cart.items = [];
    await cart.save();
    res.json({ items: [], totalAmount: 0 });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
};
