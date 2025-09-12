# Use official Node.js LTS as base
FROM node:18-bullseye

# Install dependencies for Terraform, AWS CLI, Docker, Java 17, and other utils
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    git \
    python3 \
    python3-pip \
    gnupg \
    lsb-release \
    software-properties-common \
    docker.io \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

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

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH:/workspace/node_modules/.bin"

# Set workdir
WORKDIR /workspace

# Default command (keep container alive)
CMD ["bash"]
