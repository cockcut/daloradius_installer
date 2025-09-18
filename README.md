# daloradius_installer
# Rocky Linux 8 minimal 버전 기준.

1) dnf -y install git httpd
2) mkdir /var/www/html/private
3) git clone https://github.com/cockcut/daloradius_installer.git private
4) cd private
5) chmod +x radius_install.sh
6) ./radius_install.sh
   6-1) MySQL/MariaDB root 비밀번호를 입력하세요:       -----> "mysql의 root 패스워드 입력후 Enter"
   6-2) Enter MySQL Host (default: localhost):        -----> "Entert입력시 기본값으로 설정"
   6-3) Enter MySQL Port (default: 3306):             -----> "Entert입력시 기본값으로 설정"
   6-4) Enter MySQL Database (default: radius):       -----> "Entert입력시 기본값으로 설정"
   6-5) Enter MySQL User (default: radius):           -----> "Entert입력시 기본값으로 설정"
   6-6) Enter MySQL Password (default: radius12#$):    -----> "Entert입력시 기본값으로 설정"

8) http://serverip/private/radius 접속
9) 초기 WEB-UI ID/비번 : administrator / radius
