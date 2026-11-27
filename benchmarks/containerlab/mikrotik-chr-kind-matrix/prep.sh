# prep.sh: bench host setup for #3636 (bonding module, images, the Linux bond peer image)
sudo modprobe bonding && echo "bonding module loaded"
uname -r; sudo docker version --format 'docker {{.Server.Version}}'; which sshpass nc curl
for t in 7.24.5 7.26beta7; do sudo docker pull -q mikrotik/chr:$t; done
sudo docker pull -q alpine:3.20
mkdir -p ~/bp && printf 'FROM alpine:3.20\nRUN apk add --no-cache iproute2 ethtool\n' > ~/bp/Dockerfile && sudo docker build -q -t bondpeer:1 ~/bp
sudo docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep -E 'chr|alpine|bondpeer'
echo PREP_DONE
