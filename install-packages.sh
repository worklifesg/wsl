#!/bin/bash
# Script to install packages

set -e
export DEBIAN_FRONTEND=noninteractive

# Update and Upgrade
echo "Updating system..."
apt-get update
apt-get upgrade -y || true

# Default packages
PACKAGES="sudo curl wget git ca-certificates gnupg lsb-release apt-transport-https build-essential make gcc g++ clang python3 python3-pip python3-venv unzip zip jq htop net-tools iproute2 iputils-ping procps locales tzdata"

if [ -f /root/packages.txt ]; then
    echo "Reading packages from /root/packages.txt"
    PACKAGES=$(cat /root/packages.txt | tr '\n' ' ')
fi

echo "Installing packages: $PACKAGES"
apt-get install -y $PACKAGES

# Locale generation
echo "Generating locales..."
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Create dev user
echo "Creating devuser..."
if ! id -u devuser >/dev/null 2>&1; then
  useradd -m -s /bin/bash devuser
  echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# -------------------------
# Node.js + nvm
# -------------------------
echo "Installing NVM and Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash || true
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
  nvm install 22 || true
  nvm alias default 22 || true
fi

# -------------------------
# Go
# -------------------------
echo "Installing Go..."
GO_VER=1.23.9
wget -q https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz -O /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
# Overwrite /etc/profile.d/go.sh to ensure idempotency. Using '>' avoids duplicate entries if the script is run multiple times.
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
chmod +x /etc/profile.d/go.sh

# -------------------------
# Java & Rust & Python
# -------------------------
echo "Installing Java, Rust, Python..."
apt-get install -y openjdk-17-jdk
curl https://sh.rustup.rs -sSf | sh -s -- -y || true
python3 -m pip install --upgrade pip setuptools wheel || true

# -------------------------
# Web dev tools
# -------------------------
echo "Installing Web Dev tools..."
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
  npm install -g yarn pnpm typescript vite webpack webpack-cli || true
fi
curl -fsSL https://code-server.dev/install.sh | sh || true

# -------------------------
# Kubernetes & cloud tools
# -------------------------
echo "Installing Cloud tools..."
# kubectl
curl -L --silent "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl || true

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || true

# kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash || true
mv kustomize /usr/local/bin/ || true

# kind
curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x /usr/local/bin/kind || true

# minikube
curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x /usr/local/bin/minikube || true

# k9s
curl -sS https://webinstall.dev/k9s | bash || true
# Move k9s to global path if installed locally
if [ -f "$HOME/.local/bin/k9s" ]; then
    # If /usr/local/bin/k9s exists, back it up before overwriting
    if [ -f /usr/local/bin/k9s ]; then
        echo "Warning: /usr/local/bin/k9s already exists. Backing up to /usr/local/bin/k9s.bak.$(date +%s)"
        cp /usr/local/bin/k9s /usr/local/bin/k9s.bak.$(date +%s)
    fi
    # Overwrite is intentional to ensure latest version is globally accessible
    mv "$HOME/.local/bin/k9s" /usr/local/bin/
fi

# trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin || true

# docker client
apt-get install -y docker.io || true

# aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install || true

# azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | bash || true

# Final cleanup
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

exit 0