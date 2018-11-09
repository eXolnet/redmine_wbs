const mix = require('laravel-mix');

/*
 |--------------------------------------------------------------------------
 | Mix Asset Management
 |--------------------------------------------------------------------------
 |
 | Mix provides a clean, fluent API for defining some Webpack build steps
 | for your Laravel application. By default, we are compiling the Sass
 | file for the application as well as bundling up all the JS files.
 |
 */

mix
  .js('resources/js/wbs.js', 'assets/javascripts')
  .sass('resources/sass/wbs.scss', 'assets/stylesheets')
  .options({
    processCssUrls: false,
  });
