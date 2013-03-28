MoneyWellSpent - How much did you spend?
==============
A script to summarize your money spent on amazon.(de,com,co.uk,fr)

As someone who considers himself as some kind of poweruser of amazon with quite some orders during the last years, I have always wondered how much money I really spent on amazon during the last years.

As amazon by itself doesn't seem to offer an option to display the total amount money spent, I wrote a simple ruby script, which logs in to the amazon site (amazon.de, amazon.com, amazon.co.uk, amazon.fr) and iterates the pages of the order history to sum up the individual orders. After it reaches the last page it displays the total amount.

Requirements
==============
You need a ruby interpreter and the following rubygems on your system to use this script: "mechanize highline"
```gem install mechanize highline```

Usage
==============
Simply execute `ruby moneywellspent.rb`

If you didn't supply any configuration via commandline options or configfile, the script interactively asks you about the required infos:

```
ruby moneywellspent.rb 
Enter the site to be summed up:  amazon.com
Enter your amazon.com username:  your.email@example.org
Enter your amazon.com password:  ************
Enter the year to be summed up: 2013
Logging in to amazon.de
Retrieving order history..
1337.00
```
