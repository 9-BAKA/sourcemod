#include <sourcemod>
#include <sdktools>

bool SetZCommonEnable = false;

public Plugin:myinfo =
{
	name = "自动设置小僵尸数",
	description = "自动设置小僵尸数",
	author = "BAKA",
	version = "1.0",
	url = "https://baka.cirno.cn"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_onzc", OnAutoZc, ADMFLAG_ROOT, "开启自动僵尸数");
	RegAdminCmd("sm_offzc", OffAutoZc, ADMFLAG_ROOT, "关闭自动僵尸数");
}

public Action OnAutoZc(int client, int args)
{
	SetZCommonEnable = true;
	CreateTimer(0.1, SetZCommon);
	return Plugin_Continue;
}

public Action OffAutoZc(int client, int args)
{
	SetZCommonEnable = false;
	CreateTimer(0.1, SetZCommon);
	return Plugin_Continue;
}
public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if(SetZCommonEnable && !IsFakeClient(client))
	{
		CreateTimer(5.0, SetZCommon);
	}
}

public void OnClientDisconnect(int client)
{
	if(SetZCommonEnable && !IsFakeClient(client))
	{
		CreateTimer(5.0, SetZCommon);
	}
}

public Action SetZCommon(Handle timer)
{
	if (!SetZCommonEnable)
	{
		SetConVarInt(FindConVar("z_common_limit"), 30, false, false);
	}
	else
	{
		int numSurvivors = Survivors();
		if (numSurvivors <= 6) SetConVarInt(FindConVar("z_common_limit"), 30, false, false);
		else if (numSurvivors <= 8) SetConVarInt(FindConVar("z_common_limit"), 45, false, false);
		else SetConVarInt(FindConVar("z_common_limit"), 60, false, false);
	}
}

public int Survivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 1))
		{
			numSurvivors++;
		}
		i++;
	}
	return numSurvivors;
}