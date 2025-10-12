const User = require("../models/User");
const JoinRequest = require("../models/JoinRequest");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  console.log("Получен запрос на регистрацию. Тело запроса:");
  console.log(req.body);

  try {
    const {
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      weight,
      userType,
      groupId,
      password,
      parentId,
    } = req.body;

    // Проверка на наличие обязательных полей
    if (
      !phoneNumber ||
      !iin ||
      !fullName ||
      !dateOfBirth ||
      !weight ||
      !userType ||
      !password
    ) {
      console.log("Ошибка: Отсутствуют обязательные поля.");
      return res
        .status(400)
        .json({ message: "Пожалуйста, заполните все обязательные поля." });
    }

    const userExists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (userExists) {
      console.log(
        "Ошибка: Пользователь с таким phoneNumber или IIN уже существует."
      );
      return res.status(400).json({
        message:
          "Пользователь с таким номером телефона или ИИН уже существует.",
      });
    }

    const roles = Array.isArray(userType) ? userType : [userType];

    const user = await User.create({
      phoneNumber,
      iin,
      fullName,
      dateOfBirth,
      weight,
      userType: roles,
      password,
      parentId: parentId || null,
    });

    if (parentId) {
      await User.findByIdAndUpdate(parentId, {
        $push: { children: user._id },
      });
    }

    if (roles.includes("student") && groupId) {
      await JoinRequest.create({
        studentId: user._id,
        groupId,
        status: "pending",
      });
    }

    const token = generateToken(user._id);

    // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Преобразуем Mongoose документ в plain object
    const userObject = user.toObject();

    // ✅ Явно преобразуем userType в обычный массив
    userObject.userType = Array.isArray(userObject.userType)
      ? [...userObject.userType]
      : [userObject.userType];

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

    const user = await User.findOne({ phoneNumber })
      .populate("groupId")
      .populate("children", "fullName phoneNumber groupId")
      .populate("parentId", "fullName phoneNumber");

    if (user && (await user.matchPassword(password))) {
      const token = generateToken(user._id);

      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: То же самое для логина
      const userObject = user.toObject();

      // ✅ Явно преобразуем userType в обычный массив
      userObject.userType = Array.isArray(userObject.userType)
        ? [...userObject.userType]
        : [userObject.userType];

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
