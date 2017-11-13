MoneyWellSpent - How much did you spend on Amazon?
==============
A script to summarize your money spent on amazon.{de,com,co.uk,fr}

As someone who considers himself as some kind of Amazon poweruser with quite a few orders during the last years, I have always wondered how much money I actually spent there.

As Amazon officially doesn't seem to offer an option to display the total amount spent, I wrote a simple ruby script, which logs into the Amazon site (amazon.de, amazon.com, amazon.co.uk, amazon.fr) and iterates the pages of your order history to sum up the individual orders. After it reaches the last page it displays the total amount.

Requirements
==============
- Ruby
- Ruby gems
  - [Mechanize](https://github.com/sparklemotion/mechanize)
  - [HighLine](https://github.com/JEG2/highline)

To install the gems:
```gem install mechanize highline```

Usage
==============
Simply execute `ruby moneywellspent.rb`

If you didn't supply any configuration via commandline options or configfile (`~/.moneywellspentrc`), the script interactively asks you about the required information:

```
$ ruby moneywellspent.rb
Enter the site to be summed up:  amazon.com
Enter your amazon.com username:  your.email@example.org
Enter your amazon.com password:  ************
Enter the year to be summed up: 2013
Logging in to amazon.de
Retrieving order history..
1334.00
```
