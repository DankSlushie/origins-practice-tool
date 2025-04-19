#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

#include scripts\zm\origins_menu\menu_utility;
#include scripts\zm\origins_menu\menu_base;

panzprac_initialize()
{
    replacefunc( maps\mp\zm_tomb_giant_robot::robot_cycling, ::panzprac_robot_cycling);
	replacefunc( maps\mp\zombies\_zm_ai_mechz::mechz_spawn, ::panzprac_mechz_spawn);

    set_dvar_if_unset("panzprac_box", "gen4");
	set_dvar_if_unset("panzprac_clay", "1");
	set_dvar_if_unset("panzprac_prefills", "10");
	set_dvar_if_unset("panzprac_hud", "0");
}

panzprac_run()
{
    level thread setup_map();
	level thread on_player_connect_panz();

    level.delay_robot = 1;
	flag_init("start_robots");
    flag_clear("start_robots");
	flag_wait("initial_blackscreen_passed");
	thread open_all_doors();

	level.level_start_time = GetTime();

	while(level.round_number < 8) level waittill( "end_of_round" );
	level.delay_robot = 0;
}

on_player_connect_panz()
{
	while(true)
	{
		level waittill("connected", player);
		player thread on_player_spawned_panz();
	}
}


cycle_box()
{
    dvar = "panzprac_box";
    box = getDvar(dvar);
    switch(box)
    {
        case "gen4": setDvar("panzprac_box", "gen5"); break;
        case "gen5": setDvar("panzprac_box", "mid"); break;
        case "mid": setDvar("panzprac_box", "gen4"); break;
        default: setDvar("panzprac_box", "gen4"); break;
    }
    self refresh_menu();
}

cycle_prefills()
{
    dvar = "panzprac_prefills";
    val = getDvar(dvar);
	if(val == 15)
		setDvar(dvar, 5);
	else
		setDvar(dvar, val + 1);

    self refresh_menu();
}

setup_map()
{
	setDvar("timescale", 10);
    level waittill("start_of_round");

	set_round = 7;
    level.zombie_total = 0;
    maps\mp\zombies\_zm::ai_calculate_health(set_round - 1);
    level.round_number = (set_round - 1);
    zombies = get_round_enemy_array();
    if (isDefined(zombies))
    {
        for (i = 0; i < zombies.size + 1; i++)
            zombies[i] dodamage(zombies[i].health + 666, zombies[i].origin);
    }

    level waittill("start_of_round");
    level.zombie_total = 0;
    delay = 2;
    for (i = 2; i <= level.round_number; i++)
        delay *= 0.95;
    level.zombie_vars["zombie_spawn_delay"] = delay;

	wait 9;
	setDvar("timescale", 1);
}

on_player_spawned_panz()
{

	self waittill("spawned_player");
	flag_wait("initial_blackscreen_passed");
    self freezecontrols( 1 );
	level waittill("start_of_round");
	active_box = (1, 1, 1);
	switch(getdvar("panzprac_box"))
    {
        case "gen4":
			boxes = array((-2138.38, -300.07, 176), (667.01, 640.63, 66)); //GEN4
			active_box = (2752.62, -88.68, 151);
            break;
		case "gen5":
			boxes = array((2752.62, -88.68, 151), (667.01, 640.63, 66)); //GEN5
			active_box = (-2138.38, -300.07, 176);
            break;

		case "mid":
			boxes = array((-2138.38, -300.07, 176), (2752.62, -88.68, 151)); //MID
			active_box = (667.01, 640.63, 66);
            break;
    }

	a_boxes = getentarray("foot_box", "script_noteworthy");

    foreach(a_box in a_boxes)
    {
        foreach(box_loc in boxes)
        {
            if(a_box.origin == box_loc)
            {
				a_box notify("soul_absorbed", self);
                a_box.n_souls_absorbed = 30;
			    a_box notify("soul_absorbed", self);
            }
			else if(a_box.origin == active_box)
			{
				a_box notify("soul_absorbed", self);
				wait 0.5;
				num = getdvarint("panzprac_prefills");
				a_box.n_souls_absorbed = num;
			}
        }

    }

	level waittill("start_of_round");
	self.score = 10000;
    self giveWeapon("mp40_zm");
	self switchToWeapon("mp40_zm");

	switch(getdvar("panzprac_box"))
    {
        case "gen4":
			tp = (2895, -246, 166); //GEN4
			self maps\mp\zombies\_zm_perks::give_perk("specialty_longersprint");
            break;

		case "gen5":
			tp = (-2501, -368, 195); //GEN5
			self maps\mp\zombies\_zm_perks::give_perk("specialty_armorvest");
            break;

		case "mid":
			tp = (540, 795, 83); //MID
			self maps\mp\zombies\_zm_perks::give_perk("specialty_longersprint");
			self maps\mp\zombies\_zm_perks::give_perk("specialty_armorvest");
            break;
    }

	if(getdvarint("panzprac_clay"))
	{
		self maps\mp\zombies\_zm_weap_claymore::claymore_setup();
	}

    if(GetDvarInt("panzprac_hud"))
	{
		//self thread zombie_remaining_hud();
		self thread slowed();
		//level soulbox_tracker_hud(active_box);
	}

	self setOrigin(tp);
    //self setOrigin(tp); angles
    wait 9;
	flag_set("menu_active");
    self freezecontrols( 0 );
}

panzprac_refresh()
{
    if(isdefined(level.slew))
	{
		level.slew.label = &"Slowed: ^6";
		level.comp.label = &"Complex behaviors: ^6";
		level.p_hp.label = &"HP: ^6";
		level.p_mask.label = &"MASK: ^6";
		level.p_power.label = &"POWERPLANT COVER: ^6";
		level.p_power_d.label = &"POWERPLANT: ^6";
		notify_label_text(6);
	}
}

slowed()
{
	level.slew = createfontstring("default", 1.3);
	level.slew setpoint("LEFT", "LEFT", "LEFT", -105);
	level.slew.label = &"Slowed: ^6";
	level.slew.alpha = 1;
	notify_label_text();

	while(true)
	{
		level.slew setvalue(self.is_player_slowed);
		wait 0.05;
        //self refresh_menu();
	}

}

mech_info()
{
	level.comp = createserverfontstring("default", 1.3);
	level.comp setpoint("LEFT", "LEFT", "LEFT", -120);
	level.comp.label = &"Complex behaviors: ^6";
	level.comp.alpha = 1;

	level.p_hp = createserverfontstring("default", 1.3);
	level.p_hp setpoint("LEFT", "LEFT", "LEFT", -15);
	level.p_hp.label = &"HP: ^6";
	level.p_hp.alpha = 1;

	level.p_mask = createserverfontstring("default", 1.3);
	level.p_mask setpoint("LEFT", "LEFT", "LEFT", 0);
	level.p_mask.label = &"MASK: ^6";
	level.p_mask.alpha = 1;

	level.p_power = createserverfontstring("default", 1.3);
	level.p_power setpoint("LEFT", "LEFT", "LEFT", 15);
	level.p_power.label = &"POWERPLANT COVER: ^6";
	level.p_power.alpha = 1;

	level.p_power_d = createserverfontstring("default", 1.3);
	level.p_power_d setpoint("LEFT", "LEFT", "LEFT", 30);
	level.p_power_d.label = &"POWERPLANT: ^6";
	level.p_power_d.alpha = 1;

	while(self.health > 0)
	{

		level.comp setvalue(1 - self.disable_complex_behaviors);

		if(self.health > 0)
		{
			level.p_hp setvalue(self.health);
		}
		else
		{
			level.p_hp setvalue(0);
		}

		if(self.helmet_dmg_for_removal - self.helmet_dmg > 0)
		{
			level.p_mask setvalue(self.helmet_dmg_for_removal - self.helmet_dmg);
		}
		else
		{
			level.p_mask setvalue(0);
		}

		if(self.powerplant_cover_dmg_for_removal - self.powerplant_cover_dmg > 0)
		{
			level.p_power setvalue(self.powerplant_cover_dmg_for_removal - self.powerplant_cover_dmg);
		}
		else
		{
			level.p_power setvalue(0);
		}
		if(self.powerplant_dmg_for_destroy - self.powerplant_dmg > 0)
		{
			level.p_power_d setvalue(self.powerplant_dmg_for_destroy - self.powerplant_dmg);
		}
		else
		{
			level.p_power_d setvalue(0);
		}

		wait 0.05;
	}

	level.p_hp setvalue(0);
	level.p_mask setvalue(0);
	level.p_power setvalue(0);
	level.p_power_d setvalue(0);
}

panzprac_mechz_spawn()
{
    self maps\mp\zombies\_zm_ai_mechz_ffotd::spawn_start();
    self endon( "death" );
    level endon( "intermission" );
    self maps\mp\zombies\_zm_ai_mechz::mechz_attach_objects();
    self maps\mp\zombies\_zm_ai_mechz::mechz_set_starting_health();
    self maps\mp\zombies\_zm_ai_mechz::mechz_setup_fx();
    self maps\mp\zombies\_zm_ai_mechz::mechz_setup_snd();
    level notify( "sam_clue_mechz", self );
    self.closest_player_override = maps\mp\zombies\_zm_ai_mechz::get_favorite_enemy;
    self.animname = "mechz_zombie";
    self.has_legs = 1;
    self.no_gib = 1;
    self.ignore_all_poi = 1;
    self.is_mechz = 1;
    self.ignore_enemy_count = 1;
    self.no_damage_points = 1;
    self.melee_anim_func = maps\mp\zombies\_zm_ai_mechz::melee_anim_func;
    self.meleedamage = 75;
    self.custom_item_dmg = 2000;
    recalc_zombie_array();
    self setphysparams( 20, 0, 80 );
    self setcandamage( 0 );
    self.zombie_init_done = 1;
    self notify( "zombie_init_done" );
    self.allowpain = 0;
    self animmode( "normal" );
    self orientmode( "face enemy" );
    self maps\mp\zombies\_zm_spawner::zombie_setup_attack_properties();
    self.completed_emerging_into_playable_area = 1;
    self notify( "completed_emerging_into_playable_area" );
    self.no_powerups = 0;
    self setfreecameralockonallowed( 0 );
    self notsolid();
    self thread maps\mp\zombies\_zm_spawner::zombie_eye_glow();
    level thread maps\mp\zombies\_zm_spawner::zombie_death_event( self );
    self thread maps\mp\zombies\_zm_spawner::enemy_death_detection();

    if ( level.zombie_mechz_locations.size )
        spawn_pos = self maps\mp\zombies\_zm_ai_mechz::get_best_mechz_spawn_pos();

    if ( !isdefined( spawn_pos ) )
    {
/#
        println( "ERROR: Tried to spawn mechz with no mechz spawn_positions!\\n" );
        iprintln( "ERROR: Tried to spawn mechz with no mechz spawn_positions!" );
#/
        self delete();
        return;
    }

    if ( isdefined( level.mechz_force_spawn_pos ) )
    {
        spawn_pos = level.mechz_force_spawn_pos;
        level.mechz_force_spawn_pos = undefined;
    }

    if ( !isdefined( spawn_pos.angles ) )
        spawn_pos.angles = ( 0, 0, 0 );

    self thread maps\mp\zombies\_zm_ai_mechz::mechz_death();
    self forceteleport( spawn_pos.origin, spawn_pos.angles );
    self playsound( "zmb_ai_mechz_incoming_alarm" );

    if ( !isdefined( spawn_pos.angles ) )
        spawn_pos.angles = ( 0, 0, 0 );

    self animscripted( spawn_pos.origin, spawn_pos.angles, "zm_spawn" );
    self maps\mp\animscripts\zm_shared::donotetracks( "jump_anim" );
    self setfreecameralockonallowed( 1 );
    self solid();
    self set_zombie_run_cycle( "walk" );

    if ( isdefined( level.mechz_find_flesh_override_func ) )
        level thread [[ level.mechz_find_flesh_override_func ]]();
    else
        self thread maps\mp\zombies\_zm_ai_mechz::mechz_find_flesh();
    self thread maps\mp\zombies\_zm_ai_mechz_booster::mechz_jump_think( spawn_pos );
    self setcandamage( 1 );
    self init_anim_rate();
    self maps\mp\zombies\_zm_ai_mechz_ffotd::spawn_end();

	if(GetDvarInt("panzprac_hud")) self thread mech_info();
}

panzprac_robot_cycling()
{
	level.robot_start_time = GetTime();
	three_robot_round = 0;
	last_robot = -1;
	level thread maps\mp\zm_tomb_giant_robot::giant_robot_intro_walk(1);
	level waittill("giant_robot_intro_complete");

	while(level.delay_robot == 1)
	{
		wait 0.05;
	}

	while( true )
	{
		level.robot_cycle++;
		random_number = -1;
		if( !(level.round_number % 4) && three_robot_round != level.round_number && level.round_number != 8)
		{
			flag_set("three_robot_round");
		}

		if(flag("ee_all_staffs_placed") && !flag("ee_mech_zombie_hole_opened"))
		{
			flag_set("three_robot_round");
		}
		if(flag("three_robot_round"))
		{
			level.zombie_ai_limit = 22;
			random_number = randomint(3);
			if(random_number == 2)
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(2);
			}
			else
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(2, 0);
			}
			wait 5;
			if(random_number == 0)
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(0);
			}
			else
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(0, 0);
			}
			wait 5;
			if(random_number == 1)
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(1);
			}
			else
			{
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(1, 0);
			}
			level waittill("giant_robot_walk_cycle_complete");
			level waittill("giant_robot_walk_cycle_complete");
			level waittill("giant_robot_walk_cycle_complete");
			wait 5;
			level.zombie_ai_limit = 24;
			three_robot_round = level.round_number;
			last_robot = -1;
			flag_clear("three_robot_round");
		}
		else
		{
			if(!flag("activate_zone_nml"))
			{
				random_number = randomint(2);
			}
			else
			{
				while(random_number == last_robot)
					random_number = randomint(3);
			}

			last_robot = random_number;
			level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk(random_number);
			level waittill("giant_robot_walk_cycle_complete");
			wait 5;
		}
	}
}