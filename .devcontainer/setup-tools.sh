#!/bin/bash
mkdir setup-tools
cd setup-tools

set -euo pipefail

echo "📦 Installing Taskfile.dev CLI (task)..."

# Install Task
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

echo "✅ Taskfile.dev installed successfully!"

echo "📦 Installing mkcert..."

# Install mkcert dependencies
apt-get update && apt-get install -y libnss3-tools curl

# Download mkcert binary
MKCERT_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/mkcert/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -L -o /usr/local/bin/mkcert "https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v${MKCERT_VERSION}-linux-amd64"
chmod +x /usr/local/bin/mkcert

# Setup local CA (Optional: run this manually if interactive setup is needed)
mkcert -install

echo "✅ mkcert installed successfully!"

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