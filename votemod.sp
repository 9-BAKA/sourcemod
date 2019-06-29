#include <sourcemod>
#include <sdktools_functions>

int voteMode = 0, timeoutt = 0;
bool VoteInProgress = false;
Handle votepanel;
bool passvote;
bool Foujue;
int voteYES, voteNO, votenum;
bool vote_me[66];

public Plugin:myinfo =
{
	name = "投票更改服务器模式",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_votemod", Command_VoteCvar, "投票更改服务器模式");
	RegConsoleCmd("sm_gamemodevote", Command_VotemapsMenu, "投票更换游戏模式");
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
	SetMenuTitle(menu, "选择您要投票更改的服务器模式:");
	
	AddMenuItem(menu, "0", "游戏模式");
	AddMenuItem(menu, "1", "跳跃模式");
	AddMenuItem(menu, "2", "----敬请期待----", ITEMDRAW_DISABLED)

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
			switch (position)
			{
				case 0:
				{
					FakeClientCommand(client, "sm_gamemodevote");
				}
				case 1:
				{
					FakeClientCommand(client, "sm_votejp");
				}
				default:
				{
				}
			}
		}
		case MenuAction_Cancel:
		{
			FakeClientCommand(client, "sm_vote");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action Command_VotemapsMenu(int client, int args)
{
	Handle menu = CreateMenu(GameModeHandler);
	SetMenuTitle(menu, "选择您要投票更改的服务器模式:");
	
	AddMenuItem(menu, "0", "合作模式");
	AddMenuItem(menu, "1", "写实模式");
	AddMenuItem(menu, "2", "对抗模式");
	AddMenuItem(menu, "3", "生存模式");
	AddMenuItem(menu, "4", "清道夫模式");
	AddMenuItem(menu, "5", "----敬请期待----", ITEMDRAW_DISABLED)

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public GameModeHandler(Handle menu, MenuAction action, int client, int position) 
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
					Format(buffer, 255, " %s 想要将游戏模式变为合作模式:", iname);
					voteMode = 0;
				}
				case 1:
				{
					Format(buffer, 255, " %s 想要将游戏模式变为写实模式:", iname);
					voteMode = 1;
				}
				case 2:
				{
					Format(buffer, 255, " %s 想要将游戏模式变为对抗模式:", iname);
					voteMode = 2;
				}
				case 3:
				{
					Format(buffer, 255, " %s 想要将游戏模式变为生存模式:", iname);
					voteMode =3;
				}
				case 4:
				{
					Format(buffer, 255, " %s 想要将游戏模式变为清道夫模式:", iname);
					voteMode = 4;
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
					SendPanelToClient(votepanel, i, Handler_VoteCallback, 20);
				}
				i++;
			}
			CreateTimer(1.0, votetimeout, client, 1);
			PrintToChatAll("\x03%s \x01发起更改服务器模式的投票", iname);
			PrintToChatAll("\x03[提示] \x01该投票需要所有人同意");
			VoteInProgress = true;
			CloseHandle(votepanel);
		}
		case MenuAction_Cancel:
		{
			FakeClientCommand(client, "sm_votesmod");
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
	int atime = 20 - timeoutt;
	int playernum = HumanNum();
	if (!IsClientInGame(client))
	{
		PrintToChatAll("\x04[模式]\x03 投票发起人退出游戏,投票中止!");
		return Plugin_Stop;
	}
	if (Foujue == true)
	{
		PrintToChatAll("\x04[模式]\x03 投票服务器模式失败,被管理员强制否决.");
		Foujue = false;
		return Action:3;
	}
	if (votenum >= playernum)
	{
		if (voteNO == 0)
		{
			PrintToChatAll("\x03[模式] \x04投票通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[模式] \x04投票否决,需要所有人同意");
		}
		VoteMenuClose();
		return Action:4;
	}
	PrintHintTextToAll("你还有 %d 秒可以投票. \n同意: %d票 反对: %d票 已投票数 %d/%d", atime, voteYES, voteNO, votenum, playernum);
	if (timeoutt >= 20)
	{
		if (playernum != voteNO + voteYES)
		{
			voteNO = playernum - voteYES;
		}
		if (voteNO == 0)
		{
			PrintToChatAll("\x03[模式] \x04投票通过");
			PassVote();
		}
		else
		{
			PrintToChatAll("\x03[模式] \x04投票否决,需要所有人同意");
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
	PrintHintTextToAll("模式投票已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, playernum);
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
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
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
	switch (voteMode)
	{
		case 0:
		{
			ServerCommand("sm_cvar mp_gamemode coop");
		}
		case 1:
		{
			ServerCommand("sm_cvar mp_gamemode realism");
		}
		case 2:
		{
			ServerCommand("sm_cvar mp_gamemode versus");
		}
		case 3:
		{
			ServerCommand("sm_cvar mp_gamemode survival");
		}
		case 4:
		{
			ServerCommand("sm_cvar mp_gamemode teamscavenge");
		}
		default:
		{
		}
	}
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
		PrintToChat(client, "\x03[模式]\x01 当前没有可以否决的投票");
	}
	return Action:3;
}

public Action Command_Restore(int args)
{
	ServerCommand("sm_cvar mp_gamemode coop");
}
