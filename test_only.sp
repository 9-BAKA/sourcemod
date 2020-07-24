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

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
		PrintToServer("[Test]OnClientPostAdminCheck, %d, %d", IsClientConnected(client), IsClientInGame(client));
}

public void OnClientConnected(int client)
{
	if (!IsFakeClient(client))
    	PrintToServer("[Test]OnClientConnected, %d, %d", IsClientConnected(client), IsClientInGame(client));
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
    	PrintToServer("[Test]OnClientPutInServer, %d, %d", IsClientConnected(client), IsClientInGame(client));
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
		PrintToServer("[Test]OnClientConnect: %d, %s, %d", client, rejectmsg, maxlen);
	return true;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!IsFakeClient(client))
    	PrintToServer("[Test]OnClientAuthorized, %d, %d", IsClientConnected(client), IsClientInGame(client));
}