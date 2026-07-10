import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Login gagal');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-forest-950 to-forest-700 p-5">
      <form onSubmit={handleSubmit} className="w-full max-w-sm rounded-2xl bg-white p-9 text-center shadow-pop">
        <div className="text-5xl">🥗</div>
        <h1 className="mt-2.5 text-[23px] font-bold text-forest-900">NutriScan Admin</h1>
        <p className="mb-6 mt-1 text-sm text-slate-500">Masuk untuk mengelola aplikasi</p>

        {error && <div className="alert-error text-left">{error}</div>}

        <div className="text-left">
          <label className="field-label">Email</label>
          <input
            className="input"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@nutriscan.com"
            required
          />
          <label className="field-label mt-3">Password</label>
          <input
            className="input"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
          />
        </div>

        <button className="btn-primary mt-6 w-full py-3" type="submit" disabled={loading}>
          {loading ? 'Memproses…' : 'Masuk'}
        </button>
      </form>
    </div>
  );
}
