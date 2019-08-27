#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

new bool:g_bSpawn[2150];
new String:ModelList[60][256];
new IsTouched[66][2150];
new ComboCount[66];
new ComboWaitTime[66];
new Handle:ComboTimer[66];

public Plugin:myinfo =
{
	name = "连跳提示",
	description = "",
	author = "BAKA",
	version = "1.0",
	url = "baka.cirno.cn/l4d2/"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode:1);
	HookEvent("round_end", Event_RoundEnd, EventHookMode:1);
}

public OnMapStart()
{
	PrecacheSound("player/TouchModel.mp3", false);
	PrecacheSound("ui/beep_error01.wav", false);
	PrecacheSound("ui/survival_medal.wav", false);
	PrecacheSound("player/orch_hit_csharp_short.wav", false);
	CreateTimer(1.0, Timer_TouchStar, any:0, 0);
}

public OnClientDisconnect(client)
{
	CreateTimer(0.2, Timer_Delete, client, 0);
}

public OnEntityDestroyed(entity)
{
	if (entity > MaxClients)
	{
		if (g_bSpawn[entity])
		{
			decl String:ModelName[256];
			GetEntPropString(entity, PropType:1, "m_ModelName", ModelName, 256, 0);
			new i;
			while (i < 60)
			{
				if (!StrEqual(ModelList[i], "", false))
				{
					if (StrEqual(ModelList[i], ModelName, false))
					{
						SDKUnhook(entity, SDKHookType:8, SDKCallBack_StartTouch);
						g_bSpawn[entity] = false;
					}
				}
				i++;
			}
		}
	}
}

public SDKCallBack_StartTouch(entity, client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (0 < entity)
		{
			if (g_bSpawn[entity] && !IsTouched[client][entity])
			{
				IsTouched[client][entity] = 1;
				if (ComboCount[client])
				{
					if (ComboTimer[client])
					{
						ComboWaitTime[client] = 0;
					}
					ComboCount[client]++;
					PrintCenterText(client, "Combo跳 %d 次!", ComboCount[client]);
					if (ComboCount[client] >= 15 && ComboCount[client] % 5 == 0)
					{
						PrintToChatAll("\x04玩家\x03[%N]\x04连跳成功%d次!", client, ComboCount[client]);
						EmitSoundToAll("ui/survival_medal.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
                }
				EmitSoundToClient(client, "player/TouchModel.mp3", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
		}
	}
	return 0;
}

public Action:CallBack_ComboTimer(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ComboWaitTime[client]++;
		if (ComboWaitTime[client] >= 2)
		{
			ComboCount[client] = 0;
			ComboWaitTime[client] = 0;
			KillTimer(ComboTimer[client], false);
			ComboTimer[client] = INVALID_HANDLE;
			EmitSoundToClient(client, "ui/beep_error01.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	else
	{
		ComboCount[client] = 0;
		ComboWaitTime[client] = 0;
		KillTimer(ComboTimer[client], false);
		ComboTimer[client] = INVALID_HANDLE;
	}
	return Action:0;
}

public Event_RoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	CreateTimer(5.0, Timer_TouchStar, any:0, 0);
	return 0;
}

public Event_RoundEnd(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	CreateTimer(5.0, Timer_TouchEnd, any:0, 0);
	return 0;
}

public Action:Timer_TouchStar(Handle:timer)
{
	CreateTimer(1.0, Timer_DeleteAll, any:0, 0);
	new entity = MaxClients + 1;
	while (entity < 2150)
	{
		if (!g_bSpawn[entity] && IsValidEntity(entity))
		{
			decl String:ModelName[256];
			GetEntPropString(entity, PropType:1, "m_ModelName", ModelName, 256, 0);
			new i;
			while (i < 60)
			{
				if (!StrEqual(ModelName, "", true) && StrEqual(ModelList[i], ModelName, true))
				{
					SDKHook(entity, SDKHookType:8, SDKCallBack_StartTouch);
					g_bSpawn[entity] = true;
				}
				i++;
			}
		}
		entity++;
	}
	return Action:0;
}

public Action:Timer_TouchEnd(Handle:timer)
{
	new a = MaxClients + 1;
	while (a < 2150)
	{
		if (g_bSpawn[a] && IsValidEntity(a))
		{
			decl String:ModelName[256];
			GetEntPropString(a, PropType:1, "m_ModelName", ModelName, 256, 0);
			new b;
			while (b < 60)
			{
				if (!StrEqual(ModelName, "", true) && StrEqual(ModelList[b], ModelName, false))
				{
					SDKUnhook(a, SDKHookType:8, SDKCallBack_StartTouch);
					g_bSpawn[a] = false;
				}
				b++;
			}
		}
		a++;
	}
	return Action:0;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	new i;
	while (i < 2150)
	{
		IsTouched[client][i] = 0;
		i++;
	}
	ComboWaitTime[client] = 0;
	ComboCount[client] = 0;
	if (ComboTimer[client])
	{
		KillTimer(ComboTimer[client], false);
	}
	return Action:0;
}

public Action:Timer_DeleteAll(Handle:timer)
{
	new a = 1;
	while (a <= MaxClients)
	{
		if (IsClientConnected(a) && !IsFakeClient(a))
		{
			ComboWaitTime[a] = 0;
			ComboCount[a] = 0;
			if (ComboTimer[a])
			{
				KillTimer(ComboTimer[a], false);
			}
		}
		a++;
	}
	return Action:0;
}

