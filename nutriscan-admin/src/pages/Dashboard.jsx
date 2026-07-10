import { useEffect, useState } from 'react';
import {
  ResponsiveContainer, AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip,
} from 'recharts';
import api from '../api/client';
import PageHeader from '../components/PageHeader';
import StatCard from '../components/StatCard';
import VerifyBadge from '../components/VerifyBadge';
import { formatDateTime } from '../lib/format';

const DAYS_ID = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
const tooltipStyle = {
  border: '1px solid rgba(11,11,11,0.10)', borderRadius: 8, fontSize: 13,
  boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
};

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [recent, setRecent] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api.get('/api/admin/stats'),
      api.get('/api/admin/scans', { params: { limit: 8 } }),
    ])
      .then(([s, r]) => { setStats(s.data.data); setRecent(r.data.data); })
      .catch((err) => setError(err.response?.data?.message || 'Gagal memuat data'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="py-16 text-center text-slate-400">Memuat dashboard…</div>;
  if (error)   return <div className="alert-error">{error}</div>;

  const trend = (stats.scan_trend || []).map((d) => ({
    label: DAYS_ID[new Date(d.date).getDay()], total: Number(d.total),
  }));
  const topFoods = (stats.top_foods || []).map((f) => ({
    label: f.detected_label, total: Number(f.total),
  }));

  return (
    <div>
      <PageHeader title="Dashboard" subtitle="Ringkasan aktivitas aplikasi NutriScan" />

      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <StatCard icon="👥" label="Total User"    value={stats.total_users}  accent="blue" />
        <StatCard icon="🍽️" label="Total Makanan" value={stats.total_foods}  accent="mint" />
        <StatCard icon="📷" label="Total Scan"     value={stats.total_scans}  accent="violet" />
        <StatCard icon="🎯" label="Akurasi Model"  value={stats.accuracy_pct != null ? stats.accuracy_pct + '%' : '—'} accent="forest" />
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <div className="card p-5">
          <div className="mb-3.5 text-[15px] font-semibold text-forest-900">Tren Scan 7 Hari Terakhir</div>
          {trend.length === 0 ? (
            <Empty>Belum ada data scan</Empty>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <AreaChart data={trend} margin={{ top: 10, right: 12, left: -18, bottom: 0 }}>
                <defs>
                  <linearGradient id="scanFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#2D6A4F" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="#2D6A4F" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#e5e7eb" vertical={false} />
                <XAxis dataKey="label" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={{ stroke: '#cbd5e1' }} tickLine={false} />
                <YAxis allowDecimals={false} tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={tooltipStyle} cursor={{ stroke: '#cbd5e1' }} />
                <Area type="monotone" dataKey="total" name="Jumlah scan" stroke="#1B4332" strokeWidth={2} fill="url(#scanFill)" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="card p-5">
          <div className="mb-3.5 text-[15px] font-semibold text-forest-900">Makanan Paling Sering Discan</div>
          {topFoods.length === 0 ? (
            <Empty>Belum ada data scan</Empty>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={topFoods} layout="vertical" margin={{ top: 4, right: 16, left: 8, bottom: 0 }}>
                <CartesianGrid stroke="#e5e7eb" horizontal={false} />
                <XAxis type="number" allowDecimals={false} tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="label" width={110} tick={{ fill: '#475569', fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={tooltipStyle} cursor={{ fill: 'rgba(45,106,79,0.06)' }} />
                <Bar dataKey="total" name="Jumlah" fill="#40916C" radius={[0, 4, 4, 0]} barSize={18} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="mt-5 card overflow-hidden">
        <div className="flex items-center justify-between px-5 pb-3 pt-5">
          <div className="text-[15px] font-semibold text-forest-900">Aktivitas Scan Terbaru</div>
          <span className="text-[13px] text-slate-400">{recent.length} terbaru</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-y border-slate-200 bg-slate-50 text-left text-[11px] uppercase tracking-wide text-slate-500">
                <th className="px-5 py-3 font-semibold">Waktu</th>
                <th className="px-5 py-3 font-semibold">User</th>
                <th className="px-5 py-3 font-semibold">Terdeteksi</th>
                <th className="px-5 py-3 text-right font-semibold">Confidence</th>
                <th className="px-5 py-3 font-semibold">Status</th>
              </tr>
            </thead>
            <tbody>
              {recent.length === 0 ? (
                <tr><td colSpan={5} className="py-8 text-center text-slate-400">Belum ada scan</td></tr>
              ) : (
                recent.map((s) => (
                  <tr key={s.scan_id} className="border-b border-slate-100 last:border-0 hover:bg-slate-50/60">
                    <td className="px-5 py-3 text-slate-500">{formatDateTime(s.scanned_at)}</td>
                    <td className="px-5 py-3">{s.user_name || '—'}</td>
                    <td className="px-5 py-3">
                      <span className="font-medium text-slate-800">{s.food_name || s.detected_label}</span>
                      <span className="ml-2 rounded bg-slate-100 px-1.5 py-0.5 font-mono text-[11px] text-slate-500">{s.detected_label}</span>
                    </td>
                    <td className="px-5 py-3 text-right font-medium tabular-nums">{s.confidence_pct}%</td>
                    <td className="px-5 py-3"><VerifyBadge verdict={s.verdict} /></td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function Empty({ children }) {
  return <div className="grid h-[250px] place-items-center text-sm text-slate-400">{children}</div>;
}
