nextflow.enable.dsl = 2

params.outdir = "${projectDir}/output"
params.festival_name = 'Smoke Festival'
params.festival_year = '2026'
params.baseuri = 'http://app:3000'
params.username = 'admin'
params.password = 'admin'
params.app_port = 3000

process startStack {
  executor 'local'

  output:
  val true

  script:
  """
  docker compose -f ${projectDir}/docker-compose.yml down -v >/dev/null 2>&1 || true
  docker volume rm -f smoketests_beerfestdb_smoke_mysql >/dev/null 2>&1 || true
  BFDB_SMOKE_APP_PORT=${params.app_port} docker compose -f ${projectDir}/docker-compose.yml down -v >/dev/null 2>&1 || true
  BFDB_SMOKE_APP_PORT=${params.app_port} docker compose -f ${projectDir}/docker-compose.yml up -d --wait mysql redis app
  BFDB_SMOKE_APP_PORT=${params.app_port} docker compose -f ${projectDir}/docker-compose.yml up -d --wait rstudio
  """
}

process loadFestival {
  executor 'local'

  input:
  val started

  output:
  val true

  script:
  """
  docker compose -f ${projectDir}/docker-compose.yml run --rm app \
    bash -lc "load_data.pl -i /workspace/smoketests/data/festival_seed.csv"
  docker exec smoketests-mysql-1 mysql -u beerfestdb -p"vent&T4p" -D beerfestdb \
    -e "UPDATE system_defaults SET festival_id = (SELECT festival_id FROM festival WHERE name = 'Smoke Festival') WHERE id = 1;"
  """
}

process preloadCasks {
  executor 'local'

  input:
  val loaded

  output:
  val true

  script:
  """
  docker compose -f ${projectDir}/docker-compose.yml run --rm app \
    bash -lc "preload_festival_casks.pl"
  """
}

process markCasksReceived {
  executor 'local'

  input:
  val preloaded

  output:
  val true

  script:
  """
  printf 'y\\n' | docker compose -f ${projectDir}/docker-compose.yml run --rm -T app \
    bash -lc "load_data.pl -i /workspace/smoketests/data/festival_seed_received.csv"
  """
}

process setSalePrice {
  executor 'local'

  input:
  val received

  output:
  val true

  script:
  """
  docker compose -f ${projectDir}/docker-compose.yml run --rm app \
    bash -lc "load_data.pl -i /workspace/smoketests/data/festival_sale_price.csv"
  """
}

process assignStillage {
  executor 'local'

  input:
  val received

  output:
  val true

  script:
  """
  docker exec smoketests-mysql-1 mysql -u beerfestdb -p"vent&T4p" -D beerfestdb \
    -e "INSERT INTO stillage_location (festival_id, description) \
        SELECT festival_id, 'DMZ' FROM system_defaults WHERE id = 1 \
        UNION ALL \
        SELECT festival_id, 'Marquee' FROM system_defaults WHERE id = 1 \
        ON DUPLICATE KEY UPDATE description = VALUES(description);"
  docker compose -f ${projectDir}/docker-compose.yml run --rm app \
    bash -lc "update_cask_details.pl -a -i /workspace/smoketests/data/cask_stillage.tsv"
  """
}

process generateLabels {
  executor 'local'

  input:
  val marked

  output:
  val true

  script:
  """
  mkdir -p ${params.outdir}
  docker compose -f ${projectDir}/docker-compose.yml run --rm app \
    bash -lc "cd /workspace && dump_to_template.pl -t util/templates/cask_labels_no_barcode.tt2 -o cask_management > /output/cask_labels.tex"
  """
}

process loadDips {
  executor 'local'

  input:
  val labelsGenerated

  output:
  val true

  script:
  """
  for day in 1 2 3 4 5 6; do
    docker exec smoketests-mysql-1 mysql -u beerfestdb -p"vent&T4p" -D beerfestdb \
      -e "INSERT INTO measurement_batch (festival_id, measurement_time, description) \
          SELECT festival_id, DATE_ADD('2026-08-17 12:00:00', INTERVAL (\$day - 1) DAY), CONCAT('Smoke report dip batch ', \$day) \
          FROM system_defaults WHERE id = 1 \
          ON DUPLICATE KEY UPDATE description = VALUES(description);"
    docker compose -f ${projectDir}/docker-compose.yml run --rm app \
      bash -lc "printf '%s\\n' \$day | load_dips.pl -i /workspace/smoketests/data/dips_\$day.tsv"
  done
  """
}

process reportFinal {
  executor 'local'

  input:
  val dipsLoaded

  script:
  """
  mkdir -p ${params.outdir}
  docker compose -f ${projectDir}/docker-compose.yml exec -T rstudio bash -lc \
    "cp /workspace/R/dip_figure_analysis.qmd /tmp/dip_figure_analysis.qmd && cd /tmp && quarto render dip_figure_analysis.qmd --output-dir /output -P baseuri:${params.baseuri} -P username:${params.username} -P password:${params.password} -P ssl_verify:false"
  cp -f ${params.outdir}/dip_figure_analysis.html ${params.outdir}/festival_report.html 2>/dev/null || true
  ls -l ${params.outdir}
  """
}

workflow {
  stackReady = startStack()
  datasetLoaded = loadFestival(stackReady)
  casksPreloaded = preloadCasks(datasetLoaded)
  casksReceived = markCasksReceived(casksPreloaded)
  salePriceSet = setSalePrice(casksReceived)
  stillageAssigned = assignStillage(salePriceSet)
  labelsGenerated = generateLabels(stillageAssigned)
  dipsLoaded = loadDips(labelsGenerated)
  reportFinal(dipsLoaded)
}
