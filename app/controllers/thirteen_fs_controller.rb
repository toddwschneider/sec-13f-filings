class ThirteenFsController < ApplicationController
  before_action :set_public_cache_header

  def manager
    @filer = ThirteenFFiler.find_by_param!(params[:id])

    if request.path != manager_path(@filer)
      redirect_to manager_path(@filer), status: :moved_permanently
      return
    end

    @filings = @filer.
      thirteen_fs.
      without_xml_fields.
      most_recent
  end

  def holdings_aggregated
    @filing = ThirteenF.without_xml_fields.find_by_param!(params[:id])
    @filing.process! if @filing.unprocessed?

    if request.path != thirteen_f_path(@filing)
      redirect_to thirteen_f_path(@filing), status: :moved_permanently
      return
    end
  end

  def holdings_detailed
    @filing = ThirteenF.without_xml_fields.find_by_param!(params[:id])
    @filing.process! if @filing.unprocessed?
  end

  def compare_holdings
    @filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:external_id])
    @other_filing = ThirteenF.without_xml_fields.find_by!(external_id: params[:other_external_id])

    head :bad_request unless @filing.cik == @other_filing.cik

    @filing.process! if @filing.unprocessed?
    @other_filing.process! if @other_filing.unprocessed?

    if @filing.report_date < @other_filing.report_date
      redirect_to thirteen_f_comparison_path(external_id: @other_filing.external_id, other_external_id: @filing.external_id)
      return
    end
  end

  def cusip_index
    @cusip = parsed_cusip
    @lookup = CompanyCusipLookup.find_by(cusip: @cusip)
    @investment_name = @lookup&.issuer_name || @cusip
    @name_for_title = @lookup&.symbol_and_name || @cusip
    @periods = CusipQuarterlyFilingsCount.for_cusip_index(@cusip)

    head :not_found if @periods.blank?
  end

  def all_cusip_holders
    @cusip = parsed_cusip
    @year = params[:year].to_i
    @quarter = params[:quarter].to_i

    head :bad_request unless (1..4).include?(@quarter) && @year <= Date.today.year

    @lookup = CompanyCusipLookup.find_by(cusip: @cusip)
    @investment_name = @lookup&.issuer_name || @cusip
    @name_for_title = @lookup&.symbol_and_name || @cusip
  end

  def manager_cusip_history
    @manager = ThirteenFFiler.find_by!(cik: params[:cik])
    @cusip = parsed_cusip
    @lookup = CompanyCusipLookup.find_by(cusip: @cusip)
    @investment_name = @lookup&.issuer_name || @cusip
    @name_for_title = @lookup&.symbol_and_name || @cusip
  end

  def newest_filings
    @filed_since = (Date.today - 7).beginning_of_quarter

    @filings = ThirteenF.
      newest_filings_since(@filed_since).
      processed.
      without_xml_fields.
      includes(:filer).
      page(params[:page]).
      per(100)
  end

  private

  def set_public_cache_header
    expires_in 5.minutes, public: true
  end
end
