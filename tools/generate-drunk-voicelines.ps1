param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $PSScriptRoot "voicelines.ps1"

function Invoke-VoiceBatch {
    param(
        [string]$ReferenceId,
        [string[]]$Keys
    )

    $arguments = @{
        Mode = "Generate"
        Keys = $Keys
        ReferenceId = $ReferenceId
    }
    if ($DryRun) { $arguments.DryRun = $true }
    & $generator @arguments
}

Push-Location $repoRoot
try {
    Invoke-VoiceBatch "82895e2c2e62463bb023c0c858a55b9d" @(
        "Nazgrek_DrunkPuke1", "Nazgrek_DrunkPuke2",
        "Nazgrek_DrunkPassOut1", "Nazgrek_DrunkPassOut2",
        "Nazgrek_HangoverWake1", "Nazgrek_HangoverWake2", "Nazgrek_HangoverWake3",
        "Nazgrek_LastNight1", "Nazgrek_LastNight2", "Nazgrek_LastNight3"
    )
    Invoke-VoiceBatch "139c8b251a2f4a97a2dbce510e1f94cf" @(
        "Zulkis_DrunkPuke1", "Zulkis_DrunkPuke2",
        "Zulkis_DrunkPassOut1", "Zulkis_DrunkPassOut2",
        "Zulkis_HangoverWake1", "Zulkis_HangoverWake2", "Zulkis_HangoverWake3",
        "Zulkis_LastNight1", "Zulkis_LastNight2", "Zulkis_LastNight3"
    )

    Invoke-VoiceBatch "b901bbbb4b3748e5ae04a4defaf7a3c9" @("HeroEngineer_DrunkPuke1", "HeroEngineer_DrunkPuke2")
    Invoke-VoiceBatch "ffa580e4304440e2b78bf2a02d493942" @("HeroPaladin_DrunkPuke1", "HeroPaladin_DrunkPuke2")
    Invoke-VoiceBatch "2f5da025973948bea9c3d21b09a73d8f" @("HeroShaman_DrunkPuke1", "HeroShaman_DrunkPuke2")
    Invoke-VoiceBatch "6f5776ec9e67431b9aee2ed1f17f902d" @("HeroRogue_DrunkPuke1", "HeroRogue_DrunkPuke2")
    Invoke-VoiceBatch "06209f0d44a146b08ba67d5a8d121f74" @("HeroWarlock_DrunkPuke1", "HeroWarlock_DrunkPuke2")
    Invoke-VoiceBatch "8be8a11dd4524e6a813ac34ce1580008" @("HeroWarrior_DrunkPuke1", "HeroWarrior_DrunkPuke2")

    Invoke-VoiceBatch "6f5776ec9e67431b9aee2ed1f17f902d" @("GenericOrcMale1_1101", "GenericOrcMale1_1102", "GenericOrcMale1_1103")
    Invoke-VoiceBatch "b29f7aa78b9c42098b08a3fab7adbe9f" @("GenericOrcMale3_1101", "GenericOrcMale3_1102", "GenericOrcMale3_1103")
    Invoke-VoiceBatch "7f2e1215df0444af865febb74d324593" @("GenericOrcMale4_1101", "GenericOrcMale4_1102", "GenericOrcMale4_1103")
    Invoke-VoiceBatch "f21002b6d17b4819b0c9ad5107bff001" @("GenericOrcMale5_1101", "GenericOrcMale5_1102", "GenericOrcMale5_1103")
    Invoke-VoiceBatch "dab87e7b8c7549d691a90076609bc317" @("GenericOrcMale8_1101", "GenericOrcMale8_1102", "GenericOrcMale8_1103")
    Invoke-VoiceBatch "90a80ffccde247c69af75edf5d66cad2" @("GenericOrcMale9_1101", "GenericOrcMale9_1102", "GenericOrcMale9_1103")
    Invoke-VoiceBatch "8be8a11dd4524e6a813ac34ce1580008" @("GenericTaurenMale1_1101", "GenericTaurenMale1_1102", "GenericTaurenMale1_1103")
    Invoke-VoiceBatch "a12406c85a944d7bae13e9164517f920" @("GenericTaurenMale2_1101", "GenericTaurenMale2_1102", "GenericTaurenMale2_1103")
    Invoke-VoiceBatch "7fa831b0ab1646b58dc7571a65550662" @("GenericTaurenMale3_1101", "GenericTaurenMale3_1102", "GenericTaurenMale3_1103")
    Invoke-VoiceBatch "749a792a18654ac19c8668fe9ceb6a31" @("GenericTrollMale1_1001", "GenericTrollMale1_1002", "GenericTrollMale1_1003")
    Invoke-VoiceBatch "11573f63b7cb42cd919a0ebd0f74aa84" @("GenericTrollMale2_1001", "GenericTrollMale2_1002", "GenericTrollMale2_1003")

    Write-Warning "Aveline_DrunkPuke1-2 remain text-only until an Aveline Fish Audio reference ID is supplied."
}
finally {
    Pop-Location
}
