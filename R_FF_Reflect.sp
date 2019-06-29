#include <sourcemod>
#include <sdktools>

new bool:RFFControl;
new Handle:hFfStatus;
new Handle:hCountPNum;
new Float:CountPNum;
public Plugin:myinfo =
{
	name = "R FF Reflect ",
	description = "L4D2 Friendly Fire Reflect",
	author = "Ryanx",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_onfs", OnFFControl, "", 0);
	RegConsoleCmd("sm_offfs", OffFFControl, "", 0);
	CreateConVar("L4D2_r_ffs_version", "1.0", "反伤控制", 8512, false, 0.0, false, 0.0);
	hFfStatus = CreateConVar("L4D2_r_ffs_status", "0", "默认是否开启反伤", 8512, false, 0.0, false, 0.0);
	hCountPNum = CreateConVar("L4D2_ff_rp", "0.5", "反伤百分比", 0, true, 0.0, true, 2.0);
	HookEvent("player_hurt", RFFSEvent_PlayerHurt, EventHookMode:1);
	HookEvent("round_start", RFFSHEvent_RoundStart, EventHookMode:1);
	AutoExecConfig(true, "R_FF_Reflect", "sourcemod");
	RFFControl = GetConVarBool(hFfStatus);
}

public Action:OnFFControl(client, args)
{
	if (client == 0 || GetUserFlagBits(client))
	{
		RFFControl = true;
		PrintToChatAll("\x04[!提示!]\x03 已开启反伤;输入!offfs可关闭");
		return Action:0;
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用");
	return Action:0;
}

public Action:OffFFControl(client, args)
{
	if (client == 0 || GetUserFlagBits(client))
	{
		RFFControl = false;
		PrintToChatAll("\x04[!提示!]\x03 已关闭反伤;输入!onfs可开启");
		return Action:0;
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	return Action:0;
}

public void OnMapStart()
{
	CountPNum = GetConVarFloat(hCountPNum);
}

public Action:RFFSHEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CountPNum = GetConVarFloat(hCountPNum);
	CreateTimer(3.0, CheckRFFDelays, any:0, 0);
	return Action:0;
}

public Action:CheckRFFDelays(Handle:timer)
{
	if (RFFControl)
	{
		PrintToChatAll("\x04[!提示!]\x03 已开启反伤;输入!offfs可关闭");
	}
	else
	{
		PrintToChatAll("\x04[!提示!]\x03 已关闭反伤;输入!onfs可开启");
	}
	return Action:0;
}

public Action:RFFSEvent_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	if (RFFControl)
	{
		new Traget_FFid = GetClientOfUserId(GetEventInt(event, "userid", 0));
		new Attacker_FFid = GetClientOfUserId(GetEventInt(event, "attacker", 0));
		if (Traget_FFid && Attacker_FFid && GetClientTeam(Traget_FFid) == 2 && GetClientTeam(Attacker_FFid) == 2 && !IsFakeClient(Traget_FFid))
		{
			decl String:Aweapon[32];
			GetEventString(event, "weapon", Aweapon, 32, "");
			if (Attacker_FFid != Traget_FFid && !RIsPlayerIncapacitated(Traget_FFid))
			{
				if (!StrEqual(Aweapon, "inferno", true) && !StrEqual(Aweapon, "pipe_bomb", true) && !StrEqual(Aweapon, "fire_cracker_blast", true) && !StrEqual(Aweapon, "melee", true))
				{
					new Attackerhealth = GetClientHealth(Attacker_FFid);
					new Attackerarmor = GetClientArmor(Attacker_FFid);
					new R_dmgHP = GetEventInt(event, "dmg_health", 0);
					new R_dmgAR = GetEventInt(event, "dmg_armor", 0);
					new CountFFHPNum = RoundToCeil(CountPNum * float(R_dmgHP));
					new CountFFARNum = RoundToCeil(CountPNum * float(R_dmgAR));
					if (0 >= Attackerhealth - CountFFHPNum)
					{
						new BUFFFFHNum = RoundToCeil(GetEntPropFloat(Attacker_FFid, PropType:0, "m_healthBuffer", 0));
						if (0 >= BUFFFFHNum - CountFFHPNum)
						{
							if (GetEntProp(Attacker_FFid, PropType:0, "m_currentReviveCount", 4, 0) > 1)
							{
								ForcePlayerSuicide(Attacker_FFid);
								return Action:0;
							}
							SetEntPropFloat(Attacker_FFid, PropType:0, "m_healthBuffer", 299.0, 0);
							SetEntProp(Attacker_FFid, PropType:0, "m_isIncapacitated", any:1, 4, 0);
							SetEntPropFloat(Attacker_FFid, PropType:0, "m_healthBuffer", 299.0, 0);
							SetEntPropFloat(Attacker_FFid, PropType:0, "m_healthBufferTime", GetGameTime(), 0);
						}
						else
						{
							SetEntPropFloat(Attacker_FFid, PropType:0, "m_healthBuffer", float(BUFFFFHNum) - float(CountFFHPNum), 0);
						}
					}
					else
					{
						SetEntityHealth(Attacker_FFid, Attackerhealth - CountFFHPNum);
						SetEntProp(Attacker_FFid, PropType:1, "m_ArmorValue", Attackerarmor - CountFFARNum, 4, 0);
					}
					PrintHintText(Attacker_FFid, "[!黑枪!] 反伤 -%d HP", CountFFHPNum);
				}
			}
		}
	}
	return Action:0;
}

bool:RIsPlayerIncapacitated(client)
{
	return GetEntProp(client, PropType:0, "m_isIncapacitated", 1, 0) > 0;
}

