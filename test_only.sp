#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

public Plugin:myinfo =
{
	name = "仅供测试",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_test", Test, "测试");
}

public Action Test(int client, int args)
{
	char currentMap[64], nextMap[64];
	bool isNextMap;
	GetCmdArg(1, currentMap, sizeof(currentMap));
	isNextMap = GetNextMap(nextMap, 64);
	if (isNextMap)
	{
		PrintToServer("下一张地图 %s", nextMap);
	}
	else
	{
		PrintToServer("无下一张地图");
	}
	return Plugin_Continue;
}

