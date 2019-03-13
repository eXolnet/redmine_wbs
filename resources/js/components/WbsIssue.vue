<template>
  <tbody @keydown.meta.shift.down.stop.prevent="showDescription" @keydown.meta.shift.up.stop.prevent="hideDescription" @keydown.meta.[.stop.prevent="unindentLine" @keydown.meta.].stop.prevent="indentLine">
    <tr class="hascontextmenu" :class="cssClasses">
      <td class="checkbox hide-when-print">
        <input type="checkbox" name="ids[]" :value="issue.id">
      </td>
      <td class="id">
        <a :href="'/issues/' + issue.id">{{ issue.id }}</a>
      </td>
      <td class="description_toggle">
        <a href="#" class="wbs__description-toggle" @click.prevent="toggleDescription"></a>
      </td>
      <td class="subject">
        <input ref="subject" type="text" :value="issue.subject" @input="update({ subject: $event.target.value })" @blur="removeIfNewEmptyIssue"/>
      </td>
      <td class="estimated_hours">
        <input ref="estimated_hours" type="number" :value="issue.estimated_hours" @input="update({ estimated_hours: $event.target.value })" @keydown.alt.up.exact.prevent/>
      </td>
      <td class="total_estimated_hours">
        {{ issue.total_estimated_hours | round(2) }}
      </td>

      <td v-for="column in issue.additionnal_columns" :key="column.name" :class="column.css_classes" v-html="column.content"></td>
    </tr>

    <tr class="issue" :class="cssClasses" v-if="isDescriptionShowed">
      <td colspan="3"></td>
      <td class="description">
        <textarea
          ref="description"
          :rows="countDescriptionLines"
          :value="issue.description"
          @input="update({ description: $event.target.value })"
          @keydown.enter.stop
        ></textarea>
      </td>
    </tr>
  </tbody>
</template>

<script>
  import _debounce from 'lodash/debounce';
  import _isEqual from 'lodash/isEqual';
  import _omit from 'lodash/omit';
  import _pick from 'lodash/pick';
  import axios from 'axios';

  import { COLUMNS_EDITABLE } from '../constants';

  export default {
    name: 'WbsIssue',

    model: {
      prop: 'issue',
      event: 'update'
    },

    computed: {
      watchableColumns() {
        return _pick(this.issue, COLUMNS_EDITABLE);
      },

      countDescriptionLines() {
        const description = this.issue.description || "";

        return description.split(/\r\n|\r|\n/).length;
      },

      cssClasses() {
        const classes = this.issue.css_classes.split(/\s/);

        if (this.issue.level > 0) {
          classes.push('idnt');
          classes.push(`idnt-${ this.issue.level }`);
        }

        if (this.issue.description) {
          classes.push('hasdescription');
        }

        return classes;
      }
    },

    data() {
      return {
        isDescriptionShowed: false,
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

      save(data = {}) {
        const issue = Object.assign(this.issue, data);

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
              this.update(_omit(response.data, COLUMNS_EDITABLE));
            }

            this.$emit('refreshIssueList');
          })
          .catch(error => {
            // TODO: Handle and manage caught errors properly
            console.error('WbsIssue Error', error);
          });
      },

      hideDescription() {
        this.isDescriptionShowed = false;

        this.$nextTick(() => this.$refs.subject.focus());
      },

      indentLine() {
        const index = this.$parent.getIndexForIssue(this.issue);
        const previousIssue = this.$parent.getIssueByIndex(index - 1);

        if (! previousIssue) {
          return;
        }

        if (previousIssue.level === this.issue.level) {
          this.save({ parent_issue_id: previousIssue.id });
        } else if (previousIssue.level === (this.issue.level + 1)) {
          this.save({ parent_issue_id: previousIssue.parent_id });
        }
      },

      unindentLine() {
        if (! this.issue.parent_id) {
          return;
        }

        const parent = this.$parent.getIssueById(this.issue.parent_id);

        this.save({ parent_issue_id: parent.parent_id });
      },

      showDescription() {
        this.isDescriptionShowed = true;

        this.$nextTick(() => this.$refs.description.focus());
      },

      toggleDescription() {
        if (this.isDescriptionShowed) {
          this.hideDescription();
        } else {
          this.showDescription();
        }
      },

      removeIfNewEmptyIssue() {
        if (this.issue.id || this.issue.subject) {
          return;
        }

        this.$emit('remove');
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
      watchableColumns: {
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
