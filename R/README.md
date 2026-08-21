# Data Analysis

This directory contains an R package named `BeerFestDB` which can pull data from the main beerfestdb web API and run some analyses on the dip figures. This is used in the quarto document `dip_figure_analysis.qmd` which can be used to generate a report for the current festival (e.g., after festival closing). The report includes various ways of looking at the dip data that may be useful when planning the budget and beer orders for future festivals:

    quarto render dip_figure_analysis.qmd -P basuri:https://your-beerfestdb-instance -P username:your-username -P password:your-password

Also included is a Dockerfile that can be used to containerise the dependencies required for building these reports.
