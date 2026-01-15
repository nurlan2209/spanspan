const slots = [
  "08:00-09:30",
  "10:00-11:30",
  "16:00-17:00",
  "18:00-20:00",
  "20:00-22:00",
];

const getSlotStart = (slot) => {
  const [start] = slot.split("-");
  const [hour, minute] = start.split(":").map((v) => parseInt(v, 10));
  return { hour, minute };
};

const getWindowTimes = (trainingDate, slot) => {
  const { hour, minute } = getSlotStart(slot);
  const startTime = new Date(trainingDate);
  startTime.setHours(hour, minute, 0, 0);

  const windowStart = new Date(startTime.getTime() - 60 * 60 * 1000);
  const windowEnd = new Date(startTime.getTime() - 30 * 60 * 1000);

  return { startTime, windowStart, windowEnd };
};

const isLateAt = (trainingDate, slot, now = new Date()) => {
  const { windowEnd } = getWindowTimes(trainingDate, slot);
  return now > windowEnd;
};

const canSubmitAt = (trainingDate, slot, now = new Date()) => {
  const { windowStart } = getWindowTimes(trainingDate, slot);
  return now >= windowStart;
};

module.exports = {
  slots,
  getWindowTimes,
  isLateAt,
  canSubmitAt,
};
