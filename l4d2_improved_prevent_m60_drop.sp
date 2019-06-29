#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

iLastWeapon[MAXPLAYERS+1];

bool bM60[MAXPLAYERS+1] = {false, ...};
bool InReloadM60[MAXPLAYERS+1] = {false, ...};

Handle M60AmmoCVAR = INVALID_HANDLE;
Handle M60AmmoReserveCVAR = INVALID_HANDLE;
Handle M60ResupplyCVAR = INVALID_HANDLE;
Handle ReloadNotifyCVAR = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "[L4D2] Improved Prevent M60 Drop",
	author = "MasterMind420, Ludastar, DeathChaos25",
	description = "Prevents dropping the M60 when ammo runs out and allows reloading",
	version = "1.6",
	url = ""
};

public void OnPluginStart()
{
	char sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));

	if (!StrEqual(sGame, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");

	ReloadNotifyCVAR = CreateConVar("m60_reload_notify", "2", "0 = Disabled, 1 = Chat, 2 = Hint ", FCVAR_NOTIFY);
	M60AmmoCVAR = CreateConVar("m60_ammo", "150", " How much Ammo for the M60 ", FCVAR_NOTIFY);
	M60AmmoReserveCVAR = CreateConVar("m60_ammo_reserve", "300", " How much Ammo Reserve for the M60 ", FCVAR_NOTIFY);
	M60ResupplyCVAR = CreateConVar("m60_resupply", "1", " Do you allow players to resupply the M60 off ammospots ", FCVAR_NOTIFY);

	HookConVarChange(M60AmmoReserveCVAR, CVARChanged);

	HookEvent("player_use", ePlayerUse);
	HookEvent("weapon_fire", eWeaponFire);
	//HookEvent("item_pickup", eItemPickup);
	HookEvent("receive_upgrade", eAmmoUpgrade);
	HookEvent("upgrade_explosive_ammo", eAmmoUpgrade);
	HookEvent("upgrade_incendiary_ammo", eAmmoUpgrade);
	HookEvent("upgrade_pack_added", eSpecialAmmo);
	HookEvent("weapon_reload", eWeaponReloadPre, EventHookMode_Pre);

	//CreateTimer(0.1, M60AmmoCheck, _, TIMER_REPEAT);

	AutoExecConfig(true, "l4d2_improved_prevent_m60_drop");

	CvarsChanged();
}

public void OnMapStart()
{
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl"))
		PrecacheModel("models/w_models/weapons/w_m60.mdl");

	if (!IsModelPrecached("models/v_models/v_m60.mdl"))
		PrecacheModel("models/v_models/v_m60.mdl");

	CvarsChanged();
}

public void CVARChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    CvarsChanged();
}

void CvarsChanged()
{
	SetConVarInt(FindConVar("ammo_m60_max"), GetConVarInt(M60AmmoReserveCVAR));
}

public Action M60AmmoCheck(Handle Timer)
{
	int ReserveAmmo = GetConVarInt(FindConVar("ammo_m60_max"));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || !IsPlayerAlive(i))
			continue;

		int Weapon = GetPlayerWeaponSlot(i, 0);

		if (Weapon == -1)
			continue;

		if(iLastWeapon[i] != Weapon)
		{
			iLastWeapon[i] = Weapon;

			char sWeapon[17];
			GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

			if(sWeapon[13] != 'm' || !StrEqual(sWeapon, "weapon_rifle_m60"))
			{
				bM60[i] = false;
				continue;
			}

			bM60[i] = true;
		}

		if(!bM60[i])
			continue;

		int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
		int PrimType = GetEntProp(Weapon, Prop_Send, "m_iPrimaryAmmoType");
		int Ammo = GetEntProp(i, Prop_Send, "m_iAmmo", _, PrimType);

		if (Clip == 0 && Ammo > ReserveAmmo + 150)
			SetEntProp(i, Prop_Send, "m_iAmmo", ReserveAmmo + 150, _, PrimType);
		else if (Clip > 0 && Ammo > ReserveAmmo)
			SetEntProp(i, Prop_Send, "m_iAmmo", ReserveAmmo + (150 - Clip), _, PrimType);
	}
}

public void eItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (Weapon == -1)
		return;

	if(iLastWeapon[client] != Weapon)
	{
		iLastWeapon[client] = Weapon;

		char sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if(sWeapon[13] != 'm' || !StrEqual(sWeapon, "weapon_rifle_m60"))
		{
			bM60[client] = false;
			return;
		}

		bM60[client] = true;
	}

	if(!bM60[client])
		return;

	int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

	if (AmmoType == -1)
		return;

	SetEntProp(Weapon, Prop_Data, "m_iClip1", GetConVarInt(M60AmmoCVAR), 1);
	SetEntProp(client, Prop_Send, "m_iAmmo", GetConVarInt(M60AmmoReserveCVAR), _, AmmoType);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsSurvivor(client))
		return;

	static int slot;
	slot = GetPlayerWeaponSlot(client, 0);

	if (IsValidEntity(slot))
	{
		char sWeapon[17];
		GetEntityClassname(slot, sWeapon, sizeof(sWeapon));

		if(!StrEqual(sWeapon, "weapon_rifle_m60"))
			return;

		int Clip = GetEntProp(slot, Prop_Data, "m_iClip1");
		int PrimType = GetEntProp(slot, Prop_Send, "m_iPrimaryAmmoType");
		int Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
		int ReserveAmmo = GetConVarInt(FindConVar("ammo_m60_max"));

		if (Clip == 0 && Ammo > ReserveAmmo + 150)
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 150, _, PrimType);
		else if (Clip > 0 && Ammo > ReserveAmmo)
			SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + (150 - Clip), _, PrimType);
		else if (Ammo <= 0 && Clip <= 1)
			SetEntPropFloat(slot, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
	}
}
		
public void eWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (Weapon == -1)
		return;

	if(iLastWeapon[client] != Weapon)
	{
		iLastWeapon[client] = Weapon;

		char sWeapon[17];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if(sWeapon[13] != 'm' || !StrEqual(sWeapon, "weapon_rifle_m60"))
		{
			bM60[client] = false;
			return;
		}

		bM60[client] = true;
	}

	if(!bM60[client])
		return;

	int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
	int PrimType = GetEntProp(Weapon, Prop_Send, "m_iPrimaryAmmoType");
	int Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
	int Laser = GetEntProp(Weapon, Prop_Send, "m_upgradeBitVec");
	int InReload = GetEntProp(Weapon, Prop_Data, "m_bInReload");

	if (Clip == 1)
		InReloadM60[client] = true;

	if (InReload)
		return;

	if (Clip <= 1 && InReloadM60[client])
	{
		AcceptEntityInput(Weapon, "kill");
		int M60 = CreateEntityByName("weapon_rifle_m60");
		DispatchSpawn(M60);
		EquipPlayerWeapon(client, M60);
		SetEntProp(M60, Prop_Send, "m_iClip1", 0);
		SetEntProp(client, Prop_Send, "m_iAmmo", Ammo, _, PrimType);
		SetEntProp(M60, Prop_Send, "m_upgradeBitVec", Laser);
		InReloadM60[client] = false;
	}
}

public void eWeaponReloadPre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int Weapon = GetPlayerWeaponSlot(client, 0);

	if (Weapon == -1)
		return;

	if(iLastWeapon[client] != Weapon)
	{
		iLastWeapon[client] = Weapon;

		char sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if(sWeapon[13] != 'm' || !StrEqual(sWeapon, "weapon_rifle_m60"))
		{
			bM60[client] = false;
			return;
		}

		bM60[client] = true;
	}

	if(!bM60[client])
		return;

	SetEntProp(Weapon, Prop_Send, "m_releasedFireButton", 1);
	SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
}

public void eAmmoUpgrade(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int Weapon = GetPlayerWeaponSlot(client, 0);

	if (Weapon == -1)
		return;

	if(iLastWeapon[client] != Weapon)
	{
		iLastWeapon[client] = Weapon;

		char sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if(sWeapon[13] != 'm' || !StrEqual(sWeapon, "weapon_rifle_m60"))
		{
			bM60[client] = false;
			return;
		}

		bM60[client] = true;
	}

	if(!bM60[client])
		return;

	int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

	if (Clip != 0)
		return;

	SetEntProp(Weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", Clip, 1);
	SetEntProp(Weapon, Prop_Send, "m_iClip1", Clip);
}

public void ePlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(M60ResupplyCVAR) != 1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	int AmmoPile = event.GetInt("targetid");

	if (!IsValidEntity(AmmoPile))
		return;

	char sWeapon[32];
	GetEntityClassname(AmmoPile, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_ammo_spawn", false))
		return;

	int Weapon = GetPlayerWeaponSlot(client, 0);

	if (Weapon == -1)
		return;

	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_rifle_m60", false))
		return;

	int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

	if (AmmoType == -1)
		return;

	int Clip = GetEntProp(Weapon, Prop_Send, "m_iClip1");
	int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

	float cPos[3];
	float aPos[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);
	GetEntPropVector(AmmoPile, Prop_Data, "m_vecAbsOrigin", aPos);

	if (GetVectorDistance(cPos, aPos) <= 100)
	{
		//DONT RELOAD WHEN FULL
		if (Ammo >= GetConVarInt(M60AmmoReserveCVAR) && Clip == GetConVarInt(M60AmmoCVAR))
			return;
		else if (Ammo > GetConVarInt(M60AmmoReserveCVAR) && Clip <= GetConVarInt(M60AmmoCVAR))
			return;

		//SET CLIP & RESERVE TO 0 WHEN 1 AMMO LEFT IN CLIP
		if (Ammo < 1 && Clip == 1)
		{
			SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, AmmoType);
		}

		SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.1);
		SetEntProp(client, Prop_Send, "m_iAmmo", GetConVarInt(M60AmmoReserveCVAR) + GetConVarInt(M60AmmoCVAR), _, AmmoType);

		if (GetConVarInt(ReloadNotifyCVAR) == 1)
			PrintToChat(client, "\x04M60 RELOADED");
		else if (GetConVarInt(ReloadNotifyCVAR) == 2)
			PrintHintText(client, "M60 RELOADED");
	}
}

public void eSpecialAmmo(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!IsSurvivor(client))
		return;

	int Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (Weapon == -1)
		return;

	char sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "weapon_rifle_m60"))
		return;

	int UpgradeId = event.GetInt("upgradeid");
	GetEntityClassname(UpgradeId, sWeapon, sizeof(sWeapon));

	if (StrEqual(sWeapon, "upgrade_laser_sight"))
		return;

	int NewAmmo;
	int Ammo = GetSpecialAmmoInPlayerGun(client);

	if (StrEqual(sWeapon, "upgrade_ammo_incendiary"))
		NewAmmo = Ammo * 1;
	else if (StrEqual(sWeapon, "upgrade_ammo_explosive"))
		NewAmmo = Ammo * 1;

	if (NewAmmo > 1)
		SetSpecialAmmoInPlayerGun(client, NewAmmo);
	else
		return;
}

stock int GetSpecialAmmoInPlayerGun(int client)
{
	if (!client)
		client = 1;

	int Gun = GetPlayerWeaponSlot(client, 0);

	if (IsValidEntity(Gun))
		return GetEntProp(Gun, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else
		return 0;
}

stock int SetSpecialAmmoInPlayerGun(int client, int amount)
{
	if (!client)
		client = 1;

	int Gun = GetPlayerWeaponSlot(client, 0);

	if (IsValidEntity(Gun))
		SetEntProp(Gun, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}