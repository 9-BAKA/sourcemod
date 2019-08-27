/************************************************************************
*	背包系统
************************************************************************/
/* 物品Size */
static Bag_Size[5] = { 10, 5, 3, 4, 2 }

/* 背包类别 */

#define BAG_GUN		0	//枪械
#define BAG_MELEE		1	//近战
#define BAG_BOMB		2	//手雷
#define BAG_MEDIC		3	//药物
#define BAG_OTHER		4	//小药物

/* 类别物品 */

//枪械物品
#define GUN_AK47		0	//AK47
#define GUN_M16		1	//M16
#define GUN_M60		2	//M60
#define GUN_MP5		3	//MP5
#define GUN_SPAS		4	//大散弹枪
#define GUN_CHROME	5	//二代单喷
#define GUN_HUNTING	6	//猎枪
#define GUN_SCOUT		7	//鸟狙
#define GUN_AWP		8	//AWP大狙
#define GUN_GL		9	//榴弹炮

//近战武器
#define MELEE_FX		0	//消防斧
#define MELEE_KT		1	//武士刀
#define MELEE_MT		2	//斩马刀
#define MELEE_FP		3	//平底锅
#define MELEE_CS		4	//电锯

//手雷
#define BOMB_MT		0	//燃烧瓶
#define BOMB_VJ		1	//胆汁液
#define BOMB_PB		2	//土制炸弹

//药物
#define MEDIC_FAK		0	//医疗包
#define MEDIC_DF		1	//电击器
#define MEDIC_UE		2	//高爆包
#define MEDIC_UI		3	//燃烧包

//其他
#define OTHER_AL		0	//肾上腺素
#define OTHER_PP		1	//止痛药

/* 类别物品name */
static String:Bag_GunName[10][64] = { "rifle_ak47", "rifle_m60", "rifle", "smg_mp5", "shotgun_spas", "shotgun_chrome", "hunting_rifle", "sniper_scout", "sniper_awp", "grenade_launcher" };
static String:Bag_MeleeName[5][64] = { "fireaxe", "katana", "machete", "frying_pan", "chainsaw" };
static String:Bag_BombName[3][64] = { "molotov", "vomitjar", "pipe_bomb" };
static String:Bag_MedicName[4][64] = { "first_aid_kit", "defibrillator", "upgradepack_explosive", "upgradepack_incendiary" };
static String:Bag_OtherName[2][64] = { "adrenaline", "pain_pills" };

/* 类别物品显示名称 */
static String:Bag_DisGunName[10][64] = { "AK47步枪", "M60机枪", "M16步枪", "MP5冲锋枪", "战斗散弹枪", "二代单发散弹枪", "猎枪", "轻型狙击枪", "AWP狙击枪", "榴弹发射器" };
static String:Bag_DisMeleeName[5][64] = { "消防斧", "武士刀", "斩马刀", "平底锅", "电锯" };
static String:Bag_DisBombName[3][64] = { "燃烧瓶", "胆汁液", "土制炸弹" };
static String:Bag_DisMedicName[4][64] = { "医疗包", "电击器", "高爆子弹包", "燃烧子弹包" };
static String:Bag_DisOtherName[2][64] = { "肾上腺素", "止痛药丸" };

/* 扩充背包价格 */
new buybagcost = 50000;
#define BAGCOST[%1]	(I_BagSize[%1] - 10) * 25000

/* 快捷指令 */
public Action:Command_MyBag(Client,args)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return Plugin_Handled;
		
	MenuFunc_IBag(Client);
	
	return Plugin_Handled;
}


//背包主面板
public MenuFunc_IBag(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_IBag);
	decl String:line[64];
	new bagnum = I_BagSize[Client] - GetClientBagSize(Client);
	new itemnum[5];
	
	for (new i; i < 5; i++)
		itemnum[i] = GetClientBagWeapon(Client, i);
		
	new n_BagCost;
	if (BAGCOST[Client] >= 5000)
		n_BagCost = buybagcost + BAGCOST[Client];
	else
		n_BagCost = buybagcost;
		
	SetMenuTitle(menu, "军用战斗包[L键]:");

	Format(line, sizeof(line), "取出物品(拥有数量:%d)", GetClientBagSize(Client));
	AddMenuItem(menu, "item0", line);
	
	Format(line, sizeof(line), "存入物品(剩余空间:%d)", bagnum);
	AddMenuItem(menu, "item1", line);	
	
	Format(line, sizeof(line), "扩充背包(当前空间:%d 价格:%d$/格)", I_BagSize[Client], n_BagCost);
	AddMenuItem(menu, "item2", line);	
	
	Format(line, sizeof(line), "使用天神附体资格");
	AddMenuItem(menu, "item3", line);	
		
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_IBag(Handle:menu, MenuAction:action, Client, param)
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
			case 0: MenuFunc_GetBag(Client); //提取武器
			case 1: MenuFunc_SaveBag(Client); //保存物品
			case 2: BuyBag(Client), MenuFunc_IBag(Client); //扩充背包
			case 3: MenuFunc_Equipmentsale(Client); //使用力量
		}
	}
}

//使用力量
public Action:MenuFunc_Equipmentsale(Client)
{
	new Handle:menu = CreatePanel();
	  
	decl String:line[256];   
	Format(line, sizeof (line), "═══使用天神附体资格═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof (line), "使用宙斯附体: %d", LisA[Client]);   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "使用哈迪斯附体: %d", LisB[Client]);  
	DrawPanelItem(menu, line);  
	DrawPanelItem(menu, "返回背包");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_Equipmentsale, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_Equipmentsale(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:CSTOU(Client);
            case 2:CSJIA(Client);
			case 3:MenuFunc_IBag(Client);
		}
	}
}
public CSTOU(Client)
{   
	if(Lis[Client] <= 0)    
	{	    
		if(LisA[Client] > 0)        
		{            
			Lis[Client]+=1;       
		}	
	} else PrintHintText(Client, "你已经被天神宙斯附体!");	
}

public CSJIA(Client)
{   
	if(Lis[Client] <= 0)    
	{	    
		if(LisB[Client] > 0)        
		{            
			Lis[Client]+=2;       
		}	
	} else PrintHintText(Client, "你已经被冥王哈迪斯附体!");	
}


//取出物品
public MenuFunc_GetBag(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_GetBag);
	decl String:line[64];
	new bagnum = I_BagSize[Client] - GetClientBagSize(Client);
	new itemnum[5];
	
	for (new i; i < 5; i++)
		itemnum[i] = GetClientBagWeapon(Client, i);
	
	Format(line, sizeof(line), "提取物品(剩余空间:%d)", bagnum);	
	SetMenuTitle(menu, line);

	Format(line, sizeof(line), "枪械武器(总数:%d 手续费:200$)", itemnum[0]);
	AddMenuItem(menu, "item0", line);

	Format(line, sizeof(line), "近战武器(总数:%d 手续费:200$)", itemnum[1]);
	AddMenuItem(menu, "item1", line);	

	Format(line, sizeof(line), "投掷武器(总数:%d)", itemnum[2]);
	AddMenuItem(menu, "item2", line);	
	
	Format(line, sizeof(line), "药物物品(总数:%d)", itemnum[3]);
	AddMenuItem(menu, "item3", line);	

	Format(line, sizeof(line), "其他物品(总数:%d)", itemnum[4]);
	AddMenuItem(menu, "item4", line);	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_GetBag(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 0: MenuFunc_Bag_Gun(Client); //提取枪械武器
			case 1: MenuFunc_Bag_Melee(Client); //提取近战武器
			case 2: MenuFunc_Bag_Bomb(Client); //提取投掷武器
			case 3: MenuFunc_Bag_Medic(Client); //提取药物物品
			case 4: MenuFunc_Bag_Other(Client); //提取其他物品
		}
	}
}


//背包扩充
public BuyBag(Client)
{
	new n_BagCost;
	if (BAGCOST[Client] >= 5000)
		n_BagCost = buybagcost + BAGCOST[Client];
	else
		n_BagCost = buybagcost;
		
	if (Cash[Client] >= n_BagCost)
	{
		Cash[Client] -= n_BagCost;
		I_BagSize[Client] += 1;
		PrintHintText(Client, "购买成功,你的背包已经扩充了一个位置!");
	}
	else
		PrintHintText(Client, "你的金钱不足,无法购买!");
}


//保存物品
public MenuFunc_SaveBag(Client)
{
	
	new Handle:menu = CreateMenu(MenuHandler_SaveBag);
	decl String:line[64];
	new bagnum = I_BagSize[Client] - GetClientBagSize(Client);
	Format(line, sizeof(line), "存入物品(剩余空间:%d)", bagnum);
	SetMenuTitle(menu, line);

	Format(line, sizeof(line), "存入枪械武器");
	AddMenuItem(menu, "item0", line);

	Format(line, sizeof(line), "存入近战武器");
	AddMenuItem(menu, "item1", line);	

	Format(line, sizeof(line), "存入投掷武器");
	AddMenuItem(menu, "item2", line);	
	
	Format(line, sizeof(line), "存入药物物品");
	AddMenuItem(menu, "item3", line);	

	Format(line, sizeof(line), "存入其他物品");
	AddMenuItem(menu, "item4", line);	

	Format(line, sizeof(line), "存入全部物品");
	AddMenuItem(menu, "item5", line);		
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_SaveBag(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{
		new size = GetClientBagSize(Client);
		if (size >= I_BagSize[Client])
		{
			PrintHintText(Client, "你的背包已满,无法再存入物品!");
			MenuFunc_SaveBag(Client);
			return;
		}
				
		if (param < 5)
		{
			new type = CheckWeaponBag(Client, param);
			new bagnum = I_BagSize[Client] - GetClientBagSize(Client);
			if (type >= 0)
			{
				new String:name[64];
				if (param == 0)
					Format(name, sizeof(name), "%s", Bag_DisGunName[type]);
				else if (param == 1)
					Format(name, sizeof(name), "%s", Bag_DisMeleeName[type]);
				else if (param == 2)
					Format(name, sizeof(name), "%s", Bag_DisBombName[type]);
				else if (param == 3)
					Format(name, sizeof(name), "%s", Bag_DisMedicName[type]);
				else if (param == 4)
					Format(name, sizeof(name), "%s", Bag_DisOtherName[type]);
				
				CPrintToChat(Client, "\x03[系统]{green}物品: \x03%s {green}保存成功!剩余 \x03%d {green}个背包位置.", name, bagnum);
				CPrintToChatAll("\x03[背包] \x03%N {olive}将手中的 \x03%s {olive}存进了自己的包内!", Client, name);
			}
			else
				PrintHintText(Client, "物品保存失败,可能该物品无法被保存!");
		}
		else
		{
			new num;
			for(new i; i < 5; i++)
			{
				new type = CheckWeaponBag(Client, i);
				if (type > -1)
					num++;
			}
			
			if (num > 0)
			{
				new bagnum = I_BagSize[Client] - GetClientBagSize(Client);
				CPrintToChat(Client, "\x03[系统] \x03%d{green} 件物品保存成功!剩余 \x03%d {green}个背包位置.", num, bagnum);
				CPrintToChatAll("\x03[背包] \x03%N {olive}将手中的 \x03%d {olive}件物品存进了自己的包内!", Client, num);
			}
			else
				CPrintToChat(Client, "\x03[系统] \x03物品保存失败!当前身上没有有效的物品可以保存.");
		}
		
		MenuFunc_SaveBag(Client);
	}
}

//检查物品类型
public CheckWeaponBag(Client, WeaponSlot)
{
	if (!IsValidPlayer(Client) || IsFakeClient(Client))
		return -2;
	
	new weaponid = GetPlayerWeaponSlot(Client, WeaponSlot);
	new String:weaponname[64];
	new saveweapon = -1;
	if (weaponid > 0)
	{
		GetEdictClassname(weaponid, weaponname, sizeof(weaponname));
		if (WeaponSlot == 0)
		{
			//new clip = GetEntProp(weaponid, Prop_Send, "m_iClip1");
			//new ammo = GetEntData(Client, ammoOffset+(68));
			//PrintToChatAll("clip: %d ammo: %d", clip, ammo);
			for(new i; i < Bag_Size[BAG_GUN]; i++)
			{
				if (StrContains(weaponname, Bag_GunName[i], false) >= 0)
				{
					if (AddWeaponInBag(Client, BAG_GUN, i, weaponid) > 0)
						saveweapon = i;
					break;
				}
			}
		}
		else if (WeaponSlot == 1)
		{
			GetEntPropString(weaponid, Prop_Data, "m_ModelName", weaponname, sizeof(weaponname));
			for(new i; i < Bag_Size[BAG_MELEE]; i++)
			{
				if (StrContains(weaponname, Bag_MeleeName[i], false) >= 0)
				{
					if (AddWeaponInBag(Client, BAG_MELEE, i, weaponid) > 0)
						saveweapon = i;
					break;
				}
			}		
		}
		else if (WeaponSlot == 2)
		{
			for(new i; i < Bag_Size[BAG_BOMB]; i++)
			{
				if (StrContains(weaponname, Bag_BombName[i], false) >= 0)
				{
					if (AddWeaponInBag(Client, BAG_BOMB, i, weaponid) > 0)
						saveweapon = i;
					break;
				}
			}		
		}
		else if (WeaponSlot == 3)
		{
			for(new i; i < Bag_Size[BAG_MEDIC]; i++)
			{
				if (StrContains(weaponname, Bag_MedicName[i], false) >= 0)
				{
					if (AddWeaponInBag(Client, BAG_MEDIC, i, weaponid) > 0)
						saveweapon = i;
					break;
				}
			}		
		}
		else if (WeaponSlot == 4)
		{
			for(new i; i < Bag_Size[BAG_OTHER]; i++)
			{
				if (StrContains(weaponname, Bag_OtherName[i], false) >= 0)
				{
					if (AddWeaponInBag(Client, BAG_OTHER, i, weaponid) > 0)
						saveweapon = i;
					break;
				}
			}		
		}
	}
	
	if (saveweapon >= 0)
		return saveweapon;
	else
		return -1;
}

//保存物品数据
public AddWeaponInBag(Client, WeaponType, WeaponNum, id)
{
	new size = GetClientBagSize(Client);
	if (size >= I_BagSize[Client])
		return 0;
	
	I_Bag[Client][WeaponType][WeaponNum] += 1;
	RemoveEdict(id);
	if (WeaponType == BAG_MELEE)
		CheatCommand(Client, "give", "pistol");
		
	return 1;
}

//获取玩家背包物品总数
public GetClientBagSize(Client)
{	
	new size;
	
	for (new i; i < Bag_Size[BAG_GUN]; i++)
	{
		size += I_Bag[Client][BAG_GUN][i];
	}
	for (new i; i < Bag_Size[BAG_MELEE]; i++)
	{
		size += I_Bag[Client][BAG_MELEE][i];
	}
	for (new i; i < Bag_Size[BAG_BOMB]; i++)
	{
		size += I_Bag[Client][BAG_BOMB][i];
	}
	for (new i; i < Bag_Size[BAG_MEDIC]; i++)
	{
		size += I_Bag[Client][BAG_MEDIC][i];
	}
	for (new i; i < Bag_Size[BAG_OTHER]; i++)
	{
		size += I_Bag[Client][BAG_OTHER][i];
	}
	
	return size;
}

//获取玩家物品数量
public GetClientBagWeapon(Client, WeaponType)
{	
	new size;
	
	for (new i; i < Bag_Size[WeaponType]; i++)
		size += I_Bag[Client][WeaponType][i];

	return size;
}

//枪械武器提取
public MenuFunc_Bag_Gun(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bag_Gun);
	decl String:line[256], String:info[256];

	SetMenuTitle(menu, "我的背包(手续费:200$):");
	for (new i; i < Bag_Size[BAG_GUN]; i++)
	{
		Format(line, sizeof(line), "%s(数量:%d)", Bag_DisGunName[i], I_Bag[Client][BAG_GUN][i]);
		Format(info, sizeof(info), "%s", Bag_GunName[i]);
		AddMenuItem(menu, info, line);	
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_Bag_Gun(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{
		
		if (I_Bag[Client][BAG_GUN][param] > 0)
		{
			if (Cash[Client] >= 200)
			{
				new String:info[64];
				GetMenuItem(menu, param, info, sizeof(info));
				CheatCommand(Client, "give", info);
				I_Bag[Client][BAG_GUN][param] -= 1;
				Cash[Client] -= 200;
				CPrintToChatAll("\x03[背包] {red}%N {olive}从背包内拿出了 \x03%s {olive}花费 \x03-200$", Client, Bag_DisGunName[param]);
			}
			else
				PrintHintText(Client, "你没有足够的金钱提取武器,提取枪械武器(装满子弹)需要200金钱手续费!");
		}
		else
			PrintHintText(Client, "你背包内没有该物品!");
			
		MenuFunc_Bag_Gun(Client);
	}
}

//近战武器提取
public MenuFunc_Bag_Melee(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bag_Melee);
	decl String:line[256], String:info[256];

	SetMenuTitle(menu, "我的背包(手续费:200$):");
	for (new i; i < Bag_Size[BAG_MELEE]; i++)
	{
		Format(line, sizeof(line), "%s(数量:%d)", Bag_DisMeleeName[i], I_Bag[Client][BAG_MELEE][i]);
		Format(info, sizeof(info), "%s", Bag_MeleeName[i]);
		AddMenuItem(menu, info, line);	
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_Bag_Melee(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{		
		if (I_Bag[Client][BAG_MELEE][param] > 0)
		{
			if (Cash[Client] >= 200)
			{
				new String:info[64];
				GetMenuItem(menu, param, info, sizeof(info));
				CheatCommand(Client, "give", info);
				I_Bag[Client][BAG_MELEE][param] -= 1;
				Cash[Client] -= 200;
				CPrintToChatAll("\x03[背包] {red}%N {olive}从背包内拿出了 \x03%s  {olive}花费 \x03200$", Client, Bag_DisMeleeName[param]);
			}
			else
				PrintHintText(Client, "你没有足够的金钱提取武器,提取近战武器(回满耐久)需要200$手续费!");	
		}
		else
			PrintHintText(Client, "你背包内没有该物品!");
	
		MenuFunc_Bag_Melee(Client);
	}
}


//投掷武器提取
public MenuFunc_Bag_Bomb(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bag_Bomb);
	decl String:line[256], String:info[256];

	SetMenuTitle(menu, "我的背包:");
	for (new i; i < Bag_Size[BAG_BOMB]; i++)
	{
		Format(line, sizeof(line), "%s(数量:%d)", Bag_DisBombName[i], I_Bag[Client][BAG_BOMB][i]);
		Format(info, sizeof(info), "%s", Bag_BombName[i]);
		AddMenuItem(menu, info, line);	
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_Bag_Bomb(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{

		if (I_Bag[Client][BAG_BOMB][param] > 0)
		{
			new String:info[64];
			GetMenuItem(menu, param, info, sizeof(info));
			CheatCommand(Client, "give", info);
			I_Bag[Client][BAG_BOMB][param] -= 1;
			CPrintToChatAll("\x03[背包] \x03%N {olive}从背包内拿出了 \x03%s", Client, Bag_DisBombName[param]);
		}
		else
			PrintHintText(Client, "你背包内没有该物品!");
	
		MenuFunc_Bag_Bomb(Client);
	}
}


//药物物品提取
public MenuFunc_Bag_Medic(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bag_Medic);
	decl String:line[256], String:info[256];

	SetMenuTitle(menu, "我的背包:");
	for (new i; i < Bag_Size[BAG_MEDIC]; i++)
	{
		Format(line, sizeof(line), "%s(数量:%d)", Bag_DisMedicName[i], I_Bag[Client][BAG_MEDIC][i]);
		Format(info, sizeof(info), "%s", Bag_MedicName[i]);
		AddMenuItem(menu, info, line);	
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_Bag_Medic(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{

		if (I_Bag[Client][BAG_MEDIC][param] > 0)
		{
			new String:info[64];
			GetMenuItem(menu, param, info, sizeof(info));
			CheatCommand(Client, "give", info);
			I_Bag[Client][BAG_MEDIC][param] -= 1;
			CPrintToChatAll("\x03[背包] {red}%N {olive}从背包内拿出了 \x03%s", Client, Bag_DisMedicName[param]);
		}
		else
			PrintHintText(Client, "你背包内没有该物品!");
	
		MenuFunc_Bag_Medic(Client);
	}
}



//其他物品提取
public MenuFunc_Bag_Other(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_Bag_Other);
	decl String:line[256], String:info[256];

	SetMenuTitle(menu, "我的背包:");
	for (new i; i < Bag_Size[BAG_OTHER]; i++)
	{
		Format(line, sizeof(line), "%s(数量:%d)", Bag_DisOtherName[i], I_Bag[Client][BAG_OTHER][i]);
		Format(info, sizeof(info), "%s", Bag_OtherName[i]);
		AddMenuItem(menu, info, line);	
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);	
}

public MenuHandler_Bag_Other(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_IBag(Client);
	}
	if(action == MenuAction_Select)
	{

		if (I_Bag[Client][BAG_OTHER][param] > 0)
		{
			new String:info[64];
			GetMenuItem(menu, param, info, sizeof(info));
			CheatCommand(Client, "give", info);
			I_Bag[Client][BAG_OTHER][param] -= 1;
			CPrintToChatAll("\x03[背包] {red}%N {olive}从背包内拿出了 \x03%s", Client, Bag_DisOtherName[param]);
		}
		else
			PrintHintText(Client, "你背包内没有该物品!");
	
		MenuFunc_Bag_Other(Client);
	}
}