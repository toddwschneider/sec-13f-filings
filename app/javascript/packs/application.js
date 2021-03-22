import Rails from '@rails/ujs';
Rails.start();

import '@fontsource/ibm-plex-sans/400.css';
import '@fontsource/ibm-plex-sans/500.css';
import '@fontsource/ibm-plex-mono/400.css';

require('datatables.net-dt');
require('datatables.net-buttons/js/buttons.html5');
require('datatables.net-fixedheader-dt');
require('datatables.net-fixedheader-dt/css/fixedHeader.dataTables.css');
import $ from 'jquery';
window.$ = jQuery;

require('javascripts/autocomplete.js');
require('javascripts/datatables.js');

require('stylesheets/application.scss');
require('stylesheets/datatables.scss');

const images = require.context('../images', true);
