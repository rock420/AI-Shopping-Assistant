const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.(j|t)s(x)'
  ],
  theme: {
    fontFamily: {
      sans: ['InterVariable', ...defaultTheme.fontFamily.sans],
    },
  },
}
