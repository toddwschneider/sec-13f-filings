namespace :filings do
  desc "Seed development database with enough filings to get started"
  task seed_minimal_db: :environment do
    MinimalDbSeeder.new.seed_minimal_db!
  end

  desc "Import all 13F filings"
  task import_all: :environment do
    current_year = Date.today.year
    current_quarter = (Date.today.month - 1) / 3 + 1
    years_range = (ThirteenF::FIRST_YEAR_EXPECTED_TO_HAVE_XML_URLS..current_year)

    years_range.to_a.product([1, 2, 3, 4]).
      reject { |y, q| y == current_year && q > current_quarter }.
      each do |y, q|
        puts "#{Time.zone.now}: importing 13F forms filed during #{y} Q#{q}"
        ThirteenF.import_filings!(filing_year: y, filing_quarter: q)
      end

    puts "#{Time.zone.now}: all 13F forms imported, but you'll need to process them to fetch all of the holdings data"
  end
end
