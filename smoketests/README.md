# Smoke tests for the festival lifecycle

This directory contains a Nextflow-driven smoke test that exercises the BeerFestDB festival workflow from database bootstrap through the final R report.

The workflow intentionally avoids changing the application code and instead uses the existing container images already published for the project:

- `tfrayner/beerfestdb:latest` for the CLI utilities and the web app
- `tfrayner/beerfestdb-rstudio:latest` for the Quarto/R final report

## What the workflow covers

1. Starts a disposable MySQL + app stack using Docker Compose
2. Loads a minimal festival seed dataset with `load_data.pl`
3. Runs `preload_festival_casks.pl` to create the expected cask set
4. Generates a sample LaTeX output via `dump_to_template.pl`
5. Renders the standard final report from `R/dip_figure_analysis.qmd`

## Files in this directory

- `docker-compose.yml` — disposable smoke-stack definition
- `beerfestdb_smoke.yml` — minimal app config for local container testing
- `main.nf` — Nextflow workflow entry point
- `nextflow.config` — default parameters and container settings
- `data/festival_seed.csv` — minimal test dataset for a festival order

## Running the smoke test

From the repository root:

```bash
# Choose an unused port on your machine here:
nextflow run smoketests/main.nf --app_port 3100
```

The workflow writes a report to:

```bash
smoketests/output/festival_report.html
```

## Why this is designed this way

The real BeerFestDB workflow is a stack of CLI operations layered on top of a live database and a web API. This smoke test mirrors that process without modifying the application code: it brings up the same MySQL and app containers the project already documents, runs the CLI utilities exactly as the project expects, and then renders the final R report in the dedicated RStudio image.

## Optional K8s translation

The same sequence can be converted to a Kubernetes job graph by replacing the Docker Compose stack with a MySQL StatefulSet, an app Deployment, and one-off jobs for each CLI step. The logic remains the same: bootstrap DB -> seed festival order -> preload casks -> generate outputs -> render report.
