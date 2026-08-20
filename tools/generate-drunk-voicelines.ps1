param(
    [switch]$DryRun,
    [switch]$Force,
    [string[]]$OnlyKeys
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $PSScriptRoot "voicelines.ps1"

function Invoke-VoiceBatch {
    param(
        [string]$ReferenceId,
        [string[]]$BatchKeys
    )

    $selectedKeys = $BatchKeys
    if ($OnlyKeys.Count -gt 0) {
        $selectedKeys = @($BatchKeys | Where-Object { $OnlyKeys -contains $_ })
        if ($selectedKeys.Count -eq 0) { return }
    }

    $arguments = @{
        Mode = "Generate"
        Keys = $selectedKeys
        ReferenceId = $ReferenceId
    }
    if ($DryRun) { $arguments.DryRun = $true }
    if ($Force) { $arguments.Force = $true }
    & $generator @arguments
}

Push-Location $repoRoot
try {
    Invoke-VoiceBatch "82895e2c2e62463bb023c0c858a55b9d" @(
        "Nazgrek_DrunkPuke1", "Nazgrek_DrunkPuke2",
        "Nazgrek_DrunkPassOut1", "Nazgrek_DrunkPassOut2",
        "Nazgrek_HangoverWake1", "Nazgrek_HangoverWake2", "Nazgrek_HangoverWake3",
        "Nazgrek_LastNight1", "Nazgrek_LastNight2", "Nazgrek_LastNight3", "Nazgrek_LastNight4", "Nazgrek_LastNight5",
        "Nazgrek_LastNightResponse1", "Nazgrek_LastNightResponse2", "Nazgrek_LastNightResponse3", "Nazgrek_LastNightResponse4", "Nazgrek_LastNightResponse5"
    )
    Invoke-VoiceBatch "139c8b251a2f4a97a2dbce510e1f94cf" @(
        "Zulkis_DrunkPuke1", "Zulkis_DrunkPuke2",
        "Zulkis_DrunkPassOut1", "Zulkis_DrunkPassOut2",
        "Zulkis_HangoverWake1", "Zulkis_HangoverWake2", "Zulkis_HangoverWake3",
        "Zulkis_LastNight1", "Zulkis_LastNight2", "Zulkis_LastNight3", "Zulkis_LastNight4", "Zulkis_LastNight5",
        "Zulkis_LastNightResponse1", "Zulkis_LastNightResponse2", "Zulkis_LastNightResponse3", "Zulkis_LastNightResponse4", "Zulkis_LastNightResponse5"
    )

    Invoke-VoiceBatch "b901bbbb4b3748e5ae04a4defaf7a3c9" @("HeroEngineer_DrunkPuke1", "HeroEngineer_DrunkPuke2", "HeroEngineer_LastNight1", "HeroEngineer_LastNight2", "HeroEngineer_LastNight3", "HeroEngineer_LastNight4", "HeroEngineer_LastNight5", "HeroEngineer_HangoverTask", "HeroEngineer_HangoverForgive")
    Invoke-VoiceBatch "ffa580e4304440e2b78bf2a02d493942" @("HeroPaladin_DrunkPuke1", "HeroPaladin_DrunkPuke2", "HeroPaladin_LastNight1", "HeroPaladin_LastNight2", "HeroPaladin_LastNight3", "HeroPaladin_LastNight4", "HeroPaladin_LastNight5", "HeroPaladin_HangoverTask", "HeroPaladin_HangoverForgive")
    Invoke-VoiceBatch "2f5da025973948bea9c3d21b09a73d8f" @("HeroShaman_DrunkPuke1", "HeroShaman_DrunkPuke2", "HeroShaman_LastNight1", "HeroShaman_LastNight2", "HeroShaman_LastNight3", "HeroShaman_LastNight4", "HeroShaman_LastNight5", "HeroShaman_HangoverTask", "HeroShaman_HangoverForgive")
    Invoke-VoiceBatch "6f5776ec9e67431b9aee2ed1f17f902d" @("HeroRogue_DrunkPuke1", "HeroRogue_DrunkPuke2", "HeroRogue_LastNight1", "HeroRogue_LastNight2", "HeroRogue_LastNight3", "HeroRogue_LastNight4", "HeroRogue_LastNight5", "HeroRogue_HangoverTask", "HeroRogue_HangoverForgive")
    Invoke-VoiceBatch "06209f0d44a146b08ba67d5a8d121f74" @("HeroWarlock_DrunkPuke1", "HeroWarlock_DrunkPuke2", "HeroWarlock_LastNight1", "HeroWarlock_LastNight2", "HeroWarlock_LastNight3", "HeroWarlock_LastNight4", "HeroWarlock_LastNight5", "HeroWarlock_HangoverTask", "HeroWarlock_HangoverForgive")
    Invoke-VoiceBatch "8be8a11dd4524e6a813ac34ce1580008" @("HeroWarrior_DrunkPuke1", "HeroWarrior_DrunkPuke2", "HeroWarrior_LastNight1", "HeroWarrior_LastNight2", "HeroWarrior_LastNight3", "HeroWarrior_LastNight4", "HeroWarrior_LastNight5", "HeroWarrior_HangoverTask", "HeroWarrior_HangoverForgive")
    Invoke-VoiceBatch "829032b867d447ebbabc6c30ebba911c" @("Aveline_DrunkPuke1", "Aveline_DrunkPuke2", "Aveline_LastNight1", "Aveline_LastNight2", "Aveline_LastNight3", "Aveline_LastNight4", "Aveline_LastNight5", "Aveline_HangoverTask", "Aveline_HangoverForgive")

    Invoke-VoiceBatch "6f5776ec9e67431b9aee2ed1f17f902d" @("GenericOrcMale1_1101", "GenericOrcMale1_1102", "GenericOrcMale1_1103", "GenericOrcMale1_1104", "GenericOrcMale1_1105", "GenericOrcMale1_1106", "GenericOrcMale1_1107")
    Invoke-VoiceBatch "b29f7aa78b9c42098b08a3fab7adbe9f" @("GenericOrcMale3_1101", "GenericOrcMale3_1102", "GenericOrcMale3_1103", "GenericOrcMale3_1104", "GenericOrcMale3_1105", "GenericOrcMale3_1106", "GenericOrcMale3_1107")
    Invoke-VoiceBatch "7f2e1215df0444af865febb74d324593" @("GenericOrcMale4_1101", "GenericOrcMale4_1102", "GenericOrcMale4_1103", "GenericOrcMale4_1104", "GenericOrcMale4_1105", "GenericOrcMale4_1106", "GenericOrcMale4_1107")
    Invoke-VoiceBatch "f21002b6d17b4819b0c9ad5107bff001" @("GenericOrcMale5_1101", "GenericOrcMale5_1102", "GenericOrcMale5_1103", "GenericOrcMale5_1104", "GenericOrcMale5_1105", "GenericOrcMale5_1106", "GenericOrcMale5_1107")
    Invoke-VoiceBatch "dab87e7b8c7549d691a90076609bc317" @("GenericOrcMale8_1101", "GenericOrcMale8_1102", "GenericOrcMale8_1103", "GenericOrcMale8_1104", "GenericOrcMale8_1105", "GenericOrcMale8_1106", "GenericOrcMale8_1107")
    Invoke-VoiceBatch "90a80ffccde247c69af75edf5d66cad2" @("GenericOrcMale9_1101", "GenericOrcMale9_1102", "GenericOrcMale9_1103", "GenericOrcMale9_1104", "GenericOrcMale9_1105", "GenericOrcMale9_1106", "GenericOrcMale9_1107")
    Invoke-VoiceBatch "8be8a11dd4524e6a813ac34ce1580008" @("GenericTaurenMale1_1101", "GenericTaurenMale1_1102", "GenericTaurenMale1_1103", "GenericTaurenMale1_1104", "GenericTaurenMale1_1105", "GenericTaurenMale1_1106", "GenericTaurenMale1_1107")
    Invoke-VoiceBatch "a12406c85a944d7bae13e9164517f920" @("GenericTaurenMale2_1101", "GenericTaurenMale2_1102", "GenericTaurenMale2_1103", "GenericTaurenMale2_1104", "GenericTaurenMale2_1105", "GenericTaurenMale2_1106", "GenericTaurenMale2_1107")
    Invoke-VoiceBatch "7fa831b0ab1646b58dc7571a65550662" @("GenericTaurenMale3_1101", "GenericTaurenMale3_1102", "GenericTaurenMale3_1103", "GenericTaurenMale3_1104", "GenericTaurenMale3_1105", "GenericTaurenMale3_1106", "GenericTaurenMale3_1107")
    Invoke-VoiceBatch "749a792a18654ac19c8668fe9ceb6a31" @("GenericTrollMale1_1001", "GenericTrollMale1_1002", "GenericTrollMale1_1003", "GenericTrollMale1_1004", "GenericTrollMale1_1005", "GenericTrollMale1_1006", "GenericTrollMale1_1007")
    Invoke-VoiceBatch "11573f63b7cb42cd919a0ebd0f74aa84" @("GenericTrollMale2_1001", "GenericTrollMale2_1002", "GenericTrollMale2_1003", "GenericTrollMale2_1004", "GenericTrollMale2_1005", "GenericTrollMale2_1006", "GenericTrollMale2_1007")
}
finally {
    Pop-Location
}
