[![Actions Status](https://github.com/tbrowder/RakuFinance/actions/workflows/test.yml/badge.svg)](https://github.com/tbrowder/RakuFinance/actions)

NAME
====

**THIS IS A WORK-IN-PROGRESS: NOT YET RELEASED**

**RakuFinance** - Show basis, gain/loss, current value, and other data for a portfolio of investments

SYNOPSIS
========

```raku
use RakuFinance;
```

DESCRIPTION
===========

**RakuFinance** is a module one can use to calculate various data for a portfolio of investments including basis, gain/loss, current value, and time-series statistics.

The user has to provide the accepted symbols for his or her securities as well as their buy/sell data in a comma-separated-value (CSV) file with the appropriate header line (see **Input Files**) along with pertinent historical data available from public data sources (see **Data Sources**).

Note the module is currently designed for the US but should be able to be modified to handle currency and securities for any country with the help of an interested collaborator. Contact the author if you are volunteering.

Tranactions
-----------

Transactions recognized by this module currently are:

<table class="pod-table">
<thead><tr>
<th>Type</th> <th>Code</th>
</tr></thead>
<tbody>
<tr> <td>Buy</td> <td>b</td> </tr> <tr> <td>Sale</td> <td>sa</td> </tr> <tr> <td>Split</td> <td>sp</td> </tr> <tr> <td>Merger</td> <td>m</td> </tr> <tr> <td>Dividend</td> <td>d</td> </tr> <tr> <td>Capital gain</td> <td>c</td> </tr>
</tbody>
</table>

Note transaction codes may be entered in lower- or upper-case.

In addition to the transaction type, each transaction for a security on the same date has a temporal number to distinguish its order of execution regardless of type.

The following table shows a hypothetical, abbreviated set of transactions for security XXX (number of shares, prices, and other transaction data are not shown).

<table class="pod-table">
<thead><tr>
<th>Security</th> <th>Date</th> <th>Trans Code</th> <th>Trans Order</th>
</tr></thead>
<tbody>
<tr> <td>XXX</td> <td>2022-01-01</td> <td>b</td> <td>1</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>d</td> <td>2</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>sp</td> <td>3</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>c</td> <td>4</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>b</td> <td>5</td> </tr>
</tbody>
</table>

Environment Variables
---------------------

The working directory chosen by the user should be a dedicated directory with several subdirectories to hold public data of various types. The user's personal data of buys, holdings, and sales should be segregated into another directory outside of the working directory. The absolute path of that directory should be defined in one of the environment variables **RAKU_FINANCE_USER_DATA_DIRECTORY** [the default] or **RAKU_FINANCE_USER_DATA_FOLDER**.

Input Files
-----------

Input files can be read from the following financial financial firms:

  * TD Ameritrade

  * Fidelity

Data Sources
------------

Environment Variables
---------------------

User Program
------------

An executable Raku program, **finance**, is installed as part of this module. It provides modes for calculating the following statistics for a portfolio:

  * 1 - create a CSV file showing all transactions by date, symbol, transaction order (for a single security or all);

  * 3 - create a CSV file showing basis for 

  * 4 - create a CSV file showing current value, gain/loss, basis, and return on investment (for a single security or all)

Planned Features
----------------

  * Live updates via one of several possible free or paid sources

  * Interface with an SQLite database file in GnuCash format (see [https://gnucash.org](https://gnucash.org))

  * Accept inputs via a JSON file

  * Output files in JSON format

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

