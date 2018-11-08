<template>
  <table class="list issues issues--wbs odd-even">
    <colgroup>
      <col width="75">
      <col>
      <col width="125">
      <col width="150">
    </colgroup>

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
        @keydown.enter.exact.native="newSibling($index)"
        @keydown.alt.enter.exact.native="newChild($index)"
        @keydown.alt.down.exact.native="navigateDown($index)"
        @keydown.alt.up.exact.native="navigateUp($index)"
      ></tr>

      <tr v-if="issues.length === 0">
        <td colspan="4">
          No issues to display. <a href="#" @click.prevent="newIssue(0, null, 0)">Click here</a> to create the first one.
        </td>
      </tr>
    </tbody>

    <tfoot v-if="issues.length > 0">
      <tr>
          <td></td>
          <td></td>
          <td>{{ total_estimated_hours | round(2) }}</td>
          <td>{{ total_estimated_hours | round(2) }}</td>
      </tr>
    </tfoot>
  </table>
</template>

<script>
  import _findLastIndex from 'lodash/findLastIndex';
  import _keyBy from 'lodash/keyBy';
  import _pick from 'lodash/pick';
  import _sumBy from 'lodash/sumBy';
  import axios from 'axios';
  import WbsIssue from './WbsIssue';

  let uuidAutoincrement = 1;

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
      newSibling(ofIssueIndex) {
        const ofIssue = this.issues[ofIssueIndex];

        if ( ! ofIssue.hasOwnProperty('id')) {
          return;
        }

        const targetIndex = _findLastIndex(this.issues, issue => {
          return issue.parent_id === ofIssue.parent_id || issue.root_id === ofIssue.root_id && issue.level >= ofIssue.level;
        });

        this.newIssue(targetIndex + 1, ofIssue.parent_id, ofIssue.level);
      },

      newChild(ofIssueIndex) {
        const ofIssue = this.issues[ofIssueIndex];

        if ( ! ofIssue.hasOwnProperty('id')) {
          return;
        }

        let targetIndex = _findLastIndex(this.issues, issue => {
          return issue.parent_id === ofIssue.id && issue.level >= ofIssue.level;
        });

        if (targetIndex < 0) {
          targetIndex = ofIssueIndex;
        }

        this.newIssue(targetIndex + 1, ofIssue.id, ofIssue.level + 1);
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

      navigateVertically(targetIndex)  {
        const targetRow = document.querySelectorAll('.list tbody tr')[targetIndex];

        if (targetRow) {
          targetRow.querySelector('input').focus();
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
        return uuidAutoincrement++;
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
