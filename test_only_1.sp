#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define AA   1
#define BB   2

public Plugin:myinfo =
{
    name = "仅供测试1",
    description = "",
    author = "",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_test", Test, "测试");

    HookEvent("player_disconnect", Event_PlayerDisconnect);
    HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
    AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action Test(int client, int args)
{
    int test[5];
    int temp = 2;
    if (temp == AA)
        test[temp] = 3;
    PrintToChatAll("队伍:%d", GetClientTeam(client));
    
    return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, String:strName[], bool:bDontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
    if (client != 0 && IsClientInGame(client))
    {
        char disconnectReason[64];
        GetEventString(event, "reason", disconnectReason, sizeof(disconnectReason)); 
        PrintToChatAll("\x04[提示]\x03%N 离开了游戏,原因: %s,队伍:%d", client, disconnectReason, GetClientTeam(client));
    }
    return Action:0;
}

public Action EventPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid", 0));
    if (client != 0 && IsClientInGame(client))
    {
        PrintToChatAll("\x04[提示]\x03%N 更换了队伍,队伍:%d", client, GetClientTeam(client));
    }
    return Action:0;
}

public Action:Command_JoinTeam(client, const String:command[], argc) 
{
    PrintToChatAll("\x04[提示]\x03%N 使用了jointeam指令", client);
} 