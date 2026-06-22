const pool = require("./db");
const initDB = require("../db/init");

const connectDB = async () => {
  if (!process.env.BASE_URL) {
    console.warn("⚠️  BASE_URL is not set — uploaded file URLs will use http://localhost:5000");
  }
  try {
    await pool.query("SELECT 1");
    console.log("✅ PostgreSQL connected");
    await initDB();
  } catch (error) {
    console.error("❌ PostgreSQL connection error:", error.message);
    process.exit(1);
  }
};

module.exports = connectDB;
