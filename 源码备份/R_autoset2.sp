#include <sourcemod>
#include <sdktools_functions>

new bool:Rautogive1;
new bool:R_abhop[66];
new Handle:hOA_AT;
new bool:OA_AT;
public Plugin:myinfo =
{
	name = "L4D2自动设定1.0-by望夜",
	description = "L4D2 auto set (!ontui,!offtui,!onhw,!offhw,!onrb,!offrb)",
	author = "Ryanx",
	version = "L4D2自动设定1.0-by望夜",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("L4D2_auto_set_version", "L4D2自动设定1.0-by望夜", "L4D2自动设定1.0-by望夜", 131392, false, 0.0, false, 0.0);
	RegConsoleCmd("sm_ontui", Ontuisets, "", 0);
	RegConsoleCmd("sm_offtui", Offtuisets, "", 0);
	RegConsoleCmd("sm_onhw", Onhwsets, "", 0);
	RegConsoleCmd("sm_offhw", Offhwsets, "", 0);
	RegConsoleCmd("sm_onrb", OnAutoRbhop, "", 0);
	RegConsoleCmd("sm_offrb", OffAutoRbhop, "", 0);
	HookEvent("player_disconnect", RAEvent_PlayerDisct, EventHookMode:1);
	HookEvent("item_pickup", RAweaponEvent_pickup, EventHookMode:1);
	hOA_AT = CreateConVar("Only_Admin", "0", "[0=所有人|1=仅管理员]可使用命令(连跳除外)", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "r_autoset", "sourcemod");
	Rautogive1 = false;
	OA_AT = GetConVarBool(hOA_AT);
}

public OnMapStart()
{
	OA_AT = GetConVarBool(hOA_AT);
}

public Action:Ontuisets(client, args)
{
	new var1;
	if (OA_AT && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.-by望夜");
		return Action:0;
	}
	SetConVarInt(FindConVar("z_gun_swing_coop_max_penalty"), 0, false, false);
	PrintToChatAll("\x04[!提示!]\x03 已开启无限推!ontui,!offtui进行设置-by望夜 ");
	return Action:0;
}

public Action:Offtuisets(client, args)
{
	new var1;
	if (OA_AT && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.-by望夜");
		return Action:0;
	}
	SetConVarInt(FindConVar("z_gun_swing_coop_max_penalty"), 8, false, false);
	PrintToChatAll("\x04[!提示!]\x03 已关闭无限推!ontui,!offtui进行设置-by望夜 ");
	return Action:0;
}

public Action:Onhwsets(client, args)
{
	new var1;
	if (OA_AT && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.-by望夜");
		return Action:0;
	}
	Rautogive1 = true;
	CreateTimer(0.1, RautosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:Offhwsets(client, args)
{
	new var1;
	if (OA_AT && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.-by望夜");
		return Action:0;
	}
	Rautogive1 = false;
	PrintToChatAll("\x04[!提示!]\x03 已关闭自动给于红外!onhw,!offhw进行设置-by望夜 ");
	return Action:0;
}

public Action:OnAutoRbhop(client, args)
{
	R_abhop[client] = 1;
	PrintToChat(client, "\x04[提醒:]\x03已开启按住空格自动连跳,!offrb关闭-by望夜");
	return Action:0;
}

public Action:OffAutoRbhop(client, args)
{
	R_abhop[client] = 0;
	PrintToChat(client, "\x04[提醒:]\x03已关闭按住空格自动连跳,!onrb开启-by望夜");
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
			new var1;
			if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsPlayerAlive(ix))
			{
				FakeClientCommand(ix, "upgrade_add laser_sight");
			}
			ix++;
		}
		SetCommandFlags("upgrade_add", flagsRautoset | 16384);
		PrintToChatAll("\x04[!提示!]\x03 已开启自动给于红外!onhw,!offhw进行设置-by望夜 ");
	}
	else
	{
		PrintToChatAll("\x04[!提示!]\x03 已关闭自动给于红外!onhw,!offhw进行设置-by望夜 ");
	}
	return Action:0;
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (R_abhop[Client] == true)
	{
		new var1;
		if (IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client))
		{
			if (buttons & 2)
			{
				new var2;
				if (!GetEntityFlags(Client) & 1 && !GetEntityFlags(Client) & 512 && !GetEntityFlags(Client) & 4 && !GetEntityMoveType(Client) == 9)
				{
					buttons = buttons & -3;
				}
			}
		}
	}
	return Action:0;
}

public Action:RAEvent_PlayerDisct(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (Client && !IsFakeClient(Client))
	{
		R_abhop[Client] = 0;
	}
	return Action:0;
}

