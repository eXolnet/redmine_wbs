Vue.component('wbs-issue', {
  template: '<tr><slot :issue="issue" :update="update"></slot></tr>',
  data: function() {
    return {
      "issue": Object.assign({}, this.issueDefault),
    };
  },
  methods: {
    update: function(patch) {
      this.issue = Object.assign(this.issue, patch);
    },
    reset: function() {
      this.issue = Object.assign({}, this.issueDefault);
    },
  },
  props: {
    issueDefault: {
      type: Object,
      required: true
    }
  },
  watch: {
    issue: {
      handler: function() {
        //
      },
      deep: true
    }
  },
});

new Vue({
  el: '#wbs-list'
});
