import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const menu = [
  { to: '/',             label: 'Dashboard',         short: 'Home',    icon: '📊', end: true },
  { to: '/foods',        label: 'Manajemen Makanan', short: 'Makanan', icon: '🍽️' },
  { to: '/accuracy',     label: 'Statistik Akurasi', short: 'Akurasi', icon: '📈' },
  { to: '/verification', label: 'Verifikasi Scan',   short: 'Verif',   icon: '✅' },
  { to: '/users',        label: 'Manajemen User',    short: 'User',    icon: '👥' },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="flex min-h-screen">
      {/* ===== Sidebar (desktop) ===== */}
      <aside className="sticky top-0 hidden h-screen w-[258px] shrink-0 flex-col bg-forest-950 p-4 text-forest-100 lg:flex">
        <div className="flex items-center gap-3 px-2 pb-6 pt-1">
          <span className="text-3xl">🥗</span>
          <div>
            <div className="text-[17px] font-bold tracking-tight text-white">NutriScan</div>
            <div className="text-xs text-forest-400">Health Admin</div>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1">
          {menu.map((m) => (
            <NavLink
              key={m.to}
              to={m.to}
              end={m.end}
              className={({ isActive }) =>
                'flex items-center gap-3 rounded-lg px-3.5 py-2.5 text-[14.5px] font-medium transition ' +
                (isActive
                  ? 'bg-forest-800 text-white'
                  : 'text-forest-200 hover:bg-white/10 hover:text-white')
              }
            >
              <span className="w-5 text-center text-[17px]">{m.icon}</span>
              {m.label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-white/10 pt-3.5">
          <div className="mb-3 flex items-center gap-2.5 px-1.5">
            <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-forest-600 font-bold text-white">
              {(user?.name || 'A')[0].toUpperCase()}
            </div>
            <div className="min-w-0">
              <div className="truncate text-[13.5px] font-semibold text-white">{user?.name}</div>
              <div className="truncate text-[11.5px] text-forest-400">{user?.email}</div>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full rounded-lg border border-white/15 py-2 text-[13.5px] font-medium text-forest-100 transition hover:bg-white/10"
          >
            Keluar
          </button>
        </div>
      </aside>

      {/* ===== Mobile top bar ===== */}
      <header className="fixed inset-x-0 top-0 z-30 flex items-center justify-between border-b border-slate-200 bg-white/90 px-4 py-3 backdrop-blur lg:hidden">
        <div className="flex items-center gap-2">
          <span className="text-2xl">🥗</span>
          <span className="font-bold text-forest-900">NutriScan Admin</span>
        </div>
        <button onClick={handleLogout} className="text-sm font-medium text-slate-500">Keluar</button>
      </header>

      {/* ===== Content ===== */}
      <main className="min-w-0 flex-1 px-4 pb-24 pt-20 sm:px-6 lg:px-8 lg:pb-8 lg:pt-8">
        <Outlet />
      </main>

      {/* ===== Bottom nav (mobile) ===== */}
      <nav className="fixed inset-x-0 bottom-0 z-30 flex items-stretch justify-around border-t border-slate-200 bg-white lg:hidden">
        {menu.map((m) => (
          <NavLink
            key={m.to}
            to={m.to}
            end={m.end}
            className={({ isActive }) =>
              'flex flex-1 flex-col items-center gap-0.5 py-2 text-[10.5px] font-medium transition ' +
              (isActive ? 'text-forest-800' : 'text-slate-400')
            }
          >
            <span className="text-lg">{m.icon}</span>
            {m.short}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
