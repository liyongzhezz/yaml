#!/bin/sh

scheme=http
service_name=es-logging-service
kibana_service=kibana-logging-service
port=9200
kibana_port=5601
i=1 

while [ ${i} -le 300 ]
do
es_sts=$(curl --connect-timeout 5 -m 5 -k -u elastic:$ELASTIC_PASSWORD $scheme://$service_name:$port/_cluster/health?pretty | grep status | grep green | wc -l)
kibana_sts=$(curl --connect-timeout 5 -m 5 -k -u elastic:$ELASTIC_PASSWORD -I -s $scheme://$kibana_service:$kibana_port/api/status  |head -1|cut -d" " -f2)

if [ $es_sts = '1' ] && [ $kibana_sts = '200' ]; then
    i=100000
else
    i=`expr ${i} + 1`
    sleep 1
fi
done

#设置容器日志索引
curl -u elastic:$ELASTIC_PASSWORD -X POST $scheme://$kibana_service:$kibana_port/api/saved_objects/index-pattern/k8s-log -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d "@/tmp/k8s-log.json"

#设置系统操作日志索引
curl -u elastic:$ELASTIC_PASSWORD -X POST $scheme://$kibana_service:$kibana_port/api/saved_objects/index-pattern/systemd-log -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d "@/tmp/systemd-log.json"

#设置默认索引
curl -u elastic:$ELASTIC_PASSWORD -X POST $scheme://$kibana_service:$kibana_port/api/kibana/settings/defaultIndex  -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d '{"value": "k8s-log"}'

curl -u elastic:$ELASTIC_PASSWORD -X POST $scheme://$kibana_service:$kibana_port/api/kibana/settings/search:includeFrozen -H 'Content-Type: application/json' -H "kbn-xsrf: true" -d '{"value": "true"}'

#设置EFK的生命周期
curl -k -u elastic:$ELASTIC_PASSWORD -XPUT $scheme://$service_name:$port/_ilm/policy/efk-log-policy -H "Content-Type: application/json" -d '
{
    "policy": {
    "phases": {
        "hot": {
        "min_age": "0ms",
        "actions": {
            "rollover": {
            "max_age": "1d",
            "max_size": "50gb"
            }
        }
        },
        "delete": {
        "min_age": "14d",
        "actions": {
            "delete": {}
        }
        }
    }
    }
}'