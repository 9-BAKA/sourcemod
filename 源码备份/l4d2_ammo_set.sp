#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

new Handle:hC_SMG;
new C_SMG;
new Handle:hC_Shotgun;
new C_Shotgun;
new Handle:hC_Autoshotgun;
new C_Autoshotgun;
new Handle:hC_AssaultRifle;
new C_AssaultRifle;
new Handle:hC_HuntingRifle;
new C_HuntingRifle;
new Handle:hC_SniperRifle;
new C_SniperRifle;
new Handle:hC_GrenadeLauncher;
new C_GrenadeLauncher;
new Handle:hC_M60;
new C_M60;
new Theammoset;
new Handle:hOA_ammset;
new bool:OA_ammset;

public Plugin:myinfo =
{
	name = "L4D2备弹量设定",
	description = "L4D2 ammo set (!onammo,!onammo2,!offammo)",
	author = "Ryanx",
	version = "L4D2备弹量设定",
	url = ""
};
public void OnPluginStart()
{
	CreateConVar("L4D2_ammo_set_version", "L4D2备弹量设定", "!onammo双倍备弹;!offammo默认备弹;!onammo1自定备弹;!onammo2无限备弹", 8512, false, 0.0, false, 0.0);
	RegConsoleCmd("sm_onammo", Onammosets, "", 0);
	RegConsoleCmd("sm_offammo", Offammosets, "", 0);
	RegConsoleCmd("sm_onammo2", Onammosets2, "", 0);
	RegConsoleCmd("sm_onammo1", Onammosets1, "", 0);
	HookEvent("round_start", ammoEvent_RoundStart, EventHookMode:2);
	hOA_ammset = CreateConVar("Only_Admin", "0", "[0=所有人|1=仅管理员]可使用命令", 0, true, 0.0, true, 1.0);
	hC_SMG = CreateConVar("C_SMG", "650", "!onammo1 自定微冲备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_SMG = GetConVarInt(hC_SMG);
	hC_Shotgun = CreateConVar("C_Shotgun", "56", "!onammo1 自定单喷备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_Shotgun = GetConVarInt(hC_Shotgun);
	hC_Autoshotgun = CreateConVar("C_Autoshotgun", "90", "!onammo1 自定连喷备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_Autoshotgun = GetConVarInt(hC_Autoshotgun);
	hC_AssaultRifle = CreateConVar("C_AssaultRifle", "360", "!onammo1 自定步枪备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_AssaultRifle = GetConVarInt(hC_AssaultRifle);
	hC_HuntingRifle = CreateConVar("C_HuntingRifle", "150", "!onammo1 自定1代狙备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_HuntingRifle = GetConVarInt(hC_HuntingRifle);
	hC_SniperRifle = CreateConVar("C_SniperRifle", "180", "!onammo1 自定2代狙备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_SniperRifle = GetConVarInt(hC_SniperRifle);
	hC_GrenadeLauncher = CreateConVar("C_GrenadeLauncher", "30", "!onammo1 自定榴弹备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_GrenadeLauncher = GetConVarInt(hC_GrenadeLauncher);
	hC_M60 = CreateConVar("C_M60", "0", "!onammo1 自定M60备弹数0-1000(1000=无限)", 0, true, 0.0, true, 1000.0);
	C_M60 = GetConVarInt(hC_M60);
	Theammoset = 0;
	AutoExecConfig(true, "l4d2_ammo_set", "sourcemod");
	OA_ammset = GetConVarBool(hOA_ammset);
}

public void OnMapStart()
{
	OA_ammset = GetConVarBool(hOA_ammset);
	C_SMG = GetConVarInt(hC_SMG);
	C_Shotgun = GetConVarInt(hC_Shotgun);
	C_Autoshotgun = GetConVarInt(hC_Autoshotgun);
	C_AssaultRifle = GetConVarInt(hC_AssaultRifle);
	C_HuntingRifle = GetConVarInt(hC_HuntingRifle);
	C_SniperRifle = GetConVarInt(hC_SniperRifle);
	C_GrenadeLauncher = GetConVarInt(hC_GrenadeLauncher);
	C_M60 = GetConVarInt(hC_M60);
}

public Action:Onammosets(client, args)
{
	if (OA_ammset && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Theammoset = 1;
	CreateTimer(0.1, ammosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:Offammosets(client, args)
{
	if (OA_ammset && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Theammoset = 0;
	CreateTimer(0.1, ammosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:Onammosets2(client, args)
{
	if (OA_ammset && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Theammoset = 2;
	CreateTimer(0.1, ammosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:Onammosets1(client, args)
{
	if (OA_ammset && GetUserFlagBits(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Theammoset = 3;
	CreateTimer(0.1, ammosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:ammoEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, ammosetStartDelays, any:0, 0);
	return Action:0;
}

public Action:ammosetStartDelays(Handle:timer)
{
	switch (Theammoset)
	{
		case 0:
		{
			SetConVarInt(FindConVar("ammo_smg_max"), 650, false, false);
			SetConVarInt(FindConVar("ammo_shotgun_max"), 56, false, false);
			SetConVarInt(FindConVar("ammo_autoshotgun_max"), 90, false, false);
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), 360, false, false);
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), 150, false, false);
			SetConVarInt(FindConVar("ammo_sniperrifle_max"), 180, false, false);
			SetConVarInt(FindConVar("ammo_grenadelauncher_max"), 30, false, false);
			SetConVarInt(FindConVar("ammo_m60_max"), 0, false, false);
			PrintToChatAll("\x04[!提示!]\x03 已关闭更多备弹量");
		}
		case 1:
		{
			SetConVarInt(FindConVar("ammo_smg_max"), 999, false, false);
			SetConVarInt(FindConVar("ammo_shotgun_max"), 168, false, false);
			SetConVarInt(FindConVar("ammo_autoshotgun_max"), 180, false, false);
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), 720, false, false);
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), 300, false, false);
			SetConVarInt(FindConVar("ammo_sniperrifle_max"), 360, false, false);
			SetConVarInt(FindConVar("ammo_grenadelauncher_max"), 60, false, false);
			SetConVarInt(FindConVar("ammo_m60_max"), 150, false, false);
			PrintToChatAll("\x04[!提示!]\x03 已开启2倍备弹");
		}
		case 2:
		{
			SetConVarInt(FindConVar("ammo_smg_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_shotgun_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_autoshotgun_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_sniperrifle_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_grenadelauncher_max"), -2, false, false);
			SetConVarInt(FindConVar("ammo_m60_max"), -2, false, false);
			PrintToChatAll("\x04[!提示!]\x03 已开启无限备弹");
		}
		case 3:
		{
			new RammoN[8] = {650,56,90,360,150,180,30};
			if (C_SMG == 1000)
			{
				RammoN[0] = -2;
			}
			else
			{
				RammoN[0] = C_SMG;
			}
			if (C_Shotgun == 1000)
			{
				RammoN[1] = -2;
			}
			else
			{
				RammoN[1] = C_Shotgun;
			}
			if (C_Autoshotgun == 1000)
			{
				RammoN[2] = -2;
			}
			else
			{
				RammoN[2] = C_Autoshotgun;
			}
			if (C_AssaultRifle == 1000)
			{
				RammoN[3] = -2;
			}
			else
			{
				RammoN[3] = C_AssaultRifle;
			}
			if (C_HuntingRifle == 1000)
			{
				RammoN[4] = -2;
			}
			else
			{
				RammoN[4] = C_HuntingRifle;
			}
			if (C_SniperRifle == 1000)
			{
				RammoN[5] = -2;
			}
			else
			{
				RammoN[5] = C_SniperRifle;
			}
			if (C_GrenadeLauncher == 1000)
			{
				RammoN[6] = -2;
			}
			else
			{
				RammoN[6] = C_GrenadeLauncher;
			}
			if (C_M60 == 1000)
			{
				RammoN[7] = -2;
			}
			else
			{
				RammoN[7] = C_M60;
			}
			SetConVarInt(FindConVar("ammo_smg_max"), RammoN[0], false, false);
			SetConVarInt(FindConVar("ammo_shotgun_max"), RammoN[1], false, false);
			SetConVarInt(FindConVar("ammo_autoshotgun_max"), RammoN[2], false, false);
			SetConVarInt(FindConVar("ammo_assaultrifle_max"), RammoN[3], false, false);
			SetConVarInt(FindConVar("ammo_huntingrifle_max"), RammoN[4], false, false);
			SetConVarInt(FindConVar("ammo_sniperrifle_max"), RammoN[5], false, false);
			SetConVarInt(FindConVar("ammo_grenadelauncher_max"), RammoN[6], false, false);
			SetConVarInt(FindConVar("ammo_m60_max"), RammoN[7], false, false);
			PrintToChatAll("\x04[!提示!]\x03 已开启自定备弹");
		}
		default:
		{
		}
	}
	new Handle:hRM60CFG = LoadGameConfigFile("r_m60");
	new Address:RRM60Addr;
	if (hRM60CFG)
	{
		RRM60Addr = GameConfGetAddress(hRM60CFG, "M60RELOAD");
		if (RRM60Addr)
		{
			if (LoadFromAddress(RRM60Addr, NumberType:0) == 131 && LoadFromAddress(RRM60Addr + 9, NumberType:0) == 106 && LoadFromAddress(RRM60Addr + 11, NumberType:0) == 106 && LoadFromAddress(RRM60Addr + 13, NumberType:0) == 86 && LoadFromAddress(RRM60Addr + 15, NumberType:0) == 207)
			{
				if (GetConVarInt(FindConVar("ammo_m60_max")))
				{
					StoreToAddress(RRM60Addr + 7, 235, NumberType:0);
				}
				StoreToAddress(RRM60Addr + 7, 117, NumberType:0);
			}
		}
	}
	return Action:0;
}
