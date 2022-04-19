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

Type | Code --- | --- Buy | b Sale | sa Split | sp Merger | m Dividend | d Capital gain | c 

Note transaction codes may be entered in lower- or upper-case.

In addition to the transaction type, each transaction for a security on the same date has a temporal number to distinguish its order of execution regardless of type.

The following table shows a hypothetical, abbreviated set of transactions for security XXX (number of shares, prices, and other transacion datate are not shown).

Security | Date | Trans | Trans | | Code | Order --- | --- | --- | --- XXX | 2022-01-01 | b | 1 XXX | 2022-01-01 | d | 2 XXX | 2022-01-01 | sp | 3 XXX | 2022-01-01 | c | 4 XXX | 2022-01-01 | b | 5

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

