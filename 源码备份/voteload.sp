#include <sourcemod>
#include <sdktools_functions>

float g_vecLastEntityAngles[66][3];
bool g_bSpawned[2048];
bool vote_me[66];
int PropsLoad;
int map_number;
int et_number;
int timeoutt;
int voteYES;
int voteNO;
int votenum;
int selected_map;

Handle hAutojumpmap;
Handle hVotejumpmap;
Handle votepanel;

bool sm_auto_enable;
bool sm_vote_enable;
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
	RegConsoleCmd("sm_votejp", VoteMap, "投票载入跳跃地图");

	hAutojumpmap = CreateConVar("auto_jumpmap_enable", "0", "是否开启服务器自动随机载入地图");
	sm_auto_enable = GetConVarBool(hAutojumpmap);
	hVotejumpmap = CreateConVar("vote_jumpmap_enable", "1", "是否允许服务器投票换跳跃地图");
	sm_vote_enable = GetConVarBool(hVotejumpmap);

	HookConVarChange(hAutojumpmap, ConVarChanged);
	HookConVarChange(hVotejumpmap, ConVarChanged);
	HookEvent("round_start", Event_RoundStart, EventHookMode:1);

	jumpon = false;
	LogMessage("重复初始化jumpon");
}

public void OnMapStart()
{
	char map[256];
	char FileNameS[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, FileNameS, 256, "data/maps/plugin_cache/%s", map);
	map_number = 0;
	map_number = GetNextMapNumber(FileNameS);
	VoteInProgress = false;
	timeoutt = 0;
	votenum = 0;
	if (map_number == 0)
	{
		if (jumpon)
		{
			offjump();
			jumpon = false;
		}
	}
	else if(sm_auto_enable){
		if (!jumpon)
		{	
			onjump();
			jumpon = true;
		}
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		PropsLoad = 0;
		CreateTimer(2.0, GetMapNumber, 0, 2);
	}
	else if (jumpon)
	{
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		PropsLoad = 0;
		offjump();
		jumpon = false;
	}
}

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	sm_auto_enable = GetConVarBool(hAutojumpmap);
	sm_vote_enable = GetConVarBool(hVotejumpmap);
}

public Event_RoundStart(Handle hEvent, char[] sEventName, bool bDontBroadcast)
{
	CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
	PropsLoad = 0;
	if (sm_auto_enable) CreateTimer(1.0, GetMapNumber, 0, 2);
	else if (jumpon) CreateTimer(1.0, LoadMap, 0, 2);
	return 0;
}

public Action GetMapNumber(Handle timer)
{
	char map[256];
	char FileNameS[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, FileNameS, 256, "data/maps/plugin_cache/%s", map);
	map_number = 0;
	map_number = GetNextMapNumber(FileNameS);
	// PrintToChatAll("\x03[跳跃] \x04当前地图数量：\x04%i", map_number);
	CreateTimer(1.0, SetPropsLoad, 0, 2);
	return Plugin_Continue;
}

public Action SetPropsLoad(Handle timer)
{
	if (PropsLoad)
	{
		if (PropsLoad == 1)
		{
			return Plugin_Stop;
		}
	}
	else
	{
		PropsLoad = 1;
		new RandomMapNum = GetRandomInt(1, map_number);
		LoadPluginProps(0, RandomMapNum);
		et_number = RandomMapNum;
		CreateTimer(2.0, LoadEt, 0, 2);
		PrintToChatAll("\x03[跳跃] \x04随机载入地图编号：\x03%i", RandomMapNum);
		CreateTimer(1.0, PropsLoadEnd, 0, 2);
	}
	return Plugin_Handled;
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
	offjump(); // 关闭随机跳跃地图
	jumpon = false;
	SetConVarInt(hAutojumpmap, 0);	
	PropsLoad = 0;
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
	ReplyToCommand(client, "\x03[SM] 成功载入地图，请按H查看跳跃指令");
	return 0;
}

GetNextMapNumber(String:FileName[])
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
	if (map_number == 0)
	{
		PrintToChat(client, "\x04[提示]\x01当前地图不支持跳跃模式");
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

	if (sm_auto_enable)
	{
		IntToString(map_number + 1, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "关闭随机");
	}
	else
	{
		IntToString(map_number + 1, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "开启随机");
	}

	if (jumpon)
	{
		IntToString(map_number + 2, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "关闭跳跃");
	}

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
			if (selected_map <= map_number)
			{
				PrintToChatAll("\x03%s\x04已发起投票更换地图为编号\x03 %i \x04的跳跃图", name, selected_map);
				ShowChangeMap(client);
			}
			else if (selected_map == map_number + 1)
			{
				if (sm_auto_enable) PrintToChatAll("\x03%s \x04已发起关闭随机换图的投票", name, selected_map);
				else PrintToChatAll("\x03%s \x04已发起开启随机换图的投票", name, selected_map);
				ShowChangeMap(client);
			}
			else
			{
				PrintToChatAll("\x03%s\x04已发起投票更换地图为编号\x03 %i \x04的跳跃图", name, selected_map);
				ShowChangeMap(client);
			}
		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "已放弃选择");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action ShowChangeMap(int client)
{	
	char text[128];
	char buffer[256];
	char iname[80];
	GetClientName(client, iname, 80);
	Format(buffer, 255, " %s 想要开启跳跃地图:", iname);  // 需要修改
	votepanel = CreatePanel();
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意（默认）");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对");
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
	CreateTimer(1.0, votetimeout, client, 1);
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
				// PrintToChatAll("\x03%s \x01投了赞成票.", iname);  // 不记名
			}
			if (param == 2)
			{
				voteNO = voteNO + 1;
				vote_me[client] = true;
				// PrintToChatAll("\x05%s \x01投了否决票.", iname);
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
	RefreshVotePanel(client);
	if (votenum >= playernum)
	{
		if (2 * voteYES > playernum)
		{
			PrintToChatAll("\x04[跳跃]\x03 投票获得通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[跳跃] \x04投票不通过,至少需要超过半数玩家同意,请尝试说服其它玩家");
		}
		VoteMenuClose();
		return Plugin_Stop;
	}
	if (timeoutt >= 10)
	{
		if (playernum != voteNO + voteYES)
		{
			voteYES = playernum - voteNO;
		}
		if (2 * voteYES > playernum)
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
	if (selected_map <= map_number)
	{
		onjump();
		jumpon = true;
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		CreateTimer(1.0, LoadMap, 0, 2);
	}
	else if (selected_map == map_number + 1)
	{
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		if (sm_auto_enable)
		{
			// offjump();
			// jumpon = false;
			SetConVarInt(hAutojumpmap, 0);
			PrintToChatAll("\x03[跳跃] \x04已关闭随机跳跃地图,将在下一关生效");
		}
		else
		{
			onjump();
			SetConVarInt(hAutojumpmap, 1);
			CreateTimer(1.0, SetPropsLoad, 0, 2);
			PrintToChatAll("\x03[跳跃] \x04已开启随机跳跃地图");
		}
	}
	else
	{
		CheatCommand(0, "ent_fire", "l4d2_spawn_props_prop KillHierarchy");
		offjump();
		jumpon = false;
		PropsLoad = 0;
		PrintToChatAll("\x03[跳跃] \x04已关闭当前地图的跳跃模式");
	}
}

public Action LoadMap(Handle timer)
{
	PropsLoad = 1;
	LoadPluginProps(0, selected_map);
	et_number = selected_map;
	CreateTimer(2.0, LoadEt, 0, 2);
	PrintToChatAll("\x03[跳跃] \x04载入地图编号：\x03%i", selected_map);
	CreateTimer(1.0, PropsLoadEnd, 0, 2);
	return Plugin_Continue;
}

public void RefreshVotePanel(int client)
{
	char text[128];
	char buffer[256];
	char iname[80];
	GetClientName(client, iname, 80);
	Format(buffer, 255, " %s 想要开启跳跃模式:", iname);
	votepanel = CreatePanel(Handle:0);
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意(默认)");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对");
	DrawPanelItem(votepanel, text, 0);
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && vote_me[i])
		{
			SendPanelToClient(votepanel, i, JpMenuVoteHandler, 1);
		}
		i++;
	}
	CloseHandle(votepanel);
}

public void VoteMenuClose()
{
	VoteInProgress = false;
	int playernum = HumanNum();
	PrintHintTextToAll("投票已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, playernum);
	voteYES = 0;
	voteNO = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		vote_me[i] = false;
		i++;
	}
	votenum = 0;
	playernum = 0;
	timeoutt = 0;
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
	SetConVarInt(FindConVar("sm_teleport_enable"), 1, false, false);
	SetConVarInt(FindConVar("sm_auto_respawn"), 1, false, false);
	SetConVarInt(FindConVar("sm_health_enable"), 1, false, false);
	SetConVarInt(FindConVar("sm_tpall_enable"), 1, false, false);
}

public void offjump()
{
	SetConVarInt(FindConVar("sm_teleport_enable"), 0, false, false);
	SetConVarInt(FindConVar("sm_auto_respawn"), 0, false, false);
	SetConVarInt(FindConVar("sm_health_enable"), 0, false, false);
	SetConVarInt(FindConVar("sm_tpall_enable"), 0, false, false);
}
