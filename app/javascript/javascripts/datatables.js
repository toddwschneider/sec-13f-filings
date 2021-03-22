$(function() {
  'use strict';

  const isTouchDevice = 'ontouchstart' in window ||
    navigator.maxTouchPoints > 0 ||
    navigator.msMaxTouchPoints > 0;

  $.extend(true, $.fn.dataTable.defaults, {
    autoWidth: false,
    bLengthChange: false,
    createdRow: (row, data, dataIndex, cells) => {
      $(row).addClass('bg-gray-50 even:bg-white hover:bg-gray-200');
    },
    fixedHeader: (isTouchDevice ? false : {headerOffset: $('nav').outerHeight()}),
    language: {search: 'Filter'},
    order: [],
    pageLength: 50,
    scrollX: isTouchDevice
  });

  const cik = $('[data-cik]').data('cik');
  const cusip = $('[data-cusip]').data('cusip');

  const buttonsDefault = [
    {extend: 'csv', text: 'Download CSV', className: 'mr-4'},
    {extend: 'copy', text: 'Copy to Clipboard'}
  ];

  let issuerNameOptions = {
    createdCell: addClassToTdNotTh('truncate')
  }

  let centeredTextOptions = {
    createdCell: addClassToTdNotTh('text-center')
  };

  let numberOptions = {
    createdCell: addClassToTdNotTh('text-right'),
    orderSequence: ['desc', 'asc'],
    render: $.fn.dataTable.render.number(',', '.')
  };

  let holdingsPctOptions = {
    createdCell: addClassToTdNotTh('text-right'),
    orderSequence: ['desc', 'asc'],
    render: function(pct, type, row) {
      if (pct == null) return '';

      if (type === 'display') {
        let digits = pct >= 10 ? 0 : 1;
        return pct.toFixed(digits) + '%';
      }

      return pct;
    }
  };

  let cusipOptions = {
    createdCell: addClassToTdNotTh('text-center'),
    render: function(cusip, type, row) {
      if (type === 'display') {
        return `<a href="/manager/${cik}/cusip/${cusip}">${cusip}</a>`;
      }

      return cusip;
    }
  };

  let otherManagerOptions = {
    createdCell: addClassToTdNotTh('text-center truncate')
  };

  let comparisonPctOptions = {
    createdCell: addClassToTdNotTh('text-right truncate'),
    orderSequence: ['desc', 'asc'],
    render: function(pct, type, row) {
      if (type === 'display') {
        return pct == null ? 'NEW' : Math.round(pct) + '%';
      } else if (type === 'sort') {
        return pct == null ? Infinity : pct;
      }

      return pct;
    }
  };

  let dateFiledOptions = {
    createdCell: addClassToTdNotTh('text-right'),
    render: function(data, type, row) {
      if (type === 'display') {
        return mdy(data);
      }

      return data;
    }
  };

  let reportDateOptions = {
    createdCell: addClassToTdNotTh('text-right'),
    render: function(data, type, row) {
      if (type === 'display') {
        return `<a href="/13f/${data[1]}">${mdy(data[0])}</a>`;
      }

      return data[0];
    }
  };

  let yearQuarterOptions = {
    createdCell: addClassToTdNotTh('text-center'),
    render: function(data, type, row) {
      let label = `${data[0]} Q${data[1]}`;

      if (type === 'display') {
        return `<a href="/cusip/${cusip}/${data[0]}/${data[1]}">${label}</a>`;
      }

      return label;
    }
  };

  let managerOptions = {
    createdCell: addClassToTdNotTh('truncate'),
    render: function(data, type, row) {
      if (type === 'display') {
        return `<a href="/manager/${data[1]}">${data[0]}</a>`;
      }

      return data[0];
    }
  };

  function mdy(dateString) {
    let parts = dateString.split('-');
    return [+parts[1], +parts[2], +parts[0]].join('/');
  }

  function addClassToTdNotTh(className) {
    return (td, cellData, rowData, rowIndex, colIndex) => {
      $(td).addClass(className);
    }
  }

  function errorHandler(xhr, status, error) {
    alert('Sorry, something went wrong. You could try reloading the page');
  }

  $('#filingAggregated').DataTable({
    ajax: {
      cache: true,
      error: errorHandler,
      url: $('#filingAggregated').data('url')
    },
    buttons: buttonsDefault,
    columns: [
      issuerNameOptions,
      centeredTextOptions,
      cusipOptions,
      numberOptions,
      holdingsPctOptions,
      numberOptions,
      numberOptions,
      centeredTextOptions,
    ],
    dom: 'l<"w-52"f>rtip<"mt-6 sm:mt-0"B>'
  });

  $('#filingDetailed').DataTable({
    ajax: {
      cache: true,
      error: errorHandler,
      url: $('#filingDetailed').data('url')
    },
    buttons: buttonsDefault,
    columns: [
      issuerNameOptions,
      centeredTextOptions,
      cusipOptions,
      numberOptions,
      holdingsPctOptions,
      numberOptions,
      numberOptions,
      centeredTextOptions,
      centeredTextOptions,
      otherManagerOptions,
      numberOptions,
      numberOptions,
      numberOptions
    ],
    columnDefs: [
      {targets: [10, 11, 12], width: '8rem', className: 'truncate'}
    ],
    dom: 'l<"w-52"f>rtip<"mt-6 sm:mt-0"B>'
  });

  $('#filingComparison').DataTable({
    ajax: {
      cache: true,
      error: errorHandler,
      url: $('#filingComparison').data('url')
    },
    buttons: buttonsDefault,
    columns: [
      issuerNameOptions,
      centeredTextOptions,
      cusipOptions,
      centeredTextOptions,
      numberOptions,
      numberOptions,
      numberOptions,
      comparisonPctOptions,
      numberOptions,
      numberOptions,
      numberOptions,
      comparisonPctOptions
    ],
    createdRow: (row, data, dataIndex, cells) => {
      let bgClass;

      if (data[7] === null) {
        bgClass = 'bg-green-100 hover:bg-green-200';
      } else if (data[7] === -100) {
        bgClass = 'bg-red-100 hover:bg-red-200';
      } else {
        bgClass = 'bg-gray-50 even:bg-white hover:bg-gray-200';
      }

      $(row).addClass(bgClass);
    },
    dom: 'l<"w-52"f>rtip<"mt-6 sm:mt-0"B>'
  });

  $('#managerCusipHoldings').DataTable({
    ajax: {
      cache: true,
      error: errorHandler,
      url: $('#managerCusipHoldings').data('url')
    },
    buttons: buttonsDefault,
    columns: [
      reportDateOptions,
      numberOptions,
      holdingsPctOptions,
      numberOptions,
      centeredTextOptions,
      dateFiledOptions,
      yearQuarterOptions
    ],
    dom: 'l<"w-52"f>rtip<"mt-6 sm:mt-0"B>'
  });

  $('#allCusipHoldings').DataTable({
    ajax: {
      cache: true,
      dataSrc: function(json) {
        let val = $.fn.dataTable.render.number(',', '.', 0, '$').display(json.total_value);
        $('.total-value').html(val);
        return json.data;
      },
      error: errorHandler,
      url: $('#allCusipHoldings').data('url')
    },
    buttons: buttonsDefault,
    columns: [
      managerOptions,
      reportDateOptions,
      numberOptions,
      numberOptions,
      centeredTextOptions
    ],
    dom: 'l<"w-52"f>rtip<"mt-6 sm:mt-0"B>'
  });

  $('#managerFilings').DataTable({
    columnDefs: [
      {targets: [2, 3], orderSequence: ['desc', 'asc']}
    ],
    searching: false
  });
});
