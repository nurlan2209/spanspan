const Cart = require("../models/Cart");
const Product = require("../models/Product");

// Получить корзину текущего пользователя
const getCart = async (req, res) => {
  try {
    let cart = await Cart.findOne({ userId: req.user._id }).populate(
      "items.productId"
    );

    if (!cart) {
      cart = await Cart.create({ userId: req.user._id, items: [] });
    }

    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Добавить товар в корзину
const addToCart = async (req, res) => {
  try {
    const { productId, size, quantity } = req.body;

    const product = await Product.findById(productId);
    if (!product || !product.isActive) {
      return res.status(404).json({ message: "Product not found" });
    }

    const sizeData = product.sizes.find((s) => s.size === size);
    if (!sizeData || sizeData.stock < quantity) {
      return res.status(400).json({ message: "Insufficient stock" });
    }

    let cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      cart = await Cart.create({ userId: req.user._id, items: [] });
    }

    const existingItemIndex = cart.items.findIndex(
      (item) => item.productId.toString() === productId && item.size === size
    );

    if (existingItemIndex > -1) {
      cart.items[existingItemIndex].quantity += quantity;
    } else {
      cart.items.push({ productId, size, quantity });
    }

    await cart.save();
    await cart.populate("items.productId");

    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Обновить количество товара в корзине
const updateCartItem = async (req, res) => {
  try {
    const { productId, size, quantity } = req.body;

    const cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    const itemIndex = cart.items.findIndex(
      (item) => item.productId.toString() === productId && item.size === size
    );

    if (itemIndex === -1) {
      return res.status(404).json({ message: "Item not found in cart" });
    }

    if (quantity <= 0) {
      cart.items.splice(itemIndex, 1);
    } else {
      const product = await Product.findById(productId);
      const sizeData = product.sizes.find((s) => s.size === size);
      if (sizeData.stock < quantity) {
        return res.status(400).json({ message: "Insufficient stock" });
      }
      cart.items[itemIndex].quantity = quantity;
    }

    await cart.save();
    await cart.populate("items.productId");

    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Удалить товар из корзины
const removeFromCart = async (req, res) => {
  try {
    const { productId, size } = req.body;

    const cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    cart.items = cart.items.filter(
      (item) => !(item.productId.toString() === productId && item.size === size)
    );

    await cart.save();
    await cart.populate("items.productId");

    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Очистить корзину
const clearCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    cart.items = [];
    await cart.save();

    res.json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
};
