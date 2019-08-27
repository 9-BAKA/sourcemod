/************************************************************************
*	各种常量变量
************************************************************************/
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

/**********************
*	 玩家基本数据
**********************/
new MP[MAXPLAYERS+1];
#define KTLimit 6	//TK上限
new Handle:NewLifeLv;	//转生最低等级要求
#define PasswordRemindSecond 3	//密码提示间隔
#define PasswordLength 64	//最大密码长度
new bool:IsPasswordConfirm[MAXPLAYERS+1]	= {	false, ...};
new bool:IsSuperInfectedEnable[MAXPLAYERS+1];
new PasswordRemindTime[MAXPLAYERS+1];

/* 玩家真实等级 */
#define PLAYER_LV[%1]			(Lv[%1] + NewLifeCount[%1] * 150)

/* 死亡和倒地奖励惩罚 */
#define DEATH_EXP[%1]			Lv[%1] * 20
#define DEATH_CASH[%1]			Lv[%1] * 10
#define INCAP_EXP[%1]			Lv[%1] * 1.5
#define INCAP_CASH[%1]			Lv[%1] * 0.5

/**********************
*	 玩家属性
**********************/
/** 枪械强化率 **/
#define Qgl[%1] 100 - Shilv[%1]*10
#define Sbl[%1] 0 + Shilv[%1]*5
#define Jbl[%1] 0 + Shilv[%1]*5
/** 等级上限 **/
#define Limit_Lv 1000
/** 属性上限 **/
#define Limit_Str 2000
#define Limit_Agi 1000
#define Limit_Health 2500
#define Limit_Endurance 1000
#define Limit_Intelligence 2000
#define Limit_Crits 1000
#define Limit_CritMin 1000
#define Limit_CritMax 1000
/** 属性效能 **/
#define Effect_Str 0.001      //力量
#define Effect_Agi 0.001       //速度
#define Effect_Health 0.02    //生命
#define Effect_Endurance 0.005   //防御
#define Effect_MaxEndurance 0.5  //最大防御
//暴击效能
#define Effect_Crits 0.008
#define Effect_CritMin 0.005
#define Effect_CritMax 0.005
#define BasicIMP 100
#define BasicMaxMP 10000
/** 属性效果 **/
//普通属性
#define StrEffect[%1]				Str[%1]*Effect_Str
#define AgiEffect[%1]				Agi[%1]*Effect_Agi
#define HealthEffect[%1]			Health[%1]*Effect_Health
#define EnduranceEffect[%1]			(Endurance[%1] * Effect_Endurance > 0.95 ? 0.95 : Endurance[%1] * Effect_Endurance)
#define IntelligenceEffect_IMP[%1]	(BasicIMP + Lv[%1] + Intelligence[%1] / 2)   //每秒恢复MP
//暴击属性
#define CritsEffect[%1]		Crits[%1]*Effect_Crits*(1+Lis[%1]) 
#define CritMinEffect[%1]	CritMin[%1]*Effect_CritMin*(1+Lis[%1])
#define CritMaxEffect[%1]	CritMax[%1]*Effect_CritMax+CritMinEffect[%1]*(1+Lis[%1])
//MP最大值
#define MaxMP[%1]					BasicMaxMP + 250 * (Lv[%1] + Intelligence[%1]) + ZB_MPBuffer[%1]

/**********************
*	 幸存者通用技能
**********************/
new HealingCounter[MAXPLAYERS+1];

//治疗术
#define HealingEffect[%1]							5 + ZB_Healing[%1]
#define HealingDuration[%1]						10 + HealingLv[%1]
//狂暴模式关联
#define HealingkbEffect							999
#define HealingkbDuration[%1]						49 + HealingkbLv[%1]
#define HealingwxEffect							999
#define HealingwxDuration[%1]						49 + HealingwxLv[%1]
#define HealinggbdEffect							999
#define HealinggbdDuration[%1]						49 + HealinggbdLv[%1]
//地震术
#define EarthQuakeRadius[%1]				800 + 20 * EarthQuakeLv[%1]  //范围
#define EarthQuakeMaxKill[%1]				 1 * EarthQuakeLv[%1]   //击杀数量
//重机枪
#define HeavyGunMaxDmg[%1]					HeavyGunLv[%1] * 10 -5 
//强化苏醒术
#define EndranceQualityEffect[%1]				0.3 + 0.02*EndranceQualityLv[%1]



/**********************
*	 工程师
**********************/
/* 职业属性需求 */
#define JOB1_Str 15
#define JOB1_Agi 15
#define JOB1_Health 15
#define JOB1_Endurance 15
#define JOB1_Intelligence 40
new bool:IsSatelliteCannonReady[MAXPLAYERS+1];
#define SatelliteCannon_Sound_Launch		"animation/bombing_run_01.wav"
//制造子弹
#define AmmoMakingEffect[%1]					5*AmmoMakingLv[%1]  //子弹数量
#define AmmoMakingmissEffect[%1]					0
//卫星炮术
#define SatelliteCannonTKExpFactor				10
#define SatelliteCannonLaunchTime				3.0
#define SatelliteCannonDamage[%1]				Str[%1] * 2 + 100 + 200 * SatelliteCannonLv[%1]   //攻击伤害
#define SatelliteCannonSurvivorDamage[%1]		20 + SatelliteCannonLv[%1]
#define SatelliteCannonCDTime[%1]				30.0 - 0.5*SatelliteCannonLv[%1]   //冷却时间
#define SatelliteCannonRadius[%1]				300 + 25*SatelliteCannonLv[%1]     //攻击范围
#define SatelliteCannonmissTKExpFactor				10
#define SatelliteCannonmissLaunchTime				4.0
//射速加强术
#define FireSpeedEffect[%1]						0.1*FireSpeedLv[%1]    //子弹射速

/**********************
*	 生物专家 
**********************/
/* 职业属性需求 */
#define JOB2_Str 35
#define JOB2_Agi 10
#define JOB2_Health 10
#define JOB2_Endurance 35
#define JOB2_Intelligence 10
/* 火焰极速 */
new bool:IsSprintEnable[MAXPLAYERS+1];
/* 无限子弹术 */
new bool:IsInfiniteAmmoEnable[MAXPLAYERS+1];
/* 狂暴者模式 */
new ChainkbLightningLv[MAXPLAYERS+1];
new bool:IsChainkbed[MAXPLAYERS+1];
new HealingkbLv[MAXPLAYERS+1];
new HealingkbCounter[MAXPLAYERS+1];
new HealingwxLv[MAXPLAYERS+1];
new HealingwxCounter[MAXPLAYERS+1];
new HealinggbdLv[MAXPLAYERS+1];
new HealinggbdCounter[MAXPLAYERS+1];
new bool:IsBioShieldkbEnable[MAXPLAYERS+1];
new bool:IsBioShieldkbReady[MAXPLAYERS+1];
#define ChainkbLightning_Sound_launch		"music/zombat/slayer/fiddle/violin_slayer_02_01e.wav"
#define ChainkbLightning_Particle_hit		"electrical_arc_01_system"
//攻防加强术
#define EnergyEnhanceEffect_MaxEndurance[%1]	(0.004 * EnergyEnhanceLv[%1])   //防御上限
#define EnergyEnhanceEffect_Endurance[%1]		(0.0075 * EnergyEnhanceLv[%1])   //增加防御
#define EnergyEnhanceEffect_Attack[%1]			(0.016 * EnergyEnhanceLv[%1])   //增加伤害
//火焰极速
#define SprintEffect[%1]						Agi[%1] / 1500 + 0.5 + 0.01 * SprintLv[%1]    //增加比率
#define SprintDuration[%1]						5.0 + SprintLv[%1]    //持续时间
#define HealingBallInterval1[%1]						0.1          //间隔
//无限子弹术
#define InfiniteAmmoDuration[%1]				20.0 + 2.0*InfiniteAmmoLv[%1]  //持续时间
//狂暴模式关联
#define ChainkbLightningInterval[%1]				1.0                      //间隔
#define ChainkbLightningDamage[%1]				0 + 0*ChainkbLightningLv[%1]   //伤害
#define ChainkbLightningRadius[%1]				0 + 0*ChainkbLightningLv[%1]   //半径
#define ChainkbLightningLaunchRadius[%1]			170 + 50*ChainkbLightningLv[%1]   //发射半径


/**********************
*	 士兵
**********************/
/* 职业属性需求 */
#define JOB3_Str 10
#define JOB3_Agi 35
#define JOB3_Health 10
#define JOB3_Endurance 10
#define JOB3_Intelligence 35
/* 无敌术 */
new bool:IsBioShieldEnable[MAXPLAYERS+1];
new bool:IsBioShieldReady[MAXPLAYERS+1];
/* 反伤术 */
new bool:IsDamageReflectEnable[MAXPLAYERS+1];
/* 近战嗜血术 */
new bool:IsMeleeSpeedEnable[MAXPLAYERS+1];
/* 承受伤害经验 */
#define BearDmgExp[%1]						Lv[%1] / 600 + 0.1
#define BearDmgCash[%1]						Lv[%1] / 600 + 0.1
/* 潜能大暴发 */
new bool:IsBioShieldmissEnable[MAXPLAYERS+1];
new bool:IsBioShieldmissReady[MAXPLAYERS+1];
new HealingBallmissLv[MAXPLAYERS+1];
new HealingBallmissExp[MAXPLAYERS+1];
new bool:IsHealingBallmissEnable[MAXPLAYERS+1];
new Handle:HealingBallmissTimer[MAXPLAYERS+1];
//#define HealingBall_Particle			"st_elmos_fire_cp0"
#define HealingBallmiss_Particle_Effect	"st_elmos_fire_cp0"
#define HealingBallmiss_Sound_Lanuch	"ambient/fire/gascan_ignite1.wav"
#define HealingBallmiss_Sound_Heal		"buttons/bell1.wav"
new ChainmissLightningLv[MAXPLAYERS+1];
new bool:IsChainmissed[MAXPLAYERS+1];
#define ChainmissLightning_Sound_launch		"plats/churchbell_end.wav"
#define ChainmissLightning_Particle_hit		"electrical_arc_01_system"
//潜能大爆发关联
#define ChainmissLightningDamage[%1]				49999 + 1 * ChainmissLightningLv[%1]
#define ChainmissLightningRadius[%1]				0 + 0*ChainmissLightningLv[%1]
#define ChainmissLightningLaunchRadius[%1]			99998 + 1*ChainmissLightningLv[%1]


/* 武器速度 */
new WRQ[MAXPLAYERS+1];
new WRQL;
new Float:Multi[MAXPLAYERS+1];

/* 承担伤害 */
new BearDamage[MAXPLAYERS+1][MAXPLAYERS+1];

//潜能大爆发
#define BioShieldDuration[%1]					5.0 + 1.0*BioShieldLv[%1]  //持续时间
#define BioShieldCDTime[%1]						80.0 - 1.0*BioShieldLv[%1]   //冷却时间 
#define BioShieldSideEffect[%1]					0.20 + 1*BioShieldLv[%1]  //损耗比率
#define BioShieldmissDuration[%1]					0.5 + 0*BioShieldmissLv[%1]
#define BioShieldmissCDTime[%1]						400.0 - 0.0*BioShieldmissLv[%1]
#define BioShieldmissSideEffect					0
#define BioShieldkbDuration[%1]					45.0 + 5.0*BioShieldkbLv[%1]  //持续时间
#define BioShieldkbCDTime[%1]						161.0 - 1.0*BioShieldkbLv[%1]//冷却时间
#define BioShieldkbSideEffect					0
//反伤术
#define DamageReflectEffect[%1]					Endurance[%1] + 7.0 * DamageReflectLv[%1]  //反射比率
#define DamageReflectDuration[%1]				10.0 + 2.0 * DamageReflectLv[%1]  //持续时间
#define DamageReflectSideEffect[%1]				0.2 + 0.01*DamageReflectLv[%1] //损耗比率
//近战嗜血术
#define MeleeSpeedEffect[%1]					MeleeSpeedLv[%1]*0.1  //提速比率
#define MeleeSpeedDuration[%1]					20.0 + 1.0*MeleeSpeedLv[%1] //持续时间
//基因改造
#define GeneHealthEffect[%1]					20 * GeneLv[%1]   //增加生命
#define GeneEndEffect[%1]						(0.0048 * GeneLv[%1])  //格挡效果

/**********************
*	 心灵医师 
**********************/
/* 职业属性需求 */
#define JOB4_Str 5
#define JOB4_Agi 30
#define JOB4_Health 30
#define JOB4_Endurance 5
#define JOB4_Intelligence 30
/* 选择传送术 */
new bool:IsTeleportToSelectEnable[MAXPLAYERS+1];
/* 审判光球术 */
new bool:IsAppointTeleportEnable[MAXPLAYERS+1];
new LightBallReward[MAXPLAYERS+1];
/* 审判光球经验 */
#define LightBallExp							0.3
#define LightBallCash						0.08
/* 心灵传送术 */
new bool:IsTeleportTeamEnable[MAXPLAYERS+1];
/* 治疗光球术 */
new HealingBallExp[MAXPLAYERS+1];
new bool:IsHealingBallEnable[MAXPLAYERS+1];
new Handle:HealingBallTimer[MAXPLAYERS+1];
//#define HealingBall_Particle			"st_elmos_fire_cp0"
#define HealingBall_Particle_Effect	"st_elmos_fire_cp0"
#define HealingBall_Sound_Lanuch	"ambient/fire/gascan_ignite1.wav"
#define HealingBall_Sound_Heal		"buttons/bell1.wav"    //治疗光圈音效,玩家发光音效文件是;blip1.wav
/* 全体传送术 */
new bool:IsTeleportTeamztEnable[MAXPLAYERS+1];

//医师拉人增加额外经验比例
#define Job4_ExtraReward[%1]					Lv[%1] + TeleportToSelectLv[%1] + AppointTeleportLv[%1] + TeleportTeamLv[%1]

//治疗光球术
#define HealingBallInterval[%1]						1.0
#define HealingBallEffect[%1]					5 + HealingBallLv[%1] / 25
#define HealingBallRadius[%1]					200 + 10 * HealingBallLv[%1]
#define HealingBallDuration[%1]					50.0  //持续时间
#define HealingBallmissInterval						1.0
#define HealingBallmissEffect[%1]					9000
#define HealingBallmissRadius[%1]					99998 + 1*HealingBallLv[%1]   //治疗范围
#define HealingBallmissDuration[%1]					3.0 + 0*HealingBallLv[%1]
//审判光球术
#define LightBallHealth[%1]						Intelligence[%1] + AppointTeleportLv[%1] * 5 - AppointTeleportLv[%1]  //智力加成
#define LightBallDamage[%1]						AppointTeleportLv[%1] * 10 + Intelligence[%1]   //智力加成

/**********************
*	 魔法师 
**********************/
/* 职业属性需求 */
#define JOB5_Str 5
#define JOB5_Agi 5
#define JOB5_Health 5
#define JOB5_Endurance 5
#define JOB5_Intelligence 80
/* 火球术 */
new bool:FireBallCD[MAXPLAYERS+1];
#define FireBall_Model				"models/props_unique/airport/atlas_break_ball.mdl"
#define FireBall_Sound_Impact01		"ambient/fire/gascan_ignite1.wav"
#define FireBall_Sound_Impact02		"ambient/atmosphere/firewerks_burst_01.wav"
#define FireBall_Particle_Fire01	"molotov_explosion"
#define FireBall_Particle_Fire02	"gas_explosion_fireball2"
#define FireBall_Particle_Fire03	"fire_small_03"
/* 冰球术 */
new bool:IsFreeze[MAXPLAYERS+1];
new bool:IceBallCD[MAXPLAYERS+1];
#define IceBall_Sound_Impact01		"animation/van_inside_hit_wall.wav"
#define IceBall_Sound_Impact02		"ambient/explosions/explode_3.wav"
#define IceBall_Sound_Freeze		"physics/glass/glass_pottery_break3.wav"
#define IceBall_Sound_Defrost		"physics/glass/glass_sheet_break1.wav"
#define IceBall_Particle_Ice01		"pillardust_highrise"
/* 连锁闪电术 */
new bool:IsChained[MAXPLAYERS+1];
new bool:ChainLightningCD[MAXPLAYERS+1];
#define ChainLightning_Sound_launch		"ambient/energy/zap1.wav"
#define ChainLightning_Particle_hit		"electrical_arc_01_system"
/* 终结式暴雷 */
new bool:IsSatelliteCannonmissReady[MAXPLAYERS+1];
#define SatelliteCannonmissDamage[%1]				Intelligence[%1] * 1 + 85 * SatelliteCannonmissLv[%1]  //智力加成
#define SatelliteCannonmissSurvivorDamage[%1]		100 + 0*SatelliteCannonmissLv[%1]
#define SatelliteCannonmissCDTime[%1]				5.0 - 0*SatelliteCannonmissLv[%1]  //冷却时间
#define SatelliteCannonmissRadius[%1]				600.0 * SatelliteCannonmissLv[%1]  //攻击范围
#define SatelliteCannonmiss_Sound_Launch		"animation/bridge_destruct_swt_01.wav"

//火球术
#define FireIceBallLife							10.0
#define FireBallDamageInterval[%1]				1.0
#define FireBallDamage[%1]						Intelligence[%1] * 1 + 85 * FireBallLv[%1]  //燃烧伤害，智力加成
#define FireBallTKDamage[%1]					1
#define FireBallDuration[%1]					1.0 + 0 * FireBallLv[%1]  //燃烧持续
#define FireBallRadius[%1]						100 + 6 * FireBallLv[%1]   //燃烧范围
//冰球数
#define IceBallDamage[%1]						Intelligence[%1] * 1 + 4 * IceBallLv[%1]   //冰冻伤害，智力加成
#define IceBallTKDamage[%1]						1
#define IceBallDuration[%1]						5.0 + 0.3*IceBallLv[%1]  //冰冻持续
#define IceBallRadius[%1]						200 + 4*IceBallLv[%1]   //冰冻范围
//连锁闪电术
#define ChainLightningInterval[%1]				1.0
#define ChainLightningDamage[%1]				Intelligence[%1] * 1 + 100 * ChainLightningLv[%1]   // 闪电伤害，智力加成
#define ChainLightningRadius[%1]				100 + ChainLightningLv[%1]     //连锁范围
#define ChainLightningLaunchRadius[%1]			100 + 8*ChainLightningLv[%1]  //发动范围
#define ChainmissLightningInterval[%1]				1.0


/**********************
*	 弹药师 
**********************/
/* 职业属性需求 */
#define JOB6_Str 200
#define JOB6_Agi 40
#define JOB6_Health 30
#define JOB6_Endurance 30
#define JOB6_Intelligence 200

//破碎弹
new bool:Broken_Ammo[MAXPLAYERS+1] = false;

#define BrokenAmmoDamage[%1]						3 * BrokenAmmoLv[%1]  //破碎伤害
#define BrokenAmmoDuration[%1]						30.0 + 1.0 * BrokenAmmoLv[%1]   //持续时间
#define BrokenAmmoRange								80

#define LvLimit_BrokenAmmo							80


#define MP_BrokenAmmo								10000

//渗毒弹
new bool:Poison_Ammo[MAXPLAYERS+1] = false;

#define PoisonAmmoDamage[%1]						Agi[%1] / 50 > 0 ? Agi[%1] / 50 + PoisonAmmoLv[%1] : PoisonAmmoLv[%1]
#define PoisonAmmoDamageTime[%1]					1.0
#define PoisonAmmoDuration[%1]						30.0 + 1.0 * PoisonAmmoLv[%1]

#define LvLimit_PoisonAmmo							70

#define MP_PoisonAmmo								10000

//吸血弹
new bool:SuckBlood_Ammo[MAXPLAYERS+1] = false;

#define SuckBloodAmmoPBB[%1]						1.5 * SuckBloodAmmoLv[%1]   //吸血几率
#define SuckBloodAmmoDuration[%1]					30.0 + 1.0 * SuckBloodAmmoLv[%1]  //持续时间

#define SOUND_SUCKBLOOD "level/puck_slide_down.wav"

#define LvLimit_SuckBloodAmmo						50

#define MP_SuckBloodAmmo								10000

//区域爆破
new bool:AreaBlasting[MAXPLAYERS+1];

#define AreaBlastingDamage[%1]						1000 + 20 * AreaBlastingLv[%1]  //爆破伤害
#define AreaBlastingRange[%1]						200 + 10 * AreaBlastingLv[%1]  //爆破范围
#define AreaBlastingCD[%1]							15.0//冷却时间

#define LvLimit_AreaBlasting						30

#define MP_AreaBlasting								15000

//镭射激光炮
new bool:LaserGun[MAXPLAYERS+1];
//激光镭射计时
new Float:LaserGunDamagetimer[MAXPLAYERS+1];

#define LaserGunDamage[%1]							1000 * LaserGunLv[%1] //造成伤害
#define LaserGunCD[%1]								200.0 + 160.0 * LaserGunLv[%1]  //冷却时间
#define LaserGunDuration[%1]						3.0 + 1.0 * LaserGunLv[%1]

#define LvLimit_LaserGun								2

/**********************
*	 雷神
**********************/
/* 职业属性需求 */
#define JOB7_Str 40
#define JOB7_Agi 40
#define JOB7_Health 40
#define JOB7_Endurance 40
#define JOB7_Intelligence 100
#define EXPLOSIONSOUND	"animation/bombing_run_01.wav"
/* 雷神弹药*/
new bool:LZDcd[MAXPLAYERS+1];
/* 不熄光环 */
new bool:IsDCGY[MAXPLAYERS+1];
new bool:DCGYcd[MAXPLAYERS+1];
/* 虚空雷圈 */
new bool:Isylds[MAXPLAYERS+1];
new bool:yldscd[MAXPLAYERS+1];
new LZD[MAXPLAYERS+1];

//不熄光环
#define dcgyfw[%1]				370 + DCGYLv[%1]    //不熄光环范围
#define dcgyfwa[%1]				500    //不熄光环范围
#define dcgysh[%1]			970 + 1* DCGYLv[%1]    //不熄光环伤害
#define dcgysj[%1]						55.0 - 1.0 * DCGYLv[%1]  //持续时间
#define DCcd[%1]								55.0 - 1.0 * DCGYLv[%1]  //不熄光环CD时间
#define dcgyjg[%1]								1.0  //不熄光环间隔时间
#define MP_DCGY								20000

//雷神弹药
#define lzdsh[%1]			10 + 2* LZDLv[%1]   //子弹伤害
#define lzdsl[%1]			20 + 2* LZDLv[%1]   //子弹数量
#define lzdcd[%1]								60.0 - 1.0 * LZDLv[%1]  //子弹冷却时间
#define MP_LZD								10000


//虚空雷圈
#define yldssh[%1]			500 + 100* YLDSLv[%1]   //虚空雷圈伤害
#define ylds[%1]			200 + 50* YLDSLv[%1]   //虚空雷圈范围
#define yldscx[%1]								60.0 + 1.0 * YLDSLv[%1]  //虚空雷圈持续时间
#define ylcd[%1]								60.0 - 1.0 * YLDSLv[%1]  //虚空雷圈冷却时间
#define yldssj[%1]								1.0  //不熄光环间隔时间
#define MP_YLDS								30000



/**********************
*	 虚空之眼 
**********************/
/* 职业属性需求 */
#define JOB8_Str 40
#define JOB8_Agi 40
#define JOB8_Health 40
#define JOB8_Endurance 40
#define JOB8_Intelligence 100

//虚空之怒相关
#define CqdzRadius[%1]				30 + 50 * CqdzLv[%1]		
#define CqdzMaxKill[%1]				CqdzLv[%1]

//电弘赤炎
new bool:HMZSCD[MAXPLAYERS+3];
#define HMZS_Model				"models/props_unique/airport/atlas_break_ball.mdl"
#define HMZS_Sound_Impact01		"ambient/fire/gascan_ignite1.wav"
#define HMZS_Sound_Impact02		"ambient/atmosphere/firewerks_burst_01.wav"
#define HMZS_Particle_Fire01	"molotov_explosion"
#define HMZS_Particle_Fire02	"gas_explosion_fireball2"
#define HMZS_Particle_Fire03	"fire_small_03"
#define HMZSIceBallLife							10.0
#define HMZSDamageInterval[%1]				1.0
#define HMZSDamage[%1]						Intelligence[%1] * 1 + 1 * HMZSLv[%1]   //伤害
#define HMZSTKDamage[%1]					1
#define HMZSDuration[%1]					12.0 + 0.03 * HMZSLv[%1]   //持续时间
#define HMZSRadius[%1]						20 * HMZSLv[%1]   //范围

/* 涟漪光圈 */
new bool:IsSPZSed[MAXPLAYERS+1];
#define SPZS_Sound_launch		"ambient/energy/zap1.wav"
#define SPZS_Particle_hit		"electrical_arc_01_system"
#define SPZSInterval[%1]				2.0
#define SPZSDamage[%1]				Intelligence[%1] * 1 + 1 * SPZSLv[%1]
#define SPZSRadius[%1]				500 + 2 * SPZSLv[%1]
#define SPZSLaunchRadius[%1]			60 + 40*SPZSLv[%1]
#define SPZSmissInterval[%1]				1.0


/* 振幅爆炎 */
new bool:FBZNCD[MAXPLAYERS+3];
#define FBZN_Model				"models/props_unique/airport/atlas_break_ball.mdl"
#define FBZN_Sound_Impact01		"ambient/fire/gascan_ignite1.wav"
#define FBZN_Sound_Impact02		"ambient/atmosphere/firewerks_burst_01.wav"
#define FBZN_Particle_Fire01	"molotov_explosion"
#define FBZN_Particle_Fire02	"gas_explosion_fireball2"
#define FBZN_Particle_Fire03	"fire_small_03"
//振幅爆炎
#define FBZNIceBallLife							5.0
#define FBZNDamageInterval[%1]				1.0   //时间间隔
#define FBZNDamage[%1]						Intelligence[%1] * 1    //伤害
#define FBZNTKDamage[%1]					1   //TanK伤害
#define FBZNDuration[%1]					12.0 + 8    //燃烧持续
#define FBZNRadius[%1]						900   //燃烧范围

/* 振幅寒冰 */
new bool:FreefbCD[MAXPLAYERS+1];	//冰球术冷却
new bool:IsXBFB[MAXPLAYERS+1];
#define XBFB_Sound_Impact01		"animation/van_inside_hit_wall.wav"
#define XBFB_Sound_Impact02		"ambient/explosions/explode_3.wav"
#define XBFB_Sound_Freeze		"physics/glass/glass_pottery_break3.wav"
#define XBFB_Sound_Defrost		"physics/glass/glass_sheet_break1.wav"
#define XBFB_Particle_Ice01		"pillardust_highrise"
//振幅寒冰
#define XBFBDamage[%1]						Intelligence[%1] * 1 + 100 * GouhunLv[%1]   //伤害
#define XBFBTKDamage[%1]						1   //坦克伤害
#define XBFBDuration[%1]						20.0    //持续时间
#define XBFBRadius[%1]						900    //范围



/**********************
*	 技能等级上限
**********************/
#define LvLimit_Healing				50
#define LvLimit_Healingkb				2
#define LvLimit_Healingwx				2
#define LvLimit_Healinggbd				2
#define LvLimit_EndranceQuality		80
#define LvLimit_HeavyGun				20		//重机枪等级
#define LvLimit_EarthQuake		    30
#define LvLimit_AmmoMaking			40
#define LvLimit_AmmoMakingmiss			2
#define LvLimit_SatelliteCannon		30
#define LvLimit_SatelliteCannonmiss		1
#define LvLimit_FireSpeed			50
#define LvLimit_EnergyEnhance		50
#define LvLimit_Sprint				50
#define LvLimit_BioShield			30
#define LvLimit_BioShieldmiss			1
#define LvLimit_BioShieldkb			1
#define LvLimit_DamageReflect		50
#define LvLimit_MeleeSpeed			40
#define LvLimit_InfiniteAmmo		50
#define LvLimit_TeleportToSelect	40
#define LvLimit_AppointTeleport		50
#define LvLimit_TeleportTeam		40
#define LvLimit_TeleportTeamzt		2
#define LvLimit_HPRegeneration		30
#define LvLimit_SuperInfected		30
#define LvLimit_InfectedSummon		30
#define LvLimit_FireBall				50
#define LvLimit_IceBall				30
#define LvLimit_ChainLightning		30
#define LvLimit_ChainmissLightning		30
#define LvLimit_ChainkbLightning		30
#define LvLimit_LZDLv		50    //雷神弹药等级
#define LvLimit_DCGYLv		30    //不熄光环等级
#define LvLimit_YLDSLv		10    //虚空雷圈等级
#define LvLimit_Cqdz					30//虚空之怒等级
#define LvLimit_SPZS				40	//涟漪光圈等级
#define LvLimit_HMZS				30	//电弘赤炎等级
#define LvLimit_Gouhun			2	  //幽冥暗量等级
#define LvLimit_HealingBall			50
#define LvLimit_HealingBallmiss			5
#define LvLimit_Gene					100




/* 幸存者经验值 */
new Handle:JockeyKilledExp;
new Handle:HunterKilledExp;
new Handle:ChargerKilledExp;
new Handle:SmokerKilledExp;
new Handle:SpitterKilledExp;
new Handle:BoomerKilledExp;
new Handle:TankKilledExp;
new Handle:WitchKilledExp;
new Handle:ZombieKilledExp;
new Handle:TeammateKilledExp;
new Handle:ReviveTeammateExp;
new Handle:ReanimateTeammateExp;
new Handle:HealTeammateExp;

/* 幸存者金钱 */
new Handle:JockeyKilledCash;
new Handle:HunterKilledCash;
new Handle:ChargerKilledCash;
new Handle:SmokerKilledCash;
new Handle:SpitterKilledCash;
new Handle:BoomerKilledCash;
new Handle:TankKilledCash;
new Handle:WitchKilledCash;
new Handle:ZombieKilledCash;
new Handle:TeammateKilledCash;
new Handle:ReviveTeammateCash;
new Handle:ReanimateTeammateCash;
new Handle:HealTeammateCash;

/* 蘑菇云核弹 */
new nuclearamount[MAXPLAYERS+1];
new DurationTime[MAXPLAYERS+1];
new DurationTime2[MAXPLAYERS+1];
new bool:nuclearamountCD[MAXPLAYERS+1];
new Handle:Cvar_nuclearEnable, Handle:Cvar_nuclearAmount, Handle:CvarDurationTime, Handle:CvarDurationTime2, Handle:CvarDamageRadius, 
Handle:CvarCloudRadius, Handle:CvarDamageforce, Handle:CvarCloudDamage;

new hedancolor[4] = {255,0,0,255};

new Handle:timer_handle[MAXPLAYERS+1][128];
new Handle:hurtdata[MAXPLAYERS+1][128];
new Handle:Cvar_nuclearTime   = INVALID_HANDLE;

new halo;
new fire;
new white;

/* 特殊商店 */
new Handle:RemoveKTCost;//消除大过
new Handle:ResetStatusCost;//遗忘河药水
new Handle:TomeOfExpCost;//经验之书
new Handle:TomeOfExpEffect;//水晶会员

/* 彩票 */
#define	diceNumMin	1
#define	diceNumMax	35
new Handle:LotteryWeakenCommonsHpTimer = INVALID_HANDLE;

new AdminDiceNum[MAXPLAYERS+1]			=	{-1, ...};
new bool:IsGlowClient[MAXPLAYERS+1]		=	{false, ...};
new Handle:LotteryEnable;
new Handle:LotteryCost;
new Handle:LotteryRecycle;

/* 升级奖励 */
new Handle:LvUpSP;
new Handle:LvUpKSP;
new Handle:LvUpCash;

/* 升级成本 */
new Handle:LvUpExpRate;

/* 僵尸被击杀次数计算 */
new ZombiesKillCount[MAXPLAYERS+1];

/* 队友击杀次数计算 */
//new shalu[MAXPLAYERS+1];

/* 技能成本 */
new Handle:Cost_Healing;
new Handle:Cost_EarthQuake;
new Handle:Cost_AmmoMaking;
new Handle:Cost_AmmoMakingmiss;
new Handle:Cost_SatelliteCannon;
new Handle:Cost_SatelliteCannonmiss;
new Handle:Cost_Sprint;
new Handle:Cost_BioShield;
new Handle:Cost_BioShieldmiss;
new Handle:Cost_BioShieldkb;
new Handle:Cost_DamageReflect;
new Handle:Cost_MeleeSpeed;
new Handle:Cost_InfiniteAmmo;
new Handle:Cost_TeleportToSelect;
new Handle:Cost_AppointTeleport;
new Handle:Cost_TeleportTeammate;
new Handle:Cost_HealingBall;
new Handle:Cost_FireBall;
new Handle:Cost_IceBall;
new Handle:Cost_ChainLightning;
new Handle:Cost_Cqdz;   //虚空之怒施放所需MP
new Handle:Cost_HMZS;   //电弘赤炎施放所需MP
new Handle:Cost_SPZS;   //涟漪光圈施放所需MP
new Handle:Cost_FBZN;   //振幅爆炎施放所需MP
new Handle:Cost_XBFB;   //振幅寒冰施放所需MP

/* Admin选单 */
new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:Admin_GiveExp;
new TopMenuObject:Admin_GiveLv;
new TopMenuObject:Admin_ResetStatus;
new TopMenuObject:Admin_GiveCash;
new TopMenuObject:Admin_GiveDHJ;
new TopMenuObject:Admin_GiveKT;
new TopMenuObject:Admin_SetVIP;
new TopMenuObject:Admin_Hunpo;
new TopMenuObject:Admin_GiveST;
new AdminGiveAmount[MAXPLAYERS+1];
new g_id[MAXPLAYERS+1];

/* 洗点模式 */
#define General	1
#define Shop	2
#define Admin	3
#define NewLife	0

/* 玩家资讯显示模式 */
#define colored	1
#define simple	2

/* 其他 */
new Handle:BindMode				=	INVALID_HANDLE;
new Handle:ShowMode				=	INVALID_HANDLE;
new Handle:GiveAnnonce			=	INVALID_HANDLE;

/* 上弹 */
new S_rActiveW		= -1;
new S_rStartDur		= -1;
new S_rInsertDur	= -1;
new S_rEndDur		= -1;
new S_rPlayRate		= -1;
new s_rTimeIdle		= -1;
new S_rNextPAtt		= -1;
new s_rNextAtt		= -1;

/* 购物商店 */
new Handle:CfgNormalItemShopEnable;
new Handle:CfgSelectedGunShopEnable;
new Handle:CfgMeleeShopEnable;
/* Number of Normal Items */
#define NORMALITEMMAX 15
/* Number of Selected Guns */
#define SELECTEDGUNMAX 9
/* Number of Selected Melees */
#define SELECTEDMELEEMAX 13
/* Number of Robot */
#define ROBOTMAX 17
new String:WeaponName[ROBOTMAX][]={ "猎枪","M16突击步枪","战术散弹枪", "散弹枪", "乌兹冲锋枪", "手枪", "麦格农手枪","AK47",
"SCAR步枪", "SG552步枪", "铬钢散弹枪", "战斗散弹枪", "自动式狙击枪", "SCOUT轻型狙弹枪", "AWP麦格农狙击枪", "MP5冲锋枪", "灭音冲锋枪"};

/*会员购买区域*/
#define sm_setvip "%" "1" "30"=白银会员30日%金钱

/* 商品价格 */
new Handle:CfgNormalItemCost[NORMALITEMMAX];
new Handle:CfgSelectedGunCost[SELECTEDGUNMAX];
new Handle:CfgMeleeCost[SELECTEDMELEEMAX];
new Handle:CfgRobotCost[ROBOTMAX];
/* 音效 */
#define TSOUND			"ui/critical_event_1.wav"
#define EQSOUND		"animation/bombing_run_01.wav"
/* 圈圈顏色 */
new CyanColor[4] 	= {0, 255, 255, 255};

new SkyblueColor[4]	  = {136, 205, 236, 255};  //天蓝
new PlumredColor[4]	  = {221, 160, 221, 255};  //梅红色
new steelblueeColor[4]	  = {070, 130, 180, 255};  //钢蓝色
new mediumorchidColor[4]	  = {186, 085, 211, 255};  //间紫色
new deeppinkColor[4]	  = {255, 020, 147, 255};  //深粉色
new cornflowerblueColor[4]	  = {100, 149, 237, 255};  //菊蓝色
new orangeredColor[4]	  = { 255, 071, 000, 255};  //橘红色
new RedColor[4]		= {255, 80, 80, 255};
new WhiteColor[4]	= {255, 255, 255, 255};
new BlueColor[4]	= {80, 80, 255, 255};
new YellowColor[4]	= {255, 255, 0, 255};
new ClaretColor[4]	= {255, 0, 0, 255};  //红葡萄酒
new GreenColor[4]		= { 0, 128, 5, 255};

new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

#define SOUND_TRACING	"items/suitchargeok1.wav"
#define SOUND_TRACINGMISS	"ambient/weather/thunderstorm/lightning_strike_4.wav"

/*粒子 */
#define PARTICLE_EARTHQUAKEEFFECT	"awning_collapse"
#define PARTICLE_INFECTEDSUMMON	"electrical_arc_01_parent"
#define PARTICLE_SCEFFECT	"gen_hit_up"
#define PARTICLE_HLEFFECT	"embers_medium_03"

#define DamageDisplayBuffer 5
#define DamageDisplayLength 64
#define ALIVE 0
#define NORMALDEAD 1
#define HEADSHOT 2
new DamageToTank[MAXPLAYERS+1][MAXPLAYERS+1];
new String:DamageDisplayString[MAXPLAYERS+1][DamageDisplayBuffer][DamageDisplayLength];
new LastDamage[MAXPLAYERS+1];

/************ Robot设置 ************/
#define SOUNDCLIPEMPTY	"weapons/ClipEmpty_Rifle.wav"
#define SOUNDRELOAD		"weapons/shotgun/gunother/shotgun_load_shell_2.wav"
#define SOUNDREADY		"weapons/shotgun/gunother/shotgun_pump_1.wav"

#define WEAPONCOUNT 17

#define SOUND0 "weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav"
#define SOUND1 "weapons/rifle/gunfire/rifle_fire_1.wav"
#define SOUND2 "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav"
#define SOUND3 "weapons/shotgun/gunfire/shotgun_fire_1.wav"
#define SOUND4 "weapons/SMG/gunfire/smg_fire_1.wav"
#define SOUND5 "weapons/pistol/gunfire/pistol_fire.wav"
#define SOUND6 "weapons/magnum/gunfire/magnum_shoot.wav"
#define SOUND7 "weapons/rifle_ak47/gunfire/rifle_fire_1.wav"
#define SOUND8 "weapons/rifle_desert/gunfire/rifle_fire_1.wav"
#define SOUND9 "weapons/sg552/gunfire/sg552-1.wav"
#define SOUND10 "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav"
#define SOUND11 "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav"
#define SOUND12 "weapons/sniper_military/gunfire/sniper_military_fire_1.wav"
#define SOUND13 "weapons/scout/gunfire/scout_fire-1.wav"
#define SOUND14 "weapons/awp/gunfire/awp1.wav"
#define SOUND15 "weapons/mp5navy/gunfire/mp5-1.wav"
#define SOUND16 "weapons/smg_silenced/gunfire/smg_fire_1.wav"

#define MODEL0 "weapon_hunting_rifle"
#define MODEL1 "weapon_rifle"
#define MODEL2 "weapon_autoshotgun"
#define MODEL3 "weapon_pumpshotgun"
#define MODEL4 "weapon_smg"
#define MODEL5 "weapon_pistol"
#define MODEL6 "weapon_pistol_magnum"
#define MODEL7 "weapon_rifle_ak47"
#define MODEL8 "weapon_rifle_desert"
#define MODEL9 "weapon_rifle_sg552"
#define MODEL10 "weapon_shotgun_chrome"
#define MODEL11 "weapon_shotgun_spas"
#define MODEL12 "weapon_sniper_military"
#define MODEL13 "weapon_sniper_scout"
#define MODEL14 "weapon_sniper_awp"
#define MODEL15 "weapon_smg_mp5"
#define MODEL16 "weapon_smg_silenced"

/* 粒子 */
#define PARTICLE_BLOOD	"blood_impact_infected_01"

new String:SOUND[WEAPONCOUNT+3][70]=
{SOUND0, SOUND1, SOUND2, SOUND3, SOUND4, SOUND5, SOUND6, SOUND7,SOUND8,SOUND9, SOUND10, SOUND11,SOUND12,SOUND13,SOUND14, SOUND15,SOUND16,SOUNDCLIPEMPTY, SOUNDRELOAD, SOUNDREADY};

new String:MODEL[WEAPONCOUNT][32]=
{MODEL0, MODEL1, MODEL2, MODEL3, MODEL4, MODEL5,MODEL6, MODEL7,MODEL8,MODEL9,MODEL10, MODEL11, MODEL12 ,MODEL13,MODEL14, MODEL15, MODEL16};

new Float:fireinterval[WEAPONCOUNT]={0.25, 0.068, 0.30, 0.65, 0.060, 0.20, 0.33, 0.145, 0.14, 0.064, 0.65, 0.30, 0.265, 0.9, 1.25, 0.065, 0.055};
new Float:bulletaccuracy[WEAPONCOUNT]={1.15, 1.4, 3.5, 3.5, 1.6, 1.7 , 1.7, 1.5, 1.6, 1.5, 3.5, 3.5, 1.15, 1.00, 0.8, 1.6 ,1.6};
new Float:weaponbulletdamage[WEAPONCOUNT]={90.0, 30.0, 25.0, 30.0, 20.0, 30.0, 60.0, 70.0, 40.0, 40.0, 30.0, 30.0, 90.0, 100.0, 150.0, 35.0, 35.0};
new weaponclipsize[WEAPONCOUNT]={15, 50, 10, 8, 50, 30, 8, 40, 20, 50, 8, 10, 30, 15, 20, 50, 50};
new weaponbulletpershot[WEAPONCOUNT]={1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 7, 7,1, 1, 1,1,1};
new Float:weaponloadtime[WEAPONCOUNT]={2.0, 1.5, 0.3, 0.3, 1.5, 1.5, 1.9, 1.5, 1.5, 1.6, 0.3, 0.3, 2.0,2.0, 2.0, 1.5, 1.5};
new weaponloadcount[WEAPONCOUNT]={15, 50, 1,1, 50, 30, 8, 40, 60, 50, 1, 1, 30, 15, 20, 50, 50};
new bool:weaponloaddisrupt[WEAPONCOUNT]={false,false, true, true,false,false, false, false, false, true, true, false, false, false, false, false};

new robot[MAXPLAYERS+1];
new robot_clone[MAXPLAYERS+1];
new keybuffer[MAXPLAYERS+1];
new keybuffer_clone[MAXPLAYERS+1];
new weapontype[MAXPLAYERS+1];
new bullet[MAXPLAYERS+1];
new bullet_clone[MAXPLAYERS+1];
new Float:firetime[MAXPLAYERS+1];
new Float:firetime_clone[MAXPLAYERS+1];
new bool:reloading[MAXPLAYERS+1];
new bool:reloading_clone[MAXPLAYERS+1];
new Float:reloadtime[MAXPLAYERS+1];
new Float:reloadtime_clone[MAXPLAYERS+1];
new Float:scantime[MAXPLAYERS+1];
new Float:scantime_clone[MAXPLAYERS+1];
new Float:walktime[MAXPLAYERS+1];
new Float:walktime_clone[MAXPLAYERS+1];
new Float:botenerge[MAXPLAYERS+1];
new Float:botenerge_clone[MAXPLAYERS+1];

new SIenemy[MAXPLAYERS+1];
new CIenemy[MAXPLAYERS+1];

new SIenemy_clone[MAXPLAYERS+1];
new CIenemy_clone[MAXPLAYERS+1];

new Float:robotangle[MAXPLAYERS+1][3];	//机器人角度

new Handle:RobotReactiontime = INVALID_HANDLE;
new Handle:RobotEnergy = INVALID_HANDLE;		//机器人能量
new Handle:CfgRobotUpgradeCost[3] = INVALID_HANDLE;

new Float:robot_reactiontime;
new Float:robot_energy;

new bool:robot_gamestart = false;
new bool:robot_gamestart_clone = false;

new RobotCount[MAXPLAYERS+1];

/* 感染者CLASS */
#define CLASS_SMOKER		1
#define CLASS_BOOMER		2
#define CLASS_HUNTER		3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY		5
#define CLASS_CHARGER	6
#define CLASS_WITCH		7
#define CLASS_TANK		8

#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

/* 超级坦克类型 */
#define TANK1		1
#define TANK2		2
#define TANK3		3
#define TANK4		4
#define TANK5		5

#define MOLOTOV 		0
#define EXPLODE 		1

#define MODEL_DLCTANK	"models/infected/hulk_dlc3.mdl"
#define MODEL_TANK	"models/infected/hulk.mdl"

/* 超级坦克音效 */
#define SOUND_EXPLODE	"animation/bombing_run_01.wav"
#define SOUND_SPAWN		"music/pzattack/contusion.wav"
#define SOUND_BCLAW		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW		"plats/churchbell_end.wav"
#define SOUND_DCLAW		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE		"player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL		"physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_CHANGE	"items/suitchargeok1.wav"
#define SOUND_HOWL		"player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_WARP		"ambient/energy/zap9.wav"
#define SOUND_ABS			"level/coaster_loop03.wav"

/* 超级坦克粒子特效 */
#define PARTICLE_SPAWN	"gas_explosion_fireball2"   //开始坦克粒子特效
#define PARTICLE_DEATH	"gas_explosion_fireball2"            //死亡坦克粒子特效
#define PARTICLE_THIRD	"gas_explosion_fireball2"            //第三坦克粒子特效
#define PARTICLE_FORTH	"gas_explosion_fireball2"    //第四坦克粒子特效
#define PARTICLE_WARP	"gas_explosion_fireball2"       //瞬移粒子特效

new bool:IsRoundEnded;

new Handle:SpawnTimer    		= INVALID_HANDLE;
new Handle:CheckTimer    		= INVALID_HANDLE;

/* Timers设置 */
new Handle:ZombiesKillCountTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:CheckExpTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:HealingTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:HealingkbTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:HealingwxTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:HealinggbdTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:SprinDurationTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:InfiniteAmmoDurationTimer[MAXPLAYERS+1]		= {	INVALID_HANDLE, ...};
new Handle:BioShieldDurationTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:BioShieldCDTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:BioShieldmissDurationTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:BioShieldmissCDTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:BioShieldkbDurationTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:BioShieldkbCDTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:DamageReflectDurationTimer[MAXPLAYERS+1]		= {	INVALID_HANDLE, ...};
new Handle:MeleeSpeedDurationTimer[MAXPLAYERS+1]		= {	INVALID_HANDLE, ...};
new Handle:FadeBlackTimer[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};
new Handle:TCChargingTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:TTChargingTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:TTChargingztTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};
new Handle:SatelliteCannonCDTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:SatelliteCannonmissCDTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:DamageDisplayCleanTimer[MAXPLAYERS+1]		= {	INVALID_HANDLE, ...};
new Handle:DCGYTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};
new Handle:yldsTimer[MAXPLAYERS+1]			= {	INVALID_HANDLE, ...};

/* Sprite */
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"
#define SPRITE_HALO		"materials/sprites/halo01.vmt"
#define SPRITE_GLOW		"materials/sprites/glow01.vmt"

new g_BeamSprite;
new g_HaloSprite;
new g_GlowSprite;

#define LASERMODE_NORMAL	0
#define LASERMODE_VARTICAL	1

new String:LogPath[256];

//不输入密码超时计算参数
new pwtimeout[MAXPLAYERS+1];
new Handle:cv_pwtimeout;
//加载地图卡住计算参数
new connectkicktime[MAXPLAYERS+1];
new Handle:cv_loadtimeout;
//MP恢复药水价格
new Handle:ResumeMP;
//人数上限
new Handle:cv_survivor_limit;
new Handle:cv_infected_limit;
//VIP经验金钱加成参数
new Handle:cv_vipexp;
new Handle:cv_vipcash;
new Handle:cv_vipbuy;
new Handle:cv_vippropsA;
new Handle:cv_vippropsB;
new Handle:cv_vippropsC;
new Handle:cv_vippropsD;
//VIP免费补给
new vip_item[MAXPLAYERS+1];
//首次注册赠送金钱
new Handle:cv_firtsreg;
//VIP名字保存
new String:VipName[MAXPLAYERS+1][MAX_NAME_LENGTH];
/* 医生防刷电击 */
new String:DoctorName[MAXPLAYERS+1][MAX_NAME_LENGTH];
//禁止改名
new String:PlayerName[MAXPLAYERS+1][MAX_NAME_LENGTH];

#define CRIT_SOUND "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav" //暴击音效

/** 超级坦克参数 **/
//难度平衡参数
new Handle:rpg_gamedifficulty	 			= INVALID_HANDLE;


//帝王坦克出现几率
new Handle:sm_supertank_bossratio	 		= INVALID_HANDLE;
new Handle:sm_supertank_bossrange	 		= INVALID_HANDLE;

//超级坦克生命值
new Handle:sm_supertank_health_max	 		= INVALID_HANDLE;
new Handle:sm_supertank_health_second 		= INVALID_HANDLE;
new Handle:sm_supertank_health_third	 	= INVALID_HANDLE;
new Handle:sm_supertank_health_forth	 	= INVALID_HANDLE;
new Handle:sm_supertank_health_boss	 	= INVALID_HANDLE;
new SuperTank_Health[6];
new Float:SuperTank_Warp;

//超级坦克生颜色
new Handle:sm_supertank_color_first 	 	= INVALID_HANDLE;
new Handle:sm_supertank_color_second	 	= INVALID_HANDLE;
new Handle:sm_supertank_color_third 	 	= INVALID_HANDLE;
new Handle:sm_supertank_color_forth		= INVALID_HANDLE;
new Handle:sm_supertank_color_boss			= INVALID_HANDLE;

//超级坦克速度
new Handle:sm_supertank_speed[6] 	 		= INVALID_HANDLE;

//超级坦克护甲
new Handle:sm_supertank_armor_tank[6]		= INVALID_HANDLE;

//超级坦克技能参数
new Handle:sm_supertank_weight_second		= INVALID_HANDLE;
new Handle:sm_supertank_stealth_third 		= INVALID_HANDLE;
new Handle:sm_supertank_gravityinterval 	= INVALID_HANDLE;
new Handle:sm_supertank_quake_radius 		= INVALID_HANDLE;
new Handle:sm_supertank_quake_force	 	= INVALID_HANDLE;
new Handle:sm_supertank_dreadinterval 		= INVALID_HANDLE;
new Handle:sm_supertank_dreadrate	 		= INVALID_HANDLE;
new Handle:sm_supertank_warp_interval		= INVALID_HANDLE;
//超级坦克吸星大法
new Handle:sm_supertank_xixing_range	 	= INVALID_HANDLE;
new Handle:sm_supertank_xixing_interval	= INVALID_HANDLE;
new Handle:sm_supertank_xixing_abs			= INVALID_HANDLE;
new Handle:sm_supertank_xixing_dread		= INVALID_HANDLE;
new Handle:sm_supertank_xixing_slowspeed	= INVALID_HANDLE;
new Handle:sm_supertank_xixing_slowtime	= INVALID_HANDLE;

//超级坦克平衡
new Handle:sm_supertank_tankbalance 		= INVALID_HANDLE;

//超级坦克抵消伤害总值
new TankOffsetDmg[MAXPLAYERS+1][MAXPLAYERS+1];

//坦克伤害抵消几率
new Float:TankOffsetRadio;

/* Timer Handle */
new Handle:TimerUpdate[MAXPLAYERS+1] = INVALID_HANDLE;

/* Grobal */
new alpharate[MAXPLAYERS+1];
new visibility[MAXPLAYERS+1];
new tanktype[MAXPLAYERS+1];

/* 吸星大法 */
new Xixing[MAXPLAYERS+1];
new Float:PlayerSpeed[MAXPLAYERS+1];

//瞬移计时器
new Handle:Timer_FatalMirror[MAXPLAYERS+1];

//武器classname
new String:t_Gun[17][64] = { "weapon_autoshotgun", "weapon_autoshotgun", "weapon_hunting_rifle", "weapon_pumpshotgun", "weapon_rifle", "weapon_rifle_ak47", "weapon_rifle_desert", "weapon_rifle_m60", "weapon_rifle_sg552", "weapon_shotgun_chrome", "weapon_shotgun_spas", "weapon_smg", "weapon_smg_mp5", "weapon_smg_silenced", "weapon_sniper_awp", "weapon_sniper_military", "weapon_sniper_scout"};
new String:t_Bomb[3][64] = { "weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar" };
new String:t_Medic[4][64] = { "weapon_adrenaline", "weapon_defibrillator", "weapon_first_aid_kit", "weapon_pain_pills" };
//武器classname
//new String:t_Gun[17][64] = { "weapon_autoshotgun", "weapon_grenade_launcher", "weapon_hunting_rifle", "weapon_pumpshotgun", "weapon_rifle", "weapon_rifle_ak47", "weapon_rifle_desert", "weapon_rifle_m60", "weapon_rifle_sg552", "weapon_shotgun_chrome", "weapon_shotgun_spas", "weapon_smg", "weapon_smg_mp5", "weapon_smg_silenced", "weapon_sniper_awp", "weapon_sniper_military", "weapon_sniper_scout"};
//new String:t_Bomb[3][64] = { "weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar" };
//new String:t_Medic[4][64] = { "weapon_adrenaline", "weapon_defibrillator", "weapon_first_aid_kit", "weapon_pain_pills" };
//new String:t_Other[3][64] = { "upgrade_ammo_explosive", "upgrade_ammo_incendiary" , "weapon_ammo_spawn" };
//new String:t_Melee[12][64] = { "baseball_bat", "cricket_bat" , "crowbar", "electric_guitar", "fireaxe", "frying_pan", "katana", "machete", "tonfa", "knife", "riotshield", "golfclub" };

//商店武器变量
new String:GunName[SELECTEDGUNMAX][]={ "MP5冲锋枪","Scout轻型狙击枪",
"AWP重型狙击枪","SG552突击步枪","M60机枪","榴弹发射器", "AK47", "战斗散弹枪", "M16"};

new String:MeleeName[SELECTEDMELEEMAX][]={ "棒球棍", "板球棍", "铁撬", "电吉他",
"斧头", "平底锅", "高尔夫球棍", "武士刀", "海豹匕首", "斩马刀", "盾牌", "警棍", "警棍"};

new String:NormalItemName[NORMALITEMMAX][]={ "子弹", "红外线", "高爆弹", "燃烧弹", "药包", "药丸", "肾上腺素", "电击器", "燃烧瓶", "土制炸弹","胆汁", "高爆子弹盒", "燃烧子弹盒", "氧气瓶", "煤气瓶"};

/* Robot工场*/
new String:RobotUpgradeName[3][]={ "提升攻击力(目前等级: %d/%d, 所需费用: %d)", "提升弹匣系统(目前等级: %d/%d, 所需费用: %d)", "提升侦察距离(目前等级: %d/%d, 所需费用: %d)"};
new String:RobotUpgradeInfo[3][]={ "目前攻击力系数: %.2f", "目前弹匣量系数: %.2f", "目前侦察距离: %d"};
new RobotUpgradeLimit[3]={50, 50, 20};
#define RobotAttackEffect[%1]	0.5 + 0.025*RobotUpgradeLv[%1][0]
#define RobotAmmoEffect[%1]		1.0 + 0.1*RobotUpgradeLv[%1][1]
#define RobotRangeEffect[%1]	500 + 25*RobotUpgradeLv[%1][2]

//Robot变量
new Float:lasttime=0.0;
new button;
new Float:robotpos[3];
new Float:robotpos_clone[3];
new Float:robotvec[3];
new Float:robotvec_clone[3];
new Float:Clienteyepos[3];
new Float:Clientangle[3];
new Float:enemypos[3];
new Float:infectedorigin[3];
new Float:infectedeyepos[3];
new Float:chargetime;
new Float:chargetime_clone;

//旁观计时踢出
new KickLookOnPlayer[MAXPLAYERS+1];

//服务器最大人数
new Handle:cv_MaxPlayer;
new ServerPlayerLimit;

//普感生命值
new oldCommonHp;

//VIP设置变量
new viptarget;
new viptype;



//枪械强化伤害
#define DMG_LVD				10
//枪械伤害
#define DMG_AK47				45
#define DMG_M60				25
#define DMG_M16				32
#define DMG_MP5				20
#define DMG_SPAS				14
#define DMG_CHROME			8 
#define DMG_AUTOSHOTGUN		1
#define DMG_PUMPSHOTGUN		1
#define DMG_HUNTING		    55
#define DMG_SCOUT			    75
#define DMG_AWP				80
#define DMG_GL				130
#define DMG_SMG				25
#define DMG_SMG_S			    23
#define DMG_MAGNUM			45

#define NAME_AK47				"rifle_ak47"
#define NAME_M60				"rifle_m60"
#define NAME_M16				"rifle"
#define NAME_MP5				"smg_mp5"
#define NAME_SPAS				"shotgun_spas"
#define NAME_CHROME			"shotgun_chrome"
#define NAME_AUTOSHOTGUN		"autoshotgun"
#define NAME_PUMPSHOTGUN		"pumpshotgun"
#define NAME_HUNTING			"hunting_rifle"
#define NAME_SCOUT			"sniper_scout"
#define NAME_AWP				"sniper_awp"
#define NAME_GL				"grenade_launcher"
#define NAME_SMG				"smg"
#define NAME_SMG_S			"smg_silenced"
#define NAME_MAGNUM			"pistol_magnum"

//近战伤害
#define DMG_MELEE[%1]				100 + 1 * Str[%1]

//加密文件
/*
new Handle:PW_File;
new String:PW_Path[256];
new String:PW_Data[256];
*/

/* 回合坦克数量控制 */
new RoundTankLimit = 6;   //极限
new RoundTankNum = 0;

/* 大乐透 */
#define	DLT_MaxNum		24

new DLTNum[MAXPLAYERS+1];
new DLTCash[34];
new Float:DLT_Timer;
new Handle:DLT_Handle = INVALID_HANDLE;

/* 玩家轮廓状态 */
new PlayerGlowType[MAXPLAYERS+1];

#define NewLifeSKP[%1]		(NewLifeCount[%1] + 1) * 100
#define NewLifeSP[%1]		(NewLifeCount[%1] + 1) * 20
#define NewLifeGiveSKP[%1]		NewLifeCount[%1] * 100
#define NewLifeGiveSP[%1]		NewLifeCount[%1] * 20

/* bot计时器 */
new Handle:Handle_BotTimer;

/* 新人保护变量 */
//玩家总等级高于多少给予新人BUFF
#define RookieBuff_MaxLv		10
//低于多少级给予新人BUFF
#define RookieBuff_MinLv		50
//新人BUFF增加血量
#define RookieBuff_Health	500	
//新人BUFF增加移动速度
#define RookieBuff_Speed		0.3
//保存已有BUFF玩家
new bool:HasBuffPlayer[MAXPLAYERS+1];

/* 每日签到 */
#define SIGNAWARD_EXP[%1]		400 + 25 * Lv[%1]
#define SIGNAWARD_CASH[%1]		200 + 5 * Lv[%1]

new String:BotCheck[MAXPLAYERS+1][32];

/* 监视器 */
//new bool:entercp[MAXPLAYERS+1];    //安全门
//new bool:watching[MAXPLAYERS+1];  //监视
//new Handle:watchingtimer[MAXPLAYERS+1];  //监视定时器
//new bool:Showing[MAXPLAYERS+1];

#define SOUND_JS   "ui/survival_teamrec.wav"     //SOUND = 求生音效文件夹

new EveryDaySign[MAXPLAYERS+1];

/* 运行时间检测 */
#define RUNTIME_SEC	0
#define RUNTIME_MIN	1
new Handle:HD_ServerRuningTime;
new ServerRuningTime[2];

new Handle:hTimerAchieved[MAXPLAYERS+1];
new Handle:hTimerMiniFireworks[MAXPLAYERS+1];
new Handle:hTimerLoopEffect[MAXPLAYERS+1];

#define SOUND_GOOD					"level/gnomeftw.wav"