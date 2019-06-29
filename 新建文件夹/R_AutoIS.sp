#include <sourcemod>
#include <sdktools>

#define DEBUG_GENERAL 0
#define DEBUG_TIMES 0
#define DEBUG_SPAWNS 0
#define DEBUG_WEIGHTS 0
#define DEBUG_EVENTS 0

// Uncommons Debug
//#define DEBUG 1


#define MAX_INFECTED 28
#define NUM_TYPES_INFECTED 7

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

//pz constants (for SI type checking)
#define IS_SMOKER	1
#define IS_BOOMER	2
#define IS_HUNTER	3
#define IS_SPITTER	4
#define IS_JOCKEY	5
#define IS_CHARGER	6
#define IS_TANK		8

//pz constants (for spawning)
#define SI_SMOKER		0
#define SI_BOOMER		1
#define SI_HUNTER		2
#define SI_SPITTER		3
#define SI_JOCKEY		4
#define SI_CHARGER		5
#define SI_TANK			6

new String:Spawns[7][16] =
{
	"smoker auto",
	"boomer auto",
	"hunter auto",
	"spitter auto",
	"jockey auto",
	"charger auto",
	"tank auto"
};
new RIFADDNUMS;
new R_AutoIS_T;
new bool:IFADDEnabled;
new bool:RAScheck;
new SICount;
new SILimit;
new SpawnSize;
new SpawnTimeMode;
new GameMode;
new baseNum;
new Float:SpawnTimeMin;
new Float:SpawnTimeMax;
new Float:SpawnTimes[29];
new SpawnWeights[7];
new SpawnLimits[7];
new SpawnCounts[7];
new Handle:hSpawnWeights[7];
new Handle:hSpawnLimits[7];
new Float:IntervalEnds[7];
new bool:R14Enabled;
new bool:EventsHooked;
new bool:SafeRoomChecking;
new bool:FasterResponse;
new bool:FasterSpawn;
new bool:SafeSpawn;
new bool:ScaleWeights;
new bool:ChangeByConstantTime;
new bool:SpawnTimerStarted;
new bool:WitchTimerStarted;
new bool:WitchWaitTimerStarted;
new bool:WitchCountFull;
new bool:RoundStarted;
new bool:RoundEnded;
new bool:LeftSafeRoom;
new Handle:hRIFADDNUMS;
new Handle:hR_AutoIS_T;
new Handle:hDisableInVersus;
new Handle:hFasterResponse;
new Handle:hFasterSpawn;
new Handle:hSafeSpawn;
new Handle:hSILimit;
new Handle:hSILimitMax;
new Handle:hScaleWeights;
new Handle:hSpawnSize;
new Handle:hSpawnTimeMin;
new Handle:hSpawnTimeMax;
new Handle:hSpawnTimer;
new Handle:hSpawnTimeMode;
new Handle:hGameMode;
new WitchCount;
new WitchLimit;
new Float:WitchPeriod;
new bool:VariableWitchPeriod;
new Handle:hWitchLimit;
new Handle:hWitchPeriod;
new Handle:hWitchPeriodMode;
new Handle:hWitchTimer;
new Handle:hWitchWaitTimer;
new Handle:hOA_AIS;
new bool:OA_AIS;
public Plugin:myinfo =
{
	name = "L4D2 Auto Infected Spawner",
	description = "Custom automatic infected spawner",
	author = "Tordecybombo ,, FuzzOne - miniupdate ,, TacKLER - miniupdate again 汉化&修改-望夜",
	version = "1.2",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	IFADDEnabled = false;
	new Handle:surv_l = FindConVar("survivor_limit");
	SetConVarBounds(surv_l, ConVarBounds:0, true, 8.0);
	new Handle:zombie_player_l = FindConVar("z_max_player_zombies");
	SetConVarBounds(zombie_player_l, ConVarBounds:0, true, 8.0);
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBounds:0, false, 0.0);
	new Handle:zombie_minion_l = FindConVar("z_minion_limit");
	SetConVarBounds(zombie_minion_l, ConVarBounds:0, true, 8.0);
	new Handle:zombie_surv = FindConVar("survival_max_specials");
	SetConVarBounds(zombie_surv, ConVarBounds:0, true, 8.0);
	decl String:mod[32];
	GetGameFolderName(mod, 32);
	if (!StrEqual(mod, "left4dead2", false))
	{
		SetFailState("[AIS] This plugin is for Left 4 Dead 2 only.");
	}
	HookEvents();
	HookEvent("witch_spawn", evtWitchSpawn, EventHookMode:1);
	HookEvent("witch_killed", evtWitchKilled, EventHookMode:1);
	HookEvent("round_start", Event_14CheckStart, EventHookMode:1);
	HookEvent("player_activate", Event_RIFPlayerAct, EventHookMode:1);
	HookEvent("player_disconnect", Event_RIFPlayerDisct, EventHookMode:1);
	HookEvent("finale_win", Event_RASFinaleWin, EventHookMode:1);
	RegConsoleCmd("sm_on14", R14Infectedon, "", 0);
	RegConsoleCmd("sm_on142", R14Infectedon2, "", 0);
	RegConsoleCmd("sm_on141", R14Infectedon3, "", 0);
	RegConsoleCmd("sm_off14", R14Infectedoff, "", 0);
	RegConsoleCmd("sm_addif", IFADDNumsetcheck, "", 0);
	RegConsoleCmd("sm_it", IFADDTimecheck, "", 0);
	CreateConVar("l4d2_ais_version", "1.2", "Auto Infected Spawner Version", 139584, false, 0.0, false, 0.0);
	CreateConVar("R_AutoIS", "1", "多特插件改by望夜,请用命令来开关插件!on14按cfg刷 !on141 !on142按人数刷 !addif !off14 ", 8512, false, 0.0, false, 0.0);
	hR_AutoIS_T = CreateConVar("R_AutoIS_T", "0", "默认模式;0=关;1=!on14;2=!on142;3=!on12", 0, true, 0.0, true, 3.0);
	hRIFADDNUMS = CreateConVar("l4d2_add_if", "1", "!on141 !on142模式 >4玩家时,每加1人加几特感,最多6,!addif更改本参数", 0, true, 1.0, true, 6.0);
	hDisableInVersus = CreateConVar("l4d2_ais_disable_in_versus", "1", "[0=OFF|1=ON]对抗模式时自动停用插件", 0, true, 0.0, true, 1.0);
	hFasterResponse = CreateConVar("l4d2_ais_fast_response", "1", "[0=OFF|1=ON] 快速特感响应", 0, true, 0.0, true, 1.0);
	hFasterSpawn = CreateConVar("l4d2_ais_fast_spawn", "1", "[0=OFF|1=ON] 快速特感重生 (当SI重生率高时启用)", 0, true, 0.0, true, 1.0);
	hSafeSpawn = CreateConVar("l4d2_ais_safe_spawn", "0", "[0=OFF|1=ON] 当幸存者还在安全门里时重生", 0, true, 0.0, true, 1.0);
	hScaleWeights = CreateConVar("l4d2_ais_scale_weights", "1", "[0=OFF|1=ON] SI规模重生优先级限制", 0, true, 0.0, true, 1.0);
	hWitchLimit = CreateConVar("l4d2_ais_witch_limit", "-1", "[-1 = 不接管witch重生] witches最多一次产出几个 (independant of l4d2_ais_limit).", 0, true, -1.0, true, 100.0);
	hWitchPeriod = CreateConVar("l4d2_ais_witch_period", "300.0", "间隔多久(秒)再次重生witch", 0, true, 1.0, false, 0.0);
	hWitchPeriodMode = CreateConVar("l4d2_ais_witch_period_mode", "1", "withc重生率 [0=常量|1=变量]", 0, true, 0.0, true, 1.0);
	hSpawnWeights[6] = CreateConVar("l4d2_ais_tank_weight", "-1", "[-1 = 不接管tanks重生] tank重生优先级", 0, true, -1.0, false, 0.0);
	hSpawnLimits[6] = CreateConVar("l4d2_ais_tank_limit", "0", "tanks最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnWeights[1] = CreateConVar("l4d2_ais_boomer_weight", "100", "boomer重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnWeights[2] = CreateConVar("l4d2_ais_hunter_weight", "100", "hunter重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnWeights[0] = CreateConVar("l4d2_ais_smoker_weight", "100", "smoker重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnWeights[5] = CreateConVar("l4d2_ais_charger_weight", "100", "charger重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnWeights[4] = CreateConVar("l4d2_ais_jockey_weight", "100", "jockey重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnWeights[3] = CreateConVar("l4d2_ais_spitter_weight", "100", "spitter重生优先级", 0, true, 0.0, false, 0.0);
	hSpawnLimits[1] = CreateConVar("l4d2_ais_boomer_limit", "3", "boomers最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnLimits[2] = CreateConVar("l4d2_ais_hunter_limit", "3", "hunters最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnLimits[0] = CreateConVar("l4d2_ais_smoker_limit", "3", "smokers最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnLimits[5] = CreateConVar("l4d2_ais_charger_limit", "3", "chargers最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnLimits[4] = CreateConVar("l4d2_ais_jockey_limit", "3", "jockeys最多产出几个", 0, true, 0.0, true, 14.0);
	hSpawnLimits[3] = CreateConVar("l4d2_ais_spitter_limit", "3", "spitters最多产出几个", 0, true, 0.0, true, 14.0);
	hSILimit = CreateConVar("l4d2_ais_limit", "16", "同时存在特感上限,最多28", 0, true, 1.0, true, 28.0);
	hSILimitMax = FindConVar("z_max_player_zombies");
	hSpawnSize = CreateConVar("l4d2_ais_spawn_size", "8", "一波特感重生数,最多28,最好用默认8,越多越卡", 0, true, 1.0, true, 28.0);
	hSpawnTimeMode = CreateConVar("l4d2_ais_time_mode", "0", "重生时间模式 [0=随机|1=递增|2=递减]", 0, true, 0.0, true, 2.0);
	hSpawnTimeMin = CreateConVar("l4d2_ais_time_min", "20.0", "特感最小自动重生时间(秒)", 0, true, 0.0, false, 0.0);
	hSpawnTimeMax = CreateConVar("l4d2_ais_time_max", "35.0", "特感最大自动重生时间(秒)", 0, true, 1.0, false, 0.0);
	hOA_AIS = CreateConVar("Only_Admin", "0", "[0=所有人|1=仅管理员]可使用命令", 0, true, 0.0, true, 1.0);
	hGameMode = FindConVar("mp_gamemode");
	HookConVarChange(hFasterResponse, ConVarFasterResponse);
	HookConVarChange(hFasterSpawn, ConVarFasterSpawn);
	HookConVarChange(hSafeSpawn, ConVarSafeSpawn);
	HookConVarChange(hScaleWeights, ConVarScaleWeights);
	HookConVarChange(hSILimit, ConVarSILimit);
	HookConVarChange(hSpawnSize, ConVarSpawnSize);
	HookConVarChange(hSpawnTimeMode, ConVarSpawnTimeMode);
	HookConVarChange(hSpawnTimeMin, ConVarSpawnTime);
	HookConVarChange(hSpawnTimeMax, ConVarSpawnTime);
	HookConVarChangeSpawnWeights();
	HookConVarChangeSpawnLimits();
	HookConVarChange(hGameMode, ConVarGameMode);
	HookConVarChange(hWitchLimit, ConVarWitchLimit);
	HookConVarChange(hWitchPeriod, ConVarWitchPeriod);
	HookConVarChange(hWitchPeriodMode, ConVarWitchPeriodMode);
	R14Enabled = false;
	EnabledCheck();
	SafeSpawn = GetConVarBool(hSafeSpawn);
	SILimit = GetConVarInt(hSILimit);
	R_AutoIS_T = GetConVarInt(hR_AutoIS_T);
	RIFADDNUMS = GetConVarInt(hRIFADDNUMS);
	SpawnSize = GetConVarInt(hSpawnSize);
	SpawnTimeMode = GetConVarInt(hSpawnTimeMode);
	SetSpawnTimes();
	SetSpawnWeights();
	SetSpawnLimits();
	WitchLimit = GetConVarInt(hWitchLimit);
	WitchPeriod = GetConVarFloat(hWitchPeriod);
	VariableWitchPeriod = GetConVarBool(hWitchPeriodMode);
	ChangeByConstantTime = false;
	RoundStarted = false;
	RoundEnded = false;
	LeftSafeRoom = false;
	RAScheck = false;
	AutoExecConfig(true, "R_AutoIS", "sourcemod");
	OA_AIS = GetConVarBool(hOA_AIS);
}

public Action:R14Infectedon(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon();
	return Action:0;
}

Rs14Infectedon()
{
	IFADDEnabled = false;
	SILimit = GetConVarInt(hSILimit);
	SetSpawnLimits();
	R14Enabled = true;
	EnabledCheck();
	PrintToChatAll("\x04[!警告!]\x05 开启了\x04 %d \x05特模式,请注意!关闭请输入!off14", SILimit);
	return 0;
}

public Action:R14Infectedon2(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon2();
	return Action:0;
}

Rs14Infectedon2()
{
	IFADDEnabled = true;
	R14Enabled = true;
	baseNum = 4;
	CreateTimer(0.1, ADDIFNUMCHECKSD, any:3, 0);
	return 0;
}

public Action:R14Infectedon3(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon3();
	return Action:0;
}

Rs14Infectedon3()
{
	IFADDEnabled = true;
	R14Enabled = true;
	baseNum = 0;
	CreateTimer(0.1, ADDIFNUMCHECKSD, any:3, 0);
	return 0;
}

public Action:R14Infectedoff(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	IFADDEnabled = false;
	R14Enabled = false;
	EnabledCheck();
	PrintToChatAll("\x04[!警告!]\x05 关闭了\x04 %d \x05特模式,请注意!开启请输入!on14 ", SILimit);
	return Action:0;
}

public Action:IFADDNumsetcheck(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	rDisplayIFADDMenu(client);
	return Action:0;
}

public Action:IFADDTimecheck(client, args)
{
	if (client != 0 && OA_AIS && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	rDisplayIFTimeMenu(client);
	return Action:0;
}

rDisplayIFADDMenu(client)
{
	new String:namelist[10];
	new String:nameno[4];
	new Handle:menu = CreateMenu(rIFADDNumMMNMenuHandler, MenuAction:28);
	SetMenuTitle(menu, ">4名玩家时,每+1名玩家+多少特感");
	new i = 1;
	while (i <= 6)
	{
		Format(nameno, 3, "%i", i);
		Format(namelist, 10, "%i 个", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public rIFADDNumMMNMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new R14userids;
		GetMenuItem(menu, itemNum, clientinfos, 10);
		R14userids = StringToInt(clientinfos, 10);
		RIFADDNUMS = R14userids;
		if (R14Enabled && IFADDEnabled)
		{
			CreateTimer(1.0, ADDIFNUMCHECKSD, any:0, 0);
		}
	}
	return 0;
}

rDisplayIFTimeMenu(client)
{
	new Handle:menu = CreateMenu(rIFTimeNumMMNMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "多久刷新一轮特感(秒)");
	AddMenuItem(menu, "time0", "使用CFG的配置", 0);
	AddMenuItem(menu, "time1", "Min:20-Max:35", 0);
	AddMenuItem(menu, "time2", "Min:15-Max:30", 0);
	AddMenuItem(menu, "time3", "Min:15-Max:25", 0);
	AddMenuItem(menu, "time4", "Min:15-Max:20", 0);
	AddMenuItem(menu, "time5", "Min:10-Max:20", 0);
	AddMenuItem(menu, "time6", "Min:5-Max:15", 0);
	AddMenuItem(menu, "time7", "Min:5-Max:10", 0);
	AddMenuItem(menu, "time8", "Min:1-Max:2", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public rIFTimeNumMMNMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		switch (itemNum)
		{
			case 0:
			{
				SetSpawnTimes();
			}
			case 1:
			{
				SpawnTimeMin = 20.0;
				SpawnTimeMax = 35.0;
			}
			case 2:
			{
				SpawnTimeMin = 15.0;
				SpawnTimeMax = 30.0;
			}
			case 3:
			{
				SpawnTimeMin = 15.0;
				SpawnTimeMax = 25.0;
			}
			case 4:
			{
				SpawnTimeMin = 15.0;
				SpawnTimeMax = 20.0;
			}
			case 5:
			{
				SpawnTimeMin = 10.0;
				SpawnTimeMax = 20.0;
			}
			case 6:
			{
				SpawnTimeMin = 5.0;
				SpawnTimeMax = 15.0;
			}
			case 7:
			{
				SpawnTimeMin = 5.0;
				SpawnTimeMax = 10.0;
			}
			case 8:
			{
				SpawnTimeMin = 1.0;
				SpawnTimeMax = 2.0;
			}
			default:
			{
			}
		}
		if (0 < itemNum)
		{
			RSetSpawnTimes();
		}
		new String:rtimeminStr[8];
		new String:rtimemaxStr[8];
		FloatToString(SpawnTimeMin, rtimeminStr, 5);
		FloatToString(SpawnTimeMax, rtimemaxStr, 5);
		PrintToChatAll("\x04[!警告!]\x05 特感重生时间(秒)\x04 Min:%s - Max:%s\x05,请注意!", rtimeminStr, rtimemaxStr);
	}
	return 0;
}

public Action:Event_RIFPlayerAct(Handle:event, String:name[], bool:dontBroadcast)
{
	new check14player = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!IsFakeClient(check14player))
	{
		if (R14Enabled && IFADDEnabled)
		{
			CreateTimer(3.0, ADDIFNUMCHECKSD, any:2, 0);
		}
	}
	return Action:0;
}

public Action:Event_RIFPlayerDisct(Handle:event, String:name[], bool:dontBroadcast)
{
	new RIFcheckhplayer = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (RIFcheckhplayer && !IsFakeClient(RIFcheckhplayer))
	{
		if (R14Enabled && IFADDEnabled)
		{
			CreateTimer(3.0, ADDIFNUMCHECKSD, any:1, 0);
		}
	}
	return Action:0;
}

public Action:Event_14CheckStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Check14Delays, any:0, 0);
	return Action:0;
}

public Action:Check14Delays(Handle:timer)
{
	if (R14Enabled)
	{
		if (IFADDEnabled)
		{
			PrintToChatAll("\x04[!警告!]\x05 开启了\x04 %d \x05特模式按人数增加,请注意!关闭请输入!off14 ", SILimit);
		}
		else
		{
			PrintToChatAll("\x04[!警告!]\x05 开启了\x04 %d \x05特模式,请注意!关闭请输入!off14 ", SILimit);
		}
		new String:rtimeminStr[8];
		new String:rtimemaxStr[8];
		FloatToString(SpawnTimeMin, rtimeminStr, 5);
		FloatToString(SpawnTimeMax, rtimemaxStr, 5);
		PrintToChatAll("\x04[!警告!]\x05 特感重生时间(秒)\x04 Min:%s - Max:%s\x05,请注意!", rtimeminStr, rtimemaxStr);
	}
	else
	{
		PrintToChatAll("\x04[!警告!]\x05 关闭了\x04 %d \x05特模式,请注意!开启请输入!on14 或!on142 按人数增加特感", SILimit);
	}
	EnabledCheck();
	return Action:0;
}

public Action:ADDIFNUMCHECKSD(Handle:timer, any:Rflag)
{
	if (IFADDEnabled)
	{
		new num14Players;
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) < 3 && !IsFakeClient(i))
			{
				num14Players++;
			}
			i++;
		}
		if (num14Players <= 4)
		{
			num14Players = 4;
		}
		SILimit = RIFADDNUMS * num14Players + baseNum;
		if (SILimit > 24)
		{
			SILimit = 24;
		}
		if (SILimit < 13)
		{
			i = 0;
			while (i < 7)
			{
				SpawnLimits[i] = 2;
				i++;
			}
		}
		if (SILimit > 12 && SILimit < 19)
		{
			i = 0;
			while (i < 7)
			{
				SpawnLimits[i] = 3;
				i++;
			}
		}
		if (SILimit > 18)
		{
			i = 0;
			while (i < 7)
			{
				SpawnLimits[i] = 4;
				i++;
			}
		}
	}
	else
	{
		SILimit = GetConVarInt(hSILimit);
		SetSpawnLimits();
	}
	EnabledCheck();
	SetCvars();
	switch (Rflag)
	{
		case 0:
		{
			PrintToChatAll("\x04[!提示!]\x05 特感数量增加现在是\x03 %d 特.", SILimit);
		}
		case 1:
		{
			PrintToChatAll("\x04[!提示!]\x05 -幸存者减少了,特感数量现在是\x03 %d 特.", SILimit);
		}
		case 2:
		{
			PrintToChatAll("\x04[!提示!]\x05 +幸存者增加了,特感数量现在是\x03 %d 特.", SILimit);
		}
		case 3:
		{
			PrintToChatAll("\x04[!警告!]\x05 开启了\x04 %d \x05特模式按人数增加,请注意!关闭请输入!off14", SILimit);
		}
		default:
		{
		}
	}
	return Action:0;
}

public OnConfigsExecuted()
{
	SetCvars();
	GameModeCheck();
	if (GameMode == 2 && GetConVarBool(hDisableInVersus))
	{
		R14Enabled = false;
	}
}

HookEvents()
{
	if (!EventsHooked)
	{
		EventsHooked = true;
		HookEvent("round_start", evtRoundStart, EventHookMode:1);
		HookEvent("round_end", evtRoundEnd, EventHookMode:0);
		HookEvent("map_transition", evtRoundEnd, EventHookMode:0);
		HookEvent("create_panic_event", evtSurvivalStart, EventHookMode:1);
		HookEvent("player_death", evtInfectedDeath, EventHookMode:1);
	}
	return 0;
}

UnhookEvents()
{
	if (EventsHooked)
	{
		EventsHooked = false;
		UnhookEvent("round_start", evtRoundStart, EventHookMode:1);
		UnhookEvent("round_end", evtRoundEnd, EventHookMode:0);
		UnhookEvent("map_transition", evtRoundEnd, EventHookMode:0);
		UnhookEvent("create_panic_event", evtSurvivalStart, EventHookMode:1);
		UnhookEvent("player_death", evtInfectedDeath, EventHookMode:1);
	}
	return 0;
}

HookConVarChangeSpawnWeights()
{
	new i;
	while (i < 7)
	{
		HookConVarChange(hSpawnWeights[i], ConVarSpawnWeights);
		i++;
	}
	return 0;
}

HookConVarChangeSpawnLimits()
{
	new i;
	while (i < 7)
	{
		HookConVarChange(hSpawnLimits[i], ConVarSpawnLimits);
		i++;
	}
	return 0;
}

SetSpawnLimits()
{
	new i;
	while (i < 7)
	{
		SpawnLimits[i] = GetConVarInt(hSpawnLimits[i]);
		i++;
	}
	return 0;
}

public ConVarEnabled(Handle:convar, String:oldValue[], String:newValue[])
{
	EnabledCheck();
	return 0;
}

public ConVarFasterResponse(Handle:convar, String:oldValue[], String:newValue[])
{
	SetAIDelayCvars();
	return 0;
}

public ConVarFasterSpawn(Handle:convar, String:oldValue[], String:newValue[])
{
	SetAISpawnCvars();
	return 0;
}

public ConVarSafeSpawn(Handle:convar, String:oldValue[], String:newValue[])
{
	SafeSpawn = GetConVarBool(hSafeSpawn);
	return 0;
}

public ConVarScaleWeights(Handle:convar, String:oldValue[], String:newValue[])
{
	ScaleWeights = GetConVarBool(hScaleWeights);
	return 0;
}

public ConVarSILimit(Handle:convar, String:oldValue[], String:newValue[])
{
	SILimit = GetConVarInt(hSILimit);
	CalculateSpawnTimes();
	if (LeftSafeRoom)
	{
		StartSpawnTimer();
	}
	return 0;
}

public ConVarSpawnSize(Handle:convar, String:oldValue[], String:newValue[])
{
	SpawnSize = GetConVarInt(hSpawnSize);
	return 0;
}

public ConVarSpawnTimeMode(Handle:convar, String:oldValue[], String:newValue[])
{
	SpawnTimeMode = GetConVarInt(hSpawnTimeMode);
	CalculateSpawnTimes();
	if (LeftSafeRoom)
	{
		StartSpawnTimer();
	}
	return 0;
}

public ConVarSpawnTime(Handle:convar, String:oldValue[], String:newValue[])
{
	if (!ChangeByConstantTime)
	{
		RSetSpawnTimes();
	}
	return 0;
}

public ConVarSpawnWeights(Handle:convar, String:oldValue[], String:newValue[])
{
	SetSpawnWeights();
	if (WitchLimit < 0 && SpawnWeights[6] >= 0)
	{
		SetConVarInt(FindConVar("director_no_bosses"), 1, false, false);
		SetConVarInt(hWitchLimit, 0, false, false);
	}
	else
	{
		if (WitchLimit >= 0 && SpawnWeights[6] < 0)
		{
			SetConVarInt(FindConVar("director_no_bosses"), 0, false, false);
			SetConVarInt(hWitchLimit, -1, false, false);
		}
	}
	return 0;
}

public ConVarSpawnLimits(Handle:convar, String:oldValue[], String:newValue[])
{
	SetSpawnLimits();
	return 0;
}

public ConVarWitchLimit(Handle:convar, String:oldValue[], String:newValue[])
{
	WitchLimit = GetConVarInt(hWitchLimit);
	if (WitchLimit < 0 && SpawnWeights[6] >= 0)
	{
		SetConVarInt(FindConVar("director_no_bosses"), 0, false, false);
		SetConVarInt(hSpawnWeights[6], -1, false, false);
	}
	else
	{
		if (WitchLimit >= 0 && SpawnWeights[6] < 0)
		{
			SetConVarInt(FindConVar("director_no_bosses"), 1, false, false);
			SetConVarInt(hSpawnWeights[6], 0, false, false);
		}
	}
	if (LeftSafeRoom && WitchLimit > 0)
	{
		RestartWitchTimer(0.0);
	}
	return 0;
}

public ConVarWitchPeriod(Handle:convar, String:oldValue[], String:newValue[])
{
	WitchPeriod = GetConVarFloat(hWitchPeriod);
	if (LeftSafeRoom && WitchLimit > 0)
	{
		RestartWitchTimer(0.0);
	}
	return 0;
}

public ConVarWitchPeriodMode(Handle:convar, String:oldValue[], String:newValue[])
{
	VariableWitchPeriod = GetConVarBool(hWitchPeriodMode);
	if (LeftSafeRoom && WitchLimit > 0)
	{
		RestartWitchTimer(0.0);
	}
	return 0;
}

public ConVarGameMode(Handle:convar, String:oldValue[], String:newValue[])
{
	GameModeCheck();
	return 0;
}

EnabledCheck()
{
	SetCvars();
	if (R14Enabled)
	{
		HookEvents();
		InitTimers();
	}
	else
	{
		UnhookEvents();
	}
	return 0;
}

InitTimers()
{
	if (LeftSafeRoom)
	{
		StartTimers();
	}
	else
	{
		if (GameMode != 3 && !SafeRoomChecking)
		{
			SafeRoomChecking = true;
			CreateTimer(1.0, PlayerLeftStart, any:0, 0);
		}
	}
	return 0;
}

SetCvars()
{
	if (R14Enabled)
	{
		SetConVarBounds(hSILimitMax, ConVarBounds:0, true, float(28));
		SetConVarFloat(hSILimitMax, float(28), false, false);
		SetConVarInt(FindConVar("z_boomer_limit"), 0, false, false);
		SetConVarInt(FindConVar("z_hunter_limit"), 0, false, false);
		SetConVarInt(FindConVar("z_smoker_limit"), 0, false, false);
		SetConVarInt(FindConVar("z_charger_limit"), 0, false, false);
		SetConVarInt(FindConVar("z_spitter_limit"), 0, false, false);
		SetConVarInt(FindConVar("z_jockey_limit"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_boomers"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_hunters"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_smokers"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_chargers"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_spitters"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_jockeys"), 0, false, false);
		SetConVarInt(FindConVar("survival_max_specials"), SILimit, false, false);
		SetBossesCvar();
		SetConVarInt(FindConVar("director_spectate_specials"), 1, false, false);
	}
	else
	{
		ResetConVar(FindConVar("z_max_player_zombies"), false, false);
		ResetConVar(FindConVar("z_boomer_limit"), false, false);
		ResetConVar(FindConVar("z_hunter_limit"), false, false);
		ResetConVar(FindConVar("z_smoker_limit"), false, false);
		ResetConVar(FindConVar("z_charger_limit"), false, false);
		ResetConVar(FindConVar("z_spitter_limit"), false, false);
		ResetConVar(FindConVar("z_jockey_limit"), false, false);
		ResetConVar(FindConVar("survival_max_boomers"), false, false);
		ResetConVar(FindConVar("survival_max_hunters"), false, false);
		ResetConVar(FindConVar("survival_max_smokers"), false, false);
		ResetConVar(FindConVar("survival_max_chargers"), false, false);
		ResetConVar(FindConVar("survival_max_spitters"), false, false);
		ResetConVar(FindConVar("survival_max_jockeys"), false, false);
		ResetConVar(FindConVar("survival_max_specials"), false, false);
		ResetConVar(FindConVar("director_no_bosses"), false, false);
		ResetConVar(FindConVar("director_spectate_specials"), false, false);
	}
	SetAIDelayCvars();
	SetAISpawnCvars();
	return 0;
}

SetBossesCvar()
{
	if (WitchLimit < 0 || SpawnWeights[6] < 0)
	{
		SetConVarInt(FindConVar("director_no_bosses"), 0, false, false);
	}
	else
	{
		SetConVarInt(FindConVar("director_no_bosses"), 1, false, false);
	}
	return 0;
}

SetAIDelayCvars()
{
	FasterResponse = GetConVarBool(hFasterResponse);
	if (FasterResponse)
	{
		SetConVarInt(FindConVar("boomer_exposed_time_tolerance"), 0, false, false);
		SetConVarInt(FindConVar("boomer_vomit_delay"), 0, false, false);
		SetConVarInt(FindConVar("smoker_tongue_delay"), 0, false, false);
		SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0, false, false);
	}
	else
	{
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), false, false);
		ResetConVar(FindConVar("boomer_vomit_delay"), false, false);
		ResetConVar(FindConVar("smoker_tongue_delay"), false, false);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), false, false);
	}
	return 0;
}

SetAISpawnCvars()
{
	FasterSpawn = GetConVarBool(hFasterSpawn);
	if (FasterSpawn)
	{
		SetConVarInt(FindConVar("z_spawn_safety_range"), 0, false, false);
	}
	else
	{
		ResetConVar(FindConVar("z_spawn_safety_range"), false, false);
	}
	return 0;
}

GameModeCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, 16);
	if (StrContains(GameName, "survival", false) != -1)
	{
		GameMode = 1;
	}
	else
	{
		if (StrContains(GameName, "versus", false) != -1)
		{
			GameMode = 1;
		}
		if (StrContains(GameName, "coop", false) != -1)
		{
			GameMode = 1;
		}
		GameMode = 1;
	}
	return 0;
}

SetSpawnTimes()
{
	SpawnTimeMin = GetConVarFloat(hSpawnTimeMin);
	SpawnTimeMax = GetConVarFloat(hSpawnTimeMax);
	if (SpawnTimeMin > SpawnTimeMax)
	{
		SetConVarFloat(hSpawnTimeMin, SpawnTimeMax, false, false);
	}
	else
	{
		if (SpawnTimeMax < SpawnTimeMin)
		{
			SetConVarFloat(hSpawnTimeMax, SpawnTimeMin, false, false);
		}
		CalculateSpawnTimes();
		if (LeftSafeRoom)
		{
			StartSpawnTimer();
		}
	}
	return 0;
}

RSetSpawnTimes()
{
	CalculateSpawnTimes();
	if (LeftSafeRoom)
	{
		StartSpawnTimer();
	}
	return 0;
}

CalculateSpawnTimes()
{
	new i;
	if (SILimit > 1 && SpawnTimeMode > 0)
	{
		new Float:unit = SpawnTimeMax - SpawnTimeMin / SILimit + -1;
		switch (SpawnTimeMode)
		{
			case 1:
			{
				SpawnTimes[0] = SpawnTimeMin;
				i = 1;
				while (i <= 28)
				{
					if (i < SILimit)
					{
						SpawnTimes[i] = SpawnTimes[i -1] + unit;
					}
					else
					{
						SpawnTimes[i] = SpawnTimeMax;
					}
					i++;
				}
			}
			case 2:
			{
				SpawnTimes[0] = SpawnTimeMax;
				i = 1;
				while (i <= 28)
				{
					if (i < SILimit)
					{
						SpawnTimes[i] = SpawnTimes[i + -1] - unit;
					}
					else
					{
						SpawnTimes[i] = SpawnTimeMax;
					}
					i++;
				}
			}
			default:
			{
			}
		}
	}
	else
	{
		SpawnTimes[0] = SpawnTimeMax;
	}
	return 0;
}

SetSpawnWeights()
{
	new i;
	new weight;
	new TotalWeight;
	i = 0;
	while (i < 7)
	{
		weight = GetConVarInt(hSpawnWeights[i]);
		SpawnWeights[i] = weight;
		if (0 <= weight)
		{
			TotalWeight = weight + TotalWeight;
		}
		i++;
	}
	return 0;
}

GenerateSpawn(client)
{
	CountSpecialInfected(); //refresh infected count
	if (SICount < SILimit) //spawn when infected count hasn't reached limit
	{
		new size;
		if (SpawnSize > SILimit - SICount) //prevent amount of special infected from exceeding SILimit
			size = SILimit - SICount;
		else
			size = SpawnSize;
		
		new index;
		new SpawnQueue[MAX_INFECTED] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
		
		//refresh current SI counts
		SITypeCount();
		
		//generate the spawn queue
		for (new i = 0; i < size; i++)
		{
			index = GenerateIndex();
			if (index == -1)
				break;
			SpawnQueue[i]= index;
			SpawnCounts[index] += 1;
		}
		
		for (new i = 0; i < MAX_INFECTED; i++)
		{
			if(SpawnQueue[i] < 0) //stops if the current array index is out of bound
				break;
			new bot = CreateFakeClient("Infected Bot");
			if (bot != 0)
			{
				ChangeClientTeam(bot,TEAM_INFECTED);
				CreateTimer(0.1,kickbot,bot);
			}	
			CheatCommand(client, "z_spawn_old", Spawns[SpawnQueue[i]]); 
			
			#if DEBUG_SPAWNS
				LogMessage("[AIS] Spawned %s", Spawns[SpawnQueue[i]]);
			#endif
		}
	}
}

SITypeCount()
{
	for (new i = 0; i < NUM_TYPES_INFECTED; i++)
		SpawnCounts[i] = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		//If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		//We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		//Check if client is infected ...
		if (GetClientTeam(i)==3)
		{
			switch (GetEntProp(i,Prop_Send,"m_zombieClass")) //detect SI type
			{
				case IS_SMOKER:
					SpawnCounts[SI_SMOKER]++;
				
				case IS_BOOMER:
					SpawnCounts[SI_BOOMER]++;
				
				case IS_HUNTER:
					SpawnCounts[SI_HUNTER]++;
				
				case IS_SPITTER:
					SpawnCounts[SI_SPITTER]++;
				
				case IS_JOCKEY:
					SpawnCounts[SI_JOCKEY]++;
				
				case IS_CHARGER:
					SpawnCounts[SI_CHARGER]++;
				
				case IS_TANK:
					SpawnCounts[SI_TANK]++;
			}
		}
	}
}

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			client = target;
			break;
		}
		
		return; // case no valid Client found
	}
	
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

GenerateIndex()
{
	new TotalSpawnWeight, StandardizedSpawnWeight;
	
	//temporary spawn weights factoring in SI spawn limits
	decl TempSpawnWeights[NUM_TYPES_INFECTED];
	for(new i = 0; i < NUM_TYPES_INFECTED; i++)
	{
		if(SpawnCounts[i] < SpawnLimits[i])
		{
			if(ScaleWeights)
				TempSpawnWeights[i] = (SpawnLimits[i] - SpawnCounts[i]) * SpawnWeights[i];
			else
				TempSpawnWeights[i] = SpawnWeights[i];
		}
		else
			TempSpawnWeights[i] = 0;
		
		TotalSpawnWeight += TempSpawnWeights[i];
	}
	
	//calculate end intervals for each spawn
	new Float:unit = 1.0/TotalSpawnWeight;
	for (new i = 0; i < NUM_TYPES_INFECTED; i++)
	{
		if (TempSpawnWeights[i] >= 0)
		{
			StandardizedSpawnWeight += TempSpawnWeights[i];
			IntervalEnds[i] = StandardizedSpawnWeight * unit;
		}
	}
	
	new Float:r = GetRandomFloat(0.0, 1.0); //selector r must be within the ith interval for i to be selected
	for (new i = 0; i < NUM_TYPES_INFECTED; i++)
	{
		//negative and 0 weights are ignored
		if (TempSpawnWeights[i] <= 0) continue;
		//r is not within the ith interval
		if (IntervalEnds[i] < r) continue;
		//selected index i because r is within ith interval
		return i;
	}
	return -1; //no selection because all weights were negative or 0
}

//special infected spawn timer based on time modes
StartSpawnTimer()
{
	//prevent multiple timer instances
	EndSpawnTimer();
	//only start spawn timer if plugin is enabled
	if (R14Enabled)
	{
		new Float:time;
		CountSpecialInfected();
		
		if (SpawnTimeMode > 0) //NOT randomization spawn time mode
			time = SpawnTimes[SICount]; //a spawn time based on the current amount of special infected
		else //randomization spawn time mode
			time = GetRandomFloat(SpawnTimeMin, SpawnTimeMax); //a random spawn time between min and max inclusive

		SpawnTimerStarted = true;
		hSpawnTimer = CreateTimer(time, SpawnInfectedAuto);
		#if DEBUG_TIMES
		LogMessage("[AIS] Mode: %d | SI: %d | Next: %.3f s", SpawnTimeMode, SICount, time);
		#endif
	}
}

//never directly set hSpawnTimer, use this function for custom spawn times
StartCustomSpawnTimer(Float:time)
{
	//prevent multiple timer instances
	EndSpawnTimer();
	//only start spawn timer if plugin is enabled
	if (R14Enabled)
	{
		SpawnTimerStarted = true;
		hSpawnTimer = CreateTimer(time, SpawnInfectedAuto);
	}
}
EndSpawnTimer()
{
	if (SpawnTimerStarted)
	{
		CloseHandle(hSpawnTimer);
		SpawnTimerStarted = false;
	}
}

StartWitchWaitTimer(Float:time)
{
	EndWitchWaitTimer();
	if (R14Enabled && WitchLimit > 0)
	{
		if (WitchCount < WitchLimit)
		{
			WitchWaitTimerStarted = true;
			hWitchWaitTimer = CreateTimer(time, StartWitchTimer);
			#if DEBUG_TIMES
			LogMessage("[AIS] Mode: %b | Witches: %d | Next(WitchWait): %.3f s", VariableWitchPeriod, WitchCount, time);
			#endif
		}
		else //if witch count reached limit, wait until a witch killed event to start witch timer
		{
			WitchCountFull = true;
			#if DEBUG_TIMES
			LogMessage("[AIS] Witch Limit reached. Waiting for witch death.");
			#endif		
		}
	}
}
public Action:StartWitchTimer(Handle:timer)
{
	WitchWaitTimerStarted = false;
	EndWitchTimer();
	if (R14Enabled && WitchLimit > 0)
	{
		new Float:time;
		if (VariableWitchPeriod)
			time = GetRandomFloat(0.0, WitchPeriod);
		else
			time = WitchPeriod;
		
		WitchTimerStarted = true;
		hWitchTimer = CreateTimer(time, SpawnWitchAuto, WitchPeriod-time);
		#if DEBUG_TIMES
		LogMessage("[AIS] Mode: %b | Witches: %d | Next(Witch): %.3f s", VariableWitchPeriod, WitchCount, time);
		#endif
	}
	return Plugin_Handled;
}
EndWitchWaitTimer()
{
	if (WitchWaitTimerStarted)
	{
		CloseHandle(hWitchWaitTimer);
		WitchWaitTimerStarted = false;
	}
}
EndWitchTimer()
{
	if (WitchTimerStarted)
	{
		CloseHandle(hWitchTimer);
		WitchTimerStarted = false;
	}
}
//take account of both witch timers when restarting overall witch timer
RestartWitchTimer(Float:time)
{
	EndWitchTimer();
	StartWitchWaitTimer(time);
}

StartTimers()
{
	StartSpawnTimer();
	RestartWitchTimer(0.0);
}
EndTimers()
{
	EndSpawnTimer();
	EndWitchWaitTimer();
	EndWitchTimer();
}

public Action:SpawnInfectedAuto(Handle:timer)
{
	SpawnTimerStarted = false; //spawn timer always stops here (the non-repeated spawn timer calls this function)
	if (LeftSafeRoom) //only spawn infected and repeat spawn timer when survivors have left safe room
	{
		new client = GetAnyClient();
		if (client) //make sure client is in-game
		{
			GenerateSpawn(client);
			StartSpawnTimer();
		}
		else //longer timer for when invalid client was returned (prevent a potential infinite loop when there are 0 SI)
			StartCustomSpawnTimer(SpawnTimeMax);
	}

	return Plugin_Handled;
}

public Action:SpawnWitchAuto(Handle:timer, any:waitTime)
{
	WitchTimerStarted = false;
	if (LeftSafeRoom)
	{
		new client = GetAnyClient();
		if (client)
		{
			if (WitchCount < WitchLimit)
				ExecuteCheatCommand(client, "z_spawn_old", "witch", "auto");
			StartWitchWaitTimer(waitTime);
		}
		else
			StartWitchWaitTimer(waitTime+1.0);
	}
	return Plugin_Handled;
}

ExecuteCheatCommand(client, const String:command[], String:param1[], String:param2[]) 
{
	//Hold original user flag for restoration, temporarily give user root admin flag (prevent conflict with admincheats)
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	
	//Removes sv_cheat flag from command
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);

	FakeClientCommand(client, "%s %s %s", command, param1, param2);
	
	//Restore command flag and user flag
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

CountSpecialInfected()
{
	//reset counter
	SICount = 0;
	
	//First we count the amount of infected players
	for (new i = 1; i <= MaxClients; i++)
	{
		//If player is not connected ...
		if (!IsClientConnected(i)) continue;
		
		//We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		//Check if client is infected ...
		if (GetClientTeam(i)==3)
			SICount++;
	}
}

public GetAnyClient ()
{
	for (new  i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
			return i;
	}
	return 0;
}

//MI 5
public Action:evtRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	//If round haven't started
	if (!RoundStarted)
	{
		//and we reset some variables
		RoundEnded = false;
		RoundStarted = true;
		LeftSafeRoom = SafeSpawn; //depends on whether special infected should spawn while survivors are in starting safe room
		WitchCount = 0;
		SpawnTimerStarted = false;
		WitchTimerStarted = false;
		WitchWaitTimerStarted = false;
		WitchCountFull = false;

		InitTimers();
	}
}

//MI 5
public Action:evtRoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{	
	//If round has not been reported as ended ..
	if (!RoundEnded)
	{
		//we mark the round as ended
		EndTimers();
		RoundEnded = true;
		RoundStarted = false;
		LeftSafeRoom = false;
	}
}

//MI 5
public Action:PlayerLeftStart(Handle:Timer)
{
	if (LeftStartArea())
	{
		// We don't care who left, just that at least one did
		if (!LeftSafeRoom)
		{
			LeftSafeRoom = true;
			StartTimers();		
		}
		SafeRoomChecking = false;
	}
	else
		CreateTimer(1.0, PlayerLeftStart);
	
	return Plugin_Continue;
}

//MI 5
bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

//MI 5
//This is hooked to the panic event, but only starts if its survival. This is what starts up the bots in survival.
public Action:evtSurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 3)
	{  
		if (!LeftSafeRoom)
		{
			LeftSafeRoom = true;
			StartTimers();
		}
	}
	return Plugin_Continue;
}

//Kick infected bots immediately after they die to allow quicker infected respawn
public Action:evtInfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FasterSpawn)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (client) {
			if (GetClientTeam(client) == 3 && IsFakeClient(client))
				KickClient(client, "");
		}
	}
}

public Action:evtWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	WitchCount++;
}

/*
public Action:evtWitchHarasse(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:names[32];
	new killer = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(killer) == 2) //only show message if player is in survivor team
	{
		GetClientName(killer, names, sizeof(names));
		PrintToChatAll("%s startled the Witch!",names);
	}
}
*/
public Action:evtWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	WitchCount--;
	if (WitchCountFull)
	{
		WitchCountFull = false;
		StartWitchWaitTimer(0.0);
	}
}

public OnMapEnd()
{
	RoundStarted = false;
	RoundEnded = true;
	LeftSafeRoom = false;
	//KillTimer(timer);

}

public OnMapStart()
{
	OA_AIS = GetConVarBool(hOA_AIS);
	if (!RAScheck)
	{
		R_AutoIS_T = GetConVarInt(hR_AutoIS_T);
		if (R_AutoIS_T < 0 || R_AutoIS_T > 2)
		{
			R_AutoIS_T = 0;
		}
		if (R_AutoIS_T == 1)
		{
			Rs14Infectedon();
		}
		if (R_AutoIS_T == 2)
		{
			Rs14Infectedon2();
		}
		if (R_AutoIS_T == 2)
		{
			Rs14Infectedon3();
		}
		RAScheck = true;
	}
}

public Action:Event_RASFinaleWin(Handle:event, String:name[], bool:dontBroadcast)
{
	RAScheck = false;
	return Action:0;
}

