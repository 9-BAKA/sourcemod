#include <sourcemod>
#include <sdktools_functions>

Handle hMoremedicals;
int Mormedicals;
bool RCMcheck;
bool RCMFSpawn;
Handle hOA_MNN;
bool OA_MNN;

public Plugin myinfo =
{
	name = "L4D2 Multiplayer RMC",
	description = "L4D2 Multiplayer Commands",
	author = "Ryanx，joyist",
	version = "1.2",
	url = "http://chdong.top/"
};

public void OnPluginStart()
{
	CreateConVar("L4D2_More_Medical_Version", "1.1", "L4D2更多医疗补给v1.1", 8512, false, 0.0, false, 0.0);
	RegConsoleCmd("sm_mmn", MMNNumsetcheck, "", 0);
	HookEvent("round_start", Event_MMNRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_activate", Event_MMNPlayerAct, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MMNMapTransition, EventHookMode_PostNoCopy);
	hMoremedicals = CreateConVar("L4D2_More_Medical", "1", "医疗补给倍数[包&药&针&近战](例3倍表示一个包可以拿3次)", 0, true, 1.0, true, 99.0);
	hOA_MNN = CreateConVar("Only_Admin", "1", "[0=所有人|1=仅管理员]可使用命令", 0, true, 0.0, true, 1.0);
	HookConVarChange(hOA_MNN, ConVarChanged);
	AutoExecConfig(true, "l4d2_more_medical", "sourcemod");
	Mormedicals = GetConVarInt(hMoremedicals);
	OA_MNN = GetConVarBool(hOA_MNN);
	RCMcheck = false;
	RCMFSpawn = false;
}

public void OnMapStart()
{
	OA_MNN = GetConVarBool(hOA_MNN);
	if (!RCMcheck)
	{
		Mormedicals = GetConVarInt(hMoremedicals);
		if (Mormedicals < 1)
		{
			Mormedicals = 1;
		}
	}
}

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	Mormedicals = GetConVarInt(hMoremedicals);
	OA_MNN = GetConVarBool(hOA_MNN);
}

public Action Event_MMNPlayerAct(Event event, char[] name, bool dontBroadcast)
{
	if (!RCMFSpawn)
	{
		new MallnumPlayers;
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) < 3)
			{
				MallnumPlayers++;
			}
			i++;
		}
		if (MallnumPlayers == 2)
		{
			RCMFSpawn = true;
			CreateTimer(1.0, MMNsRepDelays, any:0, 0);
		}
	}
	return Plugin_Continue;
}

public Action Event_MMNRoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, MMNsRepDelays, any:0, 0);
	return Plugin_Continue;
}

public Action Event_MMNMapTransition(Event event, char[] name, bool dontBroadcast)
{
	RCMFSpawn = false;
	return Plugin_Continue;
}

public Action MMNNumsetcheck(client, args)
{
	if (OA_MNN && !GetUserFlagBits(client) && client != 0)
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Plugin_Continue;
	}
	if (args > 0)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int num = StringToInt(arg, 10);
		Mormedicals = num;
		RCMcheck = true;
		CreateTimer(1.0, MMNsRepDelays, any:0, 0);
	}
	rDisplayMMNMenu(client);
	return Plugin_Continue;
}

rDisplayMMNMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new Handle:menu = CreateMenu(rNumMMNMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "医疗补给倍数");
	new i = 1;
	while (i <= 6)
	{
		Format(nameno, 3, "%d 倍", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public rNumMMNMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new userids;
		GetMenuItem(menu, itemNum, clientinfos, 10);
		userids = StringToInt(clientinfos, 10);
		Mormedicals = userids;
		RCMcheck = true;
		CreateTimer(1.0, MMNsRepDelays, any:0, 0);
	}
}

public Action MMNsRepDelays(Handle timer)
{
	if (Mormedicals < 1)
	{
		Mormedicals = 1;
	}
	new String:Mormedicalsnums[4];
	Format(Mormedicalsnums, 2, "%d", Mormedicals);
	MMNRepNums("weapon_first_aid_kit_spawn", Mormedicalsnums);
	MMNRepNums("weapon_pain_pills_spawn", Mormedicalsnums);
	MMNRepNums("weapon_adrenaline_spawn", Mormedicalsnums);
	MMNRepNums("weapon_melee_spawn", Mormedicalsnums);
	// PrintToChatAll("\x04[!提示!]\x03 已开启 %d 倍医疗补给.", Mormedicals);
	return Plugin_Continue;
}

public MMNRepNums(String:itemname[], String:mmnums[])
{
	new mmnindex = FindEntityByClassname(-1, itemname);
	while (mmnindex != -1)
	{
		DispatchKeyValue(mmnindex, "count", mmnums);
		mmnindex = FindEntityByClassname(mmnindex, itemname);
	}
}