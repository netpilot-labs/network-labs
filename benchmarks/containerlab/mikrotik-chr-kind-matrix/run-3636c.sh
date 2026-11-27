# run-3636c.sh <label> <part> [tag] [brnf] [runs]: the ccf5be6a rerun of #3636, split over hosts (binary at ~/clab, LABEL names it)
#   a: LACP 7.24.5 + port-speeds + re-plug · b: LACP 7.26beta7 + kind matrix A and D
#   n: LACP on both versions with br_netfilter loaded (BRNF=1)
#   v <tag> <0|1> <runs>: v6tx.sh on one RouterOS version, br_netfilter loaded first when 1 (one host per combination,
#     since the module stays loaded once loaded)
bash ~/m/prep.sh; export LABEL=${1:-pr}
case ${2:-a} in
  a) CHR_TAG=7.24.5 bash ~/m/lacp.sh 3 1; bash ~/m/speeds.sh 3; bash ~/m/replug.sh 1 3; bash ~/m/replug2.sh 2 3;;
  b) CHR_TAG=7.26beta7 bash ~/m/lacp.sh 3 1; bash ~/m/ad.sh;;
  n) for t in 7.24.5 7.26beta7; do BRNF=1 CHR_TAG=$t bash ~/m/lacp.sh 3 1; done;;
  v) BRNF=${4:-0} CHR_TAG=${3:-7.24.5} bash ~/m/v6tx.sh ${5:-12};;
esac
echo ALLDONE
