#!/usr/bin/env bash
set -euo pipefail

# Usa zowe si está instalado; si no, npx (sin instalar globalmente)
if command -v zowe >/dev/null 2>&1; then
  ZOWE="zowe"
else
  ZOWE="npx -y @zowe/cli zowe"
fi

LOWERCASE_USERNAME=$(echo "${ZOWE_USERNAME:?}" | tr '[:upper:]' '[:lower:]')
USS_DIR="/z/$LOWERCASE_USERNAME/cobolcheck"   # cambia a /u/... si tu USS usa /u

# Crear directorio si no existe
if ! $ZOWE zos-files list uss-files "$USS_DIR" &>/dev/null; then
  echo "Directory does not exist. Creating it..."
  $ZOWE zos-files create uss-directory "$USS_DIR"
else
  echo "Directory already exists."
fi

# Subir archivos (misma orden; patrón del JAR relativo a ./cobol-check)
$ZOWE zos-files upload dir-to-uss "./cobol-check" "$USS_DIR" \
  --recursive --binary-files "bin/*.jar"

# Verificar
echo "Verifying upload:"
$ZOWE zos-files list uss-files "$USS_DIR"
