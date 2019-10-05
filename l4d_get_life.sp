#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define SOUND_KILL1  "/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2  "/weapons/knife/knife_deploy.wav"
#define INCAP	         1
#define INCAP_GRAB	     2
#define INCAP_POUNCE     3
#define INCAP_RIDE		 4
#define INCAP_PUMMEL	 5
#define INCAP_EDGEGRAB	 6

new Handle:g_hCvar_HealthEnabled;
new Float:g_LocationSlots[MAXPLAYERS+1][3];
bool HealthEnabled;
new Attacker[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new L4D2Version = false;

public Plugin myinfo =
{
	name = "生命回血插件",
	description = "输入代码解控加血",
	author = "BAKA",
	version = "1.0",
	url = "http://47.94.208.140/"
};

public void OnPluginStart()
{

	//RegConsoleCmd("sm_fuhuo", Revive, "输入代码复活");
	RegConsoleCmd("sm_jiaxue", Health, "输入代码回血");
	RegConsoleCmd("sm_huixue", Health, "输入代码回血");

	g_hCvar_HealthEnabled = CreateConVar("sm_health_enable", "0", "设置是否允许代码加血", FCVAR_NOTIFY);

	decl String:GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version = true;
	}	
	else
	{
		L4D2Version = false;
	}

	HookEvent("player_incapacitated", Event_Incap);

	HookEvent("lunge_pounce", lunge_pounce);
	HookEvent("pounce_stopped", pounce_stopped);
	
	HookEvent("tongue_grab", tongue_grab);
	HookEvent("tongue_release", tongue_release);

	HookEvent("player_ledge_grab", player_ledge_grab);

	HookEvent("round_start", RoundStart);

	HookConVarChange(g_hCvar_HealthEnabled, ConVarChanged);
  	 
	if(L4D2Version)
	{
		HookEvent("jockey_ride", jockey_ride);
		HookEvent("jockey_ride_end", jockey_ride_end);
		
		HookEvent("charger_pummel_start", charger_pummel_start);
		HookEvent("charger_pummel_end", charger_pummel_end);

	}
}

public void OnMapStart()
{
	HealthEnabled = GetConVarBool(g_hCvar_HealthEnabled);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAbsOrigin(i, g_LocationSlots[i]);
			break;
		}
	}
	if(L4D2Version)	PrecacheSound(SOUND_KILL2, true);
	else PrecacheSound(SOUND_KILL1, true);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HealthEnabled = GetConVarBool(g_hCvar_HealthEnabled);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	reset();
	return Plugin_Continue;
}

reset()
{
	for (new x = 0; x < MAXPLAYERS + 1; x++)
	{
		Attacker[x] = 0;
		IncapType[x] = 0;
	}
}

public Action GiveItems(Handle timer, any client)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & -16385);
	FakeClientCommand(client, "give weapon_sniper_awp");
	FakeClientCommand(client, "give knife");
	FakeClientCommand(client, "give pain_pills");
	SetCommandFlags("give", flags | 16384);
	return 0;
}

public Action:Health(client, args)
{
	HealthEnabled = GetConVarBool(g_hCvar_HealthEnabled);
	if (HealthEnabled)
	{
		if (GetClientTeam(client) != 2)
		{
			PrintToChat(client, "请先加入幸存者再使用此命令");
		}
		else if (!IsPlayerAlive(client))
		{
			PrintToChat(client, "请先复活");
		}
		else
		{
			if (CanSelfHelp(client))
			{
				SelfHelp(client);
				IncapType[client] = 0;
			}	
			SetHealth(client);

			char name[MAX_NAME_LENGTH];
			GetClientName(client, name, MAX_NAME_LENGTH);
			PrintToChatAll("\x04[加血] \x03%s \x01加血成功!", name); 

			EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav");
		}
	}
	else
	{
		PrintToChat(client, "服务器暂时没有开启代码回血功能");
	}
}

bool:CanSelfHelp(client)
{
	new bool:ok=false;
	if(IncapType[client] > 0)
	{
		ok=true;
	}
	return ok;
}

SetHealth(client)
{
	new sBonusHP = 100;
	SetEntProp(client, PropType:0, "m_iHealth", sBonusHP, 1, 0);
	SetEntDataFloat(client, 100, 100, true);
	return 0;
}

public int Humannums()
{
	int numHuman = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				numHuman++;
			}
		}
		i++;
	}
	return numHuman;
}

public int Botnums()
{
	int numBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				numBots++;
			}
		}
		i++;
	}
	return numBots;
}

public int Gonaways()
{
	int numaways = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i) && GetClientTeam(i) == 1)
			{
				numaways++;
			}
		}
		i++;
	}
	return numaways;
}

SelfHelp(client)
{
 	 
 	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	} 
	if (!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client] == 0) 
	{
		return;
	} 

	KillAttack(client);
	ReviveClientWithKid(client);

	EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound

 }

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}

bool:IsPlayerGrapEdge(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}

ReviveClientWithKid(client)
{
 
	new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
 
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
			
	SetEntData(client, propincapcounter, 0, 1);
	SetEntityHealth(client, 1);		
	SetEntDataFloat(client, 100, 100, true);
	
}

KillAttack(client)
{
	new a = Attacker[client];
	if(a != 0)
	{
		if(IsClientInGame(a) && GetClientTeam(a) == 3 && IsPlayerAlive(a))
		{
			ForcePlayerSuicide(a);		
			if(L4D2Version)	EmitSoundToAll(SOUND_KILL2, client); 
			else EmitSoundToAll(SOUND_KILL1, client); 
		}
	}
}

public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
}

public pounce_stopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	Attacker[victim] = 0;
}

public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
}

public tongue_release (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}
public jockey_ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
}

public jockey_ride_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

 public charger_pummel_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_PUMMEL;
}

public charger_pummel_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}

}
 
public Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim] = INCAP;
}

public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim] = INCAP_EDGEGRAB;
}
