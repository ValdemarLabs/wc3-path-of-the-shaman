using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Repositories;

namespace WC3ItemManager.Dialogs
{
    public sealed class DropBulkEditDialog : Form
    {
        private readonly CheckBox applyDropChance = new CheckBox();
        private readonly CheckBox applyGuaranteed = new CheckBox();
        private readonly CheckBox applyMinQuantity = new CheckBox();
        private readonly CheckBox applyMaxQuantity = new CheckBox();
        private readonly CheckBox applyWeight = new CheckBox();
        private readonly CheckBox applyQuestGate = new CheckBox();
        private readonly CheckBox applyNotes = new CheckBox();

        private readonly NumericUpDown dropChance = new NumericUpDown();
        private readonly CheckBox guaranteed = new CheckBox { Text = "Guaranteed" };
        private readonly NumericUpDown minQuantity = new NumericUpDown();
        private readonly NumericUpDown maxQuantity = new NumericUpDown();
        private readonly NumericUpDown weight = new NumericUpDown();
        private readonly ComboBox questGate = new ComboBox();
        private readonly ComboBox questState = new ComboBox();
        private readonly TextBox notes = new TextBox();

        public decimal? DropChance => applyDropChance.Checked ? dropChance.Value : null;
        public bool? IsGuaranteed => applyGuaranteed.Checked ? guaranteed.Checked : null;
        public int? MinQuantity => applyMinQuantity.Checked ? (int)minQuantity.Value : null;
        public int? MaxQuantity => applyMaxQuantity.Checked ? (int)maxQuantity.Value : null;
        public int? Weight => applyWeight.Checked ? (int)weight.Value : null;
        public bool ApplyQuestGate => applyQuestGate.Checked;
        public int? RequiredQuestId => (questGate.SelectedItem as QuestChoice)?.Id;
        public string RequiredQuestState => questState.SelectedItem?.ToString() ?? "active";
        public bool ApplyNotes => applyNotes.Checked;
        public string Notes => notes.Text;

        public DropBulkEditDialog(string connectionString, int selectedCount)
        {
            Text = $"Bulk Edit {selectedCount} Drop Sources";
            Size = new Size(600, 500);
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;

            ConfigureControls(connectionString);
            BuildLayout(selectedCount);
            ApplyDarkTheme();
        }

        private void ConfigureControls(string connectionString)
        {
            dropChance.DecimalPlaces = 2;
            dropChance.Minimum = 0;
            dropChance.Maximum = 100;
            dropChance.Width = 140;

            minQuantity.Minimum = 1;
            minQuantity.Maximum = 99;
            minQuantity.Value = 1;
            minQuantity.Width = 140;

            maxQuantity.Minimum = 1;
            maxQuantity.Maximum = 99;
            maxQuantity.Value = 1;
            maxQuantity.Width = 140;

            weight.Minimum = 1;
            weight.Maximum = 10000;
            weight.Value = 100;
            weight.Width = 140;

            questGate.DropDownStyle = ComboBoxStyle.DropDownList;
            questGate.Width = 280;
            questGate.Items.Add(new QuestChoice { Label = "None" });
            var quests = new QuestDesignerRepository(connectionString).GetQuests()
                .Where(q => q.Enabled)
                .OrderBy(q => q.Title)
                .ThenBy(q => q.QuestName);
            foreach (var quest in quests)
            {
                questGate.Items.Add(new QuestChoice
                {
                    Id = quest.Id,
                    Label = $"{quest.Title} [{quest.QuestName}]"
                });
            }
            questGate.SelectedIndex = 0;

            questState.DropDownStyle = ComboBoxStyle.DropDownList;
            questState.Width = 120;
            questState.Items.AddRange(new object[] { "active", "discovered" });
            questState.SelectedIndex = 0;
            questGate.SelectedIndexChanged += (s, e) =>
                questState.Enabled = (questGate.SelectedItem as QuestChoice)?.Id != null;
            questState.Enabled = false;

            notes.Width = 280;
        }

        private void BuildLayout(int selectedCount)
        {
            var layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(15),
                ColumnCount = 3,
                RowCount = 10
            };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 55));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 125));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

            var explanation = new Label
            {
                Text = $"Check each field that should be applied to all {selectedCount} selected units.",
                AutoSize = true,
                ForeColor = Color.Silver
            };
            layout.Controls.Add(explanation, 0, 0);
            layout.SetColumnSpan(explanation, 3);

            AddRow(layout, 1, applyDropChance, "Drop chance %:", dropChance);
            AddRow(layout, 2, applyGuaranteed, "Guaranteed:", guaranteed);
            AddRow(layout, 3, applyMinQuantity, "Min quantity:", minQuantity);
            AddRow(layout, 4, applyMaxQuantity, "Max quantity:", maxQuantity);
            AddRow(layout, 5, applyWeight, "Weight:", weight);

            var questPanel = new FlowLayoutPanel { AutoSize = true, WrapContents = false };
            questPanel.Controls.Add(questGate);
            questPanel.Controls.Add(questState);
            AddRow(layout, 6, applyQuestGate, "Quest / state:", questPanel);
            AddRow(layout, 7, applyNotes, "Notes:", notes);

            var buttons = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.RightToLeft,
                Dock = DockStyle.Fill,
                AutoSize = true
            };
            var cancel = new Button { Text = "Cancel", Width = 95, DialogResult = DialogResult.Cancel };
            var apply = new Button { Text = "Apply", Width = 95 };
            apply.Click += Apply_Click;
            buttons.Controls.Add(cancel);
            buttons.Controls.Add(apply);
            layout.Controls.Add(buttons, 0, 8);
            layout.SetColumnSpan(buttons, 3);

            AcceptButton = apply;
            CancelButton = cancel;
            Controls.Add(layout);
        }

        private static void AddRow(TableLayoutPanel layout, int row, CheckBox apply, string label, Control editor)
        {
            apply.Text = "Set";
            apply.AutoSize = true;
            editor.Enabled = false;
            apply.CheckedChanged += (s, e) => editor.Enabled = apply.Checked;
            layout.Controls.Add(apply, 0, row);
            layout.Controls.Add(new Label { Text = label, AutoSize = true }, 1, row);
            layout.Controls.Add(editor, 2, row);
        }

        private void Apply_Click(object sender, EventArgs e)
        {
            if (!applyDropChance.Checked && !applyGuaranteed.Checked && !applyMinQuantity.Checked &&
                !applyMaxQuantity.Checked && !applyWeight.Checked && !applyQuestGate.Checked && !applyNotes.Checked)
            {
                MessageBox.Show("Select at least one field to apply.", "Nothing Selected",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme()
        {
            BackColor = Color.FromArgb(45, 45, 48);
            ForeColor = Color.White;
            foreach (Control control in GetAllControls(this))
            {
                control.ForeColor = control is Label label && label.ForeColor == Color.Silver
                    ? Color.Silver
                    : Color.White;
                if (control is TextBox || control is NumericUpDown || control is ComboBox)
                    control.BackColor = Color.FromArgb(30, 30, 30);
                else if (control is Button button)
                    button.BackColor = Color.FromArgb(60, 60, 60);
            }
        }

        private static IEnumerable<Control> GetAllControls(Control parent)
        {
            foreach (Control child in parent.Controls)
            {
                yield return child;
                foreach (Control descendant in GetAllControls(child)) yield return descendant;
            }
        }

        private sealed class QuestChoice
        {
            public int? Id { get; set; }
            public string Label { get; set; }
            public override string ToString() => Label;
        }
    }
}
