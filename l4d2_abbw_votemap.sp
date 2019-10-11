#include <sourcemod>
#include <sdktools>

new bool:Foujue;
new bool:Nowvote;
new bool:passvote;
new voteYES;
new voteNO;
new String:EN_name[64][64];  //改这个就行 例：EN_name[200][64]
new String:CHI_name[64][64];  //一起改
new String:CHI_name_Get[56];
new String:EN_name_Get[56];
new Handle:abbw_map_limit;
new votenum;
new timeoutt;
new playernum;
new Handle:votepanel;
new bool:vote_me[66];
public Plugin:myinfo =
{
	name = "投票换第三方图",
	description = "投票换第三方图，三方图从data/l4d2_abbw_map.txt加载",
	author = "笨蛋海绵",
	version = "5.0.0",
	url = "QQ群：133102253"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_mapvote", check, "投票换非官图 -by 笨蛋海绵", 0);
	RegAdminCmd("sm_vote_no", votefail, 4, "管理员一键否决投票 -by 笨蛋海绵", "", 0);
	abbw_map_limit = CreateConVar("abbw_map_limit", "200", "设置你要显示几张三方图数量，可以填大点，只会显示当前有的地图数量", 0, false, 0.0, false, 0.0);
	AutoExecConfig(true, "l4d2_abbw_mapvote", "sourcemod");
	new i;
	new Handle:hFile = OpenConfig();
	decl String:sTemp[64];
	i = 0;
	while (i < 64)
	{
		IntToString(i + 1, sTemp, 8);
		if (KvJumpToKey(hFile, sTemp, false))
		{
			KvGetString(hFile, "中文名", CHI_name[i], 64, "");
			KvGetString(hFile, "建图代码", EN_name[i], 64, "");
			TrimString(sTemp);
			if (strlen(sTemp))
			{
				KvRewind(hFile);
			}
			CloseHandle(hFile);
		}
		i++;
	}
	CloseHandle(hFile);
}

public OnMapStart()
{
	Foujue = false;
	passvote = false;
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

public Action:check(client, args)
{
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x03[非官图] \x01只有幸存者才允许投票换非官图.");
		return Action:3;
	}
	map_vote(client, args);
	return Action:3;
}

public Action:map_vote(client, args)
{
	new Handle:menu = CreateMenu(ModeMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "地图切换");
	AddMenuItem(menu, "option1", "帮助说明", 0);
	new map_limit = GetConVarInt(abbw_map_limit);
	new i;
	while (i < map_limit)
	{
		if (!StrEqual("", CHI_name[i], true))
		{
			AddMenuItem(menu, EN_name[i], CHI_name[i], 0);
		}
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
	return Action:0;
}

public ModeMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		switch (itemNum)
		{
			case 0:
			{
				PrintToChat(client, "\x03[非官图] \x01如果发现无法按下5,6,7,8,9,0键,请在控制台输入 \n\x05bind 5 slot5; bind 6 slot6; bind 7 slot7; bind 8 slot8; bind 9 slot9; bind 0 slot10");
				PrintToChat(client, "如果某玩家没有该第三方图，将会断开游戏");
				return 0;
			}
			default:
			{
				new String:info[32];
				new String:name[32];
				GetMenuItem(menu, itemNum, info, 32, _, name, 32);
				MapMenuVote(client);
			}
		}
	}
	return 0;
}

public Action:MapMenuVote(client)
{
	if (Nowvote == true)
	{
		ReplyToCommand(client, "\x01[投票] \x04已有投票在进行中");
		return Action:4;
	}
	new String:text[128];
	decl String:buffer[256];
	new String:iname[80];
	GetClientName(client, iname, 80);
	Format(buffer, 255, " %s 发起更换第三方地图: %s", iname, CHI_name_Get);
	votepanel = CreatePanel(Handle:0);
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意(确认我自己有这张图)");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对(我不清楚有没有地图)");
	DrawPanelItem(votepanel, text, 0);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			playernum = playernum + 1;
			SendPanelToClient(votepanel, i, MapMenuVoteHandler, 1);
		}
		i++;
	}
	CreateTimer(1.0, votetimeout, client, 1);
	PrintToChatAll("\x03 %s \x01发起更换第三方地图: \x04%s \x01的投票", iname, CHI_name_Get);
	Nowvote = true;
	CloseHandle(votepanel);
	return Action:3;
}

public Action:votetimeout(Handle:Timer, any:client)
{
	timeoutt = timeoutt + 1;
	votenum = voteNO + voteYES;
	new atime = 25 - timeoutt;
	new i = 1;
	while (i <= MaxClients)
	{
		if (vote_me[i])
		{
		}
		else
		{
			RefreshVotePanel(client);
		}
		i++;
	}
	PrintHintTextToAll("换第三方地图投票:你还有 %d 秒可以投票. \n同意: %d票 反对: %d票 已投票数 %d/%d", atime, voteYES, voteNO, votenum, playernum);
	if (votenum >= playernum)
	{
		if (voteYES > voteNO)
		{
			passvote = true;
			CreateTimer(7.0, mapchanger, any:0, 0);
			PrintToChatAll("\x03[非官图]\x01 投票获得通过，服务器将于\x05 6秒 \x01后更换地图");
		}
		else
		{
			PrintToChatAll("\x03[非官图]\x01 投票不通过,请尝试说服其它玩家");
		}
		VoteMenuClose();
		return Action:4;
	}
	if (timeoutt >= 25)
	{
		if (playernum != voteNO + voteYES)
		{
			voteNO = playernum - voteNO + voteYES + voteNO;
		}
		if (voteYES > voteNO)
		{
			passvote = true;
			CreateTimer(7.0, mapchanger, any:0, 0);
			PrintToChatAll("\x03[非官图]\x01 投票获得通过，服务器将于\x05 6秒 \x01后更换地图");
		}
		else
		{
			PrintToChatAll("\x03[非官图]\x01 投票不通过,请尝试说服其它玩家");
		}
		VoteMenuClose();
		return Action:4;
	}
	return Action:0;
}

public RefreshVotePanel(client)
{
	new String:text[128];
	decl String:buffer[256];
	new String:iname[80];
	GetClientName(client, iname, 80);
	Format(buffer, 255, " %s 发起更换第三方地图: %s", iname, CHI_name_Get);
	votepanel = CreatePanel(Handle:0);
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意(确认我自己有这张图)");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对(我不清楚有没有地图)");
	DrawPanelItem(votepanel, text, 0);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && vote_me[i])
		{
			SendPanelToClient(votepanel, i, MapMenuVoteHandler, 1);
		}
		i++;
	}
	CloseHandle(votepanel);
	return 0;
}

public Action:votefail(client, args)
{
	if (passvote == true)
	{
		Foujue = true;
		PrintToChatAll("\x03[非官图]\x01 管理员强制否决当前投票换第三方图.");
		passvote = false;
		return Action:3;
	}
	PrintToChat(client, "\x03[非官图]\x01 当前没有可以否决的投票");
	return Action:3;
}

public Action:mapchanger(Handle:timer)
{
	if (Foujue == true)
	{
		PrintToChatAll("\x03[非官图]\x01 投票第三方图失败,被管理员强制否决.");
		Foujue = false;
		return Action:3;
	}
	ServerCommand("changelevel %s", EN_name_Get);
	return Action:3;
}

public MapMenuVoteHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction:4)
	{
		if (Nowvote == true && vote_me[client])
		{
			if (param == 1)
			{
				voteYES = voteYES + 1;
				vote_me[client] = true;
				PrintToChatAll("\x03 %N \x01投了赞成票.", client);
			}
			if (param == 2)
			{
				voteNO = voteNO + 1;
				vote_me[client] = true;
				PrintToChatAll("\x05 %N \x01投了否决票.", client);
			}
		}
	}
	return 0;
}

VoteMenuClose()
{
	Nowvote = false;
	PrintHintTextToAll("投票第三方图已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, playernum);
	voteYES = 0;
	voteNO = 0;
	new i = 1;
	while (i <= MaxClients)
	{
		vote_me[i] = false;
		i++;
	}
	votenum = 0;
	playernum = 0;
	timeoutt = 0;
	return 0;
}

 