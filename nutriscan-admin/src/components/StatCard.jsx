const ACCENTS = {
  forest: 'bg-forest-100 text-forest-800',
  mint:   'bg-forest-200 text-forest-800',
  blue:   'bg-sky-100 text-sky-700',
  violet: 'bg-violet-100 text-violet-700',
  amber:  'bg-amber-100 text-amber-700',
};

export default function StatCard({ icon, label, value, accent = 'forest' }) {
  return (
    <div className="card flex items-center gap-4 p-5">
      <div className={`grid h-12 w-12 shrink-0 place-items-center rounded-xl text-2xl ${ACCENTS[accent] || ACCENTS.forest}`}>
        {icon}
      </div>
      <div className="min-w-0">
        <div className="text-[26px] font-bold leading-none text-forest-900">{value ?? 0}</div>
        <div className="mt-1 text-[13px] text-slate-500">{label}</div>
      </div>
    </div>
  );
}
