# ad.sh: the existing kind matrix A (plain links, transparent mgmt, startup config) and D (restarts) on this build
. ~/m/lib.sh; cd ~/m; for s in A D; do echo "######## $s"; bash $s.sh 2>&1 | sed "s/^/[${LABEL:-pr}] /"; done; $CLAB destroy -t ~/m/A/a-7.24.5.clab.yml --cleanup >/dev/null 2>&1
