#!/bin/sh

# Prerequisites

# Setting up
COUNT="$1"
COUNTFILE="/dev/shm/mysql-template-counter.out"

# Checking
if [ $# -lt 1 ]; then
        echo -e "\nUsage instructions for Andrew's Podspec Educator™ Tool:\n\n\t# $(basename $0): <Replica Count>\n"
        exit 1
fi

if [ $1 = "clean" ]||[ $? = "cleanup" ];then
	echo -e "\nCleaning up mysql-template-*"
	rm -f mysql-template-*
	echo -e "\nCleaned: $(pwd)\n"
	exit 0
fi

echo "$COUNT" > $COUNTFILE

# Go time
(set -x 
grep -m 1 -A 12 -B1 PersistentVolumeClaim mysql-template.yaml > mysql-template-PVC.yaml
grep -m 1 -A 45 -B1 Deployment mysql-template.yaml > mysql-template-DEPLOY.yaml
grep -m 1 -A 16 -B1 Service mysql-template.yaml > mysql-template-SVC.yaml 
cat mysql-template-PVC.yaml mysql-template-DEPLOY.yaml mysql-template-SVC.yaml > mysql-template-template.yaml
sed -i s/mysql-[0-9]/mysql-NUM/g mysql-template-template.yaml
echo -n > mysql-template-$(cat $COUNTFILE)-replica.yaml
for i in $(seq 1 $(cat $COUNTFILE)) ; do sed s/mysql-NUM/mysql-$i/g mysql-template-template.yaml ; done >> mysql-template-$(cat $COUNTFILE)-replica.yaml
sed -i '1s;^;apiVersion: v1\nitems:\n;' mysql-template-$(cat $COUNTFILE)-replica.yaml
echo -e "kind: List\nmetadata: {}" >> mysql-template-$(cat $COUNTFILE)-replica.yaml
rm -f mysql-template-template.yaml
)

echo -e "\n+++++ Now just run the following command to deploy your template: +++++\n"
echo -e "kubectl create -f mysql-template-$(cat $COUNTFILE)-replica.yaml\n"
