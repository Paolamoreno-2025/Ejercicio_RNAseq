#!/bin/bash

mkdir -p samples  # crea la carpeta si no existe

while IFS=, read -r run sample_name
do
  if [[ "$run" == "run" ]]; then
    continue
  fi

  json_file="samples/${run}.json"

  if [[ -f "$json_file" ]]; then
    echo "✅ El archivo $json_file ya existe, se omite la descarga."
  else
    echo "⬇️  Descargando JSON para: $run"
    ffq "$run" --json > "$json_file"

    if [[ ! -s "$json_file" ]]; then
      echo "❌ Error: JSON descargado está vacío para $run. Eliminando archivo."
      rm "$json_file"
    elif ! grep -q 'ftp' "$json_file"; then
      echo "⚠️  Advertencia: JSON no contiene enlaces FTP. Puede fallar el pipeline. Eliminando."
      rm "$json_file"
    else
      echo "✅ Descarga válida para $run"
    fi

    sleep 1
  fi
done < samples/samples.csv
