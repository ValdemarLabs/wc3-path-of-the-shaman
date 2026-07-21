scope Balance initializer init

    struct Balance extends STKTalentTree_TalentTree

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

            call this.SetIdColumnsRows(1, 4, 7)
            set this.title = "Balance"
            call this.SetTalentPoints(6)
            set this.backgroundImage = "balancebg.blp"
            // set this.icon = "FireBolt"
            // TODO: set tree background texture here

            // The tree should be built with talents here
            // ==============================================

            // Improved Wrath <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Wrath")
            call t.SetDescription("Reduces the cast time of your Wrath spell by 0.1 sec.")
            call t.SetIcon("spell_nature_abolishmagic")
            call t.SetOnActivate(function thistype.Activate_CallSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Wrath")
            call t.SetDescription("Reduces the cast time of your Wrath spell by 0.2 sec.")
            call t.SetIcon("spell_nature_abolishmagic")
            call t.SetOnActivate(function thistype.Activate_CallSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Wrath")
            call t.SetDescription("Reduces the cast time of your Wrath spell by 0.3 sec.")
            call t.SetIcon("spell_nature_abolishmagic")
            call t.SetOnActivate(function thistype.Activate_CallSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Wrath")
            call t.SetDescription("Reduces the cast time of your Wrath spell by 0.4 sec.")
            call t.SetIcon("spell_nature_abolishmagic")
            call t.SetOnActivate(function thistype.Activate_CallSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 6, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(1)
            call t.SetName("Improved Wrath")
            call t.SetDescription("Reduces the cast time of your Wrath spell by 0.5 sec.")
            call t.SetIcon("spell_nature_abolishmagic")
            call t.SetOnActivate(function thistype.Activate_CallSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Nature's Grasp <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(2)
            call t.SetName("Nature's Grasp")
            call t.SetDescription("While active, any time an enemy strikes the caster they have a 35%% chance to become afflicted by Entangling Roots (Rank 1).  Only useable outdoors.  1 charge.  Lasts 45 sec.")
            call t.SetIcon("spell_nature_natureswrath")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Nature's Grasp <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Nature's Grasp")
            call t.SetDescription("Increases the chance for your Nature's Grasp to entangle an enemy by 15%%.")
            call t.SetIcon("spell_nature_natureswrath")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(1, 0, 0, 0) // left 1 (left up right down)
            call this.AddTalent(2, 6, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Nature's Grasp")
            call t.SetDescription("Increases the chance for your Nature's Grasp to entangle an enemy by 30%%.")
            call t.SetIcon("spell_nature_natureswrath")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(1, 0, 0, 0) // left 1 (left up right down)
            call this.AddTalent(2, 6, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Nature's Grasp")
            call t.SetDescription("Increases the chance for your Nature's Grasp to entangle an enemy by 45%%.")
            call t.SetIcon("spell_nature_natureswrath")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(1, 0, 0, 0) // left 1 (left up right down)
            call this.AddTalent(2, 6, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(3)
            call t.SetName("Improved Nature's Grasp")
            call t.SetDescription("Increases the chance for your Nature's Grasp to entangle an enemy by 65%%.")
            call t.SetIcon("spell_nature_natureswrath")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(1, 0, 0, 0) // left 1 (left up right down)
            call this.AddTalent(2, 6, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Entangling Roots <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Improved Entangling Roots")
            call t.SetDescription("Gives you a 40%% chance to avoid interruption caused by damage while casting Entangling Roots.")
            call t.SetIcon("EntanglingRoots")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Improved Entangling Roots")
            call t.SetDescription("Gives you a 70%% chance to avoid interruption caused by damage while casting Entangling Roots.")
            call t.SetIcon("EntanglingRoots")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(5)
            call t.SetName("Improved Entangling Roots")
            call t.SetDescription("Gives you a 100%% chance to avoid interruption caused by damage while casting Entangling Roots.")
            call t.SetIcon("EntanglingRoots")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Moonfire <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Improved Moonfire")
            call t.SetDescription("Increases the damage and critical strike chance of your Moonfire spell by 2%%.")
            call t.SetIcon("Starfall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
           // Rank 2
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Improved Moonfire")
            call t.SetDescription("Increases the damage and critical strike chance of your Moonfire spell by 4%%.")
            call t.SetIcon("Starfall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Improved Moonfire")
            call t.SetDescription("Increases the damage and critical strike chance of your Moonfire spell by 6%%.")
            call t.SetIcon("Starfall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Improved Moonfire")
            call t.SetDescription("Increases the damage and critical strike chance of your Moonfire spell by 8%%.")
            call t.SetIcon("Starfall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(6)
            call t.SetName("Improved Moonfire")
            call t.SetDescription("Increases the damage and critical strike chance of your Moonfire spell by 10%%.")
            call t.SetIcon("Starfall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 5, t) 
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Natural Weapons <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Natural Weapons")
            call t.SetDescription("Increases the damage you deal with physical attacks in all forms by 2%%.")
            call t.SetIcon("AdvancedStrengthOfTheMoon")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Natural Weapons")
            call t.SetDescription("Increases the damage you deal with physical attacks in all forms by 4%%.")
            call t.SetIcon("AdvancedStrengthOfTheMoon")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Natural Weapons")
            call t.SetDescription("Increases the damage you deal with physical attacks in all forms by 6%%.")
            call t.SetIcon("AdvancedStrengthOfTheMoon")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Natural Weapons")
            call t.SetDescription("Increases the damage you deal with physical attacks in all forms by 8%%.")
            call t.SetIcon("AdvancedStrengthOfTheMoon")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(7)
            call t.SetName("Natural Weapons")
            call t.SetDescription("Increases the damage you deal with physical attacks in all forms by 10%%.")
            call t.SetIcon("AdvancedStrengthOfTheMoon")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Natural Shapeshifter <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Natural Shapeshifter")
            call t.SetDescription("Reduces the mana cost of all shapeshifting by 10%%.")
            call t.SetIcon("WispSplode")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 5, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Natural Shapeshifter")
            call t.SetDescription("Reduces the mana cost of all shapeshifting by 20%%.")
            call t.SetIcon("WispSplode")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 5, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(8)
            call t.SetName("Natural Shapeshifter")
            call t.SetDescription("Reduces the mana cost of all shapeshifting by 30%%.")
            call t.SetIcon("WispSplode")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 5, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Thorns <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Improved Thorns")
            call t.SetDescription("Increases damage caused by your Thorns spell by 25%%.")
            call t.SetIcon("Thorns")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Improved Thorns")
            call t.SetDescription("Increases damage caused by your Thorns spell by 50%%.")
            call t.SetIcon("Thorns")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 4, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(9)
            call t.SetName("Improved Thorns")
            call t.SetDescription("Increases damage caused by your Thorns spell by 75%%.")
            call t.SetIcon("Thorns")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(0, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Link >>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(10)
            call t.SetName("Link")
            call t.SetDescription("Links")
            call t.SetDependencies(0, 5, 0, 0)
            set t.isLink = true
            call this.AddTalent(1, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // Omen of Clarity <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(11)
            call t.SetName("Omen of Clarity")
            call t.SetDescription("Imbues the Druid with natural energy.  Each of the Druid's melee attacks has a chance of causing the caster to enter a Clearcasting state.  The Clearcasting state reduces the Mana, Rage or Energy cost of your next damage or healing spell or offensive ability by 100%%.  Lasts 10 min.")
            call t.SetIcon("CrystalBall")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 5, 0, 0) // left 1 (left up right down)
            call this.AddTalent(2, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Nature's Reach <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(12)
            call t.SetName("Nature's Reach")
            call t.SetDescription("Increases the range of your Wrath, Entangling Roots, Faerie Fire, Moonfire, Starfire, and Hurricane spells by 10%%.")
            call t.SetIcon("spell_nature_naturetouchgrow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(12)
            call t.SetName("Nature's Reach")
            call t.SetDescription("Increases the range of your Wrath, Entangling Roots, Faerie Fire, Moonfire, Starfire, and Hurricane spells by 20%%.")
            call t.SetIcon("spell_nature_naturetouchgrow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(3, 4, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Vengeance <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Vengeance")
            call t.SetDescription("Increases the critical strike damage bonus of your Starfire, Moonfire, and Wrath spells by 20%%.")
            call t.SetIcon("Purge")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Vengeance")
            call t.SetDescription("Increases the critical strike damage bonus of your Starfire, Moonfire, and Wrath spells by 40%%.")
            call t.SetIcon("Purge")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 3, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Vengeance")
            call t.SetDescription("Increases the critical strike damage bonus of your Starfire, Moonfire, and Wrath spells by 60%%.")
            call t.SetIcon("Purge")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 3, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Vengeance")
            call t.SetDescription("Increases the critical strike damage bonus of your Starfire, Moonfire, and Wrath spells by 80%%.")
            call t.SetIcon("Purge")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 3, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(13)
            call t.SetName("Vengeance")
            call t.SetDescription("Increases the critical strike damage bonus of your Starfire, Moonfire, and Wrath spells by 100%%.")
            call t.SetIcon("Purge")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Improved Starfire <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Improved Starfire")
            call t.SetDescription("Reduces the cast time of Starfire by 0.1 sec and has a 3%% chance to stun the target for 3 sec.")
            call t.SetIcon("spell_arcane_starfire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 3, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Improved Starfire")
            call t.SetDescription("educes the cast time of Starfire by 0.2 sec and has a 6%% chance to stun the target for 3 sec.")
            call t.SetIcon("spell_arcane_starfire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 3, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Improved Starfire")
            call t.SetDescription("Reduces the cast time of Starfire by 0.3 sec and has a 9%% chance to stun the target for 3 sec.")
            call t.SetIcon("spell_arcane_starfire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 3, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Improved Starfire")
            call t.SetDescription("Reduces the cast time of Starfire by 0.4 sec and has a 12%% chance to stun the target for 3 sec.")
            call t.SetIcon("spell_arcane_starfire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 3, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(14)
            call t.SetName("Improved Starfire")
            call t.SetDescription("Reduces the cast time of Starfire by 0.5 sec and has a 15%% chance to stun the target for 3 sec.")
            call t.SetIcon("spell_arcane_starfire")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 3, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Nature's Grace <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(15)
            call t.SetName("Nature's Grace")
            call t.SetDescription("All spell criticals grace you with a blessing of nature, reducing the casting time of your next spell by 0.5 sec.")
            call t.SetIcon("NaturesBlessing")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(1, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Moonglow <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Moonglow")
            call t.SetDescription("Reduces the Mana cost of your Moonfire, Starfire, Wrath, Healing Touch, Regrowth and Rejuvenation spells by 3%%.")
            call t.SetIcon("Sentinel")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 2, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Moonglow")
            call t.SetDescription("Reduces the Mana cost of your Moonfire, Starfire, Wrath, Healing Touch, Regrowth and Rejuvenation spells by 6%%.")
            call t.SetIcon("Sentinel")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 2, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(16)
            call t.SetName("Moonglow")
            call t.SetDescription("Reduces the Mana cost of your Moonfire, Starfire, Wrath, Healing Touch, Regrowth and Rejuvenation spells by 9%%.")
            call t.SetIcon("Sentinel")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call this.AddTalent(2, 2, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Moonfury <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Moonfury")
            call t.SetDescription("Increases the damage done by your Starfire, Moonfire and Wrath spells by 2%%.")
            call t.SetIcon("spell_nature_moonglow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 1, t)
            // Rank 2
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Moonfury")
            call t.SetDescription("Increases the damage done by your Starfire, Moonfire and Wrath spells by 4%%.")
            call t.SetIcon("spell_nature_moonglow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 1, t)
            // Rank 3
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Moonfury")
            call t.SetDescription("Increases the damage done by your Starfire, Moonfire and Wrath spells by 6%%.")
            call t.SetIcon("spell_nature_moonglow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 1, t)
            // Rank 4
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Moonfury")
            call t.SetDescription("Increases the damage done by your Starfire, Moonfire and Wrath spells by 8%%.")
            call t.SetIcon("spell_nature_moonglow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 1, t)
            // Rank 5
            set t = this.CreateTalent().SetChainId(17)
            call t.SetName("Moonfury")
            call t.SetDescription("Increases the damage done by your Starfire, Moonfire and Wrath spells by 10%%.")
            call t.SetIcon("spell_nature_moonglow")
            call t.SetOnActivate(function thistype.Activate_CallFlyingSheep)
            call t.SetOnDeactivate(function thistype.Deactivate_Generic)
            call t.SetDependencies(0, 1, 0, 0) // left 1 (left up right down)
            call this.AddTalent(1, 1, t)
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Moonkin Form <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            // Rank 1
            set t = this.CreateTalent().SetChainId(18)
            call t.SetName("Moonkin Form")
            call t.SetDescription("Transforms the Druid into Moonkin Form.  While in this form the armor contribution from items is increased by 360%% and all party members within 30 yards have their spell critical chance increased by 3%%.  The Moonkin can only cast Balance spells while shapeshifted.\n\nThe act of shapeshifting frees the caster of Polymorph and Movement Impairing effects.")
            call t.SetIcon("spell_nature_forceofnature")
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

        static method LoadCreate takes unit u returns Balance
            return thistype.create(u)
        endmethod
    endstruct

    private function init takes nothing returns nothing
        // Register Talent Trees
        call STKSaveLoad_RegisterTalentTree(1, Balance.LoadCreate)
    endfunction

endscope