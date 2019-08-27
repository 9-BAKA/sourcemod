#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define MaxHealth 100
#define VOTE_NO "no"
#define VOTE_YES "yes"
#define L4D_MAXCLIENTS_PLUS1 (MaxClients+1)
new Votey = 0;
new Voten = 0;
//new String:ReadyMode[64];
//new String:Label[16];//ready 开启/关闭
//new String:VotensReady_ED[32];
new String:VotensHp_ED[32];
new String:VotensMap_ED[32];
new String:EN_name_total[1000][64];
new String:CHI_name_total[1000][64];
new String:EN_name[20][500][64];
new String:CHI_name[20][500][64];
new String:kickplayer[MAX_NAME_LENGTH];
new String:kickplayername[MAX_NAME_LENGTH];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;

//new Handle:g_Cvar_Limits;
//new Handle:cvarFullResetOnEmpty;
//new Handle:VotensReadyED;
new Handle:VotensHpED;
new Handle:VotensMapED;
new Handle:VotensED;
new Handle:NeedAdmin;
new Float:lastDisconnectTime;
new bool:Foujue;
 
enum voteType
{
	//ready,
	hp,
	map,
	kicks,

}

new voteType:g_voteType = voteType;
public Plugin:myinfo =
{
	name = "投票插件核心",
	author = "fenghf",
	description = "Votes Commands",
	version = "1.2.2a",
	url = "http://bbs.3dmgame.com/l4d"
}

public OnPluginStart()
{
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	//RegAdminCmd("sm_voter", Command_Vote, ADMFLAG_KICK|ADMFLAG_VOTE|ADMFLAG_GENERIC|ADMFLAG_BAN|ADMFLAG_CHANGEMAP, "投票开启ready插件");
	//RegConsoleCmd("votesready", Command_Voter, "投票准备");
	RegConsoleCmd("voteshp", Command_VoteHp, "投票回血");
	RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu, "投票换图");
	RegConsoleCmd("sm_mapvote", Command_VotemapsMenu, "投票换图");
	RegConsoleCmd("voteskick", Command_Voteskick, "投票踢人");
	RegConsoleCmd("sm_votes", Command_Votes, "打开投票菜单");
	RegConsoleCmd("sm_vote", Command_Votes, "打开投票菜单");
	RegAdminCmd("sm_vote_no", Command_VotesNo, ADMFLAG_ROOT, "管理员一键否决投票");

	VotensHpED = CreateConVar("l4d_VotenshpED", "1", " 启用、关闭 投票回血功能", FCVAR_NOTIFY);
	VotensMapED = CreateConVar("l4d_VotensmapED", "1", " 启用、关闭 投票换图功能", FCVAR_NOTIFY);
	VotensED = CreateConVar("l4d_Votens", "1", " 启用、关闭 插件", FCVAR_NOTIFY);
	NeedAdmin = CreateConVar("l4d_maprefresh_admin", "1", " 是否需要管理员权限才能刷新地图缓存", FCVAR_NOTIFY);

	LoadMapFile();

	AutoExecConfig(true, "votes2lite", "sourcemod");
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
			total++;
			catalogInt = StringToInt(catalog, 10);
			if (catalogInt)
			{
				KvGetString(hFile, "中文名", CHI_name[catalogInt][pos[catalogInt]], 64, "");
				KvGetString(hFile, "建图代码", EN_name[catalogInt][pos[catalogInt]], 64, "");
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

public OnClientPutInServer(client)
{
	CreateTimer(30.0, TimerAnnounce, client);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client, "\x04[\x03提示\x04]\x05 输入\x03 !vote \x04进行投票回血及更换三方地图.");
}
public Action:Command_Votes(client, args) 
{ 
	if(GetConVarInt(VotensED) == 1)
	{
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		if(VotensHpE_D == 0)
		{
			VotensHp_ED = "开启";
		}
		else if(VotensHpE_D == 1)
		{
			VotensHp_ED = "禁用";
		}
		
		if(VotensMapE_D == 0)
		{
			VotensMap_ED = "开启";
		}
		else if(VotensMapE_D == 1)
		{
			VotensMap_ED = "禁用";
		}
		new Handle:menu = CreatePanel();
		new String:Value[64];
		SetPanelTitle(menu, "投票菜单");
		if (VotensHpE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票回血");
		}
		else if (VotensHpE_D == 1)
		{
			DrawPanelItem(menu, "投票回血");
		}
		if (VotensMapE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票换图");
		}
		else if (VotensMapE_D == 1)
		{
			DrawPanelItem(menu, "投票换图");
		}
		DrawPanelItem(menu, "投票踢人");//常用,不添加开启关闭
		DrawPanelItem(menu, "模式投票");//投票更改模式
		DrawPanelItem(menu, "参数投票");//投票更改参数
		if (GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS)
		{
			DrawPanelText(menu, "管理员选项");
			Format(Value, sizeof(Value), "%s 投票回血", VotensHp_ED);
			DrawPanelItem(menu, Value);
			Format(Value, sizeof(Value), "%s 投票换图", VotensMap_ED);
			DrawPanelItem(menu, Value);
		}
		DrawPanelText(menu, " \n");
		DrawPanelItem(menu, "关闭");
		//SetMenuExitButton(menu, true);
		SendPanelToClient(menu, client,Votes_Menu, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0)
	{}
	return Plugin_Stop;
}
public Votes_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		switch (itemNum)
		{
			case 1: 
			{
				if (VotensHpE_D == 0)
				{
					FakeClientCommand(client,"sm_votes");
					PrintToChat(client, "[提示] 禁用投票回血");
					return;
				}
				else if (VotensHpE_D == 1)
				{
					FakeClientCommand(client,"voteshp");
				}
			}
			case 2: 
			{
				if (VotensMapE_D == 0)
				{
					FakeClientCommand(client,"sm_votes");
					PrintToChat(client, "[提示] 禁用投票换图");
					return ;
				}
				else if (VotensMapE_D == 1)
				{
					FakeClientCommand(client,"votesmapsmenu");
				}
			}
			case 3: 
			{
				FakeClientCommand(client,"voteskick");
			}
			case 4: 
			{
				FakeClientCommand(client,"sm_votemod");
			}
			case 5: 
			{
				FakeClientCommand(client,"sm_votecvar");
			}
			case 6: 
			{
				if (VotensHpE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票回血");
				}
				else if (VotensHpE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票回血");
				}
			}
			case 7: 
			{
				if (VotensMapE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票换图");
				}
				else if (VotensMapE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票换图");
				}
			}
		}
	}
}

public Action:Command_VoteHp(client, args)
{
	if(GetConVarInt(VotensED) == 1 
	&& GetConVarInt(VotensHpED) == 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[提示] 已有投票在进行中");
			return Plugin_Handled;
		}
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		PrintToChatAll("\x05[提示] \x04 %N \x03发起投票回血",client);
		
		g_voteType = voteType:hp;
		decl String:SteamId[35];
		GetClientName(client, SteamId, sizeof(SteamId));
		LogMessage("%N &s发起投票所有人回血!",  client, SteamId);//记录在log文件
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "是否所有人回血?");
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
		return Plugin_Handled;	
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensHpED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票回血");
	}
	return Plugin_Handled;
}

public Action:Command_Voteskick(client, args)
{
	if(client!=0) CreateVotekickMenu(client);		
	return Plugin_Handled;
}

CreateVotekickMenu(client)
{	
	new Handle:menu = CreateMenu(Menu_Voteskick);		
	new String:name[MAX_NAME_LENGTH];
	new String:playerid[32];
	PrintToChat(client, "警告！恶意踢人将导致被服务器封禁！");
	SetMenuTitle(menu, "选择踢出玩家");
	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(i, playerid, sizeof(playerid));
			if(GetClientName(i, name, sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);						
			}
		}		
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public Menu_Voteskick(Handle:menu, MenuAction:action, client, position)
{
	if (action == MenuAction_Select)
	{
		char info[32], name[32], steam_id[32], steam_id2[32];
		char file[PLATFORM_MAX_PATH];
		GetMenuItem(menu, position, info, sizeof(info), _, name, sizeof(name));
		kickplayer = info;
		kickplayername = name;
		GetClientAuthId(client, AuthId_Steam2, steam_id, 32);
		GetClientAuthId(StringToInt(kickplayer), AuthId_Steam2, steam_id2, 32);
		PrintToChatAll("\x05[提示] \x04%N 发起投票踢出 \x05 %s", client, kickplayername);
		BuildPath(Path_SM, file, sizeof(file), "logs/kickplayer.log");
		LogToFileEx(file, "%N (%s) 发起投票踢出 %s (%s)", client, steam_id, kickplayername, steam_id2);
		DisplayVoteKickMenu(client);
	}
}

public DisplayVoteKickMenu(client)
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
	g_voteType = voteType:kicks;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "是否踢出玩家 %s",kickplayername);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}

public Action:Command_VotemapsMenu(client, args)
{
	if(GetConVarInt(VotensED) == 1 && GetConVarInt(VotensMapED) == 1)
	{
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		new Handle:menu = CreateMenu(CatalogChoosed);
	
		SetMenuTitle(menu, "请选择地图类别");
		AddMenuItem(menu, "-1", "刷新地图缓存");
		AddMenuItem(menu, "-2", "刷新地图列表");
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

		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensMapED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票换图");
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
				if (!StrEqual("", CHI_name_total[catalog][i], true))
				{
					char displayName[256];
					FindMapResult findmap = FindMap(EN_name_total[i], displayName, 256);
					if(findmap == FindMap_Found)
					{
						AddMenuItem(mapmenu, EN_name_total[i], CHI_name_total[i]);
					}
					else
					{
						AddMenuItem(mapmenu, EN_name_total[i], CHI_name_total[i], ITEMDRAW_DISABLED);
					}
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
					char displayName[256];
					FindMapResult findmap = FindMap(EN_name[catalog][i], displayName, 256);
					if(findmap == FindMap_Found)
					{
						AddMenuItem(mapmenu, EN_name[catalog][i], CHI_name[catalog][i]);
					}
					else
					{
						AddMenuItem(mapmenu, EN_name[catalog][i], CHI_name[catalog][i], ITEMDRAW_DISABLED);
					}
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
	if (action == MenuAction_Cancel)
	{
		FakeClientCommand(client, "sm_votes");
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
		PrintToChatAll("\x05[提示] \x04%N 发起投票换图 \x05 %s", client, votesmapsname);
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
	g_voteType = voteType:map;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "发起投票换图 %s %s",votesmapsname, votesmaps);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}
public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
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
	decl String:item[64], String:display[64];
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
			PrintToChatAll("\x04[投票]\x03 投票服务器参数失败,被管理员强制否决.");
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
			switch (g_voteType)
			{
				case (voteType:hp):
				{
					AnyHp();
					LogMessage("投票 所有玩家回血 ready通过");
				}
				case (voteType:map):
				{
					CreateTimer(5.0, Changelevel_Map);
					PrintToChatAll("\x03[提示] \x04 5秒后换图 \x05%s",votesmapsname);
					PrintToChatAll("\x04 %s",votesmaps);
					LogMessage("投票换图 %s %s 通过",votesmapsname,votesmaps);
				}
				case (voteType:kicks):
				{
					PrintToChatAll("\x05[提示] \x04投票踢出 \x05%s", kickplayername);
					LogMessage("投票踢出%s 通过",kickplayername);
					if (GetUserFlagBits(StringToInt(kickplayer)))
					{
						char name[MAX_NAME_LENGTH];
						GetClientName(StringToInt(kickplayer), name, sizeof(name));
						PrintToChatAll("\x05[警告] \x04无法投票踢出管理员 \05%s\x04!", name);
					}
					else
					{
						ServerCommand("sm_ban %s 5 投票踢出", kickplayername);
					}
				}
			}
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

//====================================================
public AnyHp()
{
	PrintToChatAll("\x03[提示]\x04所有玩家回血");
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FakeClientCommand(i, "give health");
			SetEntityHealth(i, MaxHealth);
			//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03回血",i);
		}
		else
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) 
		{
			new class = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (class == ZOMBIECLASS_SMOKER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Smoker回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_BOOMER)
			{
				SetEntityHealth(i, 50);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Boomer回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_HUNTER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Hunter回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
            if (class == ZOMBIECLASS_SPITTER)
			{
				SetEntityHealth(i, 100);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Spitter 回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_JOCKEY)
			{
				decl String:game_name[64];
				GetGameFolderName(game_name, sizeof(game_name));
				if (!StrEqual(game_name, "left4dead2", false))
				{
					SetEntityHealth(i, 6000);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank 回血",i);//请勿使用提示,否则知道有那些特感
				}
				else
				{
					SetEntityHealth(i, 325);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Jockey回血",i);//请勿使用提示,否则知道有那些特感
				}
			}
			else
			if (class == ZOMBIECLASS_CHARGER)
			{
				SetEntityHealth(i, 600);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Charger回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_TANK)
			{
				SetEntityHealth(i, 6000);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank回血",i);//请勿使用提示,否则知道有那些特感
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
//================================
CheckVotes()
{
	PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", Votey, Voten);
}
public Action:VoteEndDelay(Handle:timer)
{
	Votey = 0;
	Voten = 0;
}
public Action:Changelevel_Map(Handle:timer)
{
	ServerCommand("changelevel %s", votesmaps);
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
//=======================================
public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) return;

	new Float:currenttime = GetGameTime();
	
	if (lastDisconnectTime == currenttime) return;
	
	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}
	
	return  Plugin_Stop;
}
