#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
import time
import os
import hashlib

MAX_RETRIES = 5
RETRY_DELAY = 5  # segundos

def md5sum(filename):
    """Calcula el MD5 de un archivo"""
    hash_md5 = hashlib.md5()
    with open(filename, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def download_file(url, output):
    """Descarga el archivo con wget, con reintentos"""
    for attempt in range(1, MAX_RETRIES + 1):
        print(f"Intento {attempt} de descargar {url}")
        try:
            result = subprocess.run(
                ["wget", "-O", output, url],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True
            )
            print(result.stdout)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error en intento {attempt}: {e.stderr}", file=sys.stderr)
            if attempt < MAX_RETRIES:
                print(f"Reintentando en {RETRY_DELAY} segundos...")
                time.sleep(RETRY_DELAY)
            else:
                print("Fallaron todos los intentos de descarga.", file=sys.stderr)
                return False

def main(json_path, output_file=None):
    if not os.path.isfile(json_path):
        print(f"Error: El archivo JSON {json_path} no existe.", file=sys.stderr)
        sys.exit(1)

    with open(json_path) as f:
        data = json.load(f)

    try:
        # Accede a la clave principal (ej: "SRR23091854")
        run_key = list(data.keys())[0]
        run_block = data[run_key]
        run = run_block.get("accession") or run_key

        # Busca el enlace FTP dentro de 'files' -> 'ftp'
        ftp_entries = run_block.get("files", {}).get("ftp", [])
        fastq_url = None
        expected_md5 = None

        for entry in ftp_entries:
            if entry.get("urltype") == "ftp" and entry.get("filetype") == "fastq":
                fastq_url = entry.get("url")
                expected_md5 = entry.get("md5")
                break

        if not fastq_url:
            raise KeyError("ftp_url")

    except KeyError as e:
        print(f"Error: clave {e} no encontrada en JSON.", file=sys.stderr)
        sys.exit(1)

    if not run or not fastq_url:
        print("Error: información insuficiente en JSON para descargar.", file=sys.stderr)
        sys.exit(1)

    # Si no se pasa output_file, usar por defecto {run}.fastq.gz
    if output_file is None:
        output_file = f"{run}.fastq.gz"

    # Crear carpeta padre si no existe
    os.makedirs(os.path.dirname(output_file) or '.', exist_ok=True)

    if os.path.isfile(output_file):
        print(f"Archivo {output_file} ya existe. Verificando MD5...")
        if expected_md5:
            local_md5 = md5sum(output_file)
            if local_md5 == expected_md5:
                print("MD5 coincide, se omite descarga.")
                sys.exit(0)
            else:
                print("MD5 NO coincide, se eliminará el archivo y se descargará de nuevo.")
                os.remove(output_file)
        else:
            print("No hay MD5 esperado. Se omite la descarga asumiendo archivo correcto.")
            sys.exit(0)

    # Descargar archivo
    success = download_file(fastq_url, output_file)
    if not success:
        sys.exit(1)

    # Validar MD5 si está disponible
    if expected_md5:
        print("Validando MD5 del archivo descargado...")
        local_md5 = md5sum(output_file)
        if local_md5 != expected_md5:
            print(f"Error: MD5 no coincide después de descarga. Esperado: {expected_md5}, Obtenido: {local_md5}", file=sys.stderr)
            os.remove(output_file)
            sys.exit(1)
        else:
            print("MD5 válido.")

    print(f"Descarga y validación completadas para {run}.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Descarga fastq desde JSON con validación y reintentos.")
    parser.add_argument("--json", required=True, help="Archivo JSON con información de descarga")
    parser.add_argument("--output", required=False, help="Archivo de salida para guardar el fastq.gz")
    args = parser.parse_args()

    main(args.json, args.output)
