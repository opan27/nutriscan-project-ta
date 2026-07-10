import { useEffect, useState, useCallback } from 'react';
import api from '../api/client';
import { useAuth } from '../auth/AuthContext';
import PageHeader from '../components/PageHeader';
import Modal from '../components/Modal';
import { formatDate } from '../lib/format';

const EMPTY_ADMIN = { name: '', email: '', password: '', role: 'admin' };

export default function Users() {
  const { user: me } = useAuth();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_ADMIN);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState('');

  const load = useCallback(async (q = '') => {
    setLoading(true);
    try {
      const { data } = await api.get('/api/admin/users', { params: { search: q } });
      setUsers(data.data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const t = setTimeout(() => load(search), 300);
    return () => clearTimeout(t);
  }, [search, load]);

  const toggleRole = async (u) => {
    const nextRole = u.role === 'admin' ? 'user' : 'admin';
    const verb = nextRole === 'admin' ? 'Jadikan admin' : 'Turunkan jadi user biasa';
    if (!window.confirm(`${verb}: ${u.name}?`)) return;
    setBusyId(u.id);
    try {
      await api.put(`/api/admin/users/${u.id}/role`, { role: nextRole });
      load(search);
    } catch (err) {
      alert(err.response?.data?.message || 'Gagal mengubah role');
    } finally {
      setBusyId(null);
    }
  };

  const handleDelete = async (u) => {
    if (!window.confirm(`Hapus user "${u.name}"? Semua data (scan, log) ikut terhapus.`)) return;
    setBusyId(u.id);
    try {
      await api.delete(`/api/admin/users/${u.id}`);
      load(search);
    } catch (err) {
      alert(err.response?.data?.message || 'Gagal menghapus user');
    } finally {
      setBusyId(null);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    setFormError('');
    if (!form.name || !form.email || !form.password) {
      setFormError('Semua field wajib diisi.');
      return;
    }
    setSaving(true);
    try {
      await api.post('/api/admin/users', form);
      setModalOpen(false);
      setForm(EMPTY_ADMIN);
      load(search);
    } catch (err) {
      setFormError(err.response?.data?.message || 'Gagal membuat akun');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="Manajemen User"
        subtitle="Kelola akun pengguna dan hak akses admin"
        action={<button className="btn-primary" onClick={() => { setForm(EMPTY_ADMIN); setFormError(''); setModalOpen(true); }}>+ Tambah Admin</button>}
      />

      <div className="mb-4 flex items-center gap-3">
        <input
          className="input sm:max-w-xs"
          placeholder="🔍  Cari nama atau email…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <span className="ml-auto text-[13px] text-slate-400">{users.length} user</span>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50 text-left text-[11px] uppercase tracking-wide text-slate-500">
                <th className="px-4 py-3 font-semibold">Nama</th>
                <th className="px-4 py-3 font-semibold">Email</th>
                <th className="px-4 py-3 font-semibold">Role</th>
                <th className="px-4 py-3 font-semibold">Terdaftar</th>
                <th className="px-4 py-3 text-right font-semibold">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="py-8 text-center text-slate-400">Memuat…</td></tr>
              ) : users.length === 0 ? (
                <tr><td colSpan={5} className="py-8 text-center text-slate-400">Tidak ada data</td></tr>
              ) : (
                users.map((u) => {
                  const isMe = u.id === me?.id;
                  return (
                    <tr key={u.id} className="border-b border-slate-100 last:border-0 hover:bg-slate-50/60">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2.5">
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-forest-100 text-[13px] font-bold text-forest-800">
                            {u.name[0].toUpperCase()}
                          </span>
                          <span className="font-semibold text-slate-800">{u.name}</span>
                          {isMe && <span className="rounded bg-sky-100 px-1.5 py-0.5 text-[11px] font-semibold text-sky-700">Anda</span>}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-600">{u.email}</td>
                      <td className="px-4 py-3">
                        <span className={'badge ' + (u.role === 'admin' ? 'bg-forest-100 text-forest-800' : 'bg-slate-100 text-slate-600')}>
                          {u.role}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-slate-400">{formatDate(u.created_at)}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-2">
                          <button className="btn-sm" disabled={isMe || busyId === u.id} onClick={() => toggleRole(u)}
                            title={isMe ? 'Tidak bisa mengubah akun sendiri' : ''}>
                            {u.role === 'admin' ? 'Jadikan User' : 'Jadikan Admin'}
                          </button>
                          <button className="btn-icon btn-icon-danger" disabled={isMe || busyId === u.id} onClick={() => handleDelete(u)}
                            title={isMe ? 'Tidak bisa menghapus akun sendiri' : 'Hapus'}>🗑️</button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Tambah Akun Admin" maxWidth="max-w-md">
        <form onSubmit={handleCreate}>
          {formError && <div className="alert-error">{formError}</div>}
          <label className="field-label">Nama</label>
          <input className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Nama lengkap" />
          <label className="field-label mt-3">Email</label>
          <input className="input" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder="admin@nutriscan.com" />
          <label className="field-label mt-3">Password</label>
          <input className="input" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder="Minimal 6 karakter" />
          <label className="field-label mt-3">Role</label>
          <select className="input" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })}>
            <option value="admin">Admin</option>
            <option value="user">User</option>
          </select>
          <div className="mt-5 flex justify-end gap-2.5">
            <button type="button" className="btn-ghost" onClick={() => setModalOpen(false)}>Batal</button>
            <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Menyimpan…' : 'Buat Akun'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
