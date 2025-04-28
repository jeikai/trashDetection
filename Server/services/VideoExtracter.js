const { exec } = require("child_process");
const path = require("path");

module.exports = function extractVideoToFrames(videoPath, outputDir) {
  return new Promise((resolve, reject) => {
    const outerPath = path.join(outputDir, "frame-%04d.png");
    const command = `ffmpeg -i ${videoPath} -vf "fps=1" ${outerPath}`;
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(stderr);
      } else {
        const framePaths = [];
        while (true) {
          const framePath = path.join(
            outputDir,
            `frame-${String(frameNumber).padStart(4, "0")}.png`
          );
          if (fs.existsSync(framePath)) {
            framePaths.push(framePath);
          } else {
            break;
          }
        }

        resolve({ message: "Frames extracted successfully", framePaths });
      }
    });
  });
};
