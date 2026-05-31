const fs = require("fs");
const path = require("path");
const pool = require("../config/db");

module.exports = async function initDB() {
  const sql = fs.readFileSync(path.join(__dirname, "init.sql"), "utf8");
  await pool.query(sql);
};
