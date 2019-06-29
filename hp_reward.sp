/*****
zombieClass: 2 == boomer / 4 == sppiter / 1 == smoker / 5 == jockey / 3 == hunter / 6 == charger / 8 == tank / 7 == witch
*****/	
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new bool:On = false;

new Handle:hHRSI;
new Handle:hHRBoss;
new Handle:hHRNotifications;
new Handle:hHRMax;

new iSI;
new iBoss;
new iMax;

new bool:bNotifications;
new bool:bSI;
new bool:bBoss;

public Plugin:myinfo =
{
	name = "HP Rewards",
	author = "qq1456408989",
	description = "Additional Health For Killing SI and Tanks/Witches.",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public OnpluginStart()
{
	CreateConVar("hp_rewards_version", PLUGIN_VERSION, "HP Rewards Version", FCVAR_NOTIFY);
	hHRSI = CreateConVar("hp_reward_si", "3", "Rewards HP For Kill SI", FCVAR_NOTIFY);
	hHRBoss = CreateConVar("hp_reward_boss", "15", "Rewards HP For Kill Boss", FCVAR_NOTIFY);
	hHRNotifications = CreateConVar("hp_reward_notify", "1", "Notifications Mode: 0 = CenterText, 1 = HintText", FCVAR_NOTIFY);
	hHRMax = CreateConVar("hp_reward_max", "150", "Max HP Limit", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "hp_rewards");

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRewardsReset);
	HookEvent("finale_win", OnRewardsReset);
	HookEvent("mission_lost", OnRewardsReset);
	HookEvent("map_transition", OnRewardsReset);
	HookEvent("player_death", PlayerKill);
	HookEvent("witch_killed", BossKill);
	HookEvent("tank_killed", BossKill);
	
	iSI = GetConVarInt(hHRSI);
	iBoss = GetConVarInt(hHRBoss);
	iMax = GetConVarInt(hHRMax);
	
	bNotifications = GetConVarBool(hHRNotifications);
	bSI = GetConVarBool(hHRSI);
	bBoss = GetConVarBool(hHRBoss);
	
	HookConVarChange(hHRSI, HRConfigsChanged);
	HookConVarChange(hHRBoss, HRConfigsChanged);
	HookConVarChange(hHRMax, HRConfigsChanged);
}

public HRConfigsChanged(Handle:convar, const String:oValue[], const String:nValue[])
{
	iSI = GetConVarInt(hHRSI);
	iBoss = GetConVarInt(hHRBoss);
	iMax = GetConVarInt(hHRMax);
	
	bNotifications = GetConVarBool(hHRNotifications);
	bSI = GetConVarBool(hHRSI);
	bBoss = GetConVarBool(hHRBoss);
}

public OnMapStart()
{
	On = true;
}

public OnMapEnd()
{
	On = false;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On)
	{
		return;
	}
	On = true;
}

public Action:OnRewardsReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!On)
	{
		return;
	}
	On = false;
}

public Action:PlayerKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3)
		{
			return;
		}
		
		if(On)
		{
			new zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			new Killer = GetClientOfUserId(GetEventInt(event, "attacker"));
			new nowhp = GetClientHealth(Killer);
			new rewardhp;
			new health;
			
			if(IsClientInGame(Killer) && GetClientTeam(Killer) == 2 &&  IsPlayerAlive(Killer) && !IsPlayerIncapped(Killer))
			{
				if(bBoss)
				{
					if(zClass == 7 || zClass == 8)
					{	
						health = nowhp + iBoss;
						rewardhp = iBoss;
					}
				}
				else if(bSI)
				{
					if(zClass == 1 || zClass ==2 || zClass == 3 || zClass ==4 || zClass == 5 || zClass == 6)
					{
						health = nowhp + iSI;
						rewardhp = iSI;
					}
				}
			}
			if(health <= iMax)
			{
				SetEntProp(Killer, Prop_Send, "m_iHealth", health, 1);
			}
			else
			{
				SetEntProp(Killer, Prop_Send, "m_iHealth", iMax, 1);
			}
			if(On)
			{
				if(bNotifications)
				{
					PrintHintText(Killer, "%i + %i HP", nowhp, rewardhp);
				}
				else
				{
					PrintCenterText(Killer, "%i + %i HP", nowhp, rewardhp);
				}
			}
		}
	}
}

public Action:BossKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On && bBoss)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			if(IsPlayerIncapped(client))
			{
				return;
			}
			
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			
			new tClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(tClass == 8)
			{
				PrintToChatAll("\x03%N 杀死了 \x03坦克\x04 !", client);
			}
			else if(tClass == 7)
			{
				PrintToChatAll("\x03%N 杀死了 \x03女巫\x04 !", client);
			}
		}
	}
}	
		
public IsPlayerIncapped(client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	else
	{
		return false;
	}
}		


		
	
	