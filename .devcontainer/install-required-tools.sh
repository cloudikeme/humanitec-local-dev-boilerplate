#!/usr/bin/env bash

# Define a sudo wrapper
run_as_root() {
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

set -e

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Basic packages
run_as_root apt-get update -y || true
run_as_root apt-get install -y curl unzip wget net-tools jq bash-completion

# mkcert
if ! command -v mkcert &> /dev/null; then
  echo "Installing mkcert..."
  curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/${ARCH}"
  chmod +x mkcert-v*-linux-${ARCH}
  run_as_root mv mkcert-v*-linux-${ARCH} /usr/local/bin/mkcert
  export CAROOT="/workspaces"
  mkcert -install
fi

# taskfile
if ! command -v task &> /dev/null; then
  echo "Installing Taskfile..."
  sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
fi

# yq
if ! command -v yq &> /dev/null; then
  echo "Installing yq..."
  VERSION="v4.35.1"
  wget "https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_${ARCH}" -O yq
  chmod +x yq
  run_as_root mv yq /usr/local/bin/yq
fi

# direnv
if ! command -v direnv &> /dev/null; then
  echo "Installing direnv..."
  curl -sfL https://direnv.net/install.sh | bash
  run_as_root mv ~/.local/bin/direnv /usr/local/bin/direnv || true
fi

# terraform
if ! command -v terraform &> /dev/null; then
  echo "Installing Terraform..."
  VERSION="1.5.7"
  wget "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_${ARCH}.zip"
  unzip terraform_${VERSION}_linux_${ARCH}.zip
  run_as_root mv terraform /usr/local/bin/
  rm terraform_${VERSION}_linux_${ARCH}.zip
fi

# glow
if ! command -v glow &> /dev/null; then
  echo "Installing glow..."
  curl -sSfL https://raw.githubusercontent.com/charmbracelet/glow/main/install.sh | sh
  run_as_root mv ~/.local/bin/glow /usr/local/bin/glow || true
fi

# kubectl
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
  chmod +x kubectl
  run_as_root mv kubectl /usr/local/bin/
  echo "source <(kubectl completion bash)" >> ~/.bashrc
fi

# Docker network 'kind'
if ! docker network ls | grep -q kind; then
  echo "Creating Docker network 'kind'..."
  run_as_root docker network create kind
fi

# helm
if ! command -v helm &> /dev/null; then
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# score-compose
if ! command -v score-compose &> /dev/null; then
  echo "Installing score-compose..."
  VERSION="0.10.1"
  curl -L "https://github.com/score-spec/score-compose/releases/download/v${VERSION}/score-compose_${VERSION}_${OS}_${ARCH}.tar.gz" | tar xz
  chmod +x score-compose
  run_as_root mv score-compose /usr/local/bin/
fi

# score-k8s
if ! command -v score-k8s &> /dev/null; then
  echo "Installing score-k8s..."
  VERSION="0.1.18"
  curl -LO "https://github.com/score-spec/score-k8s/releases/download/${VERSION}/score-k8s_${VERSION}_linux_${ARCH}.tar.gz"
  tar xvzf score-k8s_${VERSION}_linux_${ARCH}.tar.gz
  run_as_root mv score-k8s /usr/local/bin/
  rm score-k8s_${VERSION}_linux_${ARCH}.tar.gz LICENSE README.md
fi

# humctl
if ! command -v humctl &> /dev/null; then
  echo "Installing humctl..."
  VERSION="0.36.2"
  curl -LO "https://github.com/humanitec/cli/releases/download/v${VERSION}/cli_${VERSION}_linux_${ARCH}.tar.gz"
  tar xvzf cli_${VERSION}_linux_${ARCH}.tar.gz
  run_as_root mv humctl /usr/local/bin/
  echo "source <(humctl completion bash)" >> ~/.bashrc
  rm cli_${VERSION}_linux_${ARCH}.tar.gz LICENSE README.md
fi

# kind
if ! command -v kind &> /dev/null; then
  echo "Installing kind..."
  curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-${ARCH}"
  chmod +x ./kind
  run_as_root mv ./kind /usr/local/bin/kind
fi

echo "✅ All tools installed successfully."
