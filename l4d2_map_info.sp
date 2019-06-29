#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "地图信息",
	author = "BAKA",
	description = "地图信息",
	version = "1.0",
	url = "<- URL ->"
}

bool info_exist;
char EN_name[64];
char CHI_name[64];
char map_info[5000];

public void OnPluginStart()
{
    RegConsoleCmd("sm_mapinfo", MapInfo, "获取当前地图信息");
    RegConsoleCmd("sm_mapname", MapName, "获取当前地图名字");
}

public void OnMapStart()
{
    info_exist = GetMapInfo();
    if (info_exist)
    {
        PrintToChatAll("当前地图存在简介，请输入!mapinfo查看");
    }
    else
    {
        PrintToChatAll("当前地图暂无简介");
    }
}

public Action MapInfo(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }
    
    ShowMapInfoMenu(client);

    return Plugin_Continue;
}

public bool GetMapInfo()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/mapinfo.txt");
    if( !FileExists(sPath) )
        return false;

    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    if ( strcmp(EN_name, sMap) == 0 )
    {
        return true;
    }

    KeyValues hFile = new KeyValues("crash");
    hFile.ImportFromFile(sPath);

    if( hFile.JumpToKey(sMap, false) )
    {
        KvGetString(hFile, "中文名", CHI_name, 64, "");
        KvGetString(hFile, "建图代码", EN_name, 64, "");
        KvGetString(hFile, "简介", map_info, 5000, "");
    }
    else
    {
        return false
    }

    delete hFile;

    return true;
}

public Action ShowMapInfoMenu(int client)
{
    info_exist = GetMapInfo();
    if (info_exist)
    {
        PrintToChatAll("当前地图暂无简介");
        return Plugin_Handled;
    }

    new Handle:menu = CreatePanel(Handle:0);
    decl String:line[256];
    Format(line, 256, "地图介绍:");
    SetPanelTitle(menu, line, false);
    
    Format(line, 256, "装逼闪烁光环");
    DrawPanelItem(menu, line, ITEMDRAW_RAWLINE);
    Format(line, 10, "装,逼秒杀僵尸装逼彩色弹道装逼彩色弹道装逼彩色弹道装逼彩色弹");
    DrawPanelItem(menu, line[0], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[1], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[2], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[3], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[4], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[5], ITEMDRAW_RAWLINE);
    DrawPanelItem(menu, line[6], ITEMDRAW_RAWLINE);

    DrawPanelItem(menu, "关闭", 1);
    SendPanelToClient(menu, client, MenuHandler_GmEffect, 0);
    CloseHandle(menu);

    return Action:3;
}

public MenuHandler_GmEffect(Handle:menu, MenuAction:action, Client, param)
{
    if (action == MenuAction:4)
    {
        switch (param)
        {
            case 1:
            {
                
            }
            default:
            {
            }
        }
    }
    return 0;
} 

public Action MapName(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }
    
    ShowMapName(client);

    return Plugin_Continue;
}

public Action ShowMapName(int client)
{
    char mapName[256], displayName[256];
    GetCurrentMap(mapName, 256);
    GetMapDisplayName(mapName, displayName, 256);
    PrintToChat(client, "地图代码：%s", mapName);
    PrintToChat(client, "地图名字：%s", displayName);
    FindMap(mapName, displayName, 256);
    PrintToChat(client, "地图代码：%s", mapName);
    PrintToChat(client, "地图名字：%s", displayName);
    
    return Action:3;
}
