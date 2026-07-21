scope Restoration initializer init

    struct Restoration extends STKTalentTree_TalentTree

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

            call this.SetIdColumnsRows(3, 4, 7)
            set this.title = "Restoration"
            call this.SetTalentPoints(6)
            set this.backgroundImage = "resto.blp"
            // set this.icon = "FireBolt"
            // TODO: set tree background texture here

            // The tree should be built with talents here
            // ==============================================

            // Improved Mark of the Wild <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Mark of the Wild")
            call t.SetDescription("Increases the effects of your Mark of the Wild and Gift of the Wild spells by 7%%.")
            call t.SetIcon("spell_nature_regeneration")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Mark of the Wild")
            call t.SetDescription("Increases the effects of your Mark of the Wild and Gift of the Wild spells by 14%%.")
            call t.SetIcon("spell_nature_regeneration")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Mark of the Wild")
            call t.SetDescription("Increases the effects of your Mark of the Wild and Gift of the Wild spells by 21%%.")
            call t.SetIcon("spell_nature_regeneration")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Mark of the Wild")
            call t.SetDescription("Increases the effects of your Mark of the Wild and Gift of the Wild spells by 28%%.")
            call t.SetIcon("spell_nature_regeneration")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Mark of the Wild")
            call t.SetDescription("Increases the effects of your Mark of the Wild and Gift of the Wild spells by 35%%.")
            call t.SetIcon("spell_nature_regeneration")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Furor <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Furor")
            call t.SetDescription("Gives you 20%% chance to gain 10 Rage when you shapeshift into Bear and Dire Bear Form or 40 Energy when you shapeshift into Cat Form.")
            call t.SetIcon("spell_holy_blessingofstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Furor")
            call t.SetDescription("Gives you 40%% chance to gain 10 Rage when you shapeshift into Bear and Dire Bear Form or 40 Energy when you shapeshift into Cat Form.")
            call t.SetIcon("spell_holy_blessingofstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Furor")
            call t.SetDescription("Gives you 60%% chance to gain 10 Rage when you shapeshift into Bear and Dire Bear Form or 40 Energy when you shapeshift into Cat Form.")
            call t.SetIcon("spell_holy_blessingofstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Furor")
            call t.SetDescription("Gives you 80%% chance to gain 10 Rage when you shapeshift into Bear and Dire Bear Form or 40 Energy when you shapeshift into Cat Form.")
            call t.SetIcon("spell_holy_blessingofstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Furor")
            call t.SetDescription("Gives you 100%% chance to gain 10 Rage when you shapeshift into Bear and Dire Bear Form or 40 Energy when you shapeshift into Cat Form.")
            call t.SetIcon("spell_holy_blessingofstamina")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Healing Touch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Healing Touch")
            call t.SetDescription("Reduces the cast time of your Healing Touch spell by 0.1 sec.")
            call t.SetIcon("spell_nature_healingtouch")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Healing Touch")
            call t.SetDescription("Reduces the cast time of your Healing Touch spell by 0.2 sec.")
            call t.SetIcon("spell_nature_healingtouch")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Healing Touch")
            call t.SetDescription("Reduces the cast time of your Healing Touch spell by 0.3 sec.")
            call t.SetIcon("spell_nature_healingtouch")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Healing Touch")
            call t.SetDescription("Reduces the cast time of your Healing Touch spell by 0.4 sec.")
            call t.SetIcon("spell_nature_healingtouch")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Healing Touch")
            call t.SetDescription("Reduces the cast time of your Healing Touch spell by 0.5 sec.")
            call t.SetIcon("spell_nature_healingtouch")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Nature's Focus <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Nature's Focus")
            call t.SetDescription("Gives you a 14%% chance to avoid interruption caused by damage while casting the Healing Touch, Regrowth and Tranquility spells.")
            call t.SetIcon("MagicImmunity")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Nature's Focus")
            call t.SetDescription("Gives you a 28%% chance to avoid interruption caused by damage while casting the Healing Touch, Regrowth and Tranquility spells.")
            call t.SetIcon("MagicImmunity")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Nature's Focus")
            call t.SetDescription("Gives you a 42%% chance to avoid interruption caused by damage while casting the Healing Touch, Regrowth and Tranquility spells.")
            call t.SetIcon("MagicImmunity")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Nature's Focus")
            call t.SetDescription("Gives you a 56%% chance to avoid interruption caused by damage while casting the Healing Touch, Regrowth and Tranquility spells.")
            call t.SetIcon("MagicImmunity")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(4)
            call t.SetName("Nature's Focus")
            call t.SetDescription("Gives you a 70%% chance to avoid interruption caused by damage while casting the Healing Touch, Regrowth and Tranquility spells.")
            call t.SetIcon("MagicImmunity")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Enrage <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Improved Enrage")
            call t.SetDescription("The Enrage ability now instantly generates 5 Rage.")
            call t.SetIcon("ability_druid_enrage")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Improved Enrage")
            call t.SetDescription("The Enrage ability now instantly generates 10 Rage.")
            call t.SetIcon("ability_druid_enrage")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // TalentName <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Link Top left")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 5, 0, 0)
            set t.isLink = true
            call this.AddTalent(0, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Reflection <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Reflection")
            call t.SetDescription("Allows 5%% of your Mana regeneration to continue while casting.")
            call t.SetIcon("WindWalkOn")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Reflection")
            call t.SetDescription("Allows 10%% of your Mana regeneration to continue while casting.")
            call t.SetIcon("WindWalkOn")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 4, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Reflection")
            call t.SetDescription("Allows 15%% of your Mana regeneration to continue while casting.")
            call t.SetIcon("WindWalkOn")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Insect Swarm <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Insect Swarm")
            call t.SetDescription("The enemy target is swarmed by insects, decreasing their chance to hit by 2%% and causing 66 Nature damage over 12 sec.")
            call t.SetIcon("spell_nature_insectswarm")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Subtlety <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Subtlety")
            call t.SetDescription("Reduces the threat generated by your Healing spells by 4%%.")
            call t.SetIcon("Scout")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Subtlety")
            call t.SetDescription("Reduces the threat generated by your Healing spells by 8%%.")
            call t.SetIcon("Scout")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Subtlety")
            call t.SetDescription("Reduces the threat generated by your Healing spells by 12%%.")
            call t.SetIcon("Scout")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Subtlety")
            call t.SetDescription("Reduces the threat generated by your Healing spells by 16%%.")
            call t.SetIcon("Scout")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Subtlety")
            call t.SetDescription("Reduces the threat generated by your Healing spells by 20%%.")
            call t.SetIcon("Scout")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // TalentName <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(10)
            call t.SetName("Link left")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 1, 0, 0)
            set t.isLink = true
            call this.AddTalent(0, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Tranquil Spirit <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Tranquil Spirit")
            call t.SetDescription("Reduces the mana cost of your Healing Touch and Tranquility spells by 2%%.")
            call t.SetIcon("ElunesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Tranquil Spirit")
            call t.SetDescription("Reduces the mana cost of your Healing Touch and Tranquility spells by 4%%.")
            call t.SetIcon("ElunesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Tranquil Spirit")
            call t.SetDescription("Reduces the mana cost of your Healing Touch and Tranquility spells by 6%%.")
            call t.SetIcon("ElunesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Tranquil Spirit")
            call t.SetDescription("Reduces the mana cost of your Healing Touch and Tranquility spells by 8%%.")
            call t.SetIcon("ElunesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Tranquil Spirit")
            call t.SetDescription("Reduces the mana cost of your Healing Touch and Tranquility spells by 10%%.")
            call t.SetIcon("ElunesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Link <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(12)
            call t.SetName("Link Middle")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 1, 0, 0)
            set t.isLink = true
            call this.AddTalent(2, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Improved Rejuvenation <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Improved Rejuvenation")
            call t.SetDescription("Increases the effect of your Rejuvenation spell by 5%%.")
            call t.SetIcon("Rejuvenation")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Improved Rejuvenation")
            call t.SetDescription("Increases the effect of your Rejuvenation spell by 10%%.")
            call t.SetIcon("Rejuvenation")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 3, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Improved Rejuvenation")
            call t.SetDescription("Increases the effect of your Rejuvenation spell by 15%%.")
            call t.SetIcon("Rejuvenation")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Nature's Swiftness <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Nature's Swiftness")
            call t.SetDescription("When activated, your next Nature spell becomes an instant cast spell.")
            call t.SetIcon("RavenForm")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(0, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Link <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(15)
            call t.SetName("Link Tranquil 1")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 5, 0, 0)
            set t.isLink = true
            call this.AddTalent(1, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Gift of Nature <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Gift of Nature")
            call t.SetDescription("Increases the effect of all healing spells by 2%%.")
            call t.SetIcon("spell_nature_protectionformnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(2, 2, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Gift of Nature")
            call t.SetDescription("Increases the effect of all healing spells by 4%%.")
            call t.SetIcon("spell_nature_protectionformnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(2, 2, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Gift of Nature")
            call t.SetDescription("Increases the effect of all healing spells by 6%%.")
            call t.SetIcon("spell_nature_protectionformnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(2, 2, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Gift of Nature")
            call t.SetDescription("Increases the effect of all healing spells by 8%%.")
            call t.SetIcon("spell_nature_protectionformnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(2, 2, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Gift of Nature")
            call t.SetDescription("Increases the effect of all healing spells by 10%%.")
            call t.SetIcon("spell_nature_protectionformnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
            call this.AddTalent(2, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Tranquility <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Improved Tranquility")
            call t.SetDescription("Reduces threat caused by Tranquility by 50%%.")
            call t.SetIcon("Tranquility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 2, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Improved Tranquility")
            call t.SetDescription("Reduces threat caused by Tranquility by 100%%.")
            call t.SetIcon("Tranquility")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Link <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(18)
            call t.SetName("Link Bottom")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 1, 0, 0)
            set t.isLink = true
            call this.AddTalent(1, 1, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Improved Regrowth <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(19)
            call t.SetName("Improved Regrowth")
            call t.SetDescription("Increases the critical effect chance of your Regrowth spell by 10%%.")
            call t.SetIcon("spell_nature_resistnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 1, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(19)
            call t.SetName("Improved Regrowth")
            call t.SetDescription("Increases the critical effect chance of your Regrowth spell by 20%%.")
            call t.SetIcon("spell_nature_resistnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 1, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(19)
            call t.SetName("Improved Regrowth")
            call t.SetDescription("Increases the critical effect chance of your Regrowth spell by 30%%.")
            call t.SetIcon("spell_nature_resistnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 1, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(19)
            call t.SetName("Improved Regrowth")
            call t.SetDescription("Increases the critical effect chance of your Regrowth spell by 40%%.")
            call t.SetIcon("spell_nature_resistnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 1, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(19)
            call t.SetName("Improved Regrowth")
            call t.SetDescription("Increases the critical effect chance of your Regrowth spell by 50%%.")
            call t.SetIcon("spell_nature_resistnature")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 1, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Swiftmend <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(20)
            call t.SetName("Swiftmend")
            call t.SetDescription("Consumes a Rejuvenation or Regrowth effect on a friendly target to instantly heal them an amount equal to 12 sec. of Rejuvenation or 18 sec. of Regrowth.")
            call t.SetIcon("inv_relics_idolofrejuvenation")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0)
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

        static method LoadCreate takes unit u returns Restoration
            return thistype.create(u)
        endmethod
    endstruct

    private function init takes nothing returns nothing
        // Register Talent Trees
        call STKSaveLoad_RegisterTalentTree(3, Restoration.LoadCreate)
    endfunction

endscope