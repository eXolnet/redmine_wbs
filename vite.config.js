import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
  ],
  publicDir: false,
  resolve: {
    alias: {
      // The root component template is compiled at runtime from the Redmine view
      vue: 'vue/dist/vue.esm-bundler.js',
    },
  },
  define: {
    'process.env.NODE_ENV': JSON.stringify(mode),
  },
  build: {
    outDir: 'assets',
    emptyOutDir: false,
    sourcemap: mode !== 'production',
    minify: mode === 'production',
    lib: {
      entry: 'resources/js/wbs.js',
      name: 'RedmineWbs',
      formats: ['iife'],
      fileName: () => 'javascripts/wbs.js',
      cssFileName: 'stylesheets/wbs',
    },
  },
}));
