# Base Ubuntu for maximum compatibility
FROM ubuntu:22.04

# Avoid prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install Java, Node.js, Python, Terraform dependencies, Docker, and utils
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    gnupg \
    lsb-release \
    software-properties-common \
    docker.io \
    nodejs \
    npm \
    sudo \
    ssh \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH:/workspace/node_modules/.bin"

# Install Terraform
ARG TERRAFORM_VERSION=1.6.0
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

# Add Jenkins user with sudo
RUN useradd -m -d /var/lib/jenkins -s /bin/bash jenkins \
    && echo 'jenkins:jenkins' | chpasswd \
    && echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Set workdir
WORKDIR /workspace
USER jenkins

# Keep container alive
CMD ["bash"]
