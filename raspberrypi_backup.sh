#/bin/bash
##      .SYNOPSIS
##      Simple Backup Script to extract all the valuable data from a Raspberry Pi running InfluxDB, Telegraf, and Grafana
## 
##      .DESCRIPTION
##      This Script will take the most important information from your InfluxDB, Telegraf, and Grafana components out from Raspberry Pi 
##      The Script it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  raspberrypi_backup.sh
##      ORIGINAL NAME: raspberrypi_backup.sh
##      LASTEDIT: 02/06/2020
##      VERSION: 1.0
##      KEYWORDS: Raspberry Pi, InfluxDB, Telegraf, Grafana
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

# Configurations
##

function log_title() {
   printf "|-------------------------------------------------------------------------|\n"
   printf "|$1|\n";
   printf "|-------------------------------------------------------------------------|\n"
}

## Variables
KEY=YOURAPIKEY #Create a new API key, read-only from your Grafana
HOST=http://YOURGRAFANAFQDNORIP:3000 #Use https in case you are using SSL
BACKUP_DIR="/mnt/backup" #Change it for your desired NFS mount point
DASH_DIR="dashboards"
TELEGRAF_DIR="/home/oper" #Change it for your path, where your telegraf scripts are (the ones for veeam for example, or wordpress, etc.)
TELEGRAF_CONF="/etc/telegraf"
INFLUX_CONF="/etc/influxdb"
GRAFANA_CONF="/etc/grafana"


## Grafana Dashboards Backup
counter=0
if [ ! -d $BACKUP_DIR/$DASH_DIR ] ; then
    mkdir -p $BACKUP_DIR/$DASH_DIR
fi


for dashboard_uid in $(curl -sS -k -H "Authorization: Bearer $KEY" $HOST/api/search\?query\=\& | jq -r '.[] | select( .type | contains("dash-db")) | .uid'); do 

   counter=$((counter + 1))
   url=`echo $HOST/api/dashboards/uid/$dashboard_uid | tr -d '\r'`
   dashboard_json=$(curl -sS -k -H "Authorization: Bearer $KEY" $url)
   dashboard_title=$(echo $dashboard_json | jq -r '.dashboard | .title' | sed -r 's/[ \/]+/_/g' )
   dashboard_version=$(echo $dashboard_json | jq -r '.dashboard | .version')

   echo $dashboard_json > "$BACKUP_DIR/$DASH_DIR/${dashboard_title}_v${dashboard_version}.json"

done

log_title "${counter} dashboards were saved";

## Telegraf Scripts Backup
TELEGRAF_SCRIPTS=$(rsync -ar --stats $TELEGRAF_DIR $BACKUP_DIR/scripts | awk '/files transferred/ {print $6}')

log_title "${TELEGRAF_SCRIPTS} Files have been sync";


## Telegraf, InfluxDB, and Grafana Config Backup
TELEGRAF_CN=$(rsync -ar --stats $TELEGRAF_CONF $BACKUP_DIR/config | awk '/files transferred/ {print $6}')
INFLUXDB_CN=$(rsync -ar --stats $INFLUX_CONF $BACKUP_DIR/config | awk '/files transferred/ {print $6}')
GRAFANA_CN=$(rsync -ar --stats $GRAFANA_CONF $BACKUP_DIR/config | awk '/files transferred/ {print $6}')
TOTAL_CN=$(($TELEGRAF_CN+$INFLUXDB_CN+$GRAFANA_CN))

log_title "${TOTAL_CN} Config Files have been sync";

log_title "------------------------------ FINISHED ---------------------------------";