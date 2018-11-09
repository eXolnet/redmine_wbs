<template>
  <table class="list issues issues--wbs odd-even">
    <thead>
    <tr>
      <slot name="header"></slot>
    </tr>
    </thead>

    <tbody @keydown.enter.stop.prevent>
    <tr
      is="wbs-issue"
      v-model="issues[$index]"
      :class="[$index % 2 === 0 ? 'odd' : 'even']"
      v-for="(issue, $index) in issues"
      :key="issue.local_key"
      @keydown.enter.exact.native="newNode(issue.parent_id)"
      @keydown.alt.enter.exact.native="newNode(issue.id)"
      @keydown.alt.down.exact.native="navigateDown($index)"
      @keydown.alt.up.exact.native="navigateUp($index)"
    ></tr>

    <tr v-if="issues.length === 0">
      <td colspan="5">
        No issues to display. <a href="#" @click.prevent="newIssue(0, null, 0)">Click here</a> to create the first one.
      </td>
    </tr>
    </tbody>

    <tfoot v-if="issues.length > 0">
    <tr>
      <td></td>
      <td></td>
      <td></td>
      <td>{{ total_estimated_hours | round(2) }}</td>
      <td>{{ total_estimated_hours | round(2) }}</td>
    </tr>
    </tfoot>
  </table>
</template>

<script>
  import _findIndex from 'lodash/findIndex';
  import _keyBy from 'lodash/keyBy';
  import _pick from 'lodash/pick';
  import _sumBy from 'lodash/sumBy';
  import axios from 'axios';
  import WbsIssue from './WbsIssue';

  let localKeyAutoincrement = 1;

  export default {
    name: 'WbsIssues',

    components: {
      WbsIssue,
    },

    computed: {
      total_estimated_hours() {
        return _sumBy(this.issues, issues => {
          return parseFloat(issues.estimated_hours) || 0;
        });
      },
    },

    data() {
      return {
        issues: [],
      };
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
      newNode(parentId = null) {
        let targetLevel = 0;
        let parentIndex = _findIndex(this.issues, ['id', parentId]);
        let parentLevel = -1;

        const parentIssue = this.issues[parentIndex];

        parentLevel = parentIssue ? parentIssue.level : -1;
        targetLevel = parentLevel + 1;

        const targetIndex = this.getTargetIndex(parentIndex + 1, targetLevel);

        this.newIssue(targetIndex, parentId, targetLevel);
      },

      getTargetIndex(fromIndex, minLevel) {
        let targetIndex = fromIndex;

        for (; targetIndex < this.issues.length; targetIndex++) {
          if (this.issues[targetIndex].level < minLevel) {
            break;
          }
        }

        return targetIndex;
      },

      newIssue(index, parent_id, level) {
        const newIssue = {
          estimated_hours: '',
          level,
          project_id: this.projectId,
          subject: '',
          tracker_id: 1, // TODO: Change me... do we need to insert a dynamic value here?
          local_key: this.newLocalKey(),
        };

        if (parent_id) {
          newIssue.parent_id = parent_id;
          newIssue.parent_issue_id = parent_id;
        }

        this.issues.splice(index, 0, newIssue);

        this.$nextTick(() => this.navigateVertically(index));
      },

      navigateDown(index) {
        this.navigateVertically(index + 1);
      },

      navigateUp(index) {
        this.navigateVertically(index - 1);
      },

      navigateVertically(targetIndex) {
        const targetRow = this.$el.querySelectorAll('tbody tr')[targetIndex];

        if (targetRow) {
          targetRow.querySelector('input[type=text]').focus();
        }
      },

      loadIssues() {
        axios
          .get(`/projects/${ this.projectId }/wbs.json`)
          .then(response => this.replaceIssues(response.data.issues));
      },

      replaceIssues(issues) {
        const oldIssues = _keyBy(this.issues, 'id');

        this.issues = issues.map(issue => {
          const oldIssue = oldIssues[issue.id] || {};

          issue.local_key = this.newLocalKey();

          issue = Object.assign(issue, _pick(oldIssue, ['subject', 'estimated_hours', 'local_key']));

          return issue;
        });
      },

      newLocalKey() {
        return localKeyAutoincrement++;
      },
    },

    mounted() {
      this.loadIssues();

      window.$bus.$on('loadIssues', this.loadIssues);
    },

    props: {
      projectId: {
        type: String,
        required: true,
      }
    },
  };
</script>
