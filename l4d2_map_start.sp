#include <sourcemod>
#include <sdktools>

int RestartCount = 60;
int timeoutt = 0;
Handle RestartTimer;
bool g_bLeft4DHooks;

native bool L4D_IsFirstMapInScenario(); 

public Plugin:myinfo = 
{
    name = "地图初始重启",
    author = "BAKA",
    description = "在每章节地图的初始关卡重启",
    version = "1.0",
    url = "https://baka.cirno.cn"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_stopstart", MapStartStop, "停止初始重启");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();
    if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }

    MarkNativeAsOptional("L4D_IsFirstMapInScenario");

    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    g_bLeft4DHooks = GetFeatureStatus(FeatureType_Native, "L4D_IsFirstMapInScenario") == FeatureStatus_Available;
}

public OnMapStart()
{
    if (RestartTimer != INVALID_HANDLE){
        KillTimer(RestartTimer);
        RestartTimer = INVALID_HANDLE;
    }
    char mapName[256];
    GetCurrentMap(mapName, 256);
    if (g_bLeft4DHooks && L4D_IsFirstMapInScenario() && mapName[0] != 'c' && !IsCharNumeric(mapName[1])){
        timeoutt = 0;
        PrintToServer("开始60秒重启倒计时");
        RestartTimer = CreateTimer(1.0, RestartAnnounce, _, TIMER_REPEAT);
    }
}

public Action MapStartStop(int client, int args)
{
    if (RestartTimer != INVALID_HANDLE){
        KillTimer(RestartTimer);
        RestartTimer = INVALID_HANDLE;
    }
    PrintToChat(client, "已停止初始关卡重启");
}

public Action:RestartAnnounce(Handle:timer)
{
    timeoutt = timeoutt + 1;
    if (timeoutt <= RestartCount){
        PrintHintTextToAll("初始关卡重启倒计时:还有 %d 秒.", 60 - timeoutt);
    }
    else{
        if (RestartTimer != INVALID_HANDLE){
            KillTimer(RestartTimer);
            RestartTimer = INVALID_HANDLE;
        }
        timeoutt = 0;
        ServerCommand("sm_cvar mp_restartgame 1");
        PrintToChatAll("\x03[提示] \x04关卡已重启!");
    }
}