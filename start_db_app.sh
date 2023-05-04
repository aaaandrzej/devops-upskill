#!/bin/bash

source .env

sudo apt-get update

# below is needed if we want to host mysql locally
#sudo apt-get -y install mysql-server
#sudo mysql --defaults-file=/etc/mysql/debian.cnf -e "CREATE DATABASE ${DB_NAME};USE ${DB_NAME};CREATE TABLE Users (UserID int, LastName varchar(255), FirstName varchar(255));INSERT INTO Users (UserID, LastName, FirstName) VALUES (1, 'Placek', 'Jacek'),(2, 'Niejadek', 'Tadek'),(3, 'Awaria', 'Maria');"
#sudo mysql --defaults-file=/etc/mysql/debian.cnf -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';GRANT ALL ON *.* TO '${DB_USER}'@'localhost';GRANT ALL ON *.* TO '${DB_USER}'@'%';FLUSH PRIVILEGES;"

# below is needed  only if we want to allow external traffic into the db
#sudo sed -i -e '/127.0.0.1/s/^/#/' /etc/mysql/mysql.conf.d/mysqld.cnf
#sudo service mysql restart

sudo apt-get -y install python3-pip uvicorn
pip3 install fastapi[all] mysql-connector-python python-dotenv

uvicorn src/app-db:app --host 0.0.0.0 --port 8000