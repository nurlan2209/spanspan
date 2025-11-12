const News = require("../models/News");

const roleFlags = (user) => ({
  isAdmin: user.userType.includes("admin"),
  isDirector: user.userType.includes("director"),
  isTrainer: user.userType.includes("trainer"),
  isManager: user.userType.includes("manager"),
});

// Создать новость (admin/trainer)
const createNews = async (req, res) => {
  try {
    const { isAdmin, isDirector, isTrainer, isManager } = roleFlags(req.user);

    if (!isAdmin && !isTrainer && !isManager && !isDirector) {
      return res.status(403).json({ message: "Access denied" });
    }

    const {
      title,
      content,
      category,
      images,
      targetGroups,
      isPinned,
      newsType,
    } = req.body;

    let resolvedType = newsType;
    if (!resolvedType) {
      resolvedType = isTrainer ? "group" : "general";
    }

    if (
      resolvedType === "group" &&
      !isTrainer &&
      !isAdmin &&
      !isDirector
    ) {
      return res
        .status(403)
        .json({ message: "Only trainers/admins/directors can post group news" });
    }

    if (
      resolvedType === "general" &&
      !isManager &&
      !isAdmin &&
      !isDirector
    ) {
      return res
        .status(403)
        .json({ message: "Only managers/admins/directors can post general news" });
    }

    const normalizedTargets =
      resolvedType === "general"
        ? []
        : Array.isArray(targetGroups)
        ? targetGroups
        : targetGroups
        ? [targetGroups]
        : [];

    if (resolvedType === "group" && !normalizedTargets.length) {
      return res
        .status(400)
        .json({ message: "Group news must specify at least one group" });
    }

    const news = await News.create({
      title,
      content,
      newsType: resolvedType,
      category: category || "general",
      images: images || [],
      targetGroups: normalizedTargets,
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
    const { category, groupId, type } = req.query;
    const filter = { isActive: true };

    if (category) filter.category = category;

    if (type === "general") {
      filter.newsType = "general";
    } else if (type === "group") {
      filter.newsType = "group";
      if (groupId) {
        filter.targetGroups = groupId;
      }
    } else if (groupId) {
      filter.$or = [
        { newsType: "general" },
        { newsType: "group", targetGroups: groupId },
      ];
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

    const { isAdmin, isDirector, isManager, isTrainer } = roleFlags(req.user);
    const isAuthor = news.authorId.toString() === req.user._id.toString();

    if (!isAdmin && !isDirector && !isAuthor) {
      return res.status(403).json({ message: "Access denied" });
    }

    const {
      title,
      content,
      category,
      images,
      targetGroups,
      isPinned,
      newsType,
    } = req.body;

    if (newsType && newsType !== news.newsType && !isAdmin && !isDirector) {
      return res
        .status(403)
        .json({ message: "Only admins/directors can change news type" });
    }

    if (newsType === "general" && !isManager && !isAdmin && !isDirector) {
      return res.status(403).json({ message: "Access denied" });
    }

    if (newsType === "group" && !isTrainer && !isAdmin && !isDirector) {
      return res.status(403).json({ message: "Access denied" });
    }

    if (title) news.title = title;
    if (content) news.content = content;
    if (category) news.category = category;
    if (images !== undefined) news.images = images;
    if (newsType) {
      news.newsType = newsType;
      if (newsType === "general") {
        news.targetGroups = [];
      }
    }
    if (targetGroups !== undefined) {
      news.targetGroups =
        news.newsType === "general"
          ? []
          : Array.isArray(targetGroups)
          ? targetGroups
          : targetGroups
          ? [targetGroups]
          : [];
    }
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

    const { isAdmin, isDirector } = roleFlags(req.user);
    const isAuthor = news.authorId.toString() === req.user._id.toString();

    if (!isAdmin && !isDirector && !isAuthor) {
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
    const { isAdmin, isDirector } = roleFlags(req.user);
    if (!isAdmin && !isDirector) {
      return res
        .status(403)
        .json({ message: "Only admins or directors can pin news" });
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
