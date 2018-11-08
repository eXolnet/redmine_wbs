<template>
  <tr class="issue hascontextmenu" :class="cssClasses">
    <td class="checkbox hide-when-print">
      <input type="checkbox" name="ids[]" :value="issue.id">
    </td>
    <td class="id">
      <a :href="'/issues/' + issue.id">{{ issue.id }}</a>
    </td>
    <td class="subject">
      <input type="text" :value="issue.subject" @input="update({ subject: $event.target.value })"/>
    </td>
    <td class="estimated_hours">
      <input type="number" :value="issue.estimated_hours" @input="update({ estimated_hours: $event.target.value })" @keydown.alt.up.exact.prevent/>
    </td>
    <td>{{ issue.total_estimated_hours | round(2) }}</td>
  </tr>
</template>

<script>
  import _debounce from 'lodash/debounce';
  import _isEqual from 'lodash/isEqual';
  import _pick from 'lodash/pick';
  import axios from 'axios';

  export default {
    name: 'WbsIssue',

    model: {
      prop: 'issue',
      event: 'update'
    },

    computed: {
      issueEditable() {
        return _pick(this.issue, ['subject', 'estimated_hours']);
      },

      cssClasses() {
        const classes = [];

        classes.push(this.issue.is_closed ? 'closed' : 'opened');

        // TODO: Add children detection to append `parent` class.

        if (this.issue.hasOwnProperty('parent_id')) {
          classes.push('child');
          classes.push('idnt');
          classes.push(`idnt-${ this.issue.level }`);
        }

        return classes;
      }
    },

    filters: {
      round(value, precision = 0) {
          if (typeof value !== 'number') {
            return null;
          }

          return value.toFixed(precision);
      },
    },

    methods: {
      update(patch) {
        const patchedIssue = Object.assign({}, this.issue, patch);

        this.$emit('update', patchedIssue);
      },

      save() {
        const { issue } = this;
        const { id } = issue;
        const method = id ? 'PUT' : 'POST';
        const url = method === 'PUT' ? `/issues/${id}.json` : '/issues.json';

        axios({
            method,
            url,
            data: { issue }
          })
          .then(response => {
            const { issue } = response.data;

            if (issue) {
              this.update({id: response.data.issue.id});
            }

            window.$bus.$emit('loadIssues');
            // TODO: Maybe a toast panel such as https://github.com/shakee93/vue-toasted.
          })
          .catch(error => {
            // TODO: Handle and manage caught errors properly
            console.error('WbsIssue Error', error);
          });
      },
    },

    mounted() {
      this.saving = _debounce(this.save, 1000);
    },

    props: {
      issue: {
        type: Object,
        required: true
      }
    },

    watch: {
      issueEditable: {
        handler(newValue, oldValue) {
          if (_isEqual(newValue, oldValue)) {
            return;
          }

          this.saving();
        },
        deep: true
      },
    },
  };
</script>
