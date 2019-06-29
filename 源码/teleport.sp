#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME					"Teleport传送插件"
#define PLUGIN_AUTHOR				"BAKA."
#define PLUGIN_DESCRIPTION	"存档，传送，传送到队友身边，死亡自动复活"
#define PLUGIN_VERSION			"1.0"
#define PLUGIN_URL					"47.94.208.140"

new Handle:g_hCvar_ChatPrefix;
new Handle:g_hCvar_LogEnabled;
new Handle:g_hCvar_TeleportEnable;
new Handle:g_hCvar_RespawnEnabled;
new Handle:g_hCvar_SaveNum;

new Int:g_TpSlot[MAXPLAYERS+1][2];  // 记录当前tp信息，防止同时进行多个传送
new Float:g_LocationSlots[MAXPLAYERS+1][101][3];  // 存储玩家的位置
new Int:g_RevivePos[MAXPLAYERS+1];

new String:g_Cvar_ChatPrefix[32];  // 消息前缀

int autoRespawn;

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_save", SaveLocation, "保存玩家位置");
	RegConsoleCmd("sm_tp", Teleport, "!tp [i]传送到第i存档点");
	RegConsoleCmd("sm_tpto", TeleportTo, "传送到队友身边");
	
	g_hCvar_ChatPrefix = CreateConVar("sm_teleport_chat_prefix", "[提示]", "消息前缀", FCVAR_NOTIFY);
	g_hCvar_LogEnabled = CreateConVar("sm_teleport_log_enabled", "1", "是否将玩家行为写入日志", FCVAR_NOTIFY);
	g_hCvar_TeleportEnable = CreateConVar("sm_teleport_enable", "0", "是否开启传送", FCVAR_NOTIFY);
	g_hCvar_RespawnEnabled = CreateConVar("sm_auto_respawn", "1", "是否开启自动复活", FCVAR_NOTIFY);
	g_hCvar_SaveNum = CreateConVar("sm_save_num", "10", "存档个数（最多100，最少3个）", FCVAR_NOTIFY);

	AutoExecConfig(true, "teleport");

	HookConVarChange(g_hCvar_ChatPrefix, ConVarChanged);
	HookConVarChange(g_hCvar_LogEnabled, ConVarChanged);
	HookConVarChange(g_hCvar_TeleportEnable, ConVarChanged);
	HookConVarChange(g_hCvar_RespawnEnabled, ConVarChanged);
	HookConVarChange(g_hCvar_SaveNum, ConVarChanged);

	HookEvent("player_death", AutoRespawn);
	HookEvent("player_activate", Event_activate_R);

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
		if (!HasSavedLocation(client, 0))  // 保存玩家初始位置
		{
			GetClientAbsOrigin(client, g_LocationSlots[client][0]);
			GetClientAbsOrigin(client, g_LocationSlots[client][1]);
			PrintToChat(client, "\x03您的初始位置已被保存，可随时使用\x04 !tp 0 \x03传送到该位置\n\x04位置信息\x01 %.2f %.2f %.2f",
						g_LocationSlots[client][0][0], g_LocationSlots[client][0][1], g_LocationSlots[client][0][2]);
		}

		if (!HasSavedLocation(0, 0))
		{
			for (new j = 0; j < 3; j++)
			{
				g_LocationSlots[0][0][j] = g_LocationSlots[client][0][j];  // 保存电脑默认传送位置
			}
			PrintToChatAll("\x03电脑的初始位置已被保存\n\x04位置信息\x01 %.2f %.2f %.2f", 
						g_LocationSlots[0][0][0], g_LocationSlots[0][0][1], g_LocationSlots[0][0][2]);
		}
	}
	return Plugin_Continue;
}

public Action:AutoRespawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientId == 0 || !IsClientInGame(clientId))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(clientId) != 2)
	{
		return Plugin_Handled;
	}
	autoRespawn = GetConVarInt(g_hCvar_RespawnEnabled);
	if (autoRespawn == 1)
	{
		if (!IsFakeClient(clientId))
		{
			ShowReviveMenu(clientId);
			PrintHintText(clientId, "您已经死亡，将于5秒后重生并传送到上个存档点\n记得使用!save保存新的存档点"); // 应当动态显示
			CreateTimer(4.5, Revive, clientId, 0);  // 5秒后进行复活操作
		}
		else
		{
			CreateTimer(4.5, ReviveBot);
		}
	}
	else if (autoRespawn == 2)
	{
		PrintToChat(clientId, "\x04服务器暂时没有开启自动复活，请输入!fuhuo手动复活");
	}
	return Plugin_Continue;
}

public Action:ShowReviveMenu(client)
{
	if (client == 0) 
	{
		return;
	}

	decl String:sMenuEntry[8];
	g_RevivePos[client] = 1;
	
	new Handle:menu = CreateMenu(ReviveMenu);
	SetMenuTitle(menu, "选择一个存档点进行复活:");
	
	int MaxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	AddMenuItem(menu, "0", "出生点");
	AddMenuItem(menu, "1", "存档点1(默认)");
	for (int i = 2; i <= MaxSaveNum; i++)
	{
		if (!HasSavedLocation(client, i))
		{
			break;
		}
		IntToString(i, sMenuEntry, sizeof(sMenuEntry));
		char saveName[15];
		Format(saveName, 15, "存档点%i", i);
		AddMenuItem(menu, sMenuEntry, saveName);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 4);
}

public ReviveMenu(Handle:menu, MenuAction:action, client, position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			g_RevivePos[client] = position;
			PrintToChat(client, "你选择了%i号存档点", position);

		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "传送到默认地点");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LoadSettings();
}

public OnConfigsExecuted()
{
	LoadSettings();
}

public OnMapStart()
{
	ResetPlugin();

	PrecacheSound("buttons/blip1.wav", false);
	PrecacheSound("level/startwam.wav", false);

}

// 断开连接时清除数据
public void OnClientDisconnect(int client)
{
	int MaxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	if (client)
	{
		for (new j = 0; j <= MaxSaveNum; j++)
		{
			g_LocationSlots[client][j][0] = 0.0;
			g_LocationSlots[client][j][1] = 0.0;
			g_LocationSlots[client][j][2] = 0.0;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if (!HasSavedLocation(client, 0))  // 保存玩家初始位置
			{
				GetClientAbsOrigin(client, g_LocationSlots[client][0]);
				GetClientAbsOrigin(client, g_LocationSlots[client][1]);
				PrintToChat(client, "\x03您的初始位置已被保存，可随时使用\x04 !tp 0 \x03传送到该位置\n\x04位置信息\x01 %.2f %.2f %.2f",
							g_LocationSlots[client][0][0], g_LocationSlots[client][0][1], g_LocationSlots[client][0][2]);
			}

			if (!HasSavedLocation(0, 0))
			{
				for (new j = 0; j < 3; j++)
				{
					g_LocationSlots[0][0][j] = g_LocationSlots[client][0][j];  // 保存电脑默认传送位置
				}
				PrintToChatAll("\x03电脑的初始位置已被保存\n\x04位置信息\x01 %.2f %.2f %.2f", 
							g_LocationSlots[0][0][0], g_LocationSlots[0][0][1], g_LocationSlots[0][0][2]);
			}
		}
	}
}

// 连接时保存为默认位置
public bool OnClientConnect(int client)
{
	for (new i = 0; i < 3; i++)
	{
		g_LocationSlots[client][0][i] = g_LocationSlots[0][0][i];
		g_LocationSlots[client][1][i] = g_LocationSlots[0][0][i];
	}
	return true;
}

LoadSettings()
{

	GetConVarString(g_hCvar_ChatPrefix, g_Cvar_ChatPrefix, sizeof(g_Cvar_ChatPrefix));
	int MaxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	if (MaxSaveNum > 100)
	{
		SetConVarInt(g_hCvar_SaveNum, 100);
	}
	else if (MaxSaveNum < 3)
	{
		SetConVarInt(g_hCvar_SaveNum, 3);
	}
	
	for (new i = 0; i < sizeof(g_Cvar_ChatPrefix); i++)
	{
		if (i == 0 && g_Cvar_ChatPrefix[i] == 0)
		{
			break;
		}
		else if (g_Cvar_ChatPrefix[i] == 0)
		{
			g_Cvar_ChatPrefix[i] = ' ';
			g_Cvar_ChatPrefix[i + 1] = 0;
			break;
		}
	}

}

ResetPlugin()
{

	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		g_TpSlot[i][0] = 0;
		g_TpSlot[i][1] = 0;
		g_RevivePos[i] = 0;
		for (new j = 0; j < 3; j++)
		{
			g_LocationSlots[i][j][0] = 0.0;
			g_LocationSlots[i][j][1] = 0.0;
			g_LocationSlots[i][j][2] = 0.0;
		}			
	}

}

public HasSavedLocation(int client, int slot)
{
	return (g_LocationSlots[client][slot][0] != 0.0 && g_LocationSlots[client][slot][1] != 0.0 && g_LocationSlots[client][slot][2] != 0.0);
}

public Action:SaveLocation(client, args)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "请先复活再保存记录点");
		return Plugin_Handled;
	}

	new Float:velo[3] = 0.0;
	velo[0] = GetEntPropFloat(client, PropType:0, "m_vecVelocity[0]", 0);
	velo[1] = GetEntPropFloat(client, PropType:0, "m_vecVelocity[1]", 0);
	velo[2] = GetEntPropFloat(client, PropType:0, "m_vecVelocity[2]", 0);

	if (velo[0] != 0 || velo[1] != 0 || velo[2] != 0)
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "请勿在运动中存档");
		return Plugin_Handled;
	}

	int MaxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	for (new i = MaxSaveNum; i > 1; i--) // 向后存档
	{
		g_LocationSlots[client][i][0] = g_LocationSlots[client][i-1][0];
		g_LocationSlots[client][i][1] = g_LocationSlots[client][i-1][1];
		g_LocationSlots[client][i][2] = g_LocationSlots[client][i-1][2];
	}

	GetClientAbsOrigin(client, g_LocationSlots[client][1]);  // 保存在一号位

	PrintToChat(client, "\x04%s\x03%s", g_Cvar_ChatPrefix, "当前地点已保存");
	EmitSoundFromPlayer(client, "level/startwam.wav");
	
	if (!HasSavedLocation(0, 0))  // 应该不会被执行，仅仅为了保险
	{
		for (new j = 0; j < 3; j++)
		{
			g_LocationSlots[0][0][j] = g_LocationSlots[client][1][j];  // 保存电脑默认传送位置
		}
		PrintToChatAll("\x03电脑的初始位置已被保存\n\x04位置信息\x01 %.2f %.2f %.2f", 
					g_LocationSlots[0][0][0], g_LocationSlots[0][0][1], g_LocationSlots[0][0][2]);
	}

	return Plugin_Handled;

}

EmitSoundFromPlayer(client, String:sound[])
{
	if (!IsClientInGame(client))
	{
		return 0;
	}
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	if (!IsSoundPrecached(sound))
	{
		PrecacheSound(sound, false);
	}
	EmitAmbientSound(sound, pos, 0, 75, 0, 1.0, 100, 0.0);
	return 0;
}

// 传送对应存档点
public Action:Teleport(client, args)
{
	new tp_index = 1;

	if (args < 1)
	{
		if (!HasSavedLocation(client, 1))
		{
			PrintToChat(client, "请先保存一个存档点，或者使用!tp 0传送到出生点", client);  // 人物连接的时候应当设置默认位置
			return Plugin_Handled;
		}
		tp_index = 1;
	}
	else if (args > 1)
	{
		PrintToChat(client, "\x04%s\x01%s", g_Cvar_ChatPrefix, "\x04请输入正确参数");
		return Plugin_Handled;
	}
	else
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		tp_index = StringToInt(arg, 10);
	}
	int MaxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	if (0 <= tp_index && tp_index <= MaxSaveNum)
	{
		if (HasSavedLocation(client, tp_index))
		{
			TeleportEntity(client, g_LocationSlots[client][tp_index], NULL_VECTOR, NULL_VECTOR);
			EmitSoundFromPlayer(client, "buttons/blip1.wav");
		}
		else
		{
			for (int i = MaxSaveNum; i > 0; i--)
			{
				if (HasSavedLocation(client, i))
				{
					PrintToChat(client, "\x04[提示]\x01您未保存这么多的存档点，您当前的存档总数为\x04 %i", i);
					break;
				}
			}
		}
	}
	else
	{
		PrintToChat(client, "\x04%s\x01您输入的参数有误，当前存档点个数为\x04 %i", g_Cvar_ChatPrefix, MaxSaveNum);
	}
	return Plugin_Handled;
}

// 传送到队友身边
public Action:TeleportTo(client, agrs)
{	
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (g_TpSlot[i][0] == client || g_TpSlot[i][1] == client)
		{
			PrintToChat(client, "您有正在进行中的传送，无法进行新的传送");
			return Plugin_Handled;
		}
	}
	if (client != 0)
	{
		g_TpSlot[client][0] = client;
		ShowTpMenu(client);
		g_TpSlot[client][0] = 0;
	}
	return Plugin_Continue;
}

public tpToMenu(Handle:menu, MenuAction:action, client, position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{

			char name[MAX_NAME_LENGTH];
			GetMenuItem(menu, position, name, sizeof(name));
			
			int tpToClient = StringToInt(name, 10);
			g_TpSlot[client][1] = tpToClient;
			if (IsFakeClient(tpToClient))
			{
				float tpToPosition[3];
				GetClientAbsOrigin(tpToClient, tpToPosition);
				TeleportEntity(client, tpToPosition, NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "已传送到电脑附近");
			}
			else
			{
				PrintToChat(client, "传送请求已发送");
				ShowAcceptTpMenu(tpToClient, client);
			}
			g_TpSlot[client][1] = 0;

		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "已放弃传送");
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public int AliveSurvivors()  // 获取当前幸存者人数
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

public Action:ShowTpMenu(client)
{
	if (client == 0) 
	{
		return;
	}
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "只有幸存者能够传送队友");
		return;
	}
	if (!IsPlayerAlive(client)) 
	{
		PrintToChat(client, "你必须先复活才能够传送到队友身边");
		return;
	}
	
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(tpToMenu);
	SetMenuTitle(menu, "选择一个队友进行传送:");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			IntToString(i, sMenuEntry, sizeof(sMenuEntry));
			char name[MAX_NAME_LENGTH];
			GetClientName(i, name, MAX_NAME_LENGTH);
			AddMenuItem(menu, sMenuEntry, name);
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public tpFromMenu(Handle:menu, MenuAction:action, client, position) 
{
	int tpFrom = 0;
	decl String:info[8];
	GetMenuItem(menu, position, info, sizeof(info));	
	tpFrom = StringToInt(info, 10);
	char tpFromName[MAX_NAME_LENGTH];
	GetClientName(tpFrom, tpFromName, MAX_NAME_LENGTH);  // 离线，闲置，观察者时会否出现bug？
	char tpToName[MAX_NAME_LENGTH];
	GetClientName(client, tpToName, MAX_NAME_LENGTH);
	switch (action) 
	{
		case MenuAction_Select: 
		{
			switch(position)
			{
				case 0:
				{
					float tpToPosition[3];
					GetClientAbsOrigin(client, tpToPosition);
					TeleportEntity(tpFrom, tpToPosition, NULL_VECTOR, NULL_VECTOR);  //应设置3秒传送间隔
					if (IsClientInGame(tpFrom))  // 防止接受请求时玩家离线
					{
						PrintToChat(client, "\x04[提示]\x01您接受了%s的传送请求", tpFromName);
						PrintToChat(tpFrom, "\x04[提示]\x01%s接受了您的传送请求", tpToName);
					}
					else
					{
						PrintToChat(client, "\x04[提示]\x01您接受了%s的传送请求，但是对方已经退出了游戏！", tpFromName);
					}
				}
				case 1:
				{
					PrintToChat(client, "\x04[提示]\x01您拒绝了%s的传送请求", tpFromName);
					if (IsClientInGame(tpFrom))
					{
						PrintToChat(tpFrom, "\x04[提示]\x01%s拒绝了您的传送请求", tpToName);
					}
				}
			} 
			
		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "\x04[提示]\x01您拒绝了%s的传送请求", tpFromName);
			PrintToChat(tpFrom, "\x04[提示]\x01%s拒绝了您的传送请求", tpToName);
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}			

public Action:ShowAcceptTpMenu(client, tpFrom)
{
	new Handle:menu = CreateMenu(tpFromMenu);

	char name[MAX_NAME_LENGTH];
	GetClientName(tpFrom, name, MAX_NAME_LENGTH);
	SetMenuTitle(menu, "%s 想要传送到你这里:", name);
	
	char info[4];
	Format(info, 3, "%i", tpFrom);
	AddMenuItem(menu, info, "接受");
	AddMenuItem(menu, info, "拒绝");

	DisplayMenu(menu, client, 10);
}

public Action ReviveBot(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && !IsPlayerAlive(i))
		{
			KickClient(i, "踢出一个死亡电脑");
			LCreateOneBot(-1);
			break;
		}
	}
}

public Action Revive(Handle timer, any client)  // 救活人类
{
	ChangeClientTeam(client, 1);
	for (int i = MaxClients; i > 0; i--)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && !IsPlayerAlive(i))
		{
			KickClient(i, "踢出一个死亡电脑");
			break;
		}
	}
	LCreateOneBot(client);
	CreateTimer(1, EnterGame, client);
	return Plugin_Continue;
}

public Action EnterGame(Handle timer, any client)
{
    ClientCommand(client, "jointeam 2");
	PrintToChat(client, "你已成功复活");
}

LCreateOneBot(int client)
{
	int survivorbot = CreateFakeClient("survivor bot");
	ChangeClientTeam(survivorbot, 2);
	DispatchKeyValue(survivorbot, "classname", "SurvivorBot");
	DispatchSpawn(survivorbot);
	if (HasSavedLocation(0, 0))
	{
		if (client == -1) // 电脑
		{
			if (HasSavedLocation(0, 0))
			{
				TeleportEntity(survivorbot, g_LocationSlots[0][0], NULL_VECTOR, NULL_VECTOR);  // 如果保存了默认地点
			}
			else
			{
				int i = 1;
				while (i <= MaxClients)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == 2)
					{
						float vAngles1[3];
						float vOrigin1[3];
						GetClientAbsOrigin(i, vOrigin1);
						GetClientAbsAngles(i, vAngles1);
						TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
						break;
					}
					i++;
				}
			}
		}
		else // 不是电脑
		{
			if (HasSavedLocation(client, 1))
			{
				TeleportEntity(survivorbot, g_LocationSlots[client][g_RevivePos[client]], NULL_VECTOR, NULL_VECTOR);  // 如果保存了存档点
				g_RevivePos[client] = 0;
			}
			else
			{
				PrintHintText(client, "\x04您未保存存档点，请使用!save保存地点，已将您传送到出生点");
				TeleportEntity(survivorbot, g_LocationSlots[0][0], NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	else
	{
		PrintToChatAll("\x04未保存默认tp点，请使用!save保存地点");
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
				break;
			}
			i++;
		}
	}
	GiveItems(survivorbot);
	CreateTimer(0.4, SurvivorKicker, survivorbot);
}

public Action SurvivorKicker(Handle timer, any survivorbot)
{
	KickClient(survivorbot, "CreateOneBot...");
}


GiveItems(int client)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & -16385);
	FakeClientCommand(client, "give weapon_sniper_awp");
	FakeClientCommand(client, "give knife");
	FakeClientCommand(client, "give pain_pills");
	SetCommandFlags("give", flags | 16384);
	return 0;
}
