#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define AA   1
#define BB   2

#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"
#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"
Handle test_timer;

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
	RegConsoleCmd("sm_test2", Test, "测试");
	RegConsoleCmd("motto", Motto, "准星处更多物体");
	RegConsoleCmd("more", Motto, "准星处更多物体");
}

public Action Test(int client, int args)
{
	test_timer = CreateTimer(10.0, TimerTest);
	int Ent = GetClientAimTarget(client, false);
	if (IsValidEntity(Ent))
	{
		int i_Offset = FindDataMapInfo(Ent, "m_itemCount");
		if (i_Offset == -1) return Plugin_Continue;
		int i_Value = GetEntData(Ent, i_Offset, 4);
		PrintToChatAll("count: %d", i_Value);
	}
	else
	{
		PrintToChat(client, "\x04[model]\x05 准星处找不到实体.");
	}
	return Plugin_Continue;
}

public Action Motto(int client, int args)
{
	int num = 1;
	if (args > 0)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		num = StringToInt(arg, 10);
		if (num > 10 || num < 1)
		{
			PrintToChat(client, "\x04[Motto]\x05 请输入1-10以内的数.");
			return Plugin_Continue;
		}
	}

	int Ent = GetClientAimTarget(client, false);
	if (IsValidEntity(Ent))
	{
		int i_Offset = FindDataMapInfo(Ent, "m_itemCount");
		int i_Value;
		if (i_Offset == -1) i_Value = 1;
		else i_Value = GetEntData(Ent, i_Offset, 4);
		char increase_num[4];
		if (i_Value + num > 30)
		{
			Format(increase_num, 4, "%d", 30);
			DispatchKeyValue(Ent, "count", increase_num);
			PrintToChat(client, "\x04[Motto]\x05 已达到允许设置的拿取次数上限\x0430\x05.");
		}
		else
		{
			Format(increase_num, 4, "%d", i_Value + num);
			DispatchKeyValue(Ent, "count", increase_num);
			PrintToChat(client, "\x04[Motto]\x05 增加准星处物体\x03%d\x05次拿取次数,剩余可拿\x04%d\x05次", num, i_Value + num);
		}
	}
	else
	{
		PrintToChat(client, "\x04[Motto]\x05 准星处找不到实体.");
	}
	return Plugin_Continue;
}


public Action:TimerTest(Handle:timer)
{
	PrintToServer("计时器测试");
	return Action:0;
}