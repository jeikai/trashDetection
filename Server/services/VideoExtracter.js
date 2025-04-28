const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");

module.exports = function extractVideoToFrames(videoPath, outputDir) {
  return new Promise((resolve, reject) => {
    const outerPath = path.join(outputDir, "frame-%04d.png");
    const command = `ffmpeg -i ${videoPath} -vf "fps=1" ${outerPath}`;
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(stderr);
      } else {
        const framePaths = [];
        let frameNumber = 0;
        while (true) {
          const framePath = path.join(
            outputDir,
            `frame-${String(frameNumber).padStart(4, "0")}.png`
          );
          if (fs.existsSync(framePath)) {
            framePaths.push(framePath);
            frameNumber++;
          } else {
            break;
          }
        }

        resolve({ message: "Frames extracted successfully", framePaths });
      }
    });
  });
};
