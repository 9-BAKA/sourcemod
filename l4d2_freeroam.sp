#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.1"

public Plugin:myinfo =
{
	name = "L4D2 Take a break Free Roam",
	author = "EHG",
	description = "L4D2 Take a break Free Roam",
	version = PLUGIN_VERSION,
	url = ""
};


public OnPluginStart()
{
	CreateConVar("l4d2_takeabreak_freeroam_version", PLUGIN_VERSION, "L4D2 Enable Spectator Free Roam Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	RegConsoleCmd("sm_freeroam", Command_Freeroam);
	RegConsoleCmd("sm_fr", Command_Freeroam);
}

public Action:Command_Freeroam(client, args)
{
	if (GetClientTeam(client) == 1)
	{
		SetEntProp(client, Prop_Data, "m_iObserverMode", 6);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}




