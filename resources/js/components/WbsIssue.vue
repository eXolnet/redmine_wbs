<template>
  <tr>
    <slot :issue="issue" :update="update"></slot>
  </tr>
</template>

<script>
  import _debounce from 'lodash/debounce'
  import axios from 'axios'

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

      save() {
        //
      }
    },

    mounted() {
      this.saving = _debounce(this.save, 1000);
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
          this.saving();
        },
        deep: true
      }
    },
  };
</script>
