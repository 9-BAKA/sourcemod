#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
  name = "地图评分系统sql版", 
  author = "BAKA", 
  description = "地图评分系统 使用sql的版本", 
  version = PLUGIN_VERSION, 
  url = "https://baka.cirno.cn"
}

new Handle:g_hDB;
new Handle:g_hStatement;

public OnPluginStart()
{
  CreateConVar("sm_maprating_version", PLUGIN_VERSION, "Map Rating Plugin Version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
  SQL_TConnect(TConnect, "storage-local");
}

public TConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
  if (hndl == INVALID_HANDLE)
  {
    SetFailState("error: %s", error);
  }
  
  g_hDB = hndl;
  
  /* 
CREATE  TABLE  IF NOT EXISTS 'maps' ('map' VARCHAR PRIMARY KEY  NOT NULL , 'time' DATETIME DEFAULT CURRENT_TIMESTAMP, 'loaded' BOOL) 
*/
  SQL_LockDatabase(g_hDB);
  SQL_FastQuery(g_hDB, "CREATE TABLE maps (map varchar(255) NOT NULL,time DATETIME DEFAULT CURRENT_TIMESTAMP,loaded BOOL,PRIMARY KEY (map))");
  SQL_UnlockDatabase(g_hDB);
  
  /* 
INSERT OR REPLACE INTO 'maps' ('map','loaded') VALUES ('d1_trainstation_01' , 1) 
*/
  new String:buffer[256];
  g_hStatement = SQL_PrepareQuery(g_hDB, "REPLACE INTO maps (map,loaded) VALUES (? , ?)", buffer, sizeof(buffer));
  
  if (g_hStatement == INVALID_HANDLE)
  {
    PrintToServer("g_hStatement error: %s", buffer); 
  }
  
  //PrintToServer("connect"); 
  /* SELECT * FROM maps ORDER BY time DESC LIMIT 0 , 2*/
  SQL_TQuery(g_hDB, TQuery, "SELECT map, loaded FROM maps ORDER BY time DESC LIMIT 0 , 2");
}

public TQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
  new String:buffer[MAX_NAME_LENGTH], loaded;
  while (SQL_FetchRow(hndl))
  {
    SQL_FetchString(hndl, 0, buffer, sizeof(buffer));
    loaded = SQL_FetchInt(hndl, 1);
    //PrintToServer("buffer %s %i", buffer, loaded); 
    
    if (loaded)
    {
      ServerCommand("changelevel %s", buffer);
      LogMessage("[CrashMap] Changed map to %s after crash!", buffer);
      break;
    }
  }
}

public OnMapStart()
{
  if (g_hDB == INVALID_HANDLE)
  {
    return;
  }
  
  new String:query[256];
  GetCurrentMap(query, sizeof(query));
  SQL_BindParamString(g_hStatement, 0, query, false);
  SQL_BindParamInt(g_hStatement, 1, 0);
  
  SQL_LockDatabase(g_hDB);
  SQL_Execute(g_hStatement);
  SQL_UnlockDatabase(g_hDB);
  
  CreateTimer(30.0, update, _, TIMER_FLAG_NO_MAPCHANGE);
  //PrintToServer("insert %s", query); 
}

public Action:update(Handle:timer)
{
  new String:query[256];
  GetCurrentMap(query, sizeof(query));
  SQL_BindParamString(g_hStatement, 0, query, false);
  SQL_BindParamInt(g_hStatement, 1, 1);
  
  SQL_LockDatabase(g_hDB);
  SQL_Execute(g_hStatement);
  SQL_UnlockDatabase(g_hDB);
  //PrintToServer("update %s", query); 
} 


// Functions

public Action:InitPlayers(Handle:timer)
{
  if (db == INVALID_HANDLE)
    return;

  decl String:query[64];
  Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", DbPrefix);
  SQL_TQuery(db, GetRankTotal, query);

  new maxplayers = GetMaxClients();

  for (new i = 1; i <= maxplayers; i++)
  {
    if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
    {
      CheckPlayerDB(i);

      QueryClientPoints(i);

      TimerPoints[i] = 0;
      TimerKills[i] = 0;
    }
  }
}

CheckPlayerDB(client)
{
  if (StatsDisabled())
    return;

  if (IsClientBot(client))
    return;

  decl String:SteamID[MAX_LINE_WIDTH];
  GetClientRankAuthString(client, SteamID, sizeof(SteamID));

  decl String:query[512];
  Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE steamid = '%s'", DbPrefix, SteamID);
  SQL_TQuery(db, InsertPlayerDB, query, client);

  ReadClientRankMuteSteamID(client, SteamID);
}

public InsertPlayerDB(Handle:owner, Handle:hndl, const String:error[], any:client)
{
  if (db == INVALID_HANDLE || IsClientBot(client))
  {
    return;
  }

  if (hndl == INVALID_HANDLE)
  {
    LogError("InsertPlayerDB failed! Reason: %s", error);
    return;
  }

  if (StatsDisabled())
  {
    return;
  }

  if (!SQL_GetRowCount(hndl))
  {
    new String:SteamID[MAX_LINE_WIDTH];
    GetClientRankAuthString(client, SteamID, sizeof(SteamID));

    new String:query[512];
    Format(query, sizeof(query), "INSERT IGNORE INTO %splayers SET steamid = '%s'", DbPrefix, SteamID);
    SQL_TQuery(db, SQLErrorCheckCallback, query);
  }

  UpdatePlayer(client);
}

public UpdatePlayer(client)
{
  if (!IsClientConnected(client))
  {
    return;
  }

  decl String:SteamID[MAX_LINE_WIDTH];
  GetClientRankAuthString(client, SteamID, sizeof(SteamID));

  decl String:Name[MAX_LINE_WIDTH];
  GetClientName(client, Name, sizeof(Name));

  ReplaceString(Name, sizeof(Name), "<?php", "");
  ReplaceString(Name, sizeof(Name), "<?PHP", "");
  ReplaceString(Name, sizeof(Name), "?>", "");
  ReplaceString(Name, sizeof(Name), "\\", "");
  ReplaceString(Name, sizeof(Name), "\"", "");
  ReplaceString(Name, sizeof(Name), "'", "");
  ReplaceString(Name, sizeof(Name), ";", "");
  ReplaceString(Name, sizeof(Name), "�", "");
  ReplaceString(Name, sizeof(Name), "`", "");

  UpdatePlayerFull(client, SteamID, Name);
}

public UpdatePlayerFull(Client, const String:SteamID[], const String:Name[])
{
  // Client can be ZERO! Look at UpdatePlayerCallback.

  decl String:IP[16];
  GetClientIP(Client, IP, sizeof(IP));

  decl String:query[512];
  Format(query, sizeof(query), "UPDATE %splayers SET name = '%s', ip = '%s' WHERE steamid = '%s'", DbPrefix, Name, IP, SteamID);
  SQL_TQuery(db, UpdatePlayerCallback, query, Client);
}

public UpdatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
  if (db == INVALID_HANDLE)
  {
    return;
  }

  if (!StrEqual("", error))
  {
    if (client > 0)
    {
      decl String:SteamID[MAX_LINE_WIDTH];
      GetClientRankAuthString(client, SteamID, sizeof(SteamID));

      UpdatePlayerFull(0, SteamID, "INVALID_CHARACTERS");

      return;
    }

    LogError("SQL Error: %s", error);
  }
}
