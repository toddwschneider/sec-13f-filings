module ThirteenFsHelper
  def thirteen_f_dl_items(filing)
    if prev_filing = filing.previous_filings.without_xml_fields.first
      prev_link = link_to mdy(prev_filing.date_filed), thirteen_f_path(prev_filing)
    end

    if next_filing = filing.future_filings.without_xml_fields.first
      next_link = link_to mdy(next_filing.date_filed), thirteen_f_path(next_filing)
    end

    items = [
      ["Location", filing.city_and_state],
      ["Holdings as of", mdy(filing.report_date)],
      ["Value ($000)", number_to_currency(filing.holdings_value_calculated, precision: 0)],
      ["Num holdings", number_with_delimiter(filing.aggregate_holdings_count)],
      ["Date filed", mdy(filing.date_filed)],
      ["Form type", filing.form_and_amendment_type.upcase],
      ["Prev filing", prev_link],
      ["Next filing", next_link],
      ["SEC", link_to("View on sec.gov", filing.sec_index_url, target: :_blank)]
    ]

    if filing.other_managers.present?
      note = %{
        Holdings aggregated across “other managers” listed in original SEC filing,
        #{link_to("see here", thirteen_f_detailed_path(filing))}
        for detailed holdings broken out by other managers
      }.html_safe

      items << ["Note", note]
    end

    items
  end

  def thirteen_f_detailed_dl_items(filing)
    if prev_filing = filing.previous_filings.without_xml_fields.first
      prev_link = link_to mdy(prev_filing.date_filed), thirteen_f_detailed_path(prev_filing)
    end

    if next_filing = filing.future_filings.without_xml_fields.first
      next_link = link_to mdy(next_filing.date_filed), thirteen_f_detailed_path(next_filing)
    end

    note = %{
      Holdings broken out by “other managers” reported in original SEC filing,
      #{link_to("see here", thirteen_f_path(filing))}
      for holdings aggregated across other managers
    }.html_safe

    [
      ["Location", filing.city_and_state],
      ["Holdings as of", mdy(filing.report_date)],
      ["Value ($000)", number_to_currency(filing.holdings_value_calculated, precision: 0)],
      ["Num holdings", number_with_delimiter(filing.holdings_count_calculated)],
      ["Date filed", mdy(filing.date_filed)],
      ["Form type", filing.form_and_amendment_type.upcase],
      ["Prev filing", prev_link],
      ["Next filing", next_link],
      ["SEC", link_to("View on sec.gov", filing.sec_index_url, target: :_blank)],
      ["Note", note]
    ]
  end

  def thirteen_f_comparison_dl_items(filing, other_filing)
    [
      [
        "Period",
        link_to(filing.qq_yyyy, thirteen_f_path(filing)),
        link_to(other_filing.qq_yyyy, thirteen_f_path(other_filing))
      ],
      [
        "Holdings as of",
        mdy(filing.report_date),
        mdy(other_filing.report_date)
      ],
      [
        "Value ($000)",
        number_to_currency(filing.holdings_value_calculated, precision: 0),
        number_to_currency(other_filing.holdings_value_calculated, precision: 0)
      ],
      [
        "Num holdings",
        number_with_delimiter(filing.aggregate_holdings_count),
        number_with_delimiter(other_filing.aggregate_holdings_count)
      ],
      ["Form type", filing.form_or_amendment_type.upcase, other_filing.form_or_amendment_type.upcase],
      ["Date filed", mdy(filing.date_filed), mdy(other_filing.date_filed)]
    ]
  end

  def filer_dl_items(filer)
    [
      ["Location", filer.city_and_state],
      ["CIK", filer.cik],
      ["All SEC filings", link_to("View on sec.gov", all_sec_filings_url(filer.cik), target: :_blank)]
    ]
  end

  def cusip_index_dl_items(lookup, cusip)
    [
      (["Symbol", lookup&.symbol] if lookup&.symbol),
      ["CUSIP", cusip],
      ["Type", lookup&.investment_type],
      ["Class", lookup&.class_title&.upcase]
    ].compact
  end

  def all_cusip_holders_dl_items(lookup, cusip)
    [
      (["Symbol", lookup&.symbol] if lookup&.symbol),
      ["CUSIP", cusip],
      ["Type", lookup&.investment_type],
      ["Class", lookup&.class_title&.upcase],
      ["Total Reported Value ($000, excl. options)", nil, {dd_class: "total-value"}]
    ].compact
  end

  def manager_cusip_history_dl_items(manager, lookup, cusip)
    [
      (["Symbol", lookup&.symbol] if lookup&.symbol),
      ["CUSIP", cusip],
      ["Investment type", lookup&.investment_type],
      ["Class", lookup&.class_title&.upcase],
      ["Manager CIK", manager.cik]
    ].compact
  end

  def comparison_select_options(filing, other_filing = nil)
    options = filing.comparison_candidates.map do |f|
      label = [f.yyyy_qq, f.amendment_type&.upcase].compact.join(" - ")

      url = thirteen_f_comparison_path(
        external_id: filing.external_id,
        other_external_id: f.external_id
      )

      [label, url]
    end

    if other_filing
      selected_url = thirteen_f_comparison_path(
        external_id: filing.external_id,
        other_external_id: other_filing.external_id
      )
    end

    options_for_select(options, selected_url)
  end

  def all_sec_filings_url(cik)
    "https://www.sec.gov/cgi-bin/browse-edgar?CIK=#{cik}"
  end
end
