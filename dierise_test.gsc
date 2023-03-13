#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hostmigration;
#include maps\mp\zm_highrise_utility;
#include maps\mp\zm_highrise_distance_tracking;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zombies\_zm_ai_leaper;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_weapons;

main()
{
    flag_set("init_deleter_hud");
    replaceFunc(maps\mp\zm_highrise_elevators::elev_remove_corpses, ::elev_remove_corpses_override);
}

init()
{
    level thread testing_main_loop();
    level thread testing_players_loop();

    level.zombie_init_done = ::zombie_init_override;
    level.round_start_custom_func = ::trap_fix;
}

replaceFunc(arg1, arg2)
{
    // elev_remove_corpses()
    flag_clear("init_deleter_hud");
    if (!isDefined(level.elevator_deleted))
        level.elevator_deleted = 0;
}

testing_main_loop()
{
    level endon("end_game");

    flag_wait("initial_blackscreen_passed");

    level.bleedouts = 0;
    level.elevator_direct_kills = 0;
    level.elevator_indirect_kills = 0;

    foreach (player in level.players)
        player.score = 666666;

    level thread hud_timer();
    level thread hud_round_timer();
    level thread zombie_tracker();
    level thread hud_kills();
}

testing_players_loop()
{
    level endon("end_game");

    while (true)
    {
		level waittill("connected", player);
		player thread testing_player_loop();
    }
}

testing_player_loop()
{
    level endon("end_game");
    self endon("disconnect");

    self waittill("spawned_player");
    self iPrintLn("Die Rise Tester ^2V1");
        // self thread buildable_watcher();
}

buildable_watcher()
{
    level endon("end_game");
    self endon("disconnect");

    while (true)
    {
        self waittill("equipment_placed", weapon, weapname);
        // print("trigger 'equipment_placed' weapname='" + weapname + "'");
    }
}

zombie_init_override()
{
    self.allowpain = 0;
    self.zombie_path_bad = 0;
    self thread maps\mp\zm_highrise_distance_tracking::escaped_zombies_cleanup_init();
    self thread elevator_traverse_watcher_override();

    // self thread death_watcher();
    self thread elevator_watcher();

    if (self.classname == "actor_zm_highrise_basic_03")
    {
        health_bonus = int(self.maxhealth * 0.05);
        self.maxhealth += health_bonus;

        if (self.headmodel == "c_zom_zombie_chinese_head3_helmet")
            self.maxhealth += health_bonus;

        self.health = self.maxhealth;
    }

    self setphysparams(15, 0, 48);
}

death_watcher()
{
    level endon("end_game");

    self waittill("death", attacker);

    if (isDefined(attacker))
        print("attacker_defined");
    print("damagemod='" + self.damagemod + "'");
    print("damageweapon='" + self.damageweapon + "'");
    print("damaged_by_player='" + self.has_been_damaged_by_player + "'");
    print("marked_for_recycle='" + self.marked_for_recycle + "'");
    print("selfattacker='" + self.attacker.name + "'");
    print("attacker='" + attacker.name + "'");
    print("force_explode='" + self.force_explode + "'");

    if (!isDefined(self.damagemod) && !isDefined(self.damageweapon) && (isDefined(self.force_explode) && self.force_explode))
    {
        level.elevator_direct_kills++;
    }
}

elevator_watcher()
{
    level endon("end_game");

    self waittill("death", attacker);

    // if (isDefined(self.elevator_parent) && is_true(self.elevator_parent.is_moving))
    //     level.elevator_direct_kills++;

    if (self maps\mp\zm_highrise_elevators::is_self_on_elevator())
    {
        /*if (is_true(self.dont_throw_gib))
            level.elevator_direct_kills++;
        else*/
            level.elevator_indirect_kills++;
    }
}

elevator_traverse_watcher_override()
{
    self endon("death");

    while (true)
    {
        if (is_true(self.is_traversing))
        {
            self.elevator_parent = undefined;

            if (is_true(self maps\mp\zm_highrise_elevators::object_is_on_elevator()))
            {
                if (isdefined(self.elevator_parent))
                {
                    if (is_true(self.elevator_parent.is_moving))
                    {
                        // playfx(level._effect["zomb_gib"], self.origin);
                        
                        if (isDefined(level.elevator_direct_kills))
                            level.elevator_direct_kills++;

                        if (!is_true( self.has_been_damaged_by_player))
                            level.zombie_total++;

                        self delete();
                        return;
                    }
                }
            }
        }

        wait 0.2;
    }
}

zombie_tracker()
{
    level endon("end_game");

    zombie_counter = createserverfontstring("default" , 1.4);
	zombie_counter setPoint("CENTER", "CENTER", "CENTER", 200);
	zombie_counter.alpha = 1;
	zombie_counter.color = (1, 1, 1);
	zombie_counter.hidewheninmenu = 0;
    zombie_counter.label = &"Zombies: ^1";

    while (true)
    {
        zombie_value = level.zombie_total + get_round_enemy_array().size;
        zombie_counter setValue(zombie_value);

        wait 0.05;
    }
}

hud_timer()
{
    level endon("end_game");

    timer_hud = createserverfontstring("default" , 1.4);
	timer_hud setPoint("TOPRIGHT", "TOPRIGHT", 60, -20);
	timer_hud.alpha = 1;
	timer_hud.color = (1, 1, 1);
	timer_hud.hidewheninmenu = 0;

    timer_hud setTimerUp(0);
}

hud_round_timer()
{
    level endon("end_game");

    round_timer_hud = createserverfontstring("default" , 1.4);
	round_timer_hud setPoint("TOPRIGHT", "TOPRIGHT", 60, -6);
	round_timer_hud.alpha = 1;
	round_timer_hud.color = (1, 1, 1);
	round_timer_hud.hidewheninmenu = 0;

    while (true)
    {
        level waittill("start_of_round");
        start_time = getTime() / 1000;
        round_timer_hud setTimerUp(0);
	    round_timer_hud.alpha = 1;

        level waittill("end_of_round");
        end_time = getTime() / 1000;
        for (i = 0; i < 40; i++)
        {
            round_timer_hud setTimer(end_time - start_time - 0.1);
            wait 0.1;
        }
	    round_timer_hud.alpha = 0;
    }
}

hud_kills()
{
    level endon("end_game");

    loc_of_hud = -20;


    elevator_indirect_hud = createserverfontstring("default" , 1.4);
	elevator_indirect_hud setPoint("TOPLEFT", "TOPLEFT", -60, loc_of_hud);
	elevator_indirect_hud.alpha = 1;
	elevator_indirect_hud.color = (1, 1, 1);
	elevator_indirect_hud.hidewheninmenu = 0;
    elevator_indirect_hud.label = &"ELEVATOR - INDIRECT: ^1";
    elevator_indirect_hud setValue(0);
    loc_of_hud += 14;

    elevator_direct_hud = createserverfontstring("default" , 1.4);
	elevator_direct_hud setPoint("TOPLEFT", "TOPLEFT", -60, loc_of_hud);
	elevator_direct_hud.alpha = 1;
	elevator_direct_hud.color = (1, 1, 1);
	elevator_direct_hud.hidewheninmenu = 0;
    elevator_direct_hud.label = &"ELEVATOR - DIRECT: ^3";
    elevator_direct_hud setValue(0);
    loc_of_hud += 14;

    if (flag("init_deleter_hud"))
    {
        elevator_delete_hud = createserverfontstring("default" , 1.4);
        elevator_delete_hud setPoint("TOPLEFT", "TOPLEFT", -60, loc_of_hud);
        elevator_delete_hud.alpha = 1;
        elevator_delete_hud.color = (1, 1, 1);
        elevator_delete_hud.hidewheninmenu = 0;
        elevator_delete_hud.label = &"ELEVATOR - DELETED: ^6";
        elevator_delete_hud setValue(0);
        loc_of_hud += 14;
    }

    springpad_hud = createserverfontstring("default" , 1.4);
	springpad_hud setPoint("TOPLEFT", "TOPLEFT", -60, loc_of_hud);
	springpad_hud.alpha = 1;
	springpad_hud.color = (1, 1, 1);
	springpad_hud.hidewheninmenu = 0;
    springpad_hud.label = &"SPRINGPAD: ^2";
    springpad_hud setValue(0);
    loc_of_hud += 14;


    while (true)
    {
        if (isDefined(level.elevator_direct_kills))
            elevator_direct_hud setValue(level.elevator_direct_kills);
        if (isDefined(level.elevator_indirect_kills))
            elevator_indirect_hud setValue(level.elevator_indirect_kills);
        if (isDefined(level.elevator_deleted))
            elevator_delete_hud setValue(level.elevator_deleted);

        springpad_hud setValue(get_springpad_kills());

        wait 0.05;
    }
}

get_springpad_kills()
{
    kills = 0;
    foreach (player in level.players)
    {
        if (isDefined(player.num_zombies_flung))
            kills += player.num_zombies_flung;
    }

    return kills;
}

trap_fix()
{
    rnd_157 = 1263974369;

    if (level.zombie_health <= rnd_157)
        return;

    iPrintLn("Reverting zombie health to round 157");
    level.zombie_health = rnd_157;

    foreach (zombie in get_round_enemy_array())
    {
        if (zombie.health > rnd_157)
            zombie.heath = rnd_157;
    }
}

elev_remove_corpses_override()
{
    level.elevator_deleted++;
    // playfx(level._effect["zomb_gib"], self.origin);
    iPrintLn("remove corpses");
    self delete();
}

// zombie_gut_explosion_override()
// {
//     self.guts_explosion = 1;

//     print("guts_exploded");

//     if ( is_mature() )
//         self setclientfield( "zombie_gut_explosion", 1 );

//     if ( !( isdefined( self.isdog ) && self.isdog ) )
//         wait 0.1;

//     if ( isdefined( self ) )
//         self ghost();
// }

zombie_death_event_override( zombie )
{
    zombie.marked_for_recycle = 0;
    force_explode = 0;
    force_head_gib = 0;

    zombie waittill( "death", attacker );

    time_of_death = gettime();

    if ( isdefined( zombie ) )
        zombie stopsounds();

    if ( isdefined( zombie ) && isdefined( zombie.marked_for_insta_upgraded_death ) )
        force_head_gib = 1;

    if ( !isdefined( zombie.damagehit_origin ) && isdefined( attacker ) )
        zombie.damagehit_origin = attacker getweaponmuzzlepoint();

    if ( isdefined( attacker ) && isplayer( attacker ) )
    {
        if ( isdefined( level.pers_upgrade_carpenter ) && level.pers_upgrade_carpenter )
            maps\mp\zombies\_zm_pers_upgrades::pers_zombie_death_location_check( attacker, zombie.origin );

        if ( isdefined( level.pers_upgrade_sniper ) && level.pers_upgrade_sniper )
            attacker pers_upgrade_sniper_kill_check( zombie, attacker );

        if ( isdefined( zombie ) && isdefined( zombie.damagelocation ) )
        {
            if ( is_headshot( zombie.damageweapon, zombie.damagelocation, zombie.damagemod ) )
            {
                attacker.headshots++;
                attacker maps\mp\zombies\_zm_stats::increment_client_stat( "headshots" );
                attacker addweaponstat( zombie.damageweapon, "headshots", 1 );
                attacker maps\mp\zombies\_zm_stats::increment_player_stat( "headshots" );

                if ( is_classic() )
                    attacker maps\mp\zombies\_zm_pers_upgrades_functions::pers_check_for_pers_headshot( time_of_death, zombie );
            }
            else
                attacker notify( "zombie_death_no_headshot" );
        }

        if ( isdefined( zombie ) && isdefined( zombie.damagemod ) && zombie.damagemod == "MOD_MELEE" )
        {
            attacker maps\mp\zombies\_zm_stats::increment_client_stat( "melee_kills" );
            attacker maps\mp\zombies\_zm_stats::increment_player_stat( "melee_kills" );
            attacker notify( "melee_kill" );

            if ( attacker maps\mp\zombies\_zm_pers_upgrades::is_insta_kill_upgraded_and_active() )
                force_explode = 1;
        }

        attacker maps\mp\zombies\_zm::add_rampage_bookmark_kill_time();
        attacker.kills++;
        attacker maps\mp\zombies\_zm_stats::increment_client_stat( "kills" );
        attacker maps\mp\zombies\_zm_stats::increment_player_stat( "kills" );

        if ( isdefined( level.pers_upgrade_pistol_points ) && level.pers_upgrade_pistol_points )
            attacker maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_pistol_points_kill();

        dmgweapon = zombie.damageweapon;

        if ( is_alt_weapon( dmgweapon ) )
            dmgweapon = weaponaltweaponname( dmgweapon );

        attacker addweaponstat( dmgweapon, "kills", 1 );

        if ( attacker maps\mp\zombies\_zm_pers_upgrades_functions::pers_mulit_kill_headshot_active() || force_head_gib )
            zombie maps\mp\zombies\_zm_spawner::zombie_head_gib();

        if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
            attacker notify( "pers_player_zombie_kill" );
    }

    zombie_death_achievement_sliquifier_check( attacker, zombie );
    recalc_zombie_array();

    if ( !isdefined( zombie ) )
        return;

    level.global_zombies_killed++;

    if ( isdefined( zombie.marked_for_death ) && !isdefined( zombie.nuked ) )
        level.zombie_trap_killed_count++;

    zombie check_zombie_death_event_callbacks();
    name = zombie.animname;

    if ( isdefined( zombie.sndname ) )
        name = zombie.sndname;

    zombie thread maps\mp\zombies\_zm_audio::do_zombies_playvocals( "death", name );
    zombie thread zombie_eye_glow_stop();

    if ( isdefined( zombie.damageweapon ) && is_weapon_shotgun( zombie.damageweapon ) && maps\mp\zombies\_zm_weapons::is_weapon_upgraded( zombie.damageweapon ) || isdefined( zombie.damageweapon ) && is_placeable_mine( zombie.damageweapon ) || zombie.damagemod == "MOD_GRENADE" || zombie.damagemod == "MOD_GRENADE_SPLASH" || zombie.damagemod == "MOD_EXPLOSIVE" || force_explode == 1 )
    {
        splode_dist = 180;

        if ( isdefined( zombie.damagehit_origin ) && distancesquared( zombie.origin, zombie.damagehit_origin ) < splode_dist * splode_dist )
        {
            tag = "J_SpineLower";

            if ( isdefined( zombie.isdog ) && zombie.isdog )
                tag = "tag_origin";

            if ( !( isdefined( zombie.is_on_fire ) && zombie.is_on_fire ) && !( isdefined( zombie.guts_explosion ) && zombie.guts_explosion ) )
                zombie thread zombie_gut_explosion();
        }
    }

    if ( zombie.damagemod == "MOD_GRENADE" || zombie.damagemod == "MOD_GRENADE_SPLASH" )
    {
        if ( isdefined( attacker ) && isalive( attacker ) )
        {
            attacker.grenade_multiattack_count++;
            attacker.grenade_multiattack_ent = zombie;
        }
    }

    if ( !( isdefined( zombie.has_been_damaged_by_player ) && zombie.has_been_damaged_by_player ) && ( isdefined( zombie.marked_for_recycle ) && zombie.marked_for_recycle ) )
    {
        level.zombie_total++;
        level.zombie_total_subtract++;
    }
    else if ( isdefined( zombie.attacker ) && isplayer( zombie.attacker ) )
    {
        level.zombie_player_killed_count++;

        if ( isdefined( zombie.sound_damage_player ) && zombie.sound_damage_player == zombie.attacker )
        {
            chance = get_response_chance( "damage" );

            if ( chance != 0 )
            {
                if ( chance > randomintrange( 1, 100 ) )
                    zombie.attacker maps\mp\zombies\_zm_audio::create_and_play_dialog( "kill", "damage" );
            }
            else
                zombie.attacker maps\mp\zombies\_zm_audio::create_and_play_dialog( "kill", "damage" );
        }

        zombie.attacker notify( "zom_kill", zombie );
        damageloc = zombie.damagelocation;
        damagemod = zombie.damagemod;
        attacker = zombie.attacker;
        weapon = zombie.damageweapon;
        bbprint( "zombie_kills", "round %d zombietype %s damagetype %s damagelocation %s playername %s playerweapon %s playerx %f playery %f playerz %f zombiex %f zombiey %f zombiez %f", level.round_number, zombie.animname, damagemod, damageloc, attacker.name, weapon, attacker.origin, zombie.origin );
    }
    else if ( zombie.ignoreall && !( isdefined( zombie.marked_for_death ) && zombie.marked_for_death ) )
        level.zombies_timeout_spawn++;

    level notify( "zom_kill" );
    level.total_zombies_killed++;
}
