/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // Vitalis Health — Forest Green → Mint scale
        forest: {
          50:  '#F0F7F2',
          100: '#D8F3DC',
          200: '#B7E4C7',
          300: '#95D5B2', // mint
          400: '#74C69D',
          500: '#52B788',
          600: '#40916C',
          700: '#2D6A4F',
          800: '#1B4332', // PRIMARY brand
          900: '#0F2D20',
          950: '#081C15',
        },
        // status (colorblind-safe, dari palette tervalidasi)
        good:     '#0ca30c',
        warning:  '#eab308',
        critical: '#d03b3b',
      },
      fontFamily: {
        sans: ['"Manrope Variable"', 'Manrope', 'system-ui', '-apple-system', 'Segoe UI', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: '8px',
        lg: '10px',
        xl: '14px',
        '2xl': '18px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04)',
        pop: '0 20px 50px rgba(8,28,21,0.25)',
      },
    },
  },
  plugins: [],
};
