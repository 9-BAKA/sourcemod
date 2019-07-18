#include <sourcemod>
#include <sdktools>

new Handle:hCountKIHNum;
new CountKIHNum;
new Handle:hCountKIHWitch;
new CountKIHWitch;
new Handle:hCountKIHLimit;
new CountKIHLimit;
new Handle:hCountKIHSalve;
new CountKIHSalve;
new Handle:hCountKIHTreat;
new CountKIHTreat;
new HLkIF;
new bool:HLReturnset;
new Handle:hOA_HP;
new bool:OA_HP;
public Plugin:myinfo =
{
	name = "L4D2回血插件",
	description = "L4D2回血插件",
	author = "望夜Ryanx",
	version = "1.1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_onhx", OnHLReturn, "", 0);
	RegConsoleCmd("sm_offhx", OffHLReturn, "", 0);
	HookEvent("player_death", KIHEvent_KillInfected, EventHookMode:1);
	HookEvent("witch_killed", KIHEvent_KillWitch, EventHookMode:1);
	HookEvent("round_start", KIHEvent_RoundStart, EventHookMode:2);
	HookEvent("revive_success", KIHEvent_revive, EventHookMode:1);
	HookEvent("heal_success", KIHEvent_heal, EventHookMode:1);
	CreateConVar("l4d2_health_return_Version", "L4D2回血插件v1.1-by望夜", "L4D2回血插件v1.1-by望夜", 8512, false, 0.0, false, 0.0);
	hOA_HP = CreateConVar("Only_Admin", "0", "[0=所有人|1=仅管理员]可使用命令", 0, true, 0.0, true, 1.0);
	hCountKIHNum = CreateConVar("kill_inf_health_return", "2", "每击杀一只特感可回多少血.", 0, true, 1.0, true, 100.0);
	hCountKIHWitch = CreateConVar("kill_witch_health_return", "20", "击杀一只Witch可回多少血.", 0, true, 1.0, true, 100.0);
	hCountKIHLimit = CreateConVar("health_limit", "150", "最高回血上限.", 0, true, 40.0, true, 500.0);
	hCountKIHSalve = CreateConVar("salve_health", "5", "救人者回多少血.", 0, true, 1.0, true, 100.0);
	hCountKIHTreat = CreateConVar("treat_health", "10", "帮人打包者回多少血.", 0, true, 1.0, true, 100.0);
	AutoExecConfig(true, "l4d2_health_return", "sourcemod");
	HLReturnset = false;
	OA_HP = GetConVarBool(hOA_HP);
	HLkIF = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
}

public OnMapStart()
{
	OA_HP = GetConVarBool(hOA_HP);
	ReadCFGHR();
}

public ReadCFGHR()
{
	CountKIHNum = GetConVarInt(hCountKIHNum);
	CountKIHWitch = GetConVarInt(hCountKIHWitch);
	CountKIHLimit = GetConVarInt(hCountKIHLimit);
	CountKIHSalve = GetConVarInt(hCountKIHSalve);
	CountKIHTreat = GetConVarInt(hCountKIHTreat);
}

public Action:KIHEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(2.0, CheckKIHDelays, any:0, 0);
	return Action:0;
}

public Action:CheckKIHDelays(Handle:timer)
{
	if (HLReturnset)
	{
		PrintToChatAll("\x04[!提示!]\x03 已开启回血,上限 %d HP;输入!offhx可关闭回血", CountKIHLimit);
	}
	else
	{
		PrintToChatAll("\x04[!提示!]\x03 已关闭回血,输入!onhx可关闭回血");
	}
	return Action:0;
}

public Action:OnHLReturn(client, args)
{
	if (OA_HP && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	HLReturnset = true;
	PrintToChatAll("\x04[!提示!]\x03 已开启回血,上限 %d HP;输入!offhx可关闭回血", CountKIHLimit);
	return Action:0;
}

public Action:OffHLReturn(client, args)
{
	if (OA_HP && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	HLReturnset = false;
	PrintToChatAll("\x04[!提示!]\x03 已关闭回血,输入!onhx可关闭回血");
	return Action:0;
}

public Action:KIHEvent_KillInfected(Handle:event, String:name[], bool:dontBroadcast)
{
	if (HLReturnset)
	{
		new ikiller = GetClientOfUserId(GetEventInt(event, "attacker", 0));
		new ideadbody = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (0 < ikiller <= MaxClients && ideadbody)
		{
			new Attackerhealth = GetClientHealth(ikiller);
			if (Attackerhealth < CountKIHLimit)
			{
				new HLZClass = GetEntData(ideadbody, HLkIF, 4);
				if (GetClientTeam(ikiller) == 2)
				{
					if (HLZClass == 1 || HLZClass == 2 || HLZClass == 3 || HLZClass == 4 || HLZClass == 5 || HLZClass == 6)
					{
						new Numaddhealth = CountKIHNum + Attackerhealth;
						if (Numaddhealth > CountKIHLimit)
						{
							Numaddhealth = CountKIHLimit;
						}
						SetEntityHealth(ikiller, Numaddhealth);
						SetEntProp(ikiller, PropType:1, "m_ArmorValue", Numaddhealth, 4, 0);
					}
				}
			}
		}
	}
	return Action:0;
}

public Action:KIHEvent_KillWitch(Handle:event, String:name[], bool:dontBroadcast)
{
	if (HLReturnset)
	{
		new ikiller = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (0 < ikiller <= MaxClients)
		{
			new Attackerhealth = GetClientHealth(ikiller);
			if (Attackerhealth < CountKIHLimit)
			{
				if (GetClientTeam(ikiller) == 2)
				{
					new String:Killwitchname[64];
					GetClientName(ikiller, Killwitchname, 64);
					new Numaddhealth = CountKIHWitch + Attackerhealth;
					if (Numaddhealth > CountKIHLimit)
					{
						Numaddhealth = CountKIHLimit;
					}
					SetEntityHealth(ikiller, Numaddhealth);
					SetEntProp(ikiller, PropType:1, "m_ArmorValue", Numaddhealth, 4, 0);
					PrintToChatAll("\x04< %s >\x05 击杀了Witch,奖励 %d HP", Killwitchname, CountKIHWitch);
				}
			}
		}
	}
	return Action:0;
}

public Action:KIHEvent_revive(Handle:event, String:name[], bool:dontBroadcast)
{
	if (HLReturnset)
	{
		new irevive = GetClientOfUserId(GetEventInt(event, "userid", 0));
		new irevivehealth = GetClientHealth(irevive);
		if (irevivehealth < CountKIHLimit)
		{
			new String:irevivename[64];
			GetClientName(irevive, irevivename, 64);
			new Numaddhealth1 = CountKIHSalve + irevivehealth;
			if (Numaddhealth1 > CountKIHLimit)
			{
				Numaddhealth1 = CountKIHLimit;
			}
			SetEntityHealth(irevive, Numaddhealth1);
			SetEntProp(irevive, PropType:1, "m_ArmorValue", Numaddhealth1, 4, 0);
			PrintToChatAll("\x04< %s >\x05 救起了队友,奖励 %d HP", irevivename, CountKIHSalve);
		}
	}
	return Action:0;
}

public Action:KIHEvent_heal(Handle:event, String:name[], bool:dontBroadcast)
{
	if (HLReturnset)
	{
		new iheal = GetClientOfUserId(GetEventInt(event, "userid", 0));
		new idoheal = GetClientOfUserId(GetEventInt(event, "subject", 0));
		new ihealhealth = GetClientHealth(iheal);
		if (idoheal != iheal && ihealhealth < CountKIHLimit)
		{
			new String:ihealname[64];
			GetClientName(iheal, ihealname, 64);
			new Numaddhealth2 = CountKIHTreat + ihealhealth;
			if (Numaddhealth2 > CountKIHLimit)
			{
				Numaddhealth2 = CountKIHLimit;
			}
			SetEntityHealth(iheal, Numaddhealth2);
			SetEntProp(iheal, PropType:1, "m_ArmorValue", Numaddhealth2, 4, 0);
			PrintToChatAll("\x04< %s >\x05 治愈了队友,奖励 %d HP", ihealname, CountKIHTreat);
		}
	}
	return Action:0;
}

