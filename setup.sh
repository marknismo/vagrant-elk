#!/usr/bin/env bash
# Created by: Mark C.

#create directories
mkdir -p /home/vagrant/elasticshare/apache-access
mkdir -p /home/vagrant/elasticshare/els
mkdir -p /home/vagrant/logstash_sincedb


#install elasticsearch
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install apt-transport-https -y
sudo apt-get install openjdk-8-jre-headless -y
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.1.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.1.deb.sha512
shasum -a 512 -c elasticsearch-6.5.1.deb.sha512 
sudo dpkg -i elasticsearch-6.5.1.deb
echo "network.host: 0.0.0.0" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service


#install elasticsearch plugin
cd /usr/share/elasticsearch/
sudo bin/elasticsearch-plugin install -b ingest-geoip
sudo bin/elasticsearch-plugin install -b ingest-user-agent
sudo /bin/systemctl stop elasticsearch.service
sudo /bin/systemctl start elasticsearch.service


#install logstash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt-get update && sudo apt-get install logstash
sudo chown logstash:vagrant /home/vagrant/logstash_sincedb
sudo chmod 777 /usr/share/logstash/data
sudo mv /home/vagrant/elasticshare/logstash.conf /etc/logstash/conf.d/
echo "path.config: \"/etc/logstash/conf.d/*\"" | sudo tee -a /etc/logstash/logstash.yml
cd /home/vagrant/elasticshare
curl -XPUT -H "Content-type: application/json" http://127.0.0.1:9200/_template/apache-access_template?pretty -d @apache-access_template.json
curl -XPUT -H "Content-type: application/json" http://127.0.0.1:9200/_template/els_template?pretty -d @els_mapping_template.json
rm /home/vagrant/elasticshare/*_template.json
sudo /bin/systemctl enable logstash.service
sudo /bin/systemctl start logstash.service



#install Kibana
sudo apt-get install kibana -y
echo "server.host: 0.0.0.0" | sudo tee -a /etc/kibana/kibana.yml
sudo mkdir -p /var/log/kibana
sudo chown -R kibana:kibana /var/log/kibana
echo "logging.dest: /var/log/kibana/kibana.log" | sudo tee -a /etc/kibana/kibana.yml
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo /bin/systemctl start kibana.service


#install jq
sudo apt-get install jq -y