const { Parser } = require("json2csv");
const User = require("../models/User");

const exportStudents = async (req, res) => {
  try {
    if (
      !req.user.userType.includes("director") &&
      !req.user.userType.includes("admin")
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { status, groupId, search, format = "csv" } = req.query;

    if (format !== "csv") {
      return res.status(400).json({ message: "Only CSV export is supported" });
    }

    const filter = {
      userType: { $in: ["student"] },
    };

    if (status && ["pending", "active", "inactive"].includes(status)) {
      filter.status = status;
    }

    if (groupId) {
      filter.groupId = groupId;
    }

    if (search) {
      const regex = new RegExp(search, "i");
      filter.$or = [{ fullName: regex }, { phoneNumber: regex }];
    }

    const students = await User.find(filter)
      .select("-password")
      .populate("groupId", "name")
      .populate("parentId", "fullName phoneNumber")
      .sort({ fullName: 1 });

    const rows = students.map((student) => ({
      fullName: student.fullName,
      phoneNumber: student.phoneNumber,
      iin: student.iin,
      status: student.status,
      group: student.groupId ? student.groupId.name : "Без группы",
      parent: student.parentId ? student.parentId.fullName : "",
      createdAt: student.createdAt?.toISOString() ?? "",
    }));

    const parser = new Parser({
      fields: [
        "fullName",
        "phoneNumber",
        "iin",
        "status",
        "group",
        "parent",
        "createdAt",
      ],
    });
    const csv = parser.parse(rows);

    res.header("Content-Type", "text/csv");
    res.attachment(`students_export_${Date.now()}.csv`);
    res.send(csv);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { exportStudents };
