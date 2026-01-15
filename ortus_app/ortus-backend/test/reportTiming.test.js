const test = require("node:test");
const assert = require("node:assert/strict");

const {
  getWindowTimes,
  canSubmitAt,
  isLateAt,
} = require("../utils/reportTiming");

const trainingDate = new Date(2024, 0, 1);
const slot = "08:00-09:30";

test("report timing window is computed correctly", () => {
  const { startTime, windowStart, windowEnd } = getWindowTimes(
    trainingDate,
    slot
  );

  assert.equal(startTime.getHours(), 8);
  assert.equal(startTime.getMinutes(), 0);

  assert.equal(windowStart.getHours(), 7);
  assert.equal(windowStart.getMinutes(), 0);

  assert.equal(windowEnd.getHours(), 7);
  assert.equal(windowEnd.getMinutes(), 30);
});

test("submission earlier than 60 minutes is blocked", () => {
  const now = new Date(2024, 0, 1, 6, 59);
  assert.equal(canSubmitAt(trainingDate, slot, now), false);
  assert.equal(isLateAt(trainingDate, slot, now), false);
});

test("submission within 60-30 minute window is on time", () => {
  const now = new Date(2024, 0, 1, 7, 15);
  assert.equal(canSubmitAt(trainingDate, slot, now), true);
  assert.equal(isLateAt(trainingDate, slot, now), false);
});

test("submission after 30 minute cutoff is late but allowed", () => {
  const now = new Date(2024, 0, 1, 7, 31);
  assert.equal(canSubmitAt(trainingDate, slot, now), true);
  assert.equal(isLateAt(trainingDate, slot, now), true);
});
