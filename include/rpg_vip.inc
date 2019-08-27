/************************************************************************
*	Vip功能
************************************************************************/

//投票变量
new vote_type;
new String:vote_mapname[64];
new String:vote_mapinfo[32];
new vip_chose[MAXPLAYERS+1];
new vote_timeout;
new vote_target;

//回蓝使用变量
new bool:UseHFMP[MAXPLAYERS+1];


/* VIP主面板 */
public Action:MenuFunc_VIP(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	VipIsOver(Client);
	new viplimit = CheckVipTimeLimit(Client);
	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1 剩余:%d天", viplimit);
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2 剩余:%d天", viplimit);
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3 剩余:%d天", viplimit);
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4 剩余:%d天", viplimit);
	SetPanelTitle(menu, line);

	DrawPanelItem(menu, "会员功能介绍");
	DrawPanelItem(menu, "购买会员方法");
	DrawPanelItem(menu, "白金会员特权");
	Format(line, sizeof(line), "补给/换图/踢人");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "黄金会员特权");
	Format(line, sizeof(line), "补给/换图/踢人/战斗机");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "水晶会员特权");
	Format(line, sizeof(line), "补给/换图/踢人/战斗机/电锯");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "至尊会员特权");
	Format(line, sizeof(line), "补给/换图/踢人/战斗机/电锯/特异功能");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIP, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIP(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPInfo(Client); //VIP功能介绍
			case 2: MenuFunc_VIPBuy(Client); //VIP购买方法
			case 3: MenuFunc_bjhy(Client); //白金会员特权
			case 4: MenuFunc_hjhy(Client); //黄金会员特权
			case 5: MenuFunc_sjhy(Client); //水晶会员特权
			case 6: MenuFunc_zzhy(Client); //至尊会员特权
			case 7: MenuFunc_RPG(Client); //返回RPG菜单
		}
	}
}

//白金会员特权
public Action:MenuFunc_bjhy(Client)
{   
	new Handle:menu = CreatePanel();
	
	decl String: line[1024];
	Format(line, sizeof(line), "军队补给");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "投票踢人/换图");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_bj, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_bj(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
                if(VIP[Client] == 1)
                {
                    MenuFunc_VIPFunction(Client); //军队补给
                } else CPrintToChat(Client, "\x05【提示】你不是白金会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 2: 
			{
                if(VIP[Client] == 1)
                {
                    MenuFunc_VIPVote(Client); //投票踢人/换图
                } else CPrintToChat(Client, "\x05【提示】你不是白金会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 3: MenuFunc_VIP(Client); //返回会员特权菜单
		}
	}
}

//黄金会员特权
public Action:MenuFunc_hjhy(Client)
{   
	new Handle:menu = CreatePanel();
	
	decl String: line[1024];
	Format(line, sizeof(line), "军队补给");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "投票踢人/换图");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "军队战斗机[暂停此特权]");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_hj, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_hj(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
                if(VIP[Client] == 2)
                {
                    MenuFunc_VIPFunction(Client); //军队补给
                } else CPrintToChat(Client, "\x05【提示】你不是黄金会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 2: 
			{
                if(VIP[Client] == 2)
                {
                    MenuFunc_VIPVote(Client); //投票踢人/换图
                } else CPrintToChat(Client, "\x05【提示】你不是黄金会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 3: 
			{
                if(VIP[Client] == 2)
                {
                    MenuFunc_VIPplayer(Client); //军队战斗机
                } else CPrintToChat(Client, "\x05【提示】你不是黄金会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 4: MenuFunc_VIP(Client); //返回会员特权菜单
		}
	}
}

//水晶会员特权
public Action:MenuFunc_sjhy(Client)
{   
	new Handle:menu = CreatePanel();
	
	decl String: line[1024];
	Format(line, sizeof(line), "军队补给");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "投票踢人/换图");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "军队战斗机[暂停此特权]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "加强电锯");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_sj, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_sj(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
                if(VIP[Client] == 3)
                {
                    MenuFunc_VIPFunction(Client); //军队补给
                } else CPrintToChat(Client, "\x05【提示】你不是水晶会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 2: 
			{
                if(VIP[Client] == 3)
                {
                    MenuFunc_VIPVote(Client); //投票踢人/换图
                } else CPrintToChat(Client, "\x05【提示】你不是水晶会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 3: 
			{
                if(VIP[Client] == 3)
                {
                    MenuFunc_VIPplayer(Client); //军队战斗机
                } else CPrintToChat(Client, "\x05【提示】你不是水晶会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 4: 
			{
                if(VIP[Client] == 3)
                {
                    MenuFunc_dianju(Client); //加强电锯
                } else CPrintToChat(Client, "\x05【提示】你不是水晶会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 5: MenuFunc_VIP(Client); //返回会员特权菜单
		}
	}
}

//至尊会员特权
public Action:MenuFunc_zzhy(Client)
{   
	new Handle:menu = CreatePanel();
	
	decl String: line[1024];
	Format(line, sizeof(line), "军队补给");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "投票踢人/换图");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "军队战斗机[暂停此特权]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "加强电锯");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "特异功能");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_zz, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_zz(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
                if(VIP[Client] == 4)
                {
                    MenuFunc_VIPFunction(Client); //军队补给
                } else CPrintToChat(Client, "\x05【提示】你不是至尊会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 2: 
			{
                if(VIP[Client] == 4)
                {
                    MenuFunc_VIPVote(Client); //投票踢人/换图
                } else CPrintToChat(Client, "\x05【提示】你不是至尊会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 3: 
			{
                if(VIP[Client] == 4)
                {
                    MenuFunc_VIPplayer(Client); //军队战斗机
                } else CPrintToChat(Client, "\x05【提示】你不是至尊会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 4: 
			{
                if(VIP[Client] == 4)
                {
                    MenuFunc_dianju(Client); //加强电锯
                } else CPrintToChat(Client, "\x05【提示】你不是至尊会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 5: 
			{
                if(VIP[Client] == 4)
                {
                    MenuFunc_Teleport(Client); //特异功能
                } else CPrintToChat(Client, "\x05【提示】你不是至尊会员无法使用!请联系op扣扣;1176195532 购买会员！");
			}
			case 6: MenuFunc_VIP(Client); //返回会员特权菜单
		}
	}
}

public  Action:MenuFunc_VIPplayer(Client)//战斗机
{   
	if(VIP[Client] >= 2)    
	{       		
		CheatCommand(Client, "sm_h", "1995");     
		CPrintToChat(Client, "\x03[系统]\04%N成功获得战斗机!", Client);	    
	} else CPrintToChat(Client, "{green}【提示】你没有使用权限!请联系op扣扣；1176195532 购买会员!");
}	

public MenuFunc_dianju(Client)//戒指
{   
	if(VIP[Client] >= 3)  
	{
	if(Cash[Client] >= 500)
	 {         
		  Cash[Client] -= 500;	    		
		  CheatCommand(Client, "give", "chainsaw");     
		  CPrintToChat(Client, "\x03[系统]\04%N成功购买!", Client);	    
	} else CPrintToChat(Client, "{green}【提示】你没有购买权限!请联系op扣扣；1176195532 购买会员!");  	
   } 
}

public MenuFunc_m60(Client)//戒指
{   
	if(VIP[Client] >= 3)  
	{
//	if(Cash[Client] >= 500)
//	 {         
//		  Cash[Client] -= 500;	    		
		  CheatCommand(Client, "give", "rifle_m60");     
		  CPrintToChat(Client, "\x03[系统]\04%N成功获取!", Client);	    
	} else CPrintToChat(Client, "{green}【提示】你没有使用权限!请联系op扣扣；1176195532 购买会员!");  	
 //  } 
}

//变身
public Action:MenuFunc_VIPplayer2(Client)
{   
	new Handle:menu = CreatePanel();
	decl String: line[1024];
	Format(line, sizeof(line), "【使用变身权限 /n如需再次变身必须在买一次！】");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "提示:每次使用200避孕套！");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "购买装备");
	//DrawPanelItem(menu, line);
	Format(line, sizeof(line), "我要变身");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_BUYPLAYER2, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_BUYPLAYER2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: BSTSGRZ(Client);
			//case 2: PLAYER(Client);
		}
	}
}
public BSTSGRZ(Client)//变身
{   
//	if(VIP[Client] == 3)  
//	{
	if(Qcash[Client] >= 200)
	 {         
		Qcash[Client] -= 200;	    		
		CheatCommand(Client, "sm_csm8899", "");     
		CPrintToChat(Client, "\x03[系统]\04%N变身特殊感染者!", Client);	    
	  } else CPrintToChat(Client, "{green}【提示】你的避孕套不足，请充值后使用!请联系op扣扣；1176195532 充值避孕套!");	
 
}

//public WY(Client)//戒指
//{   
	//if(Cash[Client] >= 0)    
	//{       
		//Cash[Client] -= 0;		
		//ServerCommand("give \"%N\" \"1\" \"5\" \"15\"", Client);       
		//CPrintToChat(Client, "\x03[系统]\04%N本商品\x05停止\x04购x05买!", Client);	    
	//} else CPrintToChat(Client, "{green}【提示】你没有足够的金钱!");
//}
//VIP功能介绍
public Action:MenuFunc_VIPInfo(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1");
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2");
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3");
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4");
	SetPanelTitle(menu, line);

	DrawPanelItem(menu, "白金VIP1");
	DrawPanelItem(menu, "黄金VIP2");
	DrawPanelItem(menu, "水晶VIP3");
	DrawPanelItem(menu, "至尊VIP4");
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPInfo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPInfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPAInfo(Client); //白金VIP1介绍
			case 2: MenuFunc_VIPBInfo(Client); //黄金VIP2介绍
			case 3: MenuFunc_VIPCInfo(Client); //水晶VIP3介绍
			case 4: MenuFunc_VIPDInfo(Client); //至尊VIP4介绍
			case 5: MenuFunc_VIP(Client); //返回VIP主面板
		}
	}
}
		
//白金会员介绍
public Action:MenuFunc_VIPAInfo(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "治疗术提升为高级治疗术,移动速度增加+5% 攻击力增加+5% \n130%双倍经验和游戏币加成,倒地死亡经验减少50％ \n商店有8折优惠,免费补给3个 装备:白金勋章 \n拥有投票踢人和个性字体颜色白色光晕轮廓.");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPAInfo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPAInfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPInfo(Client); //返回VIP主面板
		}
	}
}

//黄金会员介绍
public Action:MenuFunc_VIPBInfo(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "治疗术提升为高级治疗术,移动速度增加+10% 攻击力增加+10% \n160%双倍经验和游戏币加成,倒地死亡经验减少60％ \n商店有7折优惠,免费补给5个 装备:黄金勋章 \n拥有投票踢人,换图和个性字体颜色黄色光晕轮廓 \n可无限次使用军队战斗机.");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPBInfo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPBInfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPInfo(Client); //返回VIP主面板
		}
	}
}

//水晶会员介绍
public Action:MenuFunc_VIPCInfo(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "治疗术提升为高级治疗术,移动速度增加+15% 攻击力增加+15% \n200%双倍经验和游戏币加成,倒地死亡经验减少80％ \n商店有6折优惠,免费补给6个 装备:水晶勋章 \n拥有投票踢人,换图和个性字体颜色蓝色光晕轮廓 \n可无限次使用军队战斗机/加强电锯.");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPBInfo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPCInfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPInfo(Client); //返回VIP主面板
		}
	}
}
//至尊VIP4会员介绍
public Action:MenuFunc_VIPDInfo(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "治疗术提升为高级治疗术,,移动速度增加+20% 攻击力增加+20% \n300%经验和游戏币加成,倒地死亡经验减少90％ \n商店有5折优惠,免费补给9个 装备:至尊勋章 \n拥有投票踢人,换图和个性字体颜色绿色光晕轮廓 \n可无限次使用军队战斗机/加强电锯/特异功能.");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPDInfo, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPDInfo(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIPInfo(Client); //返回VIP主面板
		}
	}
}

//VIP购买方法
public Action:MenuFunc_VIPBuy(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1");
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2");
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3");
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "如需会员，请联系作者：恋水晶之冰囧");
	DrawPanelText(menu, line);
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPBuy, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_VIPBuy(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1: MenuFunc_VIP(Client); //返回VIP主面板
		}
	}
}

//使用VIP功能
public Action:Command_VIP(Client,args)
{
	MenuFunc_VIPFunction(Client);
	return Plugin_Handled;
}

public Action:Command_VIPVote(Client,args)
{
	MenuFunc_VIPVote(Client);
	return Plugin_Handled;
}

public Action:MenuFunc_VIPFunction(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_VIPFunction);
	decl String:line[256];
	VipIsOver(Client);
	new viplimit = CheckVipTimeLimit(Client);
	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "你的身份: 普通VIP \n你不是高级会员,无法领取免费补给.");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	SetMenuTitle(menu, line);

	AddMenuItem(menu, "item0", "武器补给菜单");
	
	/*
	AddMenuItem(menu, "item1", "传送补给菜单");		
	*/
	Format(line, sizeof(line), "瞬间满血(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item1", line);	
	
	Format(line, sizeof(line), "瞬间满蓝(剩余:%d)", vip_item[Client]);
	if (!UseHFMP[Client])
		AddMenuItem(menu, "item2", line);
	else
		AddMenuItem(menu, "item2", line, ITEMDRAW_DISABLED);

	/*
	Format(line, sizeof(line), "获得医疗包(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item4", line);
	
	Format(line, sizeof(line), "获得电击器(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item5", line);
	*/
	
	Format(line, sizeof(line), "获得医疗包(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item3", line);
	
	Format(line, sizeof(line), "获得止痛药丸(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item4", line);
	
	Format(line, sizeof(line), "获得燃烧瓶(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item5", line);

	Format(line, sizeof(line), "获得电击器(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item8", line);
	
//	Format(line, sizeof(line), "获得胆汁瓶(剩余:%d)", vip_item[Client]);
//	AddMenuItem(menu, "item6", line);
	
	Format(line, sizeof(line), "获得土制炸弹(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item7", line);

	Format(line, sizeof(line), "获得斧头(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item7", line);

//	Format(line, sizeof(line), "获得电锯(剩余:%d)", vip_item[Client]);
//	AddMenuItem(menu, "item7", line);
	


	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public MenuHandler_VIPFunction(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_VIP(Client);
	}
	if(action == MenuAction_Select)
	{
		if (!IsPlayerAlive(Client) || GetClientTeam(Client) != 2)
		{
			PrintToChat(Client, "补给获取失败,因为你死亡了或你不是幸存者!");
			return;
		}
		if (param != 0)
		{
			if (vip_item[Client] >= 1)
				vip_item[Client] -= 1;
			else
			{
				PrintHintText(Client, "你在本回合的免费补给已经领取完了,请到下回合在领取!");
				MenuFunc_VIPFunction(Client);
				return;
			}
		}
		switch(param)
		{
			case 0: MenuFunc_VIPFunction_Weapon(Client); //获得武器
			//case 1: MenuFunc_Teleport(Client); //玩家传送
			case 1: CheatCommand(Client, "give", "health"), CPrintToChatAll("\x03[Vip会员]%N{olive}使用\x03补给瞬间满血\x03直接回满了生命(倒地自起).", Client); //瞬间满血
			case 2: 
			{
				if (!UseHFMP[Client])//瞬间满蓝
				{
					UseHFMP[Client] = true;  //true是真的意思
					MP[Client] = MaxMP[Client];
					CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给\x03瞬间满蓝{olive}直接回满了MP值.", Client);
				}
			}
			case 3: CheatCommand(Client, "give", "first_aid_kit"), CPrintToChatAll("\x03[Vip会员]\x03}%N{olive}使用补给获得了\x03医疗包", Client); //获得医疗包
			/*
			case 5: CheatCommand(Client, "give", "defibrillator"), CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用补给获得了{lightgreen}电击器", Client); //获得电击器
			case 6: CheatCommand(Client, "give", "adrenaline"), CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用补给获得了{lightgreen}肾上腺素", Client); //获得肾上腺素
			*/
			case 4: CheatCommand(Client, "give", "pain_pills"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了\x03止痛药丸", Client); //获得痛药丸
			case 5: CheatCommand(Client, "give", "molotov"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了\x03燃烧瓶", Client); //获得燃烧瓶
			case 6: CheatCommand(Client, "give", "defibrillator"), CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用补给获得了{lightgreen}电击器", Client); //获得电击器
			//			case 6: CheatCommand(Client, "give", "vomitjar"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了\x03胆汁液", Client); //获得胆汁瓶
			case 7: CheatCommand(Client, "give", "pipe_bomb"), CPrintToChatAll("\x03[Vip会员\x03%N{olive}使用补给获得了\x03土制炸弹", Client); //获得土制炸弹
//			case 8: CheatCommand(Client, "give", "fireaxe"), CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用补给获得了{lightgreen}斧头", Client); //获得电击器
//			case 9: CheatCommand(Client, "give", "chainsaw"), CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用补给获得了{lightgreen}电锯", Client); //获得电击器
		}
		
		if (param != 0)
			MenuFunc_VIPFunction(Client);
	}

}

//使用VIP功能_获得武器
public Action:MenuFunc_VIPFunction_Weapon(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_VIPFunction_Weapon);
	decl String:line[256];
	VipIsOver(Client);
	new viplimit = CheckVipTimeLimit(Client);
	if (VIP[Client] <= 0)
		Format(line, sizeof(line), "你的身份: 普通VIP \n你不是高级会员,无法领取免费补给.请联系op扣扣；1176195532 购买会员!");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	SetMenuTitle(menu, line);

	
	Format(line, sizeof(line), "获得武士刀(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item0", line);
	
	Format(line, sizeof(line), "获得斩马刀(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item1", line);
	
	Format(line, sizeof(line), "获得M16(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item2", line);	
	
	Format(line, sizeof(line), "获得AK47(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item3", line);
	
	Format(line, sizeof(line), "获得AWP狙击枪(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item4", line);
	
	Format(line, sizeof(line), "获得M60机枪(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item5", line);
	
	Format(line, sizeof(line), "获得榴弹发射器(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item6", line);
	
	Format(line, sizeof(line), "获得燃烧弹(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item7", line);
	
	Format(line, sizeof(line), "获得高爆弹(剩余:%d)", vip_item[Client]);
	AddMenuItem(menu, "item8", line);
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	

	return Plugin_Handled;
}

public MenuHandler_VIPFunction_Weapon(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_VIPFunction(Client);
	}
	if(action == MenuAction_Select)
	{
		if (!IsPlayerAlive(Client) || GetClientTeam(Client) != 2)
		{
			PrintToChat(Client, "补给获取失败,因为你死亡了或你不是幸存者!");
			return;
		}
		if (vip_item[Client] >= 1)
			vip_item[Client] -= 1;
		else
		{
			PrintHintText(Client, "温馨提示：你在本回合的免费补给已经领取完了,请到下回合在领取!伤心去把！")
			MenuFunc_VIPFunction_Weapon(Client);
			return;
		}
			
		switch(param)
		{
			case 0: CheatCommand(Client, "give", "katana"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}武士刀", Client); //获得武士刀
			case 1: CheatCommand(Client, "give", "machete"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}斩马刀", Client); //获得斩马刀
			case 2: CheatCommand(Client, "give", "rifle"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}M16+红外线瞄准", Client); //获得M16
			case 3: CheatCommand(Client, "give", "rifle_ak47"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}AK47+红外线瞄准", Client); //获得AK47
			case 4: CheatCommand(Client, "give", "sniper_awp"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}AWP狙击枪+红外线瞄准", Client); //获得AWP狙击枪
			case 5: CheatCommand(Client, "give", "rifle_m60"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}M60机枪+红外线瞄准", Client); //获得M60机枪
			case 6: CheatCommand(Client, "give", "grenade_launcher"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}榴弹发射器+红外线瞄准", Client); //获得榴弹发射器
			case 7: CheatCommand(Client, "upgrade_add", "Incendiary_ammo"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}燃烧弹", Client); //获得燃烧弹
			case 8: CheatCommand(Client, "upgrade_add", "explosive_ammo"), CPrintToChatAll("\x03[Vip会员]\x03%N{olive}使用补给获得了{lightgreen}高爆弹", Client); //获得高爆弹
		}
		if (param != 0 && param != 1 && param != 7 && param != 8)
			CheatCommand(Client, "upgrade_add", "laser_sight"); //获得红外线瞄准
			
		MenuFunc_VIPFunction_Weapon(Client);
	}
}

//使用VIP功能_玩家传送
public Action:MenuFunc_Teleport(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	VipIsOver(Client);
	new viplimit = CheckVipTimeLimit(Client);
	if (VIP[Client] <= 3)
		Format(line, sizeof(line), "你的身份: 普通VIP \n你不是至尊会员,无法领取传送补给.请联系op扣扣；1176195532 购买至尊会员！");
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4 剩余:%d天 \n本回合还可以免费领取补给(%d)个", viplimit, vip_item[Client]);
	SetPanelTitle(menu, line);

	
	Format(line, sizeof(line), "传送到某玩家处[捣乱的直接封号!](剩余:%d)", vip_item[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "某玩家传送到本人处[捣乱的直接封号!](剩余:%d)", vip_item[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "传送到准心位置[捣乱的直接封号!](剩余:%d)", vip_item[Client]);
	DrawPanelItem(menu, line);	
	
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Teleport, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_Teleport(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		if (!IsPlayerAlive(Client) || GetClientTeam(Client) != 2)
		{
			PrintToChat(Client, "补给获取失败,因为你死亡了或你不是幸存者!【绑定密码才能领取补给，可用本服登陆器绑定】");
			return;
		}
		if (vip_item[Client] <= 0)
		{
			PrintHintText(Client, "温馨提示：你在本回合的免费补给已经领取完了,请到下回合在领取!至尊会员有15次补给！")
			MenuFunc_Teleport(Client)
			return;
		}
		
		if (param == 3)
		{
			if (vip_item[Client] >= 1)
				vip_item[Client] -= 1;
		}
		
		switch(param)
		{
			case 1: MenuFunc_TeleportChose(Client, 0); //传送到某玩家处
			case 2: MenuFunc_TeleportChose(Client, 1); //某玩家传送到本人处
			case 3: Vip_Teleport(Client, Client, 2); //传送到鼠标位置
			case 4: MenuFunc_VIP(Client); //返回
		}
		
	}
}

//使用VIP功能_玩家传送_传送类型
public Action:MenuFunc_TeleportChose(Client, type)
{
	new Handle:menu = CreateMenu(MenuHandler_TeleportChose);
	decl String:line[256], String:id[12];
	if (type == 0)
		Format(line, sizeof(line), "传送到某玩家处:");
	else if (type == 1)
		Format(line, sizeof(line), "某玩家传送到本人处:");

	SetMenuTitle(menu, line);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 2)
		{
			if (IsPlayerAlive(i))
			{
				Format(line, sizeof(line), "生还: %N", i);
				Format(id, sizeof(id), "%d", i);
				AddMenuItem(menu, id, line);
			}			
			else
			{
				Format(line, sizeof(line), "死亡: %N", i);
				Format(id, sizeof(id), "%d", i);
				AddMenuItem(menu, id, line, ITEMDRAW_DISABLED);			
			}
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public MenuHandler_TeleportChose(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_Teleport(Client);
	}
	else if (action == MenuAction_Select)
	{
		if (vip_item[Client] <= 0)
		{
			PrintHintText(Client, "你在本回合的免费补给已经领取完了,请到下回合在领取!")
			MenuFunc_Teleport(Client)
			return;
		}
		
		decl String:info[32], String:title[32];
		new userid, target, type;
		
		GetMenuTitle(menu, title, sizeof(title));
		GetMenuItem(menu, param, info, sizeof(info));
		if (StrEqual(title, "传送到某玩家处:", false))
			type = 0;
		else if (StrEqual(title, "某玩家传送到本人处:", false))
			type = 1;
		else 
			return;
		
		userid = StringToInt(info);
		target = userid;		
		if (IsValidPlayer(target) && IsValidEntity(target))
			Vip_Teleport(Client, target, type), vip_item[Client] -= 1;
		else
			PrintHintText(Client, "无效的目标!");
	}
}

//传送玩家子程序
public Vip_Teleport(Client, target, type)
{
	new Float:pos[3];
	new Float:t_pos[3];
	new Float:m_pos[3];
	if (IsValidPlayer(Client) && IsValidPlayer(target))
	{
		GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", t_pos);
		if (type == 0)
		{
			TeleportEntity(Client, t_pos, NULL_VECTOR, NULL_VECTOR);
			MenuFunc_Teleport(Client);
			CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用传送补给,传送到了{lightgreen}%N{olive}的位置.", Client, target);
		}
		else if (type == 1)
		{
			TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR)
			MenuFunc_Teleport(Client);
			CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用传送补给,将{lightgreen}%N{olive}传送到了自己的位置.", Client, target);
		}
		else if (type == 2)
		{
			GetTracePosition(Client, m_pos);
			TeleportEntity(Client, m_pos, NULL_VECTOR, NULL_VECTOR);
			MenuFunc_Teleport(Client);
			CPrintToChatAll("{olive}[Vip会员]{lightgreen}%N{olive}使用传送补给,传送到了他准心的位置.", Client, target);
		}
			
	}
}

//重置VIP免费补给
public ReSetVipProps(Client)
{
	if (IsValidPlayer(Client) && !IsFakeClient(Client))
	{
		new vipA = GetConVarInt(cv_vippropsA);
		new vipB = GetConVarInt(cv_vippropsB);
		new vipC = GetConVarInt(cv_vippropsC);
		new vipD = GetConVarInt(cv_vippropsD);
		if (VIP[Client] <= 0)
			vip_item[Client] = 0;
		else if (VIP[Client] == 1 && VIPNameCheck(Client))
		{
			if (vipA > 0)
				vip_item[Client] = vipA, UseHFMP[Client] = false, GetClientName(Client, VipName[Client], sizeof(VipName));
				
		}
		else if (VIP[Client] == 2 && VIPNameCheck(Client))
		{
			if (vipB > 0)
				vip_item[Client] = vipB, UseHFMP[Client] = false, GetClientName(Client, VipName[Client], sizeof(VipName));
		}
		else if (VIP[Client] == 3 && VIPNameCheck(Client))
		{
			if (vipC > 0)
				vip_item[Client] = vipC, UseHFMP[Client] = false, GetClientName(Client, VipName[Client], sizeof(VipName));
		}		
		else if (VIP[Client] == 4 && VIPNameCheck(Client))
		{
			if (vipD > 0)
				vip_item[Client] = vipD, UseHFMP[Client] = false, GetClientName(Client, VipName[Client], sizeof(VipName));
		}
	}
}

/* VIP加成功能(经验金钱加成 type = 1, 商店物品打折 type = 2) */
public VIPAdd(Client, data, type, bool:exp)
{
	if(!IsValidPlayer(Client) || data <= 0)
		return 0;
	
	new Value = 0;
	
	if (type == 1)
	{	
		if (VIP[Client] == 1)
			Value = RoundToNearest(data * 1.3);
		else if (VIP[Client] == 2)
			Value = RoundToNearest(data * 1.6);
		else if (VIP[Client] == 3)
			Value = RoundToNearest(data * 2.0);
		else if (VIP[Client] == 4)
			Value = RoundToNearest(data * 3.0);
		else
			return 0;
			
		if (exp)
		{
			if(GetConVarInt(cv_vipexp) <= 0)
				return 0;
			CPrintToChat(Client, "\x03[VIP会员]\x03VIP会员经验获得总额{red}%d(默认:%d+额外:%d)", Value + data, data, Value);
		}
		else
		{
			if(GetConVarInt(cv_vipcash) <= 0)
				return 0;
			CPrintToChat(Client, "\x03[VIP会员]\x03VIP会员金钱获得总额{red}%d(默认:%d+额外:%d)", Value + data, data, Value);
		}
	}
	else if (type == 2)
	{
		if(GetConVarInt(cv_vipbuy) <= 0)
			return data;
			
		if (VIP[Client] == 1)
			Value = RoundToNearest(data * 0.8);
		else if (VIP[Client] == 2)
			Value = RoundToNearest(data * 0.7);
		else if (VIP[Client] == 3)
			Value = RoundToNearest(data * 0.6);
		else if (VIP[Client] == 4)
			Value = RoundToNearest(data * 0.5);
		else
			return data;
		
		CPrintToChat(Client, "\x03[VIP会员]\x03VIP会员商店优惠后价格{red}(默认:%d 优惠后:%d)", data, Value);
	}
	
	return Value;
}

//会员名字检查,防止刷补给
public bool:VIPNameCheck(Client)
{
	if(!IsValidPlayer(Client) || IsFakeClient(Client))
		return false;
	new String:name[MAX_NAME_LENGTH];
	GetClientName(Client, name, sizeof(name));
	for(new i = 1; i <= MaxClients; i++)
	{	
		if (StrEqual(VipName[i], name))
			return false;		
	}
	return true;
}

//设置VIP光晕轮廓
public SetVipGrow(Client)
{
	if (VIP[Client] > 0)
	{
		if (VIP[Client] == 1)
			PerformGlow(Client, 3, 0, 255, 255, 255);
		else if (VIP[Client] == 2)
			PerformGlow(Client, 3, 0, 240, 255, 80);
		else if (VIP[Client] == 3)
			PerformGlow(Client, 3, 0, 85, 240, 130);
		else if (VIP[Client] == 4)
			PerformGlow(Client, 3, 0, 186, 085, 211);
	}
}


//使用VIP功能_投票菜单
public Action:MenuFunc_VIPVote(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	VipIsOver(Client);
	new viplimit = CheckVipTimeLimit(Client);
	if (VIP[Client] == 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1 剩余:%d天", viplimit);
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2 剩余:%d天", viplimit);
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3 剩余:%d天", viplimit);
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4 剩余:%d天", viplimit);
	SetPanelTitle(menu, line);

	if (VIP[Client] == 1 || VIP[Client] == 2 || VIP[Client] == 3 || VIP[Client] == 4)
		DrawPanelItem(menu, "[可用]投票踢人");
	else
		DrawPanelItem(menu, "[不可用]投票踢人");
		
	if (VIP[Client] == 2 || VIP[Client] == 3 || VIP[Client] == 4)
		DrawPanelItem(menu, "[可用]投票换图");
	else
		DrawPanelItem(menu, "[不可用]投票换图");
		
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_VIPVote, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_VIPVote(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{	
		if (vote_type != 0)
		{
			CPrintToChat(Client, "\x03现在有投票正在进行中,请稍后再试!");
			return;
		}
			
		switch(param)
		{
			case 1:
			{
				if (VIP[Client] == 1 || VIP[Client] == 2 || VIP[Client] == 3 || VIP[Client] == 4)
					MenuFunc_VIPKick(Client); //VIP投票踢人
				else
					CPrintToChat(Client, "\x03你的会员权限不足,无法使用该功能!请联系op扣扣；1176195532 购买会员!");
			}
			case 2:
			{
				if (VIP[Client] == 2 || VIP[Client] == 3 || VIP[Client] == 4)
					MenuFunc_VIPMap(Client); //VIP投票换图
				else
					CPrintToChat(Client, "\x03你的会员权限不足,无法使用该功能!请联系op扣扣；1176195532 购买会员!");
			}
			case 3: MenuFunc_VIP(Client); //返回VIP主面板
		}

	}
}


//使用VIP功能_投票菜单_投票换图
public Action:MenuFunc_VIPMap(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_VIPMap);
	decl String:line[256];
	if (VIP[Client] == 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1");
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2");
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3");
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4");
	SetMenuTitle(menu, line);
	AddMenuItem(menu, "c1m1_hotel", "[第一关]死亡中心(Dead Center)");
	AddMenuItem(menu, "c2m1_highway", "[第二关]黑色狂欢夜(Dark Carnivale)");
	AddMenuItem(menu, "c3m1_plankcountry", "[第三关]沼泽激战(Swamp Fevere)");
	AddMenuItem(menu, "c4m1_milltown_a", "[第四关]暴风骤雨(Hard Raine)");
	AddMenuItem(menu, "c5m1_waterfront", "[第五关]教区(The Parishe)");
	AddMenuItem(menu, "c6m1_riverbank", "[第六关]消逝(The Passinge)");
	AddMenuItem(menu, "c7m1_docks", "[第七关]牺牲(The Sacrifice)");
	AddMenuItem(menu, "c8m1_apartment", "[第八关]毫不留情(No Mercy)");
	AddMenuItem(menu, "c9m1_alleys", "[第九关]坠机险途(Crash Course)");
	AddMenuItem(menu, "c10m1_caves", "[第十关]死亡丧钟(Death Toll)");
	AddMenuItem(menu, "c11m1_greenhouse", "[第十一关]静寂时分(Blood Harvest)");
	AddMenuItem(menu, "c12m1_hilltop", "[第十二关]血腥收获(Dead Air)"); 
	AddMenuItem(menu, "c13m1_alpinecreek", "[第十三关]冷流(Cold Stream)");

	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public MenuHandler_VIPMap(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_VIPVote(Client);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:mapname[64], String:C_Map[128], style;
		GetCurrentMap(C_Map, sizeof(C_Map));
		GetMenuItem(menu, param, info, sizeof(info), style, mapname, sizeof(mapname));
		if (StrEqual(C_Map, info, false))
		{
			PrintHintText(Client, "不可以更换与当前地图相同的地图!");
			Vip_VoteReSet();
			return;
		}
		strcopy(vote_mapname, sizeof(vote_mapname), mapname);
		strcopy(vote_mapinfo, sizeof(vote_mapinfo), info);
		vote_type = 2;
		CreateTimer(1.0, Timer_Voting, Client, TIMER_REPEAT);
	}
}

//使用VIP功能_投票菜单_投票踢人
public Action:MenuFunc_VIPKick(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_VIPKick);
	decl String:line[256];
	if (VIP[Client] == 0)
		Format(line, sizeof(line), "你的身份: 普通VIP");
	else if (VIP[Client] == 1)
		Format(line, sizeof(line), "你的身份: 白金VIP1");
	else if (VIP[Client] == 2)
		Format(line, sizeof(line), "你的身份: 黄金VIP2");
	else if (VIP[Client] == 3)
		Format(line, sizeof(line), "你的身份: 水晶VIP3");
	else if (VIP[Client] == 4)
		Format(line, sizeof(line), "你的身份: 至尊VIP4");
	SetMenuTitle(menu, line);

	AddTargetsToMenu2(menu, Client, COMMAND_FILTER);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public MenuHandler_VIPKick(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_VIPVote(Client);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;

		vote_type = 1;
		GetMenuItem(menu, param, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		if (VIP[target] >= 1)
		{
			PrintHintText(Client, "无法踢出Vip会员玩家!");
			Vip_VoteReSet();
			return;
		}
		vote_target = target;
		CreateTimer(1.0, Timer_Voting, Client, TIMER_REPEAT);
	}
}

//使用VIP功能_投票菜单_投票选择
public Action:MenuFunc_VoteChose(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	if (vote_type == 1)
		Format(line, sizeof(line), "玩家 %N 建议投票踢出 %N, 你的选择是?", Client, vote_target);
	else if (vote_type == 2)
		Format(line, sizeof(line), "玩家 %N 建议地图更换为 %s, 你的选择是?", Client, vote_mapname);
	else
		return Plugin_Handled;
		
	SetPanelTitle(menu, line);

	DrawPanelItem(menu, "同意");
	DrawPanelItem(menu, "反对");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || IsFakeClient(i) || vip_chose[i] == 1 || vip_chose[i] == 2)
			continue;
			
		SendPanelToClient(menu, i, MenuHandler_VoteChose, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public MenuHandler_VoteChose(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{
		if (vote_type > 0)
		{
			switch(param)
			{
				case 1: vip_chose[Client] = 1, CPrintToChatAll("\x03[投票]{red}%N{olive}选择了同意.", Client);
				case 2: vip_chose[Client] = 2, CPrintToChatAll("\x03[投票]{red}%N{olive}选择了反对.", Client);		
			}
		}
	}
}

//投票计时器
public Action:Timer_Voting(Handle:timer, any:Client)
{
	new yes;
	new no;
	new over;
	new all;

	if (vote_type == 1)
	{
		if (!IsValidPlayer(vote_target))
		{
			Vip_VoteReSet();
			CPrintToChatAll("\x03由于被投票踢出的玩家已经退出游戏,投票中止!");
			return Plugin_Stop;
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || IsFakeClient(i))
			continue;
			
		all++;
		
		if (vip_chose[i] == 1)
			yes++;
		else if (vip_chose[i] == 2)
			no++;
		else
			MenuFunc_VoteChose(Client);
	}
	
	over = all - yes - no;
	vote_timeout++;
	
	PrintHintTextToAll("当前投票的票数统计(剩余时间:%d): 未投票数: %d/%d \n同意: %d/%d \n反对:%d/%d", 20 - vote_timeout, over, all, yes, all, no, all);
	
	if (vote_timeout >= 20)
	{
		no += over;
		over = 0;
		if (yes > no)
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票同意票数最高,踢出%N", vote_target), KickClient(vote_target, "你已被投票踢出!");
			else if (vote_type == 2)
			{
				PrintHintTextToAll("投票同意票数最高,更改地图为%s", vote_mapname);
				ForceChangeLevel(vote_mapinfo, "vote");
				SaveServerTimeLog(true);
			}
		}
		else if (no > yes)
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票反对票数最高,未踢出%N", vote_target);
			else if (vote_type == 2)
				PrintHintTextToAll("投票反对票数最高,停止更改地图");		
		}
		else
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票票数相同,未踢出%N", vote_target);
			else if (vote_type == 2)
				PrintHintTextToAll("投票票数相同,停止更改地图");			
		}	
		
		Vip_VoteReSet();
		return Plugin_Stop;
	}
	else if (yes + no >= all)
	{
		if (yes > no)
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票同意票数最高,踢出%N", vote_target), KickClient(vote_target, "你已被投票踢出!");
			else if (vote_type == 2)
			{
				PrintHintTextToAll("投票同意票数最高,更改地图为%s", vote_mapname);
				ForceChangeLevel(vote_mapinfo, "vote");
				SaveServerTimeLog(true);
			}
		}
		else if (no > yes)
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票反对票数最高,未踢出%N", vote_target);
			else if (vote_type == 2)
				PrintHintTextToAll("投票反对票数最高,停止更改地图");		
		}
		else
		{
			if (vote_type == 1)
				PrintHintTextToAll("投票票数相同,未踢出%N", vote_target);
			else if (vote_type == 2)
				PrintHintTextToAll("投票票数相同,停止更改地图");			
		}	
		
		Vip_VoteReSet();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

//投票数据重置
public Vip_VoteReSet()
{
	vote_type = 0;
	vote_target = 0;
	vote_timeout = 0;
	Format(vote_mapname, sizeof(vote_mapname), "");
	Format(vote_mapinfo, sizeof(vote_mapinfo), "");
	for (new i = 1; i <= MaxClients; i++)
	{
		vip_chose[i] = 0;
	}
}

/* VIP通道_初始人数设置 */
public SetPlayerLimit()
{
	if (cv_MaxPlayer != INVALID_HANDLE)
	{
		ServerPlayerLimit = GetConVarInt(cv_MaxPlayer);
		SetConVarInt(cv_MaxPlayer, ServerPlayerLimit + 1);
	}
}

/* VIP通道_还原人数设置 */
public ResetPlayerLimit()
{
	if (cv_MaxPlayer != INVALID_HANDLE)
		SetConVarInt(cv_MaxPlayer, ServerPlayerLimit);
}

/* VIP通道_会员进入 */
public VipPlayerConnect(Client)
{
	if (!IsFakeClient(Client))
	{
		if (GetAllConnectedCount() > ServerPlayerLimit)
		{
			if (VIP[Client] >= 1)
				KickNotVipPlayer();
			else
			{
				CPrintToChatAll("\x03[公告]由于\x03%N\x03占用了Vip会员通道,已经被服务器踢出!", Client);
				KickClient(Client, "此通道为VIP专用通道");
			}
		}
	}
}

/* VIP通道_踢出玩家 */
public KickNotVipPlayer()
{
	new Handle:hasmm = CreateArray(1, 0);
	new Handle:notmm = CreateArray(1, 0);
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidPlayer(i) || IsFakeClient(i) || VIP[i] >= 1)
			continue;
			
		if (IsPasswordConfirm[i])
			PushArrayCell(hasmm, i);
		else
			PushArrayCell(notmm, i);
	}
	
	if (GetArraySize(notmm) > 1)
	{
		new target = GetArrayCell(notmm, GetRandomInt(0, GetArraySize(notmm) - 1));
		if (IsValidPlayer(target) && !IsFakeClient(target))
		{
			KickClient(target, "由于你占用了会员通道,已经被服务器踢出");
			CPrintToChatAll("\x03[公告]由于\x03%N\x03占用了Vip会员通道,已经被服务器踢出!", target);		
		}
	}
	else if (GetArraySize(hasmm) >= 1)
	{
		new target = GetArrayCell(hasmm, GetRandomInt(0, GetArraySize(hasmm) - 1));
		if (IsValidPlayer(target) && !IsFakeClient(target))
		{
			KickClient(target, "由于你占用了会员通道,已经被服务器踢出");
			CPrintToChatAll("\x03[公告]由于\x03%N\x03占用了Vip会员通道,已经被服务器踢出!", target);		
		}	
	}
	
}

/* VIP剩余时间检测 */
public CheckVipTimeLimit(Client)
{
	if (VIP[Client] >= 1)
	{
		new year = GetThisYear();
		new today = GetToday();
		new maxday = GetThisYearMaxDay();
		new last;
		if (VIPYEAR[Client] > 0 && VIPTL[Client] > 0)
		{
			if (year == VIPYEAR[Client])
			{
				last = VIPTL[Client] - today;
				if (last > 0)
					return last;
				else
					return 0;
			}
			else if (VIPYEAR[Client] > year)
			{
				new moreyear = VIPYEAR[Client] - year;
				new moreday = maxday - today;
				
				for (new i = 1; i <= moreyear; i++)
					moreday += GetThisYearMaxDay(year + i);
							
				last = moreday + VIPTL[Client];
				
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

/* VIP到期 */
public VipIsOver(Client)
{
	if (VIP[Client] >= 1)
	{
		new last = CheckVipTimeLimit(Client);
		if (last <= 0)
		{
			if (I_BagSize[Client] > 5)
			{
				if (VIP[Client] == 1)
					I_BagSize[Client] -= 3;
				else if (VIP[Client] == 2)
					I_BagSize[Client] -= 5;
			}
			VIP[Client] = 0;
			VIPTL[Client] = 0;
			VIPYEAR[Client] = 0;
			SetZBItemTime(Client, 1, 0);
			SetZBItemTime(Client, 0, 0);
			ClientSaveToFileSave(Client);
			CPrintToChat(Client, "\x03[Vip会员]\x03你的Vip会员已经到期了,如果需要续费,请联系撸主");
		}
	}
}

//检查服务器当前已连接总人数
stock GetAllConnectedCount(bool:ingame = false, team = 0)
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!ingame)
			{
				if (team == 0)
					count++;
				else if (GetClientTeam(i) == team)
					count++;
			}
			else if (IsClientInGame(i))
			{
				if (team == 0)
					count++;
				else if (GetClientTeam(i) == team)
					count++;
			}
		}
	}
	
	return count;
}

public Action:Timer_CheckMaxPlayer(Handle:timer)
{
	new max = GetAllPlayerCount();
	if (max > ServerPlayerLimit)
		KickNotVipPlayer();		
}

/* 选择玩家菜单 */
public Menu_SetVIPMenu_Select(Client)
{
	viptarget = 0;
	viptype = 0;
	new Handle:menu = CreateMenu(Handler_SetVIPMenu_Select);	
	SetMenuTitle(menu, "设置玩家为VIP:");		
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu2(menu, Client, COMMAND_FILTER);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Handler_SetVIPMenu_Select(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;

		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		Menu_SetVIPMenu(param1, target)	;
	}
}

/* 选择会员类型菜单 */
public Menu_SetVIPMenu(Client, target)
{
	new Handle:menu = CreateMenu(Handler_SetVIPMenu);
	new String:targetinfo[16];
	SetMenuTitle(menu, "设置玩家为VIP:");
	IntToString(target, targetinfo, sizeof(targetinfo));
	AddMenuItem(menu, targetinfo, "普通VIP");
	AddMenuItem(menu, targetinfo, "白金VIP1");
	AddMenuItem(menu, targetinfo, "黄金VIP2");
	AddMenuItem(menu, targetinfo, "水晶VIP3");
	AddMenuItem(menu, targetinfo, "至尊VIP4");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public Handler_SetVIPMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		if (param2 >=0 && param2 <= 4)
		{
			new String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			new target = StringToInt(info);
			viptarget = target;
			viptype = param2;
			Menu_SetVIPTimeMenu(param1);
		}	
	}
}

/* 选择会员类型菜单 */
public Menu_SetVIPTimeMenu(Client)
{
	new Handle:menu = CreateMenu(Handler_SetVIPTimeMenu);
	SetMenuTitle(menu, "设置期限:");

	AddMenuItem(menu, "0", "0");
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	AddMenuItem(menu, "15", "15");
	AddMenuItem(menu, "30", "30");
	AddMenuItem(menu, "60", "60");
	AddMenuItem(menu, "90", "90");
	AddMenuItem(menu, "180", "180");
	AddMenuItem(menu, "360", "360");
	AddMenuItem(menu, "9999", "9999");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public Handler_SetVIPTimeMenu(Handle:menu, MenuAction:action, Client, param2)
{
	if (action == MenuAction_End)
	{
		viptarget = 0;
		viptype = 0;
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:info[16];
		GetMenuItem(menu, param2, info, sizeof(info));
		new time = StringToInt(info);
		SetVip(Client, viptarget, viptype, time, false);		
	}
	else
	{
		viptarget = 0;
		viptype = 0;
	}
}

/* 设置VIP */
public SetVip(Client, Target, type, time, bool:isfirst)
{
	if (IsValidPlayer(Target) && !IsFakeClient(Target))
	{
		if (IsPasswordConfirm[Target])
		{
			if (type <= 0)
				CPrintToChatAll("\x03[VIP会员] \x03%N {red}已经被管理员设置为\x03普通VIP {green}期限: \x03%d {green}天.", Target, time);
			else if (type == 1)
				CPrintToChatAll("\x03[VIP会员] \x03%N {red}已经被管理员设置为\x03白金VIP1 {green}期限: \x03%d {green}天.", Target, time);
			else if (type == 2)
				CPrintToChatAll("\x03[VIP会员] \x03%N {red}已经被管理员设置为\x03黄金VIP2 {green}期限: \x03%d {green}天.", Target, time);
			else if (type == 3)
				CPrintToChatAll("\x03[VIP会员] \x03%N {red}已经被管理员设置为\x03水晶VIP3 {green}期限: \x03%d {green}天.", Target, time);
			else if (type == 4)
				CPrintToChatAll("\x03[VIP会员] \x03%N {red}已经被管理员设置为\x03至尊VIP4 {green}期限: \x03%d {green}天.", Target, time);
			
			if (isfirst)
				SetVipTimeLimit(Target, type, time, true);
			else
				SetVipTimeLimit(Target, type, time);
			ReSetVipProps(Target);
			SetVipGrow(Client);
		}
		else
			ReplyToCommand(Client, "\x03你选择的玩家还没有注册或登录RPG,无法给予VIP会员!");
	}
	else
		ReplyToCommand(Client, "\x03你选择的玩家是无效的!");
		
	viptarget = 0;
	viptype = 0;
}


/* 设置VIP期限 */
stock SetVipTimeLimit(Target, type, time, bool:first = false)
{
	if (type > 0)
	{
		new today = GetToday();
		new maxday = GetThisYearMaxDay();
		new year = GetThisYear();
		VIP[Target] = type;
		if (today > 0 && year > 0 && maxday > 0)
		{
			if (today + time <= maxday)
			{
				VIPYEAR[Target] = year;
				VIPTL[Target] = today + time;
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
					VIPYEAR[Target] = moreyear;
					VIPTL[Target] = moreday;
					if (first)
						Cash[Target] += 50000;
				}
			}
			
			ClientSaveToFileSave(Target);
		}
	}
}