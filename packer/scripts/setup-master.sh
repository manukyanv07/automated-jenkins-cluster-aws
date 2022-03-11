#!/bin/bash

echo "Install Jenkins stable release"
yum remove -y java
yum install -y java-1.8.0-openjdk
yum install -y wget

curl -LO 'https://rpmfind.net/linux/epel/7/x86_64/Packages/d/daemonize-1.7.7-1.el7.x86_64.rpm'
sudo rpm -Uvh ./daemonize-1.7.7-1.el7.x86_64.rpm

#install nvm and node8
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 8
nvm use 8

#Install maven
sudo yum install  -y maven

#Install docker
sudo yum install -y docker
sudo groupadd docker
sudo usermod -aG docker jenkins
sudo touch /etc/profile.d/dockerhost.sh
sudo echo "export DOCKER_HOST=unix:///var/run/docker.sock" > /etc/profile.d/dockerhost.sh
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
yum install -y epel-release # repository that provides 'daemonize'
yum install -y java-11-openjdk-devel
yum install -y jenkins

systemctl daemon-reload
chkconfig jenkins on

sudo gpasswd -a jenkins docker

echo "Install git"
yum install -y git

echo "Setup SSH key"
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
mv /tmp/humazemd.pem /var/lib/jenkins/.ssh/
chmod 600 /var/lib/jenkins/.ssh/id_rsa

echo "Configure Jenkins"
mkdir -p /var/lib/jenkins/init.groovy.d

echo "Disable Jenkins initial wizard."
export JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
mv /tmp/jenkins.install.UpgradeWizard.state /var/lib/jenkins/jenkins.install.UpgradeWizard.state
mv /tmp/jenkins.install.InstallUtil.lastExecVersion /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion
chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.UpgradeWizard.state
chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion

systemctl start jenkins
sleep 10s

#Install plugins
echo "#######################INSTALLING PLUGINS##################################"
#sudo java -jar /tmp/jenkins-plugin-manager-1.0.1.jar -p swarm --plugin-download-directory /var/lib/jenkins/plugins --latest
sudo java -jar /tmp/jenkins-plugin-manager-1.0.1.jar --plugin-download-directory /var/lib/jenkins/plugins --plugin-file /tmp/plugins.yaml --latest

echo "##############################Configure jenkins security#################3"
mv /tmp/basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy
mv /tmp/disable-cli.groovy /var/lib/jenkins/init.groovy.d/disable-cli.groovy
mv /tmp/csrf-protection.groovy /var/lib/jenkins/init.groovy.d/csrf-protection.groovy
mv /tmp/disable-jnlp.groovy /var/lib/jenkins/init.groovy.d/disable-jnlp.groovy
mv /tmp/node-agent.groovy /var/lib/jenkins/init.groovy.d/node-agent.groovy

echo "##############################Configure jobs backup###################################"
chmod +x /tmp/backupjobs.sh
crontab /tmp/crontab.txt

echo "##################################Humaze Access#####################################"
mv /tmp/humazemd.pem /var/lib/jenkins/.ssh/humazemd.pem
chmod 400 /var/lib/jenkins/.ssh/humazemd.pem
chown -R jenkins:jenkins /var/lib/jenkins/.ssh/humazemd.pem
ls -al /var/lib/jenkins/.ssh/
echo "Download jobs"
git clone https://vmanukyan:bgSmxtuniK_6YVYAS_4s@git.treehouse-holdings.com/vmanukyan/jenkins-jobs.git
ls jenkins-jobs
cp -R jenkins-jobs/* /var/lib/jenkins/jobs/
chown -R jenkins:jenkins /var/lib/jenkins/jobs/*

cp /tmp/jenkins.plugins.slack.SlackNotifier.xml /var/lib/jenkins/
cp /tmp/jenkins.plugins.nodejs.tools.NodeJSInstallation.xml /var/lib/jenkins/

chown -R jenkins:jenkins /var/lib/jenkins/*.xml

systemctl restart jenkins
sleep 15s
