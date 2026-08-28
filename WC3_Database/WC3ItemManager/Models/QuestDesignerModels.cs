using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;

namespace WC3ItemManager.Models
{
    public sealed class QuestGiverDefinition
    {
        public int Id { get; set; }
        public string GiverKey { get; set; } = "";
        public string DisplayName { get; set; } = "";
        public string LibraryName { get; set; } = "";
        [TypeConverter(typeof(QuestOwnershipModeConverter))]
        public string OwnershipMode { get; set; } = "managed";
        public string SourceFile { get; set; } = "";
        [ReadOnly(true)]
        public string SourceKind { get; set; } = "";
        [ReadOnly(true)]
        public string SourceImportFingerprint { get; set; } = "";
        [ReadOnly(true)]
        public DateTime? SourceImportedAt { get; set; }
        public string UnitCode { get; set; } = "";
        public string PlacedUnitVariable { get; set; } = "";
        public int? ZoneId { get; set; }
        public string Faction { get; set; } = "";
        public bool AllowNazgrek { get; set; } = true;
        public bool AllowZulkis { get; set; }
        public decimal DialogRange { get; set; } = 500m;
        public decimal DialogCooldown { get; set; } = 6m;
        public bool UseDialogCamera { get; set; } = true;
        public bool UseCinematicMode { get; set; } = true;
        public decimal CameraDistance { get; set; } = 850m;
        public decimal CameraZOffset { get; set; } = 20m;
        public decimal CameraAngle { get; set; } = 350m;
        public decimal CameraRotationOffset { get; set; } = 180m;
        public decimal CameraFarZ { get; set; } = 10000m;
        public decimal CameraFov { get; set; } = 60m;
        public decimal CameraBlockRadius { get; set; }
        public bool CameraBlockCheck { get; set; } = true;
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; } = "";
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public override string ToString() => DisplayName;
    }

    public sealed class QuestDefinition
    {
        public int Id { get; set; }
        public int QuestGiverId { get; set; }
        public string QuestKey { get; set; } = "";
        public string QuestName { get; set; } = "";
        public string Title { get; set; } = "";
        [TypeConverter(typeof(QuestTypeConverter))]
        public string QuestType { get; set; } = "normal";
        [TypeConverter(typeof(QuestCategoryConverter))]
        public string Category { get; set; } = "general";
        public int QuestLevel { get; set; } = 1;
        public int RequiredLevel { get; set; } = 1;
        public int RequiredReputation { get; set; }
        public string IconPath { get; set; } = "";
        public string Description { get; set; } = "";
        public string InfoText { get; set; } = "";
        public string Info2Text { get; set; } = "";
        public int? ReceiverGiverId { get; set; }
        public string ReceiverDisplayName { get; set; } = "";
        public int? ZoneId { get; set; }
        public string Faction { get; set; } = "";
        public bool AllowNazgrek { get; set; } = true;
        public bool AllowZulkis { get; set; }
        public bool RequiresTurnIn { get; set; } = true;
        public bool AutoComplete { get; set; }
        public string FailReason { get; set; } = "";
        public bool Draft { get; set; } = true;
        public bool Enabled { get; set; } = true;
        public int SortOrder { get; set; }
        public string Notes { get; set; } = "";
        [ReadOnly(true)]
        public string SourceFile { get; set; } = "";
        [ReadOnly(true)]
        public string SourceSymbol { get; set; } = "";
        [ReadOnly(true)]
        public string SourceImportFingerprint { get; set; } = "";
        [ReadOnly(true)]
        public DateTime? SourceImportedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public override string ToString() => Title;
    }

    public sealed class QuestObjectiveDefinition
    {
        public int Id { get; set; }
        public int QuestId { get; set; }
        public string ObjectiveKey { get; set; } = "Objective";
        public int DisplayOrder { get; set; } = 1;
        [TypeConverter(typeof(QuestObjectiveTypeConverter))]
        public string ObjectiveType { get; set; } = "manual";
        public string Text { get; set; } = "";
        public int Amount { get; set; } = 1;
        public string ItemCode { get; set; } = "";
        public string UnitCode { get; set; } = "";
        public string TargetVariable { get; set; } = "";
        public string TargetName { get; set; } = "";
        public string RegionVariable { get; set; } = "";
        public int? ZoneId { get; set; }
        public string Faction { get; set; } = "";
        public int RequiredReputation { get; set; }
        [TypeConverter(typeof(QuestCompletionModeConverter))]
        public string CompletionMode { get; set; } = "automatic";
        public string ExternalHook { get; set; } = "";
        public string Notes { get; set; } = "";
    }

    public sealed class QuestRewardDefinition
    {
        public int QuestId { get; set; }
        public bool XpActive { get; set; } = true;
        public int XpAdjust { get; set; }
        public bool GoldActive { get; set; } = true;
        public int GoldAdjust { get; set; }
        public bool ArenaActive { get; set; }
        public int ArenaAdjust { get; set; }
        public bool ReputationActive { get; set; }
        public int ReputationAdjust { get; set; }
        public bool ReputationLinked { get; set; }
        public string ItemCode { get; set; } = "";
        public string CustomText { get; set; } = "";
    }

    public sealed class QuestSequenceDefinition
    {
        public int Id { get; set; }
        public int QuestGiverId { get; set; }
        public int? QuestId { get; set; }
        public string SequenceKey { get; set; } = "Sequence";
        public string DisplayName { get; set; } = "New sequence";
        [TypeConverter(typeof(QuestSequencePurposeConverter))]
        public string Purpose { get; set; } = "custom";
        public bool ShowAsDialogOption { get; set; }
        public string ButtonLabel { get; set; } = "";
        public int ButtonOrder { get; set; }
        public string OnStartHook { get; set; } = "";
        public string OnFinishHook { get; set; } = "";
        public bool Skippable { get; set; } = true;
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; } = "";

        public override string ToString() => DisplayName;
    }

    public sealed class QuestSequenceStepDefinition
    {
        public int Id { get; set; }
        public int SequenceId { get; set; }
        public int DisplayOrder { get; set; } = 1;
        [TypeConverter(typeof(QuestSequenceStepTypeConverter))]
        public string StepType { get; set; } = "line";
        public string SpeakerBinding { get; set; } = "Giver";
        public string SpeakerName { get; set; } = "";
        public string Text { get; set; } = "";
        public string SoundKey { get; set; } = "";
        public int? VoicelineId { get; set; }
        public decimal Duration { get; set; }
        public string TargetBinding { get; set; } = "";
        public decimal? PointX { get; set; }
        public decimal? PointY { get; set; }
        public string ActionHook { get; set; } = "";
        public bool SoundAtUnit { get; set; } = true;
        public string Notes { get; set; } = "";
    }

    public sealed class QuestVoicelineDefinition
    {
        public int Id { get; set; }
        public string SpeakerKey { get; set; } = "";
        public string SpeakerName { get; set; } = "";
        public string LineKey { get; set; } = "";
        public string Text { get; set; } = "";
        public string ConstantName { get; set; } = "";
        public string SourceLibrary { get; set; } = "";
        public string SourceFile { get; set; } = "";
        public bool Verified { get; set; }
        public string Notes { get; set; } = "";

        [Browsable(false)]
        public string DisplayLabel => $"{SpeakerName}: {LineKey}";

        public override string ToString() => DisplayLabel;
    }

    public sealed class QuestWorldEditorDependency
    {
        public int Id { get; set; }
        public int QuestGiverId { get; set; }
        public int? QuestId { get; set; }
        [TypeConverter(typeof(QuestDependencyKindConverter))]
        public string DependencyKind { get; set; } = "other";
        public string Symbol { get; set; } = "";
        public string ExpectedValue { get; set; } = "";
        public bool Verified { get; set; }
        public string ManualFollowUp { get; set; } = "";
        public string SourceEvidence { get; set; } = "";
    }

    public abstract class QuestFixedStringConverter : StringConverter
    {
        protected abstract IReadOnlyList<string> Values { get; }

        public override bool GetStandardValuesSupported(ITypeDescriptorContext context) => true;
        public override bool GetStandardValuesExclusive(ITypeDescriptorContext context) => true;
        public override StandardValuesCollection GetStandardValues(ITypeDescriptorContext context)
        {
            return new StandardValuesCollection(Values.ToArray());
        }
    }

    public sealed class QuestOwnershipModeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[] { "managed", "hybrid", "external" };
    }

    public sealed class QuestTypeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[] { "normal", "daily", "repeatable" };
    }

    public sealed class QuestCategoryConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[] { "general", "story", "dungeon", "class", "profession" };
    }

    public sealed class QuestObjectiveTypeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[]
        {
            "item", "kill", "escort", "talk", "find", "goto", "reputation", "investigate", "manual"
        };
    }

    public sealed class QuestCompletionModeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[] { "automatic", "manual", "external" };
    }

    public sealed class QuestSequencePurposeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[]
        {
            "greet", "info", "farewell", "accept", "complete", "fail", "custom"
        };
    }

    public sealed class QuestSequenceStepTypeConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[]
        {
            "line", "delay", "face_unit", "face_point", "look_unit", "look_point",
            "reset_look", "fade_out", "fade_in", "action"
        };
    }

    public sealed class QuestDependencyKindConverter : QuestFixedStringConverter
    {
        protected override IReadOnlyList<string> Values => new[]
        {
            "unit_global", "rect", "camera", "unit_rawcode", "item_rawcode", "gui_trigger",
            "object_editor", "placed_unit", "audio_asset", "other"
        };
    }
}
