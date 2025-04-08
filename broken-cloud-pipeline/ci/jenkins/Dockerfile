FROM jenkins/jenkins:lts

USER root

# Install required tools
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    git

# Set up Docker repository
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

# Install Docker
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Handle Docker group safely
RUN if getent group docker; then \
      groupmod -g 1950 docker; \
    else \
      groupadd -g 1950 docker; \
    fi && \
    usermod -aG docker jenkins
CMD ["sh", "-c", "dockerd & sleep 5 && jenkins.sh"]  # Start dockerd, wait, then Jenkins
EXPOSE 8080
USER jenkins
