#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.1"
#define CUESOUND "level/popup.wav"

new Handle:hMode = INVALID_HANDLE;
new Handle:hMultiplier = INVALID_HANDLE;
new Handle:hLimit = INVALID_HANDLE;
new Handle:hOffset = INVALID_HANDLE;

new bool:bCueAllowed[MAXPLAYERS+1] = false;
new bool:bBunnyhopOff[MAXPLAYERS+1] = true;
new iOffset = 0;
new iDirectionCache[MAXPLAYERS+1] = 0;

new bool:Rautogive1;
new Handle:hOA_AT;
new bool:OA_AT;

public Plugin:myinfo =
{
	name = "L4D2自动设定",
	description = "L4D2 auto set (!ontui,!offtui,!onhw,!offhw,!onrb,!offrb)",
	author = "Ryanx",
	version = "L4D2自动设定",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("L4D2_auto_set_version", "L4D2自动设定", "L4D2自动设定", 131392, false, 0.0, false, 0.0);
	RegConsoleCmd("sm_ontui", Ontuisets, "", 0);
	RegConsoleCmd("sm_offtui", Offtuisets, "", 0);
	RegConsoleCmd("sm_onhw", Onhwsets, "", 0);
	RegConsoleCmd("sm_offhw", Offhwsets, "", 0);
	// HookEvent("player_disconnect", RAEvent_PlayerDisct, EventHookMode:1);
	HookEvent("item_pickup", RAweaponEvent_pickup, EventHookMode:1);
	hOA_AT = CreateConVar("autoset_admin", "0", "[0=所有人|1=仅管理员|2=仅白名单]可使用命令(连跳除外)", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "r_autoset", "sourcemod");
	Rautogive1 = false;
	OA_AT = GetConVarBool(hOA_AT);

	CreateConVar("l4d_bunnyhop_version", PLUGIN_VERSION, "version of bunnyhop+", FCVAR_NOTIFY);

	hMode = CreateConVar("l4d_bunnyhop_mode", "1.0", "Plugin mode: (0)disabled (1)auto-bunnyhop (2)manual bunnyhop training", FCVAR_NOTIFY,true,0.0,true,2.0);
	hMultiplier = CreateConVar("l4d_bunnyhop_multiplier","50.0", "Multiplier: set the value multiplied to the lateral velocity gain for each successful bunnyhop.", FCVAR_NOTIFY,true,0.0,true,200.0);
	hLimit = CreateConVar("l4d_bunnyhop_limit", "300.0", "Limit: set player speed value at which lateral velocity no longer multiplies lateral velocity.", FCVAR_NOTIFY,true,0.0,true,500.0);
	hOffset = CreateConVar("l4d_bunnyhop_delay", "0", "Cue offset: for manual mode, set integer value for how early the cue is to be heard. Higher values mean earlier cues.", FCVAR_NOTIFY,true,0.0,true,5.0);

	for (int i = 0; i < MAXPLAYERS; i++){
		bBunnyhopOff[i] = true;
	}

	HookConVarChange(hOffset, ConVar_Delay);
	HookEvent("player_jump_apex", Event_PlayerJumpApex);
	RegConsoleCmd("sm_onrb", Command_AutobhopOn);
	RegConsoleCmd("sm_offrb", Command_AutobhopOff);
	RegConsoleCmd("sm_hop", Command_Autobhop);
	RegConsoleCmd("sm_bunny", Command_Autobhop);
	RegConsoleCmd("sm_bunnyhop", Command_Autobhop);

	AutoExecConfig(true, "r_autoset", "sourcemod");
}

public OnMapStart()
{
	OA_AT = GetConVarBool(hOA_AT);
	PrecacheSound(CUESOUND, true);
	iOffset = GetConVarInt(hOffset);
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		new userid = GetClientUserId(client);
		CreateTimer(5.0, Check, userid);
	}
}

public Action:Check(Handle:Timer, any:userid)
{
	new client = !GetClientOfUserId(userid);
	if(client == 0 || !IsClientConnected(client))
	{
		PrintToServer("AutoSet重置！");
		bBunnyhopOff[client] = true;
	}
}	

public Action:Ontuisets(client, args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	SetConVarInt(FindConVar("z_gun_swing_coop_max_penalty"), 0, false, false);
	PrintToChatAll("\x04[!提示!]\x03 已开启无限推!ontui,!offtui进行设置.");
	return Action:0;
}

public Action:Offtuisets(client, args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	SetConVarInt(FindConVar("z_gun_swing_coop_max_penalty"), 8, false, false);
	PrintToChatAll("\x04[!提示!]\x03 已关闭无限推!ontui,!offtui进行设置");
	return Action:0;
}

public Action:Onhwsets(client, args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rautogive1 = true;
	CreateTimer(0.1, RautosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:Offhwsets(client, args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rautogive1 = false;
	PrintToChatAll("\x04[!提示!]\x03 已关闭自动给于红外!onhw,!offhw进行设置");
	return Action:0;
}

public Action:RAweaponEvent_pickup(Handle:event, String:name[], bool:dontBroadcast)
{
	if (Rautogive1)
	{
		new Rautosetid = GetClientOfUserId(GetEventInt(event, "userid", 0));
		new flagsRautoset = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", flagsRautoset & -16385);
		FakeClientCommand(Rautosetid, "upgrade_add laser_sight");
		SetCommandFlags("upgrade_add", flagsRautoset | 16384);
	}
	return Action:0;
}

public Action:RautosetStartDelays(Handle:timer)
{
	if (Rautogive1)
	{
		new flagsRautoset = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", flagsRautoset & -16385);
		new ix = 1;
		while (ix <= MaxClients)
		{
			if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsPlayerAlive(ix))
			{
				FakeClientCommand(ix, "upgrade_add laser_sight");
			}
			ix++;
		}
		SetCommandFlags("upgrade_add", flagsRautoset | 16384);
		PrintToChatAll("\x04[!提示!]\x03 已开启自动给于红外!onhw,!offhw进行设置");
	}
	else
	{
		PrintToChatAll("\x04[!提示!]\x03 已关闭自动给于红外!onhw,!offhw进行设置");
	}
	return Action:0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarInt(hMode) == 1 && !bBunnyhopOff[client] && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityMoveType(client) & MOVETYPE_LADDER))
			{
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2) buttons &= ~IN_JUMP;
			}
		}
	}
	return Plugin_Continue;
}

public Action:RAEvent_PlayerDisct(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (Client && !IsFakeClient(Client))
	{
		bBunnyhopOff[Client] = true;
	}
	return Action:0;
}

public ConVar_Delay(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iOffset = StringToInt(newValue);
}

public Action:Command_AutobhopOn(client, args)
{	
	if (GetConVarInt(hMode) == 1
		&& client > 0
		&& IsClientInGame(client)
		&& IsPlayerAlive(client))
	{
		bBunnyhopOff[client] = false;
		PrintToChat(client, "\x04[提醒:]\x03已开启按住空格自动连跳,!offrb关闭");
	}
	return Plugin_Handled;
}

public Action:Command_AutobhopOff(client, args)
{	
	if (GetConVarInt(hMode) == 1
		&& client > 0
		&& IsClientInGame(client)
		&& IsPlayerAlive(client))
	{
		bBunnyhopOff[client] = true;
		PrintToChat(client, "\x04[提醒:]\x03已关闭按住空格自动连跳,!onrb开启");
	}
	return Plugin_Handled;
}

public Action:Command_Autobhop(client, args)
{	
	if (GetConVarInt(hMode) == 1
		&& client > 0
		&& IsClientInGame(client)
		&& IsPlayerAlive(client))
	{
		if (bBunnyhopOff[client] == true)
		{
			bBunnyhopOff[client] = false;
			PrintToChat(client, "\x04[提醒:]\x03已开启按住空格自动连跳,!offrb关闭");
		}
		else
		{
			bBunnyhopOff[client] = true;
			PrintToChat(client, "\x04[提醒:]\x03已关闭按住空格自动连跳,!onrb开启");
		}
	}
	return Plugin_Handled;
}

public OnGameFrame()
{
	if (!IsServerProcessing()
		|| GetConVarInt(hMode) != 2)
		return;
	for (new i=1 ; i<=MaxClients ; i++)
	{
		if (!bBunnyhopOff[i]
			&& IsClientInGame(i)
			&& IsPlayerAlive(i)
			&& bCueAllowed[i]
			&& GetEntProp(i, Prop_Data, "m_nWaterLevel") < 1 + iOffset)
		{
			bCueAllowed[i] = false;
			EmitSoundToClient(i, CUESOUND);
		}	
	}
}

public Event_PlayerJumpApex(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMode = GetConVarInt(hMode);
	if (iMode == 0) return;
	int client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (!IsClientInGame(client)
		|| GetClientTeam(client)!= 2
		|| !IsPlayerAlive(client)
		|| bBunnyhopOff[client])
		return;
	
	if (iMode == 2) bCueAllowed[client] = true;
	
	if ((GetClientButtons(client) & IN_MOVELEFT)
		|| (GetClientButtons(client) & IN_MOVERIGHT))
	{	
		if (GetClientButtons(client) & IN_MOVELEFT) 
		{
			if (iDirectionCache[client] > -1)
			{
				iDirectionCache[client] = -1;
				return;
			}
			else iDirectionCache[client] = -1;
		}
		else if (GetClientButtons(client) & IN_MOVERIGHT)
		{
			if (iDirectionCache[client] < 1)
			{
				iDirectionCache[client] = 1;
				return;
			}
			else iDirectionCache[client] = 1;
		}
		new Float:fAngles[3];
		new Float:fLateralVector[3];
		new Float:fForwardVector[3];
		new Float:fNewVel[3];
		
		GetEntPropVector(client, Prop_Send, "m_angRotation", fAngles);
		GetAngleVectors(fAngles, NULL_VECTOR, fLateralVector, NULL_VECTOR);
		NormalizeVector(fLateralVector, fLateralVector);
		
		if (GetClientButtons(client) & IN_MOVELEFT) NegateVector(fLateralVector);

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fForwardVector);
		if (RoundToNearest(GetVectorLength(fForwardVector)) > GetConVarFloat(hLimit)) return;
		else ScaleVector(fLateralVector, GetVectorLength(fLateralVector) * GetConVarFloat(hMultiplier));
		
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fNewVel);
		for(new i=0;i<3;i++) fNewVel[i] += fLateralVector[i];

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,fNewVel);
	}
}

