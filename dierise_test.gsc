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

init()
{
    level thread testing_main_loop();
    level thread testing_players_loop();

    level.zombie_init_done = ::zombie_init_override;
    level.round_start_custom_func = ::trap_fix;
}

testing_main_loop()
{
    level endon("end_game");

    flag_wait("initial_blackscreen_passed");

    level.bleedouts = 0;
    level.elevator_kills = 0;

    foreach (player in level.players)
        player.score = 666666;

    level thread hud_timer();
    level thread hud_round_timer();
    level thread zombie_tracker();
    level thread hud_kills();

    level thread teleport_on_dvar_trigger();
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
    self iPrintLn("Die Rise Tester ^2V2.1");
    self thread teleport_on_chat_trigger();
    self thread get_my_coordinates();
}

zombie_init_override()
{
    self.allowpain = 0;
    self.zombie_path_bad = 0;
    self thread maps\mp\zm_highrise_distance_tracking::escaped_zombies_cleanup_init();
    self thread maps\mp\zm_highrise::elevator_traverse_watcher();

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

elevator_watcher()
{
    level endon("end_game");

    self waittill("death", attacker);

    if (self maps\mp\zm_highrise_elevators::is_self_on_elevator())
        level.elevator_kills++;
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

    elevator_kills_hud = createserverfontstring("default" , 1.4);
	elevator_kills_hud setPoint("TOPLEFT", "TOPLEFT", -60, loc_of_hud);
	elevator_kills_hud.alpha = 1;
	elevator_kills_hud.color = (1, 1, 1);
	elevator_kills_hud.hidewheninmenu = 0;
    elevator_kills_hud.label = &"ELEVATOR: ^3";
    elevator_kills_hud setValue(0);
    loc_of_hud += 14;

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
        if (isDefined(level.elevator_kills))
            elevator_kills_hud setValue(level.elevator_kills);

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

do_teleport(trigger)
{
    switch (trigger)
    {
        case "ts":
            self setorigin((1933, 1354, 3050));
            self setplayerangles((0, 180, 0));
            break;
        case "pt":
            self setorigin((2225, 1800, 3060));
            self setplayerangles((0, 55, 0));
            break;
        case "st":
            self setorigin((2141, 1162, 3080));
            self setplayerangles((0, 75, 0));
            break;
        case "kt":
            self setorigin((2269, 1858, 3068));
            self setplayerangles((0, -125, 0));
            break;
    }
}

teleport_on_dvar_trigger()
{
    level endon("end_game");

    player = level.players[0];
    dvar_state = "";
    setDvar("tp", "");

    while (true)
    {
        wait 0.05;
        if (getDvar("tp") == dvar_state)
            continue;

        player do_teleport(getDvar("tp"));

        setDvar("tp", "");
    }
}

teleport_on_chat_trigger()
{
    level endon("end_game");
    self endon("disconnect");

    while (true)
    {
        text = undefined;
        player = undefined;
        is_hidden = undefined;

        level waittill("say", text, player, is_hidden);
        if (player.name != self.name)
            continue;

        player do_teleport(text);
    }
}

get_my_coordinates()
{
    self.coordinates_x_hud = createfontstring("objective" , 1.1);
    self.coordinates_x_hud setPoint("CENTER", "BOTTOM", -40, 10);
	self.coordinates_x_hud.alpha = 0.66;
	self.coordinates_x_hud.color = (1, 1, 1);
	self.coordinates_x_hud.hidewheninmenu = 0;

    self.coordinates_y_hud = createfontstring("objective" , 1.1);
    self.coordinates_y_hud setPoint("CENTER", "BOTTOM", 0, 10);
	self.coordinates_y_hud.alpha = 0.66;
	self.coordinates_y_hud.color = (1, 1, 1);
	self.coordinates_y_hud.hidewheninmenu = 0;

    self.coordinates_z_hud = createfontstring("objective" , 1.1);
    self.coordinates_z_hud setPoint("CENTER", "BOTTOM", 40, 10);
	self.coordinates_z_hud.alpha = 0.66;
	self.coordinates_z_hud.color = (1, 1, 1);
	self.coordinates_z_hud.hidewheninmenu = 0;

	while (true)
	{
		self.coordinates_x_hud setValue(naive_round(self.origin[0]));
		self.coordinates_y_hud setValue(naive_round(self.origin[1]));
		self.coordinates_z_hud setValue(naive_round(self.origin[2]));

		wait 0.05;
	}
}

naive_round(floating_point)
{
	floating_point = int(floating_point * 1000);
	return floating_point / 1000;
}
