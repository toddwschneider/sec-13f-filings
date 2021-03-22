class DataController < ApplicationController
  before_action :set_public_cache_header

  def autocomplete
    managers_data = ThirteenFFiler.
      autocomplete(params[:q]).
      limit(8).
      map do |f|
        {
          name: f.name,
          extra: "#{f.city_and_state}",
          url: manager_path(f)
        }
      end

    cusips_data = CompanyCusipLookup.
      autocomplete(params[:q]).
      limit(5).
      map do |c|
        {
          name: c.issuer_name,
          extra: "CUSIP: #{c.cusip}, Class: #{c.class_title.upcase}",
          url: cusip_index_path(cusip: c.cusip)
        }
      end

    render json: {managers: managers_data, cusips: cusips_data}
  end

  def thirteen_f_data
    filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:external_id])
    render json: DataTableFormatter.thirteen_f_to_aggregated_datatable(filing)
  end

  def thirteen_f_detailed_data
    filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:external_id])
    render json: DataTableFormatter.thirteen_f_to_detailed_datatable(filing)
  end

  def compare_holdings_data
    filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:external_id])
    other_filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:other_external_id])
    render json: DataTableFormatter.thirteen_f_comparison_to_datatable(filing, other_filing)
  end

  def all_cusip_holders_data
    year = params[:year].to_i
    quarter = params[:quarter].to_i

    head :bad_request unless (1..4).include?(quarter) && year <= Date.today.year

    data = DataTableFormatter.all_cusip_holdings_to_datatable(
      cusip: parsed_cusip,
      year: year,
      quarter: quarter
    )

    render json: data
  end

  def manager_cusip_history_data
    data = DataTableFormatter.manager_cusip_history_to_datatable(
      cusip: parsed_cusip,
      manager_cik: params[:cik]
    )

    render json: data
  end

  private

  def set_public_cache_header
    expires_in 1.hour, public: true
  end
end
