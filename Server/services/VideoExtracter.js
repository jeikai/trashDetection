const { exec } = require("child_process");
const path = require("path");
const { v4: uuidv4 } = require("uuid");
const fs = require("fs");

module.exports = function extractVideoToFrames(videoPath, outputDir) {
  return new Promise((resolve, reject) => {
    const sessionId = uuidv4();
    const sessionDir = path.resolve(path.join(outputDir, sessionId));

    if (!fs.existsSync(sessionDir)) {
      fs.mkdirSync(sessionDir, { recursive: true });
    }

    const framePattern = "frame-%04d.png";
    const absVideoPath = path.resolve(videoPath);
    const videoFilename = path.basename(absVideoPath);
    const videoDir = path.dirname(absVideoPath);

    const command = [
      "docker run --rm",
      `-v "${videoDir}":/input:ro`,
      `-v "${sessionDir}":/output`,
      "jrottenberg/ffmpeg",
      `-i /input/${videoFilename}`,
      '-vf "fps=1"',
      `/output/${framePattern}`,
    ].join(" ");

    exec(command, (error, stdout, stderr) => {
      if (error) {
        return reject(stderr);
      }

      fs.readdir(sessionDir, (err, files) => {
        if (err) {
          return reject(err);
        }

        const framePaths = files
          .filter((file) => /^frame-\d{4}\.png$/.test(file))
          .map((file) => path.join(sessionDir, file))
          .sort();

        resolve({ message: "Frames extracted successfully", framePaths });
      });
    });
  });
};
