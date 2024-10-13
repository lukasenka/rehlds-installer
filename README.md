# rehlds-installer (v5.7.2)
ReHLDS installation script (Extended support)

# Dėmesio!
Kadangi buvo problemų iš valve, ir jei naudojot ankstesnę nei 2023-10-13 versiją,
prašome prieš naudojat pasileisti šią komandą ir nutraukti jau esamus hlds_run procesus. 
``pkill -kill hlds_run
``

__ReHLDS__ -> [![rehlds](https://img.shields.io/github/release/dreamstalker/rehlds.svg)](https://github.com/dreamstalker/rehlds/releases)  
__AmxModX__ -> [![amxmodx](https://img.shields.io/badge/release-v1.10%20(latest)-blue)](https://www.amxmodx.org/downloads-new.php?branch=master&all=1)  
__Metamod-r__ -> [![metamodr](https://img.shields.io/github/release/theAsmodai/metamod-r.svg)](https://github.com/theAsmodai/metamod-r/releases)  
__ReGameDLL__ -> [![regamedll](https://img.shields.io/github/release/s1lentq/ReGameDLL_CS.svg)](https://github.com/s1lentq/ReGameDLL_CS/releases)  
__Reunion__ -> [![reunion](https://img.shields.io/github/release/s1lentq/reunion.svg)](https://github.com/s1lentq/reunion/releases)  

# Instaliacija

``cd /root/
``

``
wget https://raw.githubusercontent.com/lukasenka/rehlds-installer/main/rehlds.sh
``

``
chmod +x rehlds.sh
``

``
./rehlds.sh
``

Gero naudojimo :)

## Naudingos komandos
__amxx modules__ - visi šiuo metu įdiegti moduliai, statusas ir jų versijos.  
__amxx version__ - jūsų serverio amxx versija.  
__meta version__ - jūsų serverio metamod serverio versija.  
__game version__ - jūsų serverio ReGameDLL versija. Jeigu komanda nesuveikia - įdiegto addon'o nėra. 

Plačiau:
* https://wiki.alliedmods.net/Commands_(amx_mod_x)#RCON_Commands
* http://metamod.org/metamod.html#commands
