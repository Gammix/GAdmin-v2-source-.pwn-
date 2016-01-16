/*
    								  (__)
		______  ___      _           /. .\
	   / ____/ / _ \    | |          \_-_/
	  / /     | | | |   | | __ _  __   _  _  __             ____
	 | |  ___ | |_| |  _| || |/ \/  \ | || |/_ \   __    __|___ \
     | | |__ || | | | / _ ||  /\__/\ || ||  / \ |  \ \  / /  / /
     \ \___| || | | || |_||| |     | || || |  | |   \ \/ / / /_
	  \______||_| |_|\____||_|     |_||_||_|  |_|    \__/ \____|

	Filterscript:
	* GAdmin System -	gadmin.pwn
	* Version       -   v2.4.0 (2016/01/16)

 	Author: (creator)
	* Gammix

 	Contributors:
 	* Fro1sha       -   Regular expression plugin
	* Zeex & Yashas	- 	IZCMD include
	* Y_Less		- 	Sscanf2 plugin, Foreach include
	* Jochemd 		-	TimeStampToDate include
	* Slice 		-	MyMailer include
	* R@f/Gammix	-	ipmatch function
	* RyDer/Y_Less/Gammix - QuickSort_Pair function
	* SAMP team

	(c) Copyright 2016
  	* This file is provided as is (no warranties).
*/

//

#include <a_samp>
#include <yoursql>
#include <colors>
#include <spectate>
#include <regex>
#include <izcmd>
#include <sscanf2>
#include <foreach>
#include <timestamptodate>

#define MAX_WARNINGS (5)
#define MAX_ADMIN_LEVELS (6)

#define MAILER_URL "my-server.com/mailer.php"
#include <mailer>

#pragma dynamic (10000)

//

#define IsValidEmail(%1) \
	regex_match(%1, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}")

#define IsValidIp(%1) \
	regex_match(%1, "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.+){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")

#define DIALOG_ID_REGISTER (1)
#define DIALOG_ID_LOGIN (2)
#define DIALOG_ID_FORGOT_PASSWORD (3)
#define DIALOG_ID_EMAIL (4)

#define DIALOG_ID_REPORTS (100)
#define DIALOG_ID_REPORTS_PAGE (101)
#define DIALOG_ID_MUTE_LIST (102)
#define DIALOG_ID_UNMUTE (103)
#define DIALOG_ID_JAILED_LIST (104)
#define DIALOG_ID_UNJAIL (105)
#define DIALOG_ID_AUTO_LOGIN (106)

#define DIALOG_ID_TOP10 (107)

#if !defined FLOAT_INFINITY
    #define FLOAT_INFINITY (Float:0x7F800000)
#endif

#if !defined KEY_AIM
    #define KEY_AIM (128)
#endif

enum e_STATS
{
	userAdmin,
	bool:userPremium,
	userWarnings,
	userKills,
	userDeaths,
	userJailTime,
	userMuteTime,
	userVehicle,
	userLastPM,
	bool:userNoPM,
	userIdx,
	bool:userGod,
	bool:userGodCar,
	bool:userOnDuty
};
new pStats[MAX_PLAYERS][e_STATS];

#define MAX_REPORTS (10)
enum e_REPORT
{
	rAgainst[MAX_PLAYER_NAME],
	rAgainstId,
	rBy[MAX_PLAYER_NAME],
	rById,
	rReason[100],
	rTime[15],
	bool:rChecked
};
new gReport[MAX_REPORTS][e_REPORT];

new bool:pLogged[MAX_PLAYERS];
new pUpdateTimer[MAX_PLAYERS];
new bool:pSync[MAX_PLAYERS];

new const Float:gAdminSpawn[][4] =
{
	{1435.8024,2662.3647,11.3926,1.1650}, //  Northern train station
	{1457.4762,2773.4868,10.8203,272.2754}, //  Northern golf club
	{2101.4192,2678.7874,10.8130,92.0607}, //  Northern near railway line
	{1951.1090,2660.3877,10.8203,180.8461}, //  Northern house 2
	{1666.6949,2604.9861,10.8203,179.8495}, //  Northern house 3
	{1860.9672,1030.2910,10.8203,271.6988}, //  Behind 4 Dragons
	{1673.2345,1316.1067,10.8203,177.7294}, //  Airport carpark
	{1412.6187,2000.0596,14.7396,271.3568} //  South baseball stadium houses
};

new const gVehicleModelNames[212][] =
{
	{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},{"Sentinel"},{"Dumper"},
	{"Firetruck"},{"Trashmaster"},{"Stretch"},{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},
	{"Cheetah"},{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},{"Washington"},
	{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},{"Premier"},{"Enforcer"},{"Securicar"},
	{"Banshee"},{"Predator"},{"Bus"},{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"},{"Previon"},
	{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},{"Packer"},{"Monster"},
	{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},{"Tram"},{"Trailer 2"},{"Turismo"},
	{"Speeder"},{"Reefer"},{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
	{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},{"Glendale"},{"Oceanic"},
	{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},
	{"Rustler"},{"ZR-350"},{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},{"Marquis"},
	{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},{"FBI Rancher"},{"Virgo"},{"Greenwood"},
	{"Jetmax"},{"Hotring"},{"Sandking"},{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},
	{"Mesa"},{"RC Goblin"},{"Hotring Racer A"},{"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
	{"Super GT"},{"Elegant"},{"Journey"},{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropdust"},{"Stunt"},
	{"Tanker"}, {"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},{"Shamal"},{"Hydra"},{"FCR-900"},
	{"NRG-500"},{"HPV1000"},{"Cement Truck"},{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},
	{"Willard"},{"Forklift"},{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},
	{"Blade"},{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
	{"Firetruck LA"},{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},{"Tampa"},{"Sunrise"},{"Merit"},
	{"Utility"},{"Nevada"},{"Yosemite"},{"Windsor"},{"Monster A"},{"Monster B"},{"Uranus"},{"Jester"},
	{"Sultan"},{"Stratum"},{"Elegy"},{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},
	{"Bandito"},{"Freight Flat"},{"Streak Carriage"},{"Kart"},{"Mower"},{"Duneride"},{"Sweeper"},
	{"Broadway"},{"Tornado"},{"AT-400"},{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},
	{"Tug"},{"Trailer 3"},{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},{"Club"},{"Freight Carriage"},
	{"Trailer 3"},{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},{"Police Car (SFPD)"},
	{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},
	{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},{"Utility Trailer"}
};

public OnFilterScriptInit()
{
    yoursql_open("Server.db");

	yoursql_verify_table(SQL:0, "users");
	yoursql_verify_column(SQL:0, "users/name", SQL_STRING);
	yoursql_verify_column(SQL:0, "users/password", SQL_STRING);
	yoursql_verify_column(SQL:0, "users/email", SQL_STRING);
	yoursql_verify_column(SQL:0, "users/ip", SQL_STRING);
	yoursql_verify_column(SQL:0, "users/register_on", SQL_STRING);
	yoursql_verify_column(SQL:0, "users/auto_login", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/kills", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/deaths", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/score", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/money", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/admin", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/vip", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/hours", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/minutes", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "users/seconds", SQL_NUMBER);

	yoursql_verify_table(SQL:0, "bans");
	yoursql_verify_column(SQL:0, "bans/name", SQL_STRING);
	yoursql_verify_column(SQL:0, "bans/ip", SQL_STRING);
	yoursql_verify_column(SQL:0, "bans/admin_name", SQL_STRING);
	yoursql_verify_column(SQL:0, "bans/reason", SQL_STRING);
	yoursql_verify_column(SQL:0, "bans/date", SQL_STRING);
	yoursql_verify_column(SQL:0, "bans/type", SQL_NUMBER);
	yoursql_verify_column(SQL:0, "bans/expire", SQL_NUMBER);

	print("\n==================| Gadmin |==================\n");
	print("\tGadmin filterscript loaded.\n");
	print("\t      Version: 2.4.0\n");
	print("\t  (c) 2015 <MIT> \"Gammix\"");
	print("\n===============================================\n");
	new SQLRow:keys[1], values[1];
	yoursql_sort_int(SQL:0, "users/ROW_ID", keys, values, .limit = 1);
	printf("\t- Total user accounts: %i\n", _:keys[0]);
	yoursql_sort_int(SQL:0, "bans/ROW_ID", keys, values, .limit = 1);
	printf("\t- Total banned accounts: %i", _:keys[0]);
	print("\n===============================================\n");

	return 1;
}

public OnFilterScriptExit()
{
	yoursql_close(SQL:0);

	return 1;
}

ReturnPlayerName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

ReturnPlayerIp(playerid)
{
	new ip[18];
	GetPlayerIp(playerid, ip, 18);
	return ip;
}

ip2long(const ip[]) //(edited by me, originally by R@f)
{
  	new len = strlen(ip);
	if(! (len > 0 && len < 17))
    {
        return 0;
    }

	new count = 0;
    for (new i; i < len; i++)
    {
     	if(ip[i] == '.')
		{
			count++;
		}
	}
	if (! (count == 3))
	{
	    return 0;
	}

 	new address = strval(ip) << 24;
    count = strfind(ip, ".", false, 0) + 1;

	address += strval(ip[count]) << 16;
	count = strfind(ip, ".", false, count) + 1;

	address += strval(ip[count]) << 8;
	count = strfind(ip, ".", false, count) + 1;

	address += strval(ip[count]);
	return address;
}

ipmatch(ip1[], ip2[], rangetype = 26)
{
   	new ip = ip2long(ip1);
    new subnet = ip2long(ip2);

    new mask = -1 << (32 - rangetype);
    subnet &= mask;

    return bool:((ip & mask) == subnet);
}

GetPlayerConnectedTime(playerid, &hours, &minutes, &seconds)
{
	new connected_time = NetStats_GetConnectedTime(playerid);
	seconds = (connected_time / 1000) % 60;
	minutes = (connected_time / (1000 * 60)) % 60;
	hours = (connected_time / (1000 * 60 * 60));
}

SyncPlayer(playerid, Float:health = 0.0, Float:armour = 0.0)
{
   	new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new Float:a;
	GetPlayerFacingAngle(playerid, a);

	new interior = GetPlayerInterior(playerid);
	new world = GetPlayerVirtualWorld(playerid);

	new weapon[13], ammo[13];
	for (new i; i < 13; i++)
	{
 		GetPlayerWeaponData(playerid, i, weapon[i], ammo[i]);
	}

	if (health == 0.0)
	{
		GetPlayerHealth(playerid, health);
	}
	if (armour == 0.0)
	{
		GetPlayerArmour(playerid, armour);
	}

	new skin = GetPlayerSkin(playerid);
	new color = GetPlayerColor(playerid);

	pSync[playerid] = true;
	SpawnPlayer(playerid);

   	SetPlayerPos(playerid, x, y, z);

	SetPlayerFacingAngle(playerid, a);

	SetPlayerInterior(playerid, interior);
	SetPlayerVirtualWorld(playerid, world);

	for (new i; i < 13; i++)
	{
	    if (weapon[i] && ammo[i])
	    {
 			GivePlayerWeapon(playerid, weapon[i], ammo[i]);
		}
	}

	SetPlayerHealth(playerid, health);
	SetPlayerArmour(playerid, armour);

	SetPlayerSkin(playerid, skin);
	SetPlayerColor(playerid, color);
}

GetVehicleModelIDFromName(name[])
{
	for (new i, j = sizeof(gVehicleModelNames); i < j; i++)
	{
		if (strfind(gVehicleModelNames[i], name, true) != -1)
		{
			return i + 400;
		}
	}
	return -1;
}

GetWeaponIDFromName(name[])
{
	for(new i; i <= 46; i++)
	{
		switch(i)
		{
			case 0, 19, 20, 21, 44, 45:
			{
				continue;
			}
			default:
			{
				new weapon_name[35];
				GetWeaponName(i, weapon_name, sizeof(weapon_name));
				if (strfind(name, weapon_name, true) != -1)
				{
					return i;
				}
			}
		}
	}
	return -1;
}

isnumeric(str[])
{
	new ch, i;
	while ((ch = str[i++])) if (!('0' <= ch <= '9'))
	{
		return false;
	}
	return true;
}

QuickSort_Pair(array[][2], bool:desc, left, right)
{
	#define PAIR_FIST (0)
	#define PAIR_SECOND (1)

	new
		tempLeft = left,
		tempRight = right,
		pivot = array[(left + right) / 2][PAIR_FIST],
		tempVar
	;
	while (tempLeft <= tempRight)
	{
	    if (desc)
	    {
			while (array[tempLeft][PAIR_FIST] > pivot)
			{
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] < pivot)
			{
				tempRight--;
			}
		}
	    else
	    {
			while (array[tempLeft][PAIR_FIST] < pivot)
			{
				tempLeft++;
			}
			while (array[tempRight][PAIR_FIST] > pivot)
			{
				tempRight--;
			}
		}

		if (tempLeft <= tempRight)
		{
			tempVar = array[tempLeft][PAIR_FIST];
		 	array[tempLeft][PAIR_FIST] = array[tempRight][PAIR_FIST];
		 	array[tempRight][PAIR_FIST] = tempVar;

			tempVar = array[tempLeft][PAIR_SECOND];
			array[tempLeft][PAIR_SECOND] = array[tempRight][PAIR_SECOND];
			array[tempRight][PAIR_SECOND] = tempVar;

			tempLeft++;
			tempRight--;
		}
	}
	if (left < tempRight)
	{
		QuickSort_Pair(array, desc, left, tempRight);
	}
	if (tempLeft < right)
	{
		QuickSort_Pair(array, desc, tempLeft, right);
	}

	#undef PAIR_FIST
	#undef PAIR_SECOND
}

GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);

	if (GetPlayerVehicleID(playerid))
	{
 		GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	}

	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

public OnPlayerConnect(playerid)
{
	new pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);

	new pip[18];
	GetPlayerIp(playerid, pip, 18);

	new SQLRow:rowid = yoursql_multiget_row(SQL:0, "bans", "ss", "name", ReturnPlayerName(playerid), "ip", ReturnPlayerIp(playerid));
	if (rowid != SQL_INVALID_ROW)
	{
	    if (yoursql_get_field_int(SQL:0, "bans/expire", rowid) != 0 && gettime() > yoursql_get_field_int(SQL:0, "bans/expire", rowid))
	    {
	        SendClientMessage(playerid, COLOR_GREEN, "You ban has been expired!");

	        yoursql_delete_row(SQL:0, "bans", rowid);
	    }
	    else
	    {
		    new buf[1000];
			strcat(buf, WHITE);

			strcat(buf, "You have been banned from the server.\n");
			strcat(buf, "If this was a mistake (from server/admin side), please report a BAN APPEAL on our forums.\n\n");

			strcat(buf, "Username: "PINK"");
		 	strcat(buf, pname);
			strcat(buf, "\n"WHITE"");

			strcat(buf, "Ip: "PINK"");
			strcat(buf, pip);
			strcat(buf, "\n"WHITE"");

		 	new value[100];

			strcat(buf, "Ban date: "PINK"");
			yoursql_get_field(SQL:0, "bans/date", rowid, value);
			strcat(buf, value);
			strcat(buf, "\n"WHITE"");

			strcat(buf, "Admin name: "PINK"");
			yoursql_get_field(SQL:0, "bans/admin_name", rowid, value);
			strcat(buf, value);
			strcat(buf, "\n"WHITE"");

			switch (yoursql_get_field_int(SQL:0, "bans/type", rowid))
			{
				case 0:
				{
					strcat(buf, "Ban type: "PINK"");
					strcat(buf, "PERMANENT");
					strcat(buf, "\n"WHITE"");
				}
				case 1:
				{
					strcat(buf, "Ban type: "PINK"");
					strcat(buf, "TEMPORARY (expire on: ");
					new year, month, day, hour, minute, second;
					TimestampToDate(yoursql_get_field_int(SQL:0, "bans/expire", rowid), year, month, day, hour, minute, second, 0);
					new month_name[15];
					switch (month)
					{
					    case 1: month_name = "January";
					    case 2: month_name = "Feburary";
					    case 3: month_name = "March";
					    case 4: month_name = "April";
					    case 5: month_name = "May";
					    case 6: month_name = "June";
					    case 7: month_name = "July";
					    case 8: month_name = "August";
					    case 9: month_name = "September";
					    case 10: month_name = "October";
					    case 11: month_name = "November";
					    case 12: month_name = "December";
					}
					format(buf, sizeof(buf), "%s%i %s, %i)", buf, day, month_name, year);
					strcat(buf, "\n"WHITE"");
				}
				case 2:
				{
					strcat(buf, "Ban type: "PINK"");
					strcat(buf, "RANGEBAN");
					strcat(buf, "\n"WHITE"");
				}
				case 3:
				{
					strcat(buf, "Ban type: "PINK"");
					strcat(buf, "TEMPORARY RANGEBAN (expire on: ");
					new year, month, day, hour, minute, second;
					TimestampToDate(yoursql_get_field_int(SQL:0, "bans/expire", rowid), year, month, day, hour, minute, second, 0);
					new month_name[15];
					switch (month)
					{
					    case 1: month_name = "January";
					    case 2: month_name = "Feburary";
					    case 3: month_name = "March";
					    case 4: month_name = "April";
					    case 5: month_name = "May";
					    case 6: month_name = "June";
					    case 7: month_name = "July";
					    case 8: month_name = "August";
					    case 9: month_name = "September";
					    case 10: month_name = "October";
					    case 11: month_name = "November";
					    case 12: month_name = "December";
					}
					format(buf, sizeof(buf), "%s%i %s, %i)", buf, day, month_name, year);
					strcat(buf, "\n"WHITE"");
				}
			}

			strcat(buf, "Reason: "RED"");
			yoursql_get_field(SQL:0, "bans/reason", rowid, value);
			strcat(buf, value);
			strcat(buf, "\n\n"WHITE"");

			strcat(buf, "Take a screenshot of this as a refrence for admins.");

			ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Account banned :(", buf, "Close", "");

			Kick(playerid);
			return 0;
		}
	}
	else
	{
		new SQLRow:keys[2], values[2];
	    yoursql_sort_int(SQL:0, "bans/ROW_ID", keys, values, .limit = 1);
		for (new i, j = _:keys[0]; i <= j; i++)
		{
		    new name[MAX_PLAYER_NAME];
		    yoursql_get_field(SQL:0, "bans/name", SQLRow:i, name, MAX_PLAYER_NAME);

		    new ip[MAX_PLAYER_NAME];
		    yoursql_get_field(SQL:0, "bans/ip", SQLRow:i, ip);

		    if (yoursql_get_field_int(SQL:0, "bans/type", SQLRow:i) >= 2)
		    {
		        if (ipmatch(pip, ip))
		        {
				    if (yoursql_get_field_int(SQL:0, "bans/expire", SQLRow:i) != 0 && gettime() > yoursql_get_field_int(SQL:0, "bans/expire", SQLRow:i))
				    {
				        SendClientMessage(playerid, COLOR_GREEN, "You rangeban has been expired!");

				        yoursql_delete_row(SQL:0, "bans", SQLRow:i);

				        break;
				    }
				    else
				    {
			            new buf[1000];
						strcat(buf, WHITE);

						strcat(buf, "You have been banned from the server.\n");
						strcat(buf, "If this was a mistake (from server/admin side), please report a BAN APPEAL on our forums.\n\n");

						strcat(buf, "Username: "PINK"");
						strcat(buf, name);
						strcat(buf, "\n"WHITE"");

						strcat(buf, "Ip: "PINK"");
						strcat(buf, ip);
						strcat(buf, "\n"WHITE"");

					 	new value[100];

						strcat(buf, "Ban date: "PINK"");
						yoursql_get_field(SQL:0, "bans/date", SQLRow:i, value);
						strcat(buf, value);
						strcat(buf, "\n"WHITE"");

						strcat(buf, "Admin name: "PINK"");
						yoursql_get_field(SQL:0, "bans/admin_name", SQLRow:i, value);
						strcat(buf, value);
						strcat(buf, "\n"WHITE"");

						switch (yoursql_get_field_int(SQL:0, "bans/type", rowid))
						{
							case 2:
							{
								strcat(buf, "Ban type: "PINK"");
								strcat(buf, "RANGEBAN");
								strcat(buf, "\n"WHITE"");
							}
							case 3:
							{
								strcat(buf, "Ban type: "PINK"");
								strcat(buf, "TEMPORARY RANGEBAN (expire on: ");
								new year, month, day, hour, minute, second;
								TimestampToDate(yoursql_get_field_int(SQL:0, "bans/expire", SQLRow:i), year, month, day, hour, minute, second, 0);
								new month_name[15];
								switch (month)
								{
								    case 1: month_name = "January";
								    case 2: month_name = "Feburary";
								    case 3: month_name = "March";
								    case 4: month_name = "April";
								    case 5: month_name = "May";
								    case 6: month_name = "June";
								    case 7: month_name = "July";
								    case 8: month_name = "August";
								    case 9: month_name = "September";
								    case 10: month_name = "October";
								    case 11: month_name = "November";
								    case 12: month_name = "December";
								}
								format(buf, sizeof(buf), "%s%i %s, %i)", buf, day, month_name, year);
								strcat(buf, "\n"WHITE"");
							}
						}

						strcat(buf, "Reason: "RED"");
						yoursql_get_field(SQL:0, "bans/reason", SQLRow:i, value);
						strcat(buf, value);
						strcat(buf, "\n\n"WHITE"");

						strcat(buf, "Take a screenshot of this as a refrence for admins.");

						ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Account banned :(", buf, "Close", "");

						Kick(playerid);
			            return 0;
      				}
		        }
		    }
		}
	}

	new text[150];
	format(text, sizeof(text), "%s(%i) has joined the server. [Total players: %i]", ReturnPlayerName(playerid), playerid, Iter_Count(Player));
	SendClientMessageToAll(COLOR_GREY, text);

	pUpdateTimer[playerid] = SetTimerEx("OnPlayerTimeUpdate", 1000, true, "i", playerid);

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	KillTimer(pUpdateTimer[playerid]);

	new SQLRow:rowid = yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid));
	yoursql_set_field_int(SQL:0, "users/score", rowid, GetPlayerScore(playerid));
	yoursql_set_field_int(SQL:0, "users/money", rowid, GetPlayerMoney(playerid));
	yoursql_set_field(SQL:0, "users/ip", rowid, ReturnPlayerIp(playerid));
	yoursql_set_field_int(SQL:0, "users/kills", rowid, pStats[playerid][userKills]);
 	yoursql_set_field_int(SQL:0, "users/deaths", rowid, pStats[playerid][userDeaths]);

	new hours, minutes, seconds;
 	GetPlayerConnectedTime(playerid, hours, minutes, seconds);
 	hours += yoursql_get_field_int(SQL:0, "users/hours", rowid);
 	minutes += yoursql_get_field_int(SQL:0, "users/minutes", rowid);
 	seconds += yoursql_get_field_int(SQL:0, "users/seconds", rowid);
	if (seconds >= 60)
	{
	    seconds = 0;
	    minutes++;
	    if (minutes >= 60)
	    {
	        minutes = 0;
	        hours++;
	    }
	}
 	yoursql_set_field_int(SQL:0, "users/hours", rowid, hours);
 	yoursql_set_field_int(SQL:0, "users/minutes", rowid, minutes);
 	yoursql_set_field_int(SQL:0, "users/seconds", rowid, seconds);

	new text[150];
	switch (reason)
	{
		case 0:
		{
			format(text, sizeof(text), "%s(%i) have left the server. [Timeout/Crashed]", ReturnPlayerName(playerid), playerid);
		}
		case 1:
		{
			format(text, sizeof(text), "%s(%i) have left the server. [Quit]", ReturnPlayerName(playerid), playerid);
		}
		case 2:
		{
			format(text, sizeof(text), "%s(%i) have left the server. [Kicked/Banned]", ReturnPlayerName(playerid), playerid);
		}
	}
	SendClientMessageToAll(COLOR_GREY, text);

	return 1;
}

forward OnPlayerTimeUpdate(playerid);
public  OnPlayerTimeUpdate(playerid)
{
	if (pStats[playerid][userJailTime] > 0)
 	{
		pStats[playerid][userJailTime]--;

		new buf[150];
		format(buf, sizeof(buf), "~r~Unjail in %i seconds", pStats[playerid][userJailTime]);
		GameTextForPlayer(playerid, buf, 1000, 3);

	   	if (pStats[playerid][userJailTime] == 0)
		{
			pStats[playerid][userJailTime] = -1;

			format(buf, sizeof(buf), "%s(%i) has been released from jail.", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_DODGER_BLUE, buf);

			GameTextForPlayer(playerid, "~g~Unjailed!", 3000, 3);

			SpawnPlayer(playerid);
			return;
	  	}
	}

	if (pStats[playerid][userMuteTime] > 0)
 	{
		pStats[playerid][userMuteTime]--;

		if (pStats[playerid][userMuteTime] == 0)
		{
			pStats[playerid][userMuteTime] = -1;

        	new buf[150];
			format(buf, sizeof(buf), "%s(%i) has been unmuted.", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_DODGER_BLUE, buf);

			GameTextForPlayer(playerid, "~g~Unmuted!", 3000, 3);
	  	}
	}
}

public OnPlayerRequestClass(playerid, classid)
{
	if (! pLogged[playerid])
	{
    	new SQLRow:rowid = yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid));
		if (rowid == SQL_INVALID_ROW)
		{
		    for (new i; i < 50; i++)
		    {
		        SendClientMessage(playerid, COLOR_WHITE, " ");
		    }
		    SendClientMessage(playerid, COLOR_GREEN, "Welcome to SAMP 0.3 Server.");
		    SendClientMessage(playerid, COLOR_GREEN, "This a little formality that every new user should complete, please register and continue to play and have fun!");
		    SendClientMessage(playerid, COLOR_GREEN, "After registeration, you will get $50000 and 15 score as a regiseration achievement.");

		    new info[450];
			strcat(info, ""WHITE"Welcome "RED"");
			strcat(info, ReturnPlayerName(playerid));
			strcat(info, " "WHITE", you are new to the server!\n\n");
			strcat(info, "Before registering, please read the main rules:\n");
			strcat(info, ""RED"1. "WHITE"No cheats/hacks/invalid ways of playing.\n");
			strcat(info, ""RED"2. "WHITE"No insulting in main chat, respect all.\n");
			strcat(info, ""RED"3. "WHITE"Read all the rules in /rules.\n\n");
			strcat(info, "Now please insert a password and register this account!");

		    ShowPlayerDialog(playerid, DIALOG_ID_REGISTER, DIALOG_STYLE_PASSWORD, "Account registration", info, "Register", "Quit");
		}
		else
		{
		    for (new i; i < 50; i++)
		    {
		        SendClientMessage(playerid, COLOR_WHITE, " ");
		    }
		    SendClientMessage(playerid, COLOR_GREEN, "Welcome back to SAMP 0.3 Server.");

		    new ip[18];
			yoursql_get_field(SQL:0, "users/ip", rowid, ip);
	  		if (yoursql_get_field_int(SQL:0, "users/auto_login", rowid) && ! strcmp(ip, ReturnPlayerIp(playerid)))
	  		{
			  	SendClientMessage(playerid, COLOR_GREEN, "Login session has automatically completed, thanks for joining us back!");
				SendClientMessage(playerid, COLOR_GREEN, "If you want to change your account settings, type /settings.");

				ResetPlayerMoney(playerid);
				GivePlayerMoney(playerid, yoursql_get_field_int(SQL:0, "users/money", rowid));
				SetPlayerScore(playerid, yoursql_get_field_int(SQL:0, "users/score", rowid));

				pLogged[playerid] = true;
			}
			else
			{
			    for (new i; i < 50; i++)
			    {
			        SendClientMessage(playerid, COLOR_WHITE, " ");
			    }
		    	SendClientMessage(playerid, COLOR_GREEN, "Welcome back to SAMP 0.3 Server.");
				SendClientMessage(playerid, COLOR_GREEN, "You are already registered here, complete the login session and enjoy your stay!");

			    new info[450];
				strcat(info, ""WHITE"Welcome back "RED"");
				strcat(info, ReturnPlayerName(playerid));
				strcat(info, " "WHITE", you are already registerd!\n\n");
				strcat(info, "If you any problem logging in this account, you can do the following:\n");
				strcat(info, ""RED"1. "WHITE"Press 'PROBLEM' and enter the email registered with this account.\n");
				strcat(info, ""RED"2. "WHITE"Press 'PROBLEM' and click 'QUIT' there if this is not your account.\n\n");
				strcat(info, "Else, please insert your password and login this account!");

			    ShowPlayerDialog(playerid, DIALOG_ID_LOGIN, DIALOG_STYLE_PASSWORD, "Account login required", info, "Login", "Problem?");
			}
		}
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if (! pLogged[playerid])
	{
		GameTextForPlayer(playerid, "~r~You must be logged in to spawn", 3000, 3);
	    return 0;
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if (pSync[playerid])
	{
		pSync[playerid] = false;
	    return 0;
	}

	if (pStats[playerid][userJailTime] > 0)
    {
		SetPlayerHealth(playerid, FLOAT_INFINITY);
		SetPlayerArmour(playerid, 0.0);
		SetPlayerInterior(playerid, 3);
		SetPlayerPos(playerid, 197.6661, 173.8179, 1003.0234);
		SetCameraBehindPlayer(playerid);

		new buf[150];
		format(buf, sizeof(buf), "You are still in jail for %i seconds.", pStats[playerid][userJailTime]);
	    SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
		return 0;
	}

	if (pStats[playerid][userOnDuty])
    {
        SendClientMessage(playerid, COLOR_WHITE, " ");
        SendClientMessage(playerid, COLOR_GREEN, "- You have spawned -");

        new i = random(sizeof(gAdminSpawn));
	    SetPlayerPos(playerid, gAdminSpawn[i][0], gAdminSpawn[i][1], gAdminSpawn[i][2]);
	    SetPlayerFacingAngle(playerid, gAdminSpawn[i][3]);

	    SetPlayerSkin(playerid, 217);
	    SetPlayerColor(playerid, COLOR_HOT_PINK);
	    SetPlayerTeam(playerid, 100);
	    ResetPlayerWeapons(playerid);
	    GivePlayerWeapon(playerid, 38, 999999);

	    if (! pStats[playerid][userGod])
	    {
	        pStats[playerid][userGod] = true;
	    }
	    if (! pStats[playerid][userGodCar])
	    {
    		pStats[playerid][userGodCar] = true;
    	}

	    SetPlayerHealth(playerid, FLOAT_INFINITY);
	    SetVehicleHealth(GetPlayerVehicleID(playerid), FLOAT_INFINITY);

	    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

        SendClientMessage(playerid, COLOR_WHITE, "You are currently "GREEN"ON Admin Duty"WHITE". To switch it off, type /offduty.");
        SendClientMessage(playerid, COLOR_WHITE, "For commands list for your respective level, type /acmds.");
        SendClientMessage(playerid, COLOR_WHITE, "Weapon recieved: Minigun (/aweaps for more weapons range)");
        SendClientMessage(playerid, COLOR_WHITE, " ");
        return 0;
	}

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if (killerid != INVALID_PLAYER_ID)
	{
	    pStats[killerid][userKills]++;
		pStats[playerid][userDeaths]++;
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && (pStats[playerid][userAdmin] || IsPlayerAdmin(playerid)))
 	{
		if (newkeys & KEY_LOOK_BEHIND)
	    {
	   		return cmd_specoff(playerid, "");
	    }
	    if (newkeys & KEY_FIRE)
	    {
	        return UpdatePlayerSpectate(playerid, true);
	    }
	    if (newkeys & KEY_AIM)
	    {
	        return UpdatePlayerSpectate(playerid, false);
	    }
	}

	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (hittype == BULLET_HIT_TYPE_VEHICLE)
    {
        foreach (new i : Player)
        {
        	if (pStats[i][userOnDuty] && pStats[i][userAdmin] > pStats[playerid][userAdmin] && GetPlayerVehicleID(i) == hitid && GetPlayerVehicleSeat(i) == 0)
        	{
	        	GameTextForPlayer(playerid, "~r~Don't hit admin vehicles!", 3000, 3);
          		return 0;
	        }
		}
    }

    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if (! ispassenger)
	{
	    if (pStats[playerid][userGodCar])
	    {
	   		SetVehicleHealth(vehicleid, FLOAT_INFINITY);
		}

        foreach (new i : Player)
        {
        	if (pStats[i][userOnDuty] && pStats[i][userAdmin] > pStats[playerid][userAdmin] && GetPlayerVehicleID(i) == vehicleid && GetPlayerVehicleSeat(i) == 0)
        	{
        	    new Float:x, Float:y, Float:z;
				GetPlayerPos(playerid, x, y, z);
				SetPlayerPos(playerid, x, y, z + 1);

	        	GameTextForPlayer(playerid, "~r~Don't jack admin vehicles!", 3000, 3);
          		return 0;
        	}
	 	}
	}

    return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    if (pStats[playerid][userGodCar])
	{
    	UpdateVehicleDamageStatus(vehicleid, 0, 0, 0, 0);
	}

	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if (newstate == PLAYER_STATE_DRIVER)
	{
	    if (pStats[playerid][userGodCar])
		{
	    	UpdateVehicleDamageStatus(GetPlayerVehicleID(playerid), 0, 0, 0, 0);
	    	RepairVehicle(GetPlayerVehicleID(playerid));
	    	SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
		}
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float: amount, weaponid, bodypart)
{
    if (pStats[damagedid][userOnDuty] && pStats[damagedid][userAdmin] > pStats[playerid][userAdmin])
	{
    	GameTextForPlayer(playerid, "~r~Don't attack admins!", 3000, 3);
    	return 0;
    }

	return 1;
}

public OnPlayerText(playerid, text[])
{
	new buf[150];

	if (text[0] == '!')
	{
	    if (pStats[playerid][userAdmin] >= 1)
		{
			format(buf, sizeof(buf), "[Admin Chat] %s(%i): %s", ReturnPlayerName(playerid), playerid, text[1]);
			foreach (new i : Player)
			{
			    if (pStats[i][userAdmin] >= 4)
			    {
					SendClientMessage(i, COLOR_PINK, buf);
				}
			}
		    return 0;
		}
	}
	else if (text[0] == '@')
	{
		if (pStats[playerid][userAdmin] >= 4)
		{
			format(buf, sizeof(buf), "[#4 Admin Chat] %s(%i): %s", ReturnPlayerName(playerid), playerid, text[1]);
			foreach (new i : Player)
			{
			    if (pStats[i][userAdmin] >= 4)
			    {
					SendClientMessage(i, COLOR_HOT_PINK, buf);
				}
			}
		    return 0;
		}
	}
	else if (text[0] == '#')
	{
		if (pStats[playerid][userAdmin] >= 5)
		{
			format(buf, sizeof(buf), "[#5 Admin Chat] %s(%i): %s", ReturnPlayerName(playerid), playerid, text[1]);
			foreach (new i : Player)
			{
			    if (pStats[i][userAdmin] >= 5)
			    {
					SendClientMessage(i, COLOR_DARK_PINK, buf);
				}
			}
		    return 0;
		}
	}

	if (pStats[playerid][userOnDuty])
	{
		format(buf, sizeof(buf), "Admin %s(%i): %s", ReturnPlayerName(playerid), playerid, text);
		SendClientMessageToAll(GetPlayerColor(playerid), buf);
	}
	else if (pStats[playerid][userPremium])
	{
		format(buf, sizeof(buf), ""CYAN"[VIP] {%06x}(%i) %s: "WHITE"%s", GetPlayerColor(playerid) >>> 8, playerid, ReturnPlayerName(playerid), text);
		SendClientMessageToAll(GetPlayerColor(playerid), buf);
	}

	return 0;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new info[700];
 	new SQLRow:rowid = yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid));

	switch (dialogid)
	{
	    case DIALOG_ID_REGISTER:
	    {
			if (response)
			{
			    if (strlen(inputtext) < 4 || strlen(inputtext) > 30)
				{
					info[0] = EOS;
					strcat(info, ""WHITE"Welcome "RED"");
					strcat(info, ReturnPlayerName(playerid));
					strcat(info, " "WHITE", you are new to the server!\n\n");
					strcat(info, "Before registering, please read the main rules:\n");
					strcat(info, ""RED"1. "WHITE"No cheats/hacks/invalid ways of playing.\n");
					strcat(info, ""RED"2. "WHITE"No insulting in main chat, respect all.\n");
					strcat(info, ""RED"3. "WHITE"Read all the rules in /rules.\n\n");
					strcat(info, "Now please insert a password and register this account!");

				    ShowPlayerDialog(playerid, DIALOG_ID_REGISTER, DIALOG_STYLE_PASSWORD, "Account registration", info, "Register", "Quit");

				    SendClientMessage(playerid, COLOR_TOMATO, "You have entered invalid password, the length must be betweem 4 - 30 characters.");

					return 1;
				}

				new hash[128];
				SHA256_PassHash(inputtext, "aafGEsq13", hash, sizeof(hash));

				yoursql_set_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid));
				rowid = yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid));
				yoursql_set_field(SQL:0, "users/ip", rowid, ReturnPlayerIp(playerid));
				yoursql_set_field(SQL:0, "users/password", rowid, hash);
			 	yoursql_set_field_int(SQL:0, "users/score", rowid, 15);
			 	yoursql_set_field_int(SQL:0, "users/money", rowid, 50000);

                new date[3];
				getdate(date[2], date[1], date[0]);

				new month[15];
				switch (date[1])
				{
				    case 1: month = "January";
				    case 2: month = "Feburary";
				    case 3: month = "March";
				    case 4: month = "April";
				    case 5: month = "May";
				    case 6: month = "June";
				    case 7: month = "July";
				    case 8: month = "August";
				    case 9: month = "September";
				    case 10: month = "October";
				    case 11: month = "November";
				    case 12: month = "December";
				}

				new register_on[25];
				format(register_on, sizeof(register_on), "%02d %s, %d", date[0], month, date[2]);
			 	yoursql_set_field(SQL:0, "users/register_on", rowid, register_on);

			 	pStats[playerid][userAdmin] = 0;
			 	pStats[playerid][userPremium] = false;
			 	pStats[playerid][userKills] = 0;
			 	pStats[playerid][userDeaths] = 0;

			    for (new i; i < 50; i++)
			    {
			        SendClientMessage(playerid, COLOR_WHITE, " ");
			    }
			    SendClientMessage(playerid, COLOR_GREEN, "Great job! now you are an official member World War IV community.");
			    SendClientMessage(playerid, COLOR_GREEN, "You have completeted your registration, you may start playing now or setup your account (/settings).");
			    SendClientMessage(playerid, COLOR_YELLOW, "+$50000 and +15 score");

			    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

			    GivePlayerMoney(playerid, 50000);
			    SetPlayerScore(playerid, 15);

			    info[0] = EOS;
			    strcat(info, ""WHITE"Email registration is an important part but "YELLOW"OPTIONAL"WHITE".\n");
			    strcat(info, "Email registration will help you to recover your password when you loose it, in a very safe way.\n\n");
			    strcat(info, "Please insert a valid "GREEN"Email Adress "WHITE"to register with this account.");
			    ShowPlayerDialog(playerid, DIALOG_ID_EMAIL, DIALOG_STYLE_INPUT, "Account registration/Register an email", info, "Done", "Cancel");
			}
			else
			{
			    Kick(playerid);
			}
	    }

	    case DIALOG_ID_LOGIN:
	    {
			if (response)
			{
			    new pass[128];
			    yoursql_get_field(SQL:0, "users/password", rowid, pass);
       			new hash[128];
			    SHA256_PassHash(inputtext, "aafGEsq13", hash, sizeof(hash));

			    if (hash[0] && strcmp(hash, pass))
				{
					info[0] = EOS;
					strcat(info, ""WHITE"Welcome back "RED"");
					strcat(info, ReturnPlayerName(playerid));
					strcat(info, " "WHITE", you are already registerd!\n\n");
					strcat(info, "If you any problem logging in this account, you can do the following:\n");
					strcat(info, ""RED"1. "WHITE"Press 'PROBLEM' and enter the email registered with this account.\n");
					strcat(info, ""RED"2. "WHITE"Press 'PROBLEM' and click 'QUIT' there if this is not your account.\n\n");
					strcat(info, "Else, please insert your password and login this account!");

				    ShowPlayerDialog(playerid, DIALOG_ID_LOGIN, DIALOG_STYLE_PASSWORD, "Account login required", info, "Login", "Problem?");

				    SendClientMessage(playerid, COLOR_TOMATO, "You have entered unmatching password, please try again or quit.");

					return 1;
				}

				yoursql_set_field(SQL:0, "users/ip", rowid, ReturnPlayerIp(playerid));

			    for (new i; i < 50; i++)
			    {
			        SendClientMessage(playerid, COLOR_WHITE, " ");
			    }
			    SendClientMessage(playerid, COLOR_GREEN, "Login session was successfully completed, thanks for joining us back!");
			    SendClientMessage(playerid, COLOR_GREEN, "If you want to change your account settings, type /settings.");

			    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

			 	pStats[playerid][userAdmin] = yoursql_get_field_int(SQL:0, "users/admin", rowid);
			 	pStats[playerid][userPremium] = bool:yoursql_get_field_int(SQL:0, "users/vip", rowid);
			 	pStats[playerid][userKills] = yoursql_get_field_int(SQL:0, "users/kills", rowid);
			 	pStats[playerid][userDeaths] = yoursql_get_field_int(SQL:0, "users/deaths", rowid);

				ResetPlayerMoney(playerid);
			    GivePlayerMoney(playerid, yoursql_get_field_int(SQL:0, "users/money", rowid));
			    SetPlayerScore(playerid, yoursql_get_field_int(SQL:0, "users/score", rowid));

				pLogged[playerid] = true;
			}
			else
			{
			    ShowPlayerDialog(playerid, DIALOG_ID_FORGOT_PASSWORD, DIALOG_STYLE_INPUT, "Account login required/Forgot password", ""WHITE"Seems like you have lost your password, don't worry!\n\nIf this is your account, you must have registered an "RED"email"WHITE" while sign-up.\nEnter that email below and open it in your browser, retrieve the "RED"password reset key "WHITE" and follow the steps given.", "Confirm", "Quit");
			}
	    }

	    case DIALOG_ID_EMAIL:
	    {
	        if (response)
	        {
	            if (! IsValidEmail(inputtext))
	            {
	                info[0] = EOS;
				    strcat(info, ""WHITE"Email registration is an important part but "YELLOW"OPTIONAL"WHITE".\n");
				    strcat(info, "Email registration will help you to recover your password when you loose it, in a very safe way.\n\n");
				    strcat(info, "Please insert a valid "GREEN"Email Adress "WHITE"to register with this account.");
				    ShowPlayerDialog(playerid, DIALOG_ID_EMAIL, DIALOG_STYLE_INPUT, "Account registration/Register an email", info, "Done", "Cancel");

	                SendClientMessage(playerid, COLOR_TOMATO, "You have entered an invalid email address.");

					return 1;
	            }

				yoursql_set_field(SQL:0, "users/email", rowid, inputtext);

			    for (new i; i < 50; i++)
			    {
			        SendClientMessage(playerid, COLOR_WHITE, " ");
			    }
				info[0] = EOS;
				strcat(info, "You have successfully registered your account email "WHITE"");
				strcat(info, inputtext);
				strcat(info, " "GREEN".");
				SendClientMessage(playerid, COLOR_GREEN, info);
				SendClientMessage(playerid, COLOR_GREEN, "If you ever wish to change it, you can do so by /email.");

			    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

				pLogged[playerid] = true;
	        }
	        else
	        {
				pLogged[playerid] = true;

			    SendClientMessage(playerid, COLOR_YELLOW, "You have canceled email registration. If you want to add an email later, you can do so by /email.");
	        }
	    }

	    case DIALOG_ID_FORGOT_PASSWORD:
	    {
	        if (response)
	        {
	            new email[100];
				yoursql_get_field(SQL:0, "users/email", rowid, email);
				if (! IsValidEmail(inputtext) || strcmp(email, inputtext))
				{
			    	ShowPlayerDialog(playerid, DIALOG_ID_FORGOT_PASSWORD, DIALOG_STYLE_INPUT, "Account login required/Forgot password", ""WHITE"Seems like you have lost your password, do't worry!\n\nIf this is your account, you must have registered an "RED"email"WHITE" while sign-up.\nEnter that email below and open it in your browser, retrieve the "RED"password reset key "WHITE" and follow the steps given.", "Confirm", "Quit");

	                SendClientMessage(playerid, COLOR_TOMATO, "You have entered an unmatching email address.");

					return 1;
				}

			    for (new i; i < 50; i++)
			    {
			        SendClientMessage(playerid, COLOR_WHITE, " ");
			    }
				SendClientMessage(playerid, COLOR_GREEN, "You have entered the correct email address, You will be recieving one shortly (also check your Spam section).");
				SendClientMessage(playerid, COLOR_GREEN, "Once you have recieved the mail, use the reset password key and login with it (we have given steps in mail as well).");

				new const chars[][] =
		        {
		            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
              		"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
		            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
		        };

				new input[30];
				for (new i, j = sizeof(input); i < j; i++)
				{
				    strcat(input, chars[random(sizeof(chars))][0]);
				}

				new hash[128];
				SHA256_PassHash(input, "aafGEsq13", hash, sizeof(hash));

				yoursql_set_field(SQL:0, "users/password", rowid, hash);

				strcat(info, "Hi Sir/Maam,\n\n");
				strcat(info, "We have recieved a password recovery request from a game login session.\n");
				strcat(info, "(if this wasn't you, please ignore this message!)\n\n");
				strcat(info, "In order to reset your password, you must login with the below password:\n");
				strcat(info, "Recovery password: \"");
				strcat(info, input);
				strcat(info, "\"\n\n");
				strcat(info, "Go in game, enter this password and reset to a new one with /changepass.");

				SendMail(email, "help@gadmin.com", "GAdminv2_4", "Password Recovery <no reply>", info);

			    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

			    Kick(playerid);
	        }
	        else
	        {
			    Kick(playerid);
	        }
	    }

		case DIALOG_ID_REPORTS:
	    {
	        if (response)
	        {
	            if (listitem == 0)
				{
				    for (new i; i < MAX_REPORTS; i++)
				    {
					    gReport[i][rAgainst][0] = EOS;
				        gReport[i][rAgainstId] = INVALID_PLAYER_ID;
				        gReport[i][rBy][0] = EOS;
				        gReport[i][rById] = INVALID_PLAYER_ID;
				        gReport[i][rReason][0] = EOS;
				        gReport[i][rTime][0] = EOS;
				        gReport[i][rChecked] = false;
					}

					new buf[150];
					format(buf, sizeof(buf), "All reports were cleared by admin %s(%i).", ReturnPlayerName(playerid), playerid);
					foreach (new i : Player)
					{
					    if (pStats[i][userAdmin])
					    {
							SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
						}
					}
				}
				else
				{
				    new i = listitem + 1;

					if (! gReport[i][rChecked] && IsPlayerConnected(gReport[i][rById]))
					{
					    new buf[150];
						format(buf, sizeof(buf), "Admin %s(%i) is checking your report.", ReturnPlayerName(playerid), playerid);
						SendClientMessage(gReport[i][rById], COLOR_DODGER_BLUE, buf);
					}

					format(info, sizeof(info), ""WHITE"You are now checking the report of "GREEN"%s(%i)"WHITE".\n\n"TOMATO"Against: "WHITE"%s(%i)\n"TOMATO"Reason:\n"WHITE"%s\n"TOMATO"Time: "WHITE"%s", gReport[i][rBy], gReport[i][rById], gReport[i][rAgainst], gReport[i][rAgainstId], gReport[i][rReason], gReport[i][rTime]);
					ShowPlayerDialog(playerid, DIALOG_ID_REPORTS_PAGE, DIALOG_STYLE_MSGBOX, "Report info.:", info, "Back", "Close");
				}
	        }
	    }

	    case DIALOG_ID_REPORTS_PAGE:
	    {
	        if (response)
	        {
	            cmd_reports(playerid);
	        }
	    }

	    case DIALOG_ID_MUTE_LIST:
	    {
	        if (response)
	        {
	            new idx;
	            foreach (new i : Player)
				{
				    if (pStats[i][userMuteTime] != -1)
				    {
				        if (idx == listitem)
				        {
							format(info, sizeof(info), ""WHITE"Click "GREEN"UNMUTE "WHITE"to lift mute from player.\n\nPlayer selected: "TOMATO"%s(%i) "WHITE"(unmute will be auto lifted in %i seconds)", ReturnPlayerName(i), i, pStats[i][userMuteTime]);
							ShowPlayerDialog(playerid, DIALOG_ID_UNMUTE, DIALOG_STYLE_MSGBOX, "Unmute confirmation:", info, "Unmute", "Cancel");

							pStats[playerid][userIdx] = i;
				            break;
				        }
				        idx++;
				    }
				}
	        }
	    }

	    case DIALOG_ID_UNMUTE:
	    {
	        if (response)
	        {
	            new params[5];
	            valstr(params, pStats[playerid][userIdx]);
	            cmd_unmute(playerid, params);
	        }
	    }

	    case DIALOG_ID_JAILED_LIST:
	    {
	        if (response)
	        {
	            new idx;
	            foreach (new i : Player)
				{
				    if (pStats[i][userJailTime] != -1)
				    {
				        if (idx == listitem)
				        {
							format(info, sizeof(info), ""WHITE"Click "GREEN"UNJAIL "WHITE"to lift jail from player.\n\nPlayer selected: "TOMATO"%s(%i) "WHITE"(jail will be auto lifted in %i seconds)", ReturnPlayerName(i), i, pStats[i][userJailTime]);
							ShowPlayerDialog(playerid, DIALOG_ID_UNJAIL, DIALOG_STYLE_MSGBOX, "Unjail confirmation:", info, "Unjail", "Cancel");

							pStats[playerid][userIdx] = i;
				            break;
				        }
				        idx++;
				    }
				}
	        }
	    }

	    case DIALOG_ID_UNJAIL:
	    {
	        if (response)
	        {
	            new params[5];
	            valstr(params, pStats[playerid][userIdx]);
	            cmd_unjail(playerid, params);
	        }
		}

	    case DIALOG_ID_AUTO_LOGIN:
	    {
	        if (response)
	        {
	            yoursql_set_field_int(SQL:0, "users/auto_login", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid)), 1);
	            SendClientMessage(playerid, COLOR_GREEN, "AUTOLOGIN: You have enabled your auto login feature.");
	        }
	        else
	        {
	            yoursql_set_field_int(SQL:0, "users/auto_login", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(playerid)), 0);
	            SendClientMessage(playerid, COLOR_GREEN, "AUTOLOGIN: You have disabled your auto login feature.");
	        }
	    }
	    
	    case DIALOG_ID_TOP10:
	    {
			if (response)
			{
			    switch (listitem)
			    {
					case 0:
					{
					    new SQLRow:keys[10], values[10];
					    yoursql_sort_int(SQL:0, "users/kills", keys, values, .limit = 10);

					    SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 10 all time players (KILLS):");
					    new name[MAX_PLAYER_NAME];
					    for (new i; i < 10; i++)
					    {
					        if (keys[i])
					        {
					            yoursql_get_field(SQL:0, "users/name", keys[i], name, MAX_PLAYER_NAME);
					        	format(info, sizeof(info), "%i. %s - %i kills\n", i, name, values[i]);
					        	SendClientMessage(playerid, COLOR_DODGER_BLUE, info);
							}
						}
					}
					case 1:
					{
					    new SQLRow:keys[10], values[10];
					    yoursql_sort_int(SQL:0, "users/deaths", keys, values, .limit = 10);

					    SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 10 all time players (DEATHS):");
					    new name[MAX_PLAYER_NAME];
					    for (new i; i < 10; i++)
					    {
					        if (keys[i])
					        {
					            yoursql_get_field(SQL:0, "users/name", keys[i], name, MAX_PLAYER_NAME);
					        	format(info, sizeof(info), "%i. %s - %i deaths\n", i, name, values[i]);
					        	SendClientMessage(playerid, COLOR_DODGER_BLUE, info);
							}
						}
					}
					case 2:
					{
					    new SQLRow:keys[10], values[10];
					    yoursql_sort_int(SQL:0, "users/score", keys, values, .limit = 10);

					    SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 10 all time players (SCORE):");
					    new name[MAX_PLAYER_NAME];
					    for (new i; i < 10; i++)
					    {
					        if (keys[i])
					        {
					            yoursql_get_field(SQL:0, "users/name", keys[i], name, MAX_PLAYER_NAME);
					        	format(info, sizeof(info), "%i. %s - %i score\n", i, name, values[i]);
					        	SendClientMessage(playerid, COLOR_DODGER_BLUE, info);
							}
						}
					}
					case 3:
					{
					    new SQLRow:keys[10], values[10];
					    yoursql_sort_int(SQL:0, "users/hours", keys, values, .limit = 10);

					    SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 10 all time players (TIME PLAYED):");
					    new name[MAX_PLAYER_NAME];
					    for (new i; i < 10; i++)
					    {
					        if (keys[i])
					        {
					            yoursql_get_field(SQL:0, "users/name", keys[i], name, MAX_PLAYER_NAME);
					        	format(info, sizeof(info), "%i. %s - %i hours\n", i, name, values[i]);
					        	SendClientMessage(playerid, COLOR_DODGER_BLUE, info);
							}
						}
					}
			    }
			}
	    }
	}
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if (pStats[playerid][userMuteTime] > 0)
	{
	    SendClientMessage(playerid, COLOR_TOMATO, "You can only perform commands when your unmuted.");
	    return 0;
	}
	else if (pStats[playerid][userJailTime] > 0)
	{
	    SendClientMessage(playerid, COLOR_TOMATO, "You can only perform commands when your unjailed.");
	    return 0;
	}
	
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid)
{
	new params[5];
	valstr(params, clickedplayerid);
    cmd_stats(playerid, params);
	return 1;
}

CMD:sync(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (IsPlayerInAnyVehicle(playerid))
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be on foot to use this command.");
	}

    SyncPlayer(playerid);
    SendClientMessage(playerid, COLOR_GREEN, "You have been synchronized upon your request (/stats restored)!");

    return 1;
}

CMD:kill(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (IsPlayerInAnyVehicle(playerid))
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be on foot to use this command.");
	}

	SetPlayerHealth(playerid, 0.0);
	SendClientMessage(playerid, COLOR_TOMATO, "You commited sucide.");

	return 1;
}

CMD:givegun(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (IsPlayerInAnyVehicle(playerid))
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be on foot to use this command.");
	}

	new target, amount;
	if (sscanf(params, "ui", target, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givegun [player] [amount]");
	}

	if(amount < 1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The amount limit must be greater than 0.");
	}

	if (! IsPlayerConnected(target))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not connected.");
	}

	if (target == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't give money to yourself.");
	}

	if (GetPlayerState(target) == PLAYER_STATE_WASTED)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not spawned.");
	}

	new weapon = GetPlayerWeapon(playerid);
	if (weapon == 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot distribute your wrist to players!");
	}

	new ammo = GetPlayerAmmo(playerid);
	if (ammo < ammo)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You yourself don't have that much ammo.");
	}

	SetPlayerAmmo(playerid, weapon, -ammo);
	GivePlayerWeapon(target, weapon, ammo);

	new weapon_name[35];
	GetWeaponName(weapon, weapon_name, sizeof(weapon_name));

	new buf[150];
	format(buf, sizeof(buf), "You have recieved a %s with %i ammo from %s(%i).", weapon_name, amount, ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_GREEN, buf);
	format(buf, sizeof(buf), "You have given a %s with %i ammo to %s(%i).", weapon_name, amount, ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_GREEN, buf);

	return 1;
}

CMD:givemoney(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (IsPlayerInAnyVehicle(playerid))
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be on foot to use this command.");
	}

	new target, amount;
	if (sscanf(params, "ui", target, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givemoney [player] [amount]");
	}

	if(amount < 1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The amount limit must be greater than 0.");
	}

	if (! IsPlayerConnected(target))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not connected.");
	}

	if (target == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't give money to yourself.");
	}

	if (GetPlayerState(target) == PLAYER_STATE_WASTED)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not spawned.");
	}

	if (GetPlayerMoney(playerid) < amount)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You yourself don't have that much money.");
	}

	GivePlayerMoney(playerid, -amount);
	GivePlayerMoney(target, amount);

	new buf[150];
	format(buf, sizeof(buf), "You have recieved $%i from %s(%i).", amount, ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_GREEN, buf);
	format(buf, sizeof(buf), "You have given $%i to %s(%i).", amount, ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_GREEN, buf);

	return 1;
}

//Admin level 1+
CMD:acmds(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
        return SendClientMessage(playerid, COLOR_TOMATO, "You must be an admin to use this command.");
    }

	new info[3024];
	strcat(info, ""HOT_PINK"Moderator (Level 1):\n");
  	strcat(info, ""WHITE"/acmds, /onduty, /offduty, /spec, /specoff, /adminarea, /weaps, /reports, /repair, /addnos,\n");
  	strcat(info, "/warn, /resetwarns, /flip, /ip, /spawn, /goto, /setweather, /settime, /kick, /asay\n");
  	strcat(info, "Use `"GREEN"!"WHITE"' for admin chat [eg. ! hello].\n\n");

	if (pStats[playerid][userAdmin] >= 2 || IsPlayerAdmin(playerid))
	{
		strcat(info, ""HOT_PINK"Junior Administrator (Level 2):\n");
  		strcat(info, ""WHITE"/ann, /ann2, /jetpack, /aka, /aweaps, /text, /carhealth, /eject, /carpaint, /carcolor,\n");
  		strcat(info, "/givecar, /car, /akill, /jailed, /jail, /unjail, /muted, /mute, /unmute, /setskin, /cc, /heal, /armour,\n");
  		strcat(info, "/setinterior, /setworld, /slap, /explode, /disarm, /ban, /ipban, /oban, /unban, /searchban\n\n");
	}
	if (pStats[playerid][userAdmin] >= 3 || IsPlayerAdmin(playerid))
	{
		strcat(info, ""HOT_PINK"Senior Administrator (Level 3):\n");
		strcat(info, ""WHITE"/get, /write, /force, /healall, /armourall, /fightstyle, /sethealth, /setarmour, /god, /godcar, /freeze,\n");
		strcat(info, "/unfreeze, /giveweapon, /setcolor, /setcash, /setscore, /givecash, /givescore, /spawncar, /destroycar, /spawncars,\n");
		strcat(info, "/removedrops, /setkills, /setdeaths\n\n");
	}
	if (pStats[playerid][userAdmin] >= 4 || IsPlayerAdmin(playerid))
	{
		strcat(info, ""HOT_PINK"Lead Administrator (Level 4):\n");
		strcat(info, ""WHITE"/fakedeath, /muteall, /unmuteall, /giveallscore, /giveallcash, /setalltime, /setallweather, /pickup, /destroypickup,\n");
		strcat(info, "/clearwindow, /giveallweapon, /object, /destroyobject, /editobject, /rban, /ripban, /roban, /event,\n");
  		strcat(info, "Use `"GREEN"@"WHITE"' for admin level 4+ chat [eg. @ hello].\n\n");
	}
	if (pStats[playerid][userAdmin] >= 5 || IsPlayerAdmin(playerid))
	{
		strcat(info, ""HOT_PINK"Server Manager (Level 5):\n");
		strcat(info, ""WHITE"/gmx, /fakechat, /setlevel, /setpremium\n");
  		strcat(info, "Use `"GREEN"#"WHITE"' for admin level 5+ chat [eg. # hello].");
	}

	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Administrative commands:", info, "Close", "");
	return 1;
}

CMD:onduty(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	if (pStats[playerid][userOnDuty])
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You are already on admin duty.");
	}

    new i = random(sizeof(gAdminSpawn));
    SetPlayerPos(playerid, gAdminSpawn[i][0], gAdminSpawn[i][1], gAdminSpawn[i][2]);
  	SetPlayerFacingAngle(playerid, gAdminSpawn[i][3]);

	SetPlayerSkin(playerid, 217);
	SetPlayerColor(playerid, COLOR_HOT_PINK);
 	SetPlayerTeam(playerid, 100);
 	ResetPlayerWeapons(playerid);
 	GivePlayerWeapon(playerid, 38, 999999);
 	if (! pStats[playerid][userGod])
  	{
   		pStats[playerid][userGod] = true;
    }
 	if (! pStats[playerid][userGodCar])
  	{
   		pStats[playerid][userGodCar] = true;
    }
    SetPlayerHealth(playerid, FLOAT_INFINITY);
    SetVehicleHealth(GetPlayerVehicleID(playerid), FLOAT_INFINITY);

    pStats[playerid][userOnDuty] = true;

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You are on admin duty, type /offduty to switch off duty.");
	return 1;
}

CMD:offduty(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	if (! pStats[playerid][userOnDuty])
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You are already off admin duty.");
	}

    pStats[playerid][userOnDuty] = false;
    pStats[playerid][userGod] = false;
    pStats[playerid][userGodCar] = false;

    SpawnPlayer(playerid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You are off admin duty.");
	return 1;
}

CMD:spec(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spec [player]");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't spectate to yourself.");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (GetPlayerState(targetid) == PLAYER_STATE_SPECTATING)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not spawned.");
	}

	PlayerSpectatePlayer(playerid, targetid);

	new buf[150];
	format(buf, sizeof(buf), "You are now spectating %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You can type /specoff when you wish to stop spectating.");
    return 1;
}

CMD:specoff(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    if (GetPlayerState(playerid) != PLAYER_STATE_SPECTATING)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You are not spectating.");
	}

	TogglePlayerSpectating(playerid, false);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have stopped spectating now.");
    return 1;
}

CMD:adminarea(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	GameTextForPlayer(playerid, "~b~Adminarea", 3000, 3);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have teleported to admin area.");

	SetPlayerPos(playerid, 377, 170, 1008);
	SetPlayerFacingAngle(playerid, 90);
	SetPlayerInterior(playerid, 3);
	SetPlayerVirtualWorld(playerid, 0);
    return 1;
}

CMD:weaps(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /weaps [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	new buf[150];
	format(buf, sizeof(buf), "%s(%i)'s weapons:", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);

	new w, a;
	new count;
	new name[35];
	buf[0] = EOS;
	for (new i; i < 13; i++)
	{
		GetPlayerWeaponData(targetid, i, w, a);
		if (w && a)
		{
		    GetWeaponName(w, name, sizeof(name));
		    if (buf[0])
		    {
		    	format(buf, sizeof(buf), "%s, %s (%i)", buf, name, a);
			}
			else
			{
		    	format(buf, sizeof(buf), "%s (%i)", buf, name, a);
			}

		    count++;
			if (count >= 5)
			{
				SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);

			    count = 0;
				buf[0] = EOS;
			}
		}
	}
	return 1;
}

CMD:reports(playerid)
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new buf[100];
	new info[sizeof(buf) * (MAX_REPORTS + 1)];
	strcat(info, ""RED"CLEAR REPORTS\n");
	for (new i; i < MAX_REPORTS; i++)
	{
	    if (gReport[i][rAgainst][0])
	    {
		    if (gReport[i][rChecked])
		    {
		    	format(buf, sizeof(buf), ""GREEN"[Unread] "WHITE"%s(%i) report against %s(%i) - %s", gReport[i][rAgainst], gReport[i][rAgainstId], gReport[i][rBy], gReport[i][rById], gReport[i][rTime]);
		    }
		    else
		    {
		        format(buf, sizeof(buf), "%s(%i) report against %s(%i) - %s", gReport[i][rAgainst], gReport[i][rAgainstId], gReport[i][rBy], gReport[i][rById], gReport[i][rTime]);
		    }
		    strcat(info, buf);
		    strcat(info, "\n");
	    }
	}

	ShowPlayerDialog(playerid, DIALOG_ID_REPORTS, DIALOG_STYLE_MSGBOX, "Reports log:", info, "Open", "Close");
	return 1;
}

CMD:repair(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (! sscanf(params, "u", targetid))
    {
		if (! IsPlayerConnected(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
		}

		if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
		}

		if (! IsPlayerInAnyVehicle(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "Player is not in a vehicle.");
		}

		new vehicleid = GetPlayerVehicleID(targetid);
		RepairVehicle(vehicleid);
	  	SetVehicleHealth(vehicleid, 1000.0);

		GameTextForPlayer(targetid, "~b~Vehicle repaired", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
		PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);

		new buf[150];
		format(buf, sizeof(buf), "You have repaired %s(%i)'s vehicle.", ReturnPlayerName(targetid), targetid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "Admin %s(%i) has repaired your vehicle.", ReturnPlayerName(playerid), playerid);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
    else
    {
		if (! IsPlayerInAnyVehicle(playerid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You must be in a vehicle to use this command.");
		}

		new vehicleid = GetPlayerVehicleID(playerid);
		RepairVehicle(vehicleid);
	  	SetVehicleHealth(vehicleid, 1000.0);

		GameTextForPlayer(playerid, "~b~Vehicle repaired", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have repaired your vehicle.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can repair other player's vehicle by /repair [player].");
    }
	return 1;
}

CMD:addnos(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (! sscanf(params, "u", targetid))
    {
		if (! IsPlayerConnected(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
		}

		if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
		}

		if (! IsPlayerInAnyVehicle(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "Player is not in a vehicle.");
		}

		new vehicleid = GetPlayerVehicleID(targetid);
		switch (GetVehicleModel(vehicleid))
		{
			case 448,461,462,463,468,471,509,510,521,522,523,581,586,449:
			{
				return SendClientMessage(playerid, COLOR_TOMATO, "You cannot add nitros to the current player's vehicle.");
			}
		}

		AddVehicleComponent(vehicleid, 1010);

		GameTextForPlayer(targetid, "~b~Nitros added", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
		PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);

		new buf[150];
		format(buf, sizeof(buf), "You have fliped %s(%i)'s vehicle.", ReturnPlayerName(targetid), targetid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "Admin %s(%i) has flipped your vehicle.", ReturnPlayerName(playerid), playerid);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
    else
    {
		if (! IsPlayerInAnyVehicle(playerid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You must be in a vehicle to use this command.");
		}

		new vehicleid = GetPlayerVehicleID(playerid);
		switch (GetVehicleModel(vehicleid))
		{
			case 448,461,462,463,468,471,509,510,521,522,523,581,586,449:
			{
				return SendClientMessage(playerid, COLOR_TOMATO, "You cannot add nitros to this vehicle.");
			}
		}

        AddVehicleComponent(vehicleid, 1010);

		GameTextForPlayer(playerid, "~b~Nitros added", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have added nitros to your vehicle.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can add nos to other player's vehicle by /addnos [player].");
    }
	return 1;
}

CMD:warn(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new targetid, reason[128];
    if (sscanf(params, "uS(No reason specified)[128]", targetid, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /warn [player] [*reason]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

    if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot warn yourself.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has warned %s(%i) [Reason: %s] (warnings: %i/%i)", ReturnPlayerName(playerid), playerid, ReturnPlayerName(targetid), targetid, reason, pStats[targetid][userWarnings], MAX_WARNINGS);
	SendClientMessageToAll(COLOR_YELLOW, buf);

	pStats[targetid][userWarnings] += 1;
	if (pStats[targetid][userWarnings] >= MAX_WARNINGS)
	{
		format(buf, sizeof(buf), "%s(%i) has been automatically kicked [Reason: Exceeded maximum warnings] (Warnings: %i/%i)", ReturnPlayerName(targetid), targetid, pStats[targetid][userWarnings], MAX_WARNINGS);
	    SendClientMessageToAll(COLOR_RED, buf);
		Kick(targetid);
		return 1;
	}

	format(buf, sizeof(buf), ""WHITE"You have been issued a "RED"WARNING from admin %s(%i).\n\n"TOMATO"Reason:\n"WHITE"%s\n"TOMATO"Warnings count:\n"WHITE"%i/%i", ReturnPlayerName(playerid), playerid, reason, pStats[targetid][userWarnings], MAX_WARNINGS);
  	ShowPlayerDialog(targetid, 0, DIALOG_STYLE_MSGBOX, "Warned by an admin:", buf, "Close", "");
	return 1;
}

CMD:resetwarns(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /resetwarns [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	pStats[targetid][userWarnings] = 0;

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has remove your warning log.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have removed %s(%i)'s warning log.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:flip(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (! sscanf(params, "u", targetid))
    {
		if (! IsPlayerConnected(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
		}

		if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
		}

		if (! IsPlayerInAnyVehicle(targetid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "Player is not in a vehicle.");
		}

		new vehicelid = GetPlayerVehicleID(targetid);
		new Float:angle;
		GetVehicleZAngle(vehicelid, angle);
		SetVehicleZAngle(vehicelid, angle);

		GameTextForPlayer(targetid, "~b~Vehicle fliped", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
		PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);

		new buf[150];
		format(buf, sizeof(buf), "You have fliped %s(%i)'s vehicle.", ReturnPlayerName(targetid), targetid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "Admin %s(%i) has flipped your vehicle.", ReturnPlayerName(playerid), playerid);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
    else
    {
		if (! IsPlayerInAnyVehicle(playerid))
		{
			return SendClientMessage(playerid, COLOR_TOMATO, "You must be in a vehicle to use this command.");
		}

		new vehicelid = GetPlayerVehicleID(targetid);
		new Float:angle;
		GetVehicleZAngle(vehicelid, angle);
		SetVehicleZAngle(vehicelid, angle);

		GameTextForPlayer(playerid, "~b~Vehicle fliped", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have fliped your vehicle.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can flip other player's vehicle by /flip [player].");
    }
	return 1;
}

CMD:ip(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ip [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new buf[150];
	format(buf, sizeof(buf), "%s(%i)'s IP: %s", ReturnPlayerName(targetid), targetid, ReturnPlayerIp(playerid));
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:spawn(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spawn [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    TogglePlayerSpectating(targetid, false);
	}
	SpawnPlayer(targetid);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has respawned you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have respawned %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:goto(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /goto [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't teleport to yourself.");
	}

	if (GetPlayerState(targetid) == PLAYER_STATE_WASTED || GetPlayerState(targetid) == PLAYER_STATE_SPECTATING)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player isn't spawned yet.");
	}

	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

	new Float:x, Float:y, Float:z;
	GetPlayerPos(targetid, x, y, z);

	if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
	    new vehicleid = GetPlayerVehicleID(playerid);
		SetVehiclePos(vehicleid, x, y + 2.5, z);
		LinkVehicleToInterior(vehicleid, GetPlayerInterior(targetid));
		SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(targetid));
	}
	else
	{
		SetPlayerPos(playerid, x, y + 2.0, z);
	}

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have teleported to %s(%i)'s position.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setweather(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new targetid, id;
	if (sscanf(params, "ui", targetid, id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setweather [player] [weatherid]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerWeather(targetid, id);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has changed your weather to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have cahnged %s(%i)'s weather to %i.", ReturnPlayerName(targetid), targetid, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:settime(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new targetid, id;
	if (sscanf(params, "ui", targetid, id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /settime [player] [timeid]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerTime(targetid, id, 0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has changed your time to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have cahnged %s(%i)'s time to %i.", ReturnPlayerName(targetid), targetid, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:kick(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

    new targetid, reason[45];
	if (sscanf(params, "us[128]", targetid, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /kick [player] [reason]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't kick yourself.");
	}

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) has been kicked by admin %s(%i) [Reason: %s]", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, reason);
	SendClientMessageToAll(COLOR_RED, buf);
	Kick(targetid);
	return 1;
}

CMD:asay(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 1)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 1+ to use this command.");
	}

	new message[135];
	if (sscanf(params, "s[135]", message))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /asay [message]");
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i): %s", ReturnPlayerName(playerid), playerid, message);
    SendClientMessageToAll(COLOR_HOT_PINK, buf);
	return 1;
}

//Admin level 2+
CMD:ann(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new message[35];
	if (sscanf(params, "s[35]", message))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ann [message]");
	}

	GameTextForAll(message, 5000, 3);
	return 1;
}

CMD:ann2(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new style, expiretime, message[35];
	if (sscanf(params, "iis[35]", style, expiretime, message))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ann2 [style] [expiretime] [message]");
	}

	GameTextForAll(message, expiretime, style);
	return 1;
}

CMD:jetpack(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid) || ! sscanf(params, "u", targetid) && playerid == targetid)
	{
	    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have spawned a jetpack.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can also give jetpack to other players by /jetpack [player].");
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		return 1;
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerSpecialAction(targetid, SPECIAL_ACTION_USEJETPACK);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given you a jetpack.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have given %s(%i) a jetpack.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:aka(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /aka [player]");
	}

	new SQLRow:keys[1], values[1];
	yoursql_sort_int(SQL:0, "users/ROW_ID", keys, values, .limit = 1);
	new ip[18];
	new aka_count;
	new aka[MAX_PLAYER_NAME * 5];
	for (new i, j = _:keys[0]; i <= j; i++)
	{
	    if (yoursql_get_field(SQL:0, "users/ip", SQLRow:i, ip, 18))
	    {
	        if (ipmatch(ip, ReturnPlayerIp(playerid)))
	        {
	            yoursql_get_field(SQL:0, "users/name", SQLRow:i, aka[aka_count], MAX_PLAYER_NAME);
	            aka_count++;

	            if (aka_count >= 5)
	            {
	                break;
	            }
	        }
	    }
	}

	if (aka_count == 1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The user doesn't have any other account from the same ip.");
	}

	new buf[150];
	format(buf, sizeof(buf), "Search result for %s's AKA: [ip: %s]", ReturnPlayerName(targetid), ReturnPlayerIp(targetid));
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	for (new i = 0, j = aka_count; i < j; i++)
	{
	    strcat(buf, aka[i]);
	    if (j == aka_count - 1)
		{
			strcat(buf, ".");
		}
		else
		{
			strcat(buf, ", ");
		}
	}
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:aweaps(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

    GivePlayerWeapon(playerid, 9, 1);//chainsaw
    GivePlayerWeapon(playerid, 32, 999999);//tec-9
    GivePlayerWeapon(playerid, 16, 999999);//grenades
    GivePlayerWeapon(playerid, 24, 999999);//deagle
    GivePlayerWeapon(playerid, 26, 999999);//sawn off
    GivePlayerWeapon(playerid, 29, 999999);//mp5
    GivePlayerWeapon(playerid, 31, 999999);//m4
    GivePlayerWeapon(playerid, 34, 999999);//sniper
    GivePlayerWeapon(playerid, 38, 999999);//minigun

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	GameTextForPlayer(playerid, "~b~Admin weapons!", 5000, 3);
    return 1;
}

CMD:text(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, message[35];
	if (sscanf(params, "us[35]", targetid, message))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /text [player] [message]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't text message to yourself.");
	}

	GameTextForPlayer(targetid, message, 5000, 3);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has sent you a screen message.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have sent %s(%i) a scren message.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:carhealth(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, Float:amount;
	if (sscanf(params, "uf", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carhealth [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (! IsPlayerInAnyVehicle(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not in any vehicle.");
	}

	SetVehicleHealth(GetPlayerVehicleID(targetid), amount);
	PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your car's health to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s car health to %.2f.", ReturnPlayerName(targetid), targetid, gVehicleModelNames[GetVehicleModel(GetPlayerVehicleID(targetid)) - 400], amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:eject(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /eject [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (! IsPlayerInAnyVehicle(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not in any vehicle.");
	}

	new Float:x, Float:y, Float:z;
	GetPlayerPos(targetid, x, y, z);
	SetPlayerPos(targetid, x, y, z + 1.0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has ejected you from your vehicle.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have ejected %s(%i) from his vehicle.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:carpaint(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, paint;
	if (sscanf(params, "ui", targetid, paint))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carpaint [player] [paintjob]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (! IsPlayerInAnyVehicle(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not in any vehicle.");
	}

	if (paint < 0 || paint > 3)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid paintjob id, must be b/w 0-3.");
	}

	ChangeVehiclePaintjob(GetPlayerVehicleID(targetid), paint);
	PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your vehicle's paintjob id to %i.", ReturnPlayerName(playerid), playerid, paint);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s vehicle's paintjob id to %i.", ReturnPlayerName(targetid), targetid, paint);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:carcolor(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, color1, color2;
	if (sscanf(params, "uiI(-1)", targetid, color1, color2))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carcolor [player] [color1] [*color2]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (! IsPlayerInAnyVehicle(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not in any vehicle.");
	}

	ChangeVehicleColor(GetPlayerVehicleID(targetid), color1, color2);
	PlayerPlaySound(targetid, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);


	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your vehicle's color to %i & %i.", ReturnPlayerName(playerid), playerid, color1, color2);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s vehicle's paintjob to %i & %i.", ReturnPlayerName(targetid), targetid, color1, color2);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:givecar(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

    new targetid, vehicle[32], color1, color2;
	if (sscanf(params, "us[32]I(-1)I(-1)", targetid, vehicle, color1, color2))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givecar [player] [vehicle] [*color1] [*color2]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new model;
	if (isnumeric(vehicle))
	{
		model = strval(vehicle);
	}
	else
	{
		model = GetVehicleModelIDFromName(vehicle);
	}

	if (model < 400 || model > 611)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid vehicle model id/name.");
	}

	if (IsValidVehicle(pStats[playerid][userVehicle]))
	{
		DestroyVehicle(pStats[playerid][userVehicle]);
	}

	new Float:x, Float:y, Float:z, Float:a;
	GetPlayerPos(targetid, x, y, z);
    GetPlayerFacingAngle(targetid, a);

	if (IsPlayerInAnyVehicle(targetid))
	{
		SetPlayerPos(playerid, x, y, z + 1.0);
	}

	pStats[targetid][userVehicle] = CreateVehicle(model, x, y + 2.5, z, a, color1, color2, -1);
    SetVehicleVirtualWorld(pStats[targetid][userVehicle], GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(pStats[targetid][userVehicle], GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, pStats[targetid][userVehicle], 0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given you vehicle %s(model: %i | color1: %i | color2: %i).", ReturnPlayerName(playerid), playerid, gVehicleModelNames[model - 400], model, color1, color2);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have given %s(%i) vehicle %s(model: %i | color1: %i | color2: %i).", ReturnPlayerName(targetid), targetid, gVehicleModelNames[model - 400], model, color1, color2);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:car(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

    new vehicle[32], color1, color2;
	if (sscanf(params, "s[32]I(-1)I(-1)", vehicle, color1, color2))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /car [vehicle] [*color1] [*color2]");
	}

	new model;
	if (isnumeric(vehicle))
	{
		model = strval(vehicle);
	}
	else
	{
		model = GetVehicleModelIDFromName(vehicle);
	}

	if (model < 400 || model > 611)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid vehicle model id/name.");
	}

	if (IsValidVehicle(pStats[playerid][userVehicle]))
	{
		DestroyVehicle(pStats[playerid][userVehicle]);
	}

	new Float:x, Float:y, Float:z, Float:a;
	GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

	if (IsPlayerInAnyVehicle(playerid))
	{
		SetPlayerPos(playerid, x, y, z + 1.0);
	}

	pStats[playerid][userVehicle] = CreateVehicle(model, x, y + 2.5, z, a, color1, color2, -1);
    SetVehicleVirtualWorld(pStats[playerid][userVehicle], GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(pStats[playerid][userVehicle], GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, pStats[playerid][userVehicle], 0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have spawned a vehicle %s(model: %i | color1: %i | color2: %i).", gVehicleModelNames[model - 400], model, color1, color2);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:akill(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, reason[128];
    if (sscanf(params, "uS(No reason specified)[128]", targetid, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /akill [player] [*reason]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

    SetPlayerHealth(targetid, 0.0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) was killed by admin %s(%i) [Reason: %s]", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:jailed(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new info[MAX_PLAYER_NAME * 100], buf[100];

	foreach (new i : Player)
	{
	    if (pStats[i][userJailTime] != -1)
	    {
	    	format(buf, sizeof(buf), "%s(%i) - %i seconds remaining for unjail", i, ReturnPlayerName(i), i, pStats[i][userJailTime]);
	        strcat(info, buf);
	    }
	}

	if (! info[0])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "No players are currently jailed.");
	}
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_ID_JAILED_LIST, DIALOG_STYLE_LIST, "Jailed players:", info, "Close", "");
	}
	return 1;
}

CMD:jail(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, time, reason[128];
	if (sscanf(params, "uI(60)S(No reason specified)[128]", targetid, time, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /jail [player] [*seconds] [*reason]");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot jail yourself.");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		 return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (time > 5 * 60 || time < 10)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The jail time must be b/w 10 - 360(5 minutes) seconds.");
	}

	if (GetPlayerState(targetid) == PLAYER_STATE_WASTED || GetPlayerState(targetid) == PLAYER_STATE_SPECTATING)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player isn't spawned yet.");
	}

	if (pStats[targetid][userJailTime] != -1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already in jail.");
	}

    pStats[targetid][userJailTime] = time;

    SetPlayerInterior(targetid, 3);
	SetPlayerPos(targetid, 197.6661, 173.8179, 1003.0234);
	SetCameraBehindPlayer(targetid);

	new string[144];
	format(string, sizeof(string), "You are in jail for %i seconds.", time);
    SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) has been jailed by admin %s(%i) for %i seconds [Reason: %s]", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "~r~Jailed for ~w~%i ~r~seconds", time);
	GameTextForPlayer(targetid, buf, 5000, 3);
	return 1;
}

CMD:unjail(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unjail [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (pStats[targetid][userJailTime] == -1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is not in jail.");
	}

	pStats[targetid][userJailTime] = -1;
	SpawnPlayer(targetid);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) has been unjailed by admin %s(%i).", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	GameTextForPlayer(targetid, "~g~Unjailed!", 5000, 3);
	return 1;
}

CMD:muted(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new info[MAX_PLAYER_NAME * 100], buf[100];

	foreach (new i : Player)
	{
	    if (pStats[i][userMuteTime] != -1)
	    {
	    	format(buf, sizeof(buf), "%s(%i) - %i seconds remaining for unmute", i, ReturnPlayerName(i), i, pStats[i][userMuteTime]);
	        strcat(info, buf);
	    }
	}

	if (! info[0])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "No players are currently mute.");
	}
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_ID_MUTE_LIST, DIALOG_STYLE_LIST, "Mute players:", info, "Close", "");
	}
	return 1;
}

CMD:mute(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, time, reason[128];
	if (sscanf(params, "uI(60)S(No reason specified)[128]", targetid, time, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /mute [player] [*seconds] [*reason]");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot jail yourself.");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		 return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (time > 5 * 60 || time < 10)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The mute time must be b/w 10 - 360(5 minutes) seconds.");
	}

	if (pStats[targetid][userMuteTime] != -1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already muted.");
	}

	pStats[targetid][userMuteTime] = time;
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) has been muted by admin %s(%i) for %i seconds [Reason: %s]", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "~r~Muted for ~w~%i ~r~seconds", time);
	GameTextForPlayer(targetid, buf, 5000, 3);
	return 1;
}

CMD:unmute(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unmute [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (pStats[targetid][userMuteTime] == -1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already muted.");
	}

	pStats[targetid][userMuteTime] = -1;
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "%s(%i) has been unmuted by admin %s(%i).", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	GameTextForPlayer(targetid, "~g~Unmuted!", 5000, 3);
	return 1;
}

/*CMD:atele(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}
	ShowPlayerDialog(playerid, DIALOG_ID_TELEPORTS, DIALOG_STYLE_LIST, "Select City", "Los Santos\nSan Fierro\nLas Venturas", "Select", "Close");
	return 1;
}*/

CMD:setskin(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, skin;
	if (sscanf(params, "ui", targetid, skin))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setskin [player] [skinid]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (GetPlayerState(targetid) == PLAYER_STATE_WASTED || GetPlayerState(targetid) == PLAYER_STATE_SPECTATING)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player isn't spawned yet.");
	}

	if (skin < 0 || skin == 74 || skin > 311)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid skin id, must be b/w 0 - 311 (except 74).");
	}

    SetPlayerSkin(targetid, skin);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your skin id to %i.", ReturnPlayerName(playerid), playerid, skin);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s skin id to %i.", ReturnPlayerName(targetid), targetid, skin);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:cc(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	for (new i; i < 250; i++)
	{
		SendClientMessageToAll(-1, " ");
	}
	foreach (new i : Player)
	{
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has cleared the chat.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:heal(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /heal [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

    SetPlayerHealth(targetid, 100.0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has healed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have healed %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:armour(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
    if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /armour [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

    SetPlayerArmour(targetid, 100.0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has armoured you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have armoured %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setinterior(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, id;
	if (sscanf(params, "ui", targetid, id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setinterior [player] [interior]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerInterior(targetid, id);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your interior id to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s interior id to %i.", ReturnPlayerName(targetid), targetid, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setworld(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, id;
	if (sscanf(params, "ui", targetid, id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setworld [player] [worldid]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerVirtualWorld(targetid, id);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your virtual world id to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s virtual world id to %i.", ReturnPlayerName(targetid), targetid, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:slap(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

    new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /slap [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new Float:x, Float:y, Float:z;
	GetPlayerPos(targetid, x, y, z);
	SetPlayerPos(targetid, x, y, z + 5.0);

    PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
    PlayerPlaySound(targetid, 1190, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have slapped %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:explode(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /explode [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new Float:x, Float:y, Float:z;
	GetPlayerPos(targetid, x, y, z);
	CreateExplosion(x, y, z, 7, 1.00);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have made an explosion on %s(%i)'s position.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:disarm(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /disarm [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	ResetPlayerWeapons(targetid);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has disarmed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have disarmed %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:ban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new targetid, reason[35], days;
	if (sscanf(params, "is[35]I(0)", targetid, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ban [player] [reason] [*days (default 0 permanent)]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

    if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", ReturnPlayerName(targetid), "ip", ReturnPlayerIp(targetid), "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (1) : (0), "expire", time);

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) [PERMANENT].", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) for %i days [TEMPERORARY].", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

 	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	Kick(targetid);
	return 1;
}

CMD:ipban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new ip[18], reason[35], days;
	if (sscanf(params, "s[18]s[35]I(0)", ip, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ipban [ip] [reason] [*days (default 0 permanent)]");
	}

	if (! IsValidIp(ip))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid Ip. specified.");
	}

    if (! strcmp(ip, ReturnPlayerIp(playerid)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < yoursql_get_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "ip = %s", ip)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	new name[MAX_PLAYER_NAME];
	yoursql_get_field(SQL:0, "users/name", yoursql_get_row(SQL:0, "users", "ip = %s", ip), name, MAX_PLAYER_NAME);
	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", name, "ip", ip, "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (1) : (0), "expire", time);

	new id = -1;
	foreach (new i : Player)
	{
	    if (! strcmp(ip, ReturnPlayerIp(i)))
	    {
	        id = i;
	        break;
	    }
	}

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) [PERMANENT].", name, id, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) for %i days [TEMPERORARY].", name, id, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

 	PlayerPlaySound(id, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	Kick(id);
	return 1;
}

CMD:oban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new name[MAX_PLAYER_NAME], reason[35], days;
	if (sscanf(params, "s[24]s[35]I(0)", name, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /oban [name] [reason] [*days (default 0 permanent)]");
	}

	if (yoursql_get_row(SQL:0, "users", "name = %s", name) == SQL_INVALID_ROW)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified username isn't registered.");
	}

    if (! strcmp(name, ReturnPlayerName(playerid)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < yoursql_get_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "name = %s", name)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	new ip[18];
	yoursql_get_field(SQL:0, "users/ip", yoursql_get_row(SQL:0, "users", "name = %s", name), ip);
	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", name, "ip", ip, "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (1) : (0), "expire", time);

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s has been offline banned by admin %s(%i) [PERMANENT].", name, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been offline banned by admin %s(%i) for %i days [TEMPERORARY].", name, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:searchban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new search[MAX_PLAYER_NAME];
	if (sscanf(params,"s[24]", search))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /searchban [name/ip]");
	}

	new SQLRow:rowid;
	if (IsValidIp(search))
	{
	    rowid = yoursql_get_row(SQL:0, "bans", "ip = %s", search);
		if (rowid == SQL_INVALID_ROW)
		{
		    return SendClientMessage(playerid, COLOR_TOMATO, "The specified ip isn't banned.");
		}
	}
	else
	{
	    rowid = yoursql_get_row(SQL:0, "bans", "name = %s", search);
		if (rowid == SQL_INVALID_ROW)
		{
		    return SendClientMessage(playerid, COLOR_TOMATO, "The specified name isn't banned.");
		}
	}

	new buf[1000];
	strcat(buf, WHITE);

	strcat(buf, "You have been banned from the server.\n");
	strcat(buf, "If this was a mistake (from server/admin side), please report a BAN APPEAL on our forums.\n\n");

	if (IsValidIp(search))
	{
		strcat(buf, "Username: "PINK"");
	    new name[MAX_PLAYER_NAME];
		yoursql_get_field(SQL:0, "bans/name", rowid, name, MAX_PLAYER_NAME);
		strcat(buf, name);
		strcat(buf, "\n"WHITE"");

		strcat(buf, "Ip: "PINK"");
		strcat(buf, search);
		strcat(buf, "\n"WHITE"");
 	}
 	else
 	{
		strcat(buf, "Username: "PINK"");
 	    strcat(buf, search);
		strcat(buf, "\n"WHITE"");

		strcat(buf, "Ip: "PINK"");
	    new ip[18];
		yoursql_get_field(SQL:0, "bans/ip", rowid, ip);
		strcat(buf, ip);
		strcat(buf, "\n"WHITE"");
 	}

 	new value[100];

	strcat(buf, "Ban date: "PINK"");
	yoursql_get_field(SQL:0, "bans/date", rowid, value);
	strcat(buf, value);
	strcat(buf, "\n"WHITE"");

	strcat(buf, "Admin name: "PINK"");
	yoursql_get_field(SQL:0, "bans/admin_name", rowid, value);
	strcat(buf, value);
	strcat(buf, "\n"WHITE"");

	switch (yoursql_get_field_int(SQL:0, "bans/type", rowid))
	{
		case 0:
		{
			strcat(buf, "Ban type: "PINK"");
			strcat(buf, "PERMANENT");
			strcat(buf, "\n"WHITE"");
		}
		case 1:
		{
			strcat(buf, "Ban type: "PINK"");
			strcat(buf, "TEMPORARY (expire on: ");
			new year, month, day, hour, minute, second;
			TimestampToDate(yoursql_get_field_int(SQL:0, "bans/expire", rowid), year, month, day, hour, minute, second, 0);
			new month_name[15];
			switch (month)
			{
			    case 1: month_name = "January";
			    case 2: month_name = "Feburary";
			    case 3: month_name = "March";
			    case 4: month_name = "April";
			    case 5: month_name = "May";
			    case 6: month_name = "June";
			    case 7: month_name = "July";
			    case 8: month_name = "August";
			    case 9: month_name = "September";
			    case 10: month_name = "October";
			    case 11: month_name = "November";
			    case 12: month_name = "December";
			}
			format(buf, sizeof(buf), "%s%i %s, %i)", buf, day, month_name, year);
			strcat(buf, "\n"WHITE"");
		}
		case 2:
		{
			strcat(buf, "Ban type: "PINK"");
			strcat(buf, "RANGEBAN");
			strcat(buf, "\n"WHITE"");
		}
		case 3:
		{
			strcat(buf, "Ban type: "PINK"");
			strcat(buf, "TEMPORARY RANGEBAN (expire on: ");
			new year, month, day, hour, minute, second;
			TimestampToDate(yoursql_get_field_int(SQL:0, "bans/expire", rowid), year, month, day, hour, minute, second, 0);
			new month_name[15];
			switch (month)
			{
			    case 1: month_name = "January";
			    case 2: month_name = "Feburary";
			    case 3: month_name = "March";
			    case 4: month_name = "April";
			    case 5: month_name = "May";
			    case 6: month_name = "June";
			    case 7: month_name = "July";
			    case 8: month_name = "August";
			    case 9: month_name = "September";
			    case 10: month_name = "October";
			    case 11: month_name = "November";
			    case 12: month_name = "December";
			}
			format(buf, sizeof(buf), "%s%i %s, %i)", buf, day, month_name, year);
			strcat(buf, "\n"WHITE"");
		}
	}

	strcat(buf, "Reason: "RED"");
	yoursql_get_field(SQL:0, "bans/reason", rowid, value);
	strcat(buf, value);
	strcat(buf, "\n\n"WHITE"");

	strcat(buf, "Take a screenshot of this as a refrence for admins.");

	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Ban search result:", buf, "Close", "");

	return 1;
}

CMD:unban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 2)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 2+ to use this command.");
	}

	new search[MAX_PLAYER_NAME];
	if (sscanf(params,"s[24]", search))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unban [name/ip]");
	}

	new SQLRow:rowid;
	if (IsValidIp(search))
	{
	    rowid = yoursql_get_row(SQL:0, "bans", "ip = %s", search);
		if (rowid == SQL_INVALID_ROW)
		{
		    return SendClientMessage(playerid, COLOR_TOMATO, "The specified ip isn't banned.");
		}
	}
	else
	{
	    rowid = yoursql_get_row(SQL:0, "bans", "name = %s", search);
		if (rowid == SQL_INVALID_ROW)
		{
		    return SendClientMessage(playerid, COLOR_TOMATO, "The specified name isn't banned.");
		}
	}

	yoursql_delete_row(SQL:0, "bans", rowid);

	new buf[150];
	if (IsValidIp(search))
	{
		format(buf, sizeof(buf), "You have unbanned ip %s successfully.", search);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);

		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	}
	else
	{
		format(buf, sizeof(buf), "Admin %s(%i) have unbanned user %s.", ReturnPlayerName(playerid), playerid, search);
		SendClientMessageToAll(COLOR_DODGER_BLUE, buf);

		foreach (new i : Player)
		{
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		}
	}

	return 1;
}

//Admin level 3+
CMD:get(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /get [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot get yourself.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	if (GetPlayerState(targetid) == PLAYER_STATE_DRIVER)
	{
	    new vehicleid = GetPlayerVehicleID(targetid);
		SetVehiclePos(vehicleid, x, y + 2.5, z);
		LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
	}
	else
	{
		SetPlayerPos(targetid, x, y + 2.0, z);
	}
	SetPlayerInterior(targetid, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has teleported you to his/her position.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have teleport %s(%i) to your position.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:write(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new text[144], color;
	if (sscanf(params, "s[144]I(1)", text, color))
	{
		SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /write [text] [*color]");
		SendClientMessage(playerid, COLOR_THISTLE, "COLOR: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
		return 1;
	}

	if (color > 9 || color > 0)
	{
		SendClientMessage(playerid, COLOR_TOMATO, "Invalid color id, must be b/w 0-9.");
		SendClientMessage(playerid, COLOR_THISTLE, "COLOR: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
		return 1;
	}

	switch(color)
	{
	    case 0: color = COLOR_BLACK;
	    case 1: color = COLOR_WHITE;
	    case 2: color = COLOR_RED;
	    case 3: color = COLOR_ORANGE;
	    case 4: color = COLOR_YELLOW;
	    case 5: color = COLOR_GREEN;
	    case 6: color = COLOR_BLUE;
	    case 7: color = COLOR_PURPLE;
	    case 8: color = COLOR_BROWN;
	    case 9: color = COLOR_PINK;
	}
	SendClientMessageToAll(color, text);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:force(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /force [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	ForceClassSelection(targetid);
	SetPlayerHealth(targetid, 0.0);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has forced you to class selection.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have forced %s(%i) to class selection.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:healall(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	foreach (new i : Player)
	{
		SetPlayerHealth(i, 100.0);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

    new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has healed all players.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:armourall(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	foreach (new i : Player)
	{
		SetPlayerArmour(i, 100.0);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has armoured all players.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:fightstyle(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, style;
    if (sscanf(params, "ui", targetid, style))
	{
		SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fightstyle [player] [style]");
		SendClientMessage(playerid, COLOR_THISTLE, "STYLES: [0]Normal, [1]Boxing, [2]Kungfu, [3]Kneehead, [4]Grabkick, [5]Elbow");
		return 1;
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (style > 5 || style < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Inavlid fighting style, must be b/w 0-5.");
	}
	new stylename[15];
	switch(style)
	{
	    case 0:
	    {
	        SetPlayerFightingStyle(targetid, 4);
	        stylename = "Normal";
	    }
	    case 1:
	    {
	        SetPlayerFightingStyle(targetid, 5);
	        stylename = "Boxing";
	    }
	    case 2:
	    {
	        SetPlayerFightingStyle(targetid, 6);
	        stylename = "Kung Fu";
	    }
	    case 3:
	    {
	        SetPlayerFightingStyle(targetid, 7);
	        stylename = "Kneehead";
	    }
	    case 4:
	    {
	        SetPlayerFightingStyle(targetid, 15);
	        stylename = "Grabkick";
	    }
	    case 5:
	    {
	        SetPlayerFightingStyle(targetid, 16);
	        stylename = "Elbow";
	    }
	}
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your fighting style to (%i)%s.", ReturnPlayerName(playerid), playerid, stylename, style);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s fighting style to (%i)%s.", ReturnPlayerName(targetid), targetid, stylename, style);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:sethealth(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, Float:amount;
	if (sscanf(params, "uf", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /sethealth [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerHealth(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your health to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s health to %.2f.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setarmour(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, Float:amount;
	if (sscanf(params, "uf", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setarmour [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerArmour(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your armour to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s armour to %.2f.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:god(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	if (! pStats[playerid][userGod])
	{
	    SetPlayerHealth(playerid, FLOAT_INFINITY);
	    GameTextForPlayer(playerid, "~g~Godmode ON", 3000, 3);

	    pStats[playerid][userGod] = true;
	}
	else
	{
	    SetPlayerHealth(playerid, 100.0);
	    GameTextForPlayer(playerid, "~r~Godmode OFF", 3000, 3);

	    pStats[playerid][userGod] = false;
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:godcar(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	if (! pStats[playerid][userGodCar])
	{
	    SetVehicleHealth(GetPlayerVehicleID(playerid), FLOAT_INFINITY);
	    GameTextForPlayer(playerid, "~g~Godcarmode ON", 3000, 3);

	    pStats[playerid][userGodCar] = true;
	}
	else
	{
	    SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
	    GameTextForPlayer(playerid, "~r~Godcarmode OFF", 3000, 3);

	    pStats[playerid][userGodCar] = false;
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:freeze(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, reason[35];
	if (sscanf(params, "uS(No reason specified)[35]", targetid, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /freeze [playerid] [*reason]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	TogglePlayerControllable(targetid, false);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has freezed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have freezed %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid;
	if (sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unfreeze [playerid]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	TogglePlayerControllable(targetid, true);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has unfreezed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have unfreezed %s(%i).", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:giveweapon(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, weapon[32], ammo;
	if (sscanf(params, "us[32]I(250)", targetid, weapon, ammo))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveweapon [player] [weapon] [*ammo]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new weaponid;
	if (isnumeric(weapon))
	{
		weaponid = strval(weapon);
	}
	else
	{
		weaponid = GetWeaponIDFromName(weapon);
	}

	if (1 > weaponid > 46)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid weapon id/name.");
	}

	GetWeaponName(weaponid, weapon, sizeof(weapon));
	GivePlayerWeapon(targetid, weaponid, ammo);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given you a %s[id: %i] with %i ammo.", ReturnPlayerName(playerid), playerid, weapon, weaponid, ammo);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have given %s(%i) a %s[id: %i] with %i ammo.", ReturnPlayerName(targetid), targetid, weapon, weaponid, ammo);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setcolor(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, color;
	if (sscanf(params, "ui", targetid, color))
	{
		SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setcolor [player] [color]");
		SendClientMessage(playerid, COLOR_THISTLE, "COLOR: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
		return 1;
	}

	if (color > 9 || color > 0)
	{
		SendClientMessage(playerid, COLOR_TOMATO, "Invalid color id, must be b/w 0-9.");
		SendClientMessage(playerid, COLOR_THISTLE, "COLOR: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
		return 1;
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new colorname[15];
	switch(color)
	{
	    case 0: color = COLOR_BLACK, colorname = "Black";
    	case 1: color = COLOR_WHITE, colorname = "White";
     	case 2: color = COLOR_RED, colorname = "Red";
      	case 3: color = COLOR_ORANGE, colorname = "Orange";
      	case 4: color = COLOR_YELLOW, colorname = "Yellow";
    	case 5: color = COLOR_GREEN, colorname = "Green";
       	case 6: color = COLOR_BLUE, colorname = "Blue";
      	case 7: color = COLOR_PURPLE, colorname = "Purple";
       	case 8: color = COLOR_BROWN, colorname = "Brown";
       	case 9: color = COLOR_PINK, colorname = "Pink";
	}

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your color to %s.", ReturnPlayerName(playerid), playerid, colorname);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s[%i]'s color to %s.", ReturnPlayerName(targetid), targetid, colorname);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setcash(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setcash [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	ResetPlayerMoney(targetid);
	GivePlayerMoney(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your money to $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s money to $%i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setscore(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setscore [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	SetPlayerScore(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your score to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s score to %i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:givecash(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givecash [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	GivePlayerMoney(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given you money $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have given %s(%i)'s money $%i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:givescore(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givescore [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	SetPlayerScore(targetid, amount);
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given you score to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have given %s(%i)'s score %i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:spawncar(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new vehicleid;
	if (sscanf(params, "i", vehicleid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spawncar [vehicleid]");
	}

	if (! IsValidVehicle(vehicleid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified vehicle is not created.");
	}

	SetVehicleToRespawn(vehicleid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have respawned vehicle id %i.", vehicleid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:destroycar(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new vehicleid;
	if (sscanf(params, "i", vehicleid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroycar [vehicleid]");
	}

	if (! IsValidVehicle(vehicleid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified vehicle is not created.");
	}

	SetVehicleToRespawn(vehicleid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have destroyed vehicle id %i.", vehicleid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setkills(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setkills [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	yoursql_set_field_int(SQL:0, "users/kills", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(targetid)), amount);
	pStats[playerid][userKills] = amount;

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your kills to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s kills to %i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setdeaths(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	new targetid, amount;
	if (sscanf(params, "ui", targetid, amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setdeaths [player] [amount]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	yoursql_set_field_int(SQL:0, "users/deaths", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(targetid)), amount);
	pStats[playerid][userDeaths] = amount;

	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set your deaths to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
	format(buf, sizeof(buf), "You have set %s(%i)'s deahs to %i.", ReturnPlayerName(targetid), targetid, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:spawncars(playerid)
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 3)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 3+ to use this command.");
	}

	for (new i; i < MAX_VEHICLES; i++)
	{
	    foreach (new p : Player)
	    {
	        if (GetPlayerVehicleID(p) == i)
	        {
	            break;
			}
			else
			{
				SetVehicleToRespawn(i);
			}
        }
	}

	foreach (new i : Player)
	{
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) have respawned all unused vehicles.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

//Admin level 4+
CMD:rban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new targetid, reason[35], days;
	if (sscanf(params, "is[35]I(0)", targetid, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /rban [player] [reason] [*days (default 0 permanent)]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

    if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", ReturnPlayerName(targetid), "ip", ReturnPlayerIp(targetid), "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (3) : (2), "expire", time);

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) [RANGE PERMANENT].", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) for %i days [RANGE TEMPERORARY].", ReturnPlayerName(targetid), targetid, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

 	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	Kick(targetid);
	return 1;
}

CMD:ripban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new ip[18], reason[35], days;
	if (sscanf(params, "s[18]s[35]I(0)", ip, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ripban [ip] [reason] [*days (default 0 permanent)]");
	}

	if (! IsValidIp(ip))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid Ip. specified.");
	}

    if (! strcmp(ip, ReturnPlayerIp(playerid)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < yoursql_get_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "ip = %s", ip)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	new name[MAX_PLAYER_NAME];
	yoursql_get_field(SQL:0, "users/name", yoursql_get_row(SQL:0, "users", "ip = %s", ip), name, MAX_PLAYER_NAME);
	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", name, "ip", ip, "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (3) : (2), "expire", time);

	new id = -1;
	foreach (new i : Player)
	{
	    if (! strcmp(ip, ReturnPlayerIp(i)))
	    {
	        id = i;
	        break;
	    }
	}

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) [RANGE PERMANENT].", name, id, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been banned by admin %s(%i) for %i days [RANGE TEMPERORARY].", name, id, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

 	PlayerPlaySound(id, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	Kick(id);

	return 1;
}

CMD:roban(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new name[MAX_PLAYER_NAME], reason[35], days;
	if (sscanf(params, "s[24]s[35]I(0)", name, reason, days))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /roban [name] [reason] [*days (default 0 permanent)]");
	}

	if (yoursql_get_row(SQL:0, "users", "name = %s", name) == SQL_INVALID_ROW)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified username isn't registered.");
	}

    if (! strcmp(name, ReturnPlayerName(playerid)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You can't ban yourself.");
	}

	if (pStats[playerid][userAdmin] < yoursql_get_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "name = %s", name)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (days < 0)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");
	}

	if (strlen(reason) < 3 || strlen(reason) > 35)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid reason length, must be b/w 0-35 characters.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);

	new month[15];
	switch (date[1])
	{
	    case 1: month = "January";
	    case 2: month = "Feburary";
	    case 3: month = "March";
	    case 4: month = "April";
	    case 5: month = "May";
	    case 6: month = "June";
	    case 7: month = "July";
	    case 8: month = "August";
	    case 9: month = "September";
	    case 10: month = "October";
	    case 11: month = "November";
	    case 12: month = "December";
	}

	format(bandate, sizeof(bandate), "%02i %s, %i", date[2], month, date[0]);

	if (days == 0)
	{
		time = 0;
	}
	else
	{
		time = ((days * 24 * 60 * 60) + gettime());
	}

	new ip[18];
	yoursql_get_field(SQL:0, "users/ip", yoursql_get_row(SQL:0, "users", "name = %s", name), ip);
	yoursql_multiset_row(SQL:0, "bans", "sssssii", "name", name, "ip", ip, "admin_name", ReturnPlayerName(playerid), "reason", reason, "date", bandate, "type", (! days) ? (3) : (2), "expire", time);

	new buf[150];
	if (! days)
	{
	    format(buf, sizeof(buf), "%s(%i) has been offline banned by admin %s(%i) [RANGE PERMANENT].", name, ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}
	else
	{
	    format(buf, sizeof(buf), "%s(%i) has been offline banned by admin %s(%i) for %i days [RANGE TEMPERORARY].", name, ReturnPlayerName(playerid), playerid, days);
		SendClientMessageToAll(COLOR_RED, buf);
	    format(buf, sizeof(buf), "Reason: %s", reason);
		SendClientMessageToAll(COLOR_RED, buf);
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:fakedeath(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new targetid, killerid, weaponid;
	if (sscanf(params, "uui", targetid, killerid, weaponid))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fakedeath [player] [killer] [weapon]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (! IsPlayerConnected(killerid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified killer is not conected.");
	}

	if (0 > weaponid > 51)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid weapon id.");
	}

	new weaponname[35];
	GetWeaponName(weaponid, weaponname, sizeof(weaponname));
	SendDeathMessage(killerid, targetid, weaponid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Fake death sent [Player: %s | Killer: %s | Weapon: %s]", ReturnPlayerName(targetid), ReturnPlayerName(killerid), weaponname);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:muteall(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	for (new i; i < MAX_PLAYERS; i++)
	{
        if (i != playerid)
        {
            if (pStats[playerid][userAdmin] < pStats[i][userAdmin])
            {
                pStats[i][userMuteTime] = 100000000;
            }
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has muted all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:unmuteall(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	for (new i; i < MAX_PLAYERS; i++)
	{
        pStats[i][userMuteTime] = -1;
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has unmuted all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setpass(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new name[MAX_PLAYER_NAME], newpass[35];
	if (sscanf(params, "s[24]s[35]", name, newpass))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setpass [name] [new password]");
	}

	new SQLRow:rowid = yoursql_get_row(SQL:0, "users", "name = %s", name);
	if (rowid == SQL_INVALID_ROW)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified username isn't registered.");
	}

	if (pStats[playerid][userAdmin] < yoursql_get_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "name = %s", name)))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (strlen(newpass) < 4 || strlen(newpass) > 30)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid password length, must be b/w 4-30 characters.");
	}

	new hash[128];
	SHA256_PassHash(newpass, "aafGEsq13", hash, sizeof(hash));
	yoursql_set_field(SQL:0, "bans/password", rowid, hash);

	new buf[150];
 	format(buf, sizeof(buf), "You have reseted the password of '%s [A/C Id: %i]' to '%s'.", name, _:rowid, newpass);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	return 1;
}

CMD:giveallscore(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new amount;
	if (sscanf(params, "i", amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallscore [amount]");
	}

	foreach (new i : Player)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerScore(i, GetPlayerScore(i) + amount);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given all players %i score.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:giveallcash(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new amount;
	if (sscanf(params, "i", amount))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallcash [amount]");
	}

	foreach (new i : Player)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		GivePlayerMoney(i, amount);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given all players $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setalltime(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new id;
	if (sscanf(params, "i", id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setalltime [id]");
	}

	foreach (new i : Player)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerTime(i, id, 0);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set all players time to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setallweather(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new id;
	if (sscanf(params, "i", id))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setallweather [id]");
	}

	foreach (new i : Player)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerWeather(i, id);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has set all players weather to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:cleardwindow(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	for (new i; i < 10; i++)
	{
		SendDeathMessage(6000, 5005, 255);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has cleared all players death window.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:giveallweapon(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new weapon[32], ammo;
	if (sscanf(params, "s[32]I(250)", weapon, ammo))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallweapon [weapon] [ammo]");
	}

	new weaponid;
	if (isnumeric(weapon))
	{
		weaponid = strval(weapon);
	}
	else
	{
		weaponid = GetWeaponIDFromName(weapon);
	}

	if (1 > weaponid > 46)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid weapon id/name.");
	}

	GetWeaponName(weaponid, weapon, sizeof(weapon));
   	foreach (new i : Player)
	{
		GivePlayerWeapon(i, weaponid, ammo);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new buf[150];
	format(buf, sizeof(buf), "Admin %s(%i) has given all players %s[id: %i] with %i ammo.", ReturnPlayerName(playerid), playerid, weapon, weaponid, ammo);
	SendClientMessageToAll(COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:object(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new model;
	if (sscanf(params, "i", model))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /object [model]");
	}

	if (0 > model > 20000)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified model is invalid.");
	}

	new Float:x, Float:y, Float:z, Float:a;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, a);

	GetXYInFrontOfPlayer(playerid, x, y, 2.0);

	new object = CreateObject(model, x, y, z, 0, 0, a);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have created a new object (model: %i, id: %i).", model, object);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You can edit the object via /editobject and destroy it via /destroyobject.");
	return 1;
}

CMD:destroyobject(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new object;
	if (sscanf(params, "i", object))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroyobject [object]");
	}

	if (! IsValidObject(object))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified object is invalid.");
	}

	DestroyObject(object);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have destroyed the object id %i.", object);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:editobject(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new object;
	if (sscanf(params, "i", object))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /editobject [object]");
	}

	if (! IsValidObject(object))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified object is invalid.");
	}

	EditObject(playerid, object);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You are now editing the object id %i.", object);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "Hold SPACE and use MOUSE to move camera.");
	return 1;
}

CMD:pickup(playerid, params[])
{
	if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You cannot perform this command when spectating.");
	}

	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new model;
	if (sscanf(params, "i", model))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /pickup [model]");
	}

	if (0 > model > 20000)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified model is invalid.");
	}

	new Float:x, Float:y, Float:z, Float:a;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, a);

	GetXYInFrontOfPlayer(playerid, x, y, 2.0);

	new pickup = CreatePickup(model, 1, x, y, z, 0);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have created a new pickup (model: %i, id: %i).", model, pickup);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You can destroy the pickup via /destroypickup.");
	return 1;
}

CMD:destroypickup(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 4)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 4+ to use this command.");
	}

	new pickup;
	if (sscanf(params, "i", pickup))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroypickup [pickup]");
	}

	if (0 <= pickup < MAX_PICKUPS)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified pickup is invalid.");
	}

	DestroyPickup(pickup);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have destroyed the pickup id %i.", pickup);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

//Admin level 5+
CMD:gmx(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 5)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 5+ to use this command.");
	}

	new time;
	if (sscanf(params, "I(0)", time))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /gmx [*interval]");
	}

	if (time < 0 || time > 5 * 60)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid restart time, must be b/w 0-360 seconds.");
	}

	if (time > 0)
	{
	    SendClientMessageToAll(COLOR_ORANGE, "_______________________________________________");
	    SendClientMessageToAll(COLOR_ORANGE, " ");
		new buf[150];
		format(buf, sizeof(buf), "Admin %s(%i) has set the gamemode to reboot. The restart will occur in %i seconds.", ReturnPlayerName(playerid), playerid, time);
		SendClientMessageToAll(COLOR_ORANGE_RED, buf);
	    SendClientMessageToAll(COLOR_ORANGE, " ");
	    SendClientMessageToAll(COLOR_ORANGE, "_______________________________________________");

	    SetTimer("OnServerRequestRestart", time * 1000, false);
	}
	else
	{
	    SendClientMessageToAll(COLOR_ORANGE, "_______________________________________________");
	    SendClientMessageToAll(COLOR_ORANGE, " ");
		new buf[150];
		format(buf, sizeof(buf), "Admin %s(%i) has restarted the gamemode, please wait while the server startsup again.", ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_ORANGE_RED, buf);
	    SendClientMessageToAll(COLOR_ORANGE, " ");
	    SendClientMessageToAll(COLOR_ORANGE, "_______________________________________________");

	    SendRconCommand("gmx");
	}
	return 1;
}

forward OnServerRequestRestart();
public 	OnServerRequestRestart()
{
	SendRconCommand("gmx");
}

CMD:fakechat(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 5)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 5+ to use this command.");
	}

	new targetid, text[129];
	if (sscanf(params, "us[129]", targetid, text))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fakechat [player] [text]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    new buf[150];
	format(buf, sizeof(buf), "(%i) %s: %s", targetid, ReturnPlayerName(targetid), text);
    SendClientMessageToAll(GetPlayerColor(targetid), buf);
	format(buf, sizeof(buf), "Fake chat sent [Player: %s(%i) | Text: %s]", ReturnPlayerName(targetid), targetid, text);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:setlevel(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 5)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 5+ to use this command.");
	}

	new targetid, level;
	if (sscanf(params, "ui", targetid, level))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setlevel [player] [level]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	new buf[150];
	if (level < 0 || level > MAX_ADMIN_LEVELS)
	{
		format(buf, sizeof(buf), "Invalid level, mus be b/w 0-%i.", MAX_ADMIN_LEVELS);
		return SendClientMessage(playerid, COLOR_TOMATO, buf);
	}

	if (level == pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already of that level.");
	}

    if (pStats[playerid][userAdmin] < level)
    {
        GameTextForPlayer(targetid, "~g~~h~~h~~h~Promoted", 5000, 1);
		format(buf, sizeof(buf), "You have been promoted to admin level %i by %s(%i), Congratulation.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "You have promoted %s(%i) to admin level %i.", ReturnPlayerName(targetid), targetid, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
    else if (pStats[playerid][userAdmin] > level)
    {
        GameTextForPlayer(targetid, "~r~~h~~h~~h~Demoted", 5000, 1);
		format(buf, sizeof(buf), "You have been demoted to admin level %i by %s(%i), Sorry.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "You have demoted %s(%i) to admin level %i.", ReturnPlayerName(targetid), targetid, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	yoursql_set_field_int(SQL:0, "users/admin", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(targetid)), level);

    pStats[targetid][userAdmin] = level;
	return 1;
}

CMD:setpremium(playerid, params[])
{
	if (! IsPlayerAdmin(playerid) && pStats[playerid][userAdmin] < 5)
	{
	    return SendClientMessage(playerid, COLOR_TOMATO, "You must be admin level 5+ to use this command.");
	}

	new targetid, set;
	if (sscanf(params, "ui", targetid, set))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setpremium [player] [1 - set/0 - remove]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	if (pStats[playerid][userAdmin] < pStats[targetid][userAdmin])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot use this command on higher level admin.");
	}

	if (0 > set > 1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid 'set' value, use 0 to remove premium or 1 to set premium");
	}

	if (pStats[targetid][userPremium] && set)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already a premium user.");
	}
	else if (! pStats[targetid][userPremium] && ! set)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Player is already non-premium user.");
	}

	new buf[150];
    if (! pStats[targetid][userPremium] && set)
    {
        GameTextForPlayer(targetid, "~g~~h~~h~~h~Premium", 5000, 1);
		format(buf, sizeof(buf), "You have been set as a premium user by admin %s(%i), Congratulation.", ReturnPlayerName(playerid), playerid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "You have set %s(%i) to a premium user.", ReturnPlayerName(targetid), targetid);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
    else
    {
        GameTextForPlayer(targetid, "~r~~h~~h~~h~Premium removed", 5000, 1);
		format(buf, sizeof(buf), "Your premium has been removed by admin %s(%i).", ReturnPlayerName(playerid), playerid);
		SendClientMessage(targetid, COLOR_DODGER_BLUE, buf);
		format(buf, sizeof(buf), "You have removed %s(%i)'s premium eligablity.", ReturnPlayerName(targetid), targetid);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
    }
	PlayerPlaySound(targetid, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	yoursql_set_field_int(SQL:0, "users/vip", yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(targetid)), set);

    pStats[targetid][userPremium] = bool:set;
	return 1;
}

//Player commands
CMD:admins(playerid)
{
	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	SendClientMessage(playerid, COLOR_GREEN, "- Online Administrators -");
	new color, status[10], rank[25], buf[150];
	foreach (new i : Player)
	{
	    if (pStats[i][userAdmin] || IsPlayerAdmin(i))
	    {
	        if (pStats[i][userOnDuty])
			{
			    color = COLOR_HOT_PINK;
				status = "On Duty";
	        }
			else
			{
			    color = COLOR_WHITE;
				status = "Playing";
			}

			if (IsPlayerAdmin(i))
			{
				rank = "RCON Administrator";
			}
			else
			{
			    switch (pStats[i][userAdmin])
			    {
			        case 1: rank = "Moderator";
			        case 2: rank = "Junior Administrator";
			        case 3: rank = "Senior Administrator";
			        case 4: rank = "Lead Administrator";
			        case 5: rank = "Server Manager";
					default: rank = "Server Owner";
			    }
   			}

	    	format(buf, sizeof(buf), "%s(%i) | Level: %i(%s) | Status: %s", ReturnPlayerName(i), i, pStats[i][userAdmin], rank, status);
	        SendClientMessage(playerid, color, buf);
	    }
	}
	if (! buf[0])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "No admin online.");
	}
	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	return 1;
}

CMD:vips(playerid)
{
	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	SendClientMessage(playerid, COLOR_GREEN, "- Online Premium Users -");
	new buf[150];
	foreach (new i : Player)
	{
	    if (pStats[i][userPremium])
	    {
		    format(buf, sizeof(buf), "%s(%i)", ReturnPlayerName(i), i);
		    SendClientMessage(playerid, COLOR_WHITE, buf);
		}
	}
	if (! buf[0])
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "No vip/premium user online.");
	}
	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	return 1;
}

CMD:report(playerid, params[])
{
	new targetid, reason[100];
	if (sscanf(params, "us[100]", targetid, reason))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /report [player] [reason]");
	}

	if (strlen(reason) < 1)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Report reason length must not be empty.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot report yourself.");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	new hour, minute, second;
	gettime(hour, minute, second);

	new buf[145];
	format(buf, sizeof(buf), "REPORT: %s(%i) has reported against %s(%i), type /reports to check it.", ReturnPlayerName(playerid), playerid, ReturnPlayerName(targetid), targetid);
	foreach (new i : Player)
	{
		if (pStats[i][userAdmin] || IsPlayerAdmin(i))
		{
			SendClientMessage(i, COLOR_RED, buf);
		}
	}

	for (new i, j = sizeof(gReport) - 1; i < j; i++)
	{
	    gReport[i + 1][rAgainst] = gReport[i][rAgainst];
	    gReport[i + 1][rAgainstId] = gReport[i][rAgainstId];
	    gReport[i + 1][rBy] = gReport[i][rBy];
	    gReport[i + 1][rById] = gReport[i][rById];
	    gReport[i + 1][rReason] = gReport[i][rReason];
	    gReport[i + 1][rTime] = gReport[i][rTime];
	    gReport[i + 1][rChecked] = gReport[i][rChecked];
	}

	GetPlayerName(targetid, gReport[0][rAgainst], MAX_PLAYER_NAME);
	gReport[0][rAgainstId] = targetid;
	GetPlayerName(playerid, gReport[0][rBy], MAX_PLAYER_NAME);
	gReport[0][rById]= playerid;
 	format(gReport[0][rReason], 100, reason);
 	format(gReport[0][rTime], 15, "%i:%i", hour, minute);
 	gReport[0][rChecked] = false;

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	format(buf, sizeof(buf), "Your report against %s(%i) has been sent to online admins.", ReturnPlayerName(targetid), targetid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
	return 1;
}

CMD:changename(playerid, params[])
{
	new name[MAX_PLAYER_NAME];
    if (sscanf(params, "s[24]", name))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /changename [newname]");
	}

	if (strlen(name) < 4 || strlen(name) > MAX_PLAYER_NAME)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid user name length, must be b/w 4-24.");
	}

	if (yoursql_get_row(SQL:0, "user", "name = %s", name) != SQL_INVALID_ROW)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "That username is already registered, try another one!");
	}

    yoursql_set_field(SQL:0, "user/name", yoursql_get_row(SQL:0, "user", "name = %s", ReturnPlayerName(playerid)), name);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new buf[150];
	format(buf, sizeof(buf), "You have changed your username from '%s' to '%s'.", ReturnPlayerName(playerid), name);
	SendClientMessage(playerid, COLOR_GREEN, buf);
	GameTextForPlayer(playerid, "~w~Username changed", 5000, 3);

	SetPlayerName(playerid, name);
	return 1;
}

CMD:changepass(playerid, params[])
{
	new pass[30];
    if (sscanf(params, "s[30]", pass))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /changepass [newpass]");
	}

	if (strlen(pass) < 4 || strlen(pass) > MAX_PLAYER_NAME)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "Invalid password length, must be b/w 4-24.");
	}

	new hash[128];
	SHA256_PassHash(pass, "aafGEsq13", hash, sizeof(hash));
	yoursql_set_field(SQL:0, "user/password", yoursql_get_row(SQL:0, "user", "name = %s", ReturnPlayerName(playerid)), hash);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	SendClientMessage(playerid, COLOR_GREEN, "You have successfully changed your account password.");
	GameTextForPlayer(playerid, "~w~Password changed", 5000, 3);
	return 1;
}

CMD:autologin(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_ID_AUTO_LOGIN, DIALOG_STYLE_MSGBOX, "Autologin confirmation:", "Press "GREEN"ENABLE "WHITE"to switch auto login on or "RED"DISABLE "WHITE"to off.\n\nAutologin allows you to directly login without entering password when your ip is matching to the one registered with.", "Enable", "Disable");
	return 1;
}

CMD:nopm(playerid)
{
	if (! pStats[playerid][userNoPM])
	{
	    pStats[playerid][userNoPM] = true;

	    SendClientMessage(playerid, COLOR_TOMATO, "You are no longer accepting private messages (DND. On).");
	}
	else
	{
	    pStats[playerid][userNoPM] = false;

	    SendClientMessage(playerid, COLOR_GREEN, "You are now accepting private messages (DND. Off).");
	}
	return 1;
}
CMD:dnd(playerid)
{
	return cmd_nopm(playerid);
}

CMD:pm(playerid, params[])
{
	new targetid, text[128];
	if (sscanf(params, "us[128]", targetid, text))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /pm [player] [message]");
	}

	if (!IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not connected.");
	}

	if (targetid == playerid)
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "You cannot PM yourself.");
	}

	new buf[150];
	if (pStats[targetid][userNoPM])
	{
	    format(buf, sizeof(buf), "%s(%i) is not accepting private messages at the moment (DND).", ReturnPlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOR_TOMATO, buf);
	}

	PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
	PlayerPlaySound(targetid, 1085, 0.0, 0.0, 0.0);

	format(buf, sizeof(buf), "PM to %s(%i): %s", ReturnPlayerName(targetid), targetid, text);
	SendClientMessage(playerid, COLOR_YELLOW, buf);
	format(buf, sizeof(buf), "PM from %s(%i): %s", ReturnPlayerName(playerid), playerid, text);
	SendClientMessage(targetid, COLOR_YELLOW, buf);

	format(buf, sizeof(buf), "[READPM] %s(%i) to %s(%i): %s", ReturnPlayerName(playerid), playerid, ReturnPlayerName(targetid), targetid, text);
	foreach (new i : Player)
	{
	    if (pStats[i][userAdmin] > 2)
	    {
	        SendClientMessage(i, COLOR_GREY, buf);
	    }
	}

	pStats[playerid][userLastPM] = targetid;
	return 1;
}

CMD:reply(playerid, params[])
{
	new text[128];
	if (sscanf(params, "s[128]", text))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /reply [message]");
	}

 	new targetid = pStats[playerid][userLastPM];
	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The player is not connected anymore.");
	}

	new buf[150];
	if (pStats[targetid][userNoPM])
	{
	    format(buf, sizeof(buf), "%s(%i) is not accepting private messages at the moment (DND).", ReturnPlayerName(targetid), targetid);
		return SendClientMessage(playerid, COLOR_TOMATO, buf);
	}

	format(buf, sizeof(buf), "PM to %s(%i): %s", ReturnPlayerName(targetid), targetid, text);
	SendClientMessage(playerid, COLOR_YELLOW, buf);
	format(buf, sizeof(buf), "PM from %s(%i): %s", ReturnPlayerName(playerid), playerid, text);
	SendClientMessage(targetid, COLOR_YELLOW, buf);

	format(buf, sizeof(buf), "[READPM] %s(%i) to %s(%i): %s", ReturnPlayerName(playerid), playerid, ReturnPlayerName(targetid), targetid, text);
	foreach (new i : Player)
	{
	    if (pStats[i][userAdmin] > 2)
	    {
	        SendClientMessage(i, COLOR_GREY, buf);
	    }
	}
	return 1;
}

CMD:time(playerid, params[])
{
	new time[3];
	gettime(time[0], time[1], time[2]);

	new buf[150];
	format(buf, sizeof(buf), "Server time: %i:%i:%i", time[0], time[1], time[2]);
	SendClientMessage(playerid, COLOR_WHITE, buf);

	format(buf, sizeof(buf), "~w~~h~%i:%i", time[0], time[1]);
	GameTextForPlayer(playerid, buf, 5000, 1);
	return 1;
}

CMD:id(playerid, params[])
{
	new name[MAX_PLAYER_NAME];
	if (sscanf(params, "s[24]", name))
	{
		return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /id [name]");
	}

	SendClientMessage(playerid, COLOR_DODGER_BLUE, " ");
	new buf[150];
	format(buf, sizeof(buf), "- Search result for '%s' -", name);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);

	new count;
	foreach (new i : Player)
	{
	    if (strfind(ReturnPlayerName(i), name, true) != -1)
	    {
	        count++;
			format(buf, sizeof(buf), "%i. %s(%i)", count, ReturnPlayerName(i), i);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
		}
	}

	if (! count)
	{
		return SendClientMessage(playerid, COLOR_DODGER_BLUE, "No match found.");
	}
	return 1;
}
CMD:getid(playerid, params[])
{
	return cmd_id(playerid, params);
}

CMD:stats(playerid, params[])
{
	new targetid;
	if (sscanf(params, "u", targetid))
	{
  		targetid = playerid;
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can also view other players stats by /stats [player]");
	}

	if (! IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, COLOR_TOMATO, "The specified player is not conected.");
	}

	new SQLRow:rowid = yoursql_get_row(SQL:0, "users", "name = %s", ReturnPlayerName(targetid));

	new buf[150];
	format(buf, sizeof(buf), "%s(%i)'s stats: (AccountID: %i)", ReturnPlayerName(targetid), targetid, _:rowid);
	SendClientMessage(playerid, COLOR_GREEN, buf);

	new Float:ratio;
	if (pStats[targetid][userDeaths] <= 0)
	{
		ratio = 0.0;
	}
	else
	{
		ratio = floatdiv(pStats[targetid][userKills], pStats[targetid][userDeaths]);
	}

	format(buf, sizeof(buf), "Teamid: %i, Skinid: %i, Score: %i, Money: $%i, Kills: %i, Deaths: %i, Ratio: %0.2f", GetPlayerTeam(playerid), GetPlayerSkin(playerid), GetPlayerScore(targetid), GetPlayerMoney(targetid), pStats[targetid][userKills], pStats[targetid][userDeaths], ratio);
	SendClientMessage(playerid, COLOR_GREEN, buf);

	new admin_rank[25];
	if (IsPlayerAdmin(targetid))
	{
		admin_rank = "RCON Administrator";
	}
	else
	{
	    switch (pStats[targetid][userAdmin])
	    {
	        case 1: admin_rank = "Moderator";
	        case 2: admin_rank = "Junior Administrator";
	        case 3: admin_rank = "Senior Administrator";
	        case 4: admin_rank = "Lead Administrator";
		    case 5: admin_rank = "Server Manager";
			default: admin_rank = "Server Owner";
	    }
 	}

 	new premium[5];
 	if (pStats[targetid][userPremium])
 	{
	 	premium = "Yes";
	}
	else
	{
		premium = "No";
	}

 	new hours, minutes, seconds;
 	GetPlayerConnectedTime(targetid, hours, minutes, seconds);
 	hours += yoursql_get_field_int(SQL:0, "users/hours", rowid);
 	minutes += yoursql_get_field_int(SQL:0, "users/minutes", rowid);
 	seconds += yoursql_get_field_int(SQL:0, "users/seconds", rowid);
	if (seconds >= 60)
	{
	    seconds = 0;
	    minutes++;
	    if (minutes >= 60)
	    {
	        minutes = 0;
	        hours++;
	    }
	}

	new register_on[25];
	yoursql_get_field(SQL:0, "users/register_on", rowid, register_on);

	format(buf, sizeof(buf), "Admin Level: %i (%s), Premium: %s, Time Played: %i hours, %i minutes, %i seconds, Registeration Date: %s", pStats[targetid][userAdmin], admin_rank, premium, hours, minutes, seconds, register_on);
	SendClientMessage(playerid, COLOR_GREEN, buf);
	return 1;
}

CMD:richlist(playerid)
{
	new data[MAX_PLAYERS][2];
	foreach (new i : Player)
	{
	    data[i][0] = GetPlayerMoney(i);
	    data[i][1] = i;
	}

	QuickSort_Pair(data, true, 0, Iter_Count(Player));

	SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 5 rich players:");
	new buf[150];
	for (new i; i < 5; i++)
	{
	    if (data[i][0])
	    {
	        format(buf, sizeof(buf), "%i. %s(%i) - $%i", i + 1, ReturnPlayerName(data[i][1]), data[i][1], data[i][0]);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
		}
	}
	return 1;
}

CMD:scorelist(playerid)
{
	new data[MAX_PLAYERS][2];
	foreach (new i : Player)
	{
	    data[i][0] = GetPlayerScore(i);
	    data[i][1] = i;
	}

	QuickSort_Pair(data, true, 0, Iter_Count(Player));

	SendClientMessage(playerid, COLOR_DODGER_BLUE, "Top 5 score players:");
	new buf[150];
	for (new i; i < 5; i++)
	{
	    if (data[i][0])
	    {
	        format(buf, sizeof(buf), "%i. %s(%i) - %i", i + 1, ReturnPlayerName(data[i][1]), data[i][1], data[i][0]);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, buf);
		}
	}
	return 1;
}

CMD:top10(playerid)
{
	ShowPlayerDialog(playerid, DIALOG_ID_TOP10, DIALOG_STYLE_LIST, "Select a top10 category:", "Kills\nDeaths\nScore\nTime Played", "Select", "Cancel");
	return 1;
}
