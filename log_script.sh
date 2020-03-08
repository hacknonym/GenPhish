#!/bin/bash
#coding:utf-8

#terminal text color code
grey='\e[0;37m'
yellow='\e[0;33m'
yellowb='\e[0;33;1m'

while [ true ] ; do
	for i in $(cat ident.txt | tr ' ' '_') ; do
		for j in $(echo "$i") ; do
			date=$(echo "$j" | cut -d '|' -f 1 | tr '_' ' ')
			website=$(echo "$j" | cut -d '|' -f 2 | tr '_' ' ')
			username=$(echo "$j" | cut -d '|' -f 3 | tr '_' ' ')
			password=$(echo "$j" | cut -d '|' -f 4 | tr '_' ' ')
			useragent=$(echo "$j" | cut -d '|' -f 5 | tr '_' ' ')
			ip=$(echo "$j" | cut -d '|' -f 6 | tr '_' ' ')
			geolocation=$(echo "$j" | cut -d '|' -f 7-9 | tr '_' ' ' | tr '|' ' ')
			timezone=$(echo "$j" | cut -d '|' -f 10 | tr '_' ' ')
			org=$(echo "$j" | cut -d '|' -f 11 | tr '_' ' ')
			
			echo "Date : $yellow$date$grey"
			echo "Website : $yellow$website$grey"
			echo "IP : $yellow$ip$grey"
			echo "Login : $yellowb$username$grey"
			echo "Password : $yellowb$password$grey"
			echo "User-Agent : $yellow$useragent$grey"
			echo "Geolocation : $yellow$geolocation$grey"
			echo "Timezone : $yellow$timezone$grey"
			echo "Org : $yellow$org$grey"
			echo
		done
	done
	sleep 1 && clear
done
