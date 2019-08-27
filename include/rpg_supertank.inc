/************************************************************************
*	超级坦克功能
************************************************************************/

//设置坦克第一阶段||帝王坦克
public Action:SetFirtsTankHealth(Handle:timer, any:Client)
{	
	if(IsValidPlayer(Client) && IsValidEntity(Client))
	{
		TankTypeChange(Client);
		new Float:random = GetRandomFloat(0.0, 100.0);
		if (random <= GetConVarFloat(sm_supertank_bossratio))
		{
			tanktype[Client] = TANK5;
			new health = SuperTank_Health[TANK5];
			new Float:speed = GetConVarFloat(sm_supertank_speed[tanktype[Client]]);
			new String:color[32];
			GetConVarString(sm_supertank_color_boss, color, sizeof(color));
			SetEntProp(Client, Prop_Data, "m_iMaxHealth", health);	
			SetEntProp(Client, Prop_Data, "m_iHealth", health);
			SetEntPropFloat(Client, Prop_Send, "m_flLaggedMovementValue", speed);
			SetEntityRenderMode(Client, RenderMode:0);
			DispatchKeyValue(Client, "rendercolor", color);
			PerformGlow(Client, 3, 0, 255, 255, 255);  //轮毂桔红：255, 255, 255  默认  取消轮毂：0, 0, 0
			CPrintToChatAll("{red}帝王坦克出场:\x03%N \n{red}生命值:\x03%d {red}速度倍率:\x03%.1f", Client, health, speed);
			CPrintToChatAll("\x03帝王坦克技能:\n\x03拥有所有阶段的坦克技能并且血量速度都是最强大的!!!");		
			CreateTimer(1.0, SuperBossAbsTimer, Client, TIMER_REPEAT);				
		}
		else
		{
			if(TimerUpdate[Client] != INVALID_HANDLE)
			{
				KillTimer(TimerUpdate[Client]);
				TimerUpdate[Client] = INVALID_HANDLE;
			}
			
			tanktype[Client] = TANK1;
			TimerUpdate[Client] = CreateTimer(1.0, TankUpdate, Client, TIMER_REPEAT);	
			new health = SuperTank_Health[TANK1];
			new Float:speed = GetConVarFloat(sm_supertank_speed[tanktype[Client]]);	
			new String:color[32];
			GetConVarString(sm_supertank_color_first, color, sizeof(color));
			SetEntProp(Client, Prop_Data, "m_iMaxHealth", health);	
			SetEntProp(Client, Prop_Data, "m_iHealth", health);
			SetEntPropFloat(Client, Prop_Send, "m_flLaggedMovementValue", speed);
			SetEntityRenderMode(Client, RenderMode:0);  //创建轮廓颜色，RenderMode不变，后面的数字可改变
			DispatchKeyValue(Client, "rendercolor", color);
			PerformGlow(Client, 3, 0, 199, 97, 20);  //橙黄色轮毂：199, 97, 20  默认  取消轮毂：0, 0, 0
			CPrintToChatAll("{red}变身为第一阶段坦克:\x03%N \n{red}生命值:{olive}%d v速度倍率:{red}%.1f", Client, health, speed);
			CPrintToChatAll("\x03此阶段拥有技能:\n{red}彗星石头:投掷出的石头会产生爆炸对幸存者造成伤害!");
		}
		/* 瞬移技能 */
		if(Timer_FatalMirror[Client] != INVALID_HANDLE)
		{
			KillTimer(Timer_FatalMirror[Client]);
			Timer_FatalMirror[Client] = INVALID_HANDLE;
		}
		Timer_FatalMirror[Client] = CreateTimer(SuperTank_Warp, FatalMirror, Client, TIMER_REPEAT);	
		SetTankXiXingDaFa(Client);
	}
	
	KillTimer(timer);
}


/** 坦克技能子程序 **/

//技能_吸星大法_设置
public SetTankXiXingDaFa(Client)
{
	new Float:xixingtime = GetConVarFloat(sm_supertank_xixing_interval);
	if (xixingtime <= 0)  //设置施放间隔后，自动施放。然后跳转↓
		return;
	else
		CreateTimer(xixingtime, TankAdsTimer, Client);
}

//技能_吸星大法_开始倒计时             开始施放技能,显示圈圈↓
public Action:TankAdsTimer(Handle:timer, any:client)
{
	if (IsValidPlayer(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == CLASS_TANK && tanktype[client] > 0)
	{
		new Float:pos[3];
		new Float:range;
		if (tanktype[client] != TANK5)
			range = GetConVarFloat(sm_supertank_xixing_range) * 2.0;
		else
			range = GetConVarFloat(sm_supertank_xixing_range) * 2.0 * 2.0;
			
		SetEntityMoveType(client, MOVETYPE_NONE);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);	//得到玩家位置	
		//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(10), 持续时间(7.0), 播放宽度(20.0),播放振幅(2.5), 顏色(Color[4]), (播放速度)5, (标识)0)
		TE_SetupBeamRingPoint(pos, range - 0.1, range, g_BeamSprite, g_HaloSprite, 0, 15, 7.0, 20.0, 3.0, SkyblueColor, 5, 0);  //固定外圈  修改了播放振幅
//		TE_SetupBeamRingPoint(pos, range - 0.1, range, g_BeamSprite, g_HaloSprite, 0, 15, 7.0, 50.0, 0.0, RedColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(pos, 0.1, range, g_GlowSprite, g_GlowSprite, 0, 15, 7.0, 20.0, 0.0, mediumorchidColor, 5, 0);    //固定内圈
		TE_SendToAll();
		
		if (tanktype[client] != TANK5)
			CPrintToChatAll("{red}第 %d 阶段坦克:\x03%N {red}即将使用万象引天,开始倒计时!", tanktype[client], client);	
		else
			CPrintToChatAll("{red}帝王坦克:v%N {red}即将使用万象引天,开始倒计时!", client);
		Xixing[client] = 0;
		
		//倒计时吸人
		CreateTimer(1.0, TankAdsTimer_A, client, TIMER_REPEAT);
		KillTimer(timer);
	}	
}

//技能_吸星大法_倒计时与释放     设置多少秒吸人+新人buff   参考不熄光环  修改慢慢吸人过去
public Action:TankAdsTimer_A(Handle:timer, any:client)
{
	if (IsValidPlayer(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == CLASS_TANK && tanktype[client] > 0)
	{
		new Float:pos[3];
		new Float:entpos[3];
		new Float:distance;
		new Float:range;
		if (tanktype[client] != TANK5)
			range = GetConVarFloat(sm_supertank_xixing_range);
		else
			range = GetConVarFloat(sm_supertank_xixing_range) * 2.0;
			
		Xixing[client]++;
		if (Xixing[client] >= 6)  //6秒时间施放
		{	
			if (tanktype[client] != TANK5)
				PrintHintTextToAll("第[%d]阶段坦克: %N 使用万象引天,将[%.0f]码范围内的幸存者吸附过来!", tanktype[client], client, range);
			else
				PrintHintTextToAll("帝王坦克: %N 使用万象引天,将[%.0f]码范围内的幸存者吸附过来!", client, range);	

			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			
			Xixing[client] = 0;
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsValidPlayer(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
					continue;
				
				//对比距离
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				distance = GetVectorDistance(pos, entpos);
				if (distance <= range)
				{
					if(PLAYER_LV[i] <= 30)
					{
						CPrintToChat(i, "\x03由于你等级低于\x0530级\x03,被系统判定为\x05新手,\x03将免疫坦克的\x05万象引天!");
						PrintHintText(i, "由于你等级低于50级,被系统判定为新手,将免疫坦克的万象引天!");
					}
					else
					{
						TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
						EmitSoundToAll(SOUND_DCLAW, i);
						XingxingTankType(client, i);
					}
				}		
			}
			
			//产生随机特感
			SpawnRandomInfected(client, pos);
			
			if (tanktype[client] == TANK1)
				CPrintToChatAll("\x02第一阶段坦克万象引天: \n\x04吸住人产生爆炸冲击波和小团火焰来造成伤害!");
			else if (tanktype[client] == TANK2)
			{
				CPrintToChatAll("\x02第二阶段坦克万象引天: \n\x04吸住人产生爆炸冲击波和小团火焰来造成伤害!");
				CPrintToChatAll("\x04吸住人后产生冰冻效果,使幸存者持续减速!");
			}
			else if (tanktype[client] == TANK3)
			{
				CPrintToChatAll("\x02第三阶段坦克万象引天: \n\x04吸住人产生爆炸冲击波来造成伤害!");
				CPrintToChatAll("\x04吸住人后产生震击效果来震飞幸存者!");
				CPrintToChatAll("\x04吸住人后产生大范围的地狱火!");
			}
			else if (tanktype[client] == TANK4)
			{
				CPrintToChatAll("\x02第四阶段坦克万象引天: \n\x04吸住人产生爆炸冲击波来造成伤害!");
				CPrintToChatAll("\x04吸住人后产生大范围的地狱火!");
				CPrintToChatAll("\x04吸住人后产生冰冻效果,使幸存者持续减速!");
				CPrintToChatAll("\x04吸住人后对被吸住的人进行致盲袭击!");
			}
			else if (tanktype[client] == TANK5)
			{
				CPrintToChatAll("\x02帝王坦克万象引天: \n\x04吸住人产生爆炸冲击波来造成伤害!");
				CPrintToChatAll("\x04吸住人后产生大范围的地狱火!");
				CPrintToChatAll("\x04吸住人后产生冰冻效果,使幸存者持续减速!");
				CPrintToChatAll("\x04吸住人后对被吸住的人进行致盲袭击!");
			}
				
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			new Float:xixingtime = GetConVarFloat(sm_supertank_xixing_interval);
			if (xixingtime > 0)
				CreateTimer(xixingtime, TankAdsTimer, client);
			
			KillTimer(timer);
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			if (tanktype[client] != TANK5)
				PrintHintTextToAll("第[%d]阶段坦克:%N 即将使用[%.0f]范围的万象引天,请赶紧躲开!! \n---------- 倒计时: %d 秒 ----------", tanktype[client], client, range, 6 - Xixing[client]);
			else
				PrintHintTextToAll("帝王坦克:%N 即将使用[%.0f]范围的万象引天,请赶紧躲开!! \n---------- 倒计时: %d 秒 ----------", client, range, 6 - Xixing[client]);
		}
	}
	else
		KillTimer(timer);
}

//技能_吸星大法_坦克阶段判断技能
public XingxingTankType(Client, target)
{
	new Float:pos[3];
	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);
	if (tanktype[Client] == TANK1)
	{
		SuperTank_LittleFlower(Client, pos, EXPLODE);
		SuperTank_LittleFlower(Client, pos, MOLOTOV);
	}
	else if (tanktype[Client] == TANK2)
	{
		SuperTank_LittleFlower(Client, pos, EXPLODE);
		SuperTank_LittleFlower(Client, pos, MOLOTOV);
		PlayerSlowDown(target);
	}
	else if (tanktype[Client] == TANK3)
	{
		SuperTank_LittleFlower(Client, pos, EXPLODE);
		CreateTimer(1.0, TankAdsTimer_B, target);	
		SuperTank_LittleFlower(Client, pos, MOLOTOV);
	}
	else if (tanktype[Client] == TANK4 || tanktype[Client] == TANK5)
	{
		SuperTank_LittleFlower(Client, pos, EXPLODE);
		SuperTank_LittleFlower(Client, pos, MOLOTOV);
		PlayerSlowDown(target);	
		ScreenFade(target, 0, 0, 0, 255, 0, 0);
		new Float:dreadmax = GetConVarFloat(sm_supertank_xixing_dread);
		CreateTimer(dreadmax, DreadTimer, target);
	}
}


//技能_吸星大法_吸人后的震击
public Action:TankAdsTimer_B(Handle:timer, any:client)
{
	new Float:smashmax = GetConVarFloat(sm_supertank_xixing_abs);
	Smash(client, client, smashmax, 1.0, 1.5);
	EmitSoundToClient(client, SOUND_QUAKE);   //传达客户端音效
	KillTimer(timer);
}

//技能_吸星大法_范围减速
public PlayerSlowDown(Target)
{
	new Float:slowspeed = GetConVarFloat(sm_supertank_xixing_slowspeed);
	new Float:time = GetConVarFloat(sm_supertank_xixing_slowtime);
	PlayerSpeed[Target] = GetEntPropFloat(Target, Prop_Send, "m_flLaggedMovementValue");
	SetEntPropFloat(Target, Prop_Send, "m_flLaggedMovementValue", slowspeed);
	ScreenFade(Target, 10, 10, 235, 80, 100, 1);
	CreateTimer(time, PlayerSlowDownReset, Target);
}

//技能_地震攻击
public SkillEarthQuake(Client, target)
{
	decl Float:Pos[3], Float:tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(i == Client)
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			
			GetClientAbsOrigin(Client, Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_supertank_quake_radius))
			{
				EmitSoundToClient(i, SOUND_QUAKE);
				ScreenShake(i, 60.0);
				Smash(Client, i, GetConVarFloat(sm_supertank_quake_force), 1.0, 1.5);
			}
		}
	}
}

//技能_致盲攻击
public SkillDreadClaw(target)
{
	visibility[target] = GetConVarInt(sm_supertank_dreadrate); //GetConVarInt = 获取cfg里的设置
	CreateTimer(GetConVarFloat(sm_supertank_dreadinterval), DreadTimer, target);
	EmitSoundToAll(SOUND_DCLAW, target);
	ScreenFade(target, 0, 0, 0, visibility[target], 0, 0);
}

//技能_重力攻击
public SkillGravityClaw(target)
{
	if (IsValidEntity(target))
		SetEntityGravity(target, 0.95);
	CreateTimer(GetConVarFloat(sm_supertank_gravityinterval), GravityTimer, target);
	EmitSoundToAll(SOUND_GCLAW, target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

//技能_火焰攻击
public SkillBurnClaw(Client, target)
{
	new health = GetClientHealth(target);
	new dmg = health / 2;
		
	if (GeneLv[target] > 0)
		dmg = dmg - RoundToNearest(dmg * GeneEndEffect[target]);
	
	DealDamage(Client, target, dmg, 0, "tank_fireclaw");			
	EmitSoundToAll(SOUND_BCLAW, target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

//技能_彗星石头
public SkillCometStrike(Client, target, type)
{	
	decl Float:pos[3];
	GetClientAbsOrigin(target, pos);
	
	if(type == MOLOTOV)
	{
		SuperTank_LittleFlower(Client, pos, EXPLODE);
		SuperTank_LittleFlower(Client, pos, MOLOTOV);
	}
	else if(type == EXPLODE)
		SuperTank_LittleFlower(Client, pos, EXPLODE);
}

//技能_火焰喷发(被攻击)
public SkillFlameGush(Client, target)
{
	decl Float:pos[3];
		
	SkillBurnClaw(Client, target);
	GetClientAbsOrigin(Client, pos);
	SuperTank_LittleFlower(Client, pos, MOLOTOV);
}


/******************************************************
*	检查坦克状态升级
*******************************************************/
public Action:TankUpdate(Handle:timer, any:Client)
{
	if(!IsValidPlayer(Client) || !IsValidEntity(Client) || !IsPlayerAlive(Client))
	{
		KillTimer(timer);
		TimerUpdate[Client] = INVALID_HANDLE;
	}

	new health = GetClientHealth(Client);
	
	/* 第二阶段*/
	if(SuperTank_Health[TANK2] >= health && health > SuperTank_Health[TANK3])
	{
		if(tanktype[Client] != TANK2)
			SetPrameter(Client, TANK2);
	}
	/* 第三阶段 */
	else if(SuperTank_Health[TANK3] >= health && health > SuperTank_Health[TANK4])
	{
		ExtinguishEntity(Client);
		if(tanktype[Client] != TANK3)
			SetPrameter(Client, TANK3);
	}
	/* 第四阶段 */
	else if(SuperTank_Health[TANK4] >= health && health > 0)
	{
		if(tanktype[Client] != TANK4)
			SetPrameter(Client, TANK4);
	}
	
	return Plugin_Continue;
}

//设置坦克升级类型
public SetPrameter(Client, type)
{
	new health;
	new Float:speed;
	decl String:color[32];
	tanktype[Client] = type;

	/* 升级坦克 */
	if(type == TANK2)
	{
		health = SuperTank_Health[TANK2];
		speed = GetConVarFloat(sm_supertank_speed[tanktype[Client]]);
		GetConVarString(sm_supertank_color_second, color, sizeof(color));
		
		TankTypeChange(Client);
		/* 增加重力 */
		SetEntityGravity(Client, GetConVarFloat(sm_supertank_weight_second));
		CPrintToChatAll("\x03变身为第二阶段坦克: \x03%N \n{red}生命值: \x03%d {red}速度倍率: \x03%.1f", Client, health, speed);
		CPrintToChatAll("\x04此阶段拥有技能:\n \x02重力之拳:被攻击后的幸存者会丧失重力几秒! \n钢铁皮肤:免疫所有近战武器伤害!");
	}
	else if(type == TANK3)
	{
		health = SuperTank_Health[TANK3];
		speed = GetConVarFloat(sm_supertank_speed[tanktype[Client]]);
		GetConVarString(sm_supertank_color_third, color, sizeof(color));
		SetEntityGravity(Client, 1.0);
		
		/* 攻击特效 */
		CreateTimer(0.8, ParticleTimer, Client, TIMER_REPEAT);
		
		TankTypeChange(Client);
		/* 隐形皮肤 */
		CreateTimer(GetConVarFloat(sm_supertank_stealth_third), StealthTimer, Client);
		CPrintToChatAll("{red}变身为第三阶段坦克: \x03%N \n{red}生命值: \x03%d {red}速度倍率: \x03%.1f", Client, health, speed);
		CPrintToChatAll(" \x04此阶段拥有技能:\n \x02隐形皮肤:坦克会慢慢进入隐形状态. \n致盲侵袭:被攻击后幸存者将失去视力一段时间!");
	}
	else if(type == TANK4)
	{
		SetEntityRenderMode(Client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Client, _, _, _, 255);
		
		health = SuperTank_Health[TANK4];
		speed = GetConVarFloat(sm_supertank_speed[tanktype[Client]]);
		GetConVarString(sm_supertank_color_forth, color, sizeof(color));
		SetEntityGravity(Client, 1.0);
		
		TankTypeChange(Client);
		/* 点燃坦克 */
		IgniteEntity(Client, 9999.9);
		CPrintToChatAll("{red}变身为第一阶段坦克: \x03%N \n{red}生命值: \x03%d {red}速度倍率: \x03%.1f", Client, health, speed);
		CPrintToChatAll("\x04此阶段拥有技能:\n \x04熔岩之石:投掷出的石头会产生爆炸和火焰对幸存者造成伤害! \n红血之爪:被攻击的幸存者会直接变成临时血量! \n熔岩喷发:使用近战砍该坦克会产生火焰喷发!");
	}
	
	/* Set speed */
	SetEntPropFloat(Client, Prop_Send, "m_flLaggedMovementValue", speed);
	
	/* Set color */
	SetEntityRenderMode(Client, RenderMode:0);
	DispatchKeyValue(Client, "rendercolor", color);
}

//坦克变身效果
public TankTypeChange(Client)
{
	if(!IsValidPlayer(Client) || !IsValidEntity(Client))
		return;
		
	ExtinguishEntity(Client);	
	/* 形式改变时的效果 */
	AttachParticle(Client, PARTICLE_SPAWN, 1.0);
	for(new j = 1; j <= GetMaxClients(); j++)
	{
		if(!IsValidPlayer(j) || GetClientTeam(j) != 2)
			continue;
			
		EmitSoundToClient(j, SOUND_CHANGE);
	  //ScreenFade(j, 200, 200, 255, 255, 100, 1); 坦克变身时==屏幕闪一下
	}
}

/******************************************************
*	坦克计时器子程序
*******************************************************/
public Action:ParticleTimer(Handle:timer, any:Client)
{
	if(tanktype[Client] == TANK3)
		AttachParticle(Client, PARTICLE_THIRD, 1.0);
	else if(tanktype[Client] == TANK4)
		AttachParticle(Client, PARTICLE_FORTH, 1.0);
	else
		KillTimer(timer);
}

//重力还原计时器
public Action:GravityTimer(Handle:timer, any:target)
{
	if (IsValidPlayer(target) && IsValidEntity(target))
		CreateTimer(0.1, StatusUp, target);
}

//隐形计时器
public Action:StealthTimer(Handle:timer, any:Client)
{
	if(tanktype[Client] == TANK3)
	{
		new s_lv = GetTeamLvCount(2, 1);
		if(s_lv >= 300)
		{
			PerformGlow(Client, 0, 0, 0, 0, 0);		//取消tank轮廓
			CPrintToChatAll("{red}TANK恶魔附体,产生隐身效果,请大家小心!");
		}
		alpharate[Client] = 255;
		Remove(Client);
	}
}

//致盲计时器
public Action:DreadTimer(Handle:timer, any:target)
{
	visibility[target] -= 8;
	
	if(visibility[target] < 0)  
		visibility[target] = 0;
		
	ScreenFade(target, 0, 0, 0, visibility[target], 0, 1);
	
	if(visibility[target] <= 0)
	{
		visibility[target] = 0;
		KillTimer(timer);
	}
}

//坦克瞬移计时器
public Action:WarpTimer(Handle:timer, any:Client)
{
	if(IsValidPlayer(Client) && IsValidEntity(Client) && IsPlayerAlive(Client) && tanktype[Client] > 0 && Xixing[Client] <= 0)
	{
		decl Float:pos[3], Float:t_pos[3];
		new target = GetRandomSurvivor();
			
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidPlayer(i) || !IsValidEntity(i) || GetClientTeam(i) != 2 || IsPlayerIncapped(i))
				continue;
				
			EmitSoundToClient(i, SOUND_WARP);
		}	
		GetClientAbsOrigin(Client, pos);
		if (IsValidPlayer(target))
			GetClientAbsOrigin(target, t_pos);
		else
		{
			SetEntityMoveType(Client, MOVETYPE_WALK);
			SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
			KillTimer(timer);
		}
		
		//(开始坐标, 结束坐标, 效果1, 效果2,渲染帧(0), 渲染速率(15), 持续时间, 播放宽度, 播放振幅(0.0)颜色, 播放速度(10))
		TE_SetupBeamPoints(pos, t_pos, g_BeamSprite, g_HaloSprite, 0, 15, 5.0, 50.0, 50.0, 5, 0.0, YellowColor, 10);  //瞬移中间的线
		TE_SendToAll();
		//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
		TE_SetupBeamRingPoint(pos, 250.0, 250.0 - 0.1, g_GlowSprite, g_GlowSprite, 0, 15, 5.0, 20.0, 3.0, cornflowerblueColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(pos, 0.1, 250.0, g_BeamSprite, g_HaloSprite, 0, 15, 5.0, 10.0, 0.0, deeppinkColor, 10, 0);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(t_pos, 250.0, 250.0 - 0.1, g_BeamSprite, g_HaloSprite, 0, 15, 5.0, 20.0, 0.0, orangeredColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(t_pos, 0.1, 250.0, g_BeamSprite, g_HaloSprite, 0, 15, 5.0, 10.0, 0.0, PlumredColor, 10, 0);
		TE_SendToAll();		
		
		PrintHintTextToAll("超级坦克 %N 瞬移到了 %N 的身边,请赶紧躲开!!", Client, target);
		CPrintToChatAll("\x03超级坦克 {red}%N \x03瞬移到了 {red}%N \x03的身边,请赶紧躲开!!", Client, target);
		ShowParticle(pos, PARTICLE_WARP, 2.0);
		TeleportEntity(Client, t_pos, NULL_VECTOR, NULL_VECTOR);
		ShowParticle(t_pos, PARTICLE_WARP, 2.0);
		SetEntityMoveType(Client, MOVETYPE_WALK);
		SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
		new Float:xixingtime = GetConVarFloat(sm_supertank_xixing_interval);
		if (xixingtime <= 0)
			CreateTimer(0.1, TankAdsTimer, Client);
	}
	else
		KillTimer(timer);
}

//获取随机有效幸存者
public GetRandomSurvivor()
{
	new Handle:array;
	array = CreateArray(1, 0);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidPlayer(i) || !IsValidEntity(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2 || PLAYER_LV[i] <= 30)
			continue;
		PushArrayCell(array, i);
	}
	
	if (GetArraySize(array) <= 0)
	{
		ClearArray(array);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidPlayer(i) || !IsValidEntity(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
			PushArrayCell(array, i);
		}	
	}
	
	if (GetArraySize(array) <= 0)
		return 0;
	
	new maxsize = GetArraySize(array) - 1;
	new clientNum = GetArrayCell(array, GetRandomInt(0, maxsize));
	return clientNum;
}

public Action:FatalMirror(Handle:timer, any:Client)
{
	if(IsValidPlayer(Client) && IsValidEntity(Client) && IsPlayerAlive(Client) && tanktype[Client] > 0)
	{
		/* Stop moving and prevent all damage for a while */
		SetEntityMoveType(Client, MOVETYPE_NONE);
		SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
		
		/* Teleport to position that survivor exsited 2sec ago */
		CreateTimer(0.1, WarpTimer, Client);
	}
	else
	{
		KillTimer(timer);
		Timer_FatalMirror[Client] = INVALID_HANDLE;
	}
}

//帝王坦克地震计时器
public Action:SuperBossAbsTimer(Handle:timer, any:Client)
{
	if (!IsValidPlayer(Client) || !IsPlayerAlive(Client) || tanktype[Client] != TANK5)
		return Plugin_Stop;
	
	new Float:pos[3];
	new Float:entpos[3];
	new Float:distance;
	new Float:range = GetConVarFloat(sm_supertank_bossrange);
	
	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);
	EmitSoundToAll(SOUND_ABS, Client);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
			continue;
		
		//对比距离
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
		distance = GetVectorDistance(pos, entpos);

		if (distance <= range)
		{
			new Float:power = 100.0 - distance / 10.0;
			ScreenShake(i, power);
			PrintHintText(i, "你离帝王坦克越近你的震击感会越强烈,请远离帝王坦克!!");
		}		
	}	
	return Plugin_Continue;
}

//范围减速恢复计时器
public Action:PlayerSlowDownReset(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client))
		SetEntPropFloat(Client, Prop_Send, "m_flLaggedMovementValue", PlayerSpeed[Client]);
		
	KillTimer(timer);
}


/** 坦克其他子程序 **/

public Action:Remove(ent)
{
	if(IsValidEntity(ent) && tanktype[ent] > 0)
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
	if(!IsValidEntity(ent) || tanktype[ent] != TANK3)
	{
		KillTimer(Timer);
		return;
	}
	alpharate[ent] -= 2;
	
	if (alpharate[ent] < 0)  
		alpharate[ent] = 0;
		
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate[ent]);
	if(alpharate[ent] <= 0)
	{
		KillTimer(Timer);
	}
}

public SuperTank_LittleFlower(Client, Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", Client);
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 1)
			/* fire */
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		else
			/* explode */
			DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

/* 重置变量 */
InitData()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		tanktype[i] = 0;
		if(TimerUpdate[i] != INVALID_HANDLE)
		{
			KillTimer(TimerUpdate[i]);
			TimerUpdate[i] = INVALID_HANDLE;
		}
		if(Timer_FatalMirror[i] != INVALID_HANDLE)
		{
			KillTimer(Timer_FatalMirror[i]);
			Timer_FatalMirror[i] = INVALID_HANDLE;
		}		
		
		alpharate[i] = 0;
		visibility[i] = 0;
		
		Xixing[i] = 0;
	}
}

//超级坦克等级平衡产生
public Tank_Balance(Client)
{
	new num = AllLv_Count();

	if (num >= 1 && GetTankCount() < num + 1)
	{
		new i = GetTeamLvCount(2) - GetTeamLvCount(3);
		PrintHintTextToAll("当前幸存者阵营总等级(%d)高于感染者阵营(%d)级,所以系统增加[%d]只超级坦克.", GetTeamLvCount(2), i, num);
		CheatCommand(Client, "z_spawn", "tank auto");
	}
	
}

//取幸存者等级差
public AllLv_Count()
{
	new s_lv;
	new i_lv;
	new more = GetConVarInt(sm_supertank_tankbalance); //GetConVarInt = 获取cfg里的设置
	new num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || IsFakeClient(i))
			continue;
			
		if (GetClientTeam(i) == 2)
			s_lv += Lv[i];
		else if (GetClientTeam(i) == 3)
			i_lv += Lv[i];
	}
	
	num = (s_lv - i_lv) / more;
	if (num >= 1)
		return num;
	else
		return 0;
}

//取阵营总等级
stock GetTeamLvCount(targetteam, type = 0)
{
	new s_lv;
	new i_lv;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || IsFakeClient(i))
			continue;
			
		if (GetClientTeam(i) == 2)
		{
			if (type == 0)
				s_lv += NewLifeCount[i] * 100;
			else
				s_lv += NewLifeCount[i] * 50;
			s_lv += Lv[i];
		}
		else if (GetClientTeam(i) == 3)
		{
			i_lv += NewLifeCount[i] * 100;
			i_lv += Lv[i];
		}
	}
	
	if (targetteam == 2)
		return s_lv;
	else if (targetteam == 3)
		return i_lv;
	else
		return 0;
}

//取坦克数量
GetTankCount()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 3)
			continue;
		if (GetEntProp(i, Prop_Send, "m_zombieClass") == CLASS_TANK)
			count++;
	}
	
	return count;
}

/* 难度控制 */
public SetGameDifficulty()
{
	if (GetConVarInt(rpg_gamedifficulty) != 1) //GetConVarInt = 获取cfg里的设置
		return;

	new s_lv = GetTeamLvCount(2, 1);
	if (s_lv < 50)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Hard");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 5);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 100);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1000);
		SetConVarInt(FindConVar("z_hunter_health"), 800);
		SetConVarInt(FindConVar("z_jockey_health"), 650);
		SetConVarInt(FindConVar("z_gas_health"), 650);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 700);
		//坦克HP
		SuperTank_Health[TANK5] = 100000;
		SuperTank_Health[TANK1] = 65000;
		SuperTank_Health[TANK2] = 55000;
		SuperTank_Health[TANK3] = 30000;
		SuperTank_Health[TANK4] = 20000;
		//坦克瞬移间隔
		SuperTank_Warp = 50.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 3);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[新手]", s_lv);	
	}
	else if (s_lv > 50 && s_lv < 100)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Hard");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1450);
		SetConVarInt(FindConVar("z_hunter_health"),1420);
		SetConVarInt(FindConVar("z_jockey_health"), 1405);
		SetConVarInt(FindConVar("z_gas_health"), 1405);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 1405);
		//坦克HP
		SuperTank_Health[TANK5] = 150000;
		SuperTank_Health[TANK1] = 100000;
		SuperTank_Health[TANK2] = 70000;
		SuperTank_Health[TANK3] = 40000;
		SuperTank_Health[TANK4] = 30000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[简单]", s_lv);	
	}
	else if (s_lv >= 100 && s_lv < 200)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Normal");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1650);
		SetConVarInt(FindConVar("z_hunter_health"),1620);
		SetConVarInt(FindConVar("z_jockey_health"), 1605);
		SetConVarInt(FindConVar("z_gas_health"), 1605);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 1605);
		//坦克HP
		SuperTank_Health[TANK5] = 150000;
		SuperTank_Health[TANK1] = 80000;
		SuperTank_Health[TANK2] = 65000;
		SuperTank_Health[TANK3] = 45000;
		SuperTank_Health[TANK4] = 30000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[中等]", s_lv);	
	}
	else if (s_lv >= 200 && s_lv < 300)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Normal");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1750);
		SetConVarInt(FindConVar("z_hunter_health"),1720);
		SetConVarInt(FindConVar("z_jockey_health"), 1705);
		SetConVarInt(FindConVar("z_gas_health"), 1705);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 1705);
		//坦克HP
		SuperTank_Health[TANK5] = 180000;
		SuperTank_Health[TANK1] = 100000;
		SuperTank_Health[TANK2] = 80000;
		SuperTank_Health[TANK3] = 65000;
		SuperTank_Health[TANK4] = 50000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[困难]", s_lv);	
	}
	else if (s_lv >= 300 && s_lv < 400)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "hard");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1850);
		SetConVarInt(FindConVar("z_hunter_health"),1820);
		SetConVarInt(FindConVar("z_jockey_health"), 1805);
		SetConVarInt(FindConVar("z_gas_health"), 1805);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 1885);
		//坦克HP
		SuperTank_Health[TANK5] = 220000;
		SuperTank_Health[TANK1] = 150000;
		SuperTank_Health[TANK2] = 120000;
		SuperTank_Health[TANK3] = 80000;
		SuperTank_Health[TANK4] = 35000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[疯狂]", s_lv);	
	}
	else if (s_lv >= 400 && s_lv < 500)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "hard");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 1950);
		SetConVarInt(FindConVar("z_hunter_health"),1920);
		SetConVarInt(FindConVar("z_jockey_health"), 1905);
		SetConVarInt(FindConVar("z_gas_health"), 1905);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 1905);
		//坦克HP
		SuperTank_Health[TANK5] = 260000;
		SuperTank_Health[TANK1] = 220000;
		SuperTank_Health[TANK2] = 190000;
		SuperTank_Health[TANK3] = 140000;
		SuperTank_Health[TANK4] = 60000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[地狱]", s_lv);	
	}
	else if (s_lv >= 500 && s_lv < 600)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 2350);
		SetConVarInt(FindConVar("z_hunter_health"),2320);
		SetConVarInt(FindConVar("z_jockey_health"), 2305);
		SetConVarInt(FindConVar("z_gas_health"), 2305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 2305);
		//坦克HP
		SuperTank_Health[TANK5] = 300000;
		SuperTank_Health[TANK1] = 230000;
		SuperTank_Health[TANK2] = 180000;
		SuperTank_Health[TANK3] = 140000;
		SuperTank_Health[TANK4] = 60000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[毁灭]", s_lv);	
	}
	else if (s_lv >= 600 && s_lv < 700)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 3350);
		SetConVarInt(FindConVar("z_hunter_health"),3320);
		SetConVarInt(FindConVar("z_jockey_health"), 3305);
		SetConVarInt(FindConVar("z_gas_health"), 3305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 3305);
		//坦克HP
		SuperTank_Health[TANK5] = 340000;
		SuperTank_Health[TANK1] = 260000;
		SuperTank_Health[TANK2] = 200000;
		SuperTank_Health[TANK3] = 160000;
		SuperTank_Health[TANK4] = 80000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[炼狱]", s_lv);	
	}
	else if (s_lv >= 700 && s_lv < 800)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 3350);
		SetConVarInt(FindConVar("z_hunter_health"),3320);
		SetConVarInt(FindConVar("z_jockey_health"), 3305);
		SetConVarInt(FindConVar("z_gas_health"), 3305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 3305);
		//坦克HP
		SuperTank_Health[TANK5] = 380000;
		SuperTank_Health[TANK1] = 300000;
		SuperTank_Health[TANK2] = 240000;
		SuperTank_Health[TANK3] = 160000;
		SuperTank_Health[TANK4] = 100000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[消逝]", s_lv);	
	}
	else if (s_lv >= 800 && s_lv < 900)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 4350);
		SetConVarInt(FindConVar("z_hunter_health"),4320);
		SetConVarInt(FindConVar("z_jockey_health"), 4305);
		SetConVarInt(FindConVar("z_gas_health"), 4305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 4305);
		//坦克HP
		SuperTank_Health[TANK5] = 420000;
		SuperTank_Health[TANK1] = 350000;
		SuperTank_Health[TANK2] = 280000;
		SuperTank_Health[TANK3] = 200000;
		SuperTank_Health[TANK4] = 140000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[终结]", s_lv);	
	}
	else if (s_lv >= 900 && s_lv < 1000)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 5350);
		SetConVarInt(FindConVar("z_hunter_health"),5320);
		SetConVarInt(FindConVar("z_jockey_health"), 5305);
		SetConVarInt(FindConVar("z_gas_health"), 5305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 5305);
		//坦克HP
		SuperTank_Health[TANK5] = 460000;
		SuperTank_Health[TANK1] = 400000;
		SuperTank_Health[TANK2] = 320000;
		SuperTank_Health[TANK3] = 220000;
		SuperTank_Health[TANK4] = 120000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[暗黑]", s_lv);	
	}
	else if (s_lv >= 1000 && s_lv < 1100)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 5350);
		SetConVarInt(FindConVar("z_hunter_health"),5320);
		SetConVarInt(FindConVar("z_jockey_health"), 5305);
		SetConVarInt(FindConVar("z_gas_health"), 5305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 5305);
		//坦克HP
		SuperTank_Health[TANK5] = 550000;
		SuperTank_Health[TANK1] = 450000;
		SuperTank_Health[TANK2] = 350000;
		SuperTank_Health[TANK3] = 250000;
		SuperTank_Health[TANK4] = 150000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[混沌]", s_lv);	
	}
	else if (s_lv >= 1100 && s_lv < 1200)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 6350);
		SetConVarInt(FindConVar("z_hunter_health"),6320);
		SetConVarInt(FindConVar("z_jockey_health"), 6305);
		SetConVarInt(FindConVar("z_gas_health"), 6305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 6305);
		//坦克HP
		SuperTank_Health[TANK5] = 600000;
		SuperTank_Health[TANK1] = 500000;
		SuperTank_Health[TANK2] = 400000;
		SuperTank_Health[TANK3] = 300000;
		SuperTank_Health[TANK4] = 200000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[元灭]", s_lv);	
	}
	else if (s_lv >= 1200 && s_lv < 1300)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 6350);
		SetConVarInt(FindConVar("z_hunter_health"),6320);
		SetConVarInt(FindConVar("z_jockey_health"), 6305);
		SetConVarInt(FindConVar("z_gas_health"), 6305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 6305);
		//坦克HP
		SuperTank_Health[TANK5] = 700000;
		SuperTank_Health[TANK1] = 600000;
		SuperTank_Health[TANK2] = 500000;
		SuperTank_Health[TANK3] = 400000;
		SuperTank_Health[TANK4] = 250000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[崩溃]", s_lv);	
	}
	else if (s_lv >= 1300 && s_lv < 1400)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 7350);
		SetConVarInt(FindConVar("z_hunter_health"),7320);
		SetConVarInt(FindConVar("z_jockey_health"), 7305);
		SetConVarInt(FindConVar("z_gas_health"), 7305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 7305);
		//坦克HP
		SuperTank_Health[TANK5] = 800000;
		SuperTank_Health[TANK1] = 700000;
		SuperTank_Health[TANK2] = 550000;
		SuperTank_Health[TANK3] = 450000;
		SuperTank_Health[TANK4] = 300000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 80.0;		
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[瓦解]", s_lv);	
	}
	else if (s_lv >= 1400 && s_lv < 1500)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 250);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 8350);
		SetConVarInt(FindConVar("z_hunter_health"),8320);
		SetConVarInt(FindConVar("z_jockey_health"), 8305);
		SetConVarInt(FindConVar("z_gas_health"), 8305);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 8305);
		//坦克HP
		SuperTank_Health[TANK5] = 900000;
		SuperTank_Health[TANK1] = 750000;
		SuperTank_Health[TANK2] = 600000;
		SuperTank_Health[TANK3] = 500000;
		SuperTank_Health[TANK4] = 400000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[粉碎]", s_lv);	
	}
	else if (s_lv >= 2350)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 10000);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 9000);
		SetConVarInt(FindConVar("z_hunter_health"),9000);
		SetConVarInt(FindConVar("z_jockey_health"), 9500);
		SetConVarInt(FindConVar("z_gas_health"), 9500);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 9500);
		//坦克HP
		SuperTank_Health[TANK5] = 1200000;
		SuperTank_Health[TANK1] = 1000000;
		SuperTank_Health[TANK2] = 700000;
		SuperTank_Health[TANK3] = 600000;
		SuperTank_Health[TANK4] = 450000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[暗终]", s_lv);	
	}
	else if (s_lv >= 2650)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 10000);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 9999);
		SetConVarInt(FindConVar("z_hunter_health"),9999);
		SetConVarInt(FindConVar("z_jockey_health"), 9999);
		SetConVarInt(FindConVar("z_gas_health"), 9999);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 9999);
		//坦克HP
		SuperTank_Health[TANK5] = 1300000;
		SuperTank_Health[TANK1] = 1200000;
		SuperTank_Health[TANK2] = 700000;
		SuperTank_Health[TANK3] = 600000;
		SuperTank_Health[TANK4] = 450000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[灭世天劫]", s_lv);	
	}	else if (s_lv >= 2350)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 10000);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 9999);
		SetConVarInt(FindConVar("z_hunter_health"),9999);
		SetConVarInt(FindConVar("z_jockey_health"), 9999);
		SetConVarInt(FindConVar("z_gas_health"), 9999);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 9999);
		//坦克HP
		SuperTank_Health[TANK5] = 1200000;
		SuperTank_Health[TANK1] = 1000000;
		SuperTank_Health[TANK2] = 700000;
		SuperTank_Health[TANK3] = 600000;
		SuperTank_Health[TANK4] = 450000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[暗终]", s_lv);	
	}	else if (s_lv >= 2950)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 10000);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 9999);
		SetConVarInt(FindConVar("z_hunter_health"),9999);
		SetConVarInt(FindConVar("z_jockey_health"), 9999);
		SetConVarInt(FindConVar("z_gas_health"), 9999);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 9999);
		//坦克HP
		SuperTank_Health[TANK5] = 1600000;
		SuperTank_Health[TANK1] = 1500000;
		SuperTank_Health[TANK2] = 700000;
		SuperTank_Health[TANK3] = 600000;
		SuperTank_Health[TANK4] = 450000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[无人生还]", s_lv);	
	}	
	else if (s_lv >= 2650)
	{
		//游戏默认难度
		SetConVarString(FindConVar("z_difficulty"), "Impossible");
		//坦克数量
		SetConVarInt(FindConVar("director_force_tank"), 6);
		//友军伤害
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_easy"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_normal"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_hard"), 0.1);
		SetConVarFloat(FindConVar("survivor_friendly_fire_factor_expert"), 0.1);
		//火焰伤害
		SetConVarFloat(FindConVar("survivor_burn_factor_easy"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_Normal"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_hard"), 0.3);
		SetConVarFloat(FindConVar("survivor_burn_factor_expert"), 0.3);
		//普通感染者HP
		SetConVarInt(FindConVar("z_health"), 10000);
		//特感HP
		SetConVarInt(FindConVar("z_charger_health"), 9999);
		SetConVarInt(FindConVar("z_hunter_health"),9999);
		SetConVarInt(FindConVar("z_jockey_health"), 9999);
		SetConVarInt(FindConVar("z_gas_health"), 9999);
		SetConVarInt(FindConVar("z_exploding_health"), 100);
		SetConVarInt(FindConVar("z_spitter_health"), 9999);
		//坦克HP
		SuperTank_Health[TANK5] = 1800000;
		SuperTank_Health[TANK1] = 2000000;
		SuperTank_Health[TANK2] = 1400000;
		SuperTank_Health[TANK3] = 1200000;
		SuperTank_Health[TANK4] = 650000;
		//坦克瞬移间隔
		SuperTank_Warp = 30.0;
		//黑白次数
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		//坦克伤害抵消几率
		TankOffsetRadio = 100.0;	
		CPrintToChatAll("{green}[公告]{lightgreen}当前幸存者等级为{green}(%d级){lightgreen},游戏难度自动调整为{green}[终结者]", s_lv);	
	}
}

/* 随机掉落物品 */
public DropRandomWeapon(Client)
{
	if (!IsValidPlayer(Client) || GetClientTeam(Client) != 3)
		return;
	
	new String:weapon[64];
	new max;
	for (new u = 1; u <= MaxClients; u++)
	{
		if (!IsValidPlayer(u) || IsFakeClient(u) || GetClientTeam(u) != 2 || !IsPlayerAlive(u))
			continue;
			
		max++;			
	}
	
	if (tanktype[Client] != TANK5)
	{
		if (max <= 4)
			max = 1;
		else
			max = max / 4;
	}
	
	for(new i; i <= max; i++)
	{
		new gun = GetRandomInt(0, 15);
		new medic = GetRandomInt(0, 3);
		new bomb = GetRandomInt(0, 2);			
		Format(weapon, sizeof(weapon), t_Gun[gun]);   //枪
		Tank_CreateEntity(Client, weapon);
		Format(weapon, sizeof(weapon), t_Bomb[bomb]);  //炸弹
		Tank_CreateEntity(Client, weapon);
		Format(weapon, sizeof(weapon), t_Medic[medic]);   //医疗
		Tank_CreateEntity(Client, weapon);
	}
	
	if (tanktype[Client] != TANK5)
		CPrintToChatAll("\x03[系统]\x03超级坦克\x03死亡,在坦克的死亡位置掉落了{red}%d\x03份{red}物品补给!", max * 1);
	else
		CPrintToChatAll("\x03[系统]\x03帝王坦克\x03死亡,在坦克的死亡位置掉落了{red}%d\x03份{red}物品补给!", max * 1);
}

/* 实体创建 */
stock Tank_CreateEntity(Client, String:classname[], bool:IsMelee = false)
{
	new entity;
	new Float:pos[3];
	GetClientAbsOrigin(Client, pos);
	if (!IsMelee)
		entity = CreateEntityByName(classname);
	else
	{
		entity = CreateEntityByName("weapon_melee_spawn");
		DispatchKeyValue(entity, "spawnflags", "2");
		DispatchKeyValue(entity, "melee_weapon", classname);
	}
		
		
	if (IsValidEntity(entity))
	{
		pos[0] = pos[0] + GetRandomFloat(-60.0, 60.0);
		pos[1] = pos[1] + GetRandomFloat(-60.0, 60.0);
		pos[2] = pos[2] + GetRandomFloat(40.0, 60.0);
		ActivateEntity(entity);
		DispatchSpawn(entity);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropFloat(entity, Prop_Send,"m_flModelScale", 0.5); 
		PerformGlow(entity, 3, 0, 240, 240 ,240);
	}
}