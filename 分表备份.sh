#!/bin/bash
source /etc/profile
bak_path=/bak_path
[ ! -d $bak_path ] && mkdir $bak_path
for dbname in `mysql -e "show databases"|sed '1,2d'|grep -v _schema`
do
    for tableName in `mysql -e "show tables from ${dbname}"|sed '1d'`
    do 
        mysqldump ${dbname} ${tableName}|gzip > ${bak_path}/${dbname}_${tableName}_$(date +%F).sql.gz 
    done
done
