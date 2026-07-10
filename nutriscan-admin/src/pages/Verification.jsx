import { useEffect, useState, useCallback } from 'react';
import api from '../api/client';
import PageHeader from '../components/PageHeader';
import VerifyBadge from '../components/VerifyBadge';
import { imageUrl, formatDateTime } from '../lib/format';

const TABS = [
  { key: 'unverified', label: 'Belum diverifikasi' },
  { key: 'verified',   label: 'Terverifikasi' },
  { key: 'all',        label: 'Semua' },
];
const PAGE = 9;

export default function Verification() {
  const [status, setStatus] = useState('unverified');
  const [groups, setGroups] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [labels, setLabels] = useState([]);

  const load = useCallback(async (st) => {
    setLoading(true);
    try {
      const { data } = await api.get('/api/admin/scan-groups', { params: { status: st, limit: PAGE, offset: 0 } });
      setGroups(data.data);
      setTotal(data.total);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(status); }, [status, load]);
  useEffect(() => {
    api.get('/api/admin/foods').then((r) => setLabels(r.data.data.map((f) => f.yolo_label))).catch(() => {});
  }, []);

  const loadMore = async () => {
    const { data } = await api.get('/api/admin/scan-groups', { params: { status, limit: PAGE, offset: groups.length } });
    setGroups((prev) => [...prev, ...data.data]);
    setTotal(data.total);
  };

  // Update satu objek dalam sebuah grup; hapus grup dari tab "unverified" bila sudah selesai semua
  const patchObject = (imagePath, logId, patch) => {
    setGroups((prev) => {
      const next = prev.map((g) => {
        if (g.image_path !== imagePath) return g;
        return { ...g, objects: g.objects.map((o) => o.log_id === logId ? { ...o, ...patch } : o) };
      });
      if (status === 'unverified') {
        return next.filter((g) => g.objects.some((o) => o.verdict == null));
      }
      return next;
    });
  };

  const addObject = (imagePath, obj) => {
    setGroups((prev) => prev.map((g) => g.image_path === imagePath ? { ...g, objects: [...g.objects, obj] } : g));
  };
  const removeObject = (imagePath, logId) => {
    setGroups((prev) => prev.map((g) => g.image_path === imagePath ? { ...g, objects: g.objects.filter((o) => o.log_id !== logId) } : g));
  };

  return (
    <div>
      <PageHeader title="Verifikasi Scan" subtitle="Tandai tiap objek pada foto: benar, salah deteksi, atau tambah objek yang tidak terdeteksi" />

      <div className="mb-4 inline-flex rounded-lg border border-slate-200 bg-white p-1">
        {TABS.map((t) => (
          <button key={t.key} onClick={() => setStatus(t.key)}
            className={'rounded-md px-3.5 py-1.5 text-[13px] font-medium transition ' +
              (status === t.key ? 'bg-forest-800 text-white' : 'text-slate-500 hover:text-forest-800')}>
            {t.label}
          </button>
        ))}
        <span className="ml-2 self-center px-2 text-[13px] text-slate-400">{total} foto</span>
      </div>

      {loading ? (
        <div className="py-16 text-center text-slate-400">Memuat…</div>
      ) : groups.length === 0 ? (
        <div className="card grid place-items-center py-16 text-center text-slate-400">
          {status === 'unverified' ? '🎉 Semua foto sudah diverifikasi!' : 'Tidak ada data'}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
            {groups.map((g) => (
              <ScanGroupCard
                key={g.image_path}
                group={g}
                labels={labels}
                onPatch={patchObject}
                onAdd={addObject}
                onRemove={removeObject}
              />
            ))}
          </div>
          {groups.length < total && (
            <div className="mt-5 text-center">
              <button className="btn-ghost" onClick={loadMore}>Muat lebih banyak</button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

function ScanGroupCard({ group, labels, onPatch, onAdd, onRemove }) {
  const [adding, setAdding] = useState(false);
  const [missedLabel, setMissedLabel] = useState('');
  const detectedCount = group.objects.filter((o) => o.detected_label).length;

  const addMissed = async () => {
    if (!missedLabel) return;
    const { data } = await api.post('/api/admin/accuracy/missed', { image_path: group.image_path, actual_label: missedLabel });
    onAdd(group.image_path, { log_id: data.data.id, detected_label: null, confidence_pct: null, verdict: 'missed', actual_label: missedLabel });
    setMissedLabel('');
    setAdding(false);
  };

  const delMissed = async (logId) => {
    await api.delete(`/api/admin/accuracy/${logId}`);
    onRemove(group.image_path, logId);
  };

  return (
    <div className="card overflow-hidden">
      <div className="aspect-video w-full bg-slate-100">
        {group.image_path ? (
          <img src={imageUrl(group.image_path)} alt="scan" className="h-full w-full object-cover"
            onError={(e) => { e.currentTarget.style.display = 'none'; }} />
        ) : <div className="grid h-full place-items-center text-4xl text-slate-300">🍽️</div>}
      </div>

      <div className="p-4">
        <div className="mb-2 flex items-center justify-between text-[12px] text-slate-400">
          <span>{group.user_name || '—'} · {detectedCount} objek terdeteksi</span>
          <span>{formatDateTime(group.scanned_at)}</span>
        </div>

        <div className="space-y-2">
          {group.objects.map((o) => (
            <ObjectRow key={o.log_id} obj={o} imagePath={group.image_path}
              labels={labels} onPatch={onPatch} onDelete={delMissed} />
          ))}
        </div>

        {/* Tambah objek tak terdeteksi */}
        {adding ? (
          <div className="mt-3 flex gap-2">
            <input className="input py-1.5 text-[13px]" list="missed-labels" value={missedLabel}
              onChange={(e) => setMissedLabel(e.target.value)} placeholder="Label objek yang terlewat…" autoFocus />
            <datalist id="missed-labels">{labels.map((l) => <option key={l} value={l} />)}</datalist>
            <button className="btn-primary px-3 py-1.5 text-[13px]" onClick={addMissed}>Tambah</button>
            <button className="btn-ghost px-3 py-1.5 text-[13px]" onClick={() => { setAdding(false); setMissedLabel(''); }}>✕</button>
          </div>
        ) : (
          <button onClick={() => setAdding(true)}
            className="mt-3 w-full rounded-lg border border-dashed border-slate-300 py-2 text-[13px] font-medium text-slate-500 transition hover:border-forest-400 hover:text-forest-800">
            + Objek tidak terdeteksi
          </button>
        )}
      </div>
    </div>
  );
}

function ObjectRow({ obj, imagePath, labels, onPatch, onDelete }) {
  const [choosing, setChoosing] = useState(false);
  const [wrongLabel, setWrongLabel] = useState('');
  const [busy, setBusy] = useState(false);

  const isMissed = !obj.detected_label;

  const markCorrect = async () => {
    setBusy(true);
    try {
      await api.put(`/api/admin/accuracy/${obj.log_id}/verdict`, { verdict: 'correct' });
      onPatch(imagePath, obj.log_id, { verdict: 'correct', actual_label: obj.detected_label });
    } finally { setBusy(false); }
  };
  const markWrong = async () => {
    setBusy(true);
    try {
      await api.put(`/api/admin/accuracy/${obj.log_id}/verdict`, { verdict: 'wrong', actual_label: wrongLabel || null });
      onPatch(imagePath, obj.log_id, { verdict: 'wrong', actual_label: wrongLabel || null });
      setChoosing(false);
    } finally { setBusy(false); }
  };

  return (
    <div className="rounded-lg border border-slate-200 bg-slate-50/50 p-2.5">
      <div className="flex items-center justify-between gap-2">
        <div className="min-w-0">
          {isMissed ? (
            <span className="text-[13px] text-slate-400 italic">(tak terdeteksi model)</span>
          ) : (
            <>
              <code className="text-[13px] font-semibold text-slate-700">{obj.detected_label}</code>
              <span className="ml-1.5 text-[12px] text-slate-400">{obj.confidence_pct}%</span>
            </>
          )}
        </div>

        {/* status / kontrol */}
        {obj.verdict ? (
          <div className="flex items-center gap-2">
            <VerifyBadge verdict={obj.verdict} />
            {isMissed && <button className="btn-icon btn-icon-danger !p-1 text-[13px]" title="Hapus" onClick={() => onDelete(obj.log_id)}>🗑️</button>}
          </div>
        ) : (
          <div className="flex shrink-0 gap-1.5">
            <button disabled={busy} onClick={markCorrect}
              className="rounded-md bg-forest-800 px-2.5 py-1 text-[12px] font-semibold text-white hover:bg-forest-900 disabled:opacity-50">Benar</button>
            <button disabled={busy} onClick={() => setChoosing((v) => !v)}
              className="rounded-md border border-red-300 px-2.5 py-1 text-[12px] font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">Salah</button>
          </div>
        )}
      </div>

      {/* pilih label sebenarnya saat "Salah" */}
      {choosing && !obj.verdict && (
        <div className="mt-2 flex gap-2">
          <input className="input py-1.5 text-[13px]" list={`wl-${obj.log_id}`} value={wrongLabel}
            onChange={(e) => setWrongLabel(e.target.value)} placeholder="Label sebenarnya (opsional)…" autoFocus />
          <datalist id={`wl-${obj.log_id}`}>{labels.map((l) => <option key={l} value={l} />)}</datalist>
          <button disabled={busy} className="btn-primary px-3 py-1.5 text-[13px]" onClick={markWrong}>Simpan</button>
        </div>
      )}

      {obj.verdict === 'wrong' && obj.actual_label && (
        <div className="mt-1.5 text-[12px] text-slate-400">seharusnya: <code>{obj.actual_label}</code></div>
      )}
      {obj.verdict === 'missed' && (
        <div className="mt-1.5 text-[12px] text-slate-400">objek: <code>{obj.actual_label}</code></div>
      )}
    </div>
  );
}
