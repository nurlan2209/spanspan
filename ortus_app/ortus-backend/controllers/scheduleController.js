const Schedule = require("../models/Schedule");
const Group = require("../models/Group");

const createSchedule = async (req, res) => {
  try {
    const { groupId, dayOfWeek, startTime, endTime, location } = req.body;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    if (group.trainerId.toString() !== req.user._id.toString()) {
      return res
        .status(403)
        .json({ message: "Only group trainer can create schedule" });
    }

    const schedule = await Schedule.create({
      groupId,
      dayOfWeek,
      startTime,
      endTime,
      location: location || "Зал ORTUS",
    });

    res.status(201).json(schedule);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getScheduleByGroup = async (req, res) => {
  try {
    const { groupId } = req.params;
    const schedules = await Schedule.find({ groupId }).sort({
      dayOfWeek: 1,
      startTime: 1,
    });
    res.json(schedules);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllSchedules = async (req, res) => {
  try {
    const schedules = await Schedule.find()
      .populate("groupId", "name")
      .sort({ dayOfWeek: 1, startTime: 1 });
    res.json(schedules);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteSchedule = async (req, res) => {
  try {
    const schedule = await Schedule.findById(req.params.id).populate("groupId");

    if (!schedule) {
      return res.status(404).json({ message: "Schedule not found" });
    }

    if (schedule.groupId.trainerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }

    await schedule.deleteOne();
    res.json({ message: "Schedule deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createSchedule,
  getScheduleByGroup,
  getAllSchedules,
  deleteSchedule,
};
