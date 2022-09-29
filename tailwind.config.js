const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./**/*.{html,css}"
  ],
  theme: {
    extend: {
      fontFamily: {
        'sans': ['Montserrat', ...defaultTheme.fontFamily.sans],
      },
      keyframes: {
        wiggle: {
          '0%, 100%': { transform: 'rotate(-12deg)' },
          '50%': { transform: 'rotate(12deg)' }
        }
      },
      animation: {
        wiggle: 'wiggle 3s ease-in-out infinite'
      },
      dropShadow: {
        '4xl': [
            '0 0px 5px rgba(0, 0, 0, 0.08)',
            '0 0px 13px rgba(0, 0, 0, 0.3)',
            '0 15px 35px rgba(0, 0, 0, 0.25)',
            '0 15px 65px rgba(0, 0, 0, 0.15)'
        ]
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}
