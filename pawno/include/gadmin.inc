/*
    								  (__)
		______  ___      _           /. .\
	   / ____/ / _ \    | |          \_-_/
	  / /     | | | |   | | __ _  __   _  _  __             ____
	 | |  ___ | |_| |  _| || |/ \/  \ | || |/_ \   __    __|___ \
     | | |__ || | | | / _ ||  /\__/\ || ||  / \ |  \ \  / /  / /
     \ \___| || | | || |_||| |     | || || |  | |   \ \/ / / /_
	  \______||_| |_|\____||_|     |_||_||_|  |_|    \__/ \____|

	Include:
	* GAdmin System -	gadmin.inc
	* Version       -   v2.4.0 (2016/01/16)

 	Author: (creator)
	* Gammix

 	Contributors:
	* SAMP team

	(c) Copyright 2016
  	* This file is provided as is (no warranties).
*/

/*
native bool:IsPlayerGAdmin(playerid);
native bool:IsPlayerPremium(playerid);
native GetPlayerAdminLevel(playerid);
native SetPlayerAdminLevel(playerid, level);
native SetPlayerPremium(playerid, bool:set);
*/

#include <a_samp>
#include <yoursql>

new SQL:g_db;

#if defined FILTERSCRIPT
	public OnFilterScriptInit()
	{
	    g_db = yoursql_open("server.db");

	    #if defined GAdmin_OnFilterScriptInit
			return GAdmin_OnFilterScriptInit();
		#else
			return 1;
		#endif
	}
	#if defined _ALS_OnFilterScriptInit
		#undef OnFilterScriptInit
	#else
		#define _ALS_OnFilterScriptInit
	#endif
	#define OnFilterScriptInit GAdmin_OnFilterScriptInit
	#if defined GAdmin_OnFilterScriptInit
		forward GAdmin_OnFilterScriptInit();
	#endif

	public OnFilterScriptExit()
	{
	    yoursql_close(g_db);

	    #if defined GAdmin_OnFilterScriptExit
			return GAdmin_OnFilterScriptExit();
		#else
			return 1;
		#endif
	}
	#if defined _ALS_OnFilterScriptExit
		#undef OnFilterScriptExit
	#else
		#define _ALS_OnFilterScriptExit
	#endif
	#define OnFilterScriptExit GAdmin_OnFilterScriptExit
	#if defined GAdmin_OnFilterScriptExit
		forward GAdmin_OnFilterScriptExit();
	#endif
#else
	public OnGameModeInit()
	{
	    g_db = yoursql_open("server.db");

	    #if defined GAdmin_OnGameModeInit
			return GAdmin_OnGameModeInit();
		#else
			return 1;
		#endif
	}
	#if defined _ALS_OnGameModeInit
		#undef OnGameModeInit
	#else
		#define _ALS_OnGameModeInit
	#endif
	#define OnGameModeInit GAdmin_OnGameModeInit
	#if defined GAdmin_OnGameModeInit
		forward GAdmin_OnGameModeInit();
	#endif

	public OnGameModeExit()
	{
	    yoursql_close(g_db);

	    #if defined GAdmin_OnGameModeExit
			return GAdmin_OnGameModeExit();
		#else
			return 1;
		#endif
	}
	#if defined _ALS_OnGameModeExit
		#undef OnGameModeExit
	#else
		#define _ALS_OnGameModeExit
	#endif
	#define OnGameModeExit GAdmin_OnGameModeExit
	#if defined GAdmin_OnGameModeExit
		forward GAdmin_OnGameModeExit();
	#endif
#endif

#if ! defined ReturnPlayerName
	ReturnPlayerName(playerid)
	{
		new name[MAX_PLAYER_NAME];
		GetPlayerName(playerid, name, MAX_PLAYER_NAME);
		return name;
	}
#endif

stock bool:IsPlayerGAdmin(playerid)
{
	return bool:(yoursql_get_field_int(g_db, "users/admin", yoursql_get_row(g_db, "users", "name = %s", ReturnPlayerName(playerid))));
}

stock bool:IsPlayerPremium(playerid)
{
	return bool:(yoursql_get_field_int(g_db, "users/vip", yoursql_get_row(g_db, "users", "name = %s", ReturnPlayerName(playerid))));
}

stock GetPlayerAdminLevel(playerid)
{
	return yoursql_get_field_int(g_db, "users/admin", yoursql_get_row(g_db, "users", "name = %s", ReturnPlayerName(playerid)));
}

stock SetPlayerAdminLevel(playerid, level)
{
	return yoursql_set_field_int(g_db, "users/admin", yoursql_get_row(g_db, "users", "name = %s", ReturnPlayerName(playerid)), level);
}

stock SetPlayerPremium(playerid, bool:set)
{
	return yoursql_set_field_int(g_db, "users/vip", yoursql_get_row(g_db, "users", "name = %s", ReturnPlayerName(playerid)), _:set);
}
