import { useEffect, useState } from 'react';
import {
  ResponsiveContainer, PieChart, Pie, Cell,
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
} from 'recharts';
import api from '../api/client';
import PageHeader from '../components/PageHeader';
import StatCard from '../components/StatCard';

const GOOD = '#0ca30c';      // benar
const CRITICAL = '#d03b3b';  // salah deteksi
const AMBER = '#eab308';     // tidak terdeteksi
const tooltipStyle = {
  border: '1px solid rgba(11,11,11,0.10)', borderRadius: 8, fontSize: 13,
  boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
};

export default function Accuracy() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api.get('/api/admin/accuracy-stats')
      .then((res) => setData(res.data.data))
      .catch((err) => setError(err.response?.data?.message || 'Gagal memuat data'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="py-16 text-center text-slate-400">Memuat statistik…</div>;
  if (error)   return <div className="alert-error">{error}</div>;

  const o = data.overall || {};
  const correct = Number(o.correct || 0);
  const wrong = Number(o.wrong || 0);
  const missed = Number(o.missed || 0);
  const totalVerified = correct + wrong + missed;

  const pie = [
    { name: 'Benar', value: correct, color: GOOD },
    { name: 'Salah deteksi', value: wrong, color: CRITICAL },
    { name: 'Tidak terdeteksi', value: missed, color: AMBER },
  ].filter((s) => s.value > 0);

  const perLabel = (data.per_label || []).map((r) => ({
    label: r.label,
    correct: Number(r.correct || 0),
    wrong: Number(r.wrong || 0),
    missed: Number(r.missed || 0),
    total: Number(r.total || 0),
    recall: r.total ? Math.round((Number(r.correct || 0) / Number(r.total)) * 100) : 0,
    avg_confidence: Number(r.avg_confidence || 0),
  }));

  const perScan = (data.per_scan || []).map((r) => ({
    key: r.scan_key,
    labels: r.labels || '—',
    correct: Number(r.correct || 0),
    wrong: Number(r.wrong || 0),
    missed: Number(r.missed || 0),
    total: Number(r.total || 0),
    accuracy: r.total ? Math.round((Number(r.correct || 0) / Number(r.total)) * 100) : 0,
    avg_confidence: Number(r.avg_confidence || 0),
  }));

  return (
    <div>
      <PageHeader title="Statistik Akurasi Model YOLO" subtitle="Evaluasi deteksi multi-object — bahan lampiran skripsi" />

      {totalVerified === 0 && (
        <div className="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          ℹ️ Belum ada objek yang diverifikasi. Buka menu <b>Verifikasi Scan</b> untuk menandai tiap objek
          (benar / salah deteksi / tidak terdeteksi) — angka di sini akan otomatis terisi.
        </div>
      )}

      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <StatCard icon="🎯" label="Akurasi Keseluruhan" value={o.accuracy_pct != null ? o.accuracy_pct + '%' : '—'} accent="forest" />
        <StatCard icon="✅" label="Benar (TP)" value={correct} accent="mint" />
        <StatCard icon="⚠️" label="Salah Deteksi (FP)" value={wrong} accent="amber" />
        <StatCard icon="👁️" label="Tidak Terdeteksi (FN)" value={missed} accent="violet" />
      </div>

      <div className="mt-3 text-[13px] text-slate-400">
        Akurasi = Benar / (Benar + Salah deteksi + Tidak terdeteksi) = {correct} / {totalVerified || '0'} ·
        Rata-rata confidence: <b>{o.avg_confidence != null ? o.avg_confidence + '%' : '—'}</b>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <div className="card p-5">
          <div className="mb-3.5 text-[15px] font-semibold text-forest-900">Distribusi Hasil Verifikasi</div>
          {totalVerified === 0 ? (
            <div className="grid h-[240px] place-items-center text-sm text-slate-400">Belum ada objek terverifikasi</div>
          ) : (
            <>
              <ResponsiveContainer width="100%" height={230}>
                <PieChart>
                  <Pie data={pie} dataKey="value" nameKey="name" innerRadius={58} outerRadius={86} paddingAngle={2} stroke="#fff" strokeWidth={2}>
                    {pie.map((s) => <Cell key={s.name} fill={s.color} />)}
                  </Pie>
                  <Tooltip contentStyle={tooltipStyle} />
                </PieChart>
              </ResponsiveContainer>
              <div className="mt-2 flex flex-wrap justify-center gap-x-5 gap-y-1 text-[13px] text-slate-600">
                <span className="inline-flex items-center gap-2"><span className="h-3 w-3 rounded" style={{ background: GOOD }} /> Benar: <b>{correct}</b></span>
                <span className="inline-flex items-center gap-2"><span className="h-3 w-3 rounded" style={{ background: CRITICAL }} /> Salah: <b>{wrong}</b></span>
                <span className="inline-flex items-center gap-2"><span className="h-3 w-3 rounded" style={{ background: AMBER }} /> Tak terdeteksi: <b>{missed}</b></span>
              </div>
            </>
          )}
        </div>

        <div className="card p-5">
          <div className="mb-3.5 text-[15px] font-semibold text-forest-900">Hasil per Label (Benar / Salah / Terlewat)</div>
          {perLabel.length === 0 ? (
            <div className="grid h-[240px] place-items-center text-sm text-slate-400">Belum ada data</div>
          ) : (
            <ResponsiveContainer width="100%" height={Math.max(230, perLabel.length * 38)}>
              <BarChart data={perLabel} layout="vertical" margin={{ top: 4, right: 16, left: 8, bottom: 0 }}>
                <CartesianGrid stroke="#e5e7eb" horizontal={false} />
                <XAxis type="number" allowDecimals={false} tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="label" width={110} tick={{ fill: '#475569', fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={tooltipStyle} cursor={{ fill: 'rgba(45,106,79,0.06)' }} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="correct" name="Benar" stackId="a" fill={GOOD} radius={[0, 0, 0, 0]} barSize={16} />
                <Bar dataKey="wrong" name="Salah" stackId="a" fill={CRITICAL} barSize={16} />
                <Bar dataKey="missed" name="Terlewat" stackId="a" fill={AMBER} radius={[0, 4, 4, 0]} barSize={16} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      <div className="mt-5 card overflow-hidden">
        <div className="px-5 pb-1 pt-5 text-[15px] font-semibold text-forest-900">Rincian Akurasi per Foto</div>
        <div className="px-5 pb-3 text-[12.5px] text-slate-400">Satu baris = satu foto. Objek dalam foto digabung, dengan rincian benar / salah / tidak terdeteksi.</div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-y border-slate-200 bg-slate-50 text-left text-[11px] uppercase tracking-wide text-slate-500">
                <th className="px-5 py-3 font-semibold">Objek dalam Foto</th>
                <th className="px-5 py-3 text-right font-semibold">Total Objek</th>
                <th className="px-5 py-3 text-right font-semibold">Benar</th>
                <th className="px-5 py-3 text-right font-semibold">Salah Deteksi</th>
                <th className="px-5 py-3 text-right font-semibold">Tidak Terdeteksi</th>
                <th className="px-5 py-3 text-right font-semibold">Akurasi</th>
              </tr>
            </thead>
            <tbody>
              {perScan.length === 0 ? (
                <tr><td colSpan={6} className="py-8 text-center text-slate-400">Belum ada foto terverifikasi</td></tr>
              ) : (
                perScan.map((r) => (
                  <tr key={r.key} className="border-b border-slate-100 last:border-0 hover:bg-slate-50/60">
                    <td className="px-5 py-3">
                      <div className="flex flex-wrap gap-1.5">
                        {r.labels.split(' + ').map((l, i) => (
                          <code key={i} className="rounded border border-slate-200 bg-slate-50 px-2 py-0.5 text-[12.5px] text-slate-600">{l}</code>
                        ))}
                      </div>
                    </td>
                    <td className="px-5 py-3 text-right tabular-nums text-slate-500">{r.total}</td>
                    <td className="px-5 py-3 text-right tabular-nums text-forest-700">{r.correct}</td>
                    <td className="px-5 py-3 text-right tabular-nums text-red-600">{r.wrong}</td>
                    <td className="px-5 py-3 text-right tabular-nums text-amber-600">{r.missed}</td>
                    <td className="px-5 py-3 text-right">
                      <span className={'badge tabular-nums ' + (r.accuracy >= 80 ? 'bg-forest-100 text-forest-800' : r.accuracy >= 50 ? 'bg-amber-100 text-amber-700' : 'bg-red-100 text-red-700')}>
                        {r.accuracy}%
                      </span>
                    </td>
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
