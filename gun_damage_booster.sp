// Gun Damage Booster
#include <sourcemod>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define GDB_VERSION "6.5"

public Plugin myinfo =
{
	name = "Gun Damage Booster",
	author = "Psyk0tik (Crasher_3637)",
	description = "Increases each gun's damage.",
	version = GDB_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=301641"
};

bool g_bLateLoad;
ConVar g_cvGDBConVars[22];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Gun Damage Booster only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvGDBConVars[0] = CreateConVar("gdb_ak47", "40.0", "Damage boost for the AK47 Assault Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[1] = CreateConVar("gdb_awp", "50.0", "Damage boost for the AWP Sniper Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[2] = CreateConVar("gdb_chrome", "20.0", "Damage boost for the Chrome Shotgun.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[3] = CreateConVar("gdb_disabledgamemodes", "", "Disable the Gun Damage Booster in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Disabled in these game modes.)");
	g_cvGDBConVars[4] = CreateConVar("gdb_enable", "1", "Enable the Gun Damage Booster?\n(0: OFF)\n(1: ON)", _, true, 0.0, true, 1.0);
	g_cvGDBConVars[5] = CreateConVar("gdb_enabledgamemodes", "", "Enable the Gun Damage Booster in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Enabled in these game modes.)");
	g_cvGDBConVars[6] = FindConVar("mp_gamemode");
	g_cvGDBConVars[7] = CreateConVar("gdb_hunting", "45.0", "Damage boost for the Hunting Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[8] = CreateConVar("gdb_m16", "40.0", "Damage boost for the M16 Assault Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[9] = CreateConVar("gdb_m60", "45.0", "Damage boost for the M60 Assault Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[10] = CreateConVar("gdb_magnum", "25.0", "Damage boost for the Magnum Pistol.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[11] = CreateConVar("gdb_military", "50.0", "Damage boost for the Military Sniper Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[12] = CreateConVar("gdb_mp5", "30.0", "Damage boost for the MP5 SMG.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[13] = CreateConVar("gdb_pistol", "20.0", "Damage boost for the M1911/P220 Pistol.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[14] = CreateConVar("gdb_pump", "20.0", "Damage boost for the Pump Shotgunn.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[15] = CreateConVar("gdb_scar", "40.0", "Damage boost for the SCAR-L Desert Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[16] = CreateConVar("gdb_scout", "50.0", "Damage boost for the Scout Sniper Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[17] = CreateConVar("gdb_sg552", "40.0", "Damage boost for the SG552 Assault Rifle.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[18] = CreateConVar("gdb_silenced", "35.0", "Damage boost for the Silenced SMG.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[19] = CreateConVar("gdb_smg", "30.0", "Damage boost for the SMG.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[20] = CreateConVar("gdb_spas", "25.0", "Damage boost for the SPAS Shotgun.", _, true, 0.0, true, 99999.0);
	g_cvGDBConVars[21] = CreateConVar("gdb_tactical", "25.0", "Damage boost for the Tactical Shotgun.", _, true, 0.0, true, 99999.0);
	CreateConVar("gdb_version", GDB_VERSION, "Gun Damage Booster Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "gun_damage_booster");
}

public void OnMapStart()
{
	if (g_bLateLoad)
	{
		vLateLoad(true);
		g_bLateLoad = false;
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void vLateLoad(bool late)
{
	if (late)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SDKHook(iPlayer, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetClientTeam(victim) != 3) return Plugin_Continue;
	if (g_cvGDBConVars[4].BoolValue && bIsPluginEnabled() && damage > 0.0)
	{
		if (bIsSurvivor(attacker) && bIsValidClient(victim) && damagetype & DMG_BULLET)
		{
			char sWeapon[128];
			GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
			if (strcmp(sWeapon, "weapon_rifle_ak47", false) == 0)
			{
				damage = damage + g_cvGDBConVars[0].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_sniper_awp", false) == 0)
			{
				damage = damage + g_cvGDBConVars[1].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_shotgun_chrome", false) == 0)
			{
				damage = damage + g_cvGDBConVars[2].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_hunting_rifle", false) == 0)
			{
				damage = damage + g_cvGDBConVars[7].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_rifle", false) == 0)
			{
				damage = damage + g_cvGDBConVars[8].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_rifle_m60", false) == 0)
			{
				damage = damage + g_cvGDBConVars[9].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_pistol_magnum", false) == 0)
			{
				damage = damage + g_cvGDBConVars[10].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_sniper_military", false) == 0)
			{
				damage = damage + g_cvGDBConVars[11].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_smg_mp5", false) == 0)
			{
				damage = damage + g_cvGDBConVars[12].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_pistol", false) == 0)
			{
				damage = damage + g_cvGDBConVars[13].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_pumpshotgun", false) == 0)
			{
				damage = damage + g_cvGDBConVars[14].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_rifle_desert", false) == 0)
			{
				damage = damage + g_cvGDBConVars[15].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_sniper_scout", false) == 0)
			{
				damage = damage + g_cvGDBConVars[16].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_rifle_sg552", false) == 0)
			{
				damage = damage + g_cvGDBConVars[17].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_smg_silenced", false) == 0)
			{
				damage = damage + g_cvGDBConVars[18].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_smg", false) == 0)
			{
				damage = damage + g_cvGDBConVars[19].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_shotgun_spas", false) == 0)
			{
				damage = damage + g_cvGDBConVars[20].FloatValue;
			}
			else if (strcmp(sWeapon, "weapon_autoshotgun", false) == 0)
			{
				damage = damage + g_cvGDBConVars[21].FloatValue;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock bool bIsSurvivor(int client)
{
	return bIsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool bIsPluginEnabled()
{
	char sGameMode[32];
	char sConVarModes[32];
	g_cvGDBConVars[6].GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_cvGDBConVars[5].GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	g_cvGDBConVars[3].GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	return true;
}

stock bool bIsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}