#include <sourcemod>
#include <sdktools_functions>

bool server_hibernating = true;
int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;

public Plugin:myinfo =
{
	name = "设置默认值",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_setdefault", SetDefault, ADMFLAG_ROOT, "设置服务器默认值");
}

public OnMapStart() {
	Timer_CheckEmpty_Kill();
	g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_OnFeedDog, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapEnd() {
	Timer_CheckEmpty_Kill();
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	// 是否bot？
	if (server_hibernating)
	{
		SetConVarInt(FindConVar("sb_all_bot_game"), 1);
		SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		server_hibernating = false;
	}
}

public Action SetDefault(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		SetVal();
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
	SetConVarInt(FindConVar("auto_jumpmap_enable"), 0);
	ServerCommand("sm_off14");
	ServerCommand("sm_offhx");
	ServerCommand("sm_onammo");
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
	if (mapName[0] != 'c')
		isOfficialMap = false;
	if (!IsCharNumeric(mapName[1]))
		isOfficialMap = false;


	bool hasHumanPlayer = false;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;

		if (!IsFakeClient(i))
			hasHumanPlayer = true;
	}

	if (!hasHumanPlayer) {
		thirdparty_count++;
		if (thirdparty_count > 12) {
			thirdparty_count = 0;
			
			Timer_CheckEmpty_Kill();
			SetVal();
			SetConVarInt(FindConVar("sb_all_bot_game"), 0);
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
			server_hibernating = true;
			if (!isOfficialMap)
			{
				ForceChangeLevel("c1m1_hotel", "Server idle + running third-party map, ready to switch to official maps");
			}
			LogMessage("Server idle + running third-party map, ready to switch to official maps");
			return Plugin_Stop;
		}
	} else {
		thirdparty_count = 0;
	}
	
	return Plugin_Handled;
}
