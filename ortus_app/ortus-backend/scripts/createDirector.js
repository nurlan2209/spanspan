/* eslint-disable no-console */
require("dotenv").config();
const readline = require("readline");
const mongoose = require("mongoose");
const connectDB = require("../config/db");
const User = require("../models/User");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (query) =>
  new Promise((resolve) => rl.question(query, (answer) => resolve(answer)));

const askRequired = async (label, validator) => {
  let value = "";
  do {
    value = (await question(`${label}: `)).trim();
  } while (!validator(value));
  return value;
};

const run = async () => {
  try {
    await connectDB();

    console.log("=== Создание директора ORTUS ===");

    const phoneNumber = await askRequired(
      "Телефон (+77001234567)",
      (v) => v.length >= 10
    );
    const iin = await askRequired("ИИН (12 цифр)", (v) => v.length === 12);
    const fullName = await askRequired("ФИО", (v) => v.length > 3);
    const dateOfBirthRaw = await askRequired(
      "Дата рождения (YYYY-MM-DD)",
      (v) => !Number.isNaN(Date.parse(v))
    );
    const password = await askRequired(
      "Пароль (минимум 6 символов)",
      (v) => v.length >= 6
    );

    const existing = await User.findOne({
      $or: [{ phoneNumber }, { iin }],
    });
    if (existing) {
      console.log("❌ Пользователь с таким телефоном или ИИН уже существует");
      process.exit(1);
    }

    const user = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth: new Date(dateOfBirthRaw),
      userType: ["director"],
      status: "active",
      password,
    });

    console.log("✅ Директор создан:");
    console.log(`ID: ${user._id}`);
    console.log(`ФИО: ${user.fullName}`);
  } catch (error) {
    console.error("Ошибка создания администратора:", error.message);
  } finally {
    rl.close();
    mongoose.connection.close();
  }
};

run();
