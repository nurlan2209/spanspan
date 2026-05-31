const pool = require("../config/db");

const toProduct = (row) => {
  if (!row) return null;
  return {
    _id: row.id,
    name: row.name,
    description: row.description,
    category: row.category,
    price: Number(row.price),
    sizes: row.sizes || [],
    images: row.images || [],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

const Product = {
  async findAll({ category } = {}) {
    const params = [];
    const where = category ? (params.push(category), "WHERE category = $1") : "";
    const { rows } = await pool.query(
      `SELECT * FROM products ${where} ORDER BY created_at DESC`,
      params
    );
    return rows.map(toProduct);
  },

  async findById(id) {
    const { rows } = await pool.query("SELECT * FROM products WHERE id = $1", [id]);
    return toProduct(rows[0]);
  },

  async findByIds(ids) {
    if (!ids.length) return [];
    const { rows } = await pool.query(
      "SELECT * FROM products WHERE id = ANY($1::uuid[])",
      [ids]
    );
    return rows.map(toProduct);
  },

  async create({ name, description = "", category = "other", price, sizes = [], images = [] }) {
    const { rows } = await pool.query(
      `INSERT INTO products (name, description, category, price, sizes, images)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [name, description, category, price, JSON.stringify(sizes), JSON.stringify(images)]
    );
    return toProduct(rows[0]);
  },

  async update(id, fields) {
    const colMap = {
      name: "name",
      description: "description",
      category: "category",
      price: "price",
      sizes: "sizes",
      images: "images",
    };
    const sets = [];
    const params = [];
    for (const [key, col] of Object.entries(colMap)) {
      if (fields[key] !== undefined) {
        const val = col === "sizes" || col === "images" ? JSON.stringify(fields[key]) : fields[key];
        params.push(val);
        sets.push(`${col} = $${params.length}`);
      }
    }
    if (!sets.length) return Product.findById(id);
    sets.push("updated_at = NOW()");
    params.push(id);
    const { rows } = await pool.query(
      `UPDATE products SET ${sets.join(", ")} WHERE id = $${params.length} RETURNING *`,
      params
    );
    return toProduct(rows[0]);
  },

  async deleteById(id) {
    await pool.query("DELETE FROM products WHERE id = $1", [id]);
  },
};

module.exports = Product;
