#include <sourcemod>
#include <sdktools>

new Int:Entered[MAXPLAYERS+1];
new TotalEntered;
new FirstEnter;
new TpAllEnable;
new sm_TpAllEnable;
new bool:VoteInProgress;
new timeoutt;
new bool:passvote;  // 为管理员强制否决准备
new bool:Foujue;
new voteYES;
new voteNO;
new votenum;
new bool:vote_me[66];
new Handle:votepanel;
new Float:g_LocationSlots[3];
new Handle:hTpallEnable;

public Plugin:myinfo = 
{
	name = "传送所有人",
	author = "BAKA",
	description = "到达安全门以及需要所有人开机关的地方允许传送所有人",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_tpall", TeleportAll, "传送所有队友到身边");
	RegAdminCmd("sm_vote_no", votefail, 4, "管理员一键否决投票", "", 0);
	RegConsoleCmd("sm_get", Get, "获取当前地点");

	hTpallEnable = CreateConVar("sm_tpall_enable", "0", "是否只允许tpall指令", FCVAR_NOTIFY);

	HookEvent("waiting_checkpoint_button_used", Botton);
	HookEvent("success_checkpoint_button_used", BottonUsed);
	HookEvent("player_use", Door);  // 与进入checkpoint共同作用
	HookEvent("player_entered_checkpoint", Check);
	HookEvent("player_activate", Event_activate_R);
	HookConVarChange(hTpallEnable, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	sm_TpAllEnable = GetConVarBool(hTpallEnable);
}

public Action:Get(client, agrs)
{
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);
	PrintToChatAll("位置：%.2f %.2f %.2f", loc[0], loc[1], loc[2]);
	PrintToChatAll("安全屋位置：%.2f %.2f %.2f", g_LocationSlots[0], g_LocationSlots[1], g_LocationSlots[2]);
}

public Action:Event_activate_R(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (Client && !IsFakeClient(Client))
	{
		CreateTimer(2.0, JointhemageR, Client, 0);
	}
	return Plugin_Continue;
}

public Action:JointhemageR(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_LocationSlots[0] == 0.0)  // 保存默认初始位置
		{
			GetClientAbsOrigin(client, g_LocationSlots);
			// PrintToChatAll("\x03安全屋位置已被保存\n\x04位置信息\x01 %.2f %.2f %.2f",
			// 			g_LocationSlots[0], g_LocationSlots[1], g_LocationSlots[2]);
		}
	}
	return Plugin_Continue;
}

public void OnMapStart()  // 投票换图似乎会出问题,但是应该够用了（有方法触发bug）
{
	PrintToChatAll("执行初始化");
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		Entered[i] = 0;
	}
	TotalEntered = 0;
	FirstEnter = 1;
	sm_TpAllEnable = GetConVarInt(hTpallEnable);
	TpAllEnable = false;
	VoteInProgress = false;
	passvote = false;
	Foujue = false;
	timeoutt = 0;
	votenum = 0;
	g_LocationSlots[0] = 0.0;
	g_LocationSlots[1] = 0.0;
	g_LocationSlots[2] = 0.0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (g_LocationSlots[0] == 0.0)  // 保存默认初始位置
			{
				GetClientAbsOrigin(i, g_LocationSlots);
				// PrintToChatAll("\x03安全屋位置已被保存2\n\x04位置信息\x01 %.2f %.2f %.2f",
				// 			g_LocationSlots[0], g_LocationSlots[1], g_LocationSlots[2]);
			}
		}
	}
}

public bool OnClientConnect(int client)
{
	if (client)
	{
		Entered[client] = 0;  // 没用,只是占个位置,方便后续加入代码
	}
	return true;
}

public OnClientDisconnect(int client)
{
	if (Entered[client] == 1)
	{
		Entered[client] = 0;
		TotalEntered--;
	}
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

public Action:Door(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new Entity = GetEventInt(event, "targetid");
	
	if (sm_TpAllEnable == 0)
	{
		return Plugin_Handled;
	}

	if(IsValidEntity(Entity))
	{
		new String:entname[128];
		if(GetEdictClassname(Entity, entname, sizeof(entname)))
		{
			/* Saferoom door */
			if(StrEqual(entname, "prop_door_rotating_checkpoint"))
			{
				if (Entered[Client])  // 玩家已经开过了门
				{
					return Plugin_Handled;
				}
				if (Client == 0 || !IsClientInGame(Client) || GetClientTeam(Client) != 2 || IsFakeClient(Client))
				{
					return Plugin_Handled;
				}
				else if (IsInStartSaferoom(Client))
				{
					// PrintToChatAll("检查点1");
					return Plugin_Handled;
				}
				char clientName[64];
				GetClientName(Client, clientName, 64);
				Entered[Client] = 1;
				TotalEntered++;
				int timeF = GetGameTime();
				decl String:buffer[10];
				Format(buffer, 255, "%.0f", timeF);
				int timeT = StringToInt(buffer, 10);
				int minutes = timeT / 60;
				int seconds = timeT % 60;
				if (FirstEnter)
				{
					FirstEnter = 0;
					PrintToChatAll("\x04%s \x01第一个到达安全屋,耗时\x04%i分%i秒", clientName, minutes, seconds);
					PrintToChatAll("请其他人请加快速度,或使用\x04!tpto\x01传送到他的身边");
					PrintToChatAll("如果超过半数人到达安全屋,可投票使用\x04!tpall\x01传送所有人");
				}
				else
				{
					Entered[Client] = 1;
					PrintToChatAll("\x04%s \x01到达了安全屋,耗时\x03%i分%i秒\x01,排名为\x03%i\x01,当前总人数为\x03%i",
										clientName, minutes, seconds, TotalEntered, HumanNum());
				}
				if (!TpAllEnable && TotalEntered > HumanNum() / 2)
				{
					TpAllEnable = true;
					PrintToChatAll("\x04[提示]\x03已有超过半数人到达安全屋,已可使用!tpall指令!");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Botton(Handle:event, String:name[], bool:dontBroadcast)
{
	if (sm_TpAllEnable == 0)
	{
		return Plugin_Handled;
	}
	
	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));

	if (Entered[Client])  // 玩家已经按过了按钮
	{
		return Plugin_Handled;
	}
	if (Client == 0 || !IsClientInGame(Client) || GetClientTeam(Client) != 2 || IsFakeClient(Client))
	{
		return Plugin_Handled;
	}

	char clientName[64];
	GetClientName(Client, clientName, 64);
	Entered[Client] = 1;
	TotalEntered++;
	int timeF = GetGameTime();
	decl String:buffer[10];
	Format(buffer, 255, "%.0f", timeF);
	int timeT = StringToInt(buffer, 10);
	int minutes = timeT / 60;
	int seconds = timeT % 60;
	if (FirstEnter)
	{
		FirstEnter = 0;
		PrintToChatAll("\x04%s \x03第一个 \x01按下了机关的按钮,耗时\x03 %i分%i秒 \x01!", clientName, minutes, seconds);
		PrintToChatAll("请其他人请加快速度,或使用\x03!tpto\x01传送到他的身边");
		PrintToChatAll("如果有一半人按下机关,可使用!tpall投票传送所有人");
	}
	else
	{
		TotalEntered++;
		PrintToChatAll("\x04%s \x01按下了机关,耗时\x03 %i分%i秒\x01 ,排名为\x03 %i\x01,当前总人数为\x03 %i",
							clientName, minutes, seconds, TotalEntered, HumanNum());
	}
	if (!TpAllEnable && TotalEntered > HumanNum() / 2)
	{
		TpAllEnable = true;
		PrintToChatAll("\x04[提示]\x03已有超过半数人按下机关,已可使用!tpall指令!");
	}
	return Plugin_Handled;
}

public Action:Check(Handle:event, String:name[], bool:dontBroadcast)
{
	if (sm_TpAllEnable == 0)
	{
		return Plugin_Handled;
	}

	new Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (Entered[Client])  // 玩家已经开过了门
	{
		return Plugin_Handled;
	}
	if (Client == 0 || !IsClientInGame(Client) || GetClientTeam(Client) != 2 || IsFakeClient(Client))
	{
		return Plugin_Handled;
	}
	else if (IsInStartSaferoom(Client))
	{
		// PrintToChatAll("检查点2");
		return Plugin_Handled;
	}
	char clientName[64];
	GetClientName(Client, clientName, 64);
	Entered[Client] = 1;
	TotalEntered++;
	int timeF = GetGameTime();
	decl String:buffer[10];
	Format(buffer, 255, "%.0f", timeF);
	int timeT = StringToInt(buffer, 10);
	int minutes = timeT / 60;
	int seconds = timeT % 60;
	if (FirstEnter)
	{
		FirstEnter = 0;
		PrintToChatAll("\x04%s \x01第一个到达安全屋,耗时\x04%i分%i秒", clientName, minutes, seconds);
		PrintToChatAll("请其他人请加快速度,或使用\x04!tpto\x01传送到他的身边");
		PrintToChatAll("如果超过半数人到达安全屋,可投票使用\x04!tpall\x01传送所有人");
	}
	else
	{
		PrintToChatAll("\x04%s \x01到达了安全屋,耗时\x04%i分%i秒\x01,排名为\x04%i\x01,当前总人数为\x04%i",
							clientName, minutes, seconds, TotalEntered, HumanNum());
	}
	if (!TpAllEnable && TotalEntered > HumanNum() / 2)
	{
		TpAllEnable = true;
		PrintToChatAll("\x04[提示]\x01已有超过半数人到达安全屋,已可使用!tpall指令!");
	}
	return Plugin_Continue;
}


public Action:BottonUsed(Handle:event, String:name[], bool:dontBroadcast)
{
	if (sm_TpAllEnable == 0)
	{
		return Plugin_Handled;
	}

	int timeF = GetGameTime();
	decl String:buffer[10];
	Format(buffer, 255, "%.0f", timeF);
	int timeT = StringToInt(buffer, 10);
	int minutes = timeT / 60;
	int seconds = timeT % 60;
	PrintToChatAll("\x04[提示]\x01所有人已经成功通过了检查点,耗时\x03%i分%i秒\x01", minutes, seconds);
	for (int i = 1; i <= MaxClients; i++)
	{
		Entered[i] = 0;
	}
	TotalEntered = 0;
	FirstEnter = 1;
	TpAllEnable = false;
	return Plugin_Handled;
}

bool IsInStartSaferoom(int client)
{
	new Float:Location[3];
	GetClientAbsOrigin(client, Location);
	if (g_LocationSlots[0] != 0.0)
	{
		if (abs(g_LocationSlots[0] - Location[0]) > 1000 || abs(g_LocationSlots[1] - Location[1]) > 1000 ||  abs(g_LocationSlots[2] - Location[2]) > 500)
		{
			// PrintToChatAll("[标记%.2f %.2f %.2f]", abs(g_LocationSlots[0] - Location[0]), abs(g_LocationSlots[1] - Location[1]), abs(g_LocationSlots[2] - Location[2]));
			return false;
		}
	}
	// PrintToChatAll("12[%.2f %.2f %.2f]]", abs(g_LocationSlots[0] - Location[0]), abs(g_LocationSlots[1] - Location[1]), abs(g_LocationSlots[2] - Location[2]));
	return true;
}

float abs(float i)
{
	if (i > 0)
	{
		return i;
	}
	return -i;
}

public Action:TeleportAll(client, agrs)
{
	if (sm_TpAllEnable == 0)
	{
		PrintToChat(client, "服务器暂时未开启tpall指令")
		return Plugin_Handled;
	}

	if (client == 0) 
	{
		return Plugin_Handled;
	}

	if (!TpAllEnable)
	{
		PrintToChat(client, "\x04[提示]\x01请等待超过半数队友到达后再发起投票");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[提示]\x01只有幸存者能够发起该投票");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client)) 
	{
		PrintToChat(client, "\x04[提示]\x01你必须先复活才能够发起该投票");
		return Plugin_Handled;
	}
	if (!Entered[client])
	{
		PrintToChat(client, "\x04[提示]\x01你还没到达检查点无法发起该投票");
		return Plugin_Handled;
	}
	if (VoteInProgress)
	{
		PrintToChat(client, "\x04[提示]\x01有正在进行中的传送投票,无法发起新的投票");
		return Plugin_Handled;
	}

	ShowTpAll(client);

	return Plugin_Continue;
}

public Action:ShowTpAll(client)
{	
	new String:text[128];
	decl String:buffer[256];
	new String:iname[80];
	GetClientName(client, iname, 80);
	Format(buffer, 255, " %s 想要将所有人传送到他的身边:", iname);
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
			SendPanelToClient(votepanel, i, TpMenuVoteHandler, 10);
		}
		i++;
	}
	CreateTimer(1.0, votetimeout, client, 1);
	PrintToChatAll("\x03%s \x01发起传送所有队友的投票", iname);
	VoteInProgress = true;
	CloseHandle(votepanel);
	return Plugin_Continue;
}

public TpMenuVoteHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		if (VoteInProgress == true && !vote_me[client])
		{
			new String:iname[80];
			GetClientName(client, iname, 80);
			Format(iname, 80, "[匿名]");
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

public Action:votetimeout(Handle:Timer, any:client)
{
	timeoutt = timeoutt + 1;
	votenum = voteNO + voteYES;
	new atime = 10 - timeoutt;
	new playernum = HumanNum();
	PrintHintTextToAll("传送所有人投票:你还有 %d 秒可以投票. \n同意: %d票 反对: %d票 已投票数 %d/%d", atime, voteYES, voteNO, votenum, playernum);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (vote_me[i] || !IsClientInGame(i) || IsFakeClient(i))
		{
		}
		else
		{
			RefreshVotePanel(client);
		}
		i++;
	}
	if (votenum >= playernum)
	{
		if (Foujue == true)
		{
			PrintToChatAll("\x04[传送]\x03 投票传送失败,被管理员强制否决.");
			Foujue = false;
			return Action:3;
		}
		else if (voteYES > voteNO)
		{
			passvote = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					float tpToPosition[3];
					GetClientAbsOrigin(client, tpToPosition);
					TeleportEntity(i, tpToPosition, NULL_VECTOR, NULL_VECTOR);
				}
			}
			PrintToChatAll("\x04[传送]\x03 投票获得通过");
		}
		else
		{
			PrintToChatAll("\x04[传送]\x03 投票不通过,请尝试说服其它玩家");
		}
		VoteMenuClose();
		return Action:4;
	}
	if (timeoutt >= 10)
	{
		if (Foujue == true)
		{
			PrintToChatAll("\x04[传送]\x03 投票传送失败,被管理员强制否决.");
			Foujue = false;
			return Action:3;
		}
		if (playernum != voteNO + voteYES)
		{
			voteYES = playernum - voteNO;
		}
		if (voteYES > voteNO)
		{
			passvote = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					float tpToPosition[3];
					GetClientAbsOrigin(client, tpToPosition);
					TeleportEntity(i, tpToPosition, NULL_VECTOR, NULL_VECTOR);
				}
			}
			PrintToChatAll("\x04[传送]\x03 投票获得通过");
		}
		else
		{
			PrintToChatAll("\x04[传送]\x03 投票不通过,请尝试说服其它玩家");
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
	Format(buffer, 255, " %s 想要将所有人传送到他的身边:", iname);
	votepanel = CreatePanel(Handle:0);
	SetPanelTitle(votepanel, buffer, false);
	Format(text, 128, "同意(默认)");
	DrawPanelItem(votepanel, text, 0);
	Format(text, 128, "反对");
	DrawPanelItem(votepanel, text, 0);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && vote_me[i])
		{
			SendPanelToClient(votepanel, i, TpMenuVoteHandler, 1);
		}
		i++;
	}
	CloseHandle(votepanel);
	return 0;
}

VoteMenuClose()
{
	VoteInProgress = false;
	new playernum = HumanNum();
	PrintHintTextToAll("传送投票已结束. \n同意: %d票 反对: %d票 已投票数 %d/%d", voteYES, voteNO, votenum, playernum);
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

public Action:votefail(client, args)
{
	if (passvote == true)
	{
		Foujue = true;
		PrintToChatAll("\x03[传送]\x01 管理员强制否决当前传送投票.");
		passvote = false;
		return Action:3;
	}
	PrintToChat(client, "\x03[传送]\x01 当前没有可以否决的投票");
	return Action:3;
}
