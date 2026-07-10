import { useEffect, useState, useCallback } from 'react';
import api from '../api/client';
import PageHeader from '../components/PageHeader';
import Modal from '../components/Modal';

const EMPTY = {
  name: '', name_en: '', yolo_label: '', category: '',
  calories: '', carbohydrates: '', protein: '', fat: '',
  sugar: '', sodium: '', fiber: '', serving_size_g: 100,
};

const NUTRIENTS = [
  { key: 'calories', label: 'Kalori (kcal)' },
  { key: 'carbohydrates', label: 'Karbohidrat (g)' },
  { key: 'protein', label: 'Protein (g)' },
  { key: 'fat', label: 'Lemak (g)' },
  { key: 'sugar', label: 'Gula (g)' },
  { key: 'sodium', label: 'Natrium (mg)' },
  { key: 'fiber', label: 'Serat (g)' },
  { key: 'serving_size_g', label: 'Porsi (g)' },
];

export default function Foods() {
  const [foods, setFoods] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState('');

  const load = useCallback(async (q = '', cat = '') => {
    setLoading(true);
    try {
      const { data } = await api.get('/api/admin/foods', { params: { search: q, category: cat } });
      setFoods(data.data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    api.get('/api/admin/food-categories').then((r) => setCategories(r.data.data)).catch(() => {});
  }, []);

  useEffect(() => {
    const t = setTimeout(() => load(search, category), 300);
    return () => clearTimeout(t);
  }, [search, category, load]);

  const openAdd = () => { setEditing(null); setForm(EMPTY); setFormError(''); setModalOpen(true); };
  const openEdit = (food) => { setEditing(food); setForm({ ...EMPTY, ...food }); setFormError(''); setModalOpen(true); };
  const handleChange = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const handleSave = async (e) => {
    e.preventDefault();
    setFormError('');
    if (!form.name || !form.yolo_label || form.calories === '') {
      setFormError('Nama, label YOLO, dan kalori wajib diisi.');
      return;
    }
    setSaving(true);
    try {
      if (editing) await api.put(`/api/admin/foods/${editing.id}`, form);
      else await api.post('/api/admin/foods', form);
      setModalOpen(false);
      load(search, category);
    } catch (err) {
      setFormError(err.response?.data?.message || 'Gagal menyimpan data');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (food) => {
    if (!window.confirm(`Hapus "${food.name}"?`)) return;
    try {
      await api.delete(`/api/admin/foods/${food.id}`);
      load(search, category);
    } catch (err) {
      // Makanan masih dipakai di meal_logs -> tawarkan hapus paksa
      if (err.response?.data?.code === 'IN_USE') {
        if (window.confirm(`${err.response.data.message}\n\nLanjutkan hapus paksa?`)) {
          await api.delete(`/api/admin/foods/${food.id}`, { params: { force: true } });
          load(search, category);
        }
      } else {
        alert(err.response?.data?.message || 'Gagal menghapus makanan');
      }
    }
  };

  return (
    <div>
      <PageHeader
        title="Manajemen Makanan"
        subtitle="Kelola database nutrisi makanan yang dikenali aplikasi"
        action={<button className="btn-primary" onClick={openAdd}>+ Tambah Makanan</button>}
      />

      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
        <input
          className="input sm:max-w-xs"
          placeholder="🔍  Cari nama atau label YOLO…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select className="input sm:max-w-[200px]" value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="">Semua kategori</option>
          {categories.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
        <span className="text-[13px] text-slate-400 sm:ml-auto">{foods.length} makanan</span>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50 text-left text-[11px] uppercase tracking-wide text-slate-500">
                <th className="px-4 py-3 font-semibold">Nama</th>
                <th className="px-4 py-3 font-semibold">Label YOLO</th>
                <th className="px-4 py-3 font-semibold">Kategori</th>
                <th className="px-4 py-3 text-right font-semibold">Kalori</th>
                <th className="px-4 py-3 text-right font-semibold">Prot</th>
                <th className="px-4 py-3 text-right font-semibold">Karbo</th>
                <th className="px-4 py-3 text-right font-semibold">Lemak</th>
                <th className="px-4 py-3 text-right font-semibold">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={8} className="py-8 text-center text-slate-400">Memuat…</td></tr>
              ) : foods.length === 0 ? (
                <tr><td colSpan={8} className="py-8 text-center text-slate-400">Tidak ada data</td></tr>
              ) : (
                foods.map((f) => (
                  <tr key={f.id} className="border-b border-slate-100 last:border-0 hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="font-semibold text-slate-800">{f.name}</div>
                      {f.name_en && <div className="text-xs text-slate-400">{f.name_en}</div>}
                    </td>
                    <td className="px-4 py-3"><code className="rounded border border-slate-200 bg-slate-50 px-2 py-0.5 text-[12.5px] text-slate-600">{f.yolo_label}</code></td>
                    <td className="px-4 py-3 text-slate-600">{f.category || '—'}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{f.calories}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{f.protein}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{f.carbohydrates}</td>
                    <td className="px-4 py-3 text-right tabular-nums">{f.fat}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center justify-end gap-2">
                        <button className="btn-icon" title="Edit" onClick={() => openEdit(f)}>✏️</button>
                        <button className="btn-icon btn-icon-danger" title="Hapus" onClick={() => handleDelete(f)}>🗑️</button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Makanan' : 'Tambah Makanan'}>
        <form onSubmit={handleSave}>
          {formError && <div className="alert-error">{formError}</div>}
          <div className="grid grid-cols-1 gap-x-4 gap-y-1 sm:grid-cols-2">
            <div>
              <label className="field-label">Nama *</label>
              <input className="input" value={form.name} onChange={(e) => handleChange('name', e.target.value)} placeholder="Sate Ayam" />
            </div>
            <div>
              <label className="field-label">Nama (English)</label>
              <input className="input" value={form.name_en || ''} onChange={(e) => handleChange('name_en', e.target.value)} placeholder="Chicken Satay" />
            </div>
            <div>
              <label className="field-label">Label YOLO *</label>
              <input className="input" value={form.yolo_label} onChange={(e) => handleChange('yolo_label', e.target.value)} placeholder="chicken_satay" disabled={!!editing} />
              {editing && <div className="mt-1 text-xs text-slate-400">Label YOLO tidak bisa diubah saat edit</div>}
            </div>
            <div>
              <label className="field-label">Kategori</label>
              <input className="input" value={form.category || ''} onChange={(e) => handleChange('category', e.target.value)} placeholder="Protein" list="cat-list" />
              <datalist id="cat-list">{categories.map((c) => <option key={c} value={c} />)}</datalist>
            </div>
            {NUTRIENTS.map((n) => (
              <div key={n.key}>
                <label className="field-label">{n.label}{n.key === 'calories' ? ' *' : ''}</label>
                <input className="input" type="number" step="0.1" value={form[n.key] ?? ''} onChange={(e) => handleChange(n.key, e.target.value)} />
              </div>
            ))}
          </div>
          <div className="mt-5 flex justify-end gap-2.5">
            <button type="button" className="btn-ghost" onClick={() => setModalOpen(false)}>Batal</button>
            <button type="submit" className="btn-primary" disabled={saving}>
              {saving ? 'Menyimpan…' : (editing ? 'Simpan Perubahan' : 'Tambah')}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
