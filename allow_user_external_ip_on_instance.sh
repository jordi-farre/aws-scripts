#!/bin/sh

remote_sg_name=$1
instance_id=$2
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 remote_security_group instance_id"
  exit 1
fi

echo "Remote security group: $remote_sg_name"
echo "Instance Id: $instance_id"

external_ip="none"
function getExternalIpAddress() {
  external_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  echo "External IP Address: $external_ip"
}

old_ip="none"
function getOldIPAddress() {
  old_ip=$(cat old_ip)
  echo "Old IP Address: $old_ip"
}

function createRemoteSecurityGroup() {
  aws ec2 create-security-group --group-name $1 --description $2
}

remote_sg_id="none"
function getRemoteSecurityGroupId() {
  remote_sg_id=$(aws ec2 describe-security-groups --group-names $remote_sg_name | jq -r '.SecurityGroups[0].GroupId')
  echo "Remote security group id: $remote_sg_id"
}

function revokeSecurityGroupIngress() {
  aws ec2 revoke-security-group-ingress --group-name $1 --protocol $2 --port $3 --cidr "$4/32"
}

function authorizeSecurityGroupIngress() {
  aws ec2 authorize-security-group-ingress --group-name $1 --protocol $2 --port $3 --cidr "$4/32"
}

instance_sg_list="none"
function getInstanceSecurityGroupList() {
  instance_sg_list=$(aws ec2 describe-instance-attribute --attribute groupSet --instance-id $instance_id | jq -r '.Groups | map(.GroupId) | join(" ")')
  echo "Instance security group list: $instance_sg_list"
}

function addRemoteSecurityGroupToInstance() {
  aws ec2 modify-instance-attribute --instance-id $instance_id --groups $instance_sg_list $remote_sg_id
}

function changeIPAddress() {
  echo "Changing IP on AWS..."
  createRemoteSecurityGroup $remote_sg_name $remote_sg_name
  getRemoteSecurityGroupId
  declare -a ports=( 8080 8081 9000)
  for port in "${ports[@]}"; do
    revokeSecurityGroupIngress $remote_sg_name "tcp" $port $old_ip
    authorizeSecurityGroupIngress $remote_sg_name "tcp" $port $external_ip
  done
  getInstanceSecurityGroupList
  if [[ $instance_sg_list != *$remote_sg_id* ]]; then
    addRemoteSecurityGroupToInstance
    getInstanceSecurityGroupList
  fi  
  echo "Changing IP on AWS finished"
}

getExternalIpAddress
getOldIPAddress
if [ "$old_ip" != "$external_ip" ]; then
   changeIPAddress
   echo $external_ip > old_ip
fi
