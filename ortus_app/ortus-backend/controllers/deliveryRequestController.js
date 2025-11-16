const DeliveryRequest = require("../models/DeliveryRequest");
const Order = require("../models/Order");
const User = require("../models/User");

const createDeliveryRequest = async (req, res) => {
  try {
    const { orderId } = req.body;
    if (!orderId) {
      return res.status(400).json({ message: "orderId is required" });
    }

    const order = await Order.findById(orderId).populate("userId", "fullName phoneNumber");
    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    if (order.userId._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Cannot request delivery for another user" });
    }

    const existing = await DeliveryRequest.findOne({ orderId });
    if (existing) {
      return res.status(400).json({ message: "Delivery already requested for this order" });
    }

    const summary = order.items
      .map((item) => `${item.name} x${item.quantity}`)
      .join(", ");

    const request = await DeliveryRequest.create({
      orderId,
      studentId: req.user._id,
      studentName: order.userId.fullName,
      phoneNumber: order.userId.phoneNumber,
      summary,
      pickupAddress: "Зал ORTUS",
      desiredMethod: "delivery",
      status: "new",
    });

    // Обновляем статус заказа на "ready" если он был новым, чтобы отделить доставку от выдачи
    if (order.status === "new") {
      order.status = "ready";
      await order.save();
    }

    res.status(201).json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllRequests = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Access denied" });
    }

    const requests = await DeliveryRequest.find()
      .populate("orderId")
      .populate("studentId", "fullName phoneNumber")
      .sort({ createdAt: -1 });

    res.json(requests);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateRequestStatus = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status } = req.body;
    const request = await DeliveryRequest.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );
    if (!request) {
      return res.status(404).json({ message: "Delivery request not found" });
    }

    res.json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createDeliveryRequest,
  getAllRequests,
  updateRequestStatus,
};
