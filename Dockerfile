FROM summerwind/actions-runner:latest

RUN sudo apt update -y \
  && umask 0002 \
  && sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Install MS Key
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add MS Apt repo
RUN umask 0002 && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

# Install Azure CLI
RUN sudo apt update -y \
  && umask 0002 \
  && sudo apt install -y azure-cli 
  
# Customize image for datascience repository
RUN sudo apt-get update && sudo apt-get install -y libgl1-mesa-dev ffmpeg libsm6 libxext6 locales curl jq docker.io
RUN sudo sed -i -e 's/# es_MX.UTF-8 UTF-8/es_MX.UTF-8 UTF-8/' /etc/locale.gen
RUN sudo dpkg-reconfigure --frontend=noninteractive locales
RUN echo "LANG=es_MX.UTF-8" | sudo tee -a /etc/environment
RUN echo "LC_ALL=es_MX.UTF-8" | sudo tee -a /etc/environment

# Free storage
RUN sudo rm -rf /var/lib/apt/lists/*

# Download and install kubectl 
RUN sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN sudo  chmod +x ./kubectl
RUN sudo mv ./kubectl /usr/local/bin/kubectl
