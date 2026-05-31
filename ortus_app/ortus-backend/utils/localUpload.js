const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const uploadDir = path.join(__dirname, "..", "uploads");

const saveFile = (buffer, folder, originalName) => {
  const dir = path.join(uploadDir, folder);
  fs.mkdirSync(dir, { recursive: true });

  const ext = path.extname(originalName) || "";
  const filename = crypto.randomBytes(16).toString("hex") + ext;
  fs.writeFileSync(path.join(dir, filename), buffer);

  const baseUrl = process.env.BASE_URL || "http://localhost:5000";
  const urlPath = `/uploads/${folder}/${filename}`;
  return {
    secure_url: baseUrl + urlPath,
    public_id: urlPath,
  };
};

module.exports = { saveFile };
