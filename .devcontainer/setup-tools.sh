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
