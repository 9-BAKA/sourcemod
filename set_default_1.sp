#include <sourcemod>
#include <sdktools_functions>

bool server_hibernating = true;
int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;
bool FirstSet = false;

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
	RegAdminCmd("sm_setp", SetPara, ADMFLAG_ROOT, "设置自定义参数");

	ServerCommand("map c1m1_hotel");
	PrintToServer("加载提示1");
}

public OnMapStart() {
	if (!FirstSet)
	{
		ServerCommand("sm_setp");
		FirstSet = true;
	}
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

public Action SetPara(int client, int args)
{
	PrintToServer("设置参数");
	if (args == 0)
	{
		// ServerCommand("sm_onhx");
		ServerCommand("sm_onhw");
		ServerCommand("sm_ontui");
		ServerCommand("sm_on141");
		ServerCommand("sm_mmn 2");
		// ServerCommand("sm_it 5");
		ServerCommand("sm_onzc");
		ServerCommand("sm_onammo");
		// ServerCheatCommand("z_difficulty Impossible");
		// SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1, false, false);
		PrintToChatAll("恢复参数零");
		PrintToServer("恢复参数零");
	}
	else
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int num = StringToInt(arg, 10);
		PrintToServer("%d", num);

		if (num == 1)
		{
			ServerCommand("sm_onhx");
			ServerCommand("sm_onhw");
			ServerCommand("sm_ontui");
			ServerCommand("sm_on141");
			ServerCommand("sm_mmn 4");
			ServerCommand("sm_it 5");
			ServerCommand("sm_onzc");
			ServerCommand("sm_onammo");
			ServerCheatCommand("z_difficulty Impossible");
			SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1, false, false);
			PrintToChatAll("恢复参数一");
			PrintToServer("恢复参数一");
		}
	}
}

public void SetVal()
{
	ServerCheatCommand("ent_fire l4d2_spawn_props_prop KillHierarchy");
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
	SetConVarInt(FindConVar("sm_jumpmod"), 0);
	SetConVarInt(FindConVar("sm_auto_respawn"), 0);
	SetConVarInt(FindConVar("sm_health_enable"), 0);
	SetConVarInt(FindConVar("sm_teleport_enable"), 1);
	SetConVarInt(FindConVar("sm_tpall_enable"), 0);
	ServerCommand("sm_on141");
	ServerCommand("sm_onif");
	// ServerCommand("sm_offhx");
	ServerCommand("sm_onammo");
	ServerCommand("sm_restore");
	ServerCommand("sm_cvar mp_gamemode coop");
	// ServerCommand("changelevel c1m1_hotel");
}

ServerCheatCommand(char[] command)
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	ServerCommand(command);
	SetCommandFlags(command, flags);
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
				ForceChangeLevel("c5m1_waterfront", "Server idle + running third-party map, ready to switch to official maps");
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
