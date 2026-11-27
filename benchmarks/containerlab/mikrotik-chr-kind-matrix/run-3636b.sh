# run-3636b.sh <label> <part>: run-3636.sh split over hosts for the 5646b9a4 rerun (binary at ~/clab, LABEL names it)
#   a: LACP 7.24.5 + port-speeds + re-plug · b: LACP 7.26beta7 + kind matrix A and D · c: LACP on both versions only
#   n: LACP on both versions with br_netfilter loaded (BRNF=1)
#   v: v6tx.sh, which data devices send IPv6 of their own, 5 runs per version
bash ~/m/prep.sh; export LABEL=${1:-pr}
case ${2:-a} in
  a) CHR_TAG=7.24.5 bash ~/m/lacp.sh 3 1; bash ~/m/speeds.sh 3; bash ~/m/replug.sh 1 3; bash ~/m/replug2.sh 2 3;;
  b) CHR_TAG=7.26beta7 bash ~/m/lacp.sh 3 1; bash ~/m/ad.sh;;
  c) for t in 7.24.5 7.26beta7; do CHR_TAG=$t bash ~/m/lacp.sh 3 1; done;;
  n) for t in 7.24.5 7.26beta7; do BRNF=1 CHR_TAG=$t bash ~/m/lacp.sh 3 1; done;;
  v) for t in 7.24.5 7.26beta7; do CHR_TAG=$t bash ~/m/v6tx.sh 5; done;;
esac
echo ALLDONE
