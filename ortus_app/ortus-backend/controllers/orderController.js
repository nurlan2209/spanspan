const Order = require("../models/Order");
const Cart = require("../models/Cart");
const Product = require("../models/Product");

// Создать заказ из корзины
const createOrder = async (req, res) => {
  try {
    const { paymentMethod } = req.body;

    const cart = await Cart.findOne({ userId: req.user._id }).populate(
      "items.productId"
    );

    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ message: "Cart is empty" });
    }

    let totalAmount = 0;
    const orderItems = [];

    for (const item of cart.items) {
      const product = item.productId;
      const sizeData = product.sizes.find((s) => s.size === item.size);

      if (!sizeData || sizeData.stock < item.quantity) {
        return res.status(400).json({
          message: `Insufficient stock for ${product.name} (${item.size})`,
        });
      }

      // Уменьшаем остатки
      sizeData.stock -= item.quantity;
      await product.save();

      const itemTotal = product.price * item.quantity;
      totalAmount += itemTotal;

      orderItems.push({
        productId: product._id,
        name: product.name,
        price: product.price,
        size: item.size,
        quantity: item.quantity,
        image: product.images[0] || "",
      });
    }

    const order = await Order.create({
      userId: req.user._id,
      items: orderItems,
      totalAmount,
      paymentMethod: paymentMethod || "manual",
    });

    // Очистить корзину после создания заказа
    cart.items = [];
    await cart.save();

    await order.populate("userId", "fullName phoneNumber");

    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить все заказы пользователя
const getUserOrders = async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user._id }).sort({
      createdAt: -1,
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить заказ по ID
const getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate(
      "userId",
      "fullName phoneNumber"
    );

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Проверка доступа: только владелец или админ
    if (
      order.userId._id.toString() !== req.user._id.toString() &&
      !req.user.userType.includes("admin")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить все заказы (только admin)
const getAllOrders = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status } = req.query;
    const filter = status ? { status } : {};

    const orders = await Order.find(filter)
      .populate("userId", "fullName phoneNumber")
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Обновить статус заказа (только admin)
const updateOrderStatus = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status } = req.body;
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Отменить заказ
const cancelOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Только владелец может отменить свой заказ
    if (order.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Access denied" });
    }

    // Можно отменить только pending заказы
    if (order.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Cannot cancel order in this status" });
    }

    // Вернуть товары на склад
    for (const item of order.items) {
      const product = await Product.findById(item.productId);
      if (product) {
        const sizeData = product.sizes.find((s) => s.size === item.size);
        if (sizeData) {
          sizeData.stock += item.quantity;
          await product.save();
        }
      }
    }

    order.status = "cancelled";
    await order.save();

    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createOrder,
  getUserOrders,
  getOrderById,
  getAllOrders,
  updateOrderStatus,
  cancelOrder,
};
