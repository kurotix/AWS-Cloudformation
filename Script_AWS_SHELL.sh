AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
VPC_NAME="AWS_VPC_TP"
VPC_CIDR=""
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ=$AWS_REGION"a"
SUBNET_PUBLIC_NAME="10.0.1.0 - "$AWS_REGION"a"
KEY_NAME=""
IMAGE_ID=""

echo "Creation VPC"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text )
echo "  VPC ID '$VPC_ID' Créé dans la région '$AWS_REGION'."

echo "Creation sous-réseau Public "
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PUBLIC_CIDR \
  --availability-zone $SUBNET_PUBLIC_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text )
echo "  Subnet ID '$SUBNET_PUBLIC_ID' Créé dans '$SUBNET_PUBLIC_AZ'" \
echo "Availability Zone."

echo "Entrez le nom du groupe de sécurité : "
read VPC_NAME

GROUP_ID=$(aws ec2 create-security-group \
    --group-name $VPC_NAME \
    --query 'GroupId' \
    --description "Security group for SSH access" \
    --vpc-id $VPC_ID\
    --output text )

echo "Le groupe de sécurité a été créé avec l'id "$GROUP_ID

aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

echo 'Les règles ont été ajoutées'

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $IMAGE_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $GROUP_ID \
    --subnet-id $SUBNET_PUBLIC_ID \
    --user-data file://script_deploiement.sh | sudo  jq '.Instances[0].InstanceId' | sed -e 's/^"//' -e 's/"$//' )

echo "L'instance est lancée sous l'ID "$INSTANCE_ID

INSTANCE_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text )

echo "Veuillez effectuer les dernières étapes sur http://"$INSTANCE_IP