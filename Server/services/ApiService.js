const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");

module.exports = async function getImgClassification(imgs) {
  const formData = new FormData();
  imgs.forEach((imgPath) => {
    formData.append("files", fs.createReadStream(imgPath));
  });

  try {
    console.log(formData)
    const response = await axios.post(
      "http://localhost:8000/predict/",
      formData,
      {
        headers: formData.getHeaders(),
      }
    );

    return response.data;
  } catch (error) {
    console.error("Error uploading images:", error.message);
    throw error;
  }
};
