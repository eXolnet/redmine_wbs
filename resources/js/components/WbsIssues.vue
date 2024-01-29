<template>
  <table class="list issues issues--wbs odd-even">
    <thead>
      <tr>
        <slot name="header"></slot>
      </tr>
    </thead>

    <tbody
      vue:is="wbs-issue"
      :class="[$index % 2 === 0 ? 'odd' : 'even']"
      :issue.sync="issues[$index]"
      v-for="(issue, $index) in issues"
      :key="issue.local_key"
      @refreshIssueList="loadIssues"
      @remove="removeIssue($index)"
      @keydown.enter.exact.native="newNode(issue.parent_id)"
      @keydown.alt.enter.exact.native="newNode(issue.id)"
      @keydown.alt.down.exact.native="navigateDown($index)"
      @keydown.alt.up.exact.native="navigateUp($index)"
    ></tbody>

    <tbody v-if="issues.length === 0">
      <tr>
        <td :colspan="6 + additionalColumns.length">
          No issues to display. <a href="#" @click.prevent="newIssue(0, null, 0)">Click here</a> to create the first one.
        </td>
      </tr>
    </tbody>

    <tfoot v-if="issues.length > 0">
      <tr>
        <td colspan="4"></td>
        <td>{{ total_estimated_hours | round(2) }}</td>
        <td>{{ total_estimated_hours | round(2) }}</td>
        <td v-for="column in additionalColumns"></td>
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
  import { defineComponent } from 'vue';
  import WbsIssue from './WbsIssue';

  import { COLUMNS_EDITABLE } from '../constants';

  let localKeyAutoincrement = 1;

  export default defineComponent({
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
        const location = this.newNodeLocation(parentId);

        this.newIssue(location.index, parentId, location.level);
      },

      newNodeLocation(parentId = null) {
        let targetLevel = 0;
        let parentIndex = _findIndex(this.issues, ['id', parentId]);
        let parentLevel = -1;

        const parentIssue = this.issues[parentIndex];

        parentLevel = parentIssue ? parentIssue.level : -1;
        targetLevel = parentLevel + 1;

        return {
          level: targetLevel,
          index: this.getTargetIndex(parentIndex + 1, targetLevel),
        };
      },

      getIndexForIssue(searchIssue) {
        return _findIndex(this.issues, issue => issue === searchIssue);
      },

      getIssueByIndex(index) {
        return this.issues[index];
      },

      getIssueById(id) {
        return this.issues.find(issue => issue.id === id);
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
        const css_classes = [
          'issue',
          'tracker-' + this.defaultTrackerId,
          'priority-default',
          'created-by-me'
        ];

        if (parent_id) {
          css_classes.push('child');
        }

        const newIssue = {
          estimated_hours: '',
          level,
          project_id: this.projectId,
          subject: '',
          tracker_id: this.defaultTrackerId,
          local_key: this.newLocalKey(),
          css_classes: css_classes.join(' '),
        };

        if (parent_id) {
          newIssue.parent_id = parent_id;
          newIssue.parent_issue_id = parent_id;
        }

        this.issues.splice(index, 0, newIssue);

        this.$nextTick(() => this.navigateVertically(index));
      },

      removeIssue(index) {
        this.issues.splice(index, 1);
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
        const oldIssues = _keyBy(this.issues, 'id'),
          newIssue = oldIssues[undefined];

        this.issues = issues.map(issue => {
          const oldIssue = oldIssues[issue.id] || {};

          issue.local_key = this.newLocalKey();

          issue = Object.assign(issue, _pick(oldIssue, ['local_key'].concat(COLUMNS_EDITABLE)));

          return issue;
        });

        if (newIssue) {
          const newIssueLocation = this.newNodeLocation(newIssue.parent_id);

          this.issues.splice(newIssueLocation.index, 0, newIssue);
        }
      },

      newLocalKey() {
        return localKeyAutoincrement++;
      },
    },

    mounted() {
      this.loadIssues();
    },

    props: {
      additionalColumns: {
        type: Array,
        default() {
          return [];
        }
      },

      projectId: {
        type: String,
        required: true,
      },

      defaultTrackerId: {
        type: String,
        required: true,
      }
    },
  });
</script>
