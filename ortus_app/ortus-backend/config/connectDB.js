const pool = require("./db");
const initDB = require("../db/init");

const connectDB = async () => {
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
