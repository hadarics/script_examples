#!/bin/bash
# Task:
#	- backup databases in one listed in ALL_DATABASES array
#	- backup all tables from databases listed in ALL_DATABASES array
#	- upload backups to Hetzner's storagebox
#
#  
# Created by:	Kálmán Hadarics
# E-mail:	hadarics.kalman@gmail.com
# Version:	1.0
# Last mod.:	2021-05-03
#
# ----------------------------------------

# Define Date and Time related variable

DATEH=$(date +%Y%m%d-%H)
DT=${DATEH:0:8}
DH=${DATEH:9:2}

# Define Backup directory

BACKUPDIR="/backup/database"

# CHECK -- Define MySQL connection parameters in ~/.my.cnf

# CHECK -- Setup sftp key based authentication

# Define storagebox parameters in e-mail format (username@boxname)
STORAGEBOX="username@username.your-storagebox.de"

# Define databases wanted to backup

ALL_DATABASES=(database01 database02 database03)

# Do the task for all databases defined earlier

for i in ${ALL_DATABASES[*]}; do

	# Define the Table dump directory

	OUT_TABLE_DIRNAME="${DT}-${DH}"
	OUT_TABLE_DIR="${BACKUPDIR}/${DT}-${DH}/${i}"

	# Create dump directory if not exists

	[ ! -e ${OUT_TABLE_DIR} ] && mkdir -p ${OUT_TABLE_DIR}

	# Define the DB dump name

	OUT_DB_FILENAME="${i}-${DT}-${DH}.sql"
	OUT_DB_FILE="${BACKUPDIR}/${OUT_TABLE_DIRNAME}/${OUT_DB_FILENAME}"

	# Do the DB dump

	nice -n19 ionice -c2 -n7 mysqldump --single-transaction --skip-lock-tables --quick ${i} > ${OUT_DB_FILE}

	# Get the tables from the actual database

	ALL_TABLES=($(echo "SHOW TABLES;" | mysql --batch --silent ${i}))


	# Do the task for all tables get earlier

	for j in ${ALL_TABLES[*]}; do
	
		# Define the Table dump filename

		OUT_TABLE_FILENAME="${j}.sql"
		OUT_TABLE_FILE="${OUT_TABLE_DIR}/${OUT_TABLE_FILENAME}"

		# Do the DB dump

		nice -n19 ionice -c2 -n7 mysqldump --single-transaction --skip-lock-tables --quick ${i} ${j} > ${OUT_TABLE_FILE}
	done
	# break
done

OUT_BACKUP_DIR="${BACKUPDIR}/${DT}-${DH}"


# Generate SHA256 sum for files

# for full database backups in one
nice -n19 ionice -c2 -n7 sha256sum ${OUT_BACKUP_DIR}/*.sql > ${OUT_BACKUP_DIR}/databases.sha256

# for all tables at database level
for i in ${ALL_DATABASES[*]}; do
	nice -n19 ionice -c2 -n7 sha256sum ${OUT_BACKUP_DIR}/${i}/*.sql > ${OUT_BACKUP_DIR}/${i}/${i}_tables.sha256
done


# Upload database backups to Storagebox

nice -n19 ionice -c2 -n7 echo "mkdir ${OUT_BACKUP_DIR}
put -r ${OUT_BACKUP_DIR} ${BACKUPDIR}" | sftp -p -q -l 51200 ${STORAGEBOX}