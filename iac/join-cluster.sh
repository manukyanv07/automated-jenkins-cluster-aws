#!/bin/bash

JENKINS_URL="${jenkins_url}"

JENKINS_USERNAME="${jenkins_username}"
JENKINS_PASSWORD="${jenkins_password}"

wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.9/swarm-client-3.9.jar
java -jar swarm-client-3.9.jar -master $JENKINS_URL/ -username $JENKINS_USERNAME -password $JENKINS_PASSWORD