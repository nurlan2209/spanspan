require("dotenv").config();
const connectDB = require("../config/connectDB");
const pool = require("../config/db");
const User = require("../models/User");

const seedData = async () => {
  await connectDB();
  await pool.query("DELETE FROM users");
  await User.create({
    phoneNumber: "+77007654321",
    fullName: "Петров Петр Петрович",
    role: "client",
    password: "password123",
  });
  console.log("✅ Seed data created");
  process.exit();
};

seedData();
