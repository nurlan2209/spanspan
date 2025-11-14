const normalizeDate = (input) => {
  const date = input ? new Date(input) : new Date();
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  date.setHours(0, 0, 0, 0);
  return date;
};

const getDayRange = (input) => {
  const normalized = normalizeDate(input);
  if (!normalized) {
    return { startOfDay: null, endOfDay: null };
  }
  const startOfDay = new Date(normalized);
  const endOfDay = new Date(normalized);
  endOfDay.setHours(23, 59, 59, 999);
  return { startOfDay, endOfDay };
};

module.exports = { normalizeDate, getDayRange };
