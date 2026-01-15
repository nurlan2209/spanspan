const User = require("../models/User");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  console.log("Получен запрос на регистрацию. Тело запроса:");
  console.log(req.body);

  try {
    const {
      phoneNumber,
      fullName,
      password,
    } = req.body;

    // Проверка на наличие обязательных полей
    if (!phoneNumber || !fullName || !password) {
      console.log("Ошибка: Отсутствуют обязательные поля.");
      return res
        .status(400)
        .json({ message: "Пожалуйста, заполните все обязательные поля." });
    }

    const userExists = await User.findOne({ phoneNumber });
    if (userExists) {
      console.log("Ошибка: Пользователь с таким phoneNumber уже существует.");
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

    // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Преобразуем Mongoose документ в plain object
    const userObject = user.toObject();

    // ✅ Удаляем пароль из ответа для безопасности
    delete userObject.password;

    console.log("✅ Успешная регистрация. Отправляемые данные:");
    console.log(JSON.stringify(userObject, null, 2));

    res.status(201).json({ user: userObject, token });
  } catch (error) {
    console.error("❌ Произошла ошибка при регистрации:");
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

      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: То же самое для логина
      const userObject = user.toObject();

      // ✅ Удаляем пароль из ответа
      delete userObject.password;

      console.log("✅ Успешный вход. Отправляемые данные:");
      console.log(JSON.stringify(userObject, null, 2));

      res.json({ user: userObject, token });
    } else {
      res.status(401).json({ message: "Неверный номер телефона или пароль" });
    }
  } catch (error) {
    console.error("❌ Произошла ошибка при входе:");
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { register, login };
