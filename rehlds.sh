#!/bin/bash
# Counter Strike 1.6 serverio instaliacijos skriptas
# Autorius: aaarnas (nebeaktyvus)
# Isplestinis palaikymas: SAIMON
# amxmodx.lt (nebeaktyvus)
# saimon.lt

# 5.8.1 - fix for curl package missing.
# 6.0 - port choosing enabled.

VERSION=6.0

SCRIPT_NAME=`basename $0`
MAIN_DIR=$( getent passwd "$USER" | cut -d: -f6 )

SERVER_DIR="rehlds"
INSTALL_DIR="$MAIN_DIR/$SERVER_DIR"

VERSION_ID=$(awk -F= '$1 == "VERSION_ID" {gsub(/"/, "", $2); print $2}' /etc/os-release)
ID=$(awk -F= '$1 == "ID" {gsub(/"/, "", $2); print $2}' /etc/os-release)

if [[ "$ID" == "debian" ]] && [[ "$VERSION_ID" -ge 11 ]]; then
    bits_lib_32="lib32gcc-s1"
else
    bits_lib_32="lib32gcc1"
fi

rehlds_url=$(wget -qO - https://img.shields.io/github/v/release/dreamstalker/rehlds.svg | grep -oP '(?<=release: v)[0-9.]*(?=<\/title>)')
regamedll_url=$(wget -qO - https://img.shields.io/github/release/s1lentq/ReGameDLL_CS.svg | grep -oP '(?<=release: v)[0-9.]*(?=<\/title>)')
metamodr_url=$(wget -qO - https://img.shields.io/github/release/theAsmodai/metamod-r.svg | grep -oP '(?<=release: v)[0-9.]*(?=<\/title>)')

#reunion version
reunion_version=$(wget -qO - https://img.shields.io/github/v/release/s1lentq/reunion.svg | grep -oP '(?<=release: v)[0-9.]*(?=<\/title>)')

#amxx build number
amxx_build_url='https://www.amxmodx.org/downloads-new.php?branch=master&all=1'
html=$(curl -s "$amxx_build_url")
amxx_build_version=$(echo "$html" | grep -oP '<strong>\K[0-9]+\.[0-9]+ - build \K[0-9]+' | awk '{print $1""$2}')

ip_url="https://api.ipify.org"

echo "-------------------------------------------------------------------------------"
echo "Counter Strike 1.6 serverio instaliacija"
echo "-------------------------------------------------------------------------------"
echo "Special thanks to: saimon.lt project"
echo "-------------------------------------------------------------------------------"

# generate reunion salt's to work normally.
generate_random_string() {
  local length=$1
  tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $length
}

check_version() {
	echo "Tikrinama diegimo irankio versija..."
	LATEST_VERSION=`wget -qO - https://raw.githubusercontent.com/lukasenka/rehlds-installer/main/rehlds.sh | grep "VERSION=[0-9]"`
	
	if [ -z $LATEST_VERSION ]; then
		echo "Klaida: Nepavyko patikrinti naujausios versijos is serverio. Nutraukiama..."
		exit 1
	fi
	
	if [ "VERSION=$VERSION" != $LATEST_VERSION ]; then
		echo "Yra nauja diegimo irankio versija. Atsiunciama..."
		wget -q -O installcs.tempfile https://raw.githubusercontent.com/lukasenka/rehlds-installer/main/rehlds.sh
		if [ ! -e "installcs.tempfile" ]; then
			echo "Klaida: Nepavyko gauti naujos diegimo irankio versijos is serverio..."
			exit 1
		fi
		
		mv $SCRIPT_NAME _installcs.old
		mv installcs.tempfile rehlds.sh
		chmod +x rehlds.sh
		rm _installcs.old
		echo "Atnaujinta i naujausia versija! Paleiskite ./rehlds.sh komanda dar karta"
		exit
	else
		echo "Naudojate naujausia $VERSION versija"
	fi
}
check_packages() {
	
	BIT64_CHECK=false && [ $(getconf LONG_BIT) == "64" ] && BIT64_CHECK=true
	LIB_CHECK=false && [ "`(dpkg --get-selections $bits_lib_32 | egrep -o \"(de)?install\") 2> /dev/null`" = "install" ] && LIB_CHECK=true
	SCREEN_CHECK=false && [ "`(dpkg --get-selections screen | egrep -o \"(de)?install\") 2> /dev/null`" = "install" ] && SCREEN_CHECK=true
 	UNZIP_CHECK=false && [ "`(dpkg --get-selections unzip | egrep -o \"(de)?install\") 2> /dev/null`" = "install" ] && UNZIP_CHECK=true
  	CURL_CHECK=false && [ "`(dpkg --get-selections curl | egrep -o \"(de)?install\") 2> /dev/null`" = "install" ] && CURL_CHECK=true
	
        if ($BIT64_CHECK && ! $LIB_CHECK) || ! $SCREEN_CHECK || ! $UNZIP_CHECK || ! $CURL_CHECK; then
		echo "-------------------------------------------------------------------------------"
		echo "Serveryje truksta instaliacijai reikiamu paketu"
				if [[ $(id -u) -ne 0 ]] ; then
                    echo "Kad instaliuoti trukstamus paketus, sis skriptas turi buti paleistas naudojantis"
					echo "root vartotoju arba su sudo komanda:"
					echo "sudo ./$SCRIPT_NAME"
					exit 1
				fi

		echo -e "Bus paleistos sios komandos:\n"
		echo "apt-get update"
		if $BIT64_CHECK && ! $LIB_CHECK; then
                                echo "apt-get -y install $bits_lib_32"
		fi
  
		if ! $SCREEN_CHECK; then
		echo "apt-get -y install screen"
		fi
  
  		if ! $UNZIP_CHECK; then
		echo "apt-get -y install unzip"
		fi

    		if ! $CURL_CHECK; then
		echo "apt-get -y install curl"
		fi
  
		echo -e "\nInstaliuoti?"
		echo "1. Taip"
		echo "2. Iseiti"
		read -p "Iveskite pasirinkta punkta: " NUMBER
	
		case "$NUMBER" in
		"1")
                        apt-get -y update

			if $BIT64_CHECK && ! $LIB_CHECK; then
                                apt-get -y install $bits_lib_32
			fi
  
			if ! $SCREEN_CHECK; then
				apt-get -y install screen
			fi

   			if ! $UNZIP_CHECK; then
				apt-get -y install unzip
			fi

      			if ! $CURL_CHECK; then
				apt-get -y install curl
			fi
			;;
		*)
			echo "Ate" 
			exit 0
			;;
		esac
	fi
}

check_dir() {
	echo "-------------------------------------------------------------------------------"
	if [ -e $INSTALL_DIR ]; then

 		if [ "$UPDATE" != 1 ] || [ "$UPDATE_RDLL" != 1 ]; then
  		echo "Serveri ketinta instaliuoti i '$INSTALL_DIR' direktorija, bet ji jau sukurta"
    		NUMBER=1
    		until [ ! -e "$INSTALL_DIR" ]; do
        		((NUMBER++))
        		INSTALL_DIR="$MAIN_DIR/$SERVER_DIR$NUMBER"
    		done
		else
			if screen -list | grep -q "$SERVER_DIR"; then
				screen -S $SERVER_DIR -p 0 -X stuff "amxx version$(printf '\r')"
				screen -S $SERVER_DIR -p 0 -X stuff "meta version$(printf '\r')"
				screen -S $SERVER_DIR -p 0 -X stuff "version$(printf '\r')"
				screen -S $SERVER_DIR -p 0 -X stuff "game version$(printf '\r')"
				screen -S $SERVER_DIR -X hardcopy $INSTALL_DIR/output.txt

				screen -S $SERVER_DIR -p 0 -X stuff "meta list$(printf '\r')"
				screen -S $SERVER_DIR -X hardcopy $INSTALL_DIR/output2.txt

				amxx_version=$(grep "AMX Mod X" $INSTALL_DIR/output.txt | awk '{print $4}')
				if [ -z "$amxx_version" ]; then
    					amxx_version="null"
				fi

				meta_version=$(grep "Metamod-r v" $INSTALL_DIR/output.txt | awk '{print $2 " " $3}')
				if [ -z "$meta_version" ]; then
    					meta_version="null"
				fi

				rehlds_version=$(grep "ReHLDS version" $INSTALL_DIR/output.txt | awk '{print $3}')
				if [ -z "$rehlds_version" ]; then
    					rehlds_version="null"
				fi

				my_reunion_version=$(awk '$3 == "Reunion" {print $7}' "$INSTALL_DIR/output2.txt")
				if [ -z "$my_reunion_version" ]; then
    					my_reunion_version="null"
				fi
			else
				amxx_version="OFFLINE"
				meta_version="OFFLINE"
				rehlds_version="OFFLINE"
				my_reunion_version="OFFLINE"
				
			fi

      		fi
      
		echo "Instaliuoti i '$INSTALL_DIR'?"
		echo "1. Taip"
		echo "2. Noriu nurodyti kita direktorija"
		read -p "Iveskite pasirinkta punkta: " MENU_NUMBER
	
		case "$MENU_NUMBER" in
		"1")
			SERVER_DIR="$SERVER_DIR$NUMBER"
			return 0
			;;
		"2")
			read -p "Norima direktorija: $MAIN_DIR/" SERVER_DIR
			INSTALL_DIR="$MAIN_DIR/$SERVER_DIR"
			check_dir
			;;
   		*)
			echo "Ate" 
			exit 0
			;;
		esac
	else
		echo "Instaliuoti serveri i '$INSTALL_DIR'?"
		echo "1. Taip"
		echo "2. Noriu nurodyti kita direktorija"
		echo "3. Iseiti"
		read -p "Iveskite pasirinkta punkta: " MENU_NUMBER
		
		case "$MENU_NUMBER" in
		"1")
			rm -f output2.txt
			rm -f output.txt
			return 0
			;;
		"2")
			read -p "Norima direktorija: $MAIN_DIR/" SERVER_DIR
			INSTALL_DIR="$MAIN_DIR/$SERVER_DIR"
			check_dir
			;;
		*)
			echo "Ate" 
			exit 0
			;;
		esac
	fi
}

check_app90_version()
{
	echo "[SteamCMD] Just a minute ...";
 	sleep 2

	STEAMCMD_PATH="$INSTALL_DIR/steamcmd/steamcmd.sh"
	VERSION_FILE="$INSTALL_DIR/steamcmd/app90_version.txt"

	APP_ID=90

	get_current_version() {
    		$STEAMCMD_PATH +login anonymous +app_info_update 1 +app_info_print $APP_ID +quit | grep -A 5 '"branches"' | grep -m 1 '"buildid"' | grep -oP '\d+'
	}

	CURRENT_VERSION=$(get_current_version)

	if [[ -f "$VERSION_FILE" ]]; then
    		STORED_VERSION=$(cat "$VERSION_FILE")
	else
    		STORED_VERSION=""
	fi

	if [[ "$CURRENT_VERSION" != "$STORED_VERSION" ]]; then
    		echo "[SteamCMD] New version detected for app $APP_ID: $CURRENT_VERSION"
    		echo "$CURRENT_VERSION" > "$VERSION_FILE"

      		echo "[SteamCMD] Installing new version... Please wait."

      		cd $INSTALL_DIR/steamcmd

		./steamcmd.sh +force_install_dir $INSTALL_DIR +login anonymous +app_update 90 -beta steam_legacy validate +quit

		EXITVAL=$?
		if [ $EXITVAL -gt 0 ]; then
			echo "-------------------------------------------------------------------------------"
			echo "SteamCMD vidine klaida. Klaidos kodas: $EXITVAL"
			echo "Instaliacija nutraukiama..."
        		exit 1
		fi

  		if [ $(($INSTALL_TYPE&$SYSTEM_STEAMCMD)) != 0 ]; then

		echo "[SteamCMD] [WARNING] Testas baigesi sekmingai, taciau reikia is naujo sudiegti ReHLDS ir ReGameDLL (jei toks buvo).";
		sleep 2

		cd $INSTALL_DIR

		echo "Instaliuojamas ReHLDS v. ${rehlds_url} ..."

		wget https://github.com/dreamstalker/rehlds/releases/download/${rehlds_url}/rehlds-bin-${rehlds_url}.zip
		unzip rehlds-bin-${rehlds_url}.zip
		rm -rf hlsdk

		mv $INSTALL_DIR/bin/linux32/valve/dlls/director.so $INSTALL_DIR/valve/dlls/directors.so
		cd $INSTALL_DIR/valve/dlls
		rm director.so
		mv directors.so director.so

		cd $INSTALL_DIR/bin/linux32
		mv proxy.so $INSTALL_DIR/proxys.so
		cd $INSTALL_DIR
		rm proxy.so
		mv proxys.so proxy.so

		cd $INSTALL_DIR/bin/linux32
		mv hltv $INSTALL_DIR/hltvs
		cd $INSTALL_DIR
		rm hltv
		mv hltvs hltv

		cd $INSTALL_DIR/bin/linux32
		mv demoplayer.so $INSTALL_DIR/demoplayers.so
		cd $INSTALL_DIR
		rm demoplayer.so
		mv demoplayers.so demoplayer.so

		cd $INSTALL_DIR/bin/linux32
		mv core.so $INSTALL_DIR/cores.so
		cd $INSTALL_DIR
		rm core.so
		mv cores.so core.so

		cd $INSTALL_DIR/bin/linux32
		mv hlds_linux $INSTALL_DIR/hlds_linuxs
		cd $INSTALL_DIR
		rm hlds_linux
		mv hlds_linuxs hlds_linux
		chmod +x hlds_linux

		cd $INSTALL_DIR/bin/linux32
		mv engine_i486.so $INSTALL_DIR/engine_i486s.so
		cd $INSTALL_DIR
		rm engine_i486.so
		mv engine_i486s.so engine_i486.so
		rm -rf bin
		rm rehlds-bin-${rehlds_url}.zip
		echo "Rehlds v. ${rehlds_url} diegimas sekmingas."

		if [ -d "cstrike/game.cfg" ]; then
			cd $INSTALL_DIR/cstrike
   
			if [ -e "game.cfg" ]; then
    				rm game.cfg
			fi

			if [ -e "game_init.cfg" ]; then
    				rm game_init.cfg
			fi

			if [ -e "delta.lst" ]; then
    				rm delta.lst
			fi

			cd $INSTALL_DIR

			echo "instaliuojamas ReGameDLL v. ${regamedll_url}..."
			sleep 2
			cd $INSTALL_DIR
			wget https://github.com/s1lentq/ReGameDLL_CS/releases/download/${regamedll_url}/regamedll-bin-${regamedll_url}.zip
   
			if [ ! -e "regamedll-bin-${regamedll_url}.zip" ]; then
				echo "Klaida: Nepavyko gauti ReGameDLL failu is serverio. Nutraukiama..."
				exit 1
			fi
   
			unzip regamedll-bin-${regamedll_url}.zip
			rm -rf cssdk
			cd $INSTALL_DIR/bin/linux32/cstrike/dlls
			mv cs.so $INSTALL_DIR/cstrike/dlls/css.so
			cd $INSTALL_DIR/cstrike/dlls
			rm cs.so
			mv css.so cs.so
			cd $INSTALL_DIR/bin/linux32/cstrike
			mv game_init.cfg $INSTALL_DIR/cstrike
			mv game.cfg $INSTALL_DIR/cstrike
			mv delta.lst $INSTALL_DIR/cstrike
			cd $INSTALL_DIR
			rm -rf bin
			rm regamedll-bin-${regamedll_url}.zip
	fi

fi
  
else
    	echo "[SteamCMD] Version has not changed for app $APP_ID: $CURRENT_VERSION"
fi
}


check_version
check_packages

#------------
UPDATE=0
UPDATE_RDLL=0

echo "Pasirinkite:"
echo "1. Serverio instaliacija [SERVER INSTALL]"
echo "2. Serverio atnaujinimas [SERVER UPDATE]"
echo "3. Iseiti"
read -p "Iveskite pasirinkta punkta: " MENU_NUMBER

case "$MENU_NUMBER" in
"1")
	check_dir
	;;
"2")
	UPDATE=1
	UPDATE_RDLL=1
 	check_dir
	;;
	
*)
	echo "Ate" 
	exit 0
	;;
esac


METAMOD=$((1<<0))
DPROTO=$((1<<1))
AMXMODX=$((1<<2))
CHANGES=$((1<<3))
REGAMEDLL=$((1<<4))
SYSTEM_STEAMCMD=$((1<<5))

if [ "$UPDATE" -eq 0 ] || [ "$UPDATE_RDLL" -eq 0 ]; then
echo "-------------------------------------------------------------------------------"
echo "Pasirinkite modifikacijas, kurios bus instaliuotos."
echo "-------------------------------------------------------------------------------"
echo "([modifikacija] | (serverio tipas)):"
echo "1. [rehlds][metamod-r][reunion][amxmodx] | (steam / non-steam) (Rekomenduojama)"
echo "2. [rehlds][metamod-r][reunion][amxmodx] + ReGameDLL | (steam / non-steam)"
echo "-------------------------------------------------------------------------------"
else
echo "-------------------------------------------------------------------------------"
echo "            [rehlds]                              [metamod-r]                  "
echo "-------------------------------------------------------------------------------"
echo "$rehlds_version -> $rehlds_url-dev |  $meta_version -> v$metamodr_url, API"
echo "-------------------------------------------------------------------------------"
echo "            [reunion]         [amxmodx]            	     "
echo "-------------------------------------------------------------------------------"
echo "$my_reunion_version -> v$reunion_version | $amxx_version -> 1.10.0.$amxx_build_version"
echo "-------------------------------------------------------------------------------"
echo "--- Pasirinkite modifikacijas, kurios bus atnaujintos: ------------------------"
echo "([modifikacija] | (serverio tipas)):"
echo "1. [--> UPDATE <-- ] [rehlds][metamod-r][reunion][amxmodx] | (steam / non-steam)"
echo "2. [--> UPDATE <-- ] [rehlds][metamod-r][reunion][amxmodx] + ReGameDLL | (steam / non-steam)"
echo "-------------------------------------------------------------------------------"
echo "3. [--> UPDATE <-- ] Sistemos failu naujinys [SteamCMD] / System files update [SteamCMD only]"
echo "-------------------------------------------------------------------------------"
fi
read -p "Iveskite pasirinkta punkta: " NUMBER

INSTALL_TYPE=0
case "$NUMBER" in
"1")
	if [ "$UPDATE" -eq 0 ] || [ "$UPDATE_RDLL" -eq 0 ]; then
	INSTALL_TYPE=$(($INSTALL_TYPE|$METAMOD))
	INSTALL_TYPE=$(($INSTALL_TYPE|$DPROTO))
	INSTALL_TYPE=$(($INSTALL_TYPE|$AMXMODX))
	INSTALL_TYPE=$(($INSTALL_TYPE|$CHANGES))
 	else
  	UPDATE=1
   	INSTALL_TYPE=$(($INSTALL_TYPE|$METAMOD))
	INSTALL_TYPE=$(($INSTALL_TYPE|$DPROTO))
	INSTALL_TYPE=$(($INSTALL_TYPE|$AMXMODX))
 	fi
	;;
 "2")
 	if [ "$UPDATE" -eq 0 ] || [ "$UPDATE_RDLL" -eq 0 ]; then
	INSTALL_TYPE=$(($INSTALL_TYPE|$METAMOD))
	INSTALL_TYPE=$(($INSTALL_TYPE|$DPROTO))
 	INSTALL_TYPE=$(($INSTALL_TYPE|$AMXMODX))
	INSTALL_TYPE=$(($INSTALL_TYPE|$CHANGES))
 	INSTALL_TYPE=$(($INSTALL_TYPE|$REGAMEDLL))
  	else
     	UPDATE_RDLL=1
   	INSTALL_TYPE=$(($INSTALL_TYPE|$METAMOD))
	INSTALL_TYPE=$(($INSTALL_TYPE|$DPROTO))
 	INSTALL_TYPE=$(($INSTALL_TYPE|$AMXMODX))
 	INSTALL_TYPE=$(($INSTALL_TYPE|$REGAMEDLL))
  	fi
	;;
 "3")
	if [ "$UPDATE" -eq 1 ] || [ "$UPDATE_RDLL" -eq 1 ]; then
	INSTALL_TYPE=$(($INSTALL_TYPE|$SYSTEM_STEAMCMD))
        else
        echo "Ate"
        exit 0
        fi
        ;;

  "9")
	;;
*)
	echo "Ate"
	exit 0
	;;
esac
#------------
if [ ! -d "$INSTALL_DIR" ]; then
mkdir $INSTALL_DIR
fi

cd $INSTALL_DIR

cd $MAIN_DIR

echo "-------------------------------------------------------------------------------"

if [ "$UPDATE" -eq 0 ] || [ "$UPDATE_RDLL" -eq 0 ]; then

echo "Siunciami hlds failai ..."
sleep 2
cd $INSTALL_DIR
wget -O _hlds.tar.gz "https://www.dropbox.com/scl/fi/qddwy787rbc751lt5v00v/hlds.tar.gz?rlkey=jbvxybo63cu4fg2fipwuxhywx&st=20xpq6at&dl=1"
if [ ! -e "_hlds.tar.gz" ]; then
	echo "Klaida: Nepavyko gauti failu is serverio. Nutraukiama..."
	exit 1
fi
tar zxvf _hlds.tar.gz
rm _hlds.tar.gz
chmod +x hlds_run hlds_linux

cd $INSTALL_DIR

if [ ! -e "$INSTALL_DIR/steamcmd/steamcmd.sh" ]; then
	mkdir steamcmd
    
	cd $INSTALL_DIR/steamcmd
	curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

	if [ ! -e "steamcmd.sh" ]; then
		echo "[SteamCMD] Klaida: Nepavyko gauti SteamCMD failu is serverio. Nutraukiama..."
		exit 1
	fi
fi

check_app90_version

fi

if [ ! -d "$INSTALL_DIR/cstrike" ] || [ ! -f "$INSTALL_DIR/hlds_run" ] || 
[ ! -e "$INSTALL_DIR/cstrike/liblist.gam" ]; then
    echo -e "\nKlaida: Nepavyko atsiusti serverio failu. Prasome pranesti apie si nesklanduma"
	echo "Support discord ID: lukasenka18"
	echo "Taip pat, pateikite terminalo isvesties kopija."
	echo -e "Instaliacija nutraukiama...\n"
	echo "Istrinti nebaigta instaliuoti direktorija $INSTALL_DIR ?"
	read -p "Taip/Ne (t/n):" NUMBER

	shopt -s nocasematch
	if [[ $NUMBER == "t" ]] || [[ $NUMBER == "taip" ]] ; then
		rm -r $INSTALL_DIR
		echo "Direktorija $INSTALL_DIR sunaikinta"
	fi
	shopt -u nocasematch
    exit 1
fi

cd $INSTALL_DIR

if [ "$UPDATE" -ne 0 ]; then
bash stop
fi
echo "-------------------------------------------------------------------------------"
if [ $(($INSTALL_TYPE&$METAMOD)) != 0 ]; then
echo "instaliuojamas Rehlds v. ${rehlds_url} ir Metamod v. ${metamodr_url}."
sleep 2
if [ "$UPDATE" -ne 1 ]; then
mkdir -p cstrike/addons
mkdir -p cstrike/addons/metamod
mkdir -p cstrike/addons/metamod/dlls
fi
wget https://github.com/dreamstalker/rehlds/releases/download/${rehlds_url}/rehlds-bin-${rehlds_url}.zip
unzip rehlds-bin-${rehlds_url}.zip
rm -rf hlsdk

mv $INSTALL_DIR/bin/linux32/valve/dlls/director.so $INSTALL_DIR/valve/dlls/directors.so
cd $INSTALL_DIR/valve/dlls
rm director.so
mv directors.so director.so

cd $INSTALL_DIR/bin/linux32
mv proxy.so $INSTALL_DIR/proxys.so
cd $INSTALL_DIR
rm proxy.so
mv proxys.so proxy.so

cd $INSTALL_DIR/bin/linux32
mv hltv $INSTALL_DIR/hltvs
cd $INSTALL_DIR
rm hltv
mv hltvs hltv

cd $INSTALL_DIR/bin/linux32
mv demoplayer.so $INSTALL_DIR/demoplayers.so
cd $INSTALL_DIR
rm demoplayer.so
mv demoplayers.so demoplayer.so

cd $INSTALL_DIR/bin/linux32
mv core.so $INSTALL_DIR/cores.so
cd $INSTALL_DIR
rm core.so
mv cores.so core.so

cd $INSTALL_DIR/bin/linux32
mv hlds_linux $INSTALL_DIR/hlds_linuxs
cd $INSTALL_DIR
rm hlds_linux
mv hlds_linuxs hlds_linux
chmod +x hlds_linux

cd $INSTALL_DIR/bin/linux32
mv engine_i486.so $INSTALL_DIR/engine_i486s.so
cd $INSTALL_DIR
rm engine_i486.so
mv engine_i486s.so engine_i486.so
rm -rf bin
rm rehlds-bin-${rehlds_url}.zip
echo "Rehlds v. ${rehlds_url} diegimas sekmingas."
sleep 2

mkdir $INSTALL_DIR/meta
cd $INSTALL_DIR/meta
wget https://github.com/theAsmodai/metamod-r/releases/download/${metamodr_url}/metamod-bin-${metamodr_url}.zip
unzip metamod-bin-${metamodr_url}.zip
cd $INSTALL_DIR/meta/addons/metamod
mv metamod_i386.so $INSTALL_DIR/cstrike/addons/metamod/dlls/metamod_i386s.so
mv config.ini $INSTALL_DIR/cstrike/addons/metamod/dlls/config.ini
cd $INSTALL_DIR/cstrike/addons/metamod/dlls
if [ "$UPDATE" -ne 0 ]; then
rm metamod_i386.so
fi
mv metamod_i386s.so metamod_i386.so
cd $INSTALL_DIR
rm -rf meta
echo "Metamod v. ${metamodr_url} diegimas sekmingas."
sleep 2

if [ ! -e "cstrike/addons/metamod/dlls/metamod_i386.so" ]; then
	echo "Klaida: Nepavyko gauti metamod arba engine failo is serverio. Nutraukiama..."
	exit 1
fi
if [ "$UPDATE" -ne 1 ]; then
sed -r -i s/gamedll_linux.+/"gamedll_linux \"addons\/metamod\/dlls\/metamod_i386.so\""/ cstrike/liblist.gam
fi
fi
if [ $(($INSTALL_TYPE&$DPROTO)) != 0 ]; then
echo "Instaling Reunion..."
if [ "$UPDATE" -ne 1 ]; then
mkdir -p cstrike/addons
mkdir -p cstrike/addons/reunion
fi
if [ "$UPDATE" -ne 0 ]; then
cd $INSTALL_DIR/cstrike/addons/reunion
rm reunion_mm_i386.so
cd $INSTALL_DIR/cstrike
rm reunion.cfg
cd $INSTALL_DIR
fi

echo "instaliuojamas Reunion v. ${reunion_version} ..."
sleep 2
mkdir $INSTALL_DIR/reu-temp
cd $INSTALL_DIR/reu-temp
wget https://github.com/s1lentq/reunion/releases/download/${reunion_version}/reunion-${reunion_version}.zip
if [ ! -e "reunion-${reunion_version}.zip" ]; then
	echo "Klaida: Nepavyko gauti reunion failu is github serverio. Nutraukiama..."
	exit 1
fi
unzip reunion-${reunion_version}.zip
if [ -d "reunion_${reunion_version}" ]; then
    cd "reunion_${reunion_version}"
    
    random_string=$(generate_random_string 34)
    sed -i "s/^SteamIdHashSalt =.*/SteamIdHashSalt = $random_string/" reunion.cfg
    sed -i 's/cid_NoSteam47 = [0-9]\+/cid_NoSteam47 = 3/' reunion.cfg
    sed -i 's/cid_NoSteam48 = [0-9]\+/cid_NoSteam48 = 3/' reunion.cfg
    echo "Reunion v. $reunion_version. Sukonfiguruota sekmingai."
    sleep 2

    mv reunion.cfg $INSTALL_DIR/cstrike
    cd bin/Linux
    mv reunion_mm_i386.so $INSTALL_DIR/cstrike/addons/reunion
else
    random_string=$(generate_random_string 34)
    sed -i "s/^SteamIdHashSalt =.*/SteamIdHashSalt = $random_string/" reunion.cfg
    sed -i 's/cid_NoSteam47 = [0-9]\+/cid_NoSteam47 = 3/' reunion.cfg
    sed -i 's/cid_NoSteam48 = [0-9]\+/cid_NoSteam48 = 3/' reunion.cfg
    echo "Reunion v. $reunion_version. Sukonfiguruota sekmingai."
    
    mv reunion.cfg $INSTALL_DIR/cstrike
    cd bin/Linux
    mv reunion_mm_i386.so $INSTALL_DIR/cstrike/addons/reunion
fi

cd $INSTALL_DIR
rm -rf reu-temp

if [ ! -e "cstrike/addons/reunion/reunion_mm_i386.so" ] || [ ! -e "cstrike/reunion.cfg" ]; then
	echo "Klaida: Nepavyko gauti Reunion failu is github serverio. Nutraukiama..."
	exit 1
fi

echo "Reunion v. ${reunion_version} diegimas sekmingas."
sleep 2

if [ "$UPDATE" -ne 1 ]; then
echo "linux addons/reunion/reunion_mm_i386.so" >> cstrike/addons/metamod/plugins.ini
fi
fi

if [ $(($INSTALL_TYPE&$AMXMODX)) != 0 ]; then
if [ "$UPDATE" -ne 0 ]; then
echo "Isvalomi seni failai ..."
echo "-------------------------------"
echo "Demesio! Reikalingi failai bus pakeisti *-old galune."
echo "--------------------------------"
sleep 2
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
mv maps.ini maps-old.ini
rm cvars.ini
mv sql.cfg sql-old.cfg
rm cmds.ini
rm clcmds.ini
rm miscstats.ini
rm configs.ini
rm custommenuitems.cfg
mv modules.ini modules-old.ini
rm core.ini
mv plugins.ini plugins-old.ini
rm speech.ini
rm users.ini
mv amxx.cfg amxx-old.cfg
cd $INSTALL_DIR/cstrike/addons/amxmodx/plugins
rm antiflood.amxx
rm scrollmsg.amxx
rm imessage.amxx
rm adminslots.amxx
rm nextmap.amxx
rm multilingual.amxx
rm adminhelp.amxx
rm timeleft.amxx
rm mapchooser.amxx
rm telemenu.amxx
rm statscfg.amxx
rm menufront.amxx
rm adminchat.amxx
rm pausecfg.amxx
rm admin.amxx
rm mapsmenu.amxx
rm admin_sql.amxx
rm cmdmenu.amxx
rm pluginmenu.amxx
rm adminvote.amxx
rm plmenu.amxx
rm admincmd.amxx
cd $INSTALL_DIR/cstrike/addons/amxmodx
rm -rf scripting
cd $INSTALL_DIR/cstrike/addons/amxmodx/dlls
rm amxmodx_mm_i386.so
cd $INSTALL_DIR/cstrike/addons/amxmodx/data
rm -rf gamedata
rm csstats.amxx
rm GeoLite2-Country.mmdb
cd $INSTALL_DIR/cstrike/addons/amxmodx/data/lang
rm admin.txt
rm adminchat.txt
rm admincmd.txt
rm adminhelp.txt
rm adminslots.txt
rm adminvote.txt
rm antiflood.txt
rm cmdmenu.txt
rm common.txt
rm imessage.txt
rm languages.txt
rm mapchooser.txt
rm mapsmenu.txt
rm menufront.txt
rm miscstats.txt
rm multilingual.txt
rm nextmap.txt
rm pausecfg.txt
rm plmenu.txt
rm restmenu.txt
rm scrollmsg.txt
rm stats_dod.txt
rm statscfg.txt
rm statsx.txt
rm telemenu.txt
rm time.txt
rm timeleft.txt
cd $INSTALL_DIR/cstrike/addons/amxmodx/modules
rm cstrike_amxx_i386.so
rm csx_amxx_i386.so
rm engine_amxx_i386.so
rm fakemeta_amxx_i386.so
rm fun_amxx_i386.so
rm geoip_amxx_i386.so
rm hamsandwich_amxx_i386.so
rm json_amxx_i386.so
rm mysql_amxx_i386.so
rm nvault_amxx_i386.so
rm regex_amxx_i386.so
rm sockets_amxx_i386.so
rm sqlite_amxx_i386.so

if [ "$UPDATE_RDLL" -eq 1 ]; then

cd $INSTALL_DIR/cstrike
if [ -e "game.cfg" ]; then
    rm game.cfg
fi

if [ -e "game_init.cfg" ]; then
    rm game_init.cfg
fi

if [ -e "delta.lst" ]; then
    rm delta.lst
fi

cd $INSTALL_DIR/cstrike/dlls
rm cs.so
cd $INSTALL_DIR
wget -q -P cstrike/dlls https://github.com/lukasenka/rehlds-installer/raw/main/cs.so
wget -q -P cstrike https://github.com/lukasenka/rehlds-installer/raw/main/delta.lst
fi
cd $INSTALL_DIR
fi

echo "instaliuojamas Amxmodx v. $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-version.txt) (Build: $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)) ..."
sleep 2
wget -q -P cstrike https://www.amxmodx.org/amxxdrop/$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-version.txt)/amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-base-linux.tar.gz
if [ ! -e "cstrike/amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-base-linux.tar.gz" ]; then
	echo "Klaida: Nepavyko amxmodx failu is serverio. Nutraukiama..."
	exit 1
fi
tar -xzf cstrike/amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-base-linux.tar.gz -C cstrike
rm cstrike/amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-base-linux.tar.gz
if [ "$UPDATE" -ne 1 ]; then
echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> cstrike/addons/metamod/plugins.ini
fi

mkdir $INSTALL_DIR/temp
cd $INSTALL_DIR/temp
wget https://www.amxmodx.org/amxxdrop/$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-version.txt)/amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-cstrike-linux.tar.gz
if [ ! -e "amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-cstrike-linux.tar.gz" ]; then
	echo "Klaida: Nepavyko amxmodx cstrike failu is serverio. Nutraukiama..."
	exit 1
fi
tar -xzf amxmodx-$(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)-cstrike-linux.tar.gz
cd $INSTALL_DIR/temp/addons/amxmodx/scripting
mv statsx.sma $INSTALL_DIR/cstrike/addons/amxmodx/scripting/statsx.sma
mv stats_logging.sma $INSTALL_DIR/cstrike/addons/amxmodx/scripting/stats_logging.sma
mv restmenu.sma $INSTALL_DIR/cstrike/addons/amxmodx/scripting/restmenu.sma
mv miscstats.sma $INSTALL_DIR/cstrike/addons/amxmodx/scripting/miscstats.sma
mv csstats.sma $INSTALL_DIR/cstrike/addons/amxmodx/scripting/csstats.sma

cd $INSTALL_DIR/temp/addons/amxmodx/plugins
mv statsx.amxx $INSTALL_DIR/cstrike/addons/amxmodx/plugins/statsx.amxx
mv restmenu.amxx $INSTALL_DIR/cstrike/addons/amxmodx/plugins/restmenu.amxx
mv miscstats.amxx $INSTALL_DIR/cstrike/addons/amxmodx/plugins/miscstats.amxx
mv stats_logging.amxx $INSTALL_DIR/cstrike/addons/amxmodx/plugins/stats_logging.amxx

cd $INSTALL_DIR/temp/addons/amxmodx/modules
mv csx_amxx_i386.so $INSTALL_DIR/cstrike/addons/amxmodx/modules/csx_amxx_i386.so
mv cstrike_amxx_i386.so $INSTALL_DIR/cstrike/addons/amxmodx/modules/cstrike_amxx_i386.so

cd $INSTALL_DIR/temp/addons/amxmodx/data
mv csstats.amxx $INSTALL_DIR/cstrike/addons/amxmodx/data/csstats.amxx

cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv stats.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/statss.ini
mv plugins.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/pluginss.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm plugins.ini
if [ "$UPDATE" -ne 0 ]; then
rm stats.ini
fi
mv pluginss.ini plugins.ini
mv statss.ini stats.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv modules.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/moduless.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm modules.ini
mv moduless.ini modules.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv maps.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/mapss.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm maps.ini
mv mapss.ini maps.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv cvars.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/cvarss.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm cvars.ini
mv cvarss.ini cvars.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv core.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/cores.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm core.ini
mv cores.ini core.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv cmds.ini $INSTALL_DIR/cstrike/addons/amxmodx/configs/cmdss.ini
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm cmds.ini
mv cmdss.ini cmds.ini
cd $INSTALL_DIR/temp/addons/amxmodx/configs
mv amxx.cfg $INSTALL_DIR/cstrike/addons/amxmodx/configs/amxxs.cfg
cd $INSTALL_DIR/cstrike/addons/amxmodx/configs
rm amxx.cfg
mv amxxs.cfg amxx.cfg

cd $INSTALL_DIR
rm -rf temp
fi

if [ $(($INSTALL_TYPE&$CHANGES)) != 0 ]; then
echo "atliekami pakeitimai..."
wget -q -O cstrike/_server.cfg https://raw.githubusercontent.com/lukasenka/rehlds-installer/main/server.cfg
if [ ! -e "cstrike/_server.cfg" ]; then
	echo "Klaida: Nepavyko gauti server.cfg failo is serverio. Nutraukiama..."
	exit 1
fi
rm cstrike/server.cfg
mv cstrike/_server.cfg cstrike/server.cfg
fi

if [ $(($INSTALL_TYPE&$REGAMEDLL)) != 0 ]; then
echo "instaliuojamas ReGameDLL v. ${regamedll_url}..."
sleep 2
cd $INSTALL_DIR
wget https://github.com/s1lentq/ReGameDLL_CS/releases/download/${regamedll_url}/regamedll-bin-${regamedll_url}.zip
if [ ! -e "regamedll-bin-${regamedll_url}.zip" ]; then
	echo "Klaida: Nepavyko gauti ReGameDLL failu is serverio. Nutraukiama..."
	exit 1
fi
unzip regamedll-bin-${regamedll_url}.zip
rm -rf cssdk
cd $INSTALL_DIR/bin/linux32/cstrike/dlls
mv cs.so $INSTALL_DIR/cstrike/dlls/css.so
cd $INSTALL_DIR/cstrike/dlls
rm cs.so
mv css.so cs.so
cd $INSTALL_DIR/bin/linux32/cstrike
mv game_init.cfg $INSTALL_DIR/cstrike
mv game.cfg $INSTALL_DIR/cstrike
mv delta.lst $INSTALL_DIR/cstrike
cd $INSTALL_DIR
rm -rf bin
rm regamedll-bin-${regamedll_url}.zip
fi

if [ $(($INSTALL_TYPE&$SYSTEM_STEAMCMD)) != 0 ]; then
echo "[SteamCMD] Tikrinama ir instaliuojama nauja hlds failu versija...";
sleep 2

cd $INSTALL_DIR

if [ ! -e "$INSTALL_DIR/steamcmd/steamcmd.sh" ]; then
	mkdir steamcmd
	cd $INSTALL_DIR/steamcmd
	curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

	if [ ! -e "steamcmd.sh" ]; then
		echo "[SteamCMD] Klaida: Nepavyko gauti SteamCMD failu is serverio. Nutraukiama..."
		exit 1
	fi
fi

check_app90_version

fi

if [ "$UPDATE" -ne 1 ]; then

echo "-----------------------------"

echo "Instaliacija baigta." 
echo "Iveskite, koki porta norite naudoti:"
echo "-----------------------------"
echo "Spauskite 'enter', kad naudotumete standartini: 27015"
read -p "Portas: " port

if [ -z "$port" ]; then
    port="27015"
fi

echo "Naudojamas portas: $port"
echo "cd $INSTALL_DIR && screen -A -m -d -S $SERVER_DIR ./hlds_run -game cstrike +ip $(wget -T 5 -qO - "$ip_url") +port $port +map cs_assault +maxplayers 32" >> start_line

echo "#!/bin/bash" >> start
echo "SESSION=\$(screen -ls | egrep -o -e [0-9]+\\.$SERVER_DIR | sed -r -e \"s/[0-9]+\\.//\")" >> start
echo "if [ \"\$SESSION\" == \"$SERVER_DIR\" ]; then" >> start
echo "	screen -dr $SERVER_DIR" >> start
echo "else" >> start
echo "	eval \$(cat start_line)" >> start
echo "	sleep 1" >> start
echo "	screen -dr $SERVER_DIR" >> start
echo "fi" >> start
echo "exit" >> start
chmod +x start

echo "#!/bin/bash" >> stop
echo "SESSION=\$(screen -ls | egrep -o -e [0-9]+\\.$SERVER_DIR | sed -r -e \"s/[0-9]+\\.//\")" >> stop
echo "SERVER_NAME=\$(cat cstrike/server.cfg | egrep \"hostname\\s+\\\"[^\\\"]+\\\"\" | sed \"s/hostname //\" | tr -d \"\\\"\\r\")" >> stop
echo "STATUS=\"\"" >> stop
echo "if [ \"\$SESSION\" == \"$SERVER_DIR\" ]; then" >> stop
echo "	screen -S $SERVER_DIR -X stuff $(echo -e "quit\r")" >> stop
echo "	STATUS=\"sustabdytas\"" >> stop
echo "else" >> stop
echo "	STATUS=\"nera ijungtas, tad negalima jo sustabdyti\"" >> stop
echo "fi" >> stop
echo 'echo "-------------------------------------------------------------------------------"' >> stop
echo "echo \"Serveris \$SERVER_NAME \$STATUS\"" >> stop
echo 'echo "-------------------------------------------------------------------------------"' >> stop
echo "exit" >> stop
chmod +x stop

echo "#!/bin/bash" >> restart
echo "SESSION=\$(screen -ls | egrep -o -e [0-9]+\\.$SERVER_DIR | sed -r -e \"s/[0-9]+\\.//\")" >> restart
echo "SERVER_NAME=\$(cat cstrike/server.cfg | egrep \"hostname\\s+\\\"[^\\\"]+\\\"\" | sed \"s/hostname //\" | tr -d \"\\\"\\r\")" >> restart
echo "STATUS=\"\"" >> restart
echo "if [ \"\$SESSION\" == \"$SERVER_DIR\" ]; then" >> restart
echo "	screen -S $SERVER_DIR -X stuff $(echo -e "restart\r")" >> restart
echo "	STATUS=\"perkraunamas...\"" >> restart
echo "else" >> restart
echo "	STATUS=\"nera ijungtas, tad negalima jo perkrauti\"" >> restart
echo "fi" >> restart
echo 'echo "-------------------------------------------------------------------------------"' >> restart
echo "echo \"Serveris \$SERVER_NAME \$STATUS\"" >> restart
echo 'echo "-------------------------------------------------------------------------------"' >> restart
echo "exit" >> restart
chmod +x restart

sed -i s/"if test \$retval -eq 0 && test -z \"\$RESTART\" ; then"/"if test \$retval -eq 0 ; then"/ hlds_run
sed -i s/"debugcore \$retval"/"debugcore \$retval\n\n\t\t\tif test -z \"\$RESTART\" ; then\n\t\t\t\tbreak; # no need to restart on crash\n\t\t\tfi"/ hlds_run
sed -i s/"if test -n \"\$DEBUG\" ; then"/"if test \"\$DEBUG\" -eq 1; then"/ hlds_run

fi

if [ ! -e "$INSTALL_DIR/steam_appid.txt" ]; then
echo "10" >> steam_appid.txt
fi

if [ $(($INSTALL_TYPE&SYSTEM_STEAMCMD)) != 0 ]; then
    echo "-------------------------------------------------------------------------------"
    echo "[SteamCMD] [OK] Sistemiai failai sekmingai atnaujinti."

    sed -i s/"if test \$retval -eq 0 && test -z \"\$RESTART\" ; then"/"if test \$retval -eq 0 ; then"/ hlds_run
    sed -i s/"debugcore \$retval"/"debugcore \$retval\n\n\t\t\tif test -z \"\$RESTART\" ; then\n\t\t\t\tbreak; # no need to restart on crash\n\t\t\tfi"/ hlds_run
    sed -i s/"if test -n \"\$DEBUG\" ; then"/"if test \"\$DEBUG\" -eq 1; then"/ hlds_run
    sed -r -i s/gamedll_linux.+/"gamedll_linux \"addons\/metamod\/dlls\/metamod_i386.so\""/ cstrike/liblist.gam

else
    echo "-------------------------------------------------------------------------------"
    echo "Serveris instaliuotas direktorijoje '$INSTALL_DIR'"
    
    if [ $(($INSTALL_TYPE&$REGAMEDLL)) != 0 ]; then
        echo "[INFO] ReHLDS VERSIJA: ${rehlds_url}, AMXX VERSIJA: $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-version.txt) (Build: $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)), Metamod-r VERSIJA: ${metamodr_url}, Reunion VERSIJA: ${reunion_version}, ReGameDLL VERSIJA: ${regamedll_url}"
        echo "-------------------------------------------------------------------------------"
    else
        echo "[INFO] ReHLDS VERSIJA: ${rehlds_url}, AMXX VERSIJA: $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-version.txt) (Build: $(wget -T 5 -qO - https://raw.githubusercontent.com/lukasenka/rehlds-versions/main/amxx-build.txt)), Metamod-r VERSIJA: ${metamodr_url}, Reunion VERSIJA: ${reunion_version}"
        echo "-------------------------------------------------------------------------------"
    fi

    if [ $(($INSTALL_TYPE&$CHANGES)) != 0 ]; then
        echo "$INSTALL_DIR/start - paleisti serveri."
        echo "$INSTALL_DIR/stop - sustabdyti serveri."
        echo "$INSTALL_DIR/restart - perkrauti serveri."

    	sed -i s/"if test \$retval -eq 0 && test -z \"\$RESTART\" ; then"/"if test \$retval -eq 0 ; then"/ hlds_run
    	sed -i s/"debugcore \$retval"/"debugcore \$retval\n\n\t\t\tif test -z \"\$RESTART\" ; then\n\t\t\t\tbreak; # no need to restart on crash\n\t\t\tfi"/ hlds_run
    	sed -i s/"if test -n \"\$DEBUG\" ; then"/"if test \"\$DEBUG\" -eq 1; then"/ hlds_run

    fi
fi

exit 0
# Counter Strike 1.6 serverio instaliacijos skriptas
# Autorius: SAIMON (Anksciau - aaarnas)
# Support discord ID : lukasenka18
