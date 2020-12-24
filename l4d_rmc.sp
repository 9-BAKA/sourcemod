#include <sourcemod>
#include <sdktools_functions>
#pragma semicolon 1
#pragma newdecls required

bool RJoincheck;
bool RCNcheck;
bool RAutoBotcheck;
Handle hRJoincheck;
Handle hAutoBotcheck;
Handle hAwayCEnable;
Handle hKickEnable;
Handle hUsermnums;
int usermnums;
int AwayCEnable;
int KickEnable;
char Rmc_ChangeTeam[MAXPLAYERS+1];
bool ConnectedClient[MAXPLAYERS+1];

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
    CreateConVar("L4D2_Multiplayer_RMC_version", "1.1", "L4D2多人游戏设置");
    RegConsoleCmd("sm_jg", Jointhegame, "加入幸存者");
    RegConsoleCmd("sm_join", Jointhegame, "加入幸存者");
    RegConsoleCmd("sm_joingame", Jointhegame, "加入幸存者");
    RegConsoleCmd("sm_away", Gotoaway, "闲置到观察者");
    RegConsoleCmd("sm_away2", Gotoaway2, "使用电脑托管");
    RegConsoleCmd("sm_diannao", CreateOneBot, "增加电脑");
    RegConsoleCmd("sm_addbot", CreateOneBot, "增加电脑");
    RegConsoleCmd("sm_sinfo", Vserverinfo, "获取服务器人数信息");
    RegConsoleCmd("sm_bd", Bindkeyhots, "绑定基础按键");
    RegConsoleCmd("sm_rhelp", Scdescription, "显示帮助信息");
    RegConsoleCmd("sm_kb", Kbcheck, "踢出所有电脑");
    RegConsoleCmd("sm_kb2", Kbcheck2, "将所有闲置玩家转入观察者");
    RegConsoleCmd("sm_sp", RListLoadplayer, "列出玩家加载状态");
    RegConsoleCmd("sm_zs", Rzhisha, "自杀");
    RegAdminCmd("sm_set", Numsetcheck, ADMFLAG_ROOT, "设置服务器人数");

    HookEvent("round_start", Event_rmcRoundStart, EventHookMode_Post);
    HookEvent("player_team", Event_rmcteam, EventHookMode_Pre);

    hUsermnums = CreateConVar("L4D2_Rmc_total", "8", "服务器支持玩家人数设置");
    hRJoincheck = CreateConVar("l4d2_ADM_CHA", "0", "开启几个管理员预留通道");
    hAwayCEnable = CreateConVar("L4D2_Away_Enable", "0", "是否只允许管理员使用away指令加入观察者");
    hAutoBotcheck = CreateConVar("l4d2_AUOT_ADDBOT", "1", "是否开启自动增加BOT");
    hKickEnable = CreateConVar("L4D2_Kick_Enable", "1", "是否开启自动踢出多余BOT");
    RCNcheck = false;
    for (int i = 0; i <= MAXPLAYERS; i++)
    {
        Rmc_ChangeTeam[i] = 0;
        ConnectedClient[i] = false;
    }

    HookConVarChange(hUsermnums, CVARChanged);
    HookConVarChange(hRJoincheck, CVARChanged);
    HookConVarChange(hAwayCEnable, CVARChanged);
    HookConVarChange(hAutoBotcheck, CVARChanged);
    HookConVarChange(hKickEnable, CVARChanged);

    AutoExecConfig(true, "l4d2_rmc");
}

public void OnMapStart()
{
    SetConVarInt(FindConVar("z_spawn_flow_limit"), 999999, false, false);
    RJoincheck = GetConVarBool(hRJoincheck);
    AwayCEnable = GetConVarBool(hAwayCEnable);
    KickEnable = GetConVarBool(hKickEnable);
    RAutoBotcheck = GetConVarBool(hAutoBotcheck);
    if (!RCNcheck)
    {
        usermnums = GetConVarInt(hUsermnums);
        if (usermnums < 1)
        {
            usermnums = 1;
        }
    }
}

public void OnMapEnd()
{
    ServerCommand("sm_kb2");
}

public void CVARChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    RJoincheck = GetConVarBool(hRJoincheck);
    AwayCEnable = GetConVarBool(hAwayCEnable);
    KickEnable = GetConVarBool(hKickEnable);
    RAutoBotcheck = GetConVarBool(hAutoBotcheck);
    if (!RCNcheck)
    {
        usermnums = GetConVarInt(hUsermnums);
        if (usermnums < 1)
        {
            usermnums = 1;
        }
    }
}

public Action Event_rmcRoundStart(Event event, char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, rmcRepDelays);
}

public Action Jointhegame(int client, int args)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    if (!IsClientObserver(client))
    {
        PrintToChat(client, "\x05[加入失败:]\x04你已经在游戏里了！");
    }
    else if (0 < Botnums())
    {
        if (0 < Alivebotnums())
        {
            ClientCommand(client, "jointeam 2");
            ClientCommand(client, "go_away_from_keyboard");
        }
        else
        {
            // CheatCommand(client, "sb_takecontrol");
            ClientCommand(client, "jointeam 2");
            ClientCommand(client, "go_away_from_keyboard");
            PrintToChat(client, "\x05[加入成功:]\x04但由于没有存活电脑，你当前为死亡状态.");
        }
    }
    else
    {
        LCreateOneBot(client);
        CreateTimer(1.5, PlayerJoin, client);
    }
    // PrintToChat(client, "\x05[加入失败:]\x04没有足够的BOT允许你控制,请输入!diannao增加电脑然后输入!jg加入.");
    return Plugin_Handled;
}

public Action PlayerJoin(Handle timer, any client)
{
    ClientCommand(client, "jointeam 2");
    ClientCommand(client, "go_away_from_keyboard");
}

public int CheatCommand(int Client, char[] command)
{
    if (!Client)
    {
        return 0;
    }
    int admindata = GetUserFlagBits(Client);
    SetUserFlagBits(Client, 16384);
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & -16385);
    FakeClientCommand(Client, "%s", command);
    SetCommandFlags(command, flags);
    SetUserFlagBits(Client, admindata);
    return 0;
}

public void OnClientDisconnect(int client)
{
    if(!IsFakeClient(client))
    {
        int userid = GetClientUserId(client);
        CreateTimer(5.0, Check, userid);
    }
}

public Action RACMEvent_FinaleWin(Handle event, char name, bool dontBroadcast)
{
    for (int i = 0; i <= MAXPLAYERS; i++)
        Rmc_ChangeTeam[i] = 0;
}

public Action Check(Handle Timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(client == 0 || !IsClientConnected(client))
    {
        CreateTimer(1.0, DisKickClient);
        Rmc_ChangeTeam[client] = 0;
    }
}

public Action DisKickClient(Handle timer)
{
    int playernum = 0;
    int specnum = 0;
    int botnum = 0;
    playernum = Playernums();
    specnum = Gonaways();
    botnum = Botnums();
    KickEnable = GetConVarBool(hKickEnable);
    if (KickEnable && playernum > 4 && botnum > specnum)
    {
        int i = MaxClients;
        while (i > 0 && playernum > 4 && botnum > specnum)
        {
            if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
            {
                KickClient(i, "踢出多余电脑");
                botnum--;
            }
            i--;
        }
    }
}

public Action rmcRepDelays(Handle timer)
{
    if (usermnums < 1)
    {
        usermnums = 1;
    }
    if (RJoincheck)
    {
        //ServerCommand("sm_cvar sv_maxplayers %i", usermnums + 2);
        //ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
        PrintToChatAll("\x04[提示] \x03公共位置\x01[%i] \x03管理员预留位置\x01[2]", 2272);
    }
    else
    {
        //ServerCommand("sm_cvar sv_maxplayers %i", usermnums);
        //ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
    }
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if (RJoincheck)
    {
        int Rnmax = GetConVarInt(FindConVar("sv_maxplayers"));
        int playernum = Allplayersn();  // 非管理员人数
        int reserved = 0;
        if (Rnmax - reserved < playernum)
        {
            if (!GetUserFlagBits(client))
            {
                KickClient(client, "服务器已满,你不是管理员无法进入预留通道!");
            }
            Rmc_ChangeTeam[client] = 0;
            return true;
        }
        Rmc_ChangeTeam[client] = 0;
        return true;
    }
    Rmc_ChangeTeam[client] = 0;
    return true;
}

public Action Kbcheck(int client, int args)
{
    //if (GetUserFlagBits(client))
    //{
        int ix = 1;
        while (ix <= MaxClients)
        {
            if (IsClientInGame(ix))
            {
                if (IsFakeClient(ix) && GetClientTeam(ix) == 2)
                {
                    KickClient(ix, "踢出一个bot");
                }
            }
            ix++;
        }
        PrintToChatAll("\x05[提示]\x03 踢除所有bot.");
        return Plugin_Handled;
    //}
    //ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
    //return Plugin_Handled;
}

public Action Kbcheck2(int client, int args)
{
    int ix = 1;
    while (ix <= MaxClients)
    {
        if (IsClientInGame(ix))
        {
            if (!IsFakeClient(ix) && GetClientTeam(ix) == 1)
            {
                ClientCommand(ix, "jointeam 1");
                CreateTimer(0.1, DelaySpec, ix);
                PrintToChatAll("\x05[提示]\x03 将所有闲置玩家转入观察者.");
            }
        }
        ix++;
    }
    PrintToChatAll("\x05[提示]\x03 将所有闲置玩家转入观察者.");
    return Plugin_Handled;
}

public Action DelaySpec(Handle timer, int client)
{
    ClientCommand(client, "jointeam 2");
}

public Action Numsetcheck(int client, int args)
{
    if (GetUserFlagBits(client))
    {
        rDisplaySnumMenu(client);
    }
    ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
    return Plugin_Handled;
}

public int rDisplaySnumMenu(int client)
{
    char namelist[64];
    char nameno[4];
    Handle menu = CreateMenu(rNumMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem|MenuAction_VoteEnd);
    SetMenuTitle(menu, "服务器人数设置");
    int i = 1;
    while (i <= 24)
    {
        Format(nameno, 3, "%i", i);
        AddMenuItem(menu, nameno, namelist, 0);
        i++;
    }
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
}

public int rNumMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_End)
    {
        char clientinfos[12];
        int userids = 0;
        GetMenuItem(menu, itemNum, clientinfos, sizeof(clientinfos));
        userids = StringToInt(clientinfos, 10);
        usermnums = userids;
        RCNcheck = true;
        PrintToChat(client, "\x05[提醒:]\x04 默认人数请修改l4d2_rmc.cfg");
        CreateTimer(0.1, rmcRepDelays);
    }
    return 0;
}

public Action Scdescription(int client, int args)
{
    PrintToChatAll("\x05[插件说明]\x03 !jg\x04或\x03!joingame\x04 加入游戏, \x03!away\x04 观察者, \x03!diannao\x04 增加一个电脑,");
    PrintToChatAll("\x05[插件说明]\x03 !sinfo\x04 显示服务器人数信息, \x03!rhelp\x04 显示插件使用说明");
    PrintToChatAll("\x05[插件说明]\x03 !sp\x04 显示还在加载中的玩家列表, \x03!zs或者!kill\x04 自杀");
    PrintToChatAll("\x05[插件说明]\x03 !kb\x04 踢除所有bot, \x03!sset\x04 设置服务器人数 \x03");
    return Plugin_Handled;
}

public Action Bindkeyhots(int client, int args)
{
    // 必须 cl_restrict_server_commands 0.
    ClientCommand(client, "bind q \"say_team /tp\"");
    ClientCommand(client, "bind g \"say_team /save\"");
    PrintToChat(client, "\x05[提醒:]\x04已绑定键盘\n\x03 Q \x04键为自动输入\x03!tp\x04传送\n\x03 G \x04键为自动输入\x03!save\x04存档");
    return Plugin_Handled;
}

public Action Gotoaway(int client, int argCount)
{
    if (AwayCEnable)
    {
        if (GetUserFlagBits(client))
        {
            ChangeClientTeam(client, 1);
        }
        else
        {
            PrintToChat(client, "\x05[失败:]\x04服务没有开启!away可请管理员修改l4d2_rmc.cfg");
        }
    }
    else
    {
        ChangeClientTeam(client, 1);
    }
}

public Action Gotoaway2(int client, int argCount)
{
    if (AwayCEnable)
    {
        if (GetUserFlagBits(client))
        {
            ClientCommand(client, "go_away_from_keyboard");
        }
        else
        {
            PrintToChat(client, "\x05[失败:]\x04服务没有开启!away2可请管理员修改l4d2_rmc.cfg");
        }
    }
    else
    {
        ClientCommand(client, "go_away_from_keyboard");
    }
}

public int Playernums()
{
    int numPlayers = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && (GetClientTeam(i) == 1 || GetClientTeam(i) == 2))
        {
            numPlayers++;
        }
        i++;
    }
    return numPlayers;
}

public int Survivors()
{
    int numSurvivors = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
        {
            numSurvivors++;
        }
        i++;
    }
    return numSurvivors;
}

public int AliveSurvivors()
{
    int numSurvivors = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            numSurvivors++;
        }
        i++;
    }
    return numSurvivors;
}

// 非管理员人数
public int Allplayersn()
{
    int numplayers = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !GetUserAdmin(i))
        {
            numplayers++;
        }
        i++;
    }
    return numplayers;
}

public int Humannums()
{
    int numHuman = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
        {
            numHuman++;
        }
        i++;
    }
    return numHuman;
}

public int Botnums()
{
    int numBots = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
        {
            numBots++;
        }
        i++;
    }
    return numBots;
}

public int Alivebotnums()
{
    int AnumBots = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i))
        {
            if (IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                AnumBots++;
            }
        }
        i++;
    }
    return AnumBots;
}

public int Gonaways()
{
    int numaways = 0;
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i))
        {
            if (!IsFakeClient(i) && GetClientTeam(i) == 1)
            {
                numaways++;
            }
        }
        i++;
    }
    return numaways;
}

public Action Vserverinfo(int client, int args)
{
    PrintToChat(client, "\x05[提示]\x03 服务器幸存者数量 \x04[%i]\x03 活着的幸存者数量 \x04[%i]\x03 非电脑玩家数量 \x04[%i]\x03 观察者数量 \x04[%i]\x03 电脑总数量 \x04[%i]\x03 活着的电脑数量 \x04[%i]", Survivors(), AliveSurvivors(), Playernums(), Gonaways(), Botnums(), Alivebotnums());
    return Plugin_Handled;
}

public Action Rzhisha(int client, int args)
{
    if (IsClientInGame(client))
    {
        ForcePlayerSuicide(client);
    }
    return Plugin_Handled;
}

public Action RListLoadplayer(int client, int args)
{
    char PlayerName[64];
    int InGameCount = 0;
    int HumanNum = 0;
    HumanNum = Humannums();
    PrintToChatAll("\x05[提示]\x03 已经在游戏中的玩家列表...");
    int i = 1;
    while (i <= MaxClients)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientName(i, PlayerName, 64);
            InGameCount++;
            PrintToChatAll("\x05[%i]\x04 %s \x01ID: %i", InGameCount, PlayerName, i);
            PrintToServer("\x05[%i]\x04 %s \x01ID: %i", InGameCount, PlayerName, i);
        }
        i++;
    }
    PrintToChatAll("\x05[提示]\x03 加载中的玩家列表...");
    if (HumanNum - InGameCount == 0)
    {
        PrintToChatAll("\x05       ------ 无 ------");
        PrintToServer("\x05       ------ 无 ------");
    }
    else
    {
        PrintToChatAll("\x05------\x04 %i \x05人还在加载中------", HumanNum - InGameCount);
        PrintToServer("\x05------\x04 %i \x05人还在加载中------", HumanNum - InGameCount);
        i = 1;
        while (i <= MaxClients)
        {
            if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
            {
                GetClientName(i, PlayerName, 64);
                PrintToChatAll("\x05[%i]\x04 %s \x01ID: %i", InGameCount, PlayerName, i);
                PrintToServer("\x05[%i]\x04 %s \x01ID: %i", InGameCount, PlayerName, i);
            }
            i++;
        }
    }
    return Plugin_Handled;
}

public Action CreateOneBot(int client, int agrs)
{
    LCreateOneBot(client);
}

public int LCreateOneBot(int client)
{
    PrintToServer("创造一个电脑");
    int survivorsnum = 0;
    int specnum = 0;
    int botnum = 0;
    survivorsnum = Survivors();
    specnum = Gonaways();
    botnum = Botnums();
    KickEnable = GetConVarBool(hKickEnable);
    if (!KickEnable || botnum < specnum || survivorsnum < 4)
    {
        int survivorbot = CreateFakeClient("survivor bot");
        DispatchKeyValue(survivorbot, "classname", "SurvivorBot");
        DispatchSpawn(survivorbot);
        ChangeClientTeam(survivorbot, 2);
        SetEntProp(survivorbot, Prop_Data, "m_takedamage", 0, 1);
        int i = 1;
        while (i <= MaxClients)
        {
            if (IsClientInGame(i)  && i != survivorbot && GetClientTeam(i) == 2)
            {
                float vAngles1[3];
                float vOrigin1[3];
                GetClientAbsOrigin(i, vOrigin1);
                GetClientAbsAngles(i, vAngles1);
                GiveItems(survivorbot);
                TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
                // char name[MAX_NAME_LENGTH];
                // GetClientName(i, name, MAX_NAME_LENGTH);
                // PrintToChatAll("传送到%s", name);
                break;
            }
            i++;
        }
        CreateTimer(1.0, SurvivorKicker, survivorbot);
    }
    else
    {
        PrintCenterText(client, "\x05[提示]\x03 无需增加bot.");
        PrintToChat(client, "\x05[提示]\x03 无需增加bot.");
    }
}

public Action DelayGodModeDisable(Handle timer, any survivorbot)
{
    if (IsClientInGame(survivorbot))
        SetEntProp(survivorbot, Prop_Data, "m_takedamage", 2, 1);
}

public Action SurvivorKicker(Handle timer, any survivorbot)
{
    KickClient(survivorbot, "CreateOneBot...");
    PrintToChatAll("\x05[提示]\x01 BOT 创建完成,加入请按鼠标左键.");
}

public Action Event_rmcteam(Event event, char[] name, bool dontBroadcast)
{
    if (RAutoBotcheck)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client)
        {
            if (Rmc_ChangeTeam[client])  // 不是第一次加入游戏
            {
            }
            else
            {
                CreateTimer(0.5, JointeamRmc, client);
                Rmc_ChangeTeam[client] = 1;
            }
        }
    }
}

public Action JointeamRmc(Handle timer, any client)
{
    if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != 2)
    {
        int specnum = 0;
        int botnum = 0;
        specnum = Gonaways();
        botnum = Botnums();
        if (botnum <= specnum) LCreateOneBot(client);
        CreateTimer(1.5, FirstJoin, client);
    }
}

public Action FirstJoin(Handle timer, any client)
{
    ClientCommand(client, "jointeam 2");
    ClientCommand(client, "go_away_from_keyboard");
}

public void GiveItems(int client)
{
    int flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & -16385);
    FakeClientCommand(client, "give smg");
    FakeClientCommand(client, "give first_aid_kit");
    SetCommandFlags("give", flags | 16384);
}
