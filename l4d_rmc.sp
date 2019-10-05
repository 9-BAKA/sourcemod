#include <sourcemod>
#include <sdktools_functions>
#pragma semicolon 1
#pragma newdecls required

bool RJoincheck;
bool RCNcheck;
bool RAutoBotcheck;
Handle hRJoincheck;
Handle hAutoBotcheck;
Handle hAwayCEnable;
Handle hKickEnable;
Handle hUsermnums;
int usermnums;
int AwayCEnable;
int KickEnable;
char Rmc_ChangeTeam[66];

public Plugin myinfo =
{
	name = "L4D2 Multiplayer RMC",
	description = "L4D2 Multiplayer Commands",
	author = "Ryanx，joyist",
	version = "1.2",
	url = "http://chdong.top/"
};

public void OnPluginStart()
{
	CreateConVar("L4D2_Multiplayer_RMC_version", "1.1", "L4D2多人游戏设置");
	RegConsoleCmd("sm_jg", Jointhegame);
	RegConsoleCmd("sm_join", Jointhegame);
	RegConsoleCmd("sm_joingame", Jointhegame);
	RegConsoleCmd("sm_away", Gotoaway);
	RegConsoleCmd("sm_diannao", CreateOneBot);
	RegConsoleCmd("sm_addbot", CreateOneBot);
	RegConsoleCmd("sm_sinfo", Vserverinfo);
	RegConsoleCmd("sm_bd", Bindkeyhots);
	RegConsoleCmd("sm_rhelp", Scdescription);
	RegConsoleCmd("sm_kb", Kbcheck);
	RegConsoleCmd("sm_sp", RListLoadplayer);
	RegConsoleCmd("sm_zs", Rzhisha);
	RegAdminCmd("sm_set", Numsetcheck, ADMFLAG_ROOT);

	HookEvent("round_start", Event_rmcRoundStart, EventHookMode_Post);
	HookEvent("player_team", Event_rmcteam, EventHookMode_Pre);

	hUsermnums = CreateConVar("L4D2_Rmc_total", "8", "服务器支持玩家人数设置");
	usermnums = GetConVarInt(hUsermnums);
	hRJoincheck = CreateConVar("l4d2_ADM_CHA", "0", "开启几个管理员预留通道");
	RJoincheck = GetConVarBool(hRJoincheck);
	hAwayCEnable = CreateConVar("L4D2_Away_Enable", "0", "是否只允许管理员使用away指令加入观察者");
	AwayCEnable = GetConVarBool(hAwayCEnable);
	hAutoBotcheck = CreateConVar("l4d2_AUOT_ADDBOT", "1", "是否开启自动增加BOT");
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	hKickEnable = CreateConVar("L4D2_Kick_Enable", "1", "是否开启自动踢出多余BOT");
	KickEnable = GetConVarBool(hKickEnable);
	RCNcheck = false;
	AutoExecConfig(true, "l4d2_rmc");
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 999999, false, false);
	RJoincheck = GetConVarBool(hRJoincheck);
	AwayCEnable = GetConVarBool(hAwayCEnable);
	KickEnable = GetConVarInt(hAwayCEnable);
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	if (!RCNcheck)
	{
		usermnums = GetConVarInt(hUsermnums);
		if (usermnums < 1)
		{
			usermnums = 1;
		}
	}
}

public Action Event_rmcRoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, rmcRepDelays);
}

public Action Jointhegame(int client, int args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (!IsClientObserver(client))
	{
		PrintToChat(client, "\x05[加入失败:]\x04你已经在游戏里了！");
	}
	else if (0 < Botnums())
	{
		if (0 < Alivebotnums())
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
		}
		else
		{
			CheatCommand(client, "sb_takecontrol");
			PrintToChat(client, "\x05[加入成功:]\x04但由于没有存活电脑，你当前为死亡状态.");
		}
	}
	else
	{
		LCreateOneBot(client);
		CreateTimer(2.0, PlayerJoin, client);
	}
	// PrintToChat(client, "\x05[加入失败:]\x04没有足够的BOT允许你控制,请输入!diannao增加电脑然后输入!jg加入.");
	return Plugin_Handled;
}

public Action PlayerJoin(Handle timer, any client)
{
	ClientCommand(client, "jointeam 2");
	ClientCommand(client, "go_away_from_keyboard");
}

public int CheatCommand(int Client, char[] command)
{
	if (!Client)
	{
		return 0;
	}
	int admindata = GetUserFlagBits(Client);
	SetUserFlagBits(Client, 16384);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(Client, "%s", command);
	SetCommandFlags(command, flags);
	SetUserFlagBits(Client, admindata);
	return 0;
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client))
	{
		int userid = GetClientUserId(client);
		CreateTimer(5.0, Check, userid);
	}
}

public Action Check(Handle Timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client == 0 || !IsClientConnected(client))
	{
		CreateTimer(1.0, DisKickClient);
		Rmc_ChangeTeam[client] = 0;
	}
}	

public Action DisKickClient(Handle timer)
{
	int playernum = 0;
	int specnum = 0;
	int botnum = 0;
	playernum = Playernums();
	specnum = Gonaways();
	botnum = Botnums();
	KickEnable = GetConVarBool(hKickEnable);
	if (KickEnable && playernum > 4 && botnum > specnum)
	{
		int i = MaxClients;
		while (i > 0 && playernum > 4 && botnum > specnum)
		{
			if (IsClientInGame(i))
			{
				if (IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					KickClient(i, "踢出多余电脑");
					botnum--;
				}
			}
			i--;
		}
	}
}

public Action rmcRepDelays(Handle timer)
{
	if (usermnums < 1)
	{
		usermnums = 1;
	}
	if (RJoincheck)
	{
		//ServerCommand("sm_cvar sv_maxplayers %i", usermnums + 2);
		//ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
		PrintToChatAll("\x04[提示] \x03公共位置\x01[%i] \x03管理员预留位置\x01[2]", 2272);
	}
	else
	{
		//ServerCommand("sm_cvar sv_maxplayers %i", usermnums);
		//ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (RJoincheck)
	{
		int Rnmax = GetConVarInt(FindConVar("sv_maxplayers"));
		int playernum = Allplayersn();  // 非管理员人数
		int reserved = 0;
		if (Rnmax - reserved < playernum)
		{
			if (!GetUserFlagBits(client))
			{
				KickClient(client, "服务器已满,你不是管理员无法进入预留通道!");
			}
			Rmc_ChangeTeam[client] = 0;
			return true;
		}
		Rmc_ChangeTeam[client] = 0;
		return true;
	}
	Rmc_ChangeTeam[client] = 0;
	return true;
}

public Action Kbcheck(int client, int args)
{
	//if (GetUserFlagBits(client))
	//{
		int ix = 1;
		while (ix <= MaxClients)
		{
			if (IsClientInGame(ix))
			{
				if (IsFakeClient(ix) && GetClientTeam(ix) == 2)
				{
					KickClient(ix, "踢出一个bot");
				}
			}
			ix++;
		}
		PrintToChatAll("\x05[提示]\x03 踢除所有bot.");
		return Plugin_Handled;
	//}
	//ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	//return Plugin_Handled;
}

public Action Numsetcheck(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		rDisplaySnumMenu(client);
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	return Plugin_Handled;
}

public int rDisplaySnumMenu(int client)
{
	char namelist[64];
	char nameno[4];
	Handle menu = CreateMenu(rNumMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem|MenuAction_VoteEnd);
	SetMenuTitle(menu, "服务器人数设置");
	int i = 1;
	while (i <= 24)
	{
		Format(nameno, 3, "%i", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int rNumMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		char clientinfos[12];
		int userids = 0;
		GetMenuItem(menu, itemNum, clientinfos, sizeof(clientinfos));
		userids = StringToInt(clientinfos, 10);
		usermnums = userids;
		RCNcheck = true;
		PrintToChat(client, "\x05[提醒:]\x04 默认人数请修改l4d2_rmc.cfg");
		CreateTimer(0.1, rmcRepDelays);
	}
	return 0;
}

public Action Scdescription(int client, int args)
{
	PrintToChatAll("\x05[插件说明]\x03 !jg\x04或\x03!joingame\x04 加入游戏, \x03!away\x04 观察者, \x03!diannao\x04 增加一个电脑,");
	PrintToChatAll("\x05[插件说明]\x03 !sinfo\x04 显示服务器人数信息, \x03!rhelp\x04 显示插件使用说明");
	PrintToChatAll("\x05[插件说明]\x03 !sp\x04 显示还在加载中的玩家列表, \x03!zs或者!kill\x04 自杀");
	//PrintToChatAll("\x05[插件说明]\x03 !kb\x04 踢除所有bot, \x03!sset\x04 设置服务器人数 \x03");
	return Plugin_Handled;
}

public Action Bindkeyhots(int client, int args)
{
	// 必须 cl_restrict_server_commands 0.
	ClientCommand(client, "bind q \"say_team /tp\"");
	ClientCommand(client, "bind g \"say_team /save\"");
	PrintToChat(client, "\x05[提醒:]\x04已绑定键盘\n\x03 Q \x04键为自动输入\x03!tp\x04传送\n\x03 G \x04键为自动输入\x03!save\x04存档");
	return Plugin_Handled;
}

public Action Gotoaway(int client, int argCount)
{
	if (AwayCEnable)
	{
		if (GetUserFlagBits(client))
		{
			ChangeClientTeam(client, 1);
		}
		PrintToChat(client, "\x05[失败:]\x04服务没有开启!away可请管理员修改l4d2_rmc.cfg");
	}
	ChangeClientTeam(client, 1);
}

public int Playernums()
{
	int numPlayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			numPlayers++;
		}
		i++;
	}
	return numPlayers;
}

public int Survivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 1))
		{
			numSurvivors++;
		}
		i++;
	}
	return numSurvivors;
}

public int AliveSurvivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (IsPlayerAlive(i))
			{
				numSurvivors++;
			}
		}
		i++;
	}
	return numSurvivors;
}

// 非管理员人数
public int Allplayersn()
{
	int numplayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !GetUserAdmin(i))
		{
			numplayers++;
		}
		i++;
	}
	return numplayers;
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

public int Alivebotnums()
{
	int AnumBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				AnumBots++;
			}
		}
		i++;
	}
	return AnumBots;
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

public Action Vserverinfo(int client, int args)
{
	PrintToChat(client, "\x05[提示]\x03 服务器包括电脑总人数 \x04[%i]\x03 非旁观活着的幸存者数量 \x04[%i]\x03 非电脑玩家数量 \x04[%i]\x03 观察者数量 \x04[%i]\x03 电脑总数量 \x04[%i]\x03 活着的电脑数量 \x04[%i]", Survivors(), AliveSurvivors(), Humannums(), Gonaways(), Botnums(), Alivebotnums());
	return Plugin_Handled;
}

public Action Rzhisha(int client, int args)
{
	if (IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Handled;
}

public Action RListLoadplayer(int client, int args)
{
	char RLPlist[64];
	int Rlnameall = 0;
	bool RloadplayerN = false;
	PrintToChatAll("\x05[提示]\x03 加载中的玩家列表...");
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				GetClientName(i, RLPlist, 64);
				Rlnameall++;
				PrintToChatAll("\x05[%i]\x04 %s \x01ID: %i", Rlnameall, RLPlist, i);
				RloadplayerN = true;
			}
		}
		i++;
	}
	if (!RloadplayerN)
	{
		PrintToChatAll("\x05       ------ 无 ------");
	}
	else
	{
		PrintToChatAll("\x05------\x04 %i \x05人还在加载中------", Rlnameall);
	}
	return Plugin_Handled;
}

public Action CreateOneBot(int client, int agrs)
{
	LCreateOneBot(client);
}

public int LCreateOneBot(int client)
{
	int playernum = 0;
	int specnum = 0;
	int botnum = 0;
	playernum = Playernums();
	specnum = Gonaways();
	botnum = Botnums();
	if (!KickEnable || botnum < specnum || playernum < 4)
	{
		int survivorbot = CreateFakeClient("survivor bot");
		ChangeClientTeam(survivorbot, 2);
		DispatchKeyValue(survivorbot, "classname", "SurvivorBot");
		DispatchSpawn(survivorbot);
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i)  && i != survivorbot && GetClientTeam(i) == 2)
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				GiveItems(survivorbot);
				TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
				// char name[MAX_NAME_LENGTH];
				// GetClientName(i, name, MAX_NAME_LENGTH);
				// PrintToChatAll("传送到%s", name);
				break;
			}
			i++;
		}
		CreateTimer(1.0, SurvivorKicker, survivorbot);
	}
	else
	{
		PrintCenterText(client, "\x05[提示]\x03 无需增加bot.");
		PrintToChat(client, "\x05[提示]\x03 无需增加bot.");
	}
}

public Action SurvivorKicker(Handle timer, any survivorbot)
{
	KickClient(survivorbot, "CreateOneBot...");
	PrintToChatAll("\x05[提示]\x01 BOT 创建完成,加入请按鼠标左键.");
}

public Action Event_rmcteam(Event event, char[] name, bool dontBroadcast)
{
	if (RAutoBotcheck)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client)
		{
			if (Rmc_ChangeTeam[client])  // 不是第一次加入游戏
			{
			}
			else
			{
				CreateTimer(0.5, JointeamRmc, client);
				Rmc_ChangeTeam[client] = 1;
			}
		}
	}
}

public Action JointeamRmc(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != 2)
		{
			int specnum = 0;
			int botnum = 0;
			specnum = Gonaways();
			botnum = Botnums();
			if (botnum <= specnum) LCreateOneBot(client);
			CreateTimer(1.5, FirstJoin, client);
		}
	}
}

public Action FirstJoin(Handle timer, any client)
{
	ClientCommand(client, "jointeam 2");
	ClientCommand(client, "go_away_from_keyboard");
}

public void GiveItems(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & -16385);
	FakeClientCommand(client, "give smg");
	FakeClientCommand(client, "give first_aid_kit");
	SetCommandFlags("give", flags | 16384);
}
