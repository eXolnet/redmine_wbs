import './bootstrap';
import { createApp } from 'vue';
import WbsIssues from './components/WbsIssues';

createApp({
  components: {
    WbsIssues,
  },
}).mount('#wbs-list');
