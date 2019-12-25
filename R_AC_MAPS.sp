#include <sourcemod>
#include <sdktools>

new Handle:R_Def_Maps;
new Handle:hRACMKvS;
new String:RACMKvS[128];
new Handle:hR_ACMHint;
new bool:R_ACMHint;
new Handle:hR_ACMDelay;
new Float:R_ACMDelay;
new String:R_Next_Maps[64];
new String:R_Next_Name[64];
new String:EN_name_total[1000][64];
new String:CHI_name_total[1000][64];
new String:EN_name[20][500][64];
new String:CHI_name[20][500][64];
new bool:Map_exist_total[1000];
new bool:Map_exist[20][500];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:NeedAdmin;
new bool:Foujue;
new bool:VotedMap = false;

#define VOTE_NO "no"
#define VOTE_YES "yes"
new Votey = 0;
new Voten = 0;

new bool:FirstStart = false;
new Handle:RestartTimer;
new timeoutt = 0;

public Plugin:myinfo =
{
	name = "L4D2自动换图及投票下一张图",
	description = "L4D2 auto change Maps",
	author = "Ryanx",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_votenext", Command_VotenextmapsMenu, "投票换图");
	RegConsoleCmd("sm_getnext", Command_Getnextmap, "下张图信息");

	CreateConVar("R_ACM_Version", "L4D2自动换图1.0-by望夜", "L4D2自动换图1.0-by望夜", 8512, false, 0.0, false, 0.0);
	R_Def_Maps = CreateConVar("R_ACM_Def_Map", "c2m1_highway", "不在列表时默认换的地图.", 0, false, 0.0, false, 0.0);
	hR_ACMHint = CreateConVar("R_ACM_Hint", "1", "自动换图时是否公告[0=关|1=开]", 0, true, 0.0, true, 1.0);
	hR_ACMDelay = CreateConVar("R_ACM_delay", "30.0", "自动换图延时几秒(PS:太长游戏就退到主菜单了).", 0, true, 5.0, true, 300.0);
	NeedAdmin = CreateConVar("l4d_maprefresh_admin", "1", " 是否需要管理员权限才能刷新地图缓存", FCVAR_NOTIFY);

	R_ACMHint = GetConVarBool(hR_ACMHint);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);

	LoadMapFile()

	HookEvent("finale_win", RACMEvent_FinaleWin, EventHookMode:2);
	HookEvent("player_activate", RACMEvent_activate, EventHookMode:1);
	hRACMKvS = CreateKeyValues("R_Auto_Change_Maps", "", "");

	AutoExecConfig(true, "R_AC_MAPS", "sourcemod");
}

LoadMapFile()
{
	new Handle:hFile = OpenConfig();
	decl String:sTemp[5];
	new String:catalog[3];
	new catalogInt;
	new i = 0;
	new total = 0;
	new pos[20];
	while (i < 1000)
	{
		IntToString(i, sTemp, 8);
		if (KvJumpToKey(hFile, sTemp, false))
		{
			KvGetString(hFile, "中文名", CHI_name_total[total], 64, "");
			KvGetString(hFile, "建图代码", EN_name_total[total], 64, "");
			KvGetString(hFile, "类别", catalog, 10, "");
			char displayName[256];
			FindMapResult findmap = FindMap(EN_name_total[total], displayName, 256);
			if (findmap == FindMap_Found) Map_exist_total[total] = true;
			else Map_exist_total[total] = false;
			total++;
			catalogInt = StringToInt(catalog, 10);
			if (catalogInt)
			{
				KvGetString(hFile, "中文名", CHI_name[catalogInt][pos[catalogInt]], 64, "");
				KvGetString(hFile, "建图代码", EN_name[catalogInt][pos[catalogInt]], 64, "");
				if (findmap == FindMap_Found) Map_exist[catalogInt][pos[catalogInt]] = true;
				else Map_exist[catalogInt][pos[catalogInt]] = false;
				pos[catalogInt]++;
			}
			TrimString(sTemp);
			if (strlen(sTemp))
			{
				KvRewind(hFile);
			}
			else
			{
				break;
			}
		}
		i++;
	}
	CloseHandle(hFile);
}

Handle:OpenConfig()
{
	decl String:sPath[256];
	BuildPath(PathType:0, sPath, 256, "%s", "data/l4d2_abbw_map.txt");
	if (!FileExists(sPath, false, "GAME"))
	{
		SetFailState("找不到文件 data/l4d2_abbw_map.txt");
	}
	else
	{
		PrintToServer("[笨蛋海绵提示] 文件数据 data/l4d2_abbw_map.txt 加载成功");
	}
	new Handle:hFile = CreateKeyValues("第三方图数据 -by 笨蛋海绵", "", "");
	if (!FileToKeyValues(hFile, sPath))
	{
		CloseHandle(hFile);
		SetFailState("无法载入 data/l4d2_abbw_map.txt'");
	}
	return hFile;
}

public OnMapStart()
{
	VotedMap = false;
	RACMLoad();
	if (strcmp(R_Next_Maps, "none", true)  == 0)
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	R_ACMHint = GetConVarBool(hR_ACMHint);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);

	if (FirstStart){
		PrintToServer("开始60秒重启倒计时");
		RestartTimer = CreateTimer(1.0, RestartAnnounce, _, TIMER_REPEAT);
		FirstStart = false;
	}
	timeoutt = 0;
}

public Action:RestartAnnounce(Handle:timer)
{
	timeoutt = timeoutt + 1;
	if (timeoutt <= 60){
		PrintHintTextToAll("初始关卡重启倒计时:还有 %d 秒.", 60 - timeoutt);
	}
	else{
		KillTimer(RestartTimer);
		timeoutt = 0;
		ServerCommand("sm_cvar mp_restartgame 1");
		PrintToChatAll("\x03[提示] \x04关卡已重启!");
	}
}

public RACMEvent_activate(Handle:event, String:name[], bool:dontBroadcast)
{
	if (R_ACMHint)
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (Client && !IsFakeClient(Client))
		{
			if (strcmp(R_Next_Maps, "none", true))
			{
				CreateTimer(5.0, RACSHints, Client, 0);
			}
		}
	}
	return 0;
}

public Action:RACSHints(Handle:timer, any:client)
{
	// PrintToChat(client, "\x04[ACM]\x03 已是最后一个章节");
	// PrintToChat(client, "\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
	PrintToChat(client, "\x04[ACM]\x03 请输入 \x04!votenext \x03投票选出下一张图", R_Next_Name);
	return Action:0;
}

public Action:RACMEvent_FinaleWin(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!VotedMap)
	{
		RACMLoad();
	}
	if (strcmp(R_Next_Maps, "none", true) == 0)
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	if (R_ACMHint)
	{
		new String:ACMHdelayS[12];
		FloatToString(R_ACMDelay, ACMHdelayS, 12);
		new ACMHdelayT = StringToInt(ACMHdelayS, 10);
		PrintToChatAll("\x04[ACM]\x03 已完成本战役");
		PrintToChatAll("\x04[ACM]\x03 %d秒后将自动换图", ACMHdelayT);
	}
	VotedMap = false;
	CreateTimer(3.0, RACMaps, any:0, 0);
	return Action:0;
}

CACMKV(Handle:kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle, true))
	{
		do {
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		} while (KvGotoFirstSubKey(kvhandle, true));
		KvRewind(kvhandle);
	}
	return 0;
}

public Action:RACMaps(Handle:timer)
{
	if (R_ACMHint)
	{
		PrintToChatAll("\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
		PrintToChatAll("\x01%s", R_Next_Maps);
	}
	CreateTimer(R_ACMDelay - 3.0, RACMapsN, any:0, 0);
	return Action:0;
}

public Action:Command_Getnextmap(client, args)
{
	if (!VotedMap)
	{
		RACMLoad();
	}
	if (strcmp(R_Next_Maps, "none", true) == 0)
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	PrintToChatAll("\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
	PrintToChatAll("\x01%s", R_Next_Maps);
	return Plugin_Handled;
}

public Action:RACMapsN(Handle:timer)
{
	FirstStart = true;
	ServerCommand("changelevel %s", R_Next_Maps);
	return Action:0;
}

RACMLoad()
{
	CACMKV(hRACMKvS);
	BuildPath(PathType:0, RACMKvS, 128, "data/R_AC_MAPS.txt");
	if (!FileToKeyValues(hRACMKvS, RACMKvS))
	{
		PrintToChatAll("\x04[!出错!]\x01 无法读取data/R_AC_MAPS.txt");
	}
	new String:nrcurrent_map[64];
	GetCurrentMap(nrcurrent_map, 64);
	KvRewind(hRACMKvS);
	if (KvJumpToKey(hRACMKvS, nrcurrent_map, false))
	{
		KvGetString(hRACMKvS, "R_ACM_Next_Maps", R_Next_Maps, 64, "none");
		KvGetString(hRACMKvS, "R_ACM_Next_Name", R_Next_Name, 64, "none");
	}
	else
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	KvRewind(hRACMKvS);
	return 0;
}

public Action:Command_VotenextmapsMenu(client, args)
{
	if (args == 0)
	{
		new Handle:menu = CreateMenu(CatalogChoosed);
		
		SetMenuTitle(menu, "请选择地图类别");
		AddMenuItem(menu, "-1", "刷新地图缓存");
		AddMenuItem(menu, "-2", "刷新地图列表");
		AddMenuItem(menu, "19", "每周地图");
		AddMenuItem(menu, "18", "旧本周地图");
		AddMenuItem(menu, "17", "金秋限时活动");
		AddMenuItem(menu, "16", "近期新增");
		AddMenuItem(menu, "0", "所有");
		AddMenuItem(menu, "15", "所有-评分降序");
		AddMenuItem(menu, "1", "坑爹图");
		AddMenuItem(menu, "2", "风景图");
		AddMenuItem(menu, "3", "训练图");
		AddMenuItem(menu, "14", "寂静岭");
		AddMenuItem(menu, "13", "清明节");
		AddMenuItem(menu, "12", "新地图");
		AddMenuItem(menu, "11", "12月30日新地图");
		AddMenuItem(menu, "10", "12月21日新地图");
		AddMenuItem(menu, "9", "12月14日新地图");
		AddMenuItem(menu, "8", "12月07日新地图");
		AddMenuItem(menu, "7", "11月30日新地图");
		AddMenuItem(menu, "6", "11月23日新地图");
		AddMenuItem(menu, "5", "万圣节推荐");
		AddMenuItem(menu, "4", "新图");

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (args == 1)
	{
		GetCmdArg(1, R_Next_Name, sizeof(R_Next_Name));
		GetCmdArg(1, R_Next_Maps, sizeof(R_Next_Maps));
		PrintToChatAll("\x03[提示] \x04 下张地变为 \x05%s", R_Next_Name);
		PrintToChatAll("\x04 %s", R_Next_Maps);
	}
	else if (args == 2)
	{
		VotedMap = true;
		char text[256];
		GetCmdArgString(text, sizeof(text));

		int pos = BreakString(text, R_Next_Name, sizeof(R_Next_Name));
		BreakString(text[pos], R_Next_Maps, sizeof(R_Next_Maps));

		PrintToChatAll("\x03[提示] \x04 下张地变为 \x05%s", R_Next_Name);
		PrintToChatAll("\x04 %s", R_Next_Maps);
	}

	return Plugin_Handled;
}

public CatalogChoosed(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		new String:info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new catalog = StringToInt(info, 10);
		if (catalog == -1)
		{
			if (!GetConVarBool(NeedAdmin) || GetUserFlagBits(client))
			{
				ServerCommand("update_addon_paths;mission_reload");
				PrintToChat(client, "地图缓存已刷新");
				FakeClientCommand(client, "sm_mapvote");
			}
			else
			{
				ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
				FakeClientCommand(client, "sm_mapvote");
			}
			return;
		}
		if (catalog == -2)
		{
			LoadMapFile();
			PrintToChat(client, "地图列表已刷新");
			return;
		}
		new Handle:mapmenu = CreateMenu(MapMenuHandler);
		new i = 0;
		if (catalog == 0)
		{
			while (i < 1000)
			{
				if (!StrEqual("", CHI_name_total[i], true))
				{
					if(Map_exist_total[i])
						AddMenuItem(mapmenu, EN_name_total[i], CHI_name_total[i]);
					else
						AddMenuItem(mapmenu, EN_name_total[i], CHI_name_total[i], ITEMDRAW_DISABLED);
				}
				else
				{
					break;
				}
				i++;
			}
		}
		else
		{
			while (i < 500)
			{
				if (!StrEqual("", CHI_name[catalog][i], true))
				{
					if(Map_exist[catalog][i])
						AddMenuItem(mapmenu, EN_name[catalog][i], CHI_name[catalog][i]);
					else
						AddMenuItem(mapmenu, EN_name[catalog][i], CHI_name[catalog][i], ITEMDRAW_DISABLED);
				}
				else
				{
					break;
				}
				i++;
			}
		}
		SetMenuExitBackButton(mapmenu, true);
		SetMenuExitButton(mapmenu, true);
		DisplayMenu(mapmenu, client, MENU_TIME_FOREVER);
	}
}


public MapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
		votesmaps = info;
		votesmapsname = name;
		PrintToChatAll("\x05[提示] \x04%N 想要将下一张图更换为 \x05 %s", client, votesmapsname);
		DisplayVoteMapsMenu(client);		
	}
	if (action == MenuAction_Cancel)
	{
		FakeClientCommand(client, "votesmapsmenu");
	}
}

public DisplayVoteMapsMenu(client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[提示] 已有投票正在进行中");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "发起投票将下一张图更换为 %s %s",votesmapsname, votesmaps);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	//==========================
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0: 
			{
				Votey += 1;
				// PrintToChatAll("\x03[匿名] \x05投票了.", param1);
				PrintToChatAll("\x03%N \x05投票了.", param1);  // 不记名
			}
			case 1: 
			{
				Voten += 1;
				PrintToChatAll("\x03%N \x04投票了.", param1);
			}
		}
	}
	//==========================
	decl String:item[64], String:display[64];
	// new Float:percent, Float:limit;
	new votes, totalVotes;

	GetMenuVoteInfo(param2, votes, totalVotes);
	GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
	
	if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
	{
		votes = totalVotes - votes;
	}

	int playernum = HumanNum();
	
	CheckVotes();
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[提示] 没有票数");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		if (Foujue)
		{
			PrintToChatAll("\x04[投票]\x03 投票下一张图失败,被管理员强制否决.");
			Foujue = false;
		}
		else if ((strcmp(item, VOTE_YES) == 0 && votes * 2 <= playernum && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("[提示] 投票否决,至少需要超过半数人同意");
			CreateTimer(2.0, VoteEndDelay);
		}
		else
		{
			PrintToChatAll("[提示] 投票通过");
			CreateTimer(2.0, VoteEndDelay);
			VotedMap = true;
			R_Next_Maps = votesmaps;
			R_Next_Name = votesmapsname;
			PrintToChatAll("\x03[提示] \x04 下张地变为 \x05%s", votesmapsname);
			PrintToChatAll("\x04 %s", votesmaps);
			LogMessage("投票下张图 %s %s 通过", votesmapsname, votesmaps);
		}
	}
	return 0;
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

CheckVotes()
{
	PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", Votey, Voten);
}
public Action:VoteEndDelay(Handle:timer)
{
	Votey = 0;
	Voten = 0;
}

//===============================
VoteMenuClose()
{
	Votey = 0;
	Voten = 0;
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}

public Action Command_VotesNo(int client, int args)
{
	if (IsVoteInProgress())
	{
		Foujue = true;
	}
	else
	{
		PrintToChat(client, "\x03[参数]\x01 当前没有可以否决的投票");
	}
	return Action:3;
}

bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			PrintToChat(client, "[提示] 必须等待 %i 分后才可发起投票", delay % 60);
 		}
 		else
 		{
 			PrintToChat(client, "[提示] 必须等待 %i 秒后才可发起投票", delay);
 		}
 		return false;
 	}
	return true;
}
