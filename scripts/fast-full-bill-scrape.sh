#!/bin/sh
set -e

exec 2>&1

pupa update --datadir=/cache/bills/_data/ /scrapers-us-municipal/lametro --scrape bills window=0 --rpm=0
SHARED_DB=True pupa update --datadir=/cache/bills/_data/ /scrapers-us-municipal/lametro
pupa update --datadir=/cache/bills/_data/ /scrapers-us-municipal/lametro