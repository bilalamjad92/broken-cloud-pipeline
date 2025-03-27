# Build argument to determine the target image (jenkins or app)
ARG TARGET=jenkins

# Stage 1: Build the Jenkins image
FROM jenkins/jenkins:lts AS jenkins

USER root

# Install Docker CLI inside the Jenkins container
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    git

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

USER jenkins

# Copy the plugin list file into the container
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install plugins from plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Expose Jenkins port
EXPOSE 8080

# Stage 2: Build the App image (infrastructureascode/hello-world)
FROM ghcr.io/infrastructure-as-code/hello-world AS app

# Expose the app port
EXPOSE 8080

# Final Stage: Select the target image based on TARGET argument
FROM ${TARGET}

# Start command (Jenkins uses CMD from base image, app uses default from ghcr.io/infrastructure-as-code/hello-world)
CMD ["jenkins.sh"]
