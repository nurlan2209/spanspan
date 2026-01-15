const Cart = require("../models/Cart");
const Order = require("../models/Order");
const Product = require("../models/Product");

const createOrder = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { comment } = req.body;
    const cart = await Cart.findOne({ userId: req.user._id }).populate(
      "items.productId"
    );

    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ message: "Корзина пуста" });
    }

    const items = [];
    let totalAmount = 0;

    for (const item of cart.items) {
      const product = item.productId;
      if (!product) continue;
      const sizeEntry = product.sizes.find((s) => s.label === item.size);
      if (!sizeEntry || sizeEntry.stock < item.quantity) {
        return res.status(400).json({
          message: `Недостаточно товара: ${product.name} (${item.size})`,
        });
      }

      sizeEntry.stock -= item.quantity;
      await product.save();

      const price = product.price;
      const lineTotal = price * item.quantity;
      totalAmount += lineTotal;

      items.push({
        productId: product._id,
        name: product.name,
        image: product.images?.[0] || "",
        size: item.size,
        quantity: item.quantity,
        price,
      });
    }

    const order = await Order.create({
      userId: req.user._id,
      clientName: req.user.fullName,
      clientPhone: req.user.phoneNumber,
      items,
      totalAmount,
      clientComment: comment || "",
    });

    cart.items = [];
    await cart.save();

    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getMyOrders = async (req, res) => {
  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const orders = await Order.find({ userId: req.user._id }).sort({
      createdAt: -1,
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllOrders = async (req, res) => {
  try {
    if (req.user.role !== "manager") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const orders = await Order.find(filter).sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    if (req.user.role !== "manager") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status, managerNote } = req.body;
    const allowed = [
      "new",
      "contacted",
      "paid",
      "delivering",
      "completed",
      "canceled",
    ];

    if (status && !allowed.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    if (status) order.status = status;
    if (managerNote !== undefined) order.managerNote = managerNote;

    await order.save();
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createOrder,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
};
