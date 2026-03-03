const Cart = require("../models/Cart");
const Order = require("../models/Order");
const Product = require("../models/Product");

const rollbackStock = async (appliedUpdates) => {
  for (const entry of appliedUpdates) {
    await Product.updateOne(
      { _id: entry.productId, "sizes.label": entry.size },
      { $inc: { "sizes.$.stock": entry.quantity } }
    );
  }
};

const createOrder = async (req, res) => {
  let appliedUpdates = [];
  let cartSnapshot = null;

  try {
    if (req.user.role !== "client") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { comment } = req.body;
    const cart = await Cart.findOneAndUpdate(
      { userId: req.user._id, "items.0": { $exists: true } },
      { $set: { items: [] } },
      { new: false, lean: true }
    );

    if (!cart) {
      return res.status(400).json({ message: "Корзина пуста" });
    }

    cartSnapshot = cart.items;

    const productIds = [...new Set(cart.items.map((item) => String(item.productId)))];
    const products = await Product.find({ _id: { $in: productIds } }).lean();
    const productMap = new Map(products.map((product) => [String(product._id), product]));

    const items = [];
    let totalAmount = 0;

    for (const item of cart.items) {
      const product = productMap.get(String(item.productId));
      if (!product) {
        await rollbackStock(appliedUpdates);
        await Cart.findOneAndUpdate({ userId: req.user._id, items: [] }, { $set: { items: cart.items } });
        return res.status(400).json({ message: "Один из товаров не найден" });
      }

      const sizeEntry = product.sizes.find((s) => s.label === item.size);
      if (!sizeEntry) {
        await rollbackStock(appliedUpdates);
        await Cart.findOneAndUpdate({ userId: req.user._id, items: [] }, { $set: { items: cart.items } });
        return res.status(400).json({ message: `Размер недоступен: ${product.name} (${item.size})` });
      }

      const stockResult = await Product.updateOne(
        {
          _id: product._id,
          sizes: { $elemMatch: { label: item.size, stock: { $gte: item.quantity } } },
        },
        { $inc: { "sizes.$.stock": -item.quantity } }
      );

      if (!stockResult.modifiedCount) {
        await rollbackStock(appliedUpdates);
        await Cart.findOneAndUpdate({ userId: req.user._id, items: [] }, { $set: { items: cart.items } });
        return res.status(400).json({
          message: `Недостаточно товара: ${product.name} (${item.size})`,
        });
      }

      appliedUpdates.push({
        productId: product._id,
        size: item.size,
        quantity: item.quantity,
      });

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

    res.status(201).json(order);
  } catch (error) {
    try {
      if (appliedUpdates.length) {
        await rollbackStock(appliedUpdates);
      }
      if (cartSnapshot && cartSnapshot.length) {
        await Cart.findOneAndUpdate(
          { userId: req.user._id, items: [] },
          { $set: { items: cartSnapshot } }
        );
      }
    } catch (rollbackError) {
      console.error("Order rollback failed:", rollbackError);
    }
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
