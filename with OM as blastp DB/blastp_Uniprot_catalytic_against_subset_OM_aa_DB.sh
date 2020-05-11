#!/bin/bash

# INSTRUCTION FOR BLASTP

#Requires: database
#using dbfile.fa with reference protein sequences
#makeblastdb -in dbfile.fa -dbtype prot -out database_file

if test -f 'blastp_result_Uniprot_vs_OMsubset';
then
    rm blastp_result_Uniprot_vs_OMsubset
    echo 'Previous blastp_result_Uniprot_vs_OMsubset removed'
fi

echo 'Protein blast UniProt entries with catalytic activity in prokaryotes against DB (subset of OM as amino acid sequences)'

blastp -db blastp_db_from_OMsubset -query UniProtKB_catalytic.faa -out blastp_result_Uniprot_vs_OMsubset -outfmt "6 qseqid stitle sstart send evalue sseq" -culling_limit 1 -evalue 0.05 -max_hsps 1


#group aligned sequences by UniProt entry (qseqid) and count how many <40% identity clusters

if test -f 'aligned_catalytic_uniprots.tsv';
then
    rm aligned_catalytic_uniprots.tsv
    echo 'removed previous aligned_catalytic_uniprots.tsv'
fi

while read aligned; do
    cut -f1 >> aligned_catalytic_uniprots.tsv;
done < blastp_result_Uniprot_vs_OMsubset

uniq aligned_catalytic_uniprots.tsv > unique_aligned_catalytic_uniprots.tsv


if [ -d "Aligned_seqs_by_UniProt_entry" ];
then
    rm -r Aligned_seqs_by_UniProt_entry
    echo "Directory Aligned_seqs_by_UniProt_entry was removed"
fi

mkdir Aligned_seqs_by_UniProt_entry

IFS=$'\n'

for ref_seq in $(cat unique_aligned_catalytic_uniprots.tsv); do
    filename=$(echo "${ref_seq}_output.faa")
    groups=$(grep "${ref_seq}" blastp_result_Uniprot_vs_OMsubset)
    #echo "This is a group: ${groups}" 
    for i in ${groups}; do
        info=$(echo ">$i" | awk '{$(NF--)=""; print}')
        sequence=$(echo "$i" | awk '{print $NF}' )
        echo "${info}" >> ./Aligned_seqs_by_UniProt_entry/$filename
        echo "${sequence}" | sed 's/-//g' >> ./Aligned_seqs_by_UniProt_entry/$filename;
    done
done

if test -f 'Matches_per_uniprot.tsv'; 
then
    rm Matches_per_uniprot.tsv
    echo "Previous Matches_per_uniprot.tsv removed"
fi

for file in ./Aligned_seqs_by_UniProt_entry/*.faa; do
    matches=$(blastp -query "${file}" -subject "${file}" -outfmt "6 ppos")
    echo "${file}" >> Matches_per_uniprot.tsv
    echo "${matches}" >> Matches_per_uniprot.tsv;
done



