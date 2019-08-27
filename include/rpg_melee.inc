/************************************************************************
*	近战耐久度
************************************************************************/
#define Melee_Ammo		999

new MeleeID[4096];

public ResetMeleeLasting()
{
	new max_entities = GetMaxEntities();
	for (new i = MaxClients + 1; i < max_entities; i++)
		MeleeID[i] = 0;
}

public Action:Melee_Event_WeaponFire(Handle:event, const String:ename[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidPlayer(Client, false, false) || GetClientTeam(Client) != 2 || IsPlayerIncapped(Client))
		return Plugin_Continue;
	
	decl i_Weapon, String:s_Weapon[32]
	i_Weapon = GetEntDataEnt2(Client, S_rActiveW)
	
	if (IsValidEdict(i_Weapon))
	{
		GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon))
		if (StrContains(s_Weapon, "melee", false) >= 0)
		{
			if (MeleeID[i_Weapon] > 0)
			{
				MeleeID[i_Weapon] -= 1;
				PrintCenterText(Client,"近战耐久度: %d", MeleeID[i_Weapon]);
			}
			else if (MeleeID[i_Weapon] <= 0)
			{
				MeleeID[i_Weapon] = 0;
				RemoveEdict(i_Weapon);
				CheatCommand(Client, "give", "pistol");
				PrintHintText(Client,"你的近战武器已经损坏了!!");
			}
		}
	}
	
	return Plugin_Handled;
}


public Action:Melee_Event_ItemPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!IsValidPlayer(Client, true, false) || GetClientTeam(Client) != 2)
		return;
		
	decl g_Melee, String:stWpn[24], String:sweapon[32];
	GetEventString(event, "item", stWpn, sizeof(stWpn));	
	if (StrContains(stWpn, "melee", false) >= 0)
	{
		g_Melee = GetPlayerWeaponSlot(Client, 1);
		if (IsValidEdict(g_Melee))
		{
			GetEdictClassname(g_Melee, sweapon, 32);
			if (StrContains(sweapon, "melee", false) >= 0)
			{
				if (MeleeID[g_Melee] <= 0)
					MeleeID[g_Melee] = Melee_Ammo;
			}
		}
	}
}

public Action:OnWeaponEquip(Client, weapon)
{
	if (!IsValidPlayer(Client, false, false) || GetClientTeam(Client) != 2)
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if (StrContains(sWeapon, "melee", false) >= 0)
	{
		if (IsValidEdict(weapon))
		{
			if (MeleeID[weapon] <= 0)
				MeleeID[weapon] = Melee_Ammo;
		}
	}
	
	return Plugin_Continue;
}