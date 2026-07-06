require('dotenv').config();
const app  = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`\n🥗  NutriScan API running on http://localhost:${PORT}`);
  console.log(`📋  Health check: http://localhost:${PORT}/api/ping`);
  console.log(`🌍  Environment : ${process.env.NODE_ENV || 'development'}\n`);
});
