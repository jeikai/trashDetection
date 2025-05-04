const express = require("express");
const path = require("path");
const fs = require("fs");
const multer = require("multer");
const extractVideoToFrames = require("./services/VideoExtracter");
const getImgClassification = require("./services/ApiService");
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
    console.log(result.framePaths);
    const classifyImages = await getImgClassification(
      result.framePaths,
      videoPath
    );
    res.status(200).json({
      message: "Video processed successfully",
      images: classifyImages.image_base64,
    });
    const frameDir = path.dirname(result.framePaths[0]);
    result.framePaths.forEach((imgPath) => {
      fs.unlinkSync(imgPath);
    });
    if (fs.readdirSync(frameDir).length === 0) {
      fs.rmdirSync(frameDir);
    }
    fs.unlinkSync(videoPath);
  } catch (e) {
    res.status(500).json(`Error: ${e.message}`);
  }
});

app.post("/image", upload.any(), async (req, res) => {
  const images = req.files.map((file) => file.path);
  try {
    const classifyImg = await getImgClassification(images);
    res.status(200).json({
      message: "Images processed successfully",
      images: classifyImg.image_base64,
    });
    images.forEach((imgPath) => {
      fs.unlinkSync(imgPath);
    });
  } catch (e) {
    console.error(e);
    res.status(500).json(`Error: ${e.message}`);
  }
});

app.listen(7810, () => {
  console.log("Server is running on port 7810");
});
