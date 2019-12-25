#include <sourcemod>
#include <colors>

new Handle:hCvarCvarChange;
new Handle:hCvarNameChange;
new Handle:hCvarSpecNameChange;
new Handle:hCvarShowSpecsChat;
new Handle:hCvarVocalDelay;
new bool:bCvarChange;
new bool:bNameChange;
new bool:bSpecNameChange;
new bool:bShowSpecsChat;
new Float:g_LastVocalTime[66];

public Plugin:myinfo = 
{
    name = "BeQuiet",
    author = "Sir",
    description = "Please be Quiet!",
    version = "1.33.7",
    url = "https://github.com/SirPlease/SirCoding"
}

public OnPluginStart()
{
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(TeamSay_Callback, "say_team");
    AddCommandListener(Vocal_Callback, "vocalize");

    //Server CVar
    HookEvent("server_cvar", Event_ServerDontNeedPrint, EventHookMode_Pre);
    HookEvent("player_changename", Event_NameDontNeedPrint, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);

    //Cvars
    hCvarCvarChange = CreateConVar("bq_cvar_change_suppress", "1", "不显示服务器 Cvars 改变, 这使得聊天没有干扰.");
    hCvarNameChange = CreateConVar("bq_name_change_suppress", "1", "不显示玩家名称更改.");
    hCvarSpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "不显示旁观玩家名称更改.");
    hCvarShowSpecsChat = CreateConVar("bq_show_player_team_chat_spec", "1", "旁观显示玩家在团队聊天中说什么.");
    hCvarVocalDelay = CreateConVar("bq_vocalize_guard_vdelay", "10", "玩家调用下一个语音命令之前延迟 [0 = DISABLED]", 262144, true, 0.0, false, 0.0);

    bCvarChange = GetConVarBool(hCvarCvarChange);
    bNameChange = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bShowSpecsChat = GetConVarBool(hCvarShowSpecsChat);

    HookConVarChange(hCvarCvarChange, cvarChanged);
    HookConVarChange(hCvarNameChange, cvarChanged);
    HookConVarChange(hCvarSpecNameChange, cvarChanged);
    HookConVarChange(hCvarShowSpecsChat, cvarChanged);

    AutoExecConfig(true, "bequiet");
}

public OnMapStart()
{
	new i = 1;
	while (i <= MaxClients)
	{
		g_LastVocalTime[i] = 0.0;
		i++;
	}
}

public Action:Vocal_Callback(client, const String:command[], argc)
{
	new flTimeDelay = GetConVarInt(hCvarVocalDelay);
	if (0 >= flTimeDelay)
	{
		return Plugin_Continue;
	}
	if (g_LastVocalTime[client] < GetEngineTime() - flTimeDelay)
	{
		g_LastVocalTime[client] = GetEngineTime();
		return Plugin_Continue;
	}
	new iTimeLeft = RoundToNearest(flTimeDelay - GetEngineTime() - g_LastVocalTime[client]);
	PrintToChat(client, "\x04[SM] \x01你必须等待 \x03%d\x01 秒才能发送下一个语音", iTimeLeft);
	return Plugin_Handled;
}

public Action:Say_Callback(client, const String:command[], argc)
{
    decl String:sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:TeamSay_Callback(client, const String:command[], argc)
{
    decl String:sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
    {
        return Plugin_Handled;
    }
    else if (bShowSpecsChat && GetClientTeam(client) != 1)
    {
        new String:sChat[256];
        GetCmdArgString(sChat, sizeof(sChat));
        StripQuotes(sChat);

        for (new i = 1; i <= MAXPLAYERS; i++)
        {
            if (IsValidClient(i) && GetClientTeam(i) == 1)
            {
                if (GetClientTeam(client) == 2) CPrintToChat(i, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
                else CPrintToChat(i, "{default}(Infected) {red}%N {default}: %s", client, sChat);
            }
        }
    }
    return Plugin_Continue;
}

public Action:Event_ServerDontNeedPrint(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (bCvarChange) return Plugin_Handled;
    return Plugin_Continue;
}

public Action:Event_NameDontNeedPrint(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client; 
    new clientid; 
    clientid = GetEventInt(event,"userid"); 
    client = GetClientOfUserId(clientid); 

    if (IsValidClient(client))
    {
        if (GetClientTeam(client) == 1)
        { 
            if (bSpecNameChange) return Plugin_Handled; 
        }
        else if (bNameChange) return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	g_LastVocalTime[client] = 0.0;
	return Plugin_Continue;
}

public cvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    bCvarChange = GetConVarBool(hCvarCvarChange);
    bNameChange = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bShowSpecsChat = GetConVarBool(hCvarShowSpecsChat);
}

stock bool:IsValidClient(client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client))
    {
        return false; 
    }
    return true;
}
