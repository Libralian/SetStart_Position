#include <amxmodx>
#include <cstrike>
#include <fakemeta>
//#include <hamsandwich>
#include <reapi>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "SetStart Position"
#define VERSION "1.0"
#define AUTHOR "artlx"

#pragma semicolon 1

new g_bStartPosition, Float:g_fStartOrigin[3], Float:g_fStartVAngles[3];
new g_szMapName[64];
new HookChain:g_iSpawnHook;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /setstart", "Command_SetStart", ADMIN_RCON);
	register_clcmd("setstart", "Command_SetStart", ADMIN_RCON);
	g_iSpawnHook = RegisterHookChain(RG_CBasePlayer_Spawn, "HC_CBasePlayer_Spawn_Post", true);
}

public plugin_cfg()
{
	LoadStartPosition();
}	

LoadStartPosition()
{	
	new szDir[128]; get_localinfo("amxx_datadir", szDir, charsmax(szDir));
	format(szDir, charsmax(szDir), "%s/set_start/", szDir);

	if(!dir_exists(szDir))	mkdir(szDir);

	get_mapname(g_szMapName, charsmax(g_szMapName));
	new szFile[128]; formatex(szFile, charsmax(szFile), "%s%s.bin", szDir, g_szMapName);

	if(!file_exists(szFile)) return;

	new file = fopen(szFile, "rb");
	fread_blocks(file, _:g_fStartOrigin, sizeof(g_fStartOrigin), BLOCK_INT);
	fread_blocks(file, _:g_fStartVAngles, sizeof(g_fStartVAngles), BLOCK_INT);
	fclose(file);

	g_bStartPosition = true;
}

public Command_SetStart(id, flag)
{
	if((~get_user_flags(id) & flag) || !is_user_alive(id)) return PLUGIN_HANDLED;

	get_entvar(id, var_origin, g_fStartOrigin);
	get_entvar(id, var_v_angle, g_fStartVAngles);

	g_bStartPosition = true;

	SaveStartPosition(g_szMapName, g_fStartOrigin, g_fStartVAngles);

	client_print_color(id, print_team_blue, "^4[SavePos]^1 Start position has been set.");

	return PLUGIN_HANDLED;
}

SaveStartPosition(map[], Float:origin[3], Float:vangles[3])
{
	new szDir[128]; get_localinfo("amxx_datadir", szDir, charsmax(szDir));
	new szFile[128]; formatex(szFile, charsmax(szFile), "%s/set_start/%s.bin", szDir, map);

	new file = fopen(szFile, "wb");
	fwrite_blocks(file, _:origin, sizeof(origin), BLOCK_INT);
	fwrite_blocks(file, _:vangles, sizeof(vangles), BLOCK_INT);
	fclose(file);
}

public HC_CBasePlayer_Spawn_Post(id)
{
	if(!is_user_alive(id)) return HC_CONTINUE;

	if(g_bStartPosition)
	{
		DisableHookChain(g_iSpawnHook);
		Command_Start(id);
		EnableHookChain(g_iSpawnHook);
	}

	return HC_CONTINUE;
}

public Command_Start(id)
{
	if(!is_user_connected(id)) return;

//	ExecuteHam(Ham_CS_RoundRespawn, id);
	rg_round_respawn(id);

	if(g_bStartPosition)
	{
		SetPosition(id, g_fStartOrigin, g_fStartVAngles);
	}
}

SetPosition(id, Float:origin[3], Float:vangles[3])
{
	set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
	set_entvar(id, var_v_angle, vangles);
	set_entvar(id, var_angles, vangles);
	set_entvar(id, var_fixangle, 1);
//	set_entvar(id, var_health, 100.0);
	engfunc(EngFunc_SetOrigin, id, origin);
}
