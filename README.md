# allow_user_external_ip_on_instance.sh

This script receives two parameters:

1. Name of the security group to be created.
2. Instance Id where we want to add the security group.

On the script execution:

1. The last external ip is retrieved from a local file (old_ip) in the same directory of the script.
2. The actual external ip is retrieved from a call to opendns.
3. If the IPs are different:
3.1. Create a new Security Group on AWS with the name of the first parameter.
3.2. Revokes the old ip in this Security Group for ports 8080,8081 and 9000.
3.3. Allow access to ports 8080,8081 and 9000 in the Security Group created for the actual external IP.
3.4. Add the Security Group to the instance with the id received in the first parameter.
3.5. Update the file old_ip with the actual external IP.
