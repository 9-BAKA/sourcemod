/************************************************************************
*	其他功能
************************************************************************/
//伤害显示
public DisplayDamage(const Damage, const DeadType, const attacker)
{
	for(new i = DamageDisplayBuffer-1; i >= 1; i--)
	{
		strcopy(DamageDisplayString[attacker][i], DamageDisplayLength, DamageDisplayString[attacker][i-1]);
	}
	switch (DeadType)
	{
		case ALIVE: Format(DamageDisplayString[attacker][0], DamageDisplayLength, MSG_DAMAGEDISPLAY, Damage);
		case NORMALDEAD: Format(DamageDisplayString[attacker][0], DamageDisplayLength, MSG_DAMAGEDISPLAY_DEAD, Damage);
		case HEADSHOT: Format(DamageDisplayString[attacker][0], DamageDisplayLength, MSG_DAMAGEDISPLAY_HEADSHOT, Damage);
	}
	PrintCenterText(attacker, "%s\n%s\n%s\n%s\n%s", DamageDisplayString[attacker][4], DamageDisplayString[attacker][3], DamageDisplayString[attacker][2], DamageDisplayString[attacker][1], DamageDisplayString[attacker][0]);
	if(DamageDisplayCleanTimer[attacker] != INVALID_HANDLE)	KillTimer(DamageDisplayCleanTimer[attacker]);
	DamageDisplayCleanTimer[attacker] = CreateTimer(2.5, DamageDisplayCleanTimerFunction, attacker);
}

public Action:DamageDisplayCleanTimerFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	DamageDisplayCleanTimer[Client] = INVALID_HANDLE;
	if(IsValidPlayer(Client))
	{
		if(!IsFakeClient(Client))
		{
			for(new j = 0; j < DamageDisplayBuffer; j++)
			{
				strcopy(DamageDisplayString[Client][j], DamageDisplayLength, "");
			}
		}
	}
}

public Action:ZombiesKillCountFunction(Handle:timer, any:attacker)
{
	KillTimer(timer);
	ZombiesKillCountTimer[attacker] = INVALID_HANDLE;
	if (IsValidPlayer(attacker))
	{
		if(Renwu[attacker] == 1)
        {
            if(Jenwu[attacker] == 1)
            {
                Pugan[attacker] += ZombiesKillCount[attacker];
            }
            if(Jenwu[attacker] == 3)
            {
                Pugan[attacker] += ZombiesKillCount[attacker];
            }			
            if(Jenwu[attacker] == 4)
            {
                Pugan[attacker] += ZombiesKillCount[attacker];
            }			
        }
		if (ZombiesKillCount[attacker] > 0) //GetConVarInt = 获取cfg里的设置
		{
			EXP[attacker] += GetConVarInt(ZombieKilledExp)*ZombiesKillCount[attacker] + VIPAdd(attacker, GetConVarInt(ZombieKilledExp)*ZombiesKillCount[attacker], 1, true);
			Cash[attacker] += GetConVarInt(ZombieKilledCash)*ZombiesKillCount[attacker] + VIPAdd(attacker, GetConVarInt(ZombieKilledCash)*ZombiesKillCount[attacker], 1, false);
			CPrintToChat(attacker, MSG_EXP_KILL_ZOMBIES, ZombiesKillCount[attacker], GetConVarInt(ZombieKilledExp)*ZombiesKillCount[attacker], GetConVarInt(ZombieKilledCash)*ZombiesKillCount[attacker]);
		}
		ZombiesKillCount[attacker]=0;
	}
}


//旁观超时踢出
public Action:Timer_KickLookOnPlayer(Handle:timer, any:Client)
{
	new kicktime;
	if (VIP[Client] >= 1)
		kicktime = 99999;
	else
		kicktime = 999;
		
	if (IsValidPlayer(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == 1)
	{
		if (IsAdminPlayer(Client))
			KillTimer(timer);
			
		KickLookOnPlayer[Client]++;
		if (KickLookOnPlayer[Client] >= kicktime)
		{
			KickClient(Client, "由于你旁观过久,已经被服务器踢出.");
			CPrintToChatAll("\x05[系统]\x03由于\x05%N\x03旁观时间超过\x055分钟\x03,已被服务器踢出![会员可增加99999秒旁观时间]", Client);
			KickLookOnPlayer[Client] = 0;
			KillTimer(timer);
		}
		else
		{
			if (VIP[Client] >= 1)
				PrintHintText(Client, "你正在旁观, %d 秒后会被踢出,输入指令!rpg,再按8-6 即可加入游戏!", kicktime - KickLookOnPlayer[Client]);
			else
				PrintHintText(Client, "你正在旁观, %d (VIP:99999)秒后会被踢出,输入指令!rpg,再按8-6 即可加入游戏!", kicktime - KickLookOnPlayer[Client]);
		}
	}
	else
		KickLookOnPlayer[Client] = 0, KillTimer(timer);
}

//取暴击伤害
public GetCritsDmg(Client, Dmg)
{
	new Float:Random = GetRandomFloat(0.0 , 100.0);
	if (Random <= CritsEffect[Client])
	{
		new Float:RandomDmg = GetRandomFloat(CritMinEffect[Client], CritMaxEffect[Client]);
		new CritDmg = RoundToNearest(Dmg * RandomDmg * 2);
		if (CritDmg > 0)
			return CritDmg;
	}
	else
		return 0;
		
	return 0;
}

//取团队当前人数
stock CountPlayersTeam(team, bool:allowfake = false)
{
	new Count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if (!allowfake)
			{
				if (!IsFakeClient(i))
					Count++;
			}
			else
				Count++;
		}
	}
	return Count;
}

//检查服务器当前人数
public GetAllPlayerCount()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	
	return count;
}

//检查服务器最大人数
public maxclToolzDowntownCheck()
{
	new Handle:invalid = INVALID_HANDLE;
	new Handle:downtownrun = FindConVar("l4d_maxplayers");
	new Handle:toolzrun = FindConVar("sv_maxplayers");
	new connectmaxnum;
	
	//游戏默认人数在运作
	if (downtownrun != invalid)
	{
		//Is Downtown used for slot patching? if yes use it for Max Players
		new downtown = GetConVarInt(FindConVar("l4d_maxplayers")); //GetConVarInt = 获取cfg里的设置
		if (downtown >= 1)
		{
			connectmaxnum = GetConVarInt(FindConVar("l4d_maxplayers"));
		}
	}

	//L4DToolz人数控制在运作
	if (toolzrun != invalid)
	{
		//Is L4DToolz used for slot patching? if yes use it for Max Players
		new toolz = GetConVarInt(FindConVar("sv_maxplayers")); //GetConVarInt = 获取cfg里的设置
		if (toolz >= 1)
		{
			connectmaxnum = GetConVarInt(FindConVar("sv_maxplayers"));
		}
	}

	//No Downtown or L4DToolz running using fallback (possible x/32)
	if (downtownrun == invalid && toolzrun == invalid)
	{
		connectmaxnum = MaxClients;
	}
	return connectmaxnum;
}

public bool:WeaponIsGun(String:weapon[])
{
	if (StrEqual(weapon, "pistol", false))
		return true;
	if (StrEqual(weapon, "pistol_magnum", false))
		return true;
	if (StrEqual(weapon, "smg_silenced", false))
		return true;
	if (StrEqual(weapon, "smg", false))
		return true;
	if (StrEqual(weapon, "pumpshotgun", false))
		return true;
	if (StrEqual(weapon, "shotgun_chrome", false))
		return true;
	if (StrEqual(weapon, "autoshotgun", false))
		return true;
	if (StrEqual(weapon, "shotgun_spas", false))
		return true;
	if (StrEqual(weapon, "hunting_rifle", false))
		return true;
	if (StrEqual(weapon, "sniper_military", false))
		return true;
	if (StrEqual(weapon, "rifle", false))
		return true;
	if (StrEqual(weapon, "rifle_ak47", false))
		return true;	
	if (StrEqual(weapon, "rifle_desert", false))
		return true;
	if (StrEqual(weapon, "grenade_launcher", false))
		return true;
	if (StrEqual(weapon, "rifle_m60", false))
		return true;
	if (StrEqual(weapon, "rifle_sg552", false))
		return true;
	if (StrEqual(weapon, "smg_mp5", false))
		return true;
	if (StrEqual(weapon, "sniper_awp", false))
		return true;
	if (StrEqual(weapon, "sniper_scout", false))
		return true;
		
	return false;
}

/* 判断玩家是否有效 */
stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	
	return true;
}

/* 是否管理员 */
public bool:IsAdminPlayer(Client)
{
	new AdminId:admin = GetUserAdmin(Client);
	if(admin != INVALID_ADMIN_ID)
		return true;
	else
		return false;
}

/* 检查队伍是否已满 */
stock bool:IsTeamFull(team)
{
	// Spectator's team is never full :P
	if (team == 1)
		return false;
	
	new SurvivorMaxPlayer = GetConVarInt(cv_survivor_limit); //GetConVarInt = 获取cfg里的设置
	new InfectedMaxPlayer = GetConVarInt(cv_infected_limit);
	new max;
	new count;
	new i;
	
	// we count the players in the survivor's team
	if (team == 2)
	{
		max = SurvivorMaxPlayer;
		count = 0;
		for (i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==2)
				count++;
		}
	else if (team == 3) // we count the players in the infected's team
	{
		max = InfectedMaxPlayer;
		count = 0;
		for (i=1; i<=MaxClients; i++)
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==3)
				count++;
		}
	
	// If full ...
	if (count >= max)	return true;
	else	return false;
}



stock bool:IsPlayerOnFire(Client)
{
	if (GetEntProp(Client, Prop_Data, "m_fFlags") & FL_ONFIRE)
		return true;
	return false;
}
stock bool:IsPlayerOnGround(Client)
{
	if (GetEntDataEnt2(Client, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")) != -1)
		return true;
	return false;
}

stock bool:IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock bool:IsPlayerGhost(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost", 1) == 1)
		return true;
	return false;
}

stock bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated") == 1)
		return true;
	else
		return false;
}

/* Execute Cheat Commads */
stock CheatCommand(Client, const String:command[], const String:arguments[])
{
    if (!Client) return;
    new admindata = GetUserFlagBits(Client);
    SetUserFlagBits(Client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(Client, admindata);
}

/* 获取所观察的玩家信息 */
public Action:GetObserverTargetInfo(Client)
{
	if(!IsValidEntity(Client) || !IsClientInGame(Client))
		return Plugin_Handled;
		
	new mode	= GetEntPropEnt(Client, Prop_Send, "m_iObserverMode"),
		target	= GetEntPropEnt(Client, Prop_Send, "m_hObserverTarget");
	
	if (!IsValidPlayer(target, false))
		return Plugin_Handled;
	
	//mode -1未定义 0自己 1刚死亡时 2未知 3未知 4第一视角 5第三视角 6自由视角
	if((mode!=4 && mode!=5) || target==-1)
		return Plugin_Handled;
	
	new String:playerjod[16], String:s_vip[16];
	new health = GetEntProp(target, Prop_Data, "m_iHealth");
	if (JD[target] == 1)
		Format(playerjod, sizeof(playerjod), "精灵");
	else if (JD[target] == 2)
		Format(playerjod, sizeof(playerjod), "士兵");
	else if (JD[target] == 3)
		Format(playerjod, sizeof(playerjod), "生物专家");
	else if (JD[target] == 4)
		Format(playerjod, sizeof(playerjod), "心灵医生");
	else if (JD[target] == 5)
		Format(playerjod, sizeof(playerjod), "法师");
	else if (JD[target] == 6)
		Format(playerjod, sizeof(playerjod), "弹药专家");
	else if (JD[target] == 7)
		Format(playerjod, sizeof(playerjod), "雷神");
	else
		Format(playerjod, sizeof(playerjod), "未转职");
		
	if (VIP[target] == 1)
		Format(s_vip, sizeof(s_vip), "★白金会员★");
	else if (VIP[target] == 2)
		Format(s_vip, sizeof(s_vip), "★黄金会员★");
	else if (VIP[target] == 3)
		Format(s_vip, sizeof(s_vip), "★水晶会员★");
	else if (VIP[target] == 4)
		Format(s_vip, sizeof(s_vip), "★至尊会员★");
	else if (VIP[target] <= 0)
		Format(s_vip, sizeof(s_vip), "★普通玩家★");
	PrintHintText(Client, "观看: %s 职业:%s \nID:%N 等级:%d[%d转]  \n血量值:%d 魔法值:%d  \n════════  \n本服官方Q群:141758560 ", s_vip, playerjod, target, Lv[target], NewLifeCount[target], health, MP[target]);
	return Plugin_Handled;
}

/* 读取任意一个玩家 */
public GetAnyClient()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
	}
	return -1;
}

/* 读取準心位置 */
public GetTracePosition(client, Float:TracePos[3])
{
	decl Float:clientPos[3], Float:clientAng[3];

	GetClientEyePosition(client, clientPos);
	GetClientEyeAngles(client, clientAng);
	new Handle:trace = TR_TraceRayFilterEx(clientPos, clientAng, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(TracePos, trace);

	CloseHandle(trace);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}

/* 推开效果 */
public PointPush(client, Float:center[3], force, radius, Float:duration)
{
	new push = CreateEntityByName("point_push");
	DispatchKeyValueFloat(push, "magnitude", float(force));
	DispatchKeyValueFloat(push, "radius", float(radius));
	DispatchKeyValueFloat(push, "inner_radius", float(force*2));
	DispatchKeyValue(push, "spawnflags", "24");
	DispatchSpawn(push);
	TeleportEntity(push, center, NULL_VECTOR, NULL_VECTOR);
	if(IsValidPlayer(client))
		AcceptEntityInput(push, "Enable", client, client);
	else 	
		AcceptEntityInput(push, "Enable", -1, -1);
	CreateTimer(duration, DeletePushForce, push);
	
	new exPhys = CreateEntityByName("env_physexplosion");
	DispatchKeyValueFloat(exPhys, "radius", float(radius));
	DispatchKeyValueFloat(exPhys, "inner_radius", float(force));
	DispatchKeyValueFloat(exPhys, "magnitude", force*0.5);
	DispatchKeyValue(exPhys, "spawnflags", "19");
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, center, NULL_VECTOR, NULL_VECTOR);
	if(IsValidPlayer(client))
		AcceptEntityInput(exPhys, "Explode", client, client);
	else 	
		AcceptEntityInput(exPhys, "Explode", -1, -1);
}
public Action:DeletePushForce(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Kill");
			RemoveEdict(ent);
		}
	}
}

/* 名字信息设置 */
stock String:NameInfo(Client, mode)
{
	decl String:NameInfoString[192];
	if(StrEqual(Password[Client], "", true))
	{
		if(mode == colored)
		{
			if(IsClientInGame(Client))
			{
				if(GetClientTeam(Client) == 2)	Format(NameInfoString, sizeof(NameInfoString), "{green}[未注册]{blue}%N{default}", Client);
				else if(GetClientTeam(Client) == 3)	Format(NameInfoString, sizeof(NameInfoString), "{green}[未注册]{red}%N{default}", Client);
				else	Format(NameInfoString, sizeof(NameInfoString), "{green}[未注册]{default}%N", Client);
			}
		}
		else if(mode == simple) Format(NameInfoString, sizeof(NameInfoString), "[未注册]%N", Client);
	} else if(!IsPasswordConfirm[Client])
	{
		if(mode == colored)
		{
			if(IsClientInGame(Client))
			{
				if(GetClientTeam(Client) == 2)	Format(NameInfoString, sizeof(NameInfoString), "{green}[未登录]{blue}%N{default}", Client);
				else if(GetClientTeam(Client) == 3)	Format(NameInfoString, sizeof(NameInfoString), "{green}[未登录]{red}%N{default}", Client);
				else	Format(NameInfoString, sizeof(NameInfoString), "{green}[未登录]{default}%N", Client);
			}
		}
		else if(mode == simple) Format(NameInfoString, sizeof(NameInfoString), "[未登录]%N", Client);
	} else
	{
		decl String:job[32];
		if(JD[Client] == 0)			Format(job, sizeof(job), "未转职");
		else if(JD[Client] == 1)	Format(job, sizeof(job), "精灵");
		else if(JD[Client] == 2)	Format(job, sizeof(job), "士兵");
		else if(JD[Client] == 3)	Format(job, sizeof(job), "生物专家");
		else if(JD[Client] == 4)	Format(job, sizeof(job), "心灵医生");
		else if(JD[Client] == 5)	Format(job, sizeof(job), "法师");
		else if(JD[Client] == 6)	Format(job, sizeof(job), "弹药专家");
		else if(JD[Client] == 7)	Format(job, sizeof(job), "雷神");
		if(mode == colored)
		{
			if(IsClientInGame(Client))
			{
				if(GetClientTeam(Client) == 2)
				{
					if (VIP[Client] == 1)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[白金VIP1]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 2)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[黄金VIP2]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 3)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[水晶VIP3]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 4)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[至尊VIP4]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else
						Format(NameInfoString, sizeof(NameInfoString), "{green}[%d转][Lv.%d %s]{blue}%N{default}", NewLifeCount[Client], Lv[Client], job, Client);
				}
				else if(GetClientTeam(Client) == 3)	
				{
					if (VIP[Client] == 1)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[白金VIP1]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 2)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[黄金VIP2]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 3)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[水晶VIP3]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 4)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[至尊VIP4]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else
						Format(NameInfoString, sizeof(NameInfoString), "{green}[%d转][Lv.%d %s]{red}%N{default}", NewLifeCount[Client], Lv[Client], job, Client);
				}
				else	
				{
					if (VIP[Client] == 1)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[白金VIP1]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 2)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[黄金VIP2]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 3)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[水晶VIP3]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else if (VIP[Client] == 4)
						Format(NameInfoString, sizeof(NameInfoString), "\x04[%d转][Lv.%d %s]\x03[至尊VIP4]\x04%N\x03", NewLifeCount[Client], Lv[Client], job, Client);
					else
						Format(NameInfoString, sizeof(NameInfoString), "{green}[%d转][Lv.%d %s]{default}%N{default}", NewLifeCount[Client], Lv[Client], job, Client);
				}
			}
		}
		else if(mode == simple) 
		{
			if (VIP[Client] == 1)
				Format(NameInfoString, sizeof(NameInfoString), "[%d转][Lv.%d %s][白金VIP1]%N", NewLifeCount[Client], Lv[Client], job, Client);
			else if (VIP[Client] == 2)
				Format(NameInfoString, sizeof(NameInfoString), "[%d转][Lv.%d %s][黄金VIP2]%N", NewLifeCount[Client], Lv[Client], job, Client);
			else if (VIP[Client] == 3)
				Format(NameInfoString, sizeof(NameInfoString), "[%d转][Lv.%d %s][水晶VIP3]%N", NewLifeCount[Client], Lv[Client], job, Client);
			else if (VIP[Client] == 4)
				Format(NameInfoString, sizeof(NameInfoString), "[%d转][Lv.%d %s][至尊VIP4]%N", NewLifeCount[Client], Lv[Client], job, Client);
			else
				Format(NameInfoString, sizeof(NameInfoString), "[%d转][Lv.%d %s]%N", NewLifeCount[Client], Lv[Client], job, Client);
		}
	}
	return NameInfoString;
}

/* 医生电击器防刷检测 */
public bool:DoctorDefibrillatorCheck(Client)
{
	if(!IsValidPlayer(Client) || IsFakeClient(Client))
		return false;
		
	new String:name[MAX_NAME_LENGTH];
	GetClientName(Client, name, sizeof(name));
	
	for(new i = 1; i <= MaxClients; i++)
	{	
		if (StrEqual(DoctorName[i], name))
			return false;
	}
	
	return true;	
}

/* 医生电击器重置 */
public ResetDoctor(Client)
{
	if (DoctorDefibrillatorCheck(Client))
	{
		if (JD[Client] == 4)
		{
			if (Lv[Client] < 50)
				defibrillator[Client] = 2;
			else
				defibrillator[Client] = 3;
			GetClientName(Client, DoctorName[Client], sizeof(DoctorName));
		}
	}
}


/******************************************************
*	Gimmick functions
*******************************************************/

public LittleFlower(Float:pos[3], type, activator)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			/* fire */
			DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		else
			/* explode */
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 0, 0, 0, 0);
		if(IsClientInGame(activator))
		{
			if(IsFakeClient(activator))	AcceptEntityInput(entity, "break", activator, activator);
			else
			{
				new Handle:pack;
				CreateDataTimer(0.1,Break,pack);
				WritePackCell(pack, entity);
				WritePackCell(pack, activator);
			}
		} else 	AcceptEntityInput(entity, "break", -1, -1);
	}
}

public Action:Break(Handle:timer, Handle:pack)
{
	new victim;
	new attacker;

	/* Set to the beginning and unpack it */
	ResetPack(pack);
	victim = ReadPackCell(pack);
	attacker = ReadPackCell(pack);
	DealDamage(attacker,victim,100,2);
}

public Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	if (!IsValidPlayer(client) || !IsValidPlayer(target))
		return;
		
	/* Blow off target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);

	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);

	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;

	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	if(IsClientInGame(target)){
		new Handle:msg = StartMessageOne("Fade", target);
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		if (type == 0)
			BfWriteShort(msg, (0x0002 | 0x0008));
		else
			BfWriteShort(msg, (0x0001 | 0x0010));
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
}

public ScreenShake(target, Float:intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);

	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public TriggerPanicEvent()
{
	new flager = GetAnyClient();
	if(flager == -1)  return;
	new flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

/******************************************************
*	粒子特效控制功能
*******************************************************/
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public AttachParticle(ent, String:particleType[], Float:time)
{
	decl String:tName[64];
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle) && IsValidEdict(ent))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName); 
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
    if (IsValidEntity(particle) && IsValidEdict(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

/******************************************************
*	视觉效果Functions
*******************************************************/
public CreateLaserEffect(client, Float:targetpos[3], colRed, colGre, colBlu, alpha, Float:width, Float:duration, mode)
{
	decl color[4];
	color[0] = colRed;
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;

	if(mode == LASERMODE_NORMAL)
	{
		/* Show laser between user and impact position */
		decl Float:myPos[3];

		GetClientEyePosition(client, myPos);
		TE_SetupBeamPoints(myPos, targetpos, g_BeamSprite, 0, 0, 0, duration, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	else if(mode == LASERMODE_VARTICAL)
	{
		/* Show laser like lightning bolt */
		decl Float:lchPos[3];

		for(new i = 0; i < 3; i++)
			lchPos[i] = targetpos[i];
		lchPos[2] += 1000;
		TE_SetupBeamPoints(lchPos, targetpos, g_BeamSprite, 0, 0, 0, duration, width, width, 1, 2.0, color, 0);
		TE_SendToAll();
		TE_SetupGlowSprite(lchPos, g_GlowSprite, 1.5, 2.8, 230);
		TE_SendToAll();
	}
}
/******************************************************
*	制造伤害Functions
*******************************************************/
//制造伤害
stock DealDamage(attacker=0,victim,damage,dmg_type=0,String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchSpawn(PointHurt);
			if(IsValidPlayer(attacker))
				AcceptEntityInput(PointHurt, "Hurt", attacker);
			else 	
				AcceptEntityInput(PointHurt, "Hurt", -1);
				
			RemoveEdict(PointHurt);
		}
	}
}

//制造重复伤害
stock DealDamageRepeat(attacker=0,victim,damage,dmg_type=0,String:weapon[]="", Float:DamageDelay = 0.1, Float:Duration = 1.0)
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchKeyValueFloat(PointHurt,"DamageDelay",DamageDelay);
			DispatchSpawn(PointHurt);
			if(IsClientInGame(attacker))
			{
				AcceptEntityInput(PointHurt, "TurnOn", attacker);
			} else 	AcceptEntityInput(PointHurt, "TurnOn", -1);
			CreateTimer(Duration, RemoveDealDamageRepeat, PointHurt);
		}
	}
}
public Action:RemoveDealDamageRepeat(Handle:timer, any:PointHurt)
{
	KillTimer(timer);

	if (IsValidEdict(PointHurt))
	{
		RemoveEdict(PointHurt);
	}
	return Plugin_Handled;
}
/******************************************************
*	其他Functions
*******************************************************/

/* 转换队伍 */
public ChangeTeam(client, targetteam)
{
	if (!IsValidPlayer(client) || IsFakeClient(client) || targetteam == 0)
	{
		return;
	}
	
	// If teams are the same ...
	if (GetClientTeam(client) == targetteam)
	{
		return;
	}
	
	// We check if target team is full...
	if (IsTeamFull(targetteam))
	{
		return;
	}
	
	// If player was on infected .... 
	if (GetClientTeam(client) == 3)
	{
		// ... and he wasn't a tank ...
		new iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (iClass != CLASS_TANK)
			ForcePlayerSuicide(client);	// we kill him
	}
	
	// If target is survivors .... we need to do a little trick ....
	if (targetteam == 2)
	{
		// first we switch to spectators ..
		ChangeClientTeam(client, 1); 
		new bot;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				bot = i;
				break;
			}
		}
		
		if (IsValidPlayer(bot) && IsFakeClient(bot) && GetClientTeam(bot) == 2)
		{
			// force player to spec humans
			SDKCall(fSHS, bot, client); 
			
			// force player to take over bot
			SDKCall(fTOB, client, true); 		
		}
		else
			CreateTimer(0.1, GiveBotClient, client, TIMER_REPEAT);

	}
	else // We change it's team ...
	{
		ChangeClientTeam(client, targetteam);
	}
}

/* 获取准心玩家信息 */
public Action:Timer_GetAimTargetMSG(Handle:timer, any:Client)
{	
	if (IsValidPlayer(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == 2 && IsPlayerAlive(Client))
	{
		new target = GetClientAimTarget(Client, true);
		if (IsValidPlayer(target) && !IsFakeClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target))
		{
			new String:playerjod[16], String:s_vip[16];
			new health = GetEntProp(target, Prop_Data, "m_iHealth");
			if (JD[target] == 1)
				Format(playerjod, sizeof(playerjod), "精灵");
			else if (JD[target] == 2)
				Format(playerjod, sizeof(playerjod), "士兵");
			else if (JD[target] == 3)
				Format(playerjod, sizeof(playerjod), "生物专家");
			else if (JD[target] == 4)
				Format(playerjod, sizeof(playerjod), "心灵医生");
			else if (JD[target] == 5)
				Format(playerjod, sizeof(playerjod), "法师");
			else if (JD[target] == 6)
				Format(playerjod, sizeof(playerjod), "弹药专家");
			else if (JD[target] == 7)
				Format(playerjod, sizeof(playerjod), "雷神");
			else
				Format(playerjod, sizeof(playerjod), "未转职");
			
			if (VIP[target] == 1)
				Format(s_vip, sizeof(s_vip), "★白金会员★");
			else if (VIP[target] == 2)
				Format(s_vip, sizeof(s_vip), "★黄金会员★");
			else if (VIP[target] == 3)
				Format(s_vip, sizeof(s_vip), "★水晶会员★");
			else if (VIP[target] == 4)
				Format(s_vip, sizeof(s_vip), "★至尊会员★");
			else if (VIP[target] <= 0)
				Format(s_vip, sizeof(s_vip), "★普通玩家★");
				
			PrintHintText(Client, "玩家: %s 职业:%s \nID:%N 等级:%d[%d转]  \n血量值:%d 魔法值:%d ", s_vip, playerjod, target, Lv[target], NewLifeCount[target], health, MP[target]);
		}
	}
}


/* 检测玩家是否输入密码,超时后T出 */
public Action:IsPWConfirm(Handle:timer, any:client)
{
	if (GetConVarInt(cv_pwtimeout) == 0) //GetConVarInt = 获取cfg里的设置
		return Plugin_Stop;
	if (client < 1 || client > MaxClients)
		return Plugin_Stop;
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;
	if (!IsPasswordConfirm[client])
	{
		pwtimeout[client] += 1;
		if (pwtimeout[client] >= GetConVarInt(cv_pwtimeout)) //GetConVarInt = 获取cfg里的设置
		{
			KickClient(client, "由于你长时间没有输入密码,所以你被服务器踢出了");
			CPrintToChatAll("\x03玩家: {olive}%N \x03由于长时间没有输入密码,已经被服务器踢出了", client);
			pwtimeout[client] = 0;
			return Plugin_Stop;
		}
		PrintHintText(client, "你没有注册,服务器将在 %d 后将你踢出 \n注册方法;按y，输入/pw 123[pw后面有个空格,要输入/符号]即可注册！", GetConVarInt(cv_pwtimeout) - pwtimeout[client]);
		return Plugin_Continue;
	}
	else
	{
		PrintHintText(client, "登录成功!请记住你的密码和你的游戏名称,它们是互相绑定的!");
		return Plugin_Stop;
	}
}

/* 加载卡住检测 */
public Action:Kick_Connect(Handle:timer, any:client)
{
	if (client < 1 || client > MaxClients)
		return Plugin_Stop;
	if (!IsClientConnected(client) || IsFakeClient(client))
		return Plugin_Stop;
		
	if (IsClientInGame(client))
	{
		connectkicktime[client] = 0;
		return Plugin_Stop;
	}
	
	connectkicktime[client] += 1;
	if (connectkicktime[client] >= GetConVarInt(cv_loadtimeout)) //GetConVarInt = 获取cfg里的设置
	{
		connectkicktime[client] = 0;
		KickClient(client, "由于你卡在加载地图%d秒,所以被服务器踢出", GetConVarInt(cv_loadtimeout)); //GetConVarInt = 获取cfg里的设置
		CPrintToChatAll("玩家: \x03%N \x03由于加载地图超过%d秒,为防止卡人数,所以被服务器踢出!请重新进入!", client, GetConVarInt(cv_loadtimeout));
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/* 是否闰年 */
stock bool:IsLeapYear(int)
{
	if ((int % 4 == 0) && (int % 100 != 0) || (int % 400 == 0))
		return true;
	
	return false;
}

//获取今天日数
stock GetToday()
{
	new String:text[32];
	FormatTime(text, sizeof(text), "%j");
	new time = StringToInt(text);
	return time;
}

//获取今年最大日数
stock GetThisYearMaxDay(SelectYear = 0)
{
	new String:text[32];
	new year;
	new maxday;
	
	if (SelectYear == 0)
	{
		FormatTime(text, sizeof(text), "%Y");
		year = StringToInt(text);
	}
	else
		year = SelectYear;
	
	if (IsLeapYear(year))
		maxday = 366;
	else
		maxday = 365;
		
	return maxday;
}

//获取今年年份
stock GetThisYear()
{
	new String:text[32];
	FormatTime(text, sizeof(text), "%Y");
	new year = StringToInt(text);
	return year;
}

/* 显示开火火光 */
stock ShowMuzzleFlash(client, Float:pos[3],  Float:angle[3], index)
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "weapon_muzzle_flash_pistol"); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	
}

/* 显示子弹轨迹 */
stock ShowTrack(client, Float:pos[3], Float:endpos[3] )
{  
 	decl String:temp[16]="";		
	new target = CreateEntityByName("info_particle_target");
	Format(temp, 64, "cptarget%d", target);
	DispatchKeyValue(target, "targetname", temp);	
	TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR); 
	ActivateEntity(target); 
	
	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER);
	DispatchKeyValue(particle, "cpoint1", temp);
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticletargets, target, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
}

/* 产生随机特感 */
public SpawnRandomInfected(Client, Float:pos[3])
{
	if (IsValidPlayer(Client))
	{
		new limit = GetRandomInt(3, 8);
		new type;
		new String:Name[6][32] = { "smoker","boomer","hunter","spitter","jockey","charger" };
		new String:text[64];		
		for (new i; i < limit; i++)
		{
			type = GetRandomInt(0, 5);
			Format(text, sizeof(text), "%s %.f %.f %.f", Name[type], pos[0], pos[1], pos[2]);
			CheatCommand(Client, "z_spawn", text);
		}
	}
}

/* 设置武器射速换弹速度 */
stock SetWeaponAttackSpeed(weaponid, Float:speed = 1.0, bool:LoadClip = false, bool:FireSpeed = false)
{
	if(IsValidEdict(weaponid))
	{
		decl String:entclass[64];
		GetEdictClassname(weaponid, entclass, sizeof(entclass));
		if(StrContains(entclass, "weapon") >= 0 && !StrEqual(entclass, "weapon_grenade_launcher"))
		{
			new Float:ETime = GetGameTime(); 
			new Float:time = (GetEntPropFloat(weaponid, Prop_Send, "m_flNextPrimaryAttack") - ETime) / speed;
			if (FireSpeed)
			{
				SetEntPropFloat(weaponid, Prop_Send, "m_flNextPrimaryAttack", time + ETime);
				time = (GetEntPropFloat(weaponid, Prop_Send, "m_flNextSecondaryAttack") - ETime) / speed;
				SetEntPropFloat(weaponid, Prop_Send, "m_flNextSecondaryAttack", time + ETime);
			}
			if (LoadClip)
			{
				SetEntPropFloat(weaponid, Prop_Send, "m_flPlaybackRate", speed);
				CreateTimer(time, ResetWeaponAttackSpeed, weaponid);
			}
		}
	}
}

public Action:ResetWeaponAttackSpeed(Handle:timer, any:ent)
{
	if(IsValidEdict(ent))
	{
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if(StrContains(entclass, "weapon") >= 0)
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 1.0);
	}
	
	KillTimer(timer);
}

/* 名称获取玩家ID */
stock GetClientForName(String:name[], bool:fuzzy = false)
{
	new String:temp[32], Client;

	if (!fuzzy)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, false))
			{
				GetClientName(i, temp, sizeof(temp));
				if (StrEqual(name, temp))
				{
					Client = i;
					break;
				}
			}
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, false))
			{
				GetClientName(i, temp, sizeof(temp));
				if (StrContains(name, temp) >= 0)
				{
					Client = i;
					break;
				}
			}
		}	
	}
	
	return Client;
}

stock ChangeGameTimeSpeed(Float:speed = 0.2, Float:Duration = 5.0)
{
	decl i_Ent, Handle:h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValueFloat(i_Ent, "desiredTimescale", speed);
	DispatchKeyValueFloat(i_Ent, "acceleration", 2.0);
	DispatchKeyValueFloat(i_Ent, "minBlendRate", 1.0);
	DispatchKeyValueFloat(i_Ent, "blendDeltaMultiplier", 2.0);
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	Duration = Duration * speed;
	CreateTimer(Duration, ResetGameTimeSpeed, h_pack);
}

public Action:ResetGameTimeSpeed(Handle:Timer, Handle:h_pack)
{
	decl i_Ent;
	ResetPack(h_pack);
	i_Ent = ReadPackCell(h_pack);
	if(IsValidEntity(i_Ent) && IsValidEdict(i_Ent))
		AcceptEntityInput(i_Ent, "Stop");
}	

/* 实体轮廓设置 */
stock PerformGlow(Client, Type, Range = 0, Red = 0, Green = 0, Blue = 0)
{
	decl Color;
	Color = Red + Green * 256 + Blue * 65536;
	SetEntProp(Client, Prop_Send, "m_iGlowType", Type);
	SetEntProp(Client, Prop_Send, "m_nGlowRange", Range);
	SetEntProp(Client, Prop_Send, "m_glowColorOverride", Color);
}

/* 改变自身角色模型 */
public ChangeMyModel(Client, ModelID)
{
	/*
	Cohch 0
	Nick 1
	Elie 2
	黑妹 3
	*/
	decl String:ModelName[128];
	if (ModelID == 0)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_coach.mdl");
	else if (ModelID == 1)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_gambler.mdl");
	else if (ModelID == 2)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_mechanic.mdl");
	else if (ModelID == 3)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_producer.mdl");
	else if (ModelID == 4)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_biker.mdl");
	else if (ModelID == 5)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_manager.mdl");
	else if (ModelID == 6)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_namvet.mdl");
	else if (ModelID == 7)
		Format(ModelName, sizeof(ModelName), "models/survivors/survivor_teenangst.mdl");
		
	if (IsValidPlayer(Client))
		SetEntityModel(Client, ModelName);
}

/* 附加实体 */
stock AttachEntity(Owner, Entity, String:positon[]= "medkit", Float:pos[3] = NULL_VECTOR,Float:ang[3] = NULL_VECTOR)
{
	decl String:tname[32];
	Format(tname, sizeof(tname), "target%d", Owner);
	DispatchKeyValue(Owner, "targetname", tname); 		
	DispatchKeyValue(Entity, "parentname", tname);
	SetVariantString(tname);
	AcceptEntityInput(Entity, "SetParent",Entity, Entity, 0); 	
	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(Entity, "SetParentAttachment");
	}
	TeleportEntity(Entity, pos, ang, NULL_VECTOR);
}

/* 创建克隆镜像 */
stock CreateClone(Client, iAnim, Float:Clone_Time = 5.0)
{
	decl Float:vAngles[3], Float:vOrigin[3], String:ModelName[64], Handle:pack, Clone;
	GetClientAbsOrigin(Client,vOrigin);
	GetClientEyeAngles(Client, vAngles);
	GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName)); 
	
	if(iAnim > 0)
	{
		Clone = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(Clone, ModelName);  	 
		TeleportEntity(Clone,  vOrigin, vAngles, NULL_VECTOR); 	
		SetEntProp(Clone, Prop_Send, "m_nSequence", iAnim);
		SetEntPropFloat(Clone, Prop_Send, "m_flPlaybackRate", 1.0); 	
		SetEntPropFloat(Clone, Prop_Send, "m_fadeMinDist", 10000.0); 
		SetEntPropFloat(Clone, Prop_Send, "m_fadeMaxDist", 20000.0); 
		
		if (IsValidPlayer(Client) && IsValidEntity(Client))
		{
			GotoThirdPerson(Client);
			SDKUnhook(Client, SDKHook_SetTransmit, OnSetTransmitClient);
			SDKHook(Client, SDKHook_SetTransmit, OnSetTransmitClient);
			HideEntity(Client, true)
			SetEntityMoveType(Client, MOVETYPE_NONE); 
			pack = CreateDataPack();
			CreateDataTimer(Clone_Time, Timer_KillClone, pack);
			WritePackCell(pack, Client);
			WritePackCell(pack, Clone);
		}
	}
	
	return Clone;
}

public Action:Timer_KillClone(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Clone = ReadPackCell(pack);
	if (IsValidPlayer(Client) && IsValidEntity(Client))
	{
		GotoFirstPerson(Client);	
		SetEntityMoveType(Client, MOVETYPE_WALK); 	
		HideEntity(Client, false);
	}
	
	if (IsValidEntity(Clone))
		AcceptEntityInput(Clone, "kill");
		
	KillTimer(timer);
}

public Action:OnSetTransmitClient(Climber, Client)
{
	
	if(Climber != Client)
	{
		if (GetClientTeam(Climber) == 2)
			return Plugin_Handled; 
		if (GetClientTeam(Climber) == 3 && GetClientTeam(Client) == 2)
			return Plugin_Handled; 
			
		return Plugin_Handled;
	}
	else 
		return Plugin_Continue;
}

//隐藏显示玩家
stock HideEntity(Entity, bool:Hide = false)
{
	
	if(!Hide) //显示
	{
		SetEntityRenderMode(Entity, RENDER_NORMAL);
		SetEntityRenderColor(Entity, 255, 255, 255, 255);
		if (IsValidPlayer(Entity) && PlayerGlowType[Entity] > -1)
			 SetEntProp(Entity, Prop_Send, "m_iGlowType", PlayerGlowType[Entity]);
	}
	else //隐藏
	{
		SetEntityRenderMode(Entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Entity, 0, 0, 0, 0);
		if (IsValidPlayer(Entity))
			PlayerGlowType[Entity] = GetEntProp(Entity, Prop_Send, "m_iGlowType");
		SetEntProp(Entity, Prop_Send, "m_iGlowType", 0);
	}
}

//转到第三人称
stock GotoThirdPerson(Client)
{
	SetEntPropEnt(Client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(Client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(Client, Prop_Send, "m_bDrawViewmodel", 0);
}

//转到第一人称
stock GotoFirstPerson(Client)
{
	SetEntPropEnt(Client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(Client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(Client, Prop_Send, "m_bDrawViewmodel", 1);
}

/* 公告信息 */
stock Menu_GameAnnouncement(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "欢迎来到午夜狂欢");		
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "不会注册点此[改名+注册]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "新人任务");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "会员购买[联系撸主]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "点此领取之前活动奖品");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "老玩家回归礼包");
	DrawPanelItem(menu, line);
	
	//Format(line, sizeof(line), "活动[春节/只能做一次]]");
	//DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "永久装备");
	DrawPanelItem(menu, line);
	
	//Format(line, sizeof(line), "领取开局基础装备");
	//DrawPanelItem(menu, line);

	Format(line, sizeof(line), "每日签到[赠送经验/金钱/礼包]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "升级礼包[辅助新人升级]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "RPG菜单[按y键输入/rpg呼出]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "关闭菜单");
	DrawPanelItem(menu, line);
	SendPanelToClient(menu, Client, MenuHandler_GameAnnouncement, MENU_TIME_FOREVER);
}

public MenuHandler_GameAnnouncement(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
	//		case 1: MenuFunc_lq(Client);  //免费领取会员
			case 1: MenuFunc_zc(Client);//不会注册点此
			case 2: MenuFunc_MZC(Client);  //新人任务
			case 3: Menu_VIPFS(Client);  //会员购买
			case 4: HDZTWANSA(Client);  //活动奖品领取
			case 5: MenuFunc_huigui(Client);  //老玩家回归礼包
			//case 3: MenuFunc_HD(Client);  //活动
			case 6: MenuFunc_VIPSC(Client); //购买永久装备
			//case5: Menu_JCZB(Client);  //领取基础装备
			case 7: MenuFunc_Qiandao(Client);
			case 8: MenuFunc_Shenbao(Client);    //升级礼包
			case 9: MenuFunc_RPG(Client);
		}
	}
}

public HDZTWANSA(Client)
{   
    if(HDZT[Client] <= 1 && GetClientTeam(Client) == 2 && IsPasswordConfirm[Client] && NewLifeCount[Client] >= 50)
    {
        PlayerZBItemSize[Client] += 3;//扩充装备栏
	Qcash[Client] += 500;
        ServerCommand("sm_setvip_845 \"%N\" \"2\" \"7\"", Client);
        Cash[Client] += 300000;
        PlayerItem[Client][ITEM_ZB][20] += 7; 
        PlayerItem[Client][ITEM_ZB][30] += 7; 
        TSDJ1[Client] += 3;
        PlayerItem[Client][ITEM_ZB][8] += 7;  		
	HDZT[Client] += 1; //记录活动
        PrintHintText(Client, "你补领了1000点卷+黄金会员[7天]+30W金钱+巨人腰带[7天]+饮血剑[7天]+圣石×3+狂徒铠甲套装[7天]!");
        CPrintToChatAll("\x03【提醒】】玩家%N补领了:1000点卷+黄金会员+圣石×3+狂徒铠甲套装等装备!", Client);
    } else PrintHintText(Client, "你已补领或没资格领取!"); 
}  

/* 免费领取会员 
public Action:MenuFunc_lq(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "免费领取15天白金会员!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认领取");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_lq, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_lq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: lqq(Client);
			case 2: Menu_GameAnnouncement(Client);
		}
	}
}
public lqq(Client)
{
    if(VIP[Client] <= 0)
    {
        ServerCommand("sm_setvip_515 \"%N\" \"1\" \"15\"", Client); 
        CPrintToChat(Client, "\x03【提示】你成功领取了白金VIP15天!");	
        CPrintToChatAll("\x03【系统】恭喜玩家%N成为白金会员", Client);
    } else CPrintToChat(Client, "\x03【提示】你已经是会员，不能领取!");
}
*/
public Action:Menu_JCZB(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "领取开局装备");
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "领取M60+大日本军刀+低调牌药包");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "领取M16+大日本军刀+低调牌药包");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "领取AK47+大日本军刀+低调牌药包");
	DrawPanelItem(menu,line);

	Format(line, sizeof(line), "领取榴弹发射器+大日本军刀+低调牌药包");
	DrawPanelItem(menu,line);
	
	Format(line, sizeof(line), "关闭");
	DrawPanelItem(menu, line);
	
	SendPanelToClient(menu, Client, MenuHandler_JCZB, MENU_TIME_FOREVER);
}
public MenuHandler_JCZB(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select && KJZB[Client] <= 0) {
		switch (param)
		{
			case 1:
			{
				KJZB[Client]++;
				CheatCommand(Client, "give", "rifle_m60");
				CheatCommand(Client, "give", "katana");
				CheatCommand(Client, "give", "first_aid_kit");
				CPrintToChatAll("\x05【系统】玩家%N领取了开局补给基础装备:M60+大日本军刀+低调牌药包", Client);
				CPrintToChat(Client, "\x02【提示】你领取了开局补给装备!");
			}
			case 2:
			{
				KJZB[Client]++;
				CheatCommand(Client, "give", "rifle");
				CheatCommand(Client, "give", "katana");
				CheatCommand(Client, "give", "first_aid_kit");
				CPrintToChatAll("\x05【系统】玩家%N领取了开局补给基础装备:M16+大日本军刀+低调牌药包", Client);
				CPrintToChat(Client, "\x02【提示】你领取了开局补给装备!");				
			}
			case 3:
			{
				KJZB[Client]++;
				CheatCommand(Client, "give", "rifle_ak47");
				CheatCommand(Client, "give", "katana");
				CheatCommand(Client, "give", "first_aid_kit");
				CPrintToChatAll("\x05【系统】玩家%N领取了开局补给基础装备:AK47+大日本军刀+低调牌药包", Client);
				CPrintToChat(Client, "\x02【提示】你领取了开局补给装备!");					
			}
			case 4:
			{
				KJZB[Client]++;
				CheatCommand(Client, "give", "weapon_grenade_launcher");
				CheatCommand(Client, "give", "katana");
				CheatCommand(Client, "give", "first_aid_kit");
				CPrintToChatAll("\x05【系统】玩家%N领取了开局补给基础装备:榴弹发射器+大日本军刀+低调牌药包", Client);
				CPrintToChat(Client, "\x02【提示】你领取了开局补给装备!");						
			}
		}
	}else{
		CPrintToChat(Client, "\x03【提示】你已经领取过了,无法继续领取!");		
	}
}
/*
//新人福利
public Action:MenuFunc_xrfl(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "════════════════════════════");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "玩家在游戏注册帐号[游戏窗口化]");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "把游戏名字和QQ群一起截图上报至论坛或发给op");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "════════════════════════════");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_jczb, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_jczb(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //领取基础装备[公告信息]
		}
	}
}
*/
//注册教程
public Action:MenuFunc_zc(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "游戏改名教程[第一步]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "密码注册教程[第二步]");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_zccd, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_zccd(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_yxgm(Client); //游戏改名
			case 2: MenuFunc_yxzc(Client); //游戏注册
		}
	}
}

public Action:MenuFunc_yxgm(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[256];

	Format(line, sizeof(line), "游戏改名字的方法:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "找到求生之路2的游戏目录");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "然后在游戏目录里找到 rev.ini(没有ini 也是一样的)");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "然后打开这个文件 看到 PlayerName=“[L4D2vs]我还没改名字” 之后");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "把 [L4D2vs]我还没改名字 删掉 在这个地方 改成自己想要的名字)");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "(注意 引号不要去掉了）然后 点右上角的 × 在点确定 然后登录游戏 就完成改名了");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_yxgmfh, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_yxgmfh(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //领取基础装备[公告信息]
		}
	}
}

public Action:MenuFunc_yxzc(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[256];

	Format(line, sizeof(line), "游戏 RPG注册方法:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在游戏内按Y出现聊天框 ，然后输入 /pw 123[pw后面有个空格,要输入/符号] 然后按回车发送出去 ，即可完成注册！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "（每一关都需要输入），想自动输入可以在群里下载免输入密码文件，或者是用登陆器登录，里面也有教程！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "实在不会注册,可以去群里问，会有人解答。");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_yxzcfh, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_yxzcfh(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //领取基础装备[公告信息]
		}
	}
}

public Action:Menu_VIPFS(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[256];

	Format(line, sizeof(line), "白金VIP1:拥有3次补给，1倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "钻石VIP2:拥有6次补给，2倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "水晶VIP3:拥有9次补给，3倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "至尊VIP4:拥有15次补给，4倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "如有需要请联系撸主：我要会员");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_FS, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_FS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //返回公告
		}
	}
}
public MenuHandler_JC(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //返回公告
		}
	}
}
public MenuHandler_ZC(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: Menu_GameAnnouncement(Client); //返回公告
		}
	}
}

public MenuHandler_VIPFS(Handle:menu, MenuAction:action, Client, param)
{
}
public MenuHandler_GMJC(Handle:menu, MenuAction:action, Client, param)
{
}
public MenuHandler_ZCJC(Handle:menu, MenuAction:action, Client, param)
{
}

/* 十进制转十六进制 */
stock String:IntToHex(Int)
{
	new i1, i2, String:hex[256], String:line[128];
	i1 = int;
	if (i1 == 0)
	{
		Format(hex, sizeof(hex), "0");
		return hex;
	}
		
	while (i1 > 0)
	{
		i2 = i1 % 16;
		i1 = i1 \ 16;
		if (i2 == 10)
			line[0] = 'A';
		else if (i2 == 11)
			line[0] = 'B';
		else if (i2 == 12)
			line[0] = 'C';
		else if (i2 == 13)
			line[0] = 'D';
		else if (i2 == 14)
			line[0] = 'E';
		else if (i2 == 15)
			line[0] = 'F';
		else
			IntToString(i2, line, sizeof(line));
			
		Format(hex, sizeof(hex), "%s%s", line, hex);
	}
	
	return hex;
}

/* 创建实体 */
stock CreateEntity(Client, const String:name[], const String:model[], Float:location[3]) 
{
	new entity = CreateEntityByName(name);
	if (StrEqual(model, "PROVIDED") == false)
		SetEntityModel(entity, model);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	TeleportEntity(entity, location, NULL_VECTOR, NULL_VECTOR);
}


/* 玩家名字*/
public bool:CheckPlayerNameMatch(Client)
{
	decl String:s_Name[MAX_NAME_LENGTH], bool:true_name;
	true_name = false;
	GetClientName(Client, s_Name, sizeof(s_Name));
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false))
		{
			if (StrEqual(s_Name, PlayerName[i]))
			{
				true_name = true;
				break;
			}
		}
	}
	
	return true_name;
}

/* 玩家在同一回合内是否二次进入 */
public bool:IsFirstConnect(Client)
{
	if(!IsValidPlayer(Client))
		return false;
	new String:name[MAX_NAME_LENGTH];
	GetClientName(Client, name, sizeof(name));
	for(new i = 1; i <= MaxClients; i++)
	{	
		if (StrEqual(BotCheck[i], name))
			return false;		
	}
	return true;
}

/* 随机掉落道具 */
public RandomDropItemOnPostion(Client)
{
	decl String:DropName[64], DropSlot, DropItem;
	DropSlot = GetRandomInt(0, 3);
	if (DropSlot == 0)
	{
		DropItem = GetRandomInt(0, 15);
		strcopy(DropName, sizeof(DropName), t_Gun[DropItem]);
	}
	else if (DropSlot == 2)
	{
		DropItem = GetRandomInt(0, 2);
		strcopy(DropName, sizeof(DropName), t_Bomb[DropItem]);	
	}
	else if (DropSlot == 3)
	{
		DropItem = GetRandomInt(0, 3);
		strcopy(DropName, sizeof(DropName), t_Medic[DropItem]);	
	}
		
	DropItemOnPostion(Client, DropName, DropSlot, true);
}

/* 掉落道具 */
public DropItemOnPostion(Client, String:weapon[], slot, bool:glow)
{
	new ammo;
	new clip;
	new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	//LogToFileEx(LogPath, "[道具掉落]Slot:%d Name:%s", slot, weapon);
	if (slot == 0)
	{
		clip = 7;
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			ammo = GetRandomInt(30, 160);
			SetEntData(Client, ammoOffset+(12), 0);
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			ammo = GetRandomInt(30, 160);
			SetEntData(Client, ammoOffset+(20), 0);
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			ammo = GetRandomInt(15, 50);
			SetEntData(Client, ammoOffset+(28), 0);
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			ammo = GetRandomInt(20, 60);
			SetEntData(Client, ammoOffset+(32), 0);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			ammo = GetRandomInt(30, 90);
			SetEntData(Client, ammoOffset+(36), 0);
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			ammo = GetRandomInt(30, 90);
			SetEntData(Client, ammoOffset+(40), 0);
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			ammo = GetRandomInt(10, 30);
			SetEntData(Client, ammoOffset+(68), 0);
		}
		else return;
	}	
	
	new index = CreateEntityByName(weapon);
	new Float:origin[3];
	new Float:ang[3];
	GetClientEyePosition(Client, origin);
	GetClientEyeAngles(Client, ang);
	GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(ang, ang);
	ScaleVector(ang, 150.0);	
	DispatchSpawn(index);
	TeleportEntity(index, origin, NULL_VECTOR, ang);		
	ActivateEntity(index); 		
	if (glow)
		PerformGlow(index, 3, 0, 240, 240, 240);

	if (slot == 0)
	{
		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}

/* 给予玩家基本装备 */
public GivePlayerBaseWeapon(Client)
{
	if (IsValidPlayer(Client, false, false) && GetClientTeam(Client) == 2)
	{
		GetClientName(Client, BotCheck[Client], sizeof(BotCheck[]));
		new slot0 = GetPlayerWeaponSlot(Client, 0);
		new slot3 = GetPlayerWeaponSlot(Client, 3);
		new slot4 = GetPlayerWeaponSlot(Client, 4);
		new slot5 = GetPlayerWeaponSlot(Client, 5);		
		if (!IsValidEntity(slot0))
			CheatCommand(Client, "give", "rifle");
		if (!IsValidEntity(slot3))
			CheatCommand(Client, "give", "first_aid_kit");
		if (!IsValidEntity(slot4))
			CheatCommand(Client, "give", "adrenaline");
		if (!IsValidEntity(slot5))
			CheatCommand(Client, "give", "katana");			
			
		decl String:text[3][128];
		Format(text[0], sizeof(text[]), "你已领取了基础装备套装.");
		Format(text[1], sizeof(text[]), "套装物品:[M16 + 医疗包 + 肾上腺素 + 武士刀]");
		Format(text[2], sizeof(text[]), "(如果身上已有相同部位的道具将不会替换)");
		MenuFunc_MenuMessage(Client, "提示信息:", text, 3);
	}
}

/* 给予玩家基本装备_计时器 */
public Action:Timer_GivePlayerBW(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client, false, false) && GetClientTeam(Client) == 2)
	{
		if (CheckPlayerBW(Client))
		{
			GivePlayerBaseWeapon(Client);
			CPrintToChatAll("\x03[领取基础装备]\x05玩家{olive}%N\x05领取了本回合的基础装备(M16+医疗包+肾上腺素+武士刀)!", Client);
		}
		
		KillTimer(timer);
	}
}

/* 给予玩家基本装备_检测 */
public bool:CheckPlayerBW(Client)
{
	decl String:temp[32];
	GetClientName(Client, temp, sizeof(temp));
	for (new i = 1; i <= MaxClients; i++)
	{
		if (StrEqual(temp, BotCheck[i]))
			return false;
	}
	
	return true;
}


/* 服务器运行时间计算 */
public Action:Timer_ServerRuningTime(Handle:timer)
{
	ServerRuningTime[RUNTIME_SEC] += 1;
	if (ServerRuningTime[RUNTIME_SEC] >= 60)
	{
		decl String:map[64];
		ServerRuningTime[RUNTIME_SEC] = 0;
		ServerRuningTime[RUNTIME_MIN] += 1;
		GetCurrentMap(map, sizeof(map));
		LogToFileEx(ServerTimePath, "---=================================================================---");
		LogToFileEx(ServerTimePath, "--- 当前地图: %s 服务器已运行时间: %d分%d秒 ---", map, ServerRuningTime[RUNTIME_MIN], ServerRuningTime[RUNTIME_SEC]);
		LogToFileEx(ServerTimePath, "---=================================================================---");
	}
}

/* 取当前连接中的玩家数 */
public GetConnectingPlayerNum(bool:allowbot)
{
	new num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i))
		{
			if (!allowbot)
			{
				if (!IsFakeClient(i))
					num++;
			}
			else
				num++;
		}
	}
	
	return num;
}

/* 取一随机几率事件 */
public bool:GetRandomEvent(Float:radio)
{
	new Float:a = GetRandomFloat(0.0, 100.0);
	if (a <= radio)
		return true;
	return false;
}

/* 万用菜单提示 */
public MenuFunc_MenuMessage(Client, String:title[], String:text[][], LineNum)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, title);
	
	DrawPanelText(menu, " \n");
	DrawPanelText(menu, "════════════════");
	for (new i; i < LineNum; i++)
		DrawPanelText(menu, text[i]);	
	DrawPanelText(menu, "════════════════");	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "我知道了");
	
	SendPanelToClient(menu, Client, MenuHandler_MenuMessage, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_MenuMessage(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (param == 1)
			MenuFunc_PasswordInfo(Client);
	}
}


Handle:AttachParticle1(ent, String:particleType[], Float:time=10.0)
{
	if (ent < 1)
	{
		return INVALID_HANDLE;
	}

	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		decl String:tName[32];
		new Float:pos[3];

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 60;

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		if (DispatchSpawn(particle))
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			SetVariantString("OnUser1 !self,Start,,0.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			SetVariantString("OnUser2 !self,Stop,,4.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			ActivateEntity(particle);
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");

			new Handle:pack;
			new Handle:hTimer;
			hTimer = CreateDataTimer(time, DeleteParticle, pack);
			WritePackCell(pack, particle); 
			WritePackString(pack, particleType);
			WritePackCell(pack, ent); 

			new Handle:packLoop;
			hTimerLoopEffect[ent] = CreateDataTimer(4.2, LoopParticleEffect, packLoop, TIMER_REPEAT);
			WritePackCell(packLoop, particle); 
			WritePackCell(packLoop, ent);

			return hTimer;
		} 
		else 
		{
			if (IsValidEdict(particle))
			{
				RemoveEdict(particle);
			}
			return INVALID_HANDLE;
		}
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, Handle:pack)
{
	decl String:particleType[32];

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	ReadPackString(pack, particleType, sizeof(particleType));
	new client = ReadPackCell(pack); 

	if (hTimerLoopEffect[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerLoopEffect[client]);
		hTimerLoopEffect[client] = INVALID_HANDLE;
	}

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}

	if (StrEqual(particleType, "achieved", true))
	{
		hTimerAchieved[client] = INVALID_HANDLE;
	} 
	else if (StrEqual(particleType, "mini_fireworks", true)) 
	{
		hTimerMiniFireworks[client] = INVALID_HANDLE;
	}
}

public Action:LoopParticleEffect(Handle:timer, Handle:pack)
{

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new client = ReadPackCell(pack);

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");
			return Plugin_Continue;
		}
	}
	hTimerLoopEffect[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
