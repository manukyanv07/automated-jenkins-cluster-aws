#!/bin/sh
sudo cp -R /var/lib/jenkins/jobs/* /home/ec2-user/jenkins-jobs/
sudo cp -R /var/lib/jenkins/*.xml /home/ec2-user/jenkins-jobs/config/
(cd /home/ec2-user/jenkins-jobs/;sudo /bin/git add .;sudo /bin/git commit -m "Backup job configuration changes";sudo /bin/git push origin master)