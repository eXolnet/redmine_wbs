import './bootstrap';
import '../sass/wbs.scss';
import { createApp } from 'vue';
import WbsIssues from './components/WbsIssues.vue';

createApp({
  components: {
    WbsIssues,
  },
}).mount('#wbs-list');
