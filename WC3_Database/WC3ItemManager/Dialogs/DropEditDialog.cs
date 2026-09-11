using System;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager.Dialogs
{
    /// <summary>
    /// Dialog for editing an existing unit-specific drop configuration
    /// </summary>
    public class DropEditDialog : Form
    {
        private readonly string _connectionString;
        private readonly UnitSpecificDrop _originalDrop;
        
        // Controls
        private Label lblItemName;
        private Label lblItemCode;
        private NumericUpDown nudDropChance;
        private CheckBox chkGuaranteed;
        private NumericUpDown nudMinQty;
        private NumericUpDown nudMaxQty;
        private NumericUpDown nudWeight;
        private ComboBox cmbRequiredQuest;
        private ComboBox cmbRequiredQuestState;
        private TextBox txtNotes;
        private Button btnOK;
        private Button btnCancel;
        
        public UnitSpecificDrop Result { get; private set; }

        public DropEditDialog(string connectionString, UnitSpecificDrop drop)
        {
            _connectionString = connectionString;
            _originalDrop = drop;
            
            InitializeComponent();
            LoadDropData();
            ApplyDarkTheme();
        }

        private void InitializeComponent()
        {
            this.Text = "Edit Drop Configuration";
            this.Size = new Size(500, 430);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            int y = 15;
            int labelWidth = 100;
            int controlX = 115;

            // Item info (read-only display)
            var lblItemLabel = new Label
            {
                Text = "Item:",
                Location = new Point(15, y),
                Width = labelWidth,
                Font = new Font(this.Font, FontStyle.Bold)
            };
            this.Controls.Add(lblItemLabel);

            lblItemName = new Label
            {
                Location = new Point(controlX, y),
                Width = 270,
                AutoSize = false
            };
            this.Controls.Add(lblItemName);
            y += 25;

            lblItemCode = new Label
            {
                Location = new Point(controlX, y),
                Width = 100,
                ForeColor = Color.Gray
            };
            this.Controls.Add(lblItemCode);
            y += 35;

            // Drop Chance
            var lblChance = new Label { Text = "Drop Chance %:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblChance);

            nudDropChance = new NumericUpDown
            {
                Location = new Point(controlX, y),
                Width = 80,
                DecimalPlaces = 1,
                Minimum = 0,
                Maximum = 100,
                Increment = 0.5m
            };
            this.Controls.Add(nudDropChance);

            chkGuaranteed = new CheckBox
            {
                Text = "Guaranteed",
                Location = new Point(210, y),
                AutoSize = true,
                ForeColor = Color.Lime
            };
            chkGuaranteed.CheckedChanged += ChkGuaranteed_CheckedChanged;
            this.Controls.Add(chkGuaranteed);
            y += 35;

            // Quantity
            var lblMinQty = new Label { Text = "Min Quantity:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblMinQty);

            nudMinQty = new NumericUpDown
            {
                Location = new Point(controlX, y),
                Width = 60,
                Minimum = 1,
                Maximum = 99
            };
            this.Controls.Add(nudMinQty);

            var lblMaxQty = new Label { Text = "Max:", Location = new Point(190, y + 3), AutoSize = true };
            this.Controls.Add(lblMaxQty);

            nudMaxQty = new NumericUpDown
            {
                Location = new Point(230, y),
                Width = 60,
                Minimum = 1,
                Maximum = 99
            };
            this.Controls.Add(nudMaxQty);
            y += 35;

            // Weight
            var lblWeight = new Label { Text = "Weight:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblWeight);

            nudWeight = new NumericUpDown
            {
                Location = new Point(controlX, y),
                Width = 80,
                Minimum = 1,
                Maximum = 10000,
                Value = 100
            };
            this.Controls.Add(nudWeight);

            var lblWeightHelp = new Label
            {
                Text = "(relative weight for weighted selection)",
                Location = new Point(210, y + 3),
                AutoSize = true,
                ForeColor = Color.Gray
            };
            this.Controls.Add(lblWeightHelp);
            y += 35;

            var lblQuest = new Label { Text = "Quest gate:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblQuest);

            cmbRequiredQuest = new ComboBox
            {
                Location = new Point(controlX, y),
                Width = 350,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbRequiredQuest.SelectedIndexChanged += (s, e) =>
                cmbRequiredQuestState.Enabled = (cmbRequiredQuest.SelectedItem as QuestChoice)?.Id != null;
            this.Controls.Add(cmbRequiredQuest);
            y += 35;

            var lblQuestState = new Label { Text = "Required state:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblQuestState);

            cmbRequiredQuestState = new ComboBox
            {
                Location = new Point(controlX, y),
                Width = 130,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbRequiredQuestState.Items.AddRange(new object[] { "active", "discovered" });
            cmbRequiredQuestState.SelectedIndex = 0;
            this.Controls.Add(cmbRequiredQuestState);
            y += 35;

            // Notes
            var lblNotes = new Label { Text = "Notes:", Location = new Point(15, y + 3), Width = labelWidth };
            this.Controls.Add(lblNotes);

            txtNotes = new TextBox
            {
                Location = new Point(controlX, y),
                Width = 350,
                Height = 60,
                Multiline = true
            };
            this.Controls.Add(txtNotes);
            y += 75;

            // Buttons
            btnOK = new Button
            {
                Text = "Save",
                Location = new Point(200, y),
                Width = 90,
                Height = 30,
                DialogResult = DialogResult.None,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOK.Click += BtnOK_Click;
            this.Controls.Add(btnOK);

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(300, y),
                Width = 90,
                Height = 30,
                DialogResult = DialogResult.Cancel
            };
            this.Controls.Add(btnCancel);

            this.AcceptButton = btnOK;
            this.CancelButton = btnCancel;
        }

        private void LoadDropData()
        {
            LoadQuestChoices();
            lblItemName.Text = _originalDrop.ItemName;
            lblItemCode.Text = $"({_originalDrop.ItemCode})";
            nudDropChance.Value = _originalDrop.DropChance;
            chkGuaranteed.Checked = _originalDrop.IsGuaranteed;
            nudMinQty.Value = _originalDrop.MinQuantity;
            nudMaxQty.Value = _originalDrop.MaxQuantity;
            nudWeight.Value = _originalDrop.Weight;
            cmbRequiredQuestState.SelectedItem = _originalDrop.RequiredQuestState ?? "active";
            txtNotes.Text = _originalDrop.Notes ?? "";
            
            // Disable chance if guaranteed
            nudDropChance.Enabled = !_originalDrop.IsGuaranteed;
        }

        private void LoadQuestChoices()
        {
            cmbRequiredQuest.Items.Clear();
            cmbRequiredQuest.Items.Add(new QuestChoice { Label = "None" });

            var quests = new QuestDesignerRepository(_connectionString).GetQuests()
                .Where(q => q.Enabled)
                .OrderBy(q => q.Title)
                .ThenBy(q => q.QuestName);
            foreach (var quest in quests)
            {
                cmbRequiredQuest.Items.Add(new QuestChoice
                {
                    Id = quest.Id,
                    Label = $"{quest.Title} [{quest.QuestName}]"
                });
            }

            var selected = cmbRequiredQuest.Items.Cast<QuestChoice>()
                .FirstOrDefault(q => q.Id == _originalDrop.RequiredQuestId);
            cmbRequiredQuest.SelectedItem = selected ?? cmbRequiredQuest.Items[0];
        }

        private void ChkGuaranteed_CheckedChanged(object sender, EventArgs e)
        {
            nudDropChance.Enabled = !chkGuaranteed.Checked;
            if (chkGuaranteed.Checked)
            {
                nudDropChance.Value = 100;
            }
        }

        private void BtnOK_Click(object sender, EventArgs e)
        {
            if (nudMinQty.Value > nudMaxQty.Value)
            {
                MessageBox.Show("Min quantity cannot be greater than max quantity.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // Create updated drop object
            Result = new UnitSpecificDrop
            {
                Id = _originalDrop.Id,
                UnitCode = _originalDrop.UnitCode,
                ItemCode = _originalDrop.ItemCode,
                ItemName = _originalDrop.ItemName,
                DropChance = nudDropChance.Value,
                MinQuantity = (int)nudMinQty.Value,
                MaxQuantity = (int)nudMaxQty.Value,
                IsGuaranteed = chkGuaranteed.Checked,
                Weight = (int)nudWeight.Value,
                RequiredQuestId = (cmbRequiredQuest.SelectedItem as QuestChoice)?.Id,
                RequiredQuestState = cmbRequiredQuestState.SelectedItem?.ToString() ?? "active",
                Notes = txtNotes.Text,
                Enabled = _originalDrop.Enabled
            };

            DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme()
        {
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;

            foreach (Control c in this.Controls)
            {
                if (c is TextBox || c is NumericUpDown)
                {
                    c.BackColor = Color.FromArgb(30, 30, 30);
                    c.ForeColor = Color.White;
                }
                else if (c is Button btn && btn.BackColor != Color.FromArgb(0, 122, 204))
                {
                    btn.BackColor = Color.FromArgb(60, 60, 60);
                    btn.ForeColor = Color.White;
                    btn.FlatStyle = FlatStyle.Flat;
                }
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
