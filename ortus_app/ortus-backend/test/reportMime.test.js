const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeReportMime } = require("../utils/reportMime");

test("keeps an allowed MIME type", () => {
  assert.equal(
    normalizeReportMime({ mimetype: "image/jpeg", originalname: "photo.jpg" }),
    "image/jpeg"
  );
});

test("infers JPEG MIME from an octet-stream upload", () => {
  assert.equal(
    normalizeReportMime({ mimetype: "application/octet-stream", originalname: "PHOTO.JPEG" }),
    "image/jpeg"
  );
});

test("rejects unsupported octet-stream files", () => {
  assert.equal(
    normalizeReportMime({ mimetype: "application/octet-stream", originalname: "archive.zip" }),
    null
  );
});
