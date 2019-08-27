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
new MEIZI[MAXPLAYERS+1];
new KTCount[MAXPLAYERS+1];	//误杀队友统计
new NewLifeCount[MAXPLAYERS+0];	//转生次数
new String:Password[MAXPLAYERS+1][64];
new Sxqh[MAXPLAYERS+1];//强化治疗术
new Sxcs[MAXPLAYERS+1];
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
new Crits[MAXPLAYERS+1];    //暴击
new CritMin[MAXPLAYERS+1];
new CritMax[MAXPLAYERS+1];
//开局装备领取记录
new KJZB[MAXPLAYERS+1];

/*** 任务系统 ****/
new Shitou[MAXPLAYERS+1]; //强化石
new Shilv[MAXPLAYERS+1]; //强化等级
new Qstr[MAXPLAYERS+1]; //强化攻击
new Qcash[MAXPLAYERS+1]; //元宝
new DHJ[MAXPLAYERS+1]; //兑换卷
new Libao[MAXPLAYERS+1]; //升级礼包
new Eqbox[MAXPLAYERS+1]; //奇迹宝盒
new Renwu[MAXPLAYERS+1];
new Jenwu[MAXPLAYERS+1];
new Pugan[MAXPLAYERS+1]; //普感
new Tegan[MAXPLAYERS+1]; //特感
new TYangui[MAXPLAYERS+1]; //烟鬼
new TPangzi[MAXPLAYERS+1]; //胖子
new TLieshou[MAXPLAYERS+1]; //猎手
new TKoushui[MAXPLAYERS+1]; //口水
new THouzhi[MAXPLAYERS+1]; //猴子
new TXiaoniu[MAXPLAYERS+1]; //小牛
new TDaxinxin[MAXPLAYERS+1]; //tank

//荣誉称号
new BJCH[MAXPLAYERS+1]; //称号显示
new TKSL[MAXPLAYERS+1]; 
new XGSL[MAXPLAYERS+1];
new HZSL[MAXPLAYERS+1];
new PPSL[MAXPLAYERS+1]; 
new PZSL[MAXPLAYERS+1]; 
new DXSL[MAXPLAYERS+1]; 
new NWSL[MAXPLAYERS+1];
new DRSL[MAXPLAYERS+1]; 
new BRSL[MAXPLAYERS+1];  
new YGSL[MAXPLAYERS+1];
new QHSL[MAXPLAYERS+1];    
//这里是装备称号的变量
new TKSLZ[MAXPLAYERS+1];//坦克杀手 
new XGSLZ[MAXPLAYERS+1];//僵尸猎手
new HZSLZ[MAXPLAYERS+1];//拒绝乘骑
new PPSLZ[MAXPLAYERS+1];//文明者
new PZSLZ[MAXPLAYERS+1];//瘦身教练 
new DXSLZ[MAXPLAYERS+1]; //执法者
new NWSLZ[MAXPLAYERS+1]; //哭泣杀手
new DRSLZ[MAXPLAYERS+1]; //救助者
new BRSLZ[MAXPLAYERS+1]; //好队友
new QHHSZ[MAXPLAYERS+1];  //强化好手
new BZBNZ[MAXPLAYERS+1];  //百折不挠    
new YGSLZ[MAXPLAYERS+1];  //拒绝吸烟

//记录新人教程
new XR[MAXPLAYERS+1];
//记录回归礼包
new HGLB[MAXPLAYERS+1]; //记录活动奖励
//活动
new HDZT[MAXPLAYERS+1]; //记录活动奖励
new HDRW[MAXPLAYERS+1]; //记录活动奖励
new TDaxinxin1[MAXPLAYERS+1]; //tank
new HD1[MAXPLAYERS+1]; //记录活动奖励
new HD2[MAXPLAYERS+1]; //记录活动奖励
new HD3[MAXPLAYERS+1]; //记录活动奖励
new HD4[MAXPLAYERS+1]; //记录活动奖励
new HD5[MAXPLAYERS+1]; //记录活动奖励
new HD6[MAXPLAYERS+1]; //记录活动奖励
//新增枪神附体
new Robot_appendage[MAXPLAYERS+1];

new Lis[MAXPLAYERS+1]; //人类
new LisA[MAXPLAYERS+1]; //宙斯
new LisB[MAXPLAYERS+1]; //哈迪斯

//远古力量
new TSDJ1[MAXPLAYERS+1]; //刷出TANK
new TSDJ2[MAXPLAYERS+1]; //召唤尸潮
new TSDJ3[MAXPLAYERS+1]; //回到原地

//连续签到
new everyday1[MAXPLAYERS+1]; 

/*** 武器系统 ****/
new M16[MAXPLAYERS+1];
new AK47[MAXPLAYERS+1];
new PZ[MAXPLAYERS+1];
new AWP[MAXPLAYERS+1];
new M60[MAXPLAYERS+1];
new GZ[MAXPLAYERS+1];
new JXZX[MAXPLAYERS+1];
new WQXT[MAXPLAYERS+1];
new Qhs[MAXPLAYERS+1];
new BSXY[MAXPLAYERS+1];//坦克心愿

/*** 师徒系统 ****/
new bool:IsMaster[MAXPLAYERS+1];
new bool:IsPupil[MAXPLAYERS+1];
new String:PMaster[MAXPLAYERS+1][64];	//师父
new String:Pupil_1[MAXPLAYERS+1][64]; //徒弟1
new String:Pupil_2[MAXPLAYERS+1][64]; //徒弟2
new String:Pupil_3[MAXPLAYERS+1][64]; //徒弟3
new String:Pupil_4[MAXPLAYERS+1][64]; //徒弟4
new String:Pupil_5[MAXPLAYERS+1][64]; //徒弟5
new String:PupilArray[MAXPLAYERS+1][5][64]; //徒弟数组
new String:PupilSelectedName[MAXPLAYERS+1][64];	//操作的徒弟名字
new BMaster[MAXPLAYERS+1];	//拜师的临时变量
new BPupil[MAXPLAYERS+1];	//收徒的临时变量
new MasterReward[MAXPLAYERS+1];

/*** 天赋 ****/
new MSTF[MAXPLAYERS+1];
new tgyj[MAXPLAYERS+1];
new DJYX[MAXPLAYERS+1];
new xstf[MAXPLAYERS+1];
new sxtf[MAXPLAYERS+1];
new NHYS[MAXPLAYERS+1];
new KBYS[MAXPLAYERS+1];
new ZHONGHUO[MAXPLAYERS+1];
new JIDONG[MAXPLAYERS+1];

/*** 技能强化系统 ****/
new Qhwx[MAXPLAYERS+1]; 
new Qhwd[MAXPLAYERS+1];
new Qhjs[MAXPLAYERS+1]; 
new Qhzd[MAXPLAYERS+1];
new Qhsp[MAXPLAYERS+1];
new Qhzl[MAXPLAYERS+1]; 
new Qhhq[MAXPLAYERS+1]; 
new Qhbq[MAXPLAYERS+1]; 
new Qhls[MAXPLAYERS+1]; 
new Qhps[MAXPLAYERS+1]; 
new Qhsd[MAXPLAYERS+1]; 
new Qhxx[MAXPLAYERS+1];  
new Qhdz[MAXPLAYERS+1];


/**********************
*	 幸存者通用技能
**********************/
/** 治疗术 **/
new HealingLv[MAXPLAYERS+1];
/** 地震 **/
new EarthQuakeLv[MAXPLAYERS+1];
/** 爆菊助手 **/
new HeavyGunLv[MAXPLAYERS+1];
/** 强化苏醒术 **/
new EndranceQualityLv[MAXPLAYERS+1];
/*** 职业基本资料 ***/
new bool:JobChooseBool[MAXPLAYERS+1];
new JD[MAXPLAYERS+1] = {0, ...};

/**********************
*	 工程师
**********************/
/* 毁灭核弹 */
new AmmoMakingmissLv[MAXPLAYERS+1];
/* 轨道炮 */
new SatelliteCannonLv[MAXPLAYERS+1];
/* 制造子弹 */
new AmmoMakingLv[MAXPLAYERS+1];
/* 超级射速 */
new FireSpeedLv[MAXPLAYERS+1];

/**********************
*	 游侠 
**********************/
/* 钢铁之躯 */
new EnergyEnhanceLv[MAXPLAYERS+1];
/* 疾风步 */
new SprintLv[MAXPLAYERS+1];
/* 无限弹药 */
new InfiniteAmmoLv[MAXPLAYERS+1];
/* 炎之暴走 */
new BioShieldkbLv[MAXPLAYERS+1];

/**********************
*	 狂战士
**********************/
/* 霸体 */
new BioShieldLv[MAXPLAYERS+1];
/* 复仇反击 */
new DamageReflectLv[MAXPLAYERS+1];
/* 近战乱舞 */
new MeleeSpeedLv[MAXPLAYERS+1];
/* 基因改造 */
new GeneLv[MAXPLAYERS+1];
/* 狂暴嗜血 */
new BioShieldmissLv[MAXPLAYERS+1];

/**********************
*	 圣疗者 
**********************/
/* 支援传送 */
new TeleportToSelectLv[MAXPLAYERS+1];
/* 审判光球术 */
new AppointTeleportLv[MAXPLAYERS+1];
/* 心灵传送术 */
new TeleportTeamLv[MAXPLAYERS+1];
new defibrillator[MAXPLAYERS+1];
/* 治疗光球术 */
new HealingBallLv[MAXPLAYERS+1];
/* 吸引术 */
new TeleportTeamztLv[MAXPLAYERS+1];

/**********************
*	 魔法师 
**********************/
/* 爆破 */
new FireBallLv[MAXPLAYERS+1];
/* 冰封 */
new IceBallLv[MAXPLAYERS+1];
/* 连锁闪电术 */
new ChainLightningLv[MAXPLAYERS+1];
/* 究极雷霆 */
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

/**********************
*	 雷神 
**********************/
/* 电磁感应 */
new DCGYLv[MAXPLAYERS+1];
/* 雷子弹 */
new LZDLv[MAXPLAYERS+1];
/* 引雷电术 */
new YLDSLv[MAXPLAYERS+1];

/**********************
*	 虚空之眼
**********************/
/* 虚空之怒 */
new CqdzLv[MAXPLAYERS+1];
/* 电弘赤炎 */
new HMZSLv[MAXPLAYERS+1];
/* 涟漪光圈 */
new SPZSLv[MAXPLAYERS+1];
/* 幽冥暗量 */
new GouhunLv[MAXPLAYERS+1];
//菊花
new Hunpo[MAXPLAYERS+1];


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
new MaxItemNum[2] = { 10, 57 };

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
	decl String:section[256];
	decl String:curDayStr[8] = "";
	decl String:curYearStr[8] = "";

	FormatTime(curDayStr,sizeof(curDayStr),"%j");
	FormatTime(curYearStr,sizeof(curYearStr),"%Y");

	new curDay	= StringToInt(curDayStr);
	new curYear	= StringToInt(curYearStr);
	new delDays	= 7;


	KvGotoFirstSubKey(RPGSave);

	new statsEntries = 1;
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

		KvGetSectionName(RPGSave, section, 256);

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
				else if(KvGetNum(RPGSave, "NL", 0) >=0)
				{
					KvGotoNextKey(RPGSave);
					PrintToServer("[United RPG] 略过删除 %s 的存档! (原因: 玩家)", section);
				}
				else if(KvGetNum(RPGSave, "VIP", 0) >=0)
				{
					KvGotoNextKey(RPGSave);
					PrintToServer("[United RPG] 略过删除 %s 的存档! (原因: 玩家)", section);
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
	Shitou[Client]					=	KvGetNum(RPGSave, "Shitou", 0);
	Shilv[Client]					=	KvGetNum(RPGSave, "Shilv", 0);
	Lis[Client]					=	KvGetNum(RPGSave, "Lis", 0);
	LisA[Client]					=	KvGetNum(RPGSave, "LisA", 0);
	LisB[Client]					=	KvGetNum(RPGSave, "LisB", 0);
	Qstr[Client]					=	KvGetNum(RPGSave, "Qstr", 0);
	Libao[Client]					=	KvGetNum(RPGSave, "Libao", 0);
	Eqbox[Client]					=	KvGetNum(RPGSave, "Eqbox", 0);
	Renwu[Client]                 =	KvGetNum(RPGSave, "Rwu", 0);
	Jenwu[Client]					=	KvGetNum(RPGSave, "Jwu", 0);
	Pugan[Client]                 =	KvGetNum(RPGSave, "Pgan", 0);
	Tegan[Client]                 =	KvGetNum(RPGSave, "Tgan", 0);
	TYangui[Client]                 =	KvGetNum(RPGSave, "Tyang", 0);
	TPangzi[Client]                 =	KvGetNum(RPGSave, "TPang", 0);
	TLieshou[Client]                 =	KvGetNum(RPGSave, "Tlies", 0);
	TKoushui[Client]                 =	KvGetNum(RPGSave, "Tkous", 0);
	THouzhi[Client]                 =	KvGetNum(RPGSave, "Thouz", 0);
	TXiaoniu[Client]                 =	KvGetNum(RPGSave, "Txiao", 0);
	TDaxinxin[Client]                 =	KvGetNum(RPGSave, "Txinx", 0);
	VIPYEAR[Client]				=	KvGetNum(RPGSave, "VIPYEAR", 0);
	JD[Client]						=	KvGetNum(RPGSave, "Job", 0);
	Lv[Client]						=	KvGetNum(RPGSave, "LV", 0);
	EXP[Client]					=	KvGetNum(RPGSave, "EXP", 0);
	Cash[Client]					=	KvGetNum(RPGSave, "CASH", 0);
	Qcash[Client]					=	KvGetNum(RPGSave, "QCASH", 0);
	TSDJ1[Client]					=	KvGetNum(RPGSave, "TSDJ1", 0);
	TSDJ2[Client]					=	KvGetNum(RPGSave, "TSDJ2", 0);
	TSDJ3[Client]					=	KvGetNum(RPGSave, "TSDJ3", 0);
	DHJ[Client]					=	KvGetNum(RPGSave, "DHJ", 0);
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
	HeavyGunLv[Client]			=	KvGetNum(RPGSave, "HeavyGun", 0); //爆菊助手等级
	EndranceQualityLv[Client]	=	KvGetNum(RPGSave, "GENGXINLv", 0);//强化苏醒术等级
	RobotUpgradeLv[Client][0]	=	KvGetNum(RPGSave, "RUAtLv", 0);//Robot攻击力等级
	RobotUpgradeLv[Client][1]	=	KvGetNum(RPGSave, "RUAmLv", 0);//Robot弹匣系统等级
	RobotUpgradeLv[Client][2]	=	KvGetNum(RPGSave, "RURLv", 0);//Robot侦查距离等级
	Lottery[Client]				=	KvGetNum(RPGSave, "Lottery", 0);//彩票卷
	NewLifeCount[Client]			=	KvGetNum(RPGSave, "NL", 0);//转生次数
	EveryDaySign[Client]			=	KvGetNum(RPGSave, "QD", 0);//每日签到日数
	Robot_appendage[Client]		=	KvGetNum(RPGSave, "Robot_appendage",0);	//枪神附体
	everyday1[Client]					=	KvGetNum(RPGSave, "everyday1", 0);  //连续签到
	HDZT[Client]                 =	KvGetNum(RPGSave, "HDZT", 0);//活动状态
	HDRW[Client]                 =	KvGetNum(RPGSave, "HDRW", 0);//活动任务
	TDaxinxin1[Client]                 =	KvGetNum(RPGSave, "Txinx1", 0);//活动 Tank
	HD1[Client]                 =	KvGetNum(RPGSave, "HD1", 0);//活动
	HD2[Client]                 =	KvGetNum(RPGSave, "HD2", 0);//活动
	HD3[Client]                 =	KvGetNum(RPGSave, "HD3", 0);//活动
	HD4[Client]                 =	KvGetNum(RPGSave, "HD4", 0);//活动
	HD5[Client]                 =	KvGetNum(RPGSave, "HD5", 0);//活动
	HD6[Client]                 =	KvGetNum(RPGSave, "HD6", 0);//活动
	Hunpo[Client]         =	KvGetNum(RPGSave, "Hunpo", 0);//菊花
	Sxcs[Client]					=	KvGetNum(RPGSave, "Sxcs",0);
	QHHSZ[Client]					=	KvGetNum(RPGSave, "QHHSZ", 0);		
	BZBNZ[Client]					=	KvGetNum(RPGSave, "BZBNZ", 0);
	YGSLZ[Client]					=	KvGetNum(RPGSave, "YGSLZ", 0);
	QHSL[Client]					=	KvGetNum(RPGSave, "QHSL", 0);
	BSXY[Client]					=	KvGetNum(RPGSave, "BSXY", 0);
	Qhs[Client]					=	KvGetNum(RPGSave, "Qhs", 0);
	M16[Client]					=	KvGetNum(RPGSave, "M16",0);
	AK47[Client]					=	KvGetNum(RPGSave, "AK47", 0);
	PZ[Client]					=	KvGetNum(RPGSave, "PZ", 0);
	AWP[Client]					=	KvGetNum(RPGSave, "AWP",0);
	M60[Client]					=	KvGetNum(RPGSave, "M60", 0);
	BJCH[Client]					=	KvGetNum(RPGSave, "BJCH", 0);	
	TKSL[Client]					=	KvGetNum(RPGSave, "TKSL", 0);	
	XGSL[Client]					=	KvGetNum(RPGSave, "XGSL", 0);
	HZSL[Client]					=	KvGetNum(RPGSave, "HZSL", 0);	
	PZSL[Client]					=	KvGetNum(RPGSave, "PZSL", 0);	
	PPSL[Client]					=	KvGetNum(RPGSave, "PPSL", 0);	
	DXSL[Client]					=	KvGetNum(RPGSave, "DXSL", 0);		
	NWSL[Client]					=	KvGetNum(RPGSave, "NWSL", 0);	
	DRSL[Client]					=	KvGetNum(RPGSave, "DRSL", 0);		
	BRSL[Client]					=	KvGetNum(RPGSave, "BRSL", 0);
	YGSL[Client]					=	KvGetNum(RPGSave, "YGSL", 0);	
	QHSL[Client]					=	KvGetNum(RPGSave, "QHSL", 0);		
	TKSLZ[Client]					=	KvGetNum(RPGSave, "TKSLZ", 0);	
	XGSLZ[Client]					=	KvGetNum(RPGSave, "XGSLZ", 0);
	HZSLZ[Client]					=	KvGetNum(RPGSave, "HZSLZ", 0);	
	PZSLZ[Client]					=	KvGetNum(RPGSave, "PZSLZ", 0);	
	PPSLZ[Client]					=	KvGetNum(RPGSave, "PPSLZ", 0);	
	DXSLZ[Client]					=	KvGetNum(RPGSave, "DXSLZ", 0);		
	NWSLZ[Client]					=	KvGetNum(RPGSave, "NWSLZ", 0);	
	DRSLZ[Client]					=	KvGetNum(RPGSave, "DRSLZ", 0);		
	BRSLZ[Client]					=	KvGetNum(RPGSave, "BRSLZ", 0);
	QHHSZ[Client]					=	KvGetNum(RPGSave, "QHHSZ", 0);		
	BZBNZ[Client]					=	KvGetNum(RPGSave, "BZBNZ", 0);
	YGSLZ[Client]					=	KvGetNum(RPGSave, "YGSLZ", 0);
	XR[Client]					=	KvGetNum(RPGSave, "XR", 0);
	MasterReward[Client]			=	KvGetNum(RPGSave, "师徒礼包", 0);
	Sxqh[Client]					=	KvGetNum(RPGSave, "Sx", 0); //强化治疗术
	Qhdz[Client]		        =   KvGetNum(RPGSave, "qhdz", 0);//强化地震术
	M60[Client]	                =	KvGetNum(RPGSave, "m60", 0);
	PZ[Client]	                    =	KvGetNum(RPGSave, "pz", 0);
	AWP[Client]	         		=	KvGetNum(RPGSave, "awp", 0);
	AK47[Client]                 	=	KvGetNum(RPGSave, "ak47", 0);
	M16[Client]	        		=	KvGetNum(RPGSave, "m16", 0);
	MSTF[Client]		        =   KvGetNum(RPGSave, "mstf", 0);
	tgyj[Client]		        =   KvGetNum(RPGSave, "tg", 0);
	xstf[Client]		        =   KvGetNum(RPGSave, "xs", 0);
	sxtf[Client]		        =   KvGetNum(RPGSave, "shixue", 0);
	BSXY[Client]		        =   KvGetNum(RPGSave, "bossxy", 0);
	NHYS[Client]		        =   KvGetNum(RPGSave, "nhys", 0);
	KBYS[Client]		        =   KvGetNum(RPGSave, "kbys", 0);
	HGLB[Client]                 =	KvGetNum(RPGSave, "HGLB", 0);//回归礼包
	
	if(JD[Client] > 0)
	{
		JobChooseBool[Client] = true;
		if(JD[Client] == 1)//神枪手
		{
			AmmoMakingLv[Client]			=	KvGetNum(RPGSave, "AMLv", 0);//子弹制造术等级
			AmmoMakingmissLv[Client]			=	KvGetNum(RPGSave, "MOGULv", 0);//毁灭核弹等级
			FireSpeedLv[Client]			=   KvGetNum(RPGSave, "FSLv", 0);//超级射速等级
			SatelliteCannonLv[Client]		=   KvGetNum(RPGSave, "SCLv", 0);//轨道炮等级
			Qhwx[Client]		=   KvGetNum(RPGSave, "qhwx", 0);//强化卫星炮
		} 
		else if(JD[Client] == 2)//游侠
		{
			EnergyEnhanceLv[Client]	=	KvGetNum(RPGSave, "EELv", 0);//攻防术等级
			SprintLv[Client]				=	KvGetNum(RPGSave, "SprLv", 0);//疾风步等级
			InfiniteAmmoLv[Client]		=	KvGetNum(RPGSave, "IALv", 0);//无限弹药等级
			BioShieldkbLv[Client]			=	KvGetNum(RPGSave, "kbzLv", 0);//炎之暴走等级
			Qhjs[Client]		=   KvGetNum(RPGSave, "qhjs", 0);
			Qhzd[Client]		=   KvGetNum(RPGSave, "qhzd", 0);
		} 
		else if(JD[Client] == 3)//狂战士
		{
			BioShieldLv[Client]			=	KvGetNum(RPGSave, "BSLv", 0);//霸体等级
			DamageReflectLv[Client]		=	KvGetNum(RPGSave, "DRLv", 0);//复仇反击等级
			MeleeSpeedLv[Client]			=	KvGetNum(RPGSave, "MSLv", 0);//近战乱舞等级
			BioShieldmissLv[Client]			=	KvGetNum(RPGSave, "BAOFALv", 0);//狂暴嗜血等级
			GeneLv[Client]				=	KvGetNum(RPGSave, "GENELV", 0);//基因改造等级
			Qhwd[Client]		=   KvGetNum(RPGSave, "qhwd", 0);
			ResetDoctor(Client);
		} 
		else if(JD[Client] == 4)//圣疗者
		{
			TeleportToSelectLv[Client]	=	KvGetNum(RPGSave, "TCLv", 0);//支援传送等级
			AppointTeleportLv[Client]	=	KvGetNum(RPGSave, "ATLv", 0);//圣光球等级
			TeleportTeamLv[Client]		=	KvGetNum(RPGSave, "TTLv", 0);//心灵传送等级
			HealingBallLv[Client]		=	KvGetNum(RPGSave, "HBLv", 0);//治疗光球等级
			TeleportTeamztLv[Client]		=	KvGetNum(RPGSave, "ztcsLv", 0);//圣之传送等级
			Qhsp[Client]		=   KvGetNum(RPGSave, "qhsp", 0);
			Qhzl[Client]		=   KvGetNum(RPGSave, "qhzl", 0);
			ResetDoctor(Client);
		} 
		else if(JD[Client] == 5)//魔法师
		{
			FireBallLv[Client]	=	KvGetNum(RPGSave, "FBLv", 0);//火球术等级
			IceBallLv[Client]	=	KvGetNum(RPGSave, "IBLv", 0);//冰球术等级
			ChainLightningLv[Client]	=	KvGetNum(RPGSave, "CLLv", 0);//电流术等级
			SatelliteCannonmissLv[Client]		=   KvGetNum(RPGSave, "baoleiLv", 0);//究极雷霆等级
			Qhhq[Client]		=   KvGetNum(RPGSave, "qhhq", 0);
			Qhbq[Client]		=   KvGetNum(RPGSave, "qhbq", 0);
			Qhls[Client]		=   KvGetNum(RPGSave, "qhls", 0);
		} 
		else if(JD[Client] == 6)//弹药专家
		{
			BrokenAmmoLv[Client]		=	KvGetNum(RPGSave, "PSDLv", 0);//破碎弹等级
			PoisonAmmoLv[Client]		=	KvGetNum(RPGSave, "SDDLv", 0);//渗毒弹等级
			SuckBloodAmmoLv[Client]	=	KvGetNum(RPGSave, "XXDLv", 0);//吸血弹等级
			AreaBlastingLv[Client]	=   KvGetNum(RPGSave, "QYBPLv", 0);//区域爆破等级
			LaserGunLv[Client]		=   KvGetNum(RPGSave, "LSJGPLv", 0);//镭射激光炮等级
			Qhps[Client]		=   KvGetNum(RPGSave, "qhps", 0);
			Qhsd[Client]		=   KvGetNum(RPGSave, "qhsd", 0);
			Qhxx[Client]		=   KvGetNum(RPGSave, "qhxx", 0);	
		} 
		else if(JD[Client] == 7)//雷神
		{
			LZDLv[Client]	=	KvGetNum(RPGSave, "ZDLv", 0);//雷子弹等级
			DCGYLv[Client]	=	KvGetNum(RPGSave, "DCLv", 0);//电磁感应等级
			YLDSLv[Client]	=	KvGetNum(RPGSave, "YLLv", 0);//引雷电术等级
		} 
		else if(JD[Client] == 8)//虚空之眼
		{
			CqdzLv[Client]	=	KvGetNum(RPGSave, "CqdzLv", 0);//虚空之怒等级
			HMZSLv[Client]		=	KvGetNum(RPGSave, "HMZSLv", 0);//电弘赤炎等级
			SPZSLv[Client]		=	KvGetNum(RPGSave, "SPZSLv", 0);//涟漪光圈等级
			GouhunLv[Client]		=	KvGetNum(RPGSave, "GouLv", 0);//幽冥暗量等级
		} 
	} else JobChooseBool[Client] = false;
	
	if(WQXT[Client] > 0)
	{
		if(WQXT[Client] == 1)//M16
		{
			JXZX[Client]			=	KvGetNum(RPGSave, "jxzx", 0);
			GZ[Client]			=	KvGetNum(RPGSave, "gz", 0);
		} 
		else if(WQXT[Client] == 2)//AK47
		{
			JXZX[Client]			=	KvGetNum(RPGSave, "jxzx", 0);
			GZ[Client]			=	KvGetNum(RPGSave, "gz", 0);
		} 
		else if(WQXT[Client] == 3)//AWP
		{
			JXZX[Client]			=	KvGetNum(RPGSave, "jxzx", 0);
			GZ[Client]			=	KvGetNum(RPGSave, "gz", 0);
		} 
		else if(WQXT[Client] == 4)//PZ
		{
			JXZX[Client]			=	KvGetNum(RPGSave, "jxzx", 0);
			GZ[Client]			=	KvGetNum(RPGSave, "gz", 0);
		} 
		else if(WQXT[Client] == 5)//M60
		{
            JXZX[Client]			=	KvGetNum(RPGSave, "jxzx", 0);
            GZ[Client]			=	KvGetNum(RPGSave, "gz", 0);
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
		else if (VIP[Client] == 3)
			I_BagSize[Client] += 8;
		else if (VIP[Client] == 4)
			I_BagSize[Client] += 10;
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
			PlayerXHItemSize[Client] += 6;
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
			PlayerZBItemSize[Client] += 3;
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
	KvSetNum(RPGSave, "QCASH", Qcash[Client]);
	KvSetNum(RPGSave, "DHJ", DHJ[Client]);
	KvSetString(RPGSave, "PW", Password[Client]);	
	KvSetNum(RPGSave, "Rwu", Renwu[Client]);
	KvSetNum(RPGSave, "Jwu", Jenwu[Client]);
	KvSetNum(RPGSave, "Pgan", Pugan[Client]);
	KvSetNum(RPGSave, "Tgan", Tegan[Client]);
	KvSetNum(RPGSave, "Tyang", TYangui[Client]);
	KvSetNum(RPGSave, "TPang", TPangzi[Client]);
	KvSetNum(RPGSave, "Tlies", TLieshou[Client]);
	KvSetNum(RPGSave, "Tkous", TKoushui[Client]);
	KvSetNum(RPGSave, "Thouz", THouzhi[Client]);
	KvSetNum(RPGSave, "Txiao", TXiaoniu[Client]);
	KvSetNum(RPGSave, "Libao", Libao[Client]);
	KvSetNum(RPGSave, "Eqbox", Eqbox[Client]);
	KvSetNum(RPGSave, "Shitou", Shitou[Client]);
	KvSetNum(RPGSave, "Shilv", Shilv[Client]);
	KvSetNum(RPGSave, "Qstr", Qstr[Client]);
	KvSetNum(RPGSave, "Txinx", TDaxinxin[Client]);
	KvSetNum(RPGSave, "Lis", Lis[Client]);
	KvSetNum(RPGSave, "LisA", LisA[Client]);
	KvSetNum(RPGSave, "LisB", LisB[Client]);
	KvSetNum(RPGSave, "TSDJ1", TSDJ1[Client]);
	KvSetNum(RPGSave, "TSDJ2", TSDJ2[Client]);
	KvSetNum(RPGSave, "TSDJ3", TSDJ3[Client]);
	KvSetNum(RPGSave, "Robot_appendage",Robot_appendage[Client]);//枪神
	KvSetNum(RPGSave, "everyday1", everyday1[Client]);  //连续签到
	KvSetNum(RPGSave, "HDZT", HDZT[Client]);//活动状态
	KvSetNum(RPGSave, "HDRW", HDRW[Client]);//活动任务
	KvSetNum(RPGSave, "Txinx1", TDaxinxin1[Client]);//活动
	KvSetNum(RPGSave, "HD1", HD1[Client]);//活动
	KvSetNum(RPGSave, "HD2", HD2[Client]);//活动
	KvSetNum(RPGSave, "HD3", HD3[Client]);//活动
	KvSetNum(RPGSave, "HD4", HD4[Client]);//活动
	KvSetNum(RPGSave, "HD5", HD5[Client]);//活动
	KvSetNum(RPGSave, "HD6", HD6[Client]);//活动
	KvSetNum(RPGSave, "Hunpo", Hunpo[Client]);//菊花
	KvSetNum(RPGSave, "Sxcs", Sxcs[Client]);
	KvSetNum(RPGSave, "QHHSZ", QHHSZ[Client]);
	KvSetNum(RPGSave, "BZBNZ", BZBNZ[Client]);
	KvSetNum(RPGSave, "YGSLZ", YGSLZ[Client]);
	KvSetNum(RPGSave, "QHSL", QHSL[Client]);
	KvSetNum(RPGSave, "BSXY", BSXY[Client]);
	KvSetNum(RPGSave, "Qhs", Qhs[Client]);   //强化石
	KvSetNum(RPGSave, "M16", M16[Client]);
	KvSetNum(RPGSave, "AK47", AK47[Client]);
	KvSetNum(RPGSave, "PZ", PZ[Client]);
	KvSetNum(RPGSave, "AWP", AWP[Client]);
	KvSetNum(RPGSave, "M60", M60[Client]);
	KvSetNum(RPGSave, "BJCH", BJCH[Client]);
	KvSetNum(RPGSave, "TKSL", TKSL[Client]);
	KvSetNum(RPGSave, "XGSL", XGSL[Client]);
	KvSetNum(RPGSave, "HZSL", HZSL[Client]);
	KvSetNum(RPGSave, "PPSL", PPSL[Client]);	
	KvSetNum(RPGSave, "PZSL", PZSL[Client]);
	KvSetNum(RPGSave, "DXSL", DXSL[Client]);
	KvSetNum(RPGSave, "NWSL", NWSL[Client]);	
	KvSetNum(RPGSave, "BRSL", BRSL[Client]);
	KvSetNum(RPGSave, "DRSL", DRSL[Client]);
	KvSetNum(RPGSave, "YGSL", YGSL[Client]);	
	KvSetNum(RPGSave, "QHSL", QHSL[Client]);	
	KvSetNum(RPGSave, "TKSLZ", TKSLZ[Client]);
	KvSetNum(RPGSave, "XGSLZ", XGSLZ[Client]);
	KvSetNum(RPGSave, "HZSLZ", HZSLZ[Client]);
	KvSetNum(RPGSave, "PPSLZ", PPSLZ[Client]);	
	KvSetNum(RPGSave, "PZSLZ", PZSLZ[Client]);
	KvSetNum(RPGSave, "DXSLZ", DXSLZ[Client]);
	KvSetNum(RPGSave, "NWSLZ", NWSLZ[Client]);	
	KvSetNum(RPGSave, "BRSLZ", BRSLZ[Client]);
	KvSetNum(RPGSave, "DRSLZ", DRSLZ[Client]);		
	KvSetNum(RPGSave, "QHHSZ", QHHSZ[Client]);
	KvSetNum(RPGSave, "BZBNZ", BZBNZ[Client]);
	KvSetNum(RPGSave, "YGSLZ", YGSLZ[Client]);
	KvSetNum(RPGSave, "XR", XR[Client]);
	KvSetNum(RPGSave, "师徒礼包", MasterReward[Client]);
	Sxqh[Client]					=	KvGetNum(RPGSave, "Sx", 0);//强化治疗术
	KvSetNum(RPGSave, "m16", M16[Client]);
	KvSetNum(RPGSave, "m60", M60[Client]);
	KvSetNum(RPGSave, "pz", PZ[Client]);
	KvSetNum(RPGSave, "awp", AWP[Client]);
	KvSetNum(RPGSave, "ak47", AK47[Client]);
	KvSetNum(RPGSave, "mstf", MSTF[Client]);
	KvSetNum(RPGSave, "xs", xstf[Client]);
	KvSetNum(RPGSave, "shixue", sxtf[Client]);
	KvSetNum(RPGSave, "nhys", NHYS[Client]);
	KvSetNum(RPGSave, "kbys", KBYS[Client]);
	KvSetNum(RPGSave, "HGLB", HGLB[Client]);//回归礼包
	
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
		
	if (Crits[Client] > 0)	//暴击
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
		
	if (HeavyGunLv[Client] > 0)
		KvSetNum(RPGSave, "HeavyGun", HeavyGunLv[Client]);
	else
		KvDeleteKey(RPGSave, "HeavyGun");
		
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "AMLv", AmmoMakingLv[Client]);
		KvSetNum(RPGSave, "MOGULv", AmmoMakingmissLv[Client]);
		KvSetNum(RPGSave, "FSLv", FireSpeedLv[Client]);
		KvSetNum(RPGSave, "SCLv", SatelliteCannonLv[Client]);
		KvSetNum(RPGSave, "qhwx", Qhwx[Client]);//强化卫星炮
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "EELv", EnergyEnhanceLv[Client]);
		KvSetNum(RPGSave, "SprLv", SprintLv[Client]);
		KvSetNum(RPGSave, "IALv", InfiniteAmmoLv[Client]);
		KvSetNum(RPGSave, "kbzLv", BioShieldkbLv[Client]);
		KvSetNum(RPGSave, "qhzd", Qhzd[Client]);//强化技能
		KvSetNum(RPGSave, "qhjs", Qhjs[Client]);
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "BSLv", BioShieldLv[Client]);
		KvSetNum(RPGSave, "DRLv", DamageReflectLv[Client]);
		KvSetNum(RPGSave, "MSLv", MeleeSpeedLv[Client]);
		KvSetNum(RPGSave, "GENELV", GeneLv[Client]);
		KvSetNum(RPGSave, "BAOFALv", BioShieldmissLv[Client]);
		KvSetNum(RPGSave, "qhwd", Qhwd[Client]);
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "TCLv", TeleportToSelectLv[Client]);
		KvSetNum(RPGSave, "ATLv", AppointTeleportLv[Client]);
		KvSetNum(RPGSave, "TTLv", TeleportTeamLv[Client]);
		KvSetNum(RPGSave, "ztcsLv", TeleportTeamztLv[Client]);
		KvSetNum(RPGSave, "HBLv", HealingBallLv[Client]);
		KvSetNum(RPGSave, "qhsp", Qhsp[Client]);
		KvSetNum(RPGSave, "qhzl", Qhzl[Client]);
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "FBLv", FireBallLv[Client]);
		KvSetNum(RPGSave, "IBLv", IceBallLv[Client]);
		KvSetNum(RPGSave, "CLLv", ChainLightningLv[Client]);
		KvSetNum(RPGSave, "baoleiLv", SatelliteCannonmissLv[Client]);
		KvSetNum(RPGSave, "qhhq", Qhhq[Client]);
		KvSetNum(RPGSave, "qhbq", Qhbq[Client]);
		KvSetNum(RPGSave, "qhls", Qhls[Client]);
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "PSDLv", BrokenAmmoLv[Client]); //破碎弹等级
		KvSetNum(RPGSave, "SDDLv", PoisonAmmoLv[Client]); //渗毒弹等级
		KvSetNum(RPGSave, "XXDLv", SuckBloodAmmoLv[Client]); //吸血弹等级
		KvSetNum(RPGSave, "QYBPLv", AreaBlastingLv[Client]); //区域爆破等级
		KvSetNum(RPGSave, "LSJGPLv", LaserGunLv[Client]); //镭射激光炮等级
		KvSetNum(RPGSave, "qhps", Qhps[Client]);
		KvSetNum(RPGSave, "qhsd", Qhsd[Client]);
		KvSetNum(RPGSave, "qhxx", Qhxx[Client]);
	}
	else if(JD[Client] == 7)
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
		KvDeleteKey(RPGSave, "CqdzLv");   //虚空之怒
		KvDeleteKey(RPGSave, "HMZSLv");   //电弘赤炎
		KvDeleteKey(RPGSave, "SPZSLv");   //涟漪光圈
		KvDeleteKey(RPGSave, "GouLv");    //幽冥暗量
		KvSetNum(RPGSave, "ZDLv", LZDLv[Client]); //雷子弹等级
		KvSetNum(RPGSave, "DCLv", DCGYLv[Client]); //电磁感应等级
		KvSetNum(RPGSave, "YLLv", YLDSLv[Client]); //引雷电术等级
	}
	else if(JD[Client] == 8)
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
		KvSetNum(RPGSave, "CqdzLv", CqdzLv[Client]); //虚空之怒等级
		KvSetNum(RPGSave, "HMZSLv", HMZSLv[Client]); //电弘赤炎等级
		KvSetNum(RPGSave, "SPZSLv", SPZSLv[Client]); //涟漪光圈等级
		KvSetNum(RPGSave, "GouLv", GouhunLv[Client]); //幽冥暗量等级
		
	}
	
	if(WQXT[Client] == 1)//M16
	{
		KvSetNum(RPGSave, "jxzx", JXZX[Client]);
		KvSetNum(RPGSave, "gz", GZ[Client]);
	} 
	else if(WQXT[Client] == 2)//AK47
	{
		KvSetNum(RPGSave, "jxzx", JXZX[Client]);
		KvSetNum(RPGSave, "gz", GZ[Client]);
	} 
	else if(WQXT[Client] == 3)//AWP
	{
		KvSetNum(RPGSave, "jxzx", JXZX[Client]);
		KvSetNum(RPGSave, "gz", GZ[Client]);
	} 
	else if(WQXT[Client] == 4)//PZ
	{
		KvSetNum(RPGSave, "jxzx", JXZX[Client]);
		KvSetNum(RPGSave, "gz", GZ[Client]);
	} 
	else if(WQXT[Client] == 5)//M60
	{
		KvSetNum(RPGSave, "jxzx", JXZX[Client]);
		KvSetNum(RPGSave, "gz", GZ[Client]);
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
			Format(numname, sizeof(numname), "(%d)迅闪2012", i);
		else
			Format(numname, sizeof(numname), "迅闪2012");
			
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