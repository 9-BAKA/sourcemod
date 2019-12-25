#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ZOMBIECLASS_TANK 8

Handle g_TankMeleeControlEnable;

Handle g_TankMeleeControlType;
Handle g_TankMeleeControlPercent;
Handle g_TankMeleeControlValue;
Handle g_TankMeleeControlHint;

Handle g_TankBurnControlType;
Handle g_TankBurnControlTime;
Handle g_TankBurnControlValue;
Handle g_TankFireControlValue;
// Handle g_TankBurnControlHint;

bool sm_TankMeleeControlEnable;

int sm_TankMeleeControlType;
int sm_TankMeleeControlPercent;
int sm_TankMeleeControlValue;
int sm_TankMeleeControlHint;

int sm_TankBurnControlType;
float sm_TankBurnControlTime;
int sm_TankBurnControlValue;
int sm_TankFireControlValue;
// int sm_TankBurnControlHint;

bool lateLoad;

public Plugin myinfo =  
{
	name = "求生之路Tank近战点燃伤害控制",
	author = "BAKA",
	description = "控制近战与点燃对tank所造成的伤害", 
	version = "1.1",
	url = "baka.cirno.cn"
}

public OnPluginStart()
{
	g_TankMeleeControlEnable = CreateConVar("sm_tank_melee_control_enable", "1", "启用、关闭坦克近战伤害控制功能", 0, true, 0.0, true, 1.0);
	
	g_TankMeleeControlType = CreateConVar("sm_tank_melee_control_type", "1", "坦克近战伤害控制功能类型，0为百分比，1为固定伤害", 0, true, 0.0, true, 1.0);
	g_TankMeleeControlPercent = CreateConVar("sm_tank_melee_control_percent", "2", "坦克近战伤害控制百分比量", 0, true, 0.0, true, 1.0);
	g_TankMeleeControlValue = CreateConVar("sm_tank_melee_control_Value", "100", "坦克近战伤害控制固定伤害量", 0, true, 0.0);
	g_TankMeleeControlHint = CreateConVar("sm_tank_melee_control_Hint", "1", "坦克近战伤害控制是否提示，0不提示，1提示框提示，2对话框提示", 0, true, 0.0, true, 2.0);

	g_TankBurnControlType = CreateConVar("sm_tank_burn_control_type", "0", "坦克点燃伤害控制功能类型，0为时间，1为固定伤害", 0, true, 0.0, true, 1.0);
	g_TankBurnControlTime = CreateConVar("sm_tank_burn_control_Time", "100.0", "坦克点燃存活时间", 0, true, 0.0);
	g_TankBurnControlValue = CreateConVar("sm_tank_burn_control_Value", "80", "坦克点燃固定每秒伤害", 0, true, 0.0);
	g_TankFireControlValue = CreateConVar("sm_tank_fire_control_Value", "80", "坦克燃烧瓶固定每秒伤害", 0, true, 0.0);
	// g_TankBurnControlHint = CreateConVar("sm_tank_burn_control_Hint", "2", "坦克点燃伤害控制是否提示，0不提示，1提示框提示，2对话框提示", 0, true, 0.0, true, 2.0);

	sm_TankMeleeControlEnable = GetConVarBool(g_TankMeleeControlEnable);
	sm_TankMeleeControlType = GetConVarInt(g_TankMeleeControlType);
	sm_TankMeleeControlPercent = GetConVarInt(g_TankMeleeControlPercent);
	sm_TankMeleeControlValue = GetConVarInt(g_TankMeleeControlValue);
	sm_TankMeleeControlHint = GetConVarInt(g_TankMeleeControlHint);

	sm_TankBurnControlType = GetConVarInt(g_TankBurnControlType);
	sm_TankBurnControlTime = GetConVarFloat(g_TankBurnControlTime);
	sm_TankBurnControlValue = GetConVarInt(g_TankBurnControlValue);
	sm_TankFireControlValue = GetConVarInt(g_TankFireControlValue);
	// sm_TankBurnControlHint = GetConVarInt(g_TankBurnControlHint);

	HookConVarChange(g_TankMeleeControlEnable, ConVarChanged);
	HookConVarChange(g_TankMeleeControlType, ConVarChanged);
	HookConVarChange(g_TankMeleeControlPercent, ConVarChanged);
	HookConVarChange(g_TankMeleeControlValue, ConVarChanged);
	HookConVarChange(g_TankMeleeControlHint, ConVarChanged);
	HookConVarChange(g_TankBurnControlType, ConVarChanged);
	HookConVarChange(g_TankBurnControlTime, ConVarChanged);
	HookConVarChange(g_TankBurnControlValue, ConVarChanged);
	HookConVarChange(g_TankFireControlValue, ConVarChanged);
	// HookConVarChange(g_TankBurnControlHint, ConVarChanged);

	HookEvent("player_hurt", TankOnFire);

	if (lateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}

	AutoExecConfig(true, "l4d2_tank_melee_burn_control", "sourcemod");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateLoad = late;
	return APLRes_Success;
}

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	sm_TankMeleeControlEnable = GetConVarBool(g_TankMeleeControlEnable);
	sm_TankMeleeControlType = GetConVarInt(g_TankMeleeControlType);
	sm_TankMeleeControlPercent = GetConVarInt(g_TankMeleeControlPercent);
	sm_TankMeleeControlValue = GetConVarInt(g_TankMeleeControlValue);
	sm_TankMeleeControlHint = GetConVarInt(g_TankMeleeControlHint);

	sm_TankBurnControlType = GetConVarInt(g_TankMeleeControlType);
	sm_TankBurnControlTime = GetConVarFloat(g_TankBurnControlTime);
	sm_TankBurnControlValue = GetConVarInt(g_TankBurnControlValue);
	sm_TankFireControlValue = GetConVarInt(g_TankFireControlValue);
	// sm_TankBurnControlHint = GetConVarInt(g_TankBurnControlHint);
}

public OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// PrintToChatAll("伤害 火伤：%d", damage);
	// PrintToChatAll("伤害 火伤：%.1f", damage);
	if (!sm_TankMeleeControlEnable)
	{
		return Plugin_Continue;
	}
	if (!IsClientInGame(victim) || GetClientTeam(victim) != 3)
	{
		return Plugin_Continue;
	}
	if (GetEntProp(victim, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
	{
		return Plugin_Continue;
	}
	if (damage == 0.0)
	{
		return Plugin_Continue;
	}
	// PrintToChatAll("伤害：%.1f", damage);
	char name[64];
	GetEdictClassname(inflictor, name, 64);
	if (!(strcmp(name, "weapon_melee", true)))
	{
	   ChangeDamageMelee(damage, victim, attacker);
	}
	return Plugin_Changed;
}

void ChangeDamageMelee(float &damage, int victim, int attacker)
{
	int max_health = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
	// PrintToChatAll("总血量：%d", max_health);
	if (sm_TankMeleeControlType == 0)
	{
		damage = float(max_health * sm_TankMeleeControlPercent / 100);
		if (sm_TankMeleeControlHint == 1)
			PrintHintText(attacker, "[近战伤害控制]对tank造成了总血量%d\%的伤害", sm_TankMeleeControlPercent);
		if (sm_TankMeleeControlHint == 2)
			PrintToChat(attacker, "\x04[近战伤害控制]\x01对tank造成了总血量\x05%d\%\x01的伤害", sm_TankMeleeControlPercent);
	}
	if (sm_TankMeleeControlType == 1)
	{
		damage = float(sm_TankMeleeControlValue);
		// PrintToChatAll("伤害：%.1f", damage);
		if (sm_TankMeleeControlHint == 1)
			PrintHintText(attacker, "[近战伤害控制]对tank造成了%d点伤害", sm_TankMeleeControlValue);
		if (sm_TankMeleeControlHint == 2)
			PrintToChat(attacker, "\x04[近战伤害控制]\x01对tank造成了\x05%dx01点伤害", sm_TankMeleeControlPercent);
	}
}

public TankOnFire(Handle event, char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!sm_TankMeleeControlEnable)
	{
		return 0;
	}
	if (!IsClientInGame(victim) || GetClientTeam(victim) != 3)
	{
		return 0;
	}
	if (GetEntProp(victim, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
	{
		return 0;
	}
	char weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	// inferno为火瓶伤害，entityflame为点燃伤害
	if (strcmp(weapon, "entityflame", true) == 0)
	{
		int CurHealth = GetClientHealth(victim);
		int DmgDone = GetEventInt(event, "dmg_health");
		int max_health = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		// 可在这里修改坦克受到的伤害
		int BurnDamage;
		if (sm_TankBurnControlType == 0)
		{
			BurnDamage = RoundToCeil(float(max_health) / sm_TankBurnControlTime / 10.0);
		}
		if (sm_TankBurnControlType == 1)
		{
			BurnDamage = sm_TankBurnControlValue;
		}
		// PrintToChatAll("点燃伤害：%d", BurnDamage);
		int newHealth = CurHealth + DmgDone - BurnDamage;
		if (newHealth < 0) newHealth = 0;
		SetEntityHealth(victim, newHealth);
	}
	if (strcmp(weapon, "inferno", true) == 0)
	{
		int CurHealth = GetClientHealth(victim);
		int DmgDone = GetEventInt(event, "dmg_health");
		int max_health = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		// 可在这里修改坦克受到的伤害
		int FireDamage = sm_TankFireControlValue / 10;
		int newHealth = CurHealth + DmgDone - FireDamage;
		if (newHealth < 0) newHealth = 0;
		SetEntityHealth(victim, newHealth);
	}
	return 0;
}
