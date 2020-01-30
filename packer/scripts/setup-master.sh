#!/bin/bash

echo "Install Jenkins stable release"
yum remove -y java
yum install -y java-1.8.0-openjdk
yum install -y wget
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins
chkconfig jenkins on

echo "Install git"
yum install -y git

echo "Setup SSH key"
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
chmod 600 /var/lib/jenkins/.ssh/id_rsa

echo "Configure Jenkins"
mkdir -p /var/lib/jenkins/init.groovy.d

echo "Disable Jenkins initial wizard."
export JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
mv /tmp/jenkins.install.UpgradeWizard.state /var/lib/jenkins/jenkins.install.UpgradeWizard.state
mv /tmp/jenkins.install.InstallUtil.lastExecVersion /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion
chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.UpgradeWizard.state
chown -R jenkins:jenkins /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion

service jenkins start
sleep 10s

#Install plugins
echo "#######################INSTALLING PLUGINS##################################"
sudo java -jar /tmp/jenkins-plugin-manager-1.0.1.jar -p swarm --plugin-download-directory /var/lib/jenkins/plugins --latest
sudo java -jar /tmp/jenkins-plugin-manager-1.0.1.jar --plugin-download-directory /var/lib/jenkins/plugins --plugin-file /tmp/plugins.yaml --latest

echo "##############################Configure jenkins security#################3"
mv /tmp/basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy
mv /tmp/disable-cli.groovy /var/lib/jenkins/init.groovy.d/disable-cli.groovy
mv /tmp/csrf-protection.groovy /var/lib/jenkins/init.groovy.d/csrf-protection.groovy
mv /tmp/disable-jnlp.groovy /var/lib/jenkins/init.groovy.d/disable-jnlp.groovy
mv /tmp/node-agent.groovy /var/lib/jenkins/init.groovy.d/node-agent.groovy

service jenkins restart
sleep 15s
echo "####################JENKINS LOG after init scripts ############################"
sudo cat /var/log/jenkins/jenkins.log
