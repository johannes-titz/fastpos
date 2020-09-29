This is a resubmission. In the previous submission there was a problem with an
invalid URL when built on CRAN:

  Found the following (possibly) invalid URLs:
    URL: http://r-pkgs.had.co.nz/r.html#style (moved to https://r-pkgs.org/r.html)
      From: inst/doc/fastpos.html
            README.md
      Status: 200
      Message: OK

I removed the URL since I already link to r-pkgs.org before and this should be 
sufficient information for potential contributors.

## Test environments
* local Arch GNU/Linux install, R 4.0.2
* ubuntu 16.04 (on travis-ci), R 4.0.2
* win-builder (devel, release)

## R CMD check results
There were no ERRORs or WARNINGs

There was one NOTE on Linux-systems, which seems to be caused by R itself (https://stackoverflow.com/questions/63613301/r-cmd-check-note-unable-to-verify-current-time)

* checking for future file timestamps ... NOTE
unable to verify current time

## Downstream dependencies
There are no downstream dependencies