const path = require("path");

const allowedReportMime = new Set([
  "image/jpeg",
  "image/png",
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);

const mimeByExtension = new Map([
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".png", "image/png"],
  [".pdf", "application/pdf"],
  [".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
]);

const normalizeReportMime = (file) => {
  if (allowedReportMime.has(file.mimetype)) return file.mimetype;
  if (file.mimetype !== "application/octet-stream") return null;
  return mimeByExtension.get(path.extname(file.originalname).toLowerCase()) ?? null;
};

module.exports = { normalizeReportMime };
