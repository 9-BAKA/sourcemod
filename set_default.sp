#include <sourcemod>
#include <sdktools_functions>

bool server_hibernating = true;
int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;

public Plugin:myinfo =
{
	name = "设置默认值",
	description = "设置默认值",
	author = "BAKA",
	version = "1.1",
	url = "baka.cirno.cn"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_setdefault", SetDefault, ADMFLAG_ROOT, "设置服务器默认值");
	RegAdminCmd("sm_setall", SetAll, ADMFLAG_ROOT, "将服务器所有参数设为默认值");

	ServerCommand("map c1m1_hotel");
	SetConVarInt(FindConVar("sb_all_bot_game"), 1);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	PrintToServer("加载提示1");
}

public OnMapStart() {
	thirdparty_count = 0;
	Timer_CheckEmpty_Kill();
	g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_OnFeedDog, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapEnd() {
	Timer_CheckEmpty_Kill();
}

public void OnClientConnected(int client)
{
	// 是否bot？
	if (!IsFakeClient(client) && server_hibernating)
	{
		PrintToServer("链接提示");
		SetConVarInt(FindConVar("sb_all_bot_game"), 1);
		SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		server_hibernating = false;
		thirdparty_count = 0;
		Timer_CheckEmpty_Kill();
		g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_OnFeedDog, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Action SetDefault(int client, int args)
{
	if (client == 0 || GetUserFlagBits(client))
	{
		SetVal();
	}
	else
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	}
	return Plugin_Continue;
}

public Action SetAll(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		ServerCommand("sm plugins refresh");
	}
	else
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	}
	return Plugin_Continue;
}

public void SetVal()
{
	CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
	SetConVarInt(FindConVar("sm_jumpmod"), 0);
	SetConVarInt(FindConVar("sm_auto_respawn"), 0);
	SetConVarInt(FindConVar("sm_health_enable"), 0);
	SetConVarInt(FindConVar("sm_teleport_enable"), 1);
	SetConVarInt(FindConVar("sm_tpall_enable"), 0);
	ServerCommand("sm_on141");
	ServerCommand("sm_onif");
	ServerCommand("sm_offhx");
	ServerCommand("sm_onammo");
	ServerCommand("sm_restore");
	ServerCommand("sm_cvar mp_gamemode coop");
	// ServerCommand("changelevel c1m1_hotel");
}

CheatCommand(client, char[] command, char[] arguments)
{
	if (!client || !IsClientInGame(client))
	{
		int target = 1;
		while (target <= MaxClients)
		{
			if (IsClientInGame(target))
			{
				client = target;
				if (!client || !IsClientInGame(client))
				{
					return 0;
				}
			}
			target++;
		}
		if (!client || !IsClientInGame(client))
		{
			return 0;
		}
	}
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, 16384);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
	return 0;
}

Timer_CheckEmpty_Kill() {
	if (g_hTimer_CheckEmpty != INVALID_HANDLE) {
		KillTimer(g_hTimer_CheckEmpty);
		g_hTimer_CheckEmpty = INVALID_HANDLE;
	}
}

public Action Timer_OnFeedDog(Handle timer, any param) 
{
	bool isOfficialMap = true;
	char mapName[256];
	GetCurrentMap(mapName, 256);
	if (mapName[0] != 'c' || !IsCharNumeric(mapName[1]))
		isOfficialMap = false;

	if (!HasHumanPlayer()) {
		PrintToServer("休眠计时：%d", thirdparty_count);
		thirdparty_count++;
		if (thirdparty_count > 60) {
			thirdparty_count = 0;
			
			if (!isOfficialMap)
			{
				ForceChangeLevel("c1m1_hotel", "Server idle + running third-party map, ready to switch to official maps");
			}
			else
			{
				SetVal();
				server_hibernating = true;
				LogMessage("Server idle");
			}
			Timer_CheckEmpty_Kill();
			return Plugin_Stop;
		}
	} 
	else
	{
		thirdparty_count = 0;
	}
	
	return Plugin_Handled;
}

HasHumanPlayer()
{
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;

		if (!IsFakeClient(i))
			return true;
	}
	return false;
}
