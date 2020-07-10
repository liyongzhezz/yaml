#!/bin/sh
scheme=http
service_name=es-logging-service
port=9200
i=1 
while [ ${i} -le 300 ]
do
es_sts=$(curl --connect-timeout 5 -m 5 -k -u elastic:$ELASTIC_PASSWORD $scheme://$service_name:$port/_cluster/health?pretty | grep status | grep green | wc -l)
if [ $es_sts = '1' ]; then
  i=100000
else
  i=`expr ${i} + 1`
  sleep 1
fi
done

curl -u elastic:$ELASTIC_PASSWORD -XPOST "$scheme://$service_name:$port/_security/user/kibana/_password"  -H 'Content-Type: application/json' -d'
{
 "password" : "'"$ELASTIC_PASSWORD"'"
}'


curl -u elastic:$ELASTIC_PASSWORD -XDELETE "$scheme://$service_name:$port/_xpack/security/user/kibana_nginx"
curl -u elastic:$ELASTIC_PASSWORD -XDELETE "$scheme://$service_name:$port/_xpack/security/role/kibana_nginx"
curl -u elastic:$ELASTIC_PASSWORD -XDELETE "$scheme://$service_name:$port/_xpack/security/user/ipaas_kibana_oauth"
curl -u elastic:$ELASTIC_PASSWORD -XDELETE "$scheme://$service_name:$port/_xpack/security/role/ipaas_kibana_oauth"

curl -k -u elastic:$ELASTIC_PASSWORD -XPOST "$scheme://$service_name:$port/_xpack/security/role/kibana_nginx" -H 'Content-Type: application/json' -d'
{ 
 "run_as": ["ipaas_kibana_oauth"]
}'

curl -k -u elastic:$ELASTIC_PASSWORD -XPOST "$scheme://$service_name:$port/_xpack/security/user/kibana_nginx" -H 'Content-Type: application/json' -d'
{
 "password" : "secretpassword", 
 "roles" : ["kibana_nginx"], 
 "full_name" : "Kibana Nginx Account"
}'

curl -k -u elastic:$ELASTIC_PASSWORD -XPOST "$scheme://$service_name:$port/_xpack/security/role/ipaas_kibana_oauth" -H 'Content-Type: application/json' -d'
{
  "run_as": [ ],
  "cluster": [ "monitor" ],
  "indices": [
    {
      "names": [ "*" ],
      "privileges": [ "read", "monitor", "view_index_metadata" ],
      "field_security" : {
        "grant" : [ "*" ]
      },
	  "allow_restricted_indices" : false
    }
  ],
  "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_discover.read",
          "feature_visualize.all",
          "feature_dashboard.all",
          "feature_dev_tools.all",
          "feature_advancedSettings.read",
          "feature_indexPatterns.all",
          "feature_apm.all",
          "feature_logs.read",
          "feature_infrastructure.read",
          "feature_uptime.read",
          "feature_siem.read",
          "feature_canvas.all",
          "feature_maps.all",
          "feature_graph.all",
          "feature_savedObjectsManagement.all"
        ],
        "resources" : [
          "*"
        ]
      }
  ]
}'

curl -k -u elastic:$ELASTIC_PASSWORD -XPOST "$scheme://$service_name:$port/_xpack/security/user/ipaas_kibana_oauth" -H 'Content-Type: application/json' -d'
{
 "password" : "'"$ELASTIC_PASSWORD"'", 
 "roles" : ["ipaas_kibana_oauth"], 
 "full_name" : "iPaaS Kibana Oauth"
}'