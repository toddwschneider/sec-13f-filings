# SEC 13F Filings

The code for [13f.info](https://13f.info), a more user-friendly way to view [SEC 13F filings](https://www.sec.gov/divisions/investment/13ffaq.htm)—the quarterly reports that list certain equity assets held by institutional investment managers

The Rails app has two primary functions:

1. A back end that downloads 13F data from the SEC's [EDGAR](https://www.sec.gov/edgar/searchedgar/companysearch.html) system and processes it into a structured PostgreSQL database
2. A front end that provides a way to view the processed data

Even if you don't care about the front end, you might find the code helpful purely for maintaining a relational database of 13F holdings reports

## Live examples

Some example links to showcase the app's functionality:

- [Homepage](https://13f.info)
- [List of all 13F filings from Berkshire Hathaway](https://13f.info/manager/0001067983-berkshire-hathaway-inc)
- [Berkshire Hathaway Q4 2020 13F](https://13f.info/13f/000095012321002786-berkshire-hathaway-inc-q4-2020)
- [Comparison of Berkshire Hathaway Q3 and Q4 2020 13Fs](https://13f.info/13f/000095012321002786/compare/000095012320012127)
- [History of Berkshire Hathaway's Apple stock holdings](https://13f.info/manager/0001067983/cusip/037833100)
- [All managers who reported owning Apple stock in Q4 2020](https://13f.info/cusip/037833100/2020/4)

It might be helpful to compare the above to the [SEC website's version](https://www.sec.gov/Archives/edgar/data/1067983/000095012321002786/xslForm13F_X01/0000950123-21-002786-3286.xml) of the Berkshire Hathaway Q4 2020 13F

## Limitations & caveats

**Tl; dr**: the SEC does not review filings for accuracy, there don't appear to be many validations on the SEC's side to ensure valid submissions, and even if everything is accurate, 13Fs still don't paint a complete picture of a manager's positions and/or investment outlook. Please do your own research before drawing any conclusions from 13F data

- The SEC puts this notice at the top of every filing on its site:
  - **The Securities and Exchange Commission has not necessarily reviewed the information in this filing and has not determined if it is accurate and complete. The reader should not assume that the information is accurate and complete.**
- 13Fs don't include all relevant information about a manager's positions. In particular, they do not include short positions, and only sometimes include options positions. It's plausible that a manager's actual long/short exposure to an investment is the opposite of what is listed in the 13F
- 13Fs are not very timely. Generally they are filed 45 days after the end of the quarter, by which time a manager's positions and outlook could have changed significantly
- Reported market values are as of the reporting period, they do not reflect the price at which the manager acquired the shares
- Anecdotally I've come across many errors, e.g. CUSIPs with typos, misclassified amendments ("new holdings" vs. "restatement"), obvously incorrect market values, and probably more
  - The app mostly passes data through from the SEC's website "as is", though one exception is that it attempts to correct some market values that appear to be overstated by a factor of 1,000

Some other notable limitations more specific to this app:

- Data is only available starting in 2014, because that's when the SEC began requiring managers to submit XML files [according to a spec](https://www.sec.gov/info/edgar/specifications/form13fxmltechspec.htm)
  - Filings before 2014 are generally plain text, and don't follow as consistent a structure, though with more work they could presumably be parsed and integrated into this app too
- Searching for a company by stock symbol is not fully supported
  - This is because the holdings-level SEC data is reported by [CUSIP](https://en.wikipedia.org/wiki/CUSIP), and the mapping of CUSIPs to stock symbols requires a paid license
  - The [`cusip_symbol_mappings`](app/models/cusip_symbol_mapping.rb) table can be filled in manually to support search by symbol, but the mapping data is not included in this repo
  - When in doubt, search for a company by name ("Apple") instead of by symbol ("AAPL")
- The app doesn't know anything about actual historical market prices, stock splits, dividend payouts, and other possibly relevant events. For example, when you're looking at [Berkshire Hathaway's Apple holdings over time](https://13f.info/manager/0001067983/cusip/037833100), you'll see the number of shares nearly quadrupled from Q2 to Q3 2020, which in reality reflects a 4-for-1 split, not a net purchase of shares

## Getting started with development

### Prerequisites

The app is a fairly standard Ruby on Rails app. Its primary dependencies include:

- Ruby
- PostgreSQL
- Node.js
- Yarn

Setting up each of these is beyond the scope of this readme, but if you don't know where to begin, I'd recommend the official [Getting Started with Rails](https://guides.rubyonrails.org/getting_started.html) guide. A future improvement to this repo could be to include a Docker container to help with environment setup

### Install Ruby/JavaScript dependencies and initialize database

Once the prerequisite tools are all configured, run the following commands from the project's root directory:

```sh
bundle
bundle exec rake db:setup
yarn
```

### Declare user agent with the SEC

Per the [SEC Webmaster FAQ](https://www.sec.gov/os/webmaster-faq#code-support), you need to declare your user agent:

`User-Agent: Sample Company Name AdminContact@<sample company domain>.com`

The app looks for an environment variable called `SEC_USER_AGENT`, you can set it in development by creating a `.env` file in the project root and adding `SEC_USER_AGENT="Sample Company Name AdminContact@<sample company domain>.com"`, substituting your own name/email

### Database schema

There are three main tables:

1. `thirteen_fs` - one row for each filing. Roughly corresponds to a filing's "primary doc" XML available on the SEC's website
2. `holdings` - each `thirteen_f` record has many `holdings`. One `holding` corresponds to a row in the "information table" XML
3. `aggregate_holdings` - a denormalized version of `holdings` which aggregates across the `other_manager` and `investment_discretion` columns. In practice it seems like most of the time it's more interesting to look at `aggregate_holdings` instead of `holdings`, but the app keeps both around. `aggregate_holdings` could be a view instead of a table, but I found that the indexed table helped significantly with query performance

There are a few materialized views that are calculated from the above tables and used to determine "canonical" names for each manager and CUSIP, see the `db/views/` folder for more

### Populate database with 13F data

There are a few ways to populate data. The simplest is to use the provided [`MinimalDbSeeder`](app/lib/minimal_db_seeder.rb) class, which will import and process recent filings from a handful of investment managers

```sh
bundle exec rake filings:seed_minimal_db
```

You can change the default managers and/or time periods either by editing [`minimal_db_seeder.rb`](app/lib/minimal_db_seeder.rb), or by specifying options in the Rails console:

```rb
# look up manager CIKs at https://www.sec.gov/edgar/searchedgar/cik.htm
my_ciks = ["CIK1", "CIK2"]
filing_periods = [{year: 2018, quarter: 1}, {year: 2018, quarter: 2}]
MinimalDbSeeder.new(ciks: my_ciks, periods: filing_periods).seed_minimal_db!
```

The minimal db seeder is intended as a quick and easy way to get your database into a useful state for development purposes, but if you want to import *all* filings from a given quarter, you can use the following method from within the Rails console:

```rb
ThirteenF.import_filings!(filing_year: 2021, filing_quarter: 1)
```

There's also a rake task available to import all filings from all quarters from Q1 2014 through present:

```sh
bundle exec rake filings:import_all
```

The `ThirteenF.import_filings!` method will create one placeholder row in the `thirteen_fs` table for each filing on the SEC's website, but it will *not* fetch the data for each filing. In order to fetch and process the data into the `holdings` and `aggregate_holdings` tables, you need to call `thirteen_f.process!` on each record, which:

1. Fetches the primary doc and info table XML files from the SEC's website
2. Stores them in the relevant `primary_doc_xml` and `info_table_xml` columns in the `thirteen_fs` table
3. Inserts the appropriate rows into the `holdings` and `aggregate_holdings` tables

The `ThirteenF.cache_data_and_create_holdings_for_unprocessed` method will queue up asynchronous delayed jobs to process whatever unprocessed records are in your `thirteen_fs` table. You can work off those jobs by running a delayed job worker from the project root:

```sh
bundle exec rake jobs:work
```

Processing seems to average about 1.5 records per second, and as of March 2021 there are ~140,000 records, so **it might take over a day to process all of them**. Note that the SEC's website has rate limits in place so I would not recommend running more than 2 workers at a time

### Running a development server

The app uses the [Webpacker gem](https://github.com/rails/webpacker), I find that the best development experience is to run the Rails server and Webpack dev server in separate terminal windows:

```sh
rails server
```

```sh
./bin/webpack-dev-server
```

### Keeping the database updated in production

You can run one `clock` and (at least) one `worker` process to keep the database up to date as new filings come in. There's also the `clockandworker` process, which can run on a single Heroku dyno. See the [`Procfile`](Procfile) for usage

### Other development notes

The app uses the [Tailwind CSS](https://tailwindcss.com/) framework. If you've never used Tailwind before, the short version is that you generally don't write CSS, instead you apply preexisting classes to your HTML templates. Special thanks to [Edwin Morris](https://github.com/ehmorris) for helping me get set up with Tailwind

The tables are built with [DataTables](https://datatables.net/), in most cases using AJAX data sources. Most of the relevant logic lives in the [`DataController`](app/controllers/data_controller.rb) and [`DataTableFormatter`](app/lib/data_table_formatter.rb) classes

There is no logged in experience, which makes it easier to use edge caching via [public Cache-Control headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)

### Ideas for future improvements

- Ability to analyze cohorts of managers, i.e. given a list of CIKs, look at combined holdings reports, quarterly comparisons
- Test suite! Especially geared at edge cases like misclassified amendments, reports where managers overstate values by a factor of 1,000
- Smarter/faster parsing on "13F release days", i.e. Feb 14, May 15, Aug 14, Nov 14
- Better autocomplete that does not require an exact substring match
- More official support for searching by stock ticker symbol

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
