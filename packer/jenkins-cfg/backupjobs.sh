#!/bin/sh
sudo cp -R /var/lib/jenkins/jobs/* /home/ec2-user/jenkins-jobs/
(cd /home/ec2-user/jenkins-jobs/;sudo /bin/git add .;sudo /bin/git commit -m "Backup job configuration changes";sudo /bin/git push origin master)