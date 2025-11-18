FROM summerwind/actions-runner:latest

RUN sudo apt update -y \
  && umask 0002 \
  && sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Install Docker from Docker's official repository (newer version with API 1.44+ support)
RUN umask 0002 \
  && sudo install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && sudo chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Azure CLI using the install script (works across Ubuntu versions)
RUN umask 0002 \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash 
  
# Customize image for datascience repository
# Install Python 3.11 from deadsnakes PPA (required for Ubuntu Noble)
RUN sudo apt-get update && sudo apt-get install -y \
    software-properties-common \
    && sudo add-apt-repository -y ppa:deadsnakes/ppa \
    && sudo apt-get update && sudo apt-get install -y \
    libgl1-mesa-dev \
    ffmpeg \
    libsm6 \
    libxext6 \
    locales \
    curl \
    jq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    build-essential \
    git \
    && sudo rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default python3 and ensure pip works
RUN sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Install Docker Compose as standalone binary (V2)
RUN umask 0002 \
    && sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && sudo chmod +x /usr/local/bin/docker-compose

# Install DVC CLI (version 3.55.2 as specified in workflow)
RUN umask 0002 \
    && python3.11 -m pip install --no-cache-dir "dvc[s3,azure,gdrive,gs,oss,ssh]==3.55.2"

# Pre-install common Python packages used in CI/CD to speed up workflow
RUN umask 0002 \
    && python3.11 -m pip install --no-cache-dir \
        "PyYAML>=6.0" \
        "importlib-metadata<8.0.0" \
        "importlib-resources<6.0.0" \
        "packaging<24.0" \
        "truefoundry>=0.5.1" \
        "servicefoundry" \
        "requests>=2.26.0" \
        "cryptography" \
        "pyopenssl"

# Configure locale
RUN sudo sed -i -e 's/# es_MX.UTF-8 UTF-8/es_MX.UTF-8 UTF-8/' /etc/locale.gen
RUN sudo dpkg-reconfigure --frontend=noninteractive locales
RUN echo "LANG=es_MX.UTF-8" | sudo tee -a /etc/environment
RUN echo "LC_ALL=es_MX.UTF-8" | sudo tee -a /etc/environment

# Download and install kubectl 
RUN sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && sudo chmod +x ./kubectl \
    && sudo mv ./kubectl /usr/local/bin/kubectl

# Final cleanup to reduce image size
RUN sudo rm -rf /tmp/* /var/tmp/* \
    && sudo apt-get clean \
    && python3.11 -m pip cache purge || true
