#!/bin/bash
source /etc/profile
bak_path=/bak_path
[ ! -d $bak_path ] && mkdir $bak_path
for dbname in `mysql -e "show databases"|sed '1,2d'|grep -v _schema`
do
    mysqldump -B --master-data=2 ${dbname}|gzip > ${bak_path}/${dbname}_$(date +%F).sql.gz 
done