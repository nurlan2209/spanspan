require("dotenv").config();
const mongoose = require("mongoose");
const User = require("../models/User");
const Group = require("../models/Group");

const connectDB = async () => {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("✅ Connected to MongoDB");
};

const seedData = async () => {
  await connectDB();

  await User.deleteMany({});
  await Group.deleteMany({});

  const trainer = await User.create({
    phoneNumber: "+77001234567",
    iin: "950101300123",
    fullName: "Иванов Иван Иванович",
    dateOfBirth: new Date("1995-01-01"),
    weight: 75,
    userType: "trainer",
    password: "password123",
  });

  const group = await Group.create({
    name: "2024-1",
    trainerId: trainer._id,
    students: [],
  });

  const student = await User.create({
    phoneNumber: "+77007654321",
    iin: "000101300456",
    fullName: "Петров Петр Петрович",
    dateOfBirth: new Date("2000-01-01"),
    weight: 65,
    userType: "student",
    password: "password123",
    groupId: group._id,
  });

  console.log("✅ Seed data created");
  process.exit();
};

seedData();
