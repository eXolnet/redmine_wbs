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
        issue: Object.assign({}, this.issueDefault),
      };
    },

    methods: {
      update(patch) {
        this.issue = Object.assign(this.issue, patch);
      },

      save() {
        const { issue } = this;
        const { id } = issue;

        axios
          .put(
            `/issues/${id}.json`,
            { issue }
          )
          .then(response => null) // TODO: Maybe a toast panel such as https://github.com/shakee93/vue-toasted.
          .catch(error => {
            // TODO: Handle and manage caught errors
            console.log('Error', error);
          });
      },
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
