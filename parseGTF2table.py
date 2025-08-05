from collections import defaultdict
from Bio import SeqIO
import csv
import re

def parse_attributes(attr_string):
    attributes = {}
    for attr in attr_string.strip().split(';'):
        if attr.strip() == "": continue
        key_value = attr.strip().split(' ', 1)
        if len(key_value) == 2:
            key, value = key_value
            attributes[key] = value.strip('"')
    return attributes

def build_gene_dict(gtf_file):
    gene_dict = defaultdict(dict)

    with open(gtf_file, 'r') as infile:
        for line in infile:
            if line.startswith('#'):
                continue
            parts = line.strip().split('\t')
            if len(parts) < 9:
                continue

            chrom, _, feature, start, end, _, strand, _, attr_str = parts
            attrs = parse_attributes(attr_str)
            gene_id = attrs.get('gene_id')
            transcript_id = attrs.get('transcript_id')
            protein_id = attrs.get('protein_id', '')
            if not gene_id or not transcript_id:
                continue

            if transcript_id not in gene_dict[gene_id]:
                gene_dict[gene_id][transcript_id] = {
                    'protein_id': protein_id,
                    'chrom': chrom,
                    'start': int(start),
                    'end': int(end),
                    'strand': strand,
                    'fasta_id': ''
                }
            else:
                gene_dict[gene_id][transcript_id]['start'] = min(gene_dict[gene_id][transcript_id]['start'], int(start))
                gene_dict[gene_id][transcript_id]['end'] = max(gene_dict[gene_id][transcript_id]['end'], int(end))
                if not gene_dict[gene_id][transcript_id]['protein_id'] and protein_id:
                    gene_dict[gene_id][transcript_id]['protein_id'] = protein_id
    return gene_dict

def match_fasta_ids(fasta_file, gene_dict):
    transcript_to_gene = {
        tid: gene_id
        for gene_id, transcripts in gene_dict.items()
        for tid in transcripts
    }

    for record in SeqIO.parse(fasta_file, 'fasta'):
        fasta_id = record.id
        desc = record.description

        matches = re.findall(r'\b([A-Z]{2}_[0-9]+\.[0-9]+)\b', desc)
        matched = False
        for tid in matches:
            if tid in transcript_to_gene:
                gene_id = transcript_to_gene[tid]
                gene_dict[gene_id][tid]['fasta_id'] = fasta_id
                matched = True
                break
        if matched:
            continue

    if '_trna_' in fasta_id.lower() and '[gene=' in desc and '[location=' in desc:
        try:
            gene_tag_match = re.search(r'\[gene=([^\]]+)\]', desc)
            location_match = re.search(r'\[location=([^\]]+)\]', desc)
            if not gene_tag_match or not location_match:
                raise ValueError("Missing or malformed [gene=] or [location=]")
    
            gene_tag = gene_tag_match.group(1)
            location_str = location_match.group(1)
    
            # Detect strand from complement
            loc_strand = '-'
            if location_str.startswith('complement('):
                loc_strand = '-'
                # Strip complement(...) wrapping
                location_str = location_str[len('complement('):-1]
            else:
                loc_strand = '+'
    
            # Strip join(...) wrapping if present
            if location_str.startswith('join('):
                location_str = location_str[len('join('):-1]
    
            # Extract all intervals, e.g. ['5394565..5394600', '5394613..5394650']
            intervals = re.findall(r'(\d+)\.\.(\d+)', location_str)
            if not intervals:
                raise ValueError("No coordinate intervals found in location")
    
            # Convert intervals to integers and find min start and max end
            starts = [int(start) for start, end in intervals]
            ends = [int(end) for start, end in intervals]
            loc_start = min(starts)
            loc_end = max(ends)
    
            chrom = fasta_id.split('_trna_')[0]
    
            matched = False
            for gene_id, transcripts in gene_dict.items():
                if gene_id.startswith(gene_tag):
                    for tid, data in transcripts.items():
                        if (
                            data['chrom'] == chrom and
                            data['strand'] == loc_strand and
                            not (loc_end < data['start'] or loc_start > data['end'])
                        ):
                            gene_dict[gene_id][tid]['fasta_id'] = fasta_id
                            matched = True
                            break
                if matched:
                    break
    
        except Exception as e:
            print(f"Error in tRNA matching: {e}\nFASTA header: {fasta_id} {desc}")


def write_dict_to_tsv(gene_dict, output_file):
    with open(output_file, 'w', newline='') as out:
        writer = csv.writer(out, delimiter='\t')
        writer.writerow(['gene_id', 'transcript_id', 'protein_id', 'fasta_id'])
        for gene_id, transcripts in gene_dict.items():
            for transcript_id, info in transcripts.items():
                writer.writerow([
                    gene_id,
                    transcript_id,
                    info['protein_id'],
                    info['fasta_id']
                ])

# Usage

gtf_file = 'GCF_000208745.1_Criollo_cocoa_genome_V2_genomic.gtf'
output_file = 'GCF_000208745.1_Criollo_cocoa_genome_V2_genomic.tx2gene'
fasta_file = '/Storage/data1/jenny.paola/Ejercicio_RNAseq/references/GCF_000208745.1_Criollo_cocoa_genome_V2_rna_from_genomic.fix.fna'
gene_dict = build_gene_dict(gtf_file)
match_fasta_ids(fasta_file, gene_dict)
write_dict_to_tsv(gene_dict, output_file)
