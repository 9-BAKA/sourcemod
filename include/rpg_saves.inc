/************************************************************************
*	存档保存读取功能
************************************************************************/
#define PLUGIN_VERSION "2.61x"

/**********************
*	 玩家基本数据
**********************/
new Lv[MAXPLAYERS+1];
new EXP[MAXPLAYERS+1];
new Cash[MAXPLAYERS+1];
new KTCount[MAXPLAYERS+1];	//误杀队友统计
new NewLifeCount[MAXPLAYERS+0];	//转生次数
new String:Password[MAXPLAYERS+1][64];
/**********************
*	 玩家背包数据
**********************/
new I_Bag[MAXPLAYERS+1][5][10];
new I_BagSize[MAXPLAYERS+1];
/**********************
*	 玩家属性
**********************/
new VIP[MAXPLAYERS+1];
new VIPTL[MAXPLAYERS+1];
new VIPYEAR[MAXPLAYERS+1];
new Str[MAXPLAYERS+1];
new Agi[MAXPLAYERS+1];
new Health[MAXPLAYERS+1];
new Endurance[MAXPLAYERS+1];
new Intelligence[MAXPLAYERS+1];
new SkillPoint[MAXPLAYERS+1];
new StatusPoint[MAXPLAYERS+1];
new Crits[MAXPLAYERS+1];
new CritMin[MAXPLAYERS+1];
new CritMax[MAXPLAYERS+1];

/**********************
*	 幸存者通用技能
**********************/
/** 治疗术 **/
new HealingLv[MAXPLAYERS+1];
/** 地震 **/
new EarthQuakeLv[MAXPLAYERS+1];
/** 强化苏醒术 **/
new EndranceQualityLv[MAXPLAYERS+1];
/*** 职业基本资料 ***/
new bool:JobChooseBool[MAXPLAYERS+1];
new JD[MAXPLAYERS+1] = {0, ...};

/**********************
*	 工程师
**********************/
/* 蘑菇云核弹 */
new AmmoMakingmissLv[MAXPLAYERS+1];
/* 卫星炮术 */
new SatelliteCannonLv[MAXPLAYERS+1];
/* 子弹制造术 */
new AmmoMakingLv[MAXPLAYERS+1];
/* 射速加强术 */
new FireSpeedLv[MAXPLAYERS+1];

/**********************
*	 士兵 
**********************/
/* 攻防强化术 */
new EnergyEnhanceLv[MAXPLAYERS+1];
/* 加速冲刺术 */
new SprintLv[MAXPLAYERS+1];
/* 无限子弹术 */
new InfiniteAmmoLv[MAXPLAYERS+1];
/* 狂暴者模式 */
new BioShieldkbLv[MAXPLAYERS+1];

/**********************
*	 生物学家
**********************/
/* 无敌术 */
new BioShieldLv[MAXPLAYERS+1];
/* 反伤术 */
new DamageReflectLv[MAXPLAYERS+1];
/* 近战嗜血术 */
new MeleeSpeedLv[MAXPLAYERS+1];
/* 基因改造 */
new GeneLv[MAXPLAYERS+1];
/* 潜能大暴发 */
new BioShieldmissLv[MAXPLAYERS+1];


/**********************
*	 心灵医师 
**********************/
/* 选择传送术 */
new TeleportToSelectLv[MAXPLAYERS+1];
/* 审判光球术 */
new AppointTeleportLv[MAXPLAYERS+1];
/* 心灵传送术 */
new TeleportTeamLv[MAXPLAYERS+1];
new defibrillator[MAXPLAYERS+1];
/* 治疗光球术 */
new HealingBallLv[MAXPLAYERS+1];
/* 全体传送术 */
new TeleportTeamztLv[MAXPLAYERS+1];

/**********************
*	 魔法师 
**********************/
/* 火球术 */
new FireBallLv[MAXPLAYERS+1];
/* 冰球术 */
new IceBallLv[MAXPLAYERS+1];
/* 连锁闪电术 */
new ChainLightningLv[MAXPLAYERS+1];
/* 终结式暴雷 */
new SatelliteCannonmissLv[MAXPLAYERS+1];

/**********************
*	弹药师
**********************/
//破碎弹
new BrokenAmmoLv[MAXPLAYERS+1];
//渗毒弹
new PoisonAmmoLv[MAXPLAYERS+1];
//吸血弹
new SuckBloodAmmoLv[MAXPLAYERS+1];
//区域爆破
new AreaBlastingLv[MAXPLAYERS+1];
//镭射激光炮
new LaserGunLv[MAXPLAYERS+1];


/* 存档和排名 */
new String:SavePath[256];
new String:RankPath[256];
new Handle:RPGSave = INVALID_HANDLE;
new Handle:RPGRank = INVALID_HANDLE;
#define RankNo 100
new String:LevelRankClient[MAXPLAYERS+RankNo][256];
new LevelRank[MAXPLAYERS+RankNo];
new String:CashRankClient[MAXPLAYERS+RankNo][256];
new CashRank[MAXPLAYERS+RankNo];
new bool:IsAdmin[MAXPLAYERS+1]	=	{false, ...};

/* Robot升级设置 */
new RobotUpgradeLv[MAXPLAYERS+1][3];
/*  彩票卷 */
new Lottery[MAXPLAYERS+1]				=	{0, ...};

/* 道具最大数 :消耗道具最大值 -  装备道具最大值*/
new MaxItemNum[2] = { 9, 42 };

/* 存档变量 : 玩家ID - 道具类别 - 道具 */
new PlayerItem[MAXPLAYERS+1][2][64];
new PlayerXHItemSize[MAXPLAYERS+1];
new PlayerZBItemSize[MAXPLAYERS+1];

/* 道具类别 */
#define ITEM_XH			0	//消耗类道具
#define ITEM_ZB			1	//装备类道具

new BagMax[5] = { 10, 5, 3, 4, 2 };

new Handle:ServerTimeLog = INVALID_HANDLE;
new String:ServerTimePath[256];

stock LoadRPGData()
{
	/* 创建Save和Ranking的KeyValues */
	RPGSave = CreateKeyValues("United RPG Save");
	RPGRank = CreateKeyValues("United RPG Ranking");
	/* 设置Save和Ranking位置 */
	BuildPath(Path_SM, SavePath, 255, "data/UnitedRPGSave.txt");
	BuildPath(Path_SM, RankPath, 255, "data/UnitedRPGRanking.txt");
	if (FileExists(SavePath))
		FileToKeyValues(RPGSave, SavePath);
	else
		KeyValuesToFile(RPGSave, SavePath); //PrintToserver("[United RPG] 找不到玩家记录档: %s, 将重新建立!", SavePath);
	if (FileExists(RankPath))
		FileToKeyValues(RPGRank, RankPath);
	else
		KeyValuesToFile(RPGRank, RankPath); //PrintToserver("[United RPG] 找不到排名记录档: %s, 将重新建立!", RankPath);
	
	/* 服务器时间日志 */
	ServerTimeLog = CreateKeyValues("Server Time Log");
	BuildPath(Path_SM, ServerTimePath, 255, "data/ServerTimeLog.txt");
	if (FileExists(ServerTimePath))
		FileToKeyValues(ServerTimeLog, ServerTimePath);
	else
		KeyValuesToFile(ServerTimeLog, ServerTimePath);
		
	/* 清除存档 */
	CreateTimer(1.0, CleanSaveFile);
	
	/* 读取排名 */
	LoadRanking();
}


/* 清理存档 */
public Action:CleanSaveFile(Handle:timer)
{
	decl String:section[365];
	decl String:curDayStr[8] = "StringToInt(curDayStr)";
	decl String:curYearStr[365] = "StringToInt(curYearStr)";

	FormatTime(curDayStr,sizeof(curDayStr),"%j");
	FormatTime(curYearStr,sizeof(curYearStr),"%Y");

	new curDay	= StringToInt(curDayStr);
	new curYear	= StringToInt(curYearStr);
	new delDays	= 7;


	KvGotoFirstSubKey(RPGSave);

	new statsEntries = 0;
	new statsChecked = 0;

	while (KvGotoNextKey(RPGSave))
	{
		statsEntries++;
	}
	
	PrintToServer("[United RPG] 今天是%d年的第%d天,存档总计:%d个,清理进行中...", curYear, curDay, statsEntries);
	KvRewind(RPGSave);
	KvGotoFirstSubKey(RPGSave);
	
	while (statsChecked < statsEntries)
	{
		statsChecked++;

		KvGetSectionName(RPGSave, section, 365);

		if (IsCommonName(section))
		{
			KvDeleteThis(RPGSave);
			PrintToServer("[United RPG] 删除 %s 的存档! (原因: 常用名称)", section);
			continue;
		}
		
		decl String:lastConnStr[128] = "";
		KvGetString(RPGSave,"DATE",lastConnStr,sizeof(lastConnStr),"Failed");

		if (!StrEqual(lastConnStr, "Failed", false)) //"%j:0-%Y" 000:0-0000
		{
			new String:lastDayStr[8], String:IsAdminStr[8], String:lastYearStr[8];

			lastDayStr[0] = lastConnStr[0];
			lastDayStr[1] = lastConnStr[1];
			lastDayStr[2] = lastConnStr[2];
			new lastDay	= StringToInt(lastDayStr);

			IsAdminStr[0] = lastConnStr[4];
			new isAdmin = StringToInt(IsAdminStr);

			lastYearStr[0] = lastConnStr[6];
			lastYearStr[1] = lastConnStr[7];
			lastYearStr[2] = lastConnStr[8];
			lastYearStr[3] = lastConnStr[9];
			new lastYear = StringToInt(lastYearStr);

			new daysSinceVisit = (curDay+((curYear-lastYear)*365)) - lastDay;
			PrintToServer("%s, admin:%d, date:%s, %d天未上线", section, isAdmin, lastConnStr, daysSinceVisit);

			if (daysSinceVisit >= delDays && delDays != 0)
			{
				if (isAdmin == 1)
				{
					KvGotoNextKey(RPGSave);
					PrintToServer("[United RPG] 略过删除 %s 的存档! (原因: 管理员)", section);
				}
				else if(KvGetNum(RPGSave, "Lv", 0) >= 30 || KvGetNum(RPGSave, "NL", 0) >=1)
				{
					KvGotoNextKey(RPGSave);
					PrintToServer("[United RPG] 略过删除 %s 的存档! (原因: 等级 >= 30 或 已转生)", section);
				}
				else if(KvGetNum(RPGSave, "VIP", 0) > 1)
				{
					KvGotoNextKey(RPGSave);
					PrintToServer("[United RPG] 略过删除 %s 的存档! (原因: VIP会员)", section);
				}
				else
				{
					KvDeleteThis(RPGSave);
					PrintToServer("[United RPG] 删除 %s 的存档! (原因: %d天未上线 & 等级 <= 50 & 未转生)", section, daysSinceVisit);
				}
			}
			else 
				KvGotoNextKey(RPGSave);
		}
		else 
			KvDeleteThis(RPGSave);
	}

	KvRewind(RPGSave);
	KeyValuesToFile(RPGSave, SavePath);
	return Plugin_Handled;
}

/* 读取存档Function */
public ClientSaveToFileLoad(Client)
{
	/* 读取玩家姓名 */
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(Client, user_name, sizeof(user_name));
	/* 取代玩家姓名中会导致错误的符号 */
	ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
	ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
	ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
	/* 读取玩家资料 */
	KvJumpToKey(RPGSave, user_name, true);

	VIP[Client]					=	KvGetNum(RPGSave, "VIP", 0);
	VIPTL[Client]					=	KvGetNum(RPGSave, "VIPTL", 0);
	VIPYEAR[Client]				=	KvGetNum(RPGSave, "VIPYEAR", 0);
	JD[Client]						=	KvGetNum(RPGSave, "Job", 0);
	Lv[Client]						=	KvGetNum(RPGSave, "LV", 0);
	EXP[Client]					=	KvGetNum(RPGSave, "EXP", 0);
	Cash[Client]					=	KvGetNum(RPGSave, "CASH", 0);
	KTCount[Client]				=	KvGetNum(RPGSave, "KTcount", 0);
	Str[Client]					=	KvGetNum(RPGSave, "Str", 0);
	Agi[Client]					=	KvGetNum(RPGSave, "Agi", 0);
	Health[Client]				=	KvGetNum(RPGSave, "Hea", 0);
	Endurance[Client]				=	KvGetNum(RPGSave, "End", 0);
	Intelligence[Client]			=	KvGetNum(RPGSave, "Int", 0);
	Crits[Client]					=	KvGetNum(RPGSave, "Crits", 0);
	CritMin[Client]				=	KvGetNum(RPGSave, "CritMin", 0);
	CritMax[Client]				=	KvGetNum(RPGSave, "CritMax", 0);
	StatusPoint[Client]			=	KvGetNum(RPGSave, "SP", 0);
	SkillPoint[Client]			=	KvGetNum(RPGSave, "KSP", 0);
	HealingLv[Client]				=	KvGetNum(RPGSave, "HealLv", 0);//治癒术等级
	EarthQuakeLv[Client]			=	KvGetNum(RPGSave, "EQLv", 0);//地震术等级
	EndranceQualityLv[Client]	=	KvGetNum(RPGSave, "GENGXINLv", 0);//强化苏醒术等级
	RobotUpgradeLv[Client][0]	=	KvGetNum(RPGSave, "RUAtLv", 0);//Robot攻击力等级
	RobotUpgradeLv[Client][1]	=	KvGetNum(RPGSave, "RUAmLv", 0);//Robot弹匣系统等级
	RobotUpgradeLv[Client][2]	=	KvGetNum(RPGSave, "RURLv", 0);//Robot侦查距离等级
	Lottery[Client]				=	KvGetNum(RPGSave, "Lottery", 0);//彩票卷
	NewLifeCount[Client]			=	KvGetNum(RPGSave, "NL", 0);//转生次数
	EveryDaySign[Client]			=	KvGetNum(RPGSave, "QD", 0);//每日签到日数
	
	if(JD[Client] > 0)
	{
		JobChooseBool[Client] = true;
		if(JD[Client] == 1)//工程师
		{
			AmmoMakingLv[Client]			=	KvGetNum(RPGSave, "AMLv", 0);//子弹制造术等级
			AmmoMakingmissLv[Client]			=	KvGetNum(RPGSave, "MOGULv", 0);//蘑菇云核弹等级
			FireSpeedLv[Client]			=   KvGetNum(RPGSave, "FSLv", 0);//射速加强术等级
			SatelliteCannonLv[Client]		=   KvGetNum(RPGSave, "SCLv", 0);//卫星炮术等级
		} 
		else if(JD[Client] == 2)//士兵
		{
			EnergyEnhanceLv[Client]	=	KvGetNum(RPGSave, "EELv", 0);//攻防强化术等级
			SprintLv[Client]				=	KvGetNum(RPGSave, "SprLv", 0);//加速冲刺术等级
			InfiniteAmmoLv[Client]		=	KvGetNum(RPGSave, "IALv", 0);//无限子弹术等级
			BioShieldkbLv[Client]			=	KvGetNum(RPGSave, "kbzLv", 0);//狂暴者模式等级
		} 
		else if(JD[Client] == 3)//生物专家
		{
			BioShieldLv[Client]			=	KvGetNum(RPGSave, "BSLv", 0);//无敌术等级
			DamageReflectLv[Client]		=	KvGetNum(RPGSave, "DRLv", 0);//反伤术等级
			MeleeSpeedLv[Client]			=	KvGetNum(RPGSave, "MSLv", 0);//近战嗜血术等级
			BioShieldmissLv[Client]			=	KvGetNum(RPGSave, "BAOFALv", 0);//潜能大爆发等级
			GeneLv[Client]				=	KvGetNum(RPGSave, "GENELV", 0);//基因改造等级
		} 
		else if(JD[Client] == 4)//心灵医师
		{
			TeleportToSelectLv[Client]	=	KvGetNum(RPGSave, "TCLv", 0);//选择传送术等级
			AppointTeleportLv[Client]	=	KvGetNum(RPGSave, "ATLv", 0);//审判光球术等级
			TeleportTeamLv[Client]		=	KvGetNum(RPGSave, "TTLv", 0);//心灵传送术等级
			HealingBallLv[Client]		=	KvGetNum(RPGSave, "HBLv", 0);//治疗光球术等级
			TeleportTeamztLv[Client]		=	KvGetNum(RPGSave, "ztcsLv", 0);//全体传送术等级
			ResetDoctor(Client);
		} 
		else if(JD[Client] == 5)//魔法师
		{
			FireBallLv[Client]	=	KvGetNum(RPGSave, "FBLv", 0);//火球术等级
			IceBallLv[Client]	=	KvGetNum(RPGSave, "IBLv", 0);//冰球术等级
			ChainLightningLv[Client]	=	KvGetNum(RPGSave, "CLLv", 0);//连锁闪电术等级
			SatelliteCannonmissLv[Client]		=   KvGetNum(RPGSave, "baoleiLv", 0);//终结式暴雷等级
		} 
		else if(JD[Client] == 6)//弹药师
		{
			BrokenAmmoLv[Client]		=	KvGetNum(RPGSave, "PSDLv", 0);//破碎弹等级
			PoisonAmmoLv[Client]		=	KvGetNum(RPGSave, "SDDLv", 0);//渗毒弹等级
			SuckBloodAmmoLv[Client]	=	KvGetNum(RPGSave, "XXDLv", 0);//吸血弹等级
			AreaBlastingLv[Client]	=   KvGetNum(RPGSave, "QYBPLv", 0);//区域爆破等级
			LaserGunLv[Client]		=   KvGetNum(RPGSave, "LSJGPLv", 0);//镭射激光炮等级
		}
	} else JobChooseBool[Client] = false;

	//背包物品读取
	new String:BagData[16];
	I_BagSize[Client] = KvGetNum(RPGSave, "bagsize", 5);
	if (I_BagSize[Client] == 5)
	{
		if (VIP[Client] == 1)
			I_BagSize[Client] += 3;
		else if (VIP[Client] == 2)
			I_BagSize[Client] += 5;
	}
	
	KvJumpToKey(RPGSave, "Bag", true);
	for (new i; i < 5; i++)
	{
		Format(BagData, sizeof(BagData), "t%d", i);
		KvJumpToKey(RPGSave, BagData, true);
		for (new u; u < BagMax[i]; u++)
		{
			Format(BagData, sizeof(BagData), "i%d", u);
			I_Bag[Client][i][u] = KvGetNum(RPGSave, BagData, 0);
		}
		KvGoBack(RPGSave);
	}
	KvGoBack(RPGSave);
	
	//消耗类道具物品读取
	PlayerXHItemSize[Client] = KvGetNum(RPGSave, "XHSize", 1);
	if (PlayerXHItemSize[Client] == 1)
	{
		if (VIP[Client] > 0)
			PlayerXHItemSize[Client] += 1;
	}
	
	KvJumpToKey(RPGSave, "XHItem", true);
	for (new i; i < MaxItemNum[ITEM_XH]; i++)
	{
		Format(BagData, sizeof(BagData), "XH%d", i);
		PlayerItem[Client][ITEM_XH][i] = KvGetNum(RPGSave, BagData, 0);
	}
	KvGoBack(RPGSave);
	
	//装备类道具物品读取
	PlayerZBItemSize[Client] = KvGetNum(RPGSave, "ZBSize", 1);
	if (PlayerZBItemSize[Client] == 1)
	{
		if (VIP[Client] > 0)
			PlayerZBItemSize[Client] += 1;
	}
	
	KvJumpToKey(RPGSave, "ZBItem", true);
	for (new i; i < MaxItemNum[ITEM_ZB]; i++)
	{		
		Format(BagData, sizeof(BagData), "ZB%d", i);
		PlayerItem[Client][ITEM_ZB][i] = KvGetNum(RPGSave, BagData, 0);
	}
	KvGoBack(RPGSave);
		
	KvRewind(RPGSave);
	
	//装备到期检查
	PlayerZBIsOver(Client);
	//PrintToserver("[United RPG] %N的Save已读取!", Client);
}

/* 存档Function */
public ClientSaveToFileSave(Client)
{
	if (!IsPasswordConfirm[Client])
		return;
		
	/* 读取玩家姓名 */
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(Client, user_name, sizeof(user_name));
	/* 取代玩家姓名中会导致错误的符号 */
	ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
	ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
	ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
	KvJumpToKey(RPGSave, user_name, true);
	
	
	KvSetNum(RPGSave, "EXP", EXP[Client]);
	KvSetNum(RPGSave, "CASH", Cash[Client]);
	KvSetString(RPGSave, "PW", Password[Client]);	
	
	if (VIP[Client] > 0)	
	{
		KvSetNum(RPGSave, "VIP", VIP[Client]);
		KvSetNum(RPGSave, "VIPTL", VIPTL[Client]);
		KvSetNum(RPGSave, "VIPYEAR", VIPYEAR[Client]);
	}
	else
	{
		KvDeleteKey(RPGSave, "VIP");
		KvDeleteKey(RPGSave, "VIPTL");
		KvDeleteKey(RPGSave, "VIPYEAR");
	}
		
	if (Lv[Client] > 0)	
		KvSetNum(RPGSave, "LV", Lv[Client]);
	else
		KvDeleteKey(RPGSave, "LV");
				
	if (JD[Client] > 0)	
		KvSetNum(RPGSave, "Job", JD[Client]);
	else
		KvDeleteKey(RPGSave, "Job");

	if (StatusPoint[Client] > 0)	
		KvSetNum(RPGSave, "SP", StatusPoint[Client]);
	else
		KvDeleteKey(RPGSave, "SP");
		
	if (SkillPoint[Client] > 0)	
		KvSetNum(RPGSave, "KSP", SkillPoint[Client]);
	else
		KvDeleteKey(RPGSave, "KSP");
		
	if (KTCount[Client] > 0)	
		KvSetNum(RPGSave, "KTcount", KTCount[Client]);
	else
		KvDeleteKey(RPGSave, "KTcount");

	if (Str[Client] > 0)	
		KvSetNum(RPGSave, "Str", Str[Client]);
	else
		KvDeleteKey(RPGSave, "Str");

	if (Agi[Client] > 0)	
		KvSetNum(RPGSave, "Agi", Agi[Client]);
	else
		KvDeleteKey(RPGSave, "Agi");
		
	if (Health[Client] > 0)	
		KvSetNum(RPGSave, "Hea", Health[Client]);
	else
		KvDeleteKey(RPGSave, "Hea");
		
	if (Endurance[Client] > 0)	
		KvSetNum(RPGSave, "End", Endurance[Client]);
	else
		KvDeleteKey(RPGSave, "End");

	if (Intelligence[Client] > 0)	
		KvSetNum(RPGSave, "Int", Intelligence[Client]);
	else
		KvDeleteKey(RPGSave, "Int");
		
	if (Crits[Client] > 0)	
		KvSetNum(RPGSave, "Crits", Crits[Client]);
	else
		KvDeleteKey(RPGSave, "Crits");
		
	if (CritMin[Client] > 0)	
		KvSetNum(RPGSave, "CritMin", CritMin[Client]);
	else
		KvDeleteKey(RPGSave, "CritMin");
		
	if (CritMax[Client] > 0)	
		KvSetNum(RPGSave, "CritMax", CritMax[Client]);
	else
		KvDeleteKey(RPGSave, "CritMax");

	if (HealingLv[Client] > 0)	
		KvSetNum(RPGSave, "HealLv", HealingLv[Client]);
	else
		KvDeleteKey(RPGSave, "HealLv");
		
	if (EarthQuakeLv[Client] > 0)	
		KvSetNum(RPGSave, "EQLv", EarthQuakeLv[Client]);
	else
		KvDeleteKey(RPGSave, "EQLv");
		
	if (EndranceQualityLv[Client] > 0)	
		KvSetNum(RPGSave, "GENGXINLv", EndranceQualityLv[Client]);
	else
		KvDeleteKey(RPGSave, "GENGXINLv");
		
	if (RobotUpgradeLv[Client][0] > 0)	
		KvSetNum(RPGSave, "RUAtLv", RobotUpgradeLv[Client][0]);
	else
		KvDeleteKey(RPGSave, "RUAtLv");

	if (RobotUpgradeLv[Client][1] > 0)	
		KvSetNum(RPGSave, "RUAmLv", RobotUpgradeLv[Client][1]);
	else
		KvDeleteKey(RPGSave, "RUAmLv");
		
	if (RobotUpgradeLv[Client][2] > 0)	
		KvSetNum(RPGSave, "RURLv", RobotUpgradeLv[Client][2]);
	else
		KvDeleteKey(RPGSave, "RURLv");

	if (Lottery[Client] > 0)	
		KvSetNum(RPGSave, "Lottery", Lottery[Client]);
	else
		KvDeleteKey(RPGSave, "Lottery");
		
	if (NewLifeCount[Client] > 0)	
		KvSetNum(RPGSave, "NL", NewLifeCount[Client]);
	else
		KvDeleteKey(RPGSave, "NL");
	
	//每日签到
	if (EveryDaySign[Client] > 0)
		KvSetNum(RPGSave, "QD", EveryDaySign[Client]);
	else
		KvDeleteKey(RPGSave, "QD");
	
	if(JD[Client] == 0)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "HBLv");
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
	} 
	else if(JD[Client] == 1)
	{
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "HBLv");
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
		KvSetNum(RPGSave, "AMLv", AmmoMakingLv[Client]);
		KvSetNum(RPGSave, "MOGULv", AmmoMakingmissLv[Client]);
		KvSetNum(RPGSave, "FSLv", FireSpeedLv[Client]);
		KvSetNum(RPGSave, "SCLv", SatelliteCannonLv[Client]);
	} 
	else if(JD[Client] == 2)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "HBLv");
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
		KvSetNum(RPGSave, "EELv", EnergyEnhanceLv[Client]);
		KvSetNum(RPGSave, "SprLv", SprintLv[Client]);
		KvSetNum(RPGSave, "IALv", InfiniteAmmoLv[Client]);
		KvSetNum(RPGSave, "kbzLv", BioShieldkbLv[Client]);
	} 
	else if(JD[Client] == 3)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "HBLv");
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
		KvSetNum(RPGSave, "BSLv", BioShieldLv[Client]);
		KvSetNum(RPGSave, "DRLv", DamageReflectLv[Client]);
		KvSetNum(RPGSave, "MSLv", MeleeSpeedLv[Client]);
		KvSetNum(RPGSave, "GENELV", GeneLv[Client]);
		KvSetNum(RPGSave, "BAOFALv", BioShieldmissLv[Client]);
	} 
	else if(JD[Client] == 4)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
		KvSetNum(RPGSave, "TCLv", TeleportToSelectLv[Client]);
		KvSetNum(RPGSave, "ATLv", AppointTeleportLv[Client]);
		KvSetNum(RPGSave, "TTLv", TeleportTeamLv[Client]);
		KvSetNum(RPGSave, "ztcsLv", TeleportTeamztLv[Client]);
		KvSetNum(RPGSave, "HBLv", HealingBallLv[Client]);
	}
	else if(JD[Client] == 5)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "HBLv");	
		KvDeleteKey(RPGSave, "PSDLv");
		KvDeleteKey(RPGSave, "SDDLv");
		KvDeleteKey(RPGSave, "XXDLv");
		KvDeleteKey(RPGSave, "QYBPLv");
		KvDeleteKey(RPGSave, "LSJGPLv");
		KvSetNum(RPGSave, "FBLv", FireBallLv[Client]);
		KvSetNum(RPGSave, "IBLv", IceBallLv[Client]);
		KvSetNum(RPGSave, "CLLv", ChainLightningLv[Client]);
		KvSetNum(RPGSave, "baoleiLv", SatelliteCannonmissLv[Client]);
	}
	else if(JD[Client] == 6)
	{
		KvDeleteKey(RPGSave, "AMLv");
		KvDeleteKey(RPGSave, "MOGULv");
		KvDeleteKey(RPGSave, "FSLv");
		KvDeleteKey(RPGSave, "SCLv");
		KvDeleteKey(RPGSave, "EELv");
		KvDeleteKey(RPGSave, "SprLv");
		KvDeleteKey(RPGSave, "IALv");
		KvDeleteKey(RPGSave, "BSLv");
		KvDeleteKey(RPGSave, "GENELV");
		KvDeleteKey(RPGSave, "BAOFALv");
		KvDeleteKey(RPGSave, "kbzLv");
		KvDeleteKey(RPGSave, "DRLv");
		KvDeleteKey(RPGSave, "MSLv");
		KvDeleteKey(RPGSave, "TCLv");
		KvDeleteKey(RPGSave, "ATLv");
		KvDeleteKey(RPGSave, "TTLv");
		KvDeleteKey(RPGSave, "ztcsLv");
		KvDeleteKey(RPGSave, "HBLv");
		KvDeleteKey(RPGSave, "FBLv");
		KvDeleteKey(RPGSave, "IBLv");
		KvDeleteKey(RPGSave, "CLLv");
		KvDeleteKey(RPGSave, "baoleiLv");
		KvSetNum(RPGSave, "PSDLv", BrokenAmmoLv[Client]); //破碎弹等级
		KvSetNum(RPGSave, "SDDLv", PoisonAmmoLv[Client]); //渗毒弹等级
		KvSetNum(RPGSave, "XXDLv", SuckBloodAmmoLv[Client]); //吸血弹等级
		KvSetNum(RPGSave, "QYBPLv", AreaBlastingLv[Client]); //区域爆破等级
		KvSetNum(RPGSave, "LSJGPLv", LaserGunLv[Client]); //镭射激光炮等级
	}

	//背包物品保存
	new String:BagData[16];
	KvSetNum(RPGSave, "bagsize", I_BagSize[Client]);
	KvJumpToKey(RPGSave, "Bag", true);
	for (new i; i < 5; i++)
	{
		Format(BagData, sizeof(BagData), "t%d", i);
		KvJumpToKey(RPGSave, BagData, true);
		for (new u; u < BagMax[i]; u++)
		{	
			Format(BagData, sizeof(BagData), "i%d", u);
			if (I_Bag[Client][i][u] <= 0)
				KvDeleteKey(RPGSave, BagData);
			else
				KvSetNum(RPGSave, BagData, I_Bag[Client][i][u]);
		}	
		KvGoBack(RPGSave);
	}	
	KvGoBack(RPGSave);

	//装备到期检查
	PlayerZBIsOver(Client);	
	
	//消耗类道具保存
	if (VIP[Client] > 0)
	{
		if (PlayerXHItemSize[Client] <= 2)
			KvDeleteKey(RPGSave, "XHSize");
		else
			KvSetNum(RPGSave, "XHSize", PlayerXHItemSize[Client]);
	}
	else
	{
		if (PlayerXHItemSize[Client] <= 1)
			KvDeleteKey(RPGSave, "XHSize");	
		else
			KvSetNum(RPGSave, "XHSize", PlayerXHItemSize[Client]);
	}
	
	KvJumpToKey(RPGSave, "XHItem", true);
	for (new i; i < MaxItemNum[ITEM_XH]; i++)
	{
		Format(BagData, sizeof(BagData), "XH%d", i);
		if (PlayerItem[Client][ITEM_XH][i] <= 0)
			KvDeleteKey(RPGSave, BagData);
		else
			KvSetNum(RPGSave, BagData, PlayerItem[Client][ITEM_XH][i]);			
	}
	KvGoBack(RPGSave);
	
	//装备类道具保存
	decl String:ZBTime[8];
	if (VIP[Client] > 0)
	{
		if (PlayerZBItemSize[Client] <= 2)
			KvDeleteKey(RPGSave, "ZBSize");
		else
			KvSetNum(RPGSave, "ZBSize", PlayerZBItemSize[Client]);
	}
	else
	{
		if (PlayerZBItemSize[Client] <= 1)
			KvDeleteKey(RPGSave, "ZBSize");	
		else
			KvSetNum(RPGSave, "ZBSize", PlayerZBItemSize[Client]);
	}
	
	KvJumpToKey(RPGSave, "ZBItem", true);
	for (new i; i < MaxItemNum[ITEM_ZB]; i++)
	{
		if (i == 0 || i == 1 || i == 36)
		{
			KvDeleteKey(RPGSave, "ZB0");
			KvDeleteKey(RPGSave, "ZB1");
			KvDeleteKey(RPGSave, "ZB36");
			continue;
		}
		
		Format(BagData, sizeof(BagData), "ZB%d", i);
		if (PlayerItem[Client][ITEM_ZB][i] <= 0)
			KvDeleteKey(RPGSave, BagData);
		else
		{
			Format(ZBTime, 8, "%s", ForStringZBTime(Client, i));
			KvSetString(RPGSave, BagData, ZBTime);	
		}			
	}
	KvGoBack(RPGSave);
	
	decl String:DisconnectDate[128] = "";
	if(IsAdmin[Client])
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:1-%Y/%m/%d %H:%M:%S");
	else
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:0-%Y/%m/%d %H:%M:%S");

	KvSetString(RPGSave,"DATE", DisconnectDate);
	
	KvRewind(RPGSave);
	KeyValuesToFile(RPGSave, SavePath);
	//PrintToserver("[United RPG] %s的Save已储存!", NameInfo(Client, simple));
}


/* 读取排名Function */
stock LoadRanking()
{
	KvJumpToKey(RPGRank, "LV", true);
	decl String:RankNameClient[256];
	decl String:RankNameLevel[256];
	for(new r = 0; r < RankNo; r++)
	{
		Format(RankNameClient, sizeof(RankNameClient), "第%d名玩家", r+1);
		Format(RankNameLevel, sizeof(RankNameLevel), "第%d名等级", r+1);
		KvGetString(RPGRank, RankNameClient, LevelRankClient[r], 256, "未知");
		LevelRank[r] = KvGetNum(RPGRank, RankNameLevel, 0);
	}
	KvGoBack(RPGRank);
	KvJumpToKey(RPGRank, "CASH", true);
	for(new r = 0; r < RankNo; r++)
	{
		Format(RankNameClient, sizeof(RankNameClient), "第%d名玩家", r+1);
		Format(RankNameLevel, sizeof(RankNameLevel), "第%d名金钱", r+1);
		KvGetString(RPGRank, RankNameClient, CashRankClient[r], 256, "未知");
		CashRank[r] = KvGetNum(RPGRank, RankNameLevel, 0);
	}
	KvGoBack(RPGRank);
	//PrintToserver("[United RPG] 排名已读取!");
}
/* 更新排名Function */
stock UpdateRanking()
{
	new LevelRankClientNo = RankNo;
	new CashRankClientNo = RankNo;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(!IsFakeClient(i))
			{
				new bool:IsInTopFiveLevel = false;
				new bool:IsInTopFiveCash = false;
				decl String:user_name[MAX_NAME_LENGTH]="";
				GetClientName(i, user_name, sizeof(user_name));
				ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
				ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
				ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
				ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
				ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
				for(new j = 0; j < RankNo; j++)
				{
					if(StrEqual(LevelRankClient[j],user_name,true))
					{
						LevelRank[j]=Lv[i];
						IsInTopFiveLevel = true;
						j = RankNo;
					}
				}
				for(new j = 0; j<RankNo; j++)
				{
					if(StrEqual(CashRankClient[j],user_name,true))
					{
						CashRank[j]=Cash[i];
						IsInTopFiveCash = true;
						j = RankNo;
					}
				}
				if(!IsInTopFiveLevel)
				{
					LevelRank[LevelRankClientNo] = Lv[i];
					strcopy(LevelRankClient[LevelRankClientNo],256,user_name);
					LevelRankClientNo++;
				}
				if(!IsInTopFiveCash)
				{
					CashRank[CashRankClientNo] = Cash[i];
					strcopy(CashRankClient[CashRankClientNo],256,user_name);
					CashRankClientNo++;
				}
			}
		}
	}

	/* Bubble Sort 排序 */
	new	TempLevelRank;
	new	String:TempLevelRankClient[256];
	for(new j = 1; j < LevelRankClientNo; j++)
	{
		for(new r = 0; r < LevelRankClientNo - j; r++)
		{
			if(LevelRank[r] <= LevelRank[r+1])
			{
				TempLevelRank = LevelRank[r];
				LevelRank[r] = LevelRank[r+1];
				LevelRank[r+1] = TempLevelRank;

				strcopy(TempLevelRankClient, 256, LevelRankClient[r]);
				strcopy(LevelRankClient[r], 256, LevelRankClient[r+1]);
				strcopy(LevelRankClient[r+1], 256, TempLevelRankClient);
			}
		}
	}

	new	TempCashlRank;
	new	String:TempCashRankClient[256];
	for(new j = 1; j < CashRankClientNo; j++)
	{
		for(new r = 0; r < CashRankClientNo - j; r++)
		{
			if(CashRank[r] <= CashRank[r+1])
			{
				TempCashlRank = CashRank[r];
				CashRank[r] = CashRank[r+1];
				CashRank[r+1] = TempCashlRank;

				strcopy(TempCashRankClient, 256, CashRankClient[r]);
				strcopy(CashRankClient[r], 256, CashRankClient[r+1]);
				strcopy(CashRankClient[r+1], 256, TempCashRankClient);
			}
		}
	}

	for(new r = 0; r < RankNo; r++)
	{
		KvJumpToKey(RPGRank, "LV", true);
		decl String:RankNameClient[256];
		decl String:RankNameLevel[256];
		Format(RankNameClient, sizeof(RankNameClient), "第%d名玩家", r+1);
		Format(RankNameLevel, sizeof(RankNameLevel), "第%d名等级", r+1);
		KvSetString(RPGRank, RankNameClient, LevelRankClient[r]);
		KvSetNum(RPGRank, RankNameLevel, LevelRank[r]);
		KvGoBack(RPGRank);

		KvJumpToKey(RPGRank, "CASH", true);
		decl String:RankNameCash[256];
		Format(RankNameClient, sizeof(RankNameClient), "第%d名玩家", r+1);
		Format(RankNameCash, sizeof(RankNameCash), "第%d名金钱", r+1);
		KvSetString(RPGRank, RankNameClient, CashRankClient[r]);
		KvSetNum(RPGRank, RankNameCash, CashRank[r]);
		KvGoBack(RPGRank);
	}

	KvJumpToKey(RPGRank, "United RPG", true);
	KvSetString(RPGRank, "Plugin_Version", PLUGIN_VERSION);

	KvRewind(RPGRank);
	KeyValuesToFile(RPGRank, RankPath);
	//PrintToserver("[United RPG] 排名已更新!");
}

/* 手动存档 */
public Action:Command_RPGSave(Client, args)
{
	PlayerManualSave(Client);
	return Plugin_Handled;
}

/* 是否常用名称 */
public bool:IsCommonName(String:name[])
{
	new String:numname[64];
	new bool:Is = false;
	for (new i; i < 10; i++)
	{
		if (i > 0)
			Format(numname, sizeof(numname), "(%d)自己人,别开枪", i);
		else
			Format(numname, sizeof(numname), "自己人,别开枪");
			
		if (StrEqual(name, numname))
		{
			Is = true;
			break;
		}
			
		if (i > 0)
			Format(numname, sizeof(numname), "(%d)迅闪2010", i);
		else
			Format(numname, sizeof(numname), "迅闪2010");
			
		if (StrEqual(name, numname))
		{
			Is = true;
			break;
		}	

		if (i > 0)
			Format(numname, sizeof(numname), "(%d)玩家名", i);
		else
			Format(numname, sizeof(numname), "玩家名");
			
		if (StrEqual(name, numname))
		{
			Is = true;
			break;
		}

		if (i > 0)
			Format(numname, sizeof(numname), "(%d)RPCplayer", i);
		else
			Format(numname, sizeof(numname), "RPCplayer");
			
		if (StrEqual(name, numname))
		{
			Is = true;
			break;
		}		

		if (i > 0)
			Format(numname, sizeof(numname), "(%d)REVOLUTiON", i);
		else
			Format(numname, sizeof(numname), "REVOLUTiON");
			
		if (StrEqual(name, numname))
		{
			Is = true;
			break;
		}			
	}
	
	return Is;
}