#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>
#include <sdkhooks>

float g_vecLastEntityAngles[66][3];
bool g_bSpawned[2048];
bool vote_me[66];
int map_number;
int et_number;
int timeoutt;
int voteYES;
int voteNO;
int votenum;
int selected_map;
int PropsLoad;

Handle hVotejumpmap;
Handle hJumpmod;
Handle votepanel;
Handle g_hTimer_Voter;

bool sm_vote_enable;
int sm_jumpmod;
bool VoteInProgress;
bool jumpon;

public Plugin:myinfo =
{
	name = "跳跃地图载入",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_jpload", CmdLoad, ADMFLAG_ROOT, "载入指定跳跃地图", "", 0);
	RegAdminCmd("sm_jpinfo", CmdInfo, ADMFLAG_ROOT, "当前跳跃地图信息", "", 0);
	RegAdminCmd("sm_offjp", CmdOff, ADMFLAG_ROOT, "关闭当前跳跃", "", 0);
	RegAdminCmd("sm_offif", CmdOffIf, ADMFLAG_ROOT, "关闭僵尸生成", "", 0);
	RegAdminCmd("sm_onif", CmdOnIf, ADMFLAG_ROOT, "开启僵尸生成", "", 0);
	// RegAdminCmd("sm_cheat", CmdCheat, ADMFLAG_ROOT, "作弊指令", "", 0);
	RegConsoleCmd("sm_votejp", VoteMap, "投票载入跳跃地图");

	hVotejumpmap = CreateConVar("vote_jumpmap_enable", "1", "是否允许服务器投票换跳跃地图");
	sm_vote_enable = GetConVarBool(hVotejumpmap);
	hJumpmod = CreateConVar("sm_jumpmod", "0", "服务器跳跃状态");  // 0:关闭,1:地图编号,-1:随机,-2:参数
	sm_jumpmod = GetConVarInt(hJumpmod);

	HookConVarChange(hVotejumpmap, ConVarChanged);
	HookConVarChange(hJumpmod, ConVarChanged);
	// HookEvent("round_start", Event_RoundStart, EventHookMode:1);

	jumpon = false;
	LogMessage("初始化jumpon");
}

public void OnMapStart()
{
	char map[256];
	char FileNameS[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, FileNameS, 256, "data/maps/plugin_cache/%s", map);
	map_number = GetMapNumber(FileNameS);
	VoteInProgress = false;
	PropsLoad = 0;
	timeoutt = 0;
	votenum = 0;
	CreateTimer(1.0, CheckJumpMod, 0, 2);
}

public Event_RoundStart(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	PropsLoad = 0;
	CreateTimer(1.0, CheckJumpMod, 0, 2);
}

public Event_RoundEnd(Handle:hEvent, String:sEventName[], bool:bDontBroadcast)
{
	CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	return 0;
}

public Action CheckJumpMod(Handle timer)
{
	if (PropsLoad)
	{
		return;
	}
	if(sm_jumpmod == -2)  // 仅传送参数模式
	{
		onjump(); // 开启参数
	}
	else if(sm_jumpmod == 0)
	{
		offjump(); // 如果当前跳跃状态开启，则关闭跳跃功能
	}
	else if (map_number == 0)  // 没有地图
	{
		offjump();
		PrintToChatAll("\x03[提示]\x04当前地图暂无跳跃地图，指令暂时关闭");
	}
	else if(sm_jumpmod == -1)  // 如果当前是随机地图状态
	{
		onjump();
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		CreateTimer(2.0, RandomLoad, 0, 2);
	}
	else  // 如果指定地图
	{
		onjump();
		if(map_number < sm_jumpmod)
		{
			PrintToChatAll("\x03[提示]\x04当前地图跳跃地图数量不足，随机选定一张");
			// PrintToServer("\x03[提示]\x04当前地图跳跃地图数量不足，随机选定一张");
			CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
			CreateTimer(1.0, RandomLoad, 0, 2);
		}
		else
		{
			CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
			CreateTimer(1.0, LoadMap, sm_jumpmod, 2);
		}
	}
}

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	sm_vote_enable = GetConVarBool(hVotejumpmap);
	sm_jumpmod = GetConVarInt(hJumpmod);
}

public Action RandomLoad(Handle timer)
{
	PropsLoad = 1;
	new RandomMapNum = GetRandomInt(1, map_number);
	LoadPluginProps(0, RandomMapNum);
	et_number = RandomMapNum;
	CreateTimer(2.0, LoadEt, 0, 2);
	PrintToChatAll("\x03[跳跃] \x04随机载入地图编号：\x03%i", RandomMapNum);
	CreateTimer(1.0, PropsLoadEnd, 0, 2);
	return Plugin_Continue;
}

public Action LoadMap(Handle timer, int map_num)
{
	PropsLoad = 1;
	LoadPluginProps(0, map_num);
	et_number = map_num;
	CreateTimer(2.0, LoadEt, 0, 2);
	PrintToChatAll("\x03[跳跃] \x04载入地图编号：\x03%i", map_num);
	CreateTimer(1.0, PropsLoadEnd, 0, 2);
	return Plugin_Continue;
}

public Action PropsLoadEnd(Handle timer)
{
	PrintToChatAll("\x03[跳跃] \x04实体数据载入完成！");
	return Plugin_Continue;
}

public Action CmdLoad(int client, int args)
{
	if (args < 1)
	{
		PrintToChat(client, "\x03[跳跃] \x04请输入正确的编号!");
		return Action:0;
	}
	char arg[8];
	GetCmdArgString(arg, 5);
	new number = StringToInt(arg, 10);
	et_number = StringToInt(arg, 10);
	LoadPluginProps(client, number);
	CreateTimer(2.0, LoadEt, 0, 2);
	return Plugin_Continue;
}

public Action CmdInfo(int client, int args)
{	
	PrintToChat(client, "\x03[跳跃] \x04当前地图编号为：\x03%i", et_number);
	return Plugin_Continue;
}

public Action CmdOff(int client, int args)
{
	CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	PropsLoad = 0;
	offjump(); // 关闭跳跃地图
	return Plugin_Continue;
}

public Action LoadEt(Handle timer)
{
	ServerCommand("sm_etload %i", et_number);
	return Plugin_Continue;
}

LoadPluginProps(int client, int number)
{
	ReplyToCommand(client, "\x04[SM] 正在载入地图文件");
	new Handle:keyvalues;
	char KvFileName[256];
	char map[256];
	char name[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, KvFileName, 256, "data/maps/plugin_cache/%s_%i.txt", map, number);
	if (!FileExists(KvFileName, false))
	{
		ReplyToCommand(client, "\x04[SM] 地图文件不存在");
		return 0;
	}
	keyvalues = CreateKeyValues("Objects_Cache", "", "");
	FileToKeyValues(keyvalues, KvFileName);
	KvRewind(keyvalues);
	if (KvJumpToKey(keyvalues, "total_cache", false))
	{
		new max = KvGetNum(keyvalues, "total", 0);
		if (0 >= max)
		{
			ReplyToCommand(client, "\x04[SM] 没有在这个地图文件里找到实体");
			return 0;
		}
		char model[256];
		char class[64];
		float vecOrigin[3];
		float vecAngles[3];
		new solid;
		KvRewind(keyvalues);
		new count = 1;
		while (count <= max)
		{
			Format(name, 256, "object_%i", count);
			if (KvJumpToKey(keyvalues, name, false))
			{
				solid = KvGetNum(keyvalues, "solid", 0);
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetVector(keyvalues, "angles", vecAngles);
				KvGetString(keyvalues, "model", model, 256, "");
				KvGetString(keyvalues, "classname", class, 64, "");
				new prop = -1;
				KvRewind(keyvalues);
				if (0 <= StrContains(class, "prop_physics", true))
				{
					prop = CreateEntityByName("prop_physics_override", -1);
				}
				else
				{
					prop = CreateEntityByName("prop_dynamic_override", -1);
					SetEntProp(prop, Prop_Send, "m_nSolidType", solid, 4, 0);
				}
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "targetname", "l4d2_spawn_props_prop");
				g_vecLastEntityAngles[client][0] = vecAngles[0];
				g_vecLastEntityAngles[client][1] = vecAngles[1];
				g_vecLastEntityAngles[client][2] = vecAngles[2];
				DispatchKeyValueVector(prop, "angles", vecAngles);
				DispatchSpawn(prop);
				TeleportEntity(prop, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				g_bSpawned[prop] = true;
				count++;
			}
		}
	}
	CloseHandle(keyvalues);
	PrintToChatAll("\x03[SM] 成功载入地图，请按H查看跳跃指令");
	return 0;
}

GetMapNumber(String:FileName[])
{
	char FileNameS[256];
	new i = 1;
	while (i <= 20)
	{
		Format(FileNameS, 256, "%s_%i.txt", FileName, i);
		if (!(FileExists(FileNameS, false)))
		{
			return i - 1;
		}
		i++;
	}
	return -1;
}

CheatCommand(client, char[] command, char[] arguments)
{
	if (!client || !IsClientInGame(client))
	{
		new target = 1;
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

public Action CmdCheat(int client, int args)
{
	char command[100];
	char arg[20];
	if (args < 1)
	{
		PrintToChat(client, "\x04请输入正确参数");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		GetCmdArg(1, arg, sizeof(arg));
		Format(command, sizeof(command), "%s", arg);
	}
	else
	{
		GetCmdArg(1, arg, sizeof(arg));
		Format(command, sizeof(command), "%s", arg);
		for(int i=2; i<=args; i++)
		{
			GetCmdArg(i, arg, sizeof(arg));
			Format(command, sizeof(command), "%s %s", command, arg);
		}
		
	}
	PrintToChatAll("%s", command);
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, FCVAR_CHEAT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
	return Plugin_Continue;
}

// 投票发起人检查
public Action VoteMap(int client, int agrs)
{
	if (!sm_vote_enable)
	{
		PrintToChat(client, "服务器暂时不允许投票开启跳跃")
		return Plugin_Handled;
	}

	if (client == 0) 
	{
		return Plugin_Handled;
	}
	if (VoteInProgress)
	{
		PrintToChat(client, "\x04[提示]\x01有正在进行中的投票,无法发起新的投票");
		return Plugin_Handled;
	}

	SelectMapMenu(client);

	return Plugin_Continue;
}

public Action SelectMapMenu(int client)
{
	if (client == 0) 
	{
		return;
	}
	
	char sMenuEntry[8];
	
	Handle menu = CreateMenu(SelectMapMenuHandle);
	SetMenuTitle(menu, "跳跃地图:");
	
	for (int i = 1; i <= map_number; i++)
	{
		IntToString(i, sMenuEntry, sizeof(sMenuEntry));
		char num[21];
		Format(num, 20, "地图编号 %i", i);
		AddMenuItem(menu, sMenuEntry, num);
	}

	IntToString(map_number + 1, sMenuEntry, sizeof(sMenuEntry));
	AddMenuItem(menu, sMenuEntry, "随机地图");

	if (sm_jumpmod > 0 || sm_jumpmod == -1)
	{
		IntToString(map_number + 2, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "关闭跳跃模式");
	}
	else if (sm_jumpmod == -2)
	{
		IntToString(map_number + 3, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "关闭传送参数");
	}
	else if (sm_jumpmod == 0)
	{
		IntToString(map_number + 3, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "仅开启传送参数");
	}

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// 选择是否开启跳跃以及更换地图的菜单
public SelectMapMenuHandle(Handle menu, MenuAction action, int client, int position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{

			char info[4];
			GetMenuItem(menu, position, info, sizeof(info));
			char name[80];
			GetClientName(client, name, 80);
			
			selected_map = StringToInt(info, 10);
			if(selected_map <= map_number)
			{
				PrintToChatAll("\x03%s \x04已发起投票更换地图为编号\x03 %i \x04的跳跃地图", name, selected_map);
				ShowChangeMap(client, selected_map);
			}
			else if(selected_map == map_number + 1)
			{
				PrintToChatAll("\x03%s \x04已发起开启随机地图的投票", name, selected_map);
				ShowChangeMap(client, selected_map);
			}
			else if(selected_map == map_number + 2)
			{
				PrintToChatAll("\x03%s\x04已发起投票关闭跳跃模式", name);
				ShowChangeMap(client, selected_map);
			}
			else if(selected_map == map_number + 3)
			{
				if(sm_jumpmod == -2)
				{
					PrintToChatAll("\x03%s\x04已发起投票关闭传送参数", name);
					ShowChangeMap(client, selected_map);
				}
				else
				{
					PrintToChatAll("\x03%s\x04已发起投票开启传送参数", name);
					ShowChangeMap(client, selected_map);
				}
			}
		}
		case MenuAction_Cancel:
		{
			FakeClientCommand(client, "sm_votemod");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action ShowChangeMap(int client, int slot)
{
	char text[128];
	char buffer[256];
	char iname[80];
	GetClientName(client, iname, 80);
	if(slot <= map_number) Format(buffer, 256, "%s 想要更换编号为 %i 的跳跃地图:", iname, selected_map);
	else if(slot == map_number + 1) Format(buffer, 256, "%s 想要更换随机跳跃地图:", iname);
	else if(slot == map_number + 2) Format(buffer, 256, "%s 想要关闭跳跃模式:", iname);
	else if(slot == map_number + 3){
		if(jumpon) Format(buffer, 256, "%s 想要关闭传送参数:", iname);
		else Format(buffer, 256, "%s 想要开启传送参数:", iname);
	}
	votepanel = CreatePanel(Handle:0);
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对(默认)");
	DrawPanelItem(votepanel, text, 0);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SendPanelToClient(votepanel, i, JpMenuVoteHandler, 10);
		}
		i++;
	}
	g_hTimer_Voter = CreateTimer(1.0, votetimeout, client, 1);
	PrintToChatAll("\x03%s \x01发起跳跃模式的投票", iname);
	VoteInProgress = true;
	CloseHandle(votepanel);
	return Plugin_Continue;
}

public JpMenuVoteHandler(Handle menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		if (VoteInProgress == true && !vote_me[client])
		{
			char iname[80];
			GetClientName(client, iname, 80);
			if (param == 1)
			{
				voteYES = voteYES + 1;
				vote_me[client] = true;
				PrintToChatAll("\x03%s \x01投了赞成票.", iname);
			}
			if (param == 2)
			{
				voteNO = voteNO + 1;
				vote_me[client] = true;
				PrintToChatAll("\x05%s \x01投了否决票.", iname);
			}
		}
	}
	return 0;
}

public Action votetimeout(Handle Timer, int client)
{
	timeoutt = timeoutt + 1;
	votenum = voteNO + voteYES;
	int atime = 10 - timeoutt;
	int playernum = HumanNum();
	if (!IsClientInGame(client))
	{
		PrintToChatAll("投票发起人退出游戏,投票中止!");
		VoteMenuClose();
		return Plugin_Stop;
	}
	PrintHintTextToAll("跳跃模式投票:你还有 %d 秒可以投票. \n同意: %d票 反对: %d票 已投票数 %d/%d", atime, voteYES, voteNO, votenum, playernum);
	if (timeoutt >= 10)
	{
		if (playernum != voteNO + voteYES)
		{
			voteNO = playernum - voteYES;
		}
		if (voteYES > voteNO)
		{
			PrintToChatAll("\x03[跳跃] \x04投票获得通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[跳跃] \x04投票不通过,至少需要超过半数玩家同意,请尝试说服其它玩家");
		}
		VoteMenuClose();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void PassVote()
{
	if(selected_map <= map_number)  // 编号选择
	{
		onjump();
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		SetConVarInt(hJumpmod, selected_map);
		PrintToChatAll("\x03[跳跃] \x04选择编号 %i 的跳跃地图", selected_map);
		CreateTimer(1.0, LoadMap, selected_map, 2);
	}
	else if(selected_map == map_number + 1)  // 随机地图
	{
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		CreateTimer(1.0, RandomLoad, 0, 2);
		SetConVarInt(hJumpmod, -1);
		onjump();
		PrintToChatAll("\x03[跳跃] \x04选择随机跳跃地图");
	}
	else if(selected_map == map_number + 2)  // 关闭
	{
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		SetConVarInt(hJumpmod, 0);
		offjump();
		PrintToChatAll("\x03[跳跃] \x04已关闭跳跃模式");
	}
	else if(selected_map == map_number + 3)  // 传送参数
	{
		if(jumpon)
		{
			SetConVarInt(hJumpmod, 0);
			offjump();
			PrintToChatAll("\x03[跳跃] \x04已关闭传送参数");
		}
		else
		{
			SetConVarInt(hJumpmod, -2);
			onjump();
			SetConVarInt(FindConVar("sm_auto_respawn"), 2, false, false);
			PrintToChatAll("\x03[跳跃] \x04已开启传送参数");
		}
	}
}

public void VoteMenuClose()
{
	PrintHintTextToAll("投票已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, HumanNum());
	VoteInProgress = false;
	voteYES = 0;
	voteNO = 0;
	votenum = 0;
	timeoutt = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		vote_me[i] = false;
		i++;
	}
	KillTimer(g_hTimer_Voter);
}

public int HumanNum()
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

public void onjump()
{
	if(!jumpon)
	{
		SetConVarInt(FindConVar("sm_teleport_enable"), 1, false, false);
		SetConVarInt(FindConVar("sm_auto_respawn"), 1, false, false);
		SetConVarInt(FindConVar("sm_health_enable"), 1, false, false);
		SetConVarInt(FindConVar("sm_tpall_enable"), 1, false, false);
		SetConVarInt(FindConVar("l4d_bunnyhop_mode"), 1, false, false);

		ServerCommand("sm_offif");
		jumpon = true;
	}
}

public void offjump()
{
	if(jumpon)
	{
		SetConVarInt(FindConVar("sm_teleport_enable"), 0, false, false);
		SetConVarInt(FindConVar("sm_auto_respawn"), 0, false, false);
		SetConVarInt(FindConVar("sm_health_enable"), 0, false, false);
		SetConVarInt(FindConVar("sm_tpall_enable"), 0, false, false);
		SetConVarInt(FindConVar("l4d_bunnyhop_mode"), 0, false, false);

		ServerCommand("sm_onif");
		jumpon = false;
	}
}

public Action CmdOnIf(int client, int args)
{
	ResetConVar(FindConVar("director_no_bosses"), false, false);
	ResetConVar(FindConVar("director_no_mobs"), false, false);
	ResetConVar(FindConVar("z_common_limit"), false, false);
	ResetConVar(FindConVar("z_boomer_limit"), false, false);
	ResetConVar(FindConVar("z_charger_limit"), false, false);
	ResetConVar(FindConVar("z_hunter_limit"), false, false);
	ResetConVar(FindConVar("z_jockey_limit"), false, false);
	ResetConVar(FindConVar("z_smoker_limit"), false, false);
	ResetConVar(FindConVar("z_spitter_limit"), false, false); 
	PrintToServer("恢复生成僵尸");
	PrintToChatAll("恢复生成僵尸");
}

public Action CmdOffIf(int client, int args)
{
	ServerCommand("sm_off14");
	CreateTimer(0.1, DelayOffSI);
	return Plugin_Continue;
}

public Action DelayOffSI(Handle timer, int client)
{
	SetConVarInt(FindConVar("director_no_bosses"), 1, false, false);
	SetConVarInt(FindConVar("director_no_mobs"), 1, false, false);
	SetConVarInt(FindConVar("z_common_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_boomer_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_charger_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_jockey_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_smoker_limit"), 0, false, false);
	SetConVarInt(FindConVar("z_spitter_limit"), 0, false, false); 
	int i = 1
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				ForcePlayerSuicide(i);
			}
		}
		i++;
	}
	CheatCommand(0, "ent_remove_all", "infected");
	//CheatCommand(0, "director_stop", "");
	PrintToServer("停止生成僵尸");
	PrintToChatAll("停止生成僵尸");
}
