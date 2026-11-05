/*
    - Discord: cristian505
    
    - AMXX Workshop (Counter-Strike AMXX Discord Community): https://discord.gg/Ny69XZ2pcM
    - AMXX Workshop (YouTube): https://www.youtube.com/@amxxworkshop
    - AMXX Workshop (TikTok): https://www.tiktok.com/@amxx.workshop
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>

#include <reapi>

/* ~ [ Settings ] ~ */
new const gls_Primary_Reference[] = "weapon_m249";

const Float: glf_Primary_Deploy_Next_Attack_Time = 0.3;
const Float: glf_Primary_Reload_Time = 2.05;

const GiveType: gli_Primary_GiveType = GT_APPEND; // reapi_gamedll_const.inc/GiveType

const gli_Primary_Unique_Index = 505912;

const gli_Primary_Default_Clip = 100;
const gli_Primary_Max_Clip = 100;

const gli_Primary_Default_Ammo = 999;
const gli_Primary_Max_Ammo = 999;

#define df_Primary_WeaponList
#define df_Primary_Holder_Max_Speed_Bonus

#if defined df_Primary_WeaponList
    new const glig_Primary_WeaponList_Coords[] = { 3, 200, -1, -1, 0, 4, 20, 0 }; 
    // https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
#endif

#if defined df_Primary_Holder_Max_Speed_Bonus
    const Float: glf_Primary_Holder_Max_Speed_Bonus = -17.0;
#endif 

// Primary Attack
new const Float: glfg_Primary_Shoot_PunchAngles[][] = 
{
    { -1.0, -1.5 }, // Vertical - Min & Max
    { -0.35, 0.35 }, // Horizontal - Min & Max
    { -0.1, 0.1 },  // Diagonal - Min & Max

    // FL_DUCKING & FL_ONGROUND
    { -0.6, -1.0 },
    { -0.35, 0.35 },
    { -0.1, 0.1 }
};

const Float: glf_Primary_Shoot_Rate = 0.108;
const Float: glf_Primary_Shoot_Accuracy = 0.0; // 0.0 = 100% Accurate
const Float: glf_Primary_Shoot_Distance = 8192.0; // 8192.0 Max
const Float: glf_Primary_Shoot_Range_Modifier = 1.0; // Damage Falloff : 1.0 = constant, < 1.0 drops, > 1.0 rises with distance

const Bullet: gli_Primary_Shoot_Bullet_Type = BULLET_PLAYER_338MAG; // cssdk_const.inc/Bullet

const gli_Primary_Shoot_Damage = 30;
const gli_Primary_Shoot_Penetration = 4; // 4 Max

const gli_Primary_Min_Primary_Attacks_Count_Ability_Ready = 65;

#define df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier
#define df_Primary_Shoot_Victim_Post_Damage_Knockback

#if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier = 0.0; // ~1 second 0.0 to 1.0 (player speed * x.x), lower values reduce velocity effects too (e.g. knockback effects)
#endif

#if defined df_Primary_Shoot_Victim_Post_Damage_Knockback
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Knockback_Strenght = 50.0;
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Knockback_Up_Strenght = 0.0;
#endif

// Secondary Attack
const Float: glf_Primary_Post_Ability_Next_Attack_Time = 0.35;

#define df_CustomMuzzleFlash // Comment to disable custom muzzleflash.

// Entity : Missile
new const gls_Entity_Missile_Map_HitBox_Classname[] = "ent_e7_m_map";
new const gls_Entity_Missile_Victim_HitBox_Classname[] = "ent_e7_m_victim"; // Thanks to Arabas for overflow fix

const Float: glf_Entity_Missile_Fly_Speed = 1250.0;
const Float: glf_Entity_Missile_Explode_Damage_Radius = 150.0;
const Float: glf_Entity_Missile_Explode_Damage = 99.0;
const Float: glf_Entity_Missile_Explode_Victim_Post_Damage_Velocity_Modifier = 0.0;

const gli_Entity_Missile_Explode_Damage_Type = DMG_ALWAYSGIB;

// Entity : Lightning Cloud
new const gls_Entity_Lightning_Cloud_Classname[] = "ent_e7_lightning_cloud";

const Float: glf_Entity_Lightning_Cloud_Next_Think = 0.3;
const Float: glf_Entity_Lightning_Cloud_Damage_Radius = 300.0;
const Float: glf_Entity_Lightning_Cloud_Damage = 25.0;
const Float: glf_Entity_Lightning_Cloud_Victim_Post_Damage_Velocity_Modifier = 0.0;

const gli_Entity_Lightning_Cloud_Damage_Type = DMG_ALWAYSGIB;

const gli_Entity_Lightning_Cloud_Max_Lightning_Count = 19;
// Lifetime = Next Think * Max Lightnings Count

// Entity : MuzzleFlash
#if defined df_CustomMuzzleFlash
    new const gls_Entity_MuzzleFlash_Classname[] = "ent_e7_muzzleflash";
#endif

// View Model Animations
const Float: glf_Primary_View_Model_Animation_Idle_Time = 2.07;
const Float: glf_Primary_View_Model_Animation_Reload_Time = 3.93;
const Float: glf_Primary_View_Model_Animation_Deploy_Time = 1.03;
const Float: glf_Primary_View_Model_Animation_Shoot_A_Time = 0.9;
const Float: glf_Primary_View_Model_Animation_Shoot_B_Time = 0.9;

enum 
{
    gli_Primary_View_Model_Animation_Idle = 0,
    gli_Primary_View_Model_Animation_Reload,
    gli_Primary_View_Model_Animation_Deploy,
    gli_Primary_View_Model_Animation_Shoot_A,
    gli_Primary_View_Model_Animation_Shoot_B,
    gli_Primary_View_Model_Animation_Dummy
};

/* ~ [ Resources ] ~ */
new const gls_Primary_View_Model[] = "models/Custom_Weapons/Electron_VII/v_electron7.mdl";
new const gls_Primary_Player_Model[] = "models/Custom_Weapons/Electron_VII/p_electron7.mdl";
new const gls_Primary_World_Model[] = "models/Custom_Weapons/Electron_VII/w_electron7.mdl";

new const gls_Dummy_Model[] = "models/Common/null.mdl"; // Thanks to Dam / Kamrixx / Supreme

new const gls_Entity_Lightning_Cloud_Model[] = "models/Custom_Weapons/Electron_VII/ef_electron7_cloud.mdl";

new const gls_Entity_Missile_Sprite[] = "sprites/Custom_Weapons/Electron_VII/ef_electron7_missile.spr";
new const gls_Entity_Missile_Explode_Sprite[] = "sprites/Custom_Weapons/Electron_VII/ef_electron7_explosion.spr";

new const gls_Primary_Shoot_Sound[] = "Custom_Weapons/Electron_VII/electron7-1.wav";
new const gls_Primary_Missile_Sound[] = "Custom_Weapons/Electron_VII/electron7-2.wav";

new const gls_Entity_Missile_Explode_Sound[] = "Custom_Weapons/Electron_VII/electron7_lightning_all.wav";

#if defined df_Primary_WeaponList
    new const glsg_Primary_WeaponList_Resources[][] = 
    {
        "sprites/Common/640hud265.spr"
    };

    new const gls_Primary_WeaponList_TXT_File[] = "Custom_Weapons/Electron_VII/weapon_electron7";
#endif 

#if defined df_CustomMuzzleFlash
    new const gls_Entity_MuzzleFlash_Sprite[] = "sprites/Common/muzzleflash471.spr";
#endif

/* ~ [ Macros ] ~ */
#if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
    #define var_fire_bullets3_on var_iuser1
#endif

#define var_primary_attacks_count var_iuser2

// Entity 
#define var_child_entity var_iuser1
#define var_parent_entity var_iuser1
#define var_lightning_count var_iuser1

/* ~ [ Globals ] ~ */
new HookChain: gliv_HookChain_IsPenetrableEntity_Post;

new gliv_SpriteIndex_Missile_Explode;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("[Custom Primary] Electron-VII", "2.0", "Cristian505");

    // Hamsandwich
    RegisterHam(Ham_Weapon_PrimaryAttack,    gls_Primary_Reference,    "Ham_Primary_PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_SecondaryAttack,  gls_Primary_Reference,    "Ham_Primary_SecondaryAttack_Pre",  false);
    RegisterHam(Ham_Item_Deploy,             gls_Primary_Reference,    "Ham_Primary_Deploy_Post",           true);
    RegisterHam(Ham_Weapon_WeaponIdle,       gls_Primary_Reference,    "Ham_Primary_Idle_Pre",             false);
    RegisterHam(Ham_Item_Holster,            gls_Primary_Reference,    "Ham_Primary_Holster_Post",          true);
    RegisterHam(Ham_Spawn,                   gls_Primary_Reference,    "Ham_Primary_Spawn_Post",            true);

    #if defined df_Primary_WeaponList
        RegisterHam(Ham_Item_AddToPlayer, gls_Primary_Reference, "Ham_Primary_AddToPlayer_Post", true);
    #endif

    // ReAPI
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload, "RG_Primary_Reload_Post", true);
    RegisterHookChain(RG_CWeaponBox_SetModel, "RG_Primary_WeaponBox_SetModel_Pre", false);

    DisableHookChain(gliv_HookChain_IsPenetrableEntity_Post = RegisterHookChain(RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true));

    RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CleanUp_Map_Post", true);

    #if defined df_Primary_Holder_Max_Speed_Bonus
        RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "RG_Player_ResetMaxSpeed_Post", true);
    #endif

    #if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
        RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_Player_TakeDamage_Post", true);
    #endif

    // Fakemeta
    register_forward(FM_UpdateClientData, "FW_UpdateClientData_Post", true);

    // Client Commands
    register_clcmd("say /electron_VII", "ClientCommand_Give_Custom_Primary");

    #if defined df_Primary_WeaponList
        register_clcmd(gls_Primary_WeaponList_TXT_File, "ClientCommand_Hook_Primary");
    #endif
}

public plugin_precache()
{
    // Models
    SafePrecache_Model(gls_Primary_View_Model);
    SafePrecache_Model(gls_Primary_Player_Model);
    SafePrecache_Model(gls_Primary_World_Model);
    SafePrecache_Model(gls_Dummy_Model);
    SafePrecache_Model(gls_Entity_Lightning_Cloud_Model);

    // Sprites
    SafePrecache_Model(gls_Entity_Missile_Sprite);

    #if defined df_CustomMuzzleFlash
        SafePrecache_Model(gls_Entity_MuzzleFlash_Sprite);
    #endif

    gliv_SpriteIndex_Missile_Explode = SafePrecache_Model(gls_Entity_Missile_Explode_Sprite);

    // Generic
    #if defined df_Primary_WeaponList
        for(new i = 0; i < sizeof glsg_Primary_WeaponList_Resources; i++)
        {
            SafePrecache_Generic(glsg_Primary_WeaponList_Resources[i]);
        }

        new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", gls_Primary_WeaponList_TXT_File);

        SafePrecache_Generic(szWeaponList);
    #endif

    // Sounds
    SafePrecache_Sound(gls_Primary_Shoot_Sound);
    SafePrecache_Sound(gls_Primary_Missile_Sound);
    SafePrecache_Sound(gls_Entity_Missile_Explode_Sound);
}

public client_disconnected(iPlayer)
{
    UTIL_RemoveEntitiesByOwner(gls_Entity_Missile_Map_HitBox_Classname, iPlayer);
    UTIL_RemoveEntitiesByOwner(gls_Entity_Missile_Victim_HitBox_Classname, iPlayer);
    UTIL_RemoveEntitiesByOwner(gls_Entity_Lightning_Cloud_Classname, iPlayer);

    #if defined df_CustomMuzzleFlash
        UTIL_RemoveEntitiesByOwner(gls_Entity_MuzzleFlash_Classname, iPlayer);
    #endif
}

/* ~ [ Hamsandwich ] ~ */
public Ham_Primary_PrimaryAttack_Pre(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        // ~
        static iPrimaryClip; iPrimaryClip = get_member(iPrimary, m_Weapon_iClip);

        static iPlayer; iPlayer = get_member(iPrimary, m_pPlayer);

        if(!iPrimaryClip)
        {
            rg_weapon_reload(iPlayer, 0, 0, 0.0);

            return HAM_SUPERCEDE;
        }
        // ---

        // ~
        static Float: vecPlayerNewPunchAngles[3];

        static iPlayerFlags; iPlayerFlags = get_entvar(iPlayer, var_flags);

        if(iPlayerFlags & FL_DUCKING && iPlayerFlags & FL_ONGROUND)
        {
            vecPlayerNewPunchAngles[0] = random_float(glfg_Primary_Shoot_PunchAngles[3][0], glfg_Primary_Shoot_PunchAngles[3][1]);
            vecPlayerNewPunchAngles[1] = random_float(glfg_Primary_Shoot_PunchAngles[4][0], glfg_Primary_Shoot_PunchAngles[4][1]);
            vecPlayerNewPunchAngles[2] = random_float(glfg_Primary_Shoot_PunchAngles[5][0], glfg_Primary_Shoot_PunchAngles[5][1]);
        }
        else 
        {
            vecPlayerNewPunchAngles[0] = random_float(glfg_Primary_Shoot_PunchAngles[0][0], glfg_Primary_Shoot_PunchAngles[0][1]);
            vecPlayerNewPunchAngles[1] = random_float(glfg_Primary_Shoot_PunchAngles[1][0], glfg_Primary_Shoot_PunchAngles[1][1]);
            vecPlayerNewPunchAngles[2] = random_float(glfg_Primary_Shoot_PunchAngles[2][0], glfg_Primary_Shoot_PunchAngles[2][1]);
        }

        static Float: vecPlayerPunchAngles[3]; get_entvar(iPlayer, var_punchangle, vecPlayerPunchAngles);

        UTIL_SafePunchAngle(vecPlayerNewPunchAngles, vecPlayerPunchAngles, iPlayer);
        // ---

        // ~ 
        static Float: vecPlayerOrigin[3]; get_entvar(iPlayer, var_origin, vecPlayerOrigin);
        static Float: vecPlayerViewOfs[3]; get_entvar(iPlayer, var_view_ofs, vecPlayerViewOfs);

        static Float: vecPlayerEyePosition[3]; UTIL_GetPlayerEyePosition(vecPlayerEyePosition, vecPlayerOrigin, vecPlayerViewOfs);

        static Float: vecPlayerViewAngles[3]; get_entvar(iPlayer, var_v_angle, vecPlayerViewAngles);

        static Float: vecPlayerAimVector[3]; UTIL_GetPlayerAimVector(vecPlayerAimVector, vecPlayerViewAngles, vecPlayerPunchAngles);

        #if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
            set_entvar(iPrimary, var_fire_bullets3_on, 1);
        #endif

        EnableHookChain(gliv_HookChain_IsPenetrableEntity_Post);

        rg_fire_bullets3(iPrimary, iPlayer, vecPlayerEyePosition, vecPlayerAimVector, glf_Primary_Shoot_Accuracy, glf_Primary_Shoot_Distance, gli_Primary_Shoot_Penetration, gli_Primary_Shoot_Bullet_Type, gli_Primary_Shoot_Damage, glf_Primary_Shoot_Range_Modifier, false, get_member(iPlayer, random_seed));

        DisableHookChain(gliv_HookChain_IsPenetrableEntity_Post);

        #if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
            set_entvar(iPrimary, var_fire_bullets3_on, 0);
        #endif

        static iPrimaryAttacksCount; iPrimaryAttacksCount = get_entvar(iPrimary, var_primary_attacks_count);

        iPrimaryAttacksCount++;

        set_entvar(iPrimary, var_primary_attacks_count, iPrimaryAttacksCount);
        // ---

        // ~
        if(iPrimaryAttacksCount >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
        {
            if(iPrimaryAttacksCount == gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
            {
                UTIL_StatusIcon(MSG_ONE_UNRELIABLE, iPlayer, 2, "dmg_shock", 0, 230, 255);
            }

            UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Shoot_A, MSG_ONE_UNRELIABLE, 1);
        }
        else 
        {
            UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Shoot_A, MSG_ONE_UNRELIABLE, 0);
        }

        UTIL_PlayerAnimation(iPlayer, get_entvar(iPlayer, var_flags) & FL_DUCKING ? "crouch_shoot_m249" : "ref_shoot_m249");

        rh_emit_sound2(iPlayer, 0, CHAN_WEAPON, gls_Primary_Shoot_Sound);
        // ---

        // ~
        iPrimaryClip--;

        set_member(iPrimary, m_Weapon_iClip, iPrimaryClip);

        set_member(iPrimary, m_Weapon_flNextPrimaryAttack, glf_Primary_Shoot_Rate);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Shoot_A_Time);
        // ---

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public Ham_Primary_SecondaryAttack_Pre(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index && get_entvar(iPrimary, var_primary_attacks_count) >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
    {
        // ~
        new iPlayer = get_member(iPrimary, m_pPlayer);

        Missile(iPlayer);

        #if defined df_CustomMuzzleFlash
            MuzzleFlash(iPlayer);
        #endif

        UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Shoot_B, MSG_ONE_UNRELIABLE, 0);

        UTIL_PlayerAnimation(iPlayer, get_entvar(iPlayer, var_flags) & FL_DUCKING ? "crouch_shoot_knife" : "ref_shoot_knife");

        UTIL_StatusIcon(MSG_ONE, iPlayer, 0, "dmg_shock", 0, 0, 0);

        rh_emit_sound2(iPlayer, 0, CHAN_WEAPON, gls_Primary_Missile_Sound);

        new Float: vecPlayerPunchAngles[3]; get_entvar(iPlayer, var_punchangle, vecPlayerPunchAngles);

        new Float: vecPlayerNewPunchAngles[3]; 
        vecPlayerNewPunchAngles[0] = random_float(-7.0, -10.0); // Vertical
        vecPlayerNewPunchAngles[1] = random_float(-1.5, 1.5); // Horizontal
        vecPlayerNewPunchAngles[2] = random_float(-1.5, 1.5); // Diagonal

        UTIL_SafePunchAngle(vecPlayerNewPunchAngles, vecPlayerPunchAngles, iPlayer);

        set_member(iPlayer, m_flNextAttack, glf_Primary_Post_Ability_Next_Attack_Time);
        // ---

        // ~
        set_entvar(iPrimary, var_primary_attacks_count, 0);

        set_member(iPrimary, m_Weapon_flNextPrimaryAttack, glf_Primary_Post_Ability_Next_Attack_Time);
        set_member(iPrimary, m_Weapon_flNextSecondaryAttack, glf_Primary_Post_Ability_Next_Attack_Time);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Shoot_B_Time);
        // ---
    }
}

public Ham_Primary_Deploy_Post(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        new iPlayer = get_member(iPrimary, m_pPlayer);

        set_entvar(iPlayer, var_viewmodel, gls_Primary_View_Model);
        set_entvar(iPlayer, var_weaponmodel, gls_Primary_Player_Model);

        UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Dummy, MSG_ONE_UNRELIABLE, 0);

        UTIL_PlayerAnimation(iPlayer, get_entvar(iPlayer, var_flags) & FL_DUCKING ? "crouch_aim_m249" : "ref_aim_m249");

        if(get_entvar(iPrimary, var_primary_attacks_count) >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
        {
            UTIL_StatusIcon(MSG_ONE_UNRELIABLE, iPlayer, 2, "dmg_shock", 0, 230, 255);
        }

        set_member(iPrimary, m_flLastEventCheck, Float: get_gametime() + 0.1);

        set_member(iPlayer, m_flNextAttack, glf_Primary_Deploy_Next_Attack_Time);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Deploy_Time);
    }
}

public Ham_Primary_Idle_Pre(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index && get_member(iPrimary, m_Weapon_flTimeWeaponIdle) <= 0.0)
    {
        if(get_entvar(iPrimary, var_primary_attacks_count) >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
        {
            UTIL_SetViewModelAnim(get_member(iPrimary, m_pPlayer), gli_Primary_View_Model_Animation_Idle, MSG_ONE_UNRELIABLE, 1);
        }
        else 
        {
            UTIL_SetViewModelAnim(get_member(iPrimary, m_pPlayer), gli_Primary_View_Model_Animation_Idle, MSG_ONE_UNRELIABLE, 0);
        }

        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Idle_Time);

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public Ham_Primary_Holster_Post(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        set_member(iPrimary, m_Weapon_flNextPrimaryAttack, 0.0);
        set_member(iPrimary, m_Weapon_flNextSecondaryAttack, 0.0);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, 0.0);

        new iPlayer = get_member(iPrimary, m_pPlayer);

        set_member(iPlayer, m_flNextAttack, 0.0);

        #if defined df_CustomMuzzleFlash
            UTIL_RemoveEntitiesByOwner(gls_Entity_MuzzleFlash_Classname, iPlayer);
        #endif

        UTIL_StatusIcon(MSG_ONE, iPlayer, 0, "dmg_shock", 0, 0, 0);
    }
}

public Ham_Primary_Spawn_Post(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        set_member(iPrimary, m_Weapon_iStateSecondaryAttack, WEAPON_SECONDARY_ATTACK_SET);

        set_member(iPrimary, m_Weapon_iClip, gli_Primary_Default_Clip);
        set_member(iPrimary, m_Weapon_iDefaultAmmo, gli_Primary_Default_Ammo);

        rg_set_iteminfo(iPrimary, ItemInfo_iMaxClip, gli_Primary_Max_Clip);
        rg_set_iteminfo(iPrimary, ItemInfo_iMaxAmmo1, gli_Primary_Max_Ammo);
    }
}

#if defined df_Primary_WeaponList
    public Ham_Primary_AddToPlayer_Post(iPrimary, iPlayer)
    {
        if(!is_nullent(iPrimary))
        {
            new iUniqueIndex = get_entvar(iPrimary, var_impulse);

            if(iUniqueIndex == gli_Primary_Unique_Index)
            {
                UTIL_WeaponList(MSG_ONE, iPlayer, gls_Primary_WeaponList_TXT_File, glig_Primary_WeaponList_Coords[0], glig_Primary_WeaponList_Coords[1], glig_Primary_WeaponList_Coords[2], glig_Primary_WeaponList_Coords[3], glig_Primary_WeaponList_Coords[4], glig_Primary_WeaponList_Coords[5], glig_Primary_WeaponList_Coords[6], glig_Primary_WeaponList_Coords[7]);
            }
            else if(!iUniqueIndex)
            {
                new szWeaponName[MAX_NAME_LENGTH]; rg_get_iteminfo(iPrimary, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

                UTIL_WeaponList(MSG_ONE, iPlayer, szWeaponName, get_member(iPrimary, m_Weapon_iPrimaryAmmoType), rg_get_iteminfo(iPrimary, ItemInfo_iMaxAmmo1), get_member(iPrimary, m_Weapon_iSecondaryAmmoType), rg_get_iteminfo(iPrimary, ItemInfo_iMaxAmmo2), rg_get_iteminfo(iPrimary, ItemInfo_iSlot), rg_get_iteminfo(iPrimary, ItemInfo_iPosition), rg_get_iteminfo(iPrimary, ItemInfo_iId), rg_get_iteminfo(iPrimary, ItemInfo_iFlags));
            }
        }
    }
#endif

/* ~ [ ReAPI ] ~ */
public RG_Primary_Reload_Post(iPrimary)
{
    if(get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        new iPlayer = get_member(iPrimary, m_pPlayer);

        if(get_member(iPrimary, m_Weapon_iClip) < rg_get_iteminfo(iPrimary, ItemInfo_iMaxClip) && get_member(iPlayer, m_rgAmmo, get_member(iPrimary, m_Weapon_iPrimaryAmmoType)))
        {
            if(get_entvar(iPrimary, var_primary_attacks_count) >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
            {
                UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Reload, MSG_ONE_UNRELIABLE, 1);
            }
            else 
            {
                UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Reload, MSG_ONE_UNRELIABLE, 0);
            }

            UTIL_PlayerAnimation(iPlayer, get_entvar(iPlayer, var_flags) & FL_DUCKING ? "crouch_reload_m249" : "ref_reload_m249");

            set_member(iPlayer, m_flNextAttack, glf_Primary_Reload_Time);
            set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Reload_Time);
        }
    }
}

public RG_Primary_WeaponBox_SetModel_Pre(iWeaponBox)
{
    new iPrimary = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, PRIMARY_WEAPON_SLOT);

    if(iPrimary != NULLENT && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index) 
    { 
        SetHookChainArg(2, ATYPE_STRING, gls_Primary_World_Model); 
    }

    return HC_CONTINUE;
}

public RG_IsPenetrableEntity_Post(Float: vecStartOrigin[3], Float: vecEndOrigin[3], iPlayer, iHit)
{
    static iPointContents; iPointContents = engfunc(EngFunc_PointContents, vecEndOrigin);

    if(iPointContents != CONTENTS_SKY)
    {
        // World || Valid BSP Entity
        if(!iHit || (!is_nullent(iHit) && !(get_entvar(iHit, var_flags) & FL_KILLME) && ExecuteHam(Ham_IsBSPModel, iHit)))
        {
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndOrigin, 0);
            write_byte(TE_GUNSHOTDECAL);
            engfunc(EngFunc_WriteCoord, vecEndOrigin[0]);
            engfunc(EngFunc_WriteCoord, vecEndOrigin[1]);
            engfunc(EngFunc_WriteCoord, vecEndOrigin[2]);
            write_short(iHit);
            write_byte(41); // forums.alliedmods.net/showthread.php?t=20448
            message_end();

            if(iPointContents != CONTENTS_WATER)
            {
                static Float: vecPlaneNormal[3]; global_get(glb_trace_plane_normal, vecPlaneNormal);

                for(new i = 0; i < 3; i++)
                {
                    vecPlaneNormal[i] *= 8.0;
                }

                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndOrigin, 0);
                write_byte(TE_STREAK_SPLASH);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[0]);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[1]);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[2]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[0]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[1]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[2]);
                write_byte(0); // Color
                write_short(8); // Count
                write_short(11); // Speed
                write_short(60); // Noise
                message_end();

                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndOrigin, 0);
                write_byte(TE_STREAK_SPLASH);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[0]);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[1]);
                engfunc(EngFunc_WriteCoord, vecEndOrigin[2]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[0]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[1]);
                engfunc(EngFunc_WriteCoord, vecPlaneNormal[2]);
                write_byte(3); // Color
                write_short(8); // Count
                write_short(11); // Speed
                write_short(60); // Noise
                message_end();
            }
        }
    }
}

public RG_CleanUp_Map_Post()
{
    UTIL_RemoveEntitiesByClassname(gls_Entity_Missile_Map_HitBox_Classname);
    UTIL_RemoveEntitiesByClassname(gls_Entity_Missile_Victim_HitBox_Classname);
    UTIL_RemoveEntitiesByClassname(gls_Entity_Lightning_Cloud_Classname);

    #if defined df_CustomMuzzleFlash
        UTIL_RemoveEntitiesByClassname(gls_Entity_MuzzleFlash_Classname);
    #endif
}

#if defined df_Primary_Holder_Max_Speed_Bonus
    public RG_Player_ResetMaxSpeed_Post(iPlayer)
    {
        if(is_user_alive(iPlayer))
        {   
            static iActiveItem; iActiveItem = get_member(iPlayer, m_pActiveItem);

            if(!is_nullent(iActiveItem) && get_entvar(iActiveItem, var_impulse) == gli_Primary_Unique_Index)
            {
                static Float: flPlayerMaxSpeed; flPlayerMaxSpeed = get_entvar(iPlayer, var_maxspeed);

                if(flPlayerMaxSpeed > 1.0) // Prevent overriding mp_freezetime
                {
                    flPlayerMaxSpeed = flPlayerMaxSpeed + glf_Primary_Holder_Max_Speed_Bonus;

                    set_entvar(iPlayer, var_maxspeed, flPlayerMaxSpeed);
                }
            }
        }
    }
#endif

#if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
    public RG_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float: flDamage, iDamageType)
    {
        if(is_user_alive(iAttacker) && get_member(iAttacker, m_iTeam) != get_member(iVictim, m_iTeam))
        {
            static iPrimary; iPrimary = get_member(iAttacker, m_pActiveItem);

            if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index && get_entvar(iPrimary, var_fire_bullets3_on))
            {
                #if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier
                    set_member(iVictim, m_flVelocityModifier, glf_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier);
                #endif 

                #if defined df_Primary_Shoot_Victim_Post_Damage_Knockback
                    static Float: vecVictimVelocity[3]; get_entvar(iVictim, var_velocity, vecVictimVelocity);
                    
                    static Float: vecAttackerViewAngles[3]; get_entvar(iAttacker, var_v_angle, vecAttackerViewAngles);
                    static Float: vecAttackerViewForward[3]; angle_vector(vecAttackerViewAngles, ANGLEVECTOR_FORWARD, vecAttackerViewForward);

                    UTIL_AimKnockBack(vecVictimVelocity, vecAttackerViewForward, glf_Primary_Shoot_Victim_Post_Damage_Knockback_Strenght, glf_Primary_Shoot_Victim_Post_Damage_Knockback_Up_Strenght, iVictim);
                #endif
            }
        }
    }
#endif

/* ~ [ Fakemeta ] ~ */
public FW_UpdateClientData_Post(iPlayer, iSendWeapons, iClientData)
{
    if(is_user_alive(iPlayer))
    {
        static iActiveItem; iActiveItem = get_member(iPlayer, m_pActiveItem);
        
        if(!is_nullent(iActiveItem) && get_entvar(iActiveItem, var_impulse) == gli_Primary_Unique_Index)
        {
            set_cd(iClientData, CD_flNextAttack, 2.0);

            static Float: flLastEventCheck; flLastEventCheck = get_member(iActiveItem, m_flLastEventCheck);

            if(!flLastEventCheck)
            {
	            set_cd(iClientData, CD_WeaponAnim, gli_Primary_View_Model_Animation_Dummy);
            }
            else if(Float: get_gametime() >= flLastEventCheck)
            {   
                if(get_entvar(iActiveItem, var_primary_attacks_count) >= gli_Primary_Min_Primary_Attacks_Count_Ability_Ready)
                {
                    UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Deploy, MSG_ONE_UNRELIABLE, 1);
                }
                else 
                {
                    UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Deploy, MSG_ONE_UNRELIABLE, 0);
                }

                set_member(iActiveItem, m_flLastEventCheck, 0.0);
            }
        }
    }
}

/* ~ [ Client Commands ] ~ */
public ClientCommand_Give_Custom_Primary(iPlayer)
{
    if(is_user_alive(iPlayer))
    {
        Give_Custom_Primary(iPlayer);
    }
}

#if defined df_Primary_WeaponList
    public ClientCommand_Hook_Primary(iPlayer)
    {
        engclient_cmd(iPlayer, gls_Primary_Reference);

        return PLUGIN_HANDLED;
    }
#endif

/* ~ [ Custom Functions ] ~ */
Give_Custom_Primary(iPlayer)
{
    new iPrimary = rg_give_custom_item(iPlayer, gls_Primary_Reference, gli_Primary_GiveType, gli_Primary_Unique_Index);

    if(!is_nullent(iPrimary))
    {
        new iAmmoType = get_member(iPrimary, m_Weapon_iPrimaryAmmoType);

        if(get_member(iPlayer, m_rgAmmo, iAmmoType) < gli_Primary_Default_Ammo)
        {
            set_member(iPlayer, m_rgAmmo, gli_Primary_Default_Ammo, iAmmoType);
        }
    }
}

Missile(iPlayer)
{
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) > 100)
    {
        new iParentEntity = rg_create_entity("info_target");

        if(!is_nullent(iParentEntity))
        {
            set_entvar(iParentEntity, var_classname, gls_Entity_Missile_Map_HitBox_Classname);
            set_entvar(iParentEntity, var_owner, iPlayer);
            set_entvar(iParentEntity, var_solid, SOLID_TRIGGER);
            set_entvar(iParentEntity, var_movetype, MOVETYPE_FLY);

            // ~
            new Float: vecPlayerOrigin[3]; get_entvar(iPlayer, var_origin, vecPlayerOrigin);
            new Float: vecPlayerViewOfs[3]; get_entvar(iPlayer, var_view_ofs, vecPlayerViewOfs);

            new Float: vecPlayerViewAngles[3]; get_entvar(iPlayer, var_v_angle, vecPlayerViewAngles);

            new Float: vecPlayerViewForward[3]; angle_vector(vecPlayerViewAngles, ANGLEVECTOR_FORWARD, vecPlayerViewForward);
            new Float: vecPlayerViewRight[3]; angle_vector(vecPlayerViewAngles, ANGLEVECTOR_RIGHT, vecPlayerViewRight);
            new Float: vecPlayerViewUp[3]; angle_vector(vecPlayerViewAngles, ANGLEVECTOR_UP, vecPlayerViewUp);

            new Float: vecStartOrigin[3]; UTIL_GetPlayerViewOrigin(vecPlayerOrigin, vecPlayerViewOfs, vecStartOrigin, vecPlayerViewForward, 0.0, vecPlayerViewRight, 9.0, vecPlayerViewUp, 3.0);

            new Float: vecEndOrigin[3]; fm_get_aim_origin(iPlayer, vecEndOrigin);
            // ---

            // ~
            new Float: vecDirection[3]; xs_vec_sub(vecEndOrigin, vecStartOrigin, vecDirection);

            xs_vec_normalize(vecDirection, vecDirection);

            new Float: vecVelocity[3]; xs_vec_mul_scalar(vecDirection, glf_Entity_Missile_Fly_Speed, vecVelocity);

            set_entvar(iParentEntity, var_velocity, vecVelocity);
            // ---

            engfunc(EngFunc_SetOrigin, iParentEntity, vecStartOrigin);
            engfunc(EngFunc_SetModel, iParentEntity, gls_Dummy_Model);
            engfunc(EngFunc_SetSize, iParentEntity, {-0.1, -0.1, -0.1}, {0.1, 0.1, 0.1});

            SetTouch(iParentEntity, "RG_Entity_Missile_Map_Touch");

            if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) > 100)
            {
                new iChildEntity = rg_create_entity("info_target");

                if(!is_nullent(iChildEntity))
                {
                    set_entvar(iParentEntity, var_child_entity, iChildEntity);
                    set_entvar(iChildEntity, var_parent_entity, iParentEntity);

                    set_entvar(iChildEntity, var_classname, gls_Entity_Missile_Victim_HitBox_Classname);
                    set_entvar(iChildEntity, var_owner, iPlayer);
                    set_entvar(iChildEntity, var_solid, SOLID_TRIGGER);
                    set_entvar(iChildEntity, var_movetype, MOVETYPE_FOLLOW);
                    set_entvar(iChildEntity, var_aiment, iParentEntity);
                    set_entvar(iChildEntity, var_scale, 0.35);
                    set_entvar(iChildEntity, var_rendermode, kRenderTransAdd);
                    set_entvar(iChildEntity, var_renderamt, 255.0);

                    engfunc(EngFunc_SetOrigin, iChildEntity, vecStartOrigin);
                    engfunc(EngFunc_SetModel, iChildEntity, gls_Entity_Missile_Sprite);
                    engfunc(EngFunc_SetSize, iChildEntity, {-50.0, -50.0, -50.0}, {50.0, 50.0, 50.0});

                    SetTouch(iChildEntity, "RG_Entity_Missile_Victim_Touch");
                }
            }
        }
    }
}

Lightning_Cloud(iOwner, Float: vecSpawnOrigin[3])
{
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) > 100)
    {
        new iEntity = rg_create_entity("info_target");

        if(!is_nullent(iEntity))
        {
            set_entvar(iEntity, var_classname, gls_Entity_Lightning_Cloud_Classname);
            set_entvar(iEntity, var_owner, iOwner);
            set_entvar(iEntity, var_solid, SOLID_NOT);
            set_entvar(iEntity, var_movetype, MOVETYPE_TOSS);
            set_entvar(iEntity, var_nextthink, Float: get_gametime());
            set_entvar(iEntity, var_gravity, 9999999.0);
            set_entvar(iEntity, var_rendermode, kRenderTransAdd);
            set_entvar(iEntity, var_renderamt, 255.0);

            engfunc(EngFunc_SetOrigin, iEntity, vecSpawnOrigin);
            engfunc(EngFunc_SetModel, iEntity, gls_Entity_Lightning_Cloud_Model);
            engfunc(EngFunc_SetSize, iEntity, {-0.1, -0.1, -0.1}, {0.1, 0.1, 0.1});

            SetThink(iEntity, "RG_Entity_Cloud_Think");

            UTIL_SetEntityAnim(iEntity, 0);
        }
    }
}

#if defined df_CustomMuzzleFlash
    MuzzleFlash(iPlayer)
    {
        if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) > 100)
        {
            new iSprite = rg_create_entity("env_sprite");

            if(!is_nullent(iSprite))
            {
                set_entvar(iSprite, var_classname, gls_Entity_MuzzleFlash_Classname);
                set_entvar(iSprite, var_owner, iPlayer);
                set_entvar(iSprite, var_aiment, iPlayer);
                set_entvar(iSprite, var_body, 1);
                set_entvar(iSprite, var_effects, get_entvar(iSprite, var_effects) | EF_OWNER_VISIBILITY);
                set_entvar(iSprite, var_nextthink, Float: get_gametime() + 0.0667);
                set_entvar(iSprite, var_scale, 0.25);
                set_entvar(iSprite, var_rendermode, kRenderTransAdd);
                set_entvar(iSprite, var_renderamt, 255.0);

                engfunc(EngFunc_SetModel, iSprite, gls_Entity_MuzzleFlash_Sprite);

                dllfunc(DLLFunc_Spawn, iSprite);

                SetThink(iSprite, "RG_Sprite_MuzzleFlash_Think");
            }
        }
    }
#endif

public RG_Entity_Missile_Map_Touch(iParentEntity, iTouch)
{
    if(!is_nullent(iParentEntity) && FClassnameIs(iParentEntity, gls_Entity_Missile_Map_HitBox_Classname) && !is_user_alive(iTouch) && !FClassnameIs(iTouch, gls_Entity_Missile_Victim_HitBox_Classname))
    {
        new Float: vecEntityOrigin[3]; get_entvar(iParentEntity, var_origin, vecEntityOrigin);

        new iPointContents = engfunc(EngFunc_PointContents, vecEntityOrigin);

        if(iPointContents != CONTENTS_SKY)
        {
            // ~
            new iOwner = get_entvar(iParentEntity, var_owner);

            new iVictim = NULLENT;

            while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecEntityOrigin, glf_Entity_Missile_Explode_Damage_Radius)) > 0)
            {
                if(is_user_alive(iVictim))
                {
                    if(get_member(iOwner, m_iTeam) != get_member(iVictim, m_iTeam))
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iParentEntity, iOwner, glf_Entity_Missile_Explode_Damage, gli_Entity_Missile_Explode_Damage_Type);

                        set_member(iVictim, m_flVelocityModifier, glf_Entity_Missile_Explode_Victim_Post_Damage_Velocity_Modifier);
                    }
                }
                else if(!is_nullent(iVictim) && !(get_entvar(iVictim, var_spawnflags) & SF_BREAK_TRIGGER_ONLY))
                {
                    new Float: flHealth; get_entvar(iVictim, var_health, flHealth);

                    if(flHealth > 0.0)
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iParentEntity, iOwner, glf_Entity_Missile_Explode_Damage, gli_Entity_Missile_Explode_Damage_Type);
                    }
                }
            }
            // ---

            // ~
            Lightning_Cloud(iOwner, vecEntityOrigin);

            vecEntityOrigin[2] += 115.0;

            UTIL_TE_Explosion(MSG_PVS, vecEntityOrigin, gliv_SpriteIndex_Missile_Explode, 34, 26, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
            UTIL_TE_Dlight(MSG_PVS, vecEntityOrigin, 40, 255, 255, 255, 6, 70);

            rh_emit_sound2(iParentEntity, 0, CHAN_AUTO, gls_Entity_Missile_Explode_Sound);
            // ---

            // ~
            new iChildEntity = get_entvar(iParentEntity, var_child_entity);

            if(!is_nullent(iChildEntity))
            {
                rg_remove_entity(iChildEntity);
            }

            rg_remove_entity(iParentEntity);
            // ---
        }
        else 
        {
            new iChildEntity = get_entvar(iParentEntity, var_child_entity);

            if(!is_nullent(iChildEntity))
            {
                rg_remove_entity(iChildEntity);
            }

            rg_remove_entity(iParentEntity);
        }
    }
}

public RG_Entity_Missile_Victim_Touch(iChildEntity, iTouch)
{
    if(!is_nullent(iChildEntity) && FClassnameIs(iChildEntity, gls_Entity_Missile_Victim_HitBox_Classname) && is_user_alive(iTouch))
    {
        static iOwner; iOwner = get_entvar(iChildEntity, var_owner);

        if(iTouch != iOwner && get_member(iOwner, m_iTeam) != get_member(iTouch, m_iTeam))
        {
            // ~
            new Float: vecEntityOrigin[3]; get_entvar(iChildEntity, var_origin, vecEntityOrigin);

            new iVictim = NULLENT;

            while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecEntityOrigin, glf_Entity_Missile_Explode_Damage_Radius)) > 0)
            {
                if(is_user_alive(iVictim))
                {
                    if(get_member(iOwner, m_iTeam) != get_member(iVictim, m_iTeam))
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iChildEntity, iOwner, glf_Entity_Missile_Explode_Damage, gli_Entity_Missile_Explode_Damage_Type);

                        set_member(iVictim, m_flVelocityModifier, glf_Entity_Missile_Explode_Victim_Post_Damage_Velocity_Modifier);
                    }
                }
                else if(!is_nullent(iVictim) && !(get_entvar(iVictim, var_spawnflags) & SF_BREAK_TRIGGER_ONLY))
                {
                    new Float: flHealth; get_entvar(iVictim, var_health, flHealth);

                    if(flHealth > 0.0)
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iChildEntity, iOwner, glf_Entity_Missile_Explode_Damage, gli_Entity_Missile_Explode_Damage_Type);
                    }
                }
            }
            // ---

            // ~
            Lightning_Cloud(iOwner, vecEntityOrigin);

            vecEntityOrigin[2] += 115.0;

            UTIL_TE_Explosion(MSG_PVS, vecEntityOrigin, gliv_SpriteIndex_Missile_Explode, 34, 26, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
            UTIL_TE_Dlight(MSG_PVS, vecEntityOrigin, 40, 255, 255, 255, 6, 70);

            rh_emit_sound2(iChildEntity, 0, CHAN_AUTO, gls_Entity_Missile_Explode_Sound);
            // ---

            // ~
            new iParentEntity = get_entvar(iChildEntity, var_parent_entity);

            if(!is_nullent(iParentEntity))
            {
                rg_remove_entity(iParentEntity);
            }

            rg_remove_entity(iChildEntity);
            // ---
        }
    }
}

public RG_Entity_Cloud_Think(iEntity)
{
    if(!is_nullent(iEntity) && FClassnameIs(iEntity, gls_Entity_Lightning_Cloud_Classname))
    {
        new iLightningCount = get_entvar(iEntity, var_lightning_count);

        if(iLightningCount < gli_Entity_Lightning_Cloud_Max_Lightning_Count)
        {
            // ~
            static Float: vecEntityOrigin[3]; get_entvar(iEntity, var_origin, vecEntityOrigin);

            static iOwner; iOwner = get_entvar(iEntity, var_owner);

            new iVictim = NULLENT;

            while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecEntityOrigin, glf_Entity_Lightning_Cloud_Damage_Radius)) > 0)
            {
                if(is_user_alive(iVictim))
                {
                    if(get_member(iOwner, m_iTeam) != get_member(iVictim, m_iTeam))
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, glf_Entity_Lightning_Cloud_Damage, gli_Entity_Lightning_Cloud_Damage_Type);

                        set_member(iVictim, m_flVelocityModifier, glf_Entity_Lightning_Cloud_Victim_Post_Damage_Velocity_Modifier);
                    }
                }
                else if(!is_nullent(iVictim) && !(get_entvar(iVictim, var_spawnflags) & SF_BREAK_TRIGGER_ONLY))
                {
                    new Float: flHealth; get_entvar(iVictim, var_health, flHealth);

                    if(flHealth > 0.0)
                    {
                        ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, glf_Entity_Lightning_Cloud_Damage, gli_Entity_Lightning_Cloud_Damage_Type);
                    }
                }
            }
            // ---

            // ~
            iLightningCount++;

            if(iLightningCount == gli_Entity_Lightning_Cloud_Max_Lightning_Count)
            {
                rg_remove_entity(iEntity);
            }
            else 
            {   
                set_entvar(iEntity, var_lightning_count, iLightningCount);

                set_entvar(iEntity, var_nextthink, Float: get_gametime() + glf_Entity_Lightning_Cloud_Next_Think);
            }
            // ---
        }
    }
}

#if defined df_CustomMuzzleFlash
    public RG_Sprite_MuzzleFlash_Think(iSprite)
    {
        if(!is_nullent(iSprite) && FClassnameIs(iSprite, gls_Entity_MuzzleFlash_Classname))
        {
            static Float: flSpriteFrame; flSpriteFrame = get_entvar(iSprite, var_frame);

            if(flSpriteFrame < 15.0)
            {
                flSpriteFrame += 1.0;

                set_entvar(iSprite, var_frame, flSpriteFrame);
                set_entvar(iSprite, var_nextthink, Float: get_gametime() + 0.0667);
            }
            else 
            {
                rg_remove_entity(iSprite);
            }
        }
    }
#endif

/* ~ [ Stocks ] ~ */
stock UTIL_SetViewModelAnim(iReceiver, iAnimation, iReceiverMsgDest, iBody) 
{
    set_entvar(iReceiver, var_weaponanim, iAnimation);

    message_begin(iReceiverMsgDest, SVC_WEAPONANIM, _, iReceiver);
    write_byte(iAnimation);
    write_byte(iBody);
    message_end();
}

stock UTIL_SetEntityAnim(iEntity, iSequence)
{
	set_entvar(iEntity, var_frame, 1.0);
	set_entvar(iEntity, var_framerate, 1.0);
	set_entvar(iEntity, var_animtime, get_gametime());
	set_entvar(iEntity, var_sequence, iSequence);
}

public UTIL_PlayerAnimation(iPlayer, szAnimation[])
{
    new Float: flFrameRate;
    new Float: flGroundSpeed;

    new bool: bLoops;

    new iAnimation;

    if((iAnimation = lookup_sequence(iPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1)
    {
        iAnimation = 0;
    }

    set_entvar(iPlayer, var_frame, 0.0);
    set_entvar(iPlayer, var_framerate, 1.0);
    set_entvar(iPlayer, var_animtime, Float: get_gametime());
    set_entvar(iPlayer, var_sequence, iAnimation);

    set_member(iPlayer, m_fSequenceLoops, bLoops);
    set_member(iPlayer, m_fSequenceFinished, 0);
    set_member(iPlayer, m_flFrameRate, flFrameRate);
    set_member(iPlayer, m_flGroundSpeed, flGroundSpeed);

    new Float: flGameTime = get_gametime();

    set_member(iPlayer, m_flLastEventCheck, flGameTime);
    set_member(iPlayer, m_Activity, 28);
    set_member(iPlayer, m_IdealActivity, 28);

    set_pdata_float(iPlayer, 220, flGameTime, 5); // 220 = m_flLastAttackTime | 5 = linux_diff_player 
}

stock UTIL_WeaponList(iDest, iReceiver, const szWeaponList[], iPrimaryAmmoType, iMaxPrimaryAmmo, iSecondaryAmmoType, iMaxSecondaryAmmo, iSlot, iPosition, iWeaponID, iFlags)
{
    static iMsgID_WeaponList;

    if(iMsgID_WeaponList || (iMsgID_WeaponList = get_user_msgid("WeaponList")))
    {
        message_begin(iDest, iMsgID_WeaponList, .player = iReceiver);
        write_string(szWeaponList);
        write_byte(iPrimaryAmmoType);
        write_byte(iMaxPrimaryAmmo);
        write_byte(iSecondaryAmmoType);
        write_byte(iMaxSecondaryAmmo);
        write_byte(iSlot);
        write_byte(iPosition);
        write_byte(iWeaponID);
        write_byte(iFlags);
        message_end();
    }
}

stock UTIL_StatusIcon(iDest, iPlayer, iStatus, const szSprite[], iR, iG, iB)
{
    static iMsgID_StatusIcon;

    if(!iMsgID_StatusIcon)
    {
        iMsgID_StatusIcon = get_user_msgid("StatusIcon");
    }

    message_begin(iDest, iMsgID_StatusIcon, _, iPlayer);
    write_byte(iStatus); // 0 = Hide | 1 = Show | 2 = Flicker
    write_string(szSprite);
    write_byte(iR);
    write_byte(iG);
    write_byte(iB);
    message_end();
}

stock UTIL_GetPlayerAimVector(Float: vecResultPlayerAimVector[3], Float: vecPlayerViewAngles[3], Float: vecPlayerPunchAngles[3])
{
    vecResultPlayerAimVector[0] = vecPlayerViewAngles[0] + vecPlayerPunchAngles[0];
    vecResultPlayerAimVector[1] = vecPlayerViewAngles[1] + vecPlayerPunchAngles[1];
    vecResultPlayerAimVector[2] = vecPlayerViewAngles[2] + vecPlayerPunchAngles[2];

    angle_vector(vecResultPlayerAimVector, ANGLEVECTOR_FORWARD, vecResultPlayerAimVector);
}

stock UTIL_GetPlayerEyePosition(Float: vecResultPlayerEyePosition[3], Float: vecPlayerOrigin[3], Float: vecPlayerViewOfs[3])
{
    vecResultPlayerEyePosition[0] = vecPlayerOrigin[0] + vecPlayerViewOfs[0];
    vecResultPlayerEyePosition[1] = vecPlayerOrigin[1] + vecPlayerViewOfs[1];
    vecResultPlayerEyePosition[2] = vecPlayerOrigin[2] + vecPlayerViewOfs[2];
}

stock UTIL_AimKnockBack(Float: vecVictimVelocity[3], Float: vecAttackerViewForward[3], Float: flKnockbackStrenght, Float: flKnockbackUpStrenght, iVictim)
{
    vecVictimVelocity[0] = vecVictimVelocity[0] + vecAttackerViewForward[0] * flKnockbackStrenght;
    vecVictimVelocity[1] = vecVictimVelocity[1] + vecAttackerViewForward[1] * flKnockbackStrenght;
    vecVictimVelocity[2] = vecVictimVelocity[2] + flKnockbackUpStrenght;

    set_entvar(iVictim, var_velocity, vecVictimVelocity);
}

stock UTIL_SafePunchAngle(Float: vecPlayerNewPunchAngles[3], Float: vecPlayerPunchAngles[3], iPlayer)
{
    for(new i = 0; i < 3; i++)
    {
        if(floatabs(vecPlayerNewPunchAngles[i]) >= floatabs(vecPlayerPunchAngles[i]))
        {
            vecPlayerPunchAngles[i] = vecPlayerNewPunchAngles[i];
        }
    }

    set_entvar(iPlayer, var_punchangle, vecPlayerPunchAngles);
}

stock UTIL_GetPlayerViewOrigin(Float: vecPlayerOrigin[3], Float: vecPlayerViewOfs[3], Float: vecResultOrigin[3], Float: vecPlayerViewForward[3], Float: flForward, Float: vecPlayerViewRight[3], Float: flRight, Float: vecPlayerViewUp[3], Float: flUp)
{
    xs_vec_add(vecPlayerOrigin, vecPlayerViewOfs, vecPlayerOrigin);

    vecResultOrigin[0] = vecPlayerOrigin[0] + vecPlayerViewForward[0] * flForward + vecPlayerViewRight[0] * flRight + vecPlayerViewUp[0] * flUp;
    vecResultOrigin[1] = vecPlayerOrigin[1] + vecPlayerViewForward[1] * flForward + vecPlayerViewRight[1] * flRight + vecPlayerViewUp[1] * flUp;
    vecResultOrigin[2] = vecPlayerOrigin[2] + vecPlayerViewForward[2] * flForward + vecPlayerViewRight[2] * flRight + vecPlayerViewUp[2] * flUp;
}

stock UTIL_RemoveEntitiesByClassname(const szClassName[])
{   
    new iEntity = NULLENT;

    while((iEntity = rg_find_ent_by_class(iEntity, szClassName)) > 0)
    {
        if(!is_nullent(iEntity))
        {
            rg_remove_entity(iEntity);
        }
    }
}

stock UTIL_RemoveEntitiesByOwner(const szClassName[], iOwner)
{
    new iEntity = NULLENT;

    while(rg_find_ent_by_owner(iEntity, szClassName, iOwner))
    {
        if(!is_nullent(iEntity))
        {
            rg_remove_entity(iEntity);
        }
    }
}

stock UTIL_TE_Explosion(iDest, Float: vecOrigin[3], iSpriteIndex, iScale, iFrameRate, iFlags)
{
    engfunc(EngFunc_MessageBegin, iDest, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_EXPLOSION);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
    engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
    engfunc(EngFunc_WriteCoord, vecOrigin[2]); // Position Z
    write_short(iSpriteIndex);
    write_byte(iScale);
    write_byte(iFrameRate);
    write_byte(iFlags);
    message_end();
}

stock UTIL_TE_Dlight(iDest, Float: vecOrigin[3], iRadius, iR, iG, iB, iLife, iDecay)
{
    engfunc(EngFunc_MessageBegin, iDest, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_DLIGHT);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_byte(iRadius);
    write_byte(iR);
    write_byte(iG);
    write_byte(iB);
    write_byte(iLife);
    write_byte(iDecay);
    message_end();
}

stock SafePrecache_Model(const szFileName[])
{
    if(file_exists(szFileName)) 
    {
        return engfunc(EngFunc_PrecacheModel, szFileName);
    }
    else 
    {
        set_fail_state("Model/Sprite <%s> not found. The plugin has been stopped.", szFileName);

        return 0;
    }
}

stock SafePrecache_Generic(const szFileName[])
{
    if(file_exists(szFileName)) 
    {
        return engfunc(EngFunc_PrecacheGeneric, szFileName);
    }
    else 
    {
        set_fail_state("Generic <%s> not found. The plugin has been stopped.", szFileName);

        return 0;
    }
}

stock SafePrecache_Sound(const szFileName[])
{
    if(file_exists(fmt("sound/%s", szFileName))) 
    {
        return engfunc(EngFunc_PrecacheSound, szFileName);
    }
    else 
    {
        set_fail_state("Sound <%s> not found. The plugin has been stopped.", szFileName);

        return 0;
    }
}