//------------------------------------------------
/*
    								  ___
		______  ___      _           /   \
	   / ____/ / _ \    | |          \___/
	  / /     | | | |   | | __ _  __   _  _  __             ____
	 | |  ___ | |_| |  _| || |/ \/  \ | || |/_ \   __    __|___ \
     | | |__ || | | | / _ ||  /\__/\ || ||  / \ |  \ \  / /  / /
     \ \___| || | | || |_||| |     | || || |  | |   \ \/ / / /_
	  \______||_| |_|\____||_|     |_||_||_|  |_|    \__/ \____|

	GAdmin System (gadmin.pwn)
	* Using easydb include, fast, easy and efficient SQLITE database for the admin system.
	* Support timeban/tempban, permanent ban and now range bans as well.
	* Over 100+ admin and player commands, watch the list in one dialog by typing /acmds in chat.

 	Author: (creator)
	* Gammix

 	Contributors:
	* Y_Less - sscanf2
	* Zeex & Yashas - izcmd include
	* Jochemd - timestamptodate include
	* Incognito - streamer plugin
	* Phento - HighestTopList function
	* R@f - ipmatch function
	* SAMP team

	(c) Copyright 2015
  	* This file is provided as is (no warranties).
*/
//------------------------------------------------

#define FILTERSCRIPT//must be defined

//------------------------------------------------

#include <a_samp> //SA-MP team

#include <sscanf2> //Y_Less

#include <easydb> //Gammix

#include <izcmd> //Zeex & Yashas

#include <timestamptodate> //Jochemd

#include <streamer> //Incognito

//------------------------------------------------------------------------------

//System configuration

#define LOCATION_DATABASE 				"GAdmin.db" //the ADMIN_DATABASE name

#define TABLE_USERS 					"users" //the user data table name (all player stats will be saved in it)
#define TABLE_BANS       				"bans" //the ban data table name (all the ban data will be saved in it)
#define TABLE_RANGE_BANS                "rangebans" //the rangeban data table name (all the ban data will be saved in it)
#define TABLE_FORBIDDEN_WORDS			"forbidden_words" //the bad words data table name
#define TABLE_FORBIDDEN_NAMES			"forbidden_names" //the bad names data table name
#define TABLE_FORBIDDEN_TAGS			"forbidden_tags" //the bad tag names data table name

#define MAX_FORBIDDEN_ITEMS             100 //maximum forbidden items(names, words, tags) your database tables can have

#define FORCE_REGISTER 					//comment this if you don't want registeration compulsory
#define FORCE_LOGIN 					//comment this if you don't want login compulsory

#define READ_COMMANDS       			//comment this if you don't want admin notification whenever a player types a cmd

#define REPORT_TEXTDRAW     			//comment this if you don't want a report textdraw for admin's notifications
#define MAX_REPORTLOG_LINES     		5 //maximum latest reports the dialog can store (/reports)

#define SPECTATE_TEXTDRAW     			//comment this if you don't want a spectate textdraw for admin's target player stats on screen

#define MAX_LOGIN_ATTEMPTS 				3 //maximum times a player may try loggin in a account
#define MAX_WARNINGS        			5 //maximum number of warnings a player may get after which he/she get kicked!

#define MAX_VIP_LEVELS      			3 //maximum VIP/Donor ranks
#define MAX_ADMIN_LEVELS    			6 //maximum Admin ranks, make sure its greater than 5

new const Float:gAdminSpawn[][4] =      //random admin spawns (spawns admin when on duty only)
{
	//Los santos

   	{1751.1097,-2106.4529,13.5469,183.1979}, // El-Corona - Outside random house
	{2652.6418,-1989.9175,13.9988,182.7107}, // Random house in willowfield - near pla
	{2232.1309,-1159.5679,25.8906,103.2939}, // Jefferson motel
	{2388.1003,-1279.8933,25.1291,94.3321}, // House south of pig pen
	{1240.3170,-2036.6886,59.9575,276.4659}, // Verdant Bluffs
	{2215.5181,-2627.8174,13.5469,273.7786}, // Ocean docks 1
	{2509.4346,-2637.6543,13.6453,358.3565}, // Ocean Docks spawn 2

	//Las venturas

	{1435.8024,2662.3647,11.3926,1.1650}, //  Northern train station
	{1457.4762,2773.4868,10.8203,272.2754}, //  Northern golf club
	{2101.4192,2678.7874,10.8130,92.0607}, //  Northern near railway line
	{1951.1090,2660.3877,10.8203,180.8461}, //  Northern house 2
	{1666.6949,2604.9861,10.8203,179.8495}, //  Northern house 3
	{1860.9672,1030.2910,10.8203,271.6988}, //  Behind 4 Dragons
	{1673.2345,1316.1067,10.8203,177.7294}, //  Airport carpark
	{1412.6187,2000.0596,14.7396,271.3568}, //  South baseball stadium houses

	//San fierro

	{-2723.4639,-314.8138,7.1839,43.5562}, // golf course spawn
	{-2694.5344,64.5550,4.3359,95.0190}, // in front of a house
	{-2458.2000,134.5419,35.1719,303.9446}, // hotel
	{-2866.7683,691.9363,23.4989,286.3060}, // house
	{-2108.0171,902.8030,76.5792,5.7139}, // house
	{-2173.0654,-392.7444,35.3359,237.0159}, // stadium
	{-2320.5286,-180.3870,35.3135,179.6980}, // burger shot
	{-2930.0049,487.2518,4.9141,3.8258} // harbor
};

//------------------------------------------------------------------------------

//colors list
#define COLOR_DODGER_BLUE \
			0x1E90FFFF
#define COLOR_FIREBRICK	\
			0xB22222FF
#define COLOR_STEEL_BLUE \
			0x4682B4FF
#define COLOR_RED \
			0xFF0000FF
#define COLOR_GREY \
			0x808080FF
#define COLOR_GREEN	\
			0x00CC00FF
#define COLOR_LIME \
			0xCCFF99FF
#define COLOR_BLACK \
			0x000000FF
#define COLOR_WHITE \
			0xFFFFFFFF
#define COLOR_ORANGE \
			0xFF9933FF
#define COLOR_YELLOW \
			0xFFFF66FF
#define COLOR_BLUE \
			0x0099CCFF
#define COLOR_PURPLE \
			0x6600FFFF
#define COLOR_BROWN \
			0x663300FF
#define COLOR_PINK \
			0xCC99FFFF
#define COLOR_HOT_PINK \
			0xFF99FFFF
#define COLOR_THISTLE \
			0xD8BFD8FF
#define COLOR_KHAKI \
			0x999966FF
#define COLOR_ORANGE_RED \
			0xFF4500FF
//embeded
#define SAMP_BLUE \
			"{A9C4E4}"
#define WHITE \
			"{FFFFFF}"
#define MARONE \
			"{800000}"
#define RED \
			"{FF0000}"
#define HOT_PINK \
			"{FF99FF}"
#define LIME \
			"{CCFF99}"
#define TOMATO \
			"{FF6347}"
#define PINK \
			"{CC99FF}"
#define BLACK \
			"{000000}"
#define ORANGE \
			"{FF9933}"
#define YELLOW \
			"{FFFF66}"
#define GREEN \
			"{00CC00}"
#define VIOLET \
			"{EE82EE}"
#define BROWN \
			"{663300}"
#define CORAL \
			"{993333}"

//------------------------------------------------------------------------------

//latest player looping method
#define LOOP_PLAYERS(%0) \
			for(new %0 = 0, _%0 = GetPlayerPoolSize(); %0 <= _%0, IsPlayerConnected(%0); %0++)

//------------------------------------------------

//define isnull
#if ! defined isnull
	#define isnull(%1) \
				((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))
#endif

//------------------------------------------------

//defining IsValidVehicle if not done
#if ! defined IsValidVehicle
	native IsValidVehicle(vehicleid);
#endif

//------------------------------------------------

//adjust the dialog ids yourself
#define DIALOG_COMMON   		0
#define DIALOG_REGISTER     	900
#define DIALOG_LOGIN        	901
#define DIALOG_PLAYER_COLORS    902
//tune dialogs
#define DIALOG_MAIN 			903
#define DIALOG_PAINTJOBS 		904
#define DIALOG_COLORS 			905
#define DIALOG_EXHAUSTS 		906
#define DIALOG_FBUMPS 			907
#define DIALOG_RBUMPS 			908
#define DIALOG_ROOFS    		909
#define DIALOG_SPOILERS 		910
#define DIALOG_SIDESKIRTS 		911
#define DIALOG_BULLBARS 		912
#define DIALOG_WHEELS 			913
#define DIALOG_CSTEREO 			914
#define DIALOG_HYDRAULICS 		915
#define DIALOG_NITRO 			916
#define DIALOG_LIGHTS 			917
#define DIALOG_HOODS 			918
#define DIALOG_VENTS 			919
//others
#define DIALOG_TELEPORTS        920

//------------------------------------------------

stock e_STRING[144];

#define LevelCheck(%0,%1); \
	if(GetPlayerGAdminLevel(%0) < %1 && ! IsPlayerAdmin(%0)) \
	    return (format(e_STRING, sizeof(e_STRING), "ERROR: You must be level %i admin to use this command.", %1), \
			SendClientMessage(%0, COLOR_FIREBRICK, e_STRING));

#if !defined FLOAT_INFINITY
    #define FLOAT_INFINITY (Float:0x7F800000)
#endif

#if ! defined IsValidWeapon
	#define IsValidWeapon(%0) (%0 < 47)
#endif

//------------------------------------------------

enum UserEnum
{
	//saved data
	u_admin,
	u_vip,
	u_kills,
	u_deaths,
	u_score,
	u_money,
	u_hours,
	u_minutes,
	u_seconds,

	//not saved data
	u_attempts,
	u_sessionkills,
	u_sessiondeaths,
	u_spree,
	u_chattime,
	u_chattext[144],
	Text3D:u_duty3dtext,
	u_lastreported,
	u_lastreportedtime,
	u_updatetimer,

	//conditions data
	u_jailtime,
	u_mutetime,
	u_cmutetime,
	u_specdata[2],
	Float:u_specpos[4],
	u_vehicle,
	u_warnings,

	//pm data
	u_lastuser,

	//spectate data
	u_specid,
	bool:u_spec,
	Float:u_pos[3],
	u_int,
	#if defined SPECTATE_TEXTDRAW
		PlayerText:u_spectxt,
	#endif
	u_vw
};
new gUser[MAX_PLAYERS][UserEnum];

//------------------------------------------------

enum GlobalEnum
{
	s_usertable,
	s_bantable,
	s_rangebantable,
	s_fwordstable,
	s_fnamestable,
	s_ftagstable,
	s_fwordscount,
	s_fnamescount,
	s_ftagscount,
	bool:s_locked,
	Text:s_locktd[3],
	#if defined REPORT_TEXTDRAW
		Text:s_reporttd
	#endif
}
new gGlobal[GlobalEnum];

//------------------------------------------------

#if MAX_REPORTLOG_LINES > 0
	new gReportlog[MAX_REPORTLOG_LINES][145];
#endif

//------------------------------------------------

//forbidden lists
new gForbidden_Words[(MAX_FORBIDDEN_ITEMS + 1)][150], gForbidden_Names[(MAX_FORBIDDEN_ITEMS + 1)][MAX_PLAYER_NAME], gForbidden_Tags[(MAX_FORBIDDEN_ITEMS + 1)][MAX_PLAYER_NAME];

//------------------------------------------------

//vehicle names
new const VehicleNames[212][] =
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
	{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},
	{"Utility Trailer"}
};

//------------------------------------------------

public OnFilterScriptInit()
{
	print(" ");
	print("_________________| GAdminv3 |_________________");
	print("Attempting to initialize ''GAdminv3.amx''...");
	print(" ");

	if(! DB::Open(LOCATION_DATABASE))
	{
	    printf("[GAdminv3] - ERROR: The filterscript couldn't be loaded cause the database file(%s) wasn't opened.", LOCATION_DATABASE);
	    return 0;
	}

	gGlobal[s_usertable] = DB::VerifyTable(TABLE_USERS, "ID");
	if(gGlobal[s_usertable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Users table(%s) couldn't be verified.", TABLE_USERS);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_usertable], "username", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_usertable], "password", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_usertable], "ip", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_usertable], "joindate", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_usertable], "laston", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_usertable], "admin", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "vip", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "kills", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "deaths", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "score", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "money", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "hours", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "minutes", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "seconds", DB::TYPE_NUMBER, 0);
		DB::VerifyColumn(gGlobal[s_usertable], "autologin", DB::TYPE_NUMBER, 0);
	}
	printf("[GAdminv3] - NOTICE: Total %i accounts loaded from the table ''%s''", DB::CountRows(gGlobal[s_usertable]), TABLE_USERS);
 	printf("%i", DB::GetHighestRegisteredKey(gGlobal[s_usertable]));

	gGlobal[s_rangebantable] = DB::VerifyTable(TABLE_RANGE_BANS, "ID");
	if(gGlobal[s_bantable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Rangebans table(%s) couldn't be verified.", TABLE_RANGE_BANS);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_rangebantable], "ip", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_rangebantable], "banby", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_rangebantable], "banon", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_rangebantable], "reason", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_rangebantable], "expire", DB::TYPE_NUMBER, 0);
	}
	printf("[GAdminv3] - NOTICE: Total %i range bans loaded from the table ''%s''", DB::CountRows(gGlobal[s_rangebantable]), TABLE_RANGE_BANS);

	gGlobal[s_bantable] = DB::VerifyTable(TABLE_BANS, "ID");
	if(gGlobal[s_bantable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Bans table(%s) couldn't be verified.", TABLE_BANS);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_bantable], "name", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_bantable], "ip", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_bantable], "banby", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_bantable], "banon", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_bantable], "reason", DB::TYPE_STRING, "");
		DB::VerifyColumn(gGlobal[s_bantable], "expire", DB::TYPE_NUMBER, 0);
	}
	printf("[GAdminv3] - NOTICE: Total %i bans loaded from the table ''%s''", DB::CountRows(gGlobal[s_bantable]), TABLE_BANS);

	gGlobal[s_fwordstable] = DB::VerifyTable(TABLE_FORBIDDEN_WORDS, "ID");
	if(gGlobal[s_fwordstable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Forbidden Words table(%s) couldn't be verified.", TABLE_FORBIDDEN_WORDS);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_fwordstable], "word", DB::TYPE_STRING, "");

		gGlobal[s_fwordscount] = DB::CountRows(gGlobal[s_fwordstable]);
		for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
		{
		    gForbidden_Words[i][0] = EOS;

		    if(i < gGlobal[s_fwordscount])
		    {
		    	DB::GetStringEntry(gGlobal[s_fwordstable], i + 1, "word", gForbidden_Words[i]);
		    }
		}
		printf("[GAdminv3] - NOTICE: Total %i forbidden words loaded from the table ''%s''", gGlobal[s_fwordscount], TABLE_FORBIDDEN_WORDS);
	}

	gGlobal[s_fnamestable] = DB::VerifyTable(TABLE_FORBIDDEN_NAMES, "ID");
	if(gGlobal[s_fnamestable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Forbidden Names table(%s) couldn't be verified.", TABLE_FORBIDDEN_NAMES);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_fnamestable], "name", DB::TYPE_STRING, "");

		gGlobal[s_fnamescount] = DB::CountRows(gGlobal[s_fnamestable]);
		for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
		{
		    gForbidden_Names[i][0] = EOS;

		    if(i < gGlobal[s_fnamescount])
		    {
		    	DB::GetStringEntry(gGlobal[s_fnamestable], i + 1, "name", gForbidden_Names[i]);
		    }
		}
		printf("[GAdminv3] - NOTICE: Total %i forbidden names loaded from the table ''%s''", gGlobal[s_fnamescount], TABLE_FORBIDDEN_NAMES);
	}

	gGlobal[s_ftagstable] = DB::VerifyTable(TABLE_FORBIDDEN_TAGS, "ID");
	if(gGlobal[s_ftagstable] == DB_INVALID_TABLE)
	{
	    printf("[GAdminv3] - ERROR: The Forbidden Names table(%s) couldn't be verified.", TABLE_FORBIDDEN_TAGS);
	}
	else
	{
		DB::VerifyColumn(gGlobal[s_ftagstable], "tag", DB::TYPE_STRING, "");

		gGlobal[s_ftagscount] = DB::CountRows(gGlobal[s_ftagstable]);
		for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
		{
		    gForbidden_Tags[i][0] = EOS;

		    if(i < gGlobal[s_ftagscount])
		    {
		    	DB::GetStringEntry(gGlobal[s_ftagstable], i + 1, "tag", gForbidden_Tags[i]);
		    }
		}
		printf("[GAdminv3] - NOTICE: Total %i forbidden part of names/tags loaded from the table ''%s''", gGlobal[s_ftagscount], TABLE_FORBIDDEN_TAGS);
	}

	//report TD
	#if defined REPORT_TEXTDRAW
	    gGlobal[s_reporttd] = TextDrawCreate(6.000000, 434.000000, "~b~~h~~h~~h~[12:33] ~w~~h~REPORT from Gammix(0) ~y~I~w~~h~ Against HacX(9) ~y~I~w~~h~ Reason: health hack");
		TextDrawBackgroundColor(gGlobal[s_reporttd], 255);
		TextDrawFont(gGlobal[s_reporttd], 1);
		TextDrawLetterSize(gGlobal[s_reporttd], 0.230000, 1.100000);
		TextDrawColor(gGlobal[s_reporttd], -1);
		TextDrawSetOutline(gGlobal[s_reporttd], 1);
		TextDrawSetProportional(gGlobal[s_reporttd], 1);
		TextDrawSetSelectable(gGlobal[s_reporttd], 0);
	#endif

	for(new i; i < sizeof(gReportlog); i++)
	{
	    format(gReportlog[i], 145, "");
	}

	print(" ");
	print("Gammix's Administration Filterscript (c) 2015 | "LOCATION_DATABASE" | Initialization complete...");
	print("_________________________________________________");
	print(" ");
	return 1;
}

//------------------------------------------------

public OnFilterScriptExit()
{
	DB::Close();

	//destroy server lock
 	for(new i; i < 3; i++)
	{
 		TextDrawHideForAll(gGlobal[s_locktd][i]);
   		TextDrawDestroy(gGlobal[s_locktd][i]);
	}

	//destroy report textdraws
	#if defined REPORT_TEXTDRAW
 		TextDrawHideForAll(gGlobal[s_reporttd]);
   		TextDrawDestroy(gGlobal[s_reporttd]);
	#endif

	print(" ");
	print("_________________| GAdminv3 |_________________");
	print("Gammix's Administration Filterscript (c) 2015 | "LOCATION_DATABASE" | Unloading complete...");
	print("_________________________________________________");
	print(" ");
	return 1;
}

//------------------------------------------------

//delay kick
DelayKick(playerid) return SetTimerEx("OnPlayerKicked", (10 + GetPlayerPing(playerid)), false, "i", playerid);

forward OnPlayerKicked(playerid);
public OnPlayerKicked(playerid) return Kick(playerid);

//------------------------------------------------

JailPlayer(playerid)
{
	SetPlayerInterior(playerid, 3);
	SetPlayerPos(playerid, 197.6661, 173.8179, 1003.0234);
	SetCameraBehindPlayer(playerid);

	new string[144];
	format(string, sizeof(string), "JAIL: You are in jail for %i seconds", gUser[playerid][u_jailtime]);
    SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    return 1;
}

//------------------------------------------------

EraseVeh(vehicleid)
{
    LOOP_PLAYERS(i)
	{
        new Float:X, Float:Y, Float:Z;
    	if(IsPlayerInVehicle(i, vehicleid))
		{
	  		RemovePlayerFromVehicle(i);
	  		GetPlayerPos(i, X, Y, Z);
	 		SetPlayerPos(i, X, Y+3, Z);
	    }
	    SetVehicleParamsForPlayer(vehicleid, i, 0, 1);
	}
    SetTimerEx("OnVehicleRespawned", 1500, 0, "i", vehicleid);
}

forward OnVehicleRespawned(vehicleid);
public OnVehicleRespawned(vehicleid) return DestroyVehicle(vehicleid);

//------------------------------------------------

GetVehicleModelIDFromName(vname[])
{
	for(new i = 0; i < 211; i++)
	{
		if ( strfind(VehicleNames[i], vname, true) != -1 )
		return i + 400;
	}
	return -1;
}

//------------------------------------------------

_GetWeaponName(weaponid, weapon[], len)
{
	switch(weaponid)
	{
	    case 0: format(weapon, len, "Fist");
	    case 18: format(weapon, len, "Molotov Cocktail");
		case 44: format(weapon, len, "Night Vision Goggles");
		case 45: format(weapon, len, "Thermal Goggles");
		default: GetWeaponName(weaponid, weapon, len);
	}
}
#if defined _ALS_GetWeaponName
    #undef GetWeaponName
#else
    #define _ALS_GetWeaponName
#endif
#define GetWeaponName _GetWeaponName

_TogglePlayerSpectating(playerid, set)
{
	if(set)
	{
		if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING)
		{
		    TogglePlayerSpectating(playerid, true);
		}
	}
	else
	{
		if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
		{
		    TogglePlayerSpectating(playerid, false);
		}
	}
}
#if defined _ALS_TogglePlayerSpectating
    #undef TogglePlayerSpectating
#else
    #define _ALS_TogglePlayerSpectating
#endif
#define TogglePlayerSpectating _TogglePlayerSpectating

GetWeaponIDFromName(WeaponName[])
{
	if(strfind("molotov", WeaponName, true) != -1) return 18;
	for(new i = 0; i <= 46; i++)
	{
		switch(i)
		{
			case 0,19,20,21,44,45: continue;
			default:
			{
				new name[32];
				GetWeaponName(i,name,32);
				if(strfind(name,WeaponName,true) != -1) return i;
			}
		}
	}
	return -1;
}

//------------------------------------------------

IsPlayerGAdmin(playerid)
{
	if(gUser[playerid][u_admin] > 0 || IsPlayerAdmin(playerid)) return true;
	return false;
}

GetPlayerGAdminLevel(playerid)
{
	return gUser[playerid][u_admin];
}

//------------------------------------------------

IsPlayerGVip(playerid)
{
	if(gUser[playerid][u_vip] > 0) return true;
	return false;
}

GetPlayerGVipLevel(playerid)
{
	return gUser[playerid][u_vip];
}

//------------------------------------------------

SendClientMessageForAdmins(color, message[])
{
	LOOP_PLAYERS(i)
	{
	    if(IsPlayerGAdmin(i))
	    {
	        SendClientMessage(i, color, message);
	    }
	}
	return 1;
}

//------------------------------------------------

IsPlayerSpawned(playerid)
{
	switch(GetPlayerState(playerid))
	{
	    case PLAYER_STATE_ONFOOT, PLAYER_STATE_DRIVER, PLAYER_STATE_PASSENGER, PLAYER_STATE_SPAWNED: return true;
	    default: return false;
	}
	return false;
}

IsPlayerSpectating(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) return true;
	return false;
}

//------------------------------------------------

SetPlayerSpectating(playerid, targetid)
{
    TogglePlayerSpectating(playerid, true);

	if(GetPlayerInterior(playerid) != GetPlayerInterior(targetid))
    {
    	SetPlayerInterior(playerid, GetPlayerInterior(targetid));
   	}
    if(GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid))
    {
    	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
    }

    if(IsPlayerInAnyVehicle(targetid))
    {
        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
    }
    else
    {
        PlayerSpectatePlayer(playerid, targetid);
    }

	new string[144];
    format(string, sizeof(string),"-> You are now spectating %s[%i].", ReturnPlayerName(targetid), targetid);
    SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

    gUser[playerid][u_spec] = true;
    gUser[playerid][u_specid] = targetid;
	return true;
}

UpdatePlayerSpectating(playerid, type = 0, bool:forcestop = false)
{
	switch(type)
	{
	    case 0:
	    {
			new check = 0;
		  	LOOP_PLAYERS(i)
			{
				if(i < gUser[i][u_specid]) i = (gUser[playerid][u_specid] + 1);
			    if(i > GetPlayerPoolSize()) i = 0, check += 1;

				if(check > 1) break;

				if(IsPlayerSpawned(i))
				{
					if(i != playerid)
					{
			    		if(! IsPlayerSpectating(i))
			    		{
							SetPlayerSpectating(playerid, i);
			    			break;
						}
					}
				}
		 	}

		 	if(forcestop)
			{
				cmd_specoff(playerid, "");
		 		SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: There was no player to spectate further.");
		 	}
		 	else
		 	{
		 	    SetPlayerSpectating(playerid, gUser[playerid][u_specid]);
		 	}
	 	}
	 	case 1:
	 	{
			new check = 0;
		  	LOOP_PLAYERS(i)
			{
				if(i > gUser[i][u_specid]) i = (gUser[playerid][u_specid] - 1);
			    if(i < 0) i = GetPlayerPoolSize(), check += 1;

				if(check > 1) break;

				if(IsPlayerSpawned(i))
				{
					if(i != playerid)
					{
			    		if(! IsPlayerSpectating(i))
			    		{
							SetPlayerSpectating(playerid, i);
							break;
						}
					}
				}
		 	}

		 	if(forcestop)
			{
				cmd_specoff(playerid, "");
		 		SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: There was no player to spectate back.");
	 		}
		 	else
		 	{
		 	    SetPlayerSpectating(playerid, gUser[playerid][u_specid]);
		 	}
	 	}
	 	case 2:
	 	{
	 	    if(GetPlayerInterior(playerid) != GetPlayerInterior(gUser[playerid][u_specid]))
		    {
		    	SetPlayerInterior(playerid, GetPlayerInterior(gUser[playerid][u_specid]));
		   	}
		    if(GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(gUser[playerid][u_specid]))
		    {
		    	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(gUser[playerid][u_specid]));
		    }

		    if(IsPlayerInAnyVehicle(gUser[playerid][u_specid]))
		    {
		        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(gUser[playerid][u_specid]));
		    }
		    else
		    {
		        PlayerSpectatePlayer(playerid, gUser[playerid][u_specid]);
		    }
	 	}
	}
	return true;
}

//------------------------------------------------

HighestTopList(const playerid, const Value, Player_ID[], Top_Score[], Loop) //Created by Phento
{
	new t = 0,
		p = Loop-1;
	while(t < p)
	{
	    if(Value >= Top_Score[t])
		{
			while(p > t)
			{
				Top_Score[p] = Top_Score[p - 1];
				Player_ID[p] = Player_ID[p - 1];
				p--;
			}
			Top_Score[t] = Value; Player_ID[t] = playerid;
			break;
		}
		t++;
	}
	return 1;
}

//------------------------------------------------

#if ! defined isnumeric
	isnumeric(str[])
	{
		new ch, i;
		while ((ch = str[i++])) if (!('0' <= ch <= '9')) return false;
		return true;
	}
#endif

ReturnPlayerName(playerid)
{
	new player_name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, player_name, MAX_PLAYER_NAME);
	return player_name;
}

ReturnPlayerIP(playerid)
{
	new player_ip[18];
	GetPlayerIp(playerid, player_ip, sizeof(player_ip));
	return player_ip;
}

//------------------------------------------------

forward OnPlayerTimeUpdate(playerid);
public OnPlayerTimeUpdate(playerid)
{
	new string[1024];

	#if defined SPECTATE_TEXTDRAW
	    if(gUser[playerid][u_spec])
	    {
	        if(IsPlayerConnected(gUser[playerid][u_specid]))
	        {
	            new target = gUser[playerid][u_specid];
	            new arg_s[96], Float:arg_f, Float:arg_speed[3], arg_weaps[13][2];
	            strcat(string, "~g~Username: ");
	            strcat(string, "~y~");
	            strcat(string, ReturnPlayerName(target));
	            strcat(string, " (");
	            format(arg_s, sizeof(arg_s), "%i", target);
	            strcat(string, arg_s);
	            strcat(string, ")");
	            strcat(string, "~n~");
	            strcat(string, "~g~Health: ");
	            strcat(string, "~y~");
	            GetPlayerHealth(target, arg_f);
	            format(arg_s, sizeof(arg_s), "%0.2f", arg_f);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Armour: ");
	            strcat(string, "~y~");
	            GetPlayerArmour(target, arg_f);
	            format(arg_s, sizeof(arg_s), "%0.2f", arg_f);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Ping: ");
	            strcat(string, "~y~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerPing(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~IP.: ");
	            strcat(string, "~y~");
	            strcat(string, ReturnPlayerIP(target));
	            strcat(string, "~n~");
	            strcat(string, "~g~Skinid: ");
	            strcat(string, "~y~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerSkin(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Teamid: ");
	            strcat(string, "~y~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerTeam(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Money: ");
	            strcat(string, "~y~");
	            format(arg_s, sizeof(arg_s), "$%i", GetPlayerMoney(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Score: ");
	            strcat(string, "~y~");
	            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~Camera target player: ");
	            strcat(string, "~y~");
	            if(GetPlayerCameraTargetPlayer(target) != INVALID_PLAYER_ID)
	            {
		            strcat(string, ReturnPlayerName(GetPlayerCameraTargetPlayer(target)));
		            strcat(string, " (");
		            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
		            strcat(string, arg_s);
		            strcat(string, ")");
         		}
	            else
	            {
	            	strcat(string, "No Player");
	            }
	            strcat(string, "~n~");
	            strcat(string, "~g~Weapon target player: ");
	            strcat(string, "~y~");
	            if(GetPlayerTargetPlayer(target) != INVALID_PLAYER_ID)
	            {
		            strcat(string, ReturnPlayerName(GetPlayerTargetPlayer(target)));
		            strcat(string, " (");
		            format(arg_s, sizeof(arg_s), "%i", GetPlayerScore(target));
		            strcat(string, arg_s);
		            strcat(string, ")");
         		}
	            else
	            {
	            	strcat(string, "No Player");
	            }
	            strcat(string, "~n~");
	            strcat(string, "~g~Speed: ");
	            strcat(string, "~y~");
	            if(! IsPlayerInAnyVehicle(playerid))
	            {
		            GetPlayerVelocity(target, arg_speed[0], arg_speed[1], arg_speed[2]);
				    arg_f = floatsqroot((arg_speed[0] * arg_speed[0]) + (arg_speed[1] * arg_speed[1]) + (arg_speed[2] * arg_speed[2])) * 179.28625;
		            format(arg_s, sizeof(arg_s), "%0.2f MPH", arg_f);
		            strcat(string, arg_s);
				}
				else
				{
		            strcat(string, "0.0 MPH");
				}
	            strcat(string, "~n~");
	            strcat(string, "~g~Vehicle Speed: ");
	            strcat(string, "~y~");
	            if(IsPlayerInAnyVehicle(playerid))
	            {
		            GetVehicleVelocity(GetPlayerVehicleID(target), arg_speed[0], arg_speed[1], arg_speed[2]);
				    arg_f = floatsqroot((arg_speed[0] * arg_speed[0]) + (arg_speed[1] * arg_speed[1]) + (arg_speed[2] * arg_speed[2])) * 179.28625;
		            format(arg_s, sizeof(arg_s), "%0.2f MPH", arg_f);
		            strcat(string, arg_s);
				}
				else
				{
		            strcat(string, "0.0 MPH");
				}
	            strcat(string, "~n~");
	            strcat(string, "~g~Position: ");
	            strcat(string, "~y~");
	            GetPlayerPos(playerid, arg_speed[0], arg_speed[1], arg_speed[2]);
			    format(arg_s, sizeof(arg_s), "%f, %f, %f", arg_speed[0], arg_speed[1], arg_speed[2]);
	            strcat(string, arg_s);
	            strcat(string, "~n~");
	            strcat(string, "~g~~h~Weapons:");
	            strcat(string, "~y~");
	            new count = 0;
	            for(new i; i < 13; i++)
	            {
	                GetPlayerWeaponData(target, i, arg_weaps[i][0], arg_weaps[i][1]);
	                if(arg_weaps[i][0] != 0)
	                {
	                    count += 1;

	            		strcat(string, "~n~");
	            		format(arg_s, sizeof(arg_s), "%i. ", count);
	            		strcat(string, arg_s);
	                    GetWeaponName(arg_weaps[i][0], arg_s, sizeof(arg_s));
	            		strcat(string, arg_s);
	            		strcat(string, " [Ammo: ");
	            		format(arg_s, sizeof(arg_s), "%i", arg_weaps[i][1]);
	            		strcat(string, arg_s);
	            		strcat(string, "]");
	            	}
	            }
	            strcat(string, "~n~");
	            strcat(string, "~n~");
	            strcat(string, "~g~You can use LCTRL (KEY_ACTION) and RCTRL (KEY_FIRE) to switch players");
				strcat(string, "~n~");
	            strcat(string, "~g~You can use MMB (KEY_LOOK_BEHIND) or /specoff to stop spectating");

				PlayerTextDrawSetString(playerid, gUser[playerid][u_spectxt], string);
	        }
	    }
	#endif

	if(gUser[playerid][u_lastreportedtime] > 0)
	{
		gUser[playerid][u_lastreportedtime] -= 1;
	}
	else
	{
	    if(gUser[playerid][u_lastreported] != INVALID_PLAYER_ID)
	    {
    		gUser[playerid][u_lastreported] = INVALID_PLAYER_ID;
			gUser[playerid][u_lastreportedtime] = 0;
		}
	}

	if(GetPVarType(playerid, "GAdmin_Jailed") != PLAYER_VARTYPE_NONE)
	{
	    if(gUser[playerid][u_jailtime] >= 1)
	    {
	        gUser[playerid][u_jailtime] -= 1;
	    }
	    else if(gUser[playerid][u_jailtime] <= 0)
	    {
			DeletePVar(playerid, "GAdmin_Jailed");
	        gUser[playerid][u_jailtime] = 0;
            format(string, sizeof(string), "* %s[%d] has been unjailed after completing his/her time.", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_STEEL_BLUE, string);
			SpawnPlayer(playerid);
        }
	}
	if(GetPVarType(playerid, "GAdmin_Muted") != PLAYER_VARTYPE_NONE)
	{
	    if(gUser[playerid][u_mutetime] >= 1)
	    {
	        gUser[playerid][u_mutetime] -= 1;
	    }
	    else if(gUser[playerid][u_mutetime] <= 0)
	    {
		    DeletePVar(playerid, "GAdmin_Muted");

            gUser[playerid][u_mutetime] = 0;
            format(string, sizeof(string), "* %s[%d] has been unmuted after completing his/her time.", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_STEEL_BLUE, string);
        }
	}
	if(GetPVarType(playerid, "GAdmin_CMDMuted") != PLAYER_VARTYPE_NONE)
	{
	    if(gUser[playerid][u_cmutetime] >= 1)
	    {
	        gUser[playerid][u_cmutetime] --;
	    }
        else if(gUser[playerid][u_cmutetime] <= 0)
        {
            DeletePVar(playerid, "GAdmin_CMDMuted");

            gUser[playerid][u_cmutetime] = 0;
            format(string, sizeof(string), "* %s[%d] has been unmuted for commands after completing his/her time.", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_STEEL_BLUE, string);
        }
	}
	return 1;
}

//------------------------------------------------

public OnPlayerConnect(playerid)
{
	gUser[playerid][u_admin] = 0;
	gUser[playerid][u_vip] = 0;
	gUser[playerid][u_kills] = 0;
	gUser[playerid][u_deaths] = 0;
	gUser[playerid][u_score] = 0;
	gUser[playerid][u_money] = 0;
	gUser[playerid][u_hours] = 0;
	gUser[playerid][u_minutes] = 0;
	gUser[playerid][u_seconds] = 0;

	gUser[playerid][u_attempts] = 0;
	gUser[playerid][u_sessionkills] = 0;
	gUser[playerid][u_sessiondeaths] = 0;
	gUser[playerid][u_spree] = 0;
	gUser[playerid][u_lastreported] = INVALID_PLAYER_ID;
	gUser[playerid][u_lastreportedtime] = 0;
	gUser[playerid][u_updatetimer] = SetTimerEx("OnPlayerTimeUpdate", 1000, true, "i", playerid);

	gUser[playerid][u_jailtime] = 0;
	gUser[playerid][u_mutetime] = 0;
	gUser[playerid][u_cmutetime] = 0;
	gUser[playerid][u_specdata][0] = 0;
	gUser[playerid][u_specdata][1] = 0;
	gUser[playerid][u_specpos][0] = 0.0;
	gUser[playerid][u_specpos][1] = 0.0;
	gUser[playerid][u_specpos][2] = 0.0;
	gUser[playerid][u_specpos][3] = 0.0;
	gUser[playerid][u_vehicle] = -1;
	gUser[playerid][u_warnings] = 0;

	gUser[playerid][u_lastuser] = -1;

	gUser[playerid][u_specid] = INVALID_PLAYER_ID;
	gUser[playerid][u_spec] = false;
	gUser[playerid][u_pos][0] = 0.0;
	gUser[playerid][u_pos][1] = 0.0;
	gUser[playerid][u_pos][2] = 0.0;
	gUser[playerid][u_int] = 0;
	gUser[playerid][u_vw] = 0;

	#if defined SPECTATE_TEXTDRAW
		gUser[playerid][u_spectxt] = CreatePlayerTextDraw(playerid,17.000000, 170.000000, "~g~Spectate information");
		PlayerTextDrawBackgroundColor(playerid,gUser[playerid][u_spectxt], 255);
		PlayerTextDrawFont(playerid,gUser[playerid][u_spectxt], 1);
		PlayerTextDrawLetterSize(playerid,gUser[playerid][u_spectxt], 0.130000, 0.699998);
		PlayerTextDrawColor(playerid,gUser[playerid][u_spectxt], -1);
		PlayerTextDrawSetOutline(playerid,gUser[playerid][u_spectxt], 1);
		PlayerTextDrawSetProportional(playerid,gUser[playerid][u_spectxt], 1);
		PlayerTextDrawSetSelectable(playerid,gUser[playerid][u_spectxt], 0);
	#endif

	new string[144];

    for(new i = 0; i < gGlobal[s_fnamescount]; i++)
    {
        if( ! isnull(gForbidden_Names[i]) &&
			! strcmp(ReturnPlayerName(playerid), gForbidden_Names[i], true))
		{
			SendClientMessage(playerid, COLOR_RED, "* You have a forbidden/banned username, please change it in order to play.");

			format(string, sizeof(string), "* %s[%i] has been automatically kicked [Reason: Forbidden name]", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_RED, string);

            return DelayKick(playerid);
        }
    }

    for(new i = 0; i < gGlobal[s_ftagscount]; i++)
    {
        if( ! isnull(gForbidden_Tags[i]) &&
			strfind(ReturnPlayerName(playerid), gForbidden_Tags[i], true) != -1)
		{
			format(string, sizeof(string), "* You have a forbidden/banned part of name [tag: %s], please change it in order to play.", gForbidden_Tags[i]);
			SendClientMessage(playerid, COLOR_RED, string);

			format(string, sizeof(string), "* %s[%i] has been automatically kicked [Reason: Forbidden part of name/tag]", ReturnPlayerName(playerid), playerid);
			SendClientMessageToAll(COLOR_RED, string);

            return DelayKick(playerid);
        }
    }

	format(string, sizeof(string), "* %s[%i] have joined the server!", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_GREY, string);
	return 1;
}

//------------------------------------------------

GetPlayerConnectedTime(playerid, &hours, &minutes, &seconds)
{
	new connected_time = NetStats_GetConnectedTime(playerid);
	seconds = (connected_time / 1000) % 60;
	minutes = (connected_time / (1000 * 60)) % 60;
	hours = (connected_time / (1000 * 60 * 60));
	return true;
}

//------------------------------------------------

public OnPlayerDisconnect(playerid, reason)
{
	KillTimer(gUser[playerid][u_updatetimer]);

    for(new i; i < 3; i++)
	{
		TextDrawHideForPlayer(playerid, gGlobal[s_locktd][i]);
	}
	#if defined REPORT_TEXTDRAW
		TextDrawHideForPlayer(playerid, gGlobal[s_reporttd]);
	#endif
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, gUser[playerid][u_spectxt]);
	#endif

	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(gUser[i][u_specid] == playerid)
		    {
		        UpdatePlayerSpectating(playerid, 0, true);
			}
		}
	}

    if(gUser[playerid][u_vehicle] != -1) EraseVeh(gUser[playerid][u_vehicle]);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
    if(key != DB_INVALID_KEY)
	{
	    if(GetPVarInt(playerid, "GAdmin_Loggedin") != PLAYER_VARTYPE_NONE)
	    {
	        new DATE[18], date[3];
			getdate(date[0], date[1], date[2]);
			format(DATE, sizeof(DATE), "%i/%i/%i", date[2], date[1], date[0]);

            GetPlayerConnectedTime(playerid, gUser[playerid][u_hours], gUser[playerid][u_minutes], gUser[playerid][u_seconds]);

			DB::SetStringEntry(gGlobal[s_usertable], key, "laston", DATE);
			DB::SetIntEntry(gGlobal[s_usertable], key, "kills", gUser[playerid][u_kills]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "deaths", gUser[playerid][u_deaths]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "score", GetPlayerScore(playerid));
			DB::SetIntEntry(gGlobal[s_usertable], key, "money", GetPlayerMoney(playerid));
			DB::SetIntEntry(gGlobal[s_usertable], key, "hours", gUser[playerid][u_hours]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "minutes", gUser[playerid][u_minutes]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "seconds", gUser[playerid][u_seconds]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "", 0);
		}
	}

	gUser[playerid][u_chattime] = 0;
	format(gUser[playerid][u_chattext], 144, "");

	new string[144], reasonstr[25];
	switch(reason)
	{
	    case 0: reasonstr = "Timeout";
	    case 1: reasonstr = "Quit";
	    case 2: reasonstr = "Kicked/Banned";
	}
	format(string, sizeof(string), "* %s[%i] have left the server! [%s]", ReturnPlayerName(playerid), playerid, reasonstr);
	SendClientMessageToAll(COLOR_GREY, string);
	return 1;
}

//------------------------------------------------

ip2long(const sIP[])
{
	new
 		iCount = 0,
        iIPAddress = 0,
        iIPLenght = strlen(sIP);

	if(iIPLenght > 0 && iIPLenght < 17)
    {
    	for(new i = 0; i < iIPLenght; i++)
     		if(sIP[i] == '.')
       			iCount++;

		if(iCount == 3)
   		{
    		iIPAddress = strval(sIP) << 24;
        	iCount = strfind(sIP, ".", false, 0) + 1;
            iIPAddress += strval(sIP[iCount]) << 16;
           	iCount = strfind(sIP, ".", false, iCount) + 1;
            iIPAddress += strval(sIP[iCount]) << 8;
            iCount = strfind(sIP, ".", false, iCount) + 1;
            iIPAddress += strval(sIP[iCount]);
        }
    }
	return iIPAddress;
}

split(const sSrc[], sDest[][], sDelimiter = ' ')
{
	new
 		i = 0,
   		j = 0,
     	k = 0,
      	iSourceLen = strlen(sSrc),
        iLenght = 0;

	while(i <= iSourceLen)
    {
    	if(sSrc[i] == sDelimiter || i == iSourceLen)
     	{
      		iLenght = strmid(sDest[j], sSrc, k, i, 128);
        	sDest[j][iLenght] = 0;
         	k = i + 1;
          	j++;
		}
  		i++;
	}

	return true;
}

ipmatch(sIP[], sIP2[], iRange = 26)
{
	new
 		sRangeInfo[2][18],
   		iIP = 0,
     	iSubnet = 0,
      	iBits = 0,
       	iMask = 0,
   		sRange[35];

	format(sRange, sizeof(sRange), "%s/%i", sIP2, iRange);

	split(sRange, sRangeInfo, '/');
    iIP = ip2long(sIP);
    iSubnet = ip2long(sRangeInfo[0]);
    iBits = strval(sRangeInfo[1]);

    iMask = -1 << (32 - iBits);
    iSubnet &= iMask;

    return bool:((iIP & iMask) == iSubnet);
}

//------------------------------------------------

public OnPlayerRequestClass(playerid, classid)
{
	TextDrawHideForPlayer(playerid, gGlobal[s_reporttd]);
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, gUser[playerid][u_spectxt]);
	#endif

	for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_rangebantable]); i <= j; i++)
	{
	    new range[18];
	    DB::GetStringEntry(gGlobal[s_rangebantable], i, "ip", range);
	    if(ipmatch(ReturnPlayerIP(playerid), range))
		{
		    new val;
		    val = DB::GetIntEntry(gGlobal[s_rangebantable], i, "expire");
			if(val < gettime() || val == 0)//if the player ban has not expired
			{
			    //Ban stats stuff !:D!
				new str[100];
				new DIALOG[676];
				new string[156];
				strcat(DIALOG, ""SAMP_BLUE"You are range banned from the server:\n\n");
			    //ban player ip
				DB::GetStringEntry(gGlobal[s_rangebantable], i, "ip", str);
			    format(string, sizeof(string), ""WHITE"I.P. Banned: "MARONE"%s\n", str);
				strcat(DIALOG, string);
			    //admin name
				DB::GetStringEntry(gGlobal[s_rangebantable], i, "banby", str);
			    format(string, sizeof(string), ""WHITE"Banned by: "MARONE"%s\n", str);
				strcat(DIALOG, string);
				//reason
				DB::GetStringEntry(gGlobal[s_rangebantable], i, "reason", str);
			    format(string, sizeof(string), ""WHITE"Reason: "MARONE"%s\n", str);
				strcat(DIALOG, string);
				//ban date
				DB::GetStringEntry(gGlobal[s_rangebantable], i, "banon", str);
			    format(string, sizeof(string), ""WHITE"Ban date: "MARONE"%s\n", str);
				strcat(DIALOG, string);
				//expire time
			    new expire[68];
				if(val == 0) expire = "PERMANENT";
				else expire = ConvertTime(val);
			    format(string, sizeof(string), ""WHITE"Expiration timeleft: "MARONE"%s\n\n", expire);
				strcat(DIALOG, string);
				//shit!
				strcat(DIALOG, ""SAMP_BLUE"If you think your ban is a false ban, a bug, or the admin missued his/her power; Please place an appeal in forums.\n");
				strcat(DIALOG, "Make sure you have a screen this and some good evidence.");

				for(new c; c < 250; c++) SendClientMessage(playerid, -1, " ");

				//show BAN stats in dialog
				ShowPlayerDialog(	playerid,
									DIALOG_COMMON,
									DIALOG_STYLE_MSGBOX,
									"Player Range Banned",
									DIALOG,
									"Close",
									"");

			    DelayKick(playerid);
			    return 1;
			}
			else//if player ban has expired
			{
			    DB::DeleteRow(gGlobal[s_rangebantable], i);
			    break;
			}
	    }
	}

	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "ip", ReturnPlayerIP(playerid));
	if(bankey != DB_INVALID_KEY)
	{
	    bankey = DB::RetrieveKey(gGlobal[s_bantable], "ip", ReturnPlayerIP(playerid));
	}

	if(bankey != DB_INVALID_KEY)//if the player is banned
	{
	    new val;
	    val = DB::GetIntEntry(gGlobal[s_bantable], bankey, "expire");
		if(val < gettime() || val == 0)//if the player ban has not expired
		{
		    //Ban stats stuff !:D!
			new str[100];
			new DIALOG[676];
			new string[156];
			strcat(DIALOG, ""SAMP_BLUE"You are banned from the server:\n\n");
			//ban player name
			DB::GetStringEntry(gGlobal[s_bantable], bankey, "name", str);
		    format(string, sizeof(string), ""WHITE"Username: "MARONE"%s\n", str);
			strcat(DIALOG, string);
		    //ban player ip
			DB::GetStringEntry(gGlobal[s_bantable], bankey, "ip", str);
		    format(string, sizeof(string), ""WHITE"I.P.: "MARONE"%s\n", str);
			strcat(DIALOG, string);
		    //admin name
			DB::GetStringEntry(gGlobal[s_bantable], bankey, "banby", str);
		    format(string, sizeof(string), ""WHITE"Banned by: "MARONE"%s\n", str);
			strcat(DIALOG, string);
			//reason
			DB::GetStringEntry(gGlobal[s_bantable], bankey, "reason", str);
		    format(string, sizeof(string), ""WHITE"Reason: "MARONE"%s\n", str);
			strcat(DIALOG, string);
			//ban date
			DB::GetStringEntry(gGlobal[s_bantable], bankey, "banon", str);
		    format(string, sizeof(string), ""WHITE"Ban date: "MARONE"%s\n", str);
			strcat(DIALOG, string);
			//expire time
		    new expire[68];
			if(val == 0) expire = "PERMANENT";
			else expire = ConvertTime(val);
		    format(string, sizeof(string), ""WHITE"Expiration timeleft: "MARONE"%s\n\n", expire);
			strcat(DIALOG, string);
			//shit!
			strcat(DIALOG, ""SAMP_BLUE"If you think your ban is a false ban, a bug, or the admin missued his/her power; Please place an appeal in forums.\n");
			strcat(DIALOG, "Make sure you have a screen this and some good evidence.");

			for(new i; i < 250; i++) SendClientMessage(playerid, -1, " ");

			//show BAN stats in dialog
			ShowPlayerDialog(	playerid,
								DIALOG_COMMON,
								DIALOG_STYLE_MSGBOX,
								"Player Banned",
								DIALOG,
								"Close",
								"");

		    DelayKick(playerid);
		    return 1;
		}
		else//if player ban has expired
		{
		    DB::DeleteRow(gGlobal[s_bantable], bankey);
		}
	}

	////////

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));

	//server lock
	if(gGlobal[s_locked])
	{
	    if(	(key != DB_INVALID_KEY && DB::GetIntEntry(gGlobal[s_usertable], key, "admin") >= 1) ||
			IsPlayerAdmin(playerid))
		{
			SendClientMessage(playerid, COLOR_DODGER_BLUE, "The server is locked, but you were permited in (Admins allowed).");
		    return 1;
		}
		else
     	{
			TogglePlayerSpectating(playerid, true);

   			for(new i; i < 3; i++)
   			{
			   	TextDrawShowForPlayer(playerid, gGlobal[s_locktd][i]);
      		}

      		SendClientMessage(playerid, COLOR_RED, "- Server is locked -");
      		return 1;
      	}
	}
	//

    if(	GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE &&
		GetPVarType(playerid, "GAdmin_Guest") == PLAYER_VARTYPE_NONE)
	{
		if(key != DB_INVALID_KEY)
		{
	  		if(DB::GetIntEntry(gGlobal[s_usertable], key, "autologin"))
			{
			    new IP[18];
			    DB::GetStringEntry(gGlobal[s_usertable], key, "ip", IP);
				if(! strcmp(IP, ReturnPlayerIP(playerid)))
			    {
					gUser[playerid][u_admin] = DB::GetIntEntry(gGlobal[s_usertable], key, "admin");
					gUser[playerid][u_vip] = DB::GetIntEntry(gGlobal[s_usertable], key, "vip");
					gUser[playerid][u_kills] = DB::GetIntEntry(gGlobal[s_usertable], key, "kills");
					gUser[playerid][u_deaths] = DB::GetIntEntry(gGlobal[s_usertable], key, "deaths");
					gUser[playerid][u_score] = DB::GetIntEntry(gGlobal[s_usertable], key, "score");
					gUser[playerid][u_money] = DB::GetIntEntry(gGlobal[s_usertable], key, "money");
					gUser[playerid][u_hours] = DB::GetIntEntry(gGlobal[s_usertable], key, "hours");
					gUser[playerid][u_minutes] = DB::GetIntEntry(gGlobal[s_usertable], key, "minutes");
					gUser[playerid][u_seconds] = DB::GetIntEntry(gGlobal[s_usertable], key, "seconds");

					SetPlayerScore(playerid, gUser[playerid][u_score]);

					ResetPlayerMoney(playerid);
					GivePlayerMoney(playerid, gUser[playerid][u_money]);

					SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have been auto logged in. Check /stats for account statics.");

					new string[156];
					format(string, sizeof(string), "[Admin level: %i | Vip level: %i]", gUser[playerid][u_admin], gUser[playerid][u_vip]);
					SendClientMessage(playerid, COLOR_GREEN, string);

					PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

					SetPVarInt(playerid, "GAdmin_Loggedin", 1);
		        	DeletePVar(playerid, "GAdmin_Guest");
					return 1;
				}
			}
			new string[156];
			format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"is registered.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login account", string, "Login", "Skip");
			return 1;
		}
		else
		{
			new string[156];
			format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"doesn't exist in database.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register account", string, "Register", "Skip");
		}
	}
	return 1;
}

//------------------------------------------------

public OnPlayerRequestSpawn(playerid)
{
    if(	GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE &&
		GetPVarType(playerid, "GAdmin_Guest") == PLAYER_VARTYPE_NONE)
	{
	    GameTextForPlayer(playerid, "~r~You must be logged in to spawn", 5000, 3);
	    return 0;
	}
	return 1;
}

//------------------------------------------------

public OnPlayerSpawn(playerid)
{
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, gUser[playerid][u_spectxt]);
	#endif

    if(GetPVarType(playerid, "GAdmin_Jailed") != PLAYER_VARTYPE_NONE)
    {
		JailPlayer(playerid);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, "JAIL: You cannot escape your punishment. You are still in jail!");
		return 1;
	}

	if(GetPVarType(playerid, "GAdmin_Onduty") != PLAYER_VARTYPE_NONE)
	{
     	new randompos = random(sizeof(gAdminSpawn));
	    SetPlayerPos(playerid, gAdminSpawn[randompos][0], gAdminSpawn[randompos][1], gAdminSpawn[randompos][2]);
	    SetPlayerFacingAngle(playerid, gAdminSpawn[randompos][3]);

	    SetPlayerSkin(playerid, 217);
	    SetPlayerColor(playerid, COLOR_HOT_PINK);
	    SetPlayerTeam(playerid, 100);//admin team !:D!

	    //toggle godmode
	    if(GetPVarType(playerid, "GAdmin_God") == PLAYER_VARTYPE_NONE)
	    {
	        SetPVarInt(playerid, "GAdmin_God", 1);
	    }
	    SetPlayerHealth(playerid, FLOAT_INFINITY);

	    //load admin weapons
	    ResetPlayerWeapons(playerid);
	    GivePlayerWeapon(playerid, 38, 999999);//minigun

		GameTextForPlayer(playerid, "~b~~h~~h~~h~You are currently~n~~w~~h~ON DUTY", 5000, 3);
	    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	    return 1;
	}

	if(GetPVarType(playerid, "GAdmin_God") != PLAYER_VARTYPE_NONE)
	{
	    SetPlayerHealth(playerid, FLOAT_INFINITY);

		SendClientMessage(playerid, COLOR_LIME, "GOD: Your godmode is still enabled. Type /agod if you wish to disable it.");
	}


	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(gUser[i][u_specid] == playerid)
		    {
		        SetPlayerSpectating(i, playerid);
			}
		}
	}
	return 1;
}

//------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{
	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, gUser[playerid][u_spectxt]);
	#endif

    new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);

	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(gUser[i][u_specid] == playerid)
		    {
				SetPlayerCameraPos(i, pos[0], pos[1], (pos[2] + 5.0));
				SetPlayerCameraLookAt(i, pos[0], pos[1], pos[2]);
			}
		}
	}

	gUser[playerid][u_deaths] ++;
	gUser[playerid][u_sessiondeaths] ++;
	if(killerid != INVALID_PLAYER_ID)
	{
	    gUser[playerid][u_sessionkills] ++;
		gUser[killerid][u_kills] ++;

		gUser[playerid][u_spree] ++;
	}
	return 1;
}

//------------------------------------------------

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_REGISTER)
	{
	    if(! response)
	    {
	        #if defined FORCE_REGISTER
		        GameTextForPlayer(playerid, "~r~~h~~h~~h~Goodbye", 5000, 1);

	        	DelayKick(playerid);
	        #else
				new string[156];
				format(string, sizeof(string), "guest%i_%s", playerid, ReturnPlayerName(playerid));
	            SetPlayerName(playerid, string);//set player name to a random name, a guest to server
		        //don't worry, it will not collapse with other names!

                DeletePVar(playerid, "GAdmin_Loggedin");

				SetPVarInt(playerid, "GAdmin_Guest", 1);

		        GameTextForPlayer(playerid, "~g~~h~~h~~h~Welcome Guest", 5000, 1);
	        #endif
	    }
	    else
	    {
	        if(strlen(inputtext) < 4 || strlen(inputtext) > 35)
			{
				new string[156];
				format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"doesn't exist in database.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
				ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register account", string, "Register", "Skip");
				return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid password length, must be b/w 0-35.");
			}

			new DATE[18], date[3];
			getdate(date[0], date[1], date[2]);
			format(DATE, sizeof(DATE), "%i/%i/%i", date[2], date[1], date[0]);

            gUser[playerid][u_score] = GetPlayerScore(playerid);
            gUser[playerid][u_money] = GetPlayerMoney(playerid);

			new hash[65];
			DB::Hash(hash, sizeof(hash), inputtext);

            DB::CreateRow(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
			new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
			DB::SetStringEntry(gGlobal[s_usertable], key, "password", hash);
			DB::SetStringEntry(gGlobal[s_usertable], key, "ip", ReturnPlayerIP(playerid));
			DB::SetStringEntry(gGlobal[s_usertable], key, "joindate", DATE);
			DB::SetStringEntry(gGlobal[s_usertable], key, "laston", DATE);
			DB::SetIntEntry(gGlobal[s_usertable], key, "admin", gUser[playerid][u_admin]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "vip", gUser[playerid][u_vip]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "kills", gUser[playerid][u_kills]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "deaths", gUser[playerid][u_deaths]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "score", GetPlayerScore(playerid));
			DB::SetIntEntry(gGlobal[s_usertable], key, "money", GetPlayerMoney(playerid));
			DB::SetIntEntry(gGlobal[s_usertable], key, "hours", gUser[playerid][u_hours]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "minutes", gUser[playerid][u_minutes]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "seconds", gUser[playerid][u_seconds]);
			DB::SetIntEntry(gGlobal[s_usertable], key, "autologin", 0);

			SetPVarInt(playerid, "GAdmin_Loggedin", 1);

			DeletePVar(playerid, "GAdmin_Guest");

			new string[156];
			format(string, sizeof(string), "~g~~h~~h~~h~Welcome~n~~g~~h~~h~~h~%s", ReturnPlayerName(playerid));
		    GameTextForPlayer(playerid, string, 5000, 1);

			PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
			SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have successfully registered your account. Checkout your /stats.");
	    }
	}
	if(dialogid == DIALOG_LOGIN)
	{
	    if(! response)
	    {
	        #if defined FORCE_REGISTER
		        GameTextForPlayer(playerid, "~r~~h~~h~~h~Goodbye", 5000, 1);

	        	DelayKick(playerid);
	        #else
				new string[156];
				format(string, sizeof(string), "guest%i_%s", playerid, ReturnPlayerName(playerid));
	            SetPlayerName(playerid, string);//set player name to a random name, a guest to server
				//don't worry, it will not collapse with other names!

		        DeletePVar(playerid, "GAdmin_Loggedin");

				SetPVarInt(playerid, "GAdmin_Guest", 1);

		        GameTextForPlayer(playerid, "~g~~h~~h~~h~Welcome Guest", 5000, 1);
	        #endif
	    }
	    else
	    {
	        if(strlen(inputtext) < 4 || strlen(inputtext) > 35)
			{
				new string[156];
				format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"is registered.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login account", string, "Login", "Skip");
				return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid password length, must be b/w 0-35.");
			}

			new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));

			new hash[65];
			DB::Hash(hash, sizeof(hash), inputtext);

			new password[128];
			DB::GetStringEntry(gGlobal[s_usertable], key, "password", password);
	        if(! strcmp(hash, password))
	        {
				gUser[playerid][u_admin] = DB::GetIntEntry(gGlobal[s_usertable], key, "admin");
				gUser[playerid][u_vip] = DB::GetIntEntry(gGlobal[s_usertable], key, "vip");
				gUser[playerid][u_kills] = DB::GetIntEntry(gGlobal[s_usertable], key, "kills");
				gUser[playerid][u_deaths] = DB::GetIntEntry(gGlobal[s_usertable], key, "deaths");
				gUser[playerid][u_score] = DB::GetIntEntry(gGlobal[s_usertable], key, "score");
				gUser[playerid][u_money] = DB::GetIntEntry(gGlobal[s_usertable], key, "money");
				gUser[playerid][u_hours] = DB::GetIntEntry(gGlobal[s_usertable], key, "hours");
				gUser[playerid][u_minutes] = DB::GetIntEntry(gGlobal[s_usertable], key, "minutes");
				gUser[playerid][u_seconds] = DB::GetIntEntry(gGlobal[s_usertable], key, "seconds");

				DB::SetStringEntry(gGlobal[s_usertable], key, "ip", ReturnPlayerIP(playerid));

				SetPlayerScore(playerid, gUser[playerid][u_score]);

            	ResetPlayerMoney(playerid);
				GivePlayerMoney(playerid, gUser[playerid][u_money]);

				SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have successfully logged in. Check /stats for account statics.");

				new string[156];
				format(string, sizeof(string), "[Admin level: %i | Vip level: %i]", gUser[playerid][u_admin], gUser[playerid][u_vip]);
				SendClientMessage(playerid, COLOR_GREEN, string);

				PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

				format(string, sizeof(string), "~g~~h~~h~~h~Welcome~n~~g~~h~~h~~h~%s", ReturnPlayerName(playerid));
			    GameTextForPlayer(playerid, string, 5000, 1);

				gUser[playerid][u_attempts] = 0;

				SetPVarInt(playerid, "GAdmin_Loggedin", 1);

		        DeletePVar(playerid, "GAdmin_Guest");
	        }
	        else
	        {
				new string[156];

	            SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You have entered the worng password.");

				#if MAX_LOGIN_ATTEMPTS > 0
					gUser[playerid][u_attempts]++;
		            if(gUser[playerid][u_attempts] >= MAX_LOGIN_ATTEMPTS)
		            {
		                format(string, sizeof(string), "* %s[%d] has been automatically kicked [Reason: Too many failed login attempts]", ReturnPlayerName(playerid), playerid);
		                SendClientMessageToAll(COLOR_RED, string);
						DelayKick(playerid);
						return 1;
		            }
					format(string, sizeof(string), "WARNING: You have %i/"#MAX_LOGIN_ATTEMPTS" tries left to login.", gUser[playerid][u_attempts]);
     				SendClientMessage(playerid, COLOR_STEEL_BLUE, string);
				#endif

				format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"is registered.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login account", string, "Login", "Skip");
			}
	    }
	}

    if(dialogid == DIALOG_PLAYER_COLORS)
	{
		if(! response) DeletePVar(playerid, "PlayerColor");
   		if(response)
   		{
   		    new color, colorname[18];
    		switch(listitem)
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
			SetPlayerColor(GetPVarInt(playerid, "PlayerColor"), color);

			new string[144];
			format(string, sizeof(string), "You have set %s[%i]'s color to %s.", ReturnPlayerName(GetPVarInt(playerid, "PlayerColor")), GetPVarInt(playerid, "PlayerColor"), colorname);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

			format(string, sizeof(string), "admin %s[%i] has set your color to %s.", ReturnPlayerName(playerid), playerid, colorname);
			SendClientMessage(GetPVarInt(playerid, "PlayerColor"), COLOR_DODGER_BLUE, string);

			DeletePVar(playerid, "PlayerColor");
		}
	}

    if(dialogid == DIALOG_TELEPORTS)
    {
        if(response)
		{
			switch(listitem)
			{
				case 0: ShowPlayerDialog(playerid, DIALOG_TELEPORTS + 1, DIALOG_STYLE_LIST, "Los Santos", "Los Santos Airport \nPershing Square \nVinewood \nGrove Street \nRichman \nSanta Maria Beach \nOcean Docks \nDillimore \nPalomino Creek \nBlueBerry \nMontGomery", "Select", "Back");
				case 1: ShowPlayerDialog(playerid, DIALOG_TELEPORTS + 2, DIALOG_STYLE_LIST, "San Fierro", "San Fierro Airport \nGolden Gate Bridge \nMt. Chilliad \nCJ's garage \nSan Fierro Stadium \nOcean Flats \nMissionary Hill", "Select", "Back");
				case 2: ShowPlayerDialog(playerid, DIALOG_TELEPORTS + 3, DIALOG_STYLE_LIST, "Las Venturas", "Las Venturas Airport \nArea51 \nFour Dragons Casino \nLas Venturas Police Department \nBayside \nBig Jump \nLas Barrancas \nFort Carson \nLas Venturas Stadium \nNorthern Las Venturas \nStarfish Casino", "Select", "Back");
			}
		}
	}

	if(dialogid == DIALOG_TELEPORTS + 1)
    {
		if(! response) ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Select City", "Los Santos\nSan Fierro\nLas Venturas", "Select", "Close");
		if(response)
		{
			switch(listitem)
			{
				case 0: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1642.3022,-2333.6287,13.5469);
				case 1: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1511.8770,-1661.2853,13.5469);
				case 2: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1382.6194,-888.5532,38.0863);
				case 3: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2485.2546,-1684.7223,13.5096);
				case 4: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 597.6629,-1241.3900,18.1275);
				case 5: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 491.7868,-1823.2258,5.5028);
				case 6: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2771.1060,-2417.5828,13.6405);
				case 7: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 661.0361,-573.5891,16.3359);
				case 8: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2269.6877,-75.0973,26.7724);
				case 9: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 198.4328,-252.1696,1.5781);
 	    		case 10: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1242.2875,328.5506,19.7555);
			}
			GameTextForPlayer(playerid, "~g~Teleported", 3000, 3);
		}
	}

	if(dialogid == DIALOG_TELEPORTS + 2)
    {
        if(! response) ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Select City", "Los Santos\nSan Fierro\nLas Venturas", "Select", "Close");
		if(response)
		{
			switch(listitem)
			{
				case 0: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -1422.8820,-287.4992,14.1484);
				case 1: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2672.6116,1268.4943,55.9456);
				case 2: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2305.6143,-1626.0594,483.7662);
				case 3: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2026.2843,156.4974,29.0391);
				case 4: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2159.3616,-407.8362,35.3359);
				case 5: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2648.7498,14.2868,6.1328);
				case 6: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2521.4055,-623.5245,132.7727);
			}
			GameTextForPlayer(playerid, "~g~Teleported", 3000, 3);
		}
	}

	if(dialogid == DIALOG_TELEPORTS + 3)
    {
        if(! response) ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Select City", "Los Santos\nSan Fierro\nLas Venturas", "Select", "Close");
		if(response)
		{
			switch(listitem)
			{
				case 0: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1679.3361,1448.6248,10.7744);
				case 1: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 95.7283,1920.3488,18.1163);
				case 2: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2027.5721,1008.2877,10.8203);
				case 3: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2287.0313,2431.0276,10.8203);
				case 4: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -2241.4238,2327.4290,4.9844);
				case 5: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -670.6358,2306.0559,135.2990);
				case 6: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -761.5192,1552.1647,26.9609);
				case 7: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, -143.5370,1217.8855,19.7352);
				case 8: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1099.1533,1384.3300,10.8203);
				case 9: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 1614.2190,2334.9338,10.8203);
				case 10: SetPlayerInterior(playerid, 0), SetPlayerPos(playerid, 2572.6560,1818.1030,10.8203);
			}
			GameTextForPlayer(playerid, "~g~Teleported", 3000, 3);
		}
		return 1;
    }

    if(dialogid == DIALOG_MAIN)//main tune dialog
    {
        if(response)
        {
           	switch(listitem)
        	{
        	    // Paintjobs
        	    case 0: ShowPlayerDialog(playerid, DIALOG_PAINTJOBS, DIALOG_STYLE_LIST, "Paintjobs", "Paint Job 1\nPaint Job 2\nPaint Job 3\nPaint Job 4\nPaint Job 5", "Select", "Back");
        	    // colors
				case 1: ShowPlayerDialog(playerid, DIALOG_COLORS, DIALOG_STYLE_LIST, "Colors", "Black\nWhite\nRed\nBlue\nGreen\nYellow\nPink\nBrown\nGrey\nGold\nDark Blue\nLight Blue\nCold Green\nLight Grey\nDark Red\nDark Brown", "Select", "Back");
        	    // Hoods
        	    case 2: ShowPlayerDialog(playerid, DIALOG_HOODS, DIALOG_STYLE_LIST, "Hoods", "Fury\nChamp\nRace\nWorx", "Select", "Back");
        	    // Vents
        	    case 3: ShowPlayerDialog(playerid, DIALOG_VENTS, DIALOG_STYLE_LIST, "Vents", "Oval\nSquare", "Select", "Back");
        	    // Lights
        	    case 4: ShowPlayerDialog(playerid, DIALOG_LIGHTS, DIALOG_STYLE_LIST, "Lights", "Round\nSquare", "Select", "Back");
        	    // Exhausts
        	    case 5: ShowPlayerDialog(playerid, DIALOG_EXHAUSTS, DIALOG_STYLE_LIST, "Exhausts", "Wheel Arc. Alien exhaust\nWheel Arc. X-Flow exhaust\nLow Co. Chromer exhaust\nLow Co. Slamin exhaust\nTransfender Large exhaust\nTransfender Medium exhaust\nTransfender Small exhaust\nTransfender Twin exhaust\nTransfender Upswept exhaust", "Select", "Back");
        	    // Front Bumpers
				case 6: ShowPlayerDialog(playerid, DIALOG_FBUMPS, DIALOG_STYLE_LIST,"Front Bumpers", "Wheel Arc. Alien Bumper\nWheel Arc. X-Flow Bumper\nLow co. Chromer Bumper\nLow co. Slamin Bumper", "Select", "Back");
        	    // Rear Bumpers
				case 7: ShowPlayerDialog(playerid, DIALOG_RBUMPS, DIALOG_STYLE_LIST, "Rear Bumpers", "Wheel Arc. Alien Bumper\nWheel Arc. X-Flow Bumper\nLow Co. Chromer Bumper\nLow Co. Slamin Bumper", "Select", "Back");
        	    // Roofs
				case 8: ShowPlayerDialog(playerid, DIALOG_ROOFS, DIALOG_STYLE_LIST, "Roofs", "Wheel Arc. Alien\nWheel Arc. X-Flow\nLow Co. Hardtop Roof\nLow Co. Softtop Roof\nTransfender Roof Scoop", "Select", "Back");
        	    // Spoilers
				case 9: ShowPlayerDialog(playerid, DIALOG_SPOILERS, DIALOG_STYLE_LIST, "Spoilers", "Wheel Arc. Alien Spoiler\nWheel Arc. X-Flow Spoiler\nTransfender Win Spoiler\nTransfender Fury Spoiler\nTransfender Alpha Spoiler\nTransfender Pro Spoiler\nTransfender Champ Spoiler\nTransfender Race Spoiler\nTransfender Drag Spoiler", "Select", "Back");
        	    // Side Skirts
				case 10: ShowPlayerDialog(playerid, DIALOG_SIDESKIRTS, DIALOG_STYLE_LIST, "Side Skirts", "Wheel Arc. Alien Side Skirt\nWheel Arc. X-Flow Side Skirt\nLocos Chrome Strip\nLocos Chrome Flames\nLocos Chrome Arches \nLocos Chrome Trim\nLocos Wheelcovers\nTransfender Side Skirt", "Select", "Back");
        	    // Bullbars
				case 11: ShowPlayerDialog(playerid, DIALOG_BULLBARS, DIALOG_STYLE_LIST, "Bullbars", "Locos Chrome Grill\nLocos Chrome Bars\nLocos Chrome Lights \nLocos Chrome Bullbar", "Select", "Back");
        	    // Wheels
				case 12: ShowPlayerDialog(playerid, DIALOG_WHEELS, DIALOG_STYLE_LIST, "Wheels", "Offroad\nMega\nWires\nTwist\nGrove\nImport\nAtomic\nAhab\nVirtual\nAccess\nTrance\nShadow\nRimshine\nClassic\nCutter\nSwitch\nDollar", "Select", "Back");
        	    // Car Stereo
				case 13: ShowPlayerDialog(playerid, DIALOG_CSTEREO, DIALOG_STYLE_LIST, "Car Stereo", "Bass Boost", "Select", "Back");
        	    // Hydraulics
				case 14: ShowPlayerDialog(playerid, DIALOG_HYDRAULICS, DIALOG_STYLE_LIST, "Hydaulics", "Hydaulics", "Select", "Back");
        	    // Nitrous Oxide
				case 15: ShowPlayerDialog(playerid, DIALOG_NITRO, DIALOG_STYLE_LIST, "Nitrous Oxide", "2x Nitrous\n5x Nitrous\n10x Nitrous", "Select", "Back");
        	    // Repair Car
				case 16:
        	    {
					SetVehicleHealth(GetPlayerVehicleID(playerid), 1000);
					PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
				 	SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully repaired your car.");
					ShowPlayerTuneDialog(playerid);
					return 1;
        	    }
			}
		}
	}

	if(dialogid == DIALOG_PAINTJOBS)// Paintjobs
	{
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
			switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
			{
				case 562,565,559,561,560,575,534,567,536,535,576,558:
				{
					ChangeVehiclePaintjob(GetPlayerVehicleID(playerid), listitem);
					SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully added paintjob to your car.");
					PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
				}
				default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Paintjob is only for Wheel Arch Angels and Loco Low Co types of cars.");
			}
			ShowPlayerTuneDialog(playerid);
 		}
 	}

	if(dialogid == DIALOG_COLORS)// Colors
	{
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new colors[2], colorname[14];
			switch(listitem)
			{
                case 0: colors[0] = 0, colors[1] = 0, colorname = "Black";
        	    case 1: colors[0] = 1, colors[1] = 1, colorname = "White";
        	    case 2: colors[0] = 3, colors[1] = 3, colorname = "Red";
        	    case 3: colors[0] = 79, colors[1] = 79, colorname = "Blue";
        	    case 4: colors[0] = 86, colors[1] = 86, colorname = "Green";
        	    case 5: colors[0] = 6, colors[1] = 6, colorname = "Yellow";
        	    case 6: colors[0] = 126, colors[1] = 126, colorname = "Pink";
        	    case 7: colors[0] = 66, colors[1] = 66, colorname = "Brown";
        	    case 8: colors[0] = 24, colors[1] = 24, colorname = "Grey";
        	    case 9: colors[0] = 123, colors[1] = 123, colorname = "Gold";
        	    case 10: colors[0] = 53, colors[1] = 53, colorname = "Dark Blue";
        	    case 11: colors[0] = 93, colors[1] = 93, colorname = "Light Blue";
        	    case 12: colors[0] = 83, colors[1] = 83, colorname = "Cold Green";
        	    case 13: colors[0] = 60, colors[1] = 60, colorname = "Light Grey";
        	    case 14: colors[0] = 161, colors[1] = 161, colorname = "Dark Red";
        	    case 15: colors[0] = 153, colors[1] = 153, colorname = "Dark Brown";
			}
			ChangeVehicleColor(GetPlayerVehicleID(playerid), colors[0], colors[1]);
			new string[144];
			format(string, sizeof(string), "You have succesfully changed colour of your car to %s (%i & %i).", colorname, colors[0], colors[1]);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
			PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
			ShowPlayerTuneDialog(playerid);
		}
	}

	if(dialogid == DIALOG_EXHAUSTS)// Exhausts
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
		    new exhaust = 0;
            switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: exhaust = 1034;
						case 565: exhaust = 1046;
						case 559: exhaust = 1065;
						case 561: exhaust = 1064;
						case 560: exhaust = 1028;
						case 558: exhaust = 1089;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Wheel Arc. Alien exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: exhaust = 1037;
						case 565: exhaust = 1045;
						case 559: exhaust = 1066;
						case 561: exhaust = 1059;
						case 560: exhaust = 1029;
						case 558: exhaust = 1092;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Wheel Arc. X-Flow exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: exhaust = 1044;
						case 565: exhaust = 1126;
						case 559: exhaust = 1129;
						case 561: exhaust = 1104;
						case 560: exhaust = 1113;
						case 558: exhaust = 1136;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Low Co. Chromer exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: exhaust = 1043;
						case 565: exhaust = 1127;
						case 559: exhaust = 1132;
						case 561: exhaust = 1105;
						case 560: exhaust = 1114;
						case 558: exhaust = 1135;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Low Co. Slamin exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 4:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,527,542,589,400,517,603,426,547,405,580,550,549,477: exhaust = 1020;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Transfender Large exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 5:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 527,542,400,426,436,547,405,477: exhaust = 1021;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Transfender Twin exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 6:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 518,415,542,546,400,517,603,426,436,547,405,550,549,477: exhaust = 1019;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Transfender Twin exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 7:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,527,542,589,400,517,603,426,547,405,580,550,549,477: exhaust = 1018;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Ehausts to this vehicle.");
					}
					if(exhaust != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), exhaust);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed exhaust of your car to Transfender Upswept exhaust.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
	}

	if(dialogid == DIALOG_FBUMPS)
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
        	new bumper = 0;
            switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: bumper = 1171;
						case 565: bumper = 1153;
						case 559: bumper = 1160;
						case 561: bumper = 1155;
						case 560: bumper = 1169;
						case 558: bumper = 1166;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Front bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed front bumpers of your car to Wheel Arc. Alien Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: bumper = 1172;
						case 565: bumper = 1152;
						case 559: bumper = 1173;
						case 561: bumper = 1157;
						case 560: bumper = 1170;
						case 558: bumper = 1165;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Front bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed front bumpers of your car to Wheel Arc. X-Flow Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 575: bumper = 1174;
						case 534: bumper = 1179;
						case 567: bumper = 1189;
						case 536: bumper = 1182;
						case 535: bumper = 1115;
						case 576: bumper = 1191;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Front bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed front bumpers of your car to Low co. Chromer Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 575: bumper = 1175;
						case 534: bumper = 1185;
						case 567: bumper = 1188;
						case 536: bumper = 1181;
						case 535: bumper = 1116;
						case 576: bumper = 1190;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Front bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed front bumpers of your car to Low co. Slamin Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
	}

	if(dialogid == DIALOG_RBUMPS)// Rear bumbers
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
        	new bumper = 0;
            switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: bumper = 1149;
						case 565: bumper = 1150;
						case 559: bumper = 1159;
						case 561: bumper = 1154;
						case 560: bumper = 1141;
						case 558: bumper = 1168;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Rear bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed rear bumpers of your car to Wheel Arc. Alien Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: bumper = 1148;
						case 565: bumper = 1151;
						case 559: bumper = 1161;
						case 560: bumper = 1140;
						case 561: bumper = 1156;
						case 558: bumper = 1167;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add rear bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed rear bumpers of your car to Wheel Arc. X-Flow Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 575: bumper = 1176;
						case 534: bumper = 1180;
						case 567: bumper = 1187;
						case 536: bumper = 1184;
						case 535: bumper = 1109;
						case 576: bumper = 1192;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add rear bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed rear bumpers of your car to Low co. Chromer Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 575: bumper = 1177;
						case 534: bumper = 1178;
						case 567: bumper = 1186;
						case 536: bumper = 1183;
						case 535: bumper = 1110;
						case 576: bumper = 1193;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add rear bumpers to this vehicle.");
					}
					if(bumper != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), bumper);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed rear bumpers of your car to Low co. Slamin Bumper.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
	}

	if(dialogid == DIALOG_ROOFS)// Roofs
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
		    new roof = 0;
			switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: roof = 1038;
						case 565: roof = 1054;
						case 559: roof = 1067;
						case 561: roof = 1055;
						case 560: roof = 1032;
						case 558: roof = 1088;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Roof to this vehicle.");
					}
					if(roof != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), roof);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed roof of your car to Wheel Arc. Alien roof.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: roof = 1035;
						case 565: roof = 1053;
						case 559: roof = 1068;
						case 561: roof = 1061;
						case 560: roof = 1033;
						case 558: roof = 1091;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Roof to this vehicle.");
					}
					if(roof != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), roof);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed roof of your car to Wheel Arc. X-Flow roof.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 567: roof = 1130;
						case 536: roof = 1128;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Roof to this vehicle.");
					}
					if(roof != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), roof);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed roof of your car to Low Co. Hardtop roof.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 567: roof = 1131;
						case 536: roof = 1103;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Roof to this vehicle.");
					}
					if(roof != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), roof);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed roof of your car to Low Co. Softtop roof.");
					}
					ShowPlayerTuneDialog(playerid);
				}
				case 4:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,589,492,546,603,426,436,580,550,477: roof = 1006;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add Roof to this vehicle.");
					}
					if(roof != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), roof);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed roof of your car to Transfender Roof Scoop.");
					}
					ShowPlayerTuneDialog(playerid);
				}
 			}
		}
	}

	if(dialogid == DIALOG_SPOILERS)// Spoilers
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
		    new spoiler = 0;
			switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: spoiler = 1147;
						case 565: spoiler = 1049;
						case 559: spoiler = 1162;
						case 561: spoiler = 1158;
						case 560: spoiler = 1138;
						case 558: spoiler = 1164;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Wheel Arc. Alien.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: spoiler = 1146;
						case 565: spoiler = 1150;
						case 559: spoiler = 1158;
						case 561: spoiler = 1060;
						case 560: spoiler = 1139;
						case 558: spoiler = 1163;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Wheel Arc. X-Flow.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,527,415,546,603,426,436,405,477,580,550,549: spoiler = 1001;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Win Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 518,415,546,517,603,405,477,580,550,549: spoiler = 1023;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Fury Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 4:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 518,415,546,517,603,405,477,580,550,549: spoiler = 1003;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Alpha Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 5:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 589,492,547,405: spoiler = 1000;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Pro Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 6:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 527,542,405: spoiler = 1014;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Champ Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 7:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 527,542: spoiler = 1014;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Race Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 8:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 546,517: spoiler = 1002;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add spoiler to this vehicle.");
					}
					if(spoiler != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), spoiler);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed spoiler of your car to Transfender Drag Spoiler.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
	}

	if(dialogid == DIALOG_SIDESKIRTS)// Side skirts
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
		    new skirts[2] = {0, 0};
			switch(listitem)
            {
                case 0:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: skirts[0] = 1036, skirts[1] = 1040;
						case 565: skirts[0] = 1047, skirts[1] = 1051;
						case 559: skirts[0] = 1069, skirts[1] = 1071;
						case 561: skirts[0] = 1056, skirts[1] = 1062;
						case 560: skirts[0] = 1026, skirts[1] = 1027;
						case 558: skirts[0] = 1090, skirts[1] = 1094;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Wheel Arc. Alien Side Skirts.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 1:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 562: skirts[0] = 1039, skirts[1] = 1041;
						case 565: skirts[0] = 1048, skirts[1] = 1052;
						case 559: skirts[0] = 1070, skirts[1] = 1072;
						case 561: skirts[0] = 1057, skirts[1] = 1063;
						case 560: skirts[0] = 1031, skirts[1] = 1030;
						case 558: skirts[0] = 1093, skirts[1] = 1095;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Wheel Arc. X-Flow Side Skirts.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 2:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 575: skirts[0] = 1042, skirts[1] = 1099;
						case 567: skirts[0] = 1102, skirts[1] = 1133;
						case 576: skirts[0] = 1134, skirts[1] = 1137;
						case 536: skirts[0] = 1108, skirts[1] = 1107;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Locos Chrome Strip.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 3:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 534: skirts[0] = 1122, skirts[1] = 1101;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Locos Chrome Flames.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 4:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 534: skirts[0] = 1106, skirts[1] = 1124;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Locos Chrome Arches.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 5:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 535: skirts[0] = 1118, skirts[1] = 1120;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Locos Chrome Trim.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 6:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 535: skirts[0] = 1119, skirts[1] = 1121;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Locos Wheelcovers.");
					}
					ShowPlayerTuneDialog(playerid);
				}
                case 7:
                {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,527,415,589,546,517,603,436,439,580,549,477: skirts[0] = 1007, skirts[1] = 1017;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add side skirts to this vehicle.");
					}
					if(skirts[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), skirts[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed side skirts of your car to Transfender Side Skirt.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
    }

    if(dialogid == DIALOG_BULLBARS)// Bull bars
    {
        if(! response) ShowPlayerTuneDialog(playerid);
        if(response)
        {
            new bulls = 0, bullsname[26];
            switch(listitem)
            {
                case 0:
                {
                    if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 534) SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add bull bars to this vehicle.");
					else bulls = 1100, bullsname = "Locos Chrome Grill";
				}
				case 1:
				{
                    if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 534) SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add bull bars to this vehicle.");
					else bulls = 1123, bullsname = "Locos Chrome Bars";
				}
				case 2:
				{
                    if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 534) SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add bull bars to this vehicle.");
					else bulls = 1125, bullsname = "Locos Chrome Lights";
				}
				case 3:
				{
                    if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 535) SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add bull bars to this vehicle.");
					else bulls = 1117, bullsname = "Locos Chrome Bullbar";
				}
            }
            if(bulls != 0)
			{
				AddVehicleComponent(GetPlayerVehicleID(playerid), bulls);
				PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
				new string[144];
				format(string, sizeof(string), "You have succesfully changed bull bars of your car to %s.", bullsname);
				SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
			}
			ShowPlayerTuneDialog(playerid);
        }
    }

    if(dialogid == DIALOG_WHEELS)// Wheels
    {
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new wheels, wheelsname[26];
			switch(listitem)
			{
                case 0: wheels = 1025, wheelsname = "Offroad Wheels";
                case 1: wheels = 1074, wheelsname = "Mega Wheels";
                case 2: wheels = 1076, wheelsname = "Wires Wheels";
                case 3: wheels = 1078, wheelsname = "Twist Wheels";
                case 4: wheels = 1081, wheelsname = "Grove Wheels";
                case 5: wheels = 1082, wheelsname = "Import Wheels";
                case 6: wheels = 1085, wheelsname = "Atomic Wheels";
                case 7: wheels = 1096, wheelsname = "Ahab Wheels";
                case 8: wheels = 1097, wheelsname = "Virtual Wheels";
                case 9: wheels = 1098, wheelsname = "Access Wheels";
                case 10: wheels = 1084, wheelsname = "Trance Wheels";
                case 11: wheels = 1073, wheelsname = "Shadow Wheels";
                case 12: wheels = 1075, wheelsname = "Rimshine Wheels";
                case 13: wheels = 1077, wheelsname = "Classic Wheels";
                case 14: wheels = 1079, wheelsname = "Cutter Wheels";
                case 15: wheels = 1080, wheelsname = "Switch Wheels";
                case 16: wheels = 1083, wheelsname = "Dollar Wheels";
			}
			AddVehicleComponent(GetPlayerVehicleID(playerid), wheels);
			new string[144];
			format(string, sizeof(string), "You have succesfully changed wheels of your car to %s (%i).", wheelsname, wheels);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
			PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
			ShowPlayerTuneDialog(playerid);
		}
	}

	if(dialogid == DIALOG_WHEELS)// Stero
    {
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
			AddVehicleComponent(GetPlayerVehicleID(playerid), 1086);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully added a stero to your vehicle.");
			PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
			ShowPlayerTuneDialog(playerid);
		}
	}

	if(dialogid == DIALOG_HYDRAULICS)// Hydraulics
    {
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
			AddVehicleComponent(GetPlayerVehicleID(playerid), 1087);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully added hydraulics to your vehicle.");
			PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
			ShowPlayerTuneDialog(playerid);
		}
	}

	if(dialogid == DIALOG_NITRO)// Nitros !
    {
        if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new nitro, nitroname[5];
			switch(listitem)
			{
                case 0: nitro = 1008, nitroname = "2x";
                case 1: nitro = 1009, nitroname = "5x";
                case 2: nitro = 1010, nitroname = "10x";
			}
			AddVehicleComponent(GetPlayerVehicleID(playerid), nitro);
			new string[144];
			format(string, sizeof(string), "You have succesfully added nitros to your car, %s.", nitroname);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
			PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
			ShowPlayerTuneDialog(playerid);
		}
	}

	if(dialogid == DIALOG_HOODS)// Hoods
    {
		if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new hood = 0;
	        switch(listitem)
	        {
	            case 0:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,589,492,426,550: hood = 1005;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add hood to this vehicle.");
					}
					if(hood != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), hood);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed hood of your car to Fury.");
					}
					ShowPlayerTuneDialog(playerid);
				}
	            case 1:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,546,492,426,550: hood = 1004;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add hood to this vehicle.");
					}
					if(hood != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), hood);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed hood of your car to Champ.");
					}
					ShowPlayerTuneDialog(playerid);
				}
	            case 2:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 549: hood = 1011;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add hood to this vehicle.");
					}
					if(hood != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), hood);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed hood of your car to Race.");
					}
					ShowPlayerTuneDialog(playerid);
				}
	            case 3:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 549: hood = 1012;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add hood to this vehicle.");
					}
					if(hood != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), hood);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed hood of your car to Worx.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
	    }
    }

    if(dialogid == DIALOG_VENTS)// Vents
    {
		if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new vents[2] = {0, 0};
	        switch(listitem)
	        {
	            case 0:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,546,517,603,547,439,550,549: vents[0] = 1142, vents[1] = 1143;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add vents to this vehicle.");
					}
					if(vents[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), vents[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), vents[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed vents of your car to Oval.");
					}
					ShowPlayerTuneDialog(playerid);
				}
	            case 1:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,546,517,603,547,439,550,549: vents[0] = 1144, vents[1] = 1145;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add vents to this vehicle.");
					}
					if(vents[0] != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), vents[0]);
					    AddVehicleComponent(GetPlayerVehicleID(playerid), vents[1]);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed vents of your car to Square.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
    }

    if(dialogid == DIALOG_LIGHTS)// Lights
    {
		if(! response) ShowPlayerTuneDialog(playerid);
	    if(response)
	    {
	        new light = 0;
	        switch(listitem)
	        {
	            case 0:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 401,518,589,400,436,439: light = 1013;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add lights to this vehicle.");
					}
					if(light != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), light);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed lights of your car to Round.");
					}
					ShowPlayerTuneDialog(playerid);
				}
	            case 1:
	            {
		           	switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
					{
						case 589,603,400: light = 1024;
						default: SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't add lights to this vehicle.");
					}
					if(light != 0)
					{
					    AddVehicleComponent(GetPlayerVehicleID(playerid), light);
					    PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
						SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have succesfully changed lights of your car to Square.");
					}
					ShowPlayerTuneDialog(playerid);
				}
			}
		}
    }
	return 1;
}

//------------------------------------------------

public OnVehicleSpawn(vehicleid)
{
	LOOP_PLAYERS(i)
	{
        if(vehicleid == gUser[i][u_vehicle])
		{
		    EraseVeh(vehicleid);
	        gUser[i][u_vehicle] = -1;
        }
	}
	return 1;
}

//------------------------------------------------

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

//------------------------------------------------

public OnPlayerText(playerid, text[])
{
	if(gGlobal[s_locked]) return SendClientMessage(playerid, COLOR_RED, "ERROR: The server is locked.");

	//mute system
	if(GetPVarType(playerid, "GAdmin_Muted") != PLAYER_VARTYPE_NONE)
	{
		new string[144];
		format(string, sizeof(string), "ERROR: You are muted, you can't chat till %i seconds.", gUser[playerid][u_mutetime]);
		SendClientMessage(playerid, COLOR_FIREBRICK, string);
		return 0;
	}

	//admin chat interface
	if(GetPVarType(playerid, "GAdmin_Onduty") != PLAYER_VARTYPE_NONE)
	{
		new string[144];
		format(string, sizeof(string), "Admin %s[%i]: %s", ReturnPlayerName(playerid), playerid, text);
		SendClientMessage(playerid, COLOR_HOT_PINK, string);
	    return 0;
	}

	//anti flooding
    if((GetTickCount() - gUser[playerid][u_chattime]) < 2000)
	{
	    SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Please don't flood in the chat.");
	    return 0;
	}

	//anti spam
	if(strlen(text) == strlen(gUser[playerid][u_chattext]) && ! strcmp(gUser[playerid][u_chattext], text,  false))
	{
	    SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Please don't spam in the chat.");
		format(gUser[playerid][u_chattext][playerid], 144, "%s", text);
  		return 0;
	}

	//anti swear
	new place;
    for(new i = 0; i < gGlobal[s_fwordscount]; i++)
    {
        place = strfind(text, gForbidden_Words[i], true);
        if(place != -1)
        {
            for(new x = place; x < (place + strlen(gForbidden_Words[i])); x ++)
            {
                text[x] = '*';
            }
        }
    }

	format(gUser[playerid][u_chattext], 144, "%s", text);
    gUser[playerid][u_chattime] = GetTickCount();
	return 1;
}

//------------------------------------------------

public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if(gGlobal[s_locked]) return SendClientMessage(playerid, COLOR_RED, "ERROR: The server is locked.");

	//command mute system
	if(GetPVarType(playerid, "GAdmin_CMDMuted") != PLAYER_VARTYPE_NONE)
	{
		new string[144];
		format(string, sizeof(string), "ERROR: You are muted for commands, you can't input commands till %i seconds.", gUser[playerid][u_cmutetime]);
		SendClientMessage(playerid, COLOR_FIREBRICK, string);
		return 0;
	}

	//command mute system for jailed players
	if(GetPVarType(playerid, "GAdmin_Jailed") != PLAYER_VARTYPE_NONE)
	{
		SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are muted for commands until you are unjailed, you can't input commands.");
		return 0;
	}

	//read commands
	#if defined READ_COMMANDS
	    LOOP_PLAYERS(i)
	    {
	        if(strcmp("/changepass", cmdtext, true))
	        {
		        if(	IsPlayerGAdmin(i) &&
					GetPlayerGAdminLevel(i) > GetPlayerGAdminLevel(playerid) &&
					i != playerid)
		        {
					new string[144];
					format(string, sizeof(string), "** %s[%i] inputs: %s", ReturnPlayerName(playerid), playerid, cmdtext);
		            SendClientMessage(i, COLOR_GREY, string);
		        }
			}
	    }
	#endif
	return 1;
}

//------------------------------------------------

//Admin level 1+
CMD:acmds(playerid, params[])
{
	new DIALOG[1246+546];

	strcat(DIALOG, ""HOT_PINK"PLAYER COMMANDS:\n");
  	strcat(DIALOG, ""SAMP_BLUE"/admins, /vips, /report, /pm, /reply, /nopm, /stats, /register, /login, /changename, /changepass,\n");
  	strcat(DIALOG, ""SAMP_BLUE" /autologin, /savestats, /time, /id, /richlist, /scorelist, /search\n\n");

	if(GetPlayerGAdminLevel(playerid) >= 1 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""HOT_PINK"ADMIN LEVEL 1:\n");
  		strcat(DIALOG, ""SAMP_BLUE"/acmds, /weaps, /onduty, /reports, /repair, /addnos, /warn, /rewarn, /spec, /specoff,\n");
  		strcat(DIALOG, ""SAMP_BLUE"/flip, /ip, /goto, /setweather, /settime, /ann, /kick, /asay, /spawn\n\n");
	}
	if(GetPlayerGAdminLevel(playerid) >= 2 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""HOT_PINK"ADMIN LEVEL 2:\n");
  		strcat(DIALOG, ""SAMP_BLUE"/jetpack, /aweaps, /show, /muted, /jailed, /carhealth, /eject, /carpaint,\n");
  		strcat(DIALOG, ""SAMP_BLUE"/carcolor, /givecar, /car, /akill, /jail, /unjail, /mute, /unmute, /setskin,\n");
  		strcat(DIALOG, ""SAMP_BLUE"/cc, /heal, /armour, /setinterior, /setworld, /explode, /disarm, /tune\n");
  		strcat(DIALOG, ""SAMP_BLUE"/ban, /oban, /searchban, /searchipban, /searchrangeban, /unban, /atele, /ann2\n\n");
	}
	if(GetPlayerGAdminLevel(playerid) >= 3 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""HOT_PINK"ADMIN LEVEL 3:\n");
		strcat(DIALOG, ""SAMP_BLUE"/get, /write, /force, /healall, /armourall, /fightstyle, /sethealth, /setarmour, /destroycar,\n");
		strcat(DIALOG, "/agod, /resetcash, /getall, /freeze, /unfreeze, /giveweapon, /slap, /setcolor, /setcash, /setscore,\n");
		strcat(DIALOG, "/givecash, /givescore, /respawncar, /setkills, /setdeaths, /banip, /unbanip, /freezeall, /unfreezeall\n\n");
	}
	if(GetPlayerGAdminLevel(playerid) >= 4 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""HOT_PINK"ADMIN LEVEL 4:\n");
		strcat(DIALOG, ""SAMP_BLUE"/fakedeath, /cmdmuted, /cmdmute, /uncmdmute, /killall, /ejectall, /disarmall, /muteall, /unmuteall,\n");
		strcat(DIALOG, "/giveallscore, /giveallcash, /setalltime, /setallweather, /respawncars, /clearwindow, /giveallweapon,\n");
		strcat(DIALOG, "/object, /destroyobject, /editobject, /banrange, /unbanrange\n\n");
	}
	if(GetPlayerGAdminLevel(playerid) >= 5 || IsPlayerAdmin(playerid))
	{
		strcat(DIALOG, ""HOT_PINK"ADMIN LEVEL 5+:\n");
		strcat(DIALOG, ""SAMP_BLUE"/gmx, /removeuser, /fakecmd, /fakechat, /setlevel, /setvip, /forbidname, /forbidtag, /forbidword,\n");
		strcat(DIALOG, ""SAMP_BLUE"/pickup, /destroypickup, /reloaddb");
	}

	ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_MSGBOX, "Administrative help/commands list:", DIALOG, "Close", "");
	return 1;
}

CMD:spec(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target;
    if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spec [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(! IsPlayerSpawned(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not spawned.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't spectate to yourself.");

    if(IsPlayerSpectating(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is spectating a player.");

	GetPlayerPos(playerid, gUser[playerid][u_pos][0], gUser[playerid][u_pos][1], gUser[playerid][u_pos][2]);

	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawShow(playerid, gUser[playerid][u_spectxt]);
	#endif

	gUser[playerid][u_int] = GetPlayerInterior(playerid);
	gUser[playerid][u_vw] = GetPlayerVirtualWorld(playerid);

	SetPlayerSpectating(playerid, target);
	SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can use LCTRL (KEY_ACTION) and RCTRL (KEY_FIRE) to switch players.");
	SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can use MMB (KEY_LOOK_BEHIND) or /specoff to stop spectating.");
    return 1;
}

CMD:specoff(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    if(! IsPlayerSpectating(playerid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are not spectating.");

	TogglePlayerSpectating(playerid, false);

	#if defined SPECTATE_TEXTDRAW
		PlayerTextDrawHide(playerid, gUser[playerid][u_spectxt]);
	#endif

    gUser[playerid][u_spec] = false;
    gUser[playerid][u_specid] = INVALID_PLAYER_ID;
    SetPlayerPos(playerid, gUser[playerid][u_pos][0], gUser[playerid][u_pos][1], gUser[playerid][u_pos][2]);
    SetPlayerInterior(playerid, gUser[playerid][u_int]);
    SetPlayerVirtualWorld(playerid, gUser[playerid][u_vw]);
    return 1;
}

CMD:adminarea(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	GameTextForPlayer(playerid, "~g~Admin Area", 3000, 3);

	SetPlayerPos(playerid, 377, 170, 1008);
	SetPlayerFacingAngle(playerid, 90);
	SetPlayerInterior(playerid, 3);
	SetPlayerVirtualWorld(playerid, 0);
    return 1;
}

CMD:weaps(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /weaps [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	new weap, ammo, count;
	for(new i = 0; i < 14; i++)
	{
		GetPlayerWeaponData(target, i, weap, ammo);
		if(ammo != 0 && weap != 0)
		{
			count++;
			break;
		}
	}

	if(count < 1) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Players has no weapons.");

	SendClientMessage(playerid, COLOR_DODGER_BLUE, " ");
	new string[144];
	format(string, sizeof(string), "%s(%i) weapons:", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	new weaponname[28], x;
	for(new i = 0; i < 14; i++)
	{
		GetPlayerWeaponData(target, i, weap, ammo);
		if(ammo != 0 && weap != 0)
		{
			GetWeaponName(weap, weaponname, sizeof(weaponname));
			if(ammo == 65535 || ammo == 1) format(string, sizeof(string), "%s%s [1]",string, weaponname);
			else format(string, sizeof(string), "%s%s [%d]", string, weaponname, ammo);
   			x++;
			if(x >= 5)
			{
				SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    			x = 0;
				format(string, sizeof(string), "");
			}
			else format(string, sizeof(string), "%s, ", string);
		}
	}
	if(x <= 4 && x > 0)
	{
		string[strlen(string)-3] = '.';
		SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	}
	SendClientMessage(playerid, COLOR_DODGER_BLUE, " ");
	return 1;
}

CMD:onduty(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	if(GetPVarType(playerid, "GAdmin_Onduty") == PLAYER_VARTYPE_NONE)
	{
	    for(new i; i < MAX_PLAYER_ATTACHED_OBJECTS; i++) RemovePlayerAttachedObject(playerid, i);

    	gUser[playerid][u_duty3dtext] = CreateDynamic3DTextLabel("Admin on duty\nDon't shoot", COLOR_LIME, 0.0, 0.0, 0.3, 20.0, playerid, _, 1);

	    SetPlayerSkin(playerid, 217);
	    SetPlayerColor(playerid, COLOR_HOT_PINK);
	    SetPlayerTeam(playerid, 100);//admin team !:D!

	    //toggle godmode
	    if(GetPVarType(playerid, "GAdmin_God") == PLAYER_VARTYPE_NONE)
		{
			SetPVarInt(playerid, "GAdmin_God", 1);
	    }
		SetPlayerHealth(playerid, FLOAT_INFINITY);
	    SetPlayerArmour(playerid, 0.0);

	    //load admin weapons
	    ResetPlayerWeapons(playerid);
	    GivePlayerWeapon(playerid, 38, 999999);//minigun

		GameTextForPlayer(playerid, "~g~ADMIN DUTY ~w~~h~ON", 5000, 3);
	    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

		new string[144];
		format(string, sizeof(string), "%s[%i] is now on admin duty.", ReturnPlayerName(playerid), playerid);
	    SendClientMessageToAll(COLOR_RED, string);

	    SetPVarInt(playerid, "GAdmin_Onduty", 1);
	}
	else
 	{
	    SetPlayerTeam(playerid, 0);

		DestroyDynamic3DTextLabel(gUser[playerid][u_duty3dtext]);

		GameTextForPlayer(playerid, "~g~ADMIN DUTY ~w~~h~OFF", 5000, 3);
	    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

		DeletePVar(playerid, "GAdmin_God");

		new string[144];
		format(string, sizeof(string), "%s[%i] is now off admin duty.", ReturnPlayerName(playerid), playerid);
	    SendClientMessageToAll(COLOR_RED, string);
	    ForceClassSelection(playerid);
	    SetPlayerHealth(playerid, 0.0);

	    DeletePVar(playerid, "GAdmin_Onduty");
	}
	return 1;
}

CMD:reports(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	LOOP_PLAYERS(i)
	{
	    if(gUser[i][u_lastreported] != INVALID_PLAYER_ID)
	    {
	        SendClientMessage(playerid, COLOR_DODGER_BLUE, "* An admin is checking you report now.");
			gUser[i][u_lastreported] = INVALID_PLAYER_ID;
			gUser[i][u_lastreportedtime] = 0;
	    }
	}

	new DIALOG[956], string[156];
	strcat(DIALOG, ""LIME"Reports log sent by players\n\n");
	strcat(DIALOG, ""SAMP_BLUE"");
	for(new i; i < sizeof(gReportlog); i++)
	{
	    format(string, sizeof(string), ""SAMP_BLUE"%i. %s\n\n", i, gReportlog[i]);
	    strcat(DIALOG, string);
	}

	ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_MSGBOX, "Reports log", DIALOG, "Close", "");
	return 1;
}

CMD:repair(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	if(IsPlayerInAnyVehicle(playerid))
	{
		RepairVehicle(GetPlayerVehicleID(playerid));
		GameTextForPlayer(playerid, "~b~~h~~h~~h~Vehicle Repaired", 5000, 3);
  		SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
  		return 1;
	}
	SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You must be in a vehicle to repair.");
	return 1;
}

CMD:fix(playerid, params[]) return cmd_repair(playerid, params);

CMD:addnos(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	if(IsPlayerInAnyVehicle(playerid))
	{
        switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
		{
			case 448,461,462,463,468,471,509,510,521,522,523,581,586,449:
			{
				return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot add nitros to this vehicle.");
			}
		}
		GameTextForPlayer(playerid, "~b~~h~~h~~h~Nitros Added", 5000, 3);
        AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
		return 1;
	}
	SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You must be in a vehicle to repair.");
	return 1;
}

CMD:warn(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new target, reason[128];
    if(sscanf(params, "uS(No reason specified)[128]", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /warn [player] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

    if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot warn yourself.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has warned %s[%i] [Reason: %s] (warnings: %i)", ReturnPlayerName(playerid), playerid, ReturnPlayerName(target), target, reason, gUser[target][u_warnings]);
	SendClientMessageToAll(COLOR_YELLOW, string);

	gUser[target][u_warnings] += 1;
	if(gUser[target][u_warnings] >= MAX_WARNINGS)
	{
		format(string, sizeof(string), "* %s[%d] has been automatically kicked [Reason: Exceeded maximum warnings] (Warnings: %i/"#MAX_WARNINGS")", ReturnPlayerName(target), target, gUser[target][u_warnings]);
	    SendClientMessageToAll(COLOR_RED, string);
		DelayKick(target);
		return 1;
	}

	format(string, sizeof(string), ""SAMP_BLUE"You have been issued a WARNING.\n\n"SAMP_BLUE"Admin: "PINK"%s\n"SAMP_BLUE"Reason: "PINK"%s\n"SAMP_BLUE"Warnings count: "PINK"%i/"#MAX_WARNINGS"\n\n"SAMP_BLUE"If you think this is a bug, false warn, or the admin abused his/her power, Please place a report on forums.", ReturnPlayerName(playerid), reason, gUser[target][u_warnings]);
  	ShowPlayerDialog(target, DIALOG_COMMON, DIALOG_STYLE_MSGBOX, "Warning issued", string, "Close", "");
	return 1;
}

CMD:rewarn(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target, reason[45];
    if(sscanf(params, "u", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /rewarn [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	gUser[target][u_warnings] = 0;

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has remove your warning counts (warnings: %i)", ReturnPlayerName(playerid), playerid, gUser[target][u_warnings]);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have removed %s[%i]'s warning counts (warnings: %i)", ReturnPlayerName(target), target, gUser[target][u_warnings]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:flip(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target;
    if(! sscanf(params, "u", target))
    {
		if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

		if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

		if(! IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is not in a vehicle.");

		new Float:angle;
		GetVehicleZAngle(GetPlayerVehicleID(target), angle);
		SetVehicleZAngle(GetPlayerVehicleID(target), angle);

		GameTextForPlayer(target, "~b~~h~~h~~h~Vehicle Fliped", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
		PlayerPlaySound(target, 1133, 0.0, 0.0, 0.0);

		new string[144];
		format(string, sizeof(string), "You have fliped %s[%i]'s vehicle.", ReturnPlayerName(target), target);
		SendClientMessage(target, COLOR_DODGER_BLUE, string);
		format(string, sizeof(string), "admin %s[%i] has flipped your vehicle.", ReturnPlayerName(playerid), playerid);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }
    else
    {
		if(! IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You must be in a vehicle to flip.");

		new Float:angle;
		GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
        SetVehicleZAngle(GetPlayerVehicleID(playerid), angle);

		GameTextForPlayer(target, "~b~~h~~h~~h~Vehicle Fliped", 5000, 3);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have fliped your vehicle.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can flip other player's vehicle by /flip [player].");
    }
	return 1;
}

CMD:ip(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ip [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new string[144];
	format(string, sizeof(string), "%s[%i]'s IP: %s", ReturnPlayerName(target), target, ReturnPlayerIP(playerid));
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:spawn(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target;
    if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spawn [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SpawnPlayer(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has re-spawned you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have respawned %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:goto(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /goto [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't teleport to yourself.");

	new Float:pos[3];
	GetPlayerPos(target, pos[0], pos[1], pos[2]);
	SetPlayerInterior(playerid, GetPlayerInterior(target));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));
	if(GetPlayerState(playerid) == 2)
	{
		SetVehiclePos(GetPlayerVehicleID(playerid), pos[0] + 2.5, pos[1], pos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(target));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(target));
	}
	else SetPlayerPos(playerid, pos[0] + 2.0, pos[1], pos[2]);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have teleported to %s[%i]'s position.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setweather(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new target, id;
	if(sscanf(params, "ui", target, id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setweather [player] [weatherid]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(id < 0 || id > 45) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weather id, must be b/w 0-45.");

	SetPlayerWeather(target, id);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has changed your weather to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have cahnged %s[%i]'s weather to %i.", ReturnPlayerName(target), target, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:settime(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new target, id;
	if(sscanf(params, "ui", target, id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /settime [player] [timeid]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(id < 0 || id > 24) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weather id, must be b/w 0-24.");

	SetPlayerTime(target, id, 0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has changed your time to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have cahnged %s[%i]'s time to %i.", ReturnPlayerName(target), target, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:ann(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new message[35];
	if(sscanf(params, "s[35]", message)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ann [message]");

	GameTextForAll(message, 5000, 3);
	return 1;
}

CMD:kick(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

    new target, reason[45];
	if(sscanf(params, "us[128]", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /kick [player] [reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't kick yourself.");

	new message[144];
	format(message, sizeof(message), "* %s[%i] has been kicked by admin %s[%i] [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, reason);
	SendClientMessageToAll(COLOR_RED, message);

	DelayKick(target);
	return 1;
}

CMD:asay(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 1);

	new message[135];
	if(sscanf(params, "s[135]", message)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /asay [message]");

	new string[144];
	format(string, sizeof(string), "Admin %s[%i]: %s", ReturnPlayerName(playerid), playerid, message);
    SendClientMessageToAll(COLOR_HOT_PINK, string);
	return 1;
}

//------------------------------------------------

//Admin level 2+
CMD:jetpack(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
	if(	sscanf(params, "u", target) ||
		! sscanf(params, "u", target) && playerid == target)
	{
	    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
		SendClientMessage(playerid, COLOR_DODGER_BLUE, "You have spawned a jetpack.");
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can also give jetpack to players by /jetpack [player].");
		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
		return 1;
	}

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerSpecialAction(target, SPECIAL_ACTION_USEJETPACK);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has given you a jetpack.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have given %s[%i] a jetpack.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:aweaps(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

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

	GameTextForPlayer(playerid, "~b~~h~~h~~h~Weapons recieved", 5000, 3);
    return 1;
}

CMD:show(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, message[35];
	if(sscanf(params, "us[35]", target, message)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /show [player] [message]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't show message to yourself.");

	GameTextForPlayer(target, message, 5000, 3);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has sent you a screen message.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have sent %s[%i] a scren message.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:ann2(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new style, expiretime, message[35];
	if(sscanf(params, "iis[35]", style, expiretime, message)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ann2 [style] [expiretime] [message]");

	GameTextForAll(message, expiretime, style);
	return 1;
}

CMD:muted(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new DIALOG[98+670], string[128], bool:count = false;

	LOOP_PLAYERS(i)
	{
	    if(GetPVarType(i, "GAdmin_Muted") != PLAYER_VARTYPE_NONE)
	    {
	    	format(string, sizeof(string), "%i. %s - Unmute in %i secs..", i, ReturnPlayerName(i), gUser[i][u_mutetime]);
	        strcat(DIALOG, string);
			count = true;
	    }
	}
	if(! count) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: No muted players in the server.");
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_LIST, "Muted players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:jailed(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new DIALOG[98+670], string[128], bool:count = false;

	LOOP_PLAYERS(i)
	{
	    if(GetPVarType(i, "GAdmin_Jailed") != PLAYER_VARTYPE_NONE)
	    {
	    	format(string, sizeof(string), "%i. %s - Unjail in %i secs..", i, ReturnPlayerName(i), gUser[i][u_jailtime]);
	        strcat(DIALOG, string);
			count = true;
	    }
	}
	if(! count) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: No jailed players in the server.");
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_LIST, "Jailed players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:carhealth(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, Float:amount;
	if(sscanf(params, "uf", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carhealth [player] [amount]");
	else if(! sscanf(params, "f", amount)) target = playerid;

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(! IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not in any vehicle.");

	SetVehicleHealth(GetPlayerVehicleID(target), amount);
	PlayerPlaySound(target, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your car's health to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s car health to %.2f.", ReturnPlayerName(target), target, VehicleNames[GetVehicleModel(GetPlayerVehicleID(target)) - 400], amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:eject(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
    if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /eject [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(! IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not in any vehicle.");

	new Float:pos[3];
	GetPlayerPos(target, pos[0], pos[1], pos[2]);
	SetPlayerPos(target, pos[0], pos[1], pos[2] + 3.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has ejected you from your vehicle.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have ejected %s[%i] from his vehicle.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:carpaint(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, paint;
	if(sscanf(params, "ui", target, paint)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carpaint [player] [paintjob]");
	else if(! sscanf(params, "i", paint)) target = playerid;

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(! IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not in any vehicle.");

	if(paint < 0 || paint > 3) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid paintjob id, must be b/w 0-3.");

	ChangeVehiclePaintjob(GetPlayerVehicleID(target), paint);
	PlayerPlaySound(target, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your vehicle's paintjob id to %i.", ReturnPlayerName(playerid), playerid, paint);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s vehicle's paintjob id to %i.", ReturnPlayerName(target), target, paint);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:carcolor(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, color[2];
	if(sscanf(params, "uiI(-1)", target, color[0], color[1])) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /carcolor [player] [color1] [*color2]");
	else if(! sscanf(params, "iI(-1)", color[0], color[1])) target = playerid;

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(! IsPlayerInAnyVehicle(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not in any vehicle.");

	if(color[1] == -1) color[1] = random(256);//random color
	PlayerPlaySound(target, 1133, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);

	ChangeVehicleColor(GetPlayerVehicleID(target), color[0], color[1]);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your vehicle's color to %i & %i.", ReturnPlayerName(playerid), playerid, color[0], color[1]);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s vehicle's paintjob to %i & %i.", ReturnPlayerName(target), target, color[0], color[1]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:givecar(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

    new target, vehicle[32], model, color[2];
	if(sscanf(params, "us[32]I(-1)I(-1)", target, vehicle, color[0], color[1])) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givecar [player] [vehicle] [*color1] [*color2]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(isnumeric(vehicle)) 	model = strval(vehicle);
    else 					model = GetVehicleModelIDFromName(vehicle);

	if(model < 400 || model > 611) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid vehicle model id, must be b/w 400-611.");

	new Float:pos[4];
	GetPlayerPos(target, pos[0], pos[1], pos[2]);
    GetPlayerFacingAngle(target, pos[3]);

	if(IsPlayerInAnyVehicle(target)) SetPlayerPos(target, pos[0] + 3.0, pos[1], pos[2]);//ejected!

	if(color[0] == -1) color[0] = random(256);
	if(color[1] == -1) color[1] = random(256);

	if(gUser[target][u_vehicle] != -1) EraseVeh(gUser[target][u_vehicle]);//delete previous vehicle

	gUser[target][u_vehicle] = CreateVehicle(model, pos[0] + 3.0, pos[1], pos[2], pos[3], color[0], color[1], -1);
    SetVehicleVirtualWorld(gUser[target][u_vehicle], GetPlayerVirtualWorld(target));
    LinkVehicleToInterior(gUser[target][u_vehicle], GetPlayerInterior(target));
    PutPlayerInVehicle(target, gUser[target][u_vehicle], 0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has given you vehicle %s[model: %i], colors: %i & %i.", ReturnPlayerName(playerid), playerid, VehicleNames[model - 400], model, color[0], color[1]);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have given %s[%i] vehicle %s[model: %i], colors: %i & %i.", ReturnPlayerName(target), target, VehicleNames[model - 400], model, color[0], color[1]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:car(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

    new vehicle[32], model, color[2];
	if(sscanf(params, "s[32]I(-1)I(-1)", vehicle, color[0], color[1])) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /car [vehicle] [*color1] [*color2]");

	if(isnumeric(vehicle)) 	model = strval(vehicle);
    else 					model = GetVehicleModelIDFromName(vehicle);

	if(model < 400 || model > 611) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid vehicle model id, must be b/w 400-611.");

	new Float:pos[4];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
    GetPlayerFacingAngle(playerid, pos[3]);

	if(IsPlayerInAnyVehicle(playerid)) SetPlayerPos(playerid, pos[0] + 3.0, pos[1], pos[2]);//ejected!

	if(color[0] == -1) color[0] = random(256);
	if(color[1] == -1) color[1] = random(256);

	if(gUser[playerid][u_vehicle] != -1) EraseVeh(gUser[playerid][u_vehicle]);//delete previous vehicle

	gUser[playerid][u_vehicle] = CreateVehicle(model, pos[0] + 3.0, pos[1], pos[2], pos[3], color[0], color[1], -1);
    SetVehicleVirtualWorld(gUser[playerid][u_vehicle], GetPlayerVirtualWorld(playerid));
    LinkVehicleToInterior(gUser[playerid][u_vehicle], GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, gUser[playerid][u_vehicle], 0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have spawned a vehicle %s[model: %i], colors: %i & %i.", VehicleNames[model - 400], model, color[0], color[1]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:akill(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, reason[128];
    if(sscanf(params, "uS(No reason specified)[128]", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /akill [player] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

    SetPlayerHealth(target, 0.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] was killed by admin %s[%i] [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:jail(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No reason specified)[128]", target, time, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /jail [player] [*seconds] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(time > 5*60 || time < 10) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The jail time must be b/w 10 - 360(5 minutes) seconds.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot jail yourself.");

	if(GetPVarType(target, "GAdmin_Jailed") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is already in jail.");

	SetPVarInt(target, "GAdmin_Jailed", 1);

	gUser[target][u_jailtime] = time;
	JailPlayer(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been jailed by admin %s[%i] for %i seconds [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "~b~~h~~h~~h~Jailed for %i secs", time);
	GameTextForPlayer(target, string, 5000, 3);
	return 1;
}

CMD:unjail(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unjail [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(GetPVarType(target, "GAdmin_Jailed") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is not in jail.");

	DeletePVar(target, "GAdmin_Jailed");

	gUser[target][u_jailtime] = 0;
	SpawnPlayer(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been unjailed by admin %s[%i]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	GameTextForPlayer(target, "~b~~h~~h~~h~Unjailed", 5000, 3);
	return 1;
}

CMD:mute(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No reason specified)[128]", target, time, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /mute [player] [*seconds] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(time > 5*60 || time < 10) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The mute time must be b/w 10 - 360(5 minutes) seconds.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot mute yourself.");

	if(GetPVarType(target, "GAdmin_Muted") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is already in muted.");

	SetPVarInt(target, "GAdmin_Muted", 1);

	gUser[target][u_mutetime] = time;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been muted by admin %s[%i] for %i seconds [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "~b~~h~~h~~h~Muted for %i secs", time);
	GameTextForPlayer(target, string, 5000, 3);
	return 1;
}

CMD:unmute(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unmute [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(GetPVarType(target, "GAdmin_Muted") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is not muted.");

	DeletePVar(playerid, "GAdmin_Muted");

	gUser[target][u_mutetime] = 0;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been unmuted by admin %s[%i]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	GameTextForPlayer(target, "~b~~h~~h~~h~Unmuted", 5000, 3);
	return 1;
}

CMD:atele(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Select City", "Los Santos\nSan Fierro\nLas Venturas", "Select", "Close");
	return 1;
}

CMD:setskin(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, skin;

	if(sscanf(params, "ui", target, skin)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setskin [player] [skinid]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(skin < 0 || skin == 74 || skin > 299) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid skin id, must be b/w 0 - 299 (except 74).");

    SetPlayerSkin(target, skin);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s[%i] has set your skin id to %i.", ReturnPlayerName(playerid), playerid, skin);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s skin id to %i.", ReturnPlayerName(target), target, skin);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:cc(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	for(new i; i < 250; i++) SendClientMessageToAll(-1, " ") && PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has cleared all chat.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:heal(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;

    if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /heal [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

    SetPlayerHealth(target, 100.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has healed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have healed %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:armour(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;

    if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /armour [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

    SetPlayerArmour(target, 100.0);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has armoured you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have armoured %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setinterior(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, id;
	if(sscanf(params, "ui", target, id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setinterior [player] [interior]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerInterior(target, id);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s[%i] has set your interior id to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s interior id to %i.", ReturnPlayerName(target), target, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setworld(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, id;
	if(sscanf(params, "ui", target, id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setworld [player] [worldid]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerVirtualWorld(target, id);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Admin %s[%i] has set your virtual world id to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s virtual world id to %i.", ReturnPlayerName(target), target, id);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:explode(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /explode [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new Float:pos[3];
	GetPlayerPos(target, pos[0], pos[1], pos[2]);
	CreateExplosion(pos[0], pos[1], pos[2], 7, 1.00);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have made an explosion on %s[%i]'s position.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:disarm(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /disarm [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	ResetPlayerWeapons(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has disarmed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have disarmed %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

ShowPlayerTuneDialog(playerid)
{
    ShowPlayerDialog(	playerid,
						DIALOG_MAIN,
						DIALOG_STYLE_LIST,
						"Vehicle tuning:",
						"Paint Jobs\n\
						Colors\n\
						Hoods\n\
						Vents\n\
						Lights\n\
						Exhausts\n\
						Front Bumpers\n\
						Rear Bumpers\n\
						Roofs\n\
						Spoilers\n\
						Side Skirts\n\
						Bullbars\n\
						Wheels\n\
						Car Stereo\n\
						Hydraulics\n\
						Nitrous Oxide\n\
						Repair Car",
						"Enter",
						"Close"
					);
	return true;
}

CMD:tune(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You must be in a vehicle as driver.");

	ShowPlayerTuneDialog(playerid);
	return 1;
}

CMD:ban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new target, reason[35], days;
	if(sscanf(params, "is[35]I(0)", target, reason, days)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /ban [player] [reason] [*days]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

    if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't ban yourself.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(days < 0) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");

	if(strlen(reason) < 3 || strlen(reason) > 35) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid reason length, must be b/w 0-35 characters.");

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());

	DB::CreateRow(gGlobal[s_bantable], "name", ReturnPlayerName(target));
	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "name", ReturnPlayerName(target));
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "ip", ReturnPlayerIP(target));
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banby", ReturnPlayerName(playerid));
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banon", bandate);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "reason", reason);
	DB::SetIntEntry(gGlobal[s_bantable], bankey, "expire", time);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* %s[%i] has been banned by admin %s[%d] [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, reason);
		SendClientMessage(target, COLOR_RED, string);
	}
	else
	{
	    new string[144];
	    format(string, sizeof(string), "* %s[%i] has been temp banned by admin %s[%d] [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, reason);
		SendClientMessage(target, COLOR_RED, string);
	    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime(time));
		SendClientMessage(target, COLOR_RED, string);
	}
 	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	DelayKick(target);
	return 1;
}

CMD:oban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new name[MAX_PLAYER_NAME], reason[35], days;
	if(sscanf(params, "s[24]s[35]I(0)", name, reason, days)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /oban [username] [reason] [*days]");

    if(! strcmp(name, ReturnPlayerName(playerid))) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't ban yourself.");

	LOOP_PLAYERS(i)
	{
	    if(! strcmp(name, ReturnPlayerName(i), false))
	    {
	        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified username is online. Try /ban instead.");
	    }
	}

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", name);
	if(key != DB_INVALID_KEY)
	{
		if(GetPlayerGAdminLevel(playerid) < DB::GetIntEntry(gGlobal[s_usertable], key, "admin")) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");
	}

	key = DB::RetrieveKey(gGlobal[s_bantable], "name", name);
	if(key != DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified user is already banned.");

	if(days < 0) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");

	if(strlen(reason) < 3 || strlen(reason) > 35) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid reason length, must be b/w 0-35 characters.");

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());

	DB::CreateRow(gGlobal[s_bantable], "name", name);
	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "name", name);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "ip", "");
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banby", ReturnPlayerName(playerid));
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banon", bandate);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "reason", reason);
	DB::SetIntEntry(gGlobal[s_bantable], bankey, "expire", time);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* %s has been offline banned by admin %s[%d] [Reason: %s]", name, ReturnPlayerName(playerid), playerid, reason);
		SendClientMessageToAll(COLOR_RED, string);
	}
	else
	{
	    new string[144];
	    format(string, sizeof(string), "* %s has been offline temp banned by admin %s[%d] [Reason: %s]", name, ReturnPlayerName(playerid), playerid, reason);
		SendClientMessageToAll(COLOR_RED, string);
	    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime(time));
		SendClientMessageToAll(COLOR_RED, string);
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:searchban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new name[MAX_PLAYER_NAME];
	if(sscanf(params,"s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /searchban [name]");

	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "name", name);
	if(bankey == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified username is not banned.");

	new str[100];
	new DIALOG[676];
	new string[156];
	//search result base !:D!
	format(string, sizeof(string), ""SAMP_BLUE"Search ban results for %s:\n\n", name);
	strcat(DIALOG, string);
	//user ip
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "ip", str);
	format(string, sizeof(string), ""WHITE"IP: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//admin name
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "banby", str);
	format(string, sizeof(string), ""WHITE"Banned by: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//reason
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "reason", str);
	format(string, sizeof(string), ""WHITE"Reason: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//ban date
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "banon", str);
	format(string, sizeof(string), ""WHITE"Ban date: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//expire time
	new val = DB::GetIntEntry(gGlobal[s_bantable], bankey, "expire");
	new expire[68];
	if(val == 0) expire = "PERMANENT";
	else expire = ConvertTime(val);
	format(string, sizeof(string), ""WHITE"Expiration timeleft: "MARONE"%s\n", expire);
	strcat(DIALOG, string);

	//show BAN stats in dialog
	ShowPlayerDialog(	playerid,
						DIALOG_COMMON,
						DIALOG_STYLE_MSGBOX,
						"Search-Ban results",
						DIALOG,
						"Close",
						"");
	return 1;
}

CMD:searchipban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new ip[18];
	if(sscanf(params,"s[18]", ip)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /searchipban [ip]");

	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "ip", ip);
	if(bankey == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is not banned.");

	new str[100];
	new DIALOG[676];
	new string[144];
	//search result base !:D!
	format(string, sizeof(string), ""SAMP_BLUE"Search ban results for ip %s:\n\n", ip);
	strcat(DIALOG, string);
	//user name
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "name", str);
	format(string, sizeof(string), ""WHITE"Username: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//admin name
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "banby", str);
	format(string, sizeof(string), ""WHITE"Banned by: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//reason
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "reason", str);
	format(string, sizeof(string), ""WHITE"Reason: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//ban date
	DB::GetStringEntry(gGlobal[s_bantable], bankey, "banon", str);
	format(string, sizeof(string), ""WHITE"Ban date: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//expire time
	new val = DB::GetIntEntry(gGlobal[s_bantable], bankey, "expire");
	new expire[68];
	if(val == 0) expire = "PERMANENT";
	else expire = ConvertTime(val);
	format(string, sizeof(string), ""WHITE"Expiration timeleft: "MARONE"%s\n", expire);
	strcat(DIALOG, string);

	//show BAN stats in dialog
	ShowPlayerDialog(	playerid,
						DIALOG_COMMON,
						DIALOG_STYLE_MSGBOX,
						"Search-Ban results",
						DIALOG,
						"Close",
						"");
	return 1;
}

CMD:searchrangeban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new ip[18];
	if(sscanf(params,"s[18]", ip)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /searchrangeban [ip]");

	new bankey = DB_INVALID_KEY;
    for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_rangebantable]); i <= j; i++)
	{
	    new range[18];
	    DB::GetStringEntry(gGlobal[s_rangebantable], i, "ip", range);
	    if(ipmatch(ip, range))
	    {
    		bankey = i;
    		break;
        }
    }
	if(bankey == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is not banned.");

	new str[100];
	new DIALOG[676];
	new string[144];
	//search result base !:D!
	format(string, sizeof(string), ""SAMP_BLUE"Search range ban results for ip %s:\n\n", ip);
	strcat(DIALOG, string);
	//user name
 	DB::GetStringEntry(gGlobal[s_rangebantable], bankey, "ip", str);
 	format(string, sizeof(string), ""WHITE"I.P. Banned: "MARONE"%s\n", str);
 	strcat(DIALOG, string);
	//admin name
	DB::GetStringEntry(gGlobal[s_rangebantable], bankey, "banby", str);
	format(string, sizeof(string), ""WHITE"Banned by: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//reason
	DB::GetStringEntry(gGlobal[s_rangebantable], bankey, "reason", str);
	format(string, sizeof(string), ""WHITE"Reason: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//ban date
	DB::GetStringEntry(gGlobal[s_rangebantable], bankey, "banon", str);
	format(string, sizeof(string), ""WHITE"Ban date: "MARONE"%s\n", str);
	strcat(DIALOG, string);
	//expire time
	new val = DB::GetIntEntry(gGlobal[s_rangebantable], bankey, "expire");
	new expire[68];
	if(val == 0) expire = "PERMANENT";
	else expire = ConvertTime(val);
	format(string, sizeof(string), ""WHITE"Expiration timeleft: "MARONE"%s\n", expire);
	strcat(DIALOG, string);

	//show BAN stats in dialog
	ShowPlayerDialog(	playerid,
						DIALOG_COMMON,
						DIALOG_STYLE_MSGBOX,
						"Search-Rangeban results",
						DIALOG,
						"Close",
						"");
	return 1;
}

CMD:unban(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 2);

	new name[MAX_PLAYER_NAME];
	if(sscanf(params,"s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unban [name]");

	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "name", name);
	if(bankey == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified username is not banned.");

	DB::DeleteRow(gGlobal[s_bantable], bankey);

	new string[144];
	format(string, sizeof(string), "* You have unbanned user %s successfully.", name);
	SendClientMessage(playerid, COLOR_GREEN, string);
	return 1;
}

//------------------------------------------------

//Admin level 3+
CMD:get(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /get [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot get yourself.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	if(GetPlayerState(target) == PLAYER_STATE_DRIVER)
	{
		SetVehiclePos(GetPlayerVehicleID(target), pos[0] + 3.0, pos[1], pos[2]);
		LinkVehicleToInterior(GetPlayerVehicleID(target), GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(target), GetPlayerVirtualWorld(playerid));
	}
	else
	{
		SetPlayerPos(target, pos[0] + 2.5, pos[1], pos[2]);
	}
	SetPlayerInterior(target, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(target, GetPlayerVirtualWorld(playerid));
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has teleported you to his/her position.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have teleport %s[%i] to your position.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:write(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new text[144], color;
	if(sscanf(params, "s[144]I(1)", text, color))
	{
		SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /write [text] [*color]");
		SendClientMessage(playerid, COLOR_THISTLE, "COLOR: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
		return 1;
	}

	if(color > 9 || color > 0)
	{
		SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid color id, must be b/w 0-9.");
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
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /force [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerHealth(target, 0.0);
	ForceClassSelection(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has forced you to class selection.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have forced %s[%i] to class selection.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:healall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i) SetPlayerHealth(i, 100.0) && PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

    new string[144];
	format(string, sizeof(string), "* admin %s[%i] has healed all players.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:armourall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i) SetPlayerArmour(i, 100.0) && PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has armoured all players.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:fightstyle(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, style, sylename[15];

    if(sscanf(params, "ui", target, style))
	{
		SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fightstyle [player] [style]");
		SendClientMessage(playerid, COLOR_THISTLE, "STYLES: [0]Normal, [1]Boxing, [2]Kungfu, [3]Kneehead, [4]Grabkick, [5]Elbow");
		return 1;
	}

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(style > 5 || style < 0) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Inavlid fighting style, must be b/w 0-5.");

	switch(style)
	{
	    case 0:
	    {
	        SetPlayerFightingStyle(target, 4);
	        sylename = "Normal";
	    }
	    case 1:
	    {
	        SetPlayerFightingStyle(target, 5);
	        sylename = "Boxing";
	    }
	    case 2:
	    {
	        SetPlayerFightingStyle(target, 6);
	        sylename = "Kung Fu";
	    }
	    case 3:
	    {
	        SetPlayerFightingStyle(target, 7);
	        sylename = "Kneehead";
	    }
	    case 4:
	    {
	        SetPlayerFightingStyle(target, 15);
	        sylename = "Grabkick";
	    }
	    case 5:
	    {
	        SetPlayerFightingStyle(target, 16);
	        sylename = "Elbow";
	    }
	}
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your fighting style to [%i]%s.", ReturnPlayerName(playerid), playerid, sylename, style);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s fighting style to [%i]%s.", ReturnPlayerName(target), target, sylename, style);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:sethealth(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, Float:amount;
	if(sscanf(params, "uf", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /sethealth [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerHealth(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your health to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s health to %.2f.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setarmour(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, Float:amount;
	if(sscanf(params, "uf", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setarmour [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerArmour(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your armour to %0.2f.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s armour to %.2f.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:agod(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	if(GetPVarType(playerid, "GAdmin_God") == PLAYER_VARTYPE_NONE)
	{
	    SetPlayerHealth(playerid, 9999999.0);
	    GameTextForPlayer(playerid, "~g~GODMODE ~w~~h~ON", 5000, 3);

	    SetPVarInt(playerid, "GAdmin_God", 1);
	}
	else
	{
	    SetPlayerHealth(playerid, 100.0);
	    GameTextForPlayer(playerid, "~g~GODMODE ~w~~h~OFF", 5000, 3);

	    DeletePVar(playerid, "GAdmin_God");
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:resetcash(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

    new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "ERROR: /resetcash [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	ResetPlayerMoney(target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has reset your cash to 0$.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have reset %s[%i]'s cash to 0$.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:getall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			SetPlayerPos(i, pos[0] + ((playerid / 4) + 1), pos[1] + (playerid / 4), pos[2]);
			SetPlayerInterior(i, GetPlayerInterior(playerid));
			SetPlayerVirtualWorld(i, GetPlayerVirtualWorld(playerid));
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has teleported all players to hist location.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:freeze(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, reason[35];
	if(sscanf(params, "uS(No reason specified)[35]", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /freeze [playerid] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	TogglePlayerControllable(target, false);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has freezed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have freezed %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unfreeze [playerid]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	TogglePlayerControllable(target, true);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has unfreezed you.", ReturnPlayerName(playerid), playerid);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have unfreezed %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:giveweapon(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, weapon[32], ammo;
	if(sscanf(params, "us[32]I(250)", target, weapon, ammo)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveweapon [player] [weapon] [*ammo]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new weaponid;
	if(! isnumeric(weapon)) weaponid = GetWeaponIDFromName(weapon);
	else 					weaponid = strval(weapon);

	if(! IsValidWeapon(weaponid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weapon id.");

	GetWeaponName(weaponid, weapon, sizeof(weapon));
	GivePlayerWeapon(target, weaponid, ammo);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has given you a %s[id: %i] with %i ammo.", ReturnPlayerName(playerid), playerid, weapon, weaponid, ammo);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have given %s[%i] a %s[id: %i] with %i ammo.", ReturnPlayerName(target), target, weapon, weaponid, ammo);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:slap(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

    new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /slap [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	new Float:pos[3];
	GetPlayerPos(target, pos[0], pos[1], pos[2]);
	SetPlayerPos(target, pos[0], pos[1], pos[2] + 5.0);

    PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
    PlayerPlaySound(target, 1190, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have slapped %s[%i].", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setcolor(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setcolor [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPVarInt(playerid, "PlayerColor", target);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	ShowPlayerDialog(playerid, DIALOG_PLAYER_COLORS, DIALOG_STYLE_LIST, "Select a color", ""BLACK"Black\n"WHITE"White\n"RED"Red\n"ORANGE"Orange\n"YELLOW"Yellow\n"GREEN"Green\n"RED"Blue\n"VIOLET"Purple\n"BROWN"Brown\n"PINK"Pink", "Select", "Cancel");
	return 1;
}

CMD:setcash(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setcash [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	ResetPlayerMoney(target);
	GivePlayerMoney(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your money to $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s money to $%i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setscore(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setscore [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	SetPlayerScore(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your score to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s score to %i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:givecash(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givecash [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	GivePlayerMoney(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has given you money $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have given %s[%i]'s money $%i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:givescore(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /givescore [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	SetPlayerScore(target, amount);
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has given you score to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have given %s[%i]'s score %i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:respawncar(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new vehicleid;
	if(sscanf(params, "i", vehicleid)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /respawncar [vehicleid]");

	if(! IsValidVehicle(vehicleid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified vehicle is not created.");

	SetVehicleToRespawn(vehicleid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have respawned vehicle id %i.", vehicleid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:destroycar(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new vehicleid;
	if(sscanf(params, "i", vehicleid)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroycar [vehicleid]");

	if(! IsValidVehicle(vehicleid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified vehicle is not created.");

	SetVehicleToRespawn(vehicleid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have destroyed vehicle id %i.", vehicleid);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setkills(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setkills [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	gUser[target][u_kills] = amount;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your kills to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s kills to %i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "kills", amount);
	return 1;
}

CMD:setdeaths(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new target, amount;
	if(sscanf(params, "ui", target, amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setdeaths [player] [amount]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	gUser[target][u_deaths] = amount;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "admin %s[%i] has set your deaths to %i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessage(target, COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "You have set %s[%i]'s deaths to %i.", ReturnPlayerName(target), target, amount);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "deaths", amount);
	return 1;
}

CMD:banip(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new ip[18], reason[35], days;
	if(sscanf(params,"s[18]s[35]I(0)", ip, reason, days)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /banip [ip] [reason] [*days]");

    if(! strcmp(ip, ReturnPlayerIP(playerid))) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't ban yourself.");

	if(days < 0) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid days, must be greater than 0 for temp ban, or 0 for permanent ban.");

	if(strlen(reason) < 3 || strlen(reason) > 35) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid reason length, must be b/w 0-35 characters.");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "ip", ip);
	if(key != DB_INVALID_KEY)
	{
	    if(DB::GetIntEntry(gGlobal[s_usertable], key, "admin") > GetPlayerGAdminLevel(playerid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin's ip.");
	}

	key = DB::RetrieveKey(gGlobal[s_bantable], "ip", ip);
	if(key != DB_INVALID_KEY)
	{
		return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is already banned.");
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());

	new name[MAX_PLAYER_NAME] = "Unknown";
	LOOP_PLAYERS(i)
	{
	    if(! strcmp(ip, ReturnPlayerIP(i)))
	    {
	        if(GetPlayerGAdminLevel(i) > GetPlayerGAdminLevel(playerid)) return  SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

			GetPlayerName(i, name, MAX_PLAYER_NAME);
	        break;
	    }
	}

    DB::CreateRow(gGlobal[s_bantable], "ip", ip);
	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "ip", ip);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "name", name);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banby", ReturnPlayerName(playerid));
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "banon", bandate);
	DB::SetStringEntry(gGlobal[s_bantable], bankey, "reason", reason);
	DB::SetIntEntry(gGlobal[s_bantable], bankey, "expire", time);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* You have banned the ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
		SendClientMessageToAll(COLOR_RED, string);
	}
	else
	{
	    new string[144];
	    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime(time));
		SendClientMessageToAll(COLOR_RED, string);
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	LOOP_PLAYERS(i)
	{
	    if(! strcmp(ReturnPlayerIP(i), ip))
	    {
	        if(days == 0)
			{
			    new string[144];
			    format(string, sizeof(string), "* admin %s[%i] has banned your ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
				SendClientMessage(i, COLOR_RED, string);
			}
			else
			{
			    new string[144];
			    format(string, sizeof(string), "* admin %s[%i] has temp banned your ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
				SendClientMessage(i, COLOR_RED, string);
			    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime(time));
				SendClientMessage(i, COLOR_RED, string);
			}
 			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			DelayKick(i);
		}
	}
	return 1;
}

CMD:unbanip(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new ip[18];
	if(sscanf(params,"s[18]", ip)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unbanip [ip]");

	new bankey = DB::RetrieveKey(gGlobal[s_bantable], "ip", ip);
	if(bankey == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is not banned.");

	DB::DeleteRow(gGlobal[s_bantable], bankey);

	new string[144];
	format(string, sizeof(string), "* You have unbanned ip %s successfully.", ip);
	SendClientMessage(playerid, COLOR_GREEN, string);
	return 1;
}

CMD:freezeall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
				TogglePlayerControllable(i, false);
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
            }
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has freezed all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:unfreezeall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
				TogglePlayerControllable(i, true);
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
            }
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has unfreezed all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

//------------------------------------------------

//Admin level 4+
CMD:banrange(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new ip[18], reason[35], days;
	if(sscanf(params,"s[18]s[35]I(10)", ip, reason, days)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /banip [ip] [reason] [*days]");

    if(! strcmp(ip, ReturnPlayerIP(playerid)) || ipmatch(ReturnPlayerIP(playerid), ip)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't range ban yourself.");

	if(days < 0) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid days, must be greater than 0 for temp range ban, or 0 for permanent range ban.");

	if(strlen(reason) < 3 || strlen(reason) > 35) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid reason length, must be b/w 0-35 characters.");

    for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_usertable]); i <= j; i++)
	{
	    new uIP[18];
  		DB::GetStringEntry(gGlobal[s_usertable], i, "ip", uIP);
	    if(ipmatch(uIP, ip))
	    {
	        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin's ip.");
	    }
	}

	for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_rangebantable]); i <= j; i++)
	{
	    new uIP[18];
  		DB::GetStringEntry(gGlobal[s_rangebantable], i, "ip", uIP);
	    if(ipmatch(uIP, ip))
	    {
			return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is already range banned.");
	    }
	}

	new bandate[18], date[3], time;
	getdate(date[0], date[1], date[2]);
	format(bandate, sizeof(bandate), "%02i/%02i/%i", date[2], date[1], date[0]);

	if(days == 0) time = 0;
	else time = ((days * 24 * 60 * 60) + gettime());

	LOOP_PLAYERS(i)
	{
	    if(ipmatch(ReturnPlayerIP(i), ip))
	    {
            if(GetPlayerGAdminLevel(i) > GetPlayerGAdminLevel(playerid))
			{
			    SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin's ip.");
			}
	        break;
	    }
	}

    DB::CreateRow(gGlobal[s_rangebantable], "ip", ip);
	new bankey = DB::RetrieveKey(gGlobal[s_rangebantable], "ip", ip);
	DB::SetStringEntry(gGlobal[s_rangebantable], bankey, "banby", ReturnPlayerName(playerid));
	DB::SetStringEntry(gGlobal[s_rangebantable], bankey, "banon", bandate);
	DB::SetStringEntry(gGlobal[s_rangebantable], bankey, "reason", reason);
	DB::SetIntEntry(gGlobal[s_rangebantable], bankey, "expire", time);

	if(days == 0)
	{
	    new string[144];
	    format(string, sizeof(string), "* You have range banned the ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
		SendClientMessage(playerid, COLOR_RED, string);
	}
	else
	{
	    new string[144];
	    format(string, sizeof(string), "* You have temp range banned the ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
		SendClientMessage(playerid, COLOR_RED, string);
	    format(string, sizeof(string), "* Range banned for %i days [Unban on %s]", days, ConvertTime( time - gettime() ));
		SendClientMessage(playerid, COLOR_RED, string);
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	LOOP_PLAYERS(i)
	{
	    if(ipmatch(ReturnPlayerIP(i), ip))
	    {
	        if(days == 0)
			{
			    new string[144];
			    format(string, sizeof(string), "* admin %s[%i] has range banned your ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
				SendClientMessage(i, COLOR_RED, string);
			}
			else
			{
			    new string[144];
			    format(string, sizeof(string), "* admin %s[%i] has temp range banned your ip %s [Reason: %s].", ReturnPlayerName(playerid), playerid, ip, reason);
				SendClientMessage(i, COLOR_RED, string);
			    format(string, sizeof(string), "* Banned for %i days [Unban on %s]", days, ConvertTime( time - gettime() ));
				SendClientMessage(i, COLOR_RED, string);
			}
 			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			DelayKick(i);
		}
	}
	return 1;
}

CMD:unbanrange(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	new ip[18];
	if(sscanf(params,"s[18]", ip)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /unbanrange [ip]");

    for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_rangebantable]); i <= j; i++)
	{
	    new range[18];
	    DB::GetStringEntry(gGlobal[s_rangebantable], i, "ip", range);
	    if(ipmatch(ip, range))
	    {
            DB::DeleteRow(gGlobal[s_rangebantable], i);

            new string[144];
	        format(string, sizeof(string), "* You have unbanned ip range %s successfully.", ip);
	        SendClientMessage(playerid, COLOR_GREEN, string);

            break;
        }
    }

	SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified ip is not range banned.");
	return 1;
}

CMD:fakedeath(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new target, killerid, weaponid;
	if(sscanf(params, "uui", target, killerid, weaponid)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fakedeath [player] [killer] [weapon]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(! IsPlayerConnected(killerid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified killer is not conected.");

	if(! IsValidWeapon(weaponid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weapon id.");

	new weaponname[35];
	GetWeaponName(weaponid, weaponname, sizeof(weaponname));
	SendDeathMessage(killerid, target, weaponid);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "Fake death sent [Player: %s | Killer: %s | Weapon: %s]", ReturnPlayerName(target), ReturnPlayerName(killerid), weaponname);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:cmdmuted(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new DIALOG[98+670], string[128], bool:count = false;

	LOOP_PLAYERS(i)
	{
	    if(GetPVarType(i, "GAdmin_CMDMuted") != PLAYER_VARTYPE_NONE)
	    {
	    	format(string, sizeof(string), "%i. %s - Unmute in %i secs..", i, ReturnPlayerName(i), gUser[i][u_cmutetime]);
	        strcat(DIALOG, string);
			count = true;
	    }
	}
	if(! count) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: No commands muted players in the server.");
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_LIST, "Commands muted players", DIALOG, "Close", "");
	}
	return 1;
}

CMD:cmdmute(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new target, time, reason[128];
	if(sscanf(params, "uI(60)S(No reason specified)[128]", target, time, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /cmdmute [player] [*seconds] [*reason]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(time > 5*60 || time < 10) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The cmdmute time must be b/w 10 - 360(5 minutes) seconds.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot cmdmute yourself.");

	if(GetPVarType(target, "GAdmin_CMDMuted") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is already in cmdmuted.");

	SetPVarInt(playerid, "GAdmin_CMDMuted", 1);

	gUser[target][u_cmutetime] = time;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been cmdmuted by admin %s[%i] for %i seconds [Reason: %s]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid, time, reason);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	format(string, sizeof(string), "~b~~h~~h~~h~Commands muted for %i secs", time);
	GameTextForPlayer(target, string, 5000, 3);
	return 1;
}

CMD:uncmdmute(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /uncmdmute [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(GetPVarType(playerid, "GAdmin_CMDMuted") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is not cmdmuted.");

	DeletePVar(playerid, "GAdmin_CMDMuted");

	gUser[target][u_cmutetime] = 0;
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* %s[%i] has been uncmdmuted by admin %s[%i]", ReturnPlayerName(target), target, ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	GameTextForPlayer(target, "~b~~h~~h~~h~Uncmdmuted", 5000, 3);
	return 1;
}

CMD:muteall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
				SetPVarInt(i, "GAdmin_Muted", 1);

				gUser[i][u_mutetime] = 5*60;
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
            }
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has muted all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:unmuteall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 3);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
				DeletePVar(i, "GAdmin_Muted");

				gUser[i][u_mutetime] = 0;
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
            }
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has unmuted all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:killall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
				SetPlayerHealth(i, 0.0);
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			}
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    new string[144];
	format(string, sizeof(string), "* admin %s[%i] has killed all players.", ReturnPlayerName(playerid), playerid);
    SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:ejectall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new Float:pos[3];
	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(IsPlayerInAnyVehicle(i))
	    	{
	    	    if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
	            {
	            	GetPlayerPos(i, pos[0], pos[1], pos[2]);
	    	    	SetPlayerPos(i, pos[0] + 2.5, pos[1], pos[2]);
					PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
				}
			}
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has ejected all players from their vehicles.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:disarmall(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	LOOP_PLAYERS(i)
	{
        if(i != playerid)
        {
            if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            {
            	ResetPlayerWeapons(i);
				PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
            }
		}
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has disarmed all players.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:giveallscore(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new amount;
	if(sscanf(params, "i", amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallscore [amount]");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerScore(i, GetPlayerScore(i) + amount);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has given all players %i score.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:giveallcash(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new amount;
	if(sscanf(params, "i", amount)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallcash [amount]");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		GivePlayerMoney(i, amount);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has given all players $%i.", ReturnPlayerName(playerid), playerid, amount);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setalltime(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setalltime [id]");

	if(id < 0 || id > 24) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid time hour, must be b/w 0-24.");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerTime(i, id, 0);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has set all players time to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setallweather(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setallweather [id]");

	if(id < 0 || id > 45) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weather id, must be b/w 0-45.");

	LOOP_PLAYERS(i)
	{
        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
		SetPlayerWeather(i, id);
		PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	}

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has set all players weather to %i.", ReturnPlayerName(playerid), playerid, id);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:respawncars(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	for(new cars; cars < MAX_VEHICLES; cars++)
	{
	    LOOP_PLAYERS(i)
	    {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	        if(GetPlayerVehicleID(i) == cars)
	        {
	            if(GetPlayerState(i) == PLAYER_STATE_DRIVER)
	            {
					if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(i))
            		{
            			SetVehicleToRespawn(cars);
					}
				}
				else SetVehicleToRespawn(cars);
			}
			else SetVehicleToRespawn(cars);
        }
	}

	GameTextForAll("~b~~h~~h~~h~Vehicles respawned", 5000, 3);
	new string[144];
	format(string, sizeof(string), "You respawned all vehicles.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:cleardwindow(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	for(new i = 0; i < 20; i++) SendDeathMessage(6000, 5005, 255);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has cleared all players death window.", ReturnPlayerName(playerid), playerid);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:giveallweapon(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new weapon[32], ammo;
	if(sscanf(params, "s[32]I(250)", weapon, ammo)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /giveallweapon [weapon] [ammo]");

	new weaponid;
	if(! isnumeric(weapon)) weaponid = GetWeaponIDFromName(weapon);
	else				 	weaponid = strval(weapon);

	if(! IsValidWeapon(weaponid)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid weapon id.");

	GetWeaponName(weaponid, weapon, sizeof(weapon));
   	LOOP_PLAYERS(i) GivePlayerWeapon(i, weaponid, ammo) && PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* admin %s[%i] has given all players %s[id: %i] with %i ammo.", ReturnPlayerName(playerid), playerid, weapon, weaponid, ammo);
	SendClientMessageToAll(COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:object(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new model;
	if(sscanf(params, "i", model)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /object [model]");

	if(0 > model > 20000) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified model is invalid.");

	new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);

	new Float:angle;
	GetPlayerFacingAngle(playerid, angle);

	new object = CreateObject(model, pos[0] + (20.0 * floatsin(-angle, degrees)), pos[1] + (20.0 * floatcos(-angle, degrees)), pos[2] + 5, 0, 0, angle);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have created a new object [model: %i, id: %i, position: %f, %f, %f, 0.0, 0.0, %f].", model, object, pos[0], pos[1], pos[2], angle);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:destroyobject(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new object;
	if(sscanf(params, "i", object)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroyobject [object]");

	if(! IsValidObject(object)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified object is invalid.");

	DestroyObject(object);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have destroyed the object id %i.", object);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:editobject(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 4);

	new object;
	if(sscanf(params, "i", object)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /editobject [object]");

	if(! IsValidObject(object)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified object is invalid.");

	EditObject(playerid, object);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You are now editing the object id %i.", object);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, "Hold SPACE and use MOUSE to move camera.");
	return 1;
}

//------------------------------------------------

//Admin level 5+
CMD:gmx(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new time;
	if(sscanf(params, "I(5)", time)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /gmx [*interval]");

	if(time < 0 || time > 5*60) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid restart time, must be b/w 0-360 seconds.");

	if(time > 0)
	{
	    SetTimer("RestartTimer", 1000 * time, false);
		new string[144];
		format(string, sizeof(string), ">> Admin %s[%i] has set the gamemode to reboot. The reboot will occur in %i seconds...", ReturnPlayerName(playerid), playerid, time);
		SendClientMessageToAll(COLOR_LIME, string);
	}
	else
	{
		new string[144];
		format(string, sizeof(string), ">> Admin %s[%i] has set the gamemode to reboot. rebooting...", ReturnPlayerName(playerid), playerid);
		SendClientMessageToAll(COLOR_LIME, string);
	    SendRconCommand("gmx");
	}
	return 1;
}

forward RestartTimer();
public RestartTimer() return SendRconCommand("gmx");

CMD:removeuser(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new name[MAX_PLAYER_NAME];
    if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /removeuser [username]");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", name);
	if(key == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specififed account doesn't exist.");
	else
	{
	    if(DB::GetIntEntry(gGlobal[s_usertable], key, "admin") > GetPlayerGAdminLevel(playerid))
	    {
         	return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specififed account is a higher level admin.");
	    }
	}

	if(! strcmp(ReturnPlayerName(playerid), name, false)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot delete your own account.");

	LOOP_PLAYERS(i)
	{
	    if(! strcmp(name, ReturnPlayerName(i), true))
	    {
	        new string[144];
	        format(string, sizeof(string), "* admin %s[%i] has deleted your account.", ReturnPlayerName(playerid), playerid);
         	SendClientMessage(i, COLOR_RED, string);
			DelayKick(i);
			break;
	    }
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	DB::DeleteRow(gGlobal[s_usertable], key);
 	new string[144];
	format(string, sizeof(string), "You have deleted %s's account.", name);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    return 1;
}

CMD:fakecmd(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new target, cmdtext[45];
	if(sscanf(params, "us[45]", target, cmdtext)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fakecmd [player] [command]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(strfind(cmdtext, "/", false) == -1) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Add '/' before putting the command name to avoid UNKNOWN COMMAND error.");

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	CallRemoteFunction("OnPlayerCommandText", "is", target, cmdtext);

 	new string[144];
	format(string, sizeof(string), "Fake command sent [Player: %s[%i] | Command: %s]", ReturnPlayerName(target), target, cmdtext);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:fakechat(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new target, text[129];
	if(sscanf(params, "us[129]", target, text)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /fakechat [player] [text]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    new string[144];
	format(string, sizeof(string), "%i %s: %s", target, ReturnPlayerName(target), text);
    SendClientMessageToAll(GetPlayerColor(target), string);

	format(string, sizeof(string), "Fake chat sent [Player: %s[%i] | Text: %s]", ReturnPlayerName(target), target, text);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:setlevel(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new target, level;
	if(sscanf(params, "ui", target, level)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setlevel [player] [level]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(level < 0 || level > MAX_ADMIN_LEVELS) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid level, mus be b/w 0-"#MAX_ADMIN_LEVELS".");

	if(level == GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is already of that level.");

	new string[144];
    if(GetPlayerGAdminLevel(playerid) < level)
    {
        GameTextForPlayer(target, "~g~~h~~h~~h~Promoted", 5000, 1);
		format(string, sizeof(string), "You have been promoted to admin level %i by %s[%i], Congratulation.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(target, COLOR_DODGER_BLUE, string);
		format(string, sizeof(string), "You have promoted %s[%i] to admin level %i.", ReturnPlayerName(target), target, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }
    else if(GetPlayerGAdminLevel(playerid) > level)
    {
        GameTextForPlayer(target, "~r~~h~~h~~h~Demoted", 5000, 1);
		format(string, sizeof(string), "You have been demoted to admin level %i by %s[%i], Sorry.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(target, COLOR_DODGER_BLUE, string);
		format(string, sizeof(string), "You have demoted %s[%i] to admin level %i.", ReturnPlayerName(target), target, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "admin", level);

    gUser[target][u_admin] = level;
	return 1;
}

CMD:setvip(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new target, level;
	if(sscanf(params, "ui", target, level)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /setvip [player] [level]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(GetPlayerGAdminLevel(playerid) < GetPlayerGAdminLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot use this command on higher level admin.");

	if(level < 0 || level > MAX_VIP_LEVELS) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid level, mus be b/w 0-"#MAX_VIP_LEVELS".");

	if(level == GetPlayerGVipLevel(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Player is already of that level.");

	new string[144];
    if(GetPlayerGVipLevel(playerid) < level)
    {
        GameTextForPlayer(target, "~g~~h~~h~~h~Premium", 5000, 1);
		format(string, sizeof(string), "You have been given VIP level %i by %s[%i], Congratulation.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(target, COLOR_DODGER_BLUE, string);
		format(string, sizeof(string), "You have given %s[%i] VIP level of %i.", ReturnPlayerName(target), target, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }
    else if(GetPlayerGAdminLevel(playerid) > level)
    {
        GameTextForPlayer(target, "~r~~h~~h~~h~Demoted", 5000, 1);
		format(string, sizeof(string), "Your VIP level havs been taken and reseted to level %i by %s[%i], Sorry.", level, ReturnPlayerName(playerid), playerid);
		SendClientMessage(target, COLOR_DODGER_BLUE, string);
		format(string, sizeof(string), "You have taken %s[%i]'s VIP level and reseted it to level %i.", ReturnPlayerName(target), target, level);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }
	PlayerPlaySound(target, 1057, 0.0, 0.0, 0.0);
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "vip", level);

    gUser[target][u_vip] = level;
	return 1;
}

CMD:lock(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	if(gGlobal[s_locked]) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The server is already locked, try /unlock to unlock the server.");

    gGlobal[s_locktd][0] = TextDrawCreate(1.000000, 1.000000, "box");
	TextDrawBackgroundColor(gGlobal[s_locktd][0], 255);
	TextDrawFont(gGlobal[s_locktd][0], 1);
	TextDrawLetterSize(gGlobal[s_locktd][0], 0.000000, 51.000000);
	TextDrawColor(gGlobal[s_locktd][0], -1);
	TextDrawSetOutline(gGlobal[s_locktd][0], 0);
	TextDrawSetProportional(gGlobal[s_locktd][0], 1);
	TextDrawSetShadow(gGlobal[s_locktd][0], 1);
	TextDrawUseBox(gGlobal[s_locktd][0], 1);
	TextDrawBoxColor(gGlobal[s_locktd][0], 255);
	TextDrawTextSize(gGlobal[s_locktd][0], 650.000000, 0.000000);
	TextDrawSetSelectable(gGlobal[s_locktd][0], 0);

	gGlobal[s_locktd][1] = TextDrawCreate(330.000000, 170.000000, "~y~Server Locked");
	TextDrawAlignment(gGlobal[s_locktd][1], 2);
	TextDrawBackgroundColor(gGlobal[s_locktd][1], 255);
	TextDrawFont(gGlobal[s_locktd][1], 1);
	TextDrawLetterSize(gGlobal[s_locktd][1], 1.000000, 5.800000);
	TextDrawColor(gGlobal[s_locktd][1], -1);
	TextDrawSetOutline(gGlobal[s_locktd][1], 0);
	TextDrawSetProportional(gGlobal[s_locktd][1], 1);
	TextDrawSetShadow(gGlobal[s_locktd][1], 1);
	TextDrawSetSelectable(gGlobal[s_locktd][1], 0);

	gGlobal[s_locktd][2] = TextDrawCreate(330.000000, 219.000000, "An high level admin has locked the server temporarily! Contact server website if you have any queries!");
	TextDrawAlignment(gGlobal[s_locktd][2], 2);
	TextDrawBackgroundColor(gGlobal[s_locktd][2], 255);
	TextDrawFont(gGlobal[s_locktd][2], 1);
	TextDrawLetterSize(gGlobal[s_locktd][2], 0.270000, 1.500000);
	TextDrawColor(gGlobal[s_locktd][2], -1);
	TextDrawSetOutline(gGlobal[s_locktd][2], 0);
	TextDrawSetProportional(gGlobal[s_locktd][2], 1);
	TextDrawSetShadow(gGlobal[s_locktd][2], 1);
	TextDrawSetSelectable(gGlobal[s_locktd][2], 0);

	LOOP_PLAYERS(i)
	{
	    if(! IsPlayerGAdmin(playerid))
	    {
	    	TogglePlayerSpectating(i, true);
			for(new x; x < 3; x++)
			{
				TextDrawShowForPlayer(i, gGlobal[s_locktd][x]);
			}
		}
	}

	gGlobal[s_locked] = true;

    SendClientMessage(playerid, COLOR_RED, " ");
    SendClientMessage(playerid, COLOR_RED, "- Server Locked -");
	new string[144];
	format(string, sizeof(string), "admin %s[%i] has locked the server.", ReturnPlayerName(playerid), playerid);
 	SendClientMessage(playerid, COLOR_RED, string);
	return 1;
}

CMD:unlock(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	if(! gGlobal[s_locked]) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The server is already unlocked, try /lock to lock the server.");

    for(new i; i < 3; i++)
	{
 		TextDrawHideForAll(gGlobal[s_locktd][i]);
   		TextDrawDestroy(gGlobal[s_locktd][i]);
	}
	LOOP_PLAYERS(i)
	{
	    if(! IsPlayerGAdmin(playerid))
	    {
	 		TogglePlayerSpectating(i, false);

			ForceClassSelection(i);
			SetPlayerHealth(i, 0.0);
		}
	}

	gGlobal[s_locked] = false;

    SendClientMessage(playerid, COLOR_RED, " ");
    SendClientMessage(playerid, COLOR_RED, "- Server Unlocked -");
	new string[144];
	format(string, sizeof(string), "admin %s[%i] has unlocked the server.", ReturnPlayerName(playerid), playerid);
 	SendClientMessage(playerid, COLOR_RED, string);
	return 1;
}

CMD:forbidname(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new name[MAX_PLAYER_NAME];
    if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /forbidname [username]");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", name);
	if(key != DB_INVALID_KEY)
	{
	    if(DB::GetIntEntry(gGlobal[s_usertable], key, "admin") > GetPlayerGAdminLevel(playerid))
	    {
         	return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specififed username is a higher level registered admin.");
	    }
	}

    if(gGlobal[s_fnamescount] >= (MAX_FORBIDDEN_ITEMS - 1))
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't anymore forbidden names(limit can't be exceeded), kindly increase ''MAX_FORBIDDEN_ITEMS'' to a higher value.");
    }

    if(DB::RetrieveKey(gGlobal[s_fnamestable], "name", name) != DB::INVALID_KEY)
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The name already exists in the forbiden names list.");
    }

    format(gForbidden_Names[gGlobal[s_fnamescount]], MAX_PLAYER_NAME, name);
	DB::CreateRow(gGlobal[s_fnamestable], "name", name);

	gGlobal[s_fnamescount] += 1;

	new string[144];
	LOOP_PLAYERS(i)
	{
	    if( ! isnull(name) &&
			! strcmp(ReturnPlayerName(i), name, true))
		{
			SendClientMessage(i, COLOR_RED, "* You have a forbidden/banned username, please change it in order to play.");

			format(string, sizeof(string), "* %s[%i] has been automatically kicked [Reason: Forbidden name]", ReturnPlayerName(i), i);
			SendClientMessageToAll(COLOR_RED, string);

            DelayKick(i);
            break;
	    }
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	format(string, sizeof(string), "* You have added ''%s'' to forbidden names list.", name);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    return 1;
}

CMD:forbidtag(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new tag[MAX_PLAYER_NAME];
    if(sscanf(params, "s[24]", tag)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /forbidtag [part of name/tag]");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", tag);
	if(key != DB_INVALID_KEY)
	{
	    if(DB::GetIntEntry(gGlobal[s_usertable], key, "admin") > GetPlayerGAdminLevel(playerid))
	    {
         	return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specififed part of name/tag is used by a higher level registered admin.");
	    }
	}

    if(gGlobal[s_ftagscount] >= (MAX_FORBIDDEN_ITEMS - 1))
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't anymore forbidden tags(limit can't be exceeded), kindly increase ''MAX_FORBIDDEN_ITEMS'' to a higher value.");
    }

    if(DB::RetrieveKey(gGlobal[s_ftagstable], "tag", tag) != DB::INVALID_KEY)
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The tag already exists in the forbiden tags list.");
    }

    format(gForbidden_Names[gGlobal[s_ftagscount]], MAX_PLAYER_NAME, tag);
	DB::CreateRow(gGlobal[s_ftagstable], "tag", tag);

	gGlobal[s_ftagscount] += 1;

	new string[144];
	LOOP_PLAYERS(i)
	{
	    if( ! isnull(tag) &&
			strfind(ReturnPlayerName(i), tag, true) != -1)
		{
			format(string, sizeof(string), "* You have a forbidden/banned part of name [tag: %s], please change it in order to play.", tag);
			SendClientMessage(i, COLOR_RED, string);

			format(string, sizeof(string), "* %s[%i] has been automatically kicked [Reason: Forbidden part of name/tag]", ReturnPlayerName(i), i);
			SendClientMessageToAll(COLOR_RED, string);

            DelayKick(i);
            break;
	    }
	}

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	format(string, sizeof(string), "* You have added ''%s'' to forbidden names list.", tag);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    return 1;
}

CMD:forbidword(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new word[144];
    if(sscanf(params, "s[144]", word)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /forbidword [word]");

    if(gGlobal[s_fwordscount] >= (MAX_FORBIDDEN_ITEMS - 1))
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You can't anymore forbidden words(limit can't be exceeded), kindly increase ''MAX_FORBIDDEN_ITEMS'' to a higher value.");
    }

    if(DB::RetrieveKey(gGlobal[s_fwordstable], "word", word) != DB::INVALID_KEY)
    {
        return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The word already exists in the forbiden words list.");
    }

    format(gForbidden_Words[gGlobal[s_fwordscount]], 150, word);
	DB::CreateRow(gGlobal[s_fwordstable], "word", word);

	gGlobal[s_fwordscount] += 1;

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "* You have added ''%s'' to forbidden words list.", word);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    return 1;
}

CMD:reloaddb(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

    gGlobal[s_fwordscount] = DB::CountRows(gGlobal[s_fwordstable]);
	for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
	{
		gForbidden_Words[i][0] = EOS;

		if(i < gGlobal[s_fwordscount])
		{
	    	DB::GetStringEntry(gGlobal[s_fwordstable], i + 1, "word", gForbidden_Words[i]);
	    }
	}

	gGlobal[s_fnamescount] = DB::CountRows(gGlobal[s_fnamestable]);
	for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
	{
	    gForbidden_Names[i][0] = EOS;

	    if(i < gGlobal[s_fnamescount])
	    {
	    	DB::GetStringEntry(gGlobal[s_fnamestable], i + 1, "name", gForbidden_Names[i]);
	    }
	}

	gGlobal[s_ftagscount] = DB::CountRows(gGlobal[s_ftagstable]);
	for(new i = 0; i < MAX_FORBIDDEN_ITEMS; i++)
	{
	    gForbidden_Tags[i][0] = EOS;

	    if(i < gGlobal[s_ftagscount])
	    {
	    	DB::GetStringEntry(gGlobal[s_ftagstable], i + 1, "tag", gForbidden_Tags[i]);
	    }
	}

	SendClientMessage(playerid, COLOR_DODGER_BLUE, "** Server database has been reloaded successfully. (Forbidden names, words, tags are now reloaded)");
	return 1;
}

CMD:pickup(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new model;
	if(sscanf(params, "i", model)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /pickup [model]");

	if(0 > model > 20000) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified model is invalid.");

	new Float:pos[3];
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);

	new Float:angle;
	GetPlayerFacingAngle(playerid, angle);

	new pickup = CreatePickup(model, 1, pos[0] + (20.0 * floatsin(-angle, degrees)), pos[1] + (20.0 * floatcos(-angle, degrees)), pos[2] + 5);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have created a new object [model: %i, id: %i, position: %f, %f, %f].", model, pickup, pos[0], pos[1], pos[2]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:destroypickup(playerid, params[])
{
	//check if the player is a admin
	LevelCheck(playerid, 5);

	new pickup;
	if(sscanf(params, "i", pickup)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /destroypickup [pickup]");

	DestroyPickup(pickup);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "You have destroyed the pickup id %i.", pickup);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

//------------------------------------------------

//Player commands
CMD:admins(playerid, params[])
{
	new string[128], bool:count = false, rank[35], status[15];

	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	LOOP_PLAYERS(i)
	{
	    if(IsPlayerGAdmin(i) || IsPlayerAdmin(i))
	    {
	        if(! count) SendClientMessage(playerid, COLOR_ORANGE_RED, "- Online Administrators -");

	        if(GetPVarType(playerid, "GAdmin_Onduty") != PLAYER_VARTYPE_NONE) status = "On Duty";
	        else status = "Playing";

			if(IsPlayerAdmin(i)) rank = "RCON Admin";
			else
			{
			    switch(GetPlayerGAdminLevel(i))
			    {
			        case 1: rank = "Trial Admin";
			        case 2: rank = "Junior Admin";
			        case 3: rank = "Senior Admin";
			        case 4: rank = "Lead Admin";
			        case 5: rank = "Master Admin";
					default: rank = "Server Manager";
			    }
   			}

	    	format(string, sizeof(string), "%s [%i] | Rank: %s | Level %i | Status: %s", ReturnPlayerName(i), i, rank, GetPlayerGAdminLevel(i), status);
	        SendClientMessage(playerid, COLOR_ORANGE_RED, string);
			count = true;
	    }
	}
	if(! count) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: No admin on-duty currently.");
	return 1;
}

CMD:vips(playerid, params[])
{
	new string[128], bool:count = false, rank[28];

	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	LOOP_PLAYERS(i)
	{
	    if(IsPlayerGVip(i))
	    {
	        if(! count) SendClientMessage(playerid, COLOR_ORANGE_RED, "- Online Donaters -");

	        switch(GetPlayerGVipLevel(i))
	        {
				case 1: rank = "Bronse VIP";
				case 2: rank = "Silver VIP";
				case 3: rank = "Gold VIP";
	        }

			format(string, sizeof(string), "%s [%i] | Rank: %s | Level %i", ReturnPlayerName(i), i, rank, GetPlayerGVipLevel(i));
	        SendClientMessage(playerid, COLOR_ORANGE_RED, string);
			count = true;
 	    }
	}
	if(! count) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: No vip online currently.");
	return 1;
}

CMD:report(playerid, params[])
{
	new target, reason[98];
	if(sscanf(params, "us[98]", target, reason)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /report [player] [reason]");

	if(strlen(reason) < 1) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Report reason length must be greater than 1.");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot report yourself.");

	new hour, minute, second;
	gettime(hour, minute, second);

    gUser[playerid][u_lastreported] = target;
	gUser[playerid][u_lastreportedtime] = 80;

	new string[145];
	format(string, sizeof(string), "%02d:%02d | %s[%i] reported against %s[%i] | Reason: %s", hour, minute, ReturnPlayerName(playerid), playerid, ReturnPlayerName(target), target, reason);
	SendClientMessageForAdmins(COLOR_YELLOW, string);

	for(new i = (sizeof(gReportlog) - 1); i > 0; i--)
	{
	    format(gReportlog[(i - 1)], 145, gReportlog[i]);
	}
    format(gReportlog[(sizeof(gReportlog) - 1)], 145, ""GREEN"%02d:%02d\n"WHITE"%s[%i] reported against %s[%i]\n"WHITE"Reason: %s", hour, minute, ReturnPlayerName(playerid), playerid, ReturnPlayerName(target), target, reason);

	#if defined REPORT_TEXTDRAW
		format(string, sizeof(string), "~w~~h~[%02i:%02i] ~b~~h~~h~~h~%s(%i) ~w~~h~reported against ~b~~h~~h~~h~%s(%i) ~w~~h~Reason: %s", hour, minute, ReturnPlayerName(playerid), playerid, ReturnPlayerName(target), target, reason);
		TextDrawSetString(gGlobal[s_reporttd], string);

		LOOP_PLAYERS(i)
		{
		    if(IsPlayerGAdmin(i))
		    {
				TextDrawShowForPlayer(i, gGlobal[s_reporttd]);
		    }
		}
	#endif

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	format(string, sizeof(string), "Your report against %s[%i] has been sent to online admins.", ReturnPlayerName(target), target);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:register(playerid, params[])
{
	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
    if(key != DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The username is already registered. Try /login instead.");

	if(GetPVarType(playerid, "GAdmin_Loggedin") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are already registered and logged in.");

	SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: Welcome user, type in the password to sign up.");

	new string[156];
	format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"doesn't exist in database.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
	ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register account", string, "Register", "Skip");
	return 1;
}

CMD:login(playerid, params[])
{
	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
    if(key == DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The username is not registered. Try /register instead.");

	if(GetPVarType(playerid, "GAdmin_Loggedin") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are already registered and logged in.");

	SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: Welcome user, type in the password to sign in and load your stats.");

	new string[156];
	format(string, sizeof(string), ""SAMP_BLUE"Your account "RED"%s "SAMP_BLUE"is registered.\n\nType your complicated password above to continue", ReturnPlayerName(playerid));
	ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login account", string, "Login", "Skip");
	return 1;
}

CMD:changename(playerid, params[])
{
	if(GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are not registered or logged in.");

	new name[MAX_PLAYER_NAME];
    if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /changename [newname]");

	if(strlen(name) < 4 || strlen(name) > MAX_PLAYER_NAME) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid user name length, must be b/w 4-24.");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", name);
    if(key != DB_INVALID_KEY) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: That username is already registered, try another one!");

    key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetStringEntry(gGlobal[s_usertable], key, "username", name);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	new string[144];
	format(string, sizeof(string), "ACCOUNT: You have changed your username from %s to %s.", ReturnPlayerName(playerid), name);
	SendClientMessage(playerid, COLOR_GREEN, string);
	SetPlayerName(playerid, name);

	GameTextForPlayer(playerid, "~g~NAME CHANGED!", 5000, 3);
	return 1;
}

CMD:changepass(playerid, params[])
{
	if(GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are not registered or logged in.");

	new pass[MAX_PLAYER_NAME];
    if(sscanf(params, "s[24]", pass)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /changepass [newpass]");

	if(strlen(pass) < 4 || strlen(pass) > MAX_PLAYER_NAME) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: Invalid password length, must be b/w 4-24.");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	new hash[65];
	DB::Hash(hash, sizeof(hash), pass);
	DB::SetStringEntry(gGlobal[s_usertable], key, "password", hash);

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have changed your password.");

	GameTextForPlayer(playerid, "~g~PASSWORD CHANGED!", 5000, 3);
	return 1;
}

CMD:autologin(playerid, params[])
{
	if(GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are not registered or logged in.");

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
    if(DB::GetIntEntry(gGlobal[s_usertable], key, "autologin"))
	{
		DB::SetIntEntry(gGlobal[s_usertable], key, "autologin", 0);
		SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have DISABLED auto login for this account.");
	}
	else
	{
		DB::SetIntEntry(gGlobal[s_usertable], key, "autologin", 1);
		SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: You have ENABLED auto login for this account.");
	}
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:savestats(playerid, params[])
{
	if(GetPVarType(playerid, "GAdmin_Loggedin") == PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You are not registered or logged in.");

    GetPlayerConnectedTime(playerid, gUser[playerid][u_hours], gUser[playerid][u_minutes], gUser[playerid][u_seconds]);

	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "kills", gUser[playerid][u_kills]);
	DB::SetIntEntry(gGlobal[s_usertable], key, "deaths", gUser[playerid][u_deaths]);
	DB::SetIntEntry(gGlobal[s_usertable], key, "score", GetPlayerScore(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "money", GetPlayerMoney(playerid));
	DB::SetIntEntry(gGlobal[s_usertable], key, "hours", gUser[playerid][u_hours]);
	DB::SetIntEntry(gGlobal[s_usertable], key, "minutes", gUser[playerid][u_minutes]);
	DB::SetIntEntry(gGlobal[s_usertable], key, "seconds", gUser[playerid][u_seconds]);

	SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: Your stats have been saved. (Your stats automatically saves after disconnect though)");
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	return 1;
}

CMD:stats(playerid, params[])
{
	new target;
	if(sscanf(params, "u", target))
	{
  		target = playerid;
		SendClientMessage(playerid, COLOR_KHAKI, "TIP: You can also view other players stats by /stats [player]");
	}

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not conected.");

    GetPlayerConnectedTime(target, gUser[target][u_hours], gUser[target][u_minutes], gUser[target][u_seconds]);
	//Stats stuff !:D!
	new DIALOG[676];
	new string[156];
	format(string, sizeof(string), ""WHITE"You are now viewing "LIME"%s's [id: %i]"WHITE", statics:\n\n", ReturnPlayerName(target), target);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Kills: "TOMATO"%i\n", gUser[target][u_kills]);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Deaths: "TOMATO"%i\n", gUser[target][u_deaths]);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Session Kills: "TOMATO"%i\n", gUser[target][u_sessionkills]);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Session Deaths: "TOMATO"%i\n", gUser[target][u_sessiondeaths]);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Killing Spree: "TOMATO"%i\n", gUser[target][u_spree]);
	strcat(DIALOG, string);
	//calculate Kill/Deaths ratio
	new Float:ratio;
	if(gUser[target][u_deaths] <= 0) ratio = 0.0;
	else ratio = Float:(gUser[target][u_kills] / gUser[target][u_deaths]);
	format(string, sizeof(string), ""SAMP_BLUE"K/D Ratio: "TOMATO"%0.2f\n", ratio);
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Score: "TOMATO"%i\n", GetPlayerScore(target));
	strcat(DIALOG, string);
	format(string, sizeof(string), ""SAMP_BLUE"Money: "TOMATO"$%i\n", GetPlayerMoney(target));
	strcat(DIALOG, string);
	//player game play time
	format(string, sizeof(string), ""SAMP_BLUE"Played time: "TOMATO"%02i hours %02i minutes %02i seconds\n", gUser[target][u_hours], gUser[target][u_minutes], gUser[target][u_seconds]);
	strcat(DIALOG, string);
	//print if registered or not
	new yes[4] = "YES", no[3] = "NO";
	format(string, sizeof(string), ""SAMP_BLUE"Registered: "TOMATO"%s\n", ((GetPVarType(playerid, "GAdmin_Loggedin") != PLAYER_VARTYPE_NONE) ? yes : no));
	strcat(DIALOG, string);
	//get user id
	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(target));
	new DATE[18];
	//joined date
	DB::GetStringEntry(gGlobal[s_usertable], key, "joindate", DATE);
	format(string, sizeof(string), ""SAMP_BLUE"Join date: "CORAL"%s\n", DATE);
	strcat(DIALOG, string);
	//last visit to server date
	DB::GetStringEntry(gGlobal[s_usertable], key, "laston", DATE);
	format(string, sizeof(string), ""SAMP_BLUE"Last visit: "TOMATO"%s\n", DATE);
	strcat(DIALOG, string);
	//current team id
	format(string, sizeof(string), ""SAMP_BLUE"Team: "TOMATO"%i\n\n", GetPlayerTeam(target));
	strcat(DIALOG, string);
	//shit!
	strcat(DIALOG, ""WHITE"If you think your stats are wrong or not saved according to last log out, Please place an appeal in forums.\n");
	strcat(DIALOG, "Make sure you have a screen of your last stats and this.");

	//show stats in dialog
	ShowPlayerDialog(playerid, DIALOG_COMMON, DIALOG_STYLE_MSGBOX, "Player statics", DIALOG, "Close", "");
	return 1;
}

CMD:spree(playerid, params[])
{
	new target;
	if(sscanf(params, "u", target)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /spree [player]");

	if(! IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not connected.");

	new string[144];
	format(string, sizeof(string), "* %s[%i] have a killing spree of %i kills.", ReturnPlayerName(target), target, gUser[playerid][u_spree]);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
	return 1;
}

CMD:nopm(playerid, params[])
{
	#pragma unused params
	if(GetPVarType(playerid, "GAdmin_Nopm") == PLAYER_VARTYPE_NONE)
	{
	    SetPVarInt(playerid, "GAdmin_Nopm", 1);

	    SendClientMessage(playerid, COLOR_RED, "PM: You are no longer accepting private messages.");
	}
	else
	{
	    DeletePVar(playerid, "GAdmin_Nopm");

	    SendClientMessage(playerid, COLOR_GREEN, "PM: You are now accepting private messages.");
	}
	return 1;
}
CMD:dnd(playerid, params[]) return cmd_nopm(playerid, params);

CMD:pm(playerid, params[])
{
	new target, text[128], string[145];
	if(sscanf(params, "us[128]", target, text)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /pm (player) (message)");

	if(!IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not connected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot PM yourself.");

	format(string, sizeof(string), "ERROR: %s[%d] is not accepting private messages at the moment.", ReturnPlayerName(target), target);
	if(GetPVarType(playerid, "GAdmin_Nopm") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, string);

	format(string, sizeof(string), "PM to %s[%i]: %s", ReturnPlayerName(target), target, text);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "PM from %s[%i]: %s", ReturnPlayerName(playerid), playerid, text);
	SendClientMessage(target, COLOR_YELLOW, string);
	gUser[playerid][u_lastuser] = target;
	return 1;
}

CMD:reply(playerid, params[])
{
	new target, text[128], string[145];
	if(sscanf(params, "s[128]", target, text)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /reply (message)");

	target = gUser[playerid][u_lastuser];
	if(!IsPlayerConnected(target)) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: The specified player is not connected.");

	if(target == playerid) return SendClientMessage(playerid, COLOR_FIREBRICK, "ERROR: You cannot PM yourself.");

	format(string, sizeof(string), "ERROR: %s[%d] is not accepting private messages at the moment.", ReturnPlayerName(target), target);
	if(GetPVarType(playerid, "GAdmin_Nopm") != PLAYER_VARTYPE_NONE) return SendClientMessage(playerid, COLOR_FIREBRICK, string);

	format(string, sizeof(string), "PM to %s[%i]: %s", ReturnPlayerName(target), target, text);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "PM from %s[%i]: %s", ReturnPlayerName(playerid), playerid, text);
	SendClientMessage(target, COLOR_YELLOW, string);
	return 1;
}

CMD:time(playerid, params[])
{
	new time[3];
	gettime(time[0], time[1], time[2]);

	new string[144];
	format(string, sizeof(string), "~y~~h~%i:%i", time[0], time[1]);
	GameTextForPlayer(playerid, string, 3000, 1);
	return 1;
}

CMD:id(playerid, params[])
{
	new name[MAX_PLAYER_NAME];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /id [playername]");

	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	new string[144];
	format(string, sizeof(string), "- Search result for %s", name);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	new count = 0;
	LOOP_PLAYERS(i)
	{
	    if(strfind(ReturnPlayerName(i), name, true) != -1)
	    {
			count += 1;

			format(string, sizeof(string), "%i. %s[%i]", count, ReturnPlayerName(i), i);
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
		}
	}

	if(! count) return SendClientMessage(playerid, COLOR_DODGER_BLUE, "- No player found with that part of name!");
	return 1;
}
CMD:getid(playerid, params[]) return cmd_id(playerid, params);

CMD:richlist(playerid, params[])
{
    #define TOPLINE 10

    new Player_ID[TOPLINE], Top_Info[TOPLINE];

    LOOP_PLAYERS(i)
    {
        HighestTopList(i, GetPlayerMoney(i), Player_ID, Top_Info, TOPLINE);
    }

    SendClientMessage(playerid, COLOR_DODGER_BLUE, " ");
    SendClientMessage(playerid, COLOR_DODGER_BLUE, "- Top-Richlist Results:");

    new string[144];
    for(new i; i < TOPLINE; i++)
    {
        if(Top_Info[i] <= 0) continue;
        format(string, sizeof string, "%s[%i] - $%i", ReturnPlayerName(Player_ID[i]), Player_ID[i], Top_Info[i]);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }

    #undef TOPLINE
    return 1;
}

CMD:scorelist(playerid, params[])
{
    #define TOPLINE 10

    new Player_ID[TOPLINE], Top_Info[TOPLINE];

    LOOP_PLAYERS(i)
    {
        HighestTopList(i, GetPlayerScore(i), Player_ID, Top_Info, TOPLINE);
    }

    SendClientMessage(playerid, COLOR_DODGER_BLUE, " ");
    SendClientMessage(playerid, COLOR_DODGER_BLUE, "- Top-Score Results:");

    new string[144];
    for(new i; i < TOPLINE; i++)
    {
        if(Top_Info[i] <= 0) continue;
        format(string, sizeof string, "%s[%i] - %i Score", ReturnPlayerName(Player_ID[i]), Player_ID[i], Top_Info[i]);
        SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
    }

    #undef TOPLINE
    return 1;
}

CMD:search(playerid, params[])
{
	new name[MAX_PLAYER_NAME];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, COLOR_THISTLE, "USAGE: /search [playername]");

	SendClientMessage(playerid, COLOR_ORANGE_RED, " ");
	new string[150], arg[56];
	format(string, sizeof(string), "- Search result for %s:", name);
	SendClientMessage(playerid, COLOR_DODGER_BLUE, string);

	new count = 0;
	for(new i = 1, j = DB::GetHighestRegisteredKey(gGlobal[s_usertable]); i <= j; i++)
	{
	    new uName[MAX_PLAYER_NAME];
  		DB::GetStringEntry(gGlobal[s_usertable], i, "username", uName);

		if(strfind(uName, name, true) != -1)
	    {
			count += 1;

	    	format(string, sizeof(string), "%i", count);
	    	strcat(string, ". ");
	    	strcat(string, uName);
	    	strcat(string, " [Join date: ");
	        DB::GetStringEntry(gGlobal[s_usertable], i, "joindate", arg);
	    	strcat(string, arg);
	    	strcat(string, " | Last active: ");
	        DB::GetStringEntry(gGlobal[s_usertable], i, "laston", arg);
	    	strcat(string, arg);
	    	strcat(string, "]");
			SendClientMessage(playerid, COLOR_DODGER_BLUE, string);
		}
	}

	if(! count) return SendClientMessage(playerid, COLOR_DODGER_BLUE, "- No account found with that part of name!");
	return 1;
}
CMD:searchuser(playerid, params[]) return cmd_search(playerid, params);

//------------------------------------------------

stock ConvertTime(time)
{
	new string[68];
	new values[6];
    TimestampToDate(time, values[0], values[1], values[2], values[3], values[4], values[5], 0, 0);
    format(string, sizeof(string), "%i.%i.%i (%i hrs %i mins %i secs)", values[0], values[1], values[2], values[3], values[4], values[5]);
    return string;
}

//------------------------------------------------

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	LOOP_PLAYERS(i)
	{
		if(IsPlayerSpectating(i))
		{
		    if(gUser[i][u_specid] == playerid)
		    {
		        UpdatePlayerSpectating(playerid, 0, false);
			}
		}
	}
	return 1;
}

//------------------------------------------------

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(IsPlayerGAdmin(playerid))
 	{
		if(newkeys == KEY_LOOK_BEHIND && IsPlayerSpectating(playerid))
	    {
	   		cmd_specoff(playerid, "");
	    }
	    if(newkeys == KEY_FIRE && IsPlayerSpectating(playerid))
	    {
	        UpdatePlayerSpectating(playerid, 0, false);
	    }
	    if(newkeys == KEY_ACTION && IsPlayerSpectating(playerid))
	    {
			UpdatePlayerSpectating(playerid, 1, false);
	    }
	}
    return 1;
}

//------------------------------------------------

public OnPlayerClickPlayer(playerid, clickedplayerid)
{
    GetPlayerConnectedTime(clickedplayerid, gUser[clickedplayerid][u_hours], gUser[clickedplayerid][u_minutes], gUser[clickedplayerid][u_seconds]);
	//Stats stuff !:D!
	new string[156];
	format(string, sizeof(string), "You are now viewing %s's [id: %i] statics!", ReturnPlayerName(clickedplayerid), clickedplayerid);
	SendClientMessage(playerid, COLOR_GREEN, string);

	new MESSAGE[676];
	format(string, sizeof(string), "Kills: %i | ", gUser[clickedplayerid][u_kills]);
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Deaths: %i | ", gUser[clickedplayerid][u_deaths]);
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Session Kills: %i | ", gUser[clickedplayerid][u_sessionkills]);
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Session Deaths: %i | ", gUser[clickedplayerid][u_sessiondeaths]);
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Killing Spree: %i | ", gUser[clickedplayerid][u_spree]);
	strcat(MESSAGE, string);
	//calculate Kill/Deaths ratio
	new Float:ratio;
	if(gUser[clickedplayerid][u_deaths] <= 0) ratio = 0.0;
	else ratio = Float:(gUser[clickedplayerid][u_kills] / gUser[clickedplayerid][u_deaths]);
	format(string, sizeof(string), "K/D Ratio: %0.2f | ", ratio);
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Score: %i | ", GetPlayerScore(clickedplayerid));
	strcat(MESSAGE, string);
	format(string, sizeof(string), "Money: $%i", GetPlayerMoney(clickedplayerid));
	strcat(MESSAGE, string);
	SendClientMessage(playerid, COLOR_GREEN, MESSAGE);
	//player game play time
	format(string, sizeof(string), "Played time: %02i hours %02i minutes %02i seconds | ", gUser[clickedplayerid][u_hours], gUser[clickedplayerid][u_minutes], gUser[clickedplayerid][u_seconds]);
	strcat(MESSAGE, string);
	//print if registered or not
	new yes[4] = "YES", no[3] = "NO";
	format(string, sizeof(string), "Registered: %s | ", ((GetPVarType(playerid, "GAdmin_Loggedin") != PLAYER_VARTYPE_NONE) ? yes : no));
	strcat(MESSAGE, string);
	//get user id
	new key = DB::RetrieveKey(gGlobal[s_usertable], "username", ReturnPlayerName(clickedplayerid));
	new DATE[18];
	//joined date
	DB::GetStringEntry(gGlobal[s_usertable], key, "joindate", DATE);
	format(string, sizeof(string), "Join date: %s | ", DATE);
	strcat(MESSAGE, string);
	//last visit to server date
	DB::GetStringEntry(gGlobal[s_usertable], key, "laston", DATE);
	format(string, sizeof(string), "Last visit: %s | ", DATE);
	strcat(MESSAGE, string);
	//current team id
	format(string, sizeof(string), "Team: %i", GetPlayerTeam(clickedplayerid));
	strcat(MESSAGE, string);
	SendClientMessage(playerid, COLOR_GREEN, MESSAGE);
	return 1;
}

//------------------------------------------------
