/datum/disease/transformation
	name = "Transformation"
	max_stages = 5
	spread_text = "Acute"
	spread_flags = DISEASE_SPREAD_SPECIAL
	cure_text = "A coder's love (theoretical)."
	agent = "Shenanigans"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 10
	visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC
	disease_flags = CURABLE
	var/list/stage1 = list("You feel unremarkable.")
	var/list/stage2 = list("You feel boring.")
	var/list/stage3 = list("You feel utterly plain.")
	var/list/stage4 = list("You feel white bread.")
	var/list/stage5 = list("Oh the humanity!")
	var/new_form = /mob/living/carbon/human
	var/bantype
	var/transformed_antag_datum //Do we add a specific antag datum once the transformation is complete?

/datum/disease/transformation/Copy()
	var/datum/disease/transformation/D = ..()
	D.stage1 = stage1.Copy()
	D.stage2 = stage2.Copy()
	D.stage3 = stage3.Copy()
	D.stage4 = stage4.Copy()
	D.stage5 = stage5.Copy()
	D.new_form = D.new_form
	return D

/datum/disease/transformation/stage_act()
	..()
	switch(stage)
		if(1)
			if (prob(stage_prob) && stage1)
				to_chat(affected_mob, pick(stage1))
		if(2)
			if (prob(stage_prob) && stage2)
				to_chat(affected_mob, pick(stage2))
		if(3)
			if (prob(stage_prob*2) && stage3)
				to_chat(affected_mob, pick(stage3))
		if(4)
			if (prob(stage_prob*2) && stage4)
				to_chat(affected_mob, pick(stage4))
		if(5)
			do_disease_transformation(affected_mob)

/datum/disease/transformation/proc/do_disease_transformation(mob/living/affected_mob)
	if(istype(affected_mob, /mob/living/carbon) && affected_mob.stat != DEAD)
		if(stage5)
			to_chat(affected_mob, pick(stage5))
		if(QDELETED(affected_mob))
			return
		if(affected_mob.notransform)
			return
		affected_mob.notransform = 1
		for(var/obj/item/W in affected_mob.get_equipped_items(TRUE))
			affected_mob.dropItemToGround(W)
		for(var/obj/item/I in affected_mob.held_items)
			affected_mob.dropItemToGround(I)
		var/mob/living/new_mob = new new_form(affected_mob.loc)
		if(istype(new_mob))
			new_mob.used_intent = INTENT_HARM
			if(affected_mob.mind)
				affected_mob.mind.transfer_to(new_mob)
			else
				new_mob.key = affected_mob.key
		if(transformed_antag_datum)
			new_mob.mind.add_antag_datum(transformed_antag_datum)
		new_mob.name = affected_mob.real_name
		new_mob.real_name = new_mob.name
		qdel(affected_mob)

/datum/disease/transformation/proc/replace_banned_player(mob/living/new_mob) // This can run well after the mob has been transferred, so need a handle on the new mob to kill it if needed.
	set waitfor = FALSE

	var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as [affected_mob.name]?", bantype, null, bantype, 50, affected_mob)
	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		to_chat(affected_mob, span_danger("My mob has been taken over by a ghost! Appeal my job ban if you want to avoid this in the future!"))
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(affected_mob)]) to replace a jobbanned player.")
		affected_mob.ghostize(0)
		affected_mob.key = C.key
	else
		to_chat(new_mob, span_danger("My mob has been claimed by death! Appeal my job ban if you want to avoid this in the future!"))
		new_mob.death()
		if (!QDELETED(new_mob))
			new_mob.ghostize(can_reenter_corpse = FALSE)
			new_mob.key = null

/datum/disease/transformation/jungle_fever
	name = "Jungle Fever"
	cure_text = "Death."
	cures = list(/datum/reagent/medicine/adminordrazine)
	spread_text = "Monkey Bites"
	spread_flags = DISEASE_SPREAD_SPECIAL
	viable_mobtypes = list(/mob/living/carbon/monkey, /mob/living/carbon/human)
	permeability_mod = 1
	cure_chance = 1
	disease_flags = CAN_CARRY|CAN_RESIST
	desc = ""
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 4
	visibility_flags = 0
	agent = "Kongey Vibrion M-909"
	new_form = /mob/living/carbon/monkey
	bantype = ROLE_MONKEY


	stage1	= list()
	stage2	= list()
	stage3	= list()
	stage4	= list(span_warning("My back hurts."), span_warning("I breathe through my mouth."),
					span_warning("I have a craving for bananas."), span_warning("My mind feels clouded."))
	stage5	= list(span_warning("I feel like monkeying around."))

/datum/disease/transformation/jungle_fever/do_disease_transformation(mob/living/carbon/affected_mob)
	if(affected_mob.mind && !is_monkey(affected_mob.mind))
		add_monkey(affected_mob.mind)
	if(ishuman(affected_mob))
		var/mob/living/carbon/monkey/M = affected_mob.monkeyize(TR_KEEPITEMS | TR_KEEPIMPLANTS | TR_KEEPORGANS | TR_KEEPDAMAGE | TR_KEEPVIRUS | TR_KEEPSTUNS | TR_KEEPREAGENTS | TR_KEEPSE)
		M.ventcrawler = VENTCRAWLER_ALWAYS


/datum/disease/transformation/jungle_fever/stage_act()
	..()
	switch(stage)
		if(2)
			if(prob(2))
				to_chat(affected_mob, span_notice("My [pick("back", "arm", "leg", "elbow", "head")] itches."))
		if(3)
			if(prob(4))
				to_chat(affected_mob, span_danger("I feel a stabbing pain in my head."))
				affected_mob.confused += 10
		if(4)
			if(prob(3))
				affected_mob.say(pick("Eeek, ook ook!", "Eee-eeek!", "Eeee!", "Ungh, ungh."), forced = "jungle fever")

/datum/disease/transformation/jungle_fever/cure()
	remove_monkey(affected_mob.mind)
	..()

/datum/disease/transformation/jungle_fever/monkeymode
	visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC
	disease_flags = CAN_CARRY //no vaccines! no cure!

/datum/disease/transformation/jungle_fever/monkeymode/after_add()
	if(affected_mob && !is_monkey_leader(affected_mob.mind))
		visibility_flags = NONE

/datum/disease/transformation/corgi
	name = "The Barkening"
	cure_text = "Death"
	cures = list(/datum/reagent/medicine/adminordrazine)
	agent = "Fell Doge Majicks"
	desc = ""
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = 0
	stage1	= list("BARK.")
	stage2	= list("You feel the need to wear silly hats.")
	stage3	= list(span_danger("Must... eat... chocolate...."), span_danger("YAP"))
	stage4	= list(span_danger("Visions of washing machines assail my mind!"))
	stage5	= list(span_danger("AUUUUUU!!!"))
	new_form = /mob/living/simple_animal/pet/dog/corgi

/datum/disease/transformation/corgi/stage_act()
	..()
	switch(stage)
		if(3)
			if (prob(8))
				affected_mob.say(pick("YAP", "Woof!"), forced = "corgi transformation")
		if(4)
			if (prob(20))
				affected_mob.say(pick("Bark!", "AUUUUUU"), forced = "corgi transformation")
/datum/disease/transformation/gondola
	name = "Gondola Transformation"
	cure_text = "Condensed Capsaicin, ingested or injected." //getting pepper sprayed doesn't help
	cures = list(/datum/reagent/consumable/condensedcapsaicin) //beats the hippie crap right out of my system
	cure_chance = 80
	stage_prob = 5
	agent = "Tranquility"
	desc = ""
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = 0
	stage1	= list("You seem a little lighter in my step.")
	stage2	= list("You catch myself smiling for no reason.")
	stage3	= list(span_danger("A cruel sense of calm overcomes you."), span_danger("I can't feel my arms!"), span_danger("I let go of the urge to hurt clowns."))
	stage4	= list(span_danger("I can't feel my arms. It does not bother you anymore."), span_danger("I forgive the clown for hurting you."))
	stage5	= list(span_danger("I have become a Gondola."))
	new_form = /mob/living/simple_animal/pet/gondola

/datum/disease/transformation/gondola/stage_act()
	..()
	switch(stage)
		if(2)
			if (prob(5))
				affected_mob.emote("smile")
			if (prob(20))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(3)
			if (prob(5))
				affected_mob.emote("smile")
			if (prob(20))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(4)
			if (prob(5))
				affected_mob.emote("smile")
			if (prob(20))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
			if (prob(2))
				to_chat(affected_mob, span_danger("I let go of what you were holding."))
				var/obj/item/I = affected_mob.get_active_held_item()
				affected_mob.dropItemToGround(I)
