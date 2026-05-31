const User = require("../models/User");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  try {
    const { phoneNumber, fullName, password } = req.body;
    if (!phoneNumber || !fullName || !password) {
      return res.status(400).json({ message: "Пожалуйста, заполните все обязательные поля." });
    }
    if (await User.findByPhone(phoneNumber)) {
      return res.status(400).json({ message: "Пользователь с таким номером телефона уже существует." });
    }
    const user = await User.create({ phoneNumber, fullName, password, role: "client" });
    const token = generateToken(user._id);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;
    const user = await User.findByPhone(phoneNumber);
    if (!user || !(await User.checkPassword(user.password, password))) {
      return res.status(401).json({ message: "Неверный номер телефона или пароль" });
    }
    if (user.status === "inactive") {
      return res.status(403).json({ message: "Аккаунт деактивирован" });
    }
    const token = generateToken(user._id);
    const { password: _, ...safeUser } = user;
    res.json({ user: safeUser, token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { register, login };
