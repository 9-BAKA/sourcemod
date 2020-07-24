#include <sourcemod>
#include <sdktools_functions>

Handle get_admin_enable;
Handle autoset_admin_enable;
bool get_enable;
bool autoset_enable;
bool admin_list[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = "获取及设置管理员权限",
    description = "",
    author = "",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_setadmin", CmdSetAdmin, ADMFLAG_ROOT, "临时设置权限");
    RegAdminCmd("sm_test", Test, ADMFLAG_ROOT, "测试权限");
    RegConsoleCmd("sm_get", Get, "获取权限")

    get_admin_enable = CreateConVar("get_admin_enable", "0", "允许获得管理员权限", 0);
    autoset_admin_enable = CreateConVar("autoset_admin_enable", "0", "自动获得管理员权限", 0);

    get_enable = GetConVarBool(get_admin_enable);
    autoset_enable = GetConVarBool(autoset_admin_enable);

    HookConVarChange(get_admin_enable, ConVarChange);
    HookConVarChange(autoset_admin_enable, ConVarChange);

    AutoExecConfig(true, "set_admin");
 
    for (int i = 0; i <= MAXPLAYERS; i++){
        admin_list[i] = false;
    }
}

public OnMapStart()
{
    for (int i = 0; i <= MAXPLAYERS; i++){
        if (admin_list[i])
        {
            SetUserFlagBits(i, ADMFLAG_ROOT);
        }
    }
}

public OnClientDisconnect(client)
{
    if(!IsFakeClient(client))
    {
        int userid = GetClientUserId(client);
        CreateTimer(5.0, Check, userid);
    }
}

public Action Check(Handle Timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!IsValidClient(client))
    {
        admin_list[client] = false;
    }
}	

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    get_enable = GetConVarBool(get_admin_enable);
    autoset_enable = GetConVarBool(autoset_admin_enable);
}

public Action CmdSetAdmin(int client, int args)
{
    if( !client ) return Plugin_Handled;

    SetAdmin(client);
    return Plugin_Handled;
}

void SetAdmin(int client)
{
    if( client && IsClientInGame(client) )
    {
        char sTempA[16], sTempB[MAX_NAME_LENGTH];
        Menu menu = new Menu(PlayerListMenur);

        for( int i = 1; i <= MaxClients; i++ )
        {
            if( IsValidClient(i) )
            {
                IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
                GetClientName(i, sTempB, sizeof(sTempB));
                menu.AddItem(sTempA, sTempB);
            }
        }

        menu.SetTitle("设置临时管理员:");
        menu.ExitBackButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
    }
}

public int PlayerListMenur(Menu menu, MenuAction action, int client, int index)
{
    if( action == MenuAction_End )
        delete menu;
    else if( action == MenuAction_Select )
    {
        char sTemp[32];
        menu.GetItem(index, sTemp, sizeof(sTemp));
        int target = StringToInt(sTemp);
        target = GetClientOfUserId(target);

        if( IsValidClient(target) )
        {
            SetUserFlagBits(target, ADMFLAG_ROOT);
            admin_list[target] = true;
            PrintToChat(client, "将 %N 设置为管理员", target);
            PrintToChat(target, "您已被设置为临时管理员");
        }

        SetAdmin(client);
    }
    else if( action == MenuAction_Cancel && index == MenuCancel_ExitBack )
        SetAdmin(client);
}

bool IsValidClient(int client)
{
    if( !client || !IsClientConnected(client) || IsFakeClient(client) )
        return false;
    return true;
}

public Action Test(int client, int args)
{
    PrintToChat(client, "您已具有管理员权限");
    return Plugin_Continue;
}

public Action Get(int client, int args)
{
    if (get_enable)
    {
        SetUserFlagBits(client, ADMFLAG_ROOT);
        PrintToChat(client, "您已获取管理员权限");
    }
    else
    {
        PrintToChat(client, "暂时不允许获取管理员权限");
    }
    return Plugin_Continue;
}

public bool IsInBlackList(client)
{
    Handle file;
    char FileName[256];
    char buffer[32];
    char steam_id[32];
    BuildPath(PathType:0, FileName, 256, "data/admin_blacklist.txt");
    if (!FileExists(FileName, false))
    {
        SetFailState("无法找到 admin_blacklist.txt 文件");
    }
    file = OpenFile(FileName, "r");
    GetClientAuthId(client, AuthIdType:1, steam_id, 32, true);
    PrintToServer(steam_id);
    while (ReadFileLine(file, buffer, 256))
    {
        PrintToServer(buffer);
        if (strcmp(steam_id, buffer) == 0)
        {
            PrintToServer("True");
            return true;
        }
    }
    return false;
}


public OnClientPostAdminCheck(client)
{
    if (!IsFakeClient(client) && autoset_enable)
    {
        if (!IsInBlackList(client))
        {
            SetUserFlagBits(client, ADMFLAG_ROOT);
            PrintToChatAll("%N 已获取管理员权限", client);
        }
    }
}

