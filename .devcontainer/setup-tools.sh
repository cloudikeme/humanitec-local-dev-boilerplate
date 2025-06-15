#!/bin/bash
mkdir setup-tools
cd setup-tools

set -euo pipefail

echo "🔧 Installing mkcert..."
sudo apt-get update
sudo apt-get install -y mkcert libnss3-tools

echo "📦 Installing Taskfile.dev..."
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

echo "🔧 Installing yq..."
YQ_VERSION=$(curl -sL https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)
curl -Lo yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64
chmod +x yq
sudo mv yq /usr/local/bin/yq

echo "🔧 Installing direnv..."
DIRENV_VERSION=$(curl -s https://api.github.com/repos/direnv/direnv/releases/latest | jq -r .tag_name)
curl -Lo direnv https://github.com/direnv/direnv/releases/download/${DIRENV_VERSION}/direnv.linux-amd64
chmod +x direnv
sudo mv direnv /usr/local/bin/direnv

echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc

echo "✅ mkcert, task, yq and direnv installed!"

# Detect architecture
ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && ARCH="amd64"
[ "$ARCH" == "aarch64" ] && ARCH="arm64"

# Install Terraform
VERSION="1.5.7"
wget "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_${ARCH}.zip"
unzip terraform_${VERSION}_linux_${ARCH}.zip
mv terraform /usr/local/bin/
rm terraform_${VERSION}_linux_${ARCH}.zip

# Install glow
mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" > /etc/apt/sources.list.d/charm.list
apt update
apt install glow -y

# Install kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Setup kubectl autocomplete
mkdir -p $HOME/.kube
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "complete -F __start_kubectl k" >> $HOME/.bashrc

# Create Docker network 'kind'
docker network create -d=bridge -o com.docker.network.bridge.enable_ip_masquerade=true \
  -o com.docker.network.driver.mtu=1500 \
  --subnet fc00:f853:ccd:e793::/64 kind

# Install helm
mkdir /tmp/helm
curl -fsSL https://get.helm.sh/helm-v3.14.4-linux-amd64.tar.gz > /tmp/helm/helm.tar.gz
tar -zxvf /tmp/helm/helm.tar.gz -C /tmp/helm
install -o root -g root -m 0755 /tmp/helm/linux-amd64/helm /usr/local/bin/helm
helm completion bash > /etc/bash_completion.d/helm
rm -rf /tmp/helm

SCORE_COMPOSE_VERSION=$(curl -sL https://api.github.com/repos/score-spec/score-compose/releases/latest | jq -r .tag_name)
wget https://github.com/score-spec/score-compose/releases/download/${SCORE_COMPOSE_VERSION}/score-compose_${SCORE_COMPOSE_VERSION}_linux_amd64.tar.gz
tar -xvf score-compose_${SCORE_COMPOSE_VERSION}_linux_amd64.tar.gz
chmod +x score-compose
sudo mv score-compose /usr/local/bin

SCORE_K8S_VERSION=$(curl -sL https://api.github.com/repos/score-spec/score-k8s/releases/latest | jq -r .tag_name)
wget https://github.com/score-spec/score-k8s/releases/download/${SCORE_K8S_VERSION}/score-k8s_${SCORE_K8S_VERSION}_linux_amd64.tar.gz
tar -xvf score-k8s_${SCORE_K8S_VERSION}_linux_amd64.tar.gz
chmod +x score-k8s
sudo mv score-k8s /usr/local/bin

HUMCTL_VERSION=$(curl -sL https://api.github.com/repos/humanitec/cli/releases/latest | jq -r .tag_name)
curl -fLO https://github.com/humanitec/cli/releases/download/${HUMCTL_VERSION}/cli_${HUMCTL_VERSION:1}_linux_amd64.tar.gz
tar -xvf cli_${HUMCTL_VERSION:1}_linux_amd64.tar.gz
chmod +x humctl
sudo mv humctl /usr/local/bin/humctl

KIND_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

cd ..
rm -rf setup-tools
