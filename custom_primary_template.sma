/*
    - Discord: cristian505
    
    - AMXX Workshop (Counter-Strike AMXX Discord Community): https://discord.gg/Ny69XZ2pcM
    - AMXX Workshop (YouTube): https://www.youtube.com/@amxxworkshop
    - AMXX Workshop (TikTok): https://www.tiktok.com/@amxx.workshop
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <reapi>

/* ~ [ Settings ] ~ */
new const gls_Primary_Reference[] = "weapon_ak47";

const Float: glf_Primary_Deploy_Next_Attack_Time = 0.615;
const Float: glf_Primary_Reload_Time = 1.65;

const GiveType: gli_Primary_GiveType = GT_APPEND; // reapi_gamedll_const.inc/GiveType

const gli_Primary_Unique_Index = 505123;

const gli_Primary_Default_Clip = 30;
const gli_Primary_Max_Clip = 30;

const gli_Primary_Default_Ammo = 255;
const gli_Primary_Max_Ammo = 255;

#define df_Primary_WeaponList
#define df_Primary_Holder_Max_Speed_Bonus

#if defined df_Primary_WeaponList
    new const glig_Primary_WeaponList_Coords[] = { 2, 90, -1, -1, 0, 1, 28, 0 }; 
    // https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
#endif

#if defined df_Primary_Holder_Max_Speed_Bonus
    const Float: glf_Primary_Holder_Max_Speed_Bonus = -10.0;
#endif 

// Primary Attack
new const Float: glfg_Primary_Shoot_PunchAngles[][] = 
{
    { -2.1, -2.79 }, // Vertical - Min & Max
    { -0.35, 0.35 }, // Horizontal - Min & Max
    { -0.1, 0.1 },  // Diagonal - Min & Max

    // FL_DUCKING & FL_ONGROUND
    { -1.1, -1.79 },
    { -0.35, 0.35 },
    { -0.1, 0.1 }
};

const Float: glf_Primary_Shoot_Rate = 0.115;
const Float: glf_Primary_Shoot_Accuracy = 0.0; // 0.0 = 100% Accurate
const Float: glf_Primary_Shoot_Distance = 8192.0; // 8192.0 Max
const Float: glf_Primary_Shoot_Range_Modifier = 1.0; // Damage Falloff : 1.0 = constant, < 1.0 drops, > 1.0 rises with distance

const Bullet: gli_Primary_Shoot_Bullet_Type = BULLET_PLAYER_762MM; // cssdk_const.inc/Bullet

const gli_Primary_Shoot_Damage = 10;
const gli_Primary_Shoot_Penetration = 4; // 4 Max

#define df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier
#define df_Primary_Shoot_Victim_Post_Damage_Knockback

#if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier = 0.0; // ~1 second 0.0 to 1.0 (player speed * x.x), lower values reduce velocity effects too (e.g. knockback effects)
#endif

#if defined df_Primary_Shoot_Victim_Post_Damage_Knockback
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Knockback_Strenght = 0.0;
    const Float: glf_Primary_Shoot_Victim_Post_Damage_Knockback_Up_Strenght = 0.0;
#endif

// View Model Animations
const Float: glf_Primary_View_Model_Animation_Idle_Time = 0.57;
const Float: glf_Primary_View_Model_Animation_Reload_Time = 2.46;
const Float: glf_Primary_View_Model_Animation_Deploy_Time = 1.03;
const Float: glf_Primary_View_Model_Animation_Shoot_Time = 0.85;

enum 
{
    gli_Primary_View_Model_Animation_Idle = 0,
    gli_Primary_View_Model_Animation_Reload,
    gli_Primary_View_Model_Animation_Deploy,
    gli_Primary_View_Model_Animation_Shoot
};

/* ~ [ Resources ] ~ */
new const gls_Primary_View_Model[] = "models/v_ak47.mdl";
new const gls_Primary_Player_Model[] = "models/p_ak47.mdl";
new const gls_Primary_World_Model[] = "models/w_ak47.mdl";

new const gls_Primary_Shoot_Sound[] = "weapons/ak47-1.wav";

#if defined df_Primary_WeaponList
    new const glsg_Primary_WeaponList_Resources[][] = 
    {
        "sprites/640hud10.spr",
        "sprites/640hud11.spr",
        "sprites/640hud7.spr"
    };

    new const gls_Primary_WeaponList_TXT_File[] = "weapon_ak47";
#endif 

/* ~ [ Macros ] ~ */
#if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
    #define var_fire_bullets3_on var_iuser1
#endif

/* ~ [ Globals ] ~ */
new HookChain: gliv_HookChain_IsPenetrableEntity_Post;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("Custom Primary Template", "11.0 | Final", "Cristian505");
    // Last Update : 2 Nov 2026

    // Hamsandwich
    RegisterHam(Ham_Weapon_PrimaryAttack,    gls_Primary_Reference,    "Ham_Primary_PrimaryAttack_Pre",    false);
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

    #if defined df_Primary_Holder_Max_Speed_Bonus
        RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "RG_Player_ResetMaxSpeed_Post", true);
    #endif

    #if defined df_Primary_Shoot_Victim_Post_Damage_Velocity_Modifier || defined df_Primary_Shoot_Victim_Post_Damage_Knockback
        RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_Player_TakeDamage_Post", true);
    #endif

    // Fakemeta
    register_forward(FM_UpdateClientData, "FW_UpdateClientData_Post", true);

    // Client Commands
    register_clcmd("say /custom_primary_template", "ClientCommand_Give_Custom_Primary");

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
        // ---

        // ~
        UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Shoot, MSG_ONE_UNRELIABLE);

        rh_emit_sound2(iPlayer, 0, CHAN_WEAPON, gls_Primary_Shoot_Sound);
        // ---

        // ~
        iPrimaryClip--;

        set_member(iPrimary, m_Weapon_iClip, iPrimaryClip);

        set_member(iPrimary, m_Weapon_flNextPrimaryAttack, glf_Primary_Shoot_Rate);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Shoot_Time);
        // ---

        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public Ham_Primary_Deploy_Post(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
        new iPlayer = get_member(iPrimary, m_pPlayer);

        set_entvar(iPlayer, var_viewmodel, gls_Primary_View_Model);
        set_entvar(iPlayer, var_weaponmodel, gls_Primary_Player_Model);

        UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Deploy, MSG_ONE_UNRELIABLE);

        set_member(iPlayer, m_flNextAttack, glf_Primary_Deploy_Next_Attack_Time);
        set_member(iPrimary, m_Weapon_flTimeWeaponIdle, glf_Primary_View_Model_Animation_Deploy_Time);
    }
}

public Ham_Primary_Idle_Pre(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index && get_member(iPrimary, m_Weapon_flTimeWeaponIdle) <= 0.0)
    {
        UTIL_SetViewModelAnim(get_member(iPrimary, m_pPlayer), gli_Primary_View_Model_Animation_Idle, MSG_ONE_UNRELIABLE);

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

        set_member(get_member(iPrimary, m_pPlayer), m_flNextAttack, 0.0);
    }
}

public Ham_Primary_Spawn_Post(iPrimary)
{
    if(!is_nullent(iPrimary) && get_entvar(iPrimary, var_impulse) == gli_Primary_Unique_Index)
    {
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
            UTIL_SetViewModelAnim(iPlayer, gli_Primary_View_Model_Animation_Reload, MSG_ONE_UNRELIABLE);

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
                write_byte(4); // Color
                write_short(70); // Count
                write_short(15); // Speed
                write_short(50); // Noise
                message_end();
            }
        }
    }
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

/* ~ [ Stocks ] ~ */
stock UTIL_SetViewModelAnim(iReceiver, iAnimation, iReceiverMsgDest) 
{
    set_entvar(iReceiver, var_weaponanim, iAnimation);

    message_begin(iReceiverMsgDest, SVC_WEAPONANIM, _, iReceiver);
    write_byte(iAnimation);
    write_byte(0);
    message_end();
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