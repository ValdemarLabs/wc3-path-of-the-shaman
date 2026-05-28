library DialogSystemPlayer initializer Init requires DialogSystem
//===========================================================================
// DialogSystemPlayer
// Player-specific dialog line registration.
//===========================================================================
private function LinesZulkis takes nothing returns nothing
	call DialogSystem_RegisterGreetLine("Zulkis", "How you doing, mon?", "Zulkis_Greet1", true)
	call DialogSystem_RegisterGreetLine("Zulkis", "Greetings, mon.", "Zulkis_Greet2", true)
	call DialogSystem_RegisterGreetLine("Zulkis", "Zul'kis greets ya.", "Zulkis_Greet3", true)
	call DialogSystem_RegisterGreetLine("Zulkis", "Aah, greetings, mon.", "Zulkis_Greet4", true)

	call DialogSystem_RegisterFarewellLine("Zulkis", "Catch ya later, mon!", "Zulkis_Farewell1", true)
	call DialogSystem_RegisterFarewellLine("Zulkis", "May the spirits watch your back.", "Zulkis_Farewell2", true)
	call DialogSystem_RegisterFarewellLine("Zulkis", "Stay sharp, mon!", "Zulkis_Farewell3", true)
	call DialogSystem_RegisterFarewellLine("Zulkis", "Be seeing ya.", "Zulkis_Farewell4", true)

	call DialogSystem_RegisterInfoLine("Zulkis", "What happened here, mon?", "", true)
	call DialogSystem_RegisterInfoLine("Zulkis", "Tell me about this place.", "", true)
	call DialogSystem_RegisterInfoLine("Zulkis", "What be your knowledge of this?", "", true)
	call DialogSystem_RegisterInfoLine("Zulkis", "Can you help me understand?", "", true)

	// sound files not created for these
	call DialogSystem_RegisterTradeLine("Zulkis", "Let's trade.", "", true)

	call DialogSystem_RegisterExitLine("Zulkis", "Farewell.", "", true)

	call DialogSystem_RegisterFollowLine("Zulkis", "Follow me.", "", true)

	call DialogSystem_RegisterStopLine("Zulkis", "Stay here.", "", true)

	call DialogSystem_RegisterDeclineLine("Zulkis", "No.", "", true)

	call DialogSystem_RegisterAcceptLine("Zulkis", "Yes.", "", true)

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

	call DialogSystem_RegisterInfoLine("Nazgrek", "What do you know of this place?", "", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Tell me what happened here.", "", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "What's your take on this?", "", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Can you share your knowledge?", "", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "What should I know?", "", true)
	call DialogSystem_RegisterInfoLine("Nazgrek", "Explain this to me.", "", true)

	// sound files not created for these
	call DialogSystem_RegisterTradeLine("Nazgrek", "Let's trade.", "", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Show me what you have.", "", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Let's see your wares.", "", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Got anything for sale?", "", true)
	call DialogSystem_RegisterTradeLine("Nazgrek", "Let us trade.", "", true)

	// sound files not created for these
	call DialogSystem_RegisterExitLine("Nazgrek", "Farewell.", "", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Goodbye.", "", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Until next time.", "", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "Safe travels.", "", true)
	call DialogSystem_RegisterExitLine("Nazgrek", "May your path be clear.", "", true)

	// sound files not created for these
	call DialogSystem_RegisterFollowLine("Nazgrek", "Follow me.", "", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Stay close.", "", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Come with me.", "", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Move out.", "", true)
	call DialogSystem_RegisterFollowLine("Nazgrek", "Let's go.", "", true)

	// sound files not created for these
	call DialogSystem_RegisterStopLine("Nazgrek", "Stay here.", "", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Hold position.", "", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Wait here.", "", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Stand your ground.", "", true)
	call DialogSystem_RegisterStopLine("Nazgrek", "Stay.", "", true)

	// sound files not created for these
	call DialogSystem_RegisterDeclineLine("Nazgrek", "No.", "", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "Not now.", "", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "I cannot.", "", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "I must decline.", "", true)
	call DialogSystem_RegisterDeclineLine("Nazgrek", "Perhaps another time.", "", true)

	// sound files not created for these
	// REDO THE LINES / DIFFER ACCEPT (TAKE QUEST) VS SEPERATE ACCEPT (AGREE TO SOMETHING ELSE)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Yes.", "", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "I accept.", "", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Consider it done.", "", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Very well.", "", true)
	call DialogSystem_RegisterAcceptLine("Nazgrek", "Agreed.", "", true)

endfunction

private function Init takes nothing returns nothing
	call LinesZulkis()
	call LinesNazgrek()

endfunction

endlibrary
