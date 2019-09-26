#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define AA   1
#define BB   2

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
	int test[5];
	int temp = 2;
	if (temp == AA)
		test[temp] = 3;
	PrintToChatAll("%d", test[0]);
	
	return Plugin_Continue;
}

