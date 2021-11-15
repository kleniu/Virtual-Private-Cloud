#!/bin/bash
set -e

export VPC_NAME=prod-vpc

## helper functions

function getVPC_ID() {
	VPC_NAME=$1
	VPC_ID=`ibmcloud is vpcs | grep $VPC_NAME | awk '{print $1}'`
	echo $VPC_ID	
}

function getSG_ID() {
	SG_NAME=$1
	SG_ID=`ibmcloud is sgs | grep $SG_NAME | awk '{print $1}'`
	echo $SG_ID
}

function getSUBNET_ID() {
	SUBNET_NAME=$1
	SUBNET_ID=`ibmcloud is subnets | grep $SUBNET_NAME | awk '{print $1}'`
	echo $SUBNET_ID
}

function getNETACL_ID() {
	NETACL_NAME=$1
	NETACL_ID=`ibmcloud is nwacls | grep $NETACL_NAME | awk '{print $1}'`
	echo $NETACL_ID
}

function checkSubnetAclAssignment() {
	SUBNET_NAME=$1
	ACL_NAME=$2
	ASSIGNED=`ibmcloud is subnets | grep $SUBNET_NAME | grep $ACL_NAME | wc -l | xargs`
	echo $ASSIGNED
}

ibmcloud is target --gen 2
## Create VPC
if [[ .`getVPC_ID $VPC_NAME`. == .. ]]; then
	echo
	echo "### ibmcloud is vpc-create --address-prefix-management=manual $VPC_NAME" 
	ibmcloud is vpc-create --address-prefix-management=manual $VPC_NAME > /dev/null
	sleep 3
	echo "done."
else
	echo "VPS $VPC_NAME already created. Skipping creation."
fi
VPC_ID=`getVPC_ID $VPC_NAME`
echo
ibmcloud is vpcs 
sleep 3

## Assign address prefixes to zones
if [[ .`ibmcloud is vpc-address-prefixes $VPC_ID -q | grep zone1-addr | wc -l | xargs`. == .0. ]]; then
	echo
	echo "### ibmcloud is vpc-address-prefix-create zone1-addr $VPC_ID eu-de-1 10.1.0.0/16" 
	ibmcloud is vpc-address-prefix-create zone1-addr $VPC_ID eu-de-1 10.1.0.0/16 > /dev/null
	echo "done."	
else
	echo "VPC IP address range for zone eu-de-1 already created. Skipping creation."
fi
if [[ .`ibmcloud is vpc-address-prefixes $VPC_ID -q | grep zone2-addr | wc -l | xargs`. == .0. ]]; then
	echo
        echo "### ibmcloud is vpc-address-prefix-create zone2-addr $VPC_ID eu-de-2 10.2.0.0/16"
	ibmcloud is vpc-address-prefix-create zone2-addr $VPC_ID eu-de-2 10.2.0.0/16 > /dev/null
	echo "done."
else
	echo "VPC IP address range for zone eu-de-2 already created. Skipping creation."
fi
echo
ibmcloud is vpc-address-prefixes $VPC_ID
sleep 3

## Creating subnets
if [[ .`ibmcloud is subnets -q | grep zone1-app | wc -l | xargs`. == .0. ]]; then
	echo
	echo "### ibmcloud is subnet-create zone1-app $VPC_ID --ipv4-cidr-block 10.1.1.0/24 --zone eu-de-1"
	ibmcloud is subnet-create zone1-app $VPC_ID --ipv4-cidr-block 10.1.1.0/24 --zone eu-de-1 > /dev/null
	echo "done."
else
	echo "VPC subnet zone1-app in zone eu-de-1 already created. Skipping creation."
fi 
if [[ .`ibmcloud is subnets -q | grep zone1-db | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is subnet-create zone1-db  $VPC_ID --ipv4-cidr-block 10.1.2.0/24 --zone eu-de-1"
	ibmcloud is subnet-create zone1-db  $VPC_ID --ipv4-cidr-block 10.1.2.0/24 --zone eu-de-1 > /dev/null
	echo "done."
else
	echo "VPC subnet zone1-db in zone eu-de-1 already created. Skipping creation."
fi
if [[ .`ibmcloud is subnets -q | grep zone2-app | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is subnet-create zone2-app $VPC_ID --ipv4-cidr-block 10.2.1.0/24 --zone eu-de-2"
	ibmcloud is subnet-create zone2-app $VPC_ID --ipv4-cidr-block 10.2.1.0/24 --zone eu-de-2 > /dev/null
	echo "done."
else
	echo "VPC subnet zone2-app in zone eu-de-2 already created. Skipping creation."
fi 
if [[ .`ibmcloud is subnets -q | grep zone2-db | wc -l | xargs`. == .0. ]]; then
	echo
	echo "### ibmcloud is subnet-create zone2-db  $VPC_ID --ipv4-cidr-block 10.2.2.0/24 --zone eu-de-2"
	ibmcloud is subnet-create zone2-db  $VPC_ID --ipv4-cidr-block 10.2.2.0/24 --zone eu-de-2 > /dev/null
	echo done
else
	echo "VPC subnet zone2-db in zone eu-de-1 already created. Skipping creation."
fi
echo
ibmcloud is subnets
sleep 3

## Create and configure ACL
if [[ .`ibmcloud is network-acls | grep acl-app | wc -l | xargs`. == .0. ]]; then
	echo
	echo "### ibmcloud is network-acl-create acl-app $VPC_ID"
	ibmcloud is network-acl-create acl-app $VPC_ID > /dev/null
	echo "done."
else
	echo "ACL acl-app in VPC $VPC_NAME aleready created. Skipping creation."
fi
if [[ .`ibmcloud is network-acl-rules acl-app | grep alloweverythingin | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is network-acl-rule-add acl-app allow inbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingin"
	ibmcloud is network-acl-rule-add acl-app allow inbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingin > /dev/null
	echo "done."
else
	echo "Rule 'alloweverythingin' in acl-app already created. Skipping creation."
fi 
if [[ .`ibmcloud is network-acl-rules acl-app | grep alloweverythingout | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is network-acl-rule-add acl-app allow outbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingout"
	ibmcloud is network-acl-rule-add acl-app allow outbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingout > /dev/null
	echo "done."
else
	echo "Rule 'alloweverythingout' in acl-app already created. Skipping creation."
fi 
if [[ .`ibmcloud is network-acls | grep acl-db | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is network-acl-create acl-db $VPC_ID"
	ibmcloud is network-acl-create acl-db $VPC_ID > /dev/null
	echo "done."
else
	echo "ACL acl-db in VPC $VPC_NAME aleready created. Skipping creation."
fi
if [[ .`ibmcloud is network-acl-rules acl-db | grep alloweverythingin | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is network-acl-rule-add acl-db allow inbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingin"
	ibmcloud is network-acl-rule-add acl-db allow inbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingin > /dev/null
	echo "done."
else
	echo "Rule 'alloweverythingin' in acl-db already created. Skipping creation."
fi 
if [[ .`ibmcloud is network-acl-rules acl-db | grep alloweverythingout | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is network-acl-rule-add acl-db allow outbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingout"
	ibmcloud is network-acl-rule-add acl-db allow outbound all 0.0.0.0/0 0.0.0.0/0 --name alloweverythingout > /dev/null
	echo "done."
else
	echo "Rule 'alloweverythingout' in acl-db already created. Skipping creation."
fi 

echo
ibmcloud is network-acls
sleep 3

## Assign ACL to subnets
NETACL_ID=`getNETACL_ID acl-app`
if [[ .`checkSubnetAclAssignment zone1-app acl-app`. == .0. ]]; then
	SUBNET_ID=`getSUBNET_ID zone1-app`
	echo 
	echo "### ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID"
	ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID > /dev/null
	echo "done."
else
	echo "Subnet zone1-app already has ACL acl-app assigned. Skipping assignment."
fi
if [[ .`checkSubnetAclAssignment zone2-app acl-app`. == .0. ]]; then
	SUBNET_ID=`getSUBNET_ID zone2-app`
	echo 
	echo "### ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID" 
	ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID > /dev/null
	echo "done."
else
	echo "Subnet zone2-app already has ACL acl-app assigned. Skipping assignment."
fi
NETACL_ID=`getNETACL_ID acl-db`
if [[ .`checkSubnetAclAssignment zone1-db acl-db`. == .0. ]]; then
	SUBNET_ID=`getSUBNET_ID zone1-db`
	echo 
	echo "### ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID"
	ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID > /dev/null
	echo "done."
else
	echo "Subnet zone1-db already has ACL acl-db assigned. Skipping assignment."
fi
if [[ .`checkSubnetAclAssignment zone2-db acl-db`. == .0. ]]; then
	SUBNET_ID=`getSUBNET_ID zone2-db`
	echo 
	echo "### ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID"
	ibmcloud is subnet-update $SUBNET_ID --acl $NETACL_ID > /dev/null
	echo
else
	echo "Subnet zone2-db already has ACL acl-db assigned. Skipping assignment."
fi

echo
ibmcloud is subnets
sleep 3

## Create and configure SG
### sg-app
if [[ .`ibmcloud is security-groups | grep sg-app | wc -l | xargs`. == .0. ]]; then
	echo
	echo "### ibmcloud is security-group-create sg-app $VPC_ID"
	ibmcloud is security-group-create sg-app $VPC_ID > /dev/null
	echo "done."
else
	echo "Security group sg-app already created. Skipping creation."
fi

SG_ID=`getSG_ID sg-app`
echo "Security group for sg-app :" $SG_ID
if [[ .`ibmcloud is security-groups | grep sg-app | awk '{print $3}'`. == .0. ]]; then
	echo
	echo "### ibmcloud is security-group-rule-add $SG_ID inbound all --remote 0.0.0.0/0"
	ibmcloud is security-group-rule-add $SG_ID inbound all --remote 0.0.0.0/0 > /dev/null
	echo
	echo "### ibmcloud is security-group-rule-add $SG_ID outbound all --remote 0.0.0.0/0"
	ibmcloud is security-group-rule-add $SG_ID outbound all --remote 0.0.0.0/0 > /dev/null
	echo "done."
else
	echo "Security group sg-app already has rules created. Skipping creation."
fi

### sg-db
if [[ .`ibmcloud is security-groups | grep sg-db | wc -l | xargs`. == .0. ]]; then
	echo 
	echo "### ibmcloud is security-group-create sg-db $VPC_ID"
	ibmcloud is security-group-create sg-db $VPC_ID > /dev/null
	echo "done"
else
	echo "Security group sg-db already created. Skipping creation."
fi

SG_ID=`getSG_ID sg-db`
echo "Security group for sg-db :" $SG_ID
if [[ .`ibmcloud is security-groups | grep sg-db | awk '{print $3}'`. == .0. ]]; then
	echo
	echo "### ibmcloud is security-group-rule-add $SG_ID inbound all --remote 0.0.0.0/0"
	ibmcloud is security-group-rule-add $SG_ID inbound all --remote 0.0.0.0/0 > /dev/null
	echo 
	echo "### ibmcloud is security-group-rule-add $SG_ID outbound all --remote 0.0.0.0/0"
	ibmcloud is security-group-rule-add $SG_ID outbound all --remote 0.0.0.0/0 > /dev/null
	echo "done."
else
	echo "Security group sg-db already has rules created. Skipping creation."
fi

echo 
ibmcloud is security-groups
