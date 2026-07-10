// Mendukung verdict string ('correct'|'wrong'|'missed') maupun is_correct lama (1/0/null)
export default function VerifyBadge({ verdict, value }) {
  const v = verdict !== undefined ? verdict
    : value === 1 || value === true ? 'correct'
    : value === 0 || value === false ? 'wrong'
    : null;

  if (v === 'correct') return <span className="badge bg-forest-100 text-forest-800">✅ Benar</span>;
  if (v === 'wrong')   return <span className="badge bg-red-100 text-red-700">⚠️ Salah deteksi</span>;
  if (v === 'missed')  return <span className="badge bg-amber-100 text-amber-700">👁️ Tidak terdeteksi</span>;
  return <span className="badge bg-slate-100 text-slate-500">Belum diverifikasi</span>;
}
