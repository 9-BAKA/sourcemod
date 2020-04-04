#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.0"
#define ZOMBIECLASS_TANK		8

Handle g_multitank_enable;
Handle g_multitank_count;
Handle hOA_AT;
int tank_spawn_buffer = 0;
int tank_spawn_multi;
bool tank_spawn_multi_enable;
bool OA_AT;

public Plugin:myinfo =
{
	name = "L4D2多坦克",
	description = "L4D2多坦克插件",
	author = "BAKA",
	version = PLUGIN_VERSION,
	url = "baka.cirno.cn"
};

public OnPluginStart()
{
	CreateConVar("l4d2_mt_version", PLUGIN_VERSION, "插件版本");
	g_multitank_enable = CreateConVar("multitank_enable", "0", "是否默认开启插件", FCVAR_NOTIFY);
	g_multitank_count = CreateConVar("multitank_count", "2", "默认坦克倍数", FCVAR_NOTIFY);
	hOA_AT = CreateConVar("multitank_admin", "0", "是否只有管理员可使用命令", FCVAR_NOTIFY);
	tank_spawn_multi_enable = GetConVarBool(g_multitank_enable);
	tank_spawn_multi = GetConVarInt(g_multitank_count);
	OA_AT = GetConVarBool(hOA_AT);
	AutoExecConfig(true, "l4d2_multitanks");
	RegConsoleCmd("sm_onmt", Command_OnMultiTank);
	RegConsoleCmd("sm_offmt", Command_OffMultiTank);
	RegConsoleCmd("sm_setmt", Command_SetMulti);
	HookConVarChange(g_multitank_enable, ConVarChanged);
	HookConVarChange(g_multitank_count, ConVarChanged);
	HookConVarChange(hOA_AT, ConVarChanged);
	HookEvent("round_start", Event_CheckStart, EventHookMode:1);
	HookEvent("tank_spawn", OnTankSpawn);
}

public OnMapStart()
{
	tank_spawn_buffer = 0;
}

public Action:Event_CheckStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckDelays, any:0, 0);
	return Action:0;
}

public Action:CheckDelays(Handle:timer)
{
	if (tank_spawn_multi_enable) PrintToChatAll("\x04[!提示!]\x03 已开启%d倍坦克,输入!offmt可关闭,!setmt设置倍率", tank_spawn_multi);
	else PrintToChatAll("\x04[!提示!]\x03 已关闭%d倍坦克,输入!onmt可开启,!setmt设置倍率", tank_spawn_multi);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	tank_spawn_multi_enable = GetConVarBool(g_multitank_enable);
	tank_spawn_multi = GetConVarInt(g_multitank_count);
}

public Action:Command_OnMultiTank(int client, int args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	tank_spawn_multi_enable = true;
	PrintToChatAll("\x04[提醒:]\x03已开启%d倍坦克.", tank_spawn_multi);
	return Plugin_Handled;
}

public Action:Command_OffMultiTank(int client, int args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	tank_spawn_multi_enable = false;
	PrintToChatAll("\x04[提醒:]\x03已关闭%d倍坦克.", tank_spawn_multi);
	return Plugin_Handled;
}

public Action:Command_SetMulti(int client, int args)
{
	if (OA_AT && client!=0 && !GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	if (args < 1)
	{
		if(client!=0) CreateSelectCvarMenu(client);	
	}
	else if (args > 1)
	{
		PrintToChat(client, "\x04请输入正确参数");
		return Plugin_Handled;
	}
	else
	{
		char arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		tank_spawn_multi = StringToInt(arg, 10);
		PrintToChatAll("\x04[提醒:]\x03坦克倍率设为%d倍.", tank_spawn_multi);
	}
	return Plugin_Continue;
}

public Action CreateSelectCvarMenu(int client)
{
	Handle menu = CreateMenu(SelectMenuHandler);
	SetMenuTitle(menu, "选择坦克生成倍率:");
	AddMenuItem(menu, "1", "1倍(关闭)");
	for (int i = 2; i < 10; i++)
	{
		char multistr[10];
		Format(multistr, 10, "%d倍", i);
		char info[10];
		IntToString(i, info, 10);
		AddMenuItem(menu, info, multistr);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SelectMenuHandler(Handle menu, MenuAction action, int client, int position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char info[10];
			GetMenuItem(menu, position, info, sizeof(info));
			tank_spawn_multi = StringToInt(info);
			PrintToChatAll("\x04[提醒:]\x03坦克倍率设为%d倍.", tank_spawn_multi);
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action:OnTankSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (!tank_spawn_multi_enable) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != 3)
	{
		return;
	}

	if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK)
	{
		if (tank_spawn_buffer > 0)
		{
			tank_spawn_buffer = tank_spawn_buffer - 1;
		}
		else
		{
			tank_spawn_buffer = tank_spawn_multi - 1;
			SpawnMoreTank(tank_spawn_multi - 1);
		}
	}
}

public void SpawnMoreTank(int count)
{
	int iCommandExecuter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iCommandExecuter = i;
			break;
		}
	}

	if (iCommandExecuter == 0)
	{
		return;
	}
	
	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	for (int i = 0; i < count; i++)
		FakeClientCommand(iCommandExecuter, "z_spawn_old tank auto");
	SetCommandFlags("z_spawn_old", iFlags);
}

