/************************************************************************
*	道具系统
************************************************************************/
#define SOUND_GOTITEM	"doors/door_metal_thin_close2.wav"
#define SOUND_USEITEM	"doors/doormove2.wav"

#define ITEM_XH_MAX		10
#define ITEM_ZB_MAX		57


/* 消耗类道具 */
#define ITXH_QTCZL		0	//全体传召令
#define ITXH_QTKBJ		1	//全体狂暴卷
#define ITXH_QTSXJ		2	//全体嗜血卷
#define ITXH_QTHDJ		3	//全体换弹卷
#define ITXH_SMHFJ		4	//生命恢复卷
#define ITXH_MLHFJ		5	//魔力恢复卷
#define ITXH_SGBHJ		6	//圣光保护卷
#define ITXH_SGMYL		7	//圣光魔御令
#define ITXH_WXZDJ		8	//无限子弹卷
#define ITXH_FHB		    9	//复活币

/* 装备类道具 */
#define ITZB_BJXZ			0	//白金勋章
#define ITZB_ZSXZ			1	//黄金勋章
#define ITZB_SJXZ			2	//水晶勋章
#define ITZB_ZZXZ			3	//至尊勋章
//#define ITZB_KXTZ	        4	//春哥套装
#define ITZB_SQ_AH		5	//冥火之拥
#define ITZB_TYZSTZ		6	// 霸王血铠
#define ITZB_TYZSQT		7	//兰顿之兆
#define ITZB_TYZSWTZ		8	//狂徒铠甲
#define ITZB_TYZSEM	    9   //三相之力
#define ITZB_DJZYJZ		10	//活力宝珠  +HP恢复
#define ITZB_ZJZYJZ		11	//多兰之剑  +HP恢复
#define ITZB_GJZYJZ		12	//再生坠饰  +HP恢复
#define ITZB_JPZYJZ		13	//哲理之石  +HP恢复
#define ITZB_JSZYJZ		14	//精神之貌  +HP恢复
#define ITZB_ZRZYJZ		15	//自然之力  +HP恢复
#define ITZB_DJSMZD		16	//多兰之盾   +HP
#define ITZB_ZJSMZD		17	//多兰之戒   +HP
#define ITZB_GJSMZD		18	//红宝石水晶   +HP
#define ITZB_JPSMZD		19	//黄金之心   +HP
#define ITZB_JRSMZD		20	//巨人腰带   +HP
#define ITZB_DJGLDY		21  //长剑                +攻击
#define ITZB_ZJGLDY		22	//长柄战斧    +攻击
#define ITZB_GJGLDY		23	//麦瑞得的拳刃    +攻击
#define ITZB_JPGLDY		24	//熔岩巨剑    +攻击
#define ITZB_HSGLDY		25  //黑色屠刀    +攻击
#define ITZB_YHGLDY		26	//永恒之刃    +攻击
#define ITZB_ZHGLDY		27	//最后的轻语    +攻击
#define ITZB_RYGLDY		28	//残暴    +攻击
#define ITZB_HYGLDY		29	//幻影之舞    +攻击
#define ITZB_YXGLDY		30	//饮血剑    +攻击
#define ITZB_DJMLJL		31	//贤者之戒   +MP
#define ITZB_ZJMLJL		32  //女神之泪  +MP
#define ITZB_GJMLJL		33	//冰川之冠  +MP
#define ITZB_JPMLJL		34	//仲亚之戒  +MP
#define ITZB_JPMLJQ		35	//修复装备栏
#define ITZB_JPMLJW		36	//修复装备栏
#define ITZB_JPMLJE		37	//修复装备栏
#define ITZB_JPMLJR		38	//修复装备栏
#define ITZB_JPMLJT		39	//修复装备栏
#define ITZB_JPMLJY		40	//修复装备栏
#define ITZB_JPMLJU		41	//修复装备栏
#define ITZB_JPMLJI		42	//仲亚之戒  +MP
#define ITZB_JPMLJO		43	//仲亚之戒  +MP
#define ITZB_JPMLJP		44	//仲亚之戒  +MP
#define ITZB_JPMLJA		45	//仲亚之戒  +MP
#define ITZB_JPMLJS		46	//仲亚之戒  +MP
#define ITZB_JPMLJD		47	//仲亚之戒  +MP
#define ITZB_JPMLJF		48	//仲亚之戒  +MP
#define ITZB_JPMLJG		49	//仲亚之戒  +MP
#define ITZB_JPMLJH		50	//仲亚之戒  +MP
#define ITZB_JPMLJJ		51	//仲亚之戒  +MP
#define ITZB_JPMLJK		52	//仲亚之戒  +MP
#define ITZB_JPMLJZ		53	//仲亚之戒  +MP
#define ITZB_KXTZ		54	//春哥套装
#define ITZB_JPMLJC		55	//仲亚之戒  +MP
#define ITZB_JPMLJV		56	//仲亚之戒  +MP
/*
#define ITZB_DMXYZL		58	//精灵职业套装
#define ITZB_AYLS			59	//游侠职业套装
#define ITZB_WLYS			60	//圣骑士职业套装
#define ITZB_ZXZZ			61		//心灵医生职业套装
#define ITZB_YGWL			62		//魔法师职业套装
#define ITZB_DY			63		//弹药专家职业套装
#define ITZB_LS			64		//雷神职业套装
*/

/* 消耗类道具 */
static String:ItemName_XH[ITEM_XH_MAX][64] = { "全体传召令", "全体狂暴卷", "全体嗜血卷", "全体换弹卷", "生命恢复卷", "魔力恢复卷", "圣光保护卷", "圣光魔御令", "无限子弹卷", "复活币" };

/* 消耗类道具说明 */
static String:ItemMSG_XH[ITEM_XH_MAX][256] = 
{ 
"═══════ 玩家通用 ═══════ \n \n是上古流传下来用于在战场上快速救援队友的魔法卷轴. \n使用后可以快速召唤全体队友到自己身边 \n \n═══════════════════", 
"═══════ 玩家通用 ═══════ \n \n是神话中恶魔常常使用的力量,后来被魔法师制成了卷轴. \n使用后全体队友移动速度提高100％持续80秒 \n \n═══════════════════", 
"═══════ 玩家通用 ═══════ \n \n是神话中恶魔常常使用的力量,后来被魔法师制成了卷轴. \n使用后全体队友攻击速度提高100％持续80秒 \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n是神话中恶魔常常使用的力量,后来被魔法师制成了卷轴. \n使用后全体队友换弹速度提高100％持续80秒 \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n是远古巫师所创造的能够让将祝福的圣光给予已经逝去的生命. \n使用后生命值瞬间恢复至满 \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n是魔法时代各大魔导师经过数百年的尝试,终于炼制而成魔力卷. \n使用后魔法值瞬间恢复至满 \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n上帝依旧眷恋着我们...... \n使用后无敌持续80秒. \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n天堂的圣光,地狱的魔光,混沌的力量.... \n使用后全体幸存者无敌持续80秒. \n \n═══════════════════" ,
"═══════ 玩家通用 ═══════ \n \n炼金时代的炼金术士利用各种炼金科技打造的迷之卷轴. \n使用后全体幸存者无限子弹持续80秒. \n \n═══════════════════" , 
"═══════ 玩家通用 ═══════ \n \n由古代神秘药水所致,拥有复活效果，可随机复活任意一个玩家旁边. \n \n═══════════════════"  

};

/* 消耗类掉落几率 */
static Float:Item_XH_Radio[ITEM_XH_MAX] = { 0.0, 15.0, 10.0, 10.0, 10.0, 15.0, 10.0, 10.0, 10.0, 0.0 };


/* 属性类装备 */
public String:ItemName_ZB[ITEM_ZB_MAX][57] = { "白金勋章", "黄金勋章", "水晶勋章", "至尊勋章", "春哥套装", "冥火之拥", "霸王血铠", "兰顿之兆", "狂徒铠甲", "三相之力", "活力宝珠", "多兰之盾", "再生坠饰", "哲理之石", "精神之貌", "自然之力", "多兰之剑", "多兰之戒", "红宝石水晶", "黄金之心", "巨人腰带", "长剑", "长柄战斧", "麦瑞得的拳刃", "熔岩巨剑", "黑色屠刀", "永恒之刃", "最后的轻语", "残暴", "幻影之舞", "饮血剑","贤者之戒", "女神之泪", "冰川之冠", "仲亚之戒",
 "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效", "此装备无效"};

/* 属性类装备说明 */
static String:ItemMSG_ZB[ITEM_ZB_MAX][256] = 
{ 
"═══════ 会员专用 ═══════ \n \n白金会员拥有3次补给(移动速度+5%,攻击力+5%) \n130%双倍经验和游戏币加成,倒地死亡经验减少50% \n \n═══════════════════", 
"═══════ 会员专用 ═══════ \n \n黄金会员拥有5次补给(移动速度+10%,攻击力+10%) \n160%双倍经验和游戏币加成,倒地死亡经验减少60% \n \n═══════════════════",
"═══════ 会员专用 ═══════ \n \n水晶会员拥有6次补给(移动速度+15%,攻击力+15%) \n200%双倍经验和游戏币加成,倒地死亡经验减少80% \n \n═══════════════════", 
"═══════ 会员专用 ═══════ \n \n至尊会员拥有9次补给(移动速度+20%,攻击力+20%) \n300%双倍经验和游戏币加成,倒地死亡经验减少90% \n \n═══════════════════", 
"(速度+40％)(跳跃+60％) \n \n机械(攻速+80％)(攻击力+50％) \n \n(治愈术HP+50)(防御+80％) \n(HP+3000)(MP+130000) \n \n(火焰伤害-80％)",
"(速度+10％)(跳跃+0.8％) \n \n机械(攻速+16％) \n \n(攻击力+0.5％)(治愈术HP+6) \n(MP+20000)(火焰伤害-12％)",
"(速度+12％)(跳跃+16％) \n \n机械(攻速+32％)(攻击力+10％) \n \n(治愈术HP+12)(防御+30％) \n(MP+40000) \n \n(火焰伤害-24％)",
"(速度+13％)(跳跃+24％) \n \n机械(攻速+48％)(攻击力+15％) \n \n(治愈术HP+18)(防御+50％) \n(MP+60000) \n \n(火焰伤害-36％)",
"(速度+14％)(跳跃+32％) \n \n机械(攻速+64％)(攻击力+20％) \n \n(治愈术HP+24)(防御+65％) \n(MP+80000) \n \n(火焰伤害-48％)",
"(速度+15％)(跳跃+40％) \n \n机械(攻速+80％)(攻击力+25％) \n \n(治愈术HP+30)(防御+50％) \n(MP+100000) \n \n(火焰伤害-60％)",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+３) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+２５) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+１０) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+２０) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+３０) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高治疗术效果的装备(治疗术每秒恢复HP+４０) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高生命值的装备(HP+４０) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高生命值的装备(HP+１００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高生命值的装备(HP+２００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高生命值的装备(HP+３００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高生命值的装备(HP+４００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+３％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+３％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+７％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+１０％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+１０％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+１５％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+１５％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+２３％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+２０％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高枪械武器攻击力的装备(攻击力+３０％) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高魔法值的上限值(MP上限+１００００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高魔法值的上限值(MP上限+２００００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高魔法值的上限值(MP上限+３００００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n提高魔法值的上限值(MP上限+５００００) \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════",
"═══════ 玩家通用 ═══════ \n \n此装备无效，修复装备栏用。 \n \n═══════════════════"
};  

/*
"(速度+40％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+40％) \n \n(治愈术HP+80)(防御+30％)\n \n(HP+600)(MP+50000) \n \n(火焰伤害-40％)",
"(速度+40％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+60％) \n \n(治愈术HP+80)(防御+50％)\n \n(HP+600)(MP+50000) \n \n(火焰伤害-40％)",
"(速度+40％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+60％) \n \n(治愈术HP+80)(防御+60％)\n \n(HP+900)(MP+50000) \n \n(火焰伤害-40％)",
"(速度+60％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+70％) \n \n(治愈术HP+100)(防御+50％)\n \n(HP+600)(MP+80000) \n \n(火焰伤害-40％)",
"(速度+40％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+60％) \n \n(治愈术HP+80)(防御+50％)\n \n(HP+600)(MP+100000) \n \n(火焰伤害-40％)",
"(速度+60％)(跳跃+50％) \n \n机械(攻速+50％)(攻击力+70％) \n \n(治愈术HP+80)(防御+70％)\n \n(HP+1000)(MP+100000) \n \n(火焰伤害-60％)",
"(速度+60％)(跳跃+50％) \n \n机械(攻速+70％)(攻击力+60％) \n \n(治愈术HP+100)(防御+50％)\n \n(HP+800)(MP+100000) \n \n(火焰伤害-60％)"
*/

/* 装备类掉落几率 */
public Float:Item_ZB_Radio[ITEM_ZB_MAX] = 
{ 
0.0, 
0.0, 
0.0, 
0.0, 
0.0, 
0.0, 
0.0, 
0.0, 
0.0, 
0.0,
0.0, //10
0.5, 
0.2, 
0.0, 
0.0,
0.0, 
0.0, 
0.5, 
0.2, 
0.0, 
0.0, //20
0.0, 
0.5,
0.4,
0.3, 
0.0,
0.0,
0.0, 
0.0,
0.0, 
0.0,//30
0.4, 
0.2,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,
0.0,  
};


new XH_itemcost = 30000;
new ZB_itemcost = 50000;

#define XH_COSTEFFECT[%1]	PlayerXHItemSize[%1] * 10000 + XH_itemcost - 10000
#define ZB_COSTEFFECT[%1]	PlayerZBItemSize[%1] * 25000 + ZB_itemcost - 25000

/* 使用道具临时变量 */
new UseXHItem[MAXPLAYERS+1];
/* 装备物品临时变量 */
new UseZBItem[MAXPLAYERS+1];

/* 全体嗜血卷变量 */
new bool:IsActionQTSXJ = false;

/* 全体换弹卷变量 */
new bool:IsActionQTHDJ = false;

/* 无限子弹卷变量 */
new bool:IsActionWXZDJ = false;

/* 装备治愈变量 */
new ZB_Healing[MAXPLAYERS+1];

/* 装备防御变量 */
new Float:ZB_EndEffect[MAXPLAYERS+1];

/* 装备火焰抗性变量 */
new Float:ZB_FireEnd[MAXPLAYERS+1];
/* 装备枪械伤害变量 */
new Float:ZB_GunDmg[MAXPLAYERS+1];
/* 装备魔力上限变量 */
new ZB_MPBuffer[MAXPLAYERS+1];
/* 装备枪械攻速变量 */
new Float:ZB_GunSpeed[MAXPLAYERS+1];


/* 道具装备店刷新 */
static Float:ItemBuyRadio[2] = { 90.0, 65.0 };
new ItemBuy_Type = -1;
new ItemBuy_Item = -1;
new ItemBuy_Num = 0;
new ItemBuy_Cash = 0;

/* 装备属性上限 */
#define Limit_ZB_Health			5000	//加HP值
#define Limit_ZB_Healing			100	//每秒回复HP
#define Limit_ZB_End				1.0	//防御
#define Limit_ZB_FireEnd			0.99	//减少火焰伤害
#define Limit_ZB_GunDmg			5.0	//机械攻速
#define Limit_ZB_MPBuffer		100000	//加MP值
#define Limit_ZB_GunSpeed		2.0	//攻击力
#define Limit_ZB_Speed			5.0	//速度
#define Limit_ZB_Jump			0.8	//跳跃跳跃

/* 卷轴默认持续时间 */
#define XH_Duration				80.0

/*******************************************************************************************
*								我的道具主菜单_开始
*******************************************************************************************/

//道具物品主面板
public MenuFunc_MyItem(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_MyItem);
	decl String:line[64];
	
	SetMenuTitle(menu, "我的物品[K键]:");

	Format(line, sizeof(line), "消耗物品(拥有数量:%d 剩余空间:%d)", GetHasXHItemCount(Client), PlayerXHItemSize[Client] - GetHasXHItemCount(Client));
	AddMenuItem(menu, "item0", line);
	
	Format(line, sizeof(line), "装备物品(拥有数量:%d 剩余空间:%d)", GetHasZBItemCount(Client), PlayerZBItemSize[Client] - GetHasZBItemCount(Client));
	AddMenuItem(menu, "item1", line);	
	
	Format(line, sizeof(line), "扩充消耗物品栏(当前空间:%d 价格:%d$/格)", PlayerXHItemSize[Client], XH_COSTEFFECT[Client]);
	AddMenuItem(menu, "item2", line);	
	
	Format(line, sizeof(line), "扩充装备物品栏(当前空间:%d 价格:%d$/格)", PlayerZBItemSize[Client], ZB_COSTEFFECT[Client]);
	AddMenuItem(menu, "item3", line);	
	
	Format(line, sizeof(line), "查看自身所有装备的总属性");
	AddMenuItem(menu, "item4", line);		
	
	Format(line, sizeof(line), "查看装备参数表");
	AddMenuItem(menu, "item6", line);	

	Format(line, sizeof(line), "查看在线队友的物品");
	AddMenuItem(menu, "item5", line);			

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_MyItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG(Client);
	}
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 0: MenuFunc_MyXHItem(Client); //消耗物品
			case 1: MenuFunc_MyZBItem(Client); //装备物品
			case 2: BuyXHItemBag(Client), MenuFunc_MyItem(Client); //扩充消耗物品栏
			case 3: BuyZBItemBag(Client), MenuFunc_MyItem(Client); //扩充装备物品栏
			case 4: RebuildStatus(Client, false, true); //查看所有装备属性
			case 5: MenuFunc_ViewAllItem(Client); //查看道具物品一览表
			case 6: MenuFunc_ViewItemPlayer(Client); //物品查看信息
		}
	}
}

/*
//职业套装
public MenuFunc_GetZYTZ(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_GetMyZYTZ);
	decl String:line[128];
	
	SetMenuTitle(menu, "领取职业套装:");
	Format(line, sizeof(line), "精灵职业装(适合:未转生,精灵职业)");
	AddMenuItem(menu, "item1", line);

	Format(line, sizeof(line), "士兵职业装(适合:未转生,士兵职业)");
	AddMenuItem(menu, "item2", line);

	Format(line, sizeof(line), "生物专家职业装(适合:未转生,生物专家职业)");
	AddMenuItem(menu, "item3", line);

	Format(line, sizeof(line), "医师职业装(适合:未转生,医师职业)");
	AddMenuItem(menu, "item4", line);

	Format(line, sizeof(line), "法师职业装(适合:未转生,法师职业)");
	AddMenuItem(menu, "item5", line);	
	
	Format(line, sizeof(line), "弹药专家职业装(适合:3转,弹药专家职业)");
	AddMenuItem(menu, "item6", line);
	
	Format(line, sizeof(line), "雷神职业装(适合:5转,雷神职业)");
	AddMenuItem(menu, "item7", line);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}
public MenuHandler_GetMyZYTZ(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG(Client);
	}
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 0: FetchZB(Client,ITZB_DMXYZL); //精灵
			case 1: FetchZB(Client,ITZB_AYLS); //士兵
			case 2: FetchZB(Client,ITZB_WLYS);//生物专家
			case 3: FetchZB(Client,ITZB_ZXZZ); //医师
			case 4: FetchZB(Client,ITZB_YGWL); //法师
			case 5: FetchZB(Client,ITZB_DY); //弹药专家
			case 6: FetchZB(Client,ITZB_LS); //雷神
		}
	}
}

public FetchZB(Client,arg){
	switch(arg){
		case 58:
		{
			if(NewLifeCount[Client] == 0 && JD[Client] == 1 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_DMXYZL) <= 0){
				SetZBItemTime(Client, 58, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[精灵职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[精灵职业装]失败!");
			}		
		}
		case 59:
		{
			if(NewLifeCount[Client] == 0 && JD[Client] == 2 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_AYLS) <= 0){
				SetZBItemTime(Client, 59, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[游侠职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[游侠职业装]失败!");
			}		
		}	
		case 60:
		{
			if(NewLifeCount[Client] == 0 && JD[Client] == 3 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_WLYS) <= 0){
				SetZBItemTime(Client, 60, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[圣骑士职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[圣骑士职业装]失败!");
			}		
		}
		case 61:
		{
			if(NewLifeCount[Client] == 0 && JD[Client] == 4 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_ZXZZ) <= 0){
				SetZBItemTime(Client, 61, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[心灵职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[心灵职业装]失败!");
			}		
		}	
		case 62:
		{
			if(NewLifeCount[Client] == 0 && JD[Client] == 5 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_YGWL) <= 0){
				SetZBItemTime(Client, 62, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[魔法师职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[魔法师职业装]失败!");
		}	
		case 63:
		{
			if(NewLifeCount[Client] <= 3 && JD[Client] == 6 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_DY) <= 0){
				SetZBItemTime(Client, 63, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[弹药专家职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[弹药专家职业装]失败!");
		}	
		case 64:
		{
			if(NewLifeCount[Client] <= 5 && JD[Client] == 7 && PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0 && GetZBItemTime(Client, ITZB_LS) <= 0){
				SetZBItemTime(Client, 64, 10, true);
				CreateTimer(0.1, StatusUp, Client);
				CPrintToChatAll("\x05【公告】玩家%N成功领取了[雷神职业装]10日!", Client);
			}else{
				CPrintToChat(Client,"\x03【提示】领取[雷神职业装]失败!");
			}		
		}
	}
}
*/

/* 查看道具物品一览表 */
public MenuFunc_ViewAllItem(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_ViewAllItem);
	decl String:line[64];
	
	SetMenuTitle(menu, "道具物品一览表:");

	for (new i = ITEM_ZB_MAX; i > 0; i--)
	{
		Format(line, sizeof(line), "装备类: %s (基础爆率: %.3f％)", ItemName_ZB[i - 1], Item_ZB_Radio[i - 1]);
		AddMenuItem(menu, "装备", line);
	}
	
	for (new i = ITEM_XH_MAX; i > 0; i--)
	{
		Format(line, sizeof(line), "消耗类: %s (基础爆率: %.3f％)", ItemName_XH[i - 1], Item_XH_Radio[i - 1]);
		AddMenuItem(menu, "消耗", line);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_ViewAllItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
	if(action == MenuAction_Select)
	{
		decl String:info[16], type, item;
		GetMenuItem(menu, param, info, sizeof(info));
		if (StrEqual(info, "装备"))
			type = ITEM_ZB;
		else if (StrEqual(info, "消耗"))
			type = ITEM_XH;
			
		if(type == ITEM_ZB)
			item = ITEM_ZB_MAX - (param + 1);
		else if (type == ITEM_XH)
			item = ITEM_XH_MAX - (param - (ITEM_ZB_MAX - 1));
			
		if (param > -1)
			MenuFunc_ViewItemMSG(Client, Client, type, item, false);
	}
}

/* 道具装备店 */
public MenuFunc_BuyItem(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_BuyItem);
	decl String:line[64];
	
	SetMenuTitle(menu, "道具装备专卖店: \n本店在每回合游戏开始后 \n将会有一定几率进货一些装备或道具 \n请随时关注该店 有几率抢到好道具好装备哦!");

	if (ItemBuy_Type >= 0 && ItemBuy_Item >= 0 && ItemBuy_Num > 0 && ItemBuy_Cash > 0)
	{
		if (ItemBuy_Type == ITEM_XH)
			Format(line, sizeof(line), "消耗类: %s (库存:%d 价格:%d$)", ItemName_XH[ItemBuy_Item], ItemBuy_Num, ItemBuy_Cash);
		else if (ItemBuy_Type == ITEM_ZB)
			Format(line, sizeof(line), "装备类: %s (时间:%d天 价格:%d$)", ItemName_ZB[ItemBuy_Item], ItemBuy_Num, ItemBuy_Cash);
		AddMenuItem(menu, "item0", line);
	}
	else
		AddMenuItem(menu, "item0", "当前没有任何库存", ITEMDRAW_DISABLED);
		

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_BuyItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_Buy(Client);
	}
	if(action == MenuAction_Select)
	{
		if (ItemBuy_Type == ITEM_XH)
		{
			if (PlayerXHItemSize[Client] - GetHasXHItemCount(Client) > 0)
			{
				if (ItemBuy_Item >= 0 && ItemBuy_Num > 0 && Cash[Client] >= ItemBuy_Cash)
				{
					Cash[Client] -= ItemBuy_Cash;
					ItemBuy_Num -= 1;
					PlayerItem[Client][ITEM_XH][ItemBuy_Item] += 1;
					CPrintToChatAll("\x03[道具] {red}%N \x03用了 {red}%d$ \x03在道具装备专卖店抢买到了 {red}[%s(1个)]", Client, ItemBuy_Cash, ItemName_XH[ItemBuy_Item]);
					EmitSoundToClient(Client, SOUND_GOTITEM);
					if (ItemBuy_Num <= 0)
					{
						ItemBuy_Type = -1;
						ItemBuy_Item = -1;
						ItemBuy_Num = 0;
						ItemBuy_Cash = 0;	
					}
				}
				else
					PrintHintText(Client, "你没有足够的金钱购买该道具或库存不足!");
			}
			else
				PrintHintText(Client, "你没有足够的物品栏装入该道具!");
		}
		else if (ItemBuy_Type == ITEM_ZB)
		{
			if (PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0)
			{
				if (ItemBuy_Item >= 0 && ItemBuy_Num > 0 && Cash[Client] >= ItemBuy_Cash)
				{
					Cash[Client] -= ItemBuy_Cash;
					SetZBItemTime(Client, ItemBuy_Item, ItemBuy_Num, false);
					CPrintToChatAll("\x03[道具] {red}%N \x03用了 {red}%d$ \x03在道具装备专卖店抢买到了 {red}[%s(%d天)]", Client, ItemBuy_Cash, ItemName_ZB[ItemBuy_Item], ItemBuy_Num);
					EmitSoundToClient(Client, SOUND_GOTITEM);
					ItemBuy_Type = -1;
					ItemBuy_Item = -1;
					ItemBuy_Num = 0;
					ItemBuy_Cash = 0;	
				}
				else
					PrintHintText(Client, "你没有足够的金钱购买该道具或库存不足!");
			}
			else
				PrintHintText(Client, "你没有足够的物品栏装入该道具!");
		}
		else
			PrintHintText(Client, "道具库存不足!")
			
		MenuFunc_BuyItem(Client);
	}
}


/***********************************
*	 道具获得提示面板 
***********************************/
public MenuFunc_GotItemMSG(Client, type, item, day, String:MSG[])
{
	
	new Handle:menu = CreatePanel();
	decl String:line[64];
	
	SetPanelTitle(menu, MSG);
	
	DrawPanelText(menu, " \n");
	DrawPanelText(menu, "════════════════");
	if (type == ITEM_XH)
		Format(line, sizeof(line), "消耗类: [%s]", ItemName_XH[item]);
	else if (type == ITEM_ZB)
		Format(line, sizeof(line), "装备类: [%s]", ItemName_ZB[item]);
		
	DrawPanelText(menu, line);
	if (type == ITEM_XH)
		Format(line, sizeof(line), "数量: 1个");
	else if (type == ITEM_ZB)
		Format(line, sizeof(line), "时间: %d天", day);
	DrawPanelText(menu, line);	
	DrawPanelText(menu, "════════════════");	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "我知道了");
	
	SendPanelToClient(menu, Client, MenuHandler_GotItemMSG, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_GotItemMSG(Handle:menu, MenuAction:action, Client, param)
{
}

/*******************************************************************************************
*								我的道具主菜单_结束
*******************************************************************************************/

/*══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════*/

/*******************************************************************************************
*								物品查看_开始
*******************************************************************************************/

/* 物品查看_玩家列表 */
public MenuFunc_ViewItemPlayer(Client)
{
	decl String:line[256], String:name[64], has, itemcount;
	new Handle:menu = CreateMenu(MenuHandler_ViewItemPlayer);
	SetMenuTitle(menu, "查看物品:");
	has = 0;
	itemcount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false) && i != Client)
		{
			itemcount = GetHasXHItemCount(i) + GetHasZBItemCount(i);
			if (itemcount > 0)
			{
				has++;
				Format(line, sizeof(line), " %N", i);			
				GetClientName(i, name, sizeof(name));			
				if (itemcount > 0)
					AddMenuItem(menu, name, line);
			}
		}
	}

	if (has <= 0)
		AddMenuItem(menu, "item0", "没有发现任何可用玩家!", ITEMDRAW_DISABLED)
		
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}
public MenuHandler_ViewItemPlayer(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
	if(action == MenuAction_Select)
	{
		decl String:name[64], target;
		GetMenuItem(menu, param, name, sizeof(name));
		target = GetClientForName(name);
		if (IsValidPlayer(target, false))
			MenuFunc_ViewItem(Client, target);
	}
}

/* 物品查看_物品列表 */
public MenuFunc_ViewItem(Client, target)
{
	new Handle:menu = CreateMenu(MenuHandler_ViewItem);
	decl String:line[64], time;
	Format(line, sizeof(line), "查看 %N 的物品:", target);
	SetMenuTitle(menu, line);
	new has;
	for (new i; i < MaxItemNum[ITEM_XH]; i++)
	{
		if (PlayerItem[target][ITEM_XH][i] >= 1)
		{
			has++;
			Format(line, sizeof(line), "消耗类:%s (%d个)", ItemName_XH[i], PlayerItem[target][ITEM_XH][i]);
			AddMenuItem(menu, ItemName_XH[i], line);
		}
	}
	
	for (new i; i < MaxItemNum[ITEM_ZB]; i++)
	{
		time = GetZBItemTime(target, i);
		if (time > 0)
		{
			has++;
			Format(line, sizeof(line), "装备类:%s (%d天)", ItemName_ZB[i], time);
			AddMenuItem(menu, ItemName_ZB[i], line);
		}
	}
	
	if (has <= 0)
		AddMenuItem(menu, "not", "他没有任何物品", ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public MenuHandler_ViewItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
	if(action == MenuAction_Select)
	{
		decl String:info[32], String:item[32], type, id, target, String:title[32], style;
		GetMenuItem(menu, param, info, sizeof(info), style, item, sizeof(item));
		if (StrContains(item, "消耗类", false) >= 0)
			type = ITEM_XH;
		else if (StrContains(item, "装备类", false) >= 0)
			type = ITEM_ZB;
		
		GetMenuTitle(menu, title, sizeof(title));
		id = GetItemID(info, type);
		target = GetClientForName(title, true);
		if (IsValidPlayer(target, false) && id >= 0)
			MenuFunc_ViewItemMSG(Client, target, type, id);
	}
}


/* 物品查看_物品信息 */
stock MenuFunc_ViewItemMSG(Client, target, type, item, bool:viewplayer = true)
{
	decl String:line[256], overtime;
	new Handle:menu = CreatePanel();

	if (viewplayer)
	{
		if (type == ITEM_XH)
			Format(line, sizeof(line), "查看 %N 的物品: \n════ [%s] ════ \n \n拥有数量: %d", target, ItemName_XH[item], PlayerItem[target][ITEM_XH][item]);
		else if (type == ITEM_ZB)
			overtime = GetZBItemTime(target, item), Format(line, sizeof(line), "查看 %N 的物品: \n════ [%s] ════ \n \n剩余时间: %d 天", target, ItemName_ZB[item], overtime);
	}
	else
	{
		if (type == ITEM_XH)
			Format(line, sizeof(line), "查看消耗类: [%s] 物品:", ItemName_XH[item]);
		else if (type == ITEM_ZB)
			Format(line, sizeof(line), "查看装备类: [%s] 物品:", ItemName_ZB[item]);	
	}
		
	SetPanelTitle(menu, line);

	DrawPanelText(menu, " \n");
	if (type == ITEM_XH)
	{
		DrawPanelText(menu, "道具说明:");
		DrawPanelText(menu, " \n");
		Format(line, sizeof(line), "%s", ItemMSG_XH[item]);
	}
	else if (type == ITEM_ZB)
	{
		DrawPanelText(menu, "装备说明:");
		DrawPanelText(menu, " \n");
		Format(line, sizeof(line), "%s", ItemMSG_ZB[item]);
	}
		
	DrawPanelText(menu, line);	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	SendPanelToClient(menu, Client, MenuHandler_ViewItemMSG, MENU_TIME_FOREVER);
}
public MenuHandler_ViewItemMSG(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (param == 1)
			MenuFunc_MyItem(Client);
	}
}

/*******************************************************************************************
*								物品查看_结束
*******************************************************************************************/

/*══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════*/

/*******************************************************************************************
*								消耗类物品功能_开始
*******************************************************************************************/

/************************************
*	消耗类道具菜单
************************************/

//消耗类物品菜单
public MenuFunc_MyXHItem(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_MyXHItem);
	decl String:line[64];		
	SetMenuTitle(menu, "消耗类物品:");
	new has;
	for (new i; i < MaxItemNum[ITEM_XH]; i++)
	{
		if (PlayerItem[Client][ITEM_XH][i] >= 1)
		{
			has++;
			Format(line, sizeof(line), "%s (拥有数量: %d 个)", ItemName_XH[i], PlayerItem[Client][ITEM_XH][i]);
			AddMenuItem(menu, ItemName_XH[i], line);
		}
	}
	
	if (has <= 0)
		AddMenuItem(menu, "not", "你没有任何消耗物品", ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_MyXHItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
	if(action == MenuAction_Select)
	{
		decl String:info[32], id;
		GetMenuItem(menu, param, info, sizeof(info));
		id = GetItemID(info, ITEM_XH);
		if (id >= 0)
			MenuFunc_ItemXHMSG(Client, id);
	}
}

//消耗类道具物品信息面板
public MenuFunc_ItemXHMSG(Client, item)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "════ [%s] ════ \n \n拥有数量: %d", ItemName_XH[item], PlayerItem[Client][ITEM_XH][item]);
	SetPanelTitle(menu, line);

	DrawPanelText(menu, " \n");
	DrawPanelText(menu, "道具说明:");
	DrawPanelText(menu, " \n");
	Format(line, sizeof(line), "%s", ItemMSG_XH[item]);
	DrawPanelText(menu, line);
	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "使用");
	DrawPanelItem(menu, "不要了");
	DrawPanelItem(menu, "赠送");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	UseXHItem[Client] = item;
	SendPanelToClient(menu, Client, MenuHandler_ItemXHMSG, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_ItemXHMSG(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (UseXHItem[Client] >= 0)
		{
			switch(param)
			{
				case 1: Use_XHItem(Client, UseXHItem[Client]);
				case 2: MenuFunc_ItemXHDrop(Client, UseXHItem[Client]);
				case 3: MenuFunc_ItemXHGive(Client, UseXHItem[Client]);
				case 4: MenuFunc_MyXHItem(Client);
			}
		}
	}
}

//使用消耗类道具
public Use_XHItem(Client, item)
{
	if (!IsValidPlayer(Client, false))
		return;
		
	if (!IsPlayerAlive(Client))
	{
		PrintHintText(Client, "死亡状态下无法使用道具!");
		return;
	}
	
	if (PlayerItem[Client][ITEM_XH][item] >= 1)
	{
		PlayerItem[Client][ITEM_XH][item] -= 1;
		EmitSoundToClient(Client, SOUND_USEITEM);
		if (item == ITXH_QTCZL)
			XHItem_QTCZL(Client);
		else if (item == ITXH_QTKBJ)
			XHItem_QTKBJ(Client);
		else if (item == ITXH_QTSXJ)
			XHItem_QTSXJ(Client);
		else if (item == ITXH_QTHDJ)
			XHItem_QTHDJ(Client);
		else if (item == ITXH_SMHFJ)
			XHItem_SMHFJ(Client);
		else if (item == ITXH_MLHFJ)
			XHItem_MLHFJ(Client);
		else if (item == ITXH_SGBHJ)
			XHItem_SGBHJ(Client);
		else if (item == ITXH_SGMYL)
			XHItem_SGMYL(Client);
		else if (item == ITXH_WXZDJ)
			XHItem_WXZDJ(Client);
		else if (item == ITXH_FHB)  //复活币
			XHItem_FHB(Client);
		
	}
	else
		PrintHintText(Client, "════════════════ \n你没有 [%s] ,无法使用! \n════════════════", ItemName_XH[item]);
}

//丢弃消耗类道具
public MenuFunc_ItemXHDrop(Client, item)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "丢弃物品:");
	SetPanelTitle(menu, line);

	DrawPanelText(menu, "════════════════");
	
	Format(line, sizeof(line), "准备丢弃道具: \n══ [%s] ══ \n是否确认丢弃该道具一个?", ItemName_XH[item]);
	DrawPanelText(menu, line);
	
	DrawPanelText(menu, "════════════════");

	DrawPanelItem(menu, "确认");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	UseXHItem[Client] = item;
	SendPanelToClient(menu, Client, MenuHandler_ItemXHDrop, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_ItemXHDrop(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (param == 1)
		{
			PlayerItem[Client][ITEM_XH][UseXHItem[Client]] -= 1;
			PrintHintText(Client, "════════════════ \n你已丢弃了 [%s] 一个 \n════════════════", ItemName_XH[UseXHItem[Client]])
		}
	}
}

//赠送消耗类道具
public MenuFunc_ItemXHGive(Client, item)
{
	decl String:line[256], String:name[64], has;
	new Handle:menu = CreateMenu(MenuHandler_ItemXHGive);
	Format(line, sizeof(line), "赠送消耗类给他人: \n赠送道具:[%s]", ItemName_XH[item]);
	SetMenuTitle(menu, line);
	has = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false) && i != Client)
		{
			has++;
			if (PlayerXHItemSize[i] - GetHasXHItemCount(i) > 0)
				Format(line, sizeof(line), "%N(剩余空间:%d个)", i, PlayerXHItemSize[i] - GetHasXHItemCount(i));
			else
				Format(line, sizeof(line), "%N(物品栏已满)", i);
				
			GetClientName(i, name, sizeof(name));
			if (PlayerXHItemSize[i] - GetHasXHItemCount(i) > 0)
				AddMenuItem(menu, name, line);
			else
				AddMenuItem(menu, name, line, ITEMDRAW_DISABLED);
		}
	}

	if (has <= 0)
		AddMenuItem(menu, "item0", "没有发现任何可用玩家!", ITEMDRAW_DISABLED)
	UseXHItem[Client] = item;
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}
public MenuHandler_ItemXHGive(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_ItemXHMSG(Client, UseXHItem[Client]);
	}
	if(action == MenuAction_Select)
	{
		decl String:name[64], target;
		GetMenuItem(menu, param, name, sizeof(name));
		target = GetClientForName(name);
		if (PlayerGiveItem(Client, target, ITEM_XH, UseXHItem[Client]) == 1)
			PrintHintText(Client, "赠送成功!");
		else
			PrintHintText(Client, "赠送失败!");		
	}
}

/************************************
*	消耗类道具功能
************************************/
/* 复活币 */ 
//static Handle:hRoundRespawn = INVALID_HANDLE;
 
public XHItem_FHB(Client)
{
	if (IsValidPlayer(Client, false))
	{
		//SDKCall(hRoundRespawn, Client);
		Teleport(Client);

		decl String:playername[64];
		GetClientName(Client, playername, sizeof(playername));
		PrintToChatAll("\x01\x05%s \x01复活成功!", playername);
	}
}

/* 传送到玩家那里 */
Teleport(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && i != client)
		{
			// get the position coordinates of any active living player
			new Float:coordinates[3];
			GetClientAbsOrigin(i, coordinates);
			TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

/* 全体传召令 */
public XHItem_QTCZL(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[全体传召令]\x03 召回所有生还者去他的所在地!", Client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
			{
				SetEntityMoveType(i, MOVETYPE_NONE);
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			}
		}
		new Handle:pack;
		CreateDataTimer(1.0, Timer_QTCZL, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + 6.0);
	}
}

/* 全体传召令_计时器 */
public Action:Timer_QTCZL(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	new Float:pos[3];
	if (IsValidPlayer(Client, false, false))
	{
		GetClientAbsOrigin(Client, pos);
		if (GetEngineTime() >= overtime)
		{
			PrintHintTextToAll("[全体传召令] 传召完毕!");
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
				{
					TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
					SetEntityMoveType(i, MOVETYPE_WALK);
					SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				}
			}
			
			KillTimer(timer);
		}
		else
			PrintHintTextToAll("[全体传召令] %N 正在召唤你到他的所在地, 剩余 %d 秒", Client, RoundToNearest(overtime - GetEngineTime()));
	}
	else
		KillTimer(timer);
}

/* 全体狂暴卷 */
public XHItem_QTKBJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[全体狂暴卷]\x03 全体幸存者移动速度+100％", Client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
				SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 2.0);
		}
		new Handle:pack;
		CreateDataTimer(1.0, Timer_QTKBJ, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 全体狂暴卷_计时器 */
public Action:Timer_QTKBJ(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("[全体狂暴卷] 全体移动速度+100％,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
				SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 2.0);
		}
	}
	else
	{
		if (IsValidPlayer(Client, false))
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {red}[全体狂暴卷]\x03 已停止,全体移动速度还原!", Client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i, true, false) && GetClientTeam(i) == 2)
				CreateTimer(0.1, StatusUp, i);
		}
		KillTimer(timer);	
	}
}


/* 全体嗜血卷 */
public XHItem_QTSXJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[全体嗜血卷]\x03 全体幸存者攻击速度+100％", Client);
		IsActionQTSXJ = true;
		new Handle:pack;
		CreateDataTimer(1.0, Timer_QTSXJ, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 全体嗜血卷_计时器 */
public Action:Timer_QTSXJ(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("[全体嗜血卷] 全体攻击速度+100％,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
		if (!IsActionQTSXJ)
			IsActionQTSXJ = true;
	}
	else
	{
		if (IsValidPlayer(Client, false))
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {reed}[全体嗜血卷]\x03 已停止,全体攻击速度还原!", Client);
		IsActionQTSXJ = false;
		KillTimer(timer);	
	}
}

/* 全体换弹卷 */
public XHItem_QTHDJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了(red}[全体换弹卷]\x03 全体幸存者换弹速度+100％", Client);
		IsActionQTHDJ = true;
		new Handle:pack;
		CreateDataTimer(1.0, Timer_QTHDJ, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 全体换弹卷_计时器 */
public Action:Timer_QTHDJ(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("[全体换弹卷] 全体换弹速度+100％,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
		if (!IsActionQTHDJ)
			IsActionQTHDJ = true;
	}
	else
	{
		if (IsValidPlayer(Client, false))
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {red}[全体换弹卷]\x03 已停止,全体换弹速度还原!", Client);
		IsActionQTHDJ = false;
		KillTimer(timer);	
	}
}

/* 生命恢复卷 */
public XHItem_SMHFJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[生命恢复卷] \x03使用者生命值瞬间恢复至满!", Client);
		new maxhealth = GetEntProp(Client, Prop_Data, "m_iMaxHealth");	
		SetEntProp(Client, Prop_Data, "m_iHealth", maxhealth);		
	}
}

/* 魔力恢复卷 */
public XHItem_MLHFJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[魔力恢复卷] \x03使用者魔法值瞬间恢复至满!", Client);
		MP[Client] = MaxMP[Client];
	}
}

/* 圣光保护卷 */
public XHItem_SGBHJ(Client)
{
	if (IsValidPlayer(Client, false) && IsValidEntity(Client))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[圣光保护卷] \x03使用者无敌持续%.0f秒!", Client, XH_Duration);
		SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
		new Handle:pack;
		CreateDataTimer(1.0, Timer_SGBHJ, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 圣光保护卷_计时器 */
public Action:Timer_SGBHJ(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		if (IsValidPlayer(Client, false) && IsValidEntity(Client))
		{
			PrintHintText(Client, "[圣光保护卷] 你处于无敌中,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
			if (GetEntProp(Client, Prop_Data, "m_takedamage") == 2)
				SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
		}		
	}
	else
	{
		if (IsValidPlayer(Client, false) && IsValidEntity(Client))
		{
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {red}[圣光保护卷]\x03 已停止,使用者无敌已经消失!", Client);
			SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
		}
		KillTimer(timer);	
	}
}

/* 圣光魔御令 */
public XHItem_SGMYL(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[圣光魔御令] \x03全体幸存者无敌持续%.0f秒!", Client, XH_Duration);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i) && IsValidEntity(i) && GetClientTeam(i) == 2)
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
		new Handle:pack;
		CreateDataTimer(1.0, Timer_SGMYL, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 圣光魔御令_计时器 */
public Action:Timer_SGMYL(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("[圣光魔御令] 全体幸存者无敌中,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i) && IsValidEntity(i) && GetClientTeam(i) == 2)
			{
				if (GetEntProp(i, Prop_Data, "m_takedamage") == 2)
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			}
		}	
	}
	else
	{
		if (IsValidPlayer(Client, false))
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {red}[圣光魔御令]\x03 已停止,全体幸存者无敌已经消失!", Client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidPlayer(i) && IsValidEntity(i) && GetClientTeam(i) == 2)
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		}		
		KillTimer(timer);	
	}
}

/* 无限子弹卷 */
public XHItem_WXZDJ(Client)
{
	if (IsValidPlayer(Client, false))
	{
		CPrintToChatAll("\x03[道具] {red}%N \x03使用了{red}[无限子弹卷]\x03全体幸存者无限子弹持续%.0f秒!", Client, XH_Duration);
		IsActionWXZDJ = true;
		new Handle:pack;
		CreateDataTimer(1.0, Timer_WXZDJ, pack, TIMER_REPEAT);
		WritePackCell(pack, Client);
		WritePackFloat(pack, GetEngineTime() + XH_Duration);
	}
}

/* 无限子弹卷_计时器 */
public Action:Timer_WXZDJ(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("[无限子弹卷] 全体幸存者无限子弹,剩余 %d 结束.", RoundToNearest(overtime - GetEngineTime()));
		if (!IsActionWXZDJ)
			IsActionWXZDJ = true;
	}
	else
	{
		if (IsValidPlayer(Client, false))
			CPrintToChatAll("\x03[道具] {red}%N \x03使用的 {red}[无限子弹卷]\x03 已停止,无限子弹效果已经消失!", Client);
		IsActionWXZDJ = false;
		KillTimer(timer);	
	}
}

/*******************************************************************************************
*								消耗类物品功能_结束
*******************************************************************************************/

/*══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════*/

/*******************************************************************************************
*								装备类物品功能_开始
*******************************************************************************************/

/************************************
*	装备类道具菜单
************************************/

//装备类物品菜单
public MenuFunc_MyZBItem(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_MyZBItem);
	decl String:line[64];		
	SetMenuTitle(menu, "装备类物品:");
	new has;
	new time;
	for (new i; i < MaxItemNum[ITEM_ZB]; i++)
	{
		time = GetZBItemTime(Client, i);
		if (time > 0)
		{
			has++;
			Format(line, sizeof(line), "%s (剩余时间: %d 天)", ItemName_ZB[i], time);
			AddMenuItem(menu, ItemName_ZB[i], line);
		}
	}
	
	if (has <= 0)
		AddMenuItem(menu, "not", "你没有任何装备物品", ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_MyZBItem(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
	if(action == MenuAction_Select)
	{
		decl String:info[64], id;
		GetMenuItem(menu, param, info, sizeof(info));
		id = GetItemID(info, ITEM_ZB);
		if (id >= 0)
			MenuFunc_ItemZBMSG(Client, id);
	}
}

//装备类道具物品信息面板
public MenuFunc_ItemZBMSG(Client, item)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	new overtime = GetZBItemTime(Client, item);
	Format(line, sizeof(line), "════ [%s] ════ \n \n剩余时间: %d 天", ItemName_ZB[item], overtime);
	SetPanelTitle(menu, line);

	DrawPanelText(menu, " \n");
	DrawPanelText(menu, "装备说明:");
	DrawPanelText(menu, " \n");
	Format(line, sizeof(line), "%s", ItemMSG_ZB[item]);
	DrawPanelText(menu, line);
	
	DrawPanelText(menu, " \n");

	DrawPanelItem(menu, "不要了");
	if (item != ITZB_ZSXZ && item != ITZB_BJXZ && item != ITZB_SJXZ && item != ITZB_ZZXZ)
		DrawPanelItem(menu, "赠送[禁止]");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	UseZBItem[Client] = item;
	SendPanelToClient(menu, Client, MenuHandler_ItemZBMSG, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_ItemZBMSG(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (UseZBItem[Client] >= 0)
		{
			switch(param)
			{
				case 1: MenuFunc_ItemZBDrop(Client, UseZBItem[Client]);
		//		case 2: 
		//		{
		//			if (UseZBItem[Client] != ITZB_ZSXZ && UseZBItem[Client] != ITZB_BJXZ)
		//				MenuFunc_ItemZBGive(Client, UseZBItem[Client]);
		//			else
		//				MenuFunc_MyZBItem(Client);
		//		}
				case 3: 
				{
					if (UseZBItem[Client] != ITZB_ZSXZ && UseZBItem[Client] != ITZB_BJXZ)
						MenuFunc_MyZBItem(Client);
				}
			}
		}
	}
}

//丢弃装备类道具
public MenuFunc_ItemZBDrop(Client, item)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "丢弃物品:");
	SetPanelTitle(menu, line);

	DrawPanelText(menu, "════════════════");
	
	Format(line, sizeof(line), "准备丢弃装备: \n══ [%s] ══ \n是否确认丢弃该装备?", ItemName_ZB[item]);
	DrawPanelText(menu, line);
	
	DrawPanelText(menu, "════════════════");

	DrawPanelItem(menu, "确认");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	UseZBItem[Client] = item;
	SendPanelToClient(menu, Client, MenuHandler_ItemZBDrop, MENU_TIME_FOREVER);
	CloseHandle(menu);
}
public MenuHandler_ItemZBDrop(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (param == 1)
		{
			PlayerItem[Client][ITEM_ZB][UseZBItem[Client]] = 0;
			PrintHintText(Client, "════════════════ \n你已丢弃了 [%s] 装备 \n════════════════", ItemName_ZB[UseZBItem[Client]])
			CreateTimer(0.1, StatusUp, Client);
		}
	}
}

//赠送装备类道具
public MenuFunc_ItemZBGive(Client, item)
{
	decl String:line[256], String:name[64], has;
	new Handle:menu = CreateMenu(MenuHandler_ItemZBGive);
	Format(line, sizeof(line), "赠送装备类给他人: \n赠送道具:[%s]", ItemName_ZB[item]);
	SetMenuTitle(menu, line);
	has = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false) && i != Client)
		{
			has++;
			if (PlayerZBItemSize[i] - GetHasZBItemCount(i) > 0)
				Format(line, sizeof(line), "%N(剩余空间:%d个)", i, PlayerZBItemSize[i] - GetHasZBItemCount(i));
			else
				Format(line, sizeof(line), "%N(物品栏已满)", i);
				
			GetClientName(i, name, sizeof(name));
			if (PlayerZBItemSize[i] - GetHasZBItemCount(i) > 0)
				AddMenuItem(menu, name, line);
			else
				AddMenuItem(menu, name, line, ITEMDRAW_DISABLED);
		}
	}
	
	if (has <= 0)
		AddMenuItem(menu, "item0", "没有发现任何可用玩家!", ITEMDRAW_DISABLED)

	UseZBItem[Client] = item;
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}
public MenuHandler_ItemZBGive(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_ItemZBMSG(Client, UseZBItem[Client]);
	}
	if(action == MenuAction_Select)
	{
		decl String:name[64], target;
		GetMenuItem(menu, param, name, sizeof(name));
		target = GetClientForName(name);
		if (PlayerGiveItem(Client, target, ITEM_ZB, UseZBItem[Client]) == 1)
			PrintHintText(Client, "赠送成功!");
		else
			PrintHintText(Client, "赠送失败!");		
	}
}

/************************************
*	装备类道具功能
************************************/

//装备道具属性初始化
stock ResetPlayerZBData(Client, Float:Re_Speed, Re_Health, bool:Read = false)
{
	if (!IsValidPlayer(Client, false) || !IsValidEntity(Client))
		return;
		
	decl Float:f_speed, Float:f_gravity, f_health, String:text[64];

	PlayerZBIsOver(Client);
	
	if (VIP[Client] > 0 && PlayerItem[Client][ITEM_ZB][ITZB_BJXZ] == 0 && PlayerItem[Client][ITEM_ZB][ITZB_ZSXZ] == 0 && PlayerItem[Client][ITEM_ZB][ITZB_SJXZ] == 0 && PlayerItem[Client][ITEM_ZB][ITZB_ZZXZ] == 0)
	{
		if (VIP[Client] == 1)
			SetZBItemTime(Client, ITZB_BJXZ, CheckVipTimeLimit(Client));
		else if (VIP[Client] == 2)
			SetZBItemTime(Client, ITZB_ZSXZ, CheckVipTimeLimit(Client));
		else if (VIP[Client] == 3)
			SetZBItemTime(Client, ITZB_SJXZ, CheckVipTimeLimit(Client));
		else if (VIP[Client] == 4)
			SetZBItemTime(Client, ITZB_ZZXZ, CheckVipTimeLimit(Client));
	}
	else if (PlayerItem[Client][ITEM_ZB][ITZB_BJXZ] > 0 || PlayerItem[Client][ITEM_ZB][ITZB_ZSXZ] > 0 || PlayerItem[Client][ITEM_ZB][ITZB_SJXZ] > 0 || PlayerItem[Client][ITEM_ZB][ITZB_ZZXZ] > 0)
	{
		if (VIP[Client] <= 0)
		{
			SetZBItemTime(Client, ITZB_BJXZ, 0);
			SetZBItemTime(Client, ITZB_ZSXZ, 0);
			SetZBItemTime(Client, ITZB_SJXZ, 0);
			SetZBItemTime(Client, ITZB_ZZXZ, 0);
		}
	}
	
	f_speed = 0.0;
	f_gravity = 0.0;
	f_health = 0;
	ZB_Healing[Client] = 0;	
	ZB_EndEffect[Client] = 0.0;
	ZB_FireEnd[Client] = 0.0;
	ZB_GunDmg[Client] = 0.0;
	ZB_MPBuffer[Client] = 0
	ZB_GunSpeed[Client] = 0.0;
	
	//VIP勋章属性
	if (GetZBItemTime(Client, ITZB_ZZXZ) > 0)
		f_speed += 0.2,    //速度
		ZB_GunSpeed[Client] += 0.2;   //攻击力
	if (GetZBItemTime(Client, ITZB_SJXZ) > 0)
		f_speed += 0.15,    //速度
		ZB_GunSpeed[Client] += 0.15;   //攻击力
	if (GetZBItemTime(Client, ITZB_ZSXZ) > 0)
		f_speed += 0.1,   //速度
		ZB_GunSpeed[Client] += 0.1;   //攻击力
	if (GetZBItemTime(Client, ITZB_BJXZ) > 0)
		f_speed += 0.05,   //速度
		ZB_GunSpeed[Client] += 0.05;   //攻击力
	
	
	//春哥套装
	if (GetZBItemTime(Client, ITZB_KXTZ) > 0)
	{
		f_speed += 0.4;              //速度
		f_gravity += 0.6;            //跳跃
		ZB_GunDmg[Client] += 0.8;          //攻击速度
		ZB_GunSpeed[Client] += 0.5;	                 //攻击力
		ZB_Healing[Client] += 50;          //每秒回复HP
	//	ZB_EndEffect[Client] += 0.8;           //防御
		f_health += 3000;                //生命值
		ZB_MPBuffer[Client] += 130000;              //魔法值
		ZB_FireEnd[Client] += 0.80;            //减少火焰伤害
	}
	
	//冥火之拥
	if (GetZBItemTime(Client, ITZB_SQ_AH) > 0)
	{
		f_speed += 0.1;        //加速度
		f_gravity += 0.08;        //加跳跃
		ZB_GunDmg[Client] += 0.16;      //加攻击速度
		ZB_GunSpeed[Client] += 0.05;	   //攻击力
		ZB_Healing[Client] += 6;      //每秒回复HP
	//	ZB_EndEffect[Client] += 0.1;		    //加防御
	//	f_health += 500;            //加HP
		ZB_MPBuffer[Client] += 20000;        //加MP
		ZB_FireEnd[Client] += 0.12;      //减少火焰伤害
	}	
	
	//霸王血铠
	if (GetZBItemTime(Client, ITZB_TYZSTZ) > 0)
	{
		f_speed += 0.12;                 //速度
		f_gravity += 0.16;                 //跳跃
		ZB_GunDmg[Client] += 0.32;                 //攻击速度
		ZB_GunSpeed[Client] += 0.1;	                 //攻击力
		ZB_Healing[Client] += 12;                 //每秒回复HP
	//	ZB_EndEffect[Client] += 0.3;                 //防御
	//	f_health += 800;                 //生命值
		ZB_MPBuffer[Client] += 40000;                 //魔法值
		ZB_FireEnd[Client] += 0.24;                 //减少火焰伤害
	}
		
	//兰顿之兆
	if (GetZBItemTime(Client, ITZB_TYZSQT) > 0)
	{
		f_speed += 0.13;                 //速度
		f_gravity += 0.24;                 //跳跃
		ZB_GunDmg[Client] += 0.48;                //攻击速度
		ZB_GunSpeed[Client] += 0.15;		                 //攻击力
		ZB_Healing[Client] += 18;                //每秒回复HP
	//	ZB_EndEffect[Client] += 0.5;                //防御
	//	f_health += 1000;                 //生命值
		ZB_MPBuffer[Client] += 60000;                //魔法值
		ZB_FireEnd[Client] += 0.36;                //减少火焰伤害
	}
			
	//狂徒铠甲
	if (GetZBItemTime(Client, ITZB_TYZSWTZ) > 0)
	{
		f_speed += 0.14;               //速度
		f_gravity += 0.32;                //跳跃
		ZB_GunDmg[Client] += 0.64;              //攻击速度
		ZB_GunSpeed[Client] += 0.2;		                 //攻击力
		ZB_Healing[Client] += 24;               //每秒回复HP
	//	ZB_EndEffect[Client] += 0.65;               //防御
	//	f_health += 1100;                  //生命值
		ZB_MPBuffer[Client] += 80000;                //魔法值
		ZB_FireEnd[Client] += 0.48;                //减少火焰伤害
	}
	
	//三相之力
	if (GetZBItemTime(Client, ITZB_TYZSEM) > 0)
	{
		f_speed += 0.15;               //速度
		f_gravity += 0.4;              //跳跃
		ZB_GunDmg[Client] += 0.8;            //攻击速度
		ZB_GunSpeed[Client] += 0.25;	                 //攻击力
		ZB_Healing[Client] += 30;             //每秒回复HP
	//	ZB_EndEffect[Client] += 0.5;             //防御
	//	f_health += 1300;                 //生命值
		ZB_MPBuffer[Client] += 100000;               //魔法值
		ZB_FireEnd[Client] += 0.60;             //减少火焰伤害
	}
	
	//HP恢复比率
	if (GetZBItemTime(Client, ITZB_ZRZYJZ) > 0)
		ZB_Healing[Client] += 40;
	if (GetZBItemTime(Client, ITZB_JSZYJZ) > 0)
		ZB_Healing[Client] += 30;
	if (GetZBItemTime(Client, ITZB_JPZYJZ) > 0)
		ZB_Healing[Client] += 20;	
	if (GetZBItemTime(Client, ITZB_GJZYJZ) > 0)
		ZB_Healing[Client] += 10;
	if (GetZBItemTime(Client, ITZB_ZJZYJZ) > 0)	//
		ZB_Healing[Client] += 5;
	if (GetZBItemTime(Client, ITZB_DJZYJZ) > 0)  //
		ZB_Healing[Client] += 3;
	
	//生命值  
	if (GetZBItemTime(Client, ITZB_DJSMZD) > 0)
		f_health += 40;
	if (GetZBItemTime(Client, ITZB_ZJSMZD) > 0)
		f_health += 100;	
	if (GetZBItemTime(Client, ITZB_GJSMZD) > 0)
		f_health += 200;
	if (GetZBItemTime(Client, ITZB_JPSMZD) > 0)
		f_health += 300;
	if (GetZBItemTime(Client, ITZB_JRSMZD) > 0)
		f_health += 400;
	
	//枪械攻击力  
	if (GetZBItemTime(Client, ITZB_DJGLDY) > 0)
		ZB_GunDmg[Client] += 0.03;	
	if (GetZBItemTime(Client, ITZB_ZJGLDY) > 0)
		ZB_GunDmg[Client] += 0.03;
	if (GetZBItemTime(Client, ITZB_GJGLDY) > 0)
		ZB_GunDmg[Client] += 0.07;
	if (GetZBItemTime(Client, ITZB_JPGLDY) > 0)
		ZB_GunDmg[Client] += 0.10;
	if (GetZBItemTime(Client, ITZB_HSGLDY) > 0)
		ZB_GunDmg[Client] += 0.10;
	if (GetZBItemTime(Client, ITZB_YHGLDY) > 0)
		ZB_GunDmg[Client] += 0.15;
	if (GetZBItemTime(Client, ITZB_ZHGLDY) > 0)
		ZB_GunDmg[Client] += 0.15;
	if (GetZBItemTime(Client, ITZB_RYGLDY) > 0)
		ZB_GunDmg[Client] += 0.23;
	if (GetZBItemTime(Client, ITZB_HYGLDY) > 0)
		ZB_GunDmg[Client] += 0.20;
	if (GetZBItemTime(Client, ITZB_YXGLDY) > 0)
		ZB_GunDmg[Client] += 0.30;

	//魔力上限  
	if (GetZBItemTime(Client, ITZB_DJMLJL) > 0)
		ZB_MPBuffer[Client] += 10000;	
	if (GetZBItemTime(Client, ITZB_ZJMLJL) > 0)
		ZB_MPBuffer[Client] += 20000;
	if (GetZBItemTime(Client, ITZB_GJMLJL) > 0)
		ZB_MPBuffer[Client] += 30000;
	if (GetZBItemTime(Client, ITZB_JPMLJL) > 0)
		ZB_MPBuffer[Client] += 50000;
	if (GetZBItemTime(Client, ITZB_JPMLJE) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJR) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJT) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJY) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJU) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJI) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJO) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJP) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJA) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJS) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJD) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJF) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJG) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJH) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJJ) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJK) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJZ) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJC) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJA) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJW) > 0)
		ZB_MPBuffer[Client] += 0;
	if (GetZBItemTime(Client, ITZB_JPMLJE) > 0)
		ZB_MPBuffer[Client] += 0;
		
		

	//if (GetZBItemTime(Client, ITZB_XLD) > 0)
	//    ZB_Healing[Client] += 20;	
		
	/*移动速度
	if (GetZBItemTime(Client, ITZB_DJGBXZ) > 0)
		f_speed += 0.03;
	if (GetZBItemTime(Client, ITZB_ZJGBXZ) > 0)
		f_speed += 0.08;
	if (GetZBItemTime(Client, ITZB_GJGBXZ) > 0)
		f_speed += 0.12;
	if (GetZBItemTime(Client, ITZB_JPGBXZ) > 0)
		f_speed += 0.16;
	
	跳跃跳跃
	if (GetZBItemTime(Client, ITZB_YXZY) > 0)
		f_gravity += 0.3;
	if (GetZBItemTime(Client, ITZB_GZY) > 0)
		f_gravity += 0.5;
	if (GetZBItemTime(Client, ITZB_SY) > 0)
		f_gravity += 0.8;
	*/	
		
	/*防御力
	if (GetZBItemTime(Client, ITZB_DJJGHJ) > 0)
		ZB_EndEffect[Client] += 0.05;
	if (GetZBItemTime(Client, ITZB_ZJJGHJ) > 0)
		ZB_EndEffect[Client] += 0.1;
	if (GetZBItemTime(Client, ITZB_JPJGHJ) > 0)
		ZB_EndEffect[Client] += 0.20;	
         		

	火焰抗性
	if (GetZBItemTime(Client, ITZB_DJHYFY) > 0)
		ZB_FireEnd[Client] += 0.05;
	if (GetZBItemTime(Client, ITZB_ZJHYFY) > 0)
		ZB_FireEnd[Client] += 0.1;
	if (GetZBItemTime(Client, ITZB_GJHYFY) > 0)
		ZB_FireEnd[Client] += 0.15;
	if (GetZBItemTime(Client, ITZB_JPHYFY) > 0)
		ZB_FireEnd[Client] += 0.2;
	if (GetZBItemTime(Client, ITZB_SQ_HFHZY) > 0)
		ZB_FireEnd[Client] += 0.5;
	*/	
	

	/*枪械射速
	if (GetZBItemTime(Client, ITZB_DJGZQT) > 0)
		ZB_GunSpeed[Client] += 0.01;	
	if (GetZBItemTime(Client, ITZB_ZJGZQT) > 0)
		ZB_GunSpeed[Client] += 0.02;	
	if (GetZBItemTime(Client, ITZB_GJGZQT) > 0)
		ZB_GunSpeed[Client] += 0.03;	
	if (GetZBItemTime(Client, ITZB_JPGZQT) > 0)
		ZB_GunSpeed[Client] += 0.04;			
		
	//钢铁之躯	
	if (GetZBItemTime(Client, ITZB_SQ_GTZQ) > 0)
	{
		ZB_Healing[Client] += 5;
		ZB_EndEffect[Client] += 0.1;
		f_health += 200;
	}
	
	//巫师飞行装
	if (GetZBItemTime(Client, ITZB_SQ_QYZQ) > 0)
	{
		f_speed += 0.15;
		f_gravity += 0.15;
	}	
	
	巫师攻击装
	if (GetZBItemTime(Client, ITZB_SQ_KBZQ) > 0)
	{
		ZB_GunDmg[Client] += 0.5;
		ZB_GunSpeed[Client] += 0.5;	
	}	
		
	古代战神宙斯之头盔
	if (GetZBItemTime(Client, ITZB_TYZSTK) > 0)   //加MP值
	{
		ZB_MPBuffer[Client] += 150000;
	}	
		
	//古代战神宙斯之铠甲
	if (GetZBItemTime(Client, ITZB_TYZSKJ) > 0)   //加防御
	{
		ZB_EndEffect[Client] += 0.50;
	}	
		
	//古代战神宙斯之腰带
	if (GetZBItemTime(Client, ITZB_TYZSKZ) > 0)   //加跳跃
	{
		f_gravity += 0.65;
	}	
		
	//古代战神宙斯之靴子
	if (GetZBItemTime(Client, ITZB_TYZSXZ) > 0)   //加速度
	{
		f_speed += 0.65
	}	
		
	//古代战神宙斯之面罩
	if (GetZBItemTime(Client, ITZB_TYZSXL) > 0)   //每秒回复HP值
	{
		ZB_Healing[Client] += 50;
	}	
		
	//古代战神宙斯之雷电
	if (GetZBItemTime(Client, ITZB_TYZSWQ) > 0)   //加攻击力
	{
		ZB_GunSpeed[Client] += 0.80;
	}	
		
	//古代战神宙斯之戒指
	if (GetZBItemTime(Client, ITZB_TYZSMD) > 0)   //加HP
	{
		f_health += 1300;
	}		
	*/
	
	/*新手套装
	if (GetZBItemTime(Client, ITZB_XSTZ) > 0)
	{
		f_speed += 0.7;              //速度
		f_gravity += 0.8;            //跳跃
		ZB_GunDmg[Client] += 0.8;          //攻击速度
		ZB_GunSpeed[Client] += 0.8;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.8;           //防御
		f_health += 3000;                //生命值
		ZB_MPBuffer[Client] += 180000;              //魔法值
		ZB_FireEnd[Client] += 0.90;            //减少火焰伤害
	}
	*/
	
	/*
	//精灵套装    速度+40%   跳跃+50%    攻击速度+50%    攻击+40%    治疗+80   防御+30%   生命+600   MP+5w   火焰伤害-40%
	if (GetZBItemTime(Client, ITZB_DMXYZL) > 0){
		f_speed += 0.4;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.4;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.3;           //防御
		f_health += 600;                //生命值
		ZB_MPBuffer[Client] += 50000;              //魔法值
		ZB_FireEnd[Client] += 0.40;            //减少火焰伤害
	}
	//士兵套装 速度+40%   跳跃+50%    攻击速度+50%    攻击+60%    治疗+80   防御+50%   生命+600   MP+5w   火焰伤害-40%
	if (GetZBItemTime(Client, ITZB_AYLS) > 0){
		f_speed += 0.4;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.6;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.5;           //防御
		f_health += 600;                //生命值
		ZB_MPBuffer[Client] += 50000;              //魔法值
		ZB_FireEnd[Client] += 0.40;            //减少火焰伤害
	}
	//生物专家套装 速度+40%   跳跃+50%    攻击速度+50%    攻击+60%    治疗+80   防御+60%   生命+900   MP+5w   火焰伤害-40%
	if (GetZBItemTime(Client, ITZB_WLYS) > 0){
		f_speed += 0.4;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.6;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.6;           //防御
		f_health += 900;                //生命值
		ZB_MPBuffer[Client] += 50000;              //魔法值
		ZB_FireEnd[Client] += 0.40;            //减少火焰伤害
	}
	//医师套装 速度+60%   跳跃+50%    攻击速度+50%    攻击+70%    治疗+100   防御+50%   生命+600   MP+8w   火焰伤害-40%
	if (GetZBItemTime(Client, ITZB_ZXZZ) > 0){
		f_speed += 0.6;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.7;	                 //攻击力
		ZB_Healing[Client] += 100;          //每秒回复HP
		ZB_EndEffect[Client] += 0.5;           //防御
		f_health += 600;                //生命值
		ZB_MPBuffer[Client] += 80000;              //魔法值
		ZB_FireEnd[Client] += 0.40;            //减少火焰伤害
	}	
	//魔法师套装 速度+40%   跳跃+50%    攻击速度+50%    攻击+60%    治疗+80   防御+50%   生命+600   MP+10w   火焰伤害-40%
	if (GetZBItemTime(Client, ITZB_YGWL) > 0){
		f_speed += 0.4;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.6;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.5;           //防御
		f_health += 600;                //生命值
		ZB_MPBuffer[Client] += 100000;              //魔法值
		ZB_FireEnd[Client] += 0.40;            //减少火焰伤害
	}	
	//弹药专家套装 速度+60%   跳跃+50%    攻击速度+50%    攻击+70%    治疗+80   防御+70%   生命+1000   MP+10w   火焰伤害-60%
	if (GetZBItemTime(Client, ITZB_DY) > 0){
		f_speed += 0.6;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.5;          //攻击速度
		ZB_GunSpeed[Client] += 0.7;	                 //攻击力
		ZB_Healing[Client] += 80;          //每秒回复HP
		ZB_EndEffect[Client] += 0.7;           //防御
		f_health += 1000;                //生命值
		ZB_MPBuffer[Client] += 100000;              //魔法值
		ZB_FireEnd[Client] += 0.60;            //减少火焰伤害
	}	
	//雷神套装 速度+60%   跳跃+50%    攻击速度+70%    攻击+60%    治疗+100   防御+50%   生命+800   MP+10w   火焰伤害-60%
	if (GetZBItemTime(Client, ITZB_LS) > 0){
		f_speed += 0.6;              //速度
		f_gravity += 0.5;            //跳跃
		ZB_GunDmg[Client] += 0.7;          //攻击速度
		ZB_GunSpeed[Client] += 0.6;	                 //攻击力
		ZB_Healing[Client] += 100;          //每秒回复HP
		ZB_EndEffect[Client] += 0.5;           //防御
		f_health += 800;                //生命值
		ZB_MPBuffer[Client] += 100000;              //魔法值
		ZB_FireEnd[Client] += 0.60;            //减少火焰伤害
	}
	*/
	//属性上限
	if (ZB_FireEnd[Client] > 0.99)
		ZB_FireEnd[Client] = 0.99;
	if (ZB_GunSpeed[Client] > 1.0)
		ZB_GunSpeed[Client] = 1.0;	
	if (ZB_EndEffect[Client] > 0.99)
		ZB_EndEffect[Client] = 0.99;	
	if (1.0 - f_gravity < 0.2)
		f_gravity = 0.8;		
		
	//属性设置
	if (f_speed + Re_Speed > Re_Speed)
		SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", Re_Speed + f_speed);
	if (f_gravity > 0)		
		SetEntityGravity(Client, 1.0 - f_gravity);
	if (f_health + Re_Health > Re_Health)
		SetEntProp(Client, Prop_Data, "m_iMaxHealth", Re_Health + f_health);
		

	//属性查看
	if (Read)
	{
		new Handle:menu = CreateMenu(MenuHandler_ItemDisData);
		SetMenuTitle(menu, "查看所有装备属性:");
		Format(text, sizeof(text), "生命加成:%d/%d", f_health, Limit_ZB_Health);
		AddMenuItem(menu, "item0", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "防御加成:%.0f％/%.0f％", ZB_EndEffect[Client] * 100.0, Limit_ZB_End * 100.0);
		AddMenuItem(menu, "item1", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "移动速度:%.0f％/%.0f％", f_speed * 100.0, Limit_ZB_Speed * 100.0);
		AddMenuItem(menu, "item2", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "生命恢复:%d/%d", ZB_Healing[Client], Limit_ZB_Healing);
		AddMenuItem(menu, "item3", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "跳跃跳跃:%.0f％/%.0f％", f_gravity * 100.0, Limit_ZB_Jump * 100.0);
		AddMenuItem(menu, "item4", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "火焰抗性:%.0f％/%.0f％", ZB_FireEnd[Client] * 100.0, Limit_ZB_FireEnd * 100.0);
		AddMenuItem(menu, "item5", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "枪械伤害:%.0f％/%.0f％", ZB_GunDmg[Client] * 100.0, Limit_ZB_GunDmg * 100.0);
		AddMenuItem(menu, "item6", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "魔力上限:%d/%d", ZB_MPBuffer[Client], Limit_ZB_MPBuffer);
		AddMenuItem(menu, "item7", text, ITEMDRAW_DISABLED);
		Format(text, sizeof(text), "枪械射速:%.0f％/%.0f％", ZB_GunSpeed[Client] * 100.0, Limit_ZB_GunSpeed * 100.0);
		AddMenuItem(menu, "item8", text, ITEMDRAW_DISABLED);
		SetMenuPagination(menu, MENU_NO_PAGINATION);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
	}
}

//查看所有属性面板回调
public MenuHandler_ItemDisData(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_MyItem(Client);
	}
}

//装备到期检查
public PlayerZBIsOver(Client)
{
	for (new i; i < ITEM_ZB_MAX; i++)
	{
		if (GetZBItemTime(Client, i) <= 0)
			PlayerItem[Client][ITEM_ZB][i] = 0;
	}
}
/*******************************************************************************************
*								装备类物品功能_结束
*******************************************************************************************/

/*══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════*/

/*******************************************************************************************
*								道具系统_其他功能_开始
*******************************************************************************************/

/* 取装备剩余时间 */
public GetZBItemTime(Client, item)
{
	if (PlayerItem[Client][ITEM_ZB][item] > 0)
	{
		new String:s_itemtime[16];
		new String:s_itemyear[16];
		new String:s_itemday[16];
		new i_itemyear;
		new i_itemday;
		new year = GetThisYear();
		new today = GetToday();
		new maxday = GetThisYearMaxDay();
		new last;
		
		IntToString(PlayerItem[Client][ITEM_ZB][item], s_itemtime, sizeof(s_itemtime));
		
		s_itemyear[0] = s_itemtime[0];
		s_itemyear[1] = s_itemtime[1];
		s_itemyear[2] = s_itemtime[2];
		s_itemyear[3] = s_itemtime[3];
		s_itemday[0]  = s_itemtime[4];
		s_itemday[1]  = s_itemtime[5];
		s_itemday[2]  = s_itemtime[6];
		
		i_itemyear = StringToInt(s_itemyear);
		i_itemday = StringToInt(s_itemday);	
		
		if (i_itemyear > 0 && i_itemday > 0)
		{
			if (year == i_itemyear)
			{
				last = i_itemday - today;
				if (last > 0)
					return last;
				else
					return 0;
			}
			else if (i_itemyear > year)
			{
				new moreyear = i_itemyear - year;
				new moreday = maxday - today;
				
				for (new i = 1; i < moreyear; i++)
					moreday += GetThisYearMaxDay(year + i);
				
				last = moreday + i_itemday;
				
				if (last > 0)
					return last;
				else
					return 0;
			}
			else
				return 0;
		}
	}
	
	return 0;
}

/* 给予装备类道具 */
stock SetZBItemTime(Client, item, day, bool:Print = true, bool:Superimposed = true)
{
	new year = GetThisYear();
	new today = GetToday();
	new maxday = GetThisYearMaxDay();
	new String:s_year[16];
	new String:s_day[16];
	new String:s_time[16];
	new i_time;
	if (IsValidPlayer(Client, false))
	{
		if (day <= 0)
			PlayerItem[Client][ITEM_ZB][item] = 0;
		else
		{
			new i_day = today + day;
			new de_day = GetZBItemTime(Client, item);
			if (de_day > 0)
			{
				if (Superimposed)
					i_day += de_day;
			}
				
			if (i_day <= maxday)
			{
				IntToString(year, s_year, sizeof(s_year));
				IntToString(i_day, s_day, sizeof(s_day));
				Format(s_time, sizeof(s_time), "%s%s", s_year, s_day);
				i_time = StringToInt(s_time);
				if (i_time > 10)
				{
					PlayerItem[Client][ITEM_ZB][item] = i_time;
					CreateTimer(0.1, StatusUp, Client);
					if (Print)
						CPrintToChatAll("\x03[道具] {red}%N \x03获得了 {red}[%s(%d天)]", Client, ItemName_ZB[item], day);
				}
			}
			else
			{
				new moreday = i_day - maxday;
				new moreyear = year + 1;
				new nextyearmaxday = GetThisYearMaxDay(moreyear);
				
				while (moreday - nextyearmaxday > 0)
				{
					moreday = moreday - nextyearmaxday;
					moreyear += 1;
					nextyearmaxday = GetThisYearMaxDay(moreyear);
				}
				
				IntToString(moreyear, s_year, sizeof(s_year));
				IntToString(moreday, s_day, sizeof(s_day));
				Format(s_time, sizeof(s_time), "%s%s", s_year, s_day);
				i_time = StringToInt(s_time);
				if (i_time > 10)
				{
					PlayerItem[Client][ITEM_ZB][item] = i_time;
					CreateTimer(0.1, StatusUp, Client);
					if (Print)
						CPrintToChatAll("\x03[道具] {red}%N \x03获得了 {red}[%s(%d天)]", Client, ItemName_ZB[item], day);
				}					
			}
		}
	}
}

/* 格式化装备时间文本 */
stock String:ForStringZBTime(Client, item)
{
	decl String:Time[8], String:s_year[4], String:s_day[3], i_day;
	IntToString(PlayerItem[Client][ITEM_ZB][item], Time, sizeof(Time));
	s_year[0] = Time[0];
	s_year[1] = Time[1];
	s_year[2] = Time[2];
	s_year[3] = Time[3];
	s_day[0] = Time[4];
	s_day[1] = Time[5];
	s_day[2] = Time[6];
	Time[7] = 0;
	i_day = StringToInt(s_day);
	if (i_day > 99)
		return Time;
	else if (i_day <= 9)
	{
		if (s_day[0] != '0')
		{
			Time[4] = '0';
			Time[5] = '0';
			Time[6] = s_day[0];
			return Time;
		}
		else
			return Time;
	}
	else
	{
		if (s_day[0] != '0')
		{
			Time[4] = '0';
			Time[5] = s_day[0];
			Time[6] = s_day[1];
			return Time;
		}
		else
			return Time;
	}
}

/* 获取拥有的装备数量 */
public GetHasZBItemCount(Client)
{
	new count;
	for (new i; i < ITEM_ZB_MAX; i++)
	{
		if (GetZBItemTime(Client, i) > 0)
			count++;
	}
	
	return count;
}

//消耗物品栏扩充
public BuyXHItemBag(Client)
{
	if (IsValidPlayer(Client, false) && Cash[Client] >= XH_COSTEFFECT[Client])
	{
		Cash[Client] -= XH_COSTEFFECT[Client];
		PlayerXHItemSize[Client] += 1;
		PrintHintText(Client, "════════════════ \n消耗物品栏已成功扩充一格,当前总空间为 %d 格! \n════════════════", PlayerXHItemSize[Client]);
	}
}

//装备物品栏扩充
public BuyZBItemBag(Client)
{
	if (IsValidPlayer(Client, false) && Cash[Client] >= ZB_COSTEFFECT[Client])
	{
		Cash[Client] -= ZB_COSTEFFECT[Client];
		PlayerZBItemSize[Client] += 1;
		PrintHintText(Client, "════════════════ \n装备物品栏已成功扩充一格,当前总空间为 %d 格! \n════════════════", PlayerZBItemSize[Client]);
	}
}

//取玩家所有道具数
public GetPlayerAllItemCount(Client)
{
	new count;
	for (new o; o < 2; o++)
	{
		for(new p; p < MaxItemNum[o]; p++)
			count += PlayerItem[Client][o][p];	
	}
	
	return count;
}

//取玩家消耗类物品总数
public GetHasXHItemCount(Client)
{
	new count;
	for(new p; p < MaxItemNum[ITEM_XH]; p++)
		count += PlayerItem[Client][ITEM_XH][p];	

	return count;
}

//名字获取道具的ID
public GetItemID(String:name[], type)
{
	new id;
	for (new i; i < MaxItemNum[type]; i++)
	{
		if (type == ITEM_XH)
		{
			if (StrContains(name, ItemName_XH[i], false) >= 0)
			{
				id = i;
				break;
			}
		}
		else if (type == ITEM_ZB)
		{
			if (StrContains(name, ItemName_ZB[i], false) >= 0)
			{
				id = i;
				break;
			}
		}
	}
	
	return id;
}

/* 我的道具快捷指令 */
public Action:Command_MyItem(Client, args)
{
	if (!IsValidPlayer(Client, false))
		return Plugin_Handled;
		
	MenuFunc_MyItem(Client);
	
	return Plugin_Handled;
}

/* 设置装备快捷指令 */
public Action:Command_SetItem(Client, args)
{
	if (args < 3)
	{
		for (new i; i < ITEM_ZB_MAX; i++)
			ReplyToCommand(Client, "[道具] 装备类ID: %d 物品: %s", i, ItemName_ZB[i]);
			
		for (new i; i < ITEM_XH_MAX; i++)
			ReplyToCommand(Client, "[道具] 消耗类ID: %d 物品: %s", i, ItemName_XH[i]);
		
		ReplyToCommand(Client, "[道具] 命令:sm_setitem [Name] [Type] [Item] [Num]");
		return Plugin_Handled;
	}
		
	decl String:s_name[64], String:s_type[16], String:s_item[16], String:s_day[16], String:Temp[64], target, i_type, i_item, i_day;
	
	GetCmdArg(1, s_name, sizeof(s_name));
	GetCmdArg(2, s_type, sizeof(s_type));
	GetCmdArg(3, s_item, sizeof(s_item));
	i_type = StringToInt(s_type);
	i_item = StringToInt(s_item);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false))
		{
			GetClientName(i, Temp, sizeof(Temp));
			if (StrEqual(s_name, Temp))
			{
				target = i;
				break;
			}
		}
	}
	
	if (!IsValidPlayer(target, false))
	{
		ReplyToCommand(Client, "[道具] 无效的玩家!");
		return Plugin_Handled;	
	}
	
	Format(Temp, sizeof(Temp), "你收到来自管理员送来的礼物:");
	if (args > 3)
	{
		GetCmdArg(4, s_day, sizeof(s_day));
		i_day = StringToInt(s_day);
		if (i_type == 0)
		{
			if (PlayerXHItemSize[target] - GetHasXHItemCount(target) <= 0 && target != Client)
			{
				ReplyToCommand(Client, "[道具] %N 的消耗类物品栏已满.", target);
				return Plugin_Handled;
			}		
		
			if (PlayerZBItemSize[target] - GetHasZBItemCount(target) <= 0 && target != Client)
			{
				ReplyToCommand(Client, "[道具] %N 的消耗类物品栏已满.", target);
				return Plugin_Handled;
			}
			PlayerItem[target][ITEM_XH][i_item] = i_day;
			ReplyToCommand(Client, "[道具] %N 获得了 [%s](%d个)", target, ItemName_XH[i_item], i_day);
			if (target != Client)
				MenuFunc_GotItemMSG(target, ITEM_XH, i_item, i_day, Temp), CPrintToChatAll("\x03[道具] {red}%N \x03收到了来自管理员送的 {green}[%s(%d个)]", target, ItemName_XH[i_item], i_day);
				
		}
		else if (i_type == 1)
		{
			if (PlayerZBItemSize[target] - GetHasZBItemCount(target) <= 0 && target != Client)
			{
				ReplyToCommand(Client, "[道具] %N 的消耗类物品栏已满.", target);
				return Plugin_Handled;
			}
			
			SetZBItemTime(target, i_item, i_day, false, false);
			ReplyToCommand(Client, "[道具] %N 获得了 [%s](%d天)", target, ItemName_ZB[i_item], i_day);
			if (target != Client)
				MenuFunc_GotItemMSG(target, ITEM_ZB, i_item, i_day, Temp), CPrintToChatAll("\x03[道具] {red}%N \x03收到了来自管理员送的 {green}[%s(%d天)]", target, ItemName_ZB[i_item], i_day);
		}
	}
	else
	{
		if (i_type == 0)
		{
			i_day = PlayerItem[target][ITEM_XH][i_item];
			ReplyToCommand(Client, "[道具] %N 拥有 [%s](%d个)", target, ItemName_XH[i_item], i_day);
		}
		else if (i_type == 1)
		{
			i_day = GetZBItemTime(target, i_item);
			ReplyToCommand(Client, "[道具] %N 拥有 [%s](%d天)", target, ItemName_ZB[i_item], i_day);
		}	
	}
	

	return Plugin_Handled;
}



/* 道具系统全部数据重置 */
public ResetAllItemData()
{
	IsActionQTSXJ = false;
	IsActionQTHDJ = false;
	IsActionWXZDJ = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		UseXHItem[i] = -1;
		UseZBItem[i] = -1;
	}
}

/* 获取随机有效幸存者 */
public Item_GetRandomSurvivor(type)
{
	new Handle:array;
	array = CreateArray(1, 0);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidPlayer(i, false, false) || GetClientTeam(i) != 2 || !IsPasswordConfirm[i])
			continue;
		if (type == 0)
		{
			if (PlayerXHItemSize[i] - GetHasXHItemCount(i) <= 0)
				continue;
		}
		else if (type == 1)
		{
			if (PlayerXHItemSize[i] - GetHasZBItemCount(i) <= 0)
				continue;
		}
		
		PushArrayCell(array, i);
	}
	
	if (GetArraySize(array) <= 0)
		return 0;
	
	new maxsize = GetArraySize(array) - 1;
	new clientNum = GetArrayCell(array, GetRandomInt(0, maxsize));
	return clientNum;
}

/* 刷新道具装备店物品 */
public RefreshItemBuyData()
{
	new Float:Radio_Item = GetRandomFloat(0.0, 100.0);
	new bool:isok = false;
	new i_type = GetRandomInt(0, 1);
	if (Radio_Item < ItemBuyRadio[i_type])
	{
		new Float:i_item = GetRandomFloat(0.0, 100.0);
		new chose;
		if (i_type == ITEM_XH)
		{
			chose = GetRandomInt(0, ITEM_XH_MAX - 1);
			if (i_item <= Item_XH_Radio[chose])
			{
				new Float:r_max = GetRandomFloat(0.0, 100.0)
				new needcash = GetRandomInt(5000, 15000);
				new num;
				if (r_max < 1.0)
					num = GetRandomInt(10, 20);
				else if (r_max < 10.0)
					num = GetRandomInt(5, 10);
				else if (r_max < 50.0)
					num = GetRandomInt(3, 8);
				else if (r_max < 80.0)
					num = GetRandomInt(4, 7);
				else if (r_max < 100.0)
					num = GetRandomInt(1, 4);
					
				ItemBuy_Type = ITEM_XH;
				ItemBuy_Item = chose;
				ItemBuy_Num = num;
				ItemBuy_Cash = needcash;
				isok = true;
			}
		}
		else if (i_type == ITEM_ZB)
		{
			chose = GetRandomInt(0, ITEM_ZB_MAX - 1);
			if (i_item <= Item_ZB_Radio[chose])
			{
				new Float:r_day = GetRandomFloat(0.0, 100.0)
				new num;
				new needcash;
				if (r_day < 1.0)
					num = GetRandomInt(15, 30), needcash = GetRandomInt(300000, 500000);
				else if (r_day < 3.0)
					num = GetRandomInt(10, 15), needcash = GetRandomInt(200000, 250000);
				else if (r_day < 5.0)
					num = GetRandomInt(7, 10), needcash = GetRandomInt(150000, 200000);
				else if (r_day < 10.0)
					num = GetRandomInt(5, 7), needcash = GetRandomInt(80000, 150000);
				else if (r_day < 30.0)
					num = GetRandomInt(3, 5), needcash = GetRandomInt(30000, 100000);
				else if (r_day < 100.0)
					num = GetRandomInt(1, 3), needcash = GetRandomInt(10000, 50000);
					
				ItemBuy_Type = ITEM_ZB;
				ItemBuy_Item = chose;
				ItemBuy_Num = num;
				ItemBuy_Cash = needcash;
				isok = true;
			}
		}
	}
	
	if (!isok)
	{
		ItemBuy_Type = -1;
		ItemBuy_Item = -1;
		ItemBuy_Num = 0;
		ItemBuy_Cash = 0;	
	}
}

/* 物品掉落(type 0 = 消耗类 1 = 装备类) */
stock DropRandomItem(Float:Radio, type)
{
	new Float:Random_A = GetRandomFloat(0.0, 100.0);
	new Chose;
	new Player = Item_GetRandomSurvivor(type);
	if (IsValidPlayer(Player))
	{
		if (Random_A < Radio)
		{
			new Float:Random_B = GetRandomFloat(0.0, 100.0);
			if (type == 0)
			{
				Chose = GetRandomInt(0, ITEM_XH_MAX - 1);
				if (Random_B <= Item_XH_Radio[Chose])
				{
					PlayerItem[Player][ITEM_XH][Chose] += 1;
					CPrintToChatAll("\x03[道具] {red}%N \x03获得了 {red}[%s(1个)]", Player, ItemName_XH[Chose]);
					MenuFunc_GotItemMSG(Player, type, Chose, 1, "你获得了一件道具:");
					EmitSoundToClient(Player, SOUND_GOTITEM);
				}
			}
			else if (type == 1)
			{
				Chose = GetRandomInt(0, ITEM_ZB_MAX - 1);
				if (Random_B <= Item_ZB_Radio[Chose])
				{
					new Float:r_day = GetRandomFloat(0.0, 100.0)
					new day;
					if (r_day < 1.0)
						day = GetRandomInt(15, 30);
					else if (r_day < 3.0)
						day = GetRandomInt(10, 15);
					else if (r_day < 5.0)
						day = GetRandomInt(7, 10);
					else if (r_day < 10.0)
						day = GetRandomInt(5, 8);
					else if (r_day < 30.0)
						day = GetRandomInt(3, 8);
					else if (r_day < 100.0)
						day = GetRandomInt(1, 6);
						
					if (day > 0)
					{
						SetZBItemTime(Player, Chose, day);			
						EmitSoundToClient(Player, SOUND_GOTITEM);
						MenuFunc_GotItemMSG(Player, type, Chose, day, "你获得了一件道具:");
					}
				}
			}
		}
	}
}

/* 赠送道具 */
public PlayerGiveItem(Client, target, type, item)
{
	if (IsValidPlayer(Client, false) && IsValidPlayer(target, false))
	{
		decl String:msg[64];
		Format(msg, sizeof(msg), "收到来自%N送来的物品:", Client);
		if (type == ITEM_XH)
		{
			if (PlayerItem[Client][ITEM_XH][item] > 0)
			{
				PlayerItem[Client][ITEM_XH][item] -= 1;
				PlayerItem[target][ITEM_XH][item] += 1;
				CPrintToChatAll("\x03[道具] {red}%N \x03将 {green}[%s](1个) {lightgreen}赠送给了 {green}%N ", Client, ItemName_XH[item], target);
				MenuFunc_GotItemMSG(target, ITEM_XH, item, 1, msg);
				return 1;
			}
		}
		else if (type == ITEM_ZB)
		{
			if (GetZBItemTime(Client, item) > 0)
			{
				new day = GetZBItemTime(Client, item);
				SetZBItemTime(Client, item, 0, false);
				SetZBItemTime(target, item, day, false);
				PlayerItem[Client][ITEM_ZB][item] = 0;
				CPrintToChatAll("\x03[道具] {red}%N \x03将 {green}[%s](%d天) {lightgreen}赠送给了 {green}%N ", Client, ItemName_ZB[item], day, target);
				MenuFunc_GotItemMSG(target, ITEM_ZB, item, day, msg);
				return 1;
			}			
		}
	}
	
	return 0;
}

/*******************************************************************************************
*								道具系统_其他功能_结束
*******************************************************************************************/