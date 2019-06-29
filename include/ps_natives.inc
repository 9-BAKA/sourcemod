#if defined _ps_included_
 #endinput
#endif
#define _ps_included_

/**
 * Gets the version of PS
 *
 * @return				current version of ps system in form of a float
 */
native Float:PS_GetVersion();

/**
 * Sets a client's points
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetPoints(client, newval);

/**
 * Sets a client's item string
 *
 * @param client			client index
 * @param newstring			new value of a client's item string
 * @return				none
 */
native PS_SetItem(client, const String:newstring[]);

/**
 * Sets a client's item cost
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetCost(client, newval);

/**
 * Sets a client's bought string
 *
 * @param client			client index
 * @param newstring			new value of a client's bought string
 * @return				none
 */
native PS_SetBought(client, const String:newstring[]);

/**
 * Sets a client's bought cost
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetBoughtCost(client, newval);

/**
 * Sets up an uncommon mob
 *
 * @param newval		amount of uncommon to spawn
 * @return				none
 */
native PS_SetupUMob(newval);

/**
 * Gets a client's bought cost
 *
 * @param client			client index
 * @return				boughtcost
 */
native PS_GetBoughtCost(client);

/**
 * Gets a client's points
 *
 * @param client			client index
 * @return				points
 */
native PS_GetPoints(client);

/**
 * Gets a client's current item cost
 *
 * @param client			client index
 * @return				cost
 */
native PS_GetCost(client);

/**
 * Gets a client's current item
 *
 * @param client			client index
 * @param dest				destination for the item string to go
 * @return				cost
 */
native PS_GetItem(client, String:dest[], maxlength);

/**
 * Gets a client's current bought item
 *
 * @param client		client index
 * @param dest			destination for the bought string to go
 * @return				cost
 */
native PS_GetBought(client, String:dest[], maxlength);

/**
* Registers a module for points system
*
* @param modulename	String that contains the module to be registered's name
* @return			false if successful true if already registered, true should never happen.
*/
native bool:PS_RegisterModule(const String:modulename[]);

/**
* Unregisters a module for points system
*
* @param modulename	String that contains the module to be unregistered's name
* @return			none
*/
native PS_UnregisterModule(const String:modulename[]);

/**
* Called when Points System is loaded
*
* @return			none
*/
forward OnPSLoaded();

/**
* Called when Points System is unloaded
*
* @return			none
*/
forward OnPSUnloaded();

public SharedPlugin:__pl_ps = 
{
	name = "ps_natives",
	file = "l4d2_points_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};