require("dotenv").config();
const mongoose = require("mongoose");
const User = require("../models/User");

const connectDB = async () => {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("✅ Connected to MongoDB");
};

const seedData = async () => {
  await connectDB();

  await User.deleteMany({});

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
