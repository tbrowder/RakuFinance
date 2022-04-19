[![Actions Status](https://github.com/tbrowder/RakuFinance/actions/workflows/test.yml/badge.svg)](https://github.com/tbrowder/RakuFinance/actions)

NAME
====

**RakuFinance** - Show basis, gain/loss, current value, and other data for a portfolio of investments

SYNOPSIS
========

```raku
use RakuFinance;
```

DESCRIPTION
===========

RakuFinance is a module one can use to calculate various data for a portfolio of investments including basis, gain/loss, current value, and time-series statistics.

The user has to provide the accepted symbols for his or her securities as well as their buy/sell data in a comma-separated-value file with the appropriate header line (see **Input Files**) and historical data available from public data sources.

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

The following table shows a hypothetical, abbreviated set of transactions for security XXX (number of shares, prices, and other transacion datate are not shown).

<table class="pod-table">
<thead><tr>
<th>Security</th> <th>Date</th> <th>Trans Code</th> <th>Trans Order</th>
</tr></thead>
<tbody>
<tr> <td>XXX</td> <td>2022-01-01</td> <td>b</td> <td>1</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>d</td> <td>2</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>sp</td> <td>3</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>c</td> <td>4</td> </tr> <tr> <td>XXX</td> <td>2022-01-01</td> <td>b</td> <td>5</td> </tr>
</tbody>
</table>

Environment variables
---------------------

The working directory chosen by the user should be a dedicated directory with several subdirectories to hold public data of various types. The user's personal data of buys, holdings, and sales should be segregated into another directory outside of the working directory. The absolute path of that directory should be defined in environment variable **RAKUFINANCE_USER_DATA**.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

