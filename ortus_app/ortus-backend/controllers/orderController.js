const pool = require("../config/db");
const Cart = require("../models/Cart");
const Order = require("../models/Order");

const toOrder = (row) => ({
  _id: row.id,
  userId: row.user_id,
  clientName: row.client_name,
  clientPhone: row.client_phone,
  items: row.items || [],
  totalAmount: Number(row.total_amount),
  status: row.status,
  clientComment: row.client_comment,
  managerNote: row.manager_note,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const createOrder = async (req, res) => {
  const client = await pool.connect();
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });

    await client.query("BEGIN");

    const cartItems = await Cart.clearAndGetItems(client, req.user._id);
    if (!cartItems) {
      await client.query("ROLLBACK");
      return res.status(400).json({ message: "Корзина пуста" });
    }

    const orderItems = [];
    let totalAmount = 0;

    for (const item of cartItems) {
      const { rows } = await client.query(
        "SELECT * FROM products WHERE id = $1 FOR UPDATE",
        [item.productId]
      );
      const product = rows[0];
      if (!product) {
        await client.query("ROLLBACK");
        return res.status(400).json({ message: "Один из товаров не найден" });
      }

      const sizes = product.sizes;
      const sizeIdx = sizes.findIndex((s) => s.label === item.size);
      if (sizeIdx === -1) {
        await client.query("ROLLBACK");
        return res.status(400).json({ message: `Размер недоступен: ${product.name} (${item.size})` });
      }
      if (sizes[sizeIdx].stock < item.quantity) {
        await client.query("ROLLBACK");
        return res.status(400).json({ message: `Недостаточно товара: ${product.name} (${item.size})` });
      }

      sizes[sizeIdx].stock -= item.quantity;
      await client.query(
        "UPDATE products SET sizes = $1, updated_at = NOW() WHERE id = $2",
        [JSON.stringify(sizes), product.id]
      );

      const price = Number(product.price);
      totalAmount += price * item.quantity;
      orderItems.push({
        productId: product.id,
        name: product.name,
        image: (product.images || [])[0] || "",
        size: item.size,
        quantity: item.quantity,
        price,
      });
    }

    const { rows } = await client.query(
      `INSERT INTO orders (user_id, client_name, client_phone, items, total_amount, client_comment)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [req.user._id, req.user.fullName, req.user.phoneNumber, JSON.stringify(orderItems), totalAmount, req.body.comment || ""]
    );

    await client.query("COMMIT");
    res.status(201).json(toOrder(rows[0]));
  } catch (error) {
    await client.query("ROLLBACK");
    res.status(500).json({ message: error.message });
  } finally {
    client.release();
  }
};

const getMyOrders = async (req, res) => {
  try {
    if (req.user.role !== "client") return res.status(403).json({ message: "Access denied" });
    const orders = await Order.findByUserId(req.user._id);
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllOrders = async (req, res) => {
  try {
    if (req.user.role !== "manager") return res.status(403).json({ message: "Access denied" });
    const orders = await Order.findAll({ status: req.query.status });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    if (req.user.role !== "manager") return res.status(403).json({ message: "Access denied" });
    const { status, managerNote } = req.body;
    if (status && !Order.allowedStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });
    const updated = await Order.update(req.params.id, { status, managerNote });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createOrder, getMyOrders, getAllOrders, updateOrderStatus };
