#include <sourcemod>
#include <sdktools_functions>

bool server_hibernating = true;
int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;

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
	RegConsoleCmd("sm_votecvar", VoteCvar, "投票更改服务器参数");
}

public void SetVal(int CvarMode)
{
	switch(CvarMode)
	{
		case 1: // 关闭黑枪
		{

		}
		case 2: // 关闭
		{

		}

	}
}

CheatCommand(int client, char[] command, char[] arguments)
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


public Action ShowSelectMenu(int client, timeT)
{
	if (client == 0) 
	{
		return;
	}

	string sMenuEntry[8];
	g_RevivePos[client] = 1;
	
	new Handle:menu = CreateMenu(SelectMenu);
	SetMenuTitle(menu, "选择您要投票更改的服务器参数:");
	
	AddMenuItem(menu, "0", "黑枪(当前%s)", );
	AddMenuItem(menu, "1", "传送(当前%s)", );
	AddMenuItem(menu, "2", "回血(当前%s)", );
	AddMenuItem(menu, "3", "复活(当前%s)", );

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, timeT);
}

public SelectMenu(Handle menu, MenuAction action, int client, int position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char text[32];
			char buffer[256];
			char iname[80];
			GetClientName(client, iname, 80);
			Format(buffer, 255, " %s 想要%s%s:", iname, status, cvarname);
			votepanel = CreatePanel(Handle:0);
			SetPanelTitle(votepanel, buffer, false);
			Format(text, 32, "同意");
			DrawPanelItem(votepanel, text, 0);
			Format(text, 32, "反对(默认)");
			DrawPanelItem(votepanel, text, 0);
			int i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					SendPanelToClient(votepanel, i, TpMenuVoteHandler, 10);
				}
				i++;
			}
			CreateTimer(1.0, votetimeout, client, 1);
			PrintToChatAll("\x03%s \x01发起%s%s的投票.", iname, status, cvarname);
			VoteInProgress = true;
			CloseHandle(votepanel);
		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "取消选择");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}



