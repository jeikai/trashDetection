const express = require("express");
const path = require("path");
const fs = require("fs");
const multer = require("multer");
const extractVideoToFrames = require("./services/VideoExtracter");
const app = express();
const cors = require("cors");
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const mimeType = file.mimetype;

    let folderPath = "uploads/";
    if (mimeType.startsWith("image/")) {
      folderPath += "images/";
    } else if (mimeType.startsWith("video/")) {
      folderPath += "videos/";
    }

    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath, { recursive: true });
    }
    cb(null, folderPath);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const baseName = path.basename(file.originalname, ext);
    cb(null, Date.now() + "-" + baseName + ext);
  },
});
app.use(cors());
const upload = multer({ storage: storage });

app.post("/video", upload.single("video"), async (req, res) => {
  const videoPath = req.file.path;
  const outputDir = "uploads/frames";
  try {
    const result = await extractVideoToFrames(videoPath, outputDir);
    res.status(200).json({ message: result.message });
  } catch (e) {
    console.error(error);
    res.status(500).json("Error extracting frames");
  }
});

app.post("/image", upload.any(), (req, res) => {
  const images = req.files.map((file) => file.path);
  console.log(images);
  res.json("Images uploaded successfully");
});

app.listen(7810, () => {
  console.log("Server is running on port 7810");
});
