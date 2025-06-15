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

# Install required packages
echo "Installing packages..."
sudo apt-get update
sudo apt-get install -y bash curl git jq bash-completion

# Create bash completion directory
sudo mkdir -p /etc/bash_completion.d

# Detect target architecture
TARGETARCH=$(dpkg --print-architecture)
if [ "$TARGETARCH" = "amd64" ]; then
    TARGETARCH="amd64"
elif [ "$TARGETARCH" = "arm64" ]; then
    TARGETARCH="arm64"
else
    echo "Unsupported architecture: $TARGETARCH"
    exit 1
fi

echo "Detected architecture: $TARGETARCH"

# Install kubectl
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" > /tmp/kubectl
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
rm /tmp/kubectl

# Install helm
echo "Installing helm..."
mkdir /tmp/helm
curl -fsSL https://get.helm.sh/helm-v3.14.4-linux-${TARGETARCH}.tar.gz > /tmp/helm/helm.tar.gz
tar -zxf /tmp/helm/helm.tar.gz -C /tmp/helm
sudo install -o root -g root -m 0755 /tmp/helm/linux-${TARGETARCH}/helm /usr/local/bin/helm
helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
rm -rf /tmp/helm

# Install kind
echo "Installing kind..."
curl -fsSL https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-${TARGETARCH} > /tmp/kind
sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
rm /tmp/kind

# Install terraform
echo "Installing terraform..."
mkdir /tmp/terraform
curl -fsSL https://releases.hashicorp.com/terraform/1.8.1/terraform_1.8.1_linux_${TARGETARCH}.zip > /tmp/terraform/terraform.zip
unzip /tmp/terraform/terraform.zip -d /tmp/terraform
sudo install -o root -g root -m 0755 /tmp/terraform/terraform /usr/local/bin/terraform
rm -rf /tmp/terraform

# Install yq
echo "Installing yq..."
curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH} > /tmp/yq
sudo install -o root -g root -m 0755 /tmp/yq /usr/local/bin/yq
yq shell-completion bash | sudo tee /etc/bash_completion.d/yq > /dev/null
rm /tmp/yq

# Install humctl
echo "Installing humctl..."
mkdir /tmp/humctl
curl -fsSL https://github.com/humanitec/cli/releases/download/v0.23.0/cli_0.23.0_linux_${TARGETARCH}.tar.gz > /tmp/humctl/humctl.tar.gz
tar -zxf /tmp/humctl/humctl.tar.gz -C /tmp/humctl
sudo install -o root -g root -m 0755 /tmp/humctl/humctl /usr/local/bin/humctl
humctl completion bash | sudo tee /etc/bash_completion.d/humctl > /dev/null
rm -rf /tmp/humctl

# Set environment variable in user's bashrc
echo "Setting up environment variables..."
echo 'export KUBECONFIG="/state/kube/config-internal.yaml"' >> ~/.bashrc

# Source bash completion in user's bashrc if not already present
if ! grep -q "bash_completion" ~/.bashrc; then
    echo "# Enable bash completion" >> ~/.bashrc
    echo "if [ -f /etc/bash_completion ]; then" >> ~/.bashrc
    echo "    . /etc/bash_completion" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
fi

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


echo "postCreateCommand setup completed successfully!"
echo "Please restart your terminal or run 'source ~/.bashrc' to apply environment changes."
