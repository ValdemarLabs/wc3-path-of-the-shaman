using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using Npgsql;

namespace WC3ItemManager
{
    public class BatchItemEditDialog : Form
    {
        private const string UnchangedComboText = "(Leave unchanged / mixed)";

        private readonly string _connectionString;
        private readonly List<int> _itemIds;
        private bool _isLoading;

        private CheckBox chkApplyBaseId;
        private ComboBox cmbBaseId;
        private CheckBox chkApplyRarity;
        private ComboBox cmbRarity;
        private CheckBox chkApplyClass;
        private ComboBox cmbClass;
        private CheckBox chkApplyType;
        private ComboBox cmbType;
        private CheckBox chkApplyWC3Classification;
        private ComboBox cmbWC3Classification;

        private CheckBox chkApplyItemLevel;
        private NumericUpDown numItemLevel;
        private CheckBox chkApplyGoldCost;
        private NumericUpDown numGoldCost;
        private CheckBox chkApplyLumberCost;
        private NumericUpDown numLumberCost;
        private CheckBox chkApplyMaxCharges;
        private NumericUpDown numMaxCharges;
        private CheckBox chkApplyMaxStack;
        private NumericUpDown numMaxStack;

        private CheckBox chkApplyTooltip;
        private TextBox txtTooltip;
        private CheckBox chkApplyTooltipExtended;
        private TextBox txtTooltipExtended;
        private CheckBox chkApplyHotkey;
        private TextBox txtHotkey;
        private CheckBox chkApplyIconPath;
        private TextBox txtIconPath;
        private CheckBox chkApplyModelPath;
        private TextBox txtModelPath;

        private CheckBox chkApplyPowerUpAutoAcquire;
        private CheckBox chkPowerUpAutoAcquire;
        private CheckBox chkApplyDroppable;
        private CheckBox chkDroppable;
        private CheckBox chkApplySellable;
        private CheckBox chkSellable;
        private CheckBox chkApplyPawnable;
        private CheckBox chkPawnable;
        private CheckBox chkApplyActivelyUsed;
        private CheckBox chkActivelyUsed;
        private CheckBox chkApplyDroppedOnDeath;
        private CheckBox chkDroppedOnDeath;
        private CheckBox chkApplySpecificDropOnly;
        private CheckBox chkSpecificDropOnly;

        private bool _powerUpAutoAcquireMixed;
        private bool _powerUpAutoAcquireOriginalValue;

        private sealed class SelectedItemSnapshot
        {
            public string BaseId { get; init; } = string.Empty;
            public string Rarity { get; init; } = string.Empty;
            public string ItemClass { get; init; } = string.Empty;
            public string ItemType { get; init; } = string.Empty;
            public string WC3Classification { get; init; } = string.Empty;
            public int ItemLevel { get; init; }
            public int GoldCost { get; init; }
            public int LumberCost { get; init; }
            public int MaxCharges { get; init; }
            public int MaxStack { get; init; }
            public string Tooltip { get; init; } = string.Empty;
            public string TooltipExtended { get; init; } = string.Empty;
            public string Hotkey { get; init; } = string.Empty;
            public string IconPath { get; init; } = string.Empty;
            public string ModelPath { get; init; } = string.Empty;
            public bool PowerUpAutoAcquire { get; init; }
            public bool Droppable { get; init; }
            public bool Sellable { get; init; }
            public bool Pawnable { get; init; }
            public bool ActivelyUsed { get; init; }
            public bool DroppedOnDeath { get; init; }
            public bool SpecificDropOnly { get; init; }
        }

        private sealed class ComboValueItem
        {
            public string Value { get; init; } = string.Empty;
            public string Display { get; init; } = string.Empty;
            public bool IsPlaceholder { get; init; }

            public override string ToString()
            {
                return Display;
            }
        }

        public BatchItemEditDialog(IEnumerable<int> itemIds, string connectionString)
        {
            _itemIds = itemIds?.Distinct().OrderBy(id => id).ToList() ?? new List<int>();
            _connectionString = connectionString;

            if (_itemIds.Count == 0)
                throw new ArgumentException("At least one item must be selected for batch edit.", nameof(itemIds));

            InitializeComponent();
            LoadLookupData();
            LoadSelectedItemData();
        }

        private void InitializeComponent()
        {
            Text = _itemIds.Count == 1 ? "Edit Item" : $"Batch Edit {_itemIds.Count} Items";
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.Sizable;
            MinimumSize = new Size(920, 760);
            Size = new Size(980, 860);

            var lblSummary = new Label
            {
                Dock = DockStyle.Top,
                Height = 64,
                Padding = new Padding(12, 10, 12, 10),
                Text = "Only fields with Apply checked are written. Changing a field auto-checks Apply. " +
                       "Mixed fields stay unchanged unless you choose a value or tick Apply manually. " +
                       "Item code/name, stats, abilities, and drop sources remain single-item only."
            };
            Controls.Add(lblSummary);

            var contentPanel = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true
            };
            Controls.Add(contentPanel);

            var buttonPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 56,
                Padding = new Padding(12, 10, 12, 10)
            };
            Controls.Add(buttonPanel);

            var btnSave = new Button
            {
                Text = "Apply Changes",
                Width = 130,
                Height = 30,
                Anchor = AnchorStyles.Right | AnchorStyles.Top
            };
            btnSave.Location = new Point(buttonPanel.Width - 270, 10);
            btnSave.Click += BtnSave_Click;
            buttonPanel.Controls.Add(btnSave);

            var btnCancel = new Button
            {
                Text = "Cancel",
                Width = 100,
                Height = 30,
                DialogResult = DialogResult.Cancel,
                Anchor = AnchorStyles.Right | AnchorStyles.Top
            };
            btnCancel.Location = new Point(buttonPanel.Width - 130, 10);
            buttonPanel.Controls.Add(btnCancel);

            buttonPanel.Resize += (s, e) =>
            {
                btnCancel.Location = new Point(buttonPanel.Width - 112, 10);
                btnSave.Location = new Point(buttonPanel.Width - 252, 10);
            };

            AcceptButton = btnSave;
            CancelButton = btnCancel;

            int y = 16;
            AddSectionHeader(contentPanel, "Classification And IDs", ref y);

            chkApplyBaseId = CreateApplyCheckBox();
            cmbBaseId = CreateComboBox(470);
            AddEditorRow(contentPanel, chkApplyBaseId, "Base Item ID:", cmbBaseId, ref y);

            chkApplyRarity = CreateApplyCheckBox();
            cmbRarity = CreateComboBox(240);
            AddEditorRow(contentPanel, chkApplyRarity, "Rarity:", cmbRarity, ref y);

            chkApplyClass = CreateApplyCheckBox();
            cmbClass = CreateComboBox(320);
            AddEditorRow(contentPanel, chkApplyClass, "Class (Slot):", cmbClass, ref y);

            chkApplyType = CreateApplyCheckBox();
            cmbType = CreateComboBox(260);
            AddEditorRow(contentPanel, chkApplyType, "Type (Category):", cmbType, ref y);

            chkApplyWC3Classification = CreateApplyCheckBox();
            cmbWC3Classification = CreateComboBox(240);
            AddEditorRow(contentPanel, chkApplyWC3Classification, "WC3 Classification:", cmbWC3Classification, ref y);

            AddSectionHeader(contentPanel, "Values And Costs", ref y);

            chkApplyItemLevel = CreateApplyCheckBox();
            numItemLevel = CreateNumericUpDown(0, 999, 120);
            AddEditorRow(contentPanel, chkApplyItemLevel, "Item Level:", numItemLevel, ref y);

            chkApplyGoldCost = CreateApplyCheckBox();
            numGoldCost = CreateNumericUpDown(0, 999999, 140);
            AddEditorRow(contentPanel, chkApplyGoldCost, "Gold Cost:", numGoldCost, ref y);

            chkApplyLumberCost = CreateApplyCheckBox();
            numLumberCost = CreateNumericUpDown(0, 999999, 140);
            AddEditorRow(contentPanel, chkApplyLumberCost, "Lumber Cost:", numLumberCost, ref y);

            chkApplyMaxCharges = CreateApplyCheckBox();
            numMaxCharges = CreateNumericUpDown(0, 999, 120);
            AddEditorRow(contentPanel, chkApplyMaxCharges, "Max Charges:", numMaxCharges, ref y);

            chkApplyMaxStack = CreateApplyCheckBox();
            numMaxStack = CreateNumericUpDown(0, 999, 120);
            AddEditorRow(contentPanel, chkApplyMaxStack, "Max Stack:", numMaxStack, ref y);

            AddSectionHeader(contentPanel, "Text And Assets", ref y);

            chkApplyTooltip = CreateApplyCheckBox();
            txtTooltip = CreateTextBox(540);
            AddEditorRow(contentPanel, chkApplyTooltip, "Tooltip (Basic):", txtTooltip, ref y);

            chkApplyTooltipExtended = CreateApplyCheckBox();
            txtTooltipExtended = CreateMultilineTextBox(540, 110);
            AddEditorRow(contentPanel, chkApplyTooltipExtended, "Extended Tooltip / Description:", txtTooltipExtended, ref y, 118);

            chkApplyHotkey = CreateApplyCheckBox();
            txtHotkey = CreateTextBox(80);
            txtHotkey.MaxLength = 1;
            txtHotkey.CharacterCasing = CharacterCasing.Upper;
            AddEditorRow(contentPanel, chkApplyHotkey, "Hotkey:", txtHotkey, ref y);

            chkApplyIconPath = CreateApplyCheckBox();
            txtIconPath = CreateTextBox(430);
            var btnBrowseIcon = new Button
            {
                Text = "Browse...",
                Width = 90,
                Height = 26
            };
            btnBrowseIcon.Click += BtnBrowseIcon_Click;
            AddEditorRow(contentPanel, chkApplyIconPath, "Icon Path:", txtIconPath, ref y, 34, btnBrowseIcon);

            chkApplyModelPath = CreateApplyCheckBox();
            txtModelPath = CreateTextBox(540);
            AddEditorRow(contentPanel, chkApplyModelPath, "Model Path:", txtModelPath, ref y);

            AddSectionHeader(contentPanel, "Flags", ref y);

            chkApplyPowerUpAutoAcquire = CreateApplyCheckBox();
            chkPowerUpAutoAcquire = CreateValueCheckBox("Use Automatically When Acquired");
            AddEditorRow(contentPanel, chkApplyPowerUpAutoAcquire, "PowerUp / Auto Use:", chkPowerUpAutoAcquire, ref y);

            chkApplyDroppable = CreateApplyCheckBox();
            chkDroppable = CreateValueCheckBox("Droppable");
            AddEditorRow(contentPanel, chkApplyDroppable, "Droppable:", chkDroppable, ref y);

            chkApplySellable = CreateApplyCheckBox();
            chkSellable = CreateValueCheckBox("Sellable");
            AddEditorRow(contentPanel, chkApplySellable, "Sellable:", chkSellable, ref y);

            chkApplyPawnable = CreateApplyCheckBox();
            chkPawnable = CreateValueCheckBox("Pawnable");
            AddEditorRow(contentPanel, chkApplyPawnable, "Pawnable:", chkPawnable, ref y);

            chkApplyActivelyUsed = CreateApplyCheckBox();
            chkActivelyUsed = CreateValueCheckBox("Actively Used");
            AddEditorRow(contentPanel, chkApplyActivelyUsed, "Actively Used:", chkActivelyUsed, ref y);

            chkApplyDroppedOnDeath = CreateApplyCheckBox();
            chkDroppedOnDeath = CreateValueCheckBox("Dropped On Death");
            AddEditorRow(contentPanel, chkApplyDroppedOnDeath, "Dropped On Death:", chkDroppedOnDeath, ref y);

            chkApplySpecificDropOnly = CreateApplyCheckBox();
            chkSpecificDropOnly = CreateValueCheckBox("Specific Drop Only");
            AddEditorRow(contentPanel, chkApplySpecificDropOnly, "Specific Drop Only:", chkSpecificDropOnly, ref y);
        }

        private CheckBox CreateApplyCheckBox()
        {
            return new CheckBox
            {
                Text = "Apply",
                AutoSize = true
            };
        }

        private ComboBox CreateComboBox(int width)
        {
            return new ComboBox
            {
                Width = width,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
        }

        private NumericUpDown CreateNumericUpDown(int minimum, int maximum, int width)
        {
            return new NumericUpDown
            {
                Minimum = minimum,
                Maximum = maximum,
                Width = width
            };
        }

        private TextBox CreateTextBox(int width)
        {
            return new TextBox
            {
                Width = width
            };
        }

        private TextBox CreateMultilineTextBox(int width, int height)
        {
            return new TextBox
            {
                Width = width,
                Height = height,
                Multiline = true,
                ScrollBars = ScrollBars.Vertical
            };
        }

        private CheckBox CreateValueCheckBox(string text)
        {
            return new CheckBox
            {
                Text = text,
                AutoSize = true,
                ThreeState = true
            };
        }

        private void AddSectionHeader(Control parent, string title, ref int y)
        {
            if (y > 16)
            {
                var divider = new Label
                {
                    BorderStyle = BorderStyle.Fixed3D,
                    Width = 880,
                    Height = 2,
                    Location = new Point(16, y)
                };
                parent.Controls.Add(divider);
                y += 12;
            }

            var header = new Label
            {
                Text = title,
                Font = new Font(Font, FontStyle.Bold),
                AutoSize = true,
                Location = new Point(16, y)
            };
            parent.Controls.Add(header);
            y += 32;
        }

        private void AddEditorRow(Control parent, CheckBox applyCheckBox, string labelText, Control editor, ref int y, int rowHeight = 32, Control accessory = null)
        {
            applyCheckBox.Location = new Point(20, y + 4);
            parent.Controls.Add(applyCheckBox);

            var label = new Label
            {
                Text = labelText,
                AutoSize = true,
                Location = new Point(105, y + 6)
            };
            parent.Controls.Add(label);

            editor.Location = new Point(285, y);
            parent.Controls.Add(editor);

            if (accessory != null)
            {
                accessory.Location = new Point(editor.Right + 10, y - 1);
                parent.Controls.Add(accessory);
            }

            y += rowHeight;
        }

        private void LoadLookupData()
        {
            try
            {
                using var conn = new NpgsqlConnection(_connectionString);
                conn.Open();

                PopulateBaseItemOptions(conn);
                PopulateLookupCombo(conn, cmbRarity, "SELECT rarity_name FROM item_rarities ORDER BY rarity_level",
                    new[] { "Common", "Uncommon", "Rare", "Epic", "Legendary" });
                PopulateLookupCombo(conn, cmbClass, "SELECT class_name FROM item_classes ORDER BY class_name",
                    new[] { "Miscellaneous", "Weapon", "Armor" });
                PopulateLookupCombo(conn, cmbType, "SELECT type_name FROM item_types ORDER BY type_name",
                    new[] { "Other", "Consumable", "Equipment" });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading batch edit lookup data: {ex.Message}", "Warning",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);

                PopulateLookupComboItems(cmbBaseId, new[]
                {
                    new ComboValueItem { Value = string.Empty, Display = "(None - Custom Item)" }
                });
                PopulateLookupComboItems(cmbRarity, new[]
                {
                    new ComboValueItem { Value = "Common", Display = "Common" },
                    new ComboValueItem { Value = "Uncommon", Display = "Uncommon" },
                    new ComboValueItem { Value = "Rare", Display = "Rare" },
                    new ComboValueItem { Value = "Epic", Display = "Epic" },
                    new ComboValueItem { Value = "Legendary", Display = "Legendary" }
                });
                PopulateLookupComboItems(cmbClass, new[]
                {
                    new ComboValueItem { Value = "Miscellaneous", Display = "Miscellaneous" }
                });
                PopulateLookupComboItems(cmbType, new[]
                {
                    new ComboValueItem { Value = "Other", Display = "Other" }
                });
            }

            PopulateLookupComboItems(cmbWC3Classification, new[]
            {
                new ComboValueItem { Value = "Permanent", Display = "Permanent" },
                new ComboValueItem { Value = "Charged", Display = "Charged" },
                new ComboValueItem { Value = "PowerUp", Display = "PowerUp" },
                new ComboValueItem { Value = "Artifact", Display = "Artifact" },
                new ComboValueItem { Value = "Campaign", Display = "Campaign" },
                new ComboValueItem { Value = "Miscellaneous", Display = "Miscellaneous" }
            });
        }

        private void PopulateBaseItemOptions(NpgsqlConnection conn)
        {
            var items = new List<ComboValueItem>
            {
                new ComboValueItem { Value = string.Empty, Display = "(None - Custom Item)" }
            };

            using var cmd = new NpgsqlCommand(@"
                SELECT item_code, item_name, item_type
                FROM wc3_base_items
                ORDER BY is_common DESC, item_name", conn);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                string code = ReadString(reader, "item_code");
                string name = ReadString(reader, "item_name");
                string type = ReadString(reader, "item_type");
                string display = string.IsNullOrWhiteSpace(type)
                    ? $"{code} - {name}"
                    : $"{code} - {name} ({type})";

                items.Add(new ComboValueItem
                {
                    Value = code,
                    Display = display
                });
            }

            PopulateLookupComboItems(cmbBaseId, items);
        }

        private void PopulateLookupCombo(NpgsqlConnection conn, ComboBox combo, string query, IEnumerable<string> fallbacks)
        {
            var items = new List<ComboValueItem>();
            using (var cmd = new NpgsqlCommand(query, conn))
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    string value = reader.GetString(0);
                    items.Add(new ComboValueItem
                    {
                        Value = value,
                        Display = value
                    });
                }
            }

            if (items.Count == 0)
            {
                items.AddRange(fallbacks.Select(value => new ComboValueItem
                {
                    Value = value,
                    Display = value
                }));
            }

            PopulateLookupComboItems(combo, items);
        }

        private void PopulateLookupComboItems(ComboBox combo, IEnumerable<ComboValueItem> items)
        {
            combo.Items.Clear();
            combo.Items.Add(new ComboValueItem
            {
                Value = string.Empty,
                Display = UnchangedComboText,
                IsPlaceholder = true
            });

            foreach (var item in items)
            {
                combo.Items.Add(item);
            }

            combo.SelectedIndex = 0;
        }

        private void LoadSelectedItemData()
        {
            var selectedItems = new List<SelectedItemSnapshot>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();

                using var cmd = new NpgsqlCommand(@"
                    SELECT i.base_id,
                           r.rarity_name,
                           c.class_name,
                           t.type_name,
                           i.wc3_classification,
                           i.item_level,
                           i.gold_cost,
                           i.lumber_cost,
                           i.max_charges,
                           i.max_stack,
                           i.tooltip,
                           i.tooltip_extended,
                           i.hotkey,
                           i.icon_path,
                           i.model_path,
                           i.is_powerup,
                           i.use_automatically,
                           i.is_droppable,
                           i.is_sellable,
                           i.is_pawnable,
                           i.actively_used,
                           i.dropped_on_death,
                           i.specific_drop_only
                    FROM items i
                    LEFT JOIN item_rarities r ON i.rarity_id = r.id
                    LEFT JOIN item_classes c ON i.class_id = c.id
                    LEFT JOIN item_types t ON i.type_id = t.id
                    WHERE i.id = ANY(@ids)", conn);
                cmd.Parameters.AddWithValue("ids", _itemIds.ToArray());

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string classification = NormalizeWC3Classification(ReadString(reader, "wc3_classification"));
                    bool isPowerUp = ReadBool(reader, "is_powerup");
                    bool useAutomatically = ReadBool(reader, "use_automatically");

                    selectedItems.Add(new SelectedItemSnapshot
                    {
                        BaseId = ReadString(reader, "base_id"),
                        Rarity = ReadString(reader, "rarity_name"),
                        ItemClass = ReadString(reader, "class_name"),
                        ItemType = ReadString(reader, "type_name"),
                        WC3Classification = classification,
                        ItemLevel = ReadInt(reader, "item_level"),
                        GoldCost = ReadInt(reader, "gold_cost"),
                        LumberCost = ReadInt(reader, "lumber_cost"),
                        MaxCharges = ReadInt(reader, "max_charges"),
                        MaxStack = ReadInt(reader, "max_stack"),
                        Tooltip = ReadString(reader, "tooltip"),
                        TooltipExtended = ReadString(reader, "tooltip_extended"),
                        Hotkey = ReadString(reader, "hotkey"),
                        IconPath = ReadString(reader, "icon_path"),
                        ModelPath = ReadString(reader, "model_path"),
                        PowerUpAutoAcquire = isPowerUp || useAutomatically || classification.Equals("PowerUp", StringComparison.OrdinalIgnoreCase),
                        Droppable = ReadBool(reader, "is_droppable"),
                        Sellable = ReadBool(reader, "is_sellable"),
                        Pawnable = ReadBool(reader, "is_pawnable"),
                        ActivelyUsed = ReadBool(reader, "actively_used"),
                        DroppedOnDeath = ReadBool(reader, "dropped_on_death"),
                        SpecificDropOnly = ReadBool(reader, "specific_drop_only")
                    });
                }
            }

            if (selectedItems.Count == 0)
            {
                throw new InvalidOperationException("None of the selected items could be loaded.");
            }

            ConfigureFormFromSelectedItems(selectedItems);
        }

        private void ConfigureFormFromSelectedItems(List<SelectedItemSnapshot> items)
        {
            _isLoading = true;

            bool sameBaseId = TryGetCommonString(items.Select(i => i.BaseId), out string commonBaseId);
            bool sameRarity = TryGetCommonString(items.Select(i => i.Rarity), out string commonRarity);
            bool sameClass = TryGetCommonString(items.Select(i => i.ItemClass), out string commonClass);
            bool sameType = TryGetCommonString(items.Select(i => i.ItemType), out string commonType);
            bool sameClassification = TryGetCommonString(items.Select(i => i.WC3Classification), out string commonClassification);
            bool sameLevel = TryGetCommonInt(items.Select(i => i.ItemLevel), out int commonLevel);
            bool sameGoldCost = TryGetCommonInt(items.Select(i => i.GoldCost), out int commonGoldCost);
            bool sameLumberCost = TryGetCommonInt(items.Select(i => i.LumberCost), out int commonLumberCost);
            bool sameMaxCharges = TryGetCommonInt(items.Select(i => i.MaxCharges), out int commonMaxCharges);
            bool sameMaxStack = TryGetCommonInt(items.Select(i => i.MaxStack), out int commonMaxStack);
            bool sameTooltip = TryGetCommonString(items.Select(i => i.Tooltip), out string commonTooltip);
            bool sameTooltipExtended = TryGetCommonString(items.Select(i => i.TooltipExtended), out string commonTooltipExtended);
            bool sameHotkey = TryGetCommonString(items.Select(i => i.Hotkey), out string commonHotkey);
            bool sameIconPath = TryGetCommonString(items.Select(i => i.IconPath), out string commonIconPath);
            bool sameModelPath = TryGetCommonString(items.Select(i => i.ModelPath), out string commonModelPath);
            bool samePowerUpAutoAcquire = TryGetCommonBool(items.Select(i => i.PowerUpAutoAcquire), out bool commonPowerUpAutoAcquire);
            bool sameDroppable = TryGetCommonBool(items.Select(i => i.Droppable), out bool commonDroppable);
            bool sameSellable = TryGetCommonBool(items.Select(i => i.Sellable), out bool commonSellable);
            bool samePawnable = TryGetCommonBool(items.Select(i => i.Pawnable), out bool commonPawnable);
            bool sameActivelyUsed = TryGetCommonBool(items.Select(i => i.ActivelyUsed), out bool commonActivelyUsed);
            bool sameDroppedOnDeath = TryGetCommonBool(items.Select(i => i.DroppedOnDeath), out bool commonDroppedOnDeath);
            bool sameSpecificDropOnly = TryGetCommonBool(items.Select(i => i.SpecificDropOnly), out bool commonSpecificDropOnly);

            ConfigureComboField(cmbBaseId, chkApplyBaseId, commonBaseId, !sameBaseId);
            ConfigureComboField(cmbRarity, chkApplyRarity, commonRarity, !sameRarity);
            ConfigureComboField(cmbClass, chkApplyClass, commonClass, !sameClass);
            ConfigureComboField(cmbType, chkApplyType, commonType, !sameType);
            ConfigureComboField(cmbWC3Classification, chkApplyWC3Classification, commonClassification, !sameClassification,
                UpdatePowerUpAutoAcquireEditorState);

            ConfigureNumericField(numItemLevel, chkApplyItemLevel, commonLevel, !sameLevel);
            ConfigureNumericField(numGoldCost, chkApplyGoldCost, commonGoldCost, !sameGoldCost);
            ConfigureNumericField(numLumberCost, chkApplyLumberCost, commonLumberCost, !sameLumberCost);
            ConfigureNumericField(numMaxCharges, chkApplyMaxCharges, commonMaxCharges, !sameMaxCharges);
            ConfigureNumericField(numMaxStack, chkApplyMaxStack, commonMaxStack, !sameMaxStack);

            ConfigureTextField(txtTooltip, chkApplyTooltip, commonTooltip, !sameTooltip);
            ConfigureTextField(txtTooltipExtended, chkApplyTooltipExtended, commonTooltipExtended, !sameTooltipExtended);
            ConfigureTextField(txtHotkey, chkApplyHotkey, commonHotkey, !sameHotkey);
            ConfigureTextField(txtIconPath, chkApplyIconPath, commonIconPath, !sameIconPath);
            ConfigureTextField(txtModelPath, chkApplyModelPath, commonModelPath, !sameModelPath);

            _powerUpAutoAcquireMixed = !samePowerUpAutoAcquire;
            _powerUpAutoAcquireOriginalValue = commonPowerUpAutoAcquire;
            ConfigurePowerUpAutoAcquireField(samePowerUpAutoAcquire, commonPowerUpAutoAcquire);

            ConfigureBooleanField(chkDroppable, chkApplyDroppable, sameDroppable, commonDroppable);
            ConfigureBooleanField(chkSellable, chkApplySellable, sameSellable, commonSellable);
            ConfigureBooleanField(chkPawnable, chkApplyPawnable, samePawnable, commonPawnable);
            ConfigureBooleanField(chkActivelyUsed, chkApplyActivelyUsed, sameActivelyUsed, commonActivelyUsed);
            ConfigureBooleanField(chkDroppedOnDeath, chkApplyDroppedOnDeath, sameDroppedOnDeath, commonDroppedOnDeath);
            ConfigureBooleanField(chkSpecificDropOnly, chkApplySpecificDropOnly, sameSpecificDropOnly, commonSpecificDropOnly);

            _isLoading = false;
            UpdatePowerUpAutoAcquireEditorState();
        }

        private void ConfigureComboField(ComboBox combo, CheckBox applyCheckBox, string commonValue, bool mixed, Action onChanged = null)
        {
            applyCheckBox.Checked = false;
            combo.Tag = Tuple.Create(commonValue ?? string.Empty, mixed);

            SelectComboValue(combo, mixed ? null : commonValue);
            UpdateComboAppearance(combo, applyCheckBox);

            combo.SelectedIndexChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                SyncComboApplyCheckBox(combo, applyCheckBox);
                onChanged?.Invoke();
            };

            applyCheckBox.CheckedChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                UpdateComboAppearance(combo, applyCheckBox);
                onChanged?.Invoke();
            };
        }

        private void ConfigureNumericField(NumericUpDown numeric, CheckBox applyCheckBox, int commonValue, bool mixed)
        {
            applyCheckBox.Checked = false;
            numeric.Tag = Tuple.Create(commonValue, mixed);
            numeric.Value = mixed ? numeric.Minimum : commonValue;
            UpdateNumericAppearance(numeric, applyCheckBox);

            numeric.ValueChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                SyncNumericApplyCheckBox(numeric, applyCheckBox);
            };

            applyCheckBox.CheckedChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                UpdateNumericAppearance(numeric, applyCheckBox);
            };
        }

        private void ConfigureTextField(TextBox textBox, CheckBox applyCheckBox, string commonValue, bool mixed)
        {
            applyCheckBox.Checked = false;
            textBox.Tag = Tuple.Create(commonValue ?? string.Empty, mixed);
            textBox.Text = mixed ? string.Empty : commonValue ?? string.Empty;
            textBox.PlaceholderText = mixed ? "Mixed values" : string.Empty;
            UpdateTextAppearance(textBox, applyCheckBox);

            textBox.TextChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                SyncTextApplyCheckBox(textBox, applyCheckBox);
            };

            applyCheckBox.CheckedChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                UpdateTextAppearance(textBox, applyCheckBox);
            };
        }

        private void ConfigureBooleanField(CheckBox valueCheckBox, CheckBox applyCheckBox, bool sameValue, bool commonValue)
        {
            applyCheckBox.Checked = false;
            valueCheckBox.Tag = Tuple.Create(commonValue, !sameValue);
            valueCheckBox.CheckState = sameValue
                ? (commonValue ? CheckState.Checked : CheckState.Unchecked)
                : CheckState.Indeterminate;

            valueCheckBox.CheckStateChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                SyncBooleanApplyCheckBox(valueCheckBox, applyCheckBox);
            };
        }

        private void ConfigurePowerUpAutoAcquireField(bool sameValue, bool commonValue)
        {
            chkApplyPowerUpAutoAcquire.Checked = false;
            chkPowerUpAutoAcquire.CheckState = sameValue
                ? (commonValue ? CheckState.Checked : CheckState.Unchecked)
                : CheckState.Indeterminate;

            chkPowerUpAutoAcquire.CheckStateChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                SyncPowerUpAutoAcquireApplyCheckBox();
            };

            chkApplyPowerUpAutoAcquire.CheckedChanged += (s, e) =>
            {
                if (_isLoading)
                    return;

                UpdatePowerUpAutoAcquireEditorState();
            };
        }

        private void SyncComboApplyCheckBox(ComboBox combo, CheckBox applyCheckBox)
        {
            var selectedItem = combo.SelectedItem as ComboValueItem;
            var state = (Tuple<string, bool>)combo.Tag;
            string originalValue = state.Item1;
            bool mixed = state.Item2;

            applyCheckBox.Checked = selectedItem != null &&
                                    !selectedItem.IsPlaceholder &&
                                    (mixed || !string.Equals(selectedItem.Value ?? string.Empty, originalValue, StringComparison.Ordinal));
            UpdateComboAppearance(combo, applyCheckBox);
        }

        private void SyncNumericApplyCheckBox(NumericUpDown numeric, CheckBox applyCheckBox)
        {
            var state = (Tuple<int, bool>)numeric.Tag;
            int originalValue = state.Item1;
            bool mixed = state.Item2;

            applyCheckBox.Checked = mixed
                ? numeric.Value != numeric.Minimum
                : numeric.Value != originalValue;
            UpdateNumericAppearance(numeric, applyCheckBox);
        }

        private void SyncTextApplyCheckBox(TextBox textBox, CheckBox applyCheckBox)
        {
            var state = (Tuple<string, bool>)textBox.Tag;
            string originalValue = state.Item1;
            bool mixed = state.Item2;

            applyCheckBox.Checked = mixed
                ? !string.IsNullOrEmpty(textBox.Text)
                : !string.Equals(textBox.Text, originalValue, StringComparison.Ordinal);
            UpdateTextAppearance(textBox, applyCheckBox);
        }

        private void SyncBooleanApplyCheckBox(CheckBox valueCheckBox, CheckBox applyCheckBox)
        {
            var state = (Tuple<bool, bool>)valueCheckBox.Tag;
            bool originalValue = state.Item1;
            bool mixed = state.Item2;

            if (mixed)
            {
                applyCheckBox.Checked = valueCheckBox.CheckState != CheckState.Indeterminate;
                return;
            }

            applyCheckBox.Checked = valueCheckBox.CheckState != (originalValue ? CheckState.Checked : CheckState.Unchecked);
        }

        private void SyncPowerUpAutoAcquireApplyCheckBox()
        {
            if (IsPowerUpClassificationForced())
            {
                return;
            }

            chkApplyPowerUpAutoAcquire.Checked = _powerUpAutoAcquireMixed
                ? chkPowerUpAutoAcquire.CheckState != CheckState.Indeterminate
                : chkPowerUpAutoAcquire.CheckState != (_powerUpAutoAcquireOriginalValue ? CheckState.Checked : CheckState.Unchecked);
        }

        private void UpdateComboAppearance(ComboBox combo, CheckBox applyCheckBox)
        {
            var selectedItem = combo.SelectedItem as ComboValueItem;
            combo.BackColor = selectedItem != null && selectedItem.IsPlaceholder && !applyCheckBox.Checked
                ? Color.LemonChiffon
                : SystemColors.Window;
        }

        private void UpdateNumericAppearance(NumericUpDown numeric, CheckBox applyCheckBox)
        {
            var state = (Tuple<int, bool>)numeric.Tag;
            bool mixed = state.Item2;
            numeric.BackColor = mixed && !applyCheckBox.Checked
                ? Color.LemonChiffon
                : SystemColors.Window;
        }

        private void UpdateTextAppearance(TextBox textBox, CheckBox applyCheckBox)
        {
            var state = (Tuple<string, bool>)textBox.Tag;
            bool mixed = state.Item2;
            textBox.BackColor = mixed && !applyCheckBox.Checked
                ? Color.LemonChiffon
                : SystemColors.Window;
        }

        private void SelectComboValue(ComboBox combo, string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                if (combo == cmbBaseId)
                {
                    var noneItem = combo.Items.Cast<ComboValueItem>()
                        .FirstOrDefault(item => !item.IsPlaceholder && string.IsNullOrEmpty(item.Value));
                    if (noneItem != null)
                    {
                        combo.SelectedItem = noneItem;
                        return;
                    }
                }

                combo.SelectedIndex = 0;
                return;
            }

            var existingItem = combo.Items.Cast<ComboValueItem>()
                .FirstOrDefault(item => !item.IsPlaceholder &&
                                        string.Equals(item.Value ?? string.Empty, value, StringComparison.OrdinalIgnoreCase));

            if (existingItem == null)
            {
                existingItem = new ComboValueItem
                {
                    Value = value,
                    Display = value
                };
                combo.Items.Add(existingItem);
            }

            combo.SelectedItem = existingItem;
        }

        private ComboValueItem GetSelectedComboItem(ComboBox combo)
        {
            return combo.SelectedItem as ComboValueItem;
        }

        private void UpdatePowerUpAutoAcquireEditorState()
        {
            bool forced = IsPowerUpClassificationForced();

            _isLoading = true;
            if (forced)
            {
                chkPowerUpAutoAcquire.CheckState = CheckState.Checked;
                chkApplyPowerUpAutoAcquire.Checked = true;
            }
            else
            {
                chkPowerUpAutoAcquire.Enabled = true;
                chkApplyPowerUpAutoAcquire.Enabled = true;
                SyncPowerUpAutoAcquireApplyCheckBox();
            }
            _isLoading = false;

            chkPowerUpAutoAcquire.Enabled = !forced;
            chkApplyPowerUpAutoAcquire.Enabled = !forced;
        }

        private bool IsPowerUpClassificationForced()
        {
            if (!chkApplyWC3Classification.Checked)
                return false;

            var selectedItem = GetSelectedComboItem(cmbWC3Classification);
            return selectedItem != null &&
                   !selectedItem.IsPlaceholder &&
                   string.Equals(selectedItem.Value, "PowerUp", StringComparison.OrdinalIgnoreCase);
        }

        private void BtnBrowseIcon_Click(object sender, EventArgs e)
        {
            try
            {
                using var iconSelector = new IconSelectorDialog(txtIconPath.Text);
                if (iconSelector.ShowDialog(this) == DialogResult.OK)
                {
                    txtIconPath.Text = iconSelector.SelectedIconPath;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error opening icon selector: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            try
            {
                var updates = new List<string>();
                var updatedFields = new List<string>();

                using var conn = new NpgsqlConnection(_connectionString);
                conn.Open();

                using var cmd = new NpgsqlCommand();
                cmd.Connection = conn;

                if (chkApplyBaseId.Checked)
                {
                    var selectedBaseItem = GetSelectedComboItem(cmbBaseId);
                    if (selectedBaseItem == null || selectedBaseItem.IsPlaceholder)
                    {
                        MessageBox.Show("Select a Base Item value or uncheck Apply.", "Validation Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        return;
                    }

                    updates.Add("base_id = @base_id");
                    cmd.Parameters.AddWithValue("base_id", string.IsNullOrEmpty(selectedBaseItem.Value)
                        ? (object)DBNull.Value
                        : selectedBaseItem.Value);
                    updatedFields.Add("base_id");
                }

                if (!TryAddLookupUpdate(cmd, updates, updatedFields, chkApplyRarity, cmbRarity, "rarity_id", "item_rarities", "rarity_name", "rarity")) return;
                if (!TryAddLookupUpdate(cmd, updates, updatedFields, chkApplyClass, cmbClass, "class_id", "item_classes", "class_name", "class")) return;
                if (!TryAddLookupUpdate(cmd, updates, updatedFields, chkApplyType, cmbType, "type_id", "item_types", "type_name", "type")) return;

                if (chkApplyWC3Classification.Checked)
                {
                    var selectedClassification = GetSelectedComboItem(cmbWC3Classification);
                    if (selectedClassification == null || selectedClassification.IsPlaceholder)
                    {
                        MessageBox.Show("Select a WC3 Classification value or uncheck Apply.", "Validation Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        return;
                    }

                    updates.Add("wc3_classification = @wc3_classification");
                    cmd.Parameters.AddWithValue("wc3_classification", selectedClassification.Value);
                    updatedFields.Add("wc3_classification");
                }

                AddNumericUpdate(cmd, updates, updatedFields, chkApplyItemLevel, numItemLevel, "item_level");
                AddNumericUpdate(cmd, updates, updatedFields, chkApplyGoldCost, numGoldCost, "gold_cost");
                AddNumericUpdate(cmd, updates, updatedFields, chkApplyLumberCost, numLumberCost, "lumber_cost");
                AddNumericUpdate(cmd, updates, updatedFields, chkApplyMaxCharges, numMaxCharges, "max_charges");
                AddNumericUpdate(cmd, updates, updatedFields, chkApplyMaxStack, numMaxStack, "max_stack");

                AddTextUpdate(cmd, updates, updatedFields, chkApplyTooltip, txtTooltip, "tooltip", allowNull: false);

                if (chkApplyTooltipExtended.Checked)
                {
                    string value = txtTooltipExtended.Text ?? string.Empty;
                    updates.Add("tooltip_extended = @tooltip_extended");
                    updates.Add("description = @description");
                    cmd.Parameters.AddWithValue("tooltip_extended", value);
                    cmd.Parameters.AddWithValue("description", value);
                    updatedFields.Add("tooltip_extended");
                }

                AddTextUpdate(cmd, updates, updatedFields, chkApplyHotkey, txtHotkey, "hotkey", allowNull: true);
                AddTextUpdate(cmd, updates, updatedFields, chkApplyIconPath, txtIconPath, "icon_path", allowNull: false);
                AddTextUpdate(cmd, updates, updatedFields, chkApplyModelPath, txtModelPath, "model_path", allowNull: false);

                bool applyPowerUpAutoAcquire = chkApplyPowerUpAutoAcquire.Checked || IsPowerUpClassificationForced();
                if (applyPowerUpAutoAcquire)
                {
                    if (!IsPowerUpClassificationForced() && chkPowerUpAutoAcquire.CheckState == CheckState.Indeterminate)
                    {
                        MessageBox.Show("Choose a PowerUp / Auto Use value or uncheck Apply.", "Validation Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        return;
                    }

                    bool powerUpAutoAcquire = IsPowerUpClassificationForced() ||
                                              chkPowerUpAutoAcquire.CheckState == CheckState.Checked;
                    updates.Add("is_powerup = @is_powerup");
                    updates.Add("use_automatically = @use_automatically");
                    cmd.Parameters.AddWithValue("is_powerup", powerUpAutoAcquire);
                    cmd.Parameters.AddWithValue("use_automatically", powerUpAutoAcquire);
                    updatedFields.Add("powerup_auto_use");
                }

                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplyDroppable, chkDroppable, "is_droppable", "droppable")) return;
                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplySellable, chkSellable, "is_sellable", "sellable")) return;
                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplyPawnable, chkPawnable, "is_pawnable", "pawnable")) return;
                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplyActivelyUsed, chkActivelyUsed, "actively_used", "actively_used")) return;
                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplyDroppedOnDeath, chkDroppedOnDeath, "dropped_on_death", "dropped_on_death")) return;
                if (!AddBooleanUpdate(cmd, updates, updatedFields, chkApplySpecificDropOnly, chkSpecificDropOnly, "specific_drop_only", "specific_drop_only")) return;

                if (updates.Count == 0)
                {
                    MessageBox.Show("No batch-edit fields are selected to apply.", "No Changes",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                updates.Add("updated_at = CURRENT_TIMESTAMP");
                cmd.CommandText = $"UPDATE items SET {string.Join(", ", updates)} WHERE id = ANY(@ids)";
                cmd.Parameters.AddWithValue("ids", _itemIds.ToArray());
                int affectedRows = cmd.ExecuteNonQuery();

                Logger.Instance.Info($"Batch updated {affectedRows} items ({string.Join(", ", updatedFields.Distinct())})");

                MessageBox.Show($"Updated {affectedRows} items.", "Batch Edit Complete",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                DialogResult = DialogResult.OK;
                Close();
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Error during batch item edit", ex);
                MessageBox.Show($"Error applying batch changes: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private bool TryAddLookupUpdate(
            NpgsqlCommand cmd,
            List<string> updates,
            List<string> updatedFields,
            CheckBox applyCheckBox,
            ComboBox combo,
            string columnName,
            string tableName,
            string valueColumn,
            string fieldLabel)
        {
            if (!applyCheckBox.Checked)
                return true;

            var selectedItem = GetSelectedComboItem(combo);
            if (selectedItem == null || selectedItem.IsPlaceholder)
            {
                MessageBox.Show($"Select a {fieldLabel} value or uncheck Apply.", "Validation Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }

            int id = GetOrCreateLookupId(cmd.Connection, tableName, valueColumn, selectedItem.Value);
            updates.Add($"{columnName} = @{columnName}");
            cmd.Parameters.AddWithValue(columnName, id);
            updatedFields.Add(columnName);
            return true;
        }

        private void AddNumericUpdate(
            NpgsqlCommand cmd,
            List<string> updates,
            List<string> updatedFields,
            CheckBox applyCheckBox,
            NumericUpDown numeric,
            string columnName)
        {
            if (!applyCheckBox.Checked)
                return;

            updates.Add($"{columnName} = @{columnName}");
            cmd.Parameters.AddWithValue(columnName, Decimal.ToInt32(numeric.Value));
            updatedFields.Add(columnName);
        }

        private void AddTextUpdate(
            NpgsqlCommand cmd,
            List<string> updates,
            List<string> updatedFields,
            CheckBox applyCheckBox,
            TextBox textBox,
            string columnName,
            bool allowNull)
        {
            if (!applyCheckBox.Checked)
                return;

            updates.Add($"{columnName} = @{columnName}");
            object value = allowNull && string.IsNullOrWhiteSpace(textBox.Text)
                ? DBNull.Value
                : textBox.Text ?? string.Empty;
            cmd.Parameters.AddWithValue(columnName, value);
            updatedFields.Add(columnName);
        }

        private bool AddBooleanUpdate(
            NpgsqlCommand cmd,
            List<string> updates,
            List<string> updatedFields,
            CheckBox applyCheckBox,
            CheckBox valueCheckBox,
            string columnName,
            string fieldName)
        {
            if (!applyCheckBox.Checked)
                return true;

            if (valueCheckBox.CheckState == CheckState.Indeterminate)
            {
                MessageBox.Show($"Choose a value for {fieldName} or uncheck Apply.", "Validation Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }

            updates.Add($"{columnName} = @{columnName}");
            cmd.Parameters.AddWithValue(columnName, valueCheckBox.CheckState == CheckState.Checked);
            updatedFields.Add(fieldName);
            return true;
        }

        private int GetOrCreateLookupId(NpgsqlConnection conn, string tableName, string valueColumn, string value)
        {
            using (var selectCmd = new NpgsqlCommand($"SELECT id FROM {tableName} WHERE {valueColumn} = @value", conn))
            {
                selectCmd.Parameters.AddWithValue("value", value);
                object existingId = selectCmd.ExecuteScalar();
                if (existingId != null)
                    return Convert.ToInt32(existingId);
            }

            using var insertCmd = new NpgsqlCommand(
                $"INSERT INTO {tableName} ({valueColumn}) VALUES (@value) RETURNING id", conn);
            insertCmd.Parameters.AddWithValue("value", value);
            return Convert.ToInt32(insertCmd.ExecuteScalar());
        }

        private static string ReadString(NpgsqlDataReader reader, string columnName)
        {
            return reader[columnName] == DBNull.Value ? string.Empty : reader[columnName]?.ToString() ?? string.Empty;
        }

        private static int ReadInt(NpgsqlDataReader reader, string columnName)
        {
            return reader[columnName] == DBNull.Value ? 0 : Convert.ToInt32(reader[columnName]);
        }

        private static bool ReadBool(NpgsqlDataReader reader, string columnName)
        {
            return reader[columnName] != DBNull.Value && Convert.ToBoolean(reader[columnName]);
        }

        private static string NormalizeWC3Classification(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return "Permanent";

            return value.Trim().ToLowerInvariant() switch
            {
                "powerup" => "PowerUp",
                "permanent" => "Permanent",
                "charged" => "Charged",
                "artifact" => "Artifact",
                "campaign" => "Campaign",
                "miscellaneous" => "Miscellaneous",
                _ => value.Trim()
            };
        }

        private static bool TryGetCommonString(IEnumerable<string> values, out string commonValue)
        {
            var list = values.Select(value => value ?? string.Empty).ToList();
            if (list.Count == 0)
            {
                commonValue = string.Empty;
                return false;
            }

            commonValue = list[0];
            string firstValue = commonValue;
            return list.All(value => string.Equals(value, firstValue, StringComparison.Ordinal));
        }

        private static bool TryGetCommonInt(IEnumerable<int> values, out int commonValue)
        {
            var list = values.ToList();
            if (list.Count == 0)
            {
                commonValue = 0;
                return false;
            }

            commonValue = list[0];
            int firstValue = commonValue;
            return list.All(value => value == firstValue);
        }

        private static bool TryGetCommonBool(IEnumerable<bool> values, out bool commonValue)
        {
            var list = values.ToList();
            if (list.Count == 0)
            {
                commonValue = false;
                return false;
            }

            commonValue = list[0];
            bool firstValue = commonValue;
            return list.All(value => value == firstValue);
        }
    }
}
