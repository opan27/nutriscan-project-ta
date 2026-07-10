import axios from 'axios';

// Base URL kosong -> pakai proxy Vite (/api -> localhost:3000).
// Saat di-build untuk production, set VITE_API_BASE ke URL backend.
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE || '',
});

// Sisipkan token JWT di setiap request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Kalau token invalid/expired (401), tendang ke halaman login
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(err);
  }
);

export default api;
