/**
 * We'll load the axios HTTP library which allows us to easily issue requests
 * to our Laravel back-end. This library automatically handles sending the
 * CSRF token as a header based on the value of the "XSRF" token cookie.
 */

import axios from 'axios';

axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

/**
 * Next we will register the CSRF Token as a common header with Axios so that
 * all outgoing HTTP requests automatically have it attached. This is just
 * a simple convenience so we don't have to attach every token manually.
 */

const token = document.head.querySelector('meta[name="csrf-token"]');

if (token) {
  axios.defaults.headers.common['X-CSRF-Token'] = token.content;
} else {
  console.error('CSRF token not found!');
}

/**
 * Finally, we need to authenticate our Axios API calls.
 */

const userApiKey = document.head.querySelector('meta[name="user-api-key"]');

if (userApiKey) {
  axios.defaults.headers.common['X-Redmine-API-Key'] = userApiKey.content;
} else {
  console.error('User API key not found!');
}

/**
 * Prevent Redmine to display a warning when editing a textarea
 */
window.addEventListener('load', () => {
  window.onbeforeunload = null;
});
