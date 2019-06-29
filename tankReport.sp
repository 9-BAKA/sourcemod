#define ZOMBIECLASS_TANK		8

#define PLUGIN_VERSION			"1.1c"

#define CVAR_SHOW				FCVAR_NOTIFY
#define CVAR_HIDE				~FCVAR_NOTIFY

#include <sourcemod>

#include "left4downtown.inc"

new Handle:displayType;
new Handle:Logging;

// - Attacker, Victim
new damageReport[MAXPLAYERS + 1][MAXPLAYERS + 1];

// stored when a tank player spawns, in case a plugin is altering the
// health value, so percentages can be properly calculated
new startHealth[MAXPLAYERS + 1];
new class[MAXPLAYERS + 1];

public Plugin:myinfo = {
	name = "Tank Damage Reporter",
	author = "",
	description = "Displays Damage Information on Tank Death.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=181151"
}

public OnPluginStart()
{
	CreateConVar("tdr_version", PLUGIN_VERSION, "plugin version.", CVAR_SHOW);

	displayType					= CreateConVar("tdr_display_type","1","0 - Displays tank damage info to players privately. 1 - Displays all information publicly.", CVAR_SHOW);
	Logging						= CreateConVar("tdr_logging","0","whether or not to enable logging.", CVAR_SHOW);
	
	AutoExecConfig(true, "tdr_config");

	//Database_OnPluginStart();
	// Will add support for printing to the web

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

public OnClientPostAdminCheck(client)
{
	if (client != 0 && !IsFakeClient(client))
	{
		EC_OnClientPostAdminCheck(client);
	}
}

public Action:Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientIndexOutOfRange(victim)) return;
	if (!IsFakeClient(victim)) return;
	if (GetClientTeam(victim) != 3)
	{
		class[victim] = 0;
		return;
	}
	DisplayTankInformation(victim);
}

public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 3)
	{
		class[client] = 0;
		return;
	}

	class[client] = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (class[client] == ZOMBIECLASS_TANK)
	{
		clearUserData(client);
		startHealth[client] = GetClientHealth(client);
	}
}

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim	 = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage	 = GetEventInt(event, "dmg_health");

	if (IsClientIndexOutOfRange(victim)) return;
	if (IsClientIndexOutOfRange(attacker) || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return;
	if (!IsClientInGame(victim) || GetClientTeam(victim) != 3) return;

	class[victim] = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if (class[victim] != ZOMBIECLASS_TANK) return;

	if (!IsTankIncapacitated(victim)) damageReport[attacker][victim] += damage;
	if (damageReport[attacker][victim] > startHealth[victim]) damageReport[attacker][victim] = startHealth[victim];
}

public Action:Event_PlayerIncapacitated(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim					= GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientIndexOutOfRange(victim)) return;
	if (IsFakeClient(victim)) return;
	if (GetClientTeam(victim) != 3)
	{
		class[victim] = 0;
		return;
	}
	DisplayTankInformation(victim);
}

EC_OnClientPostAdminCheck(client)
{
	// Make sure this client id damage variable is cleared
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		damageReport[client][i] = 0;
		damageReport[i][client] = 0;
	}
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Cleared Data for user %N", client);
}

clearUserData(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientIndexOutOfRange(i) || !IsClientInGame(i)) continue;
		damageReport[i][client] = 0;
	}
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Cleared All User Data for %N", client);
}

stock bool:IsClientIndexOutOfRange(client)
{
	if (client <= 0 || client > MaxClients) return true;
	else return false;
}

stock bool:IsTankIncapacitated(client)
{
	if (IsIncapacitated(client) || GetClientHealth(client) < 1) return true;
	return false;
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

DisplayTankInformation(victim)
{
	if (GetConVarInt(Logging) == 1) LogToFile("tdr_log", "[TDR] Displaying Damage Report for Dead Tank: %N", victim);
	new String:pct[16];
	Format(pct, sizeof(pct), "%");

	if (GetConVarInt(displayType) == 1)
	{
		// Public Display
		PrintToChatAll("\x05[\x04TDR\x05] \x04%N \x01已被击杀.", victim);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
			new Float:damage = (damageReport[i][victim] * 1.0) / (startHealth[victim] * 1.0) * 100.0;
			if (damage > 10.0) PrintToChatAll("\x05%N \x04[\x04%d 伤害 - %3.2f%s\x04]", i, damageReport[i][victim], damage, pct);
			else if (damageReport[i][victim] > 0)
				PrintToChatAll("\x01摸鱼 \x05%N \x04[\x01%d 伤害 - %3.2f%s\x04]", i, damageReport[i][victim], damage, pct);
			else PrintToChatAll("\x01摸爆 \x05%N \x04[\x01%d 伤害 - %3.2f%s\x04]", i, damageReport[i][victim], damage, pct);
		}
	}
	else
	{
		// Display privately
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 2) continue;
			if (damageReport[i][victim] < 1) continue;
			new Float:damage = (damageReport[i][victim] * 1.0) / (startHealth[victim] * 1.0) * 100.0;
			PrintToChat(i, "\x05[\x04TDR\x05] \x04%N \x01已被击杀.", victim);
			if (damage > 10.0) PrintToChat(i, "\x03%N \x05[\x04%d 伤害 - %3.2f%s\x05]", i, damageReport[i][victim], damage, pct);
			else PrintToChat(i, "\x04摸鱼 \x03%N \x05[\x04%d 伤害 - %3.2f%s\x05]", i, damageReport[i][victim], damage, pct);
		}
	}
}