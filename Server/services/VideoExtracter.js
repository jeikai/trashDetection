const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");

module.exports = function extractVideoToFrames(videoPath, outputDir) {
  return new Promise((resolve, reject) => {
    const framePattern = "frame-%04d.png";
    const outputPath = path.join(outputDir, framePattern);
    const command = `ffmpeg -i "${videoPath}" -vf "fps=1" "${outputPath}"`;

    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    exec(command, (error, stdout, stderr) => {
      if (error) {
        return reject(stderr);
      }

      fs.readdir(outputDir, (err, files) => {
        if (err) {
          return reject(err);
        }

        const framePaths = files
          .filter((file) => /^frame-\d{4}\.png$/.test(file))
          .map((file) => path.join(outputDir, file))
          .sort();

        resolve({ message: "Frames extracted successfully", framePaths });
      });
    });
  });
};
