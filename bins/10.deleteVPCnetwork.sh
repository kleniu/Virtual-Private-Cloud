#!/bin/bash
set -e

export VPC_NAME=prod-vpc

## helper functions
function getVPC_ID() {
        VPC_NAME=$1
        VPC_ID=`ibmcloud is vpcs | grep $VPC_NAME | awk '{print $1}'`
        echo $VPC_ID
}

VPC_ID=`getVPC_ID $VPC_NAME`

echo "Deleting load balancers"
for P in `ibmcloud is lbs -q | grep -v "^ID" | grep -v "delete_pending" | grep -v "No load balancers were found." | awk '{print $1}'`; do
        ibmcloud is lbd $P -f
done

printf "Checking LBs existance."
while [[ .`ibmcloud is lbs -q | grep -v "^ID" | grep -v "No load balancers were found." | wc -l | xargs`. != .0. ]]; do
        sleep 1; printf "."
done
echo
echo "done. All LBs removed."

echo "Detaching subnets from Public Gateway (is subnet-pubgwd)"
for K in `ibmcloud is pubgws | grep $VPC_NAME | awk '{print $2}'`; do
	for P in `ibmcloud is subnets | grep $VPC_NAME | grep $K | awk '{print $1}'`; do
		ibmcloud is subnet-pubgwd $P 
	done
done

echo "Deleting Public Gateways"
for P in `ibmcloud is pubgws | grep $VPC_NAME | awk '{print $1}'`; do
        ibmcloud is pubgwd $P -f
done

printf "Checking  Public Gateways instances' existance."
while [[ .`ibmcloud is pubgws -q | grep $VPC_NAME | wc -l | xargs`. != .0. ]]; do
        sleep 1; printf "."
done
echo
echo "done. All Public Gateways instances removed."

echo "Deleting VPN gateways."
for P in `ibmcloud is vpns -q | grep -v "^ID" | grep -v "No vpn gateways were found." |awk '{print $1}'`; do
        ibmcloud is vpnd $P -f
done

printf "Checking VPNs existance."
while [[ .`ibmcloud is vpns -q | grep -v "^ID" | grep -v "No vpn gateways were found." | wc -l | xargs`. != .0. ]]; do
        sleep 1; printf "."
done
echo
echo "done. All VPNs removed."

echo "Stopping VM instances."
for P in `ibmcloud is ins | grep $VPC_NAME | awk '{print $1}'`; do
	ibmcloud is in-stop $P -f
done

printf "Checking status ...."
while [[ .`ibmcloud is ins -q | grep $VPC_NAME | grep -v stopped | wc -l | xargs`. != .0. ]]; do
	sleep 1; printf "."
done
echo
echo "done. All instances are stopped" 
ibmcloud is ins

echo "Removing VM instances."

for P in `ibmcloud is ins | grep $VPC_NAME | awk '{print $1}'`; do
	ibmcloud is ind $P -f
done

printf "Checking instances' existance."
while [[ .`ibmcloud is ins -q | grep $VPC_NAME | wc -l | xargs`. != .0. ]]; do
        sleep 1; printf "."
done
echo
echo "done. All instances removed."

for P in `ibmcloud is subnets | grep $VPC_NAME | awk '{print $1}'`; do 
	echo "Deleting subnet ID: " $P
	ibmcloud is subnet-delete $P -f
done

sleep 3

ibmcloud is vpcd $VPC_ID -f


