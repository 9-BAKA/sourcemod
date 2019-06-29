#include <sourcemod>
#include <sdktools_functions>

public Plugin:myinfo =
{
	name = "设置血量",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_xueliang", Test, ADMFLAG_ROOT, "测试权限");
}

public Action Test(int client, int args)
{
	int sBonusHP = 0;
	if (args < 1)
	{
		sBonusHP = 10000;
	}
	else if (args > 1)
	{
		PrintToChat(client, "\x04请输入正确参数");
		return Plugin_Handled;
	}
	else
	{
		char arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		sBonusHP = StringToInt(arg, 10);
	}
	// PrintToChatAll("%i", sBonusHP);
	// if (sBonusHP < 0) sBonusHP = 0;
	SetEntProp(client, PropType:0, "m_iHealth", sBonusHP, 1, 0);
	return Plugin_Continue;
}

