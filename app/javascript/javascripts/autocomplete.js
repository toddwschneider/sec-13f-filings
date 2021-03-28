document.addEventListener('DOMContentLoaded', function(e) {
  'use strict';

  if (!document.querySelector('#autocomplete')) return;

  let debounceTimeout;

  document.querySelector('#autocomplete').addEventListener('input', e => {
    clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(populateAutocomplete, 250);
  });

  document.addEventListener('keydown', function(e) {
    if ([38, 40].indexOf(e.keyCode) === -1) return;

    let links = Array.from(document.querySelectorAll('.autocomplete-link'));
    if (links.length === 0) return;

    let currentIndex = links.indexOf(document.activeElement);
    let increment = e.keyCode === 40 ? 1 : -1;
    currentIndex = Math.min(Math.max(currentIndex + increment, -1), links.length - 1);

    if (currentIndex === -1) {
      document.querySelector('#autocomplete').focus();
    } else {
      links[currentIndex].focus();
      e.preventDefault();
    }
  });

  function populateAutocomplete() {
    let input = document.querySelector('#autocomplete');
    let resultsContainer = document.querySelector('.autocomplete-results');
    let inNavBar = !!document.querySelector('nav #autocomplete');
    let query = input.value;

    if (!query) {
      resultsContainer.innerHTML = '';
      return;
    }

    let headers = {managers: 'Investment Managers', cusips: 'Investments'};
    let url = input.getAttribute('data-url') + '?q=' + encodeURIComponent(query);
    let autocompleteHtml = '';

    fetch(url).then(r => r.json()).then(data => {
      ['managers', 'cusips'].forEach(key => {
        let rows = data[key].map(row => {
          return `
            <a href="${row.url}" class="autocomplete-link" tabindex="0">
              <div class="px-3 py-1 hover:bg-indigo-200">
                <div class="text-xl leading-6 text-indigo-600 hover:text-indigo-900">${row.name}</div>
                <div class="text-base leading-4 text-gray-500">${row.extra}</div>
              </div>
            </a>
          `;
        });

        if (rows.length > 0) {
          let header = `<div class="font-medium text-xl pt-2 px-3">${headers[key]}</div>`;
          autocompleteHtml += `${header}${rows.join('')}`;
        }
      });

      if (autocompleteHtml === '') {
        autocompleteHtml = `
          <div class="text-xl px-3 pt-2 text-gray-500">No results found</div>
          <div class="px-3 pt-2 text-gray-500">Note: search by stock symbol is not currently supported, e.g. search for "Apple", not "AAPL"</div>
        `;
      }

      let autocompleteClasses = 'mt-2 pb-2 w-full max-w-xl bg-white border border-gray-500 rounded shadow absolute';
      if (inNavBar) autocompleteClasses += ' top-14 left-0 sm:left-auto';

      autocompleteHtml = `
        <div class="${autocompleteClasses}">
          ${autocompleteHtml}
        </div>
      `;

      resultsContainer.innerHTML = autocompleteHtml;
    });
  }
});
