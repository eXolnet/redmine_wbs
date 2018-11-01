<template>
  <tr>
    <slot :issue="issue" :update="update"></slot>
  </tr>
</template>

<script>
  export default {
    name: 'WbsIssue',

    data() {
      return {
        "issue": Object.assign({}, this.issueDefault),
      };
    },

    methods: {
      update(patch) {
        this.issue = Object.assign(this.issue, patch);
      },
      reset() {
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
        handler() {
          //
        },
        deep: true
      }
    },
  };
</script>
