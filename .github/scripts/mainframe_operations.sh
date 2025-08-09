#!/usr/bin/env bash
# mainframe_operations.sh
set -euo pipefail

# Java ya lo instala el workflow; esto es opcional
java -version || true

: "${ZOWE_USERNAME:?ZOWE_USERNAME no definido}"    # viene del workflow
HLQ="$(echo "$ZOWE_USERNAME" | tr '[:lower:]' '[:upper:]')"   # para datasets

# Ir a la carpeta correcta (ajusta si tu repo usa otro nombre)
cd cobol-check
echo "Changed to $(pwd)"
ls -al || true

# Asegurar ejecutables locales (por si acaso)
chmod +x cobolcheck || true
chmod +x scripts/linux_gnucobol_run_tests || true

run_cobolcheck() {
  program="$1"
  echo "=== Running cobolcheck for $program ==="
  # Ejecuta cobolcheck aunque falle (no abortamos el script)
  set +e
  ./cobolcheck -p "$program"
  ec=$?
  set -e
  echo "Cobolcheck exit code for $program: $ec"

  # Subir CC##99.CBL si existe
  if [ -f "CC##99.CBL" ]; then
    echo "Uploading CC##99.CBL to $HLQ.CBL($program)"
    zowe zos-files upload file-to-data-set "CC##99.CBL" "$HLQ.CBL($program)"
  else
    echo "CC##99.CBL not found for $program"
  fi

  # Subir el JCL si existe en esta carpeta
  if [ -f "${program}.JCL" ]; then
    echo "Uploading ${program}.JCL to $HLQ.JCL($program)"
    zowe zos-files upload file-to-data-set "${program}.JCL" "$HLQ.JCL($program)"
  else
    echo "${program}.JCL not found (skipping upload)"
  fi

  # Submit del job (si el miembro existe en el PDS)
  echo "Submitting $HLQ.JCL($program)..."
  JOBID=$(zowe jobs submit data-set "$HLQ.JCL($program)" --rff jobid --rft string --wait-for-output true)
  echo "Submitted: $JOBID"
  zowe jobs view job-status-by-jobid "$JOBID"
}

for program in NUMBERS EMPPAY DEPTPAY; do
  run_cobolcheck "$program"
done

echo "Mainframe operations completed"
