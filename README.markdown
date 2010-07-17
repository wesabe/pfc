PFC
===

PFC originally stood for Personal Finance Community and is the main part of the Wesabe website. Wesabe is a personal finance website, formerly available at wesabe.com, which has since been released as open source. The web site is now available to run on your own Mac, Linux, or Windows (with VMWare) computer. The site's main features are:

1. Account Aggregation: seeing all your checking, savings, credit accounts, etc in one place
2. Tags & Spending Targets: edit your transactions and add tags so you can set spending limits on certain categories
3. Spending Trends: get analysis on your spending over time

PFC is one of the projects required for running the Wesabe website. For more information on setting it up on your own computer, see http://github.com/wesabe/wesabe.

Issues
------

* There is a fair amount of unused code that was never purged, so don't be too confused if you find something and you have no idea why it's there. It probably doesn't need to be. This is particularly true in parts of the accounts and transactions systems, much of which were moved to the BRCM (Java) backend. Delete!

* Currency exchange rates are not provided in this initial release. Wesabe used a commercial exchange rate provider (xe.com) for this data, and we can't use that service here or redistribute their data. If anyone would like to add exchange rate support for a particular provider, here's how you would add an exchange rate to the database:

        # exchange rates are stored in units of USD. If a rate is not present in the database for a given 
        # date, the nearest existing rate will be used
        CurrencyExchangeRate.create(:currency => "EUR", :rate => 0.7873, :date => Date.parse("2010-07-13"))
