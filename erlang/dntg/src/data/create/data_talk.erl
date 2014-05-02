-module(data_talk).
-compile(export_all).
-include("common.hrl").
type_to_int(Key) -> L = [{npc,0},{role,1},{yes,2},{no,3},{fight,4},{trigger,5},{finish,6},{trigger_and_finish,7},{talk_event,8},{build_guild,9},{apply_join_guild,10},{guild_store,11},{guild_task,12},{learn_skill,13},{personal_store,14},{buy,15},{sell,16},{mixture,17},{embed,18},{identify,19},{mix,20},{strenghten,21},{drill,24},{fixed,25},{fix_all,26},{ablate,27},{back_to_guild_scene,29},{leave_guild_scene,30},{join_guild_war,31},{watch_guild_war,32},{enabled_xxd,33},{chushi,34},{bole_billboard,35},{soul_binding,36},{coin_binding,37},{task_award,38},{jobber,39},{open_favorite,40},{fb_list,41},{fb_out,42},{question,43},{pet_store,44},{guild_hall_level,45},{guild_store_level,46},{guild_out,47},{exchange,48},{transfer,49},{get_guild_out,50},{enter_xl,51},{leave_xl,52},{start_xl,53},{master_lv,54},{master_st,55},{scene_change,56}, {get_boss, 57}, {area_start, 58}, {bazhu, 59}, {quit_guild_war, 60}, {fight_against_myself, 61}],proplists:get_value(Key, L, 0).
get(_Id)  -> [].