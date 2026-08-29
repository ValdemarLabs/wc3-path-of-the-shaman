using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;

namespace WC3ItemManager.Models
{
    public sealed class QuestGiverDefinition
    {
        [Browsable(false)]
        public int Id { get; set; }
        [Category("Identity"), DisplayName("Stable key"), Description("Stable database/JASS identifier. Avoid renaming after relationships exist.")]
        public string GiverKey { get; set; } = "";
        [Category("Identity"), DisplayName("Display name")]
        public string DisplayName { get; set; } = "";
        [Category("Identity"), DisplayName("qXXX library")]
        public string LibraryName { get; set; } = "";
        [Category("Ownership"), DisplayName("Ownership mode")]
        [TypeConverter(typeof(QuestOwnershipModeConverter))]
        public string OwnershipMode { get; set; } = "managed";
        [Category("Ownership"), DisplayName("Source file")]
        public string SourceFile { get; set; } = "";
        [Category("Source synchronization"), DisplayName("Source kind"), ReadOnly(true)]
        public string SourceKind { get; set; } = "";
        [Browsable(false)]
        public string SourceImportFingerprint { get; set; } = "";
        [Category("Source synchronization"), DisplayName("Last synchronized"), ReadOnly(true)]
        public DateTime? SourceImportedAt { get; set; }
        [Category("World binding"), DisplayName("Unit rawcode")]
        public string UnitCode { get; set; } = "";
        [Category("World binding"), DisplayName("Placed unit variable")]
        public string PlacedUnitVariable { get; set; } = "";
        [Category("World binding"), DisplayName("Zone ID")]
        public int? ZoneId { get; set; }
        [Category("Availability")]
        public string Faction { get; set; } = "";
        [Category("Availability"), DisplayName("Allow Nazgrek")]
        public bool AllowNazgrek { get; set; } = true;
        [Category("Availability"), DisplayName("Allow Zul'kis")]
        public bool AllowZulkis { get; set; }
        [Category("Dialog"), DisplayName("Interaction range")]
        public decimal DialogRange { get; set; } = 500m;
        [Category("Dialog"), DisplayName("Cooldown")]
        public decimal DialogCooldown { get; set; } = 6m;
        [Category("Dialog"), DisplayName("Use dialog camera")]
        public bool UseDialogCamera { get; set; } = true;
        [Category("Dialog"), DisplayName("Use cinematic mode")]
        public bool UseCinematicMode { get; set; } = true;
        [Category("Camera"), DisplayName("Distance")]
        public decimal CameraDistance { get; set; } = 850m;
        [Category("Camera"), DisplayName("Z offset")]
        public decimal CameraZOffset { get; set; } = 20m;
        [Category("Camera"), DisplayName("Angle")]
        public decimal CameraAngle { get; set; } = 350m;
        [Category("Camera"), DisplayName("Rotation offset")]
        public decimal CameraRotationOffset { get; set; } = 180m;
        [Category("Camera"), DisplayName("Far Z")]
        public decimal CameraFarZ { get; set; } = 10000m;
        [Category("Camera"), DisplayName("Field of view")]
        public decimal CameraFov { get; set; } = 60m;
        [Category("Camera"), DisplayName("Block radius")]
        public decimal CameraBlockRadius { get; set; }
        [Category("Camera"), DisplayName("Check blocking")]
        public bool CameraBlockCheck { get; set; } = true;
        [Category("Status")]
        public bool Enabled { get; set; } = true;
        [Category("Status")]
        public string Notes { get; set; } = "";
        [Browsable(false)]
        public DateTime CreatedAt { get; set; }
        [Browsable(false)]
        public DateTime UpdatedAt { get; set; }

        public override string ToString() => DisplayName;
    }

    public sealed class QuestDefinition
    {
        [Browsable(false)]
        public int Id { get; set; }
        [Browsable(false)]
        public int QuestGiverId { get; set; }
        [Category("Identity"), DisplayName("Stable key"), Description("Stable database/JASS identifier. Avoid renaming after export or synchronization.")]
        public string QuestKey { get; set; } = "";
        [Category("Identity"), DisplayName("Internal name")]
        public string QuestName { get; set; } = "";
        [Category("Quest log"), DisplayName("Title")]
        public string Title { get; set; } = "";
        [Category("Classification"), DisplayName("Type")]
        [TypeConverter(typeof(QuestTypeConverter))]
        public string QuestType { get; set; } = "normal";
        [Category("Classification")]
        [TypeConverter(typeof(QuestCategoryConverter))]
        public string Category { get; set; } = "general";
        [Category("Levels"), DisplayName("Quest level")]
        public int QuestLevel { get; set; } = 1;
        [Category("Levels"), DisplayName("Required hero level")]
        public int RequiredLevel { get; set; } = 1;
        [Category("Levels"), DisplayName("Required reputation")]
        public int RequiredReputation { get; set; }
        [Category("Quest log"), DisplayName("Icon path")]
        public string IconPath { get; set; } = "";
        [Category("Quest log")]
        public string Description { get; set; } = "";
        [Category("Quest log"), DisplayName("Details text")]
        public string InfoText { get; set; } = "";
        [Category("Quest log"), DisplayName("Additional details")]
        public string Info2Text { get; set; } = "";
        [Browsable(false)]
        public int? ReceiverGiverId { get; set; }
        [Category("Relationships"), DisplayName("Turn-in display name")]
        public string ReceiverDisplayName { get; set; } = "";
        [Category("Availability"), DisplayName("Zone ID")]
        public int? ZoneId { get; set; }
        [Category("Availability")]
        public string Faction { get; set; } = "";
        [Category("Availability"), DisplayName("Allow Nazgrek")]
        public bool AllowNazgrek { get; set; } = true;
        [Category("Availability"), DisplayName("Allow Zul'kis")]
        public bool AllowZulkis { get; set; }
        [Category("Completion"), DisplayName("Requires turn-in")]
        public bool RequiresTurnIn { get; set; } = true;
        [Category("Completion"), DisplayName("Auto-complete")]
        public bool AutoComplete { get; set; }
        [Category("Completion"), DisplayName("Failure text")]
        public string FailReason { get; set; } = "";
        [Category("Status")]
        public bool Draft { get; set; } = true;
        [Category("Status")]
        public bool Enabled { get; set; } = true;
        [Category("Status"), DisplayName("Sort order")]
        public int SortOrder { get; set; }
        [Category("Status")]
        public string Notes { get; set; } = "";
        [Category("Source synchronization"), DisplayName("Source file"), ReadOnly(true)]
        public string SourceFile { get; set; } = "";
        [Category("Source synchronization"), DisplayName("Source symbol"), ReadOnly(true)]
        public string SourceSymbol { get; set; } = "";
        [Browsable(false)]
        public string SourceImportFingerprint { get; set; } = "";
        [Category("Source synchronization"), DisplayName("Last synchronized"), ReadOnly(true)]
        public DateTime? SourceImportedAt { get; set; }
        [Browsable(false)]
        public DateTime CreatedAt { get; set; }
        [Browsable(false)]
        public DateTime UpdatedAt { get; set; }

        public override string ToString() => Title;
    }

    public sealed class QuestObjectiveDefinition
    {
        [Browsable(false)]
        public int Id { get; set; }
        [Browsable(false)]
        public int QuestId { get; set; }
        [Category("Identity"), DisplayName("Objective key")]
        public string ObjectiveKey { get; set; } = "Objective";
        [Category("Identity"), DisplayName("Display order")]
        public int DisplayOrder { get; set; } = 1;
        [Category("Objective"), DisplayName("Type")]
        [TypeConverter(typeof(QuestObjectiveTypeConverter))]
        public string ObjectiveType { get; set; } = "manual";
        [Category("Objective")]
        public string Text { get; set; } = "";
        [Category("Tracking")]
        public int Amount { get; set; } = 1;
        [Category("Tracking"), DisplayName("Item rawcode")]
        public string ItemCode { get; set; } = "";
        [Category("Tracking"), DisplayName("Unit rawcode")]
        public string UnitCode { get; set; } = "";
        [Category("Tracking"), DisplayName("Target variable")]
        public string TargetVariable { get; set; } = "";
        [Category("Tracking"), DisplayName("Target name")]
        public string TargetName { get; set; } = "";
        [Category("Tracking"), DisplayName("Region variable")]
        public string RegionVariable { get; set; } = "";
        [Category("Tracking"), DisplayName("Zone ID")]
        public int? ZoneId { get; set; }
        [Category("Tracking")]
        public string Faction { get; set; } = "";
        [Category("Tracking"), DisplayName("Required reputation")]
        public int RequiredReputation { get; set; }
        [Category("Completion"), DisplayName("Completion mode")]
        [TypeConverter(typeof(QuestCompletionModeConverter))]
        public string CompletionMode { get; set; } = "automatic";
        [Category("Completion"), DisplayName("External hook")]
        public string ExternalHook { get; set; } = "";
        [Category("Completion")]
        public string Notes { get; set; } = "";
    }

    public sealed class QuestRewardDefinition
    {
        [Browsable(false)]
        public int QuestId { get; set; }
        [Category("Experience"), DisplayName("Enabled")]
        public bool XpActive { get; set; } = true;
        [Category("Experience"), DisplayName("Adjustment")]
        public int XpAdjust { get; set; }
        [Category("Gold"), DisplayName("Enabled")]
        public bool GoldActive { get; set; } = true;
        [Category("Gold"), DisplayName("Adjustment")]
        public int GoldAdjust { get; set; }
        [Category("Arena points"), DisplayName("Enabled")]
        public bool ArenaActive { get; set; }
        [Category("Arena points"), DisplayName("Adjustment")]
        public int ArenaAdjust { get; set; }
        [Category("Reputation"), DisplayName("Enabled")]
        public bool ReputationActive { get; set; }
        [Category("Reputation"), DisplayName("Adjustment")]
        public int ReputationAdjust { get; set; }
        [Category("Reputation"), DisplayName("Use giver faction")]
        public bool ReputationLinked { get; set; }
        [Category("Item"), DisplayName("Item rawcode")]
        public string ItemCode { get; set; } = "";
        [Category("Custom"), DisplayName("Reward text")]
        public string CustomText { get; set; } = "";
    }

    public sealed class QuestSequenceDefinition
    {
        [Browsable(false)]
        public int Id { get; set; }
        [Browsable(false)]
        public int QuestGiverId { get; set; }
        [Browsable(false)]
        public int? QuestId { get; set; }
        [Category("Identity"), DisplayName("Sequence key")]
        public string SequenceKey { get; set; } = "Sequence";
        [Category("Identity"), DisplayName("Display name")]
        public string DisplayName { get; set; } = "New sequence";
        [Category("Identity")]
        [TypeConverter(typeof(QuestSequencePurposeConverter))]
        public string Purpose { get; set; } = "custom";
        [Category("Dialog option"), DisplayName("Show as option")]
        public bool ShowAsDialogOption { get; set; }
        [Category("Dialog option"), DisplayName("Button label")]
        public string ButtonLabel { get; set; } = "";
        [Category("Dialog option"), DisplayName("Button order")]
        public int ButtonOrder { get; set; }
        [Category("Hooks"), DisplayName("On start")]
        public string OnStartHook { get; set; } = "";
        [Category("Hooks"), DisplayName("On finish")]
        public string OnFinishHook { get; set; } = "";
        [Category("Behavior")]
        public bool Skippable { get; set; } = true;
        [Category("Behavior")]
        public bool Enabled { get; set; } = true;
        [Category("Behavior")]
        public string Notes { get; set; } = "";

        public override string ToString() => DisplayName;
    }

    public sealed class QuestSequenceStepDefinition
    {
        [Browsable(false)]
        public int Id { get; set; }
        [Browsable(false)]
        public int SequenceId { get; set; }
        [Category("Step"), DisplayName("Display order")]
        public int DisplayOrder { get; set; } = 1;
        [Category("Step"), DisplayName("Type")]
        [TypeConverter(typeof(QuestSequenceStepTypeConverter))]
        public string StepType { get; set; } = "line";
        [Category("Speaker"), DisplayName("Binding")]
        public string SpeakerBinding { get; set; } = "Giver";
        [Category("Speaker"), DisplayName("Display name")]
        public string SpeakerName { get; set; } = "";
        [Category("Content")]
        public string Text { get; set; } = "";
        [Category("Content"), DisplayName("Sound key")]
        public string SoundKey { get; set; } = "";
        [Category("Content"), DisplayName("Voiceline")]
        public int? VoicelineId { get; set; }
        [Category("Timing / target")]
        public decimal Duration { get; set; }
        [Category("Timing / target"), DisplayName("Target binding")]
        public string TargetBinding { get; set; } = "";
        [Category("Timing / target"), DisplayName("Point X")]
        public decimal? PointX { get; set; }
        [Category("Timing / target"), DisplayName("Point Y")]
        public decimal? PointY { get; set; }
        [Category("Content"), DisplayName("Action hook")]
        public string ActionHook { get; set; } = "";
        [Category("Content"), DisplayName("Sound at unit")]
        public bool SoundAtUnit { get; set; } = true;
        [Category("Content")]
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
