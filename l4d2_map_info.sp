#include <sourcemod>
#include <sdktools>

#define DB_CONF_NAME "l4dmapinfo"
#define MAX_LINE_WIDTH 64
#define MAX_MESSAGE_WIDTH 256
#define MAX_QUERY_COUNTER 256

int info_exist;
int map_index, chapter_num, map_chapter_num;
float map_offi_rating;
char chapter_code[256], map_name_en[256], map_name_zh[256], map_intro[10000], map_intro_buffer[150][MAX_LINE_WIDTH];
int total_index;
int current_index[64];

Handle db = INVALID_HANDLE;
Handle g_hCvarReport;
Handle g_hTimer;

public Plugin:myinfo = 
{
    name = "地图信息sql版",
    author = "BAKA",
    description = "地图信息sql版",
    version = "1.1",
    url = "https://baka.cirno.cn"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_mapinfo", MapInfo, "获取当前地图信息,1:Menu,2:Chat,3:Menu&Chat");
    RegConsoleCmd("sm_mapinfoall", MapInfoAll, "将当前地图信息展示给所有人,1:Menu,2:Chat,3:Menu&Chat");
    RegConsoleCmd("sm_mapname", MapName, "获取当前地图名字");
    RegConsoleCmd("sm_maptest", MapTest, "测试中文输出");

    g_hCvarReport = CreateConVar("sm_map_info_report", "1", "地图信息报告类型,1:只是第一关,2:所有关", 0);

    AutoExecConfig(true, "l4d2_map_info");
}

public OnConfigsExecuted()
{
    // Init MySQL connections
    if (!ConnectDB())
    {
        SetFailState("Connecting to database failed. Read error log for further details.");
        return;
    }
}

public void OnMapStart()
{
    if (g_hTimer != INVALID_HANDLE){
        KillTimer(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }

    // 初始化字符串
    Format(chapter_code, sizeof(chapter_code), "");
    Format(map_name_en, sizeof(map_name_en), "");
    Format(map_name_zh, sizeof(map_name_zh), "");
    Format(map_intro, sizeof(map_intro), "");

    for (int i = 0; i <= MaxClients; i++)
        current_index[i] = 0;
    info_exist = -1;
    CreateTimer(10.0, DelayMapInfoCheck);
}

public Action MapTest(int client, int args)
{
    if (args == 0)
    {
        PrintToChatAll(map_intro);
    }
    else
    {
        char arg[6];
        GetCmdArg(1, arg, sizeof(arg));
        int len = StringToInt(arg);
        char temp[256];
        strcopy(temp, len, map_intro);
        PrintToChatAll(temp);
        PrintToServer(temp);
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
        CreateTimer(10.0, DelayMapInfoReport, client);
}

bool ConnectDB()
{
    if (db != INVALID_HANDLE)
        return true;

    if (SQL_CheckConfig(DB_CONF_NAME))
    {
        char Error[256];
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

        if (!DoFastQuery(0, "SELECT * FROM l4d2_maps WHERE 1 = 2") ||
            !DoFastQuery(0, "SELECT * FROM l4d2_chapters WHERE 1 = 2"))
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

bool DoFastQuery(int Client, char[] Query)
{
    char FormattedQuery[4096];
    VFormat(FormattedQuery, sizeof(FormattedQuery), Query, 3);

    char Error[1024];

    if (!SQL_FastQuery(db, FormattedQuery))
    {
        if (SQL_GetError(db, Error, sizeof(Error)))
        {
            PrintToConsole(Client, "[MapInfo] Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
            LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
        }
        else
        {
            PrintToConsole(Client, "[MapInfo] Fast query failed! Query = \"%s\"", FormattedQuery);
            LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
        }

        return false;
    }

    return true;
}

public Action DelayMapInfoCheck(Handle timer)
{
    MapInfoCheck(0, 0);
}

public Action HintCheck(Handle timer, int client)
{
    // if (info_exist == 1) g_hTimer = CreateTimer(120.0, HintRepeat, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    if (!IsClientInGame(client)) return Plugin_Stop;
    if (info_exist == 1) PrintToChat(client, "\x04[地图信息]\x03该地图存在简介,请输入!mapinfo查看.");
    else if (info_exist == 0) PrintToChat(client, "\x04[地图信息]\x03该地图暂无简介.");
    return Plugin_Continue;
}

public Action HintRepeat(Handle timer, int client)
{
    PrintToChat(client, "\x04[地图信息]\x03该地图存在简介,请输入!mapinfo查看.")
}

public Action MapInfo(int client, int args)
{
    int printType;
    if (args == 0)
    {
        printType = 1;
    }
    else
    {
        char arg[4];
        GetCmdArg(1, arg, sizeof(arg));
        printType = StringToInt(arg, 10);
    }
    MapInfoPrint(client, printType);
}

MapInfoPrint(int client, int printType)
{
    char mapName[256];
    GetCurrentMap(mapName, 256);
    if (info_exist == 0 && strcmp(mapName, chapter_code, false) == 0)
    {
        if (client == 0) PrintToChatAll("\x04[地图信息]\x03该地图暂无简介");
        else if (IsClientInGame(client)) PrintToChat(client, "\x04[地图信息]\x03该地图暂无简介");
    }
    else
    {
        if (strcmp(mapName, chapter_code, false) != 0)
        {
            if (client == 0) PrintToChatAll("地图信息正在查询中...");
            else if (IsClientInGame(client)) PrintToChat(client, "地图信息正在查询中...");
            MapInfoCheck(client, printType);
        }
        else
        {
            PrintBaseIntro(client);
            if (printType & 1) ShowMapInfoMenu(client);
            if (printType & 2) PrintIntroChat(client);
        }
    }
}

public Action DelayMapInfoReport(Handle timer, int client)
{
    int report_type = GetConVarInt(g_hCvarReport);
    if (report_type == 1)  // 只是第一关
    {
        if (chapter_num == 1)
        {
            CreateTimer(60.0, DelayMapInfo, 0);
        }
    }
    else if (report_type == 2)  // 所有关
    {
        if (chapter_num == 1)
        {
            CreateTimer(60.0, DelayMapInfo, client);
        }
        else
        {
            CreateTimer(20.0, DelayMapInfo, client);
        }
    }
    CreateTimer(30.0, HintCheck, client);
}

public Action DelayMapInfo(Handle timer, int client)
{
    MapInfoPrint(client, 3);
}

public Action MapInfoAll(int client, int args)
{
    int printType;
    if (args == 0)
    {
        printType = 1;
    }
    else
    {
        char arg[4];
        GetCmdArg(1, arg, sizeof(arg));
        printType = StringToInt(arg, 10);
    }
    MapInfoAllPrint(client, printType);
}

public Action MapInfoAllPrint(int client, int printType)
{
    char mapName[256];
    GetCurrentMap(mapName, 256);
    if (info_exist == 0 && strcmp(mapName, chapter_code, false) == 0)
    {
        PrintToChatAll("该图暂无介绍");
    }
    else
    {
        if (strcmp(mapName, chapter_code, false) != 0)  // 还未获取map信息
        {
            PrintToChatAll("地图信息正在查询中...");
            MapInfoCheck(0, printType);
        }
        else
        {
            PrintBaseIntro(0);
            if (printType & 1) ShowMapInfoMenu(0);
            if (printType & 2) PrintIntroChat(0);
        }
    }
}

MapInfoCheck(int client, int printType)
{
    DataPack pack = CreateDataPack();
    pack.WriteCell(client);
    pack.WriteCell(printType);
    QueryMapIndex(pack);
}

QueryMapIndex(DataPack pack, SQLTCallback callback=INVALID_FUNCTION)
{
    if (callback == INVALID_FUNCTION)
        callback = QueryMapIndexCallback;

    char query[512];
    char mapName[256];
    GetCurrentMap(mapName, 256);
    Format(query, sizeof(query), "SELECT chapter_code,chapter_num,map_index FROM l4d2_chapters WHERE chapter_code = '%s'", mapName);
    SQL_TQuery(db, callback, query, pack);
}

public QueryMapIndexCallback(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("QueryMapIndex failed: %s", error);
        return;
    }

    if (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, chapter_code, sizeof(chapter_code));
        chapter_num = SQL_FetchInt(hndl, 1);
        map_index = SQL_FetchInt(hndl, 2);
        QueryMapIntro(pack, map_index);
    }
    else
    {
        info_exist = 0;
        pack.Reset();
        int client = pack.ReadCell();
        if (client == 0) PrintToChatAll("\x04[地图信息]\x03该地图暂无简介");
        else if (IsClientInGame(client)) PrintToChat(client, "\x04[地图信息]\x03该地图暂无简介");
    }
}

QueryMapIntro(DataPack pack, int mapIndex, SQLTCallback callback=INVALID_FUNCTION)
{
    if (callback == INVALID_FUNCTION)
        callback = QueryMapIntroCallback;

    char query[512];
    Format(query, sizeof(query), "SELECT map_name_en,map_name_zh,map_chapter_num,map_official_rating,map_intro FROM l4d2_maps WHERE map_index = %d", mapIndex);
    SQL_TQuery(db, callback, query, pack);
}


public QueryMapIntroCallback(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("QueryMapIntro failed: %s", error);
        return;
    }

    PrintToServer("[MapInfo]地图信息查询成功!");
    pack.Reset();
    int client = pack.ReadCell();
    int printType = pack.ReadCell();
    if (SQL_FetchRow(hndl))
    {
        info_exist = 1;
        SQL_FetchString(hndl, 0, map_name_en, sizeof(map_name_en));
        SQL_FetchString(hndl, 1, map_name_zh, sizeof(map_name_zh));
        map_chapter_num = SQL_FetchInt(hndl, 2);
        map_offi_rating = SQL_FetchFloat(hndl, 3);
        SQL_FetchString(hndl, 4, map_intro, sizeof(map_intro));
        SetMapIntroBuffer();
        PrintBaseIntro(client);
        if (printType & 1) ShowMapInfoMenu(client);
        if (printType & 2) PrintIntroChat(client);
    }
    else
    {
        info_exist = 0;
        if (client == 0) PrintToChatAll("该图暂无介绍");
        else if (IsClientInGame(client)) PrintToChat(client, "该图暂无介绍");
    }
    CloseHandle(pack);
}

SetMapIntroBuffer()
{
    int total_len = strlen(map_intro);
    int start = 0, buffer_index = 0;
    while (start < total_len)
    {
        strcopy(map_intro_buffer[buffer_index], MAX_LINE_WIDTH, map_intro[start]);
        terminateUTF8String(map_intro_buffer[buffer_index], MAX_LINE_WIDTH);
        start = start + strlen(map_intro_buffer[buffer_index]);
        buffer_index = buffer_index + 1;
    }
    total_index = buffer_index;
}

PrintBaseIntro(int client)
{
    if (client == 0)
    {
        PrintToServer("\x04中文名: \x01%s", map_name_zh);
        PrintToChatAll("\x04地图编号: \x01%d", map_index);
        PrintToChatAll("\x04中文名: \x01%s", map_name_zh);
        PrintToChatAll("\x04英文名: \x01%s", map_name_en);
        PrintToChatAll("\x04关卡数: \x01%d/%d", chapter_num, map_chapter_num);
        PrintToChatAll("\x04评分: \x01%.1f", map_offi_rating);
        PrintToChatAll("\x04地图介绍: \x01%d 字", strlen(map_intro));
        PrintToChatAll("\x05请输入\x04!mapinfo\x05获得更多信息！");
    }
    else
    {
        if (IsClientInGame(client))
        {
            PrintToChat(client, "\x04地图编号: \x01%d", map_index);
            PrintToChat(client, "\x04中文名: \x01%s", map_name_zh);
            PrintToChat(client, "\x04英文名: \x01%s", map_name_en);
            PrintToChat(client, "\x04关卡数: \x01%d/%d", chapter_num, map_chapter_num);
            PrintToChat(client, "\x04评分: \x01%.1f", map_offi_rating);
            PrintToChat(client, "\x04地图介绍: \x01%d 字", strlen(map_intro));
            PrintToChat(client, "\x05请输入\x04!mapinfo\x05获得更多信息！");
        }
    }
}

PrintIntroChat(int client)
{
    int buffer_index = 0;
    while (buffer_index < total_index)
    {
        if (client == 0) PrintToChatAll(map_intro_buffer[buffer_index]);
        else if (IsClientInGame(client)) PrintToChat(client, map_intro_buffer[buffer_index]);
        buffer_index = buffer_index + 1;
    }
}

const int UTF8MULTIBYTECHAR = (1 << 7);

//this function assumes string is a correctly encoded utf8 string that is cutted in not utf8 safe way.
stock terminateUTF8String(char[] buffer, const int maxlength = -1){
    
    if (maxlength > 0) {
        buffer[maxlength - 1] = '\0';
    }
    
    int length = strlen(buffer);
    int bytescounted = 0;
    
    if (length <= 0)
    {
        return 0;
    }
    for (int i = length - 1; i >= 0; i--)
    {
        if (UTF8MULTIBYTECHAR & buffer[i] == '\0')
        {
            return 0;//its a single byte character, we have nothing to do.
        }
        else
        {
            //j is not a good idea...
            for (int j = 1; j <= 7; j++){
                if ((UTF8MULTIBYTECHAR >> j) & buffer[i] == '\0')
                {	
                    if (j == 1)
                    {
                        //its part of multi byte character
                        bytescounted++;
                        break;
                    }
                    else
                    {
                        //its starting byte of multi byte character, so lets see if we readed enough amount of utf8 strings before and cut it if its not.
                        if (bytescounted != (j - 1)){
                            buffer[i] = '\0';
                        }
                        return 0;
                    }
                }
            }
        }
    }
    return 0;
}

public Action ShowMapInfoMenu(int client)
{
    if (!info_exist)
    {
        PrintToChat(client, "当前地图暂无简介");
        return Plugin_Handled;
    }

    Panel panel = new Panel();
    panel.SetTitle("地图信息:");

    int buffer_index = current_index[client];
    while (buffer_index - current_index[client] < 7 && buffer_index < total_index)
    {
        panel.DrawText(map_intro_buffer[buffer_index]);
        buffer_index = buffer_index + 1;
    }

    while (buffer_index - current_index[client] < 7)
    {
        panel.DrawText(" ");
        buffer_index = buffer_index + 1;
    }

    if (current_index[client] > 0)
    {
        panel.DrawItem("上一页", ITEMDRAW_CONTROL);
    }
    else
    {
        panel.DrawItem("上一页", ITEMDRAW_DISABLED);
    }

    if (buffer_index < total_index)
    {
        panel.DrawItem("下一页", ITEMDRAW_CONTROL);
    }
    else
    {
        panel.DrawItem("下一页", ITEMDRAW_DISABLED);
    }

    panel.DrawItem("退出", ITEMDRAW_CONTROL);

    if (client == 0)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                panel.Send(i, MapInfoPanelHandler, MENU_TIME_FOREVER);
            }
        }
    }
    else
    {
        panel.Send(client, MapInfoPanelHandler, MENU_TIME_FOREVER);
    }
    delete panel;
    return Plugin_Handled;
}

public MapInfoPanelHandler(Handle menu, MenuAction action, int client, int param)
{
    switch (action) 
	{
        case MenuAction_Start:
		{
			// PrintToServer("Displaying menu");
		}
		case MenuAction_Select: 
		{
            // PrintToChatAll("选择：%d", param);
            switch(param)
            {
                case 1:
                {
                    current_index[client] = current_index[client] - 7;
                    if (current_index[client] < 0) current_index[client] = 0;
                    ShowMapInfoMenu(client);
                }
                case 2:
                {
                    current_index[client] = current_index[client] + 7;
                    if (current_index[client] >= total_index) current_index[client] = (total_index - 1) / 7 * 7;
                    ShowMapInfoMenu(client);
                }
                case 3:
                {
                    current_index[client] = 0;
                }
            }
		}
		case MenuAction_Cancel:
		{
			current_index[client] = 0;
		}
		case MenuAction_End: 
		{
			current_index[client] = 0;
		}
        case MenuAction_DrawItem:
		{
			//return ITEMDRAW_RAWLINE;
		}
        case MenuAction_DisplayItem:
		{

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
    if (IsClientInGame(client))
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
