const User = require("../models/User");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  try {
    const {
      phoneNumber,
      fullName,
      password,
    } = req.body;

    if (!phoneNumber || !fullName || !password) {
      return res
        .status(400)
        .json({ message: "Пожалуйста, заполните все обязательные поля." });
    }

    const userExists = await User.findOne({ phoneNumber });
    if (userExists) {
      return res.status(400).json({
        message: "Пользователь с таким номером телефона уже существует.",
      });
    }

    const user = await User.create({
      phoneNumber,
      fullName,
      password,
      role: "client",
    });

    const token = generateToken(user._id);

    const userObject = user.toObject();
    delete userObject.password;

    res.status(201).json({ user: userObject, token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { phoneNumber, password } = req.body;

    const user = await User.findOne({ phoneNumber });

    if (user && (await user.matchPassword(password))) {
      if (user.status === "inactive") {
        return res.status(403).json({ message: "Аккаунт деактивирован" });
      }
      const token = generateToken(user._id);
      const userObject = user.toObject();
      delete userObject.password;

      res.json({ user: userObject, token });
    } else {
      res.status(401).json({ message: "Неверный номер телефона или пароль" });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { register, login };
