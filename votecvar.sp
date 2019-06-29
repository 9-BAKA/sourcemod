#include <sourcemod>
#include <sdktools_functions>

int FF = 1, TP = 0, HP = 0, FH = 0;
int voteType = 0, timeoutt = 0;
bool VoteInProgress = false;
Handle votepanel;
bool passvote;
bool Foujue;
int voteYES, voteNO, votenum;
bool vote_me[66];

public Plugin:myinfo =
{
	name = "投票更改服务器参数",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_votecvar", Command_VoteCvar, "投票更改服务器参数");
	RegServerCmd("sm_restore", Command_Restore, "恢复默认值");
	RegAdminCmd("sm_vote_no", Command_VotesNo, ADMFLAG_ROOT, "管理员一键否决投票");
}

public Action Command_VoteCvar(int client, int args)
{
	if(client!=0) CreateVoteCvarMenu(client);		
	return Plugin_Handled;
}

public Action CreateVoteCvarMenu(int client)
{
	Handle menu = CreateMenu(SelectMenuHandler);
	SetMenuTitle(menu, "选择您要投票更改的服务器参数:");
	
	AddMenuItem(menu, "0", "恢复默认");
	if (FF == 1) AddMenuItem(menu, "1", "[当前开启] 黑枪");
	else AddMenuItem(menu, "1", "[当前关闭] 黑枪");
	if (TP == 1) AddMenuItem(menu, "2", "[当前开启] 传送");
	else AddMenuItem(menu, "2", "[当前关闭] 传送");
	if (HP == 1) AddMenuItem(menu, "3", "[当前开启] 回血");
	else AddMenuItem(menu, "3", "[当前关闭] 回血");
	if (FH == 1) AddMenuItem(menu, "4", "[当前开启] 复活");
	else AddMenuItem(menu, "4", "[当前关闭] 复活");
	AddMenuItem(menu, "5", "----敬请期待----", ITEMDRAW_DISABLED)

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SelectMenuHandler(Handle menu, MenuAction action, int client, int position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			if (VoteInProgress)
			{
				PrintToChat(client, "\x04[提示]\x01 有正在进行中的投票,无法发起新的投票");
				return;
			}
			char text[32];
			char buffer[256];
			char iname[80];
			GetClientName(client, iname, 80);
			switch (position)
			{
				case 0:
				{
					Format(buffer, 255, " %s 想要将参数恢复默认:", iname);
					voteType = 0;
				}
				case 1:
				{
					if (FF == 1) Format(buffer, 255, " %s 想要关闭黑枪:", iname);
					else Format(buffer, 255, " %s 想要开启黑枪:", iname);
					voteType = 1;
				}
				case 2:
				{
					if (TP == 1) Format(buffer, 255, " %s 想要关闭传送:", iname);
					else Format(buffer, 255, " %s 想要开启传送:", iname);
					voteType = 2;
				}
				case 3:
				{
					if (HP == 1) Format(buffer, 255, " %s 想要关闭回血:", iname);
					else Format(buffer, 255, " %s 想要开启回血:", iname);
					voteType =3;
				}
				case 4:
				{
					if (FH == 1) Format(buffer, 255, " %s 想要关闭复活:", iname);
					else Format(buffer, 255, " %s 想要开启复活:", iname);
					voteType = 4;
				}
				default:
				{
				}
			}
			
			votepanel = CreatePanel(Handle:0);
			SetPanelTitle(votepanel, buffer, false);
			Format(text, 32, "同意");
			DrawPanelItem(votepanel, text, 0);
			Format(text, 32, "反对");
			DrawPanelItem(votepanel, text, 0);
			int i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					SendPanelToClient(votepanel, i, Handler_VoteCallback, 10);
				}
				i++;
			}
			CreateTimer(1.0, votetimeout, client, 1);
			PrintToChatAll("\x03%s \x01发起更改服务器参数的投票", iname);
			PrintToChatAll("\x03[提示] \x01该投票需要所有人同意");
			VoteInProgress = true;
			CloseHandle(votepanel);
		}
		case MenuAction_Cancel:
		{
			FakeClientCommand(client, "sm_votes");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		if (VoteInProgress == true && !vote_me[client])
		{
			new String:iname[80];
			GetClientName(client, iname, 80);
			// Format(iname, 80, "[匿名]");
			if (param == 1)
			{
				voteYES = voteYES + 1;
				vote_me[client] = true;
				PrintToChatAll("\x05%s \x01投了赞成票.", iname);
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
		PrintToChatAll("\x04[参数]\x03 投票发起人退出游戏,投票中止!");
		return Plugin_Stop;
	}
	if (Foujue == true)
	{
		PrintToChatAll("\x04[参数]\x03 投票服务器参数失败,被管理员强制否决.");
		Foujue = false;
		return Action:3;
	}
	if (votenum >= playernum)
	{
		if (voteNO == 0)
		{
			PrintToChatAll("\x03[参数] \x04投票通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[参数] \x04投票否决,需要所有人同意");
		}
		VoteMenuClose();
		return Action:4;
	}
	PrintHintTextToAll("你还有 %d 秒可以投票. \n同意: %d票 反对: %d票 已投票数 %d/%d", atime, voteYES, voteNO, votenum, playernum);
	if (timeoutt >= 10)
	{
		if (playernum != voteNO + voteYES)
		{
			voteNO = playernum - voteYES;
		}
		if (voteNO == 0)
		{
			PrintToChatAll("\x03[参数] \x04投票通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[参数] \x04投票否决,需要所有人同意");
		}
		VoteMenuClose();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int VoteMenuClose()
{
	VoteInProgress = false;
	int playernum = HumanNum();
	PrintHintTextToAll("参数投票已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, playernum);
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

public void PassVote()
{
	switch (voteType)
	{
		case 0:
		{
			SetDF();
		}
		case 1:
		{
			SetFF();
		}
		case 2:
		{
			SetTP();
		}
		case 3:
		{
			SetHP();
		}
		case 4:
		{
			SetFH();
		}
		default:
		{
		}
	}
}
public SetDF()
{
	ServerCommand("sm_restore");
}

public SetFF()
{
	if (FF == 1)
	{
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.0, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.0, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.0, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.0, false, false);
		FF = 0;
		PrintToChatAll("队友伤害已关闭");
	}
	else
	{
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.0, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.3, false, false);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.5, false, false);
		FF = 1;
		PrintToChatAll("队友伤害已开启");
	}
	return 0;
}

public SetTP()
{
	if (TP == 1)
	{
		SetConVarInt(FindConVar("sm_teleport_enable"), 0, false, false);
		SetConVarInt(FindConVar("sm_tpall_enable"), 0, false, false);
		TP = 0;
		PrintToChatAll("传送指令已关闭");
	}
	else
	{
		SetConVarInt(FindConVar("sm_teleport_enable"), 1, false, false);
		SetConVarInt(FindConVar("sm_tpall_enable"), 1, false, false);
		TP = 1;
		PrintToChatAll("传送指令已开启");
	}
	return 0;
}

public SetHP()
{
	if (HP == 1)
	{
		SetConVarInt(FindConVar("sm_health_enable"), 0, false, false);
		HP = 0;
		PrintToChatAll("回血指令已关闭");
	}
	else
	{
		SetConVarInt(FindConVar("sm_health_enable"), 1, false, false);
		HP = 1;
		PrintToChatAll("回血指令已开启");
	}
	return 0;
}

public SetFH()
{
	if (FH == 1)
	{
		SetConVarInt(FindConVar("sm_auto_respawn"), 2, false, false);
		FH = 0;
		PrintToChatAll("自动复活已关闭");
	}
	else
	{
		SetConVarInt(FindConVar("sm_auto_respawn"), 0, false, false);
		FH = 1;
		PrintToChatAll("自动复活已开启");
	}
	return 0;
}

public Action Command_VotesNo(int client, int args)
{
	if (passvote == true)
	{
		Foujue = true;
		passvote = false;
	}
	else
	{
		PrintToChat(client, "\x03[参数]\x01 当前没有可以否决的投票");
	}
	return Action:3;
}

public Action Command_Restore(int args)
{
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.0, false, false);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1, false, false);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.3, false, false);
	SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.5, false, false);
	SetConVarInt(FindConVar("sm_teleport_enable"), 0, false, false);
	SetConVarInt(FindConVar("sm_tpall_enable"), 0, false, false);
	SetConVarInt(FindConVar("sm_health_enable"), 0, false, false);
	SetConVarInt(FindConVar("sm_auto_respawn"), 0, false, false);
	FF = 1;
	TP = HP = FH = 0;
}
