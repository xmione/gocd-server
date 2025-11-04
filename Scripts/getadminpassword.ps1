# Scripts/getadminpassword.ps1
docker exec gocd-server sh -c 'printenv | grep GOCD_ADMIN_PASSWORD'