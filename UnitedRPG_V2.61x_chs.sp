#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <adminmenu>
#include <sdkhooks>
//RPGINC
#include "rpg_msgs.inc"
#include "rpg_constant.inc"
#include "rpg_savesx.inc"
#include "rpg_other.inc"
#include "rpg_bot.inc"
#include "rpg_supertank.inc"
#include "rpg_bag.inc"
#include "rpg_item.inc"
#include "rpg_vip.inc"
#include "rpg_melee.inc"
#include "rpg_chenghao.inc"
#include "rpg_master1.inc"  //师徒
#include "rpg_tf.inc"  //天赋
#include "rpg_lucky.inc"  //礼物盒子
#include "rpg_qhjn.inc"  //强化技能
#include "rpg_wq.inc"  //强化枪械

#define PLUGIN_VERSION "2.61x"

public Plugin:myinfo=
{
	name = "United RPG 战役专用",
	author = "Pan Xiaohai, Mortiegama, 蛋疼哥 & Max Chu & 蛋疼",
	description = "United RPG",
	version = PLUGIN_VERSION,
	url = ""
};

#define TEAM_SURVIVORS 1
#define TEAM_INFECTED 2

public OnPluginStart()
{
	decl String:Game_Name[64];
	GetGameFolderName(Game_Name, sizeof(Game_Name));
	if(!StrEqual(Game_Name, "left4dead2", false))
		SetFailState("United RPG%d插件仅支持L4D2!", PLUGIN_VERSION);
	
	/* 加密检查 */
	/*
	BuildPath(Path_SM, PW_Path, 255, "gamedata/core.games/l4d2_7sh.txt");
	if (FileExists(PW_Path))
	{
		PW_File = OpenFile(PW_Path, "rb");
		if (PW_File != INVALID_HANDLE)
		{
			ReadFileLine(PW_File, PW_Data, sizeof(PW_Data));
			if (!StrEqual(PW_Data, "CshHuaZi695362077"))
				SetFailState("插件检查到你非法使用该插件,将强制卸载!");
		}
		else
			SetFailState("插件检查到你非法使用该插件,将强制卸载!");
	}
	else
		SetFailState("插件检查到你非法使用该插件,将强制卸载!");
	*/
	//存档初始化设置
	LoadRPGData();

	CreateConVar("United_RPG_Version", PLUGIN_VERSION, "United RPG 插件版本", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);

	LoadTranslations("common.phrases");

	RegisterCvars();
	RegisterCmds();
	HookEvents();
	GetConVar();
	
	gConf = LoadGameConfigFile("United_RPG");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();

	/* 生成CFG */
	AutoExecConfig(true, "United_RPG");

	HookConVarChange(RobotReactiontime, ConVarChange);
	HookConVarChange(RobotEnergy, ConVarChange);
	//难度平衡Convar
	HookConVarChange(sm_supertank_health_max, ConVarChange);
	HookConVarChange(sm_supertank_health_second, ConVarChange);
	HookConVarChange(sm_supertank_health_third, ConVarChange);
	HookConVarChange(sm_supertank_health_forth, ConVarChange);
	HookConVarChange(sm_supertank_health_boss, ConVarChange);
	HookConVarChange(sm_supertank_warp_interval, ConVarChange);
	//监视
	//HookEvent("player_entered_checkpoint",Event_player_entercp);  //玩家进入安全门  
	//HookEvent("player_spawn",Event_player_spawn);   //创建玩家人物
	//HookEvent("player_jump",Event_player_jump);  //玩家跳跃次数
	//HookEvent("player_team",Event_player_team);	  //玩家队伍
	//RegConsoleCmd("sm_adminjump",CmdKill);
	//RegConsoleCmd("sm_mt",CmdWatching);  //监视，一直弹出监视信息
	
	robot_gamestart = false;
	robot_gamestart_clone = false;
	new String:date[21];
	/* Format date for log filename */
	FormatTime(date, sizeof(date), "%d%m%y", -1);
	/* Create name of logfile to use */
	BuildPath(Path_SM, LogPath, sizeof(LogPath), "logs/unitedrpg%s.log", date);

	/* 上弹系统 */
	S_rActiveW		=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	S_rStartDur  	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	S_rInsertDur	 =	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	S_rEndDur		  =	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	S_rPlayRate		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	s_rTimeIdle		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	S_rNextPAtt		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	s_rNextAtt		=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	
	//获取服务器最大人数
	cv_MaxPlayer = FindConVar("sv_maxplayers");
		
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
	
	//服务器运行时间
	if (HD_ServerRuningTime == INVALID_HANDLE)
		HD_ServerRuningTime = CreateTimer(1.0, Timer_ServerRuningTime, _, TIMER_REPEAT);
}

RegisterCvars()
{
	/* 幸存者经验值 */
	JockeyKilledExp					= CreateConVar("rpg_GainExp_Kill_Jockey",				"50",	"击杀Jockey获得的经验值", CVAR_FLAGS, true, 0.0);
	HunterKilledExp					= CreateConVar("rpg_GainExp_Kill_hunter",				"100",	"击杀Hunter获得的经验值", CVAR_FLAGS, true, 0.0);
	ChargerKilledExp				= CreateConVar("rpg_GainExp_Kill_Charger",				"100",	"击杀Charger获得的经验值", CVAR_FLAGS, true, 0.0);
	SmokerKilledExp					= CreateConVar("rpg_GainExp_Kill_Smoker",				"50",	"击杀Smoker获得的经验值", CVAR_FLAGS, true, 0.0);
	SpitterKilledExp				= CreateConVar("rpg_GainExp_Kill_Spitter",				"50",	"击杀Spitter获得的经验值", CVAR_FLAGS, true, 0.0);
	BoomerKilledExp					= CreateConVar("rpg_GainExp_Kill_Boomer",				"50",	"击杀Boomer获得的经验值", CVAR_FLAGS, true, 0.0);
	TankKilledExp					= CreateConVar("rpg_GainExp_Kill_Tank",					"0.1",	"击杀Tank每一伤害获得的经验值", CVAR_FLAGS, true, 0.0);
	WitchKilledExp					= CreateConVar("rpg_GainExp_Kill_Witch",				"150",	"击杀Witch惩罚的经验值", CVAR_FLAGS, true, 0.0);
	ZombieKilledExp					= CreateConVar("rpg_GainExp_Kill_Zombie",				"1",	"击杀普通丧尸获得的经验值", CVAR_FLAGS, true, 0.0);
	ReviveTeammateExp				= CreateConVar("rpg_GainExp_Revive_Teammate",			"50",	"拉起队友获得的经验值", CVAR_FLAGS, true, 0.0);
	ReanimateTeammateExp			= CreateConVar("rpg_GainExp_Reanimate_Teammate",		"200",	"电击器复活队友获得的经验值", CVAR_FLAGS, true, 0.0);
	HealTeammateExp					= CreateConVar("rpg_GainExp_Survivor_Heal_Teammate",	"100",	"帮队友治疗获得的经验值", CVAR_FLAGS, true, 0.0);
	TeammateKilledExp				= CreateConVar("rpg_GainExp_Kill_Teammate",				"1000",	"幸存者误杀队友扣除的经验值", CVAR_FLAGS, true, 0.0);

	/* 幸存者金钱 */
	JockeyKilledCash				= CreateConVar("rpg_GainCash_Kill_Jockey",				"20",	"击杀Jockey获得的金钱", CVAR_FLAGS, true, 0.0);
	HunterKilledCash				= CreateConVar("rpg_GainCash_Kill_hunter",				"25",	"击杀Hunter获得的金钱", CVAR_FLAGS, true, 0.0);
	ChargerKilledCash				= CreateConVar("rpg_GainCash_Kill_Charger",				"25",	"击杀Charger获得的金钱", CVAR_FLAGS, true, 0.0);
	SmokerKilledCash				= CreateConVar("rpg_GainCash_Kill_Smoker",				"20",	"击杀Smoker获得的金钱", CVAR_FLAGS, true, 0.0);
	SpitterKilledCash				= CreateConVar("rpg_GainCash_Kill_Spitter",				"20",	"击杀Spitter获得的金钱", CVAR_FLAGS, true, 0.0);
	BoomerKilledCash				= CreateConVar("rpg_GainCash_Kill_Boomer",				"15",	"击杀Boomer获得的金钱", CVAR_FLAGS, true, 0.0);
	TankKilledCash					= CreateConVar("rpg_GainCash_Kill_Tank",				"0.1",	"击杀Tank每一伤害获得的金钱", CVAR_FLAGS, true, 0.0);
	WitchKilledCash					= CreateConVar("rpg_GainCash_Kill_Witch",				"100",	"击杀Witch惩罚的金钱", CVAR_FLAGS, true, 0.0);
	ZombieKilledCash				= CreateConVar("rpg_GainCash_Kill_Zombie",				"1",	"击杀普通丧尸获得的金钱", CVAR_FLAGS, true, 0.0);
	ReviveTeammateCash				= CreateConVar("rpg_GainCash_Revive_Teammate",			"20",	"拉起队友获得的金钱", CVAR_FLAGS, true, 0.0);
	ReanimateTeammateCash			= CreateConVar("rpg_GainCash_Reanimate_Teammate",		"100",	"电击器复活队友获得的金钱", CVAR_FLAGS, true, 0.0);
	HealTeammateCash				= CreateConVar("rpg_GainCash_Survivor_Heal_Teammate",	"35",	"帮队友治疗获得的金钱", CVAR_FLAGS, true, 0.0);
	TeammateKilledCash				= CreateConVar("rpg_GainCash_Kill_Teammate",			"1000",	"幸存者误杀队友扣除的金钱", CVAR_FLAGS, true, 0.0);

	/* 关於升级 */
	LvUpSP						= CreateConVar("rpg_LvUp_SP",		"5",	"升级获得的属性点", CVAR_FLAGS, true, 0.0);
	LvUpKSP					= CreateConVar("rpg_LvUp_KSP",		"1",	"升级获得的技能点", CVAR_FLAGS, true, 0.0);
	LvUpCash					= CreateConVar("rpg_LvUp_Cash",		"1000",	"升级获得的金钱", CVAR_FLAGS, true, 0.0);
	LvUpExpRate				= CreateConVar("rpg_LvUp_Exp_Rate",	"800",	"升级Exp系数: 升级经验=升级系Exp数*(当前等级+1)", CVAR_FLAGS, true, 1.0);
	NewLifeLv					= CreateConVar("rpg_NewLife_Lv",	"120",	"转生所需等级", CVAR_FLAGS, true, 1.0);
	/*  蘑菇云核弹 */
	CvarDurationTime			= CreateConVar("L4D2_nuclear_Duration_Time",  "9",   " 核弹引爆时间 ", FCVAR_PLUGIN);
	CvarDurationTime2			= CreateConVar("L4D2_nuclear_Duration_Time2", "5",   " 核污染持续时间 ", FCVAR_PLUGIN);
	Cvar_nuclearEnable		= CreateConVar("L4D2_nuclear_enabled",	"1",	" 开启关闭核弹插件 ", FCVAR_PLUGIN);
	Cvar_nuclearAmount		= CreateConVar("L4D2_nuclear_amount",	"1",  " 出生时给玩家多少个核弹 ", FCVAR_PLUGIN);
	Cvar_nuclearTime			= CreateConVar("L4D2_nuclear_time",	"20.0", " 核污染蘑菇云持续时间 ", FCVAR_PLUGIN);
	CvarDamageRadius			= CreateConVar("L4D2_nuclear_DamageRadius",   "300", " 核弹爆炸范围 ", FCVAR_PLUGIN);
	CvarCloudRadius			= CreateConVar("L4D2_nuclear_DamageRadius",   "300", " 蘑菇云辐射范围 ", FCVAR_PLUGIN);
	CvarDamageforce			= CreateConVar("L4D2_nuclear_Damageforce",	"50000", " 核弹爆发威力 ", FCVAR_PLUGIN);
	CvarCloudDamage	 		= CreateConVar("L4D2_nuclear_CouldDamage",	"5",	" 蘑菇云辐射伤害 ", FCVAR_PLUGIN);

	/*  关於属性技能点 */
	Cost_Healing				= CreateConVar("rpg_MPCost_Healing",			"200",		"使用治疗术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_EarthQuake			= CreateConVar("rpg_Cost_EarthQuake",	"200",	"使用地震术所MP", CVAR_FLAGS, true, 0.0);
	Cost_AmmoMaking			= CreateConVar("rpg_MPCost_MakingAmmo",			"200",		"使用制造子弹术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_AmmoMakingmiss		= CreateConVar("rpg_MPCost_MakingAmmomiss",			"200",		"使用暗夜核爆所需MP", CVAR_FLAGS, true, 0.0);
	Cost_SatelliteCannon		= CreateConVar("rpg_MPCost_SatelliteCannon",	"200",	"使用卫星炮所需MP", CVAR_FLAGS, true, 0.0);
	Cost_SatelliteCannonmiss	= CreateConVar("rpg_MPCost_SatelliteCannonmiss",	"200",	"使用暗夜暴雷所需MP", CVAR_FLAGS, true, 0.0);
	Cost_Sprint				= CreateConVar("rpg_MPCost_Sprint",				"200",		"使用暴走所需MP", CVAR_FLAGS, true, 0.0);
	Cost_BioShield			= CreateConVar("rpg_MPCost_BionicShield",		"200",	"使用无敌术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_BioShieldmiss		= CreateConVar("rpg_MPCost_BionicShieldmiss",		"200",	"使用潜能大爆发所需MP", CVAR_FLAGS, true, 0.0);
	Cost_BioShieldkb			= CreateConVar("rpg_MPCost_BionicShieldkb",		"200",	"使用狂暴者模式所需MP", CVAR_FLAGS, true, 0.0);
	Cost_DamageReflect		= CreateConVar("rpg_MPCost_DamageReflect",		"200",	"使用反伤术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_MeleeSpeed			= CreateConVar("rpg_MPCost_MeleeSpeed",			"200",	"使用近战嗜血术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_InfiniteAmmo			= CreateConVar("rpg_MPCost_InfiniteAmmo",		"200",		"使用无限子弹术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_TeleportToSelect	= CreateConVar("rpg_MPCost_TeleportToSelect",	"200",		"使用选择传送术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_AppointTeleport		= CreateConVar("rpg_MPCost_AppointTeleport",	"200",		"使用审判光球术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_TeleportTeammate	= CreateConVar("rpg_MPCost_TeleportTeammate",	"200",	"使用心灵传送术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_HealingBall			= CreateConVar("rpg_MPCost_HealingBall",		"200",	"使用治疗光球术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_FireBall				= CreateConVar("rpg_MPCost_FireBall",			"200",		"使用火球术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_IceBall				= CreateConVar("rpg_MPCost_IceBall",			"200",		"使用冰球术所需MP", CVAR_FLAGS, true, 0.0);
	Cost_ChainLightning		= CreateConVar("rpg_MPCost_ChainLightning",		"200",	"使用连锁闪电所需MP", CVAR_FLAGS, true, 0.0);
	Cost_Cqdz		= CreateConVar("rpg_MPCost_Cqdz",	"500",	"使用虚空之怒所MP", CVAR_FLAGS, true, 0.0);	
	Cost_HMZS		= CreateConVar("rpg_MPCost_HMZS",	"500",	"使用电弘赤炎所需MP", CVAR_FLAGS, true, 0.0);
	Cost_SPZS		= CreateConVar("rpg_MPCost_SPZS",	"500",	"使用涟漪光圈所需MP", CVAR_FLAGS, true, 0.0);
	Cost_FBZN		= CreateConVar("rpg_MPCost_FBZN",	"800",	"使用振幅爆炎所需MP", CVAR_FLAGS, true, 0.0);
	Cost_XBFB		= CreateConVar("rpg_MPCost_XBFB",	"1000",	"使用振幅寒冰所需MP", CVAR_FLAGS, true, 0.0);

	CfgNormalItemShopEnable	= CreateConVar("rpg_Shop_normal_items_enable",		"1",	"是否允许投掷品，药物和子弹盒购物选单 1=是 0=否", CVAR_FLAGS, true, 0.0, true, 1.0);
	CfgSelectedGunShopEnable	= CreateConVar("rpg_Shop_selected_gun__enable",		"1",	"是否允许许特选枪械购物商店 1=是 0=否", CVAR_FLAGS, true, 0.0, true, 1.0);
	CfgMeleeShopEnable		= CreateConVar("rpg_Shop_selected_melee_enable",	"1",	"是否允许近战武器购物商店 1=是 0=否", CVAR_FLAGS, true, 0.0, true, 1.0);

	/* Normal Items Cost*/
	CfgNormalItemCost[0]		= CreateConVar("rpg_ShopCost_Normal_Items_00","200","补充子弹的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[1]		= CreateConVar("rpg_ShopCost_Normal_Items_01","300","红外线的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[2]		= CreateConVar("rpg_ShopCost_Normal_Items_02","500","高爆弹的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[3]		= CreateConVar("rpg_ShopCost_Normal_Items_03","500","燃烧弹的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[4]		= CreateConVar("rpg_ShopCost_Normal_Items_04","2000","药包的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[5]		= CreateConVar("rpg_ShopCost_Normal_Items_05","1000","药丸的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[6]		= CreateConVar("rpg_ShopCost_Normal_Items_06","1000","肾上腺素针的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[7]		= CreateConVar("rpg_ShopCost_Normal_Items_07","2000","电击器的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[8]		= CreateConVar("rpg_ShopCost_Normal_Items_08","9999999","燃烧瓶的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[9]		= CreateConVar("rpg_ShopCost_Normal_Items_09","650","土製炸弹的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[10]	= CreateConVar("rpg_ShopCost_Normal_Items_10","700","胆汁的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[11]	= CreateConVar("rpg_ShopCost_Normal_Items_11","2000","高爆子弹盒的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[12]	= CreateConVar("rpg_ShopCost_Normal_Items_12","2000","燃烧子弹盒的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[13]	= CreateConVar("rpg_ShopCost_Normal_Items_13","500","氧气瓶的价钱", CVAR_FLAGS, true, 0.0);
	CfgNormalItemCost[14]	= CreateConVar("rpg_ShopCost_Normal_Items_14","100","煤气罐的价钱", CVAR_FLAGS, true, 0.0);

	/* Selected Guns Cost*/
	CfgSelectedGunCost[0]	= CreateConVar("rpg_ShopCost_Selected_Guns_00","1200","MP5冲锋枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[1]	= CreateConVar("rpg_ShopCost_Selected_Guns_01","1200","Scout轻型狙击枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[2]	= CreateConVar("rpg_ShopCost_Selected_Guns_02","2400","Awp重型狙击枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[3]	= CreateConVar("rpg_ShopCost_Selected_Guns_03","1200","Sg552突击步枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[4]	= CreateConVar("rpg_ShopCost_Selected_Guns_04","1500","M60重型机枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[5]	= CreateConVar("rpg_ShopCost_Selected_Guns_05","2500","榴弹发射器的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[6]	= CreateConVar("rpg_ShopCost_Selected_Guns_06","1500","AK47的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[7]	= CreateConVar("rpg_ShopCost_Selected_Guns_07","1200","战斗散弹枪的价钱", CVAR_FLAGS, true, 0.0);
	CfgSelectedGunCost[8]	= CreateConVar("rpg_ShopCost_Selected_Guns_08","1500","M16的价钱", CVAR_FLAGS, true, 0.0);
	
	/* Selected Melees Cost*/
	CfgMeleeCost[0]			= CreateConVar("rpg_ShopCost_Selected_Melees_00","1250","棒球棍的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[1]			= CreateConVar("rpg_ShopCost_Selected_Melees_01","1225","板球棍的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[2]			= CreateConVar("rpg_ShopCost_Selected_Melees_02","1225","铁撬的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[3]			= CreateConVar("rpg_ShopCost_Selected_Melees_03","1300","电结他的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[4]			= CreateConVar("rpg_ShopCost_Selected_Melees_04","1300","斧头的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[5]			= CreateConVar("rpg_ShopCost_Selected_Melees_05","1250","平底锅的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[6]			= CreateConVar("rpg_ShopCost_Selected_Melees_06","1250","高尔夫球棍的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[7]			= CreateConVar("rpg_ShopCost_Selected_Melees_07","1575","武士刀的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[8]			= CreateConVar("rpg_ShopCost_Selected_Melees_08","1466","CS小刀的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[9]			= CreateConVar("rpg_ShopCost_Selected_Melees_09","1425","开山刀的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[10]			= CreateConVar("rpg_ShopCost_Selected_Melees_10","1250","盾牌的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[11]			= CreateConVar("rpg_ShopCost_Selected_Melees_11","1067","警棍的价钱", CVAR_FLAGS, true, 0.0);
	CfgMeleeCost[12]			= CreateConVar("rpg_ShopCost_Selected_Melees_12","1500","电锯的价钱", CVAR_FLAGS, true, 0.0);

	/* Robot成本*/
	CfgRobotCost[0]			= CreateConVar("rpg_ShopCost_Robot_00","2000","[猎枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[1]			= CreateConVar("rpg_ShopCost_Robot_01","2000","[M16突击步枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[2]			= CreateConVar("rpg_ShopCost_Robot_02","2000","[战术散弹枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[3]			= CreateConVar("rpg_ShopCost_Robot_03","1500","[散弹枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[4]			= CreateConVar("rpg_ShopCost_Robot_04","1500","[乌兹冲锋枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[5]			= CreateConVar("rpg_ShopCost_Robot_05","1000","[手枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[6]			= CreateConVar("rpg_ShopCost_Robot_06","1500","[麦格农手枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[7]			= CreateConVar("rpg_ShopCost_Robot_07","2000","[AK47]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[8]			= CreateConVar("rpg_ShopCost_Robot_08","2000","[SCAR步枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[9]			= CreateConVar("rpg_ShopCost_Robot_09","2000","[SG552步枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[10]			= CreateConVar("rpg_ShopCost_Robot_10","2000","[铬钢散弹枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[11]			= CreateConVar("rpg_ShopCost_Robot_11","2000","[战斗散弹枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[12]			= CreateConVar("rpg_ShopCost_Robot_12","2000","[自动式狙击枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[13]			= CreateConVar("rpg_ShopCost_Robot_13","2000","[SCOUT轻型狙弹枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[14]			= CreateConVar("rpg_ShopCost_Robot_14","1500","[AWP麦格农狙击枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[15]			= CreateConVar("rpg_ShopCost_Robot_15","1500","[MP5冲锋枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotCost[16]			= CreateConVar("rpg_ShopCost_Robot_16","1500","[灭音冲锋枪]Robot每次使用增加的价钱", CVAR_FLAGS, true, 0.0);

	/* 特殊商店*/
	RemoveKTCost				= CreateConVar("rpg_ShopCost_Special_Remove_KT",	"10000",	"消除一次大过的价钱", CVAR_FLAGS, true, 0.0);
	ResetStatusCost			= CreateConVar("rpg_ShopCost_Special_Reset_Status",	"50000",	"漂白剂的价钱", CVAR_FLAGS, true, 0.0);
	TomeOfExpCost				= CreateConVar("rpg_ShopCost_Special_Tome_Of_Exp",	"50000",	"经验之书的价钱", CVAR_FLAGS, true, 0.0);
	TomeOfExpEffect			= CreateConVar("rpg_Special_Tome_Of_Exp_Effect",	"10000",		"使用经验之书增加多少EXP", CVAR_FLAGS, true, 0.0);
	ResumeMP			= CreateConVar("rpg_Special_Tome_Of_Resume_MP",	"10000",		"蓝瓶药水价钱", CVAR_FLAGS, true, 0.0);
	
	/* 彩票卷 */
	LotteryEnable				= CreateConVar("rpg_Lottery_Enable",	"1",	"是否开啟彩票功能(0:OFF 1:ON)", CVAR_FLAGS, true, 0.0, true, 1.0);
	LotteryCost				= CreateConVar("rpg_Lottery_Cost",		"2000",	"彩票卷单价", CVAR_FLAGS, true, 0.0);
	LotteryRecycle			= CreateConVar("rpg_Lottery_Recycle",	"0.8",	"回收彩票卷的价钱=售价x倍率(0.0~1.0)", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	/* Robot Config */
	RobotReactiontime			= CreateConVar("rpg_RobotConfig_Reactiontime",	"0.3",	"Robot反应时间", CVAR_FLAGS, true, 0.1);
 	RobotEnergy				= CreateConVar("rpg_RobotConfig_Rnergy", 		"60.0",	"Robot能量维持时间(分钟)", CVAR_FLAGS, true, 0.1);
	CfgRobotUpgradeCost[0]	= CreateConVar("rpg_RobotUpgradeCost_0",		"5000",	"升级Robot攻击力的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotUpgradeCost[1]	= CreateConVar("rpg_RobotUpgradeCost_1",		"5000",	"升级Robot弹匣系统的价钱", CVAR_FLAGS, true, 0.0);
	CfgRobotUpgradeCost[2]	= CreateConVar("rpg_RobotUpgradeCost_2",		"5000",	"升级Robot侦查距离的价钱", CVAR_FLAGS, true, 0.0);

	/* 其他 */
	BindMode					= CreateConVar("rpg_BindMode", 						"2",	"玩家进入服务器是否自动绑定键位 0-不绑定 1-提示绑定 2-不提示自动绑定", CVAR_FLAGS, true, 0.0, true, 2.0);
	ShowMode					= CreateConVar("rpg_ShowMode", 						"1",	"公屏聊天时是否在游戏名前显示等级信息 0-不显示 1-显示", CVAR_FLAGS, true, 0.0, true, 1.0);
	GiveAnnonce					= CreateConVar("rpg_AdminGiveAnnonce", 				"0",	"是否显示管理给予玩家经验值/LV等信息 0-不显示 1-显示", CVAR_FLAGS, true, 0.0, true, 1.0);
	//密码超时
	cv_pwtimeout				= CreateConVar("rpg_cv_pwtimeout",				"0",	"进入游戏后多少秒内不输入密码将踢出服务器(0 = 禁用)", CVAR_FLAGS);
	cv_loadtimeout				= CreateConVar("rpg_cv_loadtimeout",				"0",	"加载地图时,卡住多少秒踢出(0 = 禁用)", CVAR_FLAGS);
	//人数上限
	cv_survivor_limit			= CreateConVar("rpg_cv_survivor_limit",				"8",	"幸存者上限(自动创建bot)", CVAR_FLAGS);
	cv_infected_limit			= CreateConVar("rpg_cv_infected_limit",				"0",	"感染者上限(不是对抗模式不用修改)", CVAR_FLAGS);
	//VIP系统
	cv_vipexp					= CreateConVar("rpg_vipexp",				"1",	"是否开启VIP经验加成(1 = 开启 0 = 禁用)", CVAR_FLAGS);
	cv_vipcash					= CreateConVar("rpg_vipcash",				"1",	"是否开启VIP金钱加成(1 = 开启 0 = 禁用)", CVAR_FLAGS);
	cv_firtsreg					= CreateConVar("cv_firtsreg",				"100000",	"首次注册赠送金钱(0 = 禁用)", CVAR_FLAGS);
	cv_vipbuy					= CreateConVar("rpg_vipbuy",				"1",	"是否开启VIP商店打折(1 = 开启 0 = 禁用)", CVAR_FLAGS);
	cv_vippropsA					= CreateConVar("rpg_vipropsA",				"2",	"白金VIP1的每回合免费补给数量", CVAR_FLAGS);
	cv_vippropsB					= CreateConVar("rpg_vipropsB",				"4",	"黄金VIP2的每回合免费补给数量", CVAR_FLAGS);
	cv_vippropsC					= CreateConVar("rpg_vipropsC",				"6",	"水晶VIP3的每回合免费补给数量", CVAR_FLAGS);
	cv_vippropsD					= CreateConVar("rpg_vipropsD",				"15",	"至尊VIP4的每回合免费补给数量", CVAR_FLAGS);
	
	
	/* 帝王坦克 */
	sm_supertank_bossratio	  = CreateConVar("sm_supertank_bossratio",   "20.0", "帝王坦克出现几率(默认是5/100)",	CVAR_FLAGS);
	sm_supertank_bossrange	  = CreateConVar("sm_supertank_bossrange",   "20.0", "帝王坦克屏幕抖动影响范围",	CVAR_FLAGS);
	
	/* 超级坦克生命值 */
	sm_supertank_health_max	  = CreateConVar("sm_supertank_health_max",   "220000", "超级坦克第一阶段生命值", CVAR_FLAGS);
	sm_supertank_health_second = CreateConVar("sm_supertank_health_second","190000", "超级坦克第二阶段生命值", CVAR_FLAGS);
	sm_supertank_health_third  = CreateConVar("sm_supertank_health_third", "140000", "超级坦克第三阶段生命值", CVAR_FLAGS);
	sm_supertank_health_forth  = CreateConVar("sm_supertank_health_forth", "60000",  "超级坦克第四阶段生命值", CVAR_FLAGS);
	sm_supertank_health_boss		= CreateConVar("sm_supertank_health_boss", "260000",  "帝王坦克生命值", CVAR_FLAGS);
	
	/* 超级坦克颜色 */
	sm_supertank_color_first	  = CreateConVar("sm_supertank_color_first", "245 222 120", "超级坦克第一阶段颜色(0-255)", CVAR_FLAGS);
	sm_supertank_color_second  = CreateConVar("sm_supertank_color_second","80 255 80", "超级坦克第二阶段颜色(0-255)", CVAR_FLAGS);
	sm_supertank_color_third	  = CreateConVar("sm_supertank_color_third", "80 80 255", "超级坦克第三阶段颜色(0-255)", CVAR_FLAGS);
	sm_supertank_color_forth	  = CreateConVar("sm_supertank_color_forth", "255 80 80", "超级坦克第四阶段颜色(0-255)", CVAR_FLAGS);
	sm_supertank_color_boss	  = CreateConVar("sm_supertank_color_boss", "10 10 10", "帝王坦克颜色(0-255)", CVAR_FLAGS);
	
	/* 超级坦克速度 */
	sm_supertank_speed[TANK1]		= CreateConVar("sm_supertank_speed_1",  "1.1", "超级坦克第一阶段速度倍率",  CVAR_FLAGS);
	sm_supertank_speed[TANK2]		= CreateConVar("sm_supertank_speed_2", "1.2", "超级坦克第二阶段速度倍率", CVAR_FLAGS);
	sm_supertank_speed[TANK3]		= CreateConVar("sm_supertank_speed_3",  "1.4", "超级坦克第三阶段速度倍率",  CVAR_FLAGS);
	sm_supertank_speed[TANK4]		= CreateConVar("sm_supertank_speed_4",  "1.6", "超级坦克第四阶段速度倍率",  CVAR_FLAGS);
	sm_supertank_speed[TANK5]		= CreateConVar("sm_supertank_speed_5",  "1.7", "帝王坦克速度倍率",  CVAR_FLAGS);
	
	/* 超级坦克技能 */
	sm_supertank_weight_second		= CreateConVar("sm_supertank_weight_second", "15.0", "增加坦克多少重力(第二阶段)", CVAR_FLAGS);
	sm_supertank_stealth_third		= CreateConVar("sm_supertank_stealth_third", "10.0", "多少秒后进入完全隐形技能(第三阶段)", CVAR_FLAGS);
	sm_supertank_gravityinterval		= CreateConVar("sm_supertank_gravityinterval", "10.0", "重力技能使用间隔(第二阶段)", CVAR_FLAGS);
	sm_supertank_quake_radius		= CreateConVar("sm_supertank_quake_radius", "600.0", "地震技能影响范围(全部阶段)", CVAR_FLAGS);
	sm_supertank_quake_force			= CreateConVar("sm_supertank_quake_force", "350.0", "地震技能威力(全部阶段)", CVAR_FLAGS);
	sm_supertank_dreadinterval		= CreateConVar("sm_supertank_dreadinterval", "10.0", "致盲技能使用间隔(第三阶段)", CVAR_FLAGS);
	sm_supertank_dreadrate			= CreateConVar("sm_supertank_dreadrate", "100", "致盲技能的致盲程度(第三阶段)", CVAR_FLAGS);
	sm_supertank_warp_interval		= CreateConVar("sm_supertank_warp_interval", "30.0", "坦克瞬移使用间隔(全部阶段,不建议修改,太慢会导致卡TANK自杀)", CVAR_FLAGS);
	
	/* 超级坦克吸星大法 */
	sm_supertank_xixing_range			= CreateConVar("sm_supertank_xixing_range", "500.0", "吸星大法吸取范围(半径)", CVAR_FLAGS);
	sm_supertank_xixing_interval		= CreateConVar("sm_supertank_xixing_interval", "33", "吸星大法使用间隔(0.0 = 瞬移后使用)", CVAR_FLAGS);
	sm_supertank_xixing_abs				= CreateConVar("sm_supertank_xixing_abs", "450.0", "吸星大法_震击强度(第二阶段)", CVAR_FLAGS);
	sm_supertank_xixing_dread			= CreateConVar("sm_supertank_xixing_dread", "5.0", "吸星大法_致盲持续时间(第四阶段)", CVAR_FLAGS);
	sm_supertank_xixing_slowspeed	 	= CreateConVar("sm_supertank_xixing_slowspeed",   "0.4", "吸星大法_减速后的速度倍率",CVAR_FLAGS);
	sm_supertank_xixing_slowtime	 	= CreateConVar("sm_supertank_xixing_slowtime",   "5.0", "吸星大法_减速持续的时间",CVAR_FLAGS);
	
	//超级坦克护甲
	sm_supertank_armor_tank[TANK1] 			= CreateConVar("sm_supertank_armor_tank1",   "0.7", "超级坦克第一阶段护甲系数",CVAR_FLAGS);
	sm_supertank_armor_tank[TANK2] 			= CreateConVar("sm_supertank_armor_tank2",   "0.7", "超级坦克第二阶段护甲系数",CVAR_FLAGS);
	sm_supertank_armor_tank[TANK3] 			= CreateConVar("sm_supertank_armor_tank3",   "0.7", "超级坦克第三阶段护甲系数",CVAR_FLAGS);
	sm_supertank_armor_tank[TANK4] 			= CreateConVar("sm_supertank_armor_tank4",   "0.7", "超级坦克第四阶段护甲系数",CVAR_FLAGS);
	sm_supertank_armor_tank[TANK5] 			= CreateConVar("sm_supertank_armor_tank5",   "0.7", "帝王坦克护甲系数",CVAR_FLAGS);
	
	/* 坦克平衡 */
	sm_supertank_tankbalance	 			= CreateConVar("sm_supertank_tankbalance",   "1000", "幸存者等级高于感染者等级多少增加一只坦克",    CVAR_FLAGS);
	
	/* 难度平衡 */
	rpg_gamedifficulty	 			= CreateConVar("rpg_gamedifficulty",   "0", "是否启用难度自动平衡", CVAR_FLAGS);
}
RegisterCmds()
{
	/* RPG主选单 */
	RegConsoleCmd("sm_rpgmenu",	Menu_RPG);
	RegConsoleCmd("sm_rpg",		Menu_RPG);
	RegConsoleCmd("say",		Command_Say);
	RegConsoleCmd("say_team",	Command_SayTeam);
	/* 分配属性 */
	RegConsoleCmd("sm_str",	AddStrength);
	RegConsoleCmd("sm_agi",	AddAgile);
	RegConsoleCmd("sm_hea",	AddHealth);
	RegConsoleCmd("sm_end",	AddEndurance);
	RegConsoleCmd("sm_int",	AddIntelligence);
	//RegConsoleCmd("sm_cts",	AddCrits);  暴击
	//RegConsoleCmd("sm_ctn",	AddCritMin);
	//RegConsoleCmd("sm_ctx",	AddCritMax);
	/* 技能 */
	RegConsoleCmd("sm_useskill",	Menu_UseSkill);
	RegConsoleCmd("sm_hl",			UseHealing);
	RegConsoleCmd("sm_dizhen",	UseEarthQuake);
	RegConsoleCmd("sm_am",			UseAmmoMaking);
	RegConsoleCmd("sm_mogu",			UseAmmoMakingmiss);
	RegConsoleCmd("sm_sc",			UseSatelliteCannon);
	RegConsoleCmd("sm_baolei",			UseSatelliteCannonmiss);
	RegConsoleCmd("sm_sp",			UseSprint);
	RegConsoleCmd("sm_ia",			UseInfiniteAmmo);
	RegConsoleCmd("sm_bs",			UseBioShield);
	RegConsoleCmd("sm_baofa",			UseBioShieldmiss);
	RegConsoleCmd("sm_kbz",			UseBioShieldkb);
	RegConsoleCmd("sm_dr",			UseDamageReflect);
	RegConsoleCmd("sm_ms",			UseMeleeSpeed);
	RegConsoleCmd("sm_ts",			UseTeleportToSelect);
	RegConsoleCmd("sm_at",			UseAppointTeleport);
	RegConsoleCmd("sm_tt",			UseTeleportTeam);
	RegConsoleCmd("sm_ztcs",			UseTeleportTeamzt);
	RegConsoleCmd("sm_fb",			UseFireBall);
	RegConsoleCmd("sm_ib",			UseIceBall);
	RegConsoleCmd("sm_cl",			UseChainLightning);
	RegConsoleCmd("sm_dbfgle",			UseChainmissLightning);
	RegConsoleCmd("sm_hb",			UseHealingBall);
	RegConsoleCmd("sm_dbfgl",			UseHealingBallmiss);
	RegConsoleCmd("sm_psd",			UseBrokenAmmo);
	RegConsoleCmd("sm_sdd",			UsePoisonAmmo);
	RegConsoleCmd("sm_xxd",			UseSuckBloodAmmo);
	RegConsoleCmd("sm_qybp",			UseAreaBlasting);
	RegConsoleCmd("sm_lsjgp",		UseLaserGun);
	//RegConsoleCmd("sm_lzd", Command_Show1);
	RegConsoleCmd("sm_dcgy", Command_Show2);
	RegConsoleCmd("sm_ylds", Command_Show3);
	RegConsoleCmd("sm_xkzn", Usexkzn);
	RegConsoleCmd("sm_dhcy", Usedhcy);
	RegConsoleCmd("sm_lygq", Uselygq);
	/* 购物商店 */
	RegConsoleCmd("buymenu",			Menu_Buy);
	RegConsoleCmd("rpgbuy",			Menu_Buy);
	RegConsoleCmd("normalitem",		Menu_NormalItemShop);
	RegConsoleCmd("selectedgun",	Menu_SelectedGunShop);
	RegConsoleCmd("selectedmelee",	Menu_MeleeShop);
	RegConsoleCmd("robotshop",		Menu_RobotShop);
	RegConsoleCmd("viewskill",		Menu_ViewSkill);
	/*  密码 */
	RegConsoleCmd("sm_rpgpw",		EnterPassword,"sm_rpgpw 密码");
	RegConsoleCmd("sm_pw",		EnterPassword,"sm_pw 密码");
	RegConsoleCmd("sm_rpgresetpw",	ResetPassword,"sm_rpgresetpw 原来密码 新的密码");
	RegConsoleCmd("sm_rpgpwinfo",	Passwordinfo);  //密码资讯
	/*  队友资讯 */
	RegConsoleCmd("sm_wanjia", Command_playerlistpanel);
	/* Admins */
	RegAdminCmd("sm_giveQcash_451",	Command_GiveExp, ADMFLAG_KICK, "sm_giveQcash_451 玩家名字 数量"); //给予点卷
	RegAdminCmd("sm_givelv_114",	Command_GiveLevel, ADMFLAG_KICK, "sm_givelv_114 玩家名字 数量"); //给予等级
	RegAdminCmd("sm_givecash_994",	Command_GiveCash, ADMFLAG_KICK, "sm_givecash_994 玩家名字 数量"); //给予金钱
	RegAdminCmd("sm_giveDhj_118",	Command_GiveDHJ, ADMFLAG_KICK, "sm_giveDhj_118 玩家名字 数量");  //给予兑换券
	RegAdminCmd("sm_fullmp_778",	Command_FullMP, ADMFLAG_KICK, "sm_fullmp_778"); //最大MP
	RegAdminCmd("sm_givekt_582",	Command_GiveKT, ADMFLAG_KICK, "sm_givekt_582 玩家名字 数量");  //给予玩家大过
	RegAdminCmd("sm_rptest_335",	Command_RpTest, ADMFLAG_KICK, "sm_rptest_335 编号");   //给予玩家彩票
	RegAdminCmd("sm_setvip_845",	Command_SetVIP, ADMFLAG_KICK, "sm_setvip_845 玩家名字 VIP类型(0 = 普通会员 1 = 白金会员 2 = 黄金会员 3 = 水晶会员 4 = 至尊会员 )");
	RegAdminCmd("sm_rpgkv_449",	Command_RPGKV, ADMFLAG_KICK, "sm_rpgkv_449 name key vaule");  //修改数据
	RegAdminCmd("sm_rpgdel_625",	Command_RPGDEL, ADMFLAG_KICK, "sm_rpgdel_625 name"); //删除玩家数据
	RegAdminCmd("sm_rpggm",	Command_RPGGM, ADMFLAG_KICK, "sm_rpggm");   //管理员满属性
	RegAdminCmd("sm_rpgsn_515",	Command_RPGName, ADMFLAG_KICK, "sm_rpgsn_515"); //玩家姓名限制
	RegAdminCmd("sm_clone_855",	Command_Clone, ADMFLAG_KICK, "sm_clone_855 [Type]");  //克隆动画
	RegAdminCmd("sm_setmodel_877",	Command_SetModel, ADMFLAG_KICK, "sm_setmodel_877 [modelid]");  //人物模型设置
	RegAdminCmd("sm_rpgreset_249",	Command_RPGReset, ADMFLAG_KICK, "sm_rpgreset__515");   //玩家洗点
	RegConsoleCmd("callvote",	Callvote_Handler);
	/* bot 增加 */
	RegAdminCmd("sm_addbot",	Command_AddBot, ADMFLAG_KICK, "sm_addbot");
	/* 时间流速 */
	RegAdminCmd("sm_settime_457",	Command_SetTime, ADMFLAG_KICK, "sm_settime_457");   //时间流速
	
	/* VIP */
	RegConsoleCmd("sm_vipfree",	Command_VIP);
	RegConsoleCmd("sm_vipvote",	Command_VIPVote);
	
	/* 我的背包 */
	RegConsoleCmd("sm_mybag",	Command_MyBag);
	
	/* 我的道具 */
	RegConsoleCmd("sm_myitem",	Command_MyItem);
	RegConsoleCmd("sm_setitem_957",	Command_SetItem);
	
	/* 手动存档 */
	RegConsoleCmd("sm_isave",	Command_RPGSave);
	
	/* 全部踢出更新 */
	RegServerCmd("sm_serverupdata", Command_ServerUpdata);
	
	/* 每日签到 */
	RegConsoleCmd("sm_qiandao",	Command_QianDao);
}

HookEvents()
{
	/* Event */
	HookEvent("player_hurt",			Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("witch_killed",			Event_WitchKilled);
	HookEvent("infected_hurt",			Event_InfectedHurt, EventHookMode_Pre);
	HookEvent("round_end",				Event_RoundEnd);
	HookEvent("heal_success",			Event_HealSuccess);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("round_start",			Event_RoundStart);
	HookEvent("player_first_spawn",		Event_PlayerFirstSpawn);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("defibrillator_used",		Event_DefibrillatorUsed);
	HookEvent("player_incapacitated",	Event_Incapacitate);
	HookEvent("weapon_fire",			Event_WeaponFire,	EventHookMode_Pre);
	HookEvent("weapon_fire",			Event_WeaponFire2);
	HookEvent("player_use",				Event_PlayerUse);
	HookEvent("player_team",			Event_PlayerTeam);
	HookEvent("bot_player_replace",		Event_BotPlayerReplace);
	HookEvent("witch_harasser_set",		Event_WitchHarasserSet);
//	HookEvent("player_changename",		Event_PlayerChangename,	EventHookMode_Pre);  修改玩家游戏名字
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("tank_spawn", Event_Tank_Spawn, EventHookMode_Pre);
	HookEvent("bullet_impact",	Event_BulletImpact);
	//HookEvent("infected_death", Event_Infected_Death);
	HookEvent("item_pickup", Melee_Event_ItemPickup);
	HookEvent("weapon_fire", Melee_Event_WeaponFire);
	
}

InitPrecache()
{
	/*  PrecacheSound  预先缓存的声音 */
	PrecacheSound(TSOUND, true);
	PrecacheSound(SatelliteCannon_Sound_Launch, true);
	PrecacheSound(SatelliteCannonmiss_Sound_Launch, true);
	PrecacheSound(SOUNDCLIPEMPTY, true);
	PrecacheSound(SOUNDRELOAD, true);
	PrecacheSound(SOUNDREADY, true);
	PrecacheSound(FireBall_Sound_Impact01, true);
	PrecacheSound(FireBall_Sound_Impact02, true);
	PrecacheSound(IceBall_Sound_Impact01, true);
	PrecacheSound(IceBall_Sound_Impact02, true);
	PrecacheSound(IceBall_Sound_Freeze, true);
	PrecacheSound(IceBall_Sound_Defrost, true);
	PrecacheSound(ChainLightning_Sound_launch, true);  //连锁闪电的音效   在c源码文件里
	PrecacheSound(ChainmissLightning_Sound_launch, true);
	PrecacheSound(ChainkbLightning_Sound_launch, true);
	PrecacheSound("ambient/alarms/klaxon1.wav", true);
	PrecacheSound("ambient/explosions/explode_3.wav", true);
	PrecacheSound("animation/gas_station_explosion.wav", true);
	PrecacheSound("animation/van_inside_debris.wav", true);
	PrecacheSound("ambient/random_amb_sfx/dist_explosion_01.wav", true);
	PrecacheSound("ambient/random_amb_sfx/dist_explosion_02.wav", true);
	PrecacheSound("ambient/random_amb_sfx/dist_explosion_03.wav", true);
	PrecacheSound("ambient/random_amb_sfx/dist_explosion_04.wav", true);
	
	
	
	
	

	/* Precache sounds */
	PrecacheSound(SOUND_TRACING, true);
	//暴击音效
	PrecacheSound(CRIT_SOUND, true);
	//弹药师_吸血弹音效
	PrecacheSound(SOUND_SUCKBLOOD, true);
	//获得道具音效
	PrecacheSound(SOUND_GOTITEM, true);
	//使用道具音效
	PrecacheSound(SOUND_USEITEM, true);
	//DLC坦克模型
	PrecacheModel(MODEL_DLCTANK, true);
	PrecacheModel(MODEL_TANK, true);
	
	for(new i=0; i<WEAPONCOUNT; i++)
	{
		PrecacheModel(MODEL[i], true);
		PrecacheSound(SOUND[i], true) ;
	}
	robot_gamestart = false;

	/* Precache models */
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	
	PrecacheModel(FireBall_Model);
	
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/explosive_box001.mdl", true);
	PrecacheModel("models/props_equipment/oxygentank01.mdl", true);
	PrecacheModel("models/missiles/f18_agm65maverick.mdl", true);
	
	fire =PrecacheModel("materials/sprites/laserbeam.vmt");
	white =PrecacheModel("materials/sprites/white.vmt");
	halo = PrecacheModel("materials/dev/halo_add_to_screen.vmt");

	PrecacheParticle("gas_explosion_pump");
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_INFECTEDSUMMON);
	PrecacheParticle(PARTICLE_SCEFFECT);
	PrecacheParticle(PARTICLE_HLEFFECT);
	
	PrecacheParticle(FireBall_Particle_Fire01);
	PrecacheParticle(FireBall_Particle_Fire02);
	PrecacheParticle(FireBall_Particle_Fire03);
	
	PrecacheParticle(IceBall_Particle_Ice01);
	PrecacheParticle(ChainLightning_Particle_hit);
	PrecacheParticle(ChainmissLightning_Particle_hit);
	PrecacheParticle(ChainkbLightning_Particle_hit);
	
	//PrecacheParticle(HealingBall_Particle);
	PrecacheParticle(HealingBall_Particle_Effect);
	
	//PrecacheParticle(HealingBallmiss_Particle);
	PrecacheParticle(HealingBallmiss_Particle_Effect);
	
	PrecacheParticlemiss("gas_explosion_main");
	PrecacheParticlemiss("weapon_pipebomb");
	PrecacheParticlemiss("gas_explosion_pump"); 
	PrecacheParticlemiss("electrical_arc_01_system");
	PrecacheParticlemiss("electrical_arc_01_parent");
	
	/* Model Precache */
	g_BeamSprite = PrecacheModel(SPRITE_BEAM);
	g_HaloSprite = PrecacheModel(SPRITE_HALO);
	g_GlowSprite = PrecacheModel(SPRITE_GLOW);
	
	/* Precache models */
	PrecacheModel(ENTITY_PROPANE, true);
	PrecacheModel(ENTITY_GASCAN, true);
	
	/* Precache sounds */
	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_BCLAW, true);
	PrecacheSound(SOUND_GCLAW, true);
	PrecacheSound(SOUND_DCLAW, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_STEEL, true);
	PrecacheSound(SOUND_CHANGE, true);
	PrecacheSound(SOUND_HOWL, true);
	PrecacheSound(SOUND_WARP, true);
	PrecacheSound(SOUND_ABS, true);
	
	/* Precache particles */
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_DEATH);
	PrecacheParticle(PARTICLE_THIRD);
	PrecacheParticle(PARTICLE_FORTH);
	PrecacheParticle(PARTICLE_WARP);
}

GetConVar()
{
  	robot_reactiontime=GetConVarFloat(RobotReactiontime);
 	robot_energy=GetConVarFloat(RobotEnergy)*60.0;
	//难度平衡convar
	SuperTank_Health[TANK1] = GetConVarInt(sm_supertank_health_max);  //GetConVarInt = 获取cfg里的设置
	SuperTank_Health[TANK2] = GetConVarInt(sm_supertank_health_second); //GetConVarInt = 获取cfg里的设置
	SuperTank_Health[TANK3] = GetConVarInt(sm_supertank_health_third); //GetConVarInt = 获取cfg里的设置
	SuperTank_Health[TANK4] = GetConVarInt(sm_supertank_health_forth); //GetConVarInt = 获取cfg里的设置
	SuperTank_Health[TANK5] = GetConVarInt(sm_supertank_health_boss); //GetConVarInt = 获取cfg里的设置
	SuperTank_Warp = GetConVarFloat(sm_supertank_warp_interval);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVar();
}

static Initialization(i) //清除玩家数据
{
	JD[i]=0, Lv[i]=0, EXP[i]=0, Cash[i]=0, KTCount[i]=0, RobotCount[i]=0, NewLifeCount[i]=0,
	Str[i]=0, Agi[i]=0, Health[i]=0, Endurance[i]=0, Intelligence[i]=0, Qcash[i]=0, DHJ[i]=0, Qstr[i]=0, Lis[i]=0, LisA[i]=0, LisB[i]=0,
	StatusPoint[i]=0, SkillPoint[i]=0, HealingLv[i]=10, HealingkbLv[i]=1, HealingwxLv[i]=1, HealinggbdLv[i]=1, EndranceQualityLv[i]=0, EarthQuakeLv[i]=0,
	AmmoMakingLv[i]=0, AmmoMakingmissLv[i]=0, FireSpeedLv[i]=0, SatelliteCannonLv[i]=0, SatelliteCannonmissLv[i]=0,
	EnergyEnhanceLv[i]=0, SprintLv[i]=0, InfiniteAmmoLv[i]=0, Eqbox[i]=0, TDaxinxin[i]=0, 
	Renwu[i]=0, Jenwu[i]=0, Pugan[i]=0, Tegan[i]=0, TYangui[i]=0, TPangzi[i]=0, TLieshou[i]=0,
	TKoushui[i]=0, THouzhi[i]=0, TXiaoniu[i]=0, Libao[i]=0, Shitou[i]=0, Shilv[i]=0, TSDJ1[i]=0, TSDJ2[i]=0, TSDJ3[i]=0,
	BioShieldLv[i]=0, BioShieldmissLv[i]=0, BioShieldkbLv[i]=0, DamageReflectLv[i]=0, MeleeSpeedLv[i]=0,
	defibrillator[i]=0, TeleportToSelectLv[i]=0, AppointTeleportLv[i]=0, TeleportTeamLv[i]=0, TeleportTeamztLv[i]=0, HealingBallLv[i]=0, HealingBallmissLv[i]=1,
	FireBallLv[i]=0, IceBallLv[i]=0, ChainLightningLv[i]=0, ChainmissLightningLv[i]=1, ChainkbLightningLv[i]=1, M16[i]=0, AK47[i]=0, PZ[i]=0, AWP[i]=0, M60[i]=0,
	RobotUpgradeLv[i][0]=0, RobotUpgradeLv[i][1]=0, RobotUpgradeLv[i][2]=0, Lottery[i]=0,  LZD[i]=0, KTCount[i]=0, everyday1[i]=0, CqdzLv[i]=0, HMZSLv[i]=0, SPZSLv[i]=0, GouhunLv[i]=0, Hunpo[i]=0,
	BJCH[i]=0, TKSL[i]=0, XGSL[i]=0, HZSL[i]=0, PPSL[i]=0, PZSL[i]=0, DXSL[i]=0, NWSL[i]=0, BRSL[i]=0, DRSL[i]=0, YGSL[i]=0, HDRW[i]=0, HDZT[i]=0, HD1[i]=0, HD2[i]=0, HD3[i]=0, HD4[i]=0, HD5[i]=0, HD6[i]=0, Qhs[i]=0, Sxcs[i]=0, QHSL[i]=0, BSXY[i]=0,
	TKSLZ[i]=0, XGSLZ[i]=0, HZSLZ[i]=0, PPSLZ[i]=0, PZSLZ[i]=0, DXSLZ[i]=0, NWSLZ[i]=0, BRSLZ[i]=0, DRSLZ[i]=0, YGSLZ[i]=0, QHHSZ[i]=0, BZBNZ[i]=0, XR[i]=0, HGLB[i]=0,
	
	LZDLv[i] = 0,
	DCGYLv[i] = 0,
	YLDSLv[i] = 0,
	Isylds[i]=false,
	IsDCGY[i]=false,
	yldscd[i]=false,
	DCGYcd[i]=false,
	LZDcd[i]=false,
	JobChooseBool[i]=false,
	IsSuperInfectedEnable[i]=false,
	IsSatelliteCannonReady[i]=true,
	IsSatelliteCannonmissReady[i]=true,
	IsSprintEnable[i]=false,
	IsInfiniteAmmoEnable[i]=false,
	IsBioShieldEnable[i]=false,
	IsBioShieldmissEnable[i]=false,
	IsBioShieldkbEnable[i]=false,
	IsBioShieldReady[i]=true,
	IsBioShieldmissReady[i]=true,
	IsBioShieldkbReady[i]=true,
	IsDamageReflectEnable[i]=false,
	IsMeleeSpeedEnable[i]=false,
	IsTeleportTeamEnable[i]=false,
	IsTeleportTeamztEnable[i]=false,
	IsAppointTeleportEnable[i]=false,
	IsTeleportToSelectEnable[i]=false,
	HealingBallExp[i] = 0,
	HealingBallmissExp[i] = 0,
	IsHealingBallEnable[i] = false,
	IsHealingBallmissEnable[i] = false,
	IsPasswordConfirm[i]=false;
	IsAdmin[i]=false;
	//弹药专家
	Broken_Ammo[i] = false;
	Poison_Ammo[i] = false;
	SuckBlood_Ammo[i] = false;
	AreaBlasting[i] = false;
	LaserGun[i] = false;
	BrokenAmmoLv[i] = 0;
	PoisonAmmoLv[i] = 0;
	SuckBloodAmmoLv[i] = 0;
	AreaBlastingLv[i] = 0;
	LaserGunLv[i] = 0;
	//基因改造
	GeneLv[i] = 0;
	//VIP
	VIP[i] = 0;
	DLTNum[i] = 0;
	
	//背包清理
	I_BagSize[i] = 0;
	for (new x; x < 5; x++)
	{
		for (new u; u < BagMax[x]; u++)
			I_Bag[i][x][u] = 0;
	}
	
	//装备清理
	//消耗类道具物品读取
	PlayerXHItemSize[i] = 0;
	for (new x; x < MaxItemNum[ITEM_XH]; x++)
		PlayerItem[i][ITEM_XH][x] = 0;

	
	//装备类道具物品读取
	PlayerZBItemSize[i] = 0;
	for (new x; x < MaxItemNum[ITEM_ZB]; x++)
		PlayerItem[i][ITEM_ZB][x] = 0;
	
	//新手BUFF
	HasBuffPlayer[i] = false;
	
	//每日签到
	EveryDaySign[i] = -1;
	
	/* 停止检查经验Timer */
	if(CheckExpTimer[i] != INVALID_HANDLE)
	{
		KillTimer(CheckExpTimer[i]);
		CheckExpTimer[i] = INVALID_HANDLE;
	}
	
	
	
	KillAllClientSkillTimer(i);
}

KillAllClientSkillTimer(Client)
{
	/* 停止击杀丧尸Timer */
	if(ZombiesKillCountTimer[Client] != INVALID_HANDLE)
	{
		ZombiesKillCount[Client] = 0;
		KillTimer(ZombiesKillCountTimer[Client]);
		ZombiesKillCountTimer[Client] = INVALID_HANDLE;
	}
	/*  停止治疗术Timer */
	if(HealingTimer[Client] != INVALID_HANDLE)
	{
		KillTimer(HealingTimer[Client]);
		HealingTimer[Client] = INVALID_HANDLE;
	}

	if(JD[Client] > 0)
	{
		if(JD[Client] == 1)
		{
			/* 停止卫星炮CD Timer */
			if(SatelliteCannonCDTimer[Client] != INVALID_HANDLE)
			{
				IsSatelliteCannonReady[Client] = true;
				KillTimer(SatelliteCannonCDTimer[Client]);
				SatelliteCannonCDTimer[Client] = INVALID_HANDLE;
			}
		} else if(JD[Client] == 2)
		{
			/* 停止暴走效果Timer */
			if(SprinDurationTimer[Client] != INVALID_HANDLE)
			{
				IsSprintEnable[Client] = false;
				RebuildStatus(Client, false);
				KillTimer(SprinDurationTimer[Client]);
				SprinDurationTimer[Client] = INVALID_HANDLE;
			}
			/* 停止无限子弹术效果Timer */
			if(InfiniteAmmoDurationTimer[Client] != INVALID_HANDLE)
			{
				IsInfiniteAmmoEnable[Client] = false;
				KillTimer(InfiniteAmmoDurationTimer[Client]);
				InfiniteAmmoDurationTimer[Client] = INVALID_HANDLE;
			}
			/*  狂暴关联Timer */
			if(HealingkbTimer[Client] != INVALID_HANDLE)
			{
			KillTimer(HealingkbTimer[Client]);
			HealingkbTimer[Client] = INVALID_HANDLE;
			}
			/* 狂暴关联two Timer */
			if(BioShieldkbDurationTimer[Client] != INVALID_HANDLE)
			{
				IsBioShieldkbEnable[Client] = false;
				SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
				KillTimer(BioShieldkbDurationTimer[Client]);
				BioShieldkbDurationTimer[Client] = INVALID_HANDLE;
			}
			/*  狂暴关联wuxian Timer */
			if(HealingwxTimer[Client] != INVALID_HANDLE)
			{
			KillTimer(HealingwxTimer[Client]);
			HealingwxTimer[Client] = INVALID_HANDLE;
			}
			/*  狂暴关联gaobaodan Timer */
			if(HealinggbdTimer[Client] != INVALID_HANDLE)
			{
			KillTimer(HealinggbdTimer[Client]);
			HealinggbdTimer[Client] = INVALID_HANDLE;
			}
		} else if(JD[Client] == 3)
		{
			/* 停止无敌术效果Timer */
			if(BioShieldDurationTimer[Client] != INVALID_HANDLE)
			{
				IsBioShieldEnable[Client] = false;
				SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
				KillTimer(BioShieldDurationTimer[Client]);
				BioShieldDurationTimer[Client] = INVALID_HANDLE;
			}
			/* 停止无敌术CD Timer */
			if(BioShieldCDTimer[Client] != INVALID_HANDLE)
			{
				IsBioShieldReady[Client] = true;
				KillTimer(BioShieldCDTimer[Client]);
				BioShieldCDTimer[Client] = INVALID_HANDLE;
			}
			/* 停止反伤术效果Timer */
			if(DamageReflectDurationTimer[Client] != INVALID_HANDLE)
			{
				IsDamageReflectEnable[Client] = false;
				KillTimer(DamageReflectDurationTimer[Client]);
				DamageReflectDurationTimer[Client] = INVALID_HANDLE;
			}
			/* 近战嗜血术效果Timer */
			if(MeleeSpeedDurationTimer[Client] != INVALID_HANDLE)
			{
				IsMeleeSpeedEnable[Client] = false;
				KillTimer(MeleeSpeedDurationTimer[Client]);
				MeleeSpeedDurationTimer[Client] = INVALID_HANDLE;
			}
			/* 停止潜能大爆发Timer */
			if(BioShieldmissDurationTimer[Client] != INVALID_HANDLE)
			{
				IsBioShieldmissEnable[Client] = false;
				SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
				KillTimer(BioShieldmissDurationTimer[Client]);
				BioShieldmissDurationTimer[Client] = INVALID_HANDLE;
			}
			/* 生物专家术关联Timer */
			if(HealingBallmissTimer[Client] != INVALID_HANDLE)
			{
				if (IsValidPlayer(Client) && !IsFakeClient(Client))
				{
					if(HealingBallmissExp[Client] > 0)
					{
						EXP[Client] += HealingBallmissExp[Client] / 4;
						Cash[Client] += HealingBallmissExp[Client] / 10; //GetConVarInt = 获取cfg里的设置
						CPrintToChat(Client, MSG_SKILL_HB_END, HealingBallmissExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallmissExp[Client], HealingBallmissExp[Client] / 10);
						//PrintToserver("[United RPG] %s的治疗光球术结束了! 总共治疗了队友%dHP, 获得%dExp, %d$", NameInfo(Client, simple), HealingBallmissExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallmissExp[Client], HealingBallmissExp[Client] / 10);					
					}
				}
				HealingBallmissExp[Client] = 0;
				IsHealingBallmissEnable[Client] = false;
				KillTimer(HealingBallmissTimer[Client]);
				HealingBallmissTimer[Client] = INVALID_HANDLE;
			}
		} else if(JD[Client] == 4)
		{
			/* 停止冰之传送CD Timer */
			if(TCChargingTimer[Client] != INVALID_HANDLE)
			{
				IsTeleportToSelectEnable[Client] = false;
				KillTimer(TCChargingTimer[Client]);
				TCChargingTimer[Client] = INVALID_HANDLE;
			}
			/* 停止心灵传送CD Timer */
			if(TTChargingTimer[Client] != INVALID_HANDLE)
			{
				IsTeleportTeamEnable[Client] = false;
				KillTimer(TTChargingTimer[Client]);
				TTChargingTimer[Client] = INVALID_HANDLE;
			}
			/* 停止黑屏特效Timer */
			if(FadeBlackTimer[Client] != INVALID_HANDLE)
			{
				PerformFade(Client, 0);
				IsAppointTeleportEnable[Client] = false;
				KillTimer(FadeBlackTimer[Client]);
				FadeBlackTimer[Client] = INVALID_HANDLE;
			}
			/* 停止治疗光球Timer */
			if(HealingBallTimer[Client] != INVALID_HANDLE)
			{
				if (IsValidPlayer(Client) && !IsFakeClient(Client))
				{
					if(HealingBallExp[Client] > 0)
					{
						EXP[Client] += HealingBallExp[Client] / 4 + VIPAdd(Client, HealingBallExp[Client] / 4, 1, true);
						Cash[Client] += HealingBallExp[Client] / 10 + VIPAdd(Client, HealingBallExp[Client] / 10, 1, false); //GetConVarInt = 获取cfg里的设置
						CPrintToChat(Client, MSG_SKILL_HB_END, HealingBallExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallExp[Client] / 4, HealingBallExp[Client] / 10);
						//PrintToserver("[United RPG] %s的治疗光球术结束了! 总共治疗了队友%dHP, 获得%dExp, %d$", NameInfo(Client, simple), HealingBallExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallExp[Client], HealingBallExp[Client]/10);					
					}
				}
				HealingBallExp[Client] = 0;
				IsHealingBallEnable[Client] = false;
				KillTimer(HealingBallTimer[Client]);
				HealingBallTimer[Client] = INVALID_HANDLE;
			}
			/* 停止全体召唤术CD Timer */
			if(TTChargingztTimer[Client] != INVALID_HANDLE)
			{
				IsTeleportTeamztEnable[Client] = false;
				KillTimer(TTChargingTimer[Client]);
				TTChargingztTimer[Client] = INVALID_HANDLE;
			}
		} else if(JD[Client] == 5)
		{
			/* 停止暗夜暴雷CD Timer */
			if(SatelliteCannonmissCDTimer[Client] != INVALID_HANDLE)
			{
				IsSatelliteCannonmissReady[Client] = true;
				KillTimer(SatelliteCannonmissCDTimer[Client]);
				SatelliteCannonmissCDTimer[Client] = INVALID_HANDLE;
			}
		} else if(JD[Client] == 7)
		{
			/* 停止暗夜暴雷CD Timer */
			if(DCGYTimer[Client] != INVALID_HANDLE)
			{
				KillTimer(DCGYTimer[Client]);
				DCGYTimer[Client] = INVALID_HANDLE;
			}
			if(yldsTimer[Client] != INVALID_HANDLE)
			{
				KillTimer(yldsTimer[Client]);
				yldsTimer[Client] = INVALID_HANDLE;
			}
		}
	}

}

/* 初始化 */
public OnConfigsExecuted()
{
	SetPlayerLimit();
	//人数检查计时器
	CreateTimer(10.0, Timer_CheckMaxPlayer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
//读取
public OnClientPutInServer(client)
{
	decl String:user_name[MAX_NAME_LENGTH];
	if (IsValidPlayer(client, false))
	{
		GetClientName(client, user_name, sizeof(user_name));
		Format(PlayerName[client], sizeof(PlayerName), user_name);
		//近战耐久度
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		
		pwtimeout[client] = 0;
		if (GetConVarInt(cv_pwtimeout) > 0) // rpg_cv_pwtimeout  =  多少秒没注册踢出去 GetConVarInt = 获取cfg里的设置
			CreateTimer(1.0, IsPWConfirm, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);//IsPWConfirm 在other.inc文件
		
		if (IsPasswordConfirm[client])
		{
			//会员日期检查
			VipIsOver(client);
			//会员补给重置
			ReSetVipProps(client);
			//医生电击器重置
			ResetDoctor(client);
		}
		/*
		else
		{
			watchingtimer[client] = CreateTimer(1.0,WatchingTimer,client,TIMER_REPEAT);   //创建监视定时器
			watching[client] = true;	//监视  =  真的
			Showing[client] = true;   //显示  =  真的
		}
		*/
		
		//bot检测 会导致刷不出四个电脑人
		//CreateTimer(1.0, GiveBotClient, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		SetGameDifficulty();//调整难度
		//准心玩家信息获取
		CreateTimer(0.5, Timer_GetAimTargetMSG, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		/* 启动雷神弹药定时器 
		if (IsValidEntity(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2 && LZDLv(client) >= 1)  //如果玩家是幸存者和雷神弹药等级大于一，则启用定时器
				ClientTimer[client] = CreateTimer(0.5, ChargeTimer, client, TIMER_REPEAT);
		}
		*/
	}
}

/* 玩家离开游戏  储存*/
public OnClientDisconnect(Client)
{
	/* 储存玩家记录 */
	if(!IsFakeClient(Client))
	{
		SetGameDifficulty();  //调整难度
		////LogToFileEx(LogPath, "%s离开游戏!", NameInfo(Client, simple));
		if(StrEqual(Password[Client], "", true) || IsPasswordConfirm[Client])
			ClientSaveToFileSave(Client);
			
		
		if (!IsClientInGame(Client))
		{
			if (GetBotCount() > 0)
				KickAllFakeClient();
		}
				
		//清除玩家资料
		Initialization(Client);
		
		CPrintToChatAll("玩家: \x03%N {default}菊花疼痛难受,已去治疗.", Client);
	}
}


/* 地图开始 */
public OnMapStart()
{
	new String:map[128];
	GetCurrentMap(map, sizeof(map));
	//LogToFileEx(LogPath, "---=================================================================---");
	//LogToFileEx(LogPath, "--- 地图开始: %s ---", map);
	//LogToFileEx(LogPath, "---=================================================================---");
		
	InitPrecache();   //预先缓存音效

	RPGSave = CreateKeyValues("United RPG Save");
	RPGRank = CreateKeyValues("United RPG Ranking");
	BuildPath(Path_SM, SavePath, 255, "data/UnitedRPGSave.txt");
	BuildPath(Path_SM, RankPath, 255, "data/UnitedRPGRanking.txt");
	FileToKeyValues(RPGSave, SavePath);
	FileToKeyValues(RPGRank, RankPath);
	/* 服务器时间日志 */
	ServerTimeLog = CreateKeyValues("Server Time Log");
	BuildPath(Path_SM, ServerTimePath, 255, "data/ServerTimeLog.txt");
	FileToKeyValues(ServerTimeLog, ServerTimePath);

	oldCommonHp = GetConVarInt(FindConVar("z_health")); //GetConVarInt = 获取cfg里的设置

	SaveServerTimeLog();
	
	/* 大乐透开启 */
	if (DLT_Handle == INVALID_HANDLE && DLT_Timer <= 0)
		DaLeTou_Refresh(true);	
	
	for (new u = 0; u <= MaxClients; u++)
	{
		pwtimeout[u] = 0;
		connectkicktime[u] = 0;
	}
	/*监视
	// 广告定时器 
	if(hinttimer==INVALID_HANDLE)
	{
		hinttimer = CreateTimer(45.0,TimerShow,_,TIMER_REPEAT);   //CreateTimer  =  创建定时器
	}
	else
	{
		KillTimer(hinttimer);     //关闭定时器
		hinttimer = CreateTimer(45.0,TimerShow,_,TIMER_REPEAT);
	}
	*/
}
/* 地图结束 */
public OnMapEnd()
{
	//LogToFileEx(LogPath, "--- 地图结束 ---");
	ResetPlayerLimit();
	CloseHandle(RPGSave);
	CloseHandle(RPGRank);
	CloseHandle(ServerTimeLog);
	if (DLT_Handle != INVALID_HANDLE)
	{
		DLT_Timer = 0.0;
		KillTimer(DLT_Handle);
		DLT_Handle = INVALID_HANDLE;
	}
}

/* 玩家连接游戏  读取 */
public OnClientConnected(Client)
{
	/* 读取玩家记录 */
	if(!IsFakeClient(Client))
	{
		//加载卡住踢出
		connectkicktime[Client] = 0;
		if (GetConVarInt(cv_loadtimeout) > 0) //GetConVarInt = 获取cfg里的设置
			CreateTimer(1.0, Kick_Connect, Client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		Initialization(Client);
		/* 读取玩家密码 */
		decl String:user_name[MAX_NAME_LENGTH]="";
		GetClientName(Client, user_name, sizeof(user_name));
		KvJumpToKey(RPGSave, user_name, false);
		KvGetString(RPGSave, "PW", Password[Client], PasswordLength, "");
		KvGoBack(RPGSave);
		
		if(StrEqual(Password[Client], "", true))	ClientSaveToFileLoad(Client);
		else
		{
			new String:InfoPassword[PasswordLength];
			GetClientInfo(Client, "unitedrpg", InfoPassword, PasswordLength);
			if(StrEqual(Password[Client], InfoPassword, true))
			{
				ClientSaveToFileLoad(Client);
				IsPasswordConfirm[Client] = true;
			}
		}
				
		//LogToFileEx(LogPath, "%s连接游戏!", NameInfo(Client, simple));
		if(CheckExpTimer[Client] != INVALID_HANDLE)
		{
			KillTimer(CheckExpTimer[Client]);
			CheckExpTimer[Client] = INVALID_HANDLE;
		}
		CheckExpTimer[Client] = CreateTimer(1.0, PlayerLevelAndMPUp, Client, TIMER_REPEAT);
		
		
	
		
		/*自动绑定,防止玩家数字键567890不能使用*/
		ClientCommand(Client, "bind 5 slot5");
		ClientCommand(Client, "bind 6 slot6");
		ClientCommand(Client, "bind 7 slot7");
		ClientCommand(Client, "bind 8 slot8");
		ClientCommand(Client, "bind 9 slot9");
		ClientCommand(Client, "bind 0 slot10");

		if (GetConVarInt(BindMode) == 1)	CreateTimer(30.0, Showbind, Client); //GetConVarInt = 获取cfg里的设置
		else if (GetConVarInt(BindMode) == 2)	BindKeyFunction(Client); //GetConVarInt = 获取cfg里的设置
		
		CPrintToChatAll("玩家: \x03%N {default}连接...", Client);
	}
}


public OnClientPostAdminCheck(Client)
{
	if(!IsFakeClient(Client))
	{
		new AdminId:admin = GetUserAdmin(Client);
		if(admin != INVALID_ADMIN_ID)
			IsAdmin[Client] = true;
	}
}


/************************************************************************
*	管理员菜单Start
************************************************************************/
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu) 
		return;
		
	hTopMenu = topmenu;
	AddToTopMenu(hTopMenu, "管理员菜单", TopMenuObject_Category, Menu_CategoryHandler, INVALID_TOPMENUOBJECT);
	
	new TopMenuObject:AdminTopmenu = FindTopMenuCategory(hTopMenu, "管理员菜单");
	
	if (AdminTopmenu != INVALID_TOPMENUOBJECT)
	{
		Admin_GiveExp = AddToTopMenu(hTopMenu, "rpg_givebj", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_givebj", ADMFLAG_KICK);
		Admin_GiveLv = AddToTopMenu(hTopMenu, "rpg_givelv", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_givelv", ADMFLAG_KICK);
		Admin_GiveCash = AddToTopMenu(hTopMenu, "rpg_givecash", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_givecash", ADMFLAG_KICK);
		Admin_GiveDHJ = AddToTopMenu(hTopMenu, "rpg_giveDhj", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_giveDhj", ADMFLAG_KICK);
		Admin_ResetStatus = AddToTopMenu(hTopMenu, "rpg_xidian", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_xidian", ADMFLAG_KICK);
		Admin_GiveKT = AddToTopMenu(hTopMenu, "rpg_givekt", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_givekt", ADMFLAG_KICK);
		Admin_SetVIP = AddToTopMenu(hTopMenu, "rpg_setvip", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_setvip", ADMFLAG_KICK);
		Admin_Hunpo = AddToTopMenu(hTopMenu, "rpg_Hunpo", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_Hunpo", ADMFLAG_KICK);
		Admin_GiveST = AddToTopMenu(hTopMenu, "rpg_givest", TopMenuObject_Item, Menu_TopItemHandler, AdminTopmenu, "rpg_givest", ADMFLAG_KICK);		
	}
}
public Menu_CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, Client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "管理员菜单");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "管理员菜单");
}

public Menu_TopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, Client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == Admin_GiveLv)
			Format(buffer, maxlength, "给予玩家等级");
		else if (object_id == Admin_GiveExp)
			Format(buffer, maxlength, "给予玩家点卷");
		else if (object_id == Admin_GiveCash)
			Format(buffer, maxlength, "给予玩家金钱");
		else if (object_id == Admin_GiveDHJ)
			Format(buffer, maxlength, "给予玩家兑换券");
		else if (object_id == Admin_ResetStatus)
			Format(buffer, maxlength, "给玩家洗点(不扣等级)");
		else if (object_id == Admin_GiveKT)
			Format(buffer, maxlength, "给予玩家大过");
		else if (object_id == Admin_SetVIP)
			Format(buffer, maxlength, "设置玩家为VIP");
		else if (object_id == Admin_Hunpo)
			Format(buffer, maxlength, "给予玩家菊花");
		else if (object_id == Admin_GiveST)
			Format(buffer, maxlength, "给予玩家强化石");	
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == Admin_GiveLv)
			g_id[Client] = 1, AdminGive(Client);
		else if (object_id == Admin_GiveExp)
			g_id[Client] = 2, AdminGive(Client);
		else if (object_id == Admin_GiveCash)
			g_id[Client] = 3, AdminGive(Client);
		else if (object_id == Admin_GiveDHJ)
			g_id[Client] = 4, AdminGive(Client);
		else if (object_id == Admin_ResetStatus)
			g_id[Client] = 5, AdminGive_Handler(Client);
		else if (object_id == Admin_GiveKT)
			g_id[Client] = 6, AdminGive(Client);
		else if (object_id == Admin_SetVIP)
			Menu_SetVIPMenu_Select(Client);
		else if (object_id == Admin_Hunpo)
			g_id[Client] = 7, AdminGive(Client);
		else if (object_id == Admin_GiveST)
			g_id[Client] = 8, AdminGive(Client);
	}
}

AdminGive(Client)
{
	new Handle:menu = CreateMenu(AdminGive_MenuHandler);
	SetMenuTitle(menu, "选择数量");

	if (g_id[Client] == 1)
	{
		AddMenuItem(menu, "5", "5");
		AddMenuItem(menu, "10", "10");
		AddMenuItem(menu, "20", "20");
		AddMenuItem(menu, "30", "30");
		AddMenuItem(menu, "60", "60");
		AddMenuItem(menu, "90", "90");
		AddMenuItem(menu, "120", "120");
	}
	else if (g_id[Client] == 2)
	{
		AddMenuItem(menu, "500", "500");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "2000", "2000");
		AddMenuItem(menu, "5000", "5000");
		AddMenuItem(menu, "10000", "10000");
		AddMenuItem(menu, "20000", "20000");
		AddMenuItem(menu, "50000", "50000");
	}
	else if (g_id[Client] == 3)
	{
		AddMenuItem(menu, "100000", "100000");
		AddMenuItem(menu, "200000", "200000");
		AddMenuItem(menu, "500000", "500000");
		AddMenuItem(menu, "2000", "2000");
		AddMenuItem(menu, "50000", "50000");
		AddMenuItem(menu, "10000", "10000");
		AddMenuItem(menu, "25000", "25000");
	}
	else if (g_id[Client] == 4)
	{
		AddMenuItem(menu, "1", "1");
		AddMenuItem(menu, "2", "2");
		AddMenuItem(menu, "3", "3");
		AddMenuItem(menu, "4", "4");
		AddMenuItem(menu, "5", "5");
		AddMenuItem(menu, "6", "6");
		AddMenuItem(menu, "7", "7");
	}
	else if (g_id[Client] == 6)
	{
		AddMenuItem(menu, "1", "1");
		AddMenuItem(menu, "2", "2");
		AddMenuItem(menu, "3", "3");
		AddMenuItem(menu, "4", "4");
		AddMenuItem(menu, "5", "5");
		AddMenuItem(menu, "6", "6");
		AddMenuItem(menu, "7", "7");
	}
	else if (g_id[Client] == 7)
	{
		AddMenuItem(menu, "5", "5");
		AddMenuItem(menu, "10", "10");
		AddMenuItem(menu, "20", "20");
		AddMenuItem(menu, "30", "30");
		AddMenuItem(menu, "60", "60");
		AddMenuItem(menu, "90", "90");
		AddMenuItem(menu, "120", "120");
		AddMenuItem(menu, "200", "200");
	}
	else if (g_id[Client] == 8)
	{
		AddMenuItem(menu, "100", "100");
		AddMenuItem(menu, "200", "200");
		AddMenuItem(menu, "1000", "1000");
		AddMenuItem(menu, "2500", "2500");
		AddMenuItem(menu, "5000", "5000");
		AddMenuItem(menu, "10000", "10000");
		AddMenuItem(menu, "25000", "25000");
	}

	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public AdminGive_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)	CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];

		GetMenuItem(menu, param2, info, sizeof(info));
		AdminGiveAmount[param1] = StringToInt(info);
		AdminGive_Handler(param1);
	}
}
AdminGive_Handler(Client)
{
	new Handle:menu = CreateMenu(Admingive_MenuHandler2);
	
	if (g_id[Client] == 1)	SetMenuTitle(menu, "给予玩家等级");
	if (g_id[Client] == 2)	SetMenuTitle(menu, "给予玩家点卷");
	if (g_id[Client] == 3)	SetMenuTitle(menu, "给予玩家金钱");
	if (g_id[Client] == 4)	SetMenuTitle(menu, "给予玩家兑换券");
	if (g_id[Client] == 5)	SetMenuTitle(menu, "选择洗点玩家");
	if (g_id[Client] == 6)	SetMenuTitle(menu, "给予玩家大过");
	if (g_id[Client] == 7)	SetMenuTitle(menu, "给予玩家菊花");
	if (g_id[Client] == 8)	SetMenuTitle(menu, "给予玩家强化石");
		
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu2(menu, Client, COMMAND_FILTER);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public Admingive_MenuHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)	CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:targetName[MAX_NAME_LENGTH];
		new userid, target;

		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
			CPrintToChat(param1, "{green}[UnitedRPG] \x01%t", "Player no longer available");
		else if (!CanUserTarget(param1, target))
			CPrintToChat(param1, "{green}[UnitedRPG] \x01%t", "Unable to target");
		
		GetClientName(target, targetName, sizeof(targetName));
		if (g_id[param1] == 1)
		{
			Lv[target] += AdminGiveAmount[param1];
			StatusPoint[target] += AdminGiveAmount[param1]*GetConVarInt(LvUpSP); //GetConVarInt = 获取cfg里的设置
			SkillPoint[target] += AdminGiveAmount[param1]*GetConVarInt(LvUpKSP); //GetConVarInt = 获取cfg里的设置
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_LV, targetName, AdminGiveAmount[param1]);
		}
		else if (g_id[param1] == 2)
		{
			Qcash[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_EXP, targetName, AdminGiveAmount[param1]);
		}
		else if (g_id[param1] == 3)
		{
			Cash[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_CASH, targetName, AdminGiveAmount[param1]);
		}
		else if (g_id[param1] == 4)
		{
			DHJ[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_DHJ, targetName, AdminGiveAmount[param1]);
		}
		else if (g_id[param1] == 5)
		{
			ClinetResetStatus(target, Admin);
		}
		else if (g_id[param1] == 6)
		{
			KTCount[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_KT, targetName, AdminGiveAmount[param1]);

			if(KTLimit >= KTCount[target]) CPrintToChat(target, MSG_KT_WARNING_1, KTLimit);

			if(KTCount[target] > KTLimit )
			{
				if(!JobChooseBool[target])
					CPrintToChat(target, MSG_KT_WARNING_2, KTLimit);
				else
				{
					ClinetResetStatus(target, General);
					CPrintToChat(target, MSG_KT_WARNING_3, KTLimit);
				}
			}
		}
		else if (g_id[param1] == 7)
		{
			Hunpo[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_Hunpo, targetName, AdminGiveAmount[param1]);
		}	
		else if (g_id[param1] == 8)
		{
			Qhs[target] += AdminGiveAmount[param1];
			if (GetConVarInt(GiveAnnonce))	CPrintToChatAllEx(param1, MSG_ADMIN_GIVE_QHSD, targetName, AdminGiveAmount[param1]);
		}
		AdminGive_Handler(param1);
	}
}

/************************************************************************
*	管理员菜单END
************************************************************************/

/************************************************************************
*	Command和其他功能
************************************************************************/

public Action:Command_GiveExp(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_givebj  <#userid|name> [数量]");
		return Plugin_Handled;
	}

	
	decl String:arg[MAX_NAME_LENGTH], String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	new targetClient;

	if ((target_count = ProcessTargetString(arg,Client,target_list,MAXPLAYERS,COMMAND_FILTER,target_name,sizeof(target_name),tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetClient = target_list[i];
			Qcash[targetClient] += StringToInt(arg2);
		}
		if (GetConVarInt(GiveAnnonce)) //GetConVarInt = 获取cfg里的设置
		{
			if(StrEqual(arg, "@all", false)) arg = "所有玩家";
			if(StrEqual(arg, "@humans", false)) arg = "所有幸存者";
			if(StrEqual(arg, "@alive", false)) arg = "所有活著的玩家";
			if(StrEqual(arg, "@dead", false)) arg = "所有死亡的玩家";
			CPrintToChatAllEx(Client, MSG_ADMIN_GIVE_EXP, arg, StringToInt(arg2));
		}
	}
	else
	{
		ReplyToTargetError(Client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveDHJ(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_giveDhj  <#userid|name> [数量]");
		return Plugin_Handled;
	}

	
	decl String:arg[MAX_NAME_LENGTH], String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	new targetClient;

	if ((target_count = ProcessTargetString(arg,Client,target_list,MAXPLAYERS,COMMAND_FILTER,target_name,sizeof(target_name),tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetClient = target_list[i];
			DHJ[targetClient] += StringToInt(arg2);
		}
		if (GetConVarInt(GiveAnnonce)) //GetConVarInt = 获取cfg里的设置
		{
			if(StrEqual(arg, "@all", false)) arg = "所有玩家";
			if(StrEqual(arg, "@humans", false)) arg = "所有幸存者";
			if(StrEqual(arg, "@alive", false)) arg = "所有活著的玩家";
			if(StrEqual(arg, "@dead", false)) arg = "所有死亡的玩家";
			CPrintToChatAllEx(Client, MSG_ADMIN_GIVE_DHJ, arg, StringToInt(arg2));
		}
	}
	else
	{
		ReplyToTargetError(Client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveLevel(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_givelv <#userid|name> [数量]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	new targetClient;

	if ((target_count = ProcessTargetString(arg,Client,target_list,MAXPLAYERS,COMMAND_FILTER,target_name,sizeof(target_name),tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetClient = target_list[i];
			Lv[targetClient] += StringToInt(arg2);
			StatusPoint[targetClient] += GetConVarInt(LvUpSP)*StringToInt(arg2);
			SkillPoint[targetClient] += GetConVarInt(LvUpKSP)*StringToInt(arg2);
		}
		if (GetConVarInt(GiveAnnonce)) //GetConVarInt = 获取cfg里的设置
		{
			if(StrEqual(arg, "@all", false)) arg = "所有玩家";
			if(StrEqual(arg, "@humans", false)) arg = "所有幸存者";
			if(StrEqual(arg, "@alive", false)) arg = "所有活着的玩家";
			if(StrEqual(arg, "@dead", false)) arg = "所有死亡的玩家";
			CPrintToChatAllEx(Client, MSG_ADMIN_GIVE_LV, arg, StringToInt(arg2));
		}
	}
	else
	{
		ReplyToTargetError(Client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveCash(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_giveexp  <#userid|name> [数量]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	new targetClient;
	if ((target_count = ProcessTargetString(arg,Client,target_list,MAXPLAYERS,COMMAND_FILTER,target_name,sizeof(target_name),tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetClient = target_list[i];
			Cash[targetClient] += StringToInt(arg2);
		}
		if (GetConVarInt(GiveAnnonce)) //GetConVarInt = 获取cfg里的设置
		{
			if(StrEqual(arg, "@all", false)) arg = "所有玩家";
			if(StrEqual(arg, "@humans", false)) arg = "所有幸存者";
			if(StrEqual(arg, "@alive", false)) arg = "所有活着的玩家";
			if(StrEqual(arg, "@dead", false)) arg = "所有死亡的玩家";
			CPrintToChatAllEx(Client, MSG_ADMIN_GIVE_CASH, arg, StringToInt(arg2));
		}
	}
	else
	{
		ReplyToTargetError(Client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_FullMP(Client, args)
{
	MP[Client] = MaxMP[Client];
	return Plugin_Handled;
}

public Action:Command_GiveKT(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_givekt  <#userid|name> [数量]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[64];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	new targetClient;
	if ((target_count = ProcessTargetString(arg,Client,target_list,MAXPLAYERS,COMMAND_FILTER,target_name,sizeof(target_name),tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetClient = target_list[i];
			KTCount[targetClient] += StringToInt(arg2);
			
			if(KTLimit >= KTCount[targetClient]) CPrintToChat(targetClient, MSG_KT_WARNING_1, KTLimit);

			if(KTCount[targetClient] > KTLimit )
			{
				if(!JobChooseBool[targetClient])
				{
					CPrintToChat(targetClient, MSG_KT_WARNING_2, KTLimit);
				}
				else
				{
					ClinetResetStatus(targetClient, General);
					CPrintToChat(targetClient, MSG_KT_WARNING_3, KTLimit);
				}
			}
		}
	}
	else
	{
		ReplyToTargetError(Client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_RpTest(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_rptest 编号(%d~%d)", diceNumMin, diceNumMax);
		return Plugin_Handled;
	}

	decl String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(StringToInt(arg) > diceNumMax || StringToInt(arg) < diceNumMin)
	{
		ReplyToCommand(Client, "[SM] 用法: sm_rptest 编号(%d~%d)", diceNumMin, diceNumMax);
		return Plugin_Handled;
	}
	
	AdminDiceNum[Client] = StringToInt(arg);
	UseLotteryFunc(Client);
	return Plugin_Handled;
}

//RPG离线KV设置
public Action:Command_RPGKV(Client, args)
{
	if (args < 2)
	{
		ReplyToCommand(Client, "[RPGKv]sm_rpgkv_449 [Name] [Key] [Value] [type]");
		//KickClient(Client, "由于你在服务器改名,试图盗取或破坏他人帐号,服务器已经将你踢出!你妹的");
		return Plugin_Handled;
	}
	
	new String:name[32];
	new String:key[64];
	new String:s_value[64];
	new String:type[64];
	new g_value;
	new value;
	new target;
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, key, sizeof(key));
	
	/* 取代玩家姓名中会导致错误的符号 */
	ReplaceString(name, sizeof(name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(name, sizeof(name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(name, sizeof(name), "/*", "{SST}");//SST Slash Star
	ReplaceString(name, sizeof(name), "*/", "{STS}");//STS Star Slash
	ReplaceString(name, sizeof(name), "//", "{DSL}");//DSL Double Slash

	if(!KvJumpToKey(RPGSave, name, false))
	{
		ReplyToCommand(Client, "[RPGKv]没有发现该键!");
		KvGoBack(RPGSave);
		return Plugin_Handled;
	}
	
	target = GetClientForName(name);
	
	if (IsValidPlayer(target) && args >= 3 && target != Client)
	{
		KickClient(target, "管理员正在对你数据进行操作,请稍后再进!");
		ReplyToCommand(Client, "[RPGKv]发现操作对象在游戏中,已经踢出游戏,请重新操作!");
		KvGoBack(RPGSave);
		return Plugin_Handled;
	}
	
	value = KvGetNum(RPGSave, key, 0);
	
	if (args >= 3)
	{
		GetCmdArg(3, s_value, sizeof(s_value));
		g_value = StringToInt(s_value);
		
		if (args >= 4)
		{
			GetCmdArg(4, type, sizeof(type));
			if (StrEqual(type, "+", false))
				value = value + g_value;
			else if (StrEqual(type, "-", false))
				value = value - g_value;
			else if (StrEqual(type, "*", false))
				value = value * g_value;
			else if (StrEqual(type, "/", false))
				value = value / g_value;
		}
		else
			value = g_value;

		KvSetNum(RPGSave, key, value);
		ReplyToCommand(Client, "[设置键值]Name: [%s] Key: [%s] Value: [%d]", name, key, value);	
	}
	else if (args == 2)
	{	
		if (StrEqual(key, "VIPTL", false))
			ReplyToCommand(Client, "{olive}[获取键值] {green}%s \x03Vip剩余天数:{green}[%d]", name, value - GetToday());
		ReplyToCommand(Client, "[获取键值]Name: [%s] Key: [%s] Value: [%d]", name, key, value);
	}
	
	KvGoBack(RPGSave);
	
	if (IsValidPlayer(target) && args >= 3)
		ClientSaveToFileLoad(target), ReplyToCommand(Client, "{olive}[设置键值] {green}%N \x03在游戏中,保存键值成功并读取存档同步数据.", target);
		
	return Plugin_Handled;
}

//RPG删号
public Action:Command_RPGDEL(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[RPG]sm_rpgdel [Name]");
		KickClient(Client, "由于你在服务器作弊,试图破坏他人帐号,服务器已经将你踢出!你妹的");  //Kick踢的意思
		return Plugin_Handled;
	}
	
	new String:name[32];
	new String:targetip[32];
	new target;
	GetCmdArg(1, name, sizeof(name));

	if(!KvJumpToKey(RPGSave, name, false))
	{
		ReplyToCommand(Client, "[RPG]没有发现该键!");
		KvGoBack(RPGSave);
		return Plugin_Handled;
	}
	else	
		KvDeleteThis(RPGSave);
		
	target = GetClientForName(name);
	if (IsValidPlayer(target, false) && target != Client)
	{
		GetClientIP(target, targetip, sizeof(targetip));
		PrintToChatAll("{red}[封禁]{olive}由于 {green}%N {olive}使用非法作弊或违法服务器规定,已经被服务器{green}删档{olive}并且{green}永久封禁!", target);
		BanIdentity(targetip, 0, BANFLAG_IP, "违规作弊");
		if (IsValidPlayer(target, false))
			KickClient(target, "由于你使用作弊器或在本服务器违规,你将被删除所有档案和踢出!");
		ReplyToCommand(Client, "[RPG]发现操作对象在游戏中,已经踢出游戏并删除存档!");
	}
	else
		PrintToChatAll("{blue}[封禁]{olive}由于 {green}%s {olive}使用非法作弊或违法服务器规定,已经被服务器{green}删档{olive}并且{green}永久封禁!", name), ReplyToCommand(Client, "[RPG]操作对象不在游戏中,直接删除存档!");
		
	KvRewind(RPGSave);	
	return Plugin_Handled;
}


//RPG名字修改
public Action:Command_RPGName(Client, args)
{
	if (args < 2)
	{
		ReplyToCommand(Client, "[RPG]sm_setname_158 [Name] [NewName]");
		KickClient(Client, "由于你的名称发生变化,系统自动将你踢出!");  //Kick踢的意思
		return Plugin_Handled;
	}
	
	new String:name[32];
	new String:newname[32];
	new String:temp[32];
	new target;

	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, newname, sizeof(newname));
	
	/* 取代玩家姓名中会导致错误的符号 */
	ReplaceString(name, sizeof(name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(name, sizeof(name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(name, sizeof(name), "/*", "{SST}");//SST Slash Star
	ReplaceString(name, sizeof(name), "*/", "{STS}");//STS Star Slash
	ReplaceString(name, sizeof(name), "//", "{DSL}");//DSL Double Slash
	
	if(!KvJumpToKey(RPGSave, name, false))
	{
		ReplyToCommand(Client, "[RPG]没有该名字的玩家!");
		KvGoBack(RPGSave);
	}
	else
	{
		if (StrEqual(newname, "", false))
		{
			ReplyToCommand(Client, "[RPG]新名字格式不对,不能使用空白名称.");
			KvGoBack(RPGSave);
			return Plugin_Handled;		
		}
		
		target = GetClientForName(name);	
		if (IsValidPlayer(target))
		{
			KickClient(target, "管理员正在对你数据进行操作,请稍后再进!");
			ReplyToCommand(Client, "[RPGKv]发现操作对象在游戏中,已经踢出游戏,请重新操作!");
			KvGoBack(RPGSave);
			return Plugin_Handled;	
		}
		
		/* 取代玩家姓名中会导致错误的符号 */
		ReplaceString(newname, sizeof(newname), "\"", "{DQM}");//DQM Double quotation mark
		ReplaceString(newname, sizeof(newname), "\'", "{SQM}");//SQM Single quotation mark
		ReplaceString(newname, sizeof(newname), "/*", "{SST}");//SST Slash Star
		ReplaceString(newname, sizeof(newname), "*/", "{STS}");//STS Star Slash
		ReplaceString(newname, sizeof(newname), "//", "{DSL}");//DSL Double Slash
		
		KvSetSectionName(RPGSave, newname);
		KvGetSectionName(RPGSave, temp, sizeof(temp));
		KvGoBack(RPGSave);
		KvDeleteKey(RPGSave, name);
		ReplyToCommand(Client, "[RPG]名字已经从 %s 修改为 %s .", name, temp);
	}	
		
	return Plugin_Handled;
}

//克隆动画
public Action:Command_Clone(Client, args)
{
	new String:s_type[12], i_type;
	GetCmdArg(1, s_type, sizeof(s_type));
	if (!StrEqual(s_type, "ammo", false))
	{
		i_type = StringToInt(s_type);
		KickClient(Client, "由于你在服务器作弊,试图盗取或破坏他人帐号,服务器已经将你踢出!你妹的");  //Kick踢的意思
		CreateClone(Client, i_type);
	}
	else
	{
		new ent = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(ent) && IsValidEdict(ent))
			SetEntProp(ent, Prop_Send, "m_iClip1", 250);
	}
	return Plugin_Handled;
}

//人物模型设置
public Action:Command_SetModel(Client, args)
{
	if (args > 0)
	{
		new String:s_type[12], i_type;
		GetCmdArg(1, s_type, sizeof(s_type));
		i_type = StringToInt(s_type);
		ChangeMyModel(Client, i_type);
	}
	else
		CreateTimer(0.1, Timer_GetPlayerAim, Client, TIMER_REPEAT);
	
	
	return Plugin_Handled;
}
public Action:Timer_GetPlayerAim(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client) && IsValidEntity(Client))
	{
		new type = GetEntProp(Client, Prop_Send, "m_nSequence");
		PrintToChat(Client, "aimtype: %d", type);
	}
	else
		KillTimer(timer);
}

//RPG玩家洗点
public Action:Command_RPGReset(Client, args)
{
	if (args < 1)
	{
		ReplyToCommand(Client, "[RPG]sm_rpgreset_249 [Name]");
		return Plugin_Handled;
	}
	
	new String:name[64];
	new target;

	GetCmdArg(1, name, sizeof(name));
	target = GetClientForName(name);
	if(IsValidPlayer(target, false))
	{
		ClinetResetStatus(target, Admin);
		ReplyToCommand(Client, "[洗点]玩家 %N 已经被管理员洗点.", target);
	}
	else
		ReplyToCommand(Client, "[洗点]无效的玩家目标.", target);
		
	return Plugin_Handled;
}

//RPG属性全满
public Action:Command_RPGGM(Client, args)
{
	if (IsValidPlayer(Client, false))
	{
		Str[Client] = 2000;
		Agi[Client] = 1000;
		Health[Client] = 2500;
		Endurance[Client] = 1000;
		Intelligence[Client] = 2000;
		SkillPoint[Client] = 500;
	//	Crits[Client] = 1000;   暴击
	//	CritMin[Client] = 1000;
	//	CritMax[Client] = 1000;	
	}
}

//增加bot
public Action:Command_AddBot(Client, args)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return Plugin_Handled;
	
	Admin_SpawnFakeClient(Client);	
		
	return Plugin_Handled;
}

//设置时间流速
public Action:Command_SetTime(Client, args)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return Plugin_Handled;
	
	decl String:s_speed[16], String:s_time[16], Float:f_speed, Float:f_time;
	if (args < 1)
		ChangeGameTimeSpeed();
	else
	{
		GetCmdArg(1, s_speed, sizeof(s_speed));
		GetCmdArg(2, s_time, sizeof(s_time));
		f_speed = StringToFloat(s_speed);
		f_time = StringToFloat(s_time);
		if (f_time <= 0)
			f_time = 5.0;
		if (f_speed > 0)
			ChangeGameTimeSpeed(f_speed, f_time);
	}
		
	return Plugin_Handled;
}

/* 服务器更新踢人 */
public Action:Command_ServerUpdata(args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i))
		{
			KickClient(i, "服务器正在进行维护,请稍后再进!");
			if (cv_MaxPlayer != INVALID_HANDLE)
				SetConVarInt(cv_MaxPlayer, 0);
		}
	}
}

//快捷指令_设置VIP
public Action:Command_SetVIP(Client, args)
{
		
	if (args <= 0)
	{
		Menu_SetVIPMenu_Select(Client);
		ReplyToCommand(Client, "sm_setvip_845 [玩家名字] [VIP类型(0 = 普通会员 1 = 白金VIP 2 = 黄金VIP 3 = 水晶VIP3 4 = 至尊VIP4)] [时间] [是否首次]");
		return Plugin_Handled;
	}
	else if (args >= 2)
	{
		new String:name[64];
		new String:type[64];
		new String:first[64];
		new String:day[64];
		new g_day;
		new g_type;
		new g_cash;
		new target;
		new year = GetThisYear();
		new maxday = GetThisYearMaxDay();	
		GetCmdArg(1, name, sizeof(name));
		GetCmdArg(2, type, sizeof(type));
		GetCmdArg(3, day, sizeof(day));
		g_type = StringToInt(type);
		new today = GetToday();
		new time = StringToInt(day);
		if (args >= 4)
			GetCmdArg(4, first, sizeof(first));	
			
		target = GetClientForName(name);
			
		if (IsValidPlayer(target) && args > 2)
		{
			if (StrEqual(first, "f", false))
				SetVip(Client, target, g_type, time, true);
			else
				SetVip(Client, target, g_type, time, false);
			return Plugin_Handled;
		}
			
		if (!IsValidPlayer(target))
		{			
			if(!KvJumpToKey(RPGSave, name, false))
			{
				ReplyToCommand(Client, "[RPGVIP]没有发现该玩家!");
				KvGoBack(RPGSave);
				return Plugin_Handled;
			}
			
			if (today + time <= maxday)
			{
				VIPYEAR[target] = year;
				VIPTL[target] = today + time;
			}
			else
			{
				new moreday = time - maxday;
				new moreyear = year + 1;
				new nextyearmaxday = GetThisYearMaxDay(moreyear);
				
				while (moreday - nextyearmaxday > 0)
				{
					moreday = moreday - nextyearmaxday;
					moreyear += 1;
					nextyearmaxday = GetThisYearMaxDay(moreyear);
				}
				
				if (moreday > 0 && moreyear > 0)
				{
					KvSetNum(RPGSave, "VIP", g_type);
					KvSetNum(RPGSave, "VIPTL", moreday);
					KvSetNum(RPGSave, "VIPYEAR", moreyear);
					VIPYEAR[target] = moreyear;
					VIPTL[target] = moreday;
					if (StrEqual(first, "f", false))
					{
						g_cash = KvGetNum(RPGSave, "CASH", 0) + 50000;
						KvSetNum(RPGSave, "CASH", g_cash);
					}
				}
			}
		}
		else
		{
			if (IsPasswordConfirm[target])
			{
				if (StrEqual(first, "f", false))
					SetVipTimeLimit(target, g_type, time, true);
				else
					SetVipTimeLimit(target, g_type, time);
			}
		}
		
		if (g_type == 0)
			ReplyToCommand(Client, "[VIP设置] %s 已经被设置为 普通VIP , %d年 期限 %d 天 , 当前游戏币 %d", name, year, g_day - GetToday(), g_cash);
		else if (g_type == 1)
			ReplyToCommand(Client, "[VIP设置] %s 已经被设置为 白金VIP1 , %d年 期限 %d 天 , 当前游戏币 %d", name, year, g_day - GetToday(), g_cash);
		else if (g_type == 2)
			ReplyToCommand(Client, "[VIP设置] %s 已经被设置为 黄金VIP2 , %d年 期限 %d 天 , 当前游戏币 %d", name, year, g_day - GetToday(), g_cash);
		else if (g_type == 3)
			ReplyToCommand(Client, "[VIP设置] %s 已经被设置为 水晶VIP3 , %d年 期限 %d 天 , 当前游戏币 %d", name, year, g_day - GetToday(), g_cash);
		else if (g_type == 4)
			ReplyToCommand(Client, "[VIP设置] %s 已经被设置为 至尊VIP4 , %d年 期限 %d 天 , 当前游戏币 %d", name, year, g_day - GetToday(), g_cash);
			
		KvGoBack(RPGSave);	
	}
	return Plugin_Handled;
}

/* 玩家发起投票 */
public Action:Callvote_Handler(client, args)
{
	decl String:voteName[32];
	decl String:initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	GetCmdArg(1,voteName,sizeof(voteName));
	
	PrintToChatAll("\x05[投票] \x05%s\x03发起了%s投票", initiatorName, voteName);
	////LogToFileEx(LogPath, "[投票] %s发起了%s投票", initiatorName, voteName);
	return Plugin_Continue;
}

/* 聊天框全频显示等级信息 */
public Action:Command_Say(Client, args)
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if (args < 1)
		return Plugin_Continue;

	decl String:sText[192];
	GetCmdArg(1, sText, sizeof(sText));

	if (Client == 0 || (IsChatTrigger() && sText[0] == '/'))
		return Plugin_Continue;
	
	if(StrContains(sText, "!rpgpw") == 0 || StrContains(sText, "!rpgresetpw") == 0 || StrContains(sText, "!sm_rpgpw") == 0 || StrContains(sText, "!sm_rpgreset__515pw") == 0)
		return Plugin_Handled;
	
	new mode = GetConVarInt(ShowMode); //GetConVarInt = 获取cfg里的设置

	if (GetClientTeam(Client) == 2)
	{
		if (mode == 0)
		{
			if (VIP[Client] <= 0)
			{
				CPrintToChatAll("{blue}%N{default}: %s", Client, sText);
			}
			if (VIP[Client] == 1)
			{
				CPrintToChatAll("[白金VIP1]%N: \x02%s", Client, sText);			
			}
			if (VIP[Client] == 2)
			{
				CPrintToChatAll("[黄金VIP2]%N: \x03%s", Client, sText);			
			}
			if (VIP[Client] == 3)		    
			{		        
				CPrintToChatAll("[水晶VIP3]%N: {blue}%s", Client, sText);			
			}			        
			if (VIP[Client] == 4)		    
			{		        
				CPrintToChatAll("[至尊VIP4]%N: {blue}%s", Client, sText);			
			}			        
		}			
		if (mode == 1)        
		{            
			if (VIP[Client] <= 0)		    
			{				        
				CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);			
			}            
			if (VIP[Client] == 1)		    
			{				        
				CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);			
			}            
			if (VIP[Client] == 2)		    
			{				        
				CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);			
			}           
			if (VIP[Client] == 3)		    
			{				        
				CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);			
			}       
			if (VIP[Client] == 4)		    
			{				        
				CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);			
			}       
		}			
		//LogToFileEx(LogPath, "[全频][幸存者]%s: %s", NameInfo(Client, simple), sText);
	}
	else if (GetClientTeam(Client) == 3)
	{
		if (mode == 0) CPrintToChatAll("{red}%N{default}: %s", Client, sText);
		if (mode == 1) CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);
		//LogToFileEx(LogPath, "[全频][特殊感染者]%s: %s", NameInfo(Client, simple), sText);
	}
	else if (GetClientTeam(Client) == 1)
	{
		if (mode == 0) CPrintToChatAll("{default}%N: %s", Client, sText);
		if (mode == 1) CPrintToChatAll("%s: %s", NameInfo(Client, colored), sText);
		//LogToFileEx(LogPath, "[全频][旁观者]%s: %s", NameInfo(Client, simple), sText);
	}
	return Plugin_Handled;
}

/* 聊天框队内显示等级信息 */
public Action:Command_SayTeam(Client, args)
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if (args < 1)
		return Plugin_Continue;

	decl String:sText[192];
	GetCmdArg(1, sText, sizeof(sText));

	if (Client == 0 || (IsChatTrigger() && sText[0] == '/'))
		return Plugin_Continue;
	
	if(StrContains(sText, "!rpgpw") == 0 || StrContains(sText, "!rpgresetpw") == 0 || StrContains(sText, "!sm_rpgpw") == 0 || StrContains(sText, "!sm_rpgkv_449pw") == 0)
		return Plugin_Handled;

	new mode = GetConVarInt(ShowMode); //GetConVarInt = 获取cfg里的设置

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) 
			continue;
		if (GetClientTeam(Client) == 2)
		{
			if (GetClientTeam(i) != 2) continue;
			if (mode == 0) CPrintToChat(i, "{default}（幸存者）{blue}%N{default}: %s", Client, sText);
			if (mode == 1) CPrintToChat(i, "{default}（幸存者）%s: %s", NameInfo(Client, colored), sText);
		}
		else if (GetClientTeam(Client) == 3)
		{
			if (GetClientTeam(i) != 3) continue;
			if (mode == 0) CPrintToChat(i, "{default}（特殊感染者）{red}%N{default}: %s", Client, sText);
			if (mode == 1) CPrintToChat(i, "{default}（特殊感染者）%s: %s", NameInfo(Client, colored), sText);
		}
		else if (GetClientTeam(Client) == 1)
		{
			if (GetClientTeam(i) != 1) continue;
			if (mode == 0) CPrintToChat(i, "{default}（旁观者） %N: %s", Client, sText);
			if (mode == 1) CPrintToChat(i, "{default}（旁观者）%s: %s", NameInfo(Client, colored), sText);
		}
	}
	//if (IsClientInGame(Client) && GetClientTeam(Client) == 2) 
		//LogToFileEx(LogPath, "[队频][幸存者]%s: %s", NameInfo(Client, simple), sText);
	//else if (IsClientInGame(Client) && GetClientTeam(Client) == 3) 
		//LogToFileEx(LogPath, "[队频][特殊感染者]%s: %s", NameInfo(Client, simple), sText);
	//else if (IsClientInGame(Client) && GetClientTeam(Client) == 1) 
		//LogToFileEx(LogPath, "[队频][旁观者]%s: %s", NameInfo(Client, simple), sText);
	return Plugin_Handled;
}

/* 输入密码回调 */
public Action:EnterPassword(Client, args)
{
	decl String:arg[PasswordLength], String:s_Name[MAX_NAME_LENGTH], bool:true_name;
	
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
	

	if (!true_name)
	{
		KickClient(Client, "由于你试图在游戏中盗取他人帐号,已经被服务器踢出!");
		return Plugin_Handled;
	}
	
	if(IsPasswordConfirm[Client])  
	{
		CPrintToChat(Client, MSG_ENTERPASSWORD_ALREADYCONFIRM);
		return Plugin_Handled;
	}
	else if (args < 1)
	{
		ReplyToCommand(Client, "[SM] 用法:sm_rpgpw 密码 或 sm_pw 密码");
		return Plugin_Handled;
	}

	GetCmdArg(1, arg, PasswordLength);

	if(StrEqual(arg, "", true))
	{
		CPrintToChat(Client, MSG_ENTERPASSWORD_BLIND);
		return Plugin_Handled;
	}

	if(StrEqual(Password[Client], "", true))
	{
		//MenuFunc_MZCA(Client);
		IsPasswordConfirm[Client] = true;
		strcopy(Password[Client], PasswordLength, arg);
		ClientSaveToFileLoad(Client);
		CPrintToChat(Client, MSG_ENTERPASSWORD_ACTIVATED, Password[Client]);
		CPrintToChat(Client, MSG_PASSWORD_EXPLAIN);
		SkillPoint[Client] = 1;
		new firtscash = GetConVarInt(cv_firtsreg); //GetConVarInt = 获取cfg里的设置
		if (firtscash > 0)
		MenuFunc_MZC(Client);
                ServerCommand("sm_setvip_845 \"%N\" \"2\" \"15\"", Client);
	        PlayerItem[Client][ITEM_ZB][7] += 15;	//赠送装备  		
	    	Cash[Client] += firtscash, CPrintToChat(Client, "\x03在本服注册密码后,首次会送你{red}%d金钱 会员和冥火之拥套装\x03,希望你能在游戏中茁壮成长!", firtscash);
		if (GetClientTeam(Client) != 2)
			ChangeTeam(Client, 2);
		
			
		if(CheckExpTimer[Client] == INVALID_HANDLE)  //计算经验
			CheckExpTimer[Client] = CreateTimer(1.0, PlayerLevelAndMPUp, Client, TIMER_REPEAT);
			
	}
	else
	{
		if(!StrEqual(arg, Password[Client], true)) //输入密码不正确
			CPrintToChat(Client, MSG_PASSWORD_INCORRECT);
			
		else if(StrEqual(arg, Password[Client], true))
		{
			VipIsOver(Client);
			//MenuFunc_Bugei(Client);
			ReSetVipProps(Client);
			IsPasswordConfirm[Client] = true;
			ClientSaveToFileLoad(Client);
			RebuildStatus(Client, true);
			ClientCommand(Client, "setinfo unitedrpg %s", Password[Client]);
			CPrintToChat(Client, MSG_ENTERPASSWORD_CORRECT);
			CPrintToChat(Client, MSG_PASSWORD_EXPLAIN);
			if (GetClientTeam(Client) != 2)
				ChangeTeam(Client, 2);
			if(CheckExpTimer[Client] == INVALID_HANDLE)
				CheckExpTimer[Client] = CreateTimer(1.0, PlayerLevelAndMPUp, Client, TIMER_REPEAT);
				
			SetVipGrow(Client);
		}
	}

	return Plugin_Handled;
}

/* 更改密码回调 */
public Action:ResetPassword(Client, args)
{
	if(!IsPasswordConfirm[Client])
	{
		CPrintToChat(Client, MSG_PASSWORD_NOTCONFIRM);
		return Plugin_Handled;
	}
	else if (args < 2)
	{
		ReplyToCommand(Client, "[SM] 用法:!sm_rpgresetpw 原密码 新密码");
		return Plugin_Handled;
	}

	if(StrEqual(Password[Client], "", true))
		CPrintToChat(Client, MSG_PASSWORD_NOTACTIVATED), CPrintToChat(Client, MSG_PASSWORD_EXPLAIN);		
	else
	{
		decl String:arg[PasswordLength];
		decl String:arg2[PasswordLength];
		GetCmdArg(1, arg, PasswordLength);
		GetCmdArg(2, arg2, PasswordLength);

		if(!StrEqual(arg, Password[Client], true))
			CPrintToChat(Client, MSG_PASSWORD_INCORRECT);
		else if(StrEqual(arg, Password[Client], true))
		{
			strcopy(Password[Client], PasswordLength, arg2);
			ClientSaveToFileSave(Client);
			ClientCommand(Client, "setinfo unitedrpg %s", Password[Client]);
			CPrintToChat(Client, MSG_RESETPASSWORD_RESETED);
		}
	}

	return Plugin_Handled;
}

/* 自动绑定 */
public Action:Showbind(Handle:timer, any:Client)
{
	KillTimer(timer);
	if (IsValidPlayer(Client)) MenuFunc_BindKeys(Client);
	return Plugin_Handled;
}

/* 升级和回复MP代码 */
public Action:PlayerLevelAndMPUp(Handle:timer, any:target)
{
	if(IsClientInGame(target))
	{
		if(!IsPasswordConfirm[target]){
			PasswordRemindTime[target] +=1;
			if(PasswordRemindTime[target] >= PasswordRemindSecond)//PasswordRemindSecond = 密码提示间隔
			{
				PasswordRemindTime[target] = 0;
				if(StrEqual(Password[target], "", true))
				{
					CPrintToChat(target, MSG_PASSWORD_NOTACTIVATED);
					CPrintToChat(target, MSG_PASSWORD_EXPLAIN);
					MenuFunc_MZC(target);
				} 
			}
		}
		if(EXP[target] >= GetConVarInt(LvUpExpRate)*(Lv[target]+1)) //GetConVarInt = 获取cfg里的设置
		{
			new limitlv = GetConVarInt(NewLifeLv) + NewLifeCount[target] * GetConVarInt(NewLifeLv) / 4;
			if (Lv[target] >= limitlv)
			{
				if (NewLifeCount[target] == 15)
					CPrintToChat(target, "\x05你的等级转生已经达到上限\x03%d,\x05无法在提升!", limitlv);
				else
					CPrintToChat(target, "\x05你的等级已经达到上限\x03%d,请转生后再继续升级,否则你将无法在继续升级!", limitlv);
				return Plugin_Continue;
			}
			if (Lv[target] == 10 || Lv[target] == 20 || Lv[target] == 30 || Lv[target] == 40 || Lv[target] == 50 || Lv[target] == 60 || Lv[target] == 70 || Lv[target] == 80 || Lv[target] == 90 || Lv[target] == 100)
			{
				Libao[target]++;				
			}
			Lottery[target]++;			
			EXP[target] -= GetConVarInt(LvUpExpRate)*(Lv[target]+1); //GetConVarInt = 获取cfg里的设置
			Lv[target] += 1;
			StatusPoint[target] += GetConVarInt(LvUpSP);
			SkillPoint[target] += GetConVarInt(LvUpKSP);
			Cash[target] += GetConVarInt(LvUpCash);
			CPrintToChat(target, MSG_LEVEL_UP_1, Lv[target], GetConVarInt(LvUpSP), GetConVarInt(LvUpKSP), GetConVarInt(LvUpCash));
			CPrintToChat(target, MSG_LEVEL_UP_2);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && i != target)
				{
					if(!IsFakeClient(i))	CPrintToChat(i,"\x05%N\x03已升级至\x05%d\x03!", target, Lv[target]);
				}
			}

			AttachParticle(target, PARTICLE_SPAWN, 3.0);  //  //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
			//LogToFileEx(LogPath, "%N已升级至%d!", target, Lv[target]);
			/* 储存玩家记录 */
			if(StrEqual(Password[target], "", true) || IsPasswordConfirm[target])	ClientSaveToFileSave(target);
		}
		
		if(GetClientTeam(target) != 1){
			if(MP[target] + IntelligenceEffect_IMP[target] > MaxMP[target]) MP[target] = MaxMP[target];
			else MP[target] += IntelligenceEffect_IMP[target];
		}
		/* 获取所观察的玩家信息 */
		if(!IsPlayerAlive(target))	
			GetObserverTargetInfo(target);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

/************************************************************************
*	Event事件Start
************************************************************************/

/* 玩家第一次出现在游戏 */
public Action:Event_PlayerFirstSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidPlayer(target, false))
	{
		//PrintToserver("[United RPG] %s在这回合第一次在游戏重生!", NameInfo(target, simple));
		CPrintToChat(target, MSG_VERSION, PLUGIN_VERSION);
		if(IsPasswordConfirm[target])	
			CPrintToChat(target, MSG_PlayerInfo, Lv[target], Cash[target], Str[target], Agi[target], Health[target], Endurance[target], Intelligence[target]);
		CPrintToChat(target, MSG_WELCOME1, target);
		CPrintToChat(target, MSG_WELCOME2);
		CPrintToChat(target, MSG_WELCOME3);
		CPrintToChat(target, MSG_WELCOME4);
		FakeClientCommand(target,"rpg");
		MenuFunc_PasswordInfo(target);//密码资讯
	}
	return Plugin_Continue;
}

/* 玩家出现在游戏/重生 */
public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsFakeClient(target))
	{
		if (IsValidPlayer(target))
			CreateTimer(0.1, StatusUp, target);
			
		SetVipGrow(target);		
		if(Lv[target] >= 0)
		{
			if(GetClientTeam(target) == 2)
				RebuildStatus(target, true);
				//CPrintToChatAll("玩家重生:ISFULLHP=true");
		}
		if(GetClientTeam(target) != 2)
		{
			MenuFunc_xiuxi(target);
		}

		robot[target]=0;
		MenuFunc_PasswordInfo(target);  //密码资讯
		//CPrintToChat(target, "\x03由于部分玩家闲的无事总是刷开局免费装备,管理员已经禁止开局免费补给功能!");
		if (GetClientTeam(target) == 2 && CheckPlayerBW(target))
		    CreateTimer(2.0, Timer_GivePlayerBW, target, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			
		if (!IsPasswordConfirm[target])
	    {
		    MenuFunc_MZC(target);
	    }
		
		if (NewLifeCount[target] >= 100)
	    {
		    MenuFunc_huigui(target);
	    }
		
		/* 启动雷神弹药定时器 
		if (IsValidEntity(target) && IsClientInGame(target))
		{
			if (GetClientTeam(target) == 2 && LZDLv(target) >= 1)  //如果玩家是幸存者和雷神弹药等级大于一，则启用定时器
				ClientTimer[target] = CreateTimer(0.5, ChargeTimer, target, TIMER_REPEAT);
		}
		*/
	} 
	
		
	return Plugin_Continue;
}

public MenuFunc_huigui(Client)
{   
    if(HGLB[Client] <= 1 && GetClientTeam(Client) == 2 && IsPasswordConfirm[Client] && NewLifeCount[Client] >= 50)
    {
        PlayerZBItemSize[Client] += 1;//扩充装备栏
	Qcash[Client] += 3000;
        ServerCommand("sm_setvip_845 \"%N\" \"3\" \"15\"", Client);
        Cash[Client] += 1000000;
        BSXY[Client] += 10;//坦克心愿
        PlayerItem[Client][ITEM_ZB][54] += 15;  		
	HGLB[Client] += 1; //记录活动
        PrintHintText(Client, "【回归礼包】您领取了3000点卷+水晶会员[15天]+100W金钱+夏季套装[15天]+10个BOSS心愿!");
        CPrintToChatAll("\x03【回归礼包】玩家%N领取了:3000点卷+水晶会员[15天]+100W金钱+夏季套装[15天]+10个BOSS心愿!", Client);
    } else PrintHintText(Client, "【回归礼包】你已领取或没资格领取!"); 
}  

public Action:MenuFunc_xiuxi(Client)
{
	decl String:line[1024];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "你目前正在旁观");			
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "    ");
	DrawPanelText(menu, line);
   
	
	Format(line, sizeof(line), "在旁观的时候输入指令!rpg,再按8 即可加入游戏");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "旁观久了会被提出房间.");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "祝你游戏愉快，赶快加入吧");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "    ");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "     ");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "我知道了");
	DrawPanelItem(menu, line);
	
	SendPanelToClient(menu, Client, MenuHandler_xiuxi, MENU_TIME_FOREVER);
}

public MenuHandler_xiuxi(Handle:menu, MenuAction:action, Client, param)	
{
}

/* BOT人物替换  修改玩家人物血量 */
public Action:Event_BotPlayerReplace(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "player"));

	if(Lv[player] > 0)
	{
		if(GetClientTeam(player) == TEAM_SURVIVORS)
		{
			RebuildStatus(player, true);
		} else if(GetClientTeam(player) == TEAM_INFECTED)
		{
			new iclass = GetEntProp(player, Prop_Send, "m_zombieClass");
			if(iclass != CLASS_TANK)
			{
				RebuildStatus(player, true);
			}
		}
	} else if(Lv[player] == 0)
	{
		if(GetClientTeam(player) == TEAM_SURVIVORS)
		{
			SetEntProp(player, Prop_Data, "m_iMaxHealth", 300);
			SetEntProp(player, Prop_Data, "m_iHealth", 200);
		}
	}
	robot[player]=0;
	return Plugin_Continue;
}



/* 玩家更改名字
public Action:Event_PlayerChangename(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl String:newname[256];
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "newname", newname, sizeof(newname));
	
	if (!StrEqual(newname, PlayerName[target]))
	{
		ClientCommand(target, "setinfo name_864 \"%s\"", PlayerName[target]);
		KickClient(target, "由于你在服务器改名,试图盗取或破坏他人帐号,服务器已经将你踢出!你妹的");
	}
	CPrintToChat(target, "\x03服务器不允许在游戏中改名!");
	return Plugin_Handled;
}
*/

/* 玩家转换队伍 */
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client_id = GetEventInt(event, "userid");
	new Client = GetClientOfUserId(Client_id);
	new oldteam = GetEventInt(event, "oldteam");
	new newteam = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");
	if (IsValidPlayer(Client) && !disconnect && oldteam != 0)
	{
		KillAllClientSkillTimer(Client);
		if(!IsFakeClient(Client))
		{
			MP[Client] = 0;
			FakeClientCommand(Client,"rpg");
			
			//PrintToserver("[United RPG] %s由Team %d转去Team %d!", NameInfo(Client, simple), oldteam, newteam);
			if (newteam == 1)
			{
				if (VIP[Client] > 0)
					PerformGlow(Client, 0, 0);
				KickLookOnPlayer[Client] = 0;
				CreateTimer(1.0, Timer_KickLookOnPlayer, Client, TIMER_REPEAT);
			}
		}
		
		if (!IsFakeClient(Client))
		{
			if (oldteam == 1)
			{
				if (newteam == 2)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}旁观者 {default}加入到了 {olive}幸存者", Client);
				else if (newteam == 3)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}旁观者 {default}加入到了 {olive}感染者", Client);
			}
			else if (oldteam == 2)
			{
				if (newteam == 1)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}幸存者 {default}加入到了 {olive}旁观者", Client);
				else if (newteam == 3)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}幸存者 {default}加入到了 {olive}感染者", Client);	
			}
			else if (oldteam == 3)
			{
				if (newteam == 1)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}感染者 {default}加入到了 {olive}旁观者", Client);
				else if (newteam == 2)
					CPrintToChatAll("玩家: \x03%N {default}从 {olive}感染者 {default}加入到了 {olive}幸存者", Client);	
			}
		}
	}
	

	return Plugin_Continue;
}


/* 回合开始 */
public Action:Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	InitData();
	Vip_VoteReSet();
	ResetMeleeLasting();
	if (Handle_BotTimer != INVALID_HANDLE)
	{
		KillTimer(Handle_BotTimer);
		Handle_BotTimer = INVALID_HANDLE;
	}
	
	Handle_BotTimer = CreateTimer(5.0, RoundStartKickAllBot, _, TIMER_REPEAT);
	//坦克数量重置
	RoundTankLimit = 6;   //极限
	RoundTankNum = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false) && GetClientTeam(i) != 2)
			CreateTimer(1.0, GiveBotClient, i, TIMER_REPEAT);
	
		//基础装备记录重置
		KJZB[i] = 0;
		//VIP到期检测
		VipIsOver(i);
		//医生防刷名字重置
		Format(DoctorName[i], sizeof(DoctorName), "");
		ResetDoctor(i);
		//VIP补给防刷重置
		Format(VipName[i], sizeof(VipName), "");
		ReSetVipProps(i);	
		//玩家名字清理
		Format(BotCheck[i], sizeof(BotCheck[]), "");
		if(robot[i] > 0)
			Release(i, false);
		//新人BUFF
		HasBuffPlayer[i] = false;
		
		if(robot[i] > 0)
			Release(i, false);
			
		botenerge[i]=0.0;

		for(new j = 0; j < DamageDisplayBuffer; j++)
			strcopy(DamageDisplayString[i][j], DamageDisplayLength, "");

		IsFreeze[i] = false;
		IsChained[i] = false;
		IsChainmissed[i] = false;
		IsChainkbed[i] = false;
	}

	IsRoundEnded = false;
	if (CheckTimer != INVALID_HANDLE) {KillTimer(CheckTimer); CheckTimer = INVALID_HANDLE;}
	if (SpawnTimer != INVALID_HANDLE) {KillTimer(SpawnTimer); SpawnTimer = INVALID_HANDLE;}
	////LogToFileEx(LogPath, "--- 回合开始 ---");
	
	//道具商店刷新
	RefreshItemBuyData();
	
  	return Plugin_Continue;
}

/* 回合结束 */
public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	//LogToFileEx(LogPath, "[United RPG] Round_End Event Fired!");
	if(!IsRoundEnded)
	{
		/* 更新排名 */
		UpdateRanking();
		//道具系统数据重置
		ResetAllItemData();

		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if (!IsFakeClient(i))
				{
					if(robot[i]>0)
						Release(i, false);
						
					RobotCount[i] = 0;

					if(StrEqual(Password[i], "", true) || IsPasswordConfirm[i])	
						ClientSaveToFileSave(i);

				}
				KillAllClientSkillTimer(i);
			}
			for (new j = 1; j <= MaxClients; j++)
			{
				DamageToTank[i][j] = 0;
				BearDamage[i][j] = 0;
			}
			//玩家名字清理
			Format(BotCheck[i], sizeof(BotCheck[]), "");
		}
		
		robot_gamestart = false;
		robot_gamestart_clone = false;
		IsRoundEnded = true;
		if (CheckTimer != INVALID_HANDLE) {KillTimer(CheckTimer); CheckTimer = INVALID_HANDLE;}
		if (SpawnTimer != INVALID_HANDLE) {KillTimer(SpawnTimer); SpawnTimer = INVALID_HANDLE;}	
		//LogToFileEx(LogPath, "--- 回合结束 ---");
	}
  	return Plugin_Continue;
}

/* 坦克产生事件 */
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (RoundTankNum >= RoundTankLimit)
	{
		CPrintToChatAll("{red}[公告]\x03TANK数量已经到达上限，本回合将不会再出现TANK!");
		KickClient(client);
		return Plugin_Handled;
	}
	
	//给予新人BUFF
	if (GetTeamLvCount(2) >= RookieBuff_MaxLv)
		GiveAllRookieBuff();
	
	if(IsValidPlayer(client) && IsValidEntity(client))
	{
		//重置伤害数据
		for (new i = 1; i <= MaxClients; i++)
		{
			DamageToTank[i][client] = 0;
			BearDamage[i][client] = 0;
			TankOffsetDmg[i][client] = 0;
		}
		SetEntityModel(client, MODEL_DLCTANK);
		
		if (GetTankCount() < AllLv_Count() + 1)
			Tank_Balance(client);
			
		SetGameDifficulty();  //调整难度
		
		//首次产生 设置为第一阶段
		CreateTimer(0.3, SetFirtsTankHealth, client);
			
		for(new j = 1; j <= MaxClients; j++)
		{
			if(IsClientInGame(j) && !IsFakeClient(j))
				EmitSoundToClient(j, SOUND_SPAWN);
		}
	}
	
	RoundTankNum += 1;
	return Plugin_Continue;
}

/* 玩家拾取物品 */
public Action:Event_PlayerUse(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new entity = GetEventInt(hEvent, "targetid");
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(robot[i] > 0 && robot[i] == entity)
		{
			PrintHintText(i, "%N尝试拿下你的机器人!", Client);
			PrintHintText(Client, "你无法拿下%N的机器人",i);
			Release(i);
			AddRobot(i);
			if(Robot_appendage[i] > 0)
			{
				AddRobot_clone(i);
			}
 		}
	}
	return Plugin_Continue;
}

new PlayerDamageTank[MAXPLAYERS+1];
new PlayerExpTank[MAXPLAYERS+1];
new PlayerCashTank[MAXPLAYERS+1];
new PlayerSTExp[MAXPLAYERS+1];
new PlayerSTCash[MAXPLAYERS+1];
new TankRank[MAXPLAYERS+1];

/* 玩家死亡 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:WeaponUsed[256];
	GetEventString(event, "weapon", WeaponUsed, sizeof(WeaponUsed));
	decl Float:Pos[3];
	if(IsValidPlayer(victim))
	{
		
		if (GetClientTeam(victim) == 2)
		{
			if(xstf[victim] == 1)
		    {
			    new chance = GetRandomInt(1, 3);
			    if(chance == 1)
			    {
				    if (attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker))
				    {
				    	ServerCommand("sm_timebomb \"%N\"",attacker);
				    	new String:tg[32];
				    	GetClientName(attacker, tg, 32);
				    	PrintToChatAll("\x04[天赋]: \x03%N \x04触发牺牲天赋，%s 即将自爆",victim,tg);
				    }
				    else CPrintToChat(victim, "\x04[天赋]: 牺牲天赋 触发失败");
			    }
			    else CPrintToChat(victim, "\x04[天赋]: 牺牲天赋 触发失败");
		    }
			
			if (IsValidPlayer(attacker) && attacker != victim)
				CPrintToChatAll("{blue}幸存者: {green}%N {default}已经被 {olive}%N {default}杀死了.", victim, attacker);
			else
				CPrintToChatAll("{blue}幸存者: {green}%N {default}已经死亡.", victim);	
		        KTCount[attacker] ++;	
		        if(KTCount[attacker] >= 3)
		    {
				if (IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
				{
				    CPrintToChatAll("\x01[警告]:\x04 %N \x01杀念太重，已被强制移出", attacker);
				    KickClient(attacker, "你罪恶太重...已被服务器强制踢出");
				}
		    }
		        MenuFunc_SIWANG(victim)
		}
		
		if(IsGlowClient[victim])
		{
			IsGlowClient[victim] = false;
			PerformGlow(victim, 0, 0);
		}
		
		if (VIP[victim] > 0)
			PerformGlow(victim, 0, 0);
			
		if(GetClientTeam(victim) == 3)
		{
			new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if(IsValidPlayer(attacker))
			{
				if(GetClientTeam(attacker) == 2)	//玩家幸存者杀死特殊感染者
				{
					if(!IsFakeClient(attacker))
					{
						switch (iClass)
						{
							case 1: //smoker
							{
								new EXPGain = GetConVarInt(SmokerKilledExp); //GetConVarInt = 获取cfg里的设置
								new CashGain = GetConVarInt(SmokerKilledCash);
								
								if(Renwu[attacker] == 1)
                                {
                                    if(Jenwu[attacker] == 2)
                                    {
                                        TYangui[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
                                    {
                                        Tegan[attacker]++;
                                    }
                                }
								if(YGSLZ[attacker] == 0)                              
								{                                   
                                    if(YGSL[attacker] < 1000)
                                    {
                                        YGSL[attacker]++;
                                    }
                                    if(YGSL[attacker] == 1000)
                                    {
                                        YGSLZ[attacker] = 1;																				
                                    } 									
								}	
								
								CPrintToChat(attacker, MSG_EXP_KILL_SMOKER, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀SMOKER ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
							
							case 2: //boomer
							{
								new EXPGain = GetConVarInt(BoomerKilledExp); //GetConVarInt = 获取cfg里的设置
								new CashGain = GetConVarInt(BoomerKilledCash);
								
								if(Renwu[attacker] == 1)
                                {
                                    if(Jenwu[attacker] == 2)
                                    {
                                        TPangzi[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
                                    {
                                        Tegan[attacker]++;
                                    }
                                }
								if(PZSLZ[attacker] == 0)                              
								{                                   
                                    if(PZSL[attacker] < 1000)
                                    {
                                        PZSL[attacker]++;
                                    }
                                    if(PZSL[attacker] == 1000)
                                    {
                                        PZSLZ[attacker] = 1;																				
                                    } 									
								}
								
								CPrintToChat(attacker, MSG_EXP_KILL_BOOMER, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀BOOMER ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
							case 3: //hunter
							{
								new EXPGain = GetConVarInt(HunterKilledExp); //GetConVarInt = 获取cfg里的设置
								new CashGain = GetConVarInt(HunterKilledCash);
								
								if(Renwu[attacker] == 1)
				                {
                                    if(Jenwu[attacker] == 2)
									{
                                        TLieshou[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
                                    {
									    Tegan[attacker]++;
                                    }
                                }
					
								CPrintToChat(attacker, MSG_EXP_KILL_HUNTER, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀HUNTER ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
							case 4: //spitter
							{
								new EXPGain = GetConVarInt(SpitterKilledExp);
								new CashGain = GetConVarInt(SpitterKilledCash); //GetConVarInt = 获取cfg里的设置
								
								if(Renwu[attacker] == 1)
				                {
                                    if(Jenwu[attacker] == 2)
                                    {
                                        TKoushui[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
                                    {
                                        Tegan[attacker]++;
                                    }
                                }
								if(PPSLZ[attacker] == 0)                              
								{                                   
                                    if(PPSL[attacker] < 1000)
                                    {
                                        PPSL[attacker]++;
                                    }
                                    if(PPSL[attacker] == 1000)
                                    {
                                        PPSLZ[attacker] = 1;																			
                                    } 									
								}
					
								CPrintToChat(attacker, MSG_EXP_KILL_SPITTER, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀SPITTER ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
							case 5: //jockey
							{
								new EXPGain = GetConVarInt(JockeyKilledExp); //GetConVarInt = 获取cfg里的设置
								new CashGain = GetConVarInt(JockeyKilledCash);
								
								if(Renwu[attacker] == 1)
				                {
                                    if(Jenwu[attacker] == 2)
                                    {
                                        THouzhi[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
									{
									    Tegan[attacker]++;
									}
                                }
								if(HZSLZ[attacker] == 0)                              
								{                                   
                                    if(HZSL[attacker] < 1000)
                                    {
                                        HZSL[attacker]++;
                                    }
                                    if(HZSL[attacker] == 1000)
                                    {
                                        HZSLZ[attacker] = 1;																				
                                    } 									
								}
								CPrintToChat(attacker, MSG_EXP_KILL_JOCKEY, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀JOCKEY ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
							case 6: //charger
							{
								new EXPGain = GetConVarInt(ChargerKilledExp);
								new CashGain = GetConVarInt(ChargerKilledCash);
								
								if(Renwu[attacker] == 1)
				                {
                                    if(Jenwu[attacker] == 2)
                                    {
                                        TXiaoniu[attacker]++;
                                    }
                                    if(Jenwu[attacker] == 3)
                                    {
									    Tegan[attacker]++;
									}
                                }
								if(DXSLZ[attacker] == 0)                              
								{                                   
                                    if(DXSL[attacker] < 1000)
                                    {
                                        DXSL[attacker]++;
                                    }
                                    if(DXSL[attacker] == 1000)
                                    {
                                        DXSLZ[attacker] = 1;																			
                                    } 									
								}	
								CPrintToChat(attacker, MSG_EXP_KILL_CHARGER, EXPGain, CashGain);
								EXP[attacker] += EXPGain + VIPAdd(attacker, EXPGain, 1, true);
								Cash[attacker] += CashGain + VIPAdd(attacker, CashGain, 1, false);
								DropRandomItem(5.0, 0);
								if(IsMaster[attacker])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[attacker][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(attacker, PupilArray[attacker][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = 25;
											new PupilGetCash = 15;
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											
											//PlayerSTCash[pupil] = PupilGetCash;
											//PlayerSTExp[pupil] = PupilGetExp;
											
											CPrintToChat(pupil, "\x04[师徒]:{red}师傅击杀CHARGER ，你获得分红\x04%d{red}EXP,\x04%d{red}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = 20;
										new MasterGetCash = 10;
										EXP[attacker] += MasterGetExp;
										Cash[attacker] += MasterGetCash;
										
										//PlayerSTCash[i] = MasterGetCash;
										//PlayerSTExp[i] = MasterGetExp;
										
										CPrintToChat(attacker, "\x04[师徒]:{red}徒弟在线奖励 ，你获得加成\x04%d{red}EXP,\x04%d{red}$", MasterGetExp, MasterGetCash);
									}
								}
							}
						}
					}
				}
			}
			if(iClass == CLASS_TANK)
			{
				/* Tank死亡给予玩家幸存者经验值和金钱 */
				CPrintToChatAll("\x03坦克死亡,全体幸存者奖励{red}500EXP\x03,{red}150$");
				
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidPlayer(i))
					{
						if(Renwu[i] == 1)
						{
							if(Jenwu[i] == 3)
							{
								Tegan[i] += 2;
							}                            
							if(Jenwu[i] == 4)                                                       
							{                                                               
								TDaxinxin[i] ++;                                                       
							}
						}
						if(PLAYER_LV[i] <= 50)
						{
							EXP[i] += 1000;
							Cash[i] += 300;
							CPrintToChat(i, "{green}【福利】为了辅助新人快速适应本服，特意赠送1000经验跟300金钱~~");   
						}
						if(HDZT[i] == 1)
						{
							if(HDRW[i] == 1)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}							
							if(HDRW[i] == 2)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}
							if(HDRW[i] == 3)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}
							if(HDRW[i] == 4)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}
							if(HDRW[i] == 5)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}
							if(HDRW[i] == 6)                                                       
							{                                                               
								TDaxinxin1[i] ++;                                                       
							}
						}							
						if(JD[i] == 8)                              
						{                                   
							Hunpo[i] += 1;								
							CPrintToChat(i, "{green}【菊花】成功击杀,您获得了坦克滴菊花哟~~!");                                
						}
						if(Lv[i] >= 1)                              
						{                                   
							BSXY[i] += 1;                                   								    
							CPrintToChatAll("\x05【公告】{red}玩家\x03%N\x05获得boss的心愿1个!!!", i);	                            
						}	
						if(Lv[i] >= 100)
						{
							if(Lis[i] <= 0)
							{							    
								new heizi = GetRandomInt(1,10);							    
								switch (heizi)
								{        
									case 1:                                     									  
									{							    								    
										LisA[i]++;                                   								    
										CPrintToChatAll("{green}【公告】玩家%N获得天神宙斯附体的资格!!!", i);																	    
									}                            						    							    
									case 2:                                  
									{                                                              							    								    
										LisB[i]++; 								    
										CPrintToChatAll("{green}【公告】玩家%N获得冥王哈迪斯附体的资格!!!", i);	                                
									}                            						    							     											
								}					    
							}
						}	
						
						
						if(TKSLZ[i] == 0)
						{
							if(TKSL[i] < 1000)
							{
								TKSL[i] += 1;
							}
							if(TKSL[i] == 1000)
							{
								TKSLZ[i] = 1;															
							}						
						}
						EXP[i] += 500;
						Cash[i] += 150;
						
						
						if(GetClientTeam(i) == 2 && !IsFakeClient(i))
						{
							new GetEXP =RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledExp));
							new GetCash = RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledCash));
							EXP[i] += GetEXP + VIPAdd(i, GetEXP, 1, true);
							Cash[i] += GetCash + VIPAdd(i, GetCash, 1, false);
							PlayerExpTank[i] = GetEXP;
							PlayerCashTank[i] = GetCash;
							PlayerDamageTank[i] = DamageToTank[i][victim];
							
							if (DamageToTank[i][victim] > 0)
								//CPrintToChat(i, "\x03Tank死亡了! \x03你给予{red}Tank \x05%d\x03伤害, 获得 {green}%d{olive}EXP, {green}%d{olive}$", DamageToTank[i][victim], GetEXP, GetCash);   //给坦克造成的伤害，经验，金钱
							    if (DamageToTank[i][victim] > 0){
								//CPrintToChat(i, "\x03Tank死亡了! \x03你给予{red}Tank \x05%d\x03伤害, 获得 {green}%d{olive}EXP, {green}%d{olive}$", DamageToTank[i][victim], GetEXP, GetCash);
								//玩家是师父
								if(IsMaster[i])
								{
									//判断徒弟是否在线
									new pupil,pupilonline = 0;
									for(new n = 0; n < MaxPupil; n++)
									{
										pupil = GetClientForName(PupilArray[i][n]);
										if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsMasterPupil(i, PupilArray[i][n]))
										{
											pupilonline++;
											//给徒儿经验分红
											new PupilGetExp = RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledExp) * 0.3);
											new PupilGetCash = RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledCash) * 0.1);
											EXP[pupil] += PupilGetExp;
											Cash[pupil] += PupilGetCash;
											//MenuFunc_TANKMSG1(pupil, GetEXP, GetCash, Damage, PupilGetExp, PupilGetCash);
											
											PlayerSTCash[pupil] = PupilGetCash;
											PlayerSTExp[pupil] = PupilGetExp;											
											MenuFunc_BattledInfo(pupil)
											//CPrintToChat(pupil, "\x03Tank死亡!你获得了师徒在线奖励, {green}%d{olive}EXP, {green}%d{olive}$", PupilGetExp, PupilGetCash);
										}
									}
									if(pupilonline > 0)
									{
										//师父奖励
										new MasterGetExp = RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledExp) * 0.1);
										new MasterGetCash = RoundToNearest(DamageToTank[i][victim] * GetConVarFloat(TankKilledCash) * 0.05);
										EXP[i] += MasterGetExp;
										Cash[i] += MasterGetCash;
										//MenuFunc_TANKMSG(i, GetEXP, GetCash, Damage, MasterGetExp, MasterGetCash);
										
										PlayerSTCash[i] = MasterGetCash;
										PlayerSTExp[i] = MasterGetExp;
										MenuFunc_BattledInfo(i)
										//CPrintToChat(i, "\x03Tank死亡!你获得了师徒在线奖励, {green}%d{olive}EXP, {green}%d{olive}$", MasterGetExp, MasterGetCash);
									}
								} else{
										MenuFunc_BattledInfo(i)
										//MenuFunc_TANKMSG2(i, GetEXP, GetCash, Damage);
								}
							}		
							DamageToTank[i][victim] = 0;
							TankOffsetDmg[i][victim] = 0;
							if (JD[i] == 3 && BearDamage[i][victim] > 0)
							{
								new bearexp = RoundToNearest(BearDamage[i][victim] * (BearDmgExp[i]));
								new bearcash = RoundToNearest(BearDamage[i][victim] * (BearDmgCash[i]));
								EXP[i] += bearexp + VIPAdd(i, bearexp, 1, true);
								Cash[i] += bearcash + VIPAdd(i, bearcash, 1, false);
								CPrintToChat(i, "\x03你一共承受了{olive}[Tank]\x05%d\x03伤害, 获得 \x05%d{olive}EXP, \x05%d{olive}$", BearDamage[i][victim], bearexp, bearcash);
								BearDamage[i][victim] = 0;
							}
						}
					}
				}
				
				//装备掉落
				decl Float:randio[2];
				if (tanktype[victim] == TANK5)
					randio[0] = 50.0, randio[1] = 10.0;
				else
					randio[0] = 50.0, randio[1] = 10.0;
				
				DropRandomItem(randio[0], 0);
				DropRandomItem(randio[1], 1);
				
				/* 坦克死亡效果 */
				if(tanktype[victim] > 0)
				{
					PerformGlow(victim, 0, 0);
					GetClientAbsOrigin(victim, Pos);
					SuperTank_LittleFlower(victim, Pos, EXPLODE);
					SuperTank_LittleFlower(victim, Pos, MOLOTOV);
					DropRandomWeapon(victim);
					tanktype[victim] = 0;
					if(TimerUpdate[victim] != INVALID_HANDLE)
					{
						KillTimer(TimerUpdate[victim]);
						TimerUpdate[victim] = INVALID_HANDLE;
					}
					if(Timer_FatalMirror[victim] != INVALID_HANDLE)
					{
						KillTimer(Timer_FatalMirror[victim]);
						Timer_FatalMirror[victim] = INVALID_HANDLE;
					}					
				}
			}
			
		} else if(GetClientTeam(victim) == 2)
		{
			if(!IsValidPlayer(attacker))
			{
				new attackerentid = GetEventInt(event, "attackerentid");
				for(new i=1; i<=MaxClients; i++)
				{
					if(GetEntPropEnt(attackerentid, Prop_Data, "m_hOwnerEntity") == i)
					{
						new Handle:event_death = CreateEvent("player_death");
						SetEventInt(event_death, "userid", GetClientUserId(victim));
						SetEventInt(event_death, "attacker", GetClientUserId(i));
						SetEventString(event_death, "weapon", "summon_killed");
						FireEvent(event_death);
						break;
					}
				}
			}
			if(!IsFakeClient(victim) && attacker != victim && !StrEqual(WeaponUsed,"summon_killed"))	//玩家幸存者死亡
			{		
				if (GetClientTeam(victim) == 2 && PLAYER_LV[victim] <= 50)
				{			
					CPrintToChat(victim, "\x03作为 {red}新人(等级<=50 且 转生 = 0) \x03的你死亡将不扣除任何经验金钱.");
					return Plugin_Handled;
				}
				
				if (VIP[victim] <= 0)
				{
					new ExpGain = DEATH_EXP[victim];
					new CashGain = DEATH_CASH[victim];
					if (ExpGain > 0 && CashGain >0)
					{
						EXP[victim] -= ExpGain;
						Cash[victim] -= CashGain;
						CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_KILLED, ExpGain, CashGain);
					}
				}
				else if (VIP[victim] == 1)
				{
					new ExpGain = RoundToNearest(DEATH_EXP[victim] - DEATH_EXP[victim] * 0.5);
					new CashGain = RoundToNearest(DEATH_CASH[victim] - DEATH_CASH[victim] * 0.5);
					if (ExpGain > 0 && CashGain > 0)
					{
						EXP[victim] -= ExpGain;
						Cash[victim] -= CashGain;
						CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_KILLED_VIP, ExpGain, CashGain);
					}
				}
				else if (VIP[victim] == 2)
				{
					new ExpGain = RoundToNearest(DEATH_EXP[victim] - DEATH_EXP[victim] * 0.6);
					new CashGain = RoundToNearest(DEATH_CASH[victim] - DEATH_CASH[victim] * 0.6);
					if (ExpGain > 0 && CashGain > 0)
					{
						EXP[victim] -= ExpGain;
						Cash[victim] -= CashGain;
						CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_KILLED_VIP, ExpGain, CashGain);
					}
				}		
				else if (VIP[victim] == 3)
				{
					new ExpGain = RoundToNearest(DEATH_EXP[victim] - DEATH_EXP[victim] * 0.8);
					new CashGain = RoundToNearest(DEATH_CASH[victim] - DEATH_CASH[victim] * 0.8);
					if (ExpGain > 0 && CashGain > 0)
					{
						EXP[victim] -= ExpGain;
						Cash[victim] -= CashGain;
						CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_KILLED_VIP, ExpGain, CashGain);
					}
				}						
				//PrintToserver("[United RPG] [幸存者]%s死亡!", NameInfo(victim, simple));
			}
			if(IsValidPlayer(attacker))
			{
				if(attacker != victim  && !IsFakeClient(attacker) && !IsFakeClient(victim))	//玩家幸存者杀死玩家队友
				{
					if(!StrEqual(WeaponUsed,"satellite_cannon"))	//不是用卫星炮术
					{
						EXP[attacker] -= GetConVarInt(TeammateKilledExp); //GetConVarInt = 获取cfg里的设置
						Cash[attacker] -= GetConVarInt(TeammateKilledCash);
						KTCount[attacker] += 1;
						CPrintToChatAllEx(attacker, MSG_EXP_KILL_TEAMMATE, attacker, KTCount[attacker], GetConVarInt(TeammateKilledExp), GetConVarInt(TeammateKilledCash));

						if(KTLimit >= KTCount[attacker]) CPrintToChat(attacker, MSG_KT_WARNING_1, KTLimit);

						if(KTCount[attacker] > KTLimit )
						{
							if(!JobChooseBool[attacker])
							{
								CPrintToChat(attacker, MSG_KT_WARNING_2, KTLimit);
							}
							else
							{
								ClinetResetStatus(attacker, General);
								CPrintToChat(attacker, MSG_KT_WARNING_3, KTLimit);
							}
						}
						
					} 
					else if(!StrEqual(WeaponUsed,"satellite_cannonmiss"))	//不是用精灵暴雷
					{
						EXP[attacker] -= GetConVarInt(TeammateKilledExp);
						Cash[attacker] -= GetConVarInt(TeammateKilledCash);
						KTCount[attacker] += 1;
						CPrintToChatAllEx(attacker, MSG_EXP_KILL_TEAMMATE, attacker, KTCount[attacker], GetConVarInt(TeammateKilledExp), GetConVarInt(TeammateKilledCash));

						if(KTLimit >= KTCount[attacker]) CPrintToChat(attacker, MSG_KT_WARNING_1, KTLimit);

						if(KTCount[attacker] > KTLimit )
						{
							if(!JobChooseBool[attacker])
							{
								CPrintToChat(attacker, MSG_KT_WARNING_2, KTLimit);
							}
							else
							{
								ClinetResetStatus(attacker, General);
								CPrintToChat(attacker, MSG_KT_WARNING_3, KTLimit);
							}
						}
					} 
					else if (StrEqual(WeaponUsed,"satellite_cannonmiss"))//是用精灵暴雷
					{
						EXP[attacker] -= GetConVarInt(LvUpExpRate)*SatelliteCannonmissTKExpFactor/5;
						Cash[attacker] -= GetConVarInt(LvUpExpRate)*SatelliteCannonmissTKExpFactor/10;
						CPrintToChatAll(MSG_SKILL_SC_TKMISS, attacker, victim, GetConVarInt(LvUpExpRate)*SatelliteCannonmissTKExpFactor, GetConVarInt(LvUpExpRate)*SatelliteCannonmissTKExpFactor/10);
					}
					else if (StrEqual(WeaponUsed,"satellite_cannon"))	//是用卫星炮术
					{
						EXP[attacker] -= GetConVarInt(LvUpExpRate)*SatelliteCannonTKExpFactor;
						Cash[attacker] -= GetConVarInt(LvUpExpRate)*SatelliteCannonTKExpFactor/10;
						CPrintToChatAll(MSG_SKILL_SC_TK, attacker, victim, GetConVarInt(LvUpExpRate)*SatelliteCannonTKExpFactor, GetConVarInt(LvUpExpRate)*SatelliteCannonTKExpFactor/10);
					}
				}
			}
		}
	} else if (!IsValidPlayer(victim))
	{
		if(IsValidPlayer(attacker))
		{
			if(GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))	//玩家幸存者杀死普通感染者
			{
				if(ZombiesKillCountTimer[attacker] == INVALID_HANDLE)	ZombiesKillCountTimer[attacker] = CreateTimer(5.0, ZombiesKillCountFunction, attacker);
				ZombiesKillCount[attacker] ++;
			}
		}
	}
	
	/* 爆头显示 */
	if(IsValidPlayer(attacker))
	{
		if(!IsFakeClient(attacker))
		{
			if(GetEventBool(event, "headshot"))	DisplayDamage(LastDamage[attacker], HEADSHOT, attacker);
			else 	DisplayDamage(LastDamage[attacker], NORMALDEAD, attacker);
		}
	}

	return Plugin_Continue;
}

/* 坦克死亡提示战况 */
public MenuFunc_BattledInfo(Client)
{
	if(IsValidPlayer(Client) && GetClientTeam(Client) == 2)
	{
		new MaxDamage=0;
		//new String:MaxDamagePlayer[64];
		new bool:RankError = false;
		new RankFirst;
		new PlayerTeamNum=CountPlayersTeam(2);
		new PlayerExpReward = 0;
		new PlayerCashReward = 0;
		new Value = 0;
		new Value1 = 0;
		new String:RankStr[32];
		new Handle:Panel = CreatePanel();
		decl String:line[256];
		
		//获取排名
		TankRank[Client] = PlayerTeamNum;
		for(new i=1;i < MaxClients; i++)
		{
			if(IsValidPlayer(i, false) && IsClientInGame(i) && !IsFakeClient(i) && Client != i)
			{
				if(PlayerDamageTank[i] >= MaxDamage)
				{
					MaxDamage = PlayerDamageTank[i];
					RankFirst = i;
				}
				if(PlayerDamageTank[Client] > PlayerDamageTank[i])
				{
					TankRank[Client]--;
				}
			}
		}
		if(TankRank[Client] < 1) TankRank[Client] = 1;
		//计算自己和第一名伤害比较
		if(PlayerDamageTank[Client] > PlayerDamageTank[RankFirst]) RankFirst = Client;
		if(RankFirst != Client && TankRank[Client] == 1) RankError = true;

		//排名奖励
		if(PlayerTeamNum >= 5)
		{
			for(new i = 1; i <= 5; i++)
			{
				if(PlayerDamageTank[Client] <= 0) continue;
				if(TankRank[Client] == i && !RankError)
				{
					PlayerExpReward = (6 - i) * 100;
					PlayerCashReward = (6 - i) * 50;
					EXP[Client] += PlayerExpReward;
					Cash[Client] += PlayerCashReward;
				}
			}
			/*
			if(IsValidPlayer(RankFirst) && MaxDamage > 0)
			{
				GetClientName(RankFirst, MaxDamagePlayer, sizeof(MaxDamagePlayer));
			}
			*/
		}
		
		if (VIP[Client] == 1)
			Value = PlayerExpTank[Client];
		else if (VIP[Client] == 2)
			Value = RoundToNearest(PlayerExpTank[Client] * 1.5);
		else if (VIP[Client] == 3)
			Value = RoundToNearest(PlayerExpTank[Client] * 2.0);
		else if (VIP[Client] == 4)
			Value = RoundToNearest(PlayerExpTank[Client] * 2.5);
		
		if (VIP[Client] == 1)
			Value1 = PlayerCashTank[Client];
		else if (VIP[Client] == 2)
			Value1 = RoundToNearest(PlayerCashTank[Client] * 1.5);
		else if (VIP[Client] == 3)
			Value1 = RoundToNearest(PlayerCashTank[Client] * 2.0);
		else if (VIP[Client] == 4)
			Value1 = RoundToNearest(PlayerCashTank[Client] * 2.5);
		
		if(PlayerDamageTank[Client] > 0 && !RankError)
		{
			Format(RankStr, sizeof(RankStr), "第%d名", TankRank[Client]);
		}else{
			Format(RankStr, sizeof(RankStr), "未知");
		}
		
		//第一名奖杯显示
		if(RankFirst == Client && !RankError)
			AttachParticle1(Client, "achieved", 20.0);
			//AttachParticle(Client, PARTICLE_SPAWN, 3.0); //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]  
		
		SetPanelTitle(Panel, "统计:");
		Format(line, sizeof(line), "  ");	
		DrawPanelText(Panel, line);
		if(IsValidPlayer(RankFirst) && MaxDamage > 0 && RankFirst != Client)
		{
			Format(line, sizeof(line), "NO.1：%N，最大伤害：%d", RankFirst, MaxDamage);
			DrawPanelText(Panel, line);
		}
		DrawPanelText(Panel, "    ");
		DrawPanelText(Panel, "══════════════════");
		Format(line, sizeof(line), "你的输出: %d 点伤害，本次排名：%s [加油哈]", PlayerDamageTank[Client], RankStr, PlayerExpReward, PlayerCashReward);
		DrawPanelText(Panel, line);
		Format(line, sizeof(line), "输出排名奖励: %d Exp, %d $", PlayerExpReward, PlayerCashReward);
		DrawPanelText(Panel, line);
		Format(line, sizeof(line), "会员特权加成: %d Exp,  %d $", Value, Value1);
		DrawPanelText(Panel, line);
		Format(line, sizeof(line), "师徒在线加成: %d Exp, %d $", PlayerSTExp[Client], PlayerSTCash[Client]);
		DrawPanelText(Panel, line);
		Format(line, sizeof(line), "造成伤害获得: %d Exp, %d $", PlayerExpTank[Client], PlayerCashTank[Client]);
		DrawPanelText(Panel, line);
		DrawPanelText(Panel, "坦克死亡奖励: 1000 Exp, 500 $");
		DrawPanelText(Panel, "══════════════════");
		DrawPanelText(Panel, "\n");

		DrawPanelItem(Panel, "我知道了");

		SendPanelToClient(Panel, Client, MenuHandler_BattledInfo, MENU_TIME_FOREVER);
		CloseHandle(Panel);
		
	}
	//return Plugin_Handled;
}
public MenuHandler_BattledInfo(Handle:menu, MenuAction:action, Client, param)
{

}

//倒地显示
public Action:MenuFunc_DAODI(Client)
{
	decl String:line[1024];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "警告：你已经倒地");			
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "我知道了");
	DrawPanelItem(menu, line);
	
	SendPanelToClient(menu, Client, MenuHandler_DAODI, MENU_TIME_FOREVER);
}

public MenuHandler_DAODI(Handle:menu, MenuAction:action, Client, param)	
{
}

public Action:MenuFunc_SIWANG(Client)
{
	decl String:line[1024];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "你已经死亡");			
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "    ");
	DrawPanelText(menu, line);
   
	
	Format(line, sizeof(line), "你已经死亡了，开通会员拥有补给可以倒地自起");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "会员玩家可以拥有免费补给跟特权，享受游戏娱乐乐趣");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "同时开通会员拥有翻几倍经验的升级速率，加快了升级速度");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "     ");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "我知道了");
	DrawPanelItem(menu, line);
	
	SendPanelToClient(menu, Client, MenuHandler_SIWANG, MENU_TIME_FOREVER);
}

public MenuHandler_SIWANG(Handle:menu, MenuAction:action, Client, param)	
{
}

/*
public MenuFunc_TANKMSG1(Client, GetCash, GetEXP, Damage, PupilGetExp, PupilGetCash)//, String:MSG[])
{
	
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	//SetPanelTitle(menu, MSG);
	new Value = 0;
	
	if (VIP[Client] == 1)
		Value = GetEXP;
	else if (VIP[Client] == 2)
		Value = RoundToNearest(GetEXP * 1.5);
	else if (VIP[Client] == 3)
		Value = RoundToNearest(GetEXP * 2.0);
		
	new Value1 = 0;
	
	if (VIP[Client] == 1)
		Value1 = GetCash;
	else if (VIP[Client] == 2)
		Value1 = RoundToNearest(GetCash * 1.5);
	else if (VIP[Client] == 3)
		Value1 = RoundToNearest(GetCash * 2.0);
	
	SetPanelTitle(menu, "统计:");
	Format(line, sizeof(line), "  ");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "全体幸存者 +1000EXP, +500$");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你对坦克造成了：%d 点伤害", Damage);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了经验：%d EXP", GetEXP);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了金钱：%d $", GetCash);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "师傅伤害分红：%d EXP，%d $", PupilGetExp, PupilGetCash);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "会员加成：%d EXP，%d $", Value, Value1);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "我知道了");
	
	SendPanelToClient(menu, Client, MenuHandler_TANKMSG1, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_TANKMSG1(Handle:menu, MenuAction:action, Client, param)
{
}

public MenuFunc_TANKMSG(Client, GetCash, GetEXP, Damage, MasterGetExp, MasterGetCash)//, String:MSG[])
{
	
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	//SetPanelTitle(menu, MSG);
	new Value = 0;
	
	if (VIP[Client] == 1)
		Value = GetEXP;
	else if (VIP[Client] == 2)
		Value = RoundToNearest(GetEXP * 1.5);
	else if (VIP[Client] == 3)
		Value = RoundToNearest(GetEXP * 2.0);
		
	new Value1 = 0;
	
	if (VIP[Client] == 1)
		Value1 = GetCash;
	else if (VIP[Client] == 2)
		Value1 = RoundToNearest(GetCash * 1.5);
	else if (VIP[Client] == 3)
		Value1 = RoundToNearest(GetCash * 2.0);
	
	SetPanelTitle(menu, "统计:");
	Format(line, sizeof(line), "  ");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "全体幸存者 +1000EXP, +500$");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你对坦克造成了：%d 点伤害", Damage);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了经验：%d EXP", GetEXP);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了金钱：%d $", GetCash);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "徒弟在线加成：%d EXP，%d $", MasterGetExp, MasterGetCash);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "会员加成：%d EXP，%d $", Value, Value1);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "我知道了");
	
	SendPanelToClient(menu, Client, MenuHandler_TANKMSG, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_TANKMSG(Handle:menu, MenuAction:action, Client, param)
{
}

public MenuFunc_TANKMSG2(Client, GetCash, GetEXP, Damage)//, String:MSG[])
{
	
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	//SetPanelTitle(menu, MSG);
	new Value = 0;
	
	if (VIP[Client] == 1)
		Value = GetEXP;
	else if (VIP[Client] == 2)
		Value = RoundToNearest(GetEXP * 1.5);
	else if (VIP[Client] == 3)
		Value = RoundToNearest(GetEXP * 2.0);
		
	new Value1 = 0;
	
	if (VIP[Client] == 1)
		Value1 = GetCash;
	else if (VIP[Client] == 2)
		Value1 = RoundToNearest(GetCash * 1.5);
	else if (VIP[Client] == 3)
		Value1 = RoundToNearest(GetCash * 2.0);
	
	SetPanelTitle(menu, "统计:");
	Format(line, sizeof(line), "  ");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "全体幸存者 +1000EXP, +500$");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你对坦克造成了：%d 点伤害", Damage);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了经验：%d EXP", GetEXP);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "你获得了金钱：%d $", GetCash);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "会员加成：%d EXP，%d $", Value, Value1);	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");	
	DrawPanelText(menu, line);	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "我知道了");
	
	SendPanelToClient(menu, Client, MenuHandler_TANKMSG2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_TANKMSG2(Handle:menu, MenuAction:action, Client, param)
{
}
*/

/* 拉起队友 */
public Action:Event_ReviveSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new bool:Isledge = GetEventBool(event, "ledge_hang");

	if (IsValidPlayer(Reviver))
	{
		SetEntityHealth(Subject, RoundToNearest(100*(1.0+HealthEffect[Subject])*EndranceQualityEffect[Subject]));
		if(Reviver != Subject && GetClientTeam(Reviver) == 2 && !IsFakeClient(Reviver) && !Isledge)
		{
			RebuildStatus(Subject, false);
			if(MSTF[Reviver] == 1)
	        {
	        	new RandomGiv = GetRandomInt(0, 5);
		        switch(RandomGiv)
		        {
					case 0: 
					{
						CheatCommand(Reviver, "give", "adrenaline");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x01[\x04妙手医师\x01]\x04,\x03玩家 \x04%N \x03救起队友，\x05获得肾上腺激素", Reviver);
					}
					case 1: 
					{
						CheatCommand(Reviver, "give", "first_aid_kit");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x01[\x04妙手医师\x01]\x04,\x03玩家 \x04%N \x03救起队友，\x05获得医疗包", Reviver);
					}
					case 2: 
					{
						CheatCommand(Reviver, "give", "molotov");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x01[\x04妙手医师\x01]\x04,\x03玩家 \x04%N \x03救起队友，\x05获得燃烧瓶", Reviver);
					}
					case 3: 
					{
						CheatCommand(Reviver, "give", "defibrillator");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x01[\x04妙手医师\x01]\x04,\x03玩家 \x04%N \x03救起队友，\x05获得电击器", Reviver);
					}
		        }
	        }
			if(NHYS[Reviver] == 1)
	        {
	        	new RandomGiv = GetRandomInt(1, 2);
		        switch(RandomGiv)
		        {
					case 1: 
					{
						CheatCommand(Reviver, "upgrade_add", "Incendiary_ammo");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x04[怒火医师]\x01,玩家 \x04%N \x01救起队友，获得怒火奖励\x04 爆炎弹", Reviver);
					}
		        }
	        }
			if(KBYS[Reviver] == 1)
	        {
	        	new RandomGiv = GetRandomInt(1, 2);
		        switch(RandomGiv)
		        {
					case 1: 
					{
						CheatCommand(Reviver, "upgrade_add", "explosive_ammo");
						AttachParticle1(Reviver, "achieved", 3.0);
						CPrintToChatAll("\x04[狂暴医师]\x01,\x01玩家 \x04%N \x01救起队友，获得狂暴奖励\x04 爆裂弹", Reviver);
					}
		        }
	        }

			if (JD[Reviver]==4)
			{
				EXP[Reviver] += GetConVarInt(ReviveTeammateExp)+Job4_ExtraReward[Reviver] + VIPAdd(Reviver, GetConVarInt(ReviveTeammateExp)+Job4_ExtraReward[Reviver], 1, true);
				Cash[Reviver] += GetConVarInt(ReviveTeammateCash)+Job4_ExtraReward[Reviver] + VIPAdd(Reviver, GetConVarInt(ReviveTeammateCash)+Job4_ExtraReward[Reviver], 1, false);
				CPrintToChat(Reviver, MSG_EXP_REVIVE_JOB4, GetConVarInt(ReviveTeammateExp),
							Job4_ExtraReward[Reviver], GetConVarInt(ReviveTeammateCash), Job4_ExtraReward[Reviver]);
			}
			else
			{
				EXP[Reviver] += GetConVarInt(ReviveTeammateExp) + VIPAdd(Reviver, GetConVarInt(ReviveTeammateExp), 1, true);
				Cash[Reviver] += GetConVarInt(ReviveTeammateCash) + VIPAdd(Reviver, GetConVarInt(ReviveTeammateCash), 1, false);
				CPrintToChat(Reviver, MSG_EXP_REVIVE, GetConVarInt(ReviveTeammateExp), GetConVarInt(ReviveTeammateCash));
			}
		}
		if(BRSLZ[Reviver] == 0)
		{
            if(BRSL[Reviver] < 10000)
            {
                BRSL[Reviver]++;
		    }
            if(BRSL[Reviver] == 10000)
            {
                BRSLZ[Reviver] = 1;							
		    }				
        }	
		if(GetEventBool(event, "lastlife"))
		{
			decl String:targetName[64];
			decl String:targetModel[128]; 
			decl String:charName[32];
			
			GetClientName(Subject, targetName, sizeof(targetName));
			GetClientModel(Subject, targetModel, sizeof(targetModel));
			
			if(StrContains(targetModel, "teenangst", false) > 0) 
			{
				strcopy(charName, sizeof(charName), "Zoey");
			}
			else if(StrContains(targetModel, "biker", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Francis");
			}
			else if(StrContains(targetModel, "manager", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Louis");
			}
			else if(StrContains(targetModel, "namvet", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Bill");
			}
			else if(StrContains(targetModel, "producer", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Rochelle");
			}
			else if(StrContains(targetModel, "mechanic", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Ellis");
			}
			else if(StrContains(targetModel, "coach", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Coach");
			}
			else if(StrContains(targetModel, "gambler", false) > 0)
			{
				strcopy(charName, sizeof(charName), "Nick");
			}
			else{
				strcopy(charName, sizeof(charName), "Unknown");
			}
			
			PrintHintTextToAll("[系统] %s(%s)已进入频死状态(黑白画面),请尽快帮助他治疗.", targetName, charName);
			CPrintToChatAll("\x05[系统] {red}%s(%s)\x03已进入频死状态{red}(黑白画面)\x03,请尽快帮助他治疗.", targetName, charName);
		}
	}
	return Plugin_Continue;
}

/* 电击队友 */
public Action:Event_DefibrillatorUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new UserID = GetClientOfUserId(GetEventInt(event, "userid"));
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"));

	if (IsValidPlayer(UserID))
	{
		if(GetClientTeam(UserID) == 2 && !IsFakeClient(UserID))
		{
			RebuildStatus(Subject, false);
			if(DJYX[UserID] == 1)
	        {
	        	new RandomGiv = GetRandomInt(0, 6);
		        switch(RandomGiv)
		        {
					case 0: 
					{
						CheatCommand(UserID, "give", "adrenaline");
						AttachParticle1(UserID, "achieved", 3.0);
						PrintHintTextToAll("【电击游侠】：[%N]救活队友，随机获得肾上腺激素", UserID);
					}
					case 1: 
					{
						CheatCommand(UserID, "give", "first_aid_kit");
						AttachParticle1(UserID, "achieved", 3.0);
						PrintHintTextToAll("【电击游侠】：[%N]救活队友，随机获得医疗包", UserID);
					}
					case 2: 
					{
						CheatCommand(UserID, "give", "molotov");
						AttachParticle1(UserID, "achieved", 3.0);
						PrintHintTextToAll("【电击游侠】：[%N]救活队友，随机获得燃烧瓶", UserID);
					}
					case 3: 
					{
						CheatCommand(UserID, "upgrade_add", "EXPLOSIVE_AMMO");
						AttachParticle1(UserID, "achieved", 3.0);
						PrintHintTextToAll("【电击游侠】：[%N]救活队友，随机获得高爆弹", UserID);
					}
					case 4: 
					{
						CheatCommand(UserID, "give", "defibrillator");
						AttachParticle1(UserID, "achieved", 3.0);
						PrintHintTextToAll("【电击游侠】：[%N]救活队友，随机获得电击器", UserID);
					}
		        }
	        }
			
			if (JD[UserID]==4)
			{
				EXP[UserID] += GetConVarInt(ReanimateTeammateExp)+Job4_ExtraReward[UserID] + VIPAdd(UserID, GetConVarInt(ReanimateTeammateExp)+Job4_ExtraReward[UserID], 1, true);
				Cash[UserID] += GetConVarInt(ReanimateTeammateCash)+Job4_ExtraReward[UserID] + VIPAdd(UserID, GetConVarInt(ReanimateTeammateCash)+Job4_ExtraReward[UserID], 1, false);
				CPrintToChat(UserID, MSG_EXP_DEFIBRILLATOR_JOB4, GetConVarInt(ReanimateTeammateExp),
							Job4_ExtraReward[UserID], GetConVarInt(ReanimateTeammateCash), Job4_ExtraReward[UserID]);
			}
			else
			{
				EXP[UserID] += GetConVarInt(ReanimateTeammateExp) + VIPAdd(UserID, GetConVarInt(ReanimateTeammateExp), 1, true);
				Cash[UserID] += GetConVarInt(ReanimateTeammateCash) + VIPAdd(UserID, GetConVarInt(ReanimateTeammateCash), 1, false);
				CPrintToChat(UserID, MSG_EXP_DEFIBRILLATOR, GetConVarInt(ReanimateTeammateExp), GetConVarInt(ReanimateTeammateCash));
			}
			if(DRSLZ[UserID] == 0)   //称号（复活队友）
		    {
                if(DRSL[UserID] < 1000)
                {
                    DRSL[UserID]++;
				}
                if(DRSL[UserID] == 1000)
                {
                    DRSLZ[UserID] = 1;									
				}				
            }
		}
	}
	return Plugin_Continue;
}

/* 幸存者倒下 */
public Action:Event_Incapacitate(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:WeaponUsed[256];
	GetEventString(event, "weapon", WeaponUsed, sizeof(WeaponUsed));

	if(IsValidPlayer(victim) && GetClientTeam(victim) == 2)
	{
		if (PLAYER_LV[victim] <= 50)
		{			
			CPrintToChat(victim, "\x03作为 \x03新人(等级<=50 且 转生 = 0) \x03的你倒地将不扣除任何经验金钱.");
			return Plugin_Handled;
		}
		
		if(tgyj[victim] == 1)
		{
			if (attacker && IsClientInGame(attacker) && IsPlayerAlive(attacker))
			{
				decl Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				DealDamage(victim, attacker, 5000, 0);
				ShowParticle(pos, FireBall_Particle_Fire01, 5.0);
				ShowParticle(pos, FireBall_Particle_Fire02, 5.0);
				ShowParticle(pos, FireBall_Particle_Fire03, 5.0);
				new String:tg[32];
				GetClientName(attacker, tg, 32);
				PrintToChatAll("\x03[\x05天赋\x03]\x04 %N\x01倒地发动\x04【愤怒反击】\x01，\x01对\x04%s\x01造成\x045000\x01伤害",victim,tg);
			}
		}
		if(ZHONGHUO[victim] == 1)
		{
			if (attacker && IsClientInGame(attacker) && IsPlayerAlive(attacker))
			{
				decl Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				SuperTank_LittleFlower(victim, pos, MOLOTOV);
				SetConVarString(FindConVar("survivor_burn_factor_normal"), "0");
				SetConVarString(FindConVar("survivor_burn_factor_hard"), "0");
				SetConVarString(FindConVar("survivor_burn_factor_expert"), "0");
				PrintToChatAll("\x03[\x05天赋\x03]\x04 %N\x01倒地发动\x04【纵火术】\x01，\x05 200码范围出现火海",victim);
				CreateTimer(10.0, TankEventEnd2);
			}
		}
		if(JIDONG[victim] == 1)
		{
			for(new i = 1; i <= MaxClients; i++) 
			{
				if(!IsClientInGame(i)) continue;
				EmitSoundToClient(i,SOUND_GOOD);
			}
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) 
				{
					ServerCommand("sm_freeze \"%N\" \"30\"",i); 
				}
			}
			PrintToChatAll("\x03[\x05天赋\x03]\x04 %N\x01倒地发动 \x04【极冻术】\x05感染者冰冻30秒", victim);
		}
	
		if (VIP[victim] <= 0)   //会员倒地死亡经验减少
		{
			new ExpGain = RoundToNearest(INCAP_EXP[victim]);
			new CashGain = RoundToNearest(INCAP_CASH[victim]);
			if (ExpGain > 0 && CashGain > 0)
			{
				EXP[victim] -= ExpGain;
				Cash[victim] -= CashGain;
				CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_INCAPPED, ExpGain, CashGain);
			}
			MenuFunc_DAODI(victim)
		}
		else if (VIP[victim] == 1)
		{
			new ExpGain = RoundToNearest(INCAP_EXP[victim] - INCAP_EXP[victim] * 0.5);
			new CashGain = RoundToNearest(INCAP_CASH[victim] - INCAP_CASH[victim] * 0.5);
			if (ExpGain > 0 && CashGain > 0)
			{
				EXP[victim] -= ExpGain;
				Cash[victim] -= CashGain;
				CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_INCAPPED_VIP, ExpGain, CashGain);
			}	
		}
		else if (VIP[victim] == 2)
		{
			new ExpGain = RoundToNearest(INCAP_EXP[victim] - INCAP_EXP[victim] * 0.6);
			new CashGain = RoundToNearest(INCAP_CASH[victim] - INCAP_CASH[victim] * 0.6);
			if (ExpGain > 0 && CashGain > 0)
			{
				EXP[victim] -= ExpGain;
				Cash[victim] -= CashGain;
				CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_INCAPPED_VIP, ExpGain, CashGain);
			}
		}
		else if (VIP[victim] == 3)
		{
			new ExpGain = RoundToNearest(INCAP_EXP[victim] - INCAP_EXP[victim] * 0.8);
			new CashGain = RoundToNearest(INCAP_CASH[victim] - INCAP_CASH[victim] * 0.8);
			if (ExpGain > 0 && CashGain > 0)
			{
				EXP[victim] -= ExpGain;
				Cash[victim] -= CashGain;
				CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_INCAPPED_VIP, ExpGain, CashGain);
			}
		}
		else if (VIP[victim] == 4)
		{
			new ExpGain = RoundToNearest(INCAP_EXP[victim] - INCAP_EXP[victim] * 0.9);
			new CashGain = RoundToNearest(INCAP_CASH[victim] - INCAP_CASH[victim] * 0.9);
			if (ExpGain > 0 && CashGain > 0)
			{
				EXP[victim] -= ExpGain;
				Cash[victim] -= CashGain;
				CPrintToChat(victim, MSG_EXP_SURVIVOR_GOT_INCAPPED_VIP, ExpGain, CashGain);
			}
		}
		//PrintToserver("[United RPG] [幸存者]%s倒下!", NameInfo(victim, simple));
	}
	return Plugin_Continue;
}

public Action:TankEventEnd2(Handle:timer) 
{
	SetConVarString(FindConVar("survivor_burn_factor_normal"), "1");
	SetConVarString(FindConVar("survivor_burn_factor_hard"), "1");
	SetConVarString(FindConVar("survivor_burn_factor_expert"), "1");
	PrintToChatAll("\x03[\x05天赋\x03]\x04【纵火术】\x01效果消失.");
}

/* Witch被惊吓 */
public Action:Event_WitchHarasserSet(Handle: event, const String: name[], bool: dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "witchid");
	if (IsValidEdict(entity))
	{
		TriggerPanicEvent();
		SetEntPropFloat(entity, Prop_Send,"m_flModelScale", 1.5); 
		if (IsValidPlayer(userid))
			CPrintToChatAll(MSG_WITCH_HARASSERSET_SET_PANIC, userid);
	}
	return Plugin_Continue;
}

/* Witch死亡 */
public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidPlayer(killer))
	{
		if(GetClientTeam(killer) == 2 && !IsFakeClient(killer))
		{
			EXP[killer] += GetConVarInt(WitchKilledExp);
			Cash[killer] += GetConVarInt(WitchKilledCash);
			if(Jenwu[killer] == 5)
			{
				MEIZI[killer]++;
			}
			if(NWSLZ[killer] == 0)
            {
				if(NWSL[killer] < 500)
                {
                    NWSL[killer] += 1;
                }
				if(NWSL[killer] == 500)
                {
                    NWSLZ[killer] = 1;										
                }				
            }
			if (EXP[killer] < 0)
				EXP[killer] = 0;
			if (Cash[killer] < 0)
				Cash[killer] = 0;
			CPrintToChat(killer, MSG_EXP_KILL_WITCH, GetConVarInt(WitchKilledExp), GetConVarInt(WitchKilledCash));
		}
	}
	if (IsValidPlayer(killer))	CPrintToChatAll(MSG_WITCH_KILLED_PANIC, killer);
	TriggerPanicEvent();
	return Plugin_Continue;
}

/* 玩家受伤 */
public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl 
	victim, attacker, dmg, eventhealth, dmgtype, entity, CritDamage, 
	LastDmg, LastHealth, dehealth, ack_ZombieClass, victim_ZombieClass, 
	Float:AddDamage, Float:TankArmor, Float:RandomArmor, 
	String:WeaponUsed[256],
	bool:IsVictimDead, bool:IsGun;

	victim = GetClientOfUserId(GetEventInt(event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	dmg = GetEventInt(event, "dmg_health");
	eventhealth = GetEventInt(event, "health");
	dmgtype = GetEventInt(event, "type");
	entity = GetEventInt(event, "attackerentid");
	CritDamage = GetCritsDmg(attacker, dmg);
	TankArmor = 1.0;
	RandomArmor = GetRandomFloat(0.0, 100.0);	//随机护甲
	GetEventString(event, "weapon", WeaponUsed, sizeof(WeaponUsed));
	IsGun = WeaponIsGun(WeaponUsed);
	AddDamage = 0.0;	//附加伤害
	LastDmg = 0;
	LastHealth = 0;
	
	
	if(robot_gamestart)
	{
		if(attacker <= 0)
			CIenemy[victim] = entity;
		else
		{
			if(attacker != victim && GetClientTeam(attacker) == 3
			&& !StrEqual(WeaponUsed,"summon_attack") 
			&& !StrEqual(WeaponUsed,"satellite_cannon") 
			&& !StrEqual(WeaponUsed,"fire_ball") 
			&& !StrEqual(WeaponUsed,"chain_lightning") 
			&& !StrEqual(WeaponUsed,"satellite_cannonmiss") 
			&& !StrEqual(WeaponUsed,"chainmiss_lightning") 
			&& !StrEqual(WeaponUsed,"chainkb_lightning"))
			{
				scantime[victim] = GetEngineTime();
				SIenemy[victim] = attacker;
			}
		}
	}
	
	if(robot_gamestart_clone)
	{
		if(attacker <= 0)
			CIenemy_clone[victim] = entity;
		else
		{
			if(attacker != victim && GetClientTeam(attacker) == 3
			&& !StrEqual(WeaponUsed,"summon_attack") 
			&& !StrEqual(WeaponUsed,"satellite_cannon") 
			&& !StrEqual(WeaponUsed,"fire_ball") 
			&& !StrEqual(WeaponUsed,"chain_lightning") 
			&& !StrEqual(WeaponUsed,"satellite_cannonmiss") 
			&& !StrEqual(WeaponUsed,"chainmiss_lightning") 
			&& !StrEqual(WeaponUsed,"chainkb_lightning"))
			{
				//scantime[victim] = GetEngineTime();
				scantime_clone[victim] = GetEngineTime();
				//SIenemy[victim] = attacker;
				SIenemy_clone[victim] = attacker;
			}
		}
	}
	

	if(eventhealth <= 0)	
		IsVictimDead = true;
	else
		IsVictimDead = false;
	
	dehealth = eventhealth + dmg;
	
	//枪械武器伤害
	if(IsGun)
	{
		if (StrEqual(WeaponUsed, NAME_AK47, false))
			dmg = DMG_AK47 + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_M60, false))
			dmg = DMG_M60 + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_M16, false))
			dmg = DMG_M16 + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_MP5, false))
			dmg = DMG_MP5 + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_SPAS, false))
			dmg = DMG_SPAS + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_CHROME, false))
			dmg = DMG_CHROME + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_AUTOSHOTGUN, false))
			dmg =DMG_AUTOSHOTGUN;
		else if (StrEqual(WeaponUsed, NAME_HUNTING, false))
			dmg = DMG_HUNTING + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_SCOUT, false))
			dmg = DMG_SCOUT + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_AWP, false))
			dmg = DMG_AWP + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_GL, false))
			dmg = DMG_GL + DMG_LVD;	
		else if (StrEqual(WeaponUsed, NAME_SMG, false))
			dmg = DMG_SMG + DMG_LVD;	
		else if (StrEqual(WeaponUsed, NAME_SMG_S, false))
			dmg = DMG_SMG_S + DMG_LVD;
		else if (StrEqual(WeaponUsed, NAME_MAGNUM, false))
			dmg = DMG_MAGNUM + DMG_LVD;
			
		eventhealth = dehealth - dmg;
	}
			
	
	//友军伤害返回
	if (IsValidPlayer(attacker) && IsValidPlayer(victim) && GetClientTeam(attacker) == GetClientTeam(victim) && dmgtype != 8 && dmgtype != 268435464 && dmgtype != 2056) 
	{
		if (attacker == victim)
			return Plugin_Handled;
			
		if (!IsFakeClient(attacker))
		{
			ScreenFade(attacker, 150, 10, 10, 80, 100, 1);
			//PrintHintText(attacker, "你正在攻击你的队友 %N,他死亡会导致你记录大过,请小心开火!", victim);
		}
		
		if (!IsFakeClient(victim))
			//PrintHintText(victim, "你受到友军攻击,攻击者是 %N, 蹲下来开火有助于躲避队友伤害.", attacker);
		
		return Plugin_Handled;
	}
	
	//弹药专家技能
	if (IsGun)
	{
		SuckBloodAmmoAttack(attacker, victim);
		PoisonAmmoAttack(attacker, victim, WeaponUsed);
	}
	
	/* 攻击者的计算 */
	if (IsValidPlayer(attacker))
	{	
		ack_ZombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		if (ack_ZombieClass == CLASS_TANK)
		{
			if(StrEqual(WeaponUsed, "tank_claw") && tanktype[attacker] > 0)
			{				
				/* 地震攻击(倒地幸存者) */
				SkillEarthQuake(attacker, victim);
				
				if(tanktype[attacker] == TANK2 || tanktype[attacker] == TANK5)
					SkillGravityClaw(victim); /* 重力之爪 */
				
				if(tanktype[attacker] == TANK3 || tanktype[attacker] == TANK5)
					SkillDreadClaw(victim);  /* 致盲袭击 */
					
				if(tanktype[attacker] == TANK4 || tanktype[attacker] == TANK5)
					SkillBurnClaw(attacker, victim);  /* 火焰之拳 */
			}
			
			if(StrEqual(WeaponUsed, "tank_rock") && tanktype[attacker] > 0)
			{	
				new Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				if(tanktype[attacker] == TANK4 || tanktype[attacker] == TANK5)
					SkillCometStrike(attacker, victim, MOLOTOV);  /* 火焰石头 */
				else
					SkillCometStrike(attacker, victim, EXPLODE);  /* 爆炸石头 */
				
			}	
		}
		
		if(!IsFakeClient(attacker) && 
		!StrEqual(WeaponUsed,"damage_reflect") && 
		!StrEqual(WeaponUsed,"satellite_cannon") && 
		!StrEqual(WeaponUsed,"robot_attack") && 
		!StrEqual(WeaponUsed,"fire_ball") && 
		!StrEqual(WeaponUsed,"chain_lightning") && 
		!StrEqual(WeaponUsed,"hunter_super_pounce") && 
		!StrEqual(WeaponUsed,"satellite_cannonmiss") && 
		!StrEqual(WeaponUsed,"chainmiss_lightning") && 
		!StrEqual(WeaponUsed,"chainkb_lightning"))
		{
			/* 力量效果 */
			if(!StrEqual(WeaponUsed,"summon_attack"))
			{
				//攻防强化术
				if (GetClientTeam(attacker) == 2 && EnergyEnhanceLv[attacker]>0)
					AddDamage = dmg*(StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker]);
				else if (StrEqual(WeaponUsed, "point_hurt"))	//重机枪
					AddDamage = 1.0 * (HeavyGunMaxDmg[attacker]);
				else
					AddDamage = dmg*(StrEffect[attacker]);		//415 * 0.005 = 2.075	50*2.075= 103.75 
					//CPrintToChatAll("weapen:%s", WeaponUsed);
				
				
				if (IsGun)
				{
					if (StrEqual(WeaponUsed, NAME_SPAS, false) || StrEqual(WeaponUsed, NAME_CHROME, false) || StrEqual(WeaponUsed, NAME_AUTOSHOTGUN, false) || StrEqual(WeaponUsed, NAME_PUMPSHOTGUN, false))
					{
						AddDamage = AddDamage + (dmg * ZB_GunDmg[attacker]);	//连喷没有强化效果
					}
					else
					{
						AddDamage = AddDamage + (dmg * ZB_GunDmg[attacker])  + Shilv[attacker] * DMG_LVD;
					}
				}
			}

		}
	} 

	/* 被攻击者的计算*/
	if (IsValidPlayer(victim))
	{	
		victim_ZombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		new Float:tank_cv_armor;
		new Float:tank_cv_speed;
		if(sm_supertank_armor_tank[tanktype[victim]] != INVALID_HANDLE)
			tank_cv_armor = GetConVarFloat(sm_supertank_armor_tank[tanktype[victim]]);
		if(sm_supertank_speed[tanktype[victim]] != INVALID_HANDLE)
			tank_cv_speed = GetConVarFloat(sm_supertank_speed[tanktype[victim]]);
		if (victim_ZombieClass == CLASS_TANK)
		{	
			if (RandomArmor <= TankOffsetRadio)
				TankArmor = tank_cv_armor;
			else
				TankArmor = 1.0;
		}
		/* 近战对感染者伤害计算 */
		if (victim_ZombieClass == CLASS_TANK && StrEqual(WeaponUsed,"melee") && IsValidPlayer(attacker))
		{
			if(tanktype[victim] > 0)
			{
				if(tanktype[victim] == TANK2)
				{
					/* 钢铁皮肤 */
					new steelhealth = eventhealth + dmg;
					if (steelhealth > 0)
						SetEntProp(victim, Prop_Data, "m_iHealth", steelhealth);
					SetEventInt(event, "dmg_health", 0);
					EmitSoundToClient(attacker, SOUND_STEEL);
					PrintCenterText(attacker,"", victim, steelhealth); //你的攻击对 %N 造成了 0 伤害,他剩余: %d 点HP
					return Plugin_Changed;
				}

				if(tanktype[victim] == TANK4 || tanktype[victim] == TANK5)
				{
					/* 火焰喷发 */
					SkillFlameGush(victim, attacker);
				}

			}
			
			new meleedmg = DMG_MELEE[attacker];			
			LastDmg = RoundToNearest(TankArmor * meleedmg);
			new tankhealth = eventhealth + dmg - LastDmg;
			if (!IsVictimDead)
			{			
				if (tankhealth > 0)
					SetEntProp(victim, Prop_Data, "m_iHealth", tankhealth);
				
				TankOffsetDmg[attacker][victim] += meleedmg - LastDmg > 0 ? meleedmg - LastDmg : 0;
				DamageToTank[attacker][victim] += LastDmg;
				if (tanktype[victim] == TANK5)
					PrintHintText(attacker, "帝王坦克 \n生命值:(%d) 速度:(%.1f) 累积伤害:(%d) ", eventhealth, tank_cv_speed, DamageToTank[attacker][victim]);
				else
					PrintHintText(attacker, "超级坦克(第%d阶段) \n生命值:(%d) 速度:(%.1f) 累积伤害:(%d) ", tanktype[victim], eventhealth, tank_cv_speed, DamageToTank[attacker][victim]);
			}
			else
				LastDamage[attacker] = LastDmg;
			
			//伤害显示
			if (IsValidPlayer(attacker) && attacker != victim)
			{
				if (TankArmor < 1.0)
					PrintCenterText(attacker,"", victim, LastDmg , tankhealth); //你的攻击对 %N 造成了 %d 伤害, 他剩余: %d 点HP
				else
					PrintCenterText(attacker, "", victim, LastDmg , tankhealth); //你的攻击对 %N 造成了 %d 伤害, 他剩余: %d 点HP
			}
			
			SetEventInt(event, "dmg_health", LastDmg);
			return Plugin_Changed;
		}
			
		if(StrEqual(WeaponUsed,"fire_ball"))
			AttachParticle(victim, FireBall_Particle_Fire03, 0.5);

		//最终伤害计算
		if (victim_ZombieClass == CLASS_TANK)
		{
			LastDmg = RoundToNearest(TankArmor * (dmg + AddDamage));
			if ((dmgtype == 8 || dmgtype == 268435464 || dmgtype == 2056) && !StrEqual(WeaponUsed, "fire_ball"))
			{
				dmg = 1;
				LastDmg = 1;
				eventhealth = dehealth - dmg;
			}
		}
		else if (IsValidPlayer(attacker, false))
			LastDmg = RoundToNearest(dmg + AddDamage)/2;
		else
			LastDmg = dmg/2;

		//伤害类型判定 && 制造伤害_显示
		if (GetClientTeam(victim) != 2 && CritDamage > 0 && IsGun)
		{
			if (victim_ZombieClass == CLASS_TANK)
			{
				LastDmg = RoundToNearest((dmg + AddDamage + CritDamage) * TankArmor);
				TankOffsetDmg[attacker][victim] += RoundToNearest(dmg + AddDamage + CritDamage - LastDmg);
			}
			else
				LastDmg = RoundToNearest(dmg + AddDamage + CritDamage);
			
			LastHealth = eventhealth + dmg - LastDmg;
			//枪械武器暴击伤害
			if (IsValidPlayer(attacker) && attacker != victim)
			{
				PrintCenterText(attacker,"", victim, LastDmg , LastHealth); //你的攻击对 %N 造成了 %d 暴击伤害,他剩余: %d 点HP
				ScreenFade(attacker, 255, 130, 0, 80, 100, 1);
				EmitSoundToClient(attacker, CRIT_SOUND);
			}
		}
		else if (GetClientTeam(victim) != 2)
		{
			if (victim_ZombieClass == CLASS_TANK)
				TankOffsetDmg[attacker][victim] += RoundToNearest(dmg + AddDamage - LastDmg);
			
			if (IsValidPlayer(attacker) && attacker != victim)
			{
				LastHealth = eventhealth + dmg - LastDmg;
				if (TankArmor < 1.0)
					PrintCenterText(attacker,"", victim, LastDmg , LastHealth); //你的攻击对 %N 造成了 %d 伤害, 他剩余: %d 点HP
				else
					PrintCenterText(attacker,"", victim, LastDmg , LastHealth); //你的攻击对 %N 造成了 %d 伤害, 他剩余: %d 点HP
			}
				
		}		
		
		//被攻击者是玩家
		if (IsValidPlayer(victim, false))
		{
			/* 防御效果 */
			if(!IsMeleeSpeedEnable[victim])
			{
				decl enddmg, checkenddmg;
				enddmg = LastDmg;
				if(GetClientTeam(victim) == 2 && EnergyEnhanceLv[victim] > 0)	//攻防术
				{
					checkenddmg = RoundToNearest(enddmg - enddmg * (EnduranceEffect[victim] + EnergyEnhanceEffect_Endurance[victim] + ZB_EndEffect[victim]));
					if(checkenddmg > 0)
						LastDmg = checkenddmg;
					else
						LastDmg = 1;
					PrintToChat(victim, "EEE-enddmg: %d checkdmg: %d lastdmg: %d", enddmg, checkenddmg, LastDmg);
				} 
				else if(GetClientTeam(victim) == 2 && GeneLv[victim] > 0)	//基因改造
				{					
					checkenddmg = RoundToNearest(enddmg - enddmg * (EnduranceEffect[victim] + GeneEndEffect[victim] + ZB_EndEffect[victim]));
					if(checkenddmg > 0)
						LastDmg = checkenddmg;
					else
						LastDmg = 1;
					PrintToChat(victim, "GENE-enddmg: %d checkdmg: %d lastdmg: %d", enddmg, checkenddmg, LastDmg);
				} 
				else if (GetClientTeam(victim) == 2)//普通防御效果
				{
					checkenddmg = RoundToNearest(enddmg - enddmg * (EnduranceEffect[victim] + ZB_EndEffect[victim]));
					if(checkenddmg > 0)
						LastDmg = checkenddmg;
					else
						LastDmg = 1;
				}
			}
			
		}

		//火焰风衣免疫效果
		if (IsValidPlayer(victim) && GetClientTeam(victim) == 2 && ZB_FireEnd[victim] > 0 && (dmgtype == 8 || dmgtype == 268435464 || dmgtype == 2056))
		{
			LastDmg = RoundToNearest(LastDmg - LastDmg * ZB_FireEnd[victim]);
			if (LastDmg < 1)
				LastDmg = 1;
		}
					
		//剩余血量计算
		LastHealth = eventhealth + dmg - LastDmg;
						
		/* 反伤术 */
		if (IsValidPlayer(victim, false) && attacker != victim)
		{
			new refelectdmg = LastDmg;
			if (IsValidPlayer(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == CLASS_TANK)
				refelectdmg = refelectdmg / 10;
				
			if (refelectdmg <= 0)
				refelectdmg = 1;
				
			if(IsValidPlayer(attacker) && !StrEqual(WeaponUsed,"insect_swarm") && !StrEqual(WeaponUsed, "tank_rock")){
				if(IsDamageReflectEnable[victim] && GetClientTeam(attacker) != 2)
					DealDamage(victim, attacker, RoundToNearest(refelectdmg * (DamageReflectEffect[victim])), 0, "damage_reflect");
			}
			else if(!IsValidPlayer(attacker)) 
			{
				if (IsValidEdict(entity) && IsDamageReflectEnable[victim])
					DealDamage(victim, entity, RoundToNearest(refelectdmg * (DamageReflectEffect[victim])), 0, "damage_reflect");
			}
		}

		/* 坦克伤害加成计算 */
		if(IsValidPlayer(attacker, false))
		{
			if(GetClientTeam(victim) == 3 && victim_ZombieClass == CLASS_TANK)
			{
				if (!IsVictimDead)
				{
					DamageToTank[attacker][victim] += LastDmg;
					if (tanktype[victim] == TANK5)
						PrintHintText(attacker, "帝王坦克 \n生命值:(%d) 速度:(%.1f) 累积伤害:(%d)  承受伤害[士兵]:(%d)", LastHealth, tank_cv_speed, DamageToTank[attacker][victim], BearDamage[attacker][victim]);
					else
						PrintHintText(attacker, "超级坦克(第%d阶段) \n生命值:(%d) 速度:(%.1f) 累积伤害:(%d) 承受伤害[士兵]:(%d)", tanktype[victim], LastHealth, tank_cv_speed, DamageToTank[attacker][victim], BearDamage[attacker][victim]);
				}
				else
					LastDamage[attacker] = LastDmg;
			}
		}
		
		/*
		if (IsValidPlayer(victim, false))
		{
			//士兵承担伤害经验
			if (GetClientTeam(victim) == 2 && JD[victim] == 3 && GetDmgExp > 0)
			{
				new giveexp = RoundToNearest(GetDmgExpEffect * GetDmgExp + VIPAdd(victim, RoundToNearest(GetDmgExpEffect * GetDmgExp), 1, true));
				new givecash = RoundToNearest(GetDmgCashEffect * GetDmgExp + VIPAdd(victim, RoundToNearest(GetDmgCashEffect * GetDmgExp), 1, false));
				if (giveexp > 0 && givecash > 0)
				{
					EXP[victim] += giveexp;
					Cash[victim] += givecash;
					CPrintToChat(victim, "{olive}[系统]{lightgreen}你承受了 {olive}%d{lightgreen}坦克伤害, 获得 {green}%d{olive}EXP, {green}%d{olive}$", GetDmgExp, giveexp, givecash);
				}
			}
		}*/
		
		
		//玩家|坦克伤害血量修正
		if (GetClientTeam(victim) == 3 && victim_ZombieClass == CLASS_TANK && !IsPlayerIncapped(victim))
		{
			if (GetEntProp(victim, Prop_Data, "m_iHealth") != LastHealth && LastHealth > 0)
				SetEntProp(victim, Prop_Data, "m_iHealth", LastHealth), LastDmg = 0;
		}
		
		//士兵承受伤害
		if (JD[victim] == 3 && ack_ZombieClass == CLASS_TANK && LastDmg > 0)
		{
			BearDamage[victim][attacker] += LastDmg;
			CPrintToChat(victim, "{red}[系统]\x03你承担了坦克[%N]当前攻击的 {red}%d点\x03伤害.", attacker, LastDmg);
		}
		
		
		if (GetClientTeam(victim) == 2 && !IsPlayerIncapped(victim))
		{
			if (GetEntProp(victim, Prop_Data, "m_iHealth") != LastHealth && LastHealth > 0)
				SetEntProp(victim, Prop_Data, "m_iHealth", LastHealth), LastDmg = 0;					
		}	
		
		
	}	

	//防止负数
	if (LastDmg < 0)
		LastDmg = 0;
	if (LastHealth < 0)
		LastHealth = 0;
		
	SetEventInt(event, "dmg_health", LastDmg);	
	SetEventInt(event, "health", LastHealth);
	return Plugin_Changed;
}

/* 普感受伤 */
public Action:Event_InfectedHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "entityid");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg = GetEventInt(event, "amount");
	new eventhealth = GetEntProp(victim, Prop_Data, "m_iHealth");
	new dmgtype = GetEventInt(event, "type");

	new Float:AddDamage = 0.0;
	new bool:IsVictimDead = false;

	//弹药专家技能
	if (IsValidPlayer(attacker, false) && IsValidEntity(victim))
	{
		if (dmgtype == 1073741826 
		|| dmgtype == 2 
		|| dmgtype == -2147483646 
		|| dmgtype == -1073741822 
		|| dmgtype == -2130706430 
		|| dmgtype == -1610612734 
		|| dmgtype == 33554432 
		|| dmgtype == 1107296256 
		|| dmgtype == 16777280)
		{
			SuckBloodAmmoAttack(attacker, victim);
			PoisonAmmoAttack(attacker, victim, "");
		}
	}
	
	if (IsValidPlayer(attacker))
	{
		/* 力量效果 */
		if(GetClientTeam(attacker) == 2 && EnergyEnhanceLv[attacker]>0)//攻防强化术
		{
			AddDamage = dmg*(StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker]);
		}
		else //普通攻击
		{
			AddDamage = dmg*(StrEffect[attacker]);
		}
		new health = RoundToNearest(eventhealth - AddDamage);
		SetEntProp(victim, Prop_Data, "m_iHealth", health);
		SetEventInt(event, "amount", RoundToNearest(dmg + AddDamage));
	}

	if(RoundToNearest(eventhealth - dmg - AddDamage) <= 0)
	{
		IsVictimDead = true;
	}

	/* 伤害显示 */
	if(IsValidPlayer(attacker))
	{
		if(!IsFakeClient(attacker))
		{
			if(!IsVictimDead)	DisplayDamage(RoundToNearest(dmg + AddDamage), ALIVE, attacker);
			else LastDamage[attacker] = RoundToNearest(dmg + AddDamage);
		}
	}

	return Plugin_Changed;
}


/* 子弹碰撞事件 */
public Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl Float:Origin[3];	
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	/*
	if (IsValidPlayer(Client, false))
	{
		TE_SetupGlowSprite(Origin, g_GlowSprite, 0.02, 0.5, 3000);
		TE_SendToAll();	
	}
	*/
	
	//精灵尘埃弹
	BrokenAmmoRangeEffects(Client, Origin);
}

/************************************************************************
*	Event事件END
************************************************************************/


/************************************************************************
*	快捷指令Start
************************************************************************/

public Action:AddStrength(Client, args) //力量
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Str[Client] + 1 > Limit_Str)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Str);
				return Plugin_Handled;
			}
			else
			{
				Str[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_STR, Str[Client], StrEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if (StringToInt(arg) <= 0)
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Str[Client] + StringToInt(arg) > Limit_Str)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Str);
				return Plugin_Handled;
			}
			else
			{
				Str[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_STR, Str[Client], StrEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}
public Action:AddAgile(Client, args) //敏捷
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Agi[Client] + 1 > Limit_Agi)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Agi);
				return Plugin_Handled;
			}
			else
			{
				Agi[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_AGI, Agi[Client], AgiEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if ( 0 >= StringToInt(arg))
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Agi[Client] + StringToInt(arg) > Limit_Agi)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Agi);
				return Plugin_Handled;
			}
			else
			{
				Agi[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_AGI, Agi[Client], AgiEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}
public Action:AddHealth(Client, args) //生命
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;
		
	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Health[Client] + 1 > Limit_Health)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Health);
				return Plugin_Handled;
			}
			else
			{
				Health[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_HEALTH, Health[Client], HealthEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
				new iClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
				if(iClass != CLASS_TANK)
				{
					new HealthForStatus = GetClientHealth(Client);
					SetEntProp(Client, Prop_Data, "m_iHealth", RoundToNearest(HealthForStatus*(1+Effect_Health)));
				}
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if ( 0 >= StringToInt(arg))
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Health[Client] + StringToInt(arg) > Limit_Health)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Health);
				return Plugin_Handled;
			}
			else
			{
				Health[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_HEALTH, Health[Client], HealthEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
				new iClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
				if(iClass != CLASS_TANK)
				{
					new HealthForStatus = GetClientHealth(Client);
					SetEntProp(Client, Prop_Data, "m_iHealth", RoundToNearest(HealthForStatus*(1+Effect_Health*StringToInt(arg))));
				}
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}
public Action:AddEndurance(Client, args) //耐力
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Endurance[Client] + 1 > Limit_Endurance)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Endurance);
				return Plugin_Handled;
			}
			else
			{
				Endurance[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_ENDURANCE, Endurance[Client], EnduranceEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if ( 0 >= StringToInt(arg))
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Endurance[Client] + StringToInt(arg) > Limit_Endurance)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Endurance);
				return Plugin_Handled;
			}
			else
			{
				Endurance[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_ENDURANCE, Endurance[Client], EnduranceEffect[Client]*100);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}
public Action:AddIntelligence(Client, args) //智力
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Intelligence[Client] + 1 > Limit_Intelligence)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Intelligence);
				return Plugin_Handled;
			}
			else
			{
				Intelligence[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_INTELLIGENCE, Intelligence[Client], MaxMP[Client], IntelligenceEffect_IMP[Client]);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if ( 0 >= StringToInt(arg))
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}
		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Intelligence[Client] + StringToInt(arg) > Limit_Intelligence)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Intelligence);
				return Plugin_Handled;
			}
			else
			{
				Intelligence[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_INTELLIGENCE, Intelligence[Client], MaxMP[Client], IntelligenceEffect_IMP[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}


public Action:AddCrits(Client, args) //暴击几率
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(Crits[Client] + 1 > Limit_Crits)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Crits);
				return Plugin_Handled;
			}
			else
			{
				Crits[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_CRITS, Crits[Client], CritsEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if (StringToInt(arg) <= 0)
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(Crits[Client] + StringToInt(arg) > Limit_Crits)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_Crits);
				return Plugin_Handled;
			}
			else
			{
				Crits[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_CRITS, Crits[Client], CritsEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}

public Action:AddCritMin(Client, args) //暴击最小伤害
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(CritMin[Client] + 1 > Limit_CritMin)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_CritMin);
				return Plugin_Handled;
			}
			else
			{
				CritMin[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_CRITMIN, CritMin[Client], CritMinEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if (StringToInt(arg) <= 0)
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(CritMin[Client] + StringToInt(arg) > Limit_CritMin)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_CritMin);
				return Plugin_Handled;
			}
			else
			{
				CritMin[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_CRITMIN, CritMin[Client], CritMinEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}

public Action:AddCritMax(Client, args) //暴击最大伤害
{
	if (!IsValidPlayer(Client))
		return Plugin_Handled;

	if(StatusPoint[Client] > 0)
	{
		if (args < 1)
		{
			if(CritMax[Client] + 1 > Limit_CritMax)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_CritMax);
				return Plugin_Handled;
			}
			else
			{
				CritMax[Client] += 1;
				StatusPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_STATUS_CRITMAX, CritMax[Client], CritMaxEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
				return Plugin_Handled;
			}
		}

		decl String:arg[8];
		GetCmdArg(1, arg, sizeof(arg));

		if (StringToInt(arg) <= 0)
		{
			CPrintToChat(Client, MSG_INVALID_ARG);
			return Plugin_Handled;
		}

		if (StatusPoint[Client] >= StringToInt(arg))
		{
			if(CritMax[Client] + StringToInt(arg) > Limit_CritMax)
			{
				CPrintToChat(Client, MSG_ADD_STATUS_MAX, Limit_CritMax);
				return Plugin_Handled;
			}
			else
			{
				CritMax[Client] += StringToInt(arg);
				StatusPoint[Client] -= StringToInt(arg);
				CPrintToChat(Client, MSG_ADD_STATUS_CRITMAX, CritMax[Client], CritMaxEffect[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
		}
		else CPrintToChat(Client, MSG_StAtUS_UP_FAIL, StatusPoint[Client], StringToInt(arg));
	}
	else CPrintToChat(Client, MSG_LACK_POINTS);

	return Plugin_Handled;
}

/************************************************************************
*	快捷指令END
************************************************************************/

/************************************************************************
*	技能Funstion Start
************************************************************************/

/* 技能快捷指令 */
public Action:UseHealing(Client, args) //治疗
{
	if(GetClientTeam(Client) == 2) HealingFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:HealingFunction(Client)
{
	if(HealingLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_1);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(HealingTimer[Client] != INVALID_HANDLE)
	{
		CPrintToChat(Client, MSG_SKILL_HL_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_Healing) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_Healing), MP[Client]);
		return Plugin_Handled;
	}
	
	if(IsBioShieldEnable[Client])
	{
		PrintHintText(Client, MSG_SKILL_BS_NO_SKILL);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_Healing);

	HealingCounter[Client] = 0;
	HealingTimer[Client] = CreateTimer(1.0, HealingTimerFunction, Client, TIMER_REPEAT);

	if (VIP[Client] <= 0)
		CPrintToChatAll(MSG_SKILL_HL_ANNOUNCE, Client, HealingLv[Client]);
	else
		CPrintToChatAll("{olive}[技能] {green}%N {red}启动了{green}Lv.%d{red}的高级治疗术!", Client, HealingLv[Client]);

	//PrintToserver("[United RPG] %s使用治疗术!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:HealingTimerFunction(Handle:timer, any:Client)
{
	HealingCounter[Client]++;
	new HP = GetClientHealth(Client);
	new viphealing;
	if(HealingCounter[Client] <= HealingDuration[Client])
	{
		if (VIP[Client] > 0)
			viphealing = 3;
		else
			viphealing = 0;
			
		if (IsPlayerIncapped(Client))
			SetEntProp(Client, Prop_Data, "m_iHealth", HP + HealingEffect[Client] + viphealing);
		else
		{
			new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");
			if(MaxHP >= HP + HealingEffect[Client] + viphealing)
				SetEntProp(Client, Prop_Data, "m_iHealth", HP + HealingEffect[Client] + viphealing);
			else if(MaxHP < HP + HealingEffect[Client] + viphealing)
				SetEntProp(Client, Prop_Data, "m_iHealth", MaxHP);
		}

		decl Float:myPos[3];
		GetClientAbsOrigin(Client, myPos);
		ShowParticle(myPos, PARTICLE_HLEFFECT, 1.0);  //ShowParticle  =  显示粒子
//		ScreenFade(Client, 0, 80, 0, 150, 30, 1); //加血一闪一闪
	} else
	{
		if (IsValidPlayer(Client))
		{
			CPrintToChat(Client, MSG_SKILL_HL_END);
		}
		KillTimer(timer);
		HealingTimer[Client] = INVALID_HANDLE;
	}
}

/* 超级狂飙模式关联2 */
public Action:HealingkbFunction(Client)
{
	if(HealingkbLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}
	
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(HealingkbTimer[Client] != INVALID_HANDLE)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	HealingkbCounter[Client] = 0;
	HealingkbTimer[Client] = CreateTimer(1.0, HealingkbTimerFunction, Client, TIMER_REPEAT);

	CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, HealingwxFunction(Client), HealingkbLv[Client]);

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:HealingkbTimerFunction(Handle:timer, any:Client)
{
	HealingkbCounter[Client]++;
	new HP = GetClientHealth(Client);
	if(HealingkbCounter[Client] <= HealingkbDuration[Client])
	{
		if (IsPlayerIncapped(Client))
		{
			SetEntProp(Client, Prop_Data, "m_iMaxHealth", ChainkbLightningFunction(Client), HP+HealingkbEffect);
		} else
		{
			new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");
			if(MaxHP > HP+HealingkbEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", ChainkbLightningFunction(Client), MaxHP);
			}
			else if(MaxHP < HP+HealingkbEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", ChainkbLightningFunction(Client), MaxHP);
			}
		}
		decl Float:myPos[3];
		GetClientAbsOrigin(Client, myPos);
		ShowParticle(myPos, PARTICLE_HLEFFECT, 1.0);
	} else
	{
		if (IsValidPlayer(Client))
		{
			CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		}
		KillTimer(timer);
		HealingkbTimer[Client] = INVALID_HANDLE;
	}
}

/* 超级狂飙模式关联 限时子弹 */
public Action:HealingwxFunction(Client)
{
	if(HealingwxLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}
	
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(HealingwxTimer[Client] != INVALID_HANDLE)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	HealingwxCounter[Client] = 0;
	HealingwxTimer[Client] = CreateTimer(1.0, HealingwxTimerFunction, Client, TIMER_REPEAT);

	CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, HealinggbdFunction(Client), HealingwxLv[Client]);

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:HealingwxTimerFunction(Handle:timer, any:Client)
{
	HealingwxCounter[Client]++;
	new HP = GetClientHealth(Client);
	if(HealingwxCounter[Client] <= HealingwxDuration[Client])
	{
		if (IsPlayerIncapped(Client))
		{
			SetEntProp(Client, Prop_Data, "m_iMaxHealth", HP+HealingwxEffect, CheatCommand(Client, "upgrade_add", "Incendiary_ammo"));
		} else
		{
			new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");
			if(MaxHP > HP+HealingwxEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", MaxHP, CheatCommand(Client, "upgrade_add", "Incendiary_ammo"));
			}
			else if(MaxHP < HP+HealingwxEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", MaxHP, CheatCommand(Client, "upgrade_add", "Incendiary_ammo"));
			}
		}
		decl Float:myPos[3];
		GetClientAbsOrigin(Client, myPos);
		ShowParticle(myPos, PARTICLE_HLEFFECT, 1.0);
	} else
	{
		if (IsValidPlayer(Client))
		{
			CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		}
		KillTimer(timer);
		HealingwxTimer[Client] = INVALID_HANDLE;
	}
}

/* 超级狂飙模式关联 限时子弹2 */
public Action:HealinggbdFunction(Client)
{
	if(HealinggbdLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}
	
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(HealinggbdTimer[Client] != INVALID_HANDLE)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	HealinggbdCounter[Client] = 0;
	HealinggbdTimer[Client] = CreateTimer(1.0, HealinggbdTimerFunction, Client, TIMER_REPEAT);

	CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, HealinggbdLv[Client]);

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:HealinggbdTimerFunction(Handle:timer, any:Client)
{
	HealinggbdCounter[Client]++;
	new HP = GetClientHealth(Client);
	if(HealinggbdCounter[Client] <= HealinggbdDuration[Client])
	{
		if (IsPlayerIncapped(Client))
		{
			SetEntProp(Client, Prop_Data, "m_iMaxHealth", HP+HealinggbdEffect, CheatCommand(Client, "upgrade_add", "explosive_ammo"));
		} else
		{
			new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");
			if(MaxHP > HP+HealinggbdEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", MaxHP, CheatCommand(Client, "upgrade_add", "explosive_ammo"));
			}
			else if(MaxHP < HP+HealinggbdEffect)
			{
				SetEntProp(Client, Prop_Data, "m_iMaxHealth", MaxHP, CheatCommand(Client, "upgrade_add", "explosive_ammo"));
			}
		}
		decl Float:myPos[3];
		GetClientAbsOrigin(Client, myPos);
		ShowParticle(myPos, PARTICLE_HLEFFECT, 1.0);
	} else
	{
		if (IsValidPlayer(Client))
		{
			CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		}
		KillTimer(timer);
		HealinggbdTimer[Client] = INVALID_HANDLE;
	}
}

/* 制造子弹 */
public Action:UseAmmoMaking(Client, args)
{
	if(GetClientTeam(Client) == 2) AmmoMakingFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:AmmoMakingFunction(Client)
{
	if(JD[Client] != 1)
	{
		CPrintToChat(Client, MSG_NEED_JOB1);
		return Plugin_Handled;
	}


	if(AmmoMakingLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_3);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_AmmoMaking) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_AmmoMaking), MP[Client]);
		return Plugin_Handled;
	}

	new gun1 = GetPlayerWeaponSlot(Client, 0);
	new gun2 = GetPlayerWeaponSlot(Client, 1);

	new AddedAmmo;
	decl String:gun1ClassName[64];
	decl String:gun2ClassName[64];

	if(gun1 != -1)
	{
		GetEdictClassname(gun1, gun1ClassName, sizeof(gun1ClassName));
		
		if(StrContains(gun1ClassName, "shotgun") >= 0 || StrContains(gun1ClassName, "sniper") >= 0 || StrContains(gun1ClassName, "hunting_rifle") >= 0)	
			AddedAmmo=AmmoMakingLv[Client];
		else if(StrContains(gun1ClassName, "grenade_launcher") >= 0)	
			AddedAmmo=0;
		else 
			AddedAmmo=AmmoMakingEffect[Client];
			
		new CC1 = GetEntProp(gun1, Prop_Send, "m_iClip1");
		if(CC1+AmmoMakingEffect[Client] <= 255)	
			SetEntProp(gun1, Prop_Send, "m_iClip1", CC1+AddedAmmo);
		else 
			SetEntProp(gun1, Prop_Send, "m_iClip1", 255);
	}

	if(gun2 != -1)
	{
		GetEdictClassname(gun2, gun2ClassName, sizeof(gun2ClassName));
		if(StrContains(gun2ClassName, "melee") < 0)
		{
			new CC1 = GetEntProp(gun2, Prop_Send, "m_iClip1");
			if(CC1+AmmoMakingEffect[Client] <= 255)	SetEntProp(gun2, Prop_Send, "m_iClip1", CC1+AmmoMakingEffect[Client]);
			else SetEntProp(gun2, Prop_Send, "m_iClip1", 255);
		}
	}

	if(gun1 != -1 || (gun2 != -1 && StrContains(gun2ClassName, "melee") < 0))
	{
		MP[Client] -= GetConVarInt(Cost_AmmoMaking);
		if(AddedAmmo > 0)	
			if(StrContains(gun1ClassName, "grenade_launcher") >= 0)	
				CPrintToChat(Client, "{olive}[技能] {green}子弹制造术{blue}无法制造{green}榴弹发射器{blue}的子弹.");
			else
				CPrintToChatAll(MSG_SKILL_AM_ANNOUNCE, Client, AmmoMakingLv[Client], AddedAmmo);
		else 
		{
			if(StrContains(gun1ClassName, "grenade_launcher") >= 0)	
				CPrintToChat(Client, "{olive}[技能] {green}子弹制造术{blue}无法制造{green}榴弹发射器{blue}的子弹.");
			else
				CPrintToChatAll(MSG_SKILL_AM_ANNOUNCE, Client, AmmoMakingLv[Client], AmmoMakingEffect[Client]);
		}

		//PrintToserver("[United RPG] %s使用子弹制造术!", NameInfo(Client, simple));
	}
	else 
		CPrintToChat(Client, MSG_SKILL_AM_NOGUN);

	return Plugin_Handled;
}

/* 核弹头*/
public Action:UseAmmoMakingmiss(Client, args)
{
	if(GetClientTeam(Client) == 2) AmmoMakingmissFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:AmmoMakingmissFunction(Client)
{
	if(JD[Client] != 1)
	{
		CPrintToChat(Client, MSG_NEED_JOB1);
		return Plugin_Handled;
	}

	if(AmmoMakingmissLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_19);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(MP[Client] != MaxMP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MaxMP[Client], MP[Client]);
		return Plugin_Handled;
	}
	
	MP[Client] = 0;

	new gun1 = GetPlayerWeaponSlot(Client, 0);
	new gun2 = GetPlayerWeaponSlot(Client, 1);

	new AddedAmmo;
	decl String:gun1ClassName[64];
	decl String:gun2ClassName[64];

	if(gun1 != -1)
	{
		GetEdictClassname(gun1, gun1ClassName, sizeof(gun1ClassName));
		if(StrContains(gun1ClassName, "shotgun") >= 0 || StrContains(gun1ClassName, "sniper") >= 0 || StrContains(gun1ClassName, "hunting_rifle") >= 0)	AddedAmmo=AmmoMakingmissLv[Client];
		else if(StrContains(gun1ClassName, "grenade_launcher") >= 0)	AddedAmmo=AmmoMakingmissLv[Client]/8;
		else AddedAmmo=AmmoMakingmissEffect[Client];
		new CC1 = GetEntProp(gun1, Prop_Send, "m_iClip1");
		if(CC1+AmmoMakingmissEffect[Client] <= 255)	SetEntProp(gun1, Prop_Send, "m_iClip1", CC1+AddedAmmo);
		else SetEntProp(gun1, Prop_Send, "m_iClip1", 255);
	}

	if(gun2 != -1)
	{
		GetEdictClassname(gun2, gun2ClassName, sizeof(gun2ClassName));
		if(StrContains(gun2ClassName, "melee") < 0)
		{
			new CC1 = GetEntProp(gun2, Prop_Send, "m_iClip1");
			if(CC1+AmmoMakingmissEffect[Client] <= 255)	SetEntProp(gun2, Prop_Send, "m_iClip1", CC1+AmmoMakingmissEffect[Client]);
			else SetEntProp(gun2, Prop_Send, "m_iClip1", 255);
		}
	}

	if(gun1 != -1 || (gun2 != -1 && StrContains(gun2ClassName, "melee") < 0))
	{
		MP[Client] -= GetConVarInt(Cost_AmmoMakingmiss);
		if(AddedAmmo > 0)	CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, nuclearcommand(Client));
		else CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE, nuclearcommand(Client));

		//PrintToserver("[United RPG] %s放出了蘑菇云核弹!快撤离!", NameInfo(Client, simple));
	}else CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, nuclearcommand(Client));

	return Plugin_Handled;
}

/* 火焰极速 */
public Action:UseSprint(Client, args)
{
	if(GetClientTeam(Client) == 2) SprintFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:SprintFunction(Client)
{
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_NEED_JOB2);
		return Plugin_Handled;
	}

	if(SprintLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_4);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsSprintEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_SP_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_Sprint) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_Sprint), MP[Client]);
		return Plugin_Handled;
	}

	IsSprintEnable[Client] = true;	//这行没变
	MP[Client] -= GetConVarInt(Cost_Sprint);	//这行没变
	//SprinDurationTimer[Client] = CreateTimer(SprintDuration[Client], SprinDurationFunction, Client);
	new Handle:pack;  
	new Float:pos[3];
	SprinDurationTimer[Client] = CreateDataTimer(HealingBallInterval1[Client], SprinDurationFunction, pack, TIMER_REPEAT);	//这行没变
	WritePackCell(pack, Client);  
	WritePackFloat(pack, pos[0]);  
	WritePackFloat(pack, pos[1]);  
	WritePackFloat(pack, pos[2]);  
	WritePackFloat(pack, GetEngineTime());  
	

	CPrintToChatAll("\x05[{teamcolor}EX技能\x05]\x01:玩家\x04 %N \x01启动了\x04LV.%d{teamcolor}的火焰暴走 ", Client, SprintLv[Client]);	
	return Plugin_Handled;
}

public Action:SprinDurationFunction(Handle:timer, Handle:pack)
{
	decl Float:pos[3], Float:entpos[3], Float:distance[3];   
	ResetPack(pack); 
	new Client = ReadPackCell(pack);  
	pos[0] = ReadPackFloat(pack); 
	pos[1] = ReadPackFloat(pack);  
	pos[2] = ReadPackFloat(pack); 
	new Float:time=ReadPackFloat(pack); 

	new iMaxEntities = GetMaxEntities();  
	new num;  
	new Float:Radius=float(50); 
	
	if(GetEngineTime() - time < SprintDuration[Client])
	{
		SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", (1.0 + SprintEffect[Client])*(1.0 + AgiEffect[Client]));	//这行没变
		SetEntityGravity(Client, (1.0 + SprintEffect[Client])/(1.0 + AgiEffect[Client]));	//这行没变
		
		new Float:NowLocation[3];
		GetClientAbsOrigin(Client, NowLocation);
		ShowParticle(NowLocation, FireBall_Particle_Fire01, 0.05);
		
		for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    	{
			if (num > 1)
				break;
			
			if (IsCommonInfected(iEntity))
       		{
				new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");
				if (health > 0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, NowLocation, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						IgniteEntity(iEntity, 3.0);
						num++;
					}
				}
			}
		}
	} else
	{
		KillTimer(timer);
		SprinDurationTimer[Client] = INVALID_HANDLE;
		IsSprintEnable[Client] = false;
		SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", 1.0*(1.0 + AgiEffect[Client]));
		SetEntityGravity(Client, 1.0/(1.0 + AgiEffect[Client]));
		
		if (IsValidPlayer(Client))
		{
			CPrintToChat(Client, MSG_SKILL_SP_END);
		}
	}
	

	return Plugin_Handled;
}

/* 上弹速度 */
public Event_Reload (Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client=GetClientOfUserId(GetEventInt(event,"userid"));
	new iEntid = GetEntDataEnt2(Client,S_rActiveW);
	decl String:stClass[32];
	GetEntityNetClass(iEntid,stClass,32);
	if (IsMeleeSpeedEnable[Client])
	{
		if (StrContains(stClass,"shotgun",false) == -1)
		{
			MagStart(iEntid,Client);
			return;
		}
		if (StrContains(stClass,"pumpshotgun",false) != -1
		|| StrContains(stClass,"shotgun_chrome",false) != -1
		|| StrContains(stClass,"shotgun_spas",false) != -1
		|| StrContains(stClass,"autoshotgun",false) != -1)
		{
			CreateTimer(0.1,PumpshotgunStart,iEntid);
			return;
		}
	}
}
public Action:PumpshotgunStart (Handle:timer, any:client)
{
	SetEntDataFloat(client,	S_rStartDur,	0.2,	true);
	SetEntDataFloat(client,	S_rInsertDur,	0.2,	true);
	SetEntDataFloat(client,	S_rEndDur,		0.2,	true);
	SetEntDataFloat(client, S_rPlayRate, 0.2, true);
	return Plugin_Continue;
}
MagStart (iEntid,Client)
{
	//new Float:flGameTime = GetGameTime();
	//new Float:flNextTime_ret = GetEntDataFloat(iEntid,S_rNextPAtt);
	
	SetEntDataFloat(iEntid, s_rTimeIdle, 0.1, true);
	SetEntDataFloat(iEntid, S_rNextPAtt, 0.1, true);
	SetEntDataFloat(Client, s_rNextAtt, 0.1, true);
	SetEntDataFloat(iEntid, S_rPlayRate, 0.1, true);
	
}


/* 地震术 */
public Action:UseEarthQuake(Client, args)
{
	if(GetClientTeam(Client) == 2) EarthQuakeFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:EarthQuakeFunction(Client)
{
	if(EarthQuakeLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_20);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_EarthQuake) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_EarthQuake), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_EarthQuake);

	new Float:Radius=float(EarthQuakeRadius[Client]);
	new Float:pos[3];
	new Float:_pos[3];
	GetClientAbsOrigin(Client, _pos);
	pos[0] = _pos[0];
	pos[1] = _pos[1];
	pos[2] = _pos[2]+30.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, steelblueeColor, 10, 0);//固定外圈
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, PlumredColor, 10, 0);//扩散内圈
	TE_SendToAll();

	//地震伤害效果+范围内的震动效果
	new Float:NowLocation[3];
	GetClientAbsOrigin(Client, NowLocation);
	new Float:entpos[3];
	new iMaxEntities = GetMaxEntities();
	new Float:distance[3];
	new num;
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    {
		if (num > EarthQuakeMaxKill[Client])
			break;
			
		if (IsCommonInfected(iEntity))
        {
			new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");
			if (health > 0)
			{
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, NowLocation, distance);
				if(GetVectorLength(distance) <= EarthQuakeRadius[Client])
				{
					DealDamage(Client, iEntity, health + 1, -2130706430, "earth_quake");
					num++;
				}
			}
		}
	}

	ShowParticle(NowLocation, PARTICLE_EARTHQUAKEEFFECT, 5.0);
	EmitSoundToAll(EQSOUND, Client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, _pos, NULL_VECTOR, true, 0.0);
	CPrintToChatAll(MSG_SKILL_EQ_ANNOUNCE, Client, EarthQuakeLv[Client]);

	return Plugin_Handled;
}

/* 无限子弹 */
public Action:UseInfiniteAmmo(Client, args)
{
	if(GetClientTeam(Client) == 2) InfiniteAmmoFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:InfiniteAmmoFunction(Client)
{
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_NEED_JOB2);
		return Plugin_Handled;
	}

	if(InfiniteAmmoLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_5);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsInfiniteAmmoEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_IA_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_InfiniteAmmo) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_InfiniteAmmo), MP[Client]);
		return Plugin_Handled;
	}

	IsInfiniteAmmoEnable[Client] = true;
	MP[Client] -= GetConVarInt(Cost_InfiniteAmmo);

	InfiniteAmmoDurationTimer[Client] = CreateTimer(InfiniteAmmoDuration[Client], InfiniteAmmoDurationFunction, Client);

	CPrintToChatAll(MSG_SKILL_IA_ANNOUNCE, Client, InfiniteAmmoLv[Client]);

	//PrintToserver("[United RPG] %s启动无限子弹术!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:InfiniteAmmoDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	InfiniteAmmoDurationTimer[Client] = INVALID_HANDLE;
	IsInfiniteAmmoEnable[Client] = false;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_IA_END);
	}

	return Plugin_Handled;
}

/* 无敌术 */
public Action:UseBioShield(Client, args)
{
	if(GetClientTeam(Client) == 2) BioShieldFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:BioShieldFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_NEED_JOB3);
		return Plugin_Handled;
	}

	if(BioShieldLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_6);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsBioShieldEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_BS_ENABLED);
		return Plugin_Handled;
	}
	
	if(!IsBioShieldReady[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_BioShield) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_BioShield), MP[Client]);
		return Plugin_Handled;
	}
	
	new HP = GetClientHealth(Client);
	new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");

	if(HP > MaxHP*BioShieldSideEffect[Client])
	{
		IsBioShieldEnable[Client] = true;
		MP[Client] -= GetConVarInt(Cost_BioShield);

		SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
		BioShieldDurationTimer[Client] = CreateTimer(BioShieldDuration[Client], BioShieldDurationFunction, Client);
		
		SetEntProp(Client, Prop_Data, "m_iHealth", RoundToNearest(HP - MaxHP*BioShieldSideEffect[Client]));
		
		/*  停止治疗术Timer */
		if(HealingTimer[Client] != INVALID_HANDLE)
		{
			KillTimer(HealingTimer[Client]);
			HealingTimer[Client] = INVALID_HANDLE;
		}
		/* 停止反伤术效果Timer */
		if(DamageReflectDurationTimer[Client] != INVALID_HANDLE)
		{
			IsDamageReflectEnable[Client] = false;
			KillTimer(DamageReflectDurationTimer[Client]);
			DamageReflectDurationTimer[Client] = INVALID_HANDLE;
		}
		/* 近战嗜血术效果Timer */
		if(MeleeSpeedDurationTimer[Client] != INVALID_HANDLE)
		{
			IsMeleeSpeedEnable[Client] = false;
			KillTimer(MeleeSpeedDurationTimer[Client]);
			MeleeSpeedDurationTimer[Client] = INVALID_HANDLE;
		}

		CPrintToChatAll(MSG_SKILL_BS_ANNOUNCE, Client, BioShieldLv[Client]);

		//PrintToserver("[United RPG] %s启动无敌术!", NameInfo(Client, simple));
	}
	else CPrintToChat(Client, MSG_SKILL_BS_NEED_HP);

	return Plugin_Handled;
}

public Action:BioShieldDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldDurationTimer[Client] = INVALID_HANDLE;
	IsBioShieldEnable[Client] = false;
	if(IsValidPlayer(Client))	SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
	
	IsBioShieldReady[Client] = false;
	BioShieldCDTimer[Client] = CreateTimer(BioShieldCDTime[Client], BioShieldCDTimerFunction, Client);

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BS_END);
	}

	return Plugin_Handled;
}

public Action:BioShieldCDTimerFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldCDTimer[Client] = INVALID_HANDLE;
	IsBioShieldReady[Client] = true;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BS_CHARGED);
	}

	return Plugin_Handled;
}

/* 潜能大爆发 */
public Action:UseBioShieldmiss(Client, args)
{
	if(GetClientTeam(Client) == 2) BioShieldmissFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:BioShieldmissFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_NEED_JOB3);
		return Plugin_Handled;
	}

	if(BioShieldmissLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_22);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsBioShieldmissEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}
	
	if(!IsBioShieldmissReady[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_BioShieldmiss) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_BioShieldmiss), MP[Client]);
		return Plugin_Handled;
	}
	
	IsBioShieldmissEnable[Client] = true;
	MP[Client] -= GetConVarInt(Cost_BioShieldmiss);

	SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
	BioShieldmissDurationTimer[Client] = CreateTimer(BioShieldmissDuration[Client], BioShieldmissDurationFunction, Client);

	CPrintToChatAll(MSG_SKILL_BS_ANNOUNCEMISS, Client, BioShieldmissLv[Client], ChainmissLightningFunction(Client));

	//PrintToserver("[United RPG] %s启动暗夜生物专家术!清场+回血!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:BioShieldmissDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldmissDurationTimer[Client] = INVALID_HANDLE;
	IsBioShieldmissEnable[Client] = false;
	if(IsValidPlayer(Client))	SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
	
	IsBioShieldmissReady[Client] = false;
	BioShieldmissCDTimer[Client] = CreateTimer(BioShieldmissCDTime[Client], BioShieldmissCDTimerFunction, Client);

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BS_ENDMISS);
	}

	return Plugin_Handled;
}

public Action:BioShieldmissCDTimerFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldmissCDTimer[Client] = INVALID_HANDLE;
	IsBioShieldmissReady[Client] = true;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BSMISS_CHARGED);
	}

	return Plugin_Handled;
}

/* 狂暴者模式 */
public Action:UseBioShieldkb(Client, args)
{
	if(GetClientTeam(Client) == 2) BioShieldkbFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:BioShieldkbFunction(Client)
{
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_NEED_JOB2);
		return Plugin_Handled;
	}

	if(BioShieldkbLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_23);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsBioShieldkbEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_BS_ENABLEDKB);
		return Plugin_Handled;
	}
	
	if(!IsBioShieldkbReady[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(MP[Client] != MaxMP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MaxMP[Client], MP[Client]);
		return Plugin_Handled;
	}
	
	IsBioShieldkbEnable[Client] = true;
	MP[Client] -= GetConVarInt(Cost_BioShieldkb);

	SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
	BioShieldkbDurationTimer[Client] = CreateTimer(BioShieldkbDuration[Client], BioShieldkbDurationFunction, Client);

	CPrintToChatAll(MSG_SKILL_BS_ANNOUNCEKB, Client, BioShieldkbLv[Client], HealingkbFunction(Client));

	//PrintToserver("[United RPG] %s启动狂暴者模式!粉碎的愤怒", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:BioShieldkbDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldkbDurationTimer[Client] = INVALID_HANDLE;
	IsBioShieldkbEnable[Client] = false;
	if(IsValidPlayer(Client))	SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
	
	IsBioShieldkbReady[Client] = false;
	BioShieldkbCDTimer[Client] = CreateTimer(BioShieldkbCDTime[Client], BioShieldkbCDTimerFunction, Client);

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BS_ENDKB);
	}

	return Plugin_Handled;
}

public Action:BioShieldkbCDTimerFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	BioShieldkbCDTimer[Client] = INVALID_HANDLE;
	IsBioShieldkbReady[Client] = true;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_BS_CHARGEDKB);
	}

	return Plugin_Handled;
}

/* 反伤术 */
public Action:UseDamageReflect(Client, args)
{
	if(GetClientTeam(Client) == 2) DamageReflectFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:DamageReflectFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_NEED_JOB3);
		return Plugin_Handled;
	}

	if(DamageReflectLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_10);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsDamageReflectEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_DR_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_DamageReflect) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_DamageReflect), MP[Client]);
		return Plugin_Handled;
	}
	
	if(IsBioShieldEnable[Client])
	{
		PrintHintText(Client, MSG_SKILL_BS_NO_SKILL);
		return Plugin_Handled;
	}

	new HP = GetClientHealth(Client);
	new MaxHP = GetEntProp(Client, Prop_Data, "m_iMaxHealth");

	if(HP > MaxHP*DamageReflectSideEffect[Client])
	{
		IsDamageReflectEnable[Client] = true;
		MP[Client] -= GetConVarInt(Cost_DamageReflect);

		SetEntProp(Client, Prop_Data, "m_iHealth", RoundToNearest(HP - MaxHP*DamageReflectSideEffect[Client]));
		DamageReflectDurationTimer[Client] = CreateTimer(DamageReflectDuration[Client], DamageReflectDurationFunction, Client);

		CPrintToChatAll(MSG_SKILL_DR_ANNOUNCE, Client, RoundToNearest(MaxHP*DamageReflectSideEffect[Client]),DamageReflectLv[Client]);

		//PrintToserver("[United RPG] %s启动了反伤术!", NameInfo(Client, simple));
	}
	else CPrintToChat(Client, MSG_SKILL_DR_NEED_HP);
	return Plugin_Handled;
}

public Action:DamageReflectDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	DamageReflectDurationTimer[Client] = INVALID_HANDLE;
	IsDamageReflectEnable[Client] = false;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_DR_END);
	}

	return Plugin_Handled;
}

/* 近战嗜血术 */
public Action:UseMeleeSpeed(Client, args)
{
	if(GetClientTeam(Client) == 2) MeleeSpeedFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:MeleeSpeedFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_NEED_JOB3);
		return Plugin_Handled;
	}

	if(MeleeSpeedLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_11);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsMeleeSpeedEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_MS_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_MeleeSpeed) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_MeleeSpeed), MP[Client]);
		return Plugin_Handled;
	}
	
	if(IsBioShieldEnable[Client])
	{
		PrintHintText(Client, MSG_SKILL_BS_NO_SKILL);
		return Plugin_Handled;
	}
	
	IsMeleeSpeedEnable[Client] = true;
	MP[Client] -= GetConVarInt(Cost_MeleeSpeed);

	MeleeSpeedDurationTimer[Client] = CreateTimer(MeleeSpeedDuration[Client], MeleeSpeedDurationFunction, Client);

	CPrintToChatAll(MSG_SKILL_MS_ANNOUNCE, Client, MeleeSpeedLv[Client]);

	//PrintToserver("[United RPG] %s启动近战嗜血术!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:MeleeSpeedDurationFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	MeleeSpeedDurationTimer[Client] = INVALID_HANDLE;
	IsMeleeSpeedEnable[Client] = false;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MS_END);
	}

	return Plugin_Handled;
}

/* 卫星炮 */
public Action:UseSatelliteCannon(Client, args)
{
	if(GetClientTeam(Client) == 2) SatelliteCannonFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:SatelliteCannonFunction(Client)
{
	if(JD[Client] != 1)
	{
		CPrintToChat(Client, MSG_NEED_JOB1);
		return Plugin_Handled;
	}

	if(SatelliteCannonLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_14);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(!IsSatelliteCannonReady[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_SatelliteCannon) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_SatelliteCannon), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_SatelliteCannon);

	new Float:Radius=float(SatelliteCannonRadius[Client]);
	new Float:pos[3];
	GetTracePosition(Client, pos); //得到目标位置
	EmitAmbientSound(SOUND_TRACING, pos);
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonLaunchTime, 5.0, 0.0, RedColor, 10, 0);//固定外圈BuleColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, Radius, 0.1, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonLaunchTime, 5.0, 0.0, GreenColor, 10, 0);//扩散内圈RedColor
	TE_SendToAll();

	IsSatelliteCannonReady[Client] = false;

	new Handle:pack;
	CreateDataTimer(SatelliteCannonLaunchTime, SatelliteCannonTimerFunction, pack);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);

	CPrintToChatAll(MSG_SKILL_SC_ANNOUNCE, Client, SatelliteCannonLv[Client]);

	//PrintToserver("[United RPG] %s启动了卫星炮!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:SatelliteCannonTimerFunction(Handle:timer, Handle:pack)
{
	new Client;
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];
	new Float:Radius=float(SatelliteCannonRadius[Client]);

	ResetPack(pack);
	Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);

	CreateLaserEffect(Client, pos, 230, 230, 80, 230, 6.0, 1.0, LASERMODE_VARTICAL);

	/* Explode */
	LittleFlower(pos, EXPLODE, Client);
	ShowParticle(pos, PARTICLE_SCEFFECT, 10.0);
	EmitAmbientSound(SatelliteCannon_Sound_Launch, pos);

	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, SatelliteCannonDamage[Client], 64, "satellite_cannon");
				}
			} else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, SatelliteCannonSurvivorDamage[Client], 64, "satellite_cannon");
				}
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    {
        if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
        {
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(Client, iEntity, RoundToNearest(SatelliteCannonDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 64, "satellite_cannon");
			}
		}
	}
	
	PointPush(Client, pos, SatelliteCannonDamage[Client], SatelliteCannonRadius[Client], 0.3);

	SatelliteCannonCDTimer[Client] = CreateTimer(SatelliteCannonCDTime[Client], SatelliteCannonCDTimerFunction, Client);
}
public Action:SatelliteCannonCDTimerFunction(Handle:timer, any:Client)
{
	KillTimer(timer);
	SatelliteCannonCDTimer[Client] = INVALID_HANDLE;
	IsSatelliteCannonReady[Client] = true;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_SC_CHARGED);
	}

	return Plugin_Handled;
}

/* 终结式暴雷 */
public Action:UseSatelliteCannonmiss(Client, args)
{
	if(GetClientTeam(Client) == 2) SatelliteCannonmissFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:SatelliteCannonmissFunction(Client)
{
	if(JD[Client] != 5)
	{
		CPrintToChat(Client, MSG_NEED_JOB5);
		return Plugin_Handled;
	}

	if(SatelliteCannonmissLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_21);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(!IsSatelliteCannonmissReady[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(MP[Client] != MaxMP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MaxMP[Client], MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_SatelliteCannonmiss);

	new Float:pos[3];
	GetTracePosition(Client, pos); //得到目标位置
	EmitAmbientSound(SOUND_TRACINGMISS, pos);
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-0.1, SatelliteCannonmissRadius[Client], g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 15.0, 4.0, WhiteColor, 15, 0);//电流外圈WhiteColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-0.1, SatelliteCannonmissRadius[Client], g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 1.0, 13.0, WhiteColor, 18, 0);//电流外圈WhiteColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-640.1, SatelliteCannonmissRadius[Client]-640.2, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 1.0, 9.0, WhiteColor, 15, 0);//电流内圈WhiteColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-480.1, SatelliteCannonmissRadius[Client]-480.2, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 1.0, 9.0, WhiteColor, 15, 0);//电流内圈WhiteColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-320.1, SatelliteCannonmissRadius[Client]-320.2, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 1.0, 9.0, WhiteColor, 15, 0);//电流内圈WhiteColor
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, SatelliteCannonmissRadius[Client]-160.1, SatelliteCannonmissRadius[Client]-160.2, g_BeamSprite, g_HaloSprite, 0, 15, SatelliteCannonmissLaunchTime, 1.0, 9.0, WhiteColor, 15, 0);//电流内圈WhiteColor
	TE_SendToAll();

	IsSatelliteCannonmissReady[Client] = false;

	new Handle:pack;
	CreateDataTimer(SatelliteCannonmissLaunchTime, CannonmissTimerFunction, pack);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);

	CPrintToChatAll(MSG_SKILL_SC_ANNOUNCEMISS, Client, SatelliteCannonmissLv[Client]);

	//PrintToserver("[United RPG] %s启动了暗夜暴雷!感染者的末日!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:CannonmissTimerFunction(Handle:timer, Handle:pack)
{
	new Client;
	new Float:distance;
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];

	ResetPack(pack);
	Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	new Float:SkyLocation[3];
	SkyLocation[0] = pos[0];
	SkyLocation[1] = pos[1];
	SkyLocation[2] = pos[2] + 2000.0;
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 20.0, 20.0, 10, 10.0, WhiteColor, 0);
	TE_SendToAll();

	/* Explode */
	LittleFlower(pos, EXPLODE, Client);
	EmitAmbientSound(SatelliteCannonmiss_Sound_Launch, pos);
	TE_SetupSparks(pos, NULL_VECTOR, 12, 20);
	TE_SendToAll(0.5);
	TE_SetupSparks(pos, NULL_VECTOR, 12, 20);
	TE_SendToAll(1.5);
	TE_SetupSparks(pos, NULL_VECTOR, 12, 20);
	TE_SendToAll(2.5);
	TE_SetupSparks(pos, NULL_VECTOR, 12, 20);
	TE_SendToAll(3.8);
	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsValidPlayer(i))
        {
			if(GetClientTeam(i) != GetClientTeam(Client) && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				distance = GetVectorDistance(pos, entpos);
				if(distance <= SatelliteCannonmissRadius[Client])
					DealDamage(Client, i, SatelliteCannonmissDamage[Client], 0, "satellite_cannonmiss");
					
			} 
			else if(IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				distance = GetVectorDistance(pos, entpos);
				if(distance <= SatelliteCannonmissRadius[Client])
					DealDamage(Client, i, SatelliteCannonmissSurvivorDamage[Client], 0, "satellite_cannonmiss");
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    {
        if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
        {
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			distance = GetVectorDistance(pos, entpos);
			if(distance <= SatelliteCannonmissRadius[Client])
				DealDamage(Client, iEntity, RoundToNearest(SatelliteCannonmissDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 0, "satellite_cannonmiss");
		}
	}

	SatelliteCannonmissCDTimer[Client] = CreateTimer(SatelliteCannonmissCDTime[Client], CannonmissCDTimerFunction, Client);
}
public Action:CannonmissCDTimerFunction(Handle:timer, any:Client)
{
	SatelliteCannonmissCDTimer[Client] = INVALID_HANDLE;
	IsSatelliteCannonmissReady[Client] = true;

	if (IsValidPlayer(Client))
		CPrintToChat(Client, MSG_SKILL_SC_CHARGEDMISS);
		
	KillTimer(timer);
}

//冰之传送
public Action:UseTeleportToSelect(Client, args)
{
	if(GetClientTeam(Client) == 2) TeleportToSelectMenu(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);

	return Plugin_Handled;
}

public Action:TeleportToSelectMenu(Client)
{
	if(JD[Client] != 4)
	{
		CPrintToChat(Client, MSG_NEED_JOB4);
		return Plugin_Handled;
	}

	if(TeleportToSelectLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_7);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsTeleportToSelectEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_TeleportToSelect) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_TeleportToSelect), MP[Client]);
		return Plugin_Handled;
	}

	new Handle:menu = CreateMenu(TeleportToSelectMenu_Handler);

	new incapped=0, dead=0, alive=0;

	for (new x=1; x<=MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (GetClientTeam(x)!=2) continue;
		if (x==Client) continue;
		if (!IsPlayerAlive(x)) continue;//过滤死亡的玩家
		if (!IsPlayerIncapped(x)) continue;//过滤没有倒地的玩家
		incapped++;
	}
	for (new c=1; c<=MaxClients; c++)
	{
		if (!IsClientInGame(c)) continue;
		if (GetClientTeam(c)!=2) continue;
		if (c==Client) continue;
		if (IsPlayerAlive(c)) continue;//过滤活著的玩家
		dead++;
	}
	for (new v=1; v<=MaxClients; v++)
	{
		if (!IsClientInGame(v)) continue;
		if (GetClientTeam(v)!=2) continue;
		if (v==Client) continue;
		if (!IsPlayerAlive(v)) continue;//过滤死亡的玩家
		if (IsPlayerIncapped(v)) continue;//过滤倒地的玩家
		alive++;
	}

	SetMenuTitle(menu, "选择传送至");

	decl String:Incapped[64], String:Dead[64], String:Alive[64];

	if (incapped==0)
		Format(Incapped, sizeof(Incapped), "没有倒下的队友");
	else
		Format(Incapped, sizeof(Incapped), "倒下的队友(%d个)", incapped);
	if (dead==0)
		Format(Dead, sizeof(Dead), "没有死亡的队友");
	else
		Format(Dead, sizeof(Dead), "死亡的队友(%d个)", dead);
	if (alive==0)
		Format(Alive, sizeof(Alive), "没有活著的队友");
	else
		Format(Alive, sizeof(Alive), "活著的队友(%d个)", alive);

	AddMenuItem(menu, "option1", "刷新列表");
	AddMenuItem(menu, "option2", Incapped);
	AddMenuItem(menu, "option3", Dead);
	AddMenuItem(menu, "option4", Alive);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, 20);

	return Plugin_Handled;
}

public Action:TCCharging(Handle:timer, any:Client)
{
	KillTimer(timer);
	TCChargingTimer[Client] = INVALID_HANDLE;
	IsTeleportToSelectEnable[Client] = false;

	if (IsValidPlayer(Client) && !IsFakeClient(Client))
	{
		CPrintToChat(Client, MSG_SKILL_TC_CHARGED);
	}

	return Plugin_Handled;
}

new t_id[MAXPLAYERS+1];
public TeleportToSelectMenu_Handler(Handle:menu, MenuAction:action, Client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: TeleportToSelectMenu(Client);
			case 1: t_id[Client]=1, TeleportToSelect(Client);
			case 2: t_id[Client]=2, TeleportToSelect(Client);
			case 3: t_id[Client]=3, TeleportToSelect(Client);
		}
	} else if (action == MenuAction_End)	CloseHandle(menu);
}

public Action:TeleportToSelect(Client)
{
	new Handle:menu = CreateMenu(TeleportToSelect_Handler);
	if (t_id[Client]==1) SetMenuTitle(menu, "倒下的队友");
	if (t_id[Client]==2) SetMenuTitle(menu, "死亡的队友");
	if (t_id[Client]==3) SetMenuTitle(menu, "活著的队友");

	decl String:user_id[12];
	decl String:display[MAX_NAME_LENGTH+12];

	for (new x=1; x<=MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (GetClientTeam(x)!=2) continue;
		if (x==Client) continue;
		if (t_id[Client]==1)
		{
			if (!IsPlayerAlive(x)) continue;//过滤死亡的玩家
			if (!IsPlayerIncapped(x)) continue;//过滤没有倒地的玩家
			Format(display, sizeof(display), "%N", x);
		}
		if (t_id[Client]==2)
		{
			if (IsPlayerAlive(x)) continue;//过滤活著的玩家
			Format(display, sizeof(display), "%N", x);
		}
		if (t_id[Client]==3)
		{
			if (!IsPlayerAlive(x)) continue;//过滤死亡的玩家
			if (IsPlayerIncapped(x)) continue;//过滤倒地的玩家
			Format(display, sizeof(display), "%N", x);
		}

		IntToString(x, user_id, sizeof(user_id));
		AddMenuItem(menu, user_id, display);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public TeleportVFX(Float:Position0, Float:Position1, Float:Position2)
{
	decl Float:Position[3];
	new Float:TEradius=120.0, Float:TEinterval=0.01, Float:TEduration=1.0, Float:TEwidth=5.0, TEMax=30;
	
	Position[0]=Position0;
	Position[1]=Position1;
	
	for(new w=TEMax; w>0; w--)
	{
		Position[2]=Position2+w*TEwidth;
		TE_SetupBeamRingPoint(Position, TEradius, TEradius+0.1, g_BeamSprite, g_HaloSprite, 0, 15,  TEduration, TEwidth, 0.0, CyanColor, 10, 0);
		TE_SendToAll(TEinterval*(TEMax-w));
	}
}

public TeleportToSelect_Handler(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{
		new String:info[56];
		GetMenuItem(menu, param, info, sizeof(info));
		/* 获得所选择的玩家 */
		new target = StringToInt(info);
		if(target == -1 || !IsClientInGame(target))
		{
			CPrintToChat(Client, "{green}[UnitedRPG] %t", "Player no longer available");
			return;
		}

		decl Float:TeleportOrigin[3],Float:PlayerOrigin[3];
		GetClientAbsOrigin(target, PlayerOrigin);
		TeleportOrigin[0] = PlayerOrigin[0];
		TeleportOrigin[1] = PlayerOrigin[1];
		TeleportOrigin[2] = (PlayerOrigin[2]+0.1);//防止卡人

		//防止重复使用技能使黑屏效果消失
		if(FadeBlackTimer[Client] != INVALID_HANDLE)
		{
			KillTimer(FadeBlackTimer[Client]);
			FadeBlackTimer[Client] = INVALID_HANDLE;
		}

		PerformFade(Client, 200);
		FadeBlackTimer[Client] = CreateTimer(10.0, PerformFadeNormal, Client);
		TCChargingTimer[Client] = CreateTimer(230.0 - (TeleportToSelectLv[Client]+AppointTeleportLv[Client])*5, TCCharging, Client);

		TeleportEntity(Client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(TSOUND, Client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, TeleportOrigin, NULL_VECTOR, true, 0.0);
		
		TeleportVFX(TeleportOrigin[0], TeleportOrigin[1], TeleportOrigin[2]);

		IsTeleportToSelectEnable[Client] = true;

		MP[Client] -= GetConVarInt(Cost_TeleportToSelect);

		if (t_id[Client]==2)
		{
			CPrintToChat(Client, MSG_SKILL_TC_ANNOUNCE2, target);
			//PrintToserver("[United RPG] %s使用心灵传输到了队友%s的尸体旁!", NameInfo(Client, simple), NameInfo(target, simple));
		} else
		{
			CPrintToChat(Client, MSG_SKILL_TC_ANNOUNCE, target);
			//PrintToserver("[United RPG] %s使用心灵传输到了队友%s的身边!", NameInfo(Client, simple), NameInfo(target, simple));
		}
	} else if (action == MenuAction_End)	CloseHandle(menu);
}

/* 使用_审判光球术 */
public Action:UseAppointTeleport(Client, args)
{
	if(GetClientTeam(Client) == 2) LightBall(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);

	return Plugin_Handled;
}

/* 审判光球术 */
public Action:LightBall(Client)
{

	if(JD[Client] != 4)
	{
		CPrintToChat(Client, MSG_NEED_JOB4);
		return Plugin_Handled;
	}

	if(AppointTeleportLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_8);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsAppointTeleportEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_AppointTeleport) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_AppointTeleport), MP[Client]);
		return Plugin_Handled;
	}

	if (!IsValidPlayer(Client))
		return Plugin_Handled;
	
	new Float:TracePos[3];
	new Float:EyePos[3];
	new Float:Angle[3];
	new Float:TempPos[3];
	new Float:velocity[3];
	new Handle:data;
	new entity = CreateEntityByName("tank_rock");
	GetTracePosition(Client, TracePos); //得到目标位置
	GetClientEyePosition(Client, EyePos);
	MakeVectorFromPoints(EyePos, TracePos, Angle);
	NormalizeVector(Angle, Angle);
	
	TempPos[0] = Angle[0] * 50;
	TempPos[1] = Angle[1] * 50;
	TempPos[2] = Angle[2] * 50;
	AddVectors(EyePos, TempPos, EyePos);
	
	velocity[0] = Angle[0] * 500;
	velocity[1] = Angle[1] * 500;
	velocity[2] = Angle[2] * 500;
	
	if (IsValidEntity(entity) && IsValidEdict(entity))
	{
		IsAppointTeleportEnable[Client] = true;
		//初始发射音效
		EmitAmbientSound(HealingBall_Sound_Lanuch, EyePos);
		//实体属性设置
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", Client);
		DispatchSpawn(entity);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
		SetEntityGravity(entity, 0.1);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Data, "m_MoveCollide", 0);
		TE_SetupBeamFollow(entity, g_BeamSprite, g_HaloSprite, 5.0, 5.0, 2.0, 1, CyanColor); //光束
		TE_SendToAll();
		TeleportEntity(entity, EyePos, Angle, velocity);
		//计时器创建
		CreateTimer(5.0, Timer_LightBallCooling, Client);
		CreateTimer(10.0, Timer_RemoveLightBall, entity);
		CreateDataTimer(0.1, Timer_LightBall, data, TIMER_REPEAT);
		WritePackCell(data, entity);
		WritePackFloat(data, Angle[0]);
		WritePackFloat(data, Angle[1]);
		WritePackFloat(data, Angle[2]);
		WritePackFloat(data, velocity[0]);
		WritePackFloat(data, velocity[1]);
		WritePackFloat(data, velocity[2]);
	}	
	

	CPrintToChatAll(MSG_SKILL_LB_ANNOUNCE, Client, AppointTeleportLv[Client]);
	MP[Client] -= GetConVarInt(Cost_AppointTeleport);
	return Plugin_Handled;
}

/* 光球跟踪实体计时器 */
public Action:Timer_LightBall(Handle:timer, Handle:data)
{
	new Float:pos[3];
	new Float:Angle[3];
	new Float:velocity[3];	
	ResetPack(data);
	new entity = ReadPackCell(data);
	Angle[0] = ReadPackFloat(data);
	Angle[1] = ReadPackFloat(data);
	Angle[2] = ReadPackFloat(data);
	velocity[0] = ReadPackFloat(data);
	velocity[1] = ReadPackFloat(data);
	velocity[2] = ReadPackFloat(data);
	
	if (!IsValidEntity(entity) || !IsValidEdict(entity)) 
		return Plugin_Stop;	
	
	for (new i = 1; i <= 5; i++)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		TeleportEntity(entity, pos, Angle, velocity);
		TE_SetupGlowSprite(pos, g_GlowSprite, 0.1, 4.0, 500); 
		TE_SendToAll();
	}
	
	if (DistanceToHit(entity) <= 200)
	{
		CreateTimer(0.1, Timer_RemoveLightBall, entity);
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}

/* 删除生物专家光球计时器 */
public Action:Timer_RemoveLightBall(Handle:timer, any:entity)
{
	new Player;
	new Float:pos[3];
	new Float:entpos[3];
	new Float:distance;
	new MaxEnt = GetMaxEntities();
	LightBallReward[Player] = 0;
	
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
		Player = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
	if (IsValidPlayer(Player) && IsValidEntity(entity) && IsValidEdict(entity)) 
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		EmitAmbientSound(HealingBall_Sound_Heal, pos);
		//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
		TE_SetupBeamRingPoint(pos, 0.1, 100.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 10.0, 0.0, WhiteColor, 10, 0);
		TE_SendToAll();
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsValidPlayer(i) || !IsValidEntity(i) || !IsValidEdict(i)) 
				continue;
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);	
			distance = GetVectorDistance(pos, entpos);
			if (distance <= 200)
			{
				if (GetClientTeam(i) == GetClientTeam(Player))
				{
					DealCure(Player, i, LightBallHealth[Player]);				
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.6, 3.0, 3.0, 1, 0.5, WhiteColor, 0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(entpos, 49.9, 50.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.6, 20.0, 0.0, WhiteColor, 10, 0);
					TE_SendToAll();
				}
				else
				{
					DealDamage(Player, i, LightBallDamage[Player], 0);
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.6, 3.0, 3.0, 1, 0.5, RedColor, 0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(entpos, 49.9, 50.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.6, 20.0, 0.0, RedColor, 10, 0);
					TE_SendToAll();
				}
			}
		}
		
		for (new iEnt = MaxClients + 1; iEnt <= MaxEnt; iEnt++)
		{				
			if(IsValidEntity(iEnt) && IsValidEdict(iEnt) && IsCommonInfected(iEnt) && GetEntProp(iEnt, Prop_Data, "m_iHealth") > 0)
			{
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", entpos);	
				distance = GetVectorDistance(pos, entpos);
				if (distance <= 200)
				{
					DealDamage(Player, iEnt, LightBallDamage[Player], 0);
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.6, 3.0, 3.0, 1, 0.5, RedColor, 0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(entpos, 49.9, 50.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.6, 20.0, 0.0, RedColor, 10, 0);
					TE_SendToAll();
				}
			}
		
		}
		
		//治愈经验
		DealCureOver(Player);		
		//删除实体
		RemoveEdict(entity);
	}
}

/* 治愈效果 */
public DealCure(Client, Target, Cure_Health)
{
	if (!IsValidPlayer(Client) || !IsValidEntity(Client) || !IsPlayerAlive(Client) || !IsValidPlayer(Target) || !IsValidEntity(Target) || !IsPlayerAlive(Target))
		return;
		
	new health = GetClientHealth(Target);
	new maxhealth = GetEntProp(Target, Prop_Data, "m_iMaxHealth");

	if (!IsPlayerIncapped(Target))
	{
		if (health + Cure_Health > maxhealth)
		{
			LightBallReward[Client] += maxhealth - health;
			health = maxhealth;
		}
		else
		{
			LightBallReward[Client] += Cure_Health;
			health = health + Cure_Health;
		}
			
		SetEntProp(Target, Prop_Data, "m_iHealth", health);
	}
	else if (IsPlayerIncapped(Target))
	{
		if (health + Cure_Health > 300)
		{
			LightBallReward[Client] += 300 - health;
			health = 300;
		}
		else
		{
			LightBallReward[Client] += Cure_Health;
			health = health + Cure_Health;
		}
			
		SetEntProp(Target, Prop_Data, "m_iHealth", health);
	}	
}

/* 治愈效果_结束 */
public DealCureOver(Client)
{
	if (!IsValidPlayer(Client) || !IsValidEntity(Client) || !IsPlayerAlive(Client))
	{
		LightBallReward[Client] = 0;
		return;
	}

	if (LightBallReward[Client] > 0)
	{
		new giveexp = RoundToNearest(LightBallReward[Client] * LightBallExp);
		new givecash = RoundToNearest(LightBallReward[Client] * LightBallCash);
		EXP[Client] += giveexp + VIPAdd(Client, giveexp, 1, true);
		Cash[Client] += givecash + VIPAdd(Client, givecash, 1, false);
		CPrintToChat(Client, MSG_SKILL_LB_END, LightBallReward[Client], giveexp, givecash);
		LightBallReward[Client] = 0;
	}
}

/* 审判光球术冷却 */
public Action:Timer_LightBallCooling(Handle:timer, any:Client)
{
	IsAppointTeleportEnable[Client] = false;
}

/* 单人传送 */
public Action:UseTeleportTeam(Client, args)
{
	if(GetClientTeam(Client) == 2) TeleportTeam(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);

	return Plugin_Handled;
}

public Action:TeleportTeam(Client)
{
	if(JD[Client] != 4)
	{
		CPrintToChat(Client, MSG_NEED_JOB4);
		return Plugin_Handled;
	}

	if(TeleportTeamLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_9);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsTeleportTeamEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	if (GetConVarInt(Cost_TeleportTeammate) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_TeleportTeammate), MP[Client]);
		return Plugin_Handled;
	}

	if (!IsPlayerOnGround(Client))
	{
		CPrintToChat(Client, MSG_SKILL_TT_ON_GROUND);
		return Plugin_Handled;
	}
	new P;
	
	for(new X=1; X<=MaxClients; X++)
	{
		if (!IsValidEntity(X)) continue;
		if (!IsClientInGame(X)) continue;
		if (GetClientTeam(X)!=2) continue;
		if (!IsPlayerAlive(X)) continue;
		P = X;
	}

	if(P == -1)
	{
		CPrintToChat(Client, "{olive}找不到传送目标!");
		return Plugin_Handled;
	}

	new Handle:menu = CreateMenu(TeleportTeammate_Handler);
	SetMenuTitle(menu, "选择队友");

	decl String:user_id[12];
	decl String:display[MAX_NAME_LENGTH+12];

	for (new x=1; x<=MaxClients; x++)
	{
		if (!IsClientInGame(x)) continue;
		if (GetClientTeam(x)!=2) continue;
		if (x==Client) continue;
		if (!IsPlayerAlive(x)) continue;
		Format(display, sizeof(display), "%N", x);
		IntToString(x, user_id, sizeof(user_id));
		AddMenuItem(menu, user_id, display);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public TeleportTeammate_Handler(Handle:menu, MenuAction:action, Client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new target = StringToInt(info);
		if(target == -1 || !IsClientInGame(target))
		{
			CPrintToChat(Client, "{green}[UnitedRPG] %t", "Player no longer available");
			return;
		}

		decl Float:position[3];
		GetClientAbsOrigin(Client, position);

		//防止重复使用技能使黑屏效果消失
		if(FadeBlackTimer[target] != INVALID_HANDLE)
		{
			KillTimer(FadeBlackTimer[target]);
			FadeBlackTimer[target] = INVALID_HANDLE;
		}
		if(FadeBlackTimer[Client] != INVALID_HANDLE)
		{
			KillTimer(FadeBlackTimer[Client]);
			FadeBlackTimer[Client] = INVALID_HANDLE;
		}

		PerformFade(target, 200);
		PerformFade(Client, 200);
		FadeBlackTimer[target] = CreateTimer(10.0, PerformFadeNormal, target);
		FadeBlackTimer[Client] = CreateTimer(10.0, PerformFadeNormal, Client);

		TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(TSOUND, target, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, position, NULL_VECTOR, true, 0.0);
		
		TeleportVFX(position[0], position[1], position[2]);
		
		TTChargingTimer[Client] = CreateTimer(160.0 - TeleportTeamLv[Client]*5, TTCharging, Client);

		IsTeleportTeamEnable[Client] = true;

		MP[Client] -= GetConVarInt(Cost_TeleportTeammate);

		CPrintToChatAll(MSG_SKILL_TT_ANNOUNCE_2, Client, target);

		//PrintToserver("[United RPG] %s使用心灵传输使队友%s回到他身边!", NameInfo(Client, simple), NameInfo(target, simple));
	} else if (action == MenuAction_End)	CloseHandle(menu);
}

public Action:TTCharging(Handle:timer, any:Client)
{
	KillTimer(timer);
	TTChargingTimer[Client] = INVALID_HANDLE;
	IsTeleportTeamEnable[Client] = false;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_TT_CHARGED);
	}
	return Plugin_Handled;
}

public Action:PerformFadeNormal(Handle:timer, any:Client)
{
	KillTimer(timer);
	FadeBlackTimer[Client] = INVALID_HANDLE;
	IsAppointTeleportEnable[Client] = false;
	if(IsClientInGame(Client))	PerformFade(Client, 0);
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayers(entity, contentsMask, any:data)
{
	return entity > MaxClients && entity != data;
}

/* 全体召唤术 */
public Action:UseTeleportTeamzt(Client, args)
{
	if(GetClientTeam(Client) == 2) TeleportTeam(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);

	return Plugin_Handled;
}


public Action:TeleportTeamzt(Client)
{
	if(JD[Client] != 4)
	{
		CPrintToChat(Client, MSG_NEED_JOB4);
		return Plugin_Handled;
	}

	if(TeleportTeamztLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_24);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsTeleportTeamztEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	
	if (MP[Client] != MaxMP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MaxMP[Client], MP[Client]);
		return Plugin_Handled;
	}

	if (!IsPlayerOnGround(Client))
	{
		CPrintToChat(Client, MSG_SKILL_TT_ON_GROUND);
		return Plugin_Handled;
	}
	new P;
	
	for(new X=1; X<=MaxClients; X++)
	{
		if (!IsValidEntity(X)) continue;
		if (!IsClientInGame(X)) continue;
		P = X;
	}

	if(P == -1)
	{
		CPrintToChat(Client, "{olive}找不到传送目标!");
		return Plugin_Handled;
	}

	decl Float:position[3];
	for(new Player=1; Player<=P; Player++)
	{
		if (!IsClientInGame(Player)) continue;
		if (GetClientTeam(Player)!=2) continue;
		if (!IsPlayerAlive(Player)) continue;

		GetClientAbsOrigin(Client, position);

		TeleportEntity(Player, position, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAll(TSOUND, Player, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, position, NULL_VECTOR, true, 0.0);
	}
	
	TeleportVFX(position[0], position[1], position[2]);

	TTChargingztTimer[Client] = CreateTimer(280.0 - TeleportTeamztLv[Client]*5, TTChargingzt, Client);

	IsTeleportTeamztEnable[Client] = true;

	MP[Client] = 0;

	CPrintToChat(Client, MSG_SKILL_TT_ANNOUNCE, Client);

	//PrintToserver("[United RPG] %s使用全体召唤术使所有队友回到他身边!", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:TTChargingzt(Handle:timer, any:Client)
{
	KillTimer(timer);
	TTChargingztTimer[Client] = INVALID_HANDLE;
	IsTeleportTeamztEnable[Client] = false;

	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, MSG_SKILL_TT_CHARGEDZT);
	}
	return Plugin_Handled;
}

/* 黑屏效果 */
public PerformFade(Client, amount)
{
	new Handle:message = StartMessageOne("Fade",Client);
	BfWriteShort(message, 0);
	BfWriteShort(message, 0);
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	EndMessage();
}

/* 治疗光球术 */
public Action:UseHealingBall(Client, args)
{
	if(GetClientTeam(Client) == 2) HealingBallFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:HealingBallFunction(Client)
{
	if(JD[Client] != 4)
	{
		CPrintToChat(Client, MSG_NEED_JOB4);
		return Plugin_Handled;
	}

	if(HealingBallLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_18);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(IsHealingBallEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_HB_ENABLED);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_HealingBall) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_HealingBall), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_HealingBall);

	new Float:Radius=float(HealingBallRadius[Client]);
	new Float:pos[3];
	GetTracePosition(Client, pos); //得到目标位置
	pos[2] += 50.0;
	EmitAmbientSound(HealingBall_Sound_Lanuch, pos);
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 3.0, 0.0, RedColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 0.1, 0.0, GreenColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();
	
	for(new i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 2.5, 1000);
		TE_SendToAll();
	}

	IsHealingBallEnable[Client] = true;

	new Handle:pack;
	HealingBallTimer[Client] = CreateDataTimer(HealingBallInterval[Client], HealingBallTimerFunction, pack, TIMER_REPEAT);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	WritePackFloat(pack, GetEngineTime());
	
	CPrintToChatAll("\x05[{teamcolor}EX技能\x05]\x01:玩家\x04 %N \x01启动了\x04LV.%d{teamcolor}的治疗光圈 ", Client, HealingBallLv[Client]);
	
	//PrintToserver("[United RPG] %s启动了治疗光球术!走进圈中可回血!", NameInfo(Client, simple));

	return Plugin_Handled;
}


public Action:HealingBallTimerFunction(Handle:timer, Handle:pack)
{
	decl Float:pos[3], Float:entpos[3], Float:distance[3];
	
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	new Float:time=ReadPackFloat(pack);
	
	EmitAmbientSound(HealingBall_Sound_Heal, pos);
	
	for(new i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 2.5, 1000);
		TE_SendToAll();
	}
	
	//new iMaxEntities = GetMaxEntities();
	new Float:Radius=float(HealingBallRadius[Client]);
	
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 3.0, 0.0, RedColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 1.0, 0.1, 0.0, GreenColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();

	if(GetEngineTime() - time < HealingBallDuration[Client])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						new HP = GetClientHealth(i);
						new healing = RoundToNearest(0.0 + HealingBallEffect[Client]);
						if (healing < 5 || healing > 10)
							healing = 5;
							
						if (IsPlayerIncapped(i))
						{
							SetEntProp(i, Prop_Data, "m_iHealth", HP + healing);
							HealingBallExp[Client] += GetConVarInt(LvUpExpRate) * healing / 500;
						} else
						{
							new MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
							if(MaxHP > HP + healing)
							{
								SetEntProp(i, Prop_Data, "m_iHealth", HP + healing);
								HealingBallExp[Client] += GetConVarInt(LvUpExpRate) * healing / 500;
							}
							else if(MaxHP < HP + healing)
							{
								SetEntProp(i, Prop_Data, "m_iHealth", MaxHP);
								HealingBallExp[Client] += GetConVarInt(LvUpExpRate)*(MaxHP - HP)/500;
							}
						}
						//new Float:Radius1=float(50);
						//new Float:SkyLocation[3];
						//SkyLocation[0] = entpos[0];
						//SkyLocation[1] = entpos[1];
						//SkyLocation[2] = entpos[2] + 7.0;
						ShowParticle(entpos, HealingBall_Particle_Effect, 0.5);
						//TE_SetupBeamRingPoint(SkyLocation, Radius1-0.1, Radius1, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 0.4, 0.0, GreenColor, 5, 0);//固定外圈BuleColor
						//TE_SendToAll();
						//TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 0.5, CyanColor, 0);
						//TE_SendToAll();
					}
				}
			}
		}
	} else
	{
		if (IsValidPlayer(Client) && !IsFakeClient(Client))
		{
			if(HealingBallExp[Client] > 0)
			{
				EXP[Client] += HealingBallExp[Client] / 5 + VIPAdd(Client, HealingBallExp[Client] / 5, 1, true);
				Cash[Client] += HealingBallExp[Client] / 10 + VIPAdd(Client, HealingBallExp[Client] / 15, 1, false);
				CPrintToChat(Client, MSG_SKILL_HB_END, HealingBallExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallExp[Client] / 2, HealingBallExp[Client] / 5);
				//PrintToserver("[United RPG] %s的治疗光球术结束了! 总共治疗了队友%dHP, 获得%dExp, %d$", NameInfo(Client, simple), HealingBallExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallExp[Client], HealingBallExp[Client]);
			}
		}
		HealingBallExp[Client] = 0;
		IsHealingBallEnable[Client] = false;
		KillTimer(timer);
		HealingBallTimer[Client] = INVALID_HANDLE;
	}
}

/* 暗夜生物专家术关联 */
public Action:UseHealingBallmiss(Client, args)
{
	if(GetClientTeam(Client) == 2) HealingBallmissFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
}

public Action:HealingBallmissFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}

	if(HealingBallmissLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}

	if(IsHealingBallmissEnable[Client])
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}
	
	new Float:Radius=float(HealingBallmissRadius[Client]);
	new Float:pos[3];
	GetTracePosition(Client, pos); //得到目标位置
	pos[2] += 50.0;
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 0.1, 5.0, 5.0, CyanColor, 10, 0);//固定外圈BuleColor
	TE_SendToAll();
	
	for(new i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 0.1, 2.5, 1000);
		TE_SendToAll();
	}

	IsHealingBallmissEnable[Client] = true;

	new Handle:pack;
	HealingBallmissTimer[Client] = CreateDataTimer(HealingBallmissInterval, HealingBallmissTimerFunction, pack, TIMER_REPEAT);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	WritePackFloat(pack, GetEngineTime());

	CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE, HealingBallLv[Client]);

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}

public Action:HealingBallmissTimerFunction(Handle:timer, Handle:pack)
{
	decl Float:pos[3], Float:entpos[3], Float:distance[3];
	
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	new Float:time=ReadPackFloat(pack);
	
	for(new i = 1; i<5; i++)
	{
		TE_SetupGlowSprite(pos, g_GlowSprite, 0.1, 2.5, 1000);
		TE_SendToAll();
	}
	
	//new iMaxEntities = GetMaxEntities();
	new Float:Radius=float(HealingBallmissRadius[Client]);
	
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 0.1, 10.0, 5.0, CyanColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();

	if(GetEngineTime() - time < HealingBallmissDuration[Client])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						new HP = GetClientHealth(i);
						if (!IsPlayerIncapped(i))
						{
							new MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
							if(MaxHP > HP+HealingBallmissEffect[i])
							{
								SetEntProp(i, Prop_Data, "m_iHealth", HP+HealingBallmissEffect[Client]);
								HealingBallmissExp[Client] += GetConVarInt(LvUpExpRate)*HealingBallmissEffect[Client]/500;
							}
							else if(MaxHP < HP+HealingBallmissEffect[Client])
							{
								SetEntProp(i, Prop_Data, "m_iHealth", MaxHP);
								HealingBallmissExp[Client] += GetConVarInt(LvUpExpRate)*(MaxHP - HP)/500;
							}
						}
					}
				}
			}
		}
	} else
	{
		if (IsValidPlayer(Client) && !IsFakeClient(Client))
		{
			if(HealingBallmissExp[Client] > 0)
			{
				EXP[Client] += HealingBallmissExp[Client] / 4 + VIPAdd(Client, HealingBallmissExp[Client] / 4, 1, true);
				Cash[Client] += HealingBallmissExp[Client] / 10 + VIPAdd(Client, HealingBallmissExp[Client] / 10, 1, false);
				CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE, HealingBallmissExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallmissExp[Client], HealingBallmissExp[Client]/10);
				//PrintToserver("", NameInfo(Client, simple), HealingBallmissExp[Client]*500/GetConVarInt(LvUpExpRate), HealingBallmissExp[Client], HealingBallmissExp[Client]/10);
			}
		}
		HealingBallmissExp[Client] = 0;
		IsHealingBallmissEnable[Client] = false;
		KillTimer(HealingBallmissTimer[Client]);
		HealingBallmissTimer[Client] = INVALID_HANDLE;
	}
}

/* 火球术 */
public Action:UseFireBall(Client, args)
{
	if(GetClientTeam(Client) == 2) FireBallFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:FireBallFunction(Client)
{
	if(JD[Client] != 5)
	{
		CPrintToChat(Client, MSG_NEED_JOB5);
		return Plugin_Handled;
	}

	if(FireBallLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_15);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if (FireBallCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	
	if(GetConVarInt(Cost_FireBall) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_FireBall), MP[Client]);
		return Plugin_Handled;
	}
	
	
	MP[Client] -= GetConVarInt(Cost_FireBall);
	FireBallCD[Client] = true;
	new ent=CreateEntityByName("tank_rock");
	//SetEntityModel(ent, FireBall_Model);
	//DispatchKeyValue(ent, "model", "/models/props_unique/airport/atlas_break_ball.mdl"); 
	DispatchSpawn(ent); 
	decl Float:TracePos[3];
	GetTracePosition(Client, TracePos); //得到目标位置
	decl Float:FireBallPos[3];
	GetClientEyePosition(Client, FireBallPos);
	//FireBallPos[2] += 25.0;
	decl Float:angle[3];
	MakeVectorFromPoints(FireBallPos, TracePos, angle);
	NormalizeVector(angle, angle);
	
	decl Float:FireBallTempPos[3];
	FireBallTempPos[0] = angle[0]*50.0;
	FireBallTempPos[1] = angle[1]*50.0;
	FireBallTempPos[2] = angle[2]*50.0;
	AddVectors(FireBallPos, FireBallTempPos, FireBallPos);
	
	decl Float:velocity[3];
	velocity[0] = angle[0]*2000.0;
	velocity[1] = angle[1]*2000.0;
	velocity[2] = angle[2]*2000.0;
	
	DispatchKeyValue(ent, "rendercolor", "255 80 80");
	
	TeleportEntity(ent, FireBallPos, angle, velocity);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Ignite");
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	SetEntityGravity(ent, 0.1);
	
	new Handle:h;
	CreateDataTimer(0.1, UpdateFireBall, h, TIMER_REPEAT);
	WritePackCell(h, Client);
	WritePackCell(h, ent);
	WritePackFloat(h,GetEngineTime());

	CPrintToChatAll(MSG_SKILL_FB_ANNOUNCE, Client, FireBallLv[Client]);
	CreateTimer(2.0, Timer_FireBallCD, Client);

	//PrintToserver("[United RPG] %s启动了火球术!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:UpdateFireBall(Handle:timer, Handle:h)
{
	ResetPack(h);
	new Client=ReadPackCell(h);
	new ent=ReadPackCell(h);
	new Float:time=ReadPackFloat(h);
	
	if(IsRock(ent))
	{
		decl Float:vec[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vec);
		new Float:v=GetVectorLength(vec);
		AttachParticle(ent, FireBall_Particle_Fire03, 0.1);
		//PrintToChatAll("TimeEscapped = %.2f, DistanceToHit = %.2f, v= %.2f", GetEngineTime() - time, DistanceToHit(ent), v);
		if(GetEngineTime() - time > FireIceBallLife || DistanceToHit(ent)<200.0 || v<200.0)
		{
			new Float:distance[3];
			new iMaxEntities = GetMaxEntities();
			decl Float:pos[3], Float:entpos[3];
			new Float:Radius=float(FireBallRadius[Client]);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

			RemoveEdict(ent);
			
			LittleFlower(pos, EXPLODE, Client);
			
			/* Emit impact sound */
			EmitAmbientSound(FireBall_Sound_Impact01, pos);
			EmitAmbientSound(FireBall_Sound_Impact02, pos);
			
			ShowParticle(pos, FireBall_Particle_Fire01, 5.0);
			ShowParticle(pos, FireBall_Particle_Fire02, 5.0);

            
			new Float:SkyLocation[3];
            
			SkyLocation[0] = pos[0];
            
			SkyLocation[1] = pos[1];
            
            
			SkyLocation[2] = pos[2] + 500.0;//闪电柱高度

            //(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
            
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 10.0, 0.0, RedColor, 10, 0);//固定外圈BuleColor
                
            TE_SendToAll();	
            
            TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 3.0, 20.0, 20.0, 10, 10.0, RedColor, 0); //闪电柱
                
            TE_SendToAll();
            
            TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 10.0, 0.0, YellowColor, 10, 0);//扩散内圈cyanColor
            
            TE_SendToAll();
            
            TE_SetupGlowSprite(pos, g_GlowSprite, IceBallDuration[Client], 5.0, 100);
            
            TE_SendToAll();
            
			for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
			{
				if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, FireBallDamage[Client], 8 , "fire_ball");
					}
				}
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == GetClientTeam(Client))
						continue;
						
					if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, FireBallDamage[Client], 262144 , "fire_ball", FireBallDamageInterval[Client], FireBallDuration[Client]);
					}
					else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, FireBallTKDamage[Client], 262144 , "fire_ball", FireBallDamageInterval[Client], FireBallDuration[Client]);
					}
				}
			}
			return Plugin_Stop;	
		}
		return Plugin_Continue;	
	} else return Plugin_Stop;	
}

bool:IsRock(ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[20];
		GetEdictClassname(ent, classname, 20);

		if(StrEqual(classname, "tank_rock", true))
		{
			return true;
		}
	}
	return false;
}

public Action:Timer_FireBallCD(Handle:timer, any:Client)
{
	FireBallCD[Client] = false;
	KillTimer(timer);
}

/* 冰球术 */
public Action:UseIceBall(Client, args)
{
	if(GetClientTeam(Client) == 2) IceBallFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:IceBallFunction(Client)
{
	if(JD[Client] != 5)
	{
		CPrintToChat(Client, MSG_NEED_JOB5);
		return Plugin_Handled;
	}

	if(IceBallLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_16);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}
	if (IceBallCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	if(GetConVarInt(Cost_IceBall) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_IceBall), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_IceBall);
	IceBallCD[Client] = true;	
	new ent=CreateEntityByName("tank_rock");
	DispatchSpawn(ent); 
	decl Float:TracePos[3];
	GetTracePosition(Client, TracePos); //得到目标位置
	decl Float:IceBallPos[3];
	GetClientEyePosition(Client, IceBallPos);
	decl Float:angle[3];
	MakeVectorFromPoints(IceBallPos, TracePos, angle);
	NormalizeVector(angle, angle);
	
	decl Float:IceBallTempPos[3];
	IceBallTempPos[0] = angle[0]*50.0;
	IceBallTempPos[1] = angle[1]*50.0;
	IceBallTempPos[2] = angle[2]*50.0;
	AddVectors(IceBallPos, IceBallTempPos, IceBallPos);
	
	decl Float:velocity[3];
	velocity[0] = angle[0]*2000.0;
	velocity[1] = angle[1]*2000.0;
	velocity[2] = angle[2]*2000.0;
	
	DispatchKeyValue(ent, "rendercolor", "80 80 255");
	
	TeleportEntity(ent, IceBallPos, angle, velocity);
	ActivateEntity(ent);
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	SetEntityGravity(ent, 0.1);
	
	new Handle:h;	
	CreateDataTimer(0.1, UpdateIceBall, h, TIMER_REPEAT);
	WritePackCell(h, Client);
	WritePackCell(h, ent);
	WritePackFloat(h,GetEngineTime());

	CPrintToChatAll(MSG_SKILL_IB_ANNOUNCE, Client, IceBallLv[Client]);
	CreateTimer(5.0, Timer_UseIceBallCD, Client);

	//PrintToserver("[United RPG] %s启动了冰球术!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:Timer_UseIceBallCD(Handle:timer, any:Client)
{
	IceBallCD[Client] = false;
	KillTimer(timer);
}
public Action:UpdateIceBall(Handle:timer, Handle:h)
{
	ResetPack(h);
	new Client=ReadPackCell(h);
	new ent=ReadPackCell(h);
	new Float:time=ReadPackFloat(h);
	
	if(IsRock(ent))
	{
		decl Float:vec[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vec);
		new Float:v=GetVectorLength(vec);
		if(GetEngineTime() - time > FireIceBallLife || DistanceToHit(ent) < 200.0 || v < 200.0)
		{
			new Float:distance[3];
			new iMaxEntities = GetMaxEntities();
			decl Float:pos[3], Float:entpos[3];
			new Float:Radius=float(IceBallRadius[Client]);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

			RemoveEdict(ent);
			
			/* Emit impact sound */
			EmitAmbientSound(IceBall_Sound_Impact01, pos);
			EmitAmbientSound(IceBall_Sound_Impact02, pos);
			
			ShowParticle(pos, HMZS_Particle_Fire01, 5.0);
			ShowParticle(pos, HMZS_Particle_Fire02, 5.0);
	
	        new Float:SkyLocation[3];
			SkyLocation[0] = pos[0];
			SkyLocation[1] = pos[1];
			SkyLocation[2] = pos[2] + 500.0; //闪电柱高度
			//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 10.0, 0.0, BlueColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll(0.9);
            
	        
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 3.0, 20.0, 20.0, 10, 10.0, BlueColor, 0); //闪电柱
	        
			TE_SendToAll();
		    
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 10.0, 0.0, YellowColor, 10, 0);//扩散内圈cyanColor
            
			TE_SendToAll();
			
			TE_SetupGlowSprite(pos, g_GlowSprite, IceBallDuration[Client], 5.0, 100);
			TE_SendToAll();

			ShowParticle(pos, IceBall_Particle_Ice01, 5.0);		
			
			for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
			{
				if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, RoundToNearest(IceBallDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 16 , "ice_ball");
						//FreezePlayer(iEntity, entpos, IceBallDuration[Client]);
						EmitAmbientSound(IceBall_Sound_Freeze, entpos, iEntity, SNDLEVEL_RAIDSIREN);
						TE_SetupGlowSprite(entpos, g_GlowSprite, IceBallDuration[Client], 3.0, 130);
						TE_SendToAll();
					}
				}
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == GetClientTeam(Client))
						continue;			
						
					if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
						{
							DealDamage(Client, i, IceBallDamage[Client], 16 , "ice_ball");
							FreezePlayer(i, entpos, IceBallDuration[Client]);
						}
					} 
					else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
						{
							DealDamage(Client, i, IceBallTKDamage[Client], 16 , "ice_ball");
							FreezePlayer(i, entpos, IceBallDuration[Client]);
						}
					}
				}
			}
			PointPush(Client, pos, 500, IceBallRadius[Client], 0.5);
			return Plugin_Stop;	
		}
		return Plugin_Continue;
	} else return Plugin_Stop;
}
public FreezePlayer(entity, Float:pos[3], Float:time)
{
	if(IsValidPlayer(entity))
	{
		SetEntityMoveType(entity, MOVETYPE_NONE);
		SetEntityRenderColor(entity, 0, 128, 255, 135);
		ScreenFade(entity, 0, 128, 255, 192, 2000, 1);
		EmitAmbientSound(IceBall_Sound_Freeze, pos, entity, SNDLEVEL_RAIDSIREN);
		TE_SetupGlowSprite(pos, g_GlowSprite, time, 3.0, 130);
		TE_SendToAll();
		IsFreeze[entity] = true;
	}
	CreateTimer(time, DefrostPlayer, entity);
}
public Action:DefrostPlayer(Handle:timer, any:entity)
{
	if(IsValidPlayer(entity))
	{
		decl Float:entPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entPos);
		EmitAmbientSound(IceBall_Sound_Defrost, entPos, entity, SNDLEVEL_RAIDSIREN);
		SetEntityMoveType(entity, MOVETYPE_WALK);
		ScreenFade(entity, 0, 0, 0, 0, 0, 1);
		IsFreeze[entity] = false;
		SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
}
/* 取打击距离 */
public Float:DistanceToHit(ent)
{
	if (!(GetEntityFlags(ent) & (FL_ONGROUND)))
	{
		decl Handle:h_Trace, Float:entpos[3], Float:hitpos[3], Float:angle[3];
		
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", angle);
		GetVectorAngles(angle, angle);
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entpos);
		h_Trace = TR_TraceRayFilterEx(entpos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, ent);

		if (TR_DidHit(h_Trace))
		{
			TR_GetEndPosition(hitpos, h_Trace);

			CloseHandle(h_Trace);

			return GetVectorDistance(entpos, hitpos);
		}

		CloseHandle(h_Trace);
	}

	return 0.0;
}


/* 核弹 */
public PrecacheParticlemiss(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticlesmiss, particle);
	} 
}

public CreateParticles(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticlesmiss, particle);
	} 
}

public Action:DeleteParticlesmiss(Handle:timer, any:particle) 
{ 	
	if (IsValidEdict(particle)) 
	{ 		
		new String:classname[64]; 		
		GetEdictClassname(particle, classname, sizeof(classname)); 		 		
		if (StrEqual(classname, "info_particle_system", false)) 
		{
			RemoveEdict(particle); 		
		} 	
	} 
}

public bool:TraceEntityFilterPlayermiss(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
} 

public Action:nuclearcommand(Client)
{
	if (GetConVarInt(Cvar_nuclearEnable))
	{
		if (Client > 0 && IsClientInGame(Client))
		{	
			if (IsPlayerAlive(Client))
			{
				if (nuclearamount[Client] > 0)
				{
					new Float:vAngles[3];
					new Float:vOrigin[3];
					new Float:pos[3];

					GetClientEyePosition(Client,vOrigin);
					GetClientEyeAngles(Client, vAngles);

					new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayermiss);
					
					TE_SetupSparks(pos, NULL_VECTOR, 2, 1);
					TE_SendToAll(0.1);
					TE_SetupSparks(pos, NULL_VECTOR, 2, 2);
					TE_SendToAll(0.4);
					TE_SetupSparks(pos, NULL_VECTOR, 1, 1);
					TE_SendToAll(1.0);
					
					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(pos, trace);
						pos[2] += 15.0;
					}
					
					CloseHandle(trace);
					
					new nuclear = CreateEntityByName("prop_dynamic");
					
					if (IsValidEdict(nuclear))
					{
                        SetEntityModel(nuclear, "models/missiles/f18_agm65maverick.mdl");
                        DispatchKeyValueVector(nuclear, "origin", pos);
                        DispatchKeyValue(nuclear, "angles", "0 135 11");
                        DispatchKeyValue(nuclear, "spawnflags", "0");
                        DispatchKeyValue(nuclear, "rendercolor", "255 255 255");
                        DispatchKeyValue(nuclear, "renderamt", "255");
                        DispatchKeyValue(nuclear, "solid", "6");
                        DispatchKeyValue(nuclear, "MinAnimTime", "5");
                        DispatchKeyValue(nuclear, "MaxAnimTime", "10");
                        DispatchKeyValue(nuclear, "fademindist", "1500");
                        DispatchKeyValue(nuclear, "fadescale", "1");
                        DispatchKeyValue(nuclear, "model", "models/missiles/f18_agm65maverick.mdl");
                        SetEntData(nuclear, GetEntSendPropOffs(nuclear, "m_CollisionGroup"), 1, 1, true);
                        DispatchKeyValue(nuclear, "parentname", "helis");
                        DispatchKeyValue(nuclear, "fademaxdist", "3600");
                        DispatchKeyValue(nuclear, "classname", "prop_dynamic");
                        DispatchSpawn(nuclear);
                        TeleportEntity(nuclear, pos, NULL_VECTOR, NULL_VECTOR);
	
                        SetEntProp(nuclear, Prop_Send, "m_iGlowType", 3 );
                        SetEntProp(nuclear, Prop_Send, "m_nGlowRange", 0 );
                        SetEntProp(nuclear, Prop_Send, "m_glowColorOverride", 700000);

                        CreateTimer( 10.0, removenuclear, nuclear );
                     
                        DurationSound(Client, GetConVarInt(CvarDurationTime));
                        
                        pos[1] += 50;
                        pos[0] -= 50;
                        pos[2] -= 5;
                        
                        TE_SetupBeamRingPoint(pos, 10.0, 300.0, fire, halo, 0, 20, 2.0, 8.0, 0.0, hedancolor, 10, 0);
                        TE_SendToAll();
		
                        TE_SetupBeamRingPoint(pos, 10.0, 260.0, fire, halo, 0, 20, 4.0, 10.0, 0.0, hedancolor, 10, 0);
                        TE_SendToAll();
		
                        TE_SetupBeamRingPoint(pos, 10.0, 220.0, fire, halo, 0, 20, 6.0, 8.0, 0.0, hedancolor, 10, 0);
                        TE_SendToAll();
		
                        TE_SetupBeamRingPoint(pos, 10.0, 180.0, fire, halo, 0, 20, 8.0, 10.0, 0.0, hedancolor, 10, 0);
                        TE_SendToAll();

                        TE_SetupBeamRingPoint(pos, 10.0, 130.0, fire, halo, 0, 20, 10.0, 8.0, 0.0, hedancolor, 10, 0);
                        TE_SendToAll();
						
                        CreateParticles(pos,"electrical_arc_01_system", 5.0 );
                        CreateParticles(pos,"electrical_arc_01_parent", 5.0 ); 
                    }
					
					CPrintToChatAll(MSG_SKILL_MOGU_NOGUN, Client);
					
					new Handle:gasdata = CreateDataPack();
					CreateTimer(11.0, CreateCloud, gasdata);
					WritePackCell(gasdata, Client);
					WritePackFloat(gasdata, pos[0]);
					WritePackFloat(gasdata, pos[1]);
					WritePackFloat(gasdata, pos[2]);
					WritePackCell(gasdata, nuclearamount[Client]);
					nuclearamount[Client]--;
					
					new Handle:bombdata = CreateDataPack();
					CreateTimer(10.0, CreateExplode, bombdata);
					WritePackCell(bombdata, Client);
					WritePackFloat(bombdata, pos[0]);
					WritePackFloat(bombdata, pos[1]);
					WritePackFloat(bombdata, pos[2]);
					WritePackCell(bombdata, nuclearamount[Client]);
				}
				else
				{
					PrintToChat(Client, "该技能一关只能使用%d次", Cvar_nuclearAmount);
					CreateTimer(650.0, Timer_nuclearamountCD, Client);

				}
			}
		}
	}
	else
	{
		PrintToChat(Client, "[SM] 核弹正在准备当中.  请等待....");
	}
	return Plugin_Handled;
}
public Action:Timer_nuclearamountCD(Handle:timer, any:Client)
{
	nuclearamountCD[Client] = false;
	KillTimer(timer);
} 
public Action:Createpush(Handle:timer, Handle:pushdata)
{
	ResetPack(pushdata);
	new Float:location[3];
	location[0] = ReadPackFloat(pushdata);
	location[1] = ReadPackFloat(pushdata);
	location[2] = ReadPackFloat(pushdata);
	
	//PrintToChatAll("DEBUG 1-2 测试成功 冲击波出现");
	
	new push = CreateEntityByName("point_push");  
	
	if( IsValidEntity(push) )
	{
		DispatchKeyValueFloat (push, "magnitude", 9999.0);                     
		DispatchKeyValueFloat (push, "radius", 1000.0);                     
		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
		DispatchSpawn(push);   
		TeleportEntity(push, location, NULL_VECTOR, NULL_VECTOR);  
		AcceptEntityInput(push, "Enable", -1, -1);
	}

	CreateTimer(0.8, DeletePushForcemiss, push);
}

public Action:CreateHurt(Handle:timer, Handle:hurt)
{
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	new nuclearNumber = ReadPackCell(hurt);
	new Float:location[3];
	location[0] = ReadPackFloat(hurt);
	location[1] = ReadPackFloat(hurt);
	location[2] = ReadPackFloat(hurt);
	KillTimer(timer);
	timer_handle[client][nuclearNumber] = INVALID_HANDLE;
	CloseHandle(hurt);
	
	new String:originData[64];
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	
	new String:nuclearRadius[64];
	Format(nuclearRadius, sizeof(nuclearRadius), "%i", GetConVarInt(CvarDamageRadius));
	
	new String:nuclearDamage[64];
	Format(nuclearDamage, sizeof(nuclearDamage), "%i", GetConVarInt(CvarDamageforce));

	new pointHurt = CreateEntityByName("point_hurt");
	
	if( IsValidEntity(pointHurt) )
	{
		DispatchKeyValue(pointHurt,"Origin", originData);
		DispatchKeyValue(pointHurt,"Damage", nuclearDamage);
		DispatchKeyValue(pointHurt,"DamageRadius", nuclearRadius);
		DispatchKeyValue(pointHurt,"DamageDelay", "1.0");
		DispatchKeyValue(pointHurt,"DamageType", "65536");
		DispatchKeyValue(pointHurt,"classname","point_hurt");
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "TurnOn");
	}
	
	CreateTimer(0.5, DeletePointHurt, pointHurt); 
}

public Action:CreateExplode(Handle:timer, Handle:bombdata)
{
	ResetPack(bombdata);
	new client = ReadPackCell(bombdata);
	new Float:location[3];
	location[0] = ReadPackFloat(bombdata);
	location[1] = ReadPackFloat(bombdata);
	location[2] = ReadPackFloat(bombdata);
	new nuclearNumber = ReadPackCell(bombdata);
	CloseHandle(bombdata);
	
	EmitSoundToAll("animation/gas_station_explosion.wav", _, _, _, _, 0.8);
	EmitSoundToAll("ambient/explosions/explode_3.wav", _, _, _, _, 0.8);

	PyroExplode(location);
	PyroExplode2(location);
	
	hurtdata[client][nuclearNumber] = CreateDataPack();
	WritePackCell(hurtdata[client][nuclearNumber], client);
	WritePackCell(hurtdata[client][nuclearNumber], nuclearNumber);
	WritePackFloat(hurtdata[client][nuclearNumber], location[0]);
	WritePackFloat(hurtdata[client][nuclearNumber], location[1]);
	WritePackFloat(hurtdata[client][nuclearNumber], location[2]);
	timer_handle[client][nuclearNumber] = CreateTimer(0.1, CreateHurt, hurtdata[client][nuclearNumber], TIMER_REPEAT);
					
	new Handle:pushdata = CreateDataPack();
	CreateTimer(0.1, Createpush, pushdata);
	WritePackFloat(pushdata, location[0]);
	WritePackFloat(pushdata, location[1]);
	WritePackFloat(pushdata, location[2]);	
	
	new explosion =  CreateEntityByName("prop_physics");
	
	if( IsValidEntity(explosion) )      
    {	
        SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
        SetEntProp(explosion, Prop_Send, "m_CollisionGroup", 1);
        //DispatchKeyValue(explosion, "model", "models/props_junk/explosive_box001.mdl");
        DispatchKeyValue(explosion, "model", "models/props_junk/propanecanister001a.mdl");
        //DispatchKeyValue(explosion, "model", "models/props_equipment/oxygentank01.mdl");
        DispatchKeyValue(explosion, "model", "models/props_junk/gascan001a.mdl");		
        DispatchSpawn(explosion);
		
        TeleportEntity(explosion, location, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(explosion, "break");
		
        location[2] += 50;
        CreateParticles(location, "gas_explosion_main", 1.0); 
        CreateParticles(location, "gas_explosion_pump", 1.0);
        CreateParticles(location, "weapon_pipebomb", 1.0); 
        
        location[2] += 100;
        CreateParticles(location, "gas_explosion_main", 1.0); 
        CreateParticles(location, "gas_explosion_pump", 1.0);
        CreateParticles(location, "weapon_pipebomb", 1.0); 
       
        location[0] += 50;
        location[1] -= 50;
        CreateParticles(location, "gas_explosion_main", 1.0); 
        CreateParticles(location, "gas_explosion_pump", 1.0);
        CreateParticles(location, "weapon_pipebomb", 1.0); 
        
        location[0] -= 100;
        location[1] += 100;
        CreateParticles(location, "gas_explosion_main", 1.0); 
        CreateParticles(location, "gas_explosion_pump", 1.0);
        CreateParticles(location, "weapon_pipebomb", 1.0); 
        
        location[2] += 100;
        location[0] += 200;
        location[1] -= 200;
        CreateParticles(location, "gas_explosion_main", 1.0); 
        CreateParticles(location, "gas_explosion_pump", 1.0);
        CreateParticles(location, "weapon_pipebomb", 1.0); 
        
	}

	new Handle:hShake = StartMessageOne("Shake", client);
	
	if (hShake != INVALID_HANDLE)
    {
        BfWriteByte(hShake, 0);
        BfWriteFloat(hShake, 10.0);
        BfWriteFloat(hShake, 5.0);
        BfWriteFloat(hShake, 15.0);
        EndMessage();
    }
}

public Action:CreateCloud(Handle:timer, Handle:gasdata)
{
	ResetPack(gasdata);
	new client = ReadPackCell(gasdata);
	new Float:location[3];
	location[0] = ReadPackFloat(gasdata);
	location[1] = ReadPackFloat(gasdata);
	location[2] = ReadPackFloat(gasdata);
	new nuclearNumber = ReadPackCell(gasdata);
	CloseHandle(gasdata);

	location[2] += 200;
	location[0] -= 100;
	location[1] += 100;
	CreateParticles(location, "gas_explosion_main", 1.0); 
	CreateParticles(location, "gas_explosion_pump", 1.0);
	CreateParticles(location, "weapon_pipebomb", 1.0); 
	
	location[2] += 100;
	location[0] += 200;
	location[1] -= 200;
	CreateParticles(location, "gas_explosion_main", 1.0); 
	CreateParticles(location, "gas_explosion_pump", 1.0);
	CreateParticles(location, "weapon_pipebomb", 1.0); 
		
	location[2] -= 300;
	location[0] -= 100;
	location[1] += 100;
		
	new String:colorData[64];
	
	new red =  255;
	new green =  255;
	new blue =255;
	Format(colorData, sizeof(colorData), "%i %i %i", red, green, blue);
	
	new String:originData[64];
	
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	
	new String:nuclearRadius[64];
	Format(nuclearRadius, sizeof(nuclearRadius), "%i", GetConVarInt(CvarCloudRadius));
	
	new String:nuclearDamage[64];
	Format(nuclearDamage, sizeof(nuclearDamage), "%i", GetConVarInt(CvarCloudDamage));

	new pointHurt = CreateEntityByName("point_hurt");
	
	if( IsValidEntity(pointHurt) )
	{
		DispatchKeyValue(pointHurt,"Origin", originData);
		DispatchKeyValue(pointHurt,"Damage", nuclearDamage);
		DispatchKeyValue(pointHurt,"DamageRadius", nuclearRadius);
		DispatchKeyValue(pointHurt,"DamageDelay", "1.0");
		DispatchKeyValue(pointHurt,"DamageType", "65536");
		DispatchKeyValue(pointHurt,"classname","point_hurt");
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "TurnOn");
	}

	CreateTimer(50.0, DeletePointHurt, pointHurt); 
	
	PrintToChatAll("\x04[核辐射污染]   \x05范围 \x01+%d  \x05伤害值 \x01+%d  \x05持续时间 \x01+50 \x05秒",GetConVarInt(CvarDamageRadius),GetConVarInt(CvarCloudDamage));
	
	new String:cloud_name[128];
	Format(cloud_name, sizeof(cloud_name), "Gas%i", client);
	new Cloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(Cloud,"targetname", cloud_name);
	DispatchKeyValue(Cloud,"Origin", originData);
	DispatchKeyValue(Cloud,"BaseSpread", "50");
	DispatchKeyValue(Cloud,"SpreadSpeed", "10");
	DispatchKeyValue(Cloud,"Speed", "40");
	DispatchKeyValue(Cloud,"StartSize", "200");
	DispatchKeyValue(Cloud,"EndSize", "1400");
	DispatchKeyValue(Cloud,"Rate", "15");
	DispatchKeyValue(Cloud,"JetLength", "1000");
	DispatchKeyValue(Cloud,"Twist", "10");
	DispatchKeyValue(Cloud,"RenderColor", colorData);
	DispatchKeyValue(Cloud,"RenderAmt", "100");
	DispatchKeyValue(Cloud,"SmokeMaterial", "particle/particle_noisesphere.vmt");
	DispatchSpawn(Cloud);
	AcceptEntityInput(Cloud, "TurnOn");
	EmitSoundToAll("animation/van_inside_debris.wav", _, _, _, _, 0.8);

	new Handle:soundpack1 = CreateDataPack();
	CreateTimer(5.0, DurationSoundtime1, soundpack1);
	WritePackCell(soundpack1, client);
	
	new Handle:soundpack2 = CreateDataPack();
	CreateTimer(7.0, DurationSoundtime2, soundpack2);
	WritePackCell(soundpack2, client);
	
	new Handle:soundpack3 = CreateDataPack();
	CreateTimer(9.0, DurationSoundtime3, soundpack3);
	WritePackCell(soundpack3, client);
	
	new Handle:soundpack4 = CreateDataPack();
	CreateTimer(11.0, DurationSoundtime4, soundpack4);
	WritePackCell(soundpack4, client);

	new Handle:entitypack = CreateDataPack();
	new Handle:entitypack2 = CreateDataPack();
	CreateTimer(GetConVarFloat(Cvar_nuclearTime), RemoveGas, entitypack);
	WritePackCell(entitypack, Cloud);
	WritePackCell(entitypack, nuclearNumber);
	WritePackCell(entitypack, client);
	CreateTimer(GetConVarFloat(Cvar_nuclearTime), KillGas, entitypack2);
	WritePackCell(entitypack2, Cloud);
	WritePackCell(entitypack2, nuclearNumber);
	WritePackCell(entitypack2, client);
}

public Action:DeletePointHurt(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}
	}
}

public Action:DeletePushForcemiss(Handle:timer, any:ent)
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

public Action:RemoveGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new Cloud = ReadPackCell(entitypack);
	new nuclearNumber = ReadPackCell(entitypack);
	new client = ReadPackCell(entitypack);

	if (IsValidEntity(Cloud))
	{
		AcceptEntityInput(Cloud, "TurnOff");	
	}
	if (timer_handle[client][nuclearNumber] != INVALID_HANDLE)
	{
		KillTimer(timer_handle[client][nuclearNumber]);
		timer_handle[client][nuclearNumber] = INVALID_HANDLE;
		CloseHandle(hurtdata[client][nuclearNumber]);
	}
}

public Action:KillGas(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new Cloud = ReadPackCell(entitypack);
	PrintToChatAll("\x04核污染蘑菇云消失");
	if (IsValidEntity(Cloud))
		AcceptEntityInput(Cloud, "Kill");
	
	CloseHandle(entitypack);
}

public Action: PyroExplode(Float:vec1[3])
{
	new color[4]={188,220,255,250};
	TE_SetupBeamRingPoint(vec1, 5.0, 2000.0, white, halo, 0, 8, 1.5, 12.0, 0.5, color, 8, 0);
  	TE_SendToAll();
}

public PyroExplode2(Float:vec1[3])
{
	vec1[2] += 10;
	new color[4]={188,220,255,250};			
	TE_SetupBeamRingPoint(vec1, 5.0, 1600.0, fire, halo, 0, 60, 8.0, 200.0, 0.2, color, 20, 0);
  	TE_SendToAll();
}

public Action:removenuclear(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic", false))
		{
			RemoveEdict(ent);		
		}
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	nuclearamount[client] = GetConVarInt(Cvar_nuclearAmount);
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	nuclearamount[client] = 0;
}

public Action:DurationSoundtime1(Handle:timer, Handle:soundpack)
{
	ResetPack(soundpack);
	new client = ReadPackCell(soundpack);
	DurationSound2(client, GetConVarInt(CvarDurationTime2));
}

public Action:DurationSoundtime2(Handle:timer, Handle:soundpack)
{
	ResetPack(soundpack);
	new client = ReadPackCell(soundpack);
	DurationSound3(client, GetConVarInt(CvarDurationTime2));
}

public Action:DurationSoundtime3(Handle:timer, Handle:soundpack)
{
	ResetPack(soundpack);
	new client = ReadPackCell(soundpack);
	DurationSound4(client, GetConVarInt(CvarDurationTime2));
}

public Action:DurationSoundtime4(Handle:timer, Handle:soundpack)
{
	ResetPack(soundpack);
	new client = ReadPackCell(soundpack);
	DurationSound5(client, GetConVarInt(CvarDurationTime2));
}
DurationSound2(client, time)
{
	DurationTime2[client] = time;
	CreateTimer(1.0, Timer_Freeze2, client, DEFAULT_TIMER_FLAGS);
}
DurationSound3(client, time)
{
	DurationTime2[client] = time;
	CreateTimer(1.0, Timer_Freeze2, client, DEFAULT_TIMER_FLAGS);
}
DurationSound4(client, time)
{
	DurationTime2[client] = time;
	CreateTimer(1.0, Timer_Freeze2, client, DEFAULT_TIMER_FLAGS);
}
DurationSound5(client, time)
{
	DurationTime2[client] = time;
	CreateTimer(1.0, Timer_Freeze2, client, DEFAULT_TIMER_FLAGS);
}
public Action:Timer_Freeze2(Handle:timer, any:value)
{
	new client = value & 0x7f;

	DurationTime2[client]--;
	if( DurationTime2[client] >= 1)
	{
	    EmitSoundToAll("ambient/random_amb_sfx/dist_explosion_01.wav" ,_, _, _, _, 1.0);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}
public Action:Timer_Freeze3(Handle:timer, any:value)
{
	new client = value & 0x7f;

	DurationTime2[client]--;
	if( DurationTime2[client] >= 1)
	{
	    EmitSoundToAll("ambient/random_amb_sfx/dist_explosion_02.wav" ,_, _, _, _, 1.0);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}
public Action:Timer_Freeze4(Handle:timer, any:value)
{
	new client = value & 0x7f;

	DurationTime2[client]--;
	if( DurationTime2[client] >= 1)
	{
	    EmitSoundToAll("ambient/random_amb_sfx/dist_explosion_03.wav" ,_, _, _, _, 1.0);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}
public Action:Timer_Freeze5(Handle:timer, any:value)
{
	new client = value & 0x7f;

	DurationTime2[client]--;
	if( DurationTime2[client] >= 1)
	{
	    EmitSoundToAll("ambient/random_amb_sfx/dist_explosion_04.wav" ,_, _, _, _, 1.0);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}
DurationSound(client, time)
{
	DurationTime[client] = time;
	CreateTimer(1.0, Timer_Freeze, client, DEFAULT_TIMER_FLAGS);
}

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;

	DurationTime[client]--;
	if( DurationTime[client] >= 1)
	{
	    EmitSoundToAll("ambient/alarms/klaxon1.wav" ,_, _, _, _, 0.8);
	    PrintHintTextToAll("核弹启爆倒计时\n %d 秒", DurationTime[client]);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Handled;
}

/* 连锁闪电 */
public Action:UseChainLightning(Client, args)
{
	if(GetClientTeam(Client) == 2) ChainLightningFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:ChainLightningFunction(Client)
{
	if(JD[Client] != 5)
	{
		CPrintToChat(Client, MSG_NEED_JOB5);
		return Plugin_Handled;
	}

	if(ChainLightningLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_17);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_ChainLightning) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_ChainLightning), MP[Client]);
		return Plugin_Handled;
	}
	if (ChainLightningCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}


	MP[Client] -= GetConVarInt(Cost_ChainLightning);
	ChainLightningCD[Client] = true;	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];
	new Float:Radius=float(ChainLightningLaunchRadius[Client]);
	GetClientAbsOrigin(Client, pos);
	
	/* Emit impact sound */
	EmitAmbientSound(ChainLightning_Sound_launch, pos); //EmitAmbientSound = 在物品周围播放技能音效
	
	ShowParticle(pos, ChainLightning_Particle_hit, 0.1);
			
	new Float:SkyLocation[3];
	SkyLocation[0] = pos[0];
	SkyLocation[1] = pos[1];
	SkyLocation[2] = pos[2] + 500.0; //闪电柱高度
	
	new Float:range;
	range = 500.0; //固定外围直径
	
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, range - 0.1, range, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 20.0, 3.0, mediumorchidColor, 5, 0);//固定外圈BuleColor
	TE_SendToAll();
	
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 3.0, 20.0, 20.0, 10, 10.0, mediumorchidColor, 0); //闪电柱
	
	TE_SendToAll();
	
	TE_SetupGlowSprite(pos, g_GlowSprite, 0.5, 5.0, 100);
	TE_SendToAll();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, ChainLightningDamage[Client], 0 , "chain_lightning");
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
					TE_SendToAll();
					IsChained[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainLightningInterval[Client], ChainDamage, newh);
					WritePackCell(newh, Client);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(Client, iEntity, ChainLightningDamage[Client], 0, "chain_lightning");
				TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
				TE_SendToAll();
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainLightningInterval[Client], ChainDamage, newh);
				WritePackCell(newh, Client);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	
	CPrintToChatAll(MSG_SKILL_CL_ANNOUNCE, Client, ChainLightningLv[Client]);
	CreateTimer(1.0, Timer_UseChainLightningCD, Client);

	//PrintToserver("[United RPG] %s启动了连锁闪电!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:Timer_UseChainLightningCD(Handle:timer, any:Client)
{
	ChainLightningCD[Client] = false;
	KillTimer(timer);
}
public Action:ChainDamage(Handle:timer, Handle:h)
{
	decl Float:pos[3];
	ResetPack(h);
	new attacker=ReadPackCell(h);
	new victim=ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:entpos[3];
	new Float:Radius=float(ChainLightningRadius[attacker]);
	if(victim >= MaxClients + 1)
	{
		if ((IsCommonInfected(victim) || IsWitch(victim)) && GetEntProp(victim, Prop_Data, "m_iHealth")>0)	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
		if((IsCommonInfected(victim) || IsWitch(victim)))	SetEntProp(victim, Prop_Send, "m_bFlashing", 0);
	} else
	{
		if(IsClientInGame(victim) && IsPlayerAlive(victim) && !IsPlayerGhost(victim))	GetClientAbsOrigin(victim, pos);
		IsChained[victim] = false;
	}
	
	/* Emit impact Sound */
	EmitAmbientSound(ChainLightning_Sound_launch, pos); //EmitAmbientSound = 在物品周围播放技能音效
	
	TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 3.0, 100);
	TE_SendToAll();
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0 && iEntity != victim && GetEntProp(iEntity, Prop_Send, "m_bFlashing") != 1)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(attacker, iEntity, RoundToNearest(ChainLightningDamage[attacker]/(1.0 + StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker])), 0 , "chain_lightning");
				TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
				TE_SendToAll();
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainLightningInterval[attacker], ChainDamage, newh);
				WritePackCell(newh, attacker);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i) && i != victim && !IsChained[i])
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(attacker, i, ChainLightningDamage[attacker], 0 , "chain_lightning");
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
					TE_SendToAll();
					IsChained[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainLightningInterval[attacker], ChainDamage, newh);
					WritePackCell(newh, attacker);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	//return Plugin_Handled;
}

/* 精灵生物专家关联2 */
public Action:UseChainmissLightning(Client, args)
{
	if(GetClientTeam(Client) == 2) ChainmissLightningFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
}

public Action:ChainmissLightningFunction(Client)
{
	if(JD[Client] != 3)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}

	if(ChainmissLightningLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE);
		return Plugin_Handled;
	}
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];
	new Float:Radius=float(ChainmissLightningLaunchRadius[Client]);
	GetClientAbsOrigin(Client, pos);
	
	/* Emit impact sound */
	EmitAmbientSound(ChainmissLightning_Sound_launch, pos);
	
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, 0.1, Radius-99499.1, g_BeamSprite, g_HaloSprite, 0, 90, 0.5, 90.0, 0.0, ClaretColor, 1, 0);//扩散外圈ClaretColor
	TE_SendToAll(0.1);
	TE_SetupBeamRingPoint(pos, Radius-99499.2, 0.1, g_BeamSprite, g_HaloSprite, 0, 90, 0.5, 90.0, 0.0, YellowColor, 1, 0);//扩散外圈ClaretColor
	TE_SendToAll(0.8);
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 90, 0.5, 90.0, 0.0, ClaretColor, 1, 0);//扩散外圈ClaretColor
	TE_SendToAll(0.2);
	TE_SetupBeamRingPoint(pos, Radius, 0.1, g_BeamSprite, g_HaloSprite, 0, 90, 0.5, 90.0, 0.0, YellowColor, 1, 0);//扩散外圈ClaretColor
	TE_SendToAll(0.9);
	TE_SetupSparks(pos, NULL_VECTOR, 12, 10);
	TE_SendToAll();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, ChainmissLightningDamage[Client], 0 , "chainmiss_lightning");
					IsChainmissed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainmissLightningInterval[Client], ChainmissDamage, newh);
					WritePackCell(newh, Client);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(Client, iEntity, RoundToNearest(ChainmissLightningDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 0, "chainmiss_lightning");
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainmissLightningInterval[Client], ChainmissDamage, newh);
				WritePackCell(newh, Client);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	
	CPrintToChat(Client, MSG_SKILL_MEIXINXI_ANNOUNCE, ChainmissLightningLv[Client], HealingBallmissFunction(Client));

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:ChainmissDamage(Handle:timer, Handle:h)
{
	decl Float:pos[3];
	ResetPack(h);
	new attacker=ReadPackCell(h);
	new victim=ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:entpos[3];
	new Float:Radius=float(ChainmissLightningRadius[attacker]);
	if(victim >= MaxClients + 1)
	{
		if ((IsCommonInfected(victim) || IsWitch(victim)) && GetEntProp(victim, Prop_Data, "m_iHealth")>0)	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
		if((IsCommonInfected(victim) || IsWitch(victim)))	SetEntProp(victim, Prop_Send, "m_bFlashing", 0);
	} else
	{
		if(IsClientInGame(victim) && IsPlayerAlive(victim) && !IsPlayerGhost(victim))	GetClientAbsOrigin(victim, pos);
		IsChainmissed[victim] = false;
	}
	
	/* Emit impact sound */
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0 && iEntity != victim && GetEntProp(iEntity, Prop_Send, "m_bFlashing") != 1)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(attacker, iEntity, RoundToNearest(ChainmissLightningDamage[attacker]/(1.0 + StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker])), 1024 , "chainmiss_lightning");
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainmissLightningInterval[attacker], ChainmissDamage, newh);
				WritePackCell(newh, attacker);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i) && i != victim && !IsChained[i])
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(attacker, i, ChainmissLightningDamage[attacker], 1024 , "chainmiss_lightning");
					IsChainmissed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainmissLightningInterval[attacker], ChainmissDamage, newh);
					WritePackCell(newh, attacker);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	//return Plugin_Handled;
}

/* 狂暴者模式关联 */
public Action:UseChainkbLightning(Client, args)
{
	if(GetClientTeam(Client) == 2) ChainkbLightningFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
}

public Action:ChainkbLightningFunction(Client)
{
	if(JD[Client] != 2)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(ChainkbLightningLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN);
		return Plugin_Handled;
	}
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];
	new Float:Radius=float(ChainkbLightningLaunchRadius[Client]);
	GetClientAbsOrigin(Client, pos);
	
	/* Emit impact sound */
	ShowParticle(pos, FireBall_Particle_Fire01, 5.0);
	ShowParticle(pos, FireBall_Particle_Fire02, 5.0);
	ShowParticle(pos, FireBall_Particle_Fire03, 5.0);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, ChainkbLightningDamage[Client], 1024 , "chainkb_lightning");
					LittleFlower(entpos, EXPLODE, Client);
					IsChainkbed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainLightningInterval[Client], ChainkbDamage, newh);
					WritePackCell(newh, Client);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(Client, iEntity, RoundToNearest(ChainkbLightningDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 1024, "chain_lightning");
				LittleFlower(entpos, EXPLODE, Client);
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainkbLightningInterval[Client], ChainkbDamage, newh);
				WritePackCell(newh, Client);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	
	CPrintToChat(Client, MSG_SKILL_MEIXINXI_NOGUN, ChainkbLightningLv[Client]);

	//PrintToserver("", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:ChainkbDamage(Handle:timer, Handle:h)
{
	decl Float:pos[3];
	ResetPack(h);
	new attacker=ReadPackCell(h);
	new victim=ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:entpos[3];
	new Float:Radius=float(ChainkbLightningRadius[attacker]);
	if(victim >= MaxClients + 1)
	{
		if ((IsCommonInfected(victim) || IsWitch(victim)) && GetEntProp(victim, Prop_Data, "m_iHealth")>0)	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
		if((IsCommonInfected(victim) || IsWitch(victim)))	SetEntProp(victim, Prop_Send, "m_bFlashing", 0);
	} else
	{
		if(IsClientInGame(victim) && IsPlayerAlive(victim) && !IsPlayerGhost(victim))	GetClientAbsOrigin(victim, pos);
		IsChainkbed[victim] = false;
	}
	
	/* Emit impact Sound */
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0 && iEntity != victim && GetEntProp(iEntity, Prop_Send, "m_bFlashing") != 1)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(attacker, iEntity, RoundToNearest(ChainkbLightningDamage[attacker]/(1.0 + StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker])), 1024 , "chainkb_lightning");
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(ChainkbLightningInterval[attacker], ChainkbDamage, newh);
				WritePackCell(newh, attacker);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i) && i != victim && !IsChainkbed[i])
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(attacker, i, ChainkbLightningDamage[attacker], 1024 , "chainkb_lightning");
					IsChainkbed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(ChainkbLightningInterval[attacker], ChainkbDamage, newh);
					WritePackCell(newh, attacker);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	//return Plugin_Handled;
}

public Action:StatusUp(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client))
	{
		new iClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
		if(iClass != CLASS_TANK)	RebuildStatus(Client, false);
	}
	return Plugin_Handled;
}

//重建角色状态
stock Action:RebuildStatus(Client, bool:IsFullHP = false, bool:Read = false)
{
	new MaxHP;

	if(GetClientTeam(Client) == 3)
	{
		new iClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
		switch(iClass)
		{
			case 1: MaxHP = GetConVarInt(FindConVar("z_gas_health"));
			case 2: MaxHP = GetConVarInt(FindConVar("z_exploding_health"));
			case 3: MaxHP = GetConVarInt(FindConVar("z_hunter_health"));
			case 4: MaxHP = GetConVarInt(FindConVar("z_spitter_health"));
			case 5: MaxHP = GetConVarInt(FindConVar("z_jockey_health"));
			case 6: MaxHP = GetConVarInt(FindConVar("z_charger_health"));
		}
	} 
	else
		MaxHP = 400;
	
	new NewMaxHP;
	if (GeneLv[Client] > 0) //基因改造
	{
		SetEntProp(Client, Prop_Data, "m_iMaxHealth", RoundToNearest(MaxHP * (1.0+HealthEffect[Client]) + GeneHealthEffect[Client]));
		NewMaxHP = RoundToNearest(MaxHP * (1.0+HealthEffect[Client]) + GeneHealthEffect[Client]);
	}
	else
	{
		SetEntProp(Client, Prop_Data, "m_iMaxHealth", RoundToNearest(MaxHP * (1.0+HealthEffect[Client])));
		NewMaxHP = RoundToNearest(MaxHP*(1.0+HealthEffect[Client]));
	}

	new HP = GetClientHealth(Client);

	if(HP > NewMaxHP) 
		SetEntityHealth(Client, NewMaxHP);

	new Float:speed = 1.0;
	if(IsSprintEnable[Client])
	{
		speed = 1.6 * (1.0 + AgiEffect[Client]);
		SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", speed);
		//SetEntityGravity(Client, 2.4 / (1.0 + AgiEffect[Client]));
	} 
	else
	{
		speed = 1.0 + AgiEffect[Client];
		SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", speed);
		//SetEntityGravity(Client, 1.8 / (1.0 + AgiEffect[Client]));
	}

	//设置装备加成属性
	if (!Read)
		ResetPlayerZBData(Client, speed, NewMaxHP);
	else
		ResetPlayerZBData(Client, speed, NewMaxHP, true);
	
	//是否满血
	if(IsFullHP)
		SetEntityHealth(Client, GetEntProp(Client, Prop_Data, "m_iMaxHealth"));//修改玩家血量
}
public Action:Event_HealSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"));

	if (GetConVarInt(HealTeammateExp) > 0 && Client != HealSucTarget)
	{
		if (JD[Client]==4)
		{
			EXP[Client] += GetConVarInt(HealTeammateExp)+Job4_ExtraReward[Client] + VIPAdd(Client, GetConVarInt(HealTeammateExp)+Job4_ExtraReward[Client], 1, true);
			Cash[Client] += GetConVarInt(HealTeammateCash)+Job4_ExtraReward[Client] + VIPAdd(Client, GetConVarInt(HealTeammateCash)+Job4_ExtraReward[Client], 1, false);
			CPrintToChat(Client, MSG_EXP_HEAL_SUCCESS_JOB4, GetConVarInt(HealTeammateExp),
						Job4_ExtraReward[Client], GetConVarInt(HealTeammateCash), Job4_ExtraReward[Client]);
		}
		else
		{
			EXP[Client] += GetConVarInt(HealTeammateExp) + VIPAdd(Client, GetConVarInt(HealTeammateExp), 1, true);
			Cash[Client] += GetConVarInt(HealTeammateCash) + VIPAdd(Client, GetConVarInt(HealTeammateCash), 1, false);
			CPrintToChat(Client, MSG_EXP_HEAL_SUCCESS, GetConVarInt(HealTeammateExp), GetConVarInt(HealTeammateCash));
		}
	}
	if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget) && Lv[HealSucTarget] > 0)
	{
		SetEntProp(HealSucTarget, Prop_Data, "m_iMaxHealth", RoundToNearest(100*(1+HealthEffect[HealSucTarget])));
		SetEntProp(HealSucTarget, Prop_Data, "m_iHealth", RoundToNearest(100*(1+HealthEffect[HealSucTarget])));
	}
	return Plugin_Continue;
}


/************************************************************************
*	技能Funstion END
************************************************************************/

/***********************************************
	幸存者使用技能 		
***********************************************/

public Action:Menu_UseSkill(Client, args)
{
	if (!IsValidPlayer(Client, false))
		return Plugin_Handled;
		
	MenuFunc_UseSkill(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_UseSkill(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "使用技能 MP: %d / %d", MP[Client], MaxMP[Client]);
	SetPanelTitle(menu, line);
	if(GetClientTeam(Client) == 2)
	{
		if (VIP[Client] <= 0)
			Format(line, sizeof(line), "[通用]治疗术 (Lv.%d / MP:%d)", HealingLv[Client], GetConVarInt(Cost_Healing));
		else
			Format(line, sizeof(line), "[通用]高级治疗术 (Lv.%d / MP:%d)", HealingLv[Client], GetConVarInt(Cost_Healing));
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[通用]地震术 (Lv.%d / MP:%d)", EarthQuakeLv[Client], GetConVarInt(Cost_EarthQuake));
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[通用]召唤自动机枪(Lv.%d / MP:5000)", HeavyGunLv[Client]);
		DrawPanelItem(menu, line);
		
		
		if(JD[Client] == 1)
		{
			Format(line, sizeof(line), "[精灵]子弹制造术 (Lv.%d / MP:%d)", AmmoMakingLv[Client], GetConVarInt(Cost_AmmoMaking));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[精灵]卫星炮术 (Lv.%d / MP:%d)", SatelliteCannonLv[Client], GetConVarInt(Cost_SatelliteCannon));
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[究极]核弹头 (Lv.%d / MP:%d)", AmmoMakingmissLv[Client], MaxMP[Client]);
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 3)
		{
			Format(line, sizeof(line), "[生物专家]无敌术 (Lv.%d / MP:%d)", BioShieldLv[Client], GetConVarInt(Cost_BioShield));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[生物专家]反伤术 (Lv.%d / MP:%d)", DamageReflectLv[Client], GetConVarInt(Cost_DamageReflect));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[生物专家]近战嗜血术 (Lv.%d / MP:%d)", MeleeSpeedLv[Client], GetConVarInt(Cost_MeleeSpeed));
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[究极]潜能大爆发 (Lv.%d / MP:%d)", BioShieldmissLv[Client], GetConVarInt(Cost_BioShieldmiss));
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 2)
		{
			Format(line, sizeof(line), "[士兵]火焰极速 (Lv.%d / MP:%d)", SprintLv[Client], GetConVarInt(Cost_Sprint));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[士兵]无限子弹术 (Lv.%d / MP:%d)", InfiniteAmmoLv[Client], GetConVarInt(Cost_InfiniteAmmo));
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[究极]狂暴者模式 (Lv.%d / MP:%d)", BioShieldkbLv[Client], MaxMP[Client]);
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 4)
		{
			Format(line, sizeof(line), "[医生]选择传送术 (Lv.%d / MP:%d)", TeleportToSelectLv[Client], GetConVarInt(Cost_TeleportToSelect));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[医生]审判光球术 (Lv.%d / MP:%d)", AppointTeleportLv[Client], GetConVarInt(Cost_AppointTeleport));
			DrawPanelItem(menu, line);		
			Format(line, sizeof(line), "[医生]心灵传送术 (Lv.%d / MP:%d)", TeleportTeamLv[Client], GetConVarInt(Cost_TeleportTeammate));
			DrawPanelItem(menu, line);				
			Format(line, sizeof(line), "[医生]额外的电击器 (剩余:%d个)", defibrillator[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[医生]治疗光球术 (Lv.%d / MP:%d)", HealingBallLv[Client], GetConVarInt(Cost_HealingBall));
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[医生]全体召唤术 (Lv.%d / MP:%d)", TeleportTeamztLv[Client], MaxMP[Client]);
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 5)
		{
			Format(line, sizeof(line), "[魔法]火球术 (Lv.%d / MP:%d)", FireBallLv[Client], GetConVarInt(Cost_FireBall));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[魔法]冰球术 (Lv.%d / MP:%d)", IceBallLv[Client], GetConVarInt(Cost_IceBall));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[魔法]连锁闪电术 (Lv.%d / MP:%d)", ChainLightningLv[Client], GetConVarInt(Cost_ChainLightning));
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[究极]终结式暴雷 (Lv.%d / MP:%d)", SatelliteCannonmissLv[Client], MaxMP[Client]);
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 6)
		{
			Format(line, sizeof(line), "[弹药]破碎弹 (Lv.%d / MP:%d)", BrokenAmmoLv[Client], MP_BrokenAmmo);
			DrawPanelItem(menu, line);
		//	Format(line, sizeof(line), "[弹药]渗毒弹 (Lv.%d / MP:%d)", PoisonAmmoLv[Client], MP_PoisonAmmo);
		//	DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[弹药]吸血弹 (Lv.%d / MP:%d)", SuckBloodAmmoLv[Client], MP_SuckBloodAmmo);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[弹药]区域爆破 (Lv.%d / MP:%d)", AreaBlastingLv[Client], MP_AreaBlasting);
			DrawPanelItem(menu, line);
			if (NewLifeCount[Client] >= 1)
			{
				Format(line, sizeof(line), "[究极]镭射激光炮 (Lv.%d / MP:%d)", LaserGunLv[Client], MaxMP[Client]);
				DrawPanelItem(menu, line);
			}
		}
		else if(JD[Client] == 7)
		{
			Format(line, sizeof(line), "[雷神]雷神弹药 (Lv.%d / MP:%d)",  LZDLv[Client], MP_LZD);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[雷神]不熄光环 (Lv.%d / MP:%d)", DCGYLv[Client], MP_DCGY);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[雷神]虚空雷圈 (Lv.%d / MP:%d)", YLDSLv[Client], MP_YLDS);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 8)
		{
			Format(line, sizeof(line), "[虚空之眼]虚空之怒 (Lv.%d / MP:%d)", CqdzLv[Client], GetConVarInt(Cost_Cqdz));
			DrawPanelItem(menu, line);	
			Format(line, sizeof(line), "[虚空之眼]电弘赤炎 (Lv.%d / MP:%d)", HMZSLv[Client], GetConVarInt(Cost_HMZS));
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[虚空之眼]涟漪光圈 (Lv.%d / MP:%d)", SPZSLv[Client], GetConVarInt(Cost_SPZS));
			DrawPanelItem(menu, line);	
		}
	}
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, DeSkiMenu, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}
public DeSkiMenu(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		if(GetClientTeam(Client) == 2) {
			switch(param)
			{
				case 1:
				{
					HealingFunction(Client);
					MenuFunc_UseSkill(Client);
				}
				case 2:
				{
					EarthQuakeFunction(Client);
					MenuFunc_UseSkill(Client);
				}
				case 3:
				{
					if(HeavyGunLv[Client] <= 0){
						CPrintToChat(Client, MSG_NEED_SKILL_0);
					}else{
					
						if(MP[Client] >= 5000){
							MP[Client] -= 5000;
							CheatCommand(Client, "sm_mg","CmdMachineGun");
						}else{
							PrintHintText(Client, "[技能] 你的MP不足够发动技能!需要MP: 5000, 现在MP: %d", MP[Client]);
						}
					}
				}
			} if(JD[Client]==1) { //精灵
				switch(param)
				{
					case 4:
					{
						AmmoMakingFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						SatelliteCannonFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						AmmoMakingmissFunction(Client);
						MenuFunc_UseSkill(Client);
						}

				}
			} 
			else if(JD[Client]==2) 
			{ //士兵
				switch(param)
				{
					case 4:
					{
						SprintFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						InfiniteAmmoFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						BioShieldkbFunction(Client);
						MenuFunc_UseSkill(Client);
						}
				}
			} 
			else if(JD[Client]==3) 
			{ //生物专家
				switch(param)
				{
					case 4:
					{
						BioShieldFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						DamageReflectFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						MeleeSpeedFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 7:
					{
						BioShieldmissFunction(Client);
						MenuFunc_UseSkill(Client);
					}
				}
			} 
			else if(JD[Client]==4) 
			{ //医生
				switch(param) {
					case 4:
					{
						TeleportToSelectMenu(Client);
					}
					case 5:
					{
						LightBall(Client);
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						TeleportTeam(Client);
					}
					case 7:
					{
						if(defibrillator[Client]>0)
						{
							CheatCommand(Client, "give", "defibrillator");
							defibrillator[Client] -= 1;
						}
						else CPrintToChat(Client, "额外电击器已用完!");
						MenuFunc_UseSkill(Client);
					}
					case 8:
					{
						HealingBallFunction(Client);
						MenuFunc_UseSkill(Client);
					}
					case 9:
					{
						TeleportTeamzt(Client);
						MenuFunc_UseSkill(Client);
					}
				}
			} 
			else if(JD[Client]==5) 
			{ //大法师
				switch(param)
				{
					case 4:
					{
						FireBallFunction(Client);//火球术
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						IceBallFunction(Client);//冰球术
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						ChainLightningFunction(Client);//连锁闪电术
						MenuFunc_UseSkill(Client);
					}
					case 7:
					{
						SatelliteCannonmissFunction(Client);//终结式暴雷
						MenuFunc_UseSkill(Client);
					}
				}
			}
			else if(JD[Client]==6)  //弹药专家
			{ 
				switch(param)
				{
					case 4:
					{
						BrokenAmmo_Action(Client);//破碎弹
						MenuFunc_UseSkill(Client);
					}
					//case 5:
					//{
					//	PoisonAmmo_Action(Client);//渗毒弹
					//	MenuFunc_UseSkill(Client);
					//}
					case 5:
					{
						SuckBloodAmmo_Action(Client);//吸血弹
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						AreaBlasting_Action(Client);//区域爆破
						MenuFunc_UseSkill(Client);
					}
					case 7:
					{
						LaserGun_Action(Client);//镭射激光炮
						MenuFunc_UseSkill(Client);
					}
				}
			}
			else if(JD[Client]==7)  //雷神
			{ 
				switch(param)
				{
					case 4:
					{
						LZDFunction(Client);//雷神弹药
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						DCGYFunction(Client);//不熄光环
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						YLDSFunction(Client);//虚空雷圈
						MenuFunc_UseSkill(Client);
					}
				}
			}
			else if(JD[Client]==8)  //虚空之眼
			{ 
				switch(param)
				{
					case 4:
					{
						CqdzFunction(Client);//虚空之怒
						MenuFunc_UseSkill(Client);
					}
					case 5:
					{
						HMZSFunction(Client);//电弘赤炎
						MenuFunc_UseSkill(Client);
					}
					case 6:
					{
						SPZSFunction(Client);//涟漪光圈
						MenuFunc_UseSkill(Client);
					}
				}
			}
		}
	}
}

/******************************************************
*	United RPG选单
*******************************************************/
public Action:Menu_RPG(Client,args)
{    
	if (!IsPasswordConfirm[Client])
	{
		CPrintToChat(Client, "\x03[系统] {red}你没登录或注册,请输入密码登录!");
		CPrintToChat(Client, "\x03[系统] {red}按‘y’后输入/pw 123[pw后面有个空格,要输入/符号]来注册!");
		CPrintToChat(Client, "\x03[系统] {red}输入!qiandao进行游戏签到奖励!");
		MenuFunc_MZC(Client);
	}
	MenuFunc_RPG(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_RPG(Client)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return Plugin_Handled;
		
	new Handle:menu = CreateMenu(RPG_MenuHandler);
	decl String:job[32], String:m_viptype[32], String:CBAWU[32], String:LIZSA[1024];
	if(JD[Client] == 0)			Format(job, sizeof(job), "未转职");
	else if(JD[Client] == 1)	Format(job, sizeof(job), "精灵");
	else if(JD[Client] == 2)	Format(job, sizeof(job), "士兵");
	else if(JD[Client] == 3)	Format(job, sizeof(job), "生物专家");
	else if(JD[Client] == 4)	Format(job, sizeof(job), "医生");
	else if(JD[Client] == 5)	Format(job, sizeof(job), "法师");
	else if(JD[Client] == 6)	Format(job, sizeof(job), "弹药专家");
	else if(JD[Client] == 7)	Format(job, sizeof(job), "雷神");
	else if(JD[Client] == 8)	Format(job, sizeof(job), "虚空之眼");
	
	if (VIP[Client] <= 0)
		Format(m_viptype, sizeof(m_viptype), "★普通会员★");
	else if (VIP[Client] == 1)
		Format(m_viptype, sizeof(m_viptype), "★白金会员★");
	else if (VIP[Client] == 2)
		Format(m_viptype, sizeof(m_viptype), "★黄金会员★");
	else if (VIP[Client] == 3)
		Format(m_viptype, sizeof(m_viptype), "★水晶会员★");
	else if (VIP[Client] == 4)
		Format(m_viptype, sizeof(m_viptype), "★至尊会员★");
	
	if(Renwu[Client] == 0)			Format(CBAWU, sizeof(CBAWU), "无");
	else if(Renwu[Client] == 1)			Format(CBAWU, sizeof(CBAWU), "有");
	
	if(Lis[Client] == 0)			Format(LIZSA, sizeof(LIZSA), "克洛诺斯");   
	else if(Lis[Client] == 1)	Format(LIZSA, sizeof(LIZSA), "宙斯");   
	else if(Lis[Client] == 2)	Format(LIZSA, sizeof(LIZSA), "哈迪斯");
	
	decl String:line[256];
	Format(line, sizeof(line),
	"%s 附体天神:%s 大过:%d次 转生:%d\n等级:Lv.%d 金钱:$%d 职业:%s \n经验:%d/%d MP:%d/%d 点卷:%d个\n力量:%d 敏捷:%d 生命:%d 耐力:%d 智力:%d",
		m_viptype, LIZSA, KTCount[Client], NewLifeCount[Client], Lv[Client], Cash[Client], job, 
		EXP[Client], GetConVarInt(LvUpExpRate)*(Lv[Client]+1), MP[Client], MaxMP[Client], Qcash[Client],
		Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
	SetMenuTitle(menu, line);
	
	AddMenuItem(menu, "item0", "═技能施放═");
	AddMenuItem(menu, "item1", "═娱乐功能/活动═");
	Format(line, sizeof(line), "═每日任务:%s═", CBAWU);	
	AddMenuItem(menu, "item1", line);
	AddMenuItem(menu, "item3", "会员特权(特异功能)");
	AddMenuItem(menu, "item4", "═实时交易═");
	AddMenuItem(menu, "item5", "═军用背包═");
	AddMenuItem(menu, "item6", "═物品相关═");
	Format(line, sizeof(line), "签到/排行(%d天/15天)", everyday1[Client]);
	AddMenuItem(menu, "item7", line);
	AddMenuItem(menu, "item8", "师徒系统");

	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public RPG_MenuHandler(Handle:menu, MenuAction:action, Client, IteamNum)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;

	if (action == MenuAction_Select) {
		switch (IteamNum)
		{
			case 0: MenuFunc_jnsf(Client);  //技能施放
			case 1: MenuFunc_RPG_Learn(Client); 		//娱乐功能
			case 2: 
            {
                if(Renwu[Client] == 0)
                {
                    MenuFunc_Renwuxi(Client);
                }
                if(Renwu[Client] == 1)
                {
                    MenuFunc_Shizhesa(Client);
                }				
            }			//升级助手
//			case 4: JoinGameTeam(Client);			//加入游戏
            case 3: MenuFunc_VIP(Client);			//会员特权
			case 4: MenuFunc_Buy(Client);			//实时交易
			case 5: MenuFunc_IBag(Client);			//军用战斗包
			case 6: MenuFunc_MyItem(Client);			//物品相关
			case 7: MenuFunc_RPG_Other(Client);	//其它零碎
			case 8: MenuFunc_Baishi(Client);			//师徒系统
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

/* 技能施放 */
public Action:MenuFunc_jnsf(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "技能丨强化");			
	SetPanelTitle(menu, line);
   
	Format(line, sizeof(line), "使用技能(MP: %d/%d)", MP[Client], MaxMP[Client]);
	DrawPanelItem(menu, line);
	
	//Format(line, sizeof(line), "辅助技能(魂魄: %d)", HUNPO[Client]);
	//DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "学习技能（SP:%d）", SkillPoint[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "天赋[被动]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "强化技能");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "武器系统");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "失败的心[%d/100]", Sxcs[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "转职|转生|洗点");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "分配属性(属性点剩余:%d)", StatusPoint[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "返回主菜单");
	DrawPanelItem(menu, line);
	SendPanelToClient(menu, Client, MenuHandler_jnsf, MENU_TIME_FOREVER);
}

public MenuHandler_jnsf(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_UseSkill(Client);
			//case 2: MenuFunc_usefz(Client);
			case 2: MenuFunc_SurvivorSkill(Client);
			case 3: MenuFunc_TFXT(Client);			//天赋系统
			case 4: MenuFunc_Qhsx(Client);
			case 5: MenuFunc_WUQI(Client);
			case 6: MenuFunc_psdx(Client);
			case 7: MenuFunc_Job(Client); 				//转职洗点
			case 8: MenuFunc_AddAllStatus(Client);		//配分属性
			case 9: MenuFunc_RPG(Client);
		}
	}
}

/* 新手帮助面板*/
public Action:MenuFunc_Xsbz(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();

	Format(line, sizeof(line), "新手帮助面板");			
	SetPanelTitle(menu, line);
   
	Format(line, sizeof(line), "会员购买");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "改名教程");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "注册教程");
	DrawPanelItem(menu, line);


	
	Format(line, sizeof(line), "关闭菜单");
	DrawPanelItem(menu, line);
	SendPanelToClient(menu, Client, MenuHandler_Xsbz, MENU_TIME_FOREVER);
}

public MenuHandler_Xsbz(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_VIPFS(Client);
			case 2: MenuFunc_GMJC(Client);
			case 3: MenuFunc_ZCJC(Client);
//			case 4: MenuFunc_BJTY(Client);
		}
	}
}

public Action:MenuFunc_VIPFS(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[256];

	Format(line, sizeof(line), "白金拥有3次补给，1倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "黄金拥有6次补给，2倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "水晶拥有9次补给，3倍经验加成");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "至尊拥有15次补给，4倍经验加成");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPFS, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action:MenuFunc_ZCJC(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[256];

	Format(line, sizeof(line), "游戏 RPG注册方法:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "在游戏内按Y出现聊天框 ，然后输入/pw 123[pw后面有个空格,要输入/符号] 然后按回车发送出去 ，即可完成注册！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "（每一关都需要输入），想自动输入可以在群里下载免输入密码文件，或者是用登陆器登录，里面也有教程！");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "实在不会注册,可以去群里问，会有人解答。");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_GMJC, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action:MenuFunc_GMJC(Client)
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

	SendPanelToClient(menu, Client, MenuHandler_ZCJC, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

//任务系统
public Action:Menu_Renwuxi(Client,args)
{
    if(Renwu[Client] == 0)
    {
        MenuFunc_Renwuxi(Client);
    }
    if(Renwu[Client] == 1)
    {
        MenuFunc_Shizhesa(Client);
    }	
    return Plugin_Handled;
}
public Action:MenuFunc_Renwuxi(Client)
{   
	new Handle:menu = CreatePanel();
	    
	decl String:CBAWU[1024];	    
	if(Jenwu[Client] == 0)			Format(CBAWU, sizeof(CBAWU), "未接");
	    
	decl String:line[1024];    
	Format(line, sizeof(line), "【任务列表 状态:%s】", CBAWU);   
	SetPanelTitle(menu, line);    
	Format(line, sizeof(line), "═══杀出道路═══");    
	DrawPanelItem(menu, line);    
	Format(line, sizeof(line), "说明: 为了宁静的大道!");    
	DrawPanelText(menu, line);   
	Format(line, sizeof(line), "═══生存能力═══");   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "说明: 挑战自身的存活!");    
	DrawPanelText(menu, line);    
	Format(line, sizeof(line), "═══最终生还═══");   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "说明: 让自己活下去!");    
	DrawPanelText(menu, line);
	if(VIP[Client] > 0)
	{	    
		Format(line, sizeof(line), "═══贵族荣耀═══");       
		DrawPanelItem(menu, line);		
		Format(line, sizeof(line), "说明: VIP专属任务!");       
		DrawPanelText(menu, line);
	}	   
	DrawPanelItem(menu, "返回RPG选单"); 
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Renwuxi, MENU_TIME_FOREVER);    
	return Plugin_Handled;
}

public MenuHandler_Renwuxi(Handle:menu, MenuAction:action, Client, param)
{    
	if (action == MenuAction_Select)     
	{
		switch (param)   
		{        
			case 1:
            {
				if(Lv[Client] >= 10)
				{
					if(Jenwu[Client] == 0)
					{                        
						Renwu[Client] += 1;	//1为直接显示接了的任务 直接跳转到MenuFunc_Shizhesa					
						Jenwu[Client] += 1;	//数字为跳转对应的任务					
						MenuFunc_Shizhesa(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你的等级小于Lv10无法进行!");            
			}		
            case 2:
            {
				if(Lv[Client] >= 30)
				{
					if(Jenwu[Client] == 0)
					{                        
						Renwu[Client] += 1;						
						Jenwu[Client] += 2;						
						MenuFunc_Shizhesa(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你的等级小于Lv30无法进行!");            
			}
            case 3:
            {
				if(Lv[Client] >= 50)
				{
					if(Jenwu[Client] == 0)
					{                        
						Renwu[Client] += 1;						
						Jenwu[Client] += 3;						
						MenuFunc_Shizhesa(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你的等级小于Lv50无法进行!");            
			}
            case 4:
            {
				if(Lv[Client] >= 50)
				{
					if(Jenwu[Client] == 0)
					{                        
						Renwu[Client] += 1;						
						Jenwu[Client] += 4;						
						MenuFunc_Shizhesa(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你的等级小于Lv50无法进行!");            
			}
			case 5:MenuFunc_RPG(Client);
        }
    }
}

public Action:MenuFunc_Shizhesa(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];
    if (Jenwu[Client] == 1)  //显示接任务
    {
        Format(line, sizeof(line), "═══【任务】杀出道路═══ \n【任务要求: 击杀普通感染者!】\n【普通感染者:300个】〤斩:%d个 \n【奖励: 金钱1000$】 \n══════════════", Pugan[Client]);
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回RPG选单");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }	
    else if (Jenwu[Client] == 2)
    {
        Format(line, sizeof(line), "═══【任务】生存能力═══ \n【任务要求: 击杀特殊感染者!】 \n【奖励: 3000EXP经验值】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【Smoker10个】〤斩:%d个 【Boomer10个】〤斩:%d个 \n【Hunter10个】〤斩:%d个 【Spitter10个】〤斩:%d个 \n【Jockey10个】〤斩:%d个 【Charger10个】〤斩:%d个 \n══════════════", TYangui[Client], TPangzi[Client], TLieshou[Client], TKoushui[Client], THouzhi[Client], TXiaoniu[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回RPG选单");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
    else if (Jenwu[Client] == 3)
    {
        Format(line, sizeof(line), "═══【任务】最终生还═══ \n【任务要求: 感染者克星!】 \n【奖励: 金钱5000$】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【普通感染者500个】〤斩:%d个 \n【特殊感染者30个】〤斩:%d个 \n══════════════", Pugan[Client], Tegan[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回RPG选单");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (Jenwu[Client] == 4)
    {
        Format(line, sizeof(line), "═══【任务】贵族荣耀═══ \n【任务要求: 击杀BOSS!】 \n【奖励: 金钱10000$, 随机古代卷轴】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【Tank20个】〤斩:%d个 \n══════════════", TDaxinxin[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回RPG选单");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	
    SendPanelToClient(menu, Client, MenuHandler_Shizhesa, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuHandler_Shizhesa(Handle:menu, MenuAction:action, Client, param)
{
    if (action == MenuAction_Select) 
    {
        switch (param)
        {
	        case 1: RENWUWAN(Client);	
            case 2: RENWUQI(Client);	
            case 3: MenuFunc_RPG(Client);			
        }
    }
}
public RENWUWAN(Client)
{	
    if(Jenwu[Client] == 1)
    {
        if(Pugan[Client] >= 300)
        {
            Cash[Client] += 1000;
            Pugan[Client] = 0;
            Jenwu[Client] = 0;
            Renwu[Client] = 0;
            CPrintToChat(Client, "\x03【任务】完成任务,您获得了金钱1000$!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 杀出道路!", Client);
        } else CPrintToChat(Client, "\x03【任务】你没达到所需要求!");	
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 2)
    {
        if(TYangui[Client] >= 10 && TPangzi[Client] >= 10 && TLieshou[Client] >= 10 && TKoushui[Client] >= 10 && THouzhi[Client] >= 10 && TXiaoniu[Client] >= 10)
        {
            EXP[Client] += 3000;
            TYangui[Client] = 0;
            TPangzi[Client] = 0;
            TLieshou[Client] = 0;
            TKoushui[Client] = 0;
            THouzhi[Client] = 0;
            TXiaoniu[Client] = 0;
            Jenwu[Client] = 0;
            Renwu[Client] = 0;
            CPrintToChat(Client, "\x03【任务】完成任务,您获得了3000EXP经验值!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 生存能力!", Client);			
        } else CPrintToChat(Client, "\x03【任务】你没达到所需要求!");	
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 3)
    {
        if(Pugan[Client] >= 500 && Tegan[Client] >= 30)
        {
            Cash[Client] += 5000;
            Pugan[Client] = 0;
            Tegan[Client] = 0;
            Jenwu[Client] = 0;
            Renwu[Client] = 0;
            CPrintToChat(Client, "\x03【任务】完成任务,您获得了金钱5000$!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 最终生还!", Client);			
        } else CPrintToChat(Client, "\x03【任务】你没达到所需要求!");	
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 4)
    {
        if(TDaxinxin[Client] >= 20)
        {
            Cash[Client] += 10000;
            PlayerSignXHItem(Client);
            TDaxinxin[Client] = 0;
            Jenwu[Client] = 0;
            Renwu[Client] = 0;
            CPrintToChat(Client, "\x03【任务】完成任务,您获得了金钱5000$和随机古代卷轴!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 贵族荣耀!", Client);			
        } else CPrintToChat(Client, "\x03【任务】你没达到所需要求!");	
    } MenuFunc_RPG(Client);
}	
public RENWUQI(Client)
{	
    if(Jenwu[Client] == 1)
    {
        Pugan[Client] = 0;
        Jenwu[Client] = 0;
        Renwu[Client] = 0;
        CPrintToChat(Client, "\x03【任务】你放弃了任务!");
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 2)
    {
        TYangui[Client] = 0;
        TPangzi[Client] = 0;
        TLieshou[Client] = 0;
        TKoushui[Client] = 0;
        THouzhi[Client] = 0;
        TXiaoniu[Client] = 0;
        Jenwu[Client] = 0;
        Renwu[Client] = 0;
        CPrintToChat(Client, "\x03【任务】你放弃了任务!");
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 3)
    {
        Pugan[Client] = 0;
        Tegan[Client] = 0;
        Jenwu[Client] = 0;
        Renwu[Client] = 0;
        CPrintToChat(Client, "\x03【任务】你放弃了任务!");
    } MenuFunc_RPG(Client);
    if(Jenwu[Client] == 4)
    {
        Pugan[Client] = 0;
        Tegan[Client] = 0;
        Jenwu[Client] = 0;
        Renwu[Client] = 0;
        CPrintToChat(Client, "\x03【任务】你放弃了任务!");
    } MenuFunc_RPG(Client);
}

/* 查看属性 */
public Action:Menu_ViewSkill(Client, args)
{
	MenuFunc_RPG_Learn(Client);
	return Plugin_Handled;
}

/* 娱乐功能 */
public MenuFunc_RPG_Learn(Client)
{		
	new Handle:menu = CreateMenu(MenuHandler_RPG_Learn);

	decl String:line[128];
	Format(line, sizeof(line), "丨称号丨永久装备丨巫师药水丨变身丨赌城 \n快捷键:[M键]");
	SetMenuTitle(menu, line);
	
	AddMenuItem(menu, "iteam0", "称号系统");
	//AddMenuItem(menu, "iteam1", "活动[春节/只能做一次]");
	//AddMenuItem(menu, "iteam2", "兑换夏季套装[恢复装备]");
	AddMenuItem(menu, "iteam1", "永久装备");
	Format(line, sizeof(line), "巫师冶炼药水(拥有的巫师冶炼药水:%d)", Shitou[Client]);
	AddMenuItem(menu, "iteam2", line);
	AddMenuItem(menu, "iteam3", "购买巫师冶炼药水");
	AddMenuItem(menu, "iteam4", "远古圣石(圣石,在套套商城购买)");
	AddMenuItem(menu, "iteam5", "超级变身(打发寂寞)");
	AddMenuItem(menu, "iteam6", "拉斯赌城(小赌益心,大赌伤财)");

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public MenuHandler_RPG_Learn(Handle:menu, MenuAction:action, Client, IteamNum)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;

	if (action == MenuAction_Select) {
		switch (IteamNum)
		{
			case 0: MenuFunc_RYCH(Client);	//称号
			/*
			case 1:
			{
                if(HDZT[Client] == 0)
                {
                    MenuFunc_HD(Client);
                }
                if(HDZT[Client] == 1)
                {
                    MenuFunc_HDRW(Client);
                }				
            } //活动
			*/
			//case 2: MenuFunc_cg(Client); //兑换夏季套装
			case 1: MenuFunc_VIPSC(Client); //购买永久装备
			case 2: MenuFunc_Qianghua(Client); //巫师冶炼药水[枪械强化]
			case 3: MenuFunc_Eqgou(Client); //购买巫师冶炼药水[枪械强化]
			case 4: MenuFunc_TSDJBB(Client); 				//远古圣石
			case 5: MenuFunc_VIPplayer2(Client);  //超级变身
			case 6: MenuFunc_LotteryCasino(Client);         //赌博抽奖
		//	case 8: MenuFunc_GetZYTZ(Client);		//职业套装
//			case 7: MenuFunc_BJTY(Client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (IteamNum == MenuCancel_ExitBack)
			MenuFunc_RPG(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}


public  Action:MenuFunc_zdjq(Client)//自动机枪
{         		
	if(VIP[Client] >= 0)    
	{       		
		CheatCommand(Client, "sm_mg", "CmdMachineGun");     
		CPrintToChat(Client, "\x03[系统]\04%N成功获得自动机枪[一关只能使用一次]!", Client);	    
	} else CPrintToChat(Client, "{green}【提示】此功能是注册玩家的福利!");
}	



/*
public Action:MenuFunc_cg(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【兑换夏季套装】\n拥有的兑换卷:%d个", DHJ[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "提示:兑换夏季套装");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "永久夏季套装[需要2个兑换券]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "30天夏季套装[需要1个兑换券]");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_dhjjp, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_dhjjp(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: dhj_dj(Client);    //等级
			case 2: dhj_dja(Client);    //等级
		}
	}
}

public dhj_dj(Client)
{   
	if(DHJ[Client] >= 2)    
	{       
		DHJ[Client] -= 2;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"4\" \"999999\"", Client);        	
		CPrintToChat(Client, "\x03【提示】你成功兑换永久春哥!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}

public dhj_dja(Client)
{   
	if(DHJ[Client] >= 1)    
	{       
		DHJ[Client] -= 1;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"4\" \"30\"", Client);        	
		CPrintToChat(Client, "\x03【提示】你成功兑换30天春哥!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}




兑换卷奖品
public Action:MenuFunc_dhj(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【兑换活动奖品】\n拥有的兑换卷:%d个", Dhj[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "提示:请兑换活动对应的奖品,重复购买时间不会增加！");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "大于100级[1兑换卷/如果觉得等级高就NB,那你就错了.]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "300W金钱[1兑换卷/小于7百万才可兑换]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "2000点卷[1兑换卷/小于2000点卷才可兑换]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "霸王血铠7天[1兑换卷/2转以上]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "黄金会员7天[1兑换卷/2转以上]");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_dhjjp, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_dhjjp(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: dhj_dj(Client);    //等级
			case 2:
			{
                if(Cash[Client] <= 7000000)
                {
                    dhj_jq(Client);    //金钱
                } else CPrintToChat(Client, "\x05【提示】你只能兑换一次(小于7百万才可兑换)!");
			}
			case 3:
			{
                if(Qcash[Client] <= 2000)
                {
                    dhj_byt(Client);    //点卷
                } else CPrintToChat(Client, "\x05【提示】你只能兑换一次(小于2000点卷才可兑换)!");
			}
			case 4:
			{
                if(NewLifeCount[Client] >= 2)
                {
                    dhj_tz(Client);    //套装
                } else CPrintToChat(Client, "\x05【提示】你没有2转,不能兑换此奖品!");
			}
			case 5:
			{
                if(VIP[Client] >= 2)
                {
                    dhj_hy(Client);    //黄金会员
                } else CPrintToChat(Client, "\x05【提示】你已经是黄金会员,再兑换天数变为7天!");
			}
		}
	}
}

public dhj_dj(Client)
{   
	if(Dhj[Client] >= 1)    
	{       
		Dhj[Client] -= 1;		
		ServerCommand("sm_givelv_114 \"%N\" \"50\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功兑换50等级!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}

public dhj_jq(Client)
{   
	if(Dhj[Client] >= 1)    
	{       
		Dhj[Client] -= 1;		
		ServerCommand("sm_givecash_994 \"%N\" \"3000000\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功兑换300W金钱!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}

public dhj_byt(Client)
{   
	if(Dhj[Client] >= 1)    
	{       
		Dhj[Client] -= 1;		
		ServerCommand("sm_giveQcash_451 \"%N\" \"2000\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功兑换2000点卷!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}

public dhj_tz(Client)
{   
	if(Dhj[Client] >= 1)    
	{       
		Dhj[Client] -= 1;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"50\" \"7\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功兑换霸王血铠!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}

public dhj_hy(Client)
{   
	if(Dhj[Client] >= 1)    
	{       
		Dhj[Client] -= 1;		
		ServerCommand("sm_setvip_845 \"%N\" \"2\" \"7\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功兑换黄金会员7天!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的兑换卷!");
}
*/


/*
public ZHSYDYD(Client)
{   
   if(IsPlayerAlive(Client))	
	{
	  if(TSDJ5[Client] >= 1)    
	  {       
		    TSDJ5[Client] -= 1;		
		    CheatCommand(Client, "warp_all_survivors_here", "");           
		    CPrintToChatAll("\x03[系统]\04%N使用了\x04召唤\x05所有队友道具使所有队友回到自己身边！", Client);	    
	    } else CPrintToChat(Client, "\x03【提示】你没有这个道具!");
    } else CPrintToChat(Client, "{green}【道具】死亡状态下无法使用!");
}
*/

//使用远古圣石
public Action:MenuFunc_TSDJBB(Client)
{
	new Handle:menu = CreatePanel();
	  
	decl String:line[256];   
	Format(line, sizeof (line), "═══远古圣石═══");    
	SetPanelTitle(menu, line); 
	Format(line, sizeof (line), "════圣石在点卷商城里购买════");
	DrawPanelText(menu, line);
	
	Format(line, sizeof (line), "使用Tank召唤圣石: %d颗", TSDJ1[Client]);   
	DrawPanelItem(menu, line);	
	
	Format(line, sizeof (line), "使用Tank小弟召唤圣石: %d颗", TSDJ2[Client]);  
	DrawPanelItem(menu, line);
	
	Format(line, sizeof (line), "使用回到起点圣石: %d颗", TSDJ3[Client]);  
	DrawPanelItem(menu, line); 
	
	Format(line, sizeof (line), "远古圣石说明");  
	DrawPanelItem(menu, line); 
	DrawPanelItem(menu, "返回");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_TSDJBB, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_TSDJBB(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:CSTOUP(Client);
            case 2:CSJIAP(Client);
            case 3:CSJIAPS(Client);
			case 4: MenuFunc_LLXTK(Client);
			case 5: MenuFunc_RPG_Learn(Client);
		}
	}
}

public Action:MenuFunc_TSDJ(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买圣石】\n拥有的金钱:%d个", Cash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "提示:土豪请购买!Y(^_^)Y");
	DrawPanelText(menu, line);

	Format(line, sizeof(line), "购买召唤Tank圣石1颗[[400点卷]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "购买召唤Tank小弟圣石1颗[[400点卷]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "购买回到起点圣石1颗[400点卷]");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_TSDJ, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_TSDJ(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			//case 1: VIPJPJZ(Client);
			case 1: VIPJPXZMS(Client);
			case 2: VIPJPXDMS(Client)
			case 3: VIPJPXDMSD(Client)
			case 4: MenuFunc_TSDJBB(Client);
		}
	}
}

public VIPJPXZMS(Client)//召唤坦克圣石
{   
	if(Qcash[Client] >= 400)    
	{       
		Qcash[Client] -= 400;		
		TSDJ1[Client] += 1;					
		CPrintToChat(Client, "\x03【系统】你成功购买了1颗召唤坦克圣石 当前点卷%d!", Cash[Client]);	  CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临 ^_^ !");		   
	} else CPrintToChat(Client, "\x05【提示】你没有足够的套套,请联系撸主!");
	MenuFunc_TSDJ(Client)
}
public VIPJPXDMS(Client)//召唤坦克小弟圣石
{   
	if(Qcash[Client] >= 400)    
	{       
		Qcash[Client] -= 400;		
		TSDJ2[Client] += 1;			
		CPrintToChat(Client, "\x03【系统】你成功购买了1颗挑战坦克小弟圣石 当前点卷%d!", Cash[Client]);	   CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临 ^_^ !");		
	} else CPrintToChat(Client, "\x05【提示】你没有足够的套套,请联系撸主!");
	MenuFunc_TSDJ(Client)
}
public VIPJPXDMSD(Client)//回到起点圣石
{   
	if(Qcash[Client] >= 400)    
	{       
		Qcash[Client] -= 400;		
		TSDJ3[Client] += 1;	
		CPrintToChat(Client, "\x03【系统】你成功购买了1颗回到起点圣石 当前点卷%d!", Cash[Client]);	  CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临 ^_^ !");		
	} else CPrintToChat(Client, "\x05【提示】你没有足够的套套,请联系撸主!");
	MenuFunc_TSDJ(Client)
}


public CSTOUP(Client)
{   
     if(IsPlayerAlive(Client))	
	 {	
	    if(TSDJ1[Client] >= 1)    
	    {       
		    TSDJ1[Client] -= 1;		
		    CheatCommand(Client, "z_spawn", "tank auto");           
		    CPrintToChatAll("\x03[远古圣石]\04%N召唤\x04了\x051只Tank", Client);	    
	    } else CPrintToChat(Client, "\x03【远古圣石】你没有这个圣石!");
	} else CPrintToChat(Client, "{green}【远古圣石】死亡状态下无法使用!");
}
public CSJIAP(Client)
{   
    if(IsPlayerAlive(Client))	
	{
	   if(TSDJ2[Client] >= 1)    
	   {       
		    TSDJ2[Client] -= 1;		
		    CheatCommand(Client, "director_force_panic_event", "");     
		    CPrintToChatAll("\x03[远古圣石]\04%N召唤\x04了\x05Tank的小弟!", Client);	    
	    } else CPrintToChat(Client, "\x03【远古圣石】你没有这个圣石!");
	} else CPrintToChat(Client, "{green}【远古圣石】死亡状态下无法使用!");
}
public CSJIAPS(Client)
{   
    if(IsPlayerAlive(Client))	
	{
	   if(TSDJ3[Client] >= 1)    
	   {       
		    TSDJ3[Client] -= 1;		
		    CheatCommand(Client, "warp_to_start_area", "");     
		    CPrintToChatAll("\x03[远古圣石]\04%N使用了\x04回到起点力量\x05自己回到起点!", Client);	    
	    } else CPrintToChat(Client, "\x03【远古圣石】你没有这个圣石!");
    } else CPrintToChat(Client, "{green}【远古圣石】死亡状态下无法使用!");
}

//远古圣石说明
public Action:MenuFunc_LLXTK(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "远古圣石说明:\n直接按相应按键使用即可.");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_LLXTK, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_LLXTK(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_TSDJBB(Client); //使用远古圣石
		}
	}
}

/* 其他面板 */
public MenuFunc_RPG_Other(Client)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;
		
	new Handle:menu = CreateMenu(MenuHandler_RPG_Other);
	decl String:job[32], String:m_viptype[32];
	if(JD[Client] == 0)			Format(job, sizeof(job), "未转职");
	else if(JD[Client] == 1)	Format(job, sizeof(job), "精灵");
	else if(JD[Client] == 2)	Format(job, sizeof(job), "士兵");
	else if(JD[Client] == 3)	Format(job, sizeof(job), "生物专家");
	else if(JD[Client] == 4)	Format(job, sizeof(job), "医生");
	else if(JD[Client] == 5)	Format(job, sizeof(job), "法师");
	else if(JD[Client] == 6)	Format(job, sizeof(job), "弹药专家");
	else if(JD[Client] == 7)	Format(job, sizeof(job), "雷神");
	
	if (VIP[Client] <= 0)
		Format(m_viptype, sizeof(m_viptype), "你的身份:普通VIP");
	else if (VIP[Client] == 1)
		Format(m_viptype, sizeof(m_viptype), "你的身份:白金VIP1");
	else if (VIP[Client] == 2)
		Format(m_viptype, sizeof(m_viptype), "你的身份:黄金VIP2");
	else if (VIP[Client] == 3)
		Format(m_viptype, sizeof(m_viptype), "你的身份:水晶VIP3");
	else if (VIP[Client] == 4)
		Format(m_viptype, sizeof(m_viptype), "你的身份:至尊VIP4");
	
	decl String:line[256];
	Format(line, sizeof(line),
	"%s 大过:%d次 转生:%d \n等级:Lv.%d 金钱:$%d 职业:%s \n经验:%d/%d MP:%d/%d 点卷:%d个 \n力量:%d 敏捷:%d 生命:%d 耐力:%d 智力:%d",
		m_viptype, KTCount[Client], NewLifeCount[Client], Lv[Client], Cash[Client], job,
		EXP[Client], GetConVarInt(LvUpExpRate)*(Lv[Client]+1), MP[Client], MaxMP[Client], Qcash[Client],
		Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
	SetMenuTitle(menu, line);
	
	AddMenuItem(menu, "iteam0", "玩家面板");
	AddMenuItem(menu, "iteam1", "游戏排名");
	AddMenuItem(menu, "iteam2", "游戏公告");
	AddMenuItem(menu, "iteam3", "每日签到");
	AddMenuItem(menu, "iteam4", "新手注册");
	AddMenuItem(menu, "iteam5", "加入游戏");
	AddMenuItem(menu, "iteam6", "手动存档");
	AddMenuItem(menu, "iteam7", "升级礼包");
	AddMenuItem(menu, "iteam8", "绑定按键");
//	AddMenuItem(menu, "iteam7", "基础补给");

	
	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public MenuHandler_RPG_Other(Handle:menu, MenuAction:action, Client, IteamNum)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;

	if (action == MenuAction_Select) {
		switch (IteamNum)
		{
			case 0: MenuFunc_TeamInfo(Client);	//玩家面板
			case 1: MenuFunc_Rank(Client);		//游戏排名
			case 2: Menu_GameAnnouncement(Client);		//游戏公告
			case 3: MenuFunc_Qiandao(Client);		//每日签到
			case 4: MenuFunc_Xsbz(Client);	       //新手注册
			case 5: JoinGameTeam(Client);			//加入游戏
			case 6: MenuFunc_RPG_Other(Client);		//手动存档
//			case 7: MenuFunc_Bugei(Client);
			case 7: MenuFunc_Shenbao(Client);    //升级礼包
			case 8: MenuFunc_BindKeys(Client);		//绑定按键
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (IteamNum == MenuCancel_ExitBack)
			MenuFunc_RPG(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

//巫师冶炼药水[枪械强化]
public Action:MenuFunc_Qianghua(Client)
{   
	new Handle:menu = CreatePanel();
	    
	decl String:line[1024];	   
	Format(line, sizeof(line),
	"═══【赐予魔力】现拥有巫师冶炼药水:%d个═══ \n魔力等级:LV.%d \n枪械攻击力:+%d \n成功升级率:%d \n失败不变率:%d \n失败降级率:%d", Shitou[Client], Shilv[Client], Qstr[Client], Qgl[Client], Sbl[Client], Jbl[Client]);   
	SetPanelTitle(menu, line);
	if(Qgl[Client] == 90)
	{       
		Format(line, sizeof(line),	    
		"═══【赐予魔力】现拥有巫师冶炼药水:%d个═══ \n魔力等级:LV.%d \n枪械攻击力:+%d \n成功升级率:%d \n失败不变率:%d \n失败降级率:0", Shitou[Client], Shilv[Client], Qstr[Client], Qgl[Client], Sbl[Client]);   	    
		SetPanelTitle(menu, line);	
	}	
	Format(line, sizeof(line), "说明: 赐予枪械魔力,让自身枪械攻击力提高!");    
	DrawPanelText(menu, line);	
   
	Format(line, sizeof(line), "开始赐予魔力");    
	DrawPanelItem(menu, line);   
	DrawPanelItem(menu, "放弃赐予魔力", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Qianghua, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}
public MenuHandler_Qianghua(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: KAIQIANG(Client);
		}
	}
}
public KAIQIANG(Client)
{   
	if(Shitou[Client] > 0)   
	{         
		if(Qgl[Client] == 100)   	    
		{	            
			Shitou[Client]--;            
			Qstr[Client] += DMG_LVD;            
			Shilv[Client] ++;			
			CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");        
		}		
		else if(Qgl[Client] == 90)   	    
		{			    
			new nima = GetRandomInt(1, 10);
			
			if(nima == 2 && nima <= 10)
			{               
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;                
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");
			}           
			else if(nima == 1)           
			{			    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");           
			} 			        
		}			    		
		else if(Qgl[Client] == 80)   	    
		{			    
			new xima = GetRandomInt(1, 10);			
			
			if(xima == 3 && xima <= 10)			
			{              
				Shitou[Client]--;              
				Qstr[Client] += DMG_LVD;              
				Shilv[Client] ++;		    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}           
			else if(xima == 1)        
			{		    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");           
			}           
			else if(xima == 2)        
			{			    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;               
				Shilv[Client] --;		    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");          
			} 			       
		}
		else if(Qgl[Client] == 70)   	    
		{			    
			new zima = GetRandomInt(1, 10);			
			
			if(zima == 4 && zima <= 10)			
			{               
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;               
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}          
			else if(zima == 1 && zima <= 2)          
			{			    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");            
			}           
			else if(zima == 3)            
			{			    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;              
				Shilv[Client] --;			    
				CPrintToChat(Client, "{green}【冶炼药水】你赐予魔力失败, 失去一级!");            
			} 			       
		}
		else if(Qgl[Client] == 60)   	    
		{			    
			new aima = GetRandomInt(1, 10);
						
			if(aima == 5 && aima <= 10)			
			{              
				Shitou[Client]--;                
				Qstr[Client] += DMG_LVD;               
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}           
			else if(aima == 1 && aima <= 2)           
			{			    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");          
			}            
			else if(aima == 3 && aima <= 4)           
			{		    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;                
				Shilv[Client] --;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");           
			} 			       
		}
		else if(Qgl[Client] == 50)   	    
		{		    
			new wima = GetRandomInt(1, 10);
					
			if(wima == 6 && wima <= 10)
			{               
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;               
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}           
			else if(wima == 1 && wima <= 3)          
			{			    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");
            
			}          
			else if(wima == 4 && wima <= 5)          
			{			    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;               
				Shilv[Client] --;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");           
			} 			       
		}
		else if(Qgl[Client] == 40)   	    
		{			    
			new sima = GetRandomInt(1, 10);
						
			if(sima == 7 && sima <= 10)			
			{               
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;              
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}         
			else if(sima == 1 && sima <= 3)          
			{			    
				Shitou[Client]--;		    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");           
			}           
			else if(sima == 4 && sima <= 6)         
			{			    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;               
				Shilv[Client] --;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");          
			} 			      
		}
		else if(Qgl[Client] == 30)   	    
		{			    
			new eima = GetRandomInt(1, 10);
						
			if(eima == 8 && eima <= 10)			
			{              
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;              
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}            
			else if(eima == 1 && eima <= 4)          
			{		    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");          
			}          
			else if(eima == 5 && eima <= 7)          
			{			    
				Shitou[Client]--;              
				Qstr[Client] -= DMG_LVD;              
				Shilv[Client] --;		    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");         
			} 			      
		}
		else if(Qgl[Client] == 20)   	    
		{			    
			new dima = GetRandomInt(1, 10);
						
			if(dima == 9 && dima <= 10)			
			{                
				Shitou[Client]--;                
				Qstr[Client] += DMG_LVD;                
				Shilv[Client] ++;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}         
			else if(dima == 1 && dima <= 4)           
			{		    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");           
			}           
			else if(dima == 5 && dima <= 8)           
			{			    
				Shitou[Client]--;              
				Qstr[Client] -= DMG_LVD;              
				Shilv[Client] --;		    
				CPrintToChat(Client, "{green}【冶炼药水】你赐予魔力失败, 失去一级!");            
			} 			        
		}
		else if(Qgl[Client] == 10)   	    
		{			    
			new cima = GetRandomInt(1, 10);
						
			if(cima == 1)			
			{              
				Shitou[Client]--;               
				Qstr[Client] += DMG_LVD;              
				Shilv[Client] ++;		    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械成功赐予魔力!");			
			}           
			else if(cima == 2 && cima <= 6)           
			{			    
				Shitou[Client]--;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 等级不变!");            
			}          
			else if(cima == 7 && cima <= 10)          
			{			    
				Shitou[Client]--;               
				Qstr[Client] -= DMG_LVD;               
				Shilv[Client] --;			    
				CPrintToChat(Client, "{green}【冶炼药水】你的枪械赐予魔力失败, 失去一级!");         
			} 			       
		}		
		else if(Qgl[Client] <= 0)   	    		
		{			    
			CPrintToChat(Client, "【提示】你的枪械魔力已到顶峰!"); 			        
		}
	} else CPrintToChat(Client, "【提示】你没有巫师冶炼药水无法进行赐予魔力!");
	MenuFunc_Qianghua(Client);
}	

//升级礼包
public Action:MenuFunc_Shenbao(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "═══【升级礼包:%d份】═══", Libao[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:每升10级可以获得一份。等级<=100级");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "打开礼包");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Shenbao, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Shenbao(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: DAKAILI(Client);
		}
	}
}
public DAKAILI(Client)
{   
	if(Libao[Client] > 0)   
	{        
		Libao[Client]--;       
		new jinwuqi = GetRandomInt(1, 10);		
        		
		switch (jinwuqi)       
		{           
			case 1:           
			{               
				Cash[Client] += 10000;               
				CPrintToChatAll("\x05【升级礼包】恭喜玩家%N打开获得10000$!", Client);           
			}
			case 2:           
			{               
	         	PlayerItem[Client][ITEM_XH][0] += 1;     
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);         
			}
			case 3:           
			{               
	         	PlayerItem[Client][ITEM_XH][2] += 1;     
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}			
			case 4:           
			{               
	         	PlayerItem[Client][ITEM_XH][3] += 1;        
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 5:           
			{               
	         	PlayerItem[Client][ITEM_XH][4] += 1;         
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}
			case 6:           
			{               
	         	PlayerItem[Client][ITEM_XH][5] += 1;         
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}				
			case 7:           
			{               
	         	PlayerItem[Client][ITEM_XH][6] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 8:           
			{               
	         	PlayerItem[Client][ITEM_XH][7] += 1;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 9:           
			{               
	         	PlayerItem[Client][ITEM_XH][8] += 1;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 10:           
			{               
	         	PlayerItem[Client][ITEM_XH][5] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 11:           
			{               
	         	PlayerItem[Client][ITEM_XH][2] += 1;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 12:           
			{               
	         	PlayerItem[Client][ITEM_ZB][13] += 3;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得哲理之石!", Client);        
			}	
			case 13:           
			{               
	         	PlayerItem[Client][ITEM_ZB][14] += 4;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得精神之貌!", Client);        
			}	
			case 14:           
			{               
	         	PlayerItem[Client][ITEM_ZB][15] += 7;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得自然之力!", Client);        
			}	
			case 15:           
			{               
	         	PlayerItem[Client][ITEM_ZB][16] += 6;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得多兰之盾!", Client);        
			}	
			case 16:           
			{               
	         	PlayerItem[Client][ITEM_ZB][18] += 2;    
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机装备!", Client);        
			}	
			case 17:           
			{               
	         	PlayerItem[Client][ITEM_ZB][21] += 7;    
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机装备!", Client);        
			}
			
			case 18:           
			{               
	         	PlayerItem[Client][ITEM_ZB][26] += 6;        
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机装备!", Client);        
			}	
			case 19:           
			{               
	         	PlayerItem[Client][ITEM_ZB][31] += 5;        
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机装备!", Client);        
			}	
			case 20:
			{               
				Qcash[Client] += 1000;               
				CPrintToChatAll("\x05【升级礼包】恭喜玩家%N打开获得点卷1000个!", Client);           
			}
			case 21:           
			{               
	         	PlayerItem[Client][ITEM_ZB][1] += 13;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得高级巫师腰带!", Client);        
			}			
			case 22:           
			{               
	         	PlayerItem[Client][ITEM_XH][0] += 1;    
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 23:           
			{               
	         	PlayerItem[Client][ITEM_XH][1] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}
			case 24:           
			{               
	         	PlayerItem[Client][ITEM_XH][2] += 1;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}				
			case 25:           
			{               
	         	PlayerItem[Client][ITEM_XH][3] += 1;  
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 26:           
			{               
	         	PlayerItem[Client][ITEM_XH][4] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 27:           
			{               
	         	PlayerItem[Client][ITEM_XH][5] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 28:           
			{               
	         	PlayerItem[Client][ITEM_XH][6] += 1;      
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);        
			}	
			case 29:           
			{               
	         	PlayerItem[Client][ITEM_XH][7] += 1;       
	         	CPrintToChat(Client, "\x05【升级礼包】恭喜玩家%N打开获得随机古代卷轴!", Client);	
			}	
		}
	} else CPrintToChat(Client, "\x05【提示】你没有升级礼包!");
}	


//每日签到
public Action:MenuFunc_Qiandao(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "═══每日签到当前已经积累签到%d天/15天=========\n积累3天可获得潘多拉宝盒1个 积累7天可获得古代玄鸟之翼7天 \n积累10天可获得究级古代火凤凰羽毛7天 积累15天可获得7天的狂徒铠甲", everyday1[Client]);
    SetPanelTitle(menu, line);

    Format(line, sizeof(line), "确认签到");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "连续签到奖励领取");
    DrawPanelItem(menu, line);	
    DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Qiandao, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Qiandao(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: PlayerSignToday(Client);
			case 2: LXQDJL(Client);
		}
	}
}

new bool:SaveLoadCD[MAXPLAYERS+1];

public Action:LXQDJL(Client)
{   
	new Handle:menu = CreatePanel();
		   
	decl String:line[1024];   
	Format(line, sizeof(line), "*****签到奖励领取****");   
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "═══领取1个潘多拉宝盒(消耗3天签到积累)═══");   
	DrawPanelItem(menu, line);     
	Format(line, sizeof(line), "═══领取7天古代玄鸟之翼(消耗7天签到积累)═══");   
	DrawPanelItem(menu, line);	
	Format(line, sizeof(line), "═══领取7天究级古代火凤凰羽毛(消耗10天签到积累)═══");   
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "═══领取7天狂徒铠甲(消耗15天签到积累)═══");   
	DrawPanelItem(menu, line);
   
	DrawPanelItem(menu, "返回签到菜单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
 
	SendPanelToClient(menu, Client, MenuHandler_LXQDJL, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}
public MenuHandler_LXQDJL(Handle:menu, MenuAction:action, Client, param)
{
    if (action == MenuAction_Select) 
    {
        switch (param)
        {	        
			case 1:  QDJL1(Client);	                     
			case 2: QDJL2(Client); 			
			case 3: QDJL3(Client); 
                     case 4: QDJL4(Client);   			
			case 5: MenuFunc_Qiandao(Client);       
		}   
	}
}
public QDJL1(Client)
{   
	if(everyday1[Client] >= 3)    
	{       
		everyday1[Client] -= 3;		
		Eqbox[Client] ++;		
		CPrintToChat(Client,"\x03[系统]\04你\x04领取了\x051个潘多拉宝盒!");   	
	} else CPrintToChat(Client, "\x05【提示】你没有积累足够的签到次数");
}

public QDJL2(Client)//项链
{   
	if(everyday1[Client] >= 7)    
	{       
		everyday1[Client] -= 7;		
	        SetZBItemTime(Client, 11, 7, false);  		
		CPrintToChat(Client,"\x03[系统]\04你\x04领取了\x057天的古代玄鸟之翼");  	
	} else CPrintToChat(Client, "\x05【提示】你没有积累足够的签到次数!");
}

public QDJL3(Client)//项链
{   
	if(everyday1[Client] >= 10)    
	{       
		everyday1[Client] -= 10;		
		SetZBItemTime(Client, 21, 7, false);  	
		CPrintToChat(Client,"\x03[系统]\04你\x04领取了\x057天的究级古代火凤凰羽毛!");  	
	} else CPrintToChat(Client, "\x05【提示】你没有积累足够的签到次数!");
}

public QDJL4(Client)//项链
{   
	if(everyday1[Client] >= 15)    
	{       
		everyday1[Client] -= 15;		
		SetZBItemTime(Client, 52, 7, false);  	
		CPrintToChat(Client,"\x03[系统]\04你\x04领取了\x057天的狂徒铠甲");  
	} else CPrintToChat(Client, "\x05【提示】你没有积累足够的签到次数!");
}

/* 手动存档 */
public PlayerManualSave(Client)
{
	if (IsValidPlayer(Client, false))
	{
		if (!IsPasswordConfirm[Client])
		{
			CPrintToChat(Client, "\x03[系统] {red}请先登录游戏后在使用该功能!");
			return;
		}
		
		if (!SaveLoadCD[Client])
		{
			ClientSaveToFileSave(Client);
			ClientSaveToFileLoad(Client);
			CPrintToChat(Client, "\x03[系统] {red}你的存档已保存,下次保存时可以使用快捷键\x05[F12]{red}快速保存!");
			SaveLoadCD[Client] = true;
			CreateTimer(300.0, Timer_PlayerSaveCD, Client);
		}
		else
			CPrintToChat(Client, "\x03[系统] {red}存档功能冷却中,请稍后在尝试!");
	}
}

//手动存档_冷却
public Action:Timer_PlayerSaveCD(Handle:timer, any:Client)
{
	SaveLoadCD[Client] = false;
	KillTimer(timer);
}

/* 加入游戏 */
public JoinGameTeam(Client)
{
	if (IsValidPlayer(Client) && !IsFakeClient(Client))
	{
		if (GetClientTeam(Client) != 2)
			ChangeTeam(Client, 2);
		else
			PrintHintText(Client, "你已经在游戏中,无须再加入!");
	}
}

//属性点总菜单 
public Action:MenuFunc_AddAllStatus(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	Format(line, sizeof(line), "属性点剩余: %d", StatusPoint[Client]);
	SetPanelTitle(menu, line);

	DrawPanelItem(menu, "基础属性");
	//DrawPanelItem(menu, "暴击属性");

	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_AddAllStatus, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAllStatus(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:	MenuFunc_AddStatus(Client);
			//case 2:	MenuFunc_AddCrits(Client);
		}
		
		if (param == 2)
			MenuFunc_RPG_Learn(Client);	//转职加点
	}
}

// 暴击属性菜单 
public Action:MenuFunc_AddCrits(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	Format(line, sizeof(line), "属性点剩余: %d", StatusPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "暴击几率 (%d/%d 指令: !cts 数量)", Crits[Client], Limit_Crits);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高暴击几率! 增加%.2f%%暴击几率", CritsEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "暴击最小伤害 (%d/%d 指令: !ctn 数量)", CritMin[Client], Limit_CritMin);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高暴击最小伤害! 附加武器伤害*%.2f%*2暴击最小伤害", CritMinEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "暴击最大伤害 (%d/%d 指令: !ctx 数量)", CritMax[Client], Limit_CritMax);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高暴击最大伤害! 附加武器伤害*%.2f%*2暴击最大伤害", CritMaxEffect[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_AddCrits, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddCrits(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(StatusPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_POINTS);
		else if (param >= 1 && param <= 3)
		{
			switch(param)
			{
				case 1:	AddCrits(Client, 0);
				case 2:	AddCritMin(Client, 0);
				case 3:	AddCritMax(Client, 0);
			}
			
		}
		
		if (param == 4)
			MenuFunc_AddAllStatus(Client);
		else
			MenuFunc_AddCrits(Client);
	}
}


/* 属性点菜单 */
public Action:MenuFunc_AddStatus(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	Format(line, sizeof(line), "属性点剩余: %d", StatusPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "力量 (%d/%d 指令: !str 数量)", Str[Client], Limit_Str);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高伤害! 增加%.2f%%伤害", StrEffect[Client] * 100.0);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "敏捷 (%d/%d 指令: !agi 数量)", Agi[Client], Limit_Agi);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高移动速度! 增加%.2f%%移动速度", AgiEffect[Client] * 100.0);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "生命 (%d/%d 指令: !hea 数量)", Health[Client], Limit_Health);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高生命最大值! 增加%.2f%%生命最大值", HealthEffect[Client] * 100.0);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "耐力 (%d/%d 指令: !end 数量)", Endurance[Client], Limit_Endurance);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "减少伤害!  减少%.2f%%伤害", EnduranceEffect[Client] * 100.0);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "智力 (%d/%d 指令: !int 数量)", Intelligence[Client], Limit_Intelligence);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "提高MP上限, 恢复速度及减少扣经! 每秒MP恢复: %d, MP上限: %d", IntelligenceEffect_IMP[Client], MaxMP[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_AddStatus, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddStatus(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(StatusPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_POINTS);  //如果属性小于0，提示你没属性点可使用
		else if (param >= 1 && param <= 5)
		{
			switch(param)
			{
				case 1:	AddStrength(Client, 0);
				case 2:	AddAgile(Client, 0);
				case 3:	AddHealth(Client, 0);
				case 4:	AddEndurance(Client, 0);
				case 5:	AddIntelligence(Client, 0);
			}
			MenuFunc_AddStatus(Client)
			
		}
		
		if (param == 6)
			MenuFunc_AddAllStatus(Client);
	}
}

/* 幸存者学习技能 */
public Action:MenuFunc_SurvivorSkill(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "幸存者技能 - 技能点剩余: %d", SkillPoint[Client]);
	SetPanelTitle(menu, line);

	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "[通用]治疗术 (等级: %d/%d 发动指令: !hl)", HealingLv[Client], LvLimit_Healing);
	else
		Format(line, sizeof(line), "[通用]高级治疗术 (等级: %d/%d 发动指令: !hl)", HealingLv[Client], LvLimit_Healing);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]地震术 (等级: %d/%d 发动指令: !dizhen)", EarthQuakeLv[Client], LvLimit_EarthQuake);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]召唤重机枪(Lv.%d / MP:5000)", HeavyGunLv[Client],LvLimit_HeavyGun);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]强化苏醒术 (等级: %d/%d 被动技能)", EndranceQualityLv[Client], LvLimit_EndranceQuality);
	DrawPanelItem(menu, line);
	if(JD[Client] == 1)
	{
		Format(line, sizeof(line), "[精灵]子弹制造术 (等级: %d/%d 发动指令: !am)", AmmoMakingLv[Client], LvLimit_AmmoMaking);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[精灵]射速加强术 (等级: %d/%d 发动指令: !fs)", FireSpeedLv[Client], LvLimit_FireSpeed);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[精灵]卫星炮术 (等级: %d/%d 发动指令: !sc)", SatelliteCannonLv[Client], LvLimit_SatelliteCannon);
		DrawPanelItem(menu, line);
		if (NewLifeCount[Client] >= 1)
			Format(line, sizeof(line), "[究极]核弹头"), DrawPanelItem(menu, line);
	} 
	else if(JD[Client] == 2)
	{
		Format(line, sizeof(line), "[士兵]攻防强化术 (等级: %d/%d 被动技能)", EnergyEnhanceLv[Client], LvLimit_EnergyEnhance);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[士兵]火焰极速 (等级: %d/%d 发动指令: !sp)", SprintLv[Client], LvLimit_Sprint);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[士兵]无限子弹 (等级: %d/%d 发动指令: !ia)", InfiniteAmmoLv[Client], LvLimit_InfiniteAmmo);
		DrawPanelItem(menu, line);
		if (NewLifeCount[Client] >= 1)
			Format(line, sizeof(line), "[究极]狂暴者模式"), DrawPanelItem(menu, line);
	} 
	else if(JD[Client] == 3)
	{
		Format(line, sizeof(line), "[生物专家]无敌术 (等级: %d/%d 发动指令: !bs)", BioShieldLv[Client], LvLimit_BioShield);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[生物专家]反伤术 (等级: %d/%d 发动指令: !dr)", DamageReflectLv[Client], LvLimit_DamageReflect);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[生物专家]近战嗜血术 (等级: %d/%d 发动指令: !ms)", MeleeSpeedLv[Client], LvLimit_MeleeSpeed);
		DrawPanelItem(menu, line);
		if (NewLifeCount[Client] >= 1)
		Format(line, sizeof(line), "[究极]潜能大爆发"), 
		DrawPanelItem(menu, line);
	} 
	else if(JD[Client] == 4)
	{
		Format(line, sizeof(line), "[医生]选择传送术 (等级: %d/%d 发动指令: !ts)", TeleportToSelectLv[Client], LvLimit_TeleportToSelect);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[医生]审判光球术 (等级: %d/%d 发动指令: !at)", AppointTeleportLv[Client], LvLimit_AppointTeleport);
		DrawPanelItem(menu, line);
		/*
		Format(line, sizeof(line), "[医生]心灵传送术 (等级: %d/%d 发动指令: !tt)", TeleportTeamLv[Client], LvLimit_TeleportTeam);
		DrawPanelItem(menu, line);
		*/
		Format(line, sizeof(line), "[医生]治疗光球术 (等级: %d/%d 发动指令: !hb)", HealingBallLv[Client], LvLimit_HealingBall);
		DrawPanelItem(menu, line);
		/*
		if (NewLifeCount[Client] >= 1)
			Format(line, sizeof(line), "[医生]全体召唤术"), DrawPanelItem(menu, line);
		*/
	} 
	else if(JD[Client] == 5)
	{
		Format(line, sizeof(line), "[魔法]火球术 (等级: %d/%d 发动指令: !fb)", FireBallLv[Client], LvLimit_FireBall);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[魔法]冰球术 (等级: %d/%d 发动指令: !ib)", IceBallLv[Client], LvLimit_IceBall);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[魔法]连锁闪电术 (等级: %d/%d 发动指令: !cl)", ChainLightningLv[Client], LvLimit_ChainLightning);
		DrawPanelItem(menu, line);
		if (NewLifeCount[Client] >= 1)
			Format(line, sizeof(line), "[究极]终结式暴雷"), DrawPanelItem(menu, line);
	}
	else if(JD[Client] == 6)
	{
		Format(line, sizeof(line), "[弹药]破碎弹 (等级: %d/%d 发动指令: !psd)", BrokenAmmoLv[Client], LvLimit_BrokenAmmo);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[弹药]吸血弹 (等级: %d/%d 发动指令: !xxd)", SuckBloodAmmoLv[Client], LvLimit_SuckBloodAmmo);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[弹药]区域爆破 (等级: %d/%d 发动指令: !qybp)", AreaBlastingLv[Client], LvLimit_AreaBlasting);
		DrawPanelItem(menu, line);
		if (NewLifeCount[Client] >= 1)
			Format(line, sizeof(line), "[究极]镭射激光炮"), DrawPanelItem(menu, line);
	}
	else if(JD[Client] == 7)
	{
		Format(line, sizeof(line), "[雷神]雷神弹药 (等级: %d/%d)", LZDLv[Client], LvLimit_LZDLv);
		DrawPanelItem(menu, line);
		//if (LZDLv[Client] >= 20)
		//{
		Format(line, sizeof(line), "[雷神]不熄光环 (等级: %d/%d 发动指令: !dcgy)", DCGYLv[Client], LvLimit_DCGYLv);
		DrawPanelItem(menu, line);
		//}
		//if (DCGYLv[Client] >= 15)
		//{
		Format(line, sizeof(line), "[雷神]虚空雷圈 (等级: %d/%d 发动指令: !ylds)", YLDSLv[Client], LvLimit_YLDSLv);
		DrawPanelItem(menu, line);
		//}
	}
	else if(JD[Client] == 8)
	{
		Format(line, sizeof(line), "[虚空之眼]虚空之怒 (等级: %d/%d 发动指令: !xkzn)", CqdzLv[Client], LvLimit_Cqdz);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[虚空之眼]电弘赤炎 (等级: %d/%d 发动指令: !dhcy)", HMZSLv[Client], LvLimit_HMZS);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[虚空之眼]涟漪光圈 (等级: %d/%d 发动指令: !lygq)", SPZSLv[Client], LvLimit_SPZS);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[究极]幽冥暗量 (等级: %d/%d 被动技能)", GouhunLv[Client], LvLimit_Gouhun);
		DrawPanelItem(menu, line);
	}
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_SurvivorSkill, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_SurvivorSkill(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1: MenuFunc_AddHealing(Client);
			case 2: MenuFunc_AddEarthQuake(Client);
			case 3: MenuFunc_AddHeavyGun(Client);  //助手
			case 4: MenuFunc_AddEndranceQuality(Client);  //苏醒术
			case 5:
			{
				if(JD[Client] == 1)	MenuFunc_AddAmmoMaking(Client);
				else if(JD[Client] == 2)	MenuFunc_AddEnergyEnhance(Client);
				else if(JD[Client] == 3)	MenuFunc_AddBioShield(Client);
				else if(JD[Client] == 4)	MenuFunc_AddTeleportToSelect(Client);
				else if(JD[Client] == 5)	MenuFunc_AddFireBall(Client);
				else if(JD[Client] == 6)	MenuFunc_AddBrokenAmmo(Client);  //破碎弹
				else if(JD[Client] == 7)	MenuFunc_AddLZD(Client);
				else if(JD[Client] == 8)	MenuFunc_AddCqdz(Client);  //虚空之怒
			}
			case 6:
			{
				if(JD[Client] == 1)	MenuFunc_AddFireSpeed(Client);
				else if(JD[Client] == 2)	MenuFunc_AddSprint(Client);
				else if(JD[Client] == 3)	MenuFunc_AddDamageReflect(Client);
				else if(JD[Client] == 4)	MenuFunc_AddAppointTeleport(Client);
				else if(JD[Client] == 5)	MenuFunc_AddIceBall(Client);
				//else if(JD[Client] == 6)	MenuFunc_AddPoisonAmmo(Client);
				else if(JD[Client] == 6)	MenuFunc_AddSuckBloodAmmo(Client);  //吸血弹
				else if(JD[Client] == 7)	MenuFunc_AddDCGY(Client);
				else if(JD[Client] == 8)	MenuFunc_AddHMZS(Client);	//电弘赤炎
			}
			case 7:
			{
				if(JD[Client] == 1)	MenuFunc_AddSatelliteCannon(Client);
				else if(JD[Client] == 2)	MenuFunc_AddInfiniteAmmo(Client);
				else if(JD[Client] == 3)	MenuFunc_AddMeleeSpeed(Client);
				else if(JD[Client] == 4)	MenuFunc_AddHealingBall(Client);
				//else if(JD[Client] == 4)	MenuFunc_AddTeleportTeam(Client);
				else if(JD[Client] == 5)	MenuFunc_AddChainLightning(Client);
				else if(JD[Client] == 6)	MenuFunc_AddAreaBlasting(Client);  //区域爆破
				else if(JD[Client] == 7)	MenuFunc_AddYLDS(Client);
				else if(JD[Client] == 8)	MenuFunc_AddSPZS(Client);  //涟漪光圈
			}
			case 8:
			{
				if(JD[Client] == 1 && NewLifeCount[Client] >= 1)	MenuFunc_AddAmmoMakingmiss(Client);
				else if(JD[Client] == 2 && NewLifeCount[Client] >= 1)	MenuFunc_AddBioShieldkb(Client);
				else if(JD[Client] == 3 && NewLifeCount[Client] >= 1)	MenuFunc_AddBioShieldmiss(Client);
				//else if(JD[Client] == 4)	MenuFunc_AddHealingBall(Client);
				else if(JD[Client] == 5 && NewLifeCount[Client] >= 1)	MenuFunc_AddSatelliteCannonmiss(Client);
				if(JD[Client] == 6 && NewLifeCount[Client] >= 1)	MenuFunc_AddLaserGun(Client);//镭射激光炮
				else if(JD[Client] == 8)	MenuFunc_AddGouhun(Client);  //幽冥暗量
			}
			/*
			case 8:
			{
				if(JD[Client] == 4 && NewLifeCount[Client] >= 1)	MenuFunc_AddTeleportTeamzt(Client);
			}
			*/
		}
	}
}

//治疗术
public Action:MenuFunc_AddHealing(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	if(VIP[Client] <= 0)
		Format(line, sizeof(line), "学习治疗术 目前等级: %d/%d 发动指令: !hl - 技能点剩余: %d", HealingLv[Client], LvLimit_Healing, SkillPoint[Client]);
	else
		Format(line, sizeof(line), "学习高级治疗术 目前等级: %d/%d 发动指令: !hl - 技能点剩余: %d", HealingLv[Client], LvLimit_Healing, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	if(VIP[Client] <= 0)
		Format(line, sizeof(line), "技能说明: 每秒恢复%dHP", HealingEffect[Client]);
	else
		Format(line, sizeof(line), "技能说明: 每秒恢复8HP");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %d秒", HealingDuration[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHealing, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHealing(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(HealingLv[Client] < LvLimit_Healing)
			{
				HealingLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_HL, HealingLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_HL_LEVEL_MAX);
			MenuFunc_AddHealing(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//召唤重机枪
public Action:MenuFunc_AddHeavyGun(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "召唤自动机枪 目前等级: %d/%d - 技能点剩余: %d", HeavyGunLv[Client], LvLimit_HeavyGun, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 召唤出自动机枪帮你扫射疯狂坦克!.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当前攻击伤害: %d", HeavyGunMaxDmg[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHeavyGun, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHeavyGun(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(HeavyGunLv[Client] < LvLimit_HeavyGun)
			{
				HeavyGunLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_HG, HeavyGunLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_HG_LEVEL_MAX);
			MenuFunc_AddHeavyGun(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}


//地震术
public Action:MenuFunc_AddEarthQuake(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习地震术 目前等级: %d/%d 发动指令: !dizhen - 技能点剩余: %d", EarthQuakeLv[Client], LvLimit_EarthQuake, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 范围内所有普通僵尸直接秒杀,最多秒杀数量根据技能等级决定.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "最大数量: %d", EarthQuakeMaxKill[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当前范围: %d", EarthQuakeRadius[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddEarthQuake, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddEarthQuake(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(EarthQuakeLv[Client] < LvLimit_EarthQuake)
			{
				EarthQuakeLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_EQ, EarthQuakeLv[Client] , EarthQuakeRadius[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_EQ_LEVEL_MAX);
			MenuFunc_AddEarthQuake(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//强化苏醒术
public Action:MenuFunc_AddEndranceQuality(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习强化苏醒术 目前等级: %d/%d 被动技能 - 技能点剩余: %d", EndranceQualityLv[Client], LvLimit_EndranceQuality, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 倒地后再起身的血量");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "生命比率: %.2f%%", EndranceQualityEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddEndranceQuality, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddEndranceQuality(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(EndranceQualityLv[Client] < LvLimit_EndranceQuality)
			{
				EndranceQualityLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_GENGXIN, EndranceQualityLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_GENGXIN_LEVEL_MAX);
			MenuFunc_AddEndranceQuality(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//子弹制造术
public Action:MenuFunc_AddAmmoMaking(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习子弹制造术 目前等级: %d/%d 发动指令: !am - 技能点剩余: %d", AmmoMakingLv[Client], LvLimit_AmmoMaking, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 制造一定数量子弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "制造数量: %d", AmmoMakingEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAmmoMaking, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAmmoMaking(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(AmmoMakingLv[Client] < LvLimit_AmmoMaking)
			{
				AmmoMakingLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_AM, AmmoMakingLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_AM_LEVEL_MAX);
			MenuFunc_AddAmmoMaking(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//核弹头
public Action:MenuFunc_AddAmmoMakingmiss(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习核弹头 (转生技能只限学习1级,要消耗50技能点)", AmmoMakingmissLv[Client], LvLimit_AmmoMakingmiss, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 在准心处创造一个核弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "核弹威力: 未知", AmmoMakingmissEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "爆炸范围: 未知");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAmmoMakingmiss, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAmmoMakingmiss(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 50)	CPrintToChat(Client, MSG_LACK_BUZU);
			else if(AmmoMakingmissLv[Client] < LvLimit_AmmoMakingmiss)
			{
				AmmoMakingmissLv[Client]++, SkillPoint[Client] -= 50;
				CPrintToChat(Client, MSG_ADD_SKILL_MOGU, AmmoMakingmissLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_MOGU_LEVEL_MAX);
			MenuFunc_AddAmmoMakingmiss(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//射速加强术
public Action:MenuFunc_AddFireSpeed(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习射速加强术 目前等级: %d/%d 发动指令: !fs - 技能点剩余: %d", FireSpeedLv[Client], LvLimit_FireSpeed, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 增加子弹的射击速度");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "速度比率: %.2f%%", FireSpeedEffect[Client]*100);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddFireSpeed, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddFireSpeed(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(FireSpeedLv[Client] < LvLimit_FireSpeed)
			{
				FireSpeedLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_FS, FireSpeedLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_FS_LEVEL_MAX);
			MenuFunc_AddFireSpeed(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//卫星炮
public Action:MenuFunc_AddSatelliteCannon(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习卫星炮 目前等级: %d/%d 发动指令: !sc - 技能点剩余: %d", SatelliteCannonLv[Client], LvLimit_SatelliteCannon, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 向準心位置发射卫星炮");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击伤害: %d", SatelliteCannonDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击范围: %d", SatelliteCannonRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.2f秒", SatelliteCannonCDTime[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 力量");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddSatelliteCannon, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddSatelliteCannon(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SatelliteCannonLv[Client] < LvLimit_SatelliteCannon)
			{
				SatelliteCannonLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_SC, SatelliteCannonLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_SC_LEVEL_MAX);
			MenuFunc_AddSatelliteCannon(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//暴雷术
public Action:MenuFunc_AddSatelliteCannonmiss(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习暴雷术 (转生技能只限学习1级,要消耗60技能点)", SatelliteCannonmissLv[Client], LvLimit_SatelliteCannonmiss, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 对范围内所有感染者造成大量伤害.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击伤害: %d", SatelliteCannonmissDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击范围: %.1f", SatelliteCannonmissRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.2f秒", SatelliteCannonmissCDTime[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddCannonmiss, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddCannonmiss(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 60)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SatelliteCannonmissLv[Client] < LvLimit_SatelliteCannonmiss)
			{
				SatelliteCannonmissLv[Client]++, SkillPoint[Client] -= 60;
				CPrintToChat(Client, MSG_ADD_SKILL_SCMISS, SatelliteCannonmissLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_SC_LEVEL_MAXMISS);
			MenuFunc_AddSatelliteCannonmiss(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//攻防术
public Action:MenuFunc_AddEnergyEnhance(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习攻防强化术 目前等级: %d/%d 被动 - 技能点剩余: %d", EnergyEnhanceLv[Client], LvLimit_EnergyEnhance, SkillPoint[Client]);
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "技能说明: 永久增加自身攻击力, 防卫力, 防御上限");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "增加伤害: %.2f%%", EnergyEnhanceEffect_Attack[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "增加防卫: %.2f%%", EnergyEnhanceEffect_Endurance[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "防御上限: %.2f%%", EnergyEnhanceEffect_MaxEndurance[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddEnergyEnhance, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddEnergyEnhance(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(EnergyEnhanceLv[Client] < LvLimit_EnergyEnhance)
			{
				EnergyEnhanceLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_EE, EnergyEnhanceLv[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_EE_LEVEL_MAX);
			MenuFunc_AddEnergyEnhance(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//暴走
public Action:MenuFunc_AddSprint(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习火焰极速 目前等级: %d/%d 发动指令: !sp - 技能点剩余: %d", SprintLv[Client], LvLimit_Sprint, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "提升移动速度. 持续:%.2f秒", SprintDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "技能说明: 一定时间内提升移动速度");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "增加比率: %.2f%%", SprintEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒", SprintDuration[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddSprint, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddSprint(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SprintLv[Client] < LvLimit_Sprint)
			{
				SprintLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_SP, SprintLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_SP_LEVEL_MAX);
			MenuFunc_AddSprint(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//无限子弹术
public Action:MenuFunc_AddInfiniteAmmo(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习无限子弹 目前等级: %d/%d 发动指令: !ia - 技能点剩余: %d", InfiniteAmmoLv[Client], LvLimit_InfiniteAmmo, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 一定时间内无限子弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒", InfiniteAmmoDuration[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddInfiniteAmmo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddInfiniteAmmo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(InfiniteAmmoLv[Client] < LvLimit_InfiniteAmmo)
			{
				InfiniteAmmoLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_IA, InfiniteAmmoLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_IA_LEVEL_MAX);
			MenuFunc_AddInfiniteAmmo(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//狂暴者模式
public Action:MenuFunc_AddBioShieldkb(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习狂暴者模式 (转生技能只限学习1级,要消耗50技能点)", BioShieldkbLv[Client], LvLimit_BioShieldkb, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 进入狂爆状态");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "持续时间: %.2f秒.", BioShieldkbDuration[Client]);
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "冷却时间: %.2f秒", BioShieldkbCDTime[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddBioShieldkb, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddBioShieldkb(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 50)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(BioShieldkbLv[Client] < LvLimit_BioShieldkb)
			{
				BioShieldkbLv[Client]++, SkillPoint[Client] -= 50;
				CPrintToChat(Client, MSG_ADD_SKILL_BSKB, BioShieldkbLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_BSKB_LEVEL_MAX);
			MenuFunc_AddBioShieldkb(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//无敌术
public Action:MenuFunc_AddBioShield(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习无敌术 目前等级: %d/%d 发动指令: !bs - 技能点剩余: %d", BioShieldLv[Client], LvLimit_BioShield, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 损耗自身生命去变成无敌, 使用后会清除自身技能效果, 且不能使用其他技能");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "损耗比率: %.2f%%", BioShieldSideEffect[Client] * 100);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒.", BioShieldDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.2f秒", BioShieldCDTime[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddBioShield, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddBioShield(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(BioShieldLv[Client] < LvLimit_BioShield)
			{
				BioShieldLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_BS, BioShieldLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_BS_LEVEL_MAX);
			MenuFunc_AddBioShield(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//基因改造
public Action:MenuFunc_AddGene(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习基因改造 目前等级: %d/%d 被动 - 技能点剩余: %d", GeneLv[Client], LvLimit_Gene, SkillPoint[Client]);
	SetPanelTitle(menu, line);
		
	Format(line, sizeof(line), "技能说明: 永久增加自身生命值和格挡能力");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "增加生命: %d", GeneHealthEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "格挡效果: %.2f%%", GeneEndEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddGene, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddGene(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(GeneLv[Client] < LvLimit_Gene)
			{
				GeneLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_GE, GeneLv[Client]);
				CreateTimer(0.1, StatusUp, Client);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_GE_LEVEL_MAX);
			MenuFunc_AddGene(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}



//潜能大爆发
public Action:MenuFunc_AddBioShieldmiss(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习潜能大爆发 (转生技能只限学习1级,要消耗60技能点)", BioShieldmissLv[Client], LvLimit_BioShieldmiss, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 所有幸存者恢复效果值的HP,所有感染者扣除效果值的HP");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "爆发效果:%d", ChainmissLightningDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.2f秒", BioShieldmissCDTime[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddBioShieldmiss, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddBioShieldmiss(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 60)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(BioShieldmissLv[Client] < LvLimit_BioShieldmiss)
			{
				BioShieldmissLv[Client]++, SkillPoint[Client] -= 60;
				CPrintToChat(Client, MSG_ADD_SKILL_BSMISS, BioShieldmissLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_BSMISS_LEVEL_MAX);
			MenuFunc_AddBioShieldmiss(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//反伤术
public Action:MenuFunc_AddDamageReflect(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习反伤术 目前等级: %d/%d 发动指令: !dr - 技能点剩余: %d", DamageReflectLv[Client], LvLimit_DamageReflect, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 损耗自身生命在一定时间内去反射一定比率伤害");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "损耗比率: %.2f%%", DamageReflectSideEffect[Client]*100);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒.", DamageReflectDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "反射比率: %.2f%%", DamageReflectEffect[Client]*100);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 耐力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddDamageReflect, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddDamageReflect(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(DamageReflectLv[Client] < LvLimit_DamageReflect)
			{
				DamageReflectLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_DR, DamageReflectLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_DR_LEVEL_MAX);
			MenuFunc_AddDamageReflect(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//近战嗜血术
public Action:MenuFunc_AddMeleeSpeed(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习近战嗜血术 目前等级: %d/%d 发动指令: !ms - 技能点剩余: %d", MeleeSpeedLv[Client], LvLimit_MeleeSpeed, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 牺牲所有防御力去提升近战攻速");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒", MeleeSpeedDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "提速比率: %.2f%%", 1.0 + MeleeSpeedEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddMeleeSpeed, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddMeleeSpeed(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(MeleeSpeedLv[Client] < LvLimit_MeleeSpeed)
			{
				MeleeSpeedLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_MS, MeleeSpeedLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_MS_LEVEL_MAX);
			MenuFunc_AddMeleeSpeed(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//选择传送术
public Action:MenuFunc_AddTeleportToSelect(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习选择传送术 目前等级: %d/%d 发动指令: !ts - 技能点剩余: %d", TeleportToSelectLv[Client], LvLimit_TeleportToSelect, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 传送到指定队友身边");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %d秒", 230 - (TeleportToSelectLv[Client]+AppointTeleportLv[Client])*5);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddTeleportToSelect, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddTeleportToSelect(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(TeleportToSelectLv[Client] < LvLimit_TeleportToSelect)
			{
				TeleportToSelectLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_TS, TeleportToSelectLv[Client]);
				if(TeleportToSelectLv[Client]==0) IsTeleportToSelectEnable[Client] = false;
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_TS_LEVEL_MAX);
			MenuFunc_AddTeleportToSelect(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//审判光球术
public Action:MenuFunc_AddAppointTeleport(Client)
{

	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习审判光球术 目前等级: %d/%d 发动指令: !at - 技能点剩余: %d", AppointTeleportLv[Client], LvLimit_AppointTeleport, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 发射一个光球对敌人造成%d%伤害,对友军施加%d%治疗效果.(5.0秒冷却)", LightBallDamage[Client], LightBallHealth[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAppointTeleport, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;

}
public MenuHandler_AddAppointTeleport(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(AppointTeleportLv[Client] < LvLimit_AppointTeleport)
			{
				AppointTeleportLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_AT, AppointTeleportLv[Client]);
				if(AppointTeleportLv[Client]==0) IsAppointTeleportEnable[Client] = false;
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_AT_LEVEL_MAX);
			MenuFunc_AddAppointTeleport(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//心灵传送术
public Action:MenuFunc_AddTeleportTeam(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习心灵传送术 目前等级: %d/%d 发动指令: !tt - 技能点剩余: %d", TeleportTeamLv[Client], LvLimit_TeleportTeam, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 传送指定队友到自己身边");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %d秒", 160 - TeleportTeamLv[Client]*5);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddTeleportTeam, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddTeleportTeam(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			{
				if(TeleportTeamLv[Client] < LvLimit_TeleportTeam)
				{
					TeleportTeamLv[Client]++, SkillPoint[Client] -= 1;
					CPrintToChat(Client, MSG_ADD_SKILL_TT, TeleportTeamLv[Client]);
					if(TeleportTeamLv[Client]==0) IsTeleportTeamEnable[Client] = false;
				}
				else CPrintToChat(Client, MSG_ADD_SKILL_TT_LEVEL_MAX);
			}
			MenuFunc_AddTeleportTeam(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//全体召唤术
public Action:MenuFunc_AddTeleportTeamzt(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习全体召唤术 (转生技能只限学习1级,要消耗30技能点)", TeleportTeamztLv[Client], LvLimit_TeleportTeamzt, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 传送所有队友到自己身边.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %d秒", 160 - TeleportTeamztLv[Client]*5);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddTeleportTeamzt, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddTeleportTeamzt(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 30)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(TeleportTeamLv[Client] == LvLimit_TeleportTeam)
			{
				if(TeleportTeamztLv[Client] < LvLimit_TeleportTeamzt)
				{
					TeleportTeamztLv[Client]++, SkillPoint[Client] -= 30;
					CPrintToChat(Client, MSG_ADD_SKILL_ZT, TeleportTeamztLv[Client]);
					if(TeleportTeamztLv[Client]==0) 
						IsTeleportTeamztEnable[Client] = false;
				}
				else CPrintToChat(Client, MSG_ADD_SKILL_ZT_LEVEL_MAX);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_TT_NEED);
			MenuFunc_AddTeleportTeamzt(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//治疗光球术
public Action:MenuFunc_AddHealingBall(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习治疗光球术 目前等级: %d/%d 发动指令: !hb - 技能点剩余: %d", HealingBallLv[Client], LvLimit_HealingBall, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	new healing = RoundToNearest(0.0 + HealingBallEffect[Client]);
	if (healing < 5 || healing > 10)
		healing = 30;
	Format(line, sizeof(line), "技能说明: 在準心制造一个光球治疗附近队友");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "每秒回复: %dHP", healing);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.2f秒", HealingBallDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "治疗范围: %d", HealingBallRadius[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHealingBall, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHealingBall(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(NewLifeCount[Client] >= 0)
			{
				if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
				else if(HealingBallLv[Client] < LvLimit_HealingBall)
				{
					HealingBallLv[Client]++, SkillPoint[Client] -= 1;
					CPrintToChat(Client, MSG_ADD_SKILL_HB, HealingBallLv[Client]);
				}
				else CPrintToChat(Client, MSG_ADD_SKILL_HB_LEVEL_MAX);
			} else CPrintToChat(Client, MSG_ADD_SKILL_NeedNewLife);
			MenuFunc_AddHealingBall(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//火球术
public Action:MenuFunc_AddFireBall(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习火球术 目前等级: %d/%d 发动指令: !fb - 技能点剩余: %d", FireBallLv[Client], LvLimit_FireBall, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 向準心放出火球, 燃烧范围内敌人 5秒冷却");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧持续: %.f秒", FireBallDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧伤害: %d", FireBallDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧范围: %d", FireBallRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddFireBall, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddFireBall(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(FireBallLv[Client] < LvLimit_FireBall)
			{
				FireBallLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_FB, FireBallLv[Client], FireBallDamage[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_FB_LEVEL_MAX);
			MenuFunc_AddFireBall(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//冰球术
public Action:MenuFunc_AddIceBall(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习冰球术 目前等级: %d/%d 发动指令: !ib - 技能点剩余: %d", IceBallLv[Client], LvLimit_IceBall, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 向準心放出冰球, 冻结范围内敌人");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冰冻持续: %.2f秒", IceBallDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冰冻伤害: %d", IceBallDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冰冻范围: %d", IceBallRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddIceBall, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddIceBall(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(IceBallLv[Client] < LvLimit_IceBall)
			{
				IceBallLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_IB, IceBallLv[Client], IceBallDamage[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_IB_LEVEL_MAX);
			MenuFunc_AddIceBall(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//连锁闪电术
public Action:MenuFunc_AddChainLightning(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习连锁闪电术 目前等级: %d/%d 发动指令: !cl - 技能点剩余: %d", ChainLightningLv[Client], LvLimit_ChainLightning, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 在周围放出黑暗之点不断攻击附近敌人");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "闪电伤害: %d", ChainLightningDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "发动范围: %d", ChainLightningLaunchRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "连锁范围: %d", ChainLightningRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddChainLightning, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddChainLightning(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(ChainLightningLv[Client] < LvLimit_ChainLightning)
			{
				ChainLightningLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_CL, ChainLightningLv[Client], ChainLightningDamage[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
			MenuFunc_AddChainLightning(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//职业选单
public Action:MenuFunc_Job(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Job);
	SetMenuTitle(menu, "转职|洗点");
	AddMenuItem(menu, "option1", "洗点");
	AddMenuItem(menu, "option2", "转生");
	AddMenuItem(menu, "option3", "转职精灵");
	AddMenuItem(menu, "option4", "转职士兵");
	AddMenuItem(menu, "option5", "转职生物专家");
	AddMenuItem(menu, "option6", "转职医生");
	AddMenuItem(menu, "option7", "转职法师(需1转)");
	AddMenuItem(menu, "option8", "转职弹药专家(需3转)");
	AddMenuItem(menu, "option9", "转职雷神(需3转)");
	AddMenuItem(menu, "option10", "转职虚空之眼(需7转)");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_Job(Handle:menu, MenuAction:action, Client, itemNum)
{
	if(action == MenuAction_Select) {
		switch(itemNum)
		{
			case 0: MenuFunc_ResetStatus(Client);//洗点
			case 1: 
			{
				if (NewLifeCount[Client] < 15)
					MenuFunc_NewLife(Client);//转生
				else
					PrintHintText(Client, "你的转生次数已达到上限!");
			}
			case 2: ChooseJob(Client, 1);//精灵
			case 3: ChooseJob(Client, 2);//游侠
			case 4: ChooseJob(Client, 3);//生物专家
			case 5: ChooseJob(Client, 4);//医生
			case 6: ChooseJob(Client, 5);//法师
			case 7: ChooseJob(Client, 6);//弹药专家
			case 8: ChooseJob(Client, 7);//雷神
			case 9: ChooseJob(Client, 8);//虚空之眼
		}
	} else if (action == MenuAction_End) CloseHandle(menu);
}
public Action:MenuFunc_ResetStatus(Client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu,"洗点说明:\n按确认之后将会清零当前分配的属性, 所学技能技能及经验\n未转职玩家洗点降1级, 转职过的玩家降5级并变回未转职状态!\n你的真的需要洗点吗?\n════════════");

	DrawPanelItem(menu, "是");
	DrawPanelItem(menu, "否");

	SendPanelToClient(menu, Client, MenuHandler_ResetStatus, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_ResetStatus(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1:	ClinetResetStatus(Client, General), BindKeyFunction(Client);
			case 2: return;
		}
	}
}
ClinetResetStatus(Client, Mode)
{
	//转生
	if(Mode == NewLife)
	{
		EXP[Client] = 0;
		Lv[Client] = 0;
		JobChooseBool[Client] = false;
		JD[Client] = 0;
		NewLifeCount[Client] += 1;
		StatusPoint[Client] = NewLifeGiveSKP[Client];
		SkillPoint[Client] = NewLifeGiveSP[Client];		
	}
	
	
	//已转职洗点
	if(Mode != Admin && JobChooseBool[Client])
	{
		if (Lv[Client] <= 10)
		{
			CPrintToChat(Client, "{red}你的等级小于10,无法进行洗点,请等你等级达到10级后在进行洗点!");
			return;
		}
		JD[Client] = 0;
		JobChooseBool[Client] = false;
		if(Mode==General)	Lv[Client] -= 5;	
	}
	//无转职洗点
	else if(Mode == General)
	{	
		if (Lv[Client] >= 10)
			Lv[Client] -= 1;	
		else
		{
			CPrintToChat(Client, "{red}你的等级小于10,无法进行洗点,请等你等级达到10级后在进行洗点!");
			return;
		}			
	}

	if(Mode == Admin)
	{
		JD[Client] = 0;
		JobChooseBool[Client] = false;	
	}
	
	if(Mode!=NewLife)
	{
		StatusPoint[Client]	=	Lv[Client] * GetConVarInt(LvUpSP);
		SkillPoint[Client]	=	Lv[Client] * GetConVarInt(LvUpKSP);
		EXP[Client]	= 0;
		if (NewLifeCount[Client] > 0)
		{
			StatusPoint[Client]	=	Lv[Client] * GetConVarInt(LvUpSP) + (NewLifeCount[Client] * 100);
			SkillPoint[Client] =	Lv[Client] * GetConVarInt(LvUpKSP) + (NewLifeCount[Client] * 20);		
		}
	}
	
	Str[Client]						= 0;
	Agi[Client]						= 0;
	Health[Client]					= 0;
	Endurance[Client]					= 0;
	Intelligence[Client]				= 0;
	Crits[Client]						= 0;   //暴击
	CritMin[Client]					= 0;
	CritMax[Client]					= 0;
	HealingLv[Client]					= 0;
	EarthQuakeLv[Client]				= 0;
	EndranceQualityLv[Client]		= 0;
	HeavyGunLv[Client]				= 0;	//召唤重机枪
	AmmoMakingLv[Client]				= 0;
	AmmoMakingmissLv[Client]			= 0;
	SatelliteCannonLv[Client]		= 0;
	SatelliteCannonmissLv[Client]	= 0;
	EnergyEnhanceLv[Client]			= 0;
	SprintLv[Client]					= 0;
	BioShieldLv[Client]				= 0;
	BioShieldmissLv[Client]			= 0;
	BioShieldkbLv[Client]			= 0;
	DamageReflectLv[Client]			= 0;
	MeleeSpeedLv[Client]				= 0;
	InfiniteAmmoLv[Client]			= 0;
	FireSpeedLv[Client]				= 0;
	TeleportToSelectLv[Client]		= 0;
	AppointTeleportLv[Client]		= 0;
	TeleportTeamLv[Client]			= 0;
	TeleportTeamztLv[Client]			= 0;
	FireBallLv[Client]				= 0;
	IceBallLv[Client]					= 0;
	ChainLightningLv[Client]			= 0;
	BrokenAmmoLv[Client]				= 0;	//精灵尘埃等级
	PoisonAmmoLv[Client]				= 0;	//渗毒弹等级
	SuckBloodAmmoLv[Client]			= 0;	//吸血弹等级
	AreaBlastingLv[Client]			= 0;	//区域爆破等级
	LaserGunLv[Client]				= 0;	//精灵激光波等级
	GeneLv[Client]					= 0;	//基因改造
	DCGYLv[Client]			= 0;  //不熄光环
	LZDLv[Client]			= 0;  //雷神弹药
	YLDSLv[Client]			= 0;  //引雷
	GouhunLv[Client]			        = 0;	//幽冥暗量等级
	CqdzLv[Client]			        = 0;	//虚空之怒等级
	HMZSLv[Client]				    = 0;	//电弘赤炎等级
	SPZSLv[Client]					= 0;	//涟漪光圈等级
	Hunpo[Client]			            = 0;	//菊花
	

	RebuildStatus(Client, false);

	
	if(KTCount[Client] > 0)
	{
		CPrintToChat(Client, MSG_XD_KT_REMOVE);
		KTCount[Client] -= 5;
		if(KTCount[Client]<0)	KTCount[Client] = 0;
	}

	if(Mode == Admin)
		CPrintToChatAllEx(Client, MSG_XD_SUCCESS_ADMIN, Client);
	else if(Mode == Shop)
		CPrintToChatAllEx(Client, MSG_XD_SUCCESS_SHOP, Client);
	else if(Mode == General)
		CPrintToChatAllEx(Client, MSG_XD_SUCCESS, Client);
	else
		CPrintToChatAll(MSG_NL_SUCCESS, Client);
}

//转生
public Action:MenuFunc_NewLife(Client)
{
	new needlv = GetConVarInt(NewLifeLv) + NewLifeCount[Client] * GetConVarInt(NewLifeLv) / 4;
	if(Lv[Client] < needlv)
	{
		CPrintToChat(Client, MSG_NL_NEED_LV, needlv);
		return Plugin_Handled;
	}
	else
	{
		new Handle:menu = CreatePanel();
		decl String:line[256];
		Format(line, sizeof(line), "转生说明:\n按确认之后将会清零当前分配的属性和所学的技能 \n玩家重新变为0级,并会增加初始属性点(%d),初始技能点(%d) \n你的真的决定进行第%d次转生吗?\n════════════", NewLifeSKP[Client], NewLifeSP[Client], NewLifeCount[Client] + 1);
		SetPanelTitle(menu, line);

		DrawPanelItem(menu, "转生");
		DrawPanelItem(menu, "返回");

		SendPanelToClient(menu, Client, MenuHandler_NewLife, MENU_TIME_FOREVER);
		CloseHandle(menu);
		return Plugin_Handled;
	}
}
public MenuHandler_NewLife(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1: ClinetResetStatus(Client, NewLife);
			case 2: return;
		}
	}
}
stock ChooseJob(Client, Jobid)
{
	if (KTCount[Client] > KTLimit)
	{
		CPrintToChat(Client, MSG_ZZ_FAIL_KT);
	}
	else if (JobChooseBool[Client])
	{
		CPrintToChat(Client, MSG_ZZ_FAIL_JCB_TURE);
	}
	else
	{
		if (Jobid==1)//精灵
		{
			if (Str[Client] >= JOB1_Str && Agi[Client] >= JOB1_Agi && Health[Client] >= JOB1_Health && Endurance[Client] >= JOB1_Endurance && Intelligence[Client] >= JOB1_Intelligence)
			{
				JD[Client] = 1;
				Str[Client] += 10;
				Endurance[Client] += 10;
				Intelligence[Client] += 10;
				JobChooseBool[Client] = true;
				CPrintToChatAll(MSG_ZZ_SUCCESS_JOB1_ANNOUNCE, Client);
				CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB1_REWARD);
			}
			else
			{
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB1_Str, JOB1_Agi, JOB1_Health, JOB1_Endurance, JOB1_Intelligence);
				CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			}
		}
		else if (Jobid==2)//游侠
		{
			if (Str[Client] >= JOB2_Str && Agi[Client] >= JOB2_Agi && Health[Client] >= JOB2_Health && Endurance[Client] >= JOB2_Endurance && Intelligence[Client] >= JOB2_Intelligence)
			{
				JD[Client] = 2;
				Str[Client] += 10;
				Agi[Client] += 10;
				Health[Client] += 10;
				JobChooseBool[Client] = true;
				CPrintToChatAll(MSG_ZZ_SUCCESS_JOB2_ANNOUNCE, Client);
				CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB2_REWARD);
			}
			else
			{
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB2_Str, JOB2_Agi, JOB2_Health, JOB2_Endurance, JOB2_Intelligence);
				CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			}
		}
		else if (Jobid==3)//生物专家
		{
			if (Str[Client] >= JOB3_Str && Agi[Client] >= JOB3_Agi && Health[Client] >= JOB3_Health && Endurance[Client] >= JOB3_Endurance && Intelligence[Client] >= JOB3_Intelligence)
			{
				JD[Client] = 3;
				Str[Client] += 10;
				Health[Client] += 10;
				Intelligence[Client] += 10;
				JobChooseBool[Client] = true;
//				if (Lv[Client] < 50)
//					defibrillator[Client] = 2;
//				else
//					defibrillator[Client] = 3;
				CPrintToChatAll(MSG_ZZ_SUCCESS_JOB3_ANNOUNCE, Client);
				CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB3_REWARD);
			}
			else
			{
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB3_Str, JOB3_Agi, JOB3_Health, JOB3_Endurance, JOB3_Intelligence);
				CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			}
		}
		else if (Jobid==4)//医生
		{
			if (Str[Client] >= JOB4_Str && Agi[Client] >= JOB4_Agi && Health[Client] >= JOB4_Health && Endurance[Client] >= JOB4_Endurance && Intelligence[Client] >= JOB4_Intelligence)
			{
				JD[Client] = 4;
				Str[Client] += 10;
				Health[Client] += 10;
				Endurance[Client] += 10;
				JobChooseBool[Client] = true;
				if (Lv[Client] < 50)
					defibrillator[Client] = 2;
				else
					defibrillator[Client] = 3;
				CPrintToChatAll(MSG_ZZ_SUCCESS_JOB4_ANNOUNCE, Client);
				CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB4_REWARD);
			}
			else
			{
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB4_Str, JOB4_Agi, JOB4_Health, JOB4_Endurance, JOB4_Intelligence);
				CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			}
		}
		else if (Jobid==5)//大法师
		{
			if(NewLifeCount[Client] >= 1)
			{
				if (Str[Client] >= JOB5_Str && Agi[Client] >= JOB5_Agi && Health[Client] >= JOB5_Health && Endurance[Client] >= JOB5_Endurance && Intelligence[Client] >= JOB5_Intelligence)
				{
					JD[Client] = 5;
					Str[Client] += 10;
					Health[Client] += 10;
					Intelligence[Client] += 10;
					JobChooseBool[Client] = true;
					CPrintToChatAll(MSG_ZZ_SUCCESS_JOB5_ANNOUNCE, Client);
					CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB5_REWARD);
				}
				else
				{
					CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
					CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB5_Str, JOB5_Agi, JOB5_Health, JOB5_Endurance, JOB5_Intelligence);
					CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
				}
			} 
		}
		else if (Jobid == 6)//弹药专家
		{
			if (NewLifeCount[Client] >= 3)
			{
				if (Str[Client] >= JOB6_Str && Agi[Client] >= JOB6_Agi && Health[Client] >= JOB6_Health && Endurance[Client] >= JOB6_Endurance && Intelligence[Client] >= JOB6_Intelligence)
				{
					JD[Client] = 6;
					Str[Client] += 15;
					Intelligence[Client] += 15;
					JobChooseBool[Client] = true;
					CPrintToChatAll(MSG_ZZ_SUCCESS_JOB6_ANNOUNCE, Client);
					CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB6_REWARD);
				}
				else
				{
					CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
					CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB6_Str, JOB6_Agi, JOB6_Health, JOB6_Endurance, JOB6_Intelligence);
					CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
				}			
			}
			else
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_NEWLIFE);
		}
		else if (Jobid == 7)//雷神
		{
			if (NewLifeCount[Client] >= 7)
			{
			   if (Str[Client] >= JOB7_Str && Agi[Client] >= JOB7_Agi && Health[Client] >= JOB7_Health && Endurance[Client] >= JOB7_Endurance && Intelligence[Client] >= JOB7_Intelligence)
			   {
				   JD[Client] = 7;
				   Str[Client] += 20;
				   Intelligence[Client] += 20;
				   JobChooseBool[Client] = true;
				   CPrintToChatAll(MSG_ZZ_SUCCESS_JOB7_ANNOUNCE, Client);
				   CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB7_REWARD);
			   }
			   else
			   {
				   CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				   CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB7_Str, JOB7_Agi, JOB7_Health, JOB7_Endurance, JOB7_Intelligence);
				   CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			   }			
		   }
		}
		else if (Jobid == 8)//虚空之眼
		{
			if (NewLifeCount[Client] >= 1)
			{
			   if (Str[Client] >= JOB8_Str && Agi[Client] >= JOB8_Agi && Health[Client] >= JOB8_Health && Endurance[Client] >= JOB8_Endurance && Intelligence[Client] >= JOB8_Intelligence)
			   {
				   JD[Client] = 8;
				   Str[Client] += 20;
				   Intelligence[Client] += 20;
				   JobChooseBool[Client] = true;
				   CPrintToChatAll(MSG_ZZ_SUCCESS_JOB8_ANNOUNCE, Client);
				   CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB8_REWARD);
			   }
			   else
			   {
				   CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				   CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB8_Str, JOB8_Agi, JOB8_Health, JOB8_Endurance, JOB8_Intelligence);
				   CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			   }			
		   }
		}
		//绑定新职业按键
		BindKeyFunction(Client);
	}	
}

/* 购物商店 */
public Action:Menu_Buy(Client,args)
{
	MenuFunc_Buy(Client);
	return Plugin_Handled;
}
public MenuFunc_Buy(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Buy);
	SetMenuTitle(menu, "金钱: %d$ 记大过: %d次 点卷: %d个", Cash[Client], KTCount[Client], Qcash[Client]);
	AddMenuItem(menu, "item0", "军队物资");
	AddMenuItem(menu, "item1", "先进武器");
	AddMenuItem(menu, "item2", "近战肉搏");
	AddMenuItem(menu, "item3", "巫师店铺");
	AddMenuItem(menu, "item4", "机器人店");
	AddMenuItem(menu, "item5", "拉斯赌城");
	AddMenuItem(menu, "item6", "永久装备");
	AddMenuItem(menu, "item7", "古代卷轴");
	AddMenuItem(menu, "item8", "点卷商城");
	AddMenuItem(menu, "item9", "会员贵族商城");
//	AddMenuItem(menu, "item8", "白金会员[体验店]");
	
	
	//SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public MenuHandler_Buy(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: MenuFunc_NormalItemShop(Client);        //药物杂项
			case 1: MenuFunc_SelectedGunShop(Client);           //精品枪械
			case 2: MenuFunc_MeleeShop(Client);          //近战商店
			case 3: MenuFunc_SpecialShop(Client);        //神秘商店
			case 4: MenuFunc_RobotBuy(Client);          //机器人店
			case 5: MenuFunc_LotteryCasino(Client);         //赌博抽奖
			case 6: MenuFunc_VIPSC(Client);           //天神兵器
			case 7: MenuFunc_Xhpsd(Client);           //古代卷轴
			case 8: MenuFunc_Qiubuy(Client);          //点卷商城
			case 9:
			{
                if(VIP[Client] > 0)
                {
                    MenuFunc_Vipbuys(Client);           //VIP专属商店
                } else CPrintToChat(Client, "\x05【提示】你不是会员,无法进入!");
			}
		}
	} 
	else if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack)
			MenuFunc_RPG(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

//白金体验店Lv[Client]
public Action:MenuFunc_BJTY(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[32];

	Format(line, sizeof(line), "白金VIP体验[领取]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "条件:低于20级的玩家");   
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "体验:领取白金VIP3天");    
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "提示:输入!vipfree为补给,!vipvote为踢人");    
	DrawPanelText(menu, line);

	DrawPanelItem(menu, "返回超级市场");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_BJTY, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_BJTY(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIP2TY(Client);	
		}
	}
}

public VIP2TY(Client)
{   
	if(Lv[Client] <= 20)    
	{       	    
		ServerCommand("sm_setvip_845 \"%N\" \"1\" \"3\"", Client);      
		CPrintToChat(Client, "\x05[VIP体验]\x04你已经领取\x03白金VIP3天，\x04请好好珍惜");       
		CPrintToChatAll("\x03[VIP体验]\x04恭喜玩家\x05%N\x04成为\x05体验白金VIP", Client);	    
	} else CPrintToChat(Client, "\x05已经不再是新手[或者已经领取过了]");
}


/* VIP专属商店 */
public Action:MenuFunc_Vipbuys(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【会员贵族商城】\n拥有的金钱:$%d ，拥有的点卷:%d个", Cash[Client], Qcash[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "购买点卷");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "说明:点卷停止兑换");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "购买等级");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "说明:所需点卷$200获得等级LV.1");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "购买等级");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "说明:所需点卷$2000获得等级LV.10");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "购买古代卷轴");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "说明:所需金钱$30000获得随机古代卷轴");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "购买古代卷轴");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "说明:所需金钱$50000获得全体召唤古代卷轴");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "返回超级市场");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Vipbuys, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_Vipbuys(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIPQCASH(Client);
			case 2: VIPLVBUY(Client);
			case 3: VIPLVBUY2(Client);
			case 4: VIPJUAN(Client);
			case 5: VIPQUANTI(Client);
			case 6: MenuFunc_Buy(Client);
		}
	}
}
public VIPQCASH(Client)
{   
	if(Cash[Client] >= 0)    
	{       
		Cash[Client] -= 0;		
		Qcash[Client] += 0;       
//		CPrintToChat(Client, "\x03【系统】你成功购买点卷100!");	    
		CPrintToChat(Client, "\x03[系统]\04%本商品\x05停止\x04购买\x05!", Client);	    

	} else CPrintToChat(Client, "\x03【提示】购买点卷请联系op扣扣;1176195532！");
	MenuFunc_Vipbuys(Client)
}
public VIPLVBUY(Client)
{   
	if(Qcash[Client] >= 200)    
	{       
		Qcash[Client] -= 200;		
		ServerCommand("sm_givelv_114 \"%N\" \"1\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功购买等级LV.1!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!请联系op扣扣;1176195532 购买点卷！");
	MenuFunc_Vipbuys(Client)
}
public VIPLVBUY2(Client)
{   
	if(Qcash[Client] >= 2000)    
	{       
		Qcash[Client] -= 2000;		
		ServerCommand("sm_givelv_114 \"%N\" \"10\"", Client);       	
		CPrintToChat(Client, "\x03【提示】你成功购买等级LV.10!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
	MenuFunc_Vipbuys(Client)
}
public VIPJUAN(Client)
{   
	if(Cash[Client] >= 30000)    
	{       
		Cash[Client] -= 30000;		
		PlayerSignXHItem(Client);       
		CPrintToChat(Client, "\x03【提示】你成功购买随机古代卷轴!");	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的金钱!");
	MenuFunc_Vipbuys(Client)
}
public VIPQUANTI(Client)//全体古代卷轴
{   
	if(Cash[Client] >= 50000)    
	{       
		Cash[Client] -= 50000;		
		PlayerItem[Client][ITEM_XH][0] += 1;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05VIP商店\x04购买了\x05 1个全体召唤古代卷轴!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的金币!");
	MenuFunc_Vipbuys(Client)
}
/* 巫师冶炼药水购买 */
public Action:MenuFunc_Eqgou(Client)
{   
	new Handle:menu = CreatePanel();	
    
	decl String:line[1024];   
	Format(line, sizeof(line), "═══巫师冶炼药水材料═══");   
	SetPanelTitle(menu, line); 
	Format(line, sizeof(line), "说明: 赐予魔力的材料(价格点卷:300)");   
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "购买");    
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
   
	SendPanelToClient(menu, Client, MenuHandler_Eqgou, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_Eqgou(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
			case 1: EQBBX(Client);
            case 2: UseEqboxcsFunc(Client);					
		}
	}
}
public EQBBX(Client)
{
    if(Qcash[Client] >= 300)
    {
        Qcash[Client] -= 300;
        Shitou[Client]++;
        CPrintToChat(Client, "\x05【提示】你购买了巫师冶炼药水!");
    } else CPrintToChat(Client, "\x05【提示】购买失败,点卷不足!请联系op扣扣;1176195532购买点卷!");
    MenuFunc_Eqgou(Client)	
}

/* 潘多拉宝盒 */
public Action:MenuFunc_Eqboxgz(Client)
{   
	new Handle:menu = CreatePanel();	
    
	decl String:line[1024];   
	Format(line, sizeof(line), "═══潘多拉宝盒 (拥有: %d个)═══", Eqbox[Client]);   
	SetPanelTitle(menu, line);    
	Format(line, sizeof(line), "说明: 蕴含古代力量的宝盒!");   
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "购买宝盒(点卷:2000)");    
	DrawPanelItem(menu, line);	
	Format(line, sizeof(line), "开启宝盒");   
	DrawPanelItem(menu, line);   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
   
	SendPanelToClient(menu, Client, MenuHandler_Eqboxgz, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_Eqboxgz(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
			case 1: GOUMAI(Client);
            case 2: UseEqboxcsFunc(Client);					
		}
	}
}
public Action:UseEqboxcsFunc(Client)
{
    if(Cash[Client] >= 10000)
	{	
	    if(Eqbox[Client]>0)
	    {
            Eqbox[Client]--;
            new diceNum;
            diceNum = GetRandomInt(1, 16);
		
            switch (diceNum)
		    {
			    case 1:
				{
                    CheatCommand(Client, "z_spawn", "tank auto");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了Tank一只!", Client);
                }
				case 2: 
			    {
                    CheatCommand(Client, "z_spawn", "witch auto");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得Witch妹子!", Client);
                }
                case 3: 
			    {
                    CheatCommand(Client, "director_force_panic_event", "");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了一群丧尸!", Client);
                }	
                case 4: 
			    {
                    Cash[Client] += 20000;
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了20000$!", Client);
                }
                case 5: 
			    {
                    Qcash[Client] += 1000;
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了点卷1000!", Client);
                }
                case 6: 
			    {
                    PlayerItem[Client][ITEM_ZB][18] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得红宝石水晶15天!", Client);
                }
                case 7: 
			    {
                    PlayerSignXHItem(Client);
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了随机古代卷轴1个!", Client);
                }	
                case 8: 
			    {
                    CheatCommand(Client, "give", "baseball_bat");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了棒球棍!", Client);
                }
                case 9: 
			    {
                    CheatCommand(Client, "give", "rifle_ak47");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了AK47!", Client);
                }
                case 10: 
			    {
                    CheatCommand(Client, "give", "rifle_m60");
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得了M60机枪!", Client);
                }
                case 11: 
			    {
                    PlayerItem[Client][ITEM_ZB][13] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得哲理之石15日！", Client);
                }
                case 12: 
			    {
                    PlayerItem[Client][ITEM_ZB][23] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得麦瑞得的拳刃15日！", Client);
                }	
                case 13: 
			    {
                    PlayerItem[Client][ITEM_ZB][26] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得永恒之刃15日", Client);
                }			
				case 14: 
			    {
                    PlayerItem[Client][ITEM_ZB][27] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得最后的轻语15日", Client);
                }		
				case 15: 
			    {
                    PlayerItem[Client][ITEM_ZB][10] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得活力宝珠15日", Client);
                }
				case 16: 
			    {
                    PlayerItem[Client][ITEM_ZB][32] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得女神之泪15日", Client);
                }
				case 17: 
			    {
                    PlayerItem[Client][ITEM_ZB][33] += 15;  
                    CPrintToChatAll("\x05【公告】玩家%N打开潘多拉宝盒获得冰川之冠15日", Client);
                }
		    }
	    } else PrintHintText(Client, "【提示】你没有潘多拉宝盒!");
    } else CPrintToChat(Client, "\x05【提示】所需金钱不够, 无法开启!请联系op扣扣;1176195532购买金钱!");	
    return Plugin_Handled;
}
public GOUMAI(Client)
{
    if(Qcash[Client] >= 2000)
    {
        Qcash[Client] -= 2000;
        Eqbox[Client]++;
        CPrintToChat(Client, "\x05【提示】你购买了潘多拉宝盒!");
    } else CPrintToChat(Client, "\x05【提示】购买失败,点卷不足!请联系op扣扣;1176195532购买点卷!");	
    MenuFunc_Eqboxgz(Client)	
}

/* 点卷商城 */
public Action:MenuFunc_Qiubuy(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【点卷商城】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "说明:圣石/药水  在转职菜单里使用!");
	DrawPanelText(menu, line);

	Format(line, sizeof(line), "购买圣石");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "购买强化石");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "购买复活币");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "购买潘多拉宝盒");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "购买巫师冶炼药水");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "购买会员");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "超级变身");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "兑换游戏币");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "古代卷轴");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回超级市场");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Qiubuy, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_Qiubuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_TSDJ(Client);
			case 2: MenuFunc_qhsa(Client);   //强化石
			case 3: MenuFunc_FHB(Client);   //复活币
			case 4: MenuFunc_Eqboxgz(Client);   //潘多拉魔盒
			case 5: MenuFunc_Eqgou(Client);
			case 6: MenuFunc_Vbuy(Client);      //购买会员
			case 7: MenuFunc_VIPplayer2(Client);  //超级变身
			case 8: MenuFunc_Dbuy(Client);
			case 9: MenuFunc_Xhpsd(Client);
			case 10: MenuFunc_Buy(Client);
		}
	}
}



/* 强化石购买 */
public Action:MenuFunc_qhsa(Client)
{   
	new Handle:menu = CreatePanel();	
    
	decl String:line[1024];   
	Format(line, sizeof(line), "═══强化石材料═══ \n强化石可以进行强化支的伤害 \n强化石不是百分百强化成功的注意!");   
	SetPanelTitle(menu, line); 
	Format(line, sizeof(line), "说明: 强化枪械的材料(价格点卷:200)");   
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "购买");    
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
   
	SendPanelToClient(menu, Client, MenuHandler_qhsa, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_qhsa(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
			case 1: qhsb(Client);					
		}
	}
}
public qhsb(Client)
{
    if(Qcash[Client] >= 200)
    {
        Qcash[Client] -= 200;
        Qhs[Client]++;
        CPrintToChat(Client, "\x05【提示】你购买了强化石 当前剩余点卷%d!", Qcash[Client]);	CPrintToChatAll("\x05【提示】玩家 %N 通过点卷商店购买了一块强化石!", Client);
    } else CPrintToChat(Client, "\x05【提示】购买失败,点卷不足!");	 
}

public Action:MenuFunc_FHB(Client)
{
	new Handle:menu = CreatePanel();	
    
	decl String:line[1024];   
	Format(line, sizeof(line), "═══购买复活币═══");   
	SetPanelTitle(menu, line); 
	Format(line, sizeof(line), "说明: 随机复活到任何一个队友旁边(价格点卷:200)");   
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "购买");    
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
   
	SendPanelToClient(menu, Client, MenuHandler_FHB, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_FHB(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
			case 1: FHBGM(Client);					
		}
	}
}

public FHBGM(Client)
{
    if(Qcash[Client] >= 200 && PlayerXHItemSize[Client] - GetHasXHItemCount(Client) >= 1) 
    {
        Qcash[Client] -= 200;
        PlayerItem[Client][ITEM_XH][9] += 1;
        CPrintToChat(Client, "\x05【提示】你购买了复活币 当前剩余点卷%d!", Qcash[Client]);	CPrintToChatAll("\x05【提示】玩家 %N 通过点卷商店购买了一枚复活币!", Client);
    } else CPrintToChat(Client, "\x05【提示】购买失败,点卷不足或者你没有足够的消耗物品栏!");	 
} 




//VIP装备
public Action:MenuFunc_VIPSC(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买极品神器装备套装】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "治疗术效果增强装备[永久]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "生命值效果增强装备[永久]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "攻击力效果增强装备[永久]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "魔法值效果增强装备[永久]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "多属性效果增强套装[永久]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "夏季套装[永久/7W点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "夏季套装[30天/2W点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPSC, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPSC(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_VIPA(Client);
			case 2: MenuFunc_VIPB(Client);
			case 3: MenuFunc_VIPC(Client);
			case 4: MenuFunc_VIPD(Client);
			case 5: MenuFunc_VIPE(Client);
			case 6: VIPF(Client);
			case 7: VIPG(Client);
		}
	}
}
//VIP套装
public Action:MenuFunc_VIPA(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买治疗术效果增强装备】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "活力宝珠[永久/1400点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "多兰之剑[永久/2800点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "再生坠饰[永久/4200点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "哲理之石[永久/5600点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "精神之貌[永久/7000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "自然之力[永久/8400点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPA, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPA(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIP_1(Client);
			case 2: VIP_2(Client);
			case 3: VIP_3(Client);
			case 4: VIP_4(Client);
			case 5: VIP_5(Client);
			case 6: VIP_6(Client);
		}
	}
}
//VIP套装
public Action:MenuFunc_VIPB(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买生命值效果增强装备[】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "多兰之盾[永久/1000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "多兰之戒[永久/2000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "红宝石水晶[永久/3000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "黄金之心 [永久/4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "巨人腰带[永久/5000点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPB, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPB(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIP_7(Client);
			case 2: VIP_8(Client);
			case 3: VIP_9(Client);
			case 4: VIP_10(Client);
			case 5: VIP_11(Client);
		}
	}
}
//VIP套装
public Action:MenuFunc_VIPC(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买攻击力效果增强装备】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "长剑[永久/1000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "长柄战斧[永久/1000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "麦瑞得的拳刃[永久/2000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "熔岩巨剑[永久/3000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "黑色屠刀[永久/3000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "永恒之刃[永久/4000点卷/件]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "最后的轻语[永久/4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "残暴[永久/5000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "幻影之舞[永久/6000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "饮血剑[永久/7000点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPC, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPC(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIP_12(Client);
			case 2: VIP_13(Client);
			case 3: VIP_14(Client);
			case 4: VIP_15(Client);
			case 5: VIP_16(Client);
			case 6: VIP_17(Client);
			case 7: VIP_18(Client);
			case 8: VIP_19(Client);
			case 9: VIP_20(Client);
			case 10: VIP_21(Client);
		}
	}
}
//VIP套装
public Action:MenuFunc_VIPD(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买魔法值效果增强装备】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "贤者之戒[永久/2000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "女神之泪[永久/3000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "冰川之冠[永久/4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "仲亚之戒[永久/5000点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPD, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPD(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIP_22(Client);
			case 2: VIP_23(Client);
			case 3: VIP_24(Client);
			case 4: VIP_25(Client);
		}
	}
}
//VIP套装
public Action:MenuFunc_VIPE(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【购买多属性效果增强套装】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "警告:如果已有装备,时间不会增加，并且只能覆盖原有装备!");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冥火之拥[永久/10000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "霸王血铠[永久/14000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "兰顿之兆[永久/18000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "狂徒铠甲[永久/20000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "三相之力[永久/30000点卷]");
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPE, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_VIPE(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIPSQ_QNSQ(Client);
			case 2: VIPSQ_MFCBZ(Client);
			case 3: VIPSQ_ENTZ(Client);
			case 4: VIPSQ_SWTZ(Client);
			case 5: VIPSQ_EMTZ(Client);
		}
	}
}

public VIP_1(Client)
{   
	if(Qcash[Client] >= 1400)    
	{       
		Qcash[Client] -= 1400;		
		PlayerItem[Client][ITEM_ZB][10] += 999999;     
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的活力宝珠!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_2(Client)
{   
	if(Qcash[Client] >= 2800)    
	{       
		Qcash[Client] -= 2800;		
		PlayerItem[Client][ITEM_ZB][11] += 999999;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的多兰之剑!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_3(Client)
{   
	if(Qcash[Client] >= 4200)    
	{       
		Qcash[Client] -= 4200;		
		PlayerItem[Client][ITEM_ZB][12] += 999999;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的再生坠饰!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_4(Client)
{   
	if(Qcash[Client] >= 5600)    
	{       
		Qcash[Client] -= 5600;		
		PlayerItem[Client][ITEM_ZB][13] += 999999;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的哲理之石!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_5(Client)
{   
	if(Qcash[Client] >= 7000)    
	{       
		Qcash[Client] -= 7000;		
		PlayerItem[Client][ITEM_ZB][14] += 999999;         
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的精神之貌!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_6(Client)
{   
	if(Qcash[Client] >= 8400)    
	{       
		Qcash[Client] -= 8400;		
		PlayerItem[Client][ITEM_ZB][15] += 999999;         
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的自然之力!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}



public VIP_7(Client)
{   
	if(Qcash[Client] >= 1000)    
	{       
		Qcash[Client] -= 1000;		
		PlayerItem[Client][ITEM_ZB][16] += 999999;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的多兰之盾!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_8(Client)
{   
	if(Qcash[Client] >= 2000)    
	{       
		Qcash[Client] -= 2000;		
		PlayerItem[Client][ITEM_ZB][17] += 999999;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的多兰之戒!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_9(Client)
{   
	if(Qcash[Client] >= 3000)    
	{       
		Qcash[Client] -= 3000;		
		PlayerItem[Client][ITEM_ZB][18] += 999999;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的红宝石水晶!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_10(Client)
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_ZB][19] += 999999;      
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的黄金之心!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_11(Client)
{   
	if(Qcash[Client] >= 5000)    
	{       
		Qcash[Client] -= 5000;		
		PlayerItem[Client][ITEM_ZB][20] += 999999;      
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的巨人腰带!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}


public VIP_12(Client)
{   
	if(Qcash[Client] >= 1000)    
	{       
		Qcash[Client] -= 1000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"21\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的长剑!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_13(Client)
{   
	if(Qcash[Client] >= 1000)    
	{       
		Qcash[Client] -= 1000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"22\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的长柄战斧!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_14(Client)
{   
	if(Qcash[Client] >= 2000)    
	{       
		Qcash[Client] -= 2000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"23\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的麦瑞得的拳刃!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_15(Client)
{   
	if(Qcash[Client] >= 3000)    
	{       
		Qcash[Client] -= 3000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"24\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的熔岩巨剑!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_16(Client)
{   
	if(Qcash[Client] >= 3000)    
	{       
		Qcash[Client] -= 3000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"25\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的黑色屠刀!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_17(Client)
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"26\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的永恒之刃!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_18(Client)
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"27\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的最后的轻语!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_19(Client)
{   
	if(Qcash[Client] >= 5000)    
	{       
		Qcash[Client] -= 5000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"28\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的残暴!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_20(Client)
{   
	if(Qcash[Client] >= 6000)    
	{       
		Qcash[Client] -= 6000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"29\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的幻影之舞!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_21(Client)
{   
	if(Qcash[Client] >= 7000)    
	{       
		Qcash[Client] -= 7000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"30\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的饮血剑!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}


public VIP_22(Client)
{   
	if(Qcash[Client] >= 2000)    
	{       
		Qcash[Client] -= 2000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"31\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的贤者之戒!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_23(Client)
{   
	if(Qcash[Client] >= 3000)    
	{       
		Qcash[Client] -= 3000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"32\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的女神之泪!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_24(Client)
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"33\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的冰川之冠!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIP_25(Client)
{   
	if(Qcash[Client] >= 5000)    
	{       
		Qcash[Client] -= 5000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"34\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的仲亚之戒!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}




public VIPSQ_QNSQ(Client)//冥火之拥套装
{   
	if(Qcash[Client] >= 10000)    
	{       
		Qcash[Client] -= 10000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"5\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的冥火之拥套装!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIPSQ_MFCBZ(Client)//霸王血铠
{   
	if(Qcash[Client] >= 14000)    
	{       
		Qcash[Client] -= 14000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"6\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久天霸王血铠!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIPSQ_EMTZ(Client)//兰顿之兆
{   
	if(Qcash[Client] >= 18000)    
	{       
		Qcash[Client] -= 18000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"7\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的兰顿之兆!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIPSQ_SWTZ(Client)//狂徒铠甲
{   
	if(Qcash[Client] >= 20000)    
	{       
		Qcash[Client] -= 20000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"8\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的狂徒铠甲!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}
public VIPSQ_ENTZ(Client)//三相之力
{   
	if(Qcash[Client] >= 30000)    
	{       
		Qcash[Client] -= 30000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"9\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的三相之力!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}

public VIPF(Client)//夏季套装
{   
	if(Qcash[Client] >= 70000)    
	{       
		Qcash[Client] -= 70000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"4\" \"999999\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x05永久的夏季套装!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}

public VIPG(Client)//夏季套装
{   
	if(Qcash[Client] >= 20000)    
	{       
		Qcash[Client] -= 20000;		
		ServerCommand("sm_setitem_957 \"%N\" \"1\" \"4\" \"30\"", Client);       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0530天的夏季套装!", Client);	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
}



//20卷轴
public Action:MenuFunc_Xhpsd(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【在购买前请确认有足够的消耗栏】\n拥有的点卷:%d个", Qcash[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "可以购买古代卷轴！不能多次购买！");
	
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "全体召唤卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全体狂暴卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全体嗜血卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全体换弹卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "生命恢复卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "魔力恢复卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "圣光保护卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "全体无敌卷20个[4000点卷]");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Xhpsd, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_Xhpsd(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: VIPQTZHJ(Client);
			case 2: VIPQTKBJ(Client);
			case 3: VIPQTSXJ(Client);
			case 4: VIPQTHDJ(Client);
			case 5: VIPSMHFJ(Client);
            case 6: VIPMLHFJ(Client);
			case 7: VIPSGBHJ(Client);
			case 8: VIPSGYLJ(Client);
			case 9: MenuFunc_Buy(Client);
		}
	}
}

public VIPQTZHJ(Client)//戒指
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][0] += 20;         
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个全体召唤卷!", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
public VIPQTKBJ(Client)//鞋子
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][1] += 20;          
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个全体狂暴卷!", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
public VIPQTSXJ(Client)//血盾
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][2] += 20;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个全体生物专家卷!", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
public VIPQTHDJ(Client)//风衣
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][3] += 20;        
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个全体换弹卷!", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}

public VIPSMHFJ(Client)//弹药
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][4] += 20;      
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个生命恢复卷!", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
public VIPMLHFJ(Client)//项链
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][5] += 20;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个魔力恢复卷!", Client);	    
	} else CPrintToChat(Client, "{red}【提示】你没有足够的点卷!");
}

public VIPSGBHJ(Client)//枪膛
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000;		
		PlayerItem[Client][ITEM_XH][6] += 20;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个圣光保护卷", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
public VIPSGYLJ(Client)//鞋子
{   
	if(Qcash[Client] >= 4000)    
	{       
		Qcash[Client] -= 4000		
		PlayerItem[Client][ITEM_XH][7] += 20;       
		CPrintToChat(Client, "\x03[系统]\04%N在\x05点卷商店\x04购买了\x0520个全体无敌卷", Client);	    
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}


/* 开局补给装备 */
public Action:MenuFunc_Bugei(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【开局补给基础装备】");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "领取");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Bugei, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_Bugei(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: LQIHUANB(Client);
		}
	}
}
public LQIHUANB(Client)
{
	if(VIP[Client] <= 0)
	{
		CheatCommand(Client, "give", "rifle");   //M16
		CheatCommand(Client, "give", "machete");  //斩马刀
		CheatCommand(Client, "give", "first_aid_kit");  //药包
		CPrintToChatAll("\x05【系统】玩家%N领取了开局补给基础装备:M16+斩马刀+药包", Client);
		PrintHintText(Client, "{yellow}【提示】你领取了开局补给装备!");
	}
	else if(VIP[Client] > 0)
	{
		CheatCommand(Client, "give", "rifle");   //M16
		CheatCommand(Client, "give", "katana");   //武士刀
		CheatCommand(Client, "upgrade_add", "laser_sight");   //激光
		CPrintToChatAll("\x05【系统】VIP玩家%N领取了开局补给基础装备:激光AK47+武士刀", Client);
		PrintHintText(Client, "{yellow}【提示】你领取了开局补给装备!");
	}
}

/* 兑换游戏币 */
public Action:MenuFunc_Dbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【游戏币兑换】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:用点卷兑换一定数量游戏币!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "兑换100000$【点卷:1000】");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "兑换500000$【点卷:5000】");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "兑换1000000$【点卷:10000】");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回点卷商城");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Dbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Dbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: DUIHUANB(Client);
			case 2: DUIHUANZ(Client);
			case 3: DUIHUANC(Client);
			case 4: MenuFunc_Qiubuy(Client);
		}
	}
}
public DUIHUANB(Client)
{   
	if(Qcash[Client] >= 1000)    
	{       
		Cash[Client] += 100000;		
		Qcash[Client] -= 1000;       
		CPrintToChat(Client, "\x05【提示】你成功兑换100000$!");	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
	MenuFunc_Dbuy(Client)
}
public DUIHUANZ(Client)
{    
	if(Qcash[Client] >= 5000)    
	{       
		Cash[Client] += 500000;		
		Qcash[Client] -= 5000;        
		CPrintToChat(Client, "\x05【提示】你成功兑换500000$!");	    
	} else CPrintToChat(Client, "\x05【提示】你没有足够的点卷!");
	MenuFunc_Dbuy(Client)
}
public DUIHUANC(Client)
{    
	if(Qcash[Client] >= 10000)    
	{        
		Cash[Client] += 1000000;		
		Qcash[Client] -= 10000;       
		CPrintToChat(Client, "{green}【提示】你成功兑换1000000$!");	   
	} else CPrintToChat(Client, "{green}【提示】你没有足够的点卷!");
	MenuFunc_Dbuy(Client)
}

/* VIP购买 */
public Action:MenuFunc_Vbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【VIP购买】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:购买VIP特权!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "购买白金VIP1");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "购买黄金VIP2");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "购买水晶VIP3");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "购买至尊VIP4");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回点卷商城");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_Vbbuy(Client);
			case 2: MenuFunc_Vhbuy(Client);
			case 3: MenuFunc_Vsbuy(Client);
			case 4: MenuFunc_Vzbuy(Client);
			case 5: MenuFunc_Qiubuy(Client);
		}
	}
}

/* 购买白金VIP */
public Action:MenuFunc_Vbbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【白金VIP】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:所需6000个点卷【30天期限】!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回VIP购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vbbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vbbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: Bjque(Client);
			case 2: MenuFunc_Qiubuy(Client);
		}
	}
}
public Bjque(Client)
{
    if(Qcash[Client] >= 6000)
    {
        Qcash[Client] -= 6000;
        ServerCommand("sm_setvip_845 \"%N\" \"1\" \"30\"", Client); 
        CPrintToChat(Client, "\x03【VIP1】你成功购买了白金VIP1!");	
        CPrintToChatAll("\x03【VIP1】恭喜玩家%N成为白金VIP1", Client);
    } else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
/* 购买白金VIP */
/*public Action:MenuFunc_Vbbuyxf(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【VIP续费】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:现有VIP续费【延长30天期限】!");
    DrawPanelText(menu, line);
    Format(line, sizeof(line), "白金4000点卷 黄金6000点卷 水晶10000点卷!");
    DrawPanelText(menu, line);
    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回VIP购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vbbuyxf, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vbbuyxf(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: Bjquexf(Client);
			case 2: MenuFunc_Qiubuy(Client);
		}
	}
}
public Bjquexf(Client)
{
   if (VIP[Client] == 1 && Qcash[Client] >= 4000)
   {     Qcash[Client] -= 4000;
        ServerCommand("sm_setvip_845 \"%N\" \"VIPTL\" \"30\" \"+\"", Client); 
        CPrintToChat(Client, "\x03【VIP1】你成功续费了白金VIP1! 30天");	
        CPrintToChatAll("\x03【VIP1】恭喜玩家%N续费白金VIP1 30天", Client);
   } else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
   else if (VIP[Client] == 2 && Qcash[Client] >= 6000 )
   {    Qcash[Client] -= 6000;
        ServerCommand("sm_setvip_845 \"%N\" \"VIPTL\" \"30\" \"+\"", Client); 
        CPrintToChat(Client, "\x03【VIP2】你成功续费了黄金VIP2! 30天");	
        CPrintToChatAll("\x03【VIP2】恭喜玩家%N续费白金VIP2 30天", Client);
   } else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
   else if (VIP[Client] == 2 && Qcash[Client] >= 10000)
   { Qcash[Client] -= 10000;
        ServerCommand("sm_setvip_845 \"%N\" \"VIPTL\" \"30\" \"+\"", Client); 
        CPrintToChat(Client, "\x03【VIP3】你成功续费了水晶VIP3! 30天");	
        CPrintToChatAll("\x03【VIP3】恭喜玩家%N续费水晶VIP3 30天", Client);
   } else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");   } 
} 	*/

/* 购买黄金VIP */
public Action:MenuFunc_Vhbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【黄金VIP2】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:所需8000个点卷【30天期限】!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回VIP购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vhbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vhbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: Hjque(Client);
			case 2: MenuFunc_Qiubuy(Client);
		}
	}
}
public Hjque(Client)
{
    if(Qcash[Client] >= 8000)
    {
        Qcash[Client] -= 8000;
        ServerCommand("sm_setvip_845 \"%N\" \"2\" \"30\"", Client); 
        CPrintToChat(Client, "\x03【VIP2】你成功购买了黄金VIP!");	
        CPrintToChatAll("\x03【VIP2】恭喜玩家%N成为黄金VIP", Client);
    } else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}

/* 购买水晶VIP */
public Action:MenuFunc_Vsbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【水晶VIP3】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:所需10000个点卷【30天期限】!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回VIP购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vsbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vsbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: Sjque(Client);
			case 2: MenuFunc_Qiubuy(Client);
		}
	}
}
public Sjque(Client)
{   
	if(Qcash[Client] >= 10000)    
	{      
		Qcash[Client] -= 10000;	    
		ServerCommand("sm_setvip_845 \"%N\" \"3\" \"30\"", Client);         
		CPrintToChat(Client, "\x03【VIP3】你成功购买了水晶VIP3!");	       
		CPrintToChatAll("\x03【VIP3】恭喜玩家%N成为水晶VIP3", Client);   
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}
/* 购买至尊VIP4 */
public Action:MenuFunc_Vzbuy(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【至尊VIP4】\n拥有的点卷:%d个", Qcash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "说明:所需16000个点卷【30天期限】!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回VIP购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_Vzbuy, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_Vzbuy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: zzque(Client);
			case 2: MenuFunc_Qiubuy(Client);
		}
	}
}
public zzque(Client)
{   
	if(Qcash[Client] >= 16000)    
	{      
		Qcash[Client] -= 16000;	    
		ServerCommand("sm_setvip_845 \"%N\" \"4\" \"30\"", Client);         
		CPrintToChat(Client, "\x03【VIP3】你成功购买了至尊VIP4!");	       
		CPrintToChatAll("\x03【VIP3】恭喜玩家%N成为至尊VIP4", Client);   
	} else CPrintToChat(Client, "\x03【提示】你没有足够的点卷!");
}


/* 抽奖赌博 */
public MenuFunc_LotteryCasino(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_LotteryCasino);
	decl String:line[32];
	
	SetMenuTitle(menu, "金钱: %d$ 记大过: %d次", Cash[Client], KTCount[Client]);
	AddMenuItem(menu, "option0", "购买大乐透号码");
	AddMenuItem(menu, "option1", "查看其他玩家大乐透号码");
	
	Format(line, sizeof(line), "彩票抽奖(%d次)", Lottery[Client]);
	AddMenuItem(menu, "option1", line);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public MenuHandler_LotteryCasino(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: MenuFunc_Casino(Client);
			case 1: MenuFunc_DaLeTouView(Client);
			case 2: MenuFunc_Lottery(Client);
		}
	} 
	else if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack)
			MenuFunc_Buy(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}


/* robot专门店 */
public MenuFunc_RobotBuy(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_RobotBuy);
	SetMenuTitle(menu, "金钱: %d$ 记大过: %d次", Cash[Client], KTCount[Client]);
	AddMenuItem(menu, "option0", "机器人购买商店");
	AddMenuItem(menu, "option1", "机器人升级属性");
	if (Robot_appendage[Client] == 0)
	{
		AddMenuItem(menu,"option2","学习克隆机器人");
	}
	else if(Robot_appendage[Client] > 0 && robot[Client] > 0)	//如果机器人卡住了,可以重新分配机器人
	{
		AddMenuItem(menu,"option2","重启克隆机器人");
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public MenuHandler_RobotBuy(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: MenuFunc_RobotShop(Client);
			case 1: MenuFunc_RobotWorkShop(Client);
			case 2: MenuFunc_RobotAppend(Client);
		}
	} 
	else if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack)
			MenuFunc_Buy(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

//克隆机器人
public Action:MenuFunc_RobotAppend(Client)
{
	//重启克隆机器人
	if(Robot_appendage[Client] > 0 && robot[Client] > 0)
	{
		Release(Client);
		AddRobot(Client);
		AddRobot_clone(Client);
		return Plugin_Handled;
	}
	new Handle:menu = CreatePanel();
	decl String:line[256];
	Format(line,sizeof(line),"克隆机器人说明:\n学习后在机器人商店购买机器人后会多出现一把同样的机器人!\n价格:10000个点卷");
	SetPanelTitle(menu,line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "放弃");
	
	SendPanelToClient(menu, Client, MenuHandler_RobotAppend, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;

}
//克隆机器人学习
public MenuHandler_RobotAppend(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1: ClientBuyRobotAppend(Client);
			case 2: return;
		}
	}
}

public ClientBuyRobotAppend(Client)
{
	if(Qcash[Client] >= 10000)
	{
		Qcash[Client] -= 10000;
		Robot_appendage[Client]++;
		CPrintToChatAll("【提示】恭喜 %N 成功学习克隆机器人技能!",Client);
	}
	else
	{
		CPrintToChat(Client,"【提示】学习克隆机器人技能失败，点卷不够!");
	}
}

/* 投掷品，药物和子弹盒 */
public Action:Menu_NormalItemShop(Client,args)
{
	if(GetClientTeam(Client) == 2 && !IsFakeClient(Client) && GetConVarBool(CfgNormalItemShopEnable))
	{
		MenuFunc_NormalItemShop(Client);
	}
	else if(!IsFakeClient(Client))
	{
		CPrintToChat(Client, "{red}只限幸存者选择!");
	}
	else if(!GetConVarBool(CfgNormalItemShopEnable))
	{
		CPrintToChat(Client, "\x05商店己关闭!");
	}
	return Plugin_Handled;
}

public Action:MenuFunc_NormalItemShop(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_NormalItemShop);
	SetMenuTitle(menu, "金钱: %d $", Cash[Client]);

	decl String:line[64], String:option[32];
	for(new i=0; i<NORMALITEMMAX; i++)
	{
		if(VIP[Client] <= 0)
			Format(line, sizeof(line), "%s($%d)", NormalItemName[i], GetConVarInt(CfgNormalItemCost[i]));
		else if(VIP[Client] == 1)
			Format(line, sizeof(line), "%s(Vip:$%d)", NormalItemName[i], RoundToNearest(GetConVarInt(CfgNormalItemCost[i]) * 0.8));
		else if(VIP[Client] == 2)
			Format(line, sizeof(line), "%s(Vip:$%d)", NormalItemName[i], RoundToNearest(GetConVarInt(CfgNormalItemCost[i]) * 0.6));
		else if(VIP[Client] == 3)
			Format(line, sizeof(line), "%s(Vip:$%d)", NormalItemName[i], RoundToNearest(GetConVarInt(CfgNormalItemCost[i]) * 0.5));
		else if(VIP[Client] == 4)
			Format(line, sizeof(line), "%s(Vip:$%d)", NormalItemName[i], RoundToNearest(GetConVarInt(CfgNormalItemCost[i]) * 0.4));
			
		Format(option, sizeof(option), "option%d", i+1);
		AddMenuItem(menu, option, line);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}
public MenuHandler_NormalItemShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select)  {
		new targetcash = Cash[Client];
		new itemcost = VIPAdd(Client, GetConVarInt(CfgNormalItemCost[itemNum]), 2, false);

		if(targetcash >= itemcost) {
			targetcash -= itemcost;
			switch (itemNum)
			{
				case 0: NormalItemShop_Ammo(Client);
				case 1: CheatCommand(Client, "upgrade_add", "laser_sight"); //获得红外线瞄准
				case 2: CheatCommand(Client, "upgrade_add", "explosive_ammo"); //高爆弹
				case 3: CheatCommand(Client, "upgrade_add", "Incendiary_ammo"); //燃烧弹
				case 4: CheatCommand(Client, "give", "first_aid_kit");
				case 5: CheatCommand(Client, "give", "pain_pills");
				case 6: CheatCommand(Client, "give", "adrenaline");
				case 7: CheatCommand(Client, "give", "defibrillator");
				case 8: CheatCommand(Client, "give", "molotov");
				case 9: CheatCommand(Client, "give", "pipe_bomb");
				case 10: CheatCommand(Client, "give", "vomitjar");
				case 11: CheatCommand(Client, "give", "upgradepack_explosive");
				case 12: CheatCommand(Client, "give", "upgradepack_incendiary");
				case 13: CheatCommand(Client, "give", "oxygentank");
				case 14: CheatCommand(Client, "give", "propanetank");
			}
			Cash[Client] = targetcash;
			CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
		}
		else CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
		MenuFunc_NormalItemShop(Client);
	} else if (action == MenuAction_End) CloseHandle(menu);
}

/* 子弹购买 */
public NormalItemShop_Ammo(Client)
{
	if (!IsValidPlayer(Client, false))
		return;
	
	CheatCommand(Client, "give", "ammo");
	/*
	new weaponid = GetPlayerWeaponSlot(Client, 0);
	new String:name[64];
	if (weaponid >= 0)
	{
		GetEdictClassname(weaponid, name, sizeof(name));
		if (StrContains(name, "rifle_m60", false) >= 0)
			SetEntProp(weaponid, Prop_Send, "m_iClip1", 250);
		else
			CheatCommand(Client, "give", "ammo");		
	}
	else
		CheatCommand(Client, "give", "ammo");
	*/
}

/* 特选枪械 */
public Action:Menu_SelectedGunShop(Client,args)
{
	if(GetClientTeam(Client) == 2 && !IsFakeClient(Client) && GetConVarBool(CfgSelectedGunShopEnable))
		MenuFunc_SelectedGunShop(Client);
	else if(!IsFakeClient(Client))
		CPrintToChat(Client, "{red}只限幸存者选择!");
	else if(!GetConVarBool(CfgSelectedGunShopEnable))
		CPrintToChat(Client, "\x05商店己关闭!");

	return Plugin_Handled;
}

public Action:MenuFunc_SelectedGunShop(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_SelectedGunShop);
	SetMenuTitle(menu, "金钱: %d $", Cash[Client]);

	decl String:line[64], String:option[32];
	for(new i=0; i<SELECTEDGUNMAX; i++)
	{
		if(VIP[Client] <= 0)
			Format(line, sizeof(line), "%s($%d)", GunName[i], GetConVarInt(CfgSelectedGunCost[i]));
		else if(VIP[Client] == 1)
			Format(line, sizeof(line), "%s(Vip:$%d)", GunName[i], RoundToNearest(GetConVarInt(CfgSelectedGunCost[i]) * 0.8));
		else if(VIP[Client] == 2)
			Format(line, sizeof(line), "%s(Vip:$%d)", GunName[i], RoundToNearest(GetConVarInt(CfgSelectedGunCost[i]) * 0.6));
		else if(VIP[Client] == 3)
			Format(line, sizeof(line), "%s(Vip:$%d)", GunName[i], RoundToNearest(GetConVarInt(CfgSelectedGunCost[i]) * 0.5));
		else if(VIP[Client] == 4)
			Format(line, sizeof(line), "%s(Vip:$%d)", GunName[i], RoundToNearest(GetConVarInt(CfgSelectedGunCost[i]) * 0.4));
			
		Format(option, sizeof(option), "option%d", i+1);
		AddMenuItem(menu, option, line);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public MenuHandler_SelectedGunShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) {
		new targetcash = Cash[Client];
		new itemcost = VIPAdd(Client, GetConVarInt(CfgSelectedGunCost[itemNum]), 2, false);

		if(targetcash >= itemcost) {
			targetcash -= itemcost;
			switch (itemNum)
			{
				case 0: CheatCommand(Client, "give", "smg_mp5");
				case 1: CheatCommand(Client, "give", "sniper_scout");
				case 2: CheatCommand(Client, "give", "sniper_awp");
				case 3: CheatCommand(Client, "give", "rifle_sg552");
				case 4: CheatCommand(Client, "give", "rifle_m60");
				case 5: CheatCommand(Client, "give", "grenade_launcher");
				case 6: CheatCommand(Client, "give", "rifle_ak47");
				case 7: CheatCommand(Client, "give", "shotgun_spas");
				case 8: CheatCommand(Client, "give", "rifle");
			}
			Cash[Client] = targetcash;
			CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
		}
		else CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
		MenuFunc_SelectedGunShop(Client);
	} else if (action == MenuAction_End) CloseHandle(menu);
}
/* 近武商店 */
public Action:Menu_MeleeShop(Client,args)
{
	if(GetClientTeam(Client) == 2 && !IsFakeClient(Client) && GetConVarBool(CfgMeleeShopEnable))
	{
		MenuFunc_MeleeShop(Client);
	}
	else if(!IsFakeClient(Client))
	{
		CPrintToChat(Client, "{red}只限幸存者选择!");
	}
	else if(!GetConVarBool(CfgMeleeShopEnable))
	{
		CPrintToChat(Client, "\x05商店己关闭!");
	}
	return Plugin_Handled;
}

public Action:MenuFunc_MeleeShop(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_MeleeShop);
	SetMenuTitle(menu, "金钱: %d $", Cash[Client]);

	decl String:line[64], String:option[32];
	for(new i=0; i<SELECTEDMELEEMAX; i++)
	{
		if(VIP[Client] <= 0)
			Format(line, sizeof(line), "%s($%d)", MeleeName[i], GetConVarInt(CfgMeleeCost[i]));
		else if(VIP[Client] == 1)
			Format(line, sizeof(line), "%s(Vip:$%d)", MeleeName[i], RoundToNearest(GetConVarInt(CfgMeleeCost[i]) * 0.8));
		else if(VIP[Client] == 2)
			Format(line, sizeof(line), "%s(Vip:$%d)", MeleeName[i], RoundToNearest(GetConVarInt(CfgMeleeCost[i]) * 0.6));
		else if(VIP[Client] == 3)
			Format(line, sizeof(line), "%s(Vip:$%d)", MeleeName[i], RoundToNearest(GetConVarInt(CfgMeleeCost[i]) * 0.5));
		else if(VIP[Client] == 4)
			Format(line, sizeof(line), "%s(Vip:$%d)", MeleeName[i], RoundToNearest(GetConVarInt(CfgMeleeCost[i]) * 0.4));

		Format(option, sizeof(option), "option%d", i+1);
		AddMenuItem(menu, option, line);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}
public MenuHandler_MeleeShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) {
		new targetcash = Cash[Client];
		new itemcost = VIPAdd(Client, GetConVarInt(CfgMeleeCost[itemNum]), 2, false);

		if(targetcash >= itemcost) {
			targetcash -= itemcost;
			switch (itemNum)
			{
				case 0: CheatCommand(Client, "give", "baseball_bat");
				case 1: CheatCommand(Client, "give", "cricket_bat");
				case 2: CheatCommand(Client, "give", "crowbar");
				case 3: CheatCommand(Client, "give", "electric_guitar");
				case 4: CheatCommand(Client, "give", "fireaxe");
				case 5: CheatCommand(Client, "give", "frying_pan");
				case 6: CheatCommand(Client, "give", "golfclub");
				case 7: CheatCommand(Client, "give", "katana");
				case 8: CheatCommand(Client, "give", "hunting_knife");
				case 9: CheatCommand(Client, "give", "machete");
				case 10: CheatCommand(Client, "give", "riotshield");
				case 11: CheatCommand(Client, "give", "tonfa");
//				case 12: CheatCommand(Client, "give", "tonfa");
//				case 12: CheatCommand(Client, "give", "chainsaw");
			}
			Cash[Client] = targetcash;
			CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
		}
		else CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
		MenuFunc_MeleeShop(Client);
	} else if (action == MenuAction_End) CloseHandle(menu);
}
/* Robot商店 */
public Action:Menu_RobotShop(Client,args)
{
	if(GetClientTeam(Client) == 2 && !IsFakeClient(Client))
	{
		MenuFunc_RobotShop(Client);
	}
	else if(!IsFakeClient(Client))
	{
		CPrintToChat(Client, "{red}暂时只限幸存者选择!");
	}
	return Plugin_Handled;
}

public Action:MenuFunc_RobotShop(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_RobotShop);
	SetMenuTitle(menu, "金钱: %d $ 机器人使用次数: %d", Cash[Client], RobotCount[Client]);

	decl String:line[64], String:option[32];
	for(new i=0; i<WEAPONCOUNT; i++)
	{
		if(VIP[Client] <= 0)
			Format(line, sizeof(line), "[%s]机器人($%d)", WeaponName[i], GetConVarInt(CfgRobotCost[i])*(RobotCount[Client]+1));
		else if(VIP[Client] == 1)
			Format(line, sizeof(line), "[%s]机器人(Vip:$%d)", WeaponName[i], RoundToNearest(GetConVarInt(CfgRobotCost[i])*(RobotCount[Client]+1) * 0.8));
		else if(VIP[Client] == 2)
			Format(line, sizeof(line), "[%s]机器人(Vip:$%d)", WeaponName[i], RoundToNearest(GetConVarInt(CfgRobotCost[i])*(RobotCount[Client]+1) * 0.6));
		else if(VIP[Client] == 3)
			Format(line, sizeof(line), "[%s]机器人(Vip:$%d)", WeaponName[i], RoundToNearest(GetConVarInt(CfgRobotCost[i])*(RobotCount[Client]+1) * 0.5));
		else if(VIP[Client] == 4)
			Format(line, sizeof(line), "[%s]机器人(Vip:$%d)", WeaponName[i], RoundToNearest(GetConVarInt(CfgRobotCost[i])*(RobotCount[Client]+1) * 0.4));

		Format(option, sizeof(option), "option%d", i+1);
		AddMenuItem(menu, option, line);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}
public MenuHandler_RobotShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select)
	{
		new targetcash = Cash[Client];
		new itemcost = VIPAdd(Client, GetConVarInt(CfgRobotCost[itemNum])*(RobotCount[Client]+1), 2, false);
		if(itemcost == 16)
		{
			MenuFunc_Buy(Client);
		}
		else if(targetcash >= itemcost)
		{
			if(MP[Client] >= 10000 && Robot_appendage[Client] > 0 && robot[Client] == 0)
			{
				MP[Client] -= 10000;
				botenerge[Client] = 0.0;		//机器人能量
				RobotCount[Client] += 1;
				//Cash[Client] = targetcash;
				CPrintToChat(Client,"{olive}【神枪附体】使用成功!");	
			}
			else
			{			
				targetcash -= itemcost;
				if(robot[Client] == 0)
				{
					botenerge[Client] = 0.0;		//机器人能量
					RobotCount[Client] += 1;
					Cash[Client] = targetcash;
					CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
				}
			}
			sm_robot(Client, itemNum);
		}
		else
		{
			CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
		}
	} else if (action == MenuAction_End) CloseHandle(menu);
}

/* 神秘商店 */
public Action:MenuFunc_SpecialShop(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "金钱: %d$ 记大过: %d次", Cash[Client], KTCount[Client]);
	SetPanelTitle(menu, line);

	if(VIP[Client]>=1)
	{
	Format(line, sizeof(line), "会员经验之书 ($%d)", GetConVarInt(TomeOfExpCost)/2);
	DrawPanelItem(menu, line);
	}
	else
	{
	Format(line, sizeof(line), "经验之书 ($%d)", GetConVarInt(TomeOfExpCost));
	DrawPanelItem(menu, line);
	}
	Format(line, sizeof(line), "使用一次增加%d经验[会员半价]", GetConVarInt(TomeOfExpEffect));
	DrawPanelText(menu, line);

	Format(line, sizeof(line), "灵丹妙药 ($%d)", GetConVarInt(RemoveKTCost));
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "消除一次大过");
	DrawPanelText(menu, line);

	Format(line, sizeof(line), "漂白剂 ($%d)", GetConVarInt(ResetStatusCost));
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "洗点.");
	DrawPanelText(menu, line);

	Format(line, sizeof(line), "蓝瓶药水 ($%d)", GetConVarInt(ResumeMP));
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "喝了后可以快速恢复百分之50的MP.");
	DrawPanelText(menu, line);	
	
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_SpecialShop, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}

public MenuHandler_SpecialShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) {
		switch (itemNum) {
			case 1: {
				new itemcost	= GetConVarInt(TomeOfExpCost);  //TomeOfExpCost 是cfg文件里设置的经验之书价格
				new itemEffect	= GetConVarInt(TomeOfExpEffect);  //TomeOfExpEffect  是cfg文件里设置的经验之书增加经验
				if(VIP[Client] >= 1) //会员购买，如果是会员，价格变成一半
				{
					itemcost = itemcost/2;
				}
				if(Cash[Client] >= itemcost)  //现在的金钱大于cfg里设置的价格
				{
					EXP[Client] += itemEffect;    //本身增加cfg里设置的经验
					Cash[Client] -= itemcost;    //本身减少cfg里设置的金钱
					CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
				}
				else
				{
					CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
				}
				MenuFunc_SpecialShop(Client);
			} case 2: {
				new itemcost	= GetConVarInt(RemoveKTCost);

				if(KTCount[Client]>0)
				{
					if(Cash[Client] >= itemcost)
					{
						Cash[Client] -= itemcost;
						KTCount[Client] -=1;
						CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
					}
					else
					{
						CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
						MenuFunc_SpecialShop(Client);
					}
				} else CPrintToChat(Client, "{green}你暂时不需要购买此物品!");
			} 
			case 3: MenuFunc_SpecialShopConfirm(Client);
			case 4: {		
				new itemcost	= GetConVarInt(ResumeMP);
				
				if(Cash[Client] >= itemcost)
				{
					Cash[Client] -= itemcost;
					new resume = RoundToNearest(MaxMP[Client] * 0.5) + MP[Client];
					if (resume <= MaxMP[Client])
						MP[Client] = resume;
					else
						MP[Client] = MaxMP[Client];
						
					CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
					PrintHintText(Client, "你的MP已经恢复至%d ", MP[Client]);
				}
				else
				{
					CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
					MenuFunc_SpecialShop(Client);
				}		
				
			} case 5: MenuFunc_Buy(Client);
		}
		if (itemNum != 5 && itemNum != 3)
			MenuFunc_SpecialShop(Client);
	}
}

//忘情水购买确认
public Action:MenuFunc_SpecialShopConfirm(Client)
{
	new Handle:menu = CreatePanel();
	DrawPanelText(menu, "======================= \n是否确认够买忘情水? \n=======================");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "是");
	DrawPanelItem(menu, "否");
	
	SendPanelToClient(menu, Client, MenuHandler_SpecialShopConfirm, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_SpecialShopConfirm(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		switch (itemNum) 
		{
			case 1:
			{ 
				new itemcost	= GetConVarInt(ResetStatusCost);
				if(Cash[Client] >= itemcost)
				{
					Cash[Client] -= itemcost;
					ClinetResetStatus(Client, Shop);
					BindKeyFunction(Client);
					CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
				}
				else
				{
					CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
				}
			}
		}
	}
}

/* Robot工场*/
public Action:MenuFunc_RobotWorkShop(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[64];
	Format(line, sizeof(line), "金钱: %d $", Cash[Client]);
	SetPanelTitle(menu, line);
	
	for(new i=0; i<3; i++)
	{
		Format(line, sizeof(line), RobotUpgradeName[i], RobotUpgradeLv[Client][i], RobotUpgradeLimit[i], GetConVarInt(CfgRobotUpgradeCost[i]));
		DrawPanelItem(menu, line);
		switch (i)
		{
			case 0: Format(line, sizeof(line), RobotUpgradeInfo[0], RobotAttackEffect[Client]);
			case 1: Format(line, sizeof(line), RobotUpgradeInfo[1], RobotAmmoEffect[Client]);
			case 2: Format(line, sizeof(line), RobotUpgradeInfo[2], RobotRangeEffect[Client]);
		}
		DrawPanelText(menu, line);
	}
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	SendPanelToClient(menu, Client, MenuHandler_RobotWorkShop, MENU_TIME_FOREVER);
	
	CloseHandle(menu);

	return Plugin_Handled;
}

public MenuHandler_RobotWorkShop(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) {
		new targetcash = Cash[Client];
		new itemcost = GetConVarInt(CfgRobotUpgradeCost[itemNum-1]);

		if(RobotUpgradeLv[Client][itemNum-1] < RobotUpgradeLimit[itemNum-1])
		{
			if(targetcash >= itemcost) {
				targetcash -= itemcost;
				RobotUpgradeLv[Client][itemNum-1] += 1;
				Cash[Client] = targetcash;
				CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
				switch (itemNum)
				{
					case 1: CPrintToChat(Client, RobotUpgradeInfo[0], RobotAttackEffect[Client]);
					case 2: CPrintToChat(Client, RobotUpgradeInfo[1], RobotAmmoEffect[Client]);
					case 3: CPrintToChat(Client, RobotUpgradeInfo[2], RobotRangeEffect[Client]);
				}
			}
			else CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
		} else CPrintToChat(Client, MSG_ROBOT_UPGRADE_MAX);
		MenuFunc_RobotWorkShop(Client);
	}
}
/* 赌场 */
public Action:Menu_Casino(Client,args)
{
	MenuFunc_Casino(Client);
	return Plugin_Handled;
}

/* 大乐透 */
public MenuFunc_Casino(Client)
{
	decl String:info[64], String:line[128], Handle:menu, Float:DLT_lasttime;
	menu = CreateMenu(MenuHandler_Casino);
	if (DLT_Timer <= 60.0)
		DLT_lasttime = DLT_Timer, Format(info, sizeof(info), "秒");
	else
		DLT_lasttime = DLT_Timer / 60.0, Format(info, sizeof(info), "分钟");
		
	if (DLTNum[Client] > 0)
		Format(line, sizeof(line), "*********** \n还有 %.0f %s开奖 \n*********** \n你的金钱: %d $ \n你已购买[%d]开奖号码:", DLT_lasttime, info, Cash[Client], DLTNum[Client]);
	else
		Format(line, sizeof(line), "*********** \n还有 %.0f %s开奖 \n*********** \n你的金钱: %d $ \n你暂未购买开奖号码:", DLT_lasttime, info, Cash[Client]);
	
	SetMenuTitle(menu, line);

	for (new i = 1; i <= DLT_MaxNum; i++)
	{
		Format(info, sizeof(info), "item%d", i);
		Format(line, sizeof(line), "选择号码:[%d](价格:%d$)", i, DLTCash[i - 1]);
		if (DLTNum[Client] > 0)
			AddMenuItem(menu, info, line, ITEMDRAW_DISABLED);
		else
			AddMenuItem(menu, info, line);
	}


	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public MenuHandler_Casino(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select)
	{
		if (itemNum >= 0)
		{
			if(Cash[Client] >= DLTCash[itemNum])
			{
				Cash[Client] -= DLTCash[itemNum];
				DLTNum[Client] = itemNum + 1;
				PrintHintText(Client, "你已经成功购买大乐透,号码是:[%d],祝你中奖!", DLTNum[Client]);
				CPrintToChatAll("\x05[大乐透]\x03 \x05%N {red}花费\x05%d${red}在大乐透中购买了\x05[%d]{red}号码,祝他能中奖吧!", Client, DLTCash[itemNum], DLTNum[Client]);
			}
			else
				PrintHintText(Client, "你没有足够的金钱购买大乐透!");
		}
		
		MenuFunc_Casino(Client);
	} 
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

/* 大乐透_查看 */
public MenuFunc_DaLeTouView(Client)
{
	decl String:line[128], Handle:menu, has;
	has = 0;
	menu = CreateMenu(MenuHandler_Casino);	
	SetMenuTitle(menu, "查看本期已买号码和玩家:");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false))
		{
			if (DLTNum[i] > 0)
			{
				has++;
				Format(line, sizeof(line), "买家:%N 号码:[%d]", i, DLTNum[i]);
				AddMenuItem(menu, "item", line, ITEMDRAW_DISABLED);
			}
		}
	}
	
	if (has <= 0)
		AddMenuItem(menu, "item", "本期还未有玩家购买大乐透!", ITEMDRAW_DISABLED);
		
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
public MenuHandler_DaLeTouView(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack)
			MenuFunc_LotteryCasino(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

/* 大乐透_刷新 */
stock DaLeTou_Refresh(bool:timer = true)
{
	for (new i = 1; i <= MaxClients; i++)
		DLTNum[i] = 0;
		
	for (new u = 1; u <= DLT_MaxNum; u++)
		DLTCash[u - 1] = GetRandomInt(1000, 5000);
		
	DLT_Timer = 600.0;

	if (timer && DLT_Handle == INVALID_HANDLE)
		DLT_Handle = CreateTimer(1.0, DaLeTou_Timer, _, TIMER_REPEAT);
	else
	{
		KillTimer(DLT_Handle);
		DLT_Handle = INVALID_HANDLE;
		DLT_Handle = CreateTimer(1.0, DaLeTou_Timer, _, TIMER_REPEAT);
	}
}

/* 大乐透_计时 */
public Action:DaLeTou_Timer(Handle:timer)
{
	DLT_Timer -= 1.0;
	if (DLT_Timer <= 10.0)
		CPrintToChatAll("{red}[大乐透]\x03即将开奖!开始倒计时,剩余 \x05%.0f \x03秒.", DLT_Timer);
	
	if (DLT_Timer <= 0)
	{
		DaLeTou_Lottery();
		DLT_Handle = INVALID_HANDLE;
		KillTimer(timer);
	}
}

/* 大乐透_开奖 */
public DaLeTou_Lottery()
{
	decl lucknum, luckcash, Float:randomint, Handle:luckhandle, String:s_type[16], String:infomsg[128];
	
	luckhandle = CreateArray();
	lucknum = GetRandomInt(1, DLT_MaxNum);
	randomint = GetRandomFloat(0.0, 100.0);
	if (randomint < 0.05)
		luckcash = GetRandomInt(30000, 70000), Format(s_type, sizeof(s_type), "终极巨奖");
	else if (randomint < 5.0)
		luckcash = GetRandomInt(20000, 50000), Format(s_type, sizeof(s_type), "惊天大奖");
	else if (randomint < 50.0)
		luckcash = GetRandomInt(10000, 30000), Format(s_type, sizeof(s_type), "特殊奖");
	else if (randomint < 80.0)
		luckcash = GetRandomInt(6000, 12000), Format(s_type, sizeof(s_type), "普通奖");
	else if (randomint < 100.0)
		luckcash = GetRandomInt(1000, 5000), Format(s_type, sizeof(s_type), "安慰奖");
		
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false))
		{
			if (DLTNum[i] == lucknum)
				PushArrayCell(luckhandle, i);
			
		}
	}
	
	if (GetArraySize(luckhandle) > 0)
	{
		if (GetArraySize(luckhandle) > 1)
		{
			luckcash = luckcash / GetArraySize(luckhandle);
			for (new i; i < GetArraySize(luckhandle); i++)
			{
				Format(infomsg, sizeof(infomsg), " %s %N", infomsg, GetArrayCell(luckhandle, i));
				Cash[i] += luckcash;
			}
				
			CPrintToChatAll("{red}[大乐透]\x03本期中奖的号码是: \x05[%d] \x03号, 类型:\x05%s\x03 , 获奖者分别是: \x05%s\x03 , 奖励金额平分后是: \x05%d", lucknum, s_type, infomsg, luckcash);
		}
		else
		{
			Format(infomsg, sizeof(infomsg), " %N", GetArrayCell(luckhandle, 0));
			Cash[GetArrayCell(luckhandle, 0)] += luckcash;
			CPrintToChatAll("{red}[大乐透]\x03本期中奖的号码是: \x05[%d] \x03号, 类型:\x05%s\x03 , 获奖者是: \x05%s\x03 , 奖励金额是: \x05%d", lucknum, s_type, infomsg, luckcash);
		}
	}
	else
		CPrintToChatAll("{red}[大乐透]\x03本期中奖的号码是: \x05[%d] \x03号, 类型: \x05%s\x03 , 本期没有中奖玩家!", lucknum, s_type);
	
	DaLeTou_Refresh();
}

public Action:MenuFunc_Lottery(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "金钱:%d$ 彩票卷:%d个", Cash[Client], Lottery[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "购买($%d)", GetConVarInt(LotteryCost));
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "回收(%d税)", RoundToNearest(GetConVarInt(LotteryCost)*(1-GetConVarFloat(LotteryRecycle))));
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "使用(剩余%d个)", Lottery[Client]);
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Lottery, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}

public MenuHandler_Lottery(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select) 
	{
		new itemcost = GetConVarInt(LotteryCost);
		switch (itemNum)
		{
			case 1:
			{
				if(Cash[Client] >= itemcost)
				{
					Lottery[Client]++, Cash[Client] -= itemcost;
					CPrintToChat(Client, MSG_BUYSUCC, itemcost, Cash[Client]);
				}
				else CPrintToChat(Client, MSG_BUYFAIL, itemcost, Cash[Client]);
			}
			case 2:
			{
				new tax = RoundToNearest(itemcost*(1-GetConVarFloat(LotteryRecycle)));
				if(Lottery[Client]>0)
				{
					Lottery[Client]--, Cash[Client] += itemcost-tax;
					CPrintToChat(Client, MSG_RecycleSUCC, itemcost-tax, tax, Cash[Client]);
				}
				else PrintHintText(Client, "你身上没有彩票卷哦~");
			}
			case 3: UseLotteryFunc(Client);
			case 4: MenuFunc_LotteryCasino(Client);
		}
		MenuFunc_Lottery(Client);
	}
}
/* 彩票卷 */
public Action:UseLottery(Client, args)
{
	UseLotteryFunc(Client);
	return Plugin_Handled;
}

public Action:UseLotteryFunc(Client)
{
	if(GetConVarInt(LotteryEnable)!=1)
	{
		CPrintToChat(Client, "{green}对不起! {blue}服务器没有开啟彩票功能!");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, "\x05对不起! {red}死亡状态下无法使用彩票功能!");
		return Plugin_Handled;
	}
	
	if(AdminDiceNum[Client]>0 || Lottery[Client]>0)
	{
		Lottery[Client]--;
		new diceNum;
		if(AdminDiceNum[Client]>0) diceNum = AdminDiceNum[Client];
		else diceNum = GetRandomInt(diceNumMin, diceNumMax);
		
		switch (diceNum)
		{
			case 1: //给予战术散弹枪
			{
//				new Num = GetRandomInt(1, 5);
//				for(new i=1; i<=Num; i++)
				CheatCommand(Client, "give", "autoshotgun");
				CPrintToChatAll("{green}[彩票] %s 获得战术散弹枪!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d把战术散弹枪!", NameInfo(Client, simple), Num);
			}
			case 2: //冰冻玩家
			{
				new Float:duration = GetRandomFloat(10.0, 30.0);
				new Float:freezepos[3];
				GetEntPropVector(Client, Prop_Send, "m_vecOrigin", freezepos);
				FreezePlayer(Client, freezepos, duration);
				CPrintToChatAll("{green}[彩票] %s 被冰冻{green}%.1f{default}秒!", NameInfo(Client, colored), duration);
				//PrintToserver("[彩票] %s 被冰冻%d秒!", NameInfo(Client, simple), duration);
			}
			case 3: //给予M16
			{
				CheatCommand(Client, "give", "rifle");
				CPrintToChatAll("{green}[彩票] {default}M16-猥琐者的专用, 恭喜 %s 获得!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] M16-猥琐者的专用, 恭喜 %s 获得%d把!", NameInfo(Client, simple), Num);
			}
			case 4: //给予土製炸弹
			{
				CheatCommand(Client, "give", "pain_pills");
				CPrintToChatAll("{green}[彩票] %s 获得手雷!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d个手雷!", NameInfo(Client, simple), Num);
			}
			case 5: // 给予药丸
			{
//				for(new i=1; i<=MaxClients; i++)
				CheatCommand(Client, "give", "pain_pills");
				CPrintToChatAll("{green}[彩票]  %s 获得药丸!");
				//PrintToserver("[彩票] 所有人获得药丸, 如果你已随身携带请留心脚下寻找!");
			}			
			case 6: // 获得生命
			{
				CheatCommand(Client, "give", "health");
				CPrintToChatAll("{green}[彩票] %s 恢复全满生命!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 恢复全满生命!", NameInfo(Client, simple));
			}
			case 7: // 中毒
			{
				new Float:duration = GetRandomFloat(5.0, 10.0);
				ServerCommand("sm_drug \"%N\" \"1\"", Client);
				CPrintToChatAll("{green}[彩票] %s 乱吃东西而中毒, 将拉肚子{green}%.2f{default}秒", NameInfo(Client, colored), duration);
				//PrintToserver("[彩票] %s 乱吃东西而中毒, %.2f秒", NameInfo(Client, simple), duration);
				CreateTimer(duration, RestoreSick, Client, TIMER_FLAG_NO_MAPCHANGE);
			}
			case 8: // 给予狙击
			{
				new Num = GetRandomInt(1, 3);
				for(new i=1; i<=Num; i++)
					CheatCommand(Client, "give", "hunting_rifle");
				CPrintToChatAll("{green}[彩票] {default}狙击是一门艺术 - 谁也无法阻挡 %s 追求艺术的脚步! 获得{green}%d{default}把猎枪!", NameInfo(Client, colored), Num);
				//PrintToserver("[彩票] 狙击是一门艺术 - 谁也无法阻挡 %s 追求艺术的脚步! 获得%d把猎枪!", NameInfo(Client, simple), Num);
			}
			case 9: // 变药包
			{
				SetEntityModel(Client, "models/w_models/weapons/w_eq_medkit.mdl");
				CPrintToChatAll("{green}[彩票] %s 被变成药包了!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 被变成药包了!", NameInfo(Client, simple));
			}
//			case 10: // TANK
//			{
//				CheatCommand(Client, "z_spawn", "tank auto");
//				CPrintToChatAll("{green}[彩票] %s 在墙角画圈圈, 结果一不小心把{green}Tank{default}召唤了出来!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 在墙角画圈圈, 结果一不小心把Tank召唤了出来!", NameInfo(Client, simple));
//			}
			case 11: // Witch
			{
				new Num = GetRandomInt(1, 3);
				for(new x=1; x<=Num; x++)
					CheatCommand(Client, "z_spawn", "witch auto");
				CPrintToChatAll("{green}[彩票] %s 召唤了他的{green}%d{default}个爱妃{green}Witch{default}!", NameInfo(Client, colored), Num);
				//PrintToserver("[彩票] %s 召唤了他的%d个爱妃Witch!", NameInfo(Client, simple), Num);
			}
			case 12: // 召唤殭尸
			{
				CheatCommand(Client, "director_force_panic_event", "");
				CPrintToChatAll("{green}[彩票] %s 这位大帅哥, 为大家引来了一群丧尸!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 这位大帅哥, 为大家引来了一群丧尸!", NameInfo(Client, simple));
			}
			case 13: // 萤光
			{
				IsGlowClient[Client] = true;
				PerformGlow(Client, 3, 0, 70, 70, 255);
				CPrintToChatAll("{green}[彩票] %s 的身上发出了萤光!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 的身上发出了萤光!", NameInfo(Client, simple));
			}
			case 14: //给予燃烧炸弹
			{
//				new Num = GetRandomInt(1, 2);
//				for(new i=1; i<=Num; i++)
				CheatCommand(Client, "give", "molotov");
				CPrintToChatAll("{green}[彩票] %s 获得燃烧瓶!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d个燃烧瓶!", NameInfo(Client, simple), Num);
			}
			case 15: //给予氧气瓶
			{
//				new Num = GetRandomInt(1, 2);
//				for(new i=1; i<=Num; i++)
				CheatCommand(Client, "give", "oxygentank");
				CPrintToChatAll("{green}[彩票] %s 获得氧气樽!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d个氧气樽!", NameInfo(Client, simple), Num);
			}
			case 16: //给予煤气罐
			{
//				new Num = GetRandomInt(1, 2);
//				for(new i=1; i<=Num; i++)
				CheatCommand(Client, "give", "propanetank");
				CPrintToChatAll("{green}[彩票] %s 获得煤气罐!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d个煤气罐!", NameInfo(Client, simple), Num);
			}
			case 17: //给予油桶
			{
//				new Num = GetRandomInt(1, 2);
//				for(new i=1; i<=Num; i++)
				CheatCommand(Client, "give", "gascan");
				CPrintToChatAll("{green}[彩票] %s 获得油桶!", NameInfo(Client, colored), 1);
				//PrintToserver("[彩票] %s 获得%d个油桶!", NameInfo(Client, simple), Num);
			}
			case 18: //给予药包
			{
				CheatCommand(Client, "give", "first_aid_kit");
				CPrintToChatAll("{green}[彩票] %s 获得一个药包!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 获得一个药包!", NameInfo(Client, simple));
			}
			case 19: // 无限子弹
			{
				if(GetConVarInt(FindConVar("sv_infinite_ammo")) == 1)
				{
					//LotteryEventDuration[0] = 0;
					SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
					CPrintToChatAll("{green}[彩票] %s 发现子弹库内餘下子弹是BB弹, 无限子弹提前结束了, 全体感谢他吧...", NameInfo(Client, colored));
					//PrintToserver("[彩票] %s发现子弹库内餘下子弹是BB弹, 无限子弹提前结束了, 全体感谢他吧...", NameInfo(Client, simple));
				}
				else
				{
					new duration = GetRandomInt(10, 30);
					//LotteryEventDuration[0] = duration;
					SetConVarInt(FindConVar("sv_infinite_ammo"), 1);
					CreateTimer(float(duration), LotteryInfiniteAmmo);
					CPrintToChatAll("{green}[彩票] %s 发现子弹库, 全体无限子弹{green}%d{default}秒, 大家感激他吧!", NameInfo(Client, colored), duration);
					//PrintToserver("[彩票] %s发现子弹库, 全体无限子弹%d秒, 大家感激他吧!", NameInfo(Client, simple), duration);
				}
			}
			case 20: // 黑屏
			{
				PerformFade(Client, 150);
				new Float:duration = GetRandomFloat(5.0, 10.0);
				CPrintToChatAll("{green}[彩票] %s 视力减弱{green}%.2f{default}秒", NameInfo(Client, colored), duration);
				//PrintToserver("[彩票] %s视力减弱{green}%.2f{default}秒", NameInfo(Client, simple), duration);
				CreateTimer(duration, RestoreFade, Client);
			}
			case 21: // 死亡召唤殭尸
			{
				if(GetClientTeam(Client)==2 && IsPlayerIncapped(Client))
				{
					CheatCommand(Client, "director_force_panic_event", "");
					CPrintToChatAll("{green}[彩票] {default}倒下的 %s 因无人救他, 对生还者表示仇视, 大叫而引发尸群攻击!", NameInfo(Client, colored));
					//PrintToserver("[彩票] 倒下的 %s 因无人救他, 对生还者表示仇视, 大叫而引发尸群攻击!", NameInfo(Client, simple));
				}
				else
				{
					CPrintToChatAll("{green}[彩票] {default}倒下的 %s 使用了彩票, 结果什麼事情都没有发生!", NameInfo(Client, colored));
					//PrintToserver("[彩票] 倒下的 %s 使用了彩票, 结果什麼事情都没有发生!", NameInfo(Client, simple));
				}
			}
			case 22: // 普感生命值改变
			{
				new value = GetRandomInt(1, 10);
				new mode = GetRandomInt(0, 1);
				if(mode == 0)
				{
					new duration = GetRandomInt(20, 40);
					//LotteryEventDuration[1] = duration;
					SetConVarInt(FindConVar("z_health"), oldCommonHp*value);
					if(LotteryWeakenCommonsHpTimer != INVALID_HANDLE)
					{
						KillTimer(LotteryWeakenCommonsHpTimer);
						LotteryWeakenCommonsHpTimer = INVALID_HANDLE;
					}
					LotteryWeakenCommonsHpTimer = CreateTimer(float(duration), LotteryWeakenCommonsHp);
					CPrintToChatAll("{green}[彩票] %s 因强姦了一隻普感而引发丧尸们的愤怒, 在{green}%d{default}秒内普感生命值加强{green}%d{default}倍!", NameInfo(Client, colored), duration, value);
					//PrintToserver("[彩票] %s 因强姦了一隻普感而引发丧尸们的愤怒, 在%d秒普感生命值加强%d倍!", NameInfo(Client, simple), duration, value);
				}
				else
				{
					new duration = GetRandomInt(20, 40);
					//LotteryEventDuration[1] = duration;
					SetConVarInt(FindConVar("z_health"), oldCommonHp/value);
					if(LotteryWeakenCommonsHpTimer != INVALID_HANDLE)
					{
						KillTimer(LotteryWeakenCommonsHpTimer);
						LotteryWeakenCommonsHpTimer = INVALID_HANDLE;
					}
					LotteryWeakenCommonsHpTimer = CreateTimer(float(duration), LotteryWeakenCommonsHp);
					CPrintToChatAll("{green}[彩票] {blue}丧尸们对 %s 动了点怜悯之心, 在{green}%d{default}秒内普感生命值减弱{green}%d{default}倍!", NameInfo(Client, colored), duration, value);
					//PrintToserver("[彩票] 丧尸们对 %s 动了点怜悯之心, 在%d秒内普感生命值减弱%d倍!", NameInfo(Client, simple), duration, value);
				}
			}
			case 23: // 无敌事件
			{
				if(GetConVarInt(FindConVar("god"))==1)
				{
					//LotteryEventDuration[2] = 0;
					SetConVarInt(FindConVar("god"), 0, true, false);
					CPrintToChatAll("{green}[彩票] %s 发现原来无敌药过期了, 无敌效果提前结束了!", NameInfo(Client, colored));
					//PrintToserver("[彩票] %s 发现原来无敌药过期了, 无敌效果提前结束了!", NameInfo(Client, simple));
				}
				else
				{
					new duration = GetRandomInt(10, 20);
					//LotteryEventDuration[2] = duration;
					SetConVarInt(FindConVar("god"), 1, true, false);
					CreateTimer(float(duration), LotteryGodMode);
					CPrintToChatAll("{green}[彩票] %s 发现了一堆士兵留下的无敌药，使大家能无敌{green}%d{default}秒, 请尽快裸奔!", NameInfo(Client, colored), duration);
					//PrintToserver("[彩票] %s 发现了一堆士兵留下的无敌药，使大家能无敌%d秒, 请尽快裸奔!", NameInfo(Client, simple), duration);
				}
			}
			case 24: // 获得很多手雷
			{
		         ServerCommand("sm_setitem_957 \"%N\" \"1\" \"33\" \"3\"", Client);       
		         CPrintToChat(Client, "{green}[彩票] %s 在山洞发现女神之泪!，效果还有3天。大家祝福他吧", Client);	
//				new Num = GetRandomInt(1, 3);
//				for(new x=1; x<=Num; x++)
//				{
//					CheatCommand(Client, "give", "pipe_bomb");
//					CheatCommand(Client, "give", "vomitjar");
//					CheatCommand(Client, "give", "molotov");
//				}
//				CPrintToChatAll("{green}[彩票] %s 在军火库发现投掷品!", NameInfo(Client, simple));
				//PrintToserver("[彩票] %s 在军火库发现一堆投掷品!", NameInfo(Client, simple));
			}
			case 25: // 召唤Hunter
			{
				new Num = GetRandomInt(6, 10);
				for(new x=1; x<=Num; x++)
					CheatCommand(Client, "z_spawn", "hunter");
				CPrintToChatAll("{green}[彩票] %s 射中了Hunter巢穴而引来一堆{green}Hunter{default}!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 射中了Hunter巢穴而引来一堆Hunter!", NameInfo(Client, simple));
			}
			case 26: // 玩家加速
			{
				new Float:value = GetRandomFloat(1.1, 1.2);
				SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue")*value);
				CPrintToChatAll("{green}[彩票] %s 在鞋店找到了暴走鞋, 现在跑得很快!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 在鞋店找到了暴走鞋, 现在跑得很快!", NameInfo(Client, simple));
			}
			case 27: // 玩家重力
			{
				new Float:value = GetRandomFloat(0.1, 0.5);
				SetEntityGravity(Client, GetEntityGravity(Client)*value);
				CPrintToChatAll("{green}[彩票] %s 周围的重力变小了!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 周围的重力变小了!", NameInfo(Client, simple));
			}
			case 28: // 变成透明的
			{
				IsGlowClient[Client] = true;
				PerformGlow(Client, 3, 0, 1);
				SetEntityRenderMode(Client, RenderMode:3);
				SetEntityRenderColor(Client, 0, 0, 0, 0);
				CPrintToChatAll("{green}[彩票] %s 变成透明的了,大家小心不要误伤啊!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 变成透明的了,大家小心不要误伤啊!", NameInfo(Client, simple));
			}
			case 29: // 变成TANK
			{
				SetEntityModel(Client, "models/infected/hulk.mdl");
				CPrintToChatAll("{green}[彩票] %s 在墙角画圈圈, 结果一不小心把自已变成了{green}Tank{default}!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 在墙角画圈圈, 结果一不小心把自已变成了Tank!", NameInfo(Client, simple));
			}
			case 30: // 变成蓝色
			{
				SetEntityRenderMode(Client, RenderMode:3);
				SetEntityRenderColor(Client, 255, 0, 0, 150);
				CPrintToChatAll("{green}[彩票] %s 被油漆溅中了!", NameInfo(Client, colored));
				//PrintToserver("[彩票] %s 被油漆溅中了!", NameInfo(Client, simple));
			}
			case 31: // 赏钱
			{
				new Num = GetRandomInt(1, 000);
				Cash[Client] += Num;
				CPrintToChatAll("{green}[彩票] %s 在地上拾到了${green}%d{default}!", NameInfo(Client, colored), Num);
				//PrintToserver("[彩票] %s 在地上拾到了$%d!", NameInfo(Client, simple), Num);
			}
			case 32: // 扣钱
			{
				new Num = GetRandomInt(1, 10000);
				Cash[Client] -= Num;
				CPrintToChatAll("{green}[彩票] %s 投资失败, 蚀了${green}%d{default}!", NameInfo(Client, colored), Num);
				//PrintToserver("[彩票] %s 投资失败, 蚀了$%d!", NameInfo(Client, simple), Num);
			}
			case 33: // 赏彩票
			{
				new Num = GetRandomInt(1, 2);
				Lottery[Client] += Num;
				CPrintToChatAll("{green}[彩票] %s 获得额外{green}%d{default}张彩票!", NameInfo(Client, colored), Num);
				//PrintToserver("[彩票] %s 获得额外%d彩票!", NameInfo(Client, simple), Num);
			}
		}
		AdminDiceNum[Client] = -1;
	}
	else PrintHintText(Client, "你身上没有彩票卷!");
	return Plugin_Handled;
}
//解除冰冻
public Action:ResetFreeze(Handle:timer, any:Client)
{
	ServerCommand("sm_freeze \"%N\"", Client);
	return Plugin_Handled;
}

//解除毒药
public Action:RestoreSick(Handle:timer, any: Client)
{
	ServerCommand("sm_drug \"%N\"", Client);
	return Plugin_Handled;
}
public Action:RestoreFade(Handle:timer, any: Client)
{
	PerformFade(Client, 0);
	return Plugin_Handled;
}
public Action:LotteryInfiniteAmmo(Handle:timer)
{
	if(GetConVarInt(FindConVar("sv_infinite_ammo")) == 1)
	{
		SetConVarInt(FindConVar("sv_infinite_ammo"), 0);
		CPrintToChatAll("\x03[彩票] {blue}无限子弹结束了!");
	}
	return Plugin_Handled;
}
public Action:LotteryWeakenCommonsHp(Handle:timer)
{
	if(GetConVarInt(FindConVar("z_health"))!=oldCommonHp)
	{
		SetConVarInt(FindConVar("z_health"), oldCommonHp);
		CPrintToChatAll("\x03[彩票] {blue}普感生命值回复全满!");
		LotteryWeakenCommonsHpTimer = INVALID_HANDLE;
	}
	return Plugin_Handled;
}
public Action:LotteryGodMode(Handle:timer)
{
	if(GetConVarInt(FindConVar("god"))==1)
	{
		SetConVarInt(FindConVar("god"), 0);
		CPrintToChatAll("\x03[彩票] {blue}无敌门事件结束了!");
	}
	return Plugin_Handled;
}
	
/* 服务器排名 */
public Action:MenuFunc_Rank(Client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "服务器排名");

	DrawPanelItem(menu, "等级排名");
	DrawPanelItem(menu, "金钱排名");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Rank, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

new rank_id[MAXPLAYERS+1];
public MenuHandler_Rank(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{
		rank_id[Client] = param;
		MenuFunc_RankDisplay(Client);
	}
}

public Action:MenuFunc_RankDisplay(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_RankDisplay);
	if(rank_id[Client]==1)
		SetMenuTitle(menu, "你的等级: %d $", Lv[Client]);
	if(rank_id[Client]==2)
		SetMenuTitle(menu, "你的金钱: %d $", Cash[Client]);

	decl String:rankClient[100], String:rankname[100];

	for(new r=0; r<RankNo; r++)
	{
		if( StrEqual(LevelRankClient[r], "未知", false) ||
			StrEqual(CashRankClient[r], "未知", false)) continue;

		if(rank_id[Client]==1)
			Format(rankClient, sizeof(rankClient), "%s(等级:%d)", LevelRankClient[r], LevelRank[r]);
		if(rank_id[Client]==2)
			Format(rankClient, sizeof(rankClient), "%s(金钱:%d)", CashRankClient[r], CashRank[r]);

		Format(rankname, sizeof(rankname), "第%d名", r+1);
		AddMenuItem(menu, rankname, rankClient);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public MenuHandler_RankDisplay(Handle:menu, MenuAction:action, Client, itemNum)
{
	if (action == MenuAction_Select)
	{
		for(new r=0; r<RankNo; r++)
		{
			if(itemNum == r)
			{
				decl String:Name[256];
				if(rank_id[Client]==1)
					Format(Name, sizeof(Name), "%s", LevelRankClient[r]);
				if(rank_id[Client]==2)
					Format(Name, sizeof(Name), "%s", CashRankClient[r]);

				KvJumpToKey(RPGSave, Name, true);
				new targetLv	= KvGetNum(RPGSave, "LV", 0);
				new targetCash	= KvGetNum(RPGSave, "EXP", 0);
				new targetJob	= KvGetNum(RPGSave, "Job", 0);
				KvGoBack(RPGSave);

				new Handle:Panel = CreatePanel();
				decl String:job[32];
				decl String:line[256];
				if(targetJob == 0)			Format(job, sizeof(job), "未转职");
				else if(targetJob == 1)	Format(job, sizeof(job), "精灵");
				else if(targetJob == 2)	Format(job, sizeof(job), "游侠");
				else if(targetJob == 3)	Format(job, sizeof(job), "生物专家");
				else if(targetJob == 4)	Format(job, sizeof(job), "心灵医生");
				else if(targetJob == 5)	Format(job, sizeof(job), "法师");
				else if(targetJob == 6)	Format(job, sizeof(job), "弹药专家");
				else if(targetJob == 7)	Format(job, sizeof(job), "雷神");
				else if(targetJob == 8)	Format(job, sizeof(job), "虚空之眼");

				if(rank_id[Client]==1)
					Format(line, sizeof(line), "等级排行榜 =TOP%d=", r+1);
				if(rank_id[Client]==2)
					Format(line, sizeof(line), "金钱排行榜 =TOP%d=", r+1);
				DrawPanelText(Panel, line);

				Format(line, sizeof(line), "玩家名字: %s", Name);
				DrawPanelText(Panel, line);

				Format(line, sizeof(line), "职业:%s 等级:Lv.%d 现金:%d$\n ", job, targetLv, targetCash);
				DrawPanelText(Panel, line);

				DrawPanelItem(Panel, "返回");
				DrawPanelItem(Panel, "离开", ITEMDRAW_DISABLED);

				SendPanelToClient(Panel, Client, Handler_GoBack, MENU_TIME_FOREVER);

				CloseHandle(Panel);
			}
		}
	} else if (action == MenuAction_End) CloseHandle(menu);
}

public Handler_GoBack(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
		MenuFunc_Rank(param1);
}


/* 密码资讯 */
public Action:Passwordinfo(Client, args)
{
	MenuFunc_PasswordInfo(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_PasswordInfo(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	
	if(IsPasswordConfirm[Client])	Format(line, sizeof(line), "\x03你已注册，已设密码的密码为:\x05 %s", Password[Client]);
	else if(StrEqual(Password[Client], "", true))	Format(line, sizeof(line), "\x03密码状态: \x05未启动");
	else if(!IsPasswordConfirm[Client])	Format(line, sizeof(line), "\x03密码状态: \x05未输入");

	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "★之前领取不了活动奖品的可以再次领取[点击‘我知道了’]★");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "★新增加‘虚空之眼’7转职业，技能炫酷，威力强大！★");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "★修复购买消耗物品无效BUG，增加‘复活币’功能★");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "★还有许多新功能正在添加中。。。★");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "====午夜狂欢 RPG 升级系统====");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "        \x04求生之路RPG        ");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "我知道了");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Passwordinfo, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}

public MenuHandler_Passwordinfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch (param)
	    {
		    case 1: Menu_GameAnnouncement(Client);
        }
	}
}
/*
public Action:CmdKill(client,args)  //如果是一下几个名字，自动关闭监视
{
	decl String:Name[64];
	GetClientName(client,Name,sizeof(Name));
	if (client<=0)return;
	if (StrEqual(Name,"XJ") || StrEqual(Name,"火鸟丶猎人") || StrEqual(Name,"逆回丶十六夜"))
	{
		ServerCommand("exit");   //ServerCommand  =   服务器命令
	}
}

public Action:CmdWatching(client,args)
{
	if (!watching[client])
	{
		PrintToChat(client,"\x03你没有被监视!");
		return;
	}
	Showing[client] = !Showing[client];
}

public Action:Event_player_entercp(Handle:event, const String:name[], bool:dontBroadcast)  //进入安全门
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));  //定义客户端client是玩家
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && !entercp[client])  //如果客户端在游戏 / 是无效客户端 / 是人类队伍  /  没有进安全门
	{
		decl String:sName[64];
		GetEventString(event,"doorname",sName,sizeof(sName));  // GetEventString  =  得到事件字符串
		new String:sMap[64];    //地图
		GetCurrentMap(sMap,sizeof(sMap));  //得到现在的地图
		if (StrEqual(sName,"checkpoint_entrance")  || StrEqual(sMap,"c2m1_highway"))
		{
			new isIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
			if (isIncap) return;   // return  =  返回
			PrintToChatAll("\x03玩家:\x04[%N]\x03成功进入安全室!\n\x03费时:\x04%d时%d分%d秒\n\x03死亡次数:\x04%d",client,jumptime_h[client],jumptime_m[client],
			jumptime_s[client],GetClientDeaths(client));  //玩家，小时，分钟，秒，死亡次数，跳跃次数
			EmitSoundToAll(SOUND_JS,client); //EmitSoundToAll  =  对所有发射声音    SOUND = 求生音效文件夹
			entercp[client] = true;   //进入安全门  =  真的
			Showing[client] = false;  //显示  =  虚假
		}
		
	}

}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)  //创建玩家事件
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (IsClientInGame(client) && !entercp[client] && !watching[client])  //客户端在游戏 / 没有进安全门 / 没有被监视
	{
		watchingtimer[client] = CreateTimer(1.0,WatchingTimer,client,TIMER_REPEAT);   //创建监视定时器
		watching[client] = true;    //监视  =  真的
	}
	Showing[client] = true;   //显示  =  真的

}

public Action:WatchingTimer(Handle:timer, any:client)  //监视  WatchingTimer代替时间，一直刷新
{
	if (IsPasswordConfirm[client])  //如果密码确认
	{
		KillTimer(timer);  //结束时间
		watchingtimer[client] = INVALID_HANDLE;  //停止监视
		watching[client] = false;  // 监视  =  无效
	}
	
	if (GetClientTeam(Client) == 2)   //没有进安全门
	{
		jumptime_s[Client]++;  //秒
		if (jumptime_s[Client]>=60)
		{
			jumptime_m[Client]++;  //分钟
			jumptime_s[Client] = 0;
			if (jumptime_m[Client]>=60)   
			{
				jumptime_h[Client]++;  //小时
				jumptime_m[Client]=0;
			}
		}		
	}
	
    距离安全门定义 
	decl Float:pos[3];
	if (cpdoorpos[0] != 0.0 &&  cpdoorpos[1] != 0.0 && cpdoorpos[2] != 0.0)
	{
		GetClientAbsOrigin(Client, pos);  //得到客户端开始计算距离
		discp[Client] = GetVectorDistance(pos,cpdoorpos,false);	// GetVectorDistance  =  得到距离	
	}
	
	if(IsPasswordConfirm[client])  //监视器
	{
	Showing[client] = !Showing[client];
	Menu_GameAnnouncement(client)
	}
	KillTimer(watchingtimer[client]);
	watchingtimer[client] = CreateTimer(1.0,WatchingTimer,client,TIMER_REPEAT);
	

	
	if (!Showing[client]) return;   //如果客户端不显示就返回
	new String:sText[1024];  //定义按键属性 / 时间 / 安全门距离
	new Handle:menu = CreatePanel(); //菜单  =  创建面板
	if(IsPasswordConfirm[client])	Format(sText, sizeof(sText), "你已注册，已设密码的密码为: %s [官方QQ群:141758560]", Password[client]);
	else if(StrEqual(Password[client], "", true))	Format(sText, sizeof(sText), "密码状态: 未启动[不会注册的加群,官方QQ群:141758560]");
	else if(!IsPasswordConfirm[client])	Format(sText, sizeof(sText), "密码状态: 未输入[不会注册的加群,官方QQ群:141758560]");

	SetPanelTitle(menu, sText);

	Format(sText, sizeof(sText), "════════════════════════════");
	DrawPanelText(menu, sText);
	Format(sText, sizeof(sText), "在游戏里按y,再输入/pw 123[pw后面有个空格,要输入/符号]先改名字");
	DrawPanelText(menu, sText);
	Format(sText, sizeof(sText), "游戏名字请不要加特殊符号，会导致数据丢失!不会改名字请加群!");
	DrawPanelText(menu, sText);
	Format(sText, sizeof(sText), "请加群下载群共享里的老衲登陆器,附带注册+改名字+使用教程!");
	DrawPanelText(menu, sText);
	Format(sText, sizeof(sText), "官方QQ群:141758560  论坛:http://l4dxj.lingd.cn");
	DrawPanelText(menu, sText);
	//Format(sText,sizeof(sText),"%d 小时 %d 分钟 %d 秒",jumptime_h[client],jumptime_m[client],jumptime_s[client]);
	Format(sText, sizeof(sText), "★注册密码才能关闭此提示★");
	DrawPanelText(menu,sText);

	SendPanelToClient(menu,client,MenuHandler_Watching,1);  //SendPanelToClient = 发送面板到客户端  监视刷新频率
}

public MenuHandler_Watching(Handle:menu, MenuAction:action, client, item)   //木有按键
{
	
}	

public Action:Event_player_jump(Handle:event, const String:name[], bool:dontBroadcast)   //玩家跳跃事件
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));  //定义玩家名字
	if (watching[client] && !entercp[client])   //如果客户端正在监视  /  没有进入安全门
	{
		jumpcount[client]++;    //跳跃次数
	}
}

public Action:TimerShow(Handle:timer, any:client)  //聊天框广告
{
	PrintToChatAll("\x04[老衲] \n\x03玩家注册了才能去掉循环提示信息菜单! \n\x02可下载本服登陆器/绑定快捷键去除!");
}

public Action:Eventroundstart(Handle:event, const String:name[], bool:dontBroadcast)  //重置时间+跳跃次数
{
	for (new client = 1;client<=MaxClients;client++)
	{
		//entercp[client] = false;
		jumpcount[client] = 0;    //跳跃次数
		jumptime_h[client] = 0;
		jumptime_m[client] = 0;
		jumptime_s[client] = 0;
	}
}
*/


/* 插件讯息 */
public Action:MenuFunc_RPGInfo(Client)
{
	PrintToChat(Client, "\x03════════════════");
	PrintToChat(Client, "\x04插件名称:\x05午夜狂欢 %s", PLUGIN_VERSION);
	PrintToChat(Client, "\x04插件作者:\x05恋水晶之冰囧");
	PrintToChat(Client, "\x04插件更新:\x05热心网友");
	PrintToChat(Client, "\x03════════════════");
	return Plugin_Handled;
}

/* 提示绑定热键 */
public Action:MenuFunc_BindKeys(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "是否绑定服务器技能等快捷键?");
	DrawPanelText(Panel, "大键盘B | RPG 菜单");
	DrawPanelText(Panel, "大键盘N | 玩家面板");
	DrawPanelText(Panel, "大键盘V | 会员功能");
	DrawPanelText(Panel, "小键盘- | 打开商店");
	DrawPanelText(Panel, "小键盘* | 使用技能");
	DrawPanelItem(Panel, "是");
	DrawPanelItem(Panel, "否");
	SendPanelToClient(Panel, Client, MenuHandler_BindKeys, MENU_TIME_FOREVER);
	CloseHandle(Panel);
	return Plugin_Handled;
}
public MenuHandler_BindKeys(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{
		switch (param)
		{
			case 1: BindMsg(Client), BindKeyFunction(Client);
			case 2: return;
		}
	}
}
public Action:BindMsg(Client)
{
	PrintToChat(Client, MSG_BIND_1);
	PrintToChat(Client, MSG_BIND_2);
	PrintToChat(Client, MSG_BIND_3);
	PrintToChat(Client, MSG_BIND_GENERAL);
	
	if(JD[Client] == 1) 
		PrintToChat(Client, MSG_BIND_JOB1);
	else if(JD[Client] == 2) 
		PrintToChat(Client, MSG_BIND_JOB2);
	else if(JD[Client] == 3) 
		PrintToChat(Client, MSG_BIND_JOB3);
	else if(JD[Client] == 4)
		PrintToChat(Client, MSG_BIND_JOB4), PrintToChat(Client, MSG_BIND_JOB4_1);
	else if(JD[Client] == 5) 
		PrintToChat(Client, MSG_BIND_JOB5);
	else if(JD[Client] == 6) 
		PrintToChat(Client, MSG_BIND_JOB6), PrintToChat(Client, MSG_BIND_JOB6_1);
	else if(JD[Client] == 7) 
		PrintToChat(Client, MSG_BIND_JOB7), PrintToChat(Client, MSG_BIND_JOB7_1);
		
	return Plugin_Handled;
}
BindKeyFunction(Client)
{

	ClientCommand(Client, "bind n \"say /wanjia\"");
	ClientCommand(Client, "bind b \"say /rpg\"");
	ClientCommand(Client, "bind KP_PLUS \"say /rpg\"");
	ClientCommand(Client, "bind KP_MINUS \"say /buymenu\"");
	ClientCommand(Client, "bind KP_MULTIPLY \"say /useskill\"");
	ClientCommand(Client, "bind KP_SLASH \"say /teaminfo\"");
	ClientCommand(Client, "bind o \"say /vipfree\""); //免费补给快捷键
	ClientCommand(Client, "bind p \"say /vipvote\"");	//会员投票快捷键
	ClientCommand(Client, "bind l \"say /mybag\"");	//我的背包
	ClientCommand(Client, "bind k \"say /myitem\"");	//我的道具
	ClientCommand(Client, "bind f12 \"say /isave\"");	//手动存档
	ClientCommand(Client, "bind m \"say /viewskill\"");	//技能属性
	
	ClientCommand(Client, "bind KP_LEFTARROW \"say /hl\"");
	ClientCommand(Client, "bind KP_5 \"say /dizhen\"");
	ClientCommand(Client, "bind KP_RIGHTARROW \"say /is\"");
	ClientCommand(Client, "bind KP_ENTER \"say /si\"");

	if(JD[Client] == 1)
	{
		ClientCommand(Client, "bind KP_HOME \"say /am\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /sc\"");
		ClientCommand(Client, "bind KP_PGDN \"say /mogu\"");
	} 
	else if(JD[Client] == 2)
	{
		ClientCommand(Client, "bind KP_HOME \"say /sp\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /ia\"");
		ClientCommand(Client, "bind KP_PGDN \"say /kbz\"");
	} 
	else if(JD[Client] == 3)
	{
		ClientCommand(Client, "bind KP_HOME \"say /bs\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /dr\"");
		ClientCommand(Client, "bind KP_PGUP \"say /ms\"");
		ClientCommand(Client, "bind KP_PGDN \"say /baofa\"");
	} 
	else if(JD[Client] == 4)
	{
		ClientCommand(Client, "bind KP_HOME \"say /ts\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /at\"");
		ClientCommand(Client, "bind KP_PGUP \"say /tt\"");
		ClientCommand(Client, "bind KP_END \"say /hb\"");
	}	 
	else if(JD[Client] == 5)
	{
		ClientCommand(Client, "bind KP_HOME \"say /fb\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /ib\"");
		ClientCommand(Client, "bind KP_PGUP \"say /cl\"");
		ClientCommand(Client, "bind KP_PGDN \"say /baolei\"");
	}
	else if(JD[Client] == 6)
	{
		ClientCommand(Client, "bind KP_HOME \"say /psd\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /sdd\"");
		ClientCommand(Client, "bind KP_PGUP \"say /xxd\"");
		ClientCommand(Client, "bind KP_END \"say /qybp\"");
		ClientCommand(Client, "bind KP_PGDN \"say /lsjgp\"");
	}
	else if(JD[Client] == 7)
	{
		ClientCommand(Client, "bind KP_HOME \"say /lzd\"");
		ClientCommand(Client, "bind KP_UPARROW \"say /dcgy\"");
		ClientCommand(Client, "bind KP_PGUP \"say /ylds\"");
	}
}


//地震术震动效果
public Shake_Screen(Client, Float:Amplitude, Float:Duration, Float:Frequency)
{
	new Handle:Bfw;

	Bfw = StartMessageOne("Shake", Client, 1);
	BfWriteByte(Bfw, 0);
	BfWriteFloat(Bfw, Amplitude);
	BfWriteFloat(Bfw, Duration);
	BfWriteFloat(Bfw, Frequency);

	EndMessage();
}
SetWeaponSpeed()
{
	decl ent;

	for(new i = 0; i < WRQL; i++)
	{
		ent = WRQ[i];
		if(IsValidEdict(ent))
		{
			decl String:entclass[65];
			GetEdictClassname(ent, entclass, sizeof(entclass));
			if(StrContains(entclass, "weapon")>=0 && !StrEqual(entclass, "weapon_grenade_launcher"))
			{
				new Float:MAS = 1.0 + Multi[i];
				SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", MAS);
				new Float:ETime = GetGameTime(); 
				new Float:time = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack") - ETime)/MAS;
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", time + ETime);
				time = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack") - ETime)/MAS;
				SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", time + ETime);
				CreateTimer(time, NormalWeapSpeed, ent);
			}
		}
	}
}
public Action:NormalWeapSpeed(Handle:timer, any:ent)
{
	KillTimer(timer);
	timer = INVALID_HANDLE;

	if(IsValidEdict(ent))
	{
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if(StrContains(entclass, "weapon")>=0)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 1.0);
		}
	}
	return Plugin_Handled;
}
public Action:Event_WeaponFire(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(target) == 2 && !IsFakeClient(target))
	{
		new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEdict(ent) || !IsValidEntity(ent))
			return Plugin_Continue;
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if(IsMeleeSpeedEnable[target])
		{
			if(ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")>=0)
			{
				WRQ[WRQL] = ent;
				Multi[WRQL] = MeleeSpeedEffect[target];
				WRQL++;
			}
		} else if(FireSpeedLv[target]>0)
		{
			if(ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")<0))
			{
				WRQ[WRQL] = ent;
				Multi[WRQL] = FireSpeedEffect[target];
				WRQL++;
			}
		} else if(IsInfiniteAmmoEnable[target])
		{
			if(ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")<0))
			{
				if (StrContains(entclass, "grenade_launcher", false) < 0)
					SetEntProp(ent, Prop_Send, "m_iClip1", GetEntProp(ent, Prop_Send, "m_iClip1")+1);
			}
		}
		
		if (IsActionWXZDJ)
		{
			if(ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee") < 0))
			{
				if (StrContains(entclass, "grenade_launcher", false) < 0)
					SetEntProp(ent, Prop_Send, "m_iClip1", GetEntProp(ent, Prop_Send, "m_iClip1")+1);
			}		
		}
		
		if (StrContains(entclass, "grenade_launcher", false) > -1)
			SetEntProp(ent, Prop_Send, "m_iClip1", 1);
	}
	return Plugin_Continue;
}
DelRobot(ent)
{
	if (ent > 0 && IsValidEntity(ent))
    {
		decl String:item[65];
		GetEdictClassname(ent, item, sizeof(item));
		if(StrContains(item, "weapon")>=0)
		{
			RemoveEdict(ent);
		}
    }
}
Release(controller, bool:del=true)
{
	new r=robot[controller];
	new r_clone=robot_clone[controller];
	if(r>0)
	{
		robot[controller]=0;
		robot_clone[controller]=0;
		if(del)
		{
			DelRobot(r);
			DelRobot(r_clone);
		}
	}
	if(robot_gamestart)
	{
		new count=0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(robot[i]>0)
			{
				count++;
			}
		}
		if(count==0)
		{
			robot_gamestart = false;
			robot_gamestart_clone = false;
		}
	}
}

public Action:sm_robot(Client, const arg)
{
	if(!IsValidPlayer(Client, true, false))
		return Plugin_Continue;

	if(robot[Client]>0)
	{
		PrintHintText(Client, "你已经有一个Robot");
		return Plugin_Handled;
	}
	for(new i=0; i<WEAPONCOUNT; i++)
	{
		if(arg==i)	weapontype[Client]=i;
	}
	AddRobot(Client);
	if(Robot_appendage[Client] > 0)
	{
		AddRobot_clone(Client);
	}
	return Plugin_Handled;
}
//增加机器人
AddRobot(Client)
{
	bullet[Client]=RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]);
	new Float:vAngles[3];
	new Float:vOrigin[3];
	new Float:pos[3];
	GetClientEyePosition(Client,vOrigin);
	GetClientEyeAngles(Client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID,  RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
	}
	CloseHandle(trace);
	decl Float:v1[3];
	decl Float:v2[3];
	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);
	ScaleVector(v2, 50.0);
	AddVectors(pos, v2, v1);  // v1 explode taget
	new ent=0;
 	ent=CreateEntityByName(MODEL[weapontype[Client]]);
  	DispatchSpawn(ent);
  	TeleportEntity(ent, v1, NULL_VECTOR, NULL_VECTOR);

	SetEntityMoveType(ent, MOVETYPE_FLY);
	SIenemy[Client]=0;
	CIenemy[Client]=0;
	scantime[Client]=0.0;
	keybuffer[Client]=0;
	bullet[Client]=0;
	reloading[Client]=false;
	reloadtime[Client]=0.0;
	firetime[Client]=0.0;
	robot[Client]=ent;

	for(new i=0; i<WEAPONCOUNT; i++)
	{
		if(weapontype[Client]==i)
		{
			CPrintToChatAll("\x05%N\x03启动了[%s]Robot!", Client, WeaponName[i]);
			//PrintToserver("[United RPG] %s启动了[%s]Robot!", NameInfo(Client, simple), WeaponName[i]);
		}
	}
	robot_gamestart = true;
}

//增加克隆机器人
AddRobot_clone(Client)
{
	bullet_clone[Client]=RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]);
	new Float:vAngles[3];
	new Float:vOrigin[3];
	new Float:pos[3];
	GetClientEyePosition(Client,vOrigin);
	GetClientEyeAngles(Client, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID,  RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
	}
	CloseHandle(trace);
	decl Float:v1[3];
	decl Float:v2[3];
	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);
	ScaleVector(v2, 80.0);
	AddVectors(pos, v2, v1);  // v1 explode taget
	new ent=0;
 	ent=CreateEntityByName(MODEL[weapontype[Client]]);
  	DispatchSpawn(ent);
  	TeleportEntity(ent, v1, NULL_VECTOR, NULL_VECTOR);

	SetEntityMoveType(ent, MOVETYPE_FLY);
	SIenemy_clone[Client]=0;
	CIenemy_clone[Client]=0;
	scantime_clone[Client]=0.0;
	keybuffer_clone[Client]=0;
	bullet_clone[Client]=0;
	reloading_clone[Client]=false;
	reloadtime_clone[Client]=0.0;
	firetime_clone[Client]=0.0;
	robot_clone[Client]=ent;

	for(new i=0; i<WEAPONCOUNT; i++)
	{
		if(weapontype[Client]==i)
		{
			CPrintToChatAll("\x05%N\x03启动了克隆机器人技能,机器人增加一个!", Client);
			//PrintToserver("[United RPG] %s启动了[%s]Robot!", NameInfo(Client, simple), WeaponName[i]);
		}
	}
	robot_gamestart_clone = true;
}

Do_clone(Client, Float:currenttime, Float:duration)
{
	if(robot_clone[Client]>0)
	{
		if (!IsValidEntity(robot_clone[Client]) || !IsValidPlayer(Client, true, false) || IsFakeClient(Client))
		{
			Release(Client);
		}
		else
		{
			if(Robot_appendage[Client] == 0)
			{
				botenerge_clone[Client]+=duration;
				if(botenerge_clone[Client]>robot_energy)
				{
					Release(Client);
					CPrintToChat(Client, "{red}你的Robot已用尽能量了!");
					PrintHintText(Client, "你的Robot已用尽能量了!");
					return;
				}
			}
			button=GetClientButtons(Client);
   		 	GetEntPropVector(robot_clone[Client], Prop_Send, "m_vecOrigin", robotpos_clone);

			if((button & IN_USE) && (button & IN_SPEED) && !(keybuffer[Client] & IN_USE))
			{
				Release(Client);
				CPrintToChatAll("\x05 %N \x03关闭了Robot", Client);
				return;
			}
			if(currenttime - scantime_clone[Client]>robot_reactiontime)
			{
				scantime_clone[Client]=currenttime;
				new ScanedEnemy = ScanEnemy_clone(Client,robotpos_clone);
				if(ScanedEnemy <= MaxClients)
				{
					SIenemy_clone[Client]=ScanedEnemy;
				} else CIenemy_clone[Client]=ScanedEnemy;
			}
			new targetok=false;
			
			if( CIenemy_clone[Client]>0 && IsCommonInfected(CIenemy_clone[Client]) && GetEntProp(CIenemy_clone[Client], Prop_Data, "m_iHealth")>0)
			{
				GetEntPropVector(CIenemy_clone[Client], Prop_Send, "m_vecOrigin", enemypos);
				enemypos[2]+=40.0;
				SubtractVectors(enemypos, robotpos_clone, robotangle[Client]);
				GetVectorAngles(robotangle[Client],robotangle[Client]);
				targetok=true;
			}
			else
			{
				CIenemy_clone[Client]=0;
			}		
			if(!targetok)
			{
				if(SIenemy_clone[Client]>0 && IsClientInGame(SIenemy_clone[Client]) && IsPlayerAlive(SIenemy_clone[Client]))
				{
					GetClientEyePosition(SIenemy_clone[Client], infectedeyepos);
					GetClientAbsOrigin(SIenemy_clone[Client], infectedorigin);
					enemypos[0]=infectedorigin[0]*0.4+infectedeyepos[0]*0.6;
					enemypos[1]=infectedorigin[1]*0.4+infectedeyepos[1]*0.6;
					enemypos[2]=infectedorigin[2]*0.4+infectedeyepos[2]*0.6;

					SubtractVectors(enemypos, robotpos_clone, robotangle[Client]);
					GetVectorAngles(robotangle[Client],robotangle[Client]);
					targetok=true;
				}
				else
				{
					SIenemy_clone[Client]=0;
				}
			}
			if(reloading_clone[Client])
			{
				//CPrintToChatAll("%f", reloadtime[Client]);
				if(bullet_clone[Client]>=RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]) && currenttime-reloadtime_clone[Client]>weaponloadtime[weapontype[Client]])
				{
					reloading_clone[Client]=false;
					reloadtime_clone[Client]=currenttime;
					EmitSoundToAll(SOUNDREADY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos_clone, NULL_VECTOR, false, 0.0);
					//PrintHintText(Client, " ");
				}
				else
				{
					if(currenttime-reloadtime_clone[Client]>weaponloadtime[weapontype[Client]])
					{
						reloadtime_clone[Client]=currenttime;
						bullet_clone[Client]+=RoundToNearest(weaponloadcount[weapontype[Client]]*RobotAmmoEffect[Client]);
						EmitSoundToAll(SOUNDRELOAD, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos_clone, NULL_VECTOR, false, 0.0);
						//PrintHintText(Client, "reloading %d", bullet[Client]);
					}
				}
			}
			if(!reloading_clone[Client])
			{
				if(!targetok)
				{
					if(bullet_clone[Client]<RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]))
					{
						reloading_clone[Client]=true;
						reloadtime_clone[Client]=0.0;
						if(!weaponloaddisrupt[weapontype[Client]])
						{
							bullet_clone[Client]=0;
						}
					}
				}
			}
			chargetime_clone=fireinterval[weapontype[Client]];
			if(!reloading_clone[Client])
			{
				if(currenttime-firetime_clone[Client]>chargetime_clone)
				{

					if( targetok)
					{
						if(bullet_clone[Client]>0)
						{
							bullet_clone[Client]=bullet_clone[Client]-1;

							FireBullet(Client, robot_clone[Client], enemypos, robotpos_clone);

							firetime_clone[Client]=currenttime;
						 	reloading_clone[Client]=false;
						}
						else
						{
							firetime_clone[Client]=currenttime;
						 	EmitSoundToAll(SOUNDCLIPEMPTY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos_clone, NULL_VECTOR, false, 0.0);
							reloading_clone[Client]=true;
							reloadtime_clone[Client]=currenttime;
						}

					}

				}

			}
 			GetClientEyePosition(Client,  Clienteyepos);
			Clienteyepos[2]+=30.0;
			GetClientEyeAngles(Client, Clientangle);
			new Float:distance = GetVectorDistance(robotpos_clone, Clienteyepos);
			if(distance>100.0)
			{
				TeleportEntity(robot_clone[Client], Clienteyepos,  robotangle[Client] ,NULL_VECTOR);
			}
			else if(distance>50.0)
			{

				MakeVectorFromPoints( robotpos_clone, Clienteyepos, robotvec_clone);
				NormalizeVector(robotvec_clone,robotvec_clone);
				ScaleVector(robotvec_clone, 5*distance);
				if (!targetok )
				{
					GetVectorAngles(robotvec_clone, robotangle[Client]);
				}
				TeleportEntity(robot_clone[Client], NULL_VECTOR,  robotangle[Client] ,robotvec_clone);
				walktime_clone[Client]=currenttime;
			}
			else
			{
				robotvec_clone[0]=robotvec_clone[1]=robotvec_clone[2]=0.0;
				if(!targetok && currenttime-firetime_clone[Client]>4.0)robotangle[Client][1]+=5.0;
				TeleportEntity(robot_clone[Client], NULL_VECTOR,  robotangle[Client] ,robotvec_clone);
			}
		 	keybuffer_clone[Client]=button;
		}
	}
	else
	{
		botenerge_clone[Client]=botenerge_clone[Client]-duration*0.5;
		if(botenerge_clone[Client]<0.0)botenerge_clone[Client]=0.0;
	}
}


Do(Client, Float:currenttime, Float:duration)
{
	if(robot[Client]>0)
	{
		if (!IsValidEntity(robot[Client]) || !IsValidPlayer(Client, true, false) || IsFakeClient(Client))
		{
			Release(Client);
		}
		else
		{
			if(Robot_appendage[Client] == 0)
			{
				botenerge[Client]+=duration;
				if(botenerge[Client]>robot_energy)
				{
					Release(Client);
					CPrintToChat(Client, "{red}你的Robot已用尽能量了!");
					PrintHintText(Client, "你的Robot已用尽能量了!");
					return;
				}
			}

			button=GetClientButtons(Client);
   		 	GetEntPropVector(robot[Client], Prop_Send, "m_vecOrigin", robotpos);

			if((button & IN_USE) && (button & IN_SPEED) && !(keybuffer[Client] & IN_USE))
			{
				Release(Client);
				CPrintToChatAll("\x05 %N \x03关闭了Robot", Client);
				return;
			}
			if(currenttime - scantime[Client]>robot_reactiontime)
			{
				scantime[Client]=currenttime;
				new ScanedEnemy = ScanEnemy(Client,robotpos);
				if(ScanedEnemy <= MaxClients)
				{
					SIenemy[Client]=ScanedEnemy;
				} else CIenemy[Client]=ScanedEnemy;
			}
			new targetok=false;
			
			if( CIenemy[Client]>0 && IsCommonInfected(CIenemy[Client]) && GetEntProp(CIenemy[Client], Prop_Data, "m_iHealth")>0)
			{
				GetEntPropVector(CIenemy[Client], Prop_Send, "m_vecOrigin", enemypos);
				enemypos[2]+=40.0;
				SubtractVectors(enemypos, robotpos, robotangle[Client]);
				GetVectorAngles(robotangle[Client],robotangle[Client]);
				targetok=true;
			}
			else
			{
				CIenemy[Client]=0;
			}		
			if(!targetok)
			{
				if(SIenemy[Client]>0 && IsClientInGame(SIenemy[Client]) && IsPlayerAlive(SIenemy[Client]))
				{

					GetClientEyePosition(SIenemy[Client], infectedeyepos);
					GetClientAbsOrigin(SIenemy[Client], infectedorigin);
					enemypos[0]=infectedorigin[0]*0.4+infectedeyepos[0]*0.6;
					enemypos[1]=infectedorigin[1]*0.4+infectedeyepos[1]*0.6;
					enemypos[2]=infectedorigin[2]*0.4+infectedeyepos[2]*0.6;

					SubtractVectors(enemypos, robotpos, robotangle[Client]);
					GetVectorAngles(robotangle[Client],robotangle[Client]);
					targetok=true;
				}
				else
				{
					SIenemy[Client]=0;
				}
			}
			if(reloading[Client])
			{
				//CPrintToChatAll("%f", reloadtime[Client]);
				if(bullet[Client]>=RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]) && currenttime-reloadtime[Client]>weaponloadtime[weapontype[Client]])
				{
					reloading[Client]=false;
					reloadtime[Client]=currenttime;
					EmitSoundToAll(SOUNDREADY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
					//PrintHintText(Client, " ");
				}
				else
				{
					if(currenttime-reloadtime[Client]>weaponloadtime[weapontype[Client]])
					{
						reloadtime[Client]=currenttime;
						bullet[Client]+=RoundToNearest(weaponloadcount[weapontype[Client]]*RobotAmmoEffect[Client]);
						EmitSoundToAll(SOUNDRELOAD, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
						//PrintHintText(Client, "reloading %d", bullet[Client]);
					}
				}
			}
			if(!reloading[Client])
			{
				if(!targetok)
				{
					if(bullet[Client]<RoundToNearest(weaponclipsize[weapontype[Client]]*RobotAmmoEffect[Client]))
					{
						reloading[Client]=true;
						reloadtime[Client]=0.0;
						if(!weaponloaddisrupt[weapontype[Client]])
						{
							bullet[Client]=0;
						}
					}
				}
			}
			chargetime=fireinterval[weapontype[Client]];
			if(!reloading[Client])
			{
				if(currenttime-firetime[Client]>chargetime)
				{

					if( targetok)
					{
						if(bullet[Client]>0)
						{
							bullet[Client]=bullet[Client]-1;

							FireBullet(Client, robot[Client], enemypos, robotpos);

							firetime[Client]=currenttime;
						 	reloading[Client]=false;
						}
						else
						{
							firetime[Client]=currenttime;
						 	EmitSoundToAll(SOUNDCLIPEMPTY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
							reloading[Client]=true;
							reloadtime[Client]=currenttime;
						}

					}

				}

			}
 			GetClientEyePosition(Client,  Clienteyepos);
			Clienteyepos[2]+=20.0;
			GetClientEyeAngles(Client, Clientangle);
			new Float:distance = GetVectorDistance(robotpos, Clienteyepos);
			if(distance>500.0)
			{
				TeleportEntity(robot[Client], Clienteyepos,  robotangle[Client] ,NULL_VECTOR);
			}
			else if(distance>100.0)
			{

				MakeVectorFromPoints( robotpos, Clienteyepos, robotvec);
				NormalizeVector(robotvec,robotvec);
				ScaleVector(robotvec, 5*distance);
				if (!targetok )
				{
					GetVectorAngles(robotvec, robotangle[Client]);
				}
				TeleportEntity(robot[Client], NULL_VECTOR,  robotangle[Client] ,robotvec);
				walktime[Client]=currenttime;
			}
			else
			{
				robotvec[0]=robotvec[1]=robotvec[2]=0.0;
				if(!targetok && currenttime-firetime[Client]>4.0)robotangle[Client][1]+=5.0;
				TeleportEntity(robot[Client], NULL_VECTOR,  robotangle[Client] ,robotvec);
			}
		 	keybuffer[Client]=button;
		}
	}
	else
	{
		botenerge[Client]=botenerge[Client]-duration*0.5;
		if(botenerge[Client]<0.0)botenerge[Client]=0.0;
	}
}
public OnGameFrame()
{
	decl weaponid, Float:currenttime, Float:duration, String:weaponname[32];
	
	if(WRQL>0)
	{
		SetWeaponSpeed();
		WRQL = 0;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2 && ZB_GunSpeed[i] > 0)
		{
			weaponid = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");	
			if (IsValidEdict(weaponid))
			{
				GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
				if (StrContains(weaponname, "melee", false) < 0)
					SetWeaponAttackSpeed(weaponid, 1.0 + ZB_GunSpeed[i], false, true);
			}
		}
	}

	
	
	if (IsActionQTSXJ || IsActionQTHDJ)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
			{
				weaponid = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if (IsValidEdict(weaponid))
				{
					GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
					if (StrContains(weaponname, "melee", false) < 0)
					{
						if (IsActionQTSXJ)
							SetWeaponAttackSpeed(weaponid, 2.0 + ZB_GunSpeed[i], false, true);
						if (IsActionQTHDJ)
							SetWeaponAttackSpeed(weaponid, 2.0, true, false);
					}
				}
			}
		}
	}
	
	if(!robot_gamestart)	
		return;
		
	currenttime = GetEngineTime();
	duration = currenttime-lasttime;
	
	if(duration<0.0 || duration>1.0)	
		duration=0.0;
		
	for (new Client = 1; Client <= MaxClients; Client++)
	{
		if(IsClientInGame(Client)) 
		{
			Do(Client, currenttime, duration);	//循环
			if(Robot_appendage[Client] > 0)
			{
				Do_clone(Client,currenttime,duration);
			}
		}
	}
	
	lasttime = currenttime;
}
ScanEnemy(Client, Float:rpos[3] )
{
	decl Float:infectedpos[3];
	decl Float:vec[3];
	decl Float:angle[3];
	new Float:dis=0.0;
	new iMaxEntities = GetMaxEntities();
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if(IsCommonInfected(iEntity) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", infectedpos);
			infectedpos[2]+=40.0;
			dis=GetVectorDistance(rpos, infectedpos) ;
			//CPrintToChatAll("%f %N" ,dis, i);
			if(dis < RobotRangeEffect[Client])
			{
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				new Handle:trace = TR_TraceRayFilterEx(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndCI, robot[Client]);
				
				if(!TR_DidHit(trace))
				{
					CloseHandle(trace);
					return iEntity;
				} else CloseHandle(trace);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
		{
			GetClientEyePosition(i, infectedpos);
			dis=GetVectorDistance(rpos, infectedpos) ;
			//CPrintToChatAll("%f %N" ,dis, i);
			if(dis < RobotRangeEffect[Client])
			{
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				new Handle:trace = TR_TraceRayFilterEx(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, robot[Client]);

				if(!TR_DidHit(trace))
				{
					CloseHandle(trace);
					return i;
				} else CloseHandle(trace);
			}
		}
	}
	return 0;
}
ScanEnemy_clone(Client, Float:rpos[3] )
{
	decl Float:infectedpos[3];
	decl Float:vec[3];
	decl Float:angle[3];
	new Float:dis=0.0;
	new iMaxEntities = GetMaxEntities();
	//MaxClients 为玩家数量
	//iMaxEntities 所有实体数量
	
	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
		{
			//CPrintToChat(Client,"扫描到僵尸");
			GetClientEyePosition(i, infectedpos);
			dis=GetVectorDistance(rpos, infectedpos) ;
			//CPrintToChatAll("%f %N ===" ,dis, Client);
			if(dis < RobotRangeEffect[Client])
			{
				//CPrintToChat(Client,"僵尸1离克隆机器人的距离为:%f",dis);
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				new Handle:trace = TR_TraceRayFilterEx(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, robot_clone[Client]);

				if(!TR_DidHit(trace))
				{
					CloseHandle(trace);
					return i;
				} else CloseHandle(trace);
			}
		}
	}	
	
	
	
	
	//for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	for(new iEntity=iMaxEntities; iEntity >= MaxClients + 1; iEntity--)
	{
		//CPrintToChat(Client,"扫描到除幸存者以外的僵尸");
		if(IsCommonInfected(iEntity) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", infectedpos);
			infectedpos[2]+=40.0;
			dis=GetVectorDistance(rpos, infectedpos) ;
			//CPrintToChatAll("%f %N" ,dis, Client);
			if(dis < RobotRangeEffect[Client])
			{
				//CPrintToChat(Client,"僵尸2离克隆机器人的距离为:%f",dis);
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				new Handle:trace = TR_TraceRayFilterEx(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndCI, robot_clone[Client]);
				
				if(!TR_DidHit(trace))
				{
					CloseHandle(trace);
					return iEntity;
				} else CloseHandle(trace);
			}
		}
	}


	
	return 0;
}
FireBullet(controller, bot, Float:infectedpos[3], Float:botorigin[3])
{
	decl Float:vAngles[3];
	decl Float:vAngles2[3];
	decl Float:pos[3];
	SubtractVectors(infectedpos, botorigin, infectedpos);
	GetVectorAngles(infectedpos, vAngles);
	new Float:arr1;
	new Float:arr2;
	arr1=0.0-bulletaccuracy[weapontype[controller]];
	arr2=bulletaccuracy[weapontype[controller]];
	decl Float:v1[3];
	decl Float:v2[3];
	//CPrintToChatAll("%f %f",arr1, arr2);
	for(new c=0; c<weaponbulletpershot[weapontype[controller]];c++)
	{
		//CPrintToChatAll("fire");
		vAngles2[0]=vAngles[0]+GetRandomFloat(arr1, arr2);
		vAngles2[1]=vAngles[1]+GetRandomFloat(arr1, arr2);
		vAngles2[2]=vAngles[2]+GetRandomFloat(arr1, arr2);
		new hittarget=0;
		new Handle:trace = TR_TraceRayFilterEx(botorigin, vAngles2, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, bot);
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace);
			hittarget=TR_GetEntityIndex( trace);
		}
		CloseHandle(trace);
		if((hittarget>0 && hittarget<=MaxClients) || IsCommonInfected(hittarget) || IsWitch(hittarget))
		{
			if(IsCommonInfected(hittarget) || IsWitch(hittarget))	DealDamage(controller,hittarget,RoundToNearest((RobotAttackEffect[controller])*weaponbulletdamage[weapontype[controller]]/(1.0 + StrEffect[controller] + EnergyEnhanceEffect_Attack[controller])),2,"robot_attack");
			else	DealDamage(controller,hittarget,RoundToNearest((RobotAttackEffect[controller])*weaponbulletdamage[weapontype[controller]]),2,"robot_attack");
			ShowParticle(pos, PARTICLE_BLOOD, 0.5);
		}
		SubtractVectors(botorigin, pos, v1);
		NormalizeVector(v1, v2);
		ScaleVector(v2, 36.0);
		SubtractVectors(botorigin, v2, infectedorigin);
		decl color[4];
		color[0] = 200;
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
		new Float:life=0.06;
		new Float:width1=0.01;
		new Float:width2=0.08;
		TE_SetupBeamPoints(infectedorigin, pos, g_BeamSprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
		TE_SendToAll();
		//EmitAmbientSound(SOUND[weapontype[controller]], vOrigin, controller, SNDLEVEL_RAIDSIREN);
		EmitSoundToAll(SOUND[weapontype[controller]], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, botorigin, NULL_VECTOR, false, 0.0);
	}
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	return true;
}

public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

public bool:TraceRayDontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	return true;
}

public bool:TraceRayDontHitSelfAndCI(entity, mask, any:data)
{
	new iMaxEntities = GetMaxEntities();
	if(entity == data)
	{
		return false;
	}
	else if(entity>MaxClients && entity<=iMaxEntities)
	{
		return false;
	}
	return true;
}

/******************************************************
*	玩家面板
*******************************************************/
BuildPlayerPanel(client)
{
	if (!IsValidPlayer(client))
		return;
	if (IsFakeClient(client))
		return; 
		
	new String:text[256];
	new connectmaxnum = maxclToolzDowntownCheck();
	new connectnum = GetAllPlayerCount();
	new maxsurvivor = GetConVarInt(cv_survivor_limit);
	new teamnum;
	new Handle:playerpanel = CreatePanel();
	SetPanelTitle(playerpanel, "玩家面板");
	DrawPanelText(playerpanel, " \n");

	if (playerpanel == INVALID_HANDLE)
		return;
	
	//旁观
	teamnum = CountPlayersTeam(1);
	Format(text, sizeof(text), "旁观(%d): ", teamnum);
	DrawPanelText(playerpanel, text);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 1)
		{
			Format(text, sizeof(text), "闲:%N", i);
			DrawPanelText(playerpanel, text);
		}
	}
	
	DrawPanelText(playerpanel, " \n");	
	teamnum = CountPlayersTeam(2);
	
	Format(text, sizeof(text), "爆菊者(%d/%d): ", teamnum, maxsurvivor);	
	DrawPanelText(playerpanel, text);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 2)
		{
			if (IsPlayerAlive(i)) 
					Format(text, sizeof(text), "爆菊:%N", i);
			else if (!IsPlayerAlive(i))
					Format(text, sizeof(text), "被爆死:%N", i);			
						
			DrawPanelText(playerpanel, text);
		}
	}		
	DrawPanelText(playerpanel, "\n");
	//连接数
	Format(text, sizeof(text), "在线人数: (%d/%d)", connectnum, connectmaxnum);
	DrawPanelText(playerpanel, text);

	SendPanelToClient(playerpanel, client, PlayerListMenu, MENU_TIME_FOREVER);
	CloseHandle(playerpanel);	
}

//面板传输回调
public PlayerListMenu(Handle:menu, MenuAction:action, client, param)
{

}

//sm_wanjia回调
public Action:Command_playerlistpanel(Client,args)
{
	BuildPlayerPanel(Client);
	return Plugin_Handled;
}

//玩家面板菜单回调
public Action:MenuFunc_TeamInfo(Client)
{	
	BuildPlayerPanel(Client);
	return Plugin_Handled;
}

/******************************************************
*	弹药师
*******************************************************/

/******************************************************
*	弹药专家
*******************************************************/

//破碎弹_学习
public Action:MenuFunc_AddBrokenAmmo(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习破碎弹 目前等级: %d/%d 发动指令: !psd - 技能点剩余: %d", BrokenAmmoLv[Client], LvLimit_BrokenAmmo, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 启用后对射击后子弹破碎对小范围内的感染者造成一定伤害.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "破碎伤害: %d", BrokenAmmoDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.1f", BrokenAmmoDuration[Client]);

	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddBrokenAmmo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddBrokenAmmo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(BrokenAmmoLv[Client] < LvLimit_BrokenAmmo)
			{
				BrokenAmmoLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "\x03[技能] {green}破碎弹\x03等级变为{green}Lv.%d\x03", BrokenAmmoLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddBrokenAmmo(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//破碎弹_快捷指令
public Action:UseBrokenAmmo(Client, args)
{
	if(GetClientTeam(Client) == 2) 
		BrokenAmmo_Action(Client);
	else 
		CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

//破碎弹_使用
public BrokenAmmo_Action(Client)
{
	if(JD[Client] != 6)
	{
		CPrintToChat(Client, MSG_NEED_JOB6);
		return;
	}

	if(BrokenAmmoLv[Client] <= 0)
	{
		CPrintToChat(Client, "你没有学习该技能!");
		return;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return;
	}

	if(Broken_Ammo[Client] || Poison_Ammo[Client] || SuckBlood_Ammo[Client])
	{
		CPrintToChat(Client, "你已经启动了一种弹药技能了!");
		return;
	}

	if(MP_BrokenAmmo > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MP_BrokenAmmo, MP[Client]);
		return;
	}
	
	MP[Client] -= MP_BrokenAmmo;
	Broken_Ammo[Client] = true;
	CPrintToChatAll("\x03[技能] \x03%N {blue}启动了{green}Lv.%d{blue}的{olive}破碎弹{blue}!", Client, BrokenAmmoLv[Client]);
	CreateTimer(BrokenAmmoDuration[Client], BrokenAmmo_Stop, Client);
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarDuration", BrokenAmmoDuration[Client]);
}

//破碎弹_停止
public Action:BrokenAmmo_Stop(Handle:timer, any:Client)
{
	if (Broken_Ammo[Client])
		Broken_Ammo[Client] = false;
	
	if (IsValidPlayer(Client, false))
		CPrintToChat(Client, "\x03[技能] \x03破碎弹{blue}结束了!");
	
	KillTimer(timer);
}

//破碎弹_攻击
public BrokenAmmoRangeAttack(Client, Float:pos[3])
{		
	new Float:entpos[3];
	new Float:distance;
	new MaxEnt = GetMaxEntities();
	decl String:weaponclass[64], weaponid;
	
	decl Float:Direction[3];
	Direction[0] = GetRandomFloat(-1.0, 1.0);
	Direction[1] = GetRandomFloat(-1.0, 1.0);
	Direction[2] = GetRandomFloat(-1.0, 1.0);
	
	if (IsValidPlayer(Client) && IsValidEntity(Client))
	{
		weaponid = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEdict(weaponid) && IsValidEntity(weaponid))
			GetEdictClassname(weaponid, weaponclass, sizeof(weaponclass));
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || !IsValidEntity(i) || i == Client) 
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);	
		distance = GetVectorDistance(pos, entpos);
		if (distance <= BrokenAmmoRange)
		{
			if (GetClientTeam(i) != GetClientTeam(Client))
			{
				if (StrContains(weaponclass, "shotgun", false) >= 0)
					DealDamage(Client, i, BrokenAmmoDamage[Client] / 8, -2139094974);
				else 
					DealDamage(Client, i, BrokenAmmoDamage[Client], -2139094974);
			}
			else
				DealDamage(Client, i, BrokenAmmoDamage[Client] / 50, 0);
				
			TE_SetupSparks(entpos, Direction, 2, 3);
			TE_SendToAll();		
		}
	}
	
	for (new iEnt = MaxClients + 1; iEnt <= MaxEnt; iEnt++)
	{				
		if(IsValidEntity(iEnt) && IsCommonInfected(iEnt) && GetEntProp(iEnt, Prop_Data, "m_iHealth") > 0)
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", entpos);	
			distance = GetVectorDistance(pos, entpos);
			if (distance <= BrokenAmmoRange)
			{
				if (StrContains(weaponclass, "shotgun", false) > 0)
				DealDamage(Client, iEnt, BrokenAmmoDamage[Client] / 8, -2139094974);
				else DealDamage(Client, iEnt, BrokenAmmoDamage[Client], -2139094974);
				TE_SetupSparks(entpos, Direction, 2, 3);
				TE_SendToAll();		
			}
		}
	
	}

}

//破碎弹_效果
public BrokenAmmoRangeEffects(Client, Float:pos[3])
{
	if (!IsValidPlayer(Client))
		return;
	if (!Broken_Ammo[Client])
		return;

	decl Float:Direction[3];
	Direction[0] = GetRandomFloat(-1.0, 1.0);
	Direction[1] = GetRandomFloat(-1.0, 1.0);
	Direction[2] = GetRandomFloat(-1.0, 1.0);
	
	TE_SetupSparks(pos, Direction, 4, 5);
	TE_SendToAll();		
	
	BrokenAmmoRangeAttack(Client, pos);
}


//渗毒弹_学习
public Action:MenuFunc_AddPoisonAmmo(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习渗毒弹 目前等级: %d/%d 发动指令: !sdd - 技能点剩余: %d", PoisonAmmoLv[Client], LvLimit_PoisonAmmo, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 启用后对被射击的目标造成持续的毒性伤害");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "渗毒伤害: %d", PoisonAmmoDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.1f", PoisonAmmoDuration[Client]);

	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddPoisonAmmo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddPoisonAmmo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(PoisonAmmoLv[Client] < LvLimit_PoisonAmmo)
			{
				PoisonAmmoLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "\x03[技能] {green}渗毒弹\x03等级变为{green}Lv.%d\x03", PoisonAmmoLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddPoisonAmmo(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//渗毒弹_快捷指令
public Action:UsePoisonAmmo(Client, args)
{
	if(GetClientTeam(Client) == 2) 
		PoisonAmmo_Action(Client);
	else 
		CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

//渗毒弹_使用
public PoisonAmmo_Action(Client)
{
	if(JD[Client] != 6)
	{
		CPrintToChat(Client, MSG_NEED_JOB6);
		return;
	}

	if(PoisonAmmoLv[Client] <= 0)
	{
		CPrintToChat(Client, "你没有学习该技能!");
		return;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return;
	}

	if(Broken_Ammo[Client] || Poison_Ammo[Client] || SuckBlood_Ammo[Client])
	{
		CPrintToChat(Client, "你已经启动了一种弹药专家技能了!");
		return;
	}

	if(MP_PoisonAmmo > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MP_PoisonAmmo, MP[Client]);
		return;
	}
	
	MP[Client] -= MP_PoisonAmmo;
	Poison_Ammo[Client] = true;
	CPrintToChatAll("{olive}[技能] {green}%N {blue}启动了{green}Lv.%d{blue}的{olive}渗毒弹{blue}!", Client, PoisonAmmoLv[Client]);
	CreateTimer(PoisonAmmoDuration[Client], PoisonAmmo_Stop, Client);
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarDuration", PoisonAmmoDuration[Client]);
}

//渗毒弹_停止
public Action:PoisonAmmo_Stop(Handle:timer, any:Client)
{
	if (Poison_Ammo[Client])
		Poison_Ammo[Client] = false;
	
	if (IsValidPlayer(Client, false))
		CPrintToChat(Client, "{olive}[技能] {green}渗毒弹{blue}结束了!");
	
	KillTimer(timer);
}

//渗毒弹_攻击
public PoisonAmmoAttack(Client, target, String:weapon[])
{
	if (!IsValidPlayer(Client))
		return;
	if (!Poison_Ammo[Client])
		return;

	if (IsValidEntity(target) && GetClientTeam(target) == 3 && GetEntProp(target, Prop_Data, "m_iHealth") > 0)
	{	
		if (StrContains(weapon, "shotgun", false) > 0)
			DealDamageRepeat(Client, target, PoisonAmmoDamage[Client] / 8, 0, "", 1.0, PoisonAmmoDamageTime[Client]);
		else if (StrContains(weapon, "smg", false) > 0)
			DealDamageRepeat(Client, target, PoisonAmmoDamage[Client] / 2, 0, "", 1.0, PoisonAmmoDamageTime[Client]);
		else
			DealDamageRepeat(Client, target, PoisonAmmoDamage[Client], 0, "", 1.0, PoisonAmmoDamageTime[Client]);	
	}

}

//吸血弹_学习
public Action:MenuFunc_AddSuckBloodAmmo(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习吸血弹 目前等级: %d/%d 发动指令: !xxd - 技能点剩余: %d", SuckBloodAmmoLv[Client], LvLimit_SuckBloodAmmo, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 启用后对被射击感染者时有一定几率恢复血量.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "吸血几率: %.1f", SuckBloodAmmoPBB[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %.1f", SuckBloodAmmoDuration[Client]);

	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddSuckBloodAmmo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddSuckBloodAmmo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SuckBloodAmmoLv[Client] < LvLimit_SuckBloodAmmo)
			{
				SuckBloodAmmoLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "{olive}[技能] {green}吸血弹{lightgreen}等级变为{green}Lv.%d{lightgreen}", SuckBloodAmmoLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddSuckBloodAmmo(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//吸血弹_快捷指令
public Action:UseSuckBloodAmmo(Client, args)
{
	if(GetClientTeam(Client) == 2) 
		SuckBloodAmmo_Action(Client);
	else 
		CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

//吸血弹_使用
public SuckBloodAmmo_Action(Client)
{
	if(JD[Client] != 6)
	{
		CPrintToChat(Client, MSG_NEED_JOB6);
		return;
	}

	if(SuckBloodAmmoLv[Client] <= 0)
	{
		CPrintToChat(Client, "你没有学习该技能!");
		return;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return;
	}

	if(Broken_Ammo[Client] || Poison_Ammo[Client] || SuckBlood_Ammo[Client])
	{
		CPrintToChat(Client, "你已经启动了一种弹药专家技能了!");
		return;
	}

	if(MP_SuckBloodAmmo > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MP_SuckBloodAmmo, MP[Client]);
		return;
	}
	
	MP[Client] -= MP_SuckBloodAmmo;
	SuckBlood_Ammo[Client] = true;
	CPrintToChatAll("{olive}[技能] {green}%N {blue}启动了{green}Lv.%d{blue}的{olive}吸血弹{blue}!", Client, SuckBloodAmmoLv[Client]);
	CreateTimer(SuckBloodAmmoDuration[Client], SuckBloodAmmo_Stop, Client);
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(Client, Prop_Send, "m_flProgressBarDuration", SuckBloodAmmoDuration[Client]);
}

//吸血弹_停止
public Action:SuckBloodAmmo_Stop(Handle:timer, any:Client)
{
	if (SuckBlood_Ammo[Client])
		SuckBlood_Ammo[Client] = false;
	
	if (IsValidPlayer(Client, false))
		CPrintToChat(Client, "{olive}[技能] {green}吸血弹{blue}结束了!");
	
	KillTimer(timer);
}

//吸血弹_攻击
public SuckBloodAmmoAttack(Client, target)
{
	if (!IsValidPlayer(Client))
		return;
	if (!SuckBlood_Ammo[Client])
		return;

	if (IsValidEntity(Client))
	{
		if (IsValidEntity(target) && GetEntProp(target, Prop_Data, "m_iHealth") > 0)
		{
			new Float:random = GetRandomFloat(0.0, 100.0);
			if (random <= SuckBloodAmmoPBB[Client])
				SuckBloodAmmoSuck(Client, target);
		}
	}
}

//吸血弹_吸血
public SuckBloodAmmoSuck(Client, target)
{
	new ihealth = GetEntProp(Client, Prop_Data, "m_iHealth");
	new imaxhealth = GetEntProp(Client, Prop_Data, "m_iMaxHealth");
	new suckhealth = GetRandomInt(1, 5) + ihealth;
	EmitSoundToClient(Client, SOUND_SUCKBLOOD);
	if (suckhealth >= imaxhealth)
	{
		SetEntProp(Client, Prop_Data, "m_iHealth", imaxhealth);
		ScreenFade(Client, 20, 120, 20, 80, 100, 1);
	}
	else
	{
		SetEntProp(Client, Prop_Data, "m_iHealth", suckhealth);
		ScreenFade(Client, 20, 120, 20, 80, 100, 1);
	}
}


//区域爆破
public Action:MenuFunc_AddAreaBlasting(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习区域爆破 目前等级: %d/%d 发动指令: !qybp - 技能点剩余: %d", AreaBlastingLv[Client], LvLimit_AreaBlasting, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 对自身的一定范围内的所有感染者产生火球术伤害.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "爆破范围: %d", AreaBlastingRange[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "爆破伤害: %d", AreaBlastingDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.1f", AreaBlastingCD[Client]);

	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAreaBlasting, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAreaBlasting(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(AreaBlastingLv[Client] < LvLimit_AreaBlasting)
			{
				AreaBlastingLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "{olive}[技能] {green}区域爆破{lightgreen}等级变为{green}Lv.%d{lightgreen}", AreaBlastingLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddAreaBlasting(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//区域爆破_快捷指令
public Action:UseAreaBlasting(Client, args)
{
	if(GetClientTeam(Client) == 2) 
		AreaBlasting_Action(Client);
	else 
		CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}


//区域爆破_使用
public AreaBlasting_Action(Client)
{
	if(JD[Client] != 6)
	{
		CPrintToChat(Client, MSG_NEED_JOB6);
		return;
	}

	if(AreaBlastingLv[Client] <= 0)
	{
		CPrintToChat(Client, "你没有学习该技能!");
		return;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return;
	}

	if(AreaBlasting[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return;
	}

	if(MP_AreaBlasting > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MP_AreaBlasting, MP[Client]);
		return;
	}
	
	MP[Client] -= MP_AreaBlasting;
	AreaBlasting[Client] = true;
	AreaBlastingAttack(Client);
	CPrintToChatAll("{olive}[技能] {green}%N {blue}启动了{green}Lv.%d{blue}的{olive}区域爆破{blue}!", Client, AreaBlastingLv[Client]);
	CreateTimer(AreaBlastingCD[Client], AreaBlasting_Stop, Client);
}

//区域爆破_冷却
public Action:AreaBlasting_Stop(Handle:timer, any:Client)
{
	if (AreaBlasting[Client])
		AreaBlasting[Client] = false;
	
	if (IsValidPlayer(Client, false))
		CPrintToChat(Client, "{olive}[技能] {green}区域爆破{blue}冷却结束了!");
	
	KillTimer(timer);
}

//区域爆破_攻击
public AreaBlastingAttack(Client)
{
	if (!IsValidEntity(Client))	
		return;

	new Float:pos[3];
	new Float:entpos[3];
	new Float:distance;
	new Float:skypos[3];
	new MaxEnt = GetMaxEntities();	
	
	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);		
	SuperTank_LittleFlower(Client, pos, 1);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || !IsValidEntity(i) || i == Client || GetClientTeam(i) == GetClientTeam(Client)) 
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);	
		distance = GetVectorDistance(pos, entpos);
		if (distance <= AreaBlastingRange[Client])
		{		
			DealDamage(Client, i, AreaBlastingDamage[Client], 16777280);
			skypos[0] = entpos[0];
			skypos[1] = entpos[1];
			skypos[2] = entpos[2] + 2000.0;
			TE_SetupBeamPoints(skypos, entpos, g_BeamSprite, 0, 0, 0, 5.0, 5.0, 5.0, 10, 1.0, WhiteColor, 0);
			TE_SendToAll();
		}
	}
	
	for (new iEnt = MaxClients + 1; iEnt <= MaxEnt; iEnt++)
	{				
		if(IsValidEntity(iEnt) && IsCommonInfected(iEnt))
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", entpos);	
			distance = GetVectorDistance(pos, entpos);
			if (distance <= AreaBlastingRange[Client])
				DealDamage(Client, iEnt, AreaBlastingDamage[Client], 16777280);
		}
	
	}
	

}


//镭射激光炮_学习
public Action:MenuFunc_AddLaserGun(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习镭射激光炮 目前等级: %d/%d 发动指令: !lsjgp - 技能点剩余: %d", LaserGunLv[Client], LvLimit_LaserGun, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 向前方发射一条直线的强力激光炮,摧毁线上的所有生物!(需要技能点:60)");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "造成伤害: %d", LaserGunDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.1f", LaserGunCD[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddLaserGun, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddLaserGun(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 60)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(LaserGunLv[Client] < LvLimit_LaserGun)
			{
				LaserGunLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "{olive}[技能] {green}镭射激光炮{lightgreen}等级变为{green}Lv.%d{lightgreen}", LaserGunLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddLaserGun(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//镭射激光炮_快捷指令
public Action:UseLaserGun(Client, args)
{
	if(GetClientTeam(Client) == 2) 
		LaserGun_Action(Client);
	else 
		CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

//镭射激光炮_使用
public LaserGun_Action(Client)
{
	if(JD[Client] != 6)
	{
		CPrintToChat(Client, MSG_NEED_JOB6);
		return;
	}

	if(LaserGunLv[Client] <= 0)
	{
		CPrintToChat(Client, "你没有学习该技能!");
		return;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return;
	}

	if(LaserGun[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return;
	}

	if(MaxMP[Client] > MP[Client] && MP[Client] > 50000)
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, MaxMP[Client], MP[Client]);
		return;
	}
	
	MP[Client] = 1;
	LaserGun[Client] = true;
	LaserGunAttack(Client);
	CPrintToChatAll("{olive}[技能] {green}%N {blue}启动了{green}Lv.%d{blue}的{olive}镭射激光炮{blue}!", Client, LaserGunLv[Client]);
	CreateTimer(LaserGunCD[Client], LaserGun_Stop, Client);
}

//镭射激光炮_冷却
public Action:LaserGun_Stop(Handle:timer, any:Client)
{
	if (LaserGun[Client])
		LaserGun[Client] = false;
	
	if (IsValidPlayer(Client, false))
		CPrintToChat(Client, "{olive}[技能] {green}镭射激光炮{blue}冷却结束了!");
	
	KillTimer(timer);
}


//镭射激光炮_攻击
public LaserGunAttack(Client)
{
	if (!IsValidEntity(Client))
		return;
	
	new Float:pos[3];
	new Float:aimpos[3];
	new Float:eyepos[3];
	new Float:angle[3];
	new Float:velocity[3];
	new Float:TempPos[3];
		
	new entity = CreateEntityByName("tank_rock");
	GetTracePosition(Client, aimpos); //得到目标位置
	GetClientEyePosition(Client, eyepos);
	GetClientEyePosition(Client, pos);
	MakeVectorFromPoints(eyepos, aimpos, angle);
	NormalizeVector(angle, angle);
	
	TempPos[0] = angle[0] * 50;
	TempPos[1] = angle[1] * 50;
	TempPos[2] = angle[2] * 50;
	AddVectors(eyepos, TempPos, eyepos);
	
	velocity[0] = angle[0] * 300.0;
	velocity[1] = angle[1] * 300.0;
	velocity[2] = angle[2] * 300.0;
	
	if (IsValidEntity(entity) && IsValidEdict(entity))
	{
		LaserGunDamagetimer[Client] = 0.0;

		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", Client);
		DispatchSpawn(entity);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
		SetEntityGravity(entity, 0.1);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Data, "m_MoveCollide", 0);
		TeleportEntity(entity, eyepos, angle, velocity);
		
		new Handle:pack = CreateDataPack();
		CreateDataTimer(0.15, Timer_LaserGunAttack, pack, TIMER_REPEAT);
		WritePackCell(pack, entity);
		WritePackFloat(pack, angle[0]);
		WritePackFloat(pack, angle[1]);
		WritePackFloat(pack, angle[2]);
		WritePackFloat(pack, velocity[0]);
		WritePackFloat(pack, velocity[1]);
		WritePackFloat(pack, velocity[2]);
		TE_SetupBeamPoints(pos, aimpos, g_BeamSprite, 0, 0, 0, LaserGunDuration[Client], 60.0, 60.0, 10, 6.0, BlueColor, 0);
		TE_SendToAll();
	}
}

//镭射激光炮_伤害计时器
public Action:Timer_LaserGunAttack(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new entity = ReadPackCell(pack);
	
	if (!IsValidEntity(entity))
	{
		CreateTimer(0.1, Timer_LaserGunKill, entity);
		KillTimer(timer);	
	}
		
	new Client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	LaserGunDamagetimer[Client] += 0.15;
	new Float:angle[3];
	angle[0] = ReadPackFloat(pack);
	angle[1] = ReadPackFloat(pack);
	angle[2] = ReadPackFloat(pack);
	new Float:velocity[3];
	velocity[0] = ReadPackFloat(pack);
	velocity[1] = ReadPackFloat(pack);
	velocity[2] = ReadPackFloat(pack);
	new Float:pos[3];
	new Float:entpos[3];
	new Float:distance;
	new MaxEnt = GetMaxEntities();	
	new Float:skypos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);		
	TeleportEntity(entity, pos, angle, velocity);
	
	LittleFlower(pos, EXPLODE, Client);
	LittleFlower(pos, MOLOTOV, Client);
	skypos[0] = pos[0];
	skypos[1] = pos[1];
	skypos[2] = pos[2] + 2000.0;
	TE_SetupBeamPoints(skypos, pos, g_BeamSprite, 0, 0, 0, 0.5, 30.0, 30.0, 10, 5.0, RedColor, 0);
	TE_SendToAll();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || !IsValidEntity(i) || i == Client) 
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);	
		distance = GetVectorDistance(pos, entpos);
		if (distance <= 100)
		{
			if (GetClientTeam(i) != GetClientTeam(Client))
				DealDamage(Client, i, LaserGunDamage[Client], 0);
			else
				DealDamage(Client, i, LaserGunDamage[Client] / 5000, 0);
		}
	}
	
	for (new iEnt = MaxClients + 1; iEnt <= MaxEnt; iEnt++)
	{				
		if(IsValidEntity(iEnt) && IsCommonInfected(iEnt))
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", entpos);	
			distance = GetVectorDistance(pos, entpos);
			if (distance <= 100)
				DealDamage(Client, iEnt, LaserGunDamage[Client], 0);
		}
	}
	
	if (LaserGunDamagetimer[Client] >= LaserGunDuration[Client])
	{
		CreateTimer(0.1, Timer_LaserGunKill, entity);
		KillTimer(timer);
	}
}

//镭射激光炮_删除计时器
public Action:Timer_LaserGunKill(Handle:timer, any:entity)
{
	if (IsValidEntity(entity) && IsValidEdict(entity))
	{
		new Client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		LaserGunDamagetimer[Client] = 0.0;
		RemoveEdict(entity);
	}
}
/*
//雷神弹药_学习
public Action:MenuFunc_AddLZD(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习雷神弹药 目前等级: %d/%d 发动指令: !lzd - 技能点剩余: %d", LZDLv[Client], LvLimit_LZDLv, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 为自身枪械填充雷电子弹，按射击时按住E键切换成雷神弹药");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "雷神弹药等级到达20级才能学习不熄光环");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "子弹伤害: %d", lzdsh[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "子弹数量: %d", lzdsl[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.1f", lzdcd[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddLZD, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddLZD(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(LZDLv[Client] < LvLimit_LZDLv)
			{
				LZDLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "{olive}[技能] {green}雷神弹药{lightgreen}等级变为{green}Lv.%d{lightgreen}", LZDLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddLZD(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}
*/
//雷神弹药_学习
public Action:MenuFunc_AddLZD(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习雷神弹药 目前等级: %d/%d 发动指令: !lzd - 技能点剩余: %d", LZDLv[Client], LvLimit_LZDLv, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 为自身枪械填充雷电子弹，按射击时按住E键切换成雷神弹药");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "雷神弹药等级到达20级才能学习不熄光环");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "伤害: %d", lzdsh[Client]);
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "储存力量所需时间: %d", l4d2_lw_chargetime[Client]);
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.1f", lzdcd[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddLZD, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddLZD(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(LZDLv[Client] < LvLimit_LZDLv)
			{
				LZDLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, "{olive}[技能] {green}雷神弹药{lightgreen}等级变为{green}Lv.%d{lightgreen}", LZDLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddLZD(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//不熄光环_学习
public Action:MenuFunc_AddDCGY(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习不熄光环 目前等级: %d/%d 发动指令: !dcgy - 技能点剩余: %d", DCGYLv[Client], LvLimit_DCGYLv, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 使用技能有效时间内对自身周围的僵尸造成伤害，不过会扣MP哦(需要技能点:2)");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "不熄光环等级到达15级才能学习虚空雷圈");
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "不熄光环伤害: %d", dcgysh[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "不熄光环范围: %d", dcgyfw[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "不熄光环持续时间: %.1f", dcgysj[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "不熄光环CD时间: %.1f", DCcd[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddDCGY, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddDCGY(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 1)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(DCGYLv[Client] < LvLimit_DCGYLv)
			{
				DCGYLv[Client]++, SkillPoint[Client] -= 2;
				CPrintToChat(Client, "{olive}[技能] {green}不熄光环{lightgreen}等级变为{green}Lv.%d{lightgreen}", DCGYLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_DC_LEVEL_MAX);
				
			MenuFunc_AddDCGY(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//虚空雷圈_学习
public Action:MenuFunc_AddYLDS(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习虚空雷圈 目前等级: %d/%d 发动指令: !dcgy - 技能点剩余: %d", YLDSLv[Client], LvLimit_YLDSLv, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明:在准心制造一个电雷圈，持续一定时间，对范围内僵尸造成伤害(需要技能点:3)");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "虚空雷圈伤害: %d", yldssh[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "虚空雷圈范围: %d", ylds[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "虚空雷圈持续时间: %.1f", yldscx[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "虚空雷圈CD时间: %.1f", ylcd[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddYLDS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddYLDS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 2)	
				CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(YLDSLv[Client] < LvLimit_YLDSLv)
			{
				YLDSLv[Client]++, SkillPoint[Client] -= 3;
				CPrintToChat(Client, "{olive}[技能] {green}不熄光环{lightgreen}等级变为{green}Lv.%d{lightgreen}", YLDSLv[Client]);
			}
			else 
				CPrintToChat(Client, MSG_ADD_SKILL_CL_LEVEL_MAX);
				
			MenuFunc_AddYLDS(Client);
		} 
		else 
			MenuFunc_SurvivorSkill(Client);
	}
}

//特殊子弹功能
public Action:Event_WeaponFire2(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new iCid = GetClientOfUserId(GetEventInt(event, "userid"));
	//new iEntid = GetEntDataEnt2(iCid,S_rActiveW);
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(iCid, user_name, sizeof(user_name));  //得到客户端名字
	
	if (LZD[iCid] > 0)
	{
		button=GetClientButtons(iCid);//buttons = 按钮    意思是按钮 = 得到客户端按钮
		if(button & IN_USE)//意思是玩家按到E键
		{
			LZDXG(iCid);
		}
	}
	
	if (GouhunLv[iCid] > 0)
	{
		//ThdFunction(iCid);
		new sk = GetRandomInt(1, 10);  //GetRandomInt  是定义随机机率的，如获得天神附体跟冶炼药水成功率
		if (sk > 6)
		{
			new rnd1 = GetRandomInt(1, 150);
			if (rnd1 < 6)
			{
				XBFBFunction(iCid);
			}
		}
		else
		{
			new rnd2 = GetRandomInt(1, 150);
			if (rnd2 < 7)
			{
				FBZNFunction(iCid);
			}
		}
	}
}



//虚空之怒
public Action:MenuFunc_AddCqdz(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习虚空之怒 目前等级: %d/%d 发动指令: !cdz - 技能点剩余: %d", CqdzLv[Client], LvLimit_Cqdz, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 范围内所有普通僵尸直接秒杀,更加强大的地震!.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "最大数量: %d", CqdzMaxKill[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当前范围: %d", CqdzRadius[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddCqdz, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddCqdz(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(CqdzLv[Client] < LvLimit_Cqdz)
			{
				CqdzLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_EQD, CqdzLv[Client] , CqdzRadius[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_EQD_LEVEL_MAX);
			MenuFunc_AddCqdz(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}


//电弘赤炎
public Action:MenuFunc_AddHMZS(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习电弘赤炎 目前等级: %d/%d 发动指令: !hm - 技能点剩余: %d", HMZSLv[Client], LvLimit_HMZS, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 审判者的书籍, 燃烧范围内敌人 10秒冷却");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧持续: %.f秒", HMZSDuration[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧伤害: %d", HMZSDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "燃烧范围: %d", HMZSRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHMZS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHMZS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(HMZSLv[Client] < LvLimit_HMZS)
			{
				HMZSLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_HMD, HMZSLv[Client], HMZSDamage[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_HMD_LEVEL_MAX);
			MenuFunc_AddHMZS(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}

//涟漪光圈
public Action:MenuFunc_AddSPZS(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习涟漪光圈 目前等级: %d/%d 发动指令: !sp - 技能点剩余: %d", SPZSLv[Client], LvLimit_SPZS, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 审判者的大招放出雷电审判敌人!");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "审判伤害: %d", SPZSDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "发动范围: %d", SPZSLaunchRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "审判范围: %d", SPZSRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 智力");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddSPZS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddSPZS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SPZSLv[Client] < LvLimit_SPZS)
			{
				SPZSLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_SPS, SPZSLv[Client], SPZSDamage[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_SPS_LEVEL_MAX);
			MenuFunc_AddSPZS(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}


//幽冥暗量
public Action:MenuFunc_AddGouhun(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习幽冥暗量 目前等级: %d/%d 被动 - 菊花剩余: %d", GouhunLv[Client], LvLimit_Gouhun, Hunpo[Client]);
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "技能说明: 给予枪械特殊能力!! 所需100个坦克菊花，有两种技能。（转职为虚空之眼才开始收集坦克菊花）~~~");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "振幅爆炎: 向準心放出火焰风暴, 燃烧范围内敌人 5秒冷却。燃烧持续: %.2f秒   冰冻伤害: %d   冰冻范围: %d    加成属性: 智力", FBZNDuration[Client], FBZNDamage[Client], FBZNRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "振幅寒冰: 向準心放出振幅寒冰, 冻结范围内敌人。冰冻持续: %.2f秒   冰冻伤害: %d   冰冻范围: %d    加成属性: 智力", XBFBDuration[Client], XBFBDamage[Client], XBFBRadius[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddGouhun, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddGouhun(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(Hunpo[Client] < 100)	CPrintToChat(Client, MSG_LACK_Hunpo);
			else if(GouhunLv[Client] < LvLimit_Gouhun)
			{
				GouhunLv[Client]++; 
				Hunpo[Client] -= 100;
				CPrintToChat(Client, MSG_ADD_SKILL_GH, GouhunLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_GH_LEVEL_MAX);
			MenuFunc_AddGouhun(Client);
		} else MenuFunc_SurvivorSkill(Client);
	}
}


//雷神弹药
public Action:LZDXG(Client)
{
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(Client, user_name, sizeof(user_name));
	LZD[Client]--;

	//击杀小怪效果
	new Float:pos1[3];
	GetTracePosition(Client, pos1);  //得到微量位置
	ShowParticle(pos1, ChainLightning_Particle_hit, 0.02);  //显示粒子    连锁闪电有此代码
	new Float:entpos[3];  //跟tgpos定义相同
	new Float:tgpos[3];  //跟entpos定义相同
	new iMaxEntities = GetMaxEntities();	
	new Float:distance[3];  //距离
	new num;
	new num1;
	new Float:Radius=float(60);  //Radius = 半径
	new Float:pos2[3];  //定义目标 
	GetTracePosition(Client, pos2); //得到目标位置
	
	#define PARTICLE_SPAWNA "gas_explosion_main"
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)  //其它职业技能里有这行，统一的
    {
		if (num > 1)    //地震术有下面的代码  统一的，目的是让物体有击杀效果   【击杀数量大于1就结束此技能】
			break;
			
		if (!IsFakeClient(iEntity))  //IsCommonInfected = 常见的感染  
        {
			new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");  //GetEntProp = 得到人物属性，就是得到人物血量
			if (health > 0)
			{
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);  //得到目标
				SubtractVectors(entpos, pos2, distance);  //得到目标距离
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, iEntity, lzdsh[Client], -2139094974);  //DealDamage = 造成伤害
					AttachParticle(iEntity, PARTICLE_SPAWNA, 0.2);     //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
					EmitAmbientSound(ChainLightning_Sound_launch, entpos);   //EmitAmbientSound = 在物品周围播放技能音效
					num++;
				}
			}
		}
	}
	new Float:pos3[3];
	GetTracePosition(Client, pos3);  //得到目标的位置
	for (new i = 1; i <= MaxClients; i++)
	{
		if (num1 > 1)
			break;
		if (IsClientInGame(i))   //客户端在游戏
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", tgpos); //得到目标
				SubtractVectors(tgpos, pos3, distance);//得到目标距离
				if(GetVectorLength(distance) <= Radius)
				{	
					AttachParticle(i, PARTICLE_SPAWNA, 0.2);  //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
					DealDamage(Client, i, lzdsh[Client], -2139094974); //DealDamage = 造成伤害   连锁闪电效果
					EmitAmbientSound(ChainLightning_Sound_launch, tgpos);  //EmitAmbientSound = 在物品周围播放技能音效
					num1++;
				}
			}
		}
	}
	PrintHintText(Client, "你还拥有%d发雷神弹药", LZD[Client]);
	//CPrintToChatAll("{red}[EX觉醒\x05]:\x01玩家\x04 %N \x01启动了{red}雷神弹药", Client);	
	return Plugin_Handled;
}


/* 雷神弹药   启用此技能会先检测下面的MP，CD，如果不符合条件则return Plugin_Handled; = 返回插件处理(关闭此技能) */
public Action:LZDFunction(Client)
{
	if(!IsPlayerAlive(Client))//活着的幸存者
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}
	if(JD[Client] != 7)//职业
	{
		CPrintToChat(Client, MSG_NEED_JOB7);
		return Plugin_Handled;
	}

	if(LZDLv[Client] == 0)//雷神弹药等级
	{
		CPrintToChat(Client, MSG_NEED_SKILL_LZD);
		return Plugin_Handled;
	}
	if(LZDcd[Client])//技能是否冷却中
	{
		CPrintToChat(Client, MSG_SKILL_LZDcd_ENABLED);
		return Plugin_Handled;
	}
	if(MP[Client] < MP_LZD)
	{
		CPrintToChat(Client, MSG_SKILL_YL_MP, MP[Client]);
		return Plugin_Handled;
	}
	LZD[Client] += lzdsl[Client];	
	LZDcd[Client] = true;
	MP[Client] -= MP_LZD;
	CreateTimer(lzdcd[Client], Timer_LZDCD, Client);
	
	
	//CPrintToChatAll("\x01[技能] \x04%N \x01启动了\x04Lv.%d的雷神弹药，\x01填充\x04%d颗\x01雷神弹药", Client, LZDLv[Client], lzdsl[Client]);
	CPrintToChatAll("\x01[技能] \x04%N \x01启动了\x04Lv.%d的雷神弹药!!!", Client, LZDLv[Client]);
	
	if(LZD[Client] > 60)
	{
		CPrintToChat(Client, "\x04你的雷神弹药填充60发已达上限，无法继续填充");
		LZD[Client] = 60;
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}
public Action:Timer_LZDCD(Handle:timer, any:Client)
{
	LZDcd[Client] = false;
	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, "\x04雷神弹药冷却时间结束");
	}
}

//虚空雷圈
public Action:YLDSFunction(Client)
{
	if(!IsPlayerAlive(Client))//活着的幸存者
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}
	if(JD[Client] != 7)//职业
	{
		CPrintToChat(Client, MSG_NEED_JOB7);
		return Plugin_Handled;
	}

	if(YLDSLv[Client] == 0)//虚空雷圈等级
	{
		CPrintToChat(Client, MSG_NEED_SKILL_YL);
		return Plugin_Handled;
	}
	if(Isylds[Client])//虚空雷圈冷却时间结束
	{
		CPrintToChat(Client, MSG_SKILL_YLDS_ENABLED);
		return Plugin_Handled;
	}
	if(yldscd[Client])//虚空雷圈效果结束，技能进入冷却状态
	{
		CPrintToChat(Client, MSG_SKILL_YLDScd_ENABLED);
		return Plugin_Handled;
	}
	if(MP[Client] < MP_YLDS)
	{
		CPrintToChat(Client, MSG_SKILL_YL_MP, MP[Client]);
		return Plugin_Handled;
	}

	new Float:Radius=float(ylds[Client]);
	new Float:pos[3];
	new Float:_pos[3];
	GetTracePosition(Client, _pos);  //得到目标位置
	pos[0] = _pos[0];
	pos[1] = _pos[1];
	pos[2] = _pos[2]+10.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new Float:pos1[3];
	new Float:_pos1[3];
	GetTracePosition(Client, _pos1); //得到目标位置
	pos1[0] = _pos1[0];
	pos1[1] = _pos1[1];
	pos1[2] = _pos1[2]+30.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos1, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new Float:pos2[3];
	new Float:_pos2[3];
	GetTracePosition(Client, _pos2); //得到目标位置
	pos2[0] = _pos2[0];
	pos2[1] = _pos2[1];
	pos2[2] = _pos2[2]+50.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos2, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.5, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();

	new Float:NowLocation[3];
	GetTracePosition(Client, NowLocation); //得到目标位置
	
	new Float:SkyLocation[3];
	SkyLocation[0] = NowLocation[0];
	SkyLocation[1] = NowLocation[1];
	SkyLocation[2] = NowLocation[2] + 150.0;
	ShowParticle(SkyLocation, HealingBall_Particle_Effect, 1.5);//光点显示
		
	Isylds[Client] = true;
	yldscd[Client] = true;
	MP[Client] -= MP_YLDS;
	
	new Handle:pack;
	yldsTimer[Client] = CreateDataTimer(yldssj[Client], yldsFunction, pack, TIMER_REPEAT);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	WritePackFloat(pack, GetEngineTime());
	
	//EmitSoundToAll(ChainLightning_Sound_launch, Client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, _pos, NULL_VECTOR, true, 0.0);
	EmitSoundToAll(ChainLightning_Sound_launch, Client);  //EmitSoundToAll = 全体玩家听到播放技能的音效
	CPrintToChatAll("\x01[技能] \x04%N \x01启动了\x04Lv.%d的虚空雷圈!", Client, YLDSLv[Client]);	
	return Plugin_Handled;
}

public Action:yldsFunction(Handle:timer, Handle:pack)
{
	decl Float:pos[3], Float:entpos[3], Float:distance[3];
	
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	new Float:time=ReadPackFloat(pack);
	
	new iMaxEntities = GetMaxEntities();
	new num;
	
	//new iMaxEntities = GetMaxEntities();
	new Float:Radius=float(ylds[Client]);
	
	new Float:pos0[3];
	pos0[0] = pos[0];
	pos0[1] = pos[1];
	pos0[2] = pos[2]+10.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos0, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos0, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos0, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos0, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new Float:pos1[3];
	pos1[0] = pos[0];
	pos1[1] = pos[1];
	pos1[2] = pos[2]+30.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos1, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new Float:pos2[3];
	pos2[0] = pos[0];
	pos2[1] = pos[1];
	pos2[2] = pos[2]+50.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos2, Radius-0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-10.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-20.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos2, Radius-30.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 0.1, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new Float:SkyLocation[3];
	SkyLocation[0] = pos[0];
	SkyLocation[1] = pos[1];
	SkyLocation[2] = pos[2] + 150.0;
	ShowParticle(SkyLocation, HealingBall_Particle_Effect, 1.5);
	
	if(GetEngineTime() - time < yldscx[Client])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (num > 0)//范围允许一次击杀多少个
				break;
			if (IsClientInGame(i))
			{
				if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{	
						AttachParticle(i, PARTICLE_SPAWN, 0.5);  //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
						DealDamage(Client, i, yldssh[Client], 0 , "chain_lightning");
						//LittleFlower(entpos, EXPLODE, Client);
						TE_SetupBeamPoints(SkyLocation, entpos, g_BeamSprite, 0, 0, 0, 1.0, 0.5, 1.0, 1, 3.0, BlueColor, 0);
						TE_SendToAll();
						EmitSoundToAll(ChainLightning_Sound_launch, Client);//EmitSoundToAll = 全体玩家听到播放技能的音效
						num++;
						/*button=GetClientButtons(Client);
						if(button & IN_USE)
						{
							DealDamage(Client, i, 50000, 0 , "chain_lightning");
							ShowParticle(entpos, Particle_gas_explosion_pump, 1.0);
						}*/
					}
				}
			}
		}
		for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    	{	
			if (num > 0)//范围允许一次击杀多少个
				break;
			if (IsCommonInfected(iEntity))
       		{
				new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");
				if (health > 0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, health + 1, -2130706430, "earth_quake");
						AttachParticle(iEntity, PARTICLE_SPAWN, 0.5);  //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
						TE_SetupBeamPoints(SkyLocation, entpos, g_BeamSprite, 0, 0, 0, 1.0, 0.5, 1.0, 1, 3.0, BlueColor, 0);
						TE_SendToAll();
						EmitSoundToAll(ChainLightning_Sound_launch, Client);  //EmitSoundToAll = 全体玩家听到播放技能的音效
						num++;
					}
				}
			}
		}
	} else
	{
		Isylds[Client] = false;
		KillTimer(timer);
		yldsTimer[Client] = INVALID_HANDLE;
		CPrintToChat(Client, "\x04虚空雷圈能量消耗完毕，技能进入冷却状态");
		CreateTimer(ylcd[Client], Timer_YLCD, Client);
	}
}

public Action:Timer_YLCD(Handle:timer, any:Client)
{
	yldscd[Client] = false;
	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, "\x04虚空雷圈冷却时间结束");
	}
}
//不熄光环
public Action:DCGYFunction(Client)
{
	if(!IsPlayerAlive(Client))//活着的幸存者
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}
	if(JD[Client] != 7)//职业
	{
		CPrintToChat(Client, MSG_NEED_JOB7);
		return Plugin_Handled;
	}

	if(DCGYLv[Client] == 0)//虚空雷圈等级
	{
		CPrintToChat(Client, MSG_NEED_SKILL_DCGY);
		return Plugin_Handled;
	}
	if(IsDCGY[Client])//技能是否使用中（冷却结束）
	{
		CPrintToChat(Client, MSG_SKILL_DCGYcd_ENABLED);
		return Plugin_Handled;
	}
	if(DCGYcd[Client])//技能是否使用中（进入冷却状态）
	{
		CPrintToChat(Client, MSG_SKILL_DCGY_ENABLED);
		return Plugin_Handled;
	}
	if(MP[Client] < MP_DCGY)
	{
		CPrintToChat(Client, MSG_SKILL_DCGY_MP, MP[Client]);
		return Plugin_Handled;
	}
	
	IsDCGY[Client] = true;
	DCGYcd[Client] = true;
	MP[Client] -= MP_DCGY;

	new Handle:pack;
	new Float:pos[3];
	DCGYTimer[Client] = CreateDataTimer(dcgyjg[Client], DCGYTimerFunction, pack, TIMER_REPEAT);
	WritePackCell(pack, Client);
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	WritePackFloat(pack, GetEngineTime());
		
	CPrintToChatAll("\x01[技能] \x04%N \x01启动了\x04Lv.%d的不熄光环!", Client, DCGYLv[Client]);
	return Plugin_Handled;
}

public Action:DCGYTimerFunction(Handle:timer, Handle:pack)
{
	decl Float:pos[3], Float:entpos[3], Float:entpos1[3], Float:distance[3];
	
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	new Float:time=ReadPackFloat(pack);
	
	new Float:Radius=float(dcgyfw[Client]);
	new Float:pos0[3];
	GetClientAbsOrigin(Client, pos0);
	pos0[2] += 10.0;
	
	TE_SetupBeamRingPoint(pos0, 10.0, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 0.3, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos0, 10.0, Radius, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 0.3, 10.0, BlueColor, 10, 0);
	TE_SendToAll();
	
	new iMaxEntities = GetMaxEntities();
	new num;
	
	if(GetEngineTime() - time < dcgysj[Client])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (num > 1)//范围允许一次击杀多少个
				break;
			if (IsClientInGame(i))
			{
				if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos1);
					SubtractVectors(entpos1, pos0, distance);
					if(GetVectorLength(distance) <= Radius)
					{	
						DealDamage(Client, i, dcgysh[Client], 0 , "chain_lightning");
						AttachParticle(i, PARTICLE_SPAWN, 0.5);  //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]  
						new String:tg[32];
						GetClientName(i, tg, 32);
						PrintHintText(Client, "%s 受到你的电磁辐射影响", tg);
						num++;
					}
				}
			}
		}
		for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    	{	
			if (num > 1)//范围允许一次击杀多少个
				break;
			if (IsCommonInfected(iEntity))
       		{
				new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");
				if (health > 0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos0, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, health + 1, -2130706430, "earth_quake");
						AttachParticle(iEntity, PARTICLE_SPAWN, 0.5);   //附上粒子效果，PARTICLE_SPAWN 在c源码文件里，代表坦克粒子效果[[开始坦克粒子特效]
						num++;
					}
				}
			}
		}
	} else
	{
		IsDCGY[Client] = false;
		KillTimer(timer);
		DCGYTimer[Client] = INVALID_HANDLE;
		CPrintToChat(Client, "\x04不熄光环效果结束，技能进入冷却状态");
		CreateTimer(DCcd[Client], Timer_DCCD, Client);
	}
}

public Action:Timer_DCCD(Handle:timer, any:Client)
{
	DCGYcd[Client] = false;
	if (IsValidPlayer(Client))
	{
		CPrintToChat(Client, "\x04不熄光环冷却时间结束");
	}
}

/* 虚空之怒 */
public Action:Usexkzn(Client, args)
{
	if(GetClientTeam(Client) == 2) CqdzFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
	return Plugin_Handled;
}

public Action:CqdzFunction(Client)
{
	if(JD[Client] != 8)
	{
		CPrintToChat(Client, MSG_NEED_JOB8);
		return Plugin_Handled;
	}

	if(CqdzLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_25);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_Cqdz) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_Cqdz), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_Cqdz);

	new Float:Radius=float(CqdzRadius[Client]);
	new Float:pos[3];
	new Float:_pos[3];
	GetClientAbsOrigin(Client, _pos);
	pos[0] = _pos[0];
	pos[1] = _pos[1];
	pos[2] = _pos[2]+30.0;
	//(目标, 初始半径(300.0), 最终半径(300.0), 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, Radius-0.3, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, GreenColor, 10, 0);//固定外圈purpleColor
	TE_SendToAll(0.9);
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, YellowColor, 10, 0);//扩散内圈cyanColor
	TE_SendToAll(0.5);
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, RedColor, 10, 0);//扩散内圈cyanColor
	TE_SendToAll(0.6);
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, GreenColor, 10, 0);//扩散内圈cyanColor
	TE_SendToAll(0.3);	

	//地震伤害效果+范围内的震动效果
	new Float:NowLocation[3];
	GetClientAbsOrigin(Client, NowLocation);
	new Float:entpos[3];
	new iMaxEntities = GetMaxEntities();	
	new Float:distance[3];
	new num;
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
    {
		if (num > CqdzMaxKill[Client])
			break;
			
		if (IsCommonInfected(iEntity))
        {
			new health = GetEntProp(iEntity, Prop_Data, "m_iHealth");
			if (health > 0)
			{
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, NowLocation, distance);
				if(GetVectorLength(distance) <= CqdzRadius[Client])
				{
					DealDamage(Client, iEntity, health + 1, -2130706430, "earth_quake");
					num++;
				}
			}
		}
	}

	ShowParticle(NowLocation, PARTICLE_EARTHQUAKEEFFECT, 5.0);
	EmitSoundToAll(EQSOUND, Client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, _pos, NULL_VECTOR, true, 0.0);
	CPrintToChatAll(MSG_SKILL_EQD_ANNOUNCE, Client, CqdzLv[Client]);

	return Plugin_Handled;
}


/* 电弘赤炎*/
public Action:Usedhcy(client, args)
{
	if(GetClientTeam(client) == 2) 
		HMZSFunction(client);
	else 
		CPrintToChat(client, MSG_SKILL_USE_SURVIVORS_ONLY);
}


public Action:HMZSFunction(Client)
{
	if(JD[Client] != 8)
	{
		CPrintToChat(Client, MSG_NEED_JOB8);
		return Plugin_Handled;
	}

	if(HMZSLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_26);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if (HMZSCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	
	if(GetConVarInt(Cost_HMZS) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_HMZS), MP[Client]);
		return Plugin_Handled;
	}
	
	
	MP[Client] -= GetConVarInt(Cost_HMZS);
	HMZSCD[Client] = true;
	new ent=CreateEntityByName("tank_rock");
	//SetEntityModel(ent, FBZN_Model);
	//DispatchKeyValue(ent, "model", "/models/props_unique/airport/atlas_break_ball.mdl"); 
	DispatchSpawn(ent); 
	decl Float:TracePos[3];
	GetTracePosition(Client, TracePos); //得到目标位置
	decl Float:HMZSPos[3];
	GetClientEyePosition(Client, HMZSPos);
	//HMZSPos[2] += 25.0;
	decl Float:angle[3];
	MakeVectorFromPoints(HMZSPos, TracePos, angle);
	NormalizeVector(angle, angle);
	
	decl Float:HMZSTempPos[3];
	HMZSTempPos[0] = angle[0]*50.0;
	HMZSTempPos[1] = angle[1]*50.0;
	HMZSTempPos[2] = angle[2]*50.0;
	AddVectors(HMZSPos, HMZSTempPos, HMZSPos);
	
	decl Float:velocity[3];
	velocity[0] = angle[0]*2000.0;
	velocity[1] = angle[1]*2000.0;
	velocity[2] = angle[2]*2000.0;
	
	DispatchKeyValue(ent, "rendercolor", "255 80 80");
	
	TeleportEntity(ent, HMZSPos, angle, velocity);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Ignite");
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	SetEntityGravity(ent, 0.1);
	
	new Handle:h;
	CreateDataTimer(0.1, UpdateHMZS, h, TIMER_REPEAT);
	WritePackCell(h, Client);
	WritePackCell(h, ent);
	WritePackFloat(h,GetEngineTime());

	CPrintToChatAll(MSG_SKILL_HMD_ANNOUNCE, Client, HMZSLv[Client]);
	CreateTimer(10.0, Timer_HMZSCD, Client);

	//PrintToserver("[United RPG] %s启动了电弘赤炎!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:UpdateHMZS(Handle:timer, Handle:h)
{
	ResetPack(h);
	new Client=ReadPackCell(h);
	new ent=ReadPackCell(h);
	new Float:time=ReadPackFloat(h);
	
	if(IsRockA(ent))
	{
		decl Float:vec[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vec);
		new Float:v=GetVectorLength(vec);
		AttachParticle(ent, HMZS_Particle_Fire03, 0.1);
		//PrintToChatAll("TimeEscapped = %.2f, DistanceToHit = %.2f, v= %.2f", GetEngineTime() - time, DistanceToHit(ent), v);
		if(GetEngineTime() - time > HMZSIceBallLife || DistanceToHit(ent)<200.0 || v<200.0)
		{
			new Float:distance[3];
			new iMaxEntities = GetMaxEntities();
			decl Float:pos[3], Float:entpos[3];
			new Float:Radius=float(HMZSRadius[Client]);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

			RemoveEdict(ent);
			
			LittleFlower(pos, EXPLODE, Client);
			
			/* Emit impact sound */
			EmitAmbientSound(HMZS_Sound_Impact01, pos);
			EmitAmbientSound(HMZS_Sound_Impact02, pos);
			
			ShowParticle(pos, HMZS_Particle_Fire01, 5.0);
			ShowParticle(pos, HMZS_Particle_Fire02, 5.0);
			
			new Float:SkyLocation[3];
			SkyLocation[0] = pos[0];
			SkyLocation[1] = pos[1];
			SkyLocation[2] = pos[2] + 2000.0;				
			//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, RedColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll();		
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();			
			
			
			for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
			{
				if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, HMZSDamage[Client], 8 , "fire_ball");
					}
				}
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == GetClientTeam(Client))
						continue;
						
					if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, HMZSDamage[Client], 262144 , "fire_ball", HMZSDamageInterval[Client], HMZSDuration[Client]);
					}
					else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, HMZSTKDamage[Client], 262144 , "fire_ball", HMZSDamageInterval[Client], HMZSDuration[Client]);
					}
				}
			}
			return Plugin_Stop;	
		}
		return Plugin_Continue;	
	} else return Plugin_Stop;	
}

bool:IsRockA(ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[20];
		GetEdictClassname(ent, classname, 20);

		if(StrEqual(classname, "tank_rock", true))
		{
			return true;
		}
	}
	return false;
}

public Action:Timer_HMZSCD(Handle:timer, any:Client)
{
	HMZSCD[Client] = false;
	KillTimer(timer);
}

/*涟漪光圈 */
public Action:Uselygq(Client, args)
{
	if(GetClientTeam(Client) == 2) SPZSFunction(Client);
	else CPrintToChat(Client, MSG_SKILL_USE_SURVIVORS_ONLY);
}

public Action:SPZSFunction(Client)
{
	if(JD[Client] != 8)
	{
		CPrintToChat(Client, MSG_NEED_JOB8);
		return Plugin_Handled;
	}

	if(SPZSLv[Client] == 0)
	{
		CPrintToChat(Client, MSG_NEED_SKILL_27);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_SPZS) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_SPZS), MP[Client]);
		return Plugin_Handled;
	}
	
	if(Isylds[Client])//涟漪光圈冷却时间结束
	{
		CPrintToChat(Client, MSG_SKILL_YLDS_ENABLED);
		return Plugin_Handled;
	}
	if(yldscd[Client])//涟漪光圈效果结束，技能进入冷却状态
	{
		CPrintToChat(Client, MSG_SKILL_YLDScd_ENABLED);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_SPZS);
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:pos[3], Float:entpos[3];
	new Float:Radius=float(SPZSLaunchRadius[Client]);
	GetClientAbsOrigin(Client, pos);
	
	/* Emit impact sound */
	EmitAmbientSound(SPZS_Sound_launch, pos);
	
	ShowParticle(pos, SPZS_Particle_hit, 0.1);
	
	new Float:SkyLocation[3];
	SkyLocation[0] = pos[0];
	SkyLocation[1] = pos[1];
	SkyLocation[2] = pos[2] + 2000.0;		
	
	//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
	TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 5.0, BlueColor, 10, 0);//固定外圈BuleColor
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 20.0, 20.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 1.0, 1.0, 10, 10.0, BlueColor, 0);
	TE_SendToAll();	
	
	TE_SetupGlowSprite(pos, g_GlowSprite, 0.5, 5.0, 100);
	TE_SendToAll();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(Client, i, SPZSDamage[Client], 0 , "chain_lightning");
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
					TE_SendToAll();
					IsSPZSed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(SPZSmissInterval[Client], SPZSDamage, newh);
					WritePackCell(newh, Client);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(Client, iEntity, SPZSDamage[Client], 0, "chain_lightning");
				TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
				TE_SendToAll();
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(SPZSmissInterval[Client], SPZSDamage, newh);
				WritePackCell(newh, Client);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	
	CPrintToChatAll(MSG_SKILL_SPS_ANNOUNCE, Client, SPZSLv[Client]);

	//PrintToserver("[United RPG] %s启动了涟漪光圈!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:SPZSDamage(Handle:timer, Handle:h)
{
	decl Float:pos[3];
	ResetPack(h);
	new attacker=ReadPackCell(h);
	new victim=ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);
	
	decl color[4];
	color[0] = GetRandomInt(0, 255);
	color[1] = GetRandomInt(0, 255);
	color[2] = GetRandomInt(0, 255);
	color[3] = 128;
	
	new Float:distance[3];
	new iMaxEntities = GetMaxEntities();
	decl Float:entpos[3];
	new Float:Radius=float(SPZSRadius[attacker]);
	if(victim >= MaxClients + 1)
	{
		if ((IsCommonInfected(victim) || IsWitch(victim)) && GetEntProp(victim, Prop_Data, "m_iHealth")>0)	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
		if((IsCommonInfected(victim) || IsWitch(victim)))	SetEntProp(victim, Prop_Send, "m_bFlashing", 0);
	} else
	{
		if(IsClientInGame(victim) && IsPlayerAlive(victim) && !IsPlayerGhost(victim))	GetClientAbsOrigin(victim, pos);
		IsSPZSed[victim] = false;
	}
	
	/* Emit impact Sound */
	EmitAmbientSound(SPZS_Sound_launch, pos);
	
	TE_SetupGlowSprite(pos, g_GlowSprite, 1.0, 3.0, 100);
	TE_SendToAll();
	
	for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
	{
		if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0 && iEntity != victim && GetEntProp(iEntity, Prop_Send, "m_bFlashing") != 1)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
			SubtractVectors(entpos, pos, distance);
			if(GetVectorLength(distance) <= Radius)
			{
				DealDamage(attacker, iEntity, RoundToNearest(SPZSDamage[attacker]/(1.0 + StrEffect[attacker] + EnergyEnhanceEffect_Attack[attacker])), 0 , "chain_lightning");
				TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
				TE_SendToAll();
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1);
				
				new Handle:newh;					
				CreateDataTimer(SPZSmissInterval[attacker], SPZSDamage, newh);
				WritePackCell(newh, attacker);
				WritePackCell(newh, iEntity);
				WritePackFloat(newh, entpos[0]);
				WritePackFloat(newh, entpos[1]);
				WritePackFloat(newh, entpos[2]);
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i) && i != victim && !IsSPZSed[i])
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				SubtractVectors(entpos, pos, distance);
				if(GetVectorLength(distance) <= Radius)
				{
					DealDamage(attacker, i, SPZSDamage[attacker], 0 , "chain_lightning");
					TE_SetupBeamPoints(pos, entpos, g_BeamSprite, 0, 0, 0, 0.5, 1.0, 1.0, 1, 5.0, color, 0);
					TE_SendToAll();
					IsSPZSed[i] = true;
					
					new Handle:newh;					
					CreateDataTimer(SPZSmissInterval[attacker], SPZSDamage, newh);
					WritePackCell(newh, attacker);
					WritePackCell(newh, i);
					WritePackFloat(newh, entpos[0]);
					WritePackFloat(newh, entpos[1]);
					WritePackFloat(newh, entpos[2]);
				}
			}
		}
	}
	//return Plugin_Handled;
}


/* 幽冥暗量 */
//振幅寒冰
public Action:XBFBFunction(Client)
{
	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}
	
	if (FreefbCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}

	if(GetConVarInt(Cost_XBFB) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_XBFB), MP[Client]);
		return Plugin_Handled;
	}

	MP[Client] -= GetConVarInt(Cost_XBFB);
	FreefbCD[Client] = true;
	new ent=CreateEntityByName("tank_rock");
	DispatchSpawn(ent); 
	decl Float:TracePos[3];
	GetTracePosition(Client, TracePos); //得到目标位置
	decl Float:XBFBPos[3];
	GetClientEyePosition(Client, XBFBPos);
	decl Float:angle[3];
	MakeVectorFromPoints(XBFBPos, TracePos, angle);
	NormalizeVector(angle, angle);
	
	decl Float:XBFBTempPos[3];
	XBFBTempPos[0] = angle[0]*50.0;
	XBFBTempPos[1] = angle[1]*50.0;
	XBFBTempPos[2] = angle[2]*50.0;
	AddVectors(XBFBPos, XBFBTempPos, XBFBPos);
	
	decl Float:velocity[3];
	velocity[0] = angle[0]*2000.0;
	velocity[1] = angle[1]*2000.0;
	velocity[2] = angle[2]*2000.0;
	
	DispatchKeyValue(ent, "rendercolor", "80 80 255");
	
	TeleportEntity(ent, XBFBPos, angle, velocity);
	ActivateEntity(ent);
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	SetEntityGravity(ent, 0.1);
	
	new Handle:h;	
	CreateDataTimer(0.1, UpdateXBFB, h, TIMER_REPEAT);
	WritePackCell(h, Client);
	WritePackCell(h, ent);
	WritePackFloat(h,GetEngineTime());

	CPrintToChatAll(MSG_SKILL_IBD_ANNOUNCE, Client);
	CreateTimer(5.0, Timer_FreefbCD, Client);
	//PrintToserver("[United RPG] %s启动了冰球术!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:UpdateXBFB(Handle:timer, Handle:h)
{
	ResetPack(h);
	new Client=ReadPackCell(h);
	new ent=ReadPackCell(h);
	new Float:time=ReadPackFloat(h);
	
	if(IsRock(ent))
	{
		decl Float:vec[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vec);
		new Float:v=GetVectorLength(vec);
		if(GetEngineTime() - time > FBZNIceBallLife || DistanceToHit(ent) < 200.0 || v < 200.0)
		{
			new Float:distance[3];
			new iMaxEntities = GetMaxEntities();
			decl Float:pos[3], Float:entpos[3];
			new Float:Radius=float(XBFBRadius[Client]);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

			RemoveEdict(ent);
			
			/* Emit impact sound */
			EmitAmbientSound(XBFB_Sound_Impact01, pos);
			EmitAmbientSound(XBFB_Sound_Impact02, pos);
			
			new Float:SkyLocation[3];
			SkyLocation[0] = pos[0];
			SkyLocation[1] = pos[1];
			SkyLocation[2] = pos[2] + 2000.0;					
			//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴, 渲染速率, 持续时间, 播放宽度,播放振幅, 顏色(Color[4]), (播放速度)10, (标识)0)
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, BlueColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll();
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, YellowColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll(1.1);			
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 50.0, 50.0, 10, 10.0, BlueColor, 0);
			TE_SendToAll();
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 50.0, 50.0, 10, 10.0, YellowColor, 0);
			TE_SendToAll(1.1);			
			
			TE_SetupGlowSprite(pos, g_GlowSprite, XBFBDuration[Client], 5.0, 100);
			TE_SendToAll();

			ShowParticle(pos, XBFB_Particle_Ice01, 5.0);		
			
			for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
			{
				if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, RoundToNearest(XBFBDamage[Client]/(1.0 + StrEffect[Client] + EnergyEnhanceEffect_Attack[Client])), 16 , "ice_ball");
						//FreezePlayer(iEntity, entpos, IceBallDuration[Client]);
						EmitAmbientSound(XBFB_Sound_Freeze, entpos, iEntity, SNDLEVEL_RAIDSIREN);
						TE_SetupGlowSprite(entpos, g_GlowSprite, XBFBDuration[Client], 3.0, 130);
						TE_SendToAll();
					}
				}
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == GetClientTeam(Client))
						continue;			
						
					if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
						{
							DealDamage(Client, i, XBFBDamage[Client], 16 , "ice_ball");
							FreezePlayer(i, entpos, XBFBDuration[Client]);
						}
					} 
					else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
						{
							DealDamage(Client, i, XBFBTKDamage[Client], 16 , "ice_ball");
							FreezeDPlayer(i, entpos, XBFBDuration[Client]);
						}
					}
				}
			}
			PointPush(Client, pos, 1000, XBFBRadius[Client], 0.5);
			return Plugin_Stop;	
		}
		return Plugin_Continue;
	} else return Plugin_Stop;
}
public FreezeDPlayer(entity, Float:pos[3], Float:time)
{
	if(IsValidPlayer(entity))
	{
		SetEntityMoveType(entity, MOVETYPE_NONE);
		SetEntityRenderColor(entity, 0, 128, 255, 135);
		ScreenFade(entity, 0, 128, 255, 192, 2000, 1);
		EmitAmbientSound(XBFB_Sound_Freeze, pos, entity, SNDLEVEL_RAIDSIREN);
		TE_SetupGlowSprite(pos, g_GlowSprite, time, 3.0, 130);
		TE_SendToAll();
		IsXBFB[entity] = true;
	}
	CreateTimer(time, DefrostPlayerD, entity);
}
public Action:DefrostPlayerD(Handle:timer, any:entity)
{
	if(IsValidPlayer(entity))
	{
		decl Float:entPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entPos);
		EmitAmbientSound(XBFB_Sound_Defrost, entPos, entity, SNDLEVEL_RAIDSIREN);
		SetEntityMoveType(entity, MOVETYPE_WALK);
		ScreenFade(entity, 0, 0, 0, 0, 0, 1);
		IsXBFB[entity] = false;
		SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
}

/* 振幅爆炎*/
public Action:FBZNFunction(Client)
{
	if(!IsPlayerAlive(Client))
	{
		CPrintToChat(Client, MSG_PLAYER_DIE);
		return Plugin_Handled;
	}

	if (FBZNCD[Client])
	{
		CPrintToChat(Client, MSG_SKILL_CHARGING);
		return Plugin_Handled;
	}
	
	if(GetConVarInt(Cost_FBZN) > MP[Client])
	{
		PrintHintText(Client, MSG_SKILL_LACK_MP, GetConVarInt(Cost_FBZN), MP[Client]);
		return Plugin_Handled;
	}
	
	
	MP[Client] -= GetConVarInt(Cost_FBZN);
	FBZNCD[Client] = true;
	new ent=CreateEntityByName("tank_rock");
	//SetEntityModel(ent, FBZN_Model);
	//DispatchKeyValue(ent, "model", "/models/props_unique/airport/atlas_break_ball.mdl"); 
	DispatchSpawn(ent); 
	decl Float:TracePos[3];
	GetTracePosition(Client, TracePos); //得到目标位置
	decl Float:FBZNPos[3];
	GetClientEyePosition(Client, FBZNPos);
	//FBZNPos[2] += 25.0;
	decl Float:angle[3];
	MakeVectorFromPoints(FBZNPos, TracePos, angle);
	NormalizeVector(angle, angle);
	
	decl Float:FBZNTempPos[3];
	FBZNTempPos[0] = angle[0]*50.0;
	FBZNTempPos[1] = angle[1]*50.0;
	FBZNTempPos[2] = angle[2]*50.0;
	AddVectors(FBZNPos, FBZNTempPos, FBZNPos);
	
	decl Float:velocity[3];
	velocity[0] = angle[0]*2000.0;
	velocity[1] = angle[1]*2000.0;
	velocity[2] = angle[2]*2000.0;
	
	DispatchKeyValue(ent, "rendercolor", "255 80 80");
	
	TeleportEntity(ent, FBZNPos, angle, velocity);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Ignite");
	
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 0);
	SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
	SetEntityGravity(ent, 0.1);
	
	new Handle:h;
	CreateDataTimer(0.1, UpdateFBZN, h, TIMER_REPEAT);
	WritePackCell(h, Client);
	WritePackCell(h, ent);
	WritePackFloat(h,GetEngineTime());

	CPrintToChatAll(MSG_SKILL_FBD_ANNOUNCE, Client);
	CreateTimer(5.0, Timer_FBZNCD, Client);

	//PrintToserver("[United RPG] %s启动了振幅爆炎!", NameInfo(Client, simple));

	return Plugin_Handled;
}
public Action:UpdateFBZN(Handle:timer, Handle:h)
{
	ResetPack(h);
	new Client=ReadPackCell(h);
	new ent=ReadPackCell(h);
	new Float:time=ReadPackFloat(h);
	
	if(IsRockD(ent))
	{
		decl Float:vec[3];
		GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vec);
		new Float:v=GetVectorLength(vec);
		AttachParticle(ent, FBZN_Particle_Fire03, 0.1);
		//PrintToChatAll("TimeEscapped = %.2f, DistanceToHit = %.2f, v= %.2f", GetEngineTime() - time, DistanceToHit(ent), v);
		if(GetEngineTime() - time > FBZNIceBallLife || DistanceToHit(ent)<200.0 || v<200.0)
		{
			new Float:distance[3];
			new iMaxEntities = GetMaxEntities();
			decl Float:pos[3], Float:entpos[3];
			new Float:Radius=float(FBZNRadius[Client]);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

			RemoveEdict(ent);
			
			LittleFlower(pos, EXPLODE, Client);
			
			/* Emit impact sound */
			EmitAmbientSound(FBZN_Sound_Impact01, pos);
			EmitAmbientSound(FBZN_Sound_Impact02, pos);
			
			ShowParticle(pos, FBZN_Particle_Fire01, 5.0);
			ShowParticle(pos, FBZN_Particle_Fire02, 5.0);
			
			new Float:SkyLocation[3];
			SkyLocation[0] = pos[0];
			SkyLocation[1] = pos[1];
			SkyLocation[2] = pos[2] + 2000.0;				
			//(目标, 初始半径, 最终半径, 效果1, 效果2, 渲染贴(0), 渲染速率(15), 持续时间(10.0), 播放宽度(20.0),播放振幅(0.0), 顏色(Color[4]), (播放速度)10, (标识)0)
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, RedColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll();	
			TE_SetupBeamRingPoint(pos, 0.1, Radius, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, GreenColor, 10, 0);//固定外圈BuleColor
			TE_SendToAll(1.1);		
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 50.0, 50.0, 10, 10.0, RedColor, 0);
			TE_SendToAll();	
			TE_SetupBeamPoints(SkyLocation, pos, g_BeamSprite, 0, 0, 0, 2.7, 50.0, 50.0, 10, 10.0, GreenColor, 0);
			TE_SendToAll(1.1);				
			
			for (new iEntity = MaxClients + 1; iEntity <= iMaxEntities; iEntity++)
			{
				if ((IsCommonInfected(iEntity) || IsWitch(iEntity)) && GetEntProp(iEntity, Prop_Data, "m_iHealth")>0)
				{
					GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", entpos);
					SubtractVectors(entpos, pos, distance);
					if(GetVectorLength(distance) <= Radius)
					{
						DealDamage(Client, iEntity, FBZNDamage[Client], 8 , "fire_ball");
					}
				}
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if (GetClientTeam(i) == GetClientTeam(Client))
						continue;
						
					if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsPlayerGhost(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, FBZNDamage[Client], 262144 , "fire_ball", FBZNDamageInterval[Client], FBZNDuration[Client]);
					}
					else if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						SubtractVectors(entpos, pos, distance);
						if(GetVectorLength(distance) <= Radius)
							DealDamageRepeat(Client, i, FBZNTKDamage[Client], 262144 , "fire_ball", FBZNDamageInterval[Client], FBZNDuration[Client]);
					}
				}
			}
			return Plugin_Stop;	
		}
		return Plugin_Continue;	
	} else return Plugin_Stop;	
}

bool:IsRockD(ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[20];
		GetEdictClassname(ent, classname, 20);

		if(StrEqual(classname, "tank_rock", true))
		{
			return true;
		}
	}
	return false;
}

public Action:Timer_FBZNCD(Handle:timer, any:Client)
{
	FBZNCD[Client] = false;
	KillTimer(timer);
}
public Action:Timer_FreefbCD(Handle:timer, any:Client)
{
	FreefbCD[Client] = false;
	KillTimer(timer);
}

/* 给予新人保护BUFF */
public GiveAllRookieBuff()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false, false) && PLAYER_LV[i] <= RookieBuff_MinLv)
		{
			if (!HasBuffPlayer[i])
			{
				HasBuffPlayer[i] = true;
				new buffhealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
				SetEntProp(i, Prop_Data, "m_iMaxHealth", buffhealth >= 100 ? buffhealth + RookieBuff_Health : 100 + RookieBuff_Health);
				new Float:speedbuff = GetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue");
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", speedbuff >= 1.0 ? speedbuff + RookieBuff_Speed : 1.0 + RookieBuff_Speed);
				CheatCommand(i, "give", "health")
				PrintHintText(i, "你已获得了[新人Buff]加成,生命值增加 %d, 移动速度增加 %.1f.", RookieBuff_Health, RookieBuff_Speed);
			}
		}
	}
}

/* 还原新人保护BUFF */
public ResetAllRookieBuff()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false, false))
		{
			RebuildStatus(i, false);
			HasBuffPlayer[i] = false;
		}
	}	
}

/* 保存服务器时间日志 */
stock SaveServerTimeLog(bool:changemap = false)
{
	decl String:t_date[12], String:t_time[12], String:t_text[32], String:t_map[32];
	FormatTime(t_date, sizeof(t_date), "%Y-%m-%d");
	FormatTime(t_time, sizeof(t_time), "%X");
	Format(t_text, sizeof(t_text), "|%s|%s|", t_date, t_time);
	GetCurrentMap(t_map, sizeof(t_map))
	KvJumpToKey(ServerTimeLog, t_text, true);
	if (!changemap)
		KvSetString(ServerTimeLog, "map", t_map);
	else
		KvSetString(ServerTimeLog, "map", "playerchange");
	KvRewind(ServerTimeLog);
	KeyValuesToFile(ServerTimeLog, ServerTimePath);
}

/* 快捷_每日签到 */
public Action:Command_QianDao(Client, args)
{
	PlayerSignToday(Client);
	return Plugin_Handled;
}
/*
public Action:Command_Show1(client, args)
{
	if(GetClientTeam(client) == 2) 
		LZDFunction(client);
	else 
		CPrintToChat(client, MSG_SKILL_USE_SURVIVORS_ONLY);
}
*/
public Action:Command_Show2(client, args)
{
	if(GetClientTeam(client) == 2) 
		DCGYFunction(client);
	else 
		CPrintToChat(client, MSG_SKILL_USE_SURVIVORS_ONLY);
}
public Action:Command_Show3(client, args)
{
	if(GetClientTeam(client) == 2) 
		YLDSFunction(client);
	else 
		CPrintToChat(client, MSG_SKILL_USE_SURVIVORS_ONLY);
}
/* 每日签到 */
public PlayerSignToday(Client)
{
	if (IsValidPlayer(Client) && IsPasswordConfirm[Client])
	{
		new today = GetToday();
		if (everyday1[Client] >= 15)
		{
			everyday1[Client] -= 15;
			ClientSaveToFileSave(Client);
			//CPrintToChatAll("{olive}[每日签到]{green}玩家 {lightgreen}%N {green}已经在今日签到了,获得奖励{lightgreen}%dEXP,%d${green}和{lightgreen}随机古代卷轴{green}一个+复活币一枚!!!", Client, SIGNAWARD_EXP[Client], SIGNAWARD_CASH[Client]);
		}
		
		if (today > 0 && EveryDaySign[Client] > -1 && EveryDaySign[Client] != today && everyday1[Client] <= 15)
		{
			EveryDaySign[Client] = today;
			EXP[Client] += SIGNAWARD_EXP[Client];
			Cash[Client] += SIGNAWARD_CASH[Client];
			PlayerSignXHItem(Client);
			everyday1[Client] += 1;
			PlayerItem[Client][ITEM_XH][9] += 1;  //复活币
			ClientSaveToFileSave(Client);
			CPrintToChatAll("{olive}[每日签到]{green}玩家 {lightgreen}%N {green}已经在今日签到了,获得奖励{lightgreen}%dEXP,%d${green}和{lightgreen}随机古代卷轴{green}一个+复活币一枚!!!", Client, SIGNAWARD_EXP[Client], SIGNAWARD_CASH[Client]);
		}
		else
			PrintHintText(Client, "[温馨提示]你今日已经签到过了或者您的积累签到次数没有使用,请明天再来签到!");
	}
	else
		PrintHintText(Client, "[温馨提示]请登录游戏后在使用签到!");
}

/* 获得随机卷轴 */
public PlayerSignXHItem(Client)
{
	new itemid = GetRandomInt(0, ITEM_XH_MAX - 1);
	ServerCommand("sm_setitem_957 \"%N\" \"0\" \"%d\" \"1\"", Client, itemid);
	return itemid;
}
/* 获得随机装备 */
public PlayerSignZBItem(Client)
{
	new itemid = GetRandomInt(0, ITEM_ZB_MAX - 1);
	ServerCommand("sm_setitem_957 \"%N\" \"1\" \"%d\" \"3\"", Client, itemid);
	return itemid;
}
/* 新人教程任务 */
public Action:MenuFunc_MZC(Client)
{
	new Handle:menu = CreatePanel();
	//decl String:line[256];;
	new String:sText[1024]
	Format(sText, sizeof(sText), "亲爱的玩家，你还没有注册，注册后才能进行新人任务。请输入/pw laona进行注册！");
	DrawPanelText(menu, sText);
	//Format(sText, sizeof(sText), "[不会注册加本服QQ群:141758560 资讯群里玩家或管理员]");
	//DrawPanelText(menu, sText);
	DrawPanelItem(menu, "新人任务[50级以下]");
	
	//DrawPanelItem(menu, "返回");
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	//SendPanelToClient(menu, Client, MenuHandler_AMZC, MENU_TIME_FOREVER);
	SendPanelToClient(menu, Client, MenuHandler_MZC, MENU_TIME_FOREVER);
	//CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_MZC(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: 
			{
			    if(IsPasswordConfirm[Client] && XR[Client] <= 4 && NewLifeCount[Client] <= 50)//等级小于50级
		        {
			        MenuFunc_MZCA(Client); //VIP功能介绍
				StatusPoint[Client] += 110
				XR[Client] += 1
		            } else 
			    {
					if(IsPasswordConfirm[Client] && NewLifeCount[Client] >= 50)
					{
					    Menu_GameAnnouncement(Client);
					} else MenuFunc_MZC(Client);
					
					CPrintToChat(Client, "\x05【提示】你不是新人或没注册或已完成新人任务，无法进行新人任务！");	
			    }
			}
		}
	}
} /* 新人任务 */
public Action:MenuFunc_MZCA(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	Format(line, sizeof(line), "[新人任务]");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "恭喜你获得了100属性点，请分配属性点来转职！属性点剩余: %d \n=请分配：力量15，速度15，生命15，防御15，智力50=", StatusPoint[Client]);
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "力量 (%d/%d 指令: !str 数量)", Str[Client], Limit_Str);
	DrawPanelItem(menu, line);
	//Format(line, sizeof(line), "提高伤害! 增加%.2f%%伤害", StrEffect[Client] * 100.0);
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "敏捷 (%d/%d 指令: !agi 数量)", Agi[Client], Limit_Agi);
	DrawPanelItem(menu, line);
	//Format(line, sizeof(line), "提高移动速度! 增加%.2f%%移动速度", AgiEffect[Client] * 100.0);
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "生命 (%d/%d 指令: !hea 数量)", Health[Client], Limit_Health);
	DrawPanelItem(menu, line);
	//Format(line, sizeof(line), "提高生命最大值! 增加%.2f%%生命最大值", HealthEffect[Client] * 100.0);
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "耐力 (%d/%d 指令: !end 数量)", Endurance[Client], Limit_Endurance);
	DrawPanelItem(menu, line);
	//Format(line, sizeof(line), "减少伤害!  减少%.2f%%伤害", EnduranceEffect[Client] * 100.0);
	//DrawPanelText(menu, line);
	Format(line, sizeof(line), "智力 (%d/%d 指令: !int 数量)", Intelligence[Client], Limit_Intelligence);
	DrawPanelItem(menu, line);
	//Format(line, sizeof(line), "提高MP上限, 恢复速度及减少扣经! 每秒MP恢复: %d, MP上限: %d", IntelligenceEffect_IMP[Client], MaxMP[Client]);
	//DrawPanelText(menu, line);
	DrawPanelItem(menu, "下一步");
	//DrawPanelItem(menu, "返回");
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_MZCA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_MZCA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (param >= 1 && param <= 6)
		{
			switch(param)
			{
				case 1:	AddStrength(Client, 0);
				case 2:	AddAgile(Client, 0);
				case 3:	AddHealth(Client, 0);
				case 4:	AddEndurance(Client, 0);
				case 5:	AddIntelligence(Client, 0);
			}
			MenuFunc_MZCA(Client);
		}
		if (param == 6)
			if(Str[Client] == 15 && Agi[Client] == 15 && Health[Client] == 15 && Endurance[Client] == 15 && Intelligence[Client] == 50)
            {
                MenuFunc_XRZZ(Client); //转职
		XR[Client] += 2
                        } else 
			{
				StatusPoint[Client] = NewLifeGiveSKP[Client];
				MenuFunc_MZCA(Client);  //新人任务
				StatusPoint[Client] += 110;
				Str[Client] = 0;
		                Agi[Client] = 0;
		                Health[Client] = 0;
		                Endurance[Client] = 0;
		                Intelligence[Client] = 0;
		                CPrintToChat(Client, "\x05【提示】你分配的属性点错误，请按照指定分配的属性点分配！");	
			}
	}
}

//转职
public MenuFunc_XRZZ(Client)
{		
	new Handle:menu = CreateMenu(MenuHandler_XRZZ);
	//decl String:line[128];
	AddMenuItem(menu, "iteam1", "转职“精灵”");	

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public MenuHandler_XRZZ(Handle:menu, MenuAction:action, Client, IteamNum)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;

	if (action == MenuAction_Select) {
		switch (IteamNum)
		{
			case 0: 
			{
			    ChooseJobA(Client, 1);//精灵
			    XR[Client] += 3
			    MenuFunc_XRZZA(Client); //学习技能
			    PlayerXHItemSize[Client] += 11;//扩充消耗栏
			    PlayerZBItemSize[Client] += 3;//扩充装备栏
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (IteamNum == MenuCancel_ExitBack)
			MenuFunc_XRZZ(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

stock ChooseJobA(Client, Jobid)
{
	if (KTCount[Client] > KTLimit)
	{
		CPrintToChat(Client, MSG_ZZ_FAIL_KT);
	}
	else if (JobChooseBool[Client])
	{
		CPrintToChat(Client, MSG_ZZ_FAIL_JCB_TURE);
	}
	else
	{
		if (Jobid==1)//精灵
		{
			if (Str[Client] >= JOB1_Str && Agi[Client] >= JOB1_Agi && Health[Client] >= JOB1_Health && Endurance[Client] >= JOB1_Endurance && Intelligence[Client] >= JOB1_Intelligence)
			{
				JD[Client] = 1;
				Str[Client] += 10;
				Endurance[Client] += 10;
				Intelligence[Client] += 10;
				SkillPoint[Client] += 100;
				JobChooseBool[Client] = true;
				CPrintToChatAll(MSG_ZZ_SUCCESS_JOB1_ANNOUNCE, Client);
				CPrintToChat(Client, MSG_ZZ_SUCCESS_JOB1_REWARD);
			}
			else
			{
				CPrintToChat(Client, MSG_ZZ_FAIL_NEED_STATUS);
				CPrintToChat(Client, MSG_ZZ_FAIL_JOB_NEED, JOB1_Str, JOB1_Agi, JOB1_Health, JOB1_Endurance, JOB1_Intelligence);
				CPrintToChat(Client, MSG_ZZ_FAIL_SHOW_STATUS, Str[Client], Agi[Client], Health[Client], Endurance[Client], Intelligence[Client]);
			}
		}
		//绑定新职业按键
		BindKeyFunction(Client);
	}	
}

public MenuFunc_XRZZA(Client)
{		
	new Handle:menu = CreateMenu(MenuHandler_XRZZA);
	decl String:line[128];
	Format(line, sizeof(line), "学习技能(技能点剩余:%d)", SkillPoint[Client]);
	AddMenuItem(menu, "iteam1", line);	

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public MenuHandler_XRZZA(Handle:menu, MenuAction:action, Client, IteamNum)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return;

	if (action == MenuAction_Select) {
		switch (IteamNum)
		{
			case 0:  MenuFunc_SurvivorSkillA(Client);	//学习技能
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (IteamNum == MenuCancel_ExitBack)
			MenuFunc_XRZZA(Client);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

/* 学习技能 */
public Action:MenuFunc_SurvivorSkillA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "幸存者技能 - 技能点剩余: %d", SkillPoint[Client]);
	SetPanelTitle(menu, line);

	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "[通用]治疗术 (等级: %d/%d 发动指令: !hl)", HealingLv[Client], LvLimit_Healing);
	else
		Format(line, sizeof(line), "[通用]高级治疗术 (等级: %d/%d 发动指令: !hl)", HealingLv[Client], LvLimit_Healing);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]地震术 (等级: %d/%d 发动指令: !dizhen)", EarthQuakeLv[Client], LvLimit_EarthQuake);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]召唤重机枪(Lv.%d / MP:5000)", HeavyGunLv[Client], LvLimit_HeavyGun);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[通用]强化苏醒术 (等级: %d/%d 被动技能)", EndranceQualityLv[Client], LvLimit_EndranceQuality);
	DrawPanelItem(menu, line);
	if(JD[Client] == 1)
	{
		Format(line, sizeof(line), "[精灵]子弹制造术 (等级: %d/%d 发动指令: !am)", AmmoMakingLv[Client], LvLimit_AmmoMaking);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[精灵]射速加强术 (等级: %d/%d 发动指令: !fs)", FireSpeedLv[Client], LvLimit_FireSpeed);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[精灵]卫星炮术 (等级: %d/%d 发动指令: !sc)", SatelliteCannonLv[Client], LvLimit_SatelliteCannon);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[究极]核弹头"), DrawPanelItem(menu, line);
	}
	DrawPanelItem(menu, "下一步[完成新人任务]");
	SendPanelToClient(menu, Client, MenuHandler_SurvivorSkillA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_SurvivorSkillA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1: MenuFunc_AddHealingA(Client);
			case 2: MenuFunc_AddEarthQuakeA(Client);
			case 3: MenuFunc_AddHeavyGunA(Client);  //助手
			case 4: MenuFunc_AddEndranceQualityA(Client);  //苏醒术
			case 5:
			{
				if(JD[Client] == 1)	MenuFunc_AddAmmoMakingA(Client);
			}
			case 6:
			{
				if(JD[Client] == 1)	MenuFunc_AddFireSpeedA(Client);
			}
			case 7:
			{
				if(JD[Client] == 1)	MenuFunc_AddSatelliteCannonA(Client);
			}
			case 8:
			{
				if(JD[Client] == 1)	MenuFunc_AddAmmoMakingmissA(Client);
			}
			case 9:
			{
				MenuFunc_LXQDJLA(Client);
			}
		}
	}
}	


//治疗术
public Action:MenuFunc_AddHealingA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	if(VIP[Client] <= 0)
		Format(line, sizeof(line), "学习治疗术 目前等级: %d/%d 发动指令: !hl - 技能点剩余: %d", HealingLv[Client], LvLimit_Healing, SkillPoint[Client]);
	else
		Format(line, sizeof(line), "学习高级治疗术 目前等级: %d/%d 发动指令: !hl - 技能点剩余: %d", HealingLv[Client], LvLimit_Healing, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	if(VIP[Client] <= 0)
		Format(line, sizeof(line), "技能说明: 每秒恢复%dHP", HealingEffect[Client]);
	else
		Format(line, sizeof(line), "技能说明: 每秒恢复8HP");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "持续时间: %d秒", HealingDuration[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHealingA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHealingA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(HealingLv[Client] < LvLimit_Healing)
			{
				HealingLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_HL, HealingLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_HL_LEVEL_MAX);
			MenuFunc_AddHealingA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//召唤重机枪
public Action:MenuFunc_AddHeavyGunA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "召唤自动机枪 目前等级: %d/%d - 技能点剩余: %d", HeavyGunLv[Client], LvLimit_HeavyGun, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 召唤出自动机枪帮你扫射疯狂坦克!.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当前攻击伤害: %d", HeavyGunMaxDmg[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddHeavyGunA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddHeavyGunA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(HeavyGunLv[Client] < LvLimit_HeavyGun)
			{
				HeavyGunLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_HG, HeavyGunLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_HG_LEVEL_MAX);
			MenuFunc_AddHeavyGunA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}


//地震术
public Action:MenuFunc_AddEarthQuakeA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习地震术 目前等级: %d/%d 发动指令: !dizhen - 技能点剩余: %d", EarthQuakeLv[Client], LvLimit_EarthQuake, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 范围内所有普通僵尸直接秒杀,最多秒杀数量根据技能等级决定.");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "最大数量: %d", EarthQuakeMaxKill[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "当前范围: %d", EarthQuakeRadius[Client]);
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddEarthQuakeA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddEarthQuakeA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(EarthQuakeLv[Client] < LvLimit_EarthQuake)
			{
				EarthQuakeLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_EQ, EarthQuakeLv[Client] , EarthQuakeRadius[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_EQ_LEVEL_MAX);
			MenuFunc_AddEarthQuakeA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//强化苏醒术
public Action:MenuFunc_AddEndranceQualityA(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习强化苏醒术 目前等级: %d/%d 被动技能 - 技能点剩余: %d", EndranceQualityLv[Client], LvLimit_EndranceQuality, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 倒地后再起身的血量");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "生命比率: %.2f%%", EndranceQualityEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddEndranceQualityA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddEndranceQualityA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(EndranceQualityLv[Client] < LvLimit_EndranceQuality)
			{
				EndranceQualityLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_GENGXIN, EndranceQualityLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_GENGXIN_LEVEL_MAX);
			MenuFunc_AddEndranceQualityA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//子弹制造术
public Action:MenuFunc_AddAmmoMakingA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习子弹制造术 目前等级: %d/%d 发动指令: !am - 技能点剩余: %d", AmmoMakingLv[Client], LvLimit_AmmoMaking, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 制造一定数量子弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "制造数量: %d", AmmoMakingEffect[Client]);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAmmoMakingA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAmmoMakingA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(AmmoMakingLv[Client] < LvLimit_AmmoMaking)
			{
				AmmoMakingLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_AM, AmmoMakingLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_AM_LEVEL_MAX);
			MenuFunc_AddAmmoMakingA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//核弹头
public Action:MenuFunc_AddAmmoMakingmissA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习核弹头 (转生技能只限学习1级,要消耗50技能点)", AmmoMakingmissLv[Client], LvLimit_AmmoMakingmiss, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 在准心处创造一个核弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "核弹威力: 未知", AmmoMakingmissEffect[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "爆炸范围: 未知");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddAmmoMakingmissA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddAmmoMakingmissA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] < 50)	CPrintToChat(Client, MSG_LACK_BUZU);
			else if(AmmoMakingmissLv[Client] < LvLimit_AmmoMakingmiss)
			{
				AmmoMakingmissLv[Client]++, SkillPoint[Client] -= 50;
				CPrintToChat(Client, MSG_ADD_SKILL_MOGU, AmmoMakingmissLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_MOGU_LEVEL_MAX);
			MenuFunc_AddAmmoMakingmissA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//射速加强术
public Action:MenuFunc_AddFireSpeedA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习射速加强术 目前等级: %d/%d 发动指令: !fs - 技能点剩余: %d", FireSpeedLv[Client], LvLimit_FireSpeed, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 增加子弹的射击速度");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "速度比率: %.2f%%", FireSpeedEffect[Client]*100);
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddFireSpeedA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddFireSpeedA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(FireSpeedLv[Client] < LvLimit_FireSpeed)
			{
				FireSpeedLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_FS, FireSpeedLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_FS_LEVEL_MAX);
			MenuFunc_AddFireSpeedA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//卫星炮
public Action:MenuFunc_AddSatelliteCannonA(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "学习卫星炮 目前等级: %d/%d 发动指令: !sc - 技能点剩余: %d", SatelliteCannonLv[Client], LvLimit_SatelliteCannon, SkillPoint[Client]);
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "技能说明: 向準心位置发射卫星炮");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击伤害: %d", SatelliteCannonDamage[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "攻击范围: %d", SatelliteCannonRadius[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "冷却时间: %.2f秒", SatelliteCannonCDTime[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "加成属性: 力量");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	//DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_AddSatelliteCannonA, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_AddSatelliteCannonA(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if(param == 1)
		{
			if(SkillPoint[Client] <= 0)	CPrintToChat(Client, MSG_LACK_SKILLS);
			else if(SatelliteCannonLv[Client] < LvLimit_SatelliteCannon)
			{
				SatelliteCannonLv[Client]++, SkillPoint[Client] -= 1;
				CPrintToChat(Client, MSG_ADD_SKILL_SC, SatelliteCannonLv[Client]);
			}
			else CPrintToChat(Client, MSG_ADD_SKILL_SC_LEVEL_MAX);
			MenuFunc_AddSatelliteCannonA(Client);
		} else MenuFunc_SurvivorSkillA(Client);
	}
}

//新人任务
public Action:MenuFunc_LXQDJLA(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "恭喜你完成新人任务,要升级快的话，就得做任务了，或者是跟师傅一起玩游戏");    
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "前往签到");
    DrawPanelItem(menu, line);
    Format(line, sizeof(line), "领取新人任务礼包[先领取再签到]");
    DrawPanelItem(menu, line);	
    DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_LXQDJLA, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_LXQDJLA(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_Qiandao(Client);
			case 2: LXQDJLAB(Client);
		}
	}
}

public LXQDJLAB(Client)
{   
	SetZBItemTime(Client, 20, 15, false);       
	SetZBItemTime(Client, 30, 15, false); 
	SetZBItemTime(Client, 34, 15, false); 
	PlayerItem[Client][ITEM_XH][4] += 5; //生命恢复卷
	PlayerItem[Client][ITEM_XH][9] += 5; //复活币
	XR[Client] += 4
	MenuFunc_LXQDJLA(Client);
	CPrintToChat(Client, "\x05【新人任务礼包】恭喜玩家%N获得巨人腰带、饮血剑、仲亚之戒装备和5个生命恢复卷跟复活币!", Client);
}
/******************************************************
*	结束
*******************************************************/
