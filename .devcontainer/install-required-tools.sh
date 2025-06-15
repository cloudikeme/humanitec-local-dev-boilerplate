#!/usr/bin/env bash
mkdir setup-tools
cd setup-tools

set -euo pipefail

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
#if ! command -v task &> /dev/null; then
  #echo "Installing Taskfile..."
  #sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
#fi

# Install Taskfile
if ! command -v task &> /dev/null; then
  echo "Task not found. Installing..."
  TASK_VERSION="3.37.2"
  curl -sL "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${ARCH}.tar.gz" -o task.tar.gz
  tar -xzf task.tar.gz task
  rm task.tar.gz
  run_as_root mv task /usr/local/bin/task
  run_as_root chown root: /usr/local/bin/task
else
  echo "Task is already installed."
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
#if ! command -v glow &> /dev/null; then
  #echo "Installing glow..."
  #curl -sSfL https://raw.githubusercontent.com/charmbracelet/glow/main/install.sh | sh
  #run_as_root mv ~/.local/bin/glow /usr/local/bin/glow || true
#fi

# Install glow to be able to read MD files in the terminal
if ! command -v glow &> /dev/null
then
  echo "glow not found. Installing..."
  run_as_root mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | run_as_root gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | run_as_root tee /etc/apt/sources.list.d/charm.list
  run_as_root apt update && run_as_root apt install glow -y
else
  echo "glow is already installed."
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


# For score-compose AMD64 / x86_64
if ! command -v score-compose &> /dev/null
then
  echo "score-compose not found. Installing..."
  [ $(uname -m) = x86_64 ] && curl -sLO "https://github.com/score-spec/score-compose/releases/download/0.29.2/score-compose_0.29.2_linux_amd64.tar.gz"
  # For score-compose ARM64
  [ $(uname -m) = aarch64 ] && curl -sLO "https://github.com/score-spec/score-compose/releases/download/0.29.2/score-compose_0.29.2_linux_arm64.tar.gz"
  tar xvzf score-compose*.tar.gz
  rm score-compose*.tar.gz README.md LICENSE
  run_as_root mv ./score-compose /usr/local/bin/score-compose
  run_as_root chown root: /usr/local/bin/score-compose
else
  echo "score-compose is already installed."
fi

# For score-k8s AMD64 / x86_64
if ! command -v score-k8s &> /dev/null
then
  echo "score-k8s not found. Installing..."
  [ $(uname -m) = x86_64 ] && curl -sLO "https://github.com/score-spec/score-k8s/releases/download/0.1.18/score-k8s_0.1.18_linux_amd64.tar.gz"
  # For score-k8s ARM64
  [ $(uname -m) = aarch64 ] && curl -sLO "https://github.com/score-spec/score-k8s/releases/download/0.1.18/score-k8s_0.1.18_linux_arm64.tar.gz"
  tar xvzf score-k8s*.tar.gz
  rm score-k8s*.tar.gz README.md LICENSE
  run_as_root mv ./score-k8s /usr/local/bin/score-k8s
  run_as_root chown root: /usr/local/bin/score-k8s
else
  echo "score-k8s is already installed."
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

cd ..
rm -rf setup-tools

echo "✅ All tools installed successfully."
