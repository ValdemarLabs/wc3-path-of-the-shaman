/*===========================================================================
    Ore Veins
//===========================================================================
        -------- == ZONES == --------
        -------- 1. Twilight Grove - Levels 3-8 --------
        -------- 2. Sereneglade - Levels 1-9 --------
        -------- 3. Emberpeak Highlands - Levels 10-15 --------
        -------- 4. Dragonfire Peaks - Levels 20-30 --------
        -------- 5. Wyrmhold Sanctum - Levels 20-30 --------
        -------- 6. Thornwoods - Levels 1-10 --------
        -------- 7. Havenwoods - Levels 5-10 --------
        -------- 8. Bonecrush Stronghold - Levels 10-12 --------
        -------- 9. Vanguard Vale - Levels 8-12 --------
        -------- 10. Riverbane - Levels 8-12 --------
        -------- 11. Deadwoods - Levels 8-12 --------
        -------- 12. Felfire Bastion - Levels 12-15 (Stronghold 25-30) --------
        -------- 13. Stormhaven - Levels 12-18 --------
        -------- 14. Sirensong - Levels 10-15 --------
        -------- 15. Zul’Gurak - Levels 15-20 --------
        -------- 16. Firelands - Levels 20-30 --------
        -------- 17. Verdant Plains - Levels 15-20 --------
        -------- 18. Coliseum of Ages - Levels XXX --------
        -------- 19. Ghostwalk Ridge - Levels 5-10 --------

//===========================================================================
*/
//===========================================================================
function Trig_Ore_Veins_Init_Actions takes nothing returns nothing
    // Define regions for spawning ores
// -------- 1. Twilight Grove - Levels 3-8 --------
    set udg_OreRegions[1] = gg_rct_OreVeins0001
    set udg_OreRegions[2] = gg_rct_OreVeins0002
    set udg_OreRegions[3] = gg_rct_OreVeins0003
    set udg_OreRegions[4] = gg_rct_OreVeins0004
    set udg_OreRegions[5] = gg_rct_OreVeins0005
    set udg_OreRegions[6] = gg_rct_OreVeins0006
    set udg_OreRegions[7] = gg_rct_OreVeins0007
    set udg_OreRegions[8] = gg_rct_OreVeins0008
    set udg_OreRegions[9] = gg_rct_OreVeins0009
    set udg_OreRegions[10] = gg_rct_OreVeins0010
    set udg_OreRegions[11] = gg_rct_OreVeins0011
    set udg_OreRegions[12] = gg_rct_OreVeins0012

    // -------- 2. Sereneglade - Levels 1-9 --------
    set udg_OreRegions[13] = gg_rct_OreVeins0013
    set udg_OreRegions[14] = gg_rct_OreVeins0014
    set udg_OreRegions[15] = gg_rct_OreVeins0015
    set udg_OreRegions[16] = gg_rct_OreVeins0016
    set udg_OreRegions[17] = gg_rct_OreVeins0017
    set udg_OreRegions[18] = gg_rct_OreVeins0018
    set udg_OreRegions[19] = gg_rct_OreVeins0019
    set udg_OreRegions[20] = gg_rct_OreVeins0020
    set udg_OreRegions[21] = gg_rct_OreVeins0021
    set udg_OreRegions[22] = gg_rct_OreVeins0022
    set udg_OreRegions[23] = gg_rct_OreVeins0023
    set udg_OreRegions[24] = gg_rct_OreVeins0024
    set udg_OreRegions[25] = gg_rct_OreVeins0025
    set udg_OreRegions[26] = gg_rct_OreVeins0026
    set udg_OreRegions[27] = gg_rct_OreVeins0027
    set udg_OreRegions[28] = gg_rct_OreVeins0028
    set udg_OreRegions[29] = gg_rct_OreVeins0029
    set udg_OreRegions[30] = gg_rct_OreVeins0030
    set udg_OreRegions[31] = gg_rct_OreVeins0031
    set udg_OreRegions[32] = gg_rct_OreVeins0032
    set udg_OreRegions[33] = gg_rct_OreVeins0033
    set udg_OreRegions[34] = gg_rct_OreVeins0034
    set udg_OreRegions[35] = gg_rct_OreVeins0035
    set udg_OreRegions[36] = gg_rct_OreVeins0036
    set udg_OreRegions[37] = gg_rct_OreVeins0037
    set udg_OreRegions[38] = gg_rct_OreVeins0038
    set udg_OreRegions[39] = gg_rct_OreVeins0039
    set udg_OreRegions[40] = gg_rct_OreVeins0040
    set udg_OreRegions[41] = gg_rct_OreVeins0041
    set udg_OreRegions[42] = gg_rct_OreVeins0042
    set udg_OreRegions[43] = gg_rct_OreVeins0043
    set udg_OreRegions[44] = gg_rct_OreVeins0045
    set udg_OreRegions[45] = gg_rct_OreVeins0046
    set udg_OreRegions[46] = gg_rct_OreVeins0047
    set udg_OreRegions[47] = gg_rct_OreVeins0048
    set udg_OreRegions[48] = gg_rct_OreVeins0049
    set udg_OreRegions[49] = gg_rct_OreVeins0050
    set udg_OreRegions[50] = gg_rct_OreVeins0051

    // -------- 3. Emberpeak Highlands - Levels 10-15 --------
    set udg_OreRegions[201] = gg_rct_OreVeins0201
    set udg_OreRegions[202] = gg_rct_OreVeins0202
    set udg_OreRegions[203] = gg_rct_OreVeins0203
    set udg_OreRegions[204] = gg_rct_OreVeins0204
    set udg_OreRegions[205] = gg_rct_OreVeins0205
    set udg_OreRegions[206] = gg_rct_OreVeins0206
    set udg_OreRegions[207] = gg_rct_OreVeins0207
    set udg_OreRegions[208] = gg_rct_OreVeins0208
    set udg_OreRegions[209] = gg_rct_OreVeins0209
    set udg_OreRegions[210] = gg_rct_OreVeins0210
    set udg_OreRegions[211] = gg_rct_OreVeins0211
    set udg_OreRegions[212] = gg_rct_OreVeins0212
    set udg_OreRegions[213] = gg_rct_OreVeins0213
    set udg_OreRegions[214] = gg_rct_OreVeins0214
    set udg_OreRegions[215] = gg_rct_OreVeins0215
    set udg_OreRegions[216] = gg_rct_OreVeins0216
    set udg_OreRegions[217] = gg_rct_OreVeins0217
    set udg_OreRegions[218] = gg_rct_OreVeins0218
    set udg_OreRegions[219] = gg_rct_OreVeins0219
    set udg_OreRegions[220] = gg_rct_OreVeins0220
    set udg_OreRegions[221] = gg_rct_OreVeins0221
    set udg_OreRegions[222] = gg_rct_OreVeins0222
    set udg_OreRegions[223] = gg_rct_OreVeins0223
    set udg_OreRegions[224] = gg_rct_OreVeins0224
    set udg_OreRegions[225] = gg_rct_OreVeins0225
    set udg_OreRegions[226] = gg_rct_OreVeins0226
    set udg_OreRegions[227] = gg_rct_OreVeins0227
    set udg_OreRegions[228] = gg_rct_OreVeins0228
    set udg_OreRegions[229] = gg_rct_OreVeins0229
    set udg_OreRegions[230] = gg_rct_OreVeins0230
    set udg_OreRegions[231] = gg_rct_OreVeins0231

    // -------- 4. Thornwoods - Levels 1-10 --------
    set udg_OreRegions[101] = gg_rct_OreVeins0101
    set udg_OreRegions[102] = gg_rct_OreVeins0102
    set udg_OreRegions[103] = gg_rct_OreVeins0103
    set udg_OreRegions[104] = gg_rct_OreVeins0104
    set udg_OreRegions[105] = gg_rct_OreVeins0105
    set udg_OreRegions[106] = gg_rct_OreVeins0106
    set udg_OreRegions[107] = gg_rct_OreVeins0107
    set udg_OreRegions[108] = gg_rct_OreVeins0108
    set udg_OreRegions[109] = gg_rct_OreVeins0109
    set udg_OreRegions[110] = gg_rct_OreVeins0110
    set udg_OreRegions[111] = gg_rct_OreVeins0111
    set udg_OreRegions[112] = gg_rct_OreVeins0112
    set udg_OreRegions[113] = gg_rct_OreVeins0113
    set udg_OreRegions[114] = gg_rct_OreVeins0114
    set udg_OreRegions[115] = gg_rct_OreVeins0115
    set udg_OreRegions[116] = gg_rct_OreVeins0116
    set udg_OreRegions[117] = gg_rct_OreVeins0117
    set udg_OreRegions[118] = gg_rct_OreVeins0118
    set udg_OreRegions[119] = gg_rct_OreVeins0119
    set udg_OreRegions[120] = gg_rct_OreVeins0120
    set udg_OreRegions[121] = gg_rct_OreVeins0121
    set udg_OreRegions[122] = gg_rct_OreVeins0122
    set udg_OreRegions[123] = gg_rct_OreVeins0123
    set udg_OreRegions[124] = gg_rct_OreVeins0124
    set udg_OreRegions[125] = gg_rct_OreVeins0125
    set udg_OreRegions[126] = gg_rct_OreVeins0126
    set udg_OreRegions[127] = gg_rct_OreVeins0127
    set udg_OreRegions[128] = gg_rct_OreVeins0128
    set udg_OreRegions[129] = gg_rct_OreVeins0129
    set udg_OreRegions[130] = gg_rct_OreVeins0130
    set udg_OreRegions[131] = gg_rct_OreVeins0131
    set udg_OreRegions[132] = gg_rct_OreVeins0132
    set udg_OreRegions[133] = gg_rct_OreVeins0133

    //-------- 10. Riverbane - Levels 8-12 --------
    set udg_OreRegions[232] = gg_rct_OreVeins0232
    set udg_OreRegions[233] = gg_rct_OreVeins0233
    set udg_OreRegions[234] = gg_rct_OreVeins0234
    set udg_OreRegions[235] = gg_rct_OreVeins0235
    set udg_OreRegions[236] = gg_rct_OreVeins0236
    set udg_OreRegions[237] = gg_rct_OreVeins0237
    set udg_OreRegions[238] = gg_rct_OreVeins0238
    set udg_OreRegions[239] = gg_rct_OreVeins0239
    set udg_OreRegions[240] = gg_rct_OreVeins0240
    set udg_OreRegions[241] = gg_rct_OreVeins0241
    set udg_OreRegions[242] = gg_rct_OreVeins0242
    set udg_OreRegions[243] = gg_rct_OreVeins0243
    set udg_OreRegions[244] = gg_rct_OreVeins0244
    set udg_OreRegions[245] = gg_rct_OreVeins0245
    set udg_OreRegions[246] = gg_rct_OreVeins0246
    set udg_OreRegions[247] = gg_rct_OreVeins0247
    set udg_OreRegions[248] = gg_rct_OreVeins0248
    set udg_OreRegions[249] = gg_rct_OreVeins0249
    set udg_OreRegions[250] = gg_rct_OreVeins0250
    set udg_OreRegions[251] = gg_rct_OreVeins0251
    set udg_OreRegions[252] = gg_rct_OreVeins0252
    set udg_OreRegions[253] = gg_rct_OreVeins0253
    set udg_OreRegions[254] = gg_rct_OreVeins0254
    set udg_OreRegions[255] = gg_rct_OreVeins0255
    set udg_OreRegions[256] = gg_rct_OreVeins0256
    set udg_OreRegions[257] = gg_rct_OreVeins0257
    set udg_OreRegions[258] = gg_rct_OreVeins0258
    set udg_OreRegions[259] = gg_rct_OreVeins0259
    set udg_OreRegions[260] = gg_rct_OreVeins0260
    set udg_OreRegions[261] = gg_rct_OreVeins0261
    set udg_OreRegions[262] = gg_rct_OreVeins0262
    set udg_OreRegions[263] = gg_rct_OreVeins0263
    set udg_OreRegions[264] = gg_rct_OreVeins0264
    set udg_OreRegions[265] = gg_rct_OreVeins0265
    set udg_OreRegions[266] = gg_rct_OreVeins0266
    set udg_OreRegions[267] = gg_rct_OreVeins0267
    set udg_OreRegions[268] = gg_rct_OreVeins0268
    set udg_OreRegions[269] = gg_rct_OreVeins0269
    set udg_OreRegions[270] = gg_rct_OreVeins0270
    set udg_OreRegions[271] = gg_rct_OreVeins0271
    set udg_OreRegions[272] = gg_rct_OreVeins0272
    set udg_OreRegions[273] = gg_rct_OreVeins0273
    set udg_OreRegions[274] = gg_rct_OreVeins0274
    set udg_OreRegions[275] = gg_rct_OreVeins0275
    set udg_OreRegions[276] = gg_rct_OreVeins0276
    set udg_OreRegions[277] = gg_rct_OreVeins0277
    set udg_OreRegions[278] = gg_rct_OreVeins0278
    set udg_OreRegions[279] = gg_rct_OreVeins0279
    set udg_OreRegions[280] = gg_rct_OreVeins0280
    set udg_OreRegions[281] = gg_rct_OreVeins0281
    set udg_OreRegions[282] = gg_rct_OreVeins0282
    set udg_OreRegions[283] = gg_rct_OreVeins0283
    set udg_OreRegions[284] = gg_rct_OreVeins0284
    set udg_OreRegions[285] = gg_rct_OreVeins0285

    // -------- 19. Ghostwalk Ridge - Levels 5-10 --------
    // -------- 11. Deadwoods - Levels 8-12 --------
    set udg_OreRegions[286] = gg_rct_OreVeins0286
    set udg_OreRegions[287] = gg_rct_OreVeins0287
    set udg_OreRegions[288] = gg_rct_OreVeins0288
    set udg_OreRegions[289] = gg_rct_OreVeins0289
    set udg_OreRegions[290] = gg_rct_OreVeins0290
    set udg_OreRegions[291] = gg_rct_OreVeins0291
    set udg_OreRegions[292] = gg_rct_OreVeins0292
    set udg_OreRegions[293] = gg_rct_OreVeins0293
    set udg_OreRegions[294] = gg_rct_OreVeins0294
    set udg_OreRegions[295] = gg_rct_OreVeins0295
    set udg_OreRegions[296] = gg_rct_OreVeins0296
    set udg_OreRegions[297] = gg_rct_OreVeins0297
    set udg_OreRegions[298] = gg_rct_OreVeins0298
    set udg_OreRegions[299] = gg_rct_OreVeins0299
    set udg_OreRegions[300] = gg_rct_OreVeins0300
    set udg_OreRegions[301] = gg_rct_OreVeins0301
    set udg_OreRegions[302] = gg_rct_OreVeins0302
    set udg_OreRegions[303] = gg_rct_OreVeins0303
    set udg_OreRegions[304] = gg_rct_OreVeins0304
    set udg_OreRegions[305] = gg_rct_OreVeins0305
    set udg_OreRegions[306] = gg_rct_OreVeins0306
    set udg_OreRegions[307] = gg_rct_OreVeins0307
    set udg_OreRegions[308] = gg_rct_OreVeins0308
    set udg_OreRegions[309] = gg_rct_OreVeins0309
    set udg_OreRegions[310] = gg_rct_OreVeins0310
    set udg_OreRegions[311] = gg_rct_OreVeins0311
    set udg_OreRegions[312] = gg_rct_OreVeins0312
    set udg_OreRegions[313] = gg_rct_OreVeins0313
    set udg_OreRegions[314] = gg_rct_OreVeins0314
    set udg_OreRegions[315] = gg_rct_OreVeins0315
    set udg_OreRegions[316] = gg_rct_OreVeins0316
    set udg_OreRegions[317] = gg_rct_OreVeins0317
    set udg_OreRegions[318] = gg_rct_OreVeins0318


    // The manual pattern would continue for other zones as necessary.

endfunction

//===========================================================================
//===========================================================================
function InitTrig_Ore_Veins_Init takes nothing returns nothing
    set gg_trg_Ore_Veins_Init = CreateTrigger(  )
    call TriggerRegisterTimerEventSingle( gg_trg_Ore_Veins_Init, 0.00 )
    call TriggerAddAction( gg_trg_Ore_Veins_Init, function Trig_Ore_Veins_Init_Actions )
endfunction
