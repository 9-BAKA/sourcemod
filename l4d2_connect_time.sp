#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

float ConnectTime[MAXPLAYERS + 1];
float JoinTime[MAXPLAYERS + 1];

char SpeedNames[][] = {"UFO", "火箭", "飞机", "汽车", "摩托车", "自行车", "牛车"}; 

public Plugin myinfo =
{
    name = "连接时间提示",
    description = "提示进入服务器加载花费的时间",
    author = "BAKA",
    version = "1.0",
    url = "https://baka.cirno.cn/"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_gettime", GetTimeT, "时间");
}

public OnClientConnected(int client)
{
    if (client && !IsFakeClient(client))
    {
        ConnectTime[client] = GetGameTime();
    }
}

public OnClientPutInServer(int client)
{
    if (client && !IsFakeClient(client))
    {
        JoinTime[client] = GetGameTime() - ConnectTime[client];
        int PlayerCount = GetConnectingCount(client);
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteCell(PlayerCount);
        CreateTimer(5.0, DelayConnectAnnonce, pack);
    }
}

public int GetConnectingCount(int client)
{
    int i = 1;
    int PlayerCount = 0;
    while (i <= MaxClients)
    {
        if (i != client && IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
        {
            PlayerCount++;
        }
        i++;
    }
    return PlayerCount;
}

public Action DelayConnectAnnonce(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    int PlayerCount = pack.ReadCell();

    PrintToChatAll("\x04[提示]\x03%N\x05加入了游戏，加载耗时\x03%.1f\x05秒！当前还有\x03%d\x05名玩家正在加载.", client, JoinTime[client], PlayerCount);
    int SpeedIndex = RoundToFloor(JoinTime[client] / 5);
    if (SpeedIndex > 6) SpeedIndex = 6;
    float PlayerPercent = 120 - 4 * JoinTime[client];
    if (PlayerPercent < 0) PlayerPercent = 0.0
    PrintToChatAll("\x04[提示]\x05你的加载速度像\x03%s\x05一样，领先于全服\x03%.1f%%\x05的玩家！", SpeedNames[SpeedIndex], PlayerPercent);
}

public Action GetTimeT(int client, int args)
{
    PrintToChatAll("EngineTime: %f", GetEngineTime());
    PrintToChatAll("GameTime: %f", GetGameTime());
	
    return Plugin_Continue;
}


