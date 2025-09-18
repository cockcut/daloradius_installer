#!/bin/bash

# ===============================================
# daloRADIUS 자동 설치 스크립트 (Rocky 8)
# EAP 및 Accounting, 인증서 설정 포함
# ===============================================

# --- 필수 변수 설정 ---
DALORADIUS_ZIP="daloradius-1.1-2.zip"
DALORADIUS_URL="https://downloads.sourceforge.net/project/daloradius/daloradius/${DALORADIUS_ZIP}"
WEB_ROOT="."
freeradius_path="/etc/raddb"

# --- 1. 필수 패키지 설치 ---
echo "--- 1. 필수 패키지 설치 중..."
dnf -y install freeradius freeradius-mysql freeradius-utils mysql mysql-server httpd php php-mysqlnd php-gd php-ldap php-pear php-xml unzip wget openssl
pear install DB

# --- 2. daloRADIUS 파일 다운로드 및 압축 해제 ---
echo "--- 2. daloRADIUS 파일 다운로드 및 압축 해제 중..."
if [ ! -f "${DALORADIUS_ZIP}" ]; then
    echo "--- ${DALORADIUS_ZIP} 파일이 존재하지 않아 다운로드합니다."
    wget "${DALORADIUS_URL}"
else
    echo "--- ${DALORADIUS_ZIP} 파일이 이미 존재합니다. 다운로드를 건너뜁니다."
fi

rm -rf "${WEB_ROOT}/daloradius"
rm -rf "${WEB_ROOT}/radius"
unzip "${DALORADIUS_ZIP}"
rm -rf "__MACOSX"
mv "${WEB_ROOT}/daloradius" "${WEB_ROOT}/radius"

# --- 3. MySQL/MariaDB 데이터베이스 설정 ---
echo "--- 3. MySQL/MariaDB 데이터베이스 설정 중..."
systemctl start mysqld
systemctl enable mysqld

read -sp "MySQL/MariaDB root 비밀번호를 입력하세요: " MYSQL_ROOT_PASSWORD
echo ""
read -p "Enter MySQL Host (default: localhost): " input_host
MYSQL_HOST=${input_host:-"localhost"}
read -p "Enter MySQL Port (default: 3306): " input_port
MYSQL_PORT=${input_port:-"3306"}
read -p "Enter MySQL Database (default: radius): " input_db
MYSQL_DATABASE=${input_db:-"radius"}
read -p "Enter MySQL User (default: radius): " input_user
MYSQL_USER=${input_user:-"radius"}
read -s -p "Enter MySQL Password (default: radius12#$): " input_pw
MYSQL_PASSWORD=${input_pw:-"radius12#$"}
echo ""


# MySQL root 비밀번호 접속 테스트
if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" &> /dev/null; then
    echo "정보: MySQL root 비밀번호 접속에 실패했습니다. 초기 설정을 시도합니다."
    
    # MariaDB 초기 설정 (이전 오류 해결)
    # MariaDB 설치 후 초기 비밀번호가 없는 상태에서 root 비밀번호를 설정
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
    if [ $? -ne 0 ]; then
        echo "오류: MySQL/MariaDB root 비밀번호 설정에 실패했습니다. 스크립트를 종료합니다."
        exit 1
    fi
    echo "MySQL/MariaDB root 비밀번호 설정 완료."
else
    echo "정보: MySQL root 비밀번호 접속에 성공했습니다. 초기 설정을 건너뜁니다."
fi

# 데이터베이스와 사용자 생성
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'${MYSQL_HOST}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
echo "MySQL/MariaDB database와 사용자 생성 완료."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" ${MYSQL_DATABASE} < "${WEB_ROOT}/radius/contrib/db/fr2-mysql-daloradius-and-freeradius.sql"
echo "MySQL/MariaDB database 적용 완료."

# --- 4. EAP 인증서 설정 ---
echo "--- 4. EAP 인증서 설정 중..."
sudo sed -i -E 's/^(default_days\s*=\s*)(.*)$/\13650/' ${freeradius_path}/certs/server.cnf
sudo sed -i -E 's/^(default_days\s*=\s*)(.*)$/\13650/' ${freeradius_path}/certs/ca.cnf
cd $freeradius_path/certs
rm -f *.pem *.der *.csr *.crt *.key *.p12 serial* index.txt*
./bootstrap
chmod -R 755 $freeradius_path/certs/
cd -

# --- 5. FreeRADIUS 설정 (EAP & Accounting 포함) ---
echo "--- 5. FreeRADIUS 설정 중..."
\cp -f ./sql ${freeradius_path}/mods-enabled/
#sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' ${freeradius_path}/mods-available/sql
#sed -i 's|dialect = "sqlite"|dialect = "mysql"|' ${freeradius_path}/mods-available/sql
sed -i 's|dialect = ${modules.sql.dialect}|dialect = "mysql"|' ${freeradius_path}/mods-available/sqlcounter
#sed -i 's|#\s*read_clients = yes|read_clients = yes|' ${freeradius_path}/mods-available/sql
#sed -i 's|^#\s*server = .*|server = "'$MYSQL_HOST'"|' ${freeradius_path}/mods-available/sql
#sed -i 's|^#\s*port = .*|port = "'$MYSQL_PORT'"|' ${freeradius_path}/mods-available/sql
#sed -i '1,$s/radius_db.*/radius_db="'$MYSQL_DATABASE'"/g' ${freeradius_path}/mods-available/sql
#sed -i 's|^#\s*password = .*|password = "'$MYSQL_PASSWORD'"|' ${freeradius_path}/mods-available/sql
#sed -i 's|^#\s*login = .*|login = "'$MYSQL_USER'"|' ${freeradius_path}/mods-available/sql
#sed -i 's#/etc/ssl#/etc/raddb#g' ${freeradius_path}/mods-available/sql
#sed -i 's#/etc/raddb/certs/private#/etc/raddb/certs#g' ${freeradius_path}/mods-available/sql
sed -i 's/-sql/sql/g' ${freeradius_path}/sites-available/default
sed -i '/^#\s*update request {/,/^#\s*}/s/^#\s*//' ${freeradius_path}/sites-available/default
ln -s ${freeradius_path}/mods-available/sql ${freeradius_path}/mods-available/sql
ln -s ${freeradius_path}/mods-available/sqlcounter ${freeradius_path}/mods-enabled/sqlcounter
ln -s ${freeradius_path}/mods-available/sqlippool ${freeradius_path}/mods-enabled/sqlippool

# --- 6. daloRADIUS 설정 ---
echo "--- 6. daloRADIUS 설정 중..."
#sed -i "s/\$configValues\['CONFIG_DB_ENGINE'\] = '.*';/\$configValues\['CONFIG_DB_ENGINE'\] = 'mysqli';/" "${WEB_ROOT}/radius/library/daloradius.conf.php"
sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = '.*';/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" "${WEB_ROOT}/radius/library/daloradius.conf.php"
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = '.*';/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" "${WEB_ROOT}/radius/library/daloradius.conf.php"
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = '.*';/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" "${WEB_ROOT}/radius/library/daloradius.conf.php"
sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = '.*';/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" "${WEB_ROOT}/radius/library/daloradius.conf.php"
chown -R apache:apache "${WEB_ROOT}/radius"
chmod -R 775 "${WEB_ROOT}/radius"

# --- 7. daloRADIUS에 NAS 추가후 radius 재시작 버튼 추가하기 위한 파일 수정 ---
echo "--- 7. menu-mng-rad-nas.php, mng-rad-nas.php 수정중..."
cp -f ./menu-mng-rad-nas.php ./radius
cp -f ./mng-rad-nas.php ./radius

# --- 8. 서비스 시작 및 방화벽 설정 ---
echo "--- 8. 서비스 시작 및 방화벽 설정 중..."
systemctl start httpd
systemctl enable httpd
systemctl restart radiusd
systemctl enable radiusd
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --add-port=1812/udp --permanent
firewall-cmd --add-port=1813/udp --permanent
firewall-cmd --reload

echo "==============================================="
echo "✅ daloRADIUS 설치가 완료되었습니다!"
echo "웹 브라우저에서 아래 주소로 접속하세요:"
echo "    http://<서버_IP_주소>/radius"
echo ""
echo "기본 로그인 정보:"
echo "    - 사용자명: administrator"
echo "    - 비밀번호: radius"
echo "==============================================="
