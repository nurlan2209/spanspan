const News = require("../models/News");
const User = require("../models/User");

// Создать новость (admin/trainer)
const createNews = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("admin") &&
      !req.user.userType.includes("trainer")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { title, content, category, images, targetGroups, isPinned } =
      req.body;

    const news = await News.create({
      title,
      content,
      category: category || "general",
      images: images || [],
      targetGroups: targetGroups || [],
      authorId: req.user._id,
      isPinned: isPinned || false,
    });

    await news.populate("authorId", "fullName userType");
    await news.populate("targetGroups", "name");

    res.status(201).json(news);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить все новости (с фильтрами)
const getAllNews = async (req, res) => {
  try {
    const { category, groupId } = req.query;
    const filter = { isActive: true };

    if (category) filter.category = category;

    // Если указана группа - показываем новости для всех + для этой группы
    if (groupId) {
      filter.$or = [
        { targetGroups: { $size: 0 } }, // Новости для всех
        { targetGroups: groupId }, // Новости для конкретной группы
      ];
    } else {
      // Если группа не указана - только общие новости
      filter.targetGroups = { $size: 0 };
    }

    const news = await News.find(filter)
      .populate("authorId", "fullName userType")
      .populate("targetGroups", "name")
      .sort({ isPinned: -1, createdAt: -1 });

    res.json(news);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Получить новость по ID
const getNewsById = async (req, res) => {
  try {
    const news = await News.findById(req.params.id)
      .populate("authorId", "fullName userType")
      .populate("targetGroups", "name");

    if (!news || !news.isActive) {
      return res.status(404).json({ message: "News not found" });
    }

    res.json(news);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Обновить новость (admin/trainer - только свою)
const updateNews = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(404).json({ message: "News not found" });
    }

    // Проверка прав: админ может всё, тренер только свои новости
    const isAdmin = req.user.userType.includes("admin");
    const isAuthor = news.authorId.toString() === req.user._id.toString();

    if (!isAdmin && !isAuthor) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { title, content, category, images, targetGroups, isPinned } =
      req.body;

    if (title) news.title = title;
    if (content) news.content = content;
    if (category) news.category = category;
    if (images !== undefined) news.images = images;
    if (targetGroups !== undefined) news.targetGroups = targetGroups;
    if (isPinned !== undefined) news.isPinned = isPinned;

    await news.save();
    await news.populate("authorId", "fullName userType");
    await news.populate("targetGroups", "name");

    res.json(news);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Удалить новость (мягкое удаление)
const deleteNews = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(404).json({ message: "News not found" });
    }

    const isAdmin = req.user.userType.includes("admin");
    const isAuthor = news.authorId.toString() === req.user._id.toString();

    if (!isAdmin && !isAuthor) {
      return res.status(403).json({ message: "Access denied" });
    }

    news.isActive = false;
    await news.save();

    res.json({ message: "News deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Закрепить/открепить новость (только admin)
const togglePinNews = async (req, res) => {
  try {
    if (!req.user.userType.includes("admin")) {
      return res.status(403).json({ message: "Only admins can pin news" });
    }

    const news = await News.findById(req.params.id);

    if (!news) {
      return res.status(404).json({ message: "News not found" });
    }

    news.isPinned = !news.isPinned;
    await news.save();
    await news.populate("authorId", "fullName userType");
    await news.populate("targetGroups", "name");

    res.json(news);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createNews,
  getAllNews,
  getNewsById,
  updateNews,
  deleteNews,
  togglePinNews,
};
