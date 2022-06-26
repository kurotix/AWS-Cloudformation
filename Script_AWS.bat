set/p name="Veuillez entrer le nouveau nom de votre instance : "
hostnamectl set-hostname %name%
pause

set /p names="Veuillez selectionner votre instance à modifier : "
set /p type="Veuillez choisir le type de votre instance : "

source ./change_ec2_instance_type.sh
./change_ec2_instance_type -i %names% -t %type%
pause

set /p reg="Veuillez entrer l'ID de la region : "
set /p pro="Veuillez entrer le profile avec les droit sur l'instance : "
aws configure set region %reg% --profile %pro%

set /p id="Veuillez entrer l'ID de votre instance : "

INSTANCE_IP=$(aws ec2 describe-instances --instance-ids %id% --query 'Reservations[0].Instances[0].PublicIpAddress' --output text )

echo "Votre URL est https://"$INSTANCE_IP
