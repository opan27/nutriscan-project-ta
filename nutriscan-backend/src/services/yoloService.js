const axios = require('axios');

const detectFood = async (imagePath) => {

  try {

    console.log(
      `🔍 Sending image to YOLO service: ${imagePath}`
    );

    const response = await axios.post(
      'http://127.0.0.1:5001/detect',
      {
        image: imagePath
      },
      {
        timeout: 30000
      }
    );

    console.log(
      'YOLO RESPONSE:',
      JSON.stringify(response.data, null, 2)
    );

    return response.data;

  } catch (err) {

    console.error(
      'YOLO Service Error:',
      err.message
    );

    throw new Error(
      err.response?.data?.error ||
      err.message ||
      'YOLO service failed'
    );

  }

};

module.exports = { detectFood };