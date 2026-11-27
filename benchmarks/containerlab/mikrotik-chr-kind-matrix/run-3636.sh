# run-3636.sh <label>: the #3636 bench on one host (binary at ~/clab, LABEL names it): LACP on 7.24.5 and 7.26beta7 with
# the lifecycle, port-speeds and invalid inputs, the re-plug cases, then the kind matrix A and D, then ALLDONE
bash ~/m/prep.sh; export LABEL=${1:-pr}
for t in 7.24.5 7.26beta7; do CHR_TAG=$t bash ~/m/lacp.sh 3 1; done
bash ~/m/speeds.sh 3; bash ~/m/replug.sh 1 3; bash ~/m/replug2.sh 2 3; bash ~/m/ad.sh; echo ALLDONE
