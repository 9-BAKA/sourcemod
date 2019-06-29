#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME					"Teleport传送插件"
#define PLUGIN_AUTHOR				"BAKA."
#define PLUGIN_DESCRIPTION	"存档，传送，传送到队友身边，死亡自动复活"
#define PLUGIN_VERSION			"1.0"
#define PLUGIN_URL					"47.94.208.140"

new Handle:g_hCvar_ChatPrefix;
new Handle:g_hCvar_TeleportEnable;
new Handle:g_hCvar_RespawnEnabled;
new Handle:g_hCvar_SaveNum;
new Handle:g_hCvar_ReviveTime;

new bool:g_TpSlot[MAXPLAYERS+1];  // 记录当前tp信息，防止同时进行多个传送
new Float:g_LocationSlots[MAXPLAYERS+1][101][3];  // 存储玩家的位置
int g_RevivePos[MAXPLAYERS+1];
int Death_time[MAXPLAYERS+1];

new String:g_Cvar_ChatPrefix[32];  // 消息前缀

new autoRespawn;
new teleEnable;
new maxSaveNum;
float reviveTime;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_save", SaveLocation, "保存玩家位置");
	RegConsoleCmd("sm_tp", Teleport, "!tp [i]传送到第i存档点");
	RegConsoleCmd("sm_tpto", TeleportTo, "传送到队友身边");
	RegConsoleCmd("sm_fuhuo", ManuRespawn, "手动复活");
	RegConsoleCmd("sm_clean", Clean, "清除生还者尸体");
	
	g_hCvar_ChatPrefix = CreateConVar("sm_teleport_chat_prefix", "[BAKA]", "消息前缀", FCVAR_NOTIFY);
	g_hCvar_TeleportEnable = CreateConVar("sm_teleport_enable", "0", "是否开启传送", FCVAR_NOTIFY);
	g_hCvar_RespawnEnabled = CreateConVar("sm_auto_respawn", "0", "是否开启自动复活", FCVAR_NOTIFY);
	g_hCvar_SaveNum = CreateConVar("sm_save_num", "10", "存档个数(最多100，最少3个)", FCVAR_NOTIFY);
	g_hCvar_ReviveTime = CreateConVar("sm_respawn_time", "10.0", "自动复活时长(5.0-60.0秒)", FCVAR_NOTIFY);

	AutoExecConfig(true, "teleport");

	HookConVarChange(g_hCvar_ChatPrefix, ConVarChanged);
	HookConVarChange(g_hCvar_TeleportEnable, ConVarChanged);
	HookConVarChange(g_hCvar_RespawnEnabled, ConVarChanged);
	HookConVarChange(g_hCvar_SaveNum, ConVarChanged);

	HookEvent("player_death", AutoRespawn);
	HookEvent("player_activate", Event_activate_R);

	hGameConf = LoadGameConfigFile("l4drespawn");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
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
			if (teleEnable)
			{
				PrintToChat(client, "\x03您的初始位置已被保存，可随时使用\x04 !tp 0 \x03传送到该位置\n\x04位置信息\x01 %.2f %.2f %.2f",
							g_LocationSlots[client][0][0], g_LocationSlots[client][0][1], g_LocationSlots[client][0][2]);
			}
		}

		if (!HasSavedLocation(0, 0))
		{
			for (new j = 0; j < 3; j++)
			{
				g_LocationSlots[0][0][j] = g_LocationSlots[client][0][j];  // 保存电脑默认传送位置
			}
			// PrintToChatAll("\x03电脑的初始位置已被保存\n\x04位置信息\x01 %.2f %.2f %.2f", 
			// 			g_LocationSlots[0][0][0], g_LocationSlots[0][0][1], g_LocationSlots[0][0][2]);
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
	if (autoRespawn == 0)
	{
		return Plugin_Handled;
	}
	char name[80];
	GetClientName(clientId, name, 80);
	Death_time[clientId]++;
	PrintToChatAll("\x05%s \x01死亡次数: \x05%i", name, Death_time[clientId]);
	if (autoRespawn == 1)
	{
		if (!IsFakeClient(clientId))
		{
			decl String:buffer[10];
			Format(buffer, 255, "%.0f", reviveTime);
			int timeT = StringToInt(buffer, 10);
			if (teleEnable == 1)
			{
				ShowReviveMenu(clientId, timeT-1);
				PrintHintText(clientId, "您已经死亡，将于%i秒后重生并传送到上个存档点\n记得使用!save保存新的存档点", timeT); // 应当动态显示
			}
			else
			{
				PrintHintText(clientId, "您已经死亡，将于%i秒后重生", timeT);
			}
			CreateTimer(reviveTime, ReviveHum, clientId, 0);  // 5秒后进行复活操作
		}
		else
		{
			CreateTimer(reviveTime, ReviveBot, clientId, 0);
		}
	}
	else if (autoRespawn == 2)
	{
		decl String:buffer[10];
		Format(buffer, 255, "%.0f", reviveTime);
		int timeT = StringToInt(buffer, 10);
		PrintHintText(clientId, "您已经死亡，将于%i秒后自动重生", timeT);
		CreateTimer(reviveTime, ReviveBot, clientId, 0);
	}
	else if (autoRespawn == 3)
	{
		PrintToChat(clientId, "\x04服务器暂时没有开启自动复活，请输入!fuhuo手动复活");
	}
	return Plugin_Continue;
}

public Action Clean(int client, int agrs)
{
	CleanDeadBody();
	CleanWeapon();
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			GiveItems(i);
		}
		i++;
	}
	PrintToChatAll("已清除生还者尸体和多余武器");
}

public void CleanDeadBody()
{
	new ent = -1;
	while((ent = FindEntityByClassname(-1, "survivor_death_model")) != -1)
	{
		if (IsValidEnt(ent))
		{
			RemoveEdict(ent);
			// PrintToChatAll("%i", ent);
		}
	}
}

public void CleanWeapon()
{
	new ent = -1;
	while((ent = FindEntityByClassname(-1, "weapon_sniper_awp")) != -1)
	{
		if (IsValidEnt(ent))
		{
			RemoveEdict(ent);
			// PrintToChatAll("%i", ent);
		}
	}
	while((ent = FindEntityByClassname(-1, "weapon_meele")) != -1)
	{
		if (IsValidEnt(ent))
		{
			RemoveEdict(ent);
			// PrintToChatAll("%i", ent);
		}
	}
	while((ent = FindEntityByClassname(-1, "weapon_pistol")) != -1)
	{
		if (IsValidEnt(ent))
		{
			RemoveEdict(ent);
			// PrintToChatAll("%i", ent);
		}
	}
}

IsValidEnt(ent)
{
	if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return 1;
	}
	return 0;
}

public Action:ShowReviveMenu(client, timeT)
{
	if (client == 0) 
	{
		return;
	}

	decl String:sMenuEntry[8];
	g_RevivePos[client] = 1;
	
	new Handle:menu = CreateMenu(ReviveMenu);
	SetMenuTitle(menu, "选择一个存档点进行复活:");
	
	AddMenuItem(menu, "0", "出生点");
	AddMenuItem(menu, "1", "存档1(默认)");
	for (int i = 2; i <= maxSaveNum; i++)
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
	DisplayMenu(menu, client, timeT);
}

public ReviveMenu(Handle:menu, MenuAction:action, client, position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			g_RevivePos[client] = position;
			PrintToChat(client, "你选择了 %i 号存档点", position);

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

public Action:ManuRespawn(client, agrs)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		return Plugin_Handled;
	}
	autoRespawn = GetConVarInt(g_hCvar_RespawnEnabled);
	if (autoRespawn == 0)
	{
		PrintToChat(client, "当前服务器暂时不允许复活指令");
	}
	else if (autoRespawn == 1 || autoRespawn == 2)
	{
		PrintToChat(client, "当前服务器为自动复活，无需手动复活");
	}
	else
	{
		if (IsPlayerAlive(client))
		{
			PrintToChat(client, "您当前无需复活");
		}
		else
		{
			ShowManuReviveMenu(client);
		}
	}
	return Plugin_Continue;
}

public Action:ShowManuReviveMenu(client)
{
	if (client == 0) 
	{
		return;
	}

	decl String:sMenuEntry[8];
	g_RevivePos[client] = 1;
	
	new Handle:menu = CreateMenu(ManuReviveMenu);
	SetMenuTitle(menu, "选择一个存档点进行复活:");
	
	AddMenuItem(menu, "0", "出生点");
	for (int i = 1; i <= maxSaveNum; i++)
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
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public ManuReviveMenu(Handle:menu, MenuAction:action, client, position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			g_RevivePos[client] = position;
			PrintHintText(client, "您选择了%i号存档点,您将于5秒后复活", position);
			CreateTimer(5.0, ReviveHum, client, 0);  // 5秒后进行复活操作
		}
		case MenuAction_Cancel:
		{
			PrintHintText(client, "您取消了复活");
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
	if (client)
	{
		for (new j = 0; j <= maxSaveNum; j++)
		{
			g_LocationSlots[client][j][0] = 0.0;
			g_LocationSlots[client][j][1] = 0.0;
			g_LocationSlots[client][j][2] = 0.0;
		}
		Death_time[client] = 0;
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
	
	float ReviveTime = GetConVarFloat(g_hCvar_ReviveTime);
	if (ReviveTime > 60.0)
	{
		SetConVarFloat(g_hCvar_SaveNum, 60.0);
	}
	else if (ReviveTime < 5.0)
	{
		SetConVarFloat(g_hCvar_SaveNum, 5.0);
	}

	maxSaveNum = GetConVarInt(g_hCvar_SaveNum);
	reviveTime = GetConVarFloat(g_hCvar_ReviveTime);
	teleEnable = GetConVarInt(g_hCvar_TeleportEnable);

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
		g_TpSlot[i] = false;
		g_RevivePos[i] = 0;
		Death_time[i] = 0;
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

	if (teleEnable == 0)
	{
		PrintToChat(client, "服务器暂时未开启传送指令");
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

	for (new i = maxSaveNum; i > 1; i--) // 向后存档
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
	if (teleEnable == 0)
	{
		PrintToChat(client, "服务器暂时未开启传送指令");
		return Plugin_Handled;
	}

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

	if (0 <= tp_index && tp_index <= maxSaveNum)
	{
		if (HasSavedLocation(client, tp_index))
		{
			TeleportEntity(client, g_LocationSlots[client][tp_index], NULL_VECTOR, NULL_VECTOR);
			EmitSoundFromPlayer(client, "buttons/blip1.wav");
		}
		else
		{
			for (int i = maxSaveNum; i > 0; i--)
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
		PrintToChat(client, "\x04%s\x01您输入的参数有误，当前存档点个数为\x04 %i", g_Cvar_ChatPrefix, maxSaveNum);
	}
	return Plugin_Handled;
}

// 传送到队友身边
public Action:TeleportTo(client, agrs)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}
	if (g_TpSlot[client])
	{
		PrintToChat(client, "请等待10秒后再进行传送");
		return Plugin_Handled;
	}

	ShowTpMenu(client);

	return Plugin_Continue;
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

public tpToMenu(Handle:menu, MenuAction:action, client, position) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char name[MAX_NAME_LENGTH];
			GetMenuItem(menu, position, name, sizeof(name));
			
			int tpToClient = StringToInt(name, 10);

			if (g_TpSlot[tpToClient])
			{
				PrintToChat(client, "对方有正在进行中的传送，无法进行新的传送");
				return;
			}

			if (IsFakeClient(tpToClient))
			{
				float tpToPosition[3];
				GetClientAbsOrigin(tpToClient, tpToPosition);
				TeleportEntity(client, tpToPosition, NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, "已传送到电脑附近");
			}
			else
			{
				g_TpSlot[client] = true;
				g_TpSlot[tpToClient] = true;
				PrintToChat(client, "传送请求已发送");
				ShowAcceptTpMenu(tpToClient, client);
			}

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

public Action:ShowAcceptTpMenu(client, tpFrom)
{
	new Handle:menu = CreateMenu(tpFromMenu);

	char name[MAX_NAME_LENGTH];
	GetClientName(tpFrom, name, MAX_NAME_LENGTH);
	SetMenuTitle(menu, "%s 想要传送到你这里:", name);
	
	char tpFromClientID[4];
	Format(tpFromClientID, 3, "%i", tpFrom);
	AddMenuItem(menu, tpFromClientID, "接受");
	AddMenuItem(menu, tpFromClientID, "拒绝");

	DisplayMenu(menu, client, 10);

	CreateTimer(10.0, ClearState1, client, 0);
	CreateTimer(10.0, ClearState2, tpFrom, 0);
}

public Action:ClearState1(Handle:timer, any:client)
{
	g_TpSlot[client] = false;
	return Plugin_Continue;
}

public Action:ClearState2(Handle:timer, any:client)
{
	g_TpSlot[client] = false;
	return Plugin_Continue;
}

public tpFromMenu(Handle:menu, MenuAction:action, client, position) 
{
	int tpFrom = 0;
	decl String:info[8];
	GetMenuItem(menu, position, info, sizeof(info));	
	tpFrom = StringToInt(info, 10);
	char tpFromName[MAX_NAME_LENGTH];
	GetClientName(tpFrom, tpFromName, MAX_NAME_LENGTH);
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
					if (IsClientInGame(tpFrom) && GetClientTeam(tpFrom) == 2)  // 防止接受请求时玩家离线,闲置或加入观察者
					{
						PrintToChat(client, "\x04[提示]\x01您接受了 %s 的传送请求", tpFromName);
						PrintToChat(tpFrom, "\x04[提示]\x01%s 接受了您的传送请求", tpToName);
						float tpToPosition[3];
						GetClientAbsOrigin(client, tpToPosition);
						TeleportEntity(tpFrom, tpToPosition, NULL_VECTOR, NULL_VECTOR);
					}
					else
					{
						if (IsClientInGame(tpFrom))
							PrintToChat(client, "\x04[提示]\x01无法传送,对方已经闲置！", tpFromName);
						else
							PrintToChat(client, "\x04[提示]\x01无法传送,对方已经退出了游戏！", tpFromName);
					}
				}
				case 1:
				{
					PrintToChat(client, "\x04[提示]\x01您拒绝了 %s 的传送请求", tpFromName);
					if (IsClientInGame(tpFrom))
					{
						PrintToChat(tpFrom, "\x04[提示]\x01%s 拒绝了您的传送请求", tpToName);
					}
				}
			} 
			
		}
		case MenuAction_Cancel:
		{
			PrintToChat(client, "\x04[提示]\x01您拒绝了 %s 的传送请求", tpFromName);
			PrintToChat(tpFrom, "\x04[提示]\x01 %s 拒绝了您的传送请求", tpToName);
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action ReviveBot(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			return;
		}
		if (GetClientTeam(client) != 2) // 如果玩家在复活过程中闲置了，则救起一个电脑
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (IsFakeClient(client) && !IsPlayerAlive(client))
				{
					client = i;
					break;
				}
			}
		}
		if (client == MaxClients) return;
		SDKCall(hRoundRespawn, client);

		SetHealth(client);
		GiveItems(client);
		TeleportBot(client);

		decl String:playername[64];
		GetClientName(client, playername, sizeof(playername));
		PrintToChatAll("玩家 \x05%s \x01复活了.", playername);
		CleanDeadBody();
	}
}

public Action ReviveHum(Handle timer, any client)  // 救活人类
{
	if (IsClientInGame(client))  // 防止在复活前玩家退出
	{
		if (GetClientTeam(client) != 2)
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (IsFakeClient(client) && !IsPlayerAlive(client))
				{
					client = i;
					break;
				}
			}
		}
		if (client == MaxClients) return;
		SDKCall(hRoundRespawn, client);
			
		SetHealth(client);
		GiveItems(client);
		TeleportHum(client);

		PrintToChat(client, "你已成功复活");
		decl String:playername[64];
		GetClientName(client, playername, sizeof(playername));
		PrintToChatAll("玩家 \x05%s \x01复活了.", playername);
		CleanDeadBody();
	}
}

TeleportBot(int client)
{
	if (HasSavedLocation(0, 0) && teleEnable && autoRespawn == 1)
	{
		TeleportEntity(client, g_LocationSlots[0][0], NULL_VECTOR, NULL_VECTOR);  // 如果保存了默认地点
	}
	else
	{
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && i != client)
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				TeleportEntity(client, vOrigin1, vAngles1, NULL_VECTOR);
				break;
			}
			i++;
		}
	}
}

TeleportHum(int client)
{
	if (teleEnable == 0)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && i != client)
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				TeleportEntity(client, vOrigin1, vAngles1, NULL_VECTOR);
				break;
			}
			i++;
		}
	}
	else if (HasSavedLocation(client, 1))
	{
		TeleportEntity(client, g_LocationSlots[client][g_RevivePos[client]], NULL_VECTOR, NULL_VECTOR);  // 如果保存了存档点
		g_RevivePos[client] = 0;
	}
	else
	{
		PrintHintText(client, "\x04您未保存存档点，请使用!save保存地点，已将您传送到出生点");
		TeleportEntity(client, g_LocationSlots[0][0], NULL_VECTOR, NULL_VECTOR);
		g_RevivePos[client] = 0;
	}
}

SetHealth(client)
{
	new sBonusHP = 100;
	SetEntProp(client, PropType:0, "m_iHealth", sBonusHP, 1, 0);
	SetEntDataFloat(client, 100, 100.0, true);
	return 0;
}

GiveItems(int client)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & -16385);
	FakeClientCommand(client, "give weapon_sniper_awp");
	FakeClientCommand(client, "give knife");
	FakeClientCommand(client, "give weapon_pipe_bomb");
	FakeClientCommand(client, "give weapon_first_aid_kit");
	FakeClientCommand(client, "give pain_pills");
	SetCommandFlags("give", flags | 16384);
	return 0;
}
