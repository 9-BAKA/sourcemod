#include <sourcemod>
#include <sdktools>

#define DB_CONF_NAME "l4dmap"

bool info_exist;
char EN_name[64];
char CHI_name[64];
char map_info[5000];

Handle db = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "地图信息sql版",
	author = "BAKA",
	description = "地图信息sql版",
	version = "1.0",
	url = "https://baka.cirno.cn"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_mapinfo", MapInfo, "获取当前地图信息");
    RegConsoleCmd("sm_mapname", MapName, "获取当前地图名字");
}

public OnConfigsExecuted()
{
  GetConVarString(cvar_DbPrefix, DbPrefix, sizeof(DbPrefix));

  // Init MySQL connections
  if (!ConnectDB())
  {
    SetFailState("Connecting to database failed. Read error log for further details.");
    return;
  }
	
	ReadDb();
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

bool:ConnectDB()
{
  if (db != INVALID_HANDLE)
    return true;

  if (SQL_CheckConfig(DB_CONF_NAME))
  {
    new String:Error[256];
    db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

    if (db == INVALID_HANDLE)
    {
      LogError("Failed to connect to database: %s", Error);
      return false;
    }
    else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
    {
      if (SQL_GetError(db, Error, sizeof(Error)))
        LogError("Failed to update encoding to UTF8: %s", Error);
      else
        LogError("Failed to update encoding to UTF8: unknown");
    }

    if (!CheckDatabaseValidity(DbPrefix))
    {
      LogError("Database is missing required table or tables.");
      return false;
    }
  }
  else
  {
    LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
    return false;
  }

  return true;
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
    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    
		char query[256];
		Format(query, sizeof(query), "SELECT COUNT(*) FROM l4d2_chapters WHERE  = %s", sMap);

		 SQL_Query(db, query);

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
