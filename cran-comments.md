This is a patch release to fix a problem in the multicore support, which was introduced in the last release (0.5.0), 5 days ago.

## Test environments
* local Debian GNU/Linux install, R 4.2.1
* win-builder (devel, release)
* github actions macOS-latest (release), window-latest (release), ubuntu-latest (devel, release), ubuntu-latest (oldrel-1)

## R CMD check results
There were no ERRORs or WARNINGs.

There was one NOTE on win-release and win-devel: "Days since last update: 5"

I am aware that packages should be updated only every couple of months. Unfortunately, a problem was introduced in the last release regarding multicore support. Version 0.5.1 fixes this problem.

## Downstream dependencies
There are no downstream dependencies