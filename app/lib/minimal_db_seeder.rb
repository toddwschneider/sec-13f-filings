class MinimalDbSeeder
  DEFAULT_CIKS = %w(
    0000102909
    0001067983
    0001167483
    0001603466
  )

  attr_reader :ciks, :periods

  def initialize(ciks: DEFAULT_CIKS, periods: nil)
    @ciks = Array.wrap(ciks)

    @periods = periods || (0..3).map do |i|
      date = Date.today - (3 * i).months
      {year: date.year, quarter: (date.month - 1) / 3 + 1}
    end
  end

  def seed_minimal_db!
    start_time = Time.zone.now
    puts "#{start_time}: beginning minimal db seed, might take a few minutes…"

    periods.each do |p|
      year = p.fetch(:year)
      quarter = p.fetch(:quarter)

      puts "#{Time.zone.now}: importing 13Fs filed in #{year} Q#{quarter}"
      ThirteenF.import_filings!(filing_year: year, filing_quarter: quarter)
    end

    puts "#{Time.zone.now}: queueing jobs for sample managers"
    ThirteenF.process_unprocessed_filings!(ciks: ciks)

    puts "#{Time.zone.now}: processing filings data"
    Delayed::Worker.new.work_off(1000)

    puts "#{Time.zone.now}: deleting unprocessed filings"
    ThirteenF.unprocessed.where("created_at > ?", start_time).delete_all
    ThirteenFFiler.refresh!

    puts "#{Time.zone.now}: done, minimal db now available"
  end
end
