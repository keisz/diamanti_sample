#!/bin/sh

# Prerequisites

# Setting up
COUNT="$1"
COUNTFILE="/dev/shm/postgres-template-counter.out"

# Checking
if [ $# -lt 1 ]; then
        echo -e "\nUsage instructions for Andrew's Podspec Educator™ Tool:\n\n\t# $(basename $0): <Cluster Replica Count>\n"
        exit 1
fi

if [ $1 = "clean" ]||[ $? = "cleanup" ];then
	echo -e "\nCleaning up postgres-template-*"
	rm -f postgres-template-*
	echo -e "\nCleaned: $(pwd)\n"
	exit 0
fi

echo "$COUNT" > $COUNTFILE

# Go time
(set -x 
grep -A 12 -B1 PersistentVolumeClaim postgres-template.yaml > postgres-template-PVC.yaml
grep -A 73 -B1 ReplicationController postgres-template.yaml > postgres-template-RC.yaml
grep -A 16 -B1 Service postgres-template.yaml > postgres-template-SVC.yaml 
cat postgres-template-PVC.yaml postgres-template-RC.yaml postgres-template-SVC.yaml > postgres-template-generated.yaml
echo -n > postgres-template-$(cat $COUNTFILE)-replicas.yaml
for i in $(seq -w 1 $(cat $COUNTFILE)) ; do sed s/NUM/$i/g postgres-template-generated.yaml ; done >> postgres-template-$(cat $COUNTFILE)-replicas.yaml

# Now just adding the Podspec header and footer
sed -i '1s;^;apiVersion: v1\nitems:\n;' postgres-template-$(cat $COUNTFILE)-replicas.yaml
echo -e "kind: List\nmetadata: {}" >> postgres-template-$(cat $COUNTFILE)-replicas.yaml
)

echo -e "\n+++++ Now just run the following command to deploy your template: +++++\n"
echo -e "kubectl create -f postgres-template-$(cat $COUNTFILE)-replicas.yaml\n"
