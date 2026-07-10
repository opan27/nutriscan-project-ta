const API_BASE = import.meta.env.VITE_API_BASE || '';

// image_path dari backend berbentuk "uploads\scan-xxx.jpg" (backslash Windows)
export function imageUrl(path) {
  if (!path) return '';
  const clean = path.replace(/\\/g, '/').replace(/^\/?/, '/');
  return `${API_BASE}${clean}`;
}

export function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
}

export function formatDateTime(d) {
  if (!d) return '—';
  return new Date(d).toLocaleString('id-ID', {
    day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
  });
}
