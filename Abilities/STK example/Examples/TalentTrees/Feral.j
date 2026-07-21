scope Feral initializer init

    struct Feral extends STKTalentTree_TalentTree

        // Overriden stub methods ==================================================
        method GetTalentPoints takes nothing returns integer
            return GetPlayerState(this.ownerPlayer, PLAYER_STATE_RESOURCE_LUMBER)
        endmethod

        method SetTalentPoints takes integer points returns nothing
            call SetPlayerState(this.ownerPlayer, PLAYER_STATE_RESOURCE_LUMBER, points)
            // call STK_UpdateTalentViews(this.ownerPlayer)
        endmethod

        method GetTitle takes nothing returns string
            return this.title
        endmethod
        // =========================================================================

        method Initialize takes nothing returns nothing
            local STKTalent_Talent t

            call this.SetIdColumnsRows(2, 4, 7)
            set this.title = "Feral"
            call this.SetTalentPoints(6)
            set this.backgroundImage = "feral.blp"
            // set this.icon = "FireBolt"
            // TODO: set tree background texture here

            // The tree should be built with talents here
            // ==============================================

            // Ferocity <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Ferocity")
            call t.SetDescription("Reduces the cost of your Maul, Swipe, Claw, and Rake abilities by 1 Rage or Energy.")
            call t.SetIcon("ability_hunter_pet_hyena")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Ferocity")
            call t.SetDescription("Reduces the cost of your Maul, Swipe, Claw, and Rake abilities by 2 Rage or Energy.")
            call t.SetIcon("ability_hunter_pet_hyena")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Ferocity")
            call t.SetDescription("Reduces the cost of your Maul, Swipe, Claw, and Rake abilities by 3 Rage or Energy.")
            call t.SetIcon("ability_hunter_pet_hyena")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Ferocity")
            call t.SetDescription("Reduces the cost of your Maul, Swipe, Claw, and Rake abilities by 4 Rage or Energy.")
            call t.SetIcon("ability_hunter_pet_hyena")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Ferocity")
            call t.SetDescription("Reduces the cost of your Maul, Swipe, Claw, and Rake abilities by 5 Rage or Energy.")
            call t.SetIcon("ability_hunter_pet_hyena")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Feral Aggression <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Feral Aggression")
            call t.SetDescription("Increases the Attack Power reduction of your Demoralizing Roar by 8%% and the damage caused by your Ferocious Bite by 3%%.")
            call t.SetIcon("ability_druid_demoralizingroar")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Feral Aggression")
            call t.SetDescription("Increases the Attack Power reduction of your Demoralizing Roar by 16%% and the damage caused by your Ferocious Bite by 6%%.")
            call t.SetIcon("ability_druid_demoralizingroar")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Feral Aggression")
            call t.SetDescription("Increases the Attack Power reduction of your Demoralizing Roar by 24%% and the damage caused by your Ferocious Bite by 9%%.")
            call t.SetIcon("ability_druid_demoralizingroar")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Feral Aggression")
            call t.SetDescription("Increases the Attack Power reduction of your Demoralizing Roar by 32%% and the damage caused by your Ferocious Bite by 12%%.")
            call t.SetIcon("ability_druid_demoralizingroar")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Feral Aggression")
            call t.SetDescription("Increases the Attack Power reduction of your Demoralizing Roar by 40%% and the damage caused by your Ferocious Bite by 15%%.")
            call t.SetIcon("ability_druid_demoralizingroar")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Feral Instinct <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Feral Instinct")
            call t.SetDescription("Increases threat caused in Bear and Dire Bear Form by 3%% and reduces the chance enemies have to detect you while Prowling.")
            call t.SetIcon("Ambush")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Feral Instinct")
            call t.SetDescription("Increases threat caused in Bear and Dire Bear Form by 6%% and reduces the chance enemies have to detect you while Prowling.")
            call t.SetIcon("Ambush")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Feral Instinct")
            call t.SetDescription("Increases threat caused in Bear and Dire Bear Form by 9%% and reduces the chance enemies have to detect you while Prowling.")
            call t.SetIcon("Ambush")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Feral Instinct")
            call t.SetDescription("Increases threat caused in Bear and Dire Bear Form by 12%% and reduces the chance enemies have to detect you while Prowling.")
            call t.SetIcon("Ambush")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Feral Instinct")
            call t.SetDescription("Increases threat caused in Bear and Dire Bear Form by 15%% and reduces the chance enemies have to detect you while Prowling.")
            call t.SetIcon("Ambush")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Brutal Impact <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Brutal Impact")
            call t.SetDescription("Increases the stun duration of your Bash and Pounce abilities by 0.5 sec.")
            call t.SetIcon("ability_druid_bash")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Brutal Impact")
            call t.SetDescription("Increases the stun duration of your Bash and Pounce abilities by 1 sec.")
            call t.SetIcon("ability_druid_bash")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Thick Hide <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Thick Hide")
            call t.SetDescription("Increases your Armor contribution from items by 2%%.")
            call t.SetIcon("inv_misc_pelt_bear_03")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Thick Hide")
            call t.SetDescription("Increases your Armor contribution from items by 4%%.")
            call t.SetIcon("inv_misc_pelt_bear_03")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Thick Hide")
            call t.SetDescription("Increases your Armor contribution from items by 6%%.")
            call t.SetIcon("inv_misc_pelt_bear_03")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Thick Hide")
            call t.SetDescription("Increases your Armor contribution from items by 8%%.")
            call t.SetIcon("inv_misc_pelt_bear_03")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Thick Hide")
            call t.SetDescription("Increases your Armor contribution from items by 10%%.")
            call t.SetIcon("inv_misc_pelt_bear_03")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Feline Swiftness <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Feline Swiftness")
            call t.SetDescription("Increases your movement speed by 15%% while outdoors in Cat Form and increases your chance to dodge while in Cat Form by 2%%.")
            call t.SetIcon("SpiritWolf")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Feline Swiftness")
            call t.SetDescription("Increases your movement speed by 30%% while outdoors in Cat Form and increases your chance to dodge while in Cat Form by 4%%.")
            call t.SetIcon("SpiritWolf")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Feral Charge <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Feral Charge")
            call t.SetDescription("Causes you to charge an enemy, immobilizing and interrupting any spell being cast for 4 sec.")
            call t.SetIcon("ability_hunter_pet_bear")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Sharpened Claws <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Sharpened Claws")
            call t.SetDescription("Increases your critical strike chance while in Bear, Dire Bear or Cat Form by 2%%.")
            call t.SetIcon("inv_misc_monsterclaw_04")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Sharpened Claws")
            call t.SetDescription("Increases your critical strike chance while in Bear, Dire Bear or Cat Form by 4%%.")
            call t.SetIcon("inv_misc_monsterclaw_04")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 4, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Sharpened Claws")
            call t.SetDescription("Increases your critical strike chance while in Bear, Dire Bear or Cat Form by 6%%.")
            call t.SetIcon("inv_misc_monsterclaw_04")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // TalentName <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Link Top left")
            call t.SetDescription("Links")
            call t.SetDependencies(3, 0, 0, 0)
            set t.isLink = true
            call this.AddTalent(3, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Improved Shred <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(10)
            call t.SetName("Improved Shred")
            call t.SetDescription("Reduces the Energy cost of your Shred ability by 6.")
            call t.SetIcon("VampiricAura")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(10)
            call t.SetName("Improved Shred")
            call t.SetDescription("Reduces the Energy cost of your Shred ability by 12.")
            call t.SetIcon("VampiricAura")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Predatory Strikes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Predatory Strikes")
            call t.SetDescription("Increases your melee attack power in Cat, Bear and Dire Bear Forms by 50%% of your level.")
            call t.SetIcon("ability_hunter_pet_cat")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Predatory Strikes")
            call t.SetDescription("Increases your melee attack power in Cat, Bear and Dire Bear Forms by 100%% of your level.")
            call t.SetIcon("ability_hunter_pet_cat")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Predatory Strikes")
            call t.SetDescription("Increases your melee attack power in Cat, Bear and Dire Bear Forms by 150%% of your level.")
            call t.SetIcon("ability_hunter_pet_cat")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Blood Frenzy <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(12)
            call t.SetName("Blood Frenzy")
            call t.SetDescription("Requires Cat Form\nYour critical strikes from Cat Form abilities that add combo points  have a 50%% chance to add an additional combo point.")
            call t.SetIcon("GhoulFrenzy")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 3, 0, 0)
            call this.AddTalent(2, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(12)
            call t.SetName("Blood Frenzy")
            call t.SetDescription("Requires Cat Form\nYour critical strikes from Cat Form abilities that add combo points  have a 100%% chance to add an additional combo point.")
            call t.SetIcon("GhoulFrenzy")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 3, 0, 0)
            call this.AddTalent(2, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Primal Fury <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Primal Fury")
            call t.SetDescription("Requires Bear Form, Dire Bear Form\nGives you a 50%% chance to gain an additional 5 Rage anytime you get a critical strike while in Bear and Dire Bear Form.")
            call t.SetIcon("Cannibalize")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(3, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Primal Fury")
            call t.SetDescription("Requires Bear Form, Dire Bear Form\nGives you a 100%% chance to gain an additional 5 Rage anytime you get a critical strike while in Bear and Dire Bear Form.")
            call t.SetIcon("Cannibalize")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(3, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Savage Fury <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Savage Fury")
            call t.SetDescription("Increases the damage caused by your Claw, Rake, Maul and Swipe abilities by 10%%.")
            call t.SetIcon("ability_druid_ravage")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 2, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Savage Fury")
            call t.SetDescription("Increases the damage caused by your Claw, Rake, Maul and Swipe abilities by 20%%.")
            call t.SetIcon("ability_druid_ravage")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // TalentName <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(15)
            call t.SetName("Link Bottom")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 3, 0, 0)
            set t.isLink = true
            call this.AddTalent(1, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // TalentName <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Faerie Fire (Feral)")
            call t.SetDescription("Requires Cat Form, Bear Form, Dire Bear Form\nDecrease the armor of the target by 175 for 40 sec.  While affected, the target cannot stealth or turn invisible.")
            call t.SetIcon("FaerieFire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Heart of the Wild <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Heart of the Wild")
            call t.SetDescription("Increases your Intellect by 4%%.  In addition, while in Bear or Dire Bear Form your Stamina is increased by 4%% and while in Cat Form your Strength is increased by 4%%.")
            call t.SetIcon("spell_holy_blessingofagility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(1, 1, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Heart of the Wild")
            call t.SetDescription("Increases your Intellect by 8%%.  In addition, while in Bear or Dire Bear Form your Stamina is increased by 8%% and while in Cat Form your Strength is increased by 4%%.")
            call t.SetIcon("spell_holy_blessingofagility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(1, 1, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Heart of the Wild")
            call t.SetDescription("Increases your Intellect by 12%%.  In addition, while in Bear or Dire Bear Form your Stamina is increased by 12%% and while in Cat Form your Strength is increased by 4%%.")
            call t.SetIcon("spell_holy_blessingofagility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(1, 1, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Heart of the Wild")
            call t.SetDescription("Increases your Intellect by 16%%.  In addition, while in Bear or Dire Bear Form your Stamina is increased by 16%% and while in Cat Form your Strength is increased by 4%%.")
            call t.SetIcon("spell_holy_blessingofagility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(1, 1, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Heart of the Wild")
            call t.SetDescription("Increases your Intellect by 20%%.  In addition, while in Bear or Dire Bear Form your Stamina is increased by 20%% and while in Cat Form your Strength is increased by 4%%.")
            call t.SetIcon("spell_holy_blessingofagility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(1, 1, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Leader of the Pack <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(18)
            call t.SetName("Leader of the Pack")
            call t.SetDescription("While in Cat, Bear or Dire Bear Form, the Leader of the Pack increases ranged and melee critical chance of all party members within 45 yards by 3%%.")
            call t.SetIcon("spell_nature_unyeildingstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 0, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Only need to call this if some talents start with certain rank
            // call this.SaveTalentRankState()
        endmethod


        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // Can use these methods inside Activate/Deactivate/Allocate/Deallocate/Requirements functions
        
        // Returns unit that owns the talent tree
        // static method GetEventUnit takes nothing returns unit
        // thistype.GetEventUnit()

        // Returns talent object that is being resolved
        // static method GetEventTalent takes nothing returns STKTalent_Talent
        // thistype.GetEventTalent()

        // Returns rank of the talent that is being activated
        // static method GetEventRank takes nothing returns integer
        // thistype.GetEventRank()

        // Returns "this"
        // static method GetEventTalentTree takes nothing returns TalentTree
        // thistype.GetEventTalentTree()

        // Needs to be called within Requirements function to disable the talent
        // static method SetTalentRequirementsResult takes string requirements returns nothing
        // thistype.SetTalentRequirementsResult("8 litres of milk")

        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        static method Activate_CallSheep takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            call CreateUnit(GetOwningPlayer(u), 'nshe', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
        endmethod

        static method Activate_CallFlyingSheep takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            call CreateUnit(GetOwningPlayer(u), 'nshf', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
        endmethod

        static method Activate_GainApprentice takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            call CreateUnit(GetOwningPlayer(u), 'hpea', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
        endmethod

        static method Activate_Gain2Guards takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            call CreateUnit(GetOwningPlayer(u), 'hfoo', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
            call CreateUnit(GetOwningPlayer(u), 'hfoo', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
        endmethod

        static method Activate_ComingOfTheLambs takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            local integer i = thistype.GetEventRank()
            loop
                exitwhen i <= 0
                call CreateUnit(GetOwningPlayer(u), 'nshe', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
                call CreateUnit(GetOwningPlayer(u), 'nshf', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
                set i = i - 1
            endloop
        endmethod

        static method Activate_CallOfTheWilds takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            local integer i = 0
            loop
                exitwhen i > 5
                call CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), 'nwlt', GetUnitX(u), GetUnitY(u), GetRandomDirectionDeg())
                set i = i + 1
            endloop
        endmethod

        static method IsEnumUnitSheepFilter takes nothing returns boolean
            return GetUnitTypeId(GetFilterUnit()) == 'nshe' or GetUnitTypeId(GetFilterUnit()) == 'nshf'
        endmethod

        static method Requirement_CallOfTheWilds takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            local group g = CreateGroup()
            call GroupEnumUnitsInRange(g, GetUnitX(u), GetUnitY(u), 5000, Filter(function thistype.IsEnumUnitSheepFilter))
            if (CountUnitsInGroup(g) < 8) then
                call thistype.SetTalentRequirementsResult("8 nearby sheep")
            endif
        endmethod

        static method Deactivate_Generic takes nothing returns nothing
            local unit u = thistype.GetEventUnit()
            local STKTalent_Talent t = thistype.GetEventTalent()
            local integer r = thistype.GetEventRank()
            call BJDebugMsg("Deactivated " + t.name + " " + I2S(r))
        endmethod

        static method LoadCreate takes unit u returns Feral
            return thistype.create(u)
        endmethod
    endstruct

    private function init takes nothing returns nothing
        // Register Talent Trees
        call STKSaveLoad_RegisterTalentTree(2, Feral.LoadCreate)
    endfunction

endscope