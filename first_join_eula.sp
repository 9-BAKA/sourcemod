#include <sourcemod>
#include <sdktools>

int ContDown[MAXPLAYERS+1];
int FirstJoin[MAXPLAYERS+1];
Handle Timers[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "进服游戏声明",
    description = "在玩家第一次进服时进行一些守则的声明",
    author = "BAKA",
    version = "1.0",
    url = "https://baka.cirno.cn"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_hint", Command_Hint, "提示服务器信息");

    for (int i = 0; i <= MAXPLAYERS; i++){
        FirstJoin[i] = true;
    }
}

public void OnClientPutInServer(int client)
{
    if (client && !IsFakeClient(client))
    {
        if (FirstJoin[client])
        {
            FirstJoin[client] = false;
            CreateTimer(30.0, DelayHintAnnonce, client);
        }
    }
}

public Action DelayHintAnnonce(Handle timer, int client)
{
    if (IsClientInGame(client))
    {
        if (Timers[client] != INVALID_HANDLE) return;

        ContDown[client] = 15;
        Timers[client] = CreateTimer(1.0, HintTimer, client, TIMER_REPEAT);
    }
}

public Action Command_Hint(int client, int args)
{
    DrawHintPanel(client, 1);
}

public Action HintTimer(Handle timer, int client)
{
    if(client == 0 || !IsClientInGame(client) || ContDown[client] == -1) 
    {
        Timers[client] = INVALID_HANDLE;
        return Plugin_Stop;
    }
    DrawHintPanel(client, 0);
    ContDown[client] = ContDown[client] - 1;

    return Plugin_Continue;
}

public void DrawHintPanel(int client, int command)
{
    Panel panel = new Panel();
    panel.SetTitle("和  谐  游  戏  声  明");
    panel.DrawText(" ");
    panel.DrawText("    欢迎你游玩BAKA都能玩的服务器，本服务器是公共服务器。因此");
    panel.DrawText("如果你是匹配进入的，即使你选择的是仅限好友进入，也会有路人进");
    panel.DrawText("入。请无故不要踢出他们，因为这是公共服务器，是面向所有人的。");
    panel.DrawText("    踢人请用!vote，会有记录，恶意踢人永久封禁。");
    panel.DrawText("    如果你介意，可以退出选择本地服务器建房。");
    panel.DrawText("    最后，希望大家能够友好游戏，按h键有服务器的简单说明，欢迎");
    panel.DrawText("加群一起游玩，祝你游玩愉快~");
    panel.DrawText(" ");
    
    if (ContDown[client] > 0 && command == 0)
    {
        char ExitText[64];
        Format(ExitText, sizeof(ExitText), "退出(%d秒)", ContDown[client]);
        panel.DrawItem(ExitText, ITEMDRAW_DISABLED);
    }
    else
    {
        panel.DrawItem("退出", ITEMDRAW_CONTROL);
    }

    panel.Send(client, PanelHandler, MENU_TIME_FOREVER);

    delete panel;
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        
    }
    else if (action == MenuAction_Cancel)
    {
        
    }
}

public void OnClientDisconnect(int client)
{
    if(client != 0 && !IsFakeClient(client))
    {
        int userid = GetClientUserId(client);
        DataPack pack = CreateDataPack();
        pack.WriteCell(client);
        pack.WriteCell(userid);
        CreateTimer(5.0, Check, pack);
    }
}

public Action Check(Handle Timer, DataPack pack)
{
    pack.Reset();
    int client1 = pack.ReadCell();
    int userid = pack.ReadCell();
    int client = GetClientOfUserId(userid);
    if(client == 0 || !IsClientConnected(client) || IsFakeClient(client))
    {
        FirstJoin[client1] = true;
    }
}	



