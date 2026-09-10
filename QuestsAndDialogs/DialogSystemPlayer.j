library DialogSystemPlayer initializer Init requires DialogSystem, VoicelinesZulkis
//===========================================================================
// DialogSystemPlayer
// Player-specific dialog line registration.
//===========================================================================
private function LinesZulkis takes nothing returns nothing
	call DialogSystem_RegisterGreetLine("Zulkis", VL_ZULKISDIALOG_GREET_1_TEXT, VL_ZULKISDIALOG_GREET_1_KEY, true)
	call DialogSystem_RegisterGreetLine("Zulkis", VL_ZULKISDIALOG_GREET_2_TEXT, VL_ZULKISDIALOG_GREET_2_KEY, true)
	call DialogSystem_RegisterGreetLine("Zulkis", VL_ZULKISDIALOG_GREET_3_TEXT, VL_ZULKISDIALOG_GREET_3_KEY, true)
	call DialogSystem_RegisterGreetLine("Zulkis", VL_ZULKISDIALOG_GREET_4_TEXT, VL_ZULKISDIALOG_GREET_4_KEY, true)

	call DialogSystem_RegisterFarewellLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_1_TEXT, VL_ZULKISDIALOG_FAREWELL_1_KEY, true)
	call DialogSystem_RegisterFarewellLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_2_TEXT, VL_ZULKISDIALOG_FAREWELL_2_KEY, true)
	call DialogSystem_RegisterFarewellLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_3_TEXT, VL_ZULKISDIALOG_FAREWELL_3_KEY, true)
	call DialogSystem_RegisterFarewellLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_4_TEXT, VL_ZULKISDIALOG_FAREWELL_4_KEY, true)

	call DialogSystem_RegisterGreetTrainerLine("Zulkis", VL_ZULKISDIALOG_GREET_TRAINER_1_TEXT, VL_ZULKISDIALOG_GREET_TRAINER_1_KEY, true)
	call DialogSystem_RegisterGreetTrainerLine("Zulkis", VL_ZULKISDIALOG_GREET_TRAINER_2_TEXT, VL_ZULKISDIALOG_GREET_TRAINER_2_KEY, true)
	call DialogSystem_RegisterGreetTrainerLine("Zulkis", VL_ZULKISDIALOG_GREET_TRAINER_3_TEXT, VL_ZULKISDIALOG_GREET_TRAINER_3_KEY, true)
	call DialogSystem_RegisterGreetTrainerLine("Zulkis", VL_ZULKISDIALOG_GREET_TRAINER_4_TEXT, VL_ZULKISDIALOG_GREET_TRAINER_4_KEY, true)

	call DialogSystem_RegisterFarewellTrainerLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_TRAINER_1_TEXT, VL_ZULKISDIALOG_FAREWELL_TRAINER_1_KEY, true)
	call DialogSystem_RegisterFarewellTrainerLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_TRAINER_2_TEXT, VL_ZULKISDIALOG_FAREWELL_TRAINER_2_KEY, true)
	call DialogSystem_RegisterFarewellTrainerLine("Zulkis", VL_ZULKISDIALOG_FAREWELL_TRAINER_3_TEXT, VL_ZULKISDIALOG_FAREWELL_TRAINER_3_KEY, true)

	call DialogSystem_RegisterInfoLine("Zulkis", VL_ZULKISDIALOG_INFO_1_TEXT, VL_ZULKISDIALOG_INFO_1_KEY, true)
	call DialogSystem_RegisterInfoLine("Zulkis", VL_ZULKISDIALOG_INFO_2_TEXT, VL_ZULKISDIALOG_INFO_2_KEY, true)
	call DialogSystem_RegisterInfoLine("Zulkis", VL_ZULKISDIALOG_INFO_3_TEXT, VL_ZULKISDIALOG_INFO_3_KEY, true)
	call DialogSystem_RegisterInfoLine("Zulkis", VL_ZULKISDIALOG_INFO_4_TEXT, VL_ZULKISDIALOG_INFO_4_KEY, true)

	call DialogSystem_RegisterTradeLine("Zulkis", VL_ZULKISDIALOG_TRADE_1_TEXT, VL_ZULKISDIALOG_TRADE_1_KEY, true)

	call DialogSystem_RegisterExitLine("Zulkis", VL_ZULKISDIALOG_EXIT_1_TEXT, VL_ZULKISDIALOG_EXIT_1_KEY, true)

	call DialogSystem_RegisterFollowLine("Zulkis", VL_ZULKISDIALOG_FOLLOW_1_TEXT, VL_ZULKISDIALOG_FOLLOW_1_KEY, true)

	call DialogSystem_RegisterStopLine("Zulkis", VL_ZULKISDIALOG_STOP_1_TEXT, VL_ZULKISDIALOG_STOP_1_KEY, true)

	call DialogSystem_RegisterDeclineLine("Zulkis", VL_ZULKISDIALOG_DECLINE_1_TEXT, VL_ZULKISDIALOG_DECLINE_1_KEY, true)

	call DialogSystem_RegisterAcceptLine("Zulkis", VL_ZULKISDIALOG_ACCEPT_1_TEXT, VL_ZULKISDIALOG_ACCEPT_1_KEY, true)

	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "Invite", VL_ZULKISDIALOG_COMPANION_INVITE_1_TEXT, VL_ZULKISDIALOG_COMPANION_INVITE_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "Invite", VL_ZULKISDIALOG_COMPANION_INVITE_2_TEXT, VL_ZULKISDIALOG_COMPANION_INVITE_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "Kick", VL_ZULKISDIALOG_COMPANION_KICK_1_TEXT, VL_ZULKISDIALOG_COMPANION_KICK_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "Kick", VL_ZULKISDIALOG_COMPANION_KICK_2_TEXT, VL_ZULKISDIALOG_COMPANION_KICK_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "DropItems", VL_ZULKISDIALOG_COMPANION_DROP_ITEMS_1_TEXT, VL_ZULKISDIALOG_COMPANION_DROP_ITEMS_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "DropItems", VL_ZULKISDIALOG_COMPANION_DROP_ITEMS_2_TEXT, VL_ZULKISDIALOG_COMPANION_DROP_ITEMS_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "PassiveMode", VL_ZULKISDIALOG_COMPANION_PASSIVE_MODE_1_TEXT, VL_ZULKISDIALOG_COMPANION_PASSIVE_MODE_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "PassiveMode", VL_ZULKISDIALOG_COMPANION_PASSIVE_MODE_2_TEXT, VL_ZULKISDIALOG_COMPANION_PASSIVE_MODE_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "NormalMode", VL_ZULKISDIALOG_COMPANION_NORMAL_MODE_1_TEXT, VL_ZULKISDIALOG_COMPANION_NORMAL_MODE_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "NormalMode", VL_ZULKISDIALOG_COMPANION_NORMAL_MODE_2_TEXT, VL_ZULKISDIALOG_COMPANION_NORMAL_MODE_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "AggressiveMode", VL_ZULKISDIALOG_COMPANION_AGGRESSIVE_MODE_1_TEXT, VL_ZULKISDIALOG_COMPANION_AGGRESSIVE_MODE_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "AggressiveMode", VL_ZULKISDIALOG_COMPANION_AGGRESSIVE_MODE_2_TEXT, VL_ZULKISDIALOG_COMPANION_AGGRESSIVE_MODE_2_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "HoldMode", VL_ZULKISDIALOG_COMPANION_HOLD_MODE_1_TEXT, VL_ZULKISDIALOG_COMPANION_HOLD_MODE_1_KEY, true)
	call DialogSystem_RegisterCompanionCommandLine("Zulkis", "HoldMode", VL_ZULKISDIALOG_COMPANION_HOLD_MODE_2_TEXT, VL_ZULKISDIALOG_COMPANION_HOLD_MODE_2_KEY, true)

endfunction

private function LinesNazgrek takes nothing returns nothing
	call DialogSystem_RegisterGreetLine("Nazgrek", "Hello.", "Nazgrek_Greet1", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Well met.", "Nazgrek_Greet2", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Lok'tar!", "Nazgrek_Greet3", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Hi.", "Nazgrek_Greet4", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Greetings.", "Nazgrek_Greet5", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Well met.", "Nazgrek_Greet6", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Aka'magosh.", "Nazgrek_Greet7", true)
	call DialogSystem_RegisterGreetLine("Nazgrek", "Hello there.", "Nazgrek_Greet8", true)

	call DialogSystem_RegisterFarewellLine("Nazgrek", "Walk with honor.", "Nazgrek_Farewell1", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "May the ancestors guide you.", "Nazgrek_Farewell2", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "Spirits be with you.", "Nazgrek_Farewell3", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "Until we meet again.", "Nazgrek_Farewell4", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "Until next time.", "Nazgrek_Farewell5", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "Farewell.", "Nazgrek_Farewell6", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "I will see you again.", "Nazgrek_Farewell7", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "I have to go now.", "Nazgrek_Farewell8", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "We will meet again.", "Nazgrek_Farewell9", true)
	call DialogSystem_RegisterFarewellLine("Nazgrek", "Goodbye.", "Nazgrek_Farewell10", true)

	call DialogSystem_RegisterGreetTrainerLine("Nazgrek", "I seek training.", "Nazgrek_GreetTrainer1", true)
	call DialogSystem_RegisterGreetTrainerLine("Nazgrek", "Show me the shaman's path.", "Nazgrek_GreetTrainer2", true)
	call DialogSystem_RegisterGreetTrainerLine("Nazgrek", "What wisdom do you offer?", "Nazgrek_GreetTrainer3", true)
	call DialogSystem_RegisterGreetTrainerLine("Nazgrek", "I am ready to learn.", "Nazgrek_GreetTrainer4", true)

	call DialogSystem_RegisterFarewellTrainerLine("Nazgrek", "I will return for more training.", "Nazgrek_FarewellTrainer1", true)
	call DialogSystem_RegisterFarewellTrainerLine("Nazgrek", "The lesson is learned.", "Nazgrek_FarewellTrainer2", true)
	call DialogSystem_RegisterFarewellTrainerLine("Nazgrek", "May the spirits guide your steps.", "Nazgrek_FarewellTrainer3", true)

	call DialogSystem_RegisterInfoLine("Nazgrek", "Tell me more.", "Nazgrek_Info1", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Is there something you can tell me?", "Nazgrek_Info2", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "What's your take on this?", "Nazgrek_Info3", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Can you share your knowledge?", "Nazgrek_Info4", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "What should I know?", "Nazgrek_Info5", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Explain this to me.", "Nazgrek_Info6", true)

	call DialogSystem_RegisterTradeLine("Nazgrek", "Let's trade.", "Nazgrek_Trade1", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Show me what you have.", "Nazgrek_Trade2", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Let's see your wares.", "Nazgrek_Trade3", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Got anything for sale?", "Nazgrek_Trade4", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Let us trade.", "Nazgrek_Trade5", true)

	call DialogSystem_RegisterExitLine("Nazgrek", "Farewell.", "Nazgrek_Exit1", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Goodbye.", "Nazgrek_Exit2", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Until next time.", "Nazgrek_Exit3", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Safe travels.", "Nazgrek_Exit4", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "May your path be clear.", "Nazgrek_Exit5", true)

	call DialogSystem_RegisterFollowLine("Nazgrek", "Follow me.", "Nazgrek_Follow1", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Stay close.", "Nazgrek_Follow2", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Come with me.", "Nazgrek_Follow3", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Move out.", "Nazgrek_Follow4", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Let's go.", "Nazgrek_Follow5", true)

	call DialogSystem_RegisterStopLine("Nazgrek", "Stay here.", "Nazgrek_Stop1", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Hold position.", "Nazgrek_Stop2", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Wait here.", "Nazgrek_Stop3", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Stand your ground.", "Nazgrek_Stop4", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Remain here.", "Nazgrek_Stop5", true)

	call DialogSystem_RegisterDeclineLine("Nazgrek", "Not this time.", "Nazgrek_Decline1", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "Not now.", "Nazgrek_Decline2", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "I cannot.", "Nazgrek_Decline3", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "I must decline.", "Nazgrek_Decline4", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "Perhaps another time.", "Nazgrek_Decline5", true)

	// REDO THE LINES / DIFFER ACCEPT (TAKE QUEST) VS SEPERATE ACCEPT (AGREE TO SOMETHING ELSE)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Yes.", "Nazgrek_Accept1", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "I accept.", "Nazgrek_Accept2", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Consider it done.", "Nazgrek_Accept3", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Very well.", "Nazgrek_Accept4", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Agreed.", "Nazgrek_Accept5", true)

	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "Invite", "Nice to meet you.", "Nazgrek_CompanionInvite1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "Invite", "Walk with me.", "Nazgrek_CompanionInvite2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "Kick", "You are dismissed.", "Nazgrek_CompanionKick1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "Kick", "Take care.", "Nazgrek_CompanionKick2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "DropItems", "Drop whatever you are carrying.", "Nazgrek_CompanionDropItems1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "DropItems", "Leave those items here.", "Nazgrek_CompanionDropItems2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "PassiveMode", "Follow me and don't attack.", "Nazgrek_CompanionPassiveMode1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "PassiveMode", "Don't attack unless I say otherwise.", "Nazgrek_CompanionPassiveMode2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "NormalMode", "Stay close.", "Nazgrek_CompanionNormalMode1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "NormalMode", "Form up.", "Nazgrek_CompanionNormalMode2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "AggressiveMode", "Stay aggressive.", "Nazgrek_CompanionAggressiveMode1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "AggressiveMode", "Engage on sight.", "Nazgrek_CompanionAggressiveMode2", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "HoldMode", "Hold this position.", "Nazgrek_CompanionHoldMode1", true)
	call DialogSystem_RegisterCompanionCommandLine("Nazgrek", "HoldMode", "Stay here.", "Nazgrek_CompanionHoldMode2", true)

endfunction

private function Init takes nothing returns nothing
	call LinesZulkis()
	call LinesNazgrek()

endfunction

endlibrary
