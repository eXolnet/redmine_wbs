import './bootstrap';
import Vue from 'vue';
import WbsIssues from './components/WbsIssues';

window.$bus = new Vue();

new Vue({
  el: '#wbs-list',
  components: {
    WbsIssues,
  }
});
