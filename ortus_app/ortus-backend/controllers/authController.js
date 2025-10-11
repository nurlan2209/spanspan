const User = require("../models/User");
const JoinRequest = require("../models/JoinRequest");
const generateToken = require("../utils/generateToken");

const register = async (req, res) => {
  // --- НАЧАЛО ИЗМЕНЕНИЙ ---
  console.log("Получен запрос на регистрацию. Тело запроса:");
  console.log(req.body);
  // --- КОНЕЦ ИЗМЕНЕНИЙ ---

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

    // --- НАЧАЛО ИЗМЕНЕНИЙ ---
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
    // --- КОНЕЦ ИЗМЕНЕНИЙ ---

    const userExists = await User.findOne({ $or: [{ phoneNumber }, { iin }] });
    if (userExists) {
      // --- НАЧАЛО ИЗМЕНЕНИЙ ---
      console.log(
        "Ошибка: Пользователь с таким phoneNumber или IIN уже существует."
      );
      // --- КОНЕЦ ИЗМЕНЕНИЙ ---
      return res
        .status(400)
        .json({
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
    res.status(201).json({ user, token });
  } catch (error) {
    // --- НАЧАЛО ИЗМЕНЕНИЙ ---
    console.error("Произошла ошибка при регистрации:");
    console.error(error);
    // --- КОНЕЦ ИЗМЕНЕНИЙ ---
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
      res.json({ user, token });
    } else {
      res.status(401).json({ message: "Invalid credentials" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { register, login };
