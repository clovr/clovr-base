#!/bin/sh

echo
echo
echo "query to NAST format"
echo "../NAST-iEr template_seqs.NAST query_seq.fasta > tmp.query.NAST\n\n"
../NAST-iEr template_seqs.NAST query_seq.fasta > tmp.query.NAST 2>/dev/null

echo "query and template (profile) to query NAST and template consensus NAST"
echo "../NAST-iEr -b template_seqs.NAST query_seq.fasta > tmp.both.NAST\n\n"
../NAST-iEr -b template_seqs.NAST query_seq.fasta > tmp.both.NAST 2>/dev/null

echo "converting NAST mfasta to multi-alignment output highlighting differences"
echo "../show_malign_no_gap.pl --IGNOREGAPS tmp.both.NAST > tmp.both.NAST.malign\n\n"
../util/show_malign_no_gap.pl --IGNOREGAPS tmp.both.NAST > tmp.both.NAST.malign


echo "Run via the megablast wrapper"
../run_NAST-iEr.pl --query_FASTA query_seq.fasta > tmp.mb_select.NAST

