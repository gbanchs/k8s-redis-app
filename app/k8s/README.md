kubectl create secret generic db-config --from-file=config.json  --dry-run=client -o yaml \
| kubectl  apply --force -f -

kubectl create secret generic keys --from-file="ctxr.key" --from-file="jwtRS256.key" \
--from-file="jwtRS256.key.pub" \
--from-file="private.pem" \
--dry-run=client -o yaml | kubectl  apply --force -f -

kubectl create secret generic envs --from-file=".env" \
--dry-run=client -o yaml | kubectl  apply --force -f -

kubectl create secret generic zabbix-pass --from-literal=POSTGRES_PASSWORD="6i5EMJAcs7hK" -n monitoring --dry-run=client -o yaml \
| kubectl  apply -n monitoring --force -f -


curl --location 'http://localhost:3000/api/login' --header 'Content-Type: application/json' --data-raw '{
    "email":"yg196a@telecomdistrict.com",
    "password":"123456"
}'


curl --location 'https://stg-api-new.transitxchange.cloud/api/login' --header 'Content-Type: application/json' --data-raw '{
    "email":"yg196a@telecomdistrict.com",
    "password":"123456"
}'

telnet rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com 3306

mysql -h  rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u ctxAdmin -p chopper

ssh -N -L 3306:rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com:3306 ec2-user@i-08c2f3cea122d03c2  ~/.ssh/id_bastion_ctx

URHeMvlQvKTY5Y0S


k port-forward backend-api-84ff4478b6-swwrg  3000:3000

curl localhost:3000/api/v1/healthcheck


mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u ctxAdmin -p chopper-dev < /usr/src/app/logs/dump-chopper_stg-202407301746.sql


gunzip <    ./zabbix-prod-15-08-24.sql.gz   | mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p zabbix

backend-api-18f67cb9843ff209.elb.us-east-1.amazonaws.com 

curl --location 'http://backend-api/api/login' --header 'Content-Type: application/json' --data-raw '{
    "email":"yg196a@telecomdistrict.com",
    "password":"123456"
}'




gunzip <    ./zabbix-rds-inside-01_cluster-cfyy44pyqjp6_us-east-1_rds_amazonaws_com.sql.gz   | mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p zabbix  
RDS Staging:
a5|+v.<$50$8R9#t[rxtOFKY$!|W  
mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p 



RDS prod:
I~?miu<[7jaasQyAe$h28ORx)_GO  
mysql -h rds-inside-01.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p 



# https://www.zabbix.com/forum/zabbix-help/11705-moving-zabbix-to-another-server
1. Stop Zabbix on the new and old servers
2. On the old server: mysqldump -u root -p zabbix > zab.dmp
3. Copy the dump file over to the new server
4. On the new server: mysql -u root -p zabbix < zab.dmp
5. Start Zabbix on the new server




mysqldump -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com --set-gtid-purged=OFF --single-transaction -u admin -p zabbix_new > zab_new.sql



 mysql -h rds-inside-01.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p zabbix_stg < zabbix_prod.sql





 # Prod
 mysqldump -h rds-inside-01.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com --set-gtid-purged=OFF --single-transaction -u admin -p zabbix > zabbix_prod.sql




 ##### User creation
CREATE USER 'chopperUser'@'localhost' IDENTIFIED BY 'v/e_y<;Q#K,i9Sg>kI-S8R8£';
GRANT SELECT ON chopper_stg.* TO 'chopperUser'@'localhost';



#### CHECK INFLUX
use CTX-CNT-1202302254
SELECT * FROM "network-nic-traffic-stats" WHERE "name" = 'svti-001-001' and "host" = 'CTX-CNT-D-001-001' ORDER BY time DESC limit 1


# Curl command
curl -X POST "https://api.datadoghq.com/api/v2/ci/pipeline" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: 085516710d9615462cca8893a50f760c" \
-d '{
  "data": {
    "attributes": {
        "resource": {
            "level": "pipeline",
            "unique_id": "c981e78d-ef3f-4d41-90e8-6ef5b165235c",
            "name": "Pipeline name",
            "git": {
                "repository_url": "http://provider.io/org/repo",
                "author_email": "author@org.dev",
                "sha": "cf852e17dea14008ac83036430843a1c"
            },
            "status": "success",
            "start": "2024-08-16T12:12:00-05:00",
            "end": "2024-08-16T12:12:00-05:00",
            "partial_retry": false,
            "url": "http://provider.io/pipeline/0000"
        }
    },
    "type": "cipipeline_resource_request"
  }
}'                              



# Zabbix https://www.zabbix.com/integrations/kubernetes


helm repo add datadog https://helm.datadoghq.com
helm repo update
kubectl create secret generic datadog-secret --from-literal api-key=085516710d9615462cca8893a50f760c -n monitoring



rds-inside-01-instance-1.cfyy44pyqjp6.us-east-1.rds.amazonaws.com

ssh -N -L 3306:rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com:3306  ec2-user@i-08c2f3cea122d03c2 -i ~/.ssh/db-bastion -vvv



Daniel Navas
  6:06 PM
@Gabriel Banch
 así quedó.
VPC Prod
rtb-01a12c9f0ac886374 / rt-lan-inside-srv-a
10.90.0.0/16 target pcx-0adbba5eb00a8cef1
VPC STG
rtb-05fb08e5be0642f7d / private_subnets_database-0
10.97.0.0/22 target pcx-0a30fbecd2e35a9f2
rtb-0a6acfc7d7bd1b505 / private_subnets_database-1
10.97.0.0/22 target pcx-0a30fbecd2e35a9f2
rtb-057a48e15e629908d / private_subnets_inside_pods-stg
10.97.0.0/22 target pcx-0a30fbecd2e35a9f2
rtb-02c42499849800f4e / private_subnets_dmz_pods-stg
10.97.0.0/22 target pcx-0a30fbecd2e35a9f2

  user: "zabbix"
  # -- Name of a secret used for Postgres Password, if set, it overrules the POSTGRES_PASSWORD value
  passwordSecret: "zabbix-pass"
  # -- Key of the secret used for Postgres Password, requires POSTGRES_PASSWORD_SECRET, defaults to password
  passwordSecretKey: "POSTGRES_PASSWORD"
  # -- Password of database - ignored if passwordSecret is set
  #password: "zabbix"
  # -- Name of database
  database: "zabbix"



Grafana:

kubectl create secret generic grafana-creds -n monitoring \
--from-literal=admin-user="admin" \
--from-literal=admin-password="UOFU#zEn<P$AHSRc,1v," 

admin
UOFU#zEn<P$AHSRc,1v,




mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u admin -p zabbix < ~/dumps/new/zabbix_prod.sql




kubectl create secret generic zabbix-config --from-file=zabbix_server.conf  -n monitoring --dry-run=client -o yaml \
| kubectl  apply -n monitoring --force -f -


kubectl create cm generic zabbix-config --from-file=zabbix_server.conf  -n monitoring --dry-run=client -o yaml \
| kubectl  apply -n monitoring --force -f -




kubectl create secret generic zabbix-db-creds -n monitoring \
--from-literal=DB_SERVER_PORT="3306" \
--from-literal=MYSQL_DATABASE="zabbix_test" \
--from-literal=MYSQL_USER="zabbix_user" \
--from-literal=MYSQL_PASSWORD='a5|+v.<$50$8R9' \
--from-literal=DB_SERVER_HOST_WRITE="rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com" \
--from-literal=DB_SERVER_HOST="rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com"  \
--dry-run=client -o yaml  | kubectl -n monitoring apply --force -f -

Password DB dev:
admin
77pIoGx+d0[JG1LN0UON?sH-cFjX


# ZABBIX
http://10.197.0.6/



 kubectl port-forward service/zabbix-zabbix-web 8888:80 -n monitoring

 https://pushkar-sre.medium.com/solved-aws-rds-import-you-need-super-privilege-s-71e350b41989

 perl -pe 's/\sDEFINER=`[^`]+`@`[^`]+`//' <  dump-zabbix-202408061140.sql > dump.fixed.sql




mysqldump -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com \
          -u admin  \
          -p zabbix \
          --no-tablespaces \
          --databases zabbix \
          > dump-zabbix-202408061140.sql 

          


          k rollout restart deploy/zabbix-zabbix-webservice deploy/zabbix-zabbix-server deploy/zabbix-zabbix-web -n  monitoring




      gunzip <    ./zabbix-prod-15-08-24.sql.gz   | mysql -h rds-ctx-aurora-stg.cluster-cfyy44pyqjp6.us-east-1.rds.amazonaws.com -u zabbix_user -p zabbix    




      zabbix-zabbix-web


## Import subnets prod

sn-private-lan-dmz-nodes-a  subnet-01adfa346021e8a16  Available  vpc-07bd33c9e2adff49a | ctx-ng-vpc  10.97.3.128/25  

sn-private-lan-dmz-nodes-b  subnet-08b0ea306c85544ff  Available  vpc-07bd33c9e2adff49a | ctx-ng-vpc  10.97.67.128/25  

terraform import module.base.module.vpc.aws_subnet.ctx["us-east-1a-sn-private-lan-dmz-nodes-a"] subnet-01adfa346021e8a16

terraform import module.base.module.vpc.aws_subnet.ctx["us-east-1b-sn-private-lan-dmz-nodes-b"] subnet-08b0ea306c85544ff



terraform import  module.base.module.vpc.aws_subnet.ctx["us-east-1b-sn-private-lan-dmz-lb-b"] subnet-09218a25d697824e2

terraform import  module.base.module.vpc.aws_subnet.ctx["us-east-1a-sn-private-lan-dmz-lb-a"] subnet-01c29d16fe73315c2




aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=vpc-07bd33c9e2adff49a



### Datadog Setup

https://docs.datadoghq.com/database_monitoring/setup_mysql/aurora/?tab=mysql57

CREATE USER datadog@'%' IDENTIFIED by 'vYrsu8EDb4MR9Ry';
ALTER USER datadog@'%' WITH MAX_USER_CONNECTIONS 5;
GRANT REPLICATION CLIENT ON *.* TO datadog@'%';
GRANT PROCESS ON *.* TO datadog@'%';
GRANT SELECT ON performance_schema.* TO datadog@'%';
FLUSH PRIVILEGES;