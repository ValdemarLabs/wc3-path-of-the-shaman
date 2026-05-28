using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Dialogs;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for managing gather nodes (herbs/items and veins/units)
    /// </summary>
    public class GatherNodeForm : Form
    {
        private sealed class OwnerPlayerOption
        {
            public int RawValue { get; set; }
            public string Label { get; set; }

            public override string ToString() => Label;
        }

        private readonly string _connectionString;
        private readonly GatherNodeRepository _repository;
        
        // Main layout
        private TabControl tabMain;
        private TabPage tabItemNodes;
        private TabPage tabUnitNodes;
        private TabPage tabSpawnPoints;
        private Label lblStatus;
        
        // Item nodes tab controls
        private DataGridView dgvItemNodes;
        private Panel pnlItemDetails;
        private TextBox txtItemSearch;
        private ComboBox cmbItemCategory;
        private CheckBox chkItemEnabledOnly;
        
        // Item details
        private TextBox txtItemCode;
        private TextBox txtItemNodeName;
        private ComboBox cmbItemNodeCategory;
        private NumericUpDown numItemSpawnWeight;
        private Label lblItemSpawnWeightHelp;
        private NumericUpDown numItemRespawnMin;
        private NumericUpDown numItemRespawnMax;
        private NumericUpDown numItemMaxPerZone;
        private NumericUpDown numItemSkillRequired;
        private ComboBox cmbItemProfession;
        private CheckBox chkItemPreventWaterSpawn;
        private CheckBox chkItemGlow;
        private NumericUpDown numItemGlowR;
        private NumericUpDown numItemGlowG;
        private NumericUpDown numItemGlowB;
        private NumericUpDown numItemGlowScale;
        private NumericUpDown numItemGlowHeight;
        private Panel pnlItemGlowPreview;
        private CheckBox chkItemIsRare;
        private CheckBox chkItemEnabled;
        private TextBox txtItemNotes;
        private DataGridView dgvItemZones;
        
        // Unit nodes tab controls
        private DataGridView dgvUnitNodes;
        private Panel pnlUnitDetails;
        private TextBox txtUnitSearch;
        private ComboBox cmbUnitCategory;
        private CheckBox chkUnitEnabledOnly;
        
        // Unit details
        private TextBox txtUnitCode;
        private TextBox txtUnitNodeName;
        private ComboBox cmbUnitNodeCategory;
        private NumericUpDown numUnitSpawnWeight;
        private Label lblUnitSpawnWeightHelp;
        private NumericUpDown numUnitRespawnMin;
        private NumericUpDown numUnitRespawnMax;
        private NumericUpDown numUnitMaxPerZone;
        private NumericUpDown numUnitSkillRequired;
        private ComboBox cmbUnitProfession;
        private NumericUpDown numUnitHarvestYieldMin;
        private NumericUpDown numUnitHarvestYieldMax;
        private NumericUpDown numUnitGatherSuccessChance;
        private NumericUpDown numUnitMainDropGroupChance;
        private NumericUpDown numUnitSecondaryDropGroupChance;
        private ComboBox cmbUnitSpecialBehavior;
        private NumericUpDown numUnitSpecialBehaviorChance;
        private CheckBox chkUnitPreventWaterSpawn;
        private ComboBox cmbUnitOwnerPlayer;
        private Label lblUnitOwnerPlayerHelp;
        private CheckBox chkUnitGlow;
        private NumericUpDown numUnitGlowR;
        private NumericUpDown numUnitGlowG;
        private NumericUpDown numUnitGlowB;
        private NumericUpDown numUnitGlowScale;
        private NumericUpDown numUnitGlowHeight;
        private Panel pnlUnitGlowPreview;
        private CheckBox chkUnitIsRare;
        private CheckBox chkUnitEnabled;
        private TextBox txtUnitNotes;
        private DataGridView dgvUnitZones;
        private DataGridView dgvUnitDrops;
        
        // Spawn points tab controls
        private DataGridView dgvSpawnPointGroups;
        private DataGridView dgvSpawnPoints;
        private TextBox txtSpawnPointSearch;
        private ComboBox cmbSpawnPointZone;
        private ComboBox cmbSpawnPointGroupFilter;

        // Buttons
        private Button btnItemSave;
        private Button btnItemAdd;
        private Button btnItemDelete;
        private Button btnItemEnable;
        private Button btnItemDisable;
        private Button btnItemBulkCategory;
        private Button btnItemMoveUp;
        private Button btnItemMoveDown;
        private Button btnItemAddZone;
        private Button btnItemEditZone;
        private Button btnItemRemoveZone;
        private Button btnItemZoneEnable;
        private Button btnItemZoneDisable;
        
        private Button btnUnitSave;
        private Button btnUnitAdd;
        private Button btnUnitDelete;
        private Button btnUnitEnable;
        private Button btnUnitDisable;
        private Button btnUnitBulkCategory;
        private Button btnUnitMoveUp;
        private Button btnUnitMoveDown;
        private Button btnUnitAddZone;
        private Button btnUnitEditZone;
        private Button btnUnitRemoveZone;
        private Button btnUnitZoneEnable;
        private Button btnUnitZoneDisable;
        private Button btnUnitAddDrop;
        private Button btnUnitEditDrop;
        private Button btnUnitRemoveDrop;
        
        private Button btnSpawnGroupAdd;
        private Button btnSpawnGroupEdit;
        private Button btnSpawnGroupDelete;
        private Button btnSpawnPointAdd;
        private Button btnSpawnPointEdit;
        private Button btnSpawnPointDelete;
        private Button btnSpawnPointEnable;
        private Button btnSpawnPointDisable;
        private Button btnSpawnPointAutofill;
        
        // Data
        private GatherItemNode _currentItemNode;
        private GatherUnitNode _currentUnitNode;
        private GatherSpawnPointGroup _currentSpawnPointGroup;
        private List<GatherNodeCategory> _itemCategories;
        private List<GatherNodeCategory> _unitCategories;
        private bool _isLoading;
        
        public GatherNodeForm(string connectionString)
        {
            _connectionString = connectionString;
            _repository = new GatherNodeRepository(connectionString);
            
            InitializeComponent();
            LoadCategories();
            LoadItemNodes();
            LoadUnitNodes();
            LoadSpawnPointGroups();
            LoadSpawnPoints();
        }

        private void InitializeComponent()
        {
            this.Text = "Gather Node Management";
            this.Size = new Size(1400, 900);
            this.StartPosition = FormStartPosition.CenterParent;
            this.MinimumSize = new Size(1200, 700);

            // Tab control
            tabMain = new TabControl
            {
                Dock = DockStyle.Fill
            };

            // Create tabs
            CreateItemNodesTab();
            CreateUnitNodesTab();
            CreateSpawnPointsTab();

            tabMain.TabPages.Add(tabItemNodes);
            tabMain.TabPages.Add(tabUnitNodes);
            tabMain.TabPages.Add(tabSpawnPoints);

            // Status bar
            lblStatus = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 25,
                BackColor = Color.FromArgb(35, 35, 35),
                ForeColor = Color.LightGray,
                Padding = new Padding(5, 5, 0, 0)
            };

            this.Controls.Add(tabMain);
            this.Controls.Add(lblStatus);

            // Dark theme
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            ApplyDarkTheme(this);
        }

        #region Item Nodes Tab

        private void CreateItemNodesTab()
        {
            tabItemNodes = new TabPage("Item Nodes (Herbs)");
            tabItemNodes.BackColor = Color.FromArgb(45, 45, 45);

            var splitMain = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 450
            };

            // Left panel - list
            CreateItemListPanel(splitMain.Panel1);

            // Right panel - details
            CreateItemDetailsPanel(splitMain.Panel2);

            tabItemNodes.Controls.Add(splitMain);
        }

        private void CreateItemListPanel(Panel parent)
        {
            var pnlFilters = new Panel
            {
                Dock = DockStyle.Top,
                Height = 45,
                Padding = new Padding(5)
            };

            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 10), AutoSize = true };
            txtItemSearch = new TextBox { Location = new Point(55, 7), Width = 150 };
            txtItemSearch.TextChanged += (s, e) => FilterItemNodes();

            var lblCategory = new Label { Text = "Category:", Location = new Point(220, 10), AutoSize = true };
            cmbItemCategory = new ComboBox
            {
                Location = new Point(280, 7),
                Width = 130,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbItemCategory.SelectedIndexChanged += (s, e) => FilterItemNodes();

            chkItemEnabledOnly = new CheckBox
            {
                Text = "Enabled Only",
                Location = new Point(420, 8),
                AutoSize = true
            };
            chkItemEnabledOnly.CheckedChanged += (s, e) => FilterItemNodes();

            pnlFilters.Controls.AddRange(new Control[] { lblSearch, txtItemSearch, lblCategory, cmbItemCategory, chkItemEnabledOnly });

            // Grid
            dgvItemNodes = CreateDataGridView();
            dgvItemNodes.SelectionChanged += DgvItemNodes_SelectionChanged;

            // Buttons
            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnItemAdd = new Button { Text = "Add New", Width = 80 };
            btnItemAdd.Click += BtnItemAdd_Click;
            
            btnItemDelete = new Button { Text = "Delete", Width = 80 };
            btnItemDelete.Click += BtnItemDelete_Click;

            btnItemEnable = new Button { Text = "Enable", Width = 70 };
            btnItemEnable.Click += BtnItemEnable_Click;

            btnItemDisable = new Button { Text = "Disable", Width = 70 };
            btnItemDisable.Click += BtnItemDisable_Click;

            btnItemBulkCategory = new Button { Text = "Set Category", Width = 95 };
            btnItemBulkCategory.Click += BtnItemBulkCategory_Click;

            btnItemMoveUp = new Button { Text = "Move Up", Width = 80 };
            btnItemMoveUp.Click += BtnItemMoveUp_Click;

            btnItemMoveDown = new Button { Text = "Move Down", Width = 90 };
            btnItemMoveDown.Click += BtnItemMoveDown_Click;

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadItemNodes();

            pnlButtons.Controls.AddRange(new Control[] { btnItemAdd, btnItemDelete, btnItemEnable, btnItemDisable, btnItemBulkCategory, btnItemMoveUp, btnItemMoveDown, btnRefresh });

            parent.Controls.Add(dgvItemNodes);
            parent.Controls.Add(pnlButtons);
            parent.Controls.Add(pnlFilters);
        }

        private void CreateItemDetailsPanel(Panel parent)
        {
            pnlItemDetails = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(10)
            };

            int y = 10;
            int labelWidth = 110;

            // Item Code with picker buttons
            var pnlItemCode = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            txtItemCode = new TextBox { Width = 70, MaxLength = 4 };
            var btnPickHerb = new Button { Text = "📋", Width = 30, Height = 23, FlatStyle = FlatStyle.Flat };
            btnPickHerb.Click += BtnPickHerb_Click;
            var btnPickDbItem = new Button { Text = "🔍", Width = 30, Height = 23, FlatStyle = FlatStyle.Flat };
            btnPickDbItem.Click += BtnPickDbItem_Click;
            pnlItemCode.Controls.Add(txtItemCode);
            pnlItemCode.Controls.Add(btnPickHerb);
            pnlItemCode.Controls.Add(btnPickDbItem);
            AddLabelAndControl(pnlItemDetails, "Item Code:", ref y, labelWidth, pnlItemCode);

            // Node Name
            AddLabelAndControl(pnlItemDetails, "Node Name:", ref y, labelWidth,
                txtItemNodeName = new TextBox { Width = 200 });

            // Category
            cmbItemNodeCategory = new ComboBox { Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };
            AddLabelAndControl(pnlItemDetails, "Category:", ref y, labelWidth, cmbItemNodeCategory);

            // Spawn Weight
            numItemSpawnWeight = new NumericUpDown { Width = 80, Minimum = 1, Maximum = 10000, Value = 100 };
            AddLabelAndControl(pnlItemDetails, "Spawn Weight:", ref y, labelWidth, numItemSpawnWeight);
            lblItemSpawnWeightHelp = new Label
            {
                Location = new Point(10 + labelWidth, y - 2),
                Size = new Size(300, 32),
                ForeColor = Color.Gainsboro,
                Text = "Relative chance inside the same shared category pool. Example: 60 / 30 / 10 becomes 60% / 30% / 10%."
            };
            pnlItemDetails.Controls.Add(lblItemSpawnWeightHelp);
            y += 34;

            // Respawn Time
            var pnlRespawn = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            numItemRespawnMin = new NumericUpDown { Width = 70, Minimum = 1, Maximum = 9999, DecimalPlaces = 0 };
            numItemRespawnMax = new NumericUpDown { Width = 70, Minimum = 1, Maximum = 9999, DecimalPlaces = 0 };
            pnlRespawn.Controls.Add(numItemRespawnMin);
            pnlRespawn.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlRespawn.Controls.Add(numItemRespawnMax);
            pnlRespawn.Controls.Add(new Label { Text = " sec", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            AddLabelAndControl(pnlItemDetails, "Respawn Time:", ref y, labelWidth, pnlRespawn);

            // Max Per Zone
            numItemMaxPerZone = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100, Value = 5 };
            AddLabelAndControl(pnlItemDetails, "Max Per Zone:", ref y, labelWidth, numItemMaxPerZone);

            // Skill Required
            numItemSkillRequired = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 999 };
            AddLabelAndControl(pnlItemDetails, "Skill Required:", ref y, labelWidth, numItemSkillRequired);

            cmbItemProfession = new ComboBox
            {
                Width = 160,
                DropDownStyle = ComboBoxStyle.DropDownList,
                DisplayMember = nameof(GatherProfessionOption.Name),
                ValueMember = nameof(GatherProfessionOption.Id)
            };
            cmbItemProfession.Items.AddRange(GatherProfessionInfo.Options.Cast<object>().ToArray());
            cmbItemProfession.SelectedIndex = 0;
            AddLabelAndControl(pnlItemDetails, "Profession:", ref y, labelWidth, cmbItemProfession);

            chkItemPreventWaterSpawn = new CheckBox { Text = "Do not spawn in water / amphibious terrain", AutoSize = true };
            AddLabelAndControl(pnlItemDetails, "Terrain Filter:", ref y, labelWidth, chkItemPreventWaterSpawn);

            // Glow Effect
            var pnlGlow = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            chkItemGlow = new CheckBox { Text = "Enable Glow", AutoSize = true };
            chkItemGlow.CheckedChanged += (s, e) => UpdateItemGlowPreview();
            pnlGlow.Controls.Add(chkItemGlow);
            AddLabelAndControl(pnlItemDetails, "Glow Effect:", ref y, labelWidth, pnlGlow);

            // Glow Colors
            var pnlGlowColors = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            pnlGlowColors.Controls.Add(new Label { Text = "R:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numItemGlowR = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255 };
            numItemGlowR.ValueChanged += (s, e) => UpdateItemGlowPreview();
            pnlGlowColors.Controls.Add(numItemGlowR);
            pnlGlowColors.Controls.Add(new Label { Text = " G:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numItemGlowG = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255, Value = 255 };
            numItemGlowG.ValueChanged += (s, e) => UpdateItemGlowPreview();
            pnlGlowColors.Controls.Add(numItemGlowG);
            pnlGlowColors.Controls.Add(new Label { Text = " B:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numItemGlowB = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255 };
            numItemGlowB.ValueChanged += (s, e) => UpdateItemGlowPreview();
            pnlGlowColors.Controls.Add(numItemGlowB);
            pnlItemGlowPreview = new Panel { Width = 30, Height = 20, BorderStyle = BorderStyle.FixedSingle };
            pnlGlowColors.Controls.Add(pnlItemGlowPreview);
            AddLabelAndControl(pnlItemDetails, "Glow Color:", ref y, labelWidth, pnlGlowColors);

            numItemGlowScale = new NumericUpDown { Width = 60, Minimum = 0.1M, Maximum = 5, Value = 1.0M, DecimalPlaces = 1, Increment = 0.1M };
            AddLabelAndControl(pnlItemDetails, "Glow Scale:", ref y, labelWidth, numItemGlowScale);

            numItemGlowHeight = new NumericUpDown { Width = 70, Minimum = -500, Maximum = 500, Value = 0, DecimalPlaces = 0, Increment = 5 };
            AddLabelAndControl(pnlItemDetails, "Glow Height:", ref y, labelWidth, numItemGlowHeight);

            // Flags
            var pnlFlags = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            chkItemIsRare = new CheckBox { Text = "Is Rare", AutoSize = true };
            chkItemEnabled = new CheckBox { Text = "Enabled", AutoSize = true, Checked = true };
            pnlFlags.Controls.Add(chkItemIsRare);
            pnlFlags.Controls.Add(chkItemEnabled);
            AddLabelAndControl(pnlItemDetails, "Flags:", ref y, labelWidth, pnlFlags);

            // Notes
            txtItemNotes = new TextBox { Width = 300, Height = 50, Multiline = true };
            AddLabelAndControl(pnlItemDetails, "Notes:", ref y, labelWidth, txtItemNotes);

            y += 10;

            // Save button
            btnItemSave = new Button
            {
                Text = "Save Changes",
                Location = new Point(10, y),
                Width = 120,
                Height = 30,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnItemSave.Click += BtnItemSave_Click;
            pnlItemDetails.Controls.Add(btnItemSave);

            y += 50;

            // Zone Assignments section
            var lblZones = new Label
            {
                Text = "Zone Placements",
                Location = new Point(10, y),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };
            pnlItemDetails.Controls.Add(lblZones);
            y += 25;

            dgvItemZones = CreateDataGridView();
            dgvItemZones.Location = new Point(10, y);
            dgvItemZones.Size = new Size(400, 150);
            dgvItemZones.Dock = DockStyle.None;
            dgvItemZones.CellDoubleClick += DgvItemZones_CellDoubleClick;
            ConfigureZonePlacementGrid(dgvItemZones);
            pnlItemDetails.Controls.Add(dgvItemZones);

            y += 160;

            // Zone buttons
            var pnlZoneButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                AutoSize = true,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false
            };
            btnItemAddZone = new Button { Text = "Add Placement", Width = 100 };
            btnItemAddZone.Click += BtnItemAddZone_Click;
            btnItemEditZone = new Button { Text = "Edit", Width = 70 };
            btnItemEditZone.Click += BtnItemEditZone_Click;
            btnItemRemoveZone = new Button { Text = "Remove", Width = 80 };
            btnItemRemoveZone.Click += BtnItemRemoveZone_Click;
            btnItemZoneEnable = new Button { Text = "Enable", Width = 70 };
            btnItemZoneEnable.Click += BtnItemZoneEnable_Click;
            btnItemZoneDisable = new Button { Text = "Disable", Width = 70 };
            btnItemZoneDisable.Click += BtnItemZoneDisable_Click;
            pnlZoneButtons.Controls.AddRange(new Control[] { btnItemAddZone, btnItemEditZone, btnItemRemoveZone, btnItemZoneEnable, btnItemZoneDisable });
            pnlItemDetails.Controls.Add(pnlZoneButtons);

            parent.Controls.Add(pnlItemDetails);
        }

        #endregion

        #region Unit Nodes Tab

        private void CreateUnitNodesTab()
        {
            tabUnitNodes = new TabPage("Unit Nodes (Veins)");
            tabUnitNodes.BackColor = Color.FromArgb(45, 45, 45);

            var splitMain = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 450
            };

            // Left panel - list
            CreateUnitListPanel(splitMain.Panel1);

            // Right panel - details
            CreateUnitDetailsPanel(splitMain.Panel2);

            tabUnitNodes.Controls.Add(splitMain);
        }

        private void CreateUnitListPanel(Panel parent)
        {
            var pnlFilters = new Panel
            {
                Dock = DockStyle.Top,
                Height = 45,
                Padding = new Padding(5)
            };

            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 10), AutoSize = true };
            txtUnitSearch = new TextBox { Location = new Point(55, 7), Width = 150 };
            txtUnitSearch.TextChanged += (s, e) => FilterUnitNodes();

            var lblCategory = new Label { Text = "Category:", Location = new Point(220, 10), AutoSize = true };
            cmbUnitCategory = new ComboBox
            {
                Location = new Point(280, 7),
                Width = 130,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbUnitCategory.SelectedIndexChanged += (s, e) => FilterUnitNodes();

            chkUnitEnabledOnly = new CheckBox
            {
                Text = "Enabled Only",
                Location = new Point(420, 8),
                AutoSize = true
            };
            chkUnitEnabledOnly.CheckedChanged += (s, e) => FilterUnitNodes();

            pnlFilters.Controls.AddRange(new Control[] { lblSearch, txtUnitSearch, lblCategory, cmbUnitCategory, chkUnitEnabledOnly });

            // Grid
            dgvUnitNodes = CreateDataGridView();
            dgvUnitNodes.SelectionChanged += DgvUnitNodes_SelectionChanged;

            // Buttons
            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnUnitAdd = new Button { Text = "Add New", Width = 80 };
            btnUnitAdd.Click += BtnUnitAdd_Click;
            
            btnUnitDelete = new Button { Text = "Delete", Width = 80 };
            btnUnitDelete.Click += BtnUnitDelete_Click;

            btnUnitEnable = new Button { Text = "Enable", Width = 70 };
            btnUnitEnable.Click += BtnUnitEnable_Click;

            btnUnitDisable = new Button { Text = "Disable", Width = 70 };
            btnUnitDisable.Click += BtnUnitDisable_Click;

            btnUnitBulkCategory = new Button { Text = "Set Category", Width = 95 };
            btnUnitBulkCategory.Click += BtnUnitBulkCategory_Click;

            btnUnitMoveUp = new Button { Text = "Move Up", Width = 80 };
            btnUnitMoveUp.Click += BtnUnitMoveUp_Click;

            btnUnitMoveDown = new Button { Text = "Move Down", Width = 90 };
            btnUnitMoveDown.Click += BtnUnitMoveDown_Click;

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadUnitNodes();

            pnlButtons.Controls.AddRange(new Control[] { btnUnitAdd, btnUnitDelete, btnUnitEnable, btnUnitDisable, btnUnitBulkCategory, btnUnitMoveUp, btnUnitMoveDown, btnRefresh });

            parent.Controls.Add(dgvUnitNodes);
            parent.Controls.Add(pnlButtons);
            parent.Controls.Add(pnlFilters);
        }

        private void CreateUnitDetailsPanel(Panel parent)
        {
            pnlUnitDetails = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(10)
            };

            int y = 10;
            int labelWidth = 110;

            // Unit Code with picker buttons
            var pnlUnitCode = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            txtUnitCode = new TextBox { Width = 70, MaxLength = 4 };
            var btnPickVein = new Button { Text = "📋", Width = 30, Height = 23, FlatStyle = FlatStyle.Flat };
            btnPickVein.Click += BtnPickVein_Click;
            var btnPickDbUnit = new Button { Text = "🔍", Width = 30, Height = 23, FlatStyle = FlatStyle.Flat };
            btnPickDbUnit.Click += BtnPickDbUnit_Click;
            pnlUnitCode.Controls.Add(txtUnitCode);
            pnlUnitCode.Controls.Add(btnPickVein);
            pnlUnitCode.Controls.Add(btnPickDbUnit);
            AddLabelAndControl(pnlUnitDetails, "Unit Code:", ref y, labelWidth, pnlUnitCode);

            // Node Name
            AddLabelAndControl(pnlUnitDetails, "Node Name:", ref y, labelWidth,
                txtUnitNodeName = new TextBox { Width = 200 });

            // Category
            cmbUnitNodeCategory = new ComboBox { Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };
            AddLabelAndControl(pnlUnitDetails, "Category:", ref y, labelWidth, cmbUnitNodeCategory);

            // Spawn Weight
            numUnitSpawnWeight = new NumericUpDown { Width = 80, Minimum = 1, Maximum = 10000, Value = 100 };
            AddLabelAndControl(pnlUnitDetails, "Spawn Weight:", ref y, labelWidth, numUnitSpawnWeight);
            lblUnitSpawnWeightHelp = new Label
            {
                Location = new Point(10 + labelWidth, y - 2),
                Size = new Size(300, 32),
                ForeColor = Color.Gainsboro,
                Text = "Relative chance inside the same shared category pool. Example: 60 / 30 / 10 becomes 60% / 30% / 10%."
            };
            pnlUnitDetails.Controls.Add(lblUnitSpawnWeightHelp);
            y += 34;

            // Respawn Time
            var pnlRespawn = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            numUnitRespawnMin = new NumericUpDown { Width = 70, Minimum = 1, Maximum = 9999, DecimalPlaces = 0 };
            numUnitRespawnMax = new NumericUpDown { Width = 70, Minimum = 1, Maximum = 9999, DecimalPlaces = 0 };
            pnlRespawn.Controls.Add(numUnitRespawnMin);
            pnlRespawn.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlRespawn.Controls.Add(numUnitRespawnMax);
            pnlRespawn.Controls.Add(new Label { Text = " sec", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            AddLabelAndControl(pnlUnitDetails, "Respawn Time:", ref y, labelWidth, pnlRespawn);

            // Max Per Zone
            numUnitMaxPerZone = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100, Value = 3 };
            AddLabelAndControl(pnlUnitDetails, "Max Per Zone:", ref y, labelWidth, numUnitMaxPerZone);

            // Skill Required
            numUnitSkillRequired = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 999 };
            AddLabelAndControl(pnlUnitDetails, "Skill Required:", ref y, labelWidth, numUnitSkillRequired);

            cmbUnitProfession = new ComboBox
            {
                Width = 160,
                DropDownStyle = ComboBoxStyle.DropDownList,
                DisplayMember = nameof(GatherProfessionOption.Name),
                ValueMember = nameof(GatherProfessionOption.Id)
            };
            cmbUnitProfession.Items.AddRange(GatherProfessionInfo.Options.Cast<object>().ToArray());
            cmbUnitProfession.SelectedIndex = 0;
            AddLabelAndControl(pnlUnitDetails, "Profession:", ref y, labelWidth, cmbUnitProfession);

            var unitHarvestToolTip = new ToolTip();

            var pnlHarvestYield = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            numUnitHarvestYieldMin = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 999, Value = 3 };
            numUnitHarvestYieldMax = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 999, Value = 6 };
            pnlHarvestYield.Controls.Add(numUnitHarvestYieldMin);
            pnlHarvestYield.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlHarvestYield.Controls.Add(numUnitHarvestYieldMax);
            AddLabelAndControl(pnlUnitDetails, "Main Reward Pool:", ref y, labelWidth, pnlHarvestYield);
            unitHarvestToolTip.SetToolTip(pnlHarvestYield, "Total number of main harvest rewards available on this node before it is depleted.");

            numUnitGatherSuccessChance = new NumericUpDown { Width = 70, Minimum = 0, Maximum = 100, Value = 100 };
            AddLabelAndControl(pnlUnitDetails, "Successful Hit %:", ref y, labelWidth, numUnitGatherSuccessChance);
            unitHarvestToolTip.SetToolTip(numUnitGatherSuccessChance, "Chance that one valid mining hit produces a harvest result.");

            numUnitMainDropGroupChance = new NumericUpDown { Width = 70, Minimum = 0, Maximum = 100, Value = 100 };
            AddLabelAndControl(pnlUnitDetails, "Main Drop %:", ref y, labelWidth, numUnitMainDropGroupChance);
            unitHarvestToolTip.SetToolTip(numUnitMainDropGroupChance, "After a successful hit, chance to roll one Main reward.");

            numUnitSecondaryDropGroupChance = new NumericUpDown { Width = 70, Minimum = 0, Maximum = 100, Value = 25 };
            AddLabelAndControl(pnlUnitDetails, "Secondary Drop %:", ref y, labelWidth, numUnitSecondaryDropGroupChance);
            unitHarvestToolTip.SetToolTip(numUnitSecondaryDropGroupChance, "After a successful main reward, chance to also roll one Secondary reward.");

            var lblUnitHarvestHelp = new Label
            {
                Text = "Main Reward Pool is the node's total main yield. Harvest Rewards below set the per-hit reward amounts.",
                Location = new Point(labelWidth + 20, y),
                Size = new Size(360, 34),
                ForeColor = Color.Gainsboro
            };
            pnlUnitDetails.Controls.Add(lblUnitHarvestHelp);
            y += 40;

            cmbUnitSpecialBehavior = new ComboBox
            {
                Width = 180,
                DropDownStyle = ComboBoxStyle.DropDownList,
                DisplayMember = nameof(GatherUnitSpecialBehaviorOption.Name),
                ValueMember = nameof(GatherUnitSpecialBehaviorOption.Id)
            };
            cmbUnitSpecialBehavior.Items.AddRange(GatherUnitSpecialBehaviorInfo.Options.Cast<object>().ToArray());
            cmbUnitSpecialBehavior.SelectedIndex = 0;
            AddLabelAndControl(pnlUnitDetails, "Special Behavior:", ref y, labelWidth, cmbUnitSpecialBehavior);

            numUnitSpecialBehaviorChance = new NumericUpDown { Width = 70, Minimum = 0, Maximum = 100, Value = 20 };
            AddLabelAndControl(pnlUnitDetails, "Special Chance %:", ref y, labelWidth, numUnitSpecialBehaviorChance);

            chkUnitPreventWaterSpawn = new CheckBox { Text = "Do not spawn in water / amphibious terrain", AutoSize = true };
            AddLabelAndControl(pnlUnitDetails, "Terrain Filter:", ref y, labelWidth, chkUnitPreventWaterSpawn);

            // Owner Player
            cmbUnitOwnerPlayer = new ComboBox
            {
                Width = 220,
                DropDownStyle = ComboBoxStyle.DropDownList,
                DisplayMember = nameof(OwnerPlayerOption.Label),
                ValueMember = nameof(OwnerPlayerOption.RawValue)
            };
            cmbUnitOwnerPlayer.Items.AddRange(CreateOwnerPlayerOptions().Cast<object>().ToArray());
            AddLabelAndControl(pnlUnitDetails, "Owner Player:", ref y, labelWidth, cmbUnitOwnerPlayer);
            lblUnitOwnerPlayerHelp = new Label
            {
                Location = new Point(10 + labelWidth, y - 2),
                Size = new Size(360, 32),
                ForeColor = Color.Gainsboro,
                Text = "Uses Warcraft slot names. Example: Player 24 is exported as Player(23). Neutral owners are listed separately."
            };
            pnlUnitDetails.Controls.Add(lblUnitOwnerPlayerHelp);
            y += 34;

            // Glow Effect
            var pnlGlow = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            chkUnitGlow = new CheckBox { Text = "Enable Glow", AutoSize = true, Checked = true };
            chkUnitGlow.CheckedChanged += (s, e) => UpdateUnitGlowPreview();
            pnlGlow.Controls.Add(chkUnitGlow);
            AddLabelAndControl(pnlUnitDetails, "Glow Effect:", ref y, labelWidth, pnlGlow);

            // Glow Colors
            var pnlGlowColors = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            pnlGlowColors.Controls.Add(new Label { Text = "R:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numUnitGlowR = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255, Value = 255 };
            numUnitGlowR.ValueChanged += (s, e) => UpdateUnitGlowPreview();
            pnlGlowColors.Controls.Add(numUnitGlowR);
            pnlGlowColors.Controls.Add(new Label { Text = " G:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numUnitGlowG = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255, Value = 200 };
            numUnitGlowG.ValueChanged += (s, e) => UpdateUnitGlowPreview();
            pnlGlowColors.Controls.Add(numUnitGlowG);
            pnlGlowColors.Controls.Add(new Label { Text = " B:", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            numUnitGlowB = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 255 };
            numUnitGlowB.ValueChanged += (s, e) => UpdateUnitGlowPreview();
            pnlGlowColors.Controls.Add(numUnitGlowB);
            pnlUnitGlowPreview = new Panel { Width = 30, Height = 20, BorderStyle = BorderStyle.FixedSingle };
            pnlGlowColors.Controls.Add(pnlUnitGlowPreview);
            AddLabelAndControl(pnlUnitDetails, "Glow Color:", ref y, labelWidth, pnlGlowColors);

            // Glow Scale
            numUnitGlowScale = new NumericUpDown { Width = 60, Minimum = 0.1M, Maximum = 5, Value = 1.5M, DecimalPlaces = 1, Increment = 0.1M };
            AddLabelAndControl(pnlUnitDetails, "Glow Scale:", ref y, labelWidth, numUnitGlowScale);

            // Glow Height
            numUnitGlowHeight = new NumericUpDown { Width = 70, Minimum = -500, Maximum = 500, Value = 0, DecimalPlaces = 0, Increment = 5 };
            AddLabelAndControl(pnlUnitDetails, "Glow Height:", ref y, labelWidth, numUnitGlowHeight);

            // Flags
            var pnlFlags = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
            chkUnitIsRare = new CheckBox { Text = "Is Rare", AutoSize = true };
            chkUnitEnabled = new CheckBox { Text = "Enabled", AutoSize = true, Checked = true };
            pnlFlags.Controls.Add(chkUnitIsRare);
            pnlFlags.Controls.Add(chkUnitEnabled);
            AddLabelAndControl(pnlUnitDetails, "Flags:", ref y, labelWidth, pnlFlags);

            // Notes
            txtUnitNotes = new TextBox { Width = 300, Height = 50, Multiline = true };
            AddLabelAndControl(pnlUnitDetails, "Notes:", ref y, labelWidth, txtUnitNotes);

            y += 10;

            // Save button
            btnUnitSave = new Button
            {
                Text = "Save Changes",
                Location = new Point(10, y),
                Width = 120,
                Height = 30,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnUnitSave.Click += BtnUnitSave_Click;
            pnlUnitDetails.Controls.Add(btnUnitSave);

            y += 50;

            // Zone Assignments section
            var lblZones = new Label
            {
                Text = "Zone Placements",
                Location = new Point(10, y),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };
            pnlUnitDetails.Controls.Add(lblZones);
            y += 25;

            dgvUnitZones = CreateDataGridView();
            dgvUnitZones.Location = new Point(10, y);
            dgvUnitZones.Size = new Size(400, 150);
            dgvUnitZones.Dock = DockStyle.None;
            dgvUnitZones.CellDoubleClick += DgvUnitZones_CellDoubleClick;
            ConfigureZonePlacementGrid(dgvUnitZones);
            pnlUnitDetails.Controls.Add(dgvUnitZones);

            y += 160;

            // Zone buttons
            var pnlZoneButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                Size = new Size(620, 36),
                AutoSize = false,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false
            };
            btnUnitAddZone = new Button { Text = "Add Placement", Width = 100 };
            btnUnitAddZone.Click += BtnUnitAddZone_Click;
            btnUnitEditZone = new Button { Text = "Edit", Width = 70 };
            btnUnitEditZone.Click += BtnUnitEditZone_Click;
            btnUnitRemoveZone = new Button { Text = "Remove", Width = 80 };
            btnUnitRemoveZone.Click += BtnUnitRemoveZone_Click;
            btnUnitZoneEnable = new Button { Text = "Enable", Width = 70 };
            btnUnitZoneEnable.Click += BtnUnitZoneEnable_Click;
            btnUnitZoneDisable = new Button { Text = "Disable", Width = 70 };
            btnUnitZoneDisable.Click += BtnUnitZoneDisable_Click;
            pnlZoneButtons.Controls.AddRange(new Control[] { btnUnitAddZone, btnUnitEditZone, btnUnitRemoveZone, btnUnitZoneEnable, btnUnitZoneDisable });
            pnlUnitDetails.Controls.Add(pnlZoneButtons);

            y = pnlZoneButtons.Bottom + 16;

            var lblDrops = new Label
            {
                Text = "Harvest Rewards",
                Location = new Point(10, y),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };
            pnlUnitDetails.Controls.Add(lblDrops);
            y += 25;

            var lblDropHelp = new Label
            {
                Text = "Per-hit Qty is granted on one successful harvest. Main rewards consume the Main Reward Pool; Secondary rewards are bonus rolls.",
                Location = new Point(10, y),
                Size = new Size(600, 32),
                ForeColor = Color.Gainsboro
            };
            pnlUnitDetails.Controls.Add(lblDropHelp);
            y += 36;

            dgvUnitDrops = CreateDataGridView();
            dgvUnitDrops.Location = new Point(10, y);
            dgvUnitDrops.Size = new Size(600, 160);
            dgvUnitDrops.Dock = DockStyle.None;
            dgvUnitDrops.ReadOnly = true;
            dgvUnitDrops.MultiSelect = false;
            dgvUnitDrops.AutoGenerateColumns = false;
            dgvUnitDrops.CellDoubleClick += DgvUnitDrops_CellDoubleClick;
            ConfigureUnitDropGrid(dgvUnitDrops);
            pnlUnitDetails.Controls.Add(dgvUnitDrops);
            y = dgvUnitDrops.Bottom + 12;

            var pnlDropButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                Size = new Size(420, 36),
                AutoSize = false,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false
            };
            btnUnitAddDrop = new Button { Text = "Add Reward", Width = 95 };
            btnUnitAddDrop.Click += BtnUnitAddDrop_Click;
            btnUnitEditDrop = new Button { Text = "Edit Reward", Width = 95 };
            btnUnitEditDrop.Click += BtnUnitEditDrop_Click;
            btnUnitRemoveDrop = new Button { Text = "Remove", Width = 80 };
            btnUnitRemoveDrop.Click += BtnUnitRemoveDrop_Click;
            pnlDropButtons.Controls.AddRange(new Control[] { btnUnitAddDrop, btnUnitEditDrop, btnUnitRemoveDrop });
            pnlUnitDetails.Controls.Add(pnlDropButtons);

            parent.Controls.Add(pnlUnitDetails);
        }

        #endregion

        #region Spawn Points Tab

        private void CreateSpawnPointsTab()
        {
            tabSpawnPoints = new TabPage("Spawn Points");
            tabSpawnPoints.BackColor = Color.FromArgb(45, 45, 45);

            var splitMain = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 500
            };

            // Left panel - list
            CreateSpawnPointListPanel(splitMain.Panel1);

            var splitRight = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 260
            };

            CreateSpawnPointGroupPanel(splitRight.Panel1);

            var lblInfo = new Label
            {
                Text = "Groups are the source of truth for targeted placement.\nUse Random in Zone for broad spawning, or Spawn Group to target selected rect groups.",
                Dock = DockStyle.Top,
                Height = 70,
                Padding = new Padding(10),
                ForeColor = Color.LightGray
            };
            splitRight.Panel2.Controls.Add(lblInfo);

            splitMain.Panel2.Controls.Add(splitRight);

            tabSpawnPoints.Controls.Add(splitMain);
        }

        private void CreateSpawnPointGroupPanel(Panel parent)
        {
            var lblGroups = new Label
            {
                Text = "Spawn Groups",
                Dock = DockStyle.Top,
                Height = 28,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                Padding = new Padding(8, 4, 0, 0)
            };

            dgvSpawnPointGroups = CreateDataGridView();
            dgvSpawnPointGroups.SelectionChanged += DgvSpawnPointGroups_SelectionChanged;

            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnSpawnGroupAdd = new Button { Text = "Add Group", Width = 90 };
            btnSpawnGroupAdd.Click += BtnSpawnGroupAdd_Click;
            btnSpawnGroupEdit = new Button { Text = "Edit Group", Width = 90 };
            btnSpawnGroupEdit.Click += BtnSpawnGroupEdit_Click;
            btnSpawnGroupDelete = new Button { Text = "Delete Group", Width = 100 };
            btnSpawnGroupDelete.Click += BtnSpawnGroupDelete_Click;

            pnlButtons.Controls.AddRange(new Control[] { btnSpawnGroupAdd, btnSpawnGroupEdit, btnSpawnGroupDelete });

            parent.Controls.Add(dgvSpawnPointGroups);
            parent.Controls.Add(pnlButtons);
            parent.Controls.Add(lblGroups);
        }

        private void CreateSpawnPointListPanel(Panel parent)
        {
            var pnlFilters = new Panel
            {
                Dock = DockStyle.Top,
                Height = 45,
                Padding = new Padding(5)
            };

            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 10), AutoSize = true };
            txtSpawnPointSearch = new TextBox { Location = new Point(55, 7), Width = 150 };
            txtSpawnPointSearch.TextChanged += (s, e) => FilterSpawnPoints();

            var lblZone = new Label { Text = "Zone:", Location = new Point(220, 10), AutoSize = true };
            cmbSpawnPointZone = new ComboBox
            {
                Location = new Point(260, 7),
                Width = 130,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbSpawnPointZone.SelectedIndexChanged += (s, e) => FilterSpawnPoints();

            var lblGroup = new Label { Text = "Group:", Location = new Point(405, 10), AutoSize = true };
            cmbSpawnPointGroupFilter = new ComboBox
            {
                Location = new Point(455, 7),
                Width = 180,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbSpawnPointGroupFilter.SelectedIndexChanged += (s, e) => FilterSpawnPoints();

            pnlFilters.Controls.AddRange(new Control[] { lblSearch, txtSpawnPointSearch, lblZone, cmbSpawnPointZone, lblGroup, cmbSpawnPointGroupFilter });

            // Grid
            dgvSpawnPoints = CreateDataGridView();

            // Buttons
            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnSpawnPointAdd = new Button { Text = "Add New", Width = 80 };
            btnSpawnPointAdd.Click += BtnSpawnPointAdd_Click;
            
            btnSpawnPointEdit = new Button { Text = "Edit", Width = 80 };
            btnSpawnPointEdit.Click += BtnSpawnPointEdit_Click;
            
            btnSpawnPointDelete = new Button { Text = "Delete", Width = 80 };
            btnSpawnPointDelete.Click += BtnSpawnPointDelete_Click;

            btnSpawnPointEnable = new Button { Text = "Enable", Width = 70 };
            btnSpawnPointEnable.Click += BtnSpawnPointEnable_Click;

            btnSpawnPointDisable = new Button { Text = "Disable", Width = 70 };
            btnSpawnPointDisable.Click += BtnSpawnPointDisable_Click;

            btnSpawnPointAutofill = new Button { Text = "Autofill", Width = 80 };
            btnSpawnPointAutofill.Click += BtnSpawnPointAutofill_Click;

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadSpawnPoints();

            pnlButtons.Controls.AddRange(new Control[] { btnSpawnPointAdd, btnSpawnPointEdit, btnSpawnPointDelete, btnSpawnPointEnable, btnSpawnPointDisable, btnSpawnPointAutofill, btnRefresh });

            parent.Controls.Add(dgvSpawnPoints);
            parent.Controls.Add(pnlButtons);
            parent.Controls.Add(pnlFilters);
        }

        #endregion

        #region Data Loading

        private IEnumerable<OwnerPlayerOption> CreateOwnerPlayerOptions()
        {
            for (int slot = 1; slot <= 24; slot++)
            {
                yield return new OwnerPlayerOption
                {
                    RawValue = slot - 1,
                    Label = $"Player {slot}"
                };
            }

            yield return new OwnerPlayerOption { RawValue = 24, Label = "Neutral Passive" };
            yield return new OwnerPlayerOption { RawValue = 25, Label = "Neutral Hostile" };
            yield return new OwnerPlayerOption { RawValue = 27, Label = "Neutral Victim" };
        }

        private void SetSelectedOwnerPlayer(int rawOwnerPlayer)
        {
            foreach (var item in cmbUnitOwnerPlayer.Items.Cast<object>())
            {
                if (item is OwnerPlayerOption option && option.RawValue == rawOwnerPlayer)
                {
                    cmbUnitOwnerPlayer.SelectedItem = option;
                    return;
                }
            }

            cmbUnitOwnerPlayer.SelectedIndex = 0;
        }

        private int GetSelectedOwnerPlayer()
        {
            if (cmbUnitOwnerPlayer.SelectedItem is OwnerPlayerOption option)
            {
                return option.RawValue;
            }

            return 24;
        }

        private void SetSelectedProfession(ComboBox comboBox, int professionId)
        {
            foreach (var item in comboBox.Items.Cast<object>())
            {
                if (item is GatherProfessionOption option && option.Id == professionId)
                {
                    comboBox.SelectedItem = option;
                    return;
                }
            }

            comboBox.SelectedIndex = 0;
        }

        private int GetSelectedProfession(ComboBox comboBox)
        {
            if (comboBox.SelectedItem is GatherProfessionOption option)
            {
                return option.Id;
            }

            return GatherProfessionInfo.None;
        }

        private void SetSelectedSpecialBehavior(int behaviorId)
        {
            foreach (var item in cmbUnitSpecialBehavior.Items)
            {
                if (item is GatherUnitSpecialBehaviorOption option && option.Id == behaviorId)
                {
                    cmbUnitSpecialBehavior.SelectedItem = item;
                    return;
                }
            }

            if (cmbUnitSpecialBehavior.Items.Count > 0)
            {
                cmbUnitSpecialBehavior.SelectedIndex = 0;
            }
        }

        private int GetSelectedSpecialBehavior()
        {
            if (cmbUnitSpecialBehavior.SelectedItem is GatherUnitSpecialBehaviorOption option)
            {
                return option.Id;
            }

            return GatherUnitSpecialBehaviorInfo.None;
        }

        private void LoadCategories()
        {
            try
            {
                var allCategories = _repository.GetAllCategories();
                
                _itemCategories = allCategories.Where(c => c.NodeType == "item").ToList();
                _unitCategories = allCategories.Where(c => c.NodeType == "unit").ToList();

                // Populate filter combos
                cmbItemCategory.Items.Clear();
                cmbItemCategory.Items.Add("All");
                foreach (var cat in _itemCategories)
                    cmbItemCategory.Items.Add(cat);
                cmbItemCategory.SelectedIndex = 0;

                cmbUnitCategory.Items.Clear();
                cmbUnitCategory.Items.Add("All");
                foreach (var cat in _unitCategories)
                    cmbUnitCategory.Items.Add(cat);
                cmbUnitCategory.SelectedIndex = 0;

                // Populate details combos
                cmbItemNodeCategory.Items.Clear();
                cmbItemNodeCategory.Items.Add("(None)");
                foreach (var cat in _itemCategories)
                    cmbItemNodeCategory.Items.Add(cat);

                cmbUnitNodeCategory.Items.Clear();
                cmbUnitNodeCategory.Items.Add("(None)");
                foreach (var cat in _unitCategories)
                    cmbUnitNodeCategory.Items.Add(cat);
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading categories: {ex.Message}";
            }
        }

        private void LoadItemNodes(int? selectedNodeId = null)
        {
            try
            {
                var nodes = _repository.GetAllItemNodes();
                
                dgvItemNodes.DataSource = null;
                dgvItemNodes.Columns.Clear();
                
                dgvItemNodes.DataSource = nodes;
                
                // Configure columns
                if (dgvItemNodes.Columns.Contains("Id"))
                    dgvItemNodes.Columns["Id"].Visible = false;
                if (dgvItemNodes.Columns.Contains("CategoryId"))
                    dgvItemNodes.Columns["CategoryId"].Visible = false;
                if (dgvItemNodes.Columns.Contains("Notes"))
                    dgvItemNodes.Columns["Notes"].Visible = false;
                if (dgvItemNodes.Columns.Contains("CreatedAt"))
                    dgvItemNodes.Columns["CreatedAt"].Visible = false;
                if (dgvItemNodes.Columns.Contains("UpdatedAt"))
                    dgvItemNodes.Columns["UpdatedAt"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowColorR"))
                    dgvItemNodes.Columns["GlowColorR"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowColorG"))
                    dgvItemNodes.Columns["GlowColorG"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowColorB"))
                    dgvItemNodes.Columns["GlowColorB"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowAlpha"))
                    dgvItemNodes.Columns["GlowAlpha"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowScale"))
                    dgvItemNodes.Columns["GlowScale"].Visible = false;
                if (dgvItemNodes.Columns.Contains("GlowHeight"))
                    dgvItemNodes.Columns["GlowHeight"].Visible = false;
                if (dgvItemNodes.Columns.Contains("RespawnTimeMin"))
                    dgvItemNodes.Columns["RespawnTimeMin"].Visible = false;
                if (dgvItemNodes.Columns.Contains("RespawnTimeMax"))
                    dgvItemNodes.Columns["RespawnTimeMax"].Visible = false;
                if (dgvItemNodes.Columns.Contains("DisplayOrder"))
                    dgvItemNodes.Columns["DisplayOrder"].Visible = false;
                
                if (selectedNodeId.HasValue)
                {
                    SelectGridRowById(dgvItemNodes, selectedNodeId.Value);
                }

                lblStatus.Text = $"Loaded {nodes.Count} item nodes";
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading item nodes: {ex.Message}";
            }
        }

        private void LoadUnitNodes(int? selectedNodeId = null)
        {
            try
            {
                var nodes = _repository.GetAllUnitNodes();
                
                dgvUnitNodes.DataSource = null;
                dgvUnitNodes.Columns.Clear();
                
                dgvUnitNodes.DataSource = nodes;
                
                // Configure columns
                if (dgvUnitNodes.Columns.Contains("Id"))
                    dgvUnitNodes.Columns["Id"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("CategoryId"))
                    dgvUnitNodes.Columns["CategoryId"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("Notes"))
                    dgvUnitNodes.Columns["Notes"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("CreatedAt"))
                    dgvUnitNodes.Columns["CreatedAt"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("UpdatedAt"))
                    dgvUnitNodes.Columns["UpdatedAt"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowColorR"))
                    dgvUnitNodes.Columns["GlowColorR"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowColorG"))
                    dgvUnitNodes.Columns["GlowColorG"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowColorB"))
                    dgvUnitNodes.Columns["GlowColorB"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowAlpha"))
                    dgvUnitNodes.Columns["GlowAlpha"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowScale"))
                    dgvUnitNodes.Columns["GlowScale"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("GlowHeight"))
                    dgvUnitNodes.Columns["GlowHeight"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("RespawnTimeMin"))
                    dgvUnitNodes.Columns["RespawnTimeMin"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("RespawnTimeMax"))
                    dgvUnitNodes.Columns["RespawnTimeMax"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("DisplayOrder"))
                    dgvUnitNodes.Columns["DisplayOrder"].Visible = false;
                
                if (selectedNodeId.HasValue)
                {
                    SelectGridRowById(dgvUnitNodes, selectedNodeId.Value);
                }

                lblStatus.Text = $"Loaded {nodes.Count} unit nodes";
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading unit nodes: {ex.Message}";
            }
        }

        private void LoadSpawnPoints()
        {
            try
            {
                var points = _repository.GetAllSpawnPoints();
                
                dgvSpawnPoints.DataSource = null;
                dgvSpawnPoints.Columns.Clear();
                
                dgvSpawnPoints.DataSource = points;
                
                // Configure columns
                if (dgvSpawnPoints.Columns.Contains("Id"))
                    dgvSpawnPoints.Columns["Id"].Visible = false;
                if (dgvSpawnPoints.Columns.Contains("ZoneId"))
                    dgvSpawnPoints.Columns["ZoneId"].Visible = false;
                if (dgvSpawnPoints.Columns.Contains("SpawnGroupId"))
                    dgvSpawnPoints.Columns["SpawnGroupId"].Visible = false;
                if (dgvSpawnPoints.Columns.Contains("SpawnPointIndex"))
                    dgvSpawnPoints.Columns["SpawnPointIndex"].Visible = false;
                if (dgvSpawnPoints.Columns.Contains("CreatedAt"))
                    dgvSpawnPoints.Columns["CreatedAt"].Visible = false;
                
                // Populate zone filter
                cmbSpawnPointZone.Items.Clear();
                cmbSpawnPointZone.Items.Add("All");
                var uniqueZones = points.Select(p => p.ZoneName).Where(z => z != null).Distinct().OrderBy(z => z);
                foreach (var zone in uniqueZones)
                    cmbSpawnPointZone.Items.Add(zone);
                cmbSpawnPointZone.SelectedIndex = 0;

                cmbSpawnPointGroupFilter.Items.Clear();
                cmbSpawnPointGroupFilter.Items.Add("All");
                var uniqueGroups = points.Select(p => p.SpawnGroupName).Where(g => !string.IsNullOrWhiteSpace(g)).Distinct().OrderBy(g => g);
                foreach (var group in uniqueGroups)
                    cmbSpawnPointGroupFilter.Items.Add(group);
                cmbSpawnPointGroupFilter.SelectedIndex = 0;
                
                lblStatus.Text = $"Loaded {points.Count} spawn points";
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading spawn points: {ex.Message}";
            }
        }

        private void LoadSpawnPointGroups()
        {
            try
            {
                var groups = _repository.GetAllSpawnPointGroups();
                if (dgvSpawnPointGroups == null)
                {
                    return;
                }

                dgvSpawnPointGroups.DataSource = null;
                dgvSpawnPointGroups.Columns.Clear();
                dgvSpawnPointGroups.DataSource = groups;

                if (dgvSpawnPointGroups.Columns.Contains("Id"))
                    dgvSpawnPointGroups.Columns["Id"].Visible = false;
                if (dgvSpawnPointGroups.Columns.Contains("ZoneId"))
                    dgvSpawnPointGroups.Columns["ZoneId"].Visible = false;
                if (dgvSpawnPointGroups.Columns.Contains("CreatedAt"))
                    dgvSpawnPointGroups.Columns["CreatedAt"].Visible = false;
                if (dgvSpawnPointGroups.Columns.Contains("Notes"))
                    dgvSpawnPointGroups.Columns["Notes"].Visible = false;
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading spawn groups: {ex.Message}";
            }
        }

        #endregion

        #region Event Handlers

        private void DgvItemNodes_SelectionChanged(object sender, EventArgs e)
        {
            if (_isLoading) return;
            
            if (dgvItemNodes.CurrentRow?.DataBoundItem is GatherItemNode node)
            {
                LoadItemNodeDetails(node);
            }
        }

        private void DgvUnitNodes_SelectionChanged(object sender, EventArgs e)
        {
            if (_isLoading) return;
            
            if (dgvUnitNodes.CurrentRow?.DataBoundItem is GatherUnitNode node)
            {
                LoadUnitNodeDetails(node);
            }
        }

        private void DgvSpawnPointGroups_SelectionChanged(object sender, EventArgs e)
        {
            if (_isLoading) return;
            _currentSpawnPointGroup = dgvSpawnPointGroups?.CurrentRow?.DataBoundItem as GatherSpawnPointGroup;
        }

        private void DgvItemZones_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                EditSelectedZoneAssignment(dgvItemZones, "item", _currentItemNode?.Id ?? 0);
            }
        }

        private void DgvUnitZones_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                EditSelectedZoneAssignment(dgvUnitZones, "unit", _currentUnitNode?.Id ?? 0);
            }
        }

        private void LoadItemNodeDetails(GatherItemNode node)
        {
            _isLoading = true;
            _currentItemNode = node;
            
            txtItemCode.Text = node.ItemCode;
            txtItemNodeName.Text = node.NodeName;
            
            // Find category
            cmbItemNodeCategory.SelectedIndex = 0;
            for (int i = 1; i < cmbItemNodeCategory.Items.Count; i++)
            {
                if (cmbItemNodeCategory.Items[i] is GatherNodeCategory cat && cat.Id == node.CategoryId)
                {
                    cmbItemNodeCategory.SelectedIndex = i;
                    break;
                }
            }
            
            numItemSpawnWeight.Value = node.SpawnWeight;
            numItemRespawnMin.Value = (decimal)node.RespawnTimeMin;
            numItemRespawnMax.Value = (decimal)node.RespawnTimeMax;
            numItemMaxPerZone.Value = node.MaxPerZone;
            numItemSkillRequired.Value = node.SkillRequired;
            SetSelectedProfession(cmbItemProfession, node.ProfessionId);
            chkItemPreventWaterSpawn.Checked = node.PreventWaterSpawn;
            chkItemGlow.Checked = node.GlowEffect;
            numItemGlowR.Value = node.GlowColorR;
            numItemGlowG.Value = node.GlowColorG;
            numItemGlowB.Value = node.GlowColorB;
            numItemGlowScale.Value = (decimal)node.GlowScale;
            numItemGlowHeight.Value = (decimal)node.GlowHeight;
            chkItemIsRare.Checked = node.IsRare;
            chkItemEnabled.Checked = node.Enabled;
            txtItemNotes.Text = node.Notes ?? "";
            
            UpdateItemGlowPreview();
            
            // Load zone assignments
            LoadItemNodeZones(node.Id);
            
            _isLoading = false;
        }

        private void LoadUnitNodeDetails(GatherUnitNode node)
        {
            _isLoading = true;
            _currentUnitNode = node;
            
            txtUnitCode.Text = node.UnitCode;
            txtUnitNodeName.Text = node.NodeName;
            
            // Find category
            cmbUnitNodeCategory.SelectedIndex = 0;
            for (int i = 1; i < cmbUnitNodeCategory.Items.Count; i++)
            {
                if (cmbUnitNodeCategory.Items[i] is GatherNodeCategory cat && cat.Id == node.CategoryId)
                {
                    cmbUnitNodeCategory.SelectedIndex = i;
                    break;
                }
            }
            
            numUnitSpawnWeight.Value = node.SpawnWeight;
            numUnitRespawnMin.Value = (decimal)node.RespawnTimeMin;
            numUnitRespawnMax.Value = (decimal)node.RespawnTimeMax;
            numUnitMaxPerZone.Value = node.MaxPerZone;
            numUnitSkillRequired.Value = node.SkillRequired;
            SetSelectedProfession(cmbUnitProfession, node.ProfessionId);
            numUnitHarvestYieldMin.Value = node.HarvestYieldMin;
            numUnitHarvestYieldMax.Value = node.HarvestYieldMax;
            numUnitGatherSuccessChance.Value = node.GatherSuccessChancePercent;
            numUnitMainDropGroupChance.Value = node.MainDropGroupChancePercent;
            numUnitSecondaryDropGroupChance.Value = node.SecondaryDropGroupChancePercent;
            SetSelectedSpecialBehavior(node.SpecialBehaviorId);
            numUnitSpecialBehaviorChance.Value = node.SpecialBehaviorChancePercent;
            chkUnitPreventWaterSpawn.Checked = node.PreventWaterSpawn;
            SetSelectedOwnerPlayer(node.OwnerPlayer);
            chkUnitGlow.Checked = node.GlowEffect;
            numUnitGlowR.Value = node.GlowColorR;
            numUnitGlowG.Value = node.GlowColorG;
            numUnitGlowB.Value = node.GlowColorB;
            numUnitGlowScale.Value = (decimal)node.GlowScale;
            numUnitGlowHeight.Value = (decimal)node.GlowHeight;
            chkUnitIsRare.Checked = node.IsRare;
            chkUnitEnabled.Checked = node.Enabled;
            txtUnitNotes.Text = node.Notes ?? "";
            
            UpdateUnitGlowPreview();
            
            // Load zone assignments
            LoadUnitNodeZones(node.Id);
            LoadUnitNodeDrops(node.Id);
            
            _isLoading = false;
        }

        private void LoadItemNodeZones(int nodeId)
        {
            var zones = _repository.GetZoneAssignmentsByNode("item", nodeId);
            PopulateZoneWeightDisplay(zones, "item", _currentItemNode?.CategoryId, _currentItemNode?.SpawnWeight ?? 0);
            dgvItemZones.DataSource = zones;
        }

        private void LoadUnitNodeZones(int nodeId)
        {
            var zones = _repository.GetZoneAssignmentsByNode("unit", nodeId);
            PopulateZoneWeightDisplay(zones, "unit", _currentUnitNode?.CategoryId, _currentUnitNode?.SpawnWeight ?? 0);
            dgvUnitZones.DataSource = zones;
        }

        private void LoadUnitNodeDrops(int nodeId)
        {
            dgvUnitDrops.DataSource = _repository.GetUnitNodeDrops(nodeId);
        }

        private void BtnItemSave_Click(object sender, EventArgs e)
        {
            if (_currentItemNode == null)
            {
                MessageBox.Show("No item node selected.", "Save", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var dbItem = _repository.GetDatabaseItemByCode(txtItemCode.Text.Trim());
                if (dbItem == null)
                {
                    MessageBox.Show("Select a valid item from the main Items table before saving.", "Invalid Item Code", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                _currentItemNode.ItemCode = dbItem.ItemCode;
                _currentItemNode.NodeName = txtItemNodeName.Text.Trim();
                _currentItemNode.CategoryId = cmbItemNodeCategory.SelectedIndex > 0
                    ? ((GatherNodeCategory)cmbItemNodeCategory.SelectedItem).Id
                    : (int?)null;
                _currentItemNode.SpawnWeight = (int)numItemSpawnWeight.Value;
                _currentItemNode.RespawnTimeMin = (double)numItemRespawnMin.Value;
                _currentItemNode.RespawnTimeMax = (double)numItemRespawnMax.Value;
                _currentItemNode.MaxPerZone = (int)numItemMaxPerZone.Value;
                _currentItemNode.SkillRequired = (int)numItemSkillRequired.Value;
                _currentItemNode.ProfessionId = GetSelectedProfession(cmbItemProfession);
                _currentItemNode.PreventWaterSpawn = chkItemPreventWaterSpawn.Checked;
                _currentItemNode.GlowEffect = chkItemGlow.Checked;
                _currentItemNode.GlowColorR = (int)numItemGlowR.Value;
                _currentItemNode.GlowColorG = (int)numItemGlowG.Value;
                _currentItemNode.GlowColorB = (int)numItemGlowB.Value;
                _currentItemNode.GlowScale = (double)numItemGlowScale.Value;
                _currentItemNode.GlowHeight = (double)numItemGlowHeight.Value;
                _currentItemNode.IsRare = chkItemIsRare.Checked;
                _currentItemNode.Enabled = chkItemEnabled.Checked;
                _currentItemNode.Notes = string.IsNullOrWhiteSpace(txtItemNotes.Text) ? null : txtItemNotes.Text;

                if (_currentItemNode.Id == 0)
                {
                    _currentItemNode.Id = _repository.InsertItemNode(_currentItemNode);
                    lblStatus.Text = "Item node created successfully.";
                }
                else
                {
                    _repository.UpdateItemNode(_currentItemNode);
                    lblStatus.Text = "Item node saved successfully.";
                }

                LoadItemNodes();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnUnitSave_Click(object sender, EventArgs e)
        {
            if (_currentUnitNode == null)
            {
                MessageBox.Show("No unit node selected.", "Save", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                if (numUnitHarvestYieldMin.Value > numUnitHarvestYieldMax.Value)
                {
                    MessageBox.Show("Harvest yield min cannot be greater than max.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                var dbUnit = _repository.GetDatabaseUnitTypeByCode(txtUnitCode.Text.Trim());
                if (dbUnit == null)
                {
                    MessageBox.Show("Select a valid unit from the main unit_types table before saving.", "Invalid Unit Code", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                _currentUnitNode.UnitCode = dbUnit.UnitCode;
                _currentUnitNode.NodeName = txtUnitNodeName.Text.Trim();
                _currentUnitNode.CategoryId = cmbUnitNodeCategory.SelectedIndex > 0
                    ? ((GatherNodeCategory)cmbUnitNodeCategory.SelectedItem).Id
                    : (int?)null;
                _currentUnitNode.SpawnWeight = (int)numUnitSpawnWeight.Value;
                _currentUnitNode.RespawnTimeMin = (double)numUnitRespawnMin.Value;
                _currentUnitNode.RespawnTimeMax = (double)numUnitRespawnMax.Value;
                _currentUnitNode.MaxPerZone = (int)numUnitMaxPerZone.Value;
                _currentUnitNode.SkillRequired = (int)numUnitSkillRequired.Value;
                _currentUnitNode.ProfessionId = GetSelectedProfession(cmbUnitProfession);
                _currentUnitNode.HarvestYieldMin = (int)numUnitHarvestYieldMin.Value;
                _currentUnitNode.HarvestYieldMax = (int)numUnitHarvestYieldMax.Value;
                _currentUnitNode.GatherSuccessChancePercent = (int)numUnitGatherSuccessChance.Value;
                _currentUnitNode.MainDropGroupChancePercent = (int)numUnitMainDropGroupChance.Value;
                _currentUnitNode.SecondaryDropGroupChancePercent = (int)numUnitSecondaryDropGroupChance.Value;
                _currentUnitNode.SpecialBehaviorId = GetSelectedSpecialBehavior();
                _currentUnitNode.SpecialBehaviorChancePercent = (int)numUnitSpecialBehaviorChance.Value;
                _currentUnitNode.PreventWaterSpawn = chkUnitPreventWaterSpawn.Checked;
                _currentUnitNode.OwnerPlayer = GetSelectedOwnerPlayer();
                _currentUnitNode.GlowEffect = chkUnitGlow.Checked;
                _currentUnitNode.GlowColorR = (int)numUnitGlowR.Value;
                _currentUnitNode.GlowColorG = (int)numUnitGlowG.Value;
                _currentUnitNode.GlowColorB = (int)numUnitGlowB.Value;
                _currentUnitNode.GlowScale = (double)numUnitGlowScale.Value;
                _currentUnitNode.GlowHeight = (double)numUnitGlowHeight.Value;
                _currentUnitNode.IsRare = chkUnitIsRare.Checked;
                _currentUnitNode.Enabled = chkUnitEnabled.Checked;
                _currentUnitNode.Notes = string.IsNullOrWhiteSpace(txtUnitNotes.Text) ? null : txtUnitNotes.Text;

                if (_currentUnitNode.Id == 0)
                {
                    _currentUnitNode.Id = _repository.InsertUnitNode(_currentUnitNode);
                    lblStatus.Text = "Unit node created successfully.";
                }
                else
                {
                    _repository.UpdateUnitNode(_currentUnitNode);
                    lblStatus.Text = "Unit node saved successfully.";
                }

                LoadUnitNodes();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnItemAdd_Click(object sender, EventArgs e)
        {
            _currentItemNode = new GatherItemNode();
            _isLoading = true;
            
            txtItemCode.Text = "";
            txtItemNodeName.Text = "New Herb";
            cmbItemNodeCategory.SelectedIndex = 0;
            numItemSpawnWeight.Value = 100;
            numItemRespawnMin.Value = 60;
            numItemRespawnMax.Value = 180;
            numItemMaxPerZone.Value = 5;
            numItemSkillRequired.Value = 0;
            SetSelectedProfession(cmbItemProfession, GatherProfessionInfo.Herbalism);
            chkItemPreventWaterSpawn.Checked = false;
            chkItemGlow.Checked = false;
            numItemGlowR.Value = 0;
            numItemGlowG.Value = 255;
            numItemGlowB.Value = 0;
            numItemGlowScale.Value = 1.0M;
            numItemGlowHeight.Value = 0;
            chkItemIsRare.Checked = false;
            chkItemEnabled.Checked = true;
            txtItemNotes.Text = "";
            
            dgvItemZones.DataSource = null;
            UpdateItemGlowPreview();
            
            _isLoading = false;
            BtnPickDbItem_Click(sender, e);
        }

        private void BtnUnitAdd_Click(object sender, EventArgs e)
        {
            _currentUnitNode = new GatherUnitNode();
            _isLoading = true;
            
            txtUnitCode.Text = "";
            txtUnitNodeName.Text = "New Vein";
            cmbUnitNodeCategory.SelectedIndex = 0;
            numUnitSpawnWeight.Value = 100;
            numUnitRespawnMin.Value = 120;
            numUnitRespawnMax.Value = 360;
            numUnitMaxPerZone.Value = 3;
            numUnitSkillRequired.Value = 0;
            SetSelectedProfession(cmbUnitProfession, GatherProfessionInfo.Mining);
            numUnitHarvestYieldMin.Value = 3;
            numUnitHarvestYieldMax.Value = 6;
            numUnitGatherSuccessChance.Value = 100;
            numUnitMainDropGroupChance.Value = 100;
            numUnitSecondaryDropGroupChance.Value = 25;
            SetSelectedSpecialBehavior(GatherUnitSpecialBehaviorInfo.None);
            numUnitSpecialBehaviorChance.Value = 20;
            chkUnitPreventWaterSpawn.Checked = false;
            SetSelectedOwnerPlayer(24);
            chkUnitGlow.Checked = true;
            numUnitGlowR.Value = 255;
            numUnitGlowG.Value = 200;
            numUnitGlowB.Value = 0;
            numUnitGlowScale.Value = 1.5M;
            numUnitGlowHeight.Value = 0;
            chkUnitIsRare.Checked = false;
            chkUnitEnabled.Checked = true;
            txtUnitNotes.Text = "";
            
            dgvUnitZones.DataSource = null;
            dgvUnitDrops.DataSource = null;
            UpdateUnitGlowPreview();
            
            _isLoading = false;
            BtnPickDbUnit_Click(sender, e);
        }

        private void BtnUnitAddDrop_Click(object sender, EventArgs e)
        {
            if (_currentUnitNode == null || _currentUnitNode.Id <= 0)
            {
                MessageBox.Show("Save the unit node first before adding reward rows.", "Harvest Rewards", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var dialog = new GatherUnitNodeDropDialog(_connectionString))
            {
                if (dialog.ShowDialog(this) == DialogResult.OK && dialog.Result != null)
                {
                    dialog.Result.NodeId = _currentUnitNode.Id;
                    _repository.InsertUnitNodeDrop(dialog.Result);
                    LoadUnitNodeDrops(_currentUnitNode.Id);
                    lblStatus.Text = "Harvest reward added.";
                }
            }
        }

        private void BtnUnitEditDrop_Click(object sender, EventArgs e)
        {
            EditSelectedUnitDrop();
        }

        private void BtnUnitRemoveDrop_Click(object sender, EventArgs e)
        {
            if (_currentUnitNode == null || dgvUnitDrops.SelectedRows.Count == 0)
            {
                return;
            }

            var drop = dgvUnitDrops.SelectedRows[0].DataBoundItem as GatherUnitNodeDrop;
            if (drop == null)
            {
                return;
            }

            if (MessageBox.Show($"Remove reward '{drop.ItemName}'?", "Remove Reward", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
            {
                return;
            }

            _repository.DeleteUnitNodeDrop(drop.Id);
            LoadUnitNodeDrops(_currentUnitNode.Id);
            lblStatus.Text = "Harvest reward removed.";
        }

        private void DgvUnitDrops_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                EditSelectedUnitDrop();
            }
        }

        private void EditSelectedUnitDrop()
        {
            if (_currentUnitNode == null || dgvUnitDrops.SelectedRows.Count == 0)
            {
                return;
            }

            var drop = dgvUnitDrops.SelectedRows[0].DataBoundItem as GatherUnitNodeDrop;
            if (drop == null)
            {
                return;
            }

            using (var dialog = new GatherUnitNodeDropDialog(_connectionString, drop))
            {
                if (dialog.ShowDialog(this) == DialogResult.OK && dialog.Result != null)
                {
                    dialog.Result.NodeId = _currentUnitNode.Id;
                    dialog.Result.Id = drop.Id;
                    dialog.Result.DisplayOrder = drop.DisplayOrder;
                    _repository.UpdateUnitNodeDrop(dialog.Result);
                    LoadUnitNodeDrops(_currentUnitNode.Id);
                    lblStatus.Text = "Harvest reward updated.";
                }
            }
        }

        private void BtnItemDelete_Click(object sender, EventArgs e)
        {
            var selected = dgvItemNodes.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherItemNode)
                .Where(n => n != null && n.Id > 0)
                .ToList();

            if (selected.Count == 0)
            {
                MessageBox.Show("No item node to delete.", "Delete", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string label = selected.Count == 1 ? $"Delete '{selected[0].NodeName}'?" : $"Delete {selected.Count} selected item nodes?";
            if (MessageBox.Show(label, "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                try
                {
                    foreach (var node in selected)
                    {
                        _repository.DeleteItemNode(node.Id);
                    }
                    _currentItemNode = null;
                    LoadItemNodes();
                    lblStatus.Text = $"{selected.Count} item node(s) deleted.";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnUnitDelete_Click(object sender, EventArgs e)
        {
            var selected = dgvUnitNodes.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherUnitNode)
                .Where(n => n != null && n.Id > 0)
                .ToList();

            if (selected.Count == 0)
            {
                MessageBox.Show("No unit node to delete.", "Delete", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string label = selected.Count == 1 ? $"Delete '{selected[0].NodeName}'?" : $"Delete {selected.Count} selected unit nodes?";
            if (MessageBox.Show(label, "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                try
                {
                    foreach (var node in selected)
                    {
                        _repository.DeleteUnitNode(node.Id);
                    }
                    _currentUnitNode = null;
                    LoadUnitNodes();
                    lblStatus.Text = $"{selected.Count} unit node(s) deleted.";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnItemEnable_Click(object sender, EventArgs e)
        {
            SetSelectedItemNodesEnabled(true);
        }

        private void BtnItemDisable_Click(object sender, EventArgs e)
        {
            SetSelectedItemNodesEnabled(false);
        }

        private void SetSelectedItemNodesEnabled(bool enabled)
        {
            if (dgvItemNodes.SelectedRows.Count == 0)
            {
                MessageBox.Show("No item nodes selected.", enabled ? "Enable" : "Disable", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var ids = dgvItemNodes.SelectedRows.Cast<DataGridViewRow>()
                    .Select(r => (r.DataBoundItem as GatherItemNode)?.Id ?? 0)
                    .Where(id => id > 0)
                    .ToList();

                if (ids.Count > 0)
                {
                    _repository.SetItemNodesEnabled(ids, enabled);
                    LoadItemNodes();
                    lblStatus.Text = $"{ids.Count} item node(s) {(enabled ? "enabled" : "disabled")}.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnItemBulkCategory_Click(object sender, EventArgs e)
        {
            var selected = dgvItemNodes.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherItemNode)
                .Where(n => n != null && n.Id > 0)
                .ToList();

            if (selected.Count == 0)
            {
                MessageBox.Show("Select one or more item nodes first.", "Set Category", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new BulkCategoryDialog("Set Item Node Category", _itemCategories))
            {
                if (dialog.ShowDialog() != DialogResult.OK)
                {
                    return;
                }

                try
                {
                    _repository.SetItemNodesCategory(selected.Select(n => n.Id), dialog.SelectedCategoryId);
                    LoadItemNodes();
                    lblStatus.Text = $"Updated category for {selected.Count} item node(s).";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error updating categories: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnItemMoveUp_Click(object sender, EventArgs e)
        {
            MoveSelectedItemNode(true);
        }

        private void BtnItemMoveDown_Click(object sender, EventArgs e)
        {
            MoveSelectedItemNode(false);
        }

        private void MoveSelectedItemNode(bool moveUp)
        {
            if (!(dgvItemNodes.CurrentRow?.DataBoundItem is GatherItemNode node) || node.Id <= 0)
            {
                MessageBox.Show("Select an item node first.", moveUp ? "Move Up" : "Move Down", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try
            {
                if (_repository.MoveItemNode(node.Id, moveUp))
                {
                    LoadItemNodes(node.Id);
                    lblStatus.Text = $"Moved item node '{node.NodeName}' {(moveUp ? "up" : "down")} within its category.";
                }
                else
                {
                    lblStatus.Text = $"'{node.NodeName}' is already at the {(moveUp ? "top" : "bottom")} of its category.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error moving item node: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnUnitEnable_Click(object sender, EventArgs e)
        {
            SetSelectedUnitNodesEnabled(true);
        }

        private void BtnUnitDisable_Click(object sender, EventArgs e)
        {
            SetSelectedUnitNodesEnabled(false);
        }

        private void SetSelectedUnitNodesEnabled(bool enabled)
        {
            if (dgvUnitNodes.SelectedRows.Count == 0)
            {
                MessageBox.Show("No unit nodes selected.", enabled ? "Enable" : "Disable", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var ids = dgvUnitNodes.SelectedRows.Cast<DataGridViewRow>()
                    .Select(r => (r.DataBoundItem as GatherUnitNode)?.Id ?? 0)
                    .Where(id => id > 0)
                    .ToList();

                if (ids.Count > 0)
                {
                    _repository.SetUnitNodesEnabled(ids, enabled);
                    LoadUnitNodes();
                    lblStatus.Text = $"{ids.Count} unit node(s) {(enabled ? "enabled" : "disabled")}.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnUnitBulkCategory_Click(object sender, EventArgs e)
        {
            var selected = dgvUnitNodes.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherUnitNode)
                .Where(n => n != null && n.Id > 0)
                .ToList();

            if (selected.Count == 0)
            {
                MessageBox.Show("Select one or more unit nodes first.", "Set Category", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new BulkCategoryDialog("Set Unit Node Category", _unitCategories))
            {
                if (dialog.ShowDialog() != DialogResult.OK)
                {
                    return;
                }

                try
                {
                    _repository.SetUnitNodesCategory(selected.Select(n => n.Id), dialog.SelectedCategoryId);
                    LoadUnitNodes();
                    lblStatus.Text = $"Updated category for {selected.Count} unit node(s).";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error updating categories: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnUnitMoveUp_Click(object sender, EventArgs e)
        {
            MoveSelectedUnitNode(true);
        }

        private void BtnUnitMoveDown_Click(object sender, EventArgs e)
        {
            MoveSelectedUnitNode(false);
        }

        private void MoveSelectedUnitNode(bool moveUp)
        {
            if (!(dgvUnitNodes.CurrentRow?.DataBoundItem is GatherUnitNode node) || node.Id <= 0)
            {
                MessageBox.Show("Select a unit node first.", moveUp ? "Move Up" : "Move Down", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try
            {
                if (_repository.MoveUnitNode(node.Id, moveUp))
                {
                    LoadUnitNodes(node.Id);
                    lblStatus.Text = $"Moved unit node '{node.NodeName}' {(moveUp ? "up" : "down")} within its category.";
                }
                else
                {
                    lblStatus.Text = $"'{node.NodeName}' is already at the {(moveUp ? "top" : "bottom")} of its category.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error moving unit node: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnItemAddZone_Click(object sender, EventArgs e)
        {
            if (_currentItemNode == null || _currentItemNode.Id == 0)
            {
                MessageBox.Show("Please save the item node first.", "Add Zone", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var dialog = new ZoneAssignmentDialog(_repository, "item"))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var zone = new GatherNodeZone
                        {
                            NodeType = "item",
                            NodeId = _currentItemNode.Id,
                            ZoneId = dialog.ZoneId,
                            ZoneName = dialog.ZoneName,
                            SpawnMode = dialog.SpawnMode,
                            SpawnGroupId = dialog.SpawnGroupId,
                            WeightOverride = dialog.WeightOverride,
                            MaxOverride = dialog.MaxOverride,
                            SharedMaxOverride = dialog.SharedMaxOverride,
                            Enabled = dialog.EnabledAssignment
                        };
                        _repository.InsertZoneAssignment(zone);
                        LoadItemNodeZones(_currentItemNode.Id);
                        lblStatus.Text = "Zone assigned.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnUnitAddZone_Click(object sender, EventArgs e)
        {
            if (_currentUnitNode == null || _currentUnitNode.Id == 0)
            {
                MessageBox.Show("Please save the unit node first.", "Add Zone", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var dialog = new ZoneAssignmentDialog(_repository, "unit"))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var zone = new GatherNodeZone
                        {
                            NodeType = "unit",
                            NodeId = _currentUnitNode.Id,
                            ZoneId = dialog.ZoneId,
                            ZoneName = dialog.ZoneName,
                            SpawnMode = dialog.SpawnMode,
                            SpawnGroupId = dialog.SpawnGroupId,
                            WeightOverride = dialog.WeightOverride,
                            MaxOverride = dialog.MaxOverride,
                            SharedMaxOverride = dialog.SharedMaxOverride,
                            Enabled = dialog.EnabledAssignment
                        };
                        _repository.InsertZoneAssignment(zone);
                        LoadUnitNodeZones(_currentUnitNode.Id);
                        lblStatus.Text = "Zone assigned.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnItemEditZone_Click(object sender, EventArgs e)
        {
            EditSelectedZoneAssignment(dgvItemZones, "item", _currentItemNode?.Id ?? 0);
        }

        private void BtnUnitEditZone_Click(object sender, EventArgs e)
        {
            EditSelectedZoneAssignment(dgvUnitZones, "unit", _currentUnitNode?.Id ?? 0);
        }

        private void BtnItemRemoveZone_Click(object sender, EventArgs e)
        {
            var selected = dgvItemZones.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherNodeZone)
                .Where(z => z != null && z.Id > 0)
                .ToList();

            if (selected.Count > 0)
            {
                string label = selected.Count == 1
                    ? $"Remove placement '{selected[0].ZoneName}'?"
                    : $"Remove {selected.Count} selected placements?";
                if (MessageBox.Show(label, "Confirm Remove",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        foreach (var zone in selected)
                        {
                            _repository.DeleteZoneAssignment(zone.Id);
                        }
                        LoadItemNodeZones(_currentItemNode.Id);
                        lblStatus.Text = $"{selected.Count} placement(s) removed.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnUnitRemoveZone_Click(object sender, EventArgs e)
        {
            var selected = dgvUnitZones.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherNodeZone)
                .Where(z => z != null && z.Id > 0)
                .ToList();

            if (selected.Count > 0)
            {
                string label = selected.Count == 1
                    ? $"Remove placement '{selected[0].ZoneName}'?"
                    : $"Remove {selected.Count} selected placements?";
                if (MessageBox.Show(label, "Confirm Remove",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        foreach (var zone in selected)
                        {
                            _repository.DeleteZoneAssignment(zone.Id);
                        }
                        LoadUnitNodeZones(_currentUnitNode.Id);
                        lblStatus.Text = $"{selected.Count} placement(s) removed.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnItemZoneEnable_Click(object sender, EventArgs e)
        {
            SetSelectedZoneAssignmentsEnabled(dgvItemZones, "item", _currentItemNode?.Id ?? 0, true);
        }

        private void BtnItemZoneDisable_Click(object sender, EventArgs e)
        {
            SetSelectedZoneAssignmentsEnabled(dgvItemZones, "item", _currentItemNode?.Id ?? 0, false);
        }

        private void BtnUnitZoneEnable_Click(object sender, EventArgs e)
        {
            SetSelectedZoneAssignmentsEnabled(dgvUnitZones, "unit", _currentUnitNode?.Id ?? 0, true);
        }

        private void BtnUnitZoneDisable_Click(object sender, EventArgs e)
        {
            SetSelectedZoneAssignmentsEnabled(dgvUnitZones, "unit", _currentUnitNode?.Id ?? 0, false);
        }

        private void SetSelectedZoneAssignmentsEnabled(DataGridView grid, string nodeType, int nodeId, bool enabled)
        {
            if (grid.SelectedRows.Count == 0)
            {
                MessageBox.Show("Select one or more placements first.", enabled ? "Enable Placements" : "Disable Placements", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try
            {
                var ids = grid.SelectedRows.Cast<DataGridViewRow>()
                    .Select(r => (r.DataBoundItem as GatherNodeZone)?.Id ?? 0)
                    .Where(id => id > 0)
                    .ToList();

                if (ids.Count == 0)
                {
                    return;
                }

                _repository.SetZoneAssignmentsEnabled(ids, enabled);
                if (nodeType == "item")
                {
                    LoadItemNodeZones(nodeId);
                }
                else
                {
                    LoadUnitNodeZones(nodeId);
                }
                lblStatus.Text = $"{ids.Count} placement(s) {(enabled ? "enabled" : "disabled")}.";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error updating placements: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void EditSelectedZoneAssignment(DataGridView grid, string nodeType, int nodeId)
        {
            if (nodeId <= 0)
            {
                MessageBox.Show("Please save the node first.", "Edit Placement", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!(grid.CurrentRow?.DataBoundItem is GatherNodeZone zone))
            {
                MessageBox.Show("Select a placement to edit.", "Edit Placement", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new ZoneAssignmentDialog(_repository, nodeType, zone))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        zone.ZoneId = dialog.ZoneId;
                        zone.ZoneName = dialog.ZoneName;
                        zone.SpawnMode = dialog.SpawnMode;
                        zone.SpawnGroupId = dialog.SpawnGroupId;
                        zone.WeightOverride = dialog.WeightOverride;
                        zone.MaxOverride = dialog.MaxOverride;
                        zone.SharedMaxOverride = dialog.SharedMaxOverride;
                        zone.Enabled = dialog.EnabledAssignment;

                        _repository.UpdateZoneAssignment(zone);

                        if (nodeType == "item")
                        {
                            LoadItemNodeZones(nodeId);
                        }
                        else
                        {
                            LoadUnitNodeZones(nodeId);
                        }

                        lblStatus.Text = $"Updated placement for {zone.ZoneName}.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error updating placement: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnSpawnPointAdd_Click(object sender, EventArgs e)
        {
            try
            {
                using (var dialog = new SpawnPointDialog(_repository))
                {
                    if (dialog.ShowDialog() == DialogResult.OK)
                    {
                        _repository.InsertSpawnPoint(dialog.SpawnPoint);
                        LoadSpawnPointGroups();
                        LoadSpawnPoints();
                        lblStatus.Text = $"Spawn point '{dialog.SpawnPoint.PointName}' created.";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error creating spawn point: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnSpawnPointEdit_Click(object sender, EventArgs e)
        {
            if (dgvSpawnPoints.CurrentRow?.DataBoundItem is GatherSpawnPoint point)
            {
                try
                {
                    using (var dialog = new SpawnPointDialog(_repository, point))
                    {
                        if (dialog.ShowDialog() == DialogResult.OK)
                        {
                            _repository.UpdateSpawnPoint(dialog.SpawnPoint);
                            LoadSpawnPointGroups();
                            LoadSpawnPoints();
                            lblStatus.Text = $"Spawn point '{dialog.SpawnPoint.PointName}' updated.";
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error updating spawn point: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            else
            {
                MessageBox.Show("Please select a spawn point to edit.", "Edit", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void BtnSpawnPointDelete_Click(object sender, EventArgs e)
        {
            var selected = dgvSpawnPoints.SelectedRows.Cast<DataGridViewRow>()
                .Select(r => r.DataBoundItem as GatherSpawnPoint)
                .Where(p => p != null && p.Id > 0)
                .ToList();

            if (selected.Count > 0)
            {
                string label = selected.Count == 1 ? $"Delete spawn point '{selected[0].PointName}'?" : $"Delete {selected.Count} selected spawn points?";
                if (MessageBox.Show(label, "Confirm Delete",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        foreach (var point in selected)
                        {
                            _repository.DeleteSpawnPoint(point.Id);
                        }
                        LoadSpawnPointGroups();
                        LoadSpawnPoints();
                        lblStatus.Text = $"{selected.Count} spawn point(s) deleted.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
            else
            {
                MessageBox.Show("Please select one or more spawn points to delete.", "Delete", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void BtnSpawnPointEnable_Click(object sender, EventArgs e)
        {
            SetSelectedSpawnPointsEnabled(true);
        }

        private void BtnSpawnPointDisable_Click(object sender, EventArgs e)
        {
            SetSelectedSpawnPointsEnabled(false);
        }

        private void BtnSpawnPointAutofill_Click(object sender, EventArgs e)
        {
            try
            {
                var seedPoint = dgvSpawnPoints.CurrentRow?.DataBoundItem as GatherSpawnPoint;
                using (var dialog = new SpawnPointAutofillDialog(
                    _repository,
                    seedPoint,
                    _currentSpawnPointGroup,
                    cmbSpawnPointZone.SelectedIndex > 0 ? cmbSpawnPointZone.SelectedItem?.ToString() : null))
                {
                    if (dialog.ShowDialog() != DialogResult.OK)
                    {
                        return;
                    }

                    foreach (var point in dialog.SpawnPoints)
                    {
                        _repository.InsertSpawnPoint(point);
                    }

                    LoadSpawnPointGroups();
                    LoadSpawnPoints();
                    lblStatus.Text = $"Created {dialog.SpawnPoints.Count} spawn point(s) by autofill.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error during spawn point autofill: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void SetSelectedSpawnPointsEnabled(bool enabled)
        {
            if (dgvSpawnPoints.SelectedRows.Count == 0)
            {
                MessageBox.Show("No spawn points selected.", enabled ? "Enable" : "Disable", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var ids = dgvSpawnPoints.SelectedRows.Cast<DataGridViewRow>()
                    .Select(r => (r.DataBoundItem as GatherSpawnPoint)?.Id ?? 0)
                    .Where(id => id > 0)
                    .ToList();

                if (ids.Count > 0)
                {
                    _repository.SetSpawnPointsEnabled(ids, enabled);
                    LoadSpawnPoints();
                    lblStatus.Text = $"{ids.Count} spawn point(s) {(enabled ? "enabled" : "disabled")}.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnSpawnGroupAdd_Click(object sender, EventArgs e)
        {
            using (var dialog = new SpawnPointGroupDialog(_repository))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    _repository.InsertSpawnPointGroup(dialog.SpawnPointGroup);
                    LoadSpawnPointGroups();
                    LoadSpawnPoints();
                    lblStatus.Text = $"Spawn group '{dialog.SpawnPointGroup.GroupName}' created.";
                }
            }
        }

        private void BtnSpawnGroupEdit_Click(object sender, EventArgs e)
        {
            if (_currentSpawnPointGroup == null)
            {
                MessageBox.Show("Select a spawn group first.", "Edit Group", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new SpawnPointGroupDialog(_repository, _currentSpawnPointGroup))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    _repository.UpdateSpawnPointGroup(dialog.SpawnPointGroup);
                    LoadSpawnPointGroups();
                    LoadSpawnPoints();
                    lblStatus.Text = $"Spawn group '{dialog.SpawnPointGroup.GroupName}' updated.";
                }
            }
        }

        private void BtnSpawnGroupDelete_Click(object sender, EventArgs e)
        {
            if (_currentSpawnPointGroup == null)
            {
                MessageBox.Show("Select a spawn group first.", "Delete Group", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            if (MessageBox.Show($"Delete spawn group '{_currentSpawnPointGroup.GroupName}'?\n\nAssignments using it will fall back to Random.", "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
            {
                return;
            }

            try
            {
                _repository.DeleteSpawnPointGroup(_currentSpawnPointGroup.Id);
                _currentSpawnPointGroup = null;
                LoadSpawnPointGroups();
                LoadSpawnPoints();
                if (_currentItemNode?.Id > 0)
                {
                    LoadItemNodeZones(_currentItemNode.Id);
                }
                if (_currentUnitNode?.Id > 0)
                {
                    LoadUnitNodeZones(_currentUnitNode.Id);
                }
                lblStatus.Text = "Spawn group deleted.";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error deleting group: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        #endregion

        #region Filtering

        private void FilterItemNodes()
        {
            if (_isLoading) return;
            try
            {
                var nodes = _repository.GetAllItemNodes().AsEnumerable();
                var search = txtItemSearch.Text?.Trim();
                if (!string.IsNullOrWhiteSpace(search))
                {
                    nodes = nodes.Where(n =>
                        (n.ItemCode?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0 ||
                        (n.NodeName?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0);
                }
                if (cmbItemCategory.SelectedIndex > 0 && cmbItemCategory.SelectedItem is GatherNodeCategory category)
                {
                    nodes = nodes.Where(n => n.CategoryId == category.Id);
                }
                if (chkItemEnabledOnly.Checked)
                {
                    nodes = nodes.Where(n => n.Enabled);
                }
                dgvItemNodes.DataSource = nodes.ToList();
            }
            catch { }
        }

        private void FilterUnitNodes()
        {
            if (_isLoading) return;
            try
            {
                var nodes = _repository.GetAllUnitNodes().AsEnumerable();
                var search = txtUnitSearch.Text?.Trim();
                if (!string.IsNullOrWhiteSpace(search))
                {
                    nodes = nodes.Where(n =>
                        (n.UnitCode?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0 ||
                        (n.NodeName?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0);
                }
                if (cmbUnitCategory.SelectedIndex > 0 && cmbUnitCategory.SelectedItem is GatherNodeCategory category)
                {
                    nodes = nodes.Where(n => n.CategoryId == category.Id);
                }
                if (chkUnitEnabledOnly.Checked)
                {
                    nodes = nodes.Where(n => n.Enabled);
                }
                dgvUnitNodes.DataSource = nodes.ToList();
            }
            catch { }
        }

        private void FilterSpawnPoints()
        {
            if (_isLoading) return;
            try
            {
                var points = _repository.GetAllSpawnPoints().AsEnumerable();
                var search = txtSpawnPointSearch.Text?.Trim();
                if (!string.IsNullOrWhiteSpace(search))
                {
                    points = points.Where(p =>
                        (p.PointName?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0 ||
                        (p.RegionVariable?.IndexOf(search, StringComparison.OrdinalIgnoreCase) ?? -1) >= 0);
                }
                if (cmbSpawnPointZone.SelectedIndex > 0)
                {
                    var zoneName = cmbSpawnPointZone.SelectedItem?.ToString();
                    points = points.Where(p => string.Equals(p.ZoneName, zoneName, StringComparison.OrdinalIgnoreCase));
                }
                if (cmbSpawnPointGroupFilter.SelectedIndex > 0)
                {
                    var groupName = cmbSpawnPointGroupFilter.SelectedItem?.ToString();
                    points = points.Where(p => string.Equals(p.SpawnGroupName, groupName, StringComparison.OrdinalIgnoreCase));
                }
                dgvSpawnPoints.DataSource = points.ToList();
            }
            catch { }
        }

        #endregion

        #region Helpers

        private void UpdateItemGlowPreview()
        {
            if (chkItemGlow.Checked)
            {
                pnlItemGlowPreview.BackColor = Color.FromArgb(
                    (int)numItemGlowR.Value,
                    (int)numItemGlowG.Value,
                    (int)numItemGlowB.Value);
            }
            else
            {
                pnlItemGlowPreview.BackColor = Color.Gray;
            }
        }

        private void UpdateUnitGlowPreview()
        {
            if (chkUnitGlow.Checked)
            {
                pnlUnitGlowPreview.BackColor = Color.FromArgb(
                    (int)numUnitGlowR.Value,
                    (int)numUnitGlowG.Value,
                    (int)numUnitGlowB.Value);
            }
            else
            {
                pnlUnitGlowPreview.BackColor = Color.Gray;
            }
        }

        private DataGridView CreateDataGridView()
        {
            var dgv = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = true,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgv.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgv.DefaultCellStyle.ForeColor = Color.White;
            dgv.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgv.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgv.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgv.EnableHeadersVisualStyles = false;
            return dgv;
        }

        private void ConfigureZonePlacementGrid(DataGridView grid)
        {
            grid.AutoGenerateColumns = false;
            grid.Columns.Clear();

            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "ZoneName",
                HeaderText = "Zone",
                DataPropertyName = "ZoneName",
                FillWeight = 28
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "SpawnModeDisplay",
                HeaderText = "Placement",
                DataPropertyName = "SpawnModeDisplay",
                FillWeight = 24
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "SharedScopeDisplay",
                HeaderText = "Scope",
                DataPropertyName = "SharedScopeDisplay",
                FillWeight = 34
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "EffectiveWeightDisplay",
                HeaderText = "Weight",
                DataPropertyName = "EffectiveWeightDisplay",
                FillWeight = 16
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "SharedChanceDisplay",
                HeaderText = "Chance",
                DataPropertyName = "SharedChanceDisplay",
                FillWeight = 28
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "SharedMaxOverride",
                HeaderText = "Shared Max",
                DataPropertyName = "SharedMaxOverride",
                FillWeight = 16
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "MaxOverride",
                HeaderText = "Max",
                DataPropertyName = "MaxOverride",
                FillWeight = 12
            });
            grid.Columns.Add(new DataGridViewCheckBoxColumn
            {
                Name = "Enabled",
                HeaderText = "Enabled",
                DataPropertyName = "Enabled",
                FillWeight = 16
            });
        }

        private void ConfigureUnitDropGrid(DataGridView grid)
        {
            grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.None;
            grid.ScrollBars = ScrollBars.Both;
            grid.Columns.Clear();
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.GroupName),
                HeaderText = "Drop Group",
                Width = 95
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.ItemCode),
                HeaderText = "Code",
                Width = 70
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.Weight),
                HeaderText = "Pick Weight",
                Width = 85
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.ItemName),
                HeaderText = "Reward",
                Width = 180
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.DropChancePercent),
                HeaderText = "Reward %",
                Width = 80
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.QuantityDisplay),
                HeaderText = "Per-Hit Qty",
                Width = 90
            });
            grid.Columns.Add(new DataGridViewCheckBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.Enabled),
                HeaderText = "Enabled",
                Width = 70
            });
            grid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(GatherUnitNodeDrop.Notes),
                HeaderText = "Notes",
                Width = 120
            });
        }

        private void SelectGridRowById(DataGridView grid, int id)
        {
            foreach (DataGridViewRow row in grid.Rows)
            {
                if (row.DataBoundItem is GatherItemNode itemNode && itemNode.Id == id)
                {
                    row.Selected = true;
                    grid.CurrentCell = row.Cells.Cast<DataGridViewCell>().FirstOrDefault();
                    return;
                }

                if (row.DataBoundItem is GatherUnitNode unitNode && unitNode.Id == id)
                {
                    row.Selected = true;
                    grid.CurrentCell = row.Cells.Cast<DataGridViewCell>().FirstOrDefault();
                    return;
                }
            }
        }

        private void PopulateZoneWeightDisplay(List<GatherNodeZone> zones, string nodeType, int? categoryId, int baseSpawnWeight)
        {
            if (zones == null || !categoryId.HasValue)
            {
                return;
            }

            var allNodes = nodeType == "item"
                ? _repository.GetAllItemNodes().Cast<object>().ToDictionary(n => ((GatherItemNode)n).Id)
                : _repository.GetAllUnitNodes().Cast<object>().ToDictionary(n => ((GatherUnitNode)n).Id);

            var assignmentsByZone = zones
                .Select(z => z.ZoneId)
                .Distinct()
                .ToDictionary(zoneId => zoneId, zoneId => _repository.GetZoneAssignmentsByZone(zoneId));

            foreach (var zone in zones)
            {
                zone.EffectiveWeight = zone.WeightOverride ?? baseSpawnWeight;
                zone.SharedScopeDisplay = GetSharedScopeDisplay(zone);

                if (!zone.SharedMaxOverride.HasValue)
                {
                    zone.SharedChanceDisplay = "Independent";
                    continue;
                }

                var scopeGroupId = GetSharedScopeGroupId(zone);
                var siblingAssignments = assignmentsByZone[zone.ZoneId]
                    .Where(z => z.NodeType == nodeType && z.Enabled && z.SharedMaxOverride.HasValue && GetSharedScopeGroupId(z) == scopeGroupId)
                    .Where(z =>
                    {
                        if (!allNodes.TryGetValue(z.NodeId, out var node))
                        {
                            return false;
                        }

                        return nodeType == "item"
                            ? ((GatherItemNode)node).CategoryId == categoryId
                            : ((GatherUnitNode)node).CategoryId == categoryId;
                    })
                    .ToList();

                var totalWeight = siblingAssignments.Sum(z =>
                {
                    if (!allNodes.TryGetValue(z.NodeId, out var node))
                    {
                        return 0;
                    }

                    var defaultWeight = nodeType == "item"
                        ? ((GatherItemNode)node).SpawnWeight
                        : ((GatherUnitNode)node).SpawnWeight;

                    return z.WeightOverride ?? defaultWeight;
                });

                zone.SharedPoolTotalWeight = totalWeight;
                if (totalWeight <= 0)
                {
                    zone.SharedChanceDisplay = "-";
                    continue;
                }

                var percent = (double)zone.EffectiveWeight / totalWeight * 100.0;
                zone.SharedChanceDisplay = $"{percent:0.#}% ({zone.EffectiveWeight}/{totalWeight})";
            }
        }

        private int? GetSharedScopeGroupId(GatherNodeZone zone)
        {
            return (zone.SpawnMode == "fixed" || zone.SpawnMode == "both") ? zone.SpawnGroupId : null;
        }

        private string GetSharedScopeDisplay(GatherNodeZone zone)
        {
            if (zone.SpawnMode == "fixed" || zone.SpawnMode == "both")
            {
                return string.IsNullOrWhiteSpace(zone.SpawnGroupName)
                    ? "Selected group"
                    : zone.SpawnGroupName;
            }

            return $"{zone.ZoneName} (zone)";
        }

        private void AddLabelAndControl(Panel parent, string labelText, ref int y, int labelWidth, Control control)
        {
            var label = new Label
            {
                Text = labelText,
                Location = new Point(10, y + 3),
                Width = labelWidth,
                AutoSize = false
            };
            control.Location = new Point(10 + labelWidth, y);
            parent.Controls.Add(label);
            parent.Controls.Add(control);
            y += Math.Max(control.Height, 25) + 5;
        }

        private void ApplyDarkTheme(Control parent)
        {
            foreach (Control control in parent.Controls)
            {
                if (control is TextBox txt)
                {
                    txt.BackColor = Color.FromArgb(60, 60, 60);
                    txt.ForeColor = Color.White;
                }
                else if (control is ComboBox cmb)
                {
                    cmb.BackColor = Color.FromArgb(60, 60, 60);
                    cmb.ForeColor = Color.White;
                }
                else if (control is NumericUpDown num)
                {
                    num.BackColor = Color.FromArgb(60, 60, 60);
                    num.ForeColor = Color.White;
                }
                else if (control is Button btn)
                {
                    if (btn.BackColor != Color.FromArgb(0, 122, 204))
                    {
                        btn.BackColor = Color.FromArgb(60, 60, 60);
                        btn.ForeColor = Color.White;
                        btn.FlatStyle = FlatStyle.Flat;
                        btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
                    }
                }
                else if (control is CheckBox chk)
                {
                    chk.ForeColor = Color.White;
                }
                else if (control is Label lbl)
                {
                    lbl.ForeColor = Color.White;
                }
                else if (control is TabControl tab)
                {
                    foreach (TabPage page in tab.TabPages)
                    {
                        page.BackColor = Color.FromArgb(45, 45, 45);
                        ApplyDarkTheme(page);
                    }
                }

                if (control.HasChildren)
                {
                    ApplyDarkTheme(control);
                }
            }
        }

        #endregion

        #region Node Definition Picker Handlers

        private void BtnPickHerb_Click(object sender, EventArgs e)
        {
            try
            {
                var definitions = _repository.GetHerbDefinitions();
                using (var dialog = new NodeDefinitionPickerDialog("Select Herb Definition", definitions.Cast<object>().ToList(), "ItemCode", "ItemName", "Category"))
                {
                    if (dialog.ShowDialog() == DialogResult.OK && dialog.SelectedDefinition is GatherHerbDefinition herb)
                    {
                        var dbItem = ResolveItemDefinition(herb);
                        txtItemCode.Text = dbItem?.ItemCode ?? herb.ItemCode ?? txtItemCode.Text;
                        txtItemNodeName.Text = dbItem?.ItemName ?? herb.ItemName;
                        numItemRespawnMin.Value = (decimal)herb.SuggestedRespawnMin;
                        numItemRespawnMax.Value = (decimal)herb.SuggestedRespawnMax;
                        numItemSkillRequired.Value = herb.SuggestedSkill;
                        SetSelectedProfession(cmbItemProfession, GatherProfessionInfo.InferDefault("item", herb.Category));
                        
                        // Try to select matching category
                        for (int i = 1; i < cmbItemNodeCategory.Items.Count; i++)
                        {
                            if (cmbItemNodeCategory.Items[i] is GatherNodeCategory cat && 
                                cat.CategoryName.Equals(herb.Category, StringComparison.OrdinalIgnoreCase))
                            {
                                cmbItemNodeCategory.SelectedIndex = i;
                                break;
                            }
                        }
                        
                        lblStatus.Text = dbItem != null
                            ? $"Applied herb preset: {herb.ItemName}"
                            : $"Applied herb preset metadata for {herb.ItemName}. No exact Items-table name match was found.";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading herb definitions: {ex.Message}\n\nMake sure to run gather_node_definitions.sql first.", 
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void BtnPickDbItem_Click(object sender, EventArgs e)
        {
            try
            {
                using (var dialog = new DatabasePickerDialog(_repository, "item"))
                {
                    if (dialog.ShowDialog() == DialogResult.OK && dialog.SelectedItem is DatabaseItemInfo item)
                    {
                        txtItemCode.Text = item.ItemCode;
                        txtItemNodeName.Text = item.ItemName;
                        lblStatus.Text = $"Selected database item: {item.ItemName}";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading items: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void BtnPickVein_Click(object sender, EventArgs e)
        {
            try
            {
                var definitions = _repository.GetVeinDefinitions();
                using (var dialog = new NodeDefinitionPickerDialog("Select Vein/Unit Definition", definitions.Cast<object>().ToList(), "UnitCode", "UnitName", "Category"))
                {
                    if (dialog.ShowDialog() == DialogResult.OK && dialog.SelectedDefinition is GatherVeinDefinition vein)
                    {
                        var dbUnit = ResolveUnitDefinition(vein);
                        txtUnitCode.Text = dbUnit?.UnitCode ?? vein.UnitCode ?? txtUnitCode.Text;
                        txtUnitNodeName.Text = dbUnit?.DisplayName ?? vein.UnitName;
                        numUnitRespawnMin.Value = (decimal)vein.SuggestedRespawnMin;
                        numUnitRespawnMax.Value = (decimal)vein.SuggestedRespawnMax;
                        numUnitSkillRequired.Value = vein.SuggestedSkill;
                        SetSelectedProfession(cmbUnitProfession, GatherProfessionInfo.InferDefault("unit", vein.Category));
                        numUnitGlowR.Value = vein.SuggestedGlowR;
                        numUnitGlowG.Value = vein.SuggestedGlowG;
                        numUnitGlowB.Value = vein.SuggestedGlowB;
                        chkUnitGlow.Checked = true;
                        UpdateUnitGlowPreview();
                        
                        // Try to select matching category
                        for (int i = 1; i < cmbUnitNodeCategory.Items.Count; i++)
                        {
                            if (cmbUnitNodeCategory.Items[i] is GatherNodeCategory cat && 
                                cat.CategoryName.Equals(vein.Category, StringComparison.OrdinalIgnoreCase))
                            {
                                cmbUnitNodeCategory.SelectedIndex = i;
                                break;
                            }
                        }
                        
                        lblStatus.Text = dbUnit != null
                            ? $"Applied vein preset: {vein.UnitName}"
                            : $"Applied vein preset metadata for {vein.UnitName}. No exact unit_types name match was found.";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading vein definitions: {ex.Message}\n\nMake sure to run gather_node_definitions.sql first.", 
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void BtnPickDbUnit_Click(object sender, EventArgs e)
        {
            try
            {
                using (var dialog = new DatabasePickerDialog(_repository, "unit"))
                {
                    if (dialog.ShowDialog() == DialogResult.OK && dialog.SelectedItem is DatabaseUnitInfo unit)
                    {
                        txtUnitCode.Text = unit.UnitCode;
                        txtUnitNodeName.Text = unit.DisplayName;
                        lblStatus.Text = $"Selected database unit: {unit.DisplayName}";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading units: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private DatabaseItemInfo ResolveItemDefinition(GatherHerbDefinition herb)
        {
            if (herb == null)
            {
                return null;
            }

            return _repository.GetDatabaseItemByCode(herb.ItemCode)
                ?? _repository.GetDatabaseItemByName(herb.ItemName);
        }

        private DatabaseUnitInfo ResolveUnitDefinition(GatherVeinDefinition vein)
        {
            if (vein == null)
            {
                return null;
            }

            return _repository.GetDatabaseUnitTypeByCode(vein.UnitCode)
                ?? _repository.GetDatabaseUnitTypeByName(vein.UnitName);
        }

        #endregion
    }

    /// <summary>
    /// Dialog for applying one category to multiple nodes
    /// </summary>
    public class BulkCategoryDialog : Form
    {
        private readonly List<GatherNodeCategory> _categories;
        private ComboBox cmbCategory;

        public int? SelectedCategoryId { get; private set; }

        public BulkCategoryDialog(string title, List<GatherNodeCategory> categories)
        {
            _categories = categories ?? new List<GatherNodeCategory>();
            InitializeComponent(title);
            LoadCategories();
        }

        private void InitializeComponent(string title)
        {
            Text = title;
            Size = new Size(420, 170);
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            BackColor = Color.FromArgb(45, 45, 45);
            ForeColor = Color.White;

            var lblCategory = new Label { Text = "Category:", Location = new Point(15, 20), Width = 90 };
            cmbCategory = new ComboBox
            {
                Location = new Point(110, 16),
                Width = 270,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };

            var btnOk = new Button
            {
                Text = "Apply",
                Location = new Point(215, 80),
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            var btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(305, 80),
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            Controls.AddRange(new Control[] { lblCategory, cmbCategory, btnOk, btnCancel });
            AcceptButton = btnOk;
            CancelButton = btnCancel;
        }

        private void LoadCategories()
        {
            cmbCategory.Items.Clear();
            cmbCategory.Items.Add("(None)");
            foreach (var category in _categories)
            {
                cmbCategory.Items.Add(category);
            }
            cmbCategory.SelectedIndex = 0;
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            SelectedCategoryId = cmbCategory.SelectedIndex > 0 && cmbCategory.SelectedItem is GatherNodeCategory category
                ? (int?)category.Id
                : null;
            DialogResult = DialogResult.OK;
            Close();
        }
    }

    /// <summary>
    /// Dialog for zone assignment with database zone picker
    /// </summary>
    public class ZoneAssignmentDialog : Form
    {
        private readonly GatherNodeRepository _repository;
        private readonly string _nodeType;
        private readonly GatherNodeZone _existingAssignment;

        private ComboBox cmbZone;
        private TextBox txtZoneIdManual;
        private TextBox txtZoneNameManual;
        private ComboBox cmbPlacementMode;
        private ComboBox cmbSpawnGroup;
        private CheckBox chkManualEntry;
        private CheckBox chkUseWeightOverride;
        private NumericUpDown numWeightOverride;
        private CheckBox chkUseMaxOverride;
        private NumericUpDown numMaxOverride;
        private CheckBox chkUseSharedMaxOverride;
        private NumericUpDown numSharedMaxOverride;
        private Label lblSharedMaxHelp;
        private CheckBox chkEnabled;
        private Button btnOk;
        private Button btnCancel;
        private List<GatherZone> _zones;

        public int ZoneId { get; private set; }
        public string ZoneName { get; private set; }
        public int? SpawnGroupId { get; private set; }
        public int? WeightOverride { get; private set; }
        public int? MaxOverride { get; private set; }
        public int? SharedMaxOverride { get; private set; }
        public bool EnabledAssignment { get; private set; }
        public string SpawnMode
        {
            get
            {
                switch (cmbPlacementMode.SelectedItem?.ToString())
                {
                    case "Spawn Group":
                        return "fixed";
                    case "Spawn Group + Random":
                    case "Spawn Group + Zone Random Fallback":
                        return "both";
                    default:
                        return "random";
                }
            }
        }

        public ZoneAssignmentDialog(GatherNodeRepository repository = null, string nodeType = "item", GatherNodeZone existingAssignment = null)
        {
            _repository = repository;
            _nodeType = nodeType;
            _existingAssignment = existingAssignment;
            InitializeComponent();
            LoadZones();
            PopulateFields();
        }

        private void InitializeComponent()
        {
            this.Text = _existingAssignment == null ? "Add Zone Assignment" : "Edit Zone Assignment";
            this.Size = new Size(470, 475);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            var toolTip = new ToolTip();

            int y = 15;

            var lblZone = new Label { Text = "Zone:", Location = new Point(10, y + 3), Width = 80 };
            cmbZone = new ComboBox
            {
                Location = new Point(95, y),
                Width = 320,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbZone.SelectedIndexChanged += (s, e) => UpdateZoneSelection();
            this.Controls.AddRange(new Control[] { lblZone, cmbZone });
            y += 30;

            chkManualEntry = new CheckBox
            {
                Text = "Enter zone manually (if not in list)",
                Location = new Point(95, y),
                AutoSize = true
            };
            chkManualEntry.CheckedChanged += (s, e) => ToggleManualEntry();
            this.Controls.Add(chkManualEntry);
            y += 28;

            var lblZoneId = new Label { Text = "Zone ID:", Location = new Point(10, y + 3), Width = 80 };
            txtZoneIdManual = new TextBox
            {
                Location = new Point(95, y),
                Width = 90,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                Enabled = false
            };
            txtZoneIdManual.TextChanged += (s, e) => UpdateSpawnGroupChoices();
            this.Controls.AddRange(new Control[] { lblZoneId, txtZoneIdManual });
            y += 28;

            var lblZoneName = new Label { Text = "Zone Name:", Location = new Point(10, y + 3), Width = 80 };
            txtZoneNameManual = new TextBox
            {
                Location = new Point(95, y),
                Width = 240,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                Enabled = false
            };
            this.Controls.AddRange(new Control[] { lblZoneName, txtZoneNameManual });
            y += 30;

            var lblSpawnMode = new Label { Text = "Placement:", Location = new Point(10, y + 3), Width = 80 };
            cmbPlacementMode = new ComboBox
            {
                Location = new Point(95, y),
                Width = 200,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbPlacementMode.Items.AddRange(new object[] { "Random In Zone (ZonesCore)", "Spawn Group", "Spawn Group + Zone Random Fallback" });
            cmbPlacementMode.SelectedIndex = 0;
            cmbPlacementMode.SelectedIndexChanged += (s, e) => UpdateSpawnGroupChoices();
            toolTip.SetToolTip(cmbPlacementMode, "Random In Zone uses the selected zone's main rect from ZonesCore. Spawn Group modes use explicit gather spawn groups.");
            this.Controls.AddRange(new Control[] { lblSpawnMode, cmbPlacementMode });
            y += 32;

            var lblGroup = new Label { Text = "Spawn Group:", Location = new Point(10, y + 3), Width = 80 };
            cmbSpawnGroup = new ComboBox
            {
                Location = new Point(95, y),
                Width = 320,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                Enabled = false
            };
            this.Controls.AddRange(new Control[] { lblGroup, cmbSpawnGroup });
            y += 34;

            chkUseWeightOverride = new CheckBox
            {
                Text = "Override Weight",
                Location = new Point(95, y),
                AutoSize = true
            };
            numWeightOverride = new NumericUpDown
            {
                Location = new Point(245, y - 2),
                Width = 90,
                Minimum = 1,
                Maximum = 10000,
                Enabled = false,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            chkUseWeightOverride.CheckedChanged += (s, e) => numWeightOverride.Enabled = chkUseWeightOverride.Checked;
            this.Controls.AddRange(new Control[] { chkUseWeightOverride, numWeightOverride });
            y += 32;

            chkUseMaxOverride = new CheckBox
            {
                Text = "Override Max Per Zone",
                Location = new Point(95, y),
                AutoSize = true
            };
            numMaxOverride = new NumericUpDown
            {
                Location = new Point(245, y - 2),
                Width = 90,
                Minimum = 1,
                Maximum = 1000,
                Enabled = false,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            chkUseMaxOverride.CheckedChanged += (s, e) => numMaxOverride.Enabled = chkUseMaxOverride.Checked;
            this.Controls.AddRange(new Control[] { chkUseMaxOverride, numMaxOverride });
            y += 34;

            chkUseSharedMaxOverride = new CheckBox
            {
                Text = "Shared Category Max",
                Location = new Point(95, y),
                AutoSize = true
            };
            numSharedMaxOverride = new NumericUpDown
            {
                Location = new Point(320, y - 2),
                Width = 90,
                Minimum = 1,
                Maximum = 1000,
                Enabled = false,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            chkUseSharedMaxOverride.CheckedChanged += (s, e) => numSharedMaxOverride.Enabled = chkUseSharedMaxOverride.Checked;
            toolTip.SetToolTip(chkUseSharedMaxOverride, "Caps the total active nodes from this category in the same zone or spawn group.");
            toolTip.SetToolTip(numSharedMaxOverride, "Example: if Copper, Tin, and Silver are all in Ore Veins and this value is 3, only 3 total can be active.");

            lblSharedMaxHelp = new Label
            {
                Location = new Point(115, y + 24),
                Size = new Size(300, 34),
                ForeColor = Color.Gainsboro,
                Text = string.Empty
            };

            this.Controls.AddRange(new Control[] { chkUseSharedMaxOverride, numSharedMaxOverride, lblSharedMaxHelp });
            y += 56;

            chkEnabled = new CheckBox
            {
                Text = "Enabled",
                Location = new Point(95, y),
                AutoSize = true,
                Checked = true
            };
            this.Controls.Add(chkEnabled);
            y += 42;

            btnOk = new Button
            {
                Text = "OK",
                Location = new Point(245, y),
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(335, y),
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            this.Controls.AddRange(new Control[] { btnOk, btnCancel });
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;

            UpdateSharedMaxHelpText();
        }

        private void LoadZones()
        {
            try
            {
                if (_repository != null)
                {
                    _zones = new List<GatherZone>
                    {
                        new GatherZone { ZoneId = 0, ZoneName = "Any / Not configured" }
                    };
                    _zones.AddRange(_repository.GetAllZones());
                    cmbZone.Items.Clear();
                    foreach (var zone in _zones)
                    {
                        cmbZone.Items.Add(zone);
                    }
                    cmbZone.SelectedIndex = 0;
                }
                else
                {
                    cmbZone.Items.Add("(Zones not loaded - use manual entry)");
                    cmbZone.SelectedIndex = 0;
                    chkManualEntry.Checked = true;
                }
            }
            catch
            {
                cmbZone.Items.Add("(Error loading zones - use manual entry)");
                cmbZone.SelectedIndex = 0;
            }
        }

        private void PopulateFields()
        {
            if (_existingAssignment == null)
            {
                UpdateSpawnGroupChoices();
                return;
            }

            chkEnabled.Checked = _existingAssignment.Enabled;
            chkUseWeightOverride.Checked = _existingAssignment.WeightOverride.HasValue;
            if (_existingAssignment.WeightOverride.HasValue)
            {
                numWeightOverride.Value = _existingAssignment.WeightOverride.Value;
            }

            chkUseMaxOverride.Checked = _existingAssignment.MaxOverride.HasValue;
            if (_existingAssignment.MaxOverride.HasValue)
            {
                numMaxOverride.Value = _existingAssignment.MaxOverride.Value;
            }

            chkUseSharedMaxOverride.Checked = _existingAssignment.SharedMaxOverride.HasValue;
            if (_existingAssignment.SharedMaxOverride.HasValue)
            {
                numSharedMaxOverride.Value = _existingAssignment.SharedMaxOverride.Value;
            }

            switch (_existingAssignment.SpawnMode)
            {
                case "fixed":
                    cmbPlacementMode.SelectedItem = "Spawn Group";
                    break;
                case "both":
                    cmbPlacementMode.SelectedItem = "Spawn Group + Zone Random Fallback";
                    break;
                default:
                    cmbPlacementMode.SelectedItem = "Random In Zone (ZonesCore)";
                    break;
            }

            var matchingZone = _zones?.FirstOrDefault(z => z.ZoneId == _existingAssignment.ZoneId);
            if (matchingZone != null)
            {
                cmbZone.SelectedItem = matchingZone;
                txtZoneIdManual.Text = matchingZone.ZoneId.ToString();
                txtZoneNameManual.Text = matchingZone.ZoneName;
            }
            else
            {
                chkManualEntry.Checked = true;
                txtZoneIdManual.Text = _existingAssignment.ZoneId.ToString();
                txtZoneNameManual.Text = _existingAssignment.ZoneName;
            }

            UpdateSpawnGroupChoices();
        }

        private void ToggleManualEntry()
        {
            bool manual = chkManualEntry.Checked;
            cmbZone.Enabled = !manual;
            txtZoneIdManual.Enabled = manual;
            txtZoneNameManual.Enabled = manual;
            UpdateSpawnGroupChoices();
        }

        private void UpdateZoneSelection()
        {
            if (!chkManualEntry.Checked && cmbZone.SelectedItem is GatherZone zone)
            {
                txtZoneIdManual.Text = zone.ZoneId.ToString();
                txtZoneNameManual.Text = zone.ZoneName;
                UpdateSpawnGroupChoices();
            }
        }

        private void UpdateSpawnGroupChoices()
        {
            bool requiresGroup = SpawnMode == "fixed" || SpawnMode == "both";
            int? selectedGroupId = cmbSpawnGroup.SelectedItem is GatherSpawnPointGroup selectedGroup
                ? (int?)selectedGroup.Id
                : _existingAssignment?.SpawnGroupId;

            cmbSpawnGroup.Enabled = requiresGroup;
            cmbSpawnGroup.Items.Clear();
            cmbSpawnGroup.Items.Add("(Select a group)");

            int zoneId = 0;
            if (!chkManualEntry.Checked && cmbZone.SelectedItem is GatherZone zone)
            {
                zoneId = zone.ZoneId;
            }
            else if (chkManualEntry.Checked)
            {
                int.TryParse(txtZoneIdManual.Text, out zoneId);
            }

            if (_repository != null)
            {
                foreach (var group in _repository.GetSpawnPointGroupsByZone(zoneId, _nodeType))
                {
                    cmbSpawnGroup.Items.Add(group);
                }
            }

            cmbSpawnGroup.SelectedIndex = 0;
            if (selectedGroupId.HasValue)
            {
                for (int i = 1; i < cmbSpawnGroup.Items.Count; i++)
                {
                    if (cmbSpawnGroup.Items[i] is GatherSpawnPointGroup group && group.Id == selectedGroupId.Value)
                    {
                        cmbSpawnGroup.SelectedIndex = i;
                        break;
                    }
                }
            }

            UpdateSharedMaxHelpText();
        }

        private void UpdateSharedMaxHelpText()
        {
            if (lblSharedMaxHelp == null)
            {
                return;
            }

            string scope = (SpawnMode == "fixed" || SpawnMode == "both")
                ? "selected spawn group"
                : "ZonesCore zone rect";

            lblSharedMaxHelp.Text = $"Combined cap for all nodes in the same category in this {scope}. Weight percentages only compare against other nodes that share this same pool.";
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            if (chkManualEntry.Checked)
            {
                if (!int.TryParse(txtZoneIdManual.Text, out int zoneId) || zoneId < 0)
                {
                    MessageBox.Show("Please enter a valid Zone ID.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                ZoneId = zoneId;
                ZoneName = txtZoneNameManual.Text.Trim();
            }
            else
            {
                if (cmbZone.SelectedItem is GatherZone zone)
                {
                    ZoneId = zone.ZoneId;
                    ZoneName = zone.ZoneName;
                }
                else
                {
                    MessageBox.Show("Please select a zone.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
            }

            if (string.IsNullOrWhiteSpace(ZoneName))
            {
                ZoneName = ZoneId <= 0 ? "Any / Not configured" : $"Zone {ZoneId}";
            }

            if (SpawnMode == "fixed" || SpawnMode == "both")
            {
                if (cmbSpawnGroup.SelectedItem is GatherSpawnPointGroup group)
                {
                    SpawnGroupId = group.Id;
                }
                else
                {
                    MessageBox.Show("Select a spawn group for group-based placement.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
            }
            else
            {
                SpawnGroupId = null;
            }

            WeightOverride = chkUseWeightOverride.Checked ? (int?)numWeightOverride.Value : null;
            MaxOverride = chkUseMaxOverride.Checked ? (int?)numMaxOverride.Value : null;
            SharedMaxOverride = chkUseSharedMaxOverride.Checked ? (int?)numSharedMaxOverride.Value : null;
            EnabledAssignment = chkEnabled.Checked;

            this.DialogResult = DialogResult.OK;
            this.Close();
        }
    }
    /// <summary>
    /// Dialog for picking from predefined node definitions
    /// </summary>
    public class NodeDefinitionPickerDialog : Form
    {
        private DataGridView dgvDefinitions;
        private TextBox txtSearch;
        private ComboBox cmbCategory;
        private Button btnOk;
        private Button btnCancel;
        private List<object> _allDefinitions;
        private string _codeProperty;
        private string _nameProperty;
        private string _categoryProperty;

        public object SelectedDefinition { get; private set; }

        public NodeDefinitionPickerDialog(string title, List<object> definitions, string codeProperty, string nameProperty, string categoryProperty)
        {
            _allDefinitions = definitions;
            _codeProperty = codeProperty;
            _nameProperty = nameProperty;
            _categoryProperty = categoryProperty;
            InitializeComponent(title);
            LoadDefinitions();
        }

        private void InitializeComponent(string title)
        {
            this.Text = title;
            this.Size = new Size(600, 500);
            this.StartPosition = FormStartPosition.CenterParent;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            // Search panel
            var pnlTop = new Panel { Dock = DockStyle.Top, Height = 45, Padding = new Padding(5) };

            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 12), AutoSize = true };
            txtSearch = new TextBox
            {
                Location = new Point(55, 9),
                Width = 150,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            txtSearch.TextChanged += (s, e) => FilterDefinitions();

            var lblCategory = new Label { Text = "Category:", Location = new Point(220, 12), AutoSize = true };
            cmbCategory = new ComboBox
            {
                Location = new Point(280, 9),
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbCategory.SelectedIndexChanged += (s, e) => FilterDefinitions();

            pnlTop.Controls.AddRange(new Control[] { lblSearch, txtSearch, lblCategory, cmbCategory });

            // Grid
            dgvDefinitions = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvDefinitions.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvDefinitions.DefaultCellStyle.ForeColor = Color.White;
            dgvDefinitions.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvDefinitions.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvDefinitions.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvDefinitions.EnableHeadersVisualStyles = false;
            dgvDefinitions.CellDoubleClick += (s, e) => { if (e.RowIndex >= 0) { SelectAndClose(); } };

            // Buttons
            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 45,
                FlowDirection = FlowDirection.RightToLeft,
                Padding = new Padding(5)
            };

            btnCancel = new Button
            {
                Text = "Cancel",
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            btnOk = new Button
            {
                Text = "Select",
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += (s, e) => SelectAndClose();

            pnlButtons.Controls.AddRange(new Control[] { btnCancel, btnOk });

            this.Controls.Add(dgvDefinitions);
            this.Controls.Add(pnlTop);
            this.Controls.Add(pnlButtons);

            this.CancelButton = btnCancel;
        }

        private void LoadDefinitions()
        {
            dgvDefinitions.DataSource = _allDefinitions;

            // Configure visible columns based on type
            foreach (DataGridViewColumn col in dgvDefinitions.Columns)
            {
                if (col.Name == "Id" || col.Name == "DisplayOrder" || 
                    col.Name.StartsWith("Suggested") && col.Name != "SuggestedSkill")
                {
                    col.Visible = false;
                }
            }

            // Populate category filter
            cmbCategory.Items.Clear();
            cmbCategory.Items.Add("All");
            var categories = _allDefinitions
                .Select(d => GetPropertyValue(d, _categoryProperty)?.ToString())
                .Where(c => !string.IsNullOrEmpty(c))
                .Distinct()
                .OrderBy(c => c);
            foreach (var cat in categories)
            {
                cmbCategory.Items.Add(cat);
            }
            cmbCategory.SelectedIndex = 0;
        }

        private void FilterDefinitions()
        {
            var filtered = _allDefinitions.AsEnumerable();
            var search = txtSearch.Text.Trim().ToLower();
            var category = cmbCategory.SelectedItem?.ToString();

            if (!string.IsNullOrEmpty(search))
            {
                filtered = filtered.Where(d =>
                    (GetPropertyValue(d, _codeProperty)?.ToString().ToLower().Contains(search) == true) ||
                    (GetPropertyValue(d, _nameProperty)?.ToString().ToLower().Contains(search) == true));
            }

            if (!string.IsNullOrEmpty(category) && category != "All")
            {
                filtered = filtered.Where(d =>
                    GetPropertyValue(d, _categoryProperty)?.ToString() == category);
            }

            dgvDefinitions.DataSource = filtered.ToList();
        }

        private object GetPropertyValue(object obj, string propertyName)
        {
            return obj?.GetType().GetProperty(propertyName)?.GetValue(obj);
        }

        private void SelectAndClose()
        {
            if (dgvDefinitions.CurrentRow?.DataBoundItem != null)
            {
                SelectedDefinition = dgvDefinitions.CurrentRow.DataBoundItem;
                this.DialogResult = DialogResult.OK;
                this.Close();
            }
        }
    }

    /// <summary>
    /// Dialog for picking from database items or unit_types tables
    /// </summary>
    public class DatabasePickerDialog : Form
    {
        private DataGridView dgvItems;
        private TextBox txtSearch;
        private Button btnSearch;
        private Button btnOk;
        private Button btnCancel;
        private GatherNodeRepository _repository;
        private string _type;

        public object SelectedItem { get; private set; }

        public DatabasePickerDialog(GatherNodeRepository repository, string type)
        {
            _repository = repository;
            _type = type;
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = _type == "item" ? "Select Item from Database" : "Select Unit from Database";
            this.Size = new Size(700, 500);
            this.StartPosition = FormStartPosition.CenterParent;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            // Search panel
            var pnlTop = new Panel { Dock = DockStyle.Top, Height = 55, Padding = new Padding(5) };

            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 12), AutoSize = true };
            txtSearch = new TextBox
            {
                Location = new Point(55, 9),
                Width = 200,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            txtSearch.KeyDown += (s, e) => { if (e.KeyCode == Keys.Enter) DoSearch(); };

            btnSearch = new Button
            {
                Text = "Search",
                Location = new Point(265, 7),
                Width = 80,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnSearch.Click += (s, e) => DoSearch();

            var lblHint = new Label
            {
                Text = "💡 Search by name or code. Leave empty to show first 500 entries.",
                Location = new Point(5, 35),
                AutoSize = true,
                ForeColor = Color.LightGray
            };

            pnlTop.Controls.AddRange(new Control[] { lblSearch, txtSearch, btnSearch, lblHint });

            // Grid
            dgvItems = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvItems.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvItems.DefaultCellStyle.ForeColor = Color.White;
            dgvItems.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvItems.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvItems.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvItems.EnableHeadersVisualStyles = false;
            dgvItems.CellDoubleClick += (s, e) => { if (e.RowIndex >= 0) { SelectAndClose(); } };

            // Buttons
            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 45,
                FlowDirection = FlowDirection.RightToLeft,
                Padding = new Padding(5)
            };

            btnCancel = new Button
            {
                Text = "Cancel",
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            btnOk = new Button
            {
                Text = "Select",
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += (s, e) => SelectAndClose();

            pnlButtons.Controls.AddRange(new Control[] { btnCancel, btnOk });

            this.Controls.Add(dgvItems);
            this.Controls.Add(pnlTop);
            this.Controls.Add(pnlButtons);

            this.CancelButton = btnCancel;

            // Initial load
            DoSearch();
        }

        private void DoSearch()
        {
            try
            {
                var search = txtSearch.Text.Trim();

                if (_type == "item")
                {
                    var items = _repository.GetDatabaseItems(string.IsNullOrEmpty(search) ? null : search);
                    dgvItems.DataSource = items;

                    if (dgvItems.Columns.Contains("Id"))
                        dgvItems.Columns["Id"].Visible = false;
                }
                else
                {
                    var units = _repository.GetDatabaseUnitTypes(string.IsNullOrEmpty(search) ? null : search);
                    dgvItems.DataSource = units;

                    if (dgvItems.Columns.Contains("Id"))
                        dgvItems.Columns["Id"].Visible = false;
                    if (dgvItems.Columns.Contains("DisplayName"))
                        dgvItems.Columns["DisplayName"].Visible = false;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Search error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void SelectAndClose()
        {
            if (dgvItems.CurrentRow?.DataBoundItem != null)
            {
                SelectedItem = dgvItems.CurrentRow.DataBoundItem;
                this.DialogResult = DialogResult.OK;
                this.Close();
            }
        }
    }

    /// <summary>
    /// Dialog for creating/editing spawn point groups
    /// </summary>
    public class SpawnPointGroupDialog : Form
    {
        private readonly GatherNodeRepository _repository;
        private readonly GatherSpawnPointGroup _group;
        private readonly List<GatherZone> _zones = new List<GatherZone>();

        private ComboBox cmbZone;
        private TextBox txtGroupName;
        private ComboBox cmbNodeType;
        private CheckBox chkEnabled;
        private TextBox txtNotes;

        public GatherSpawnPointGroup SpawnPointGroup => _group;

        public SpawnPointGroupDialog(GatherNodeRepository repository, GatherSpawnPointGroup existingGroup = null)
        {
            _repository = repository;
            _group = existingGroup == null
                ? new GatherSpawnPointGroup()
                : new GatherSpawnPointGroup
                {
                    Id = existingGroup.Id,
                    ZoneId = existingGroup.ZoneId,
                    ZoneName = existingGroup.ZoneName,
                    GroupName = existingGroup.GroupName,
                    NodeType = existingGroup.NodeType,
                    Enabled = existingGroup.Enabled,
                    Notes = existingGroup.Notes,
                    CreatedAt = existingGroup.CreatedAt
                };

            InitializeComponent();
            LoadZones();
            PopulateFields();
        }

        private void InitializeComponent()
        {
            this.Text = _group.Id == 0 ? "Add Spawn Group" : "Edit Spawn Group";
            this.Size = new Size(440, 290);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            int y = 15;
            int labelWidth = 110;

            var lblZone = new Label { Text = "Zone:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbZone = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 280,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblZone, cmbZone });
            y += 30;

            var lblName = new Label { Text = "Group Name:", Location = new Point(10, y + 3), Width = labelWidth };
            txtGroupName = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 280,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblName, txtGroupName });
            y += 30;

            var lblType = new Label { Text = "Node Type:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbNodeType = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbNodeType.Items.AddRange(new object[] { "both", "item", "unit" });
            this.Controls.AddRange(new Control[] { lblType, cmbNodeType });
            y += 30;

            chkEnabled = new CheckBox
            {
                Text = "Enabled",
                Location = new Point(10 + labelWidth, y),
                AutoSize = true,
                Checked = true
            };
            this.Controls.Add(chkEnabled);
            y += 30;

            var lblNotes = new Label { Text = "Notes:", Location = new Point(10, y + 3), Width = labelWidth };
            txtNotes = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 280,
                Height = 55,
                Multiline = true,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblNotes, txtNotes });
            y += 70;

            var btnOk = new Button
            {
                Text = "Save",
                Location = new Point(245, y),
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            var btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(335, y),
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            this.Controls.AddRange(new Control[] { btnOk, btnCancel });
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;
        }

        private void LoadZones()
        {
            _zones.Clear();
            cmbZone.Items.Clear();
            var unconfigured = new GatherZone { ZoneId = 0, ZoneName = "Any / Not configured" };
            _zones.Add(unconfigured);
            cmbZone.Items.Add(unconfigured);
            foreach (var zone in _repository.GetAllZones())
            {
                _zones.Add(zone);
                cmbZone.Items.Add(zone);
            }

            if (cmbZone.Items.Count > 0)
            {
                cmbZone.SelectedIndex = 0;
            }
        }

        private void PopulateFields()
        {
            txtGroupName.Text = _group.GroupName ?? string.Empty;
            txtNotes.Text = _group.Notes ?? string.Empty;
            chkEnabled.Checked = _group.Enabled;

            var nodeTypeIndex = cmbNodeType.Items.IndexOf(string.IsNullOrWhiteSpace(_group.NodeType) ? "both" : _group.NodeType);
            cmbNodeType.SelectedIndex = nodeTypeIndex >= 0 ? nodeTypeIndex : 0;

            foreach (var item in cmbZone.Items)
            {
                if (item is GatherZone zone && zone.ZoneId == _group.ZoneId)
                {
                    cmbZone.SelectedItem = item;
                    break;
                }
            }
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            if (!(cmbZone.SelectedItem is GatherZone zone))
            {
                MessageBox.Show("Select a zone for the spawn group.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(txtGroupName.Text))
            {
                MessageBox.Show("Enter a group name.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            _group.ZoneId = zone.ZoneId;
            _group.ZoneName = string.IsNullOrWhiteSpace(zone.ZoneName) ? "Any / Not configured" : zone.ZoneName;
            _group.GroupName = txtGroupName.Text.Trim();
            _group.NodeType = cmbNodeType.SelectedItem?.ToString() ?? "both";
            _group.Enabled = chkEnabled.Checked;
            _group.Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text.Trim();

            this.DialogResult = DialogResult.OK;
            this.Close();
        }
    }

    /// <summary>
    /// Dialog for generating multiple spawn points by number pattern
    /// </summary>
    public class SpawnPointAutofillDialog : Form
    {
        private readonly GatherNodeRepository _repository;
        private readonly GatherSpawnPoint _seedPoint;
        private readonly GatherSpawnPointGroup _seedGroup;
        private readonly string _seedZoneName;

        private ComboBox cmbZone;
        private ComboBox cmbSpawnGroup;
        private ComboBox cmbNodeType;
        private TextBox txtPointPrefix;
        private TextBox txtRegionPrefix;
        private NumericUpDown numStart;
        private NumericUpDown numEnd;
        private NumericUpDown numPadding;
        private NumericUpDown numSpawnIndexStart;
        private CheckBox chkEnabled;
        private TextBox txtNotes;
        private List<GatherZone> _zones = new List<GatherZone>();

        public List<GatherSpawnPoint> SpawnPoints { get; } = new List<GatherSpawnPoint>();

        public SpawnPointAutofillDialog(
            GatherNodeRepository repository,
            GatherSpawnPoint seedPoint = null,
            GatherSpawnPointGroup seedGroup = null,
            string seedZoneName = null)
        {
            _repository = repository;
            _seedPoint = seedPoint;
            _seedGroup = seedGroup;
            _seedZoneName = seedZoneName;
            InitializeComponent();
            LoadZones();
            PopulateDefaults();
        }

        private void InitializeComponent()
        {
            Text = "Autofill Spawn Points";
            Size = new Size(500, 430);
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            BackColor = Color.FromArgb(45, 45, 45);
            ForeColor = Color.White;

            int y = 15;
            int labelWidth = 120;

            var lblZone = new Label { Text = "Zone:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbZone = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 320,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbZone.SelectedIndexChanged += (s, e) => LoadGroupsForSelection();
            Controls.AddRange(new Control[] { lblZone, cmbZone });
            y += 30;

            var lblNodeType = new Label { Text = "Node Type:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbNodeType = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbNodeType.Items.AddRange(new object[] { "both", "item", "unit" });
            cmbNodeType.SelectedIndexChanged += (s, e) => LoadGroupsForSelection();
            Controls.AddRange(new Control[] { lblNodeType, cmbNodeType });
            y += 30;

            var lblGroup = new Label { Text = "Spawn Group:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbSpawnGroup = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 320,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblGroup, cmbSpawnGroup });
            y += 30;

            var lblPointPrefix = new Label { Text = "Point Prefix:", Location = new Point(10, y + 3), Width = labelWidth };
            txtPointPrefix = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 320,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblPointPrefix, txtPointPrefix });
            y += 30;

            var lblRegionPrefix = new Label { Text = "Region Prefix:", Location = new Point(10, y + 3), Width = labelWidth };
            txtRegionPrefix = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 320,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblRegionPrefix, txtRegionPrefix });
            y += 30;

            var lblRange = new Label { Text = "Number Range:", Location = new Point(10, y + 3), Width = labelWidth };
            numStart = new NumericUpDown
            {
                Location = new Point(10 + labelWidth, y),
                Width = 70,
                Minimum = 0,
                Maximum = 999999,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            numEnd = new NumericUpDown
            {
                Location = new Point(10 + labelWidth + 115, y),
                Width = 70,
                Minimum = 0,
                Maximum = 999999,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            var lblTo = new Label { Text = "to", Location = new Point(10 + labelWidth + 87, y + 3), AutoSize = true };
            Controls.AddRange(new Control[] { lblRange, numStart, lblTo, numEnd });
            y += 30;

            var lblPadding = new Label { Text = "Zero Padding:", Location = new Point(10, y + 3), Width = labelWidth };
            numPadding = new NumericUpDown
            {
                Location = new Point(10 + labelWidth, y),
                Width = 70,
                Minimum = 1,
                Maximum = 8,
                Value = 4,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblPadding, numPadding });
            y += 30;

            var lblIndex = new Label { Text = "Spawn Index Start:", Location = new Point(10, y + 3), Width = labelWidth };
            numSpawnIndexStart = new NumericUpDown
            {
                Location = new Point(10 + labelWidth, y),
                Width = 70,
                Minimum = 0,
                Maximum = 999999,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblIndex, numSpawnIndexStart });
            y += 30;

            chkEnabled = new CheckBox
            {
                Text = "Enabled",
                Location = new Point(10 + labelWidth, y),
                Checked = true,
                AutoSize = true
            };
            Controls.Add(chkEnabled);
            y += 30;

            var lblNotes = new Label { Text = "Notes:", Location = new Point(10, y + 3), Width = labelWidth };
            txtNotes = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 320,
                Height = 55,
                Multiline = true,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            Controls.AddRange(new Control[] { lblNotes, txtNotes });
            y += 75;

            var btnOk = new Button
            {
                Text = "Create",
                Location = new Point(315, y),
                Width = 75,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            var btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(400, y),
                Width = 75,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            Controls.AddRange(new Control[] { btnOk, btnCancel });
            AcceptButton = btnOk;
            CancelButton = btnCancel;
        }

        private void LoadZones()
        {
            _zones = new List<GatherZone>
            {
                new GatherZone { ZoneId = 0, ZoneName = "Any / Not configured" }
            };
            _zones.AddRange(_repository.GetAllZones());
            cmbZone.Items.Clear();
            foreach (var zone in _zones)
            {
                cmbZone.Items.Add(zone);
            }
        }

        private void PopulateDefaults()
        {
            cmbNodeType.SelectedItem = _seedPoint?.NodeType ?? _seedGroup?.NodeType ?? "both";
            if (cmbNodeType.SelectedIndex < 0)
            {
                cmbNodeType.SelectedIndex = 0;
            }

            SelectInitialZone();
            txtPointPrefix.Text = BuildDefaultPrefix(_seedPoint?.PointName, "SpawnPoint ");
            txtRegionPrefix.Text = BuildDefaultPrefix(_seedPoint?.RegionVariable, "gg_rct_SpawnPoint");
            numStart.Value = InferNumber(_seedPoint?.PointName) ?? InferNumber(_seedPoint?.RegionVariable) ?? 1;
            numEnd.Value = numStart.Value;
            numPadding.Value = InferPadding(_seedPoint?.PointName) ?? InferPadding(_seedPoint?.RegionVariable) ?? 4;
            numSpawnIndexStart.Value = _seedPoint?.SpawnPointIndex ?? 0;
            chkEnabled.Checked = _seedPoint?.Enabled ?? true;
            txtNotes.Text = _seedPoint?.Notes ?? string.Empty;
            LoadGroupsForSelection();
            SelectInitialGroup();
        }

        private void SelectInitialZone()
        {
            int? zoneId = _seedPoint?.ZoneId ?? _seedGroup?.ZoneId;
            if (zoneId.HasValue)
            {
                foreach (var item in cmbZone.Items)
                {
                    if (item is GatherZone zone && zone.ZoneId == zoneId.Value)
                    {
                        cmbZone.SelectedItem = item;
                        return;
                    }
                }
            }

            if (!string.IsNullOrWhiteSpace(_seedZoneName))
            {
                foreach (var item in cmbZone.Items)
                {
                    if (item is GatherZone zone && string.Equals(zone.ZoneName, _seedZoneName, StringComparison.OrdinalIgnoreCase))
                    {
                        cmbZone.SelectedItem = item;
                        return;
                    }
                }
            }

            if (cmbZone.Items.Count > 0)
            {
                cmbZone.SelectedIndex = 0;
            }
        }

        private void LoadGroupsForSelection()
        {
            cmbSpawnGroup.Items.Clear();
            cmbSpawnGroup.Items.Add("(No Group)");

            if (cmbZone.SelectedItem is GatherZone zone)
            {
                string nodeType = cmbNodeType.SelectedItem?.ToString() ?? "both";
                foreach (var group in _repository.GetSpawnPointGroupsByZone(zone.ZoneId, nodeType))
                {
                    cmbSpawnGroup.Items.Add(group);
                }
            }

            cmbSpawnGroup.SelectedIndex = 0;
        }

        private void SelectInitialGroup()
        {
            int? groupId = _seedPoint?.SpawnGroupId ?? _seedGroup?.Id;
            if (!groupId.HasValue)
            {
                return;
            }

            foreach (var item in cmbSpawnGroup.Items)
            {
                if (item is GatherSpawnPointGroup group && group.Id == groupId.Value)
                {
                    cmbSpawnGroup.SelectedItem = item;
                    return;
                }
            }
        }

        private string BuildDefaultPrefix(string source, string fallback)
        {
            if (string.IsNullOrWhiteSpace(source))
            {
                return fallback;
            }

            int index = source.Length;
            while (index > 0 && char.IsDigit(source[index - 1]))
            {
                index--;
            }

            return index == source.Length ? source : source.Substring(0, index);
        }

        private decimal? InferNumber(string source)
        {
            if (string.IsNullOrWhiteSpace(source))
            {
                return null;
            }

            int index = source.Length;
            while (index > 0 && char.IsDigit(source[index - 1]))
            {
                index--;
            }

            if (index == source.Length)
            {
                return null;
            }

            return int.TryParse(source.Substring(index), out int value) ? (decimal?)value : null;
        }

        private decimal? InferPadding(string source)
        {
            if (string.IsNullOrWhiteSpace(source))
            {
                return null;
            }

            int index = source.Length;
            while (index > 0 && char.IsDigit(source[index - 1]))
            {
                index--;
            }

            return index == source.Length ? null : (decimal?)(source.Length - index);
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            if (!(cmbZone.SelectedItem is GatherZone zone))
            {
                MessageBox.Show("Select a zone first.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(txtPointPrefix.Text) || string.IsNullOrWhiteSpace(txtRegionPrefix.Text))
            {
                MessageBox.Show("Enter both point and region prefixes.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (numEnd.Value < numStart.Value)
            {
                MessageBox.Show("End number must be greater than or equal to start number.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            SpawnPoints.Clear();

            string pointPrefix = txtPointPrefix.Text;
            string regionPrefix = txtRegionPrefix.Text;
            string nodeType = cmbNodeType.SelectedItem?.ToString() ?? "both";
            int padding = (int)numPadding.Value;
            int startNumber = (int)numStart.Value;
            int endNumber = (int)numEnd.Value;
            int? spawnIndexStart = numSpawnIndexStart.Value > 0 ? (int?)numSpawnIndexStart.Value : null;
            var group = cmbSpawnGroup.SelectedItem as GatherSpawnPointGroup;

            for (int number = startNumber; number <= endNumber; number++)
            {
                string suffix = number.ToString("D" + padding);
                SpawnPoints.Add(new GatherSpawnPoint
                {
                    ZoneId = zone.ZoneId,
                    ZoneName = zone.ZoneName,
                    PointName = pointPrefix + suffix,
                    RegionVariable = regionPrefix + suffix,
                    NodeType = nodeType,
                    SpawnGroupId = group?.Id,
                    SpawnGroupName = group?.GroupName,
                    SpawnPointIndex = spawnIndexStart.HasValue ? spawnIndexStart.Value + (number - startNumber) : (int?)null,
                    Enabled = chkEnabled.Checked,
                    Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text.Trim()
                });
            }

            DialogResult = DialogResult.OK;
            Close();
        }
    }

    /// <summary>
    /// Dialog for creating/editing spawn points
    /// </summary>
    public class SpawnPointDialog : Form
    {
        private ComboBox cmbZone;
        private ComboBox cmbSpawnGroup;
        private TextBox txtPointName;
        private TextBox txtRegionVariable;
        private ComboBox cmbNodeType;
        private NumericUpDown numIndex;
        private CheckBox chkEnabled;
        private TextBox txtNotes;
        private Button btnOk;
        private Button btnCancel;
        
        private GatherNodeRepository _repository;
        private GatherSpawnPoint _spawnPoint;
        private List<GatherZone> _zones;
        
        public GatherSpawnPoint SpawnPoint => _spawnPoint;

        public SpawnPointDialog(GatherNodeRepository repository, GatherSpawnPoint existingPoint = null)
        {
            _repository = repository;
            _spawnPoint = existingPoint ?? new GatherSpawnPoint();
            InitializeComponent();
            LoadZones();
            PopulateFields();
        }

        private void InitializeComponent()
        {
            this.Text = _spawnPoint.Id == 0 ? "Add Spawn Point" : "Edit Spawn Point";
            this.Size = new Size(450, 380);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            int y = 15;
            int labelWidth = 110;

            // Zone
            var lblZone = new Label { Text = "Zone:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbZone = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 300,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbZone.SelectedIndexChanged += (s, e) => LoadGroupsForSelection();
            this.Controls.AddRange(new Control[] { lblZone, cmbZone });
            y += 30;

            // Spawn Group
            var lblGroup = new Label { Text = "Spawn Group:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbSpawnGroup = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 300,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblGroup, cmbSpawnGroup });
            y += 30;

            // Point Name
            var lblPointName = new Label { Text = "Point Name:", Location = new Point(10, y + 3), Width = labelWidth };
            txtPointName = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 300,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblPointName, txtPointName });
            y += 30;

            // Region Variable
            var lblRegion = new Label { Text = "Region Variable:", Location = new Point(10, y + 3), Width = labelWidth };
            txtRegionVariable = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 300,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            var lblRegionHint = new Label
            {
                Text = "e.g., gg_rct_Herb_Spawn_01",
                Location = new Point(10 + labelWidth, y + 23),
                ForeColor = Color.LightGray,
                AutoSize = true
            };
            this.Controls.AddRange(new Control[] { lblRegion, txtRegionVariable, lblRegionHint });
            y += 50;

            // Node Type
            var lblNodeType = new Label { Text = "Node Type:", Location = new Point(10, y + 3), Width = labelWidth };
            cmbNodeType = new ComboBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbNodeType.Items.AddRange(new object[] { "both", "item", "unit" });
            cmbNodeType.SelectedIndex = 0;
            cmbNodeType.SelectedIndexChanged += (s, e) => LoadGroupsForSelection();
            this.Controls.AddRange(new Control[] { lblNodeType, cmbNodeType });
            y += 30;

            // Spawn Index
            var lblIndex = new Label { Text = "Spawn Index:", Location = new Point(10, y + 3), Width = labelWidth };
            numIndex = new NumericUpDown
            {
                Location = new Point(10 + labelWidth, y),
                Width = 80,
                Minimum = 0,
                Maximum = 9999,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            var lblIndexHint = new Label
            {
                Text = "(optional, for ordering)",
                Location = new Point(10 + labelWidth + 90, y + 3),
                ForeColor = Color.LightGray,
                AutoSize = true
            };
            this.Controls.AddRange(new Control[] { lblIndex, numIndex, lblIndexHint });
            y += 30;

            // Enabled
            chkEnabled = new CheckBox
            {
                Text = "Enabled",
                Location = new Point(10 + labelWidth, y),
                Checked = true,
                AutoSize = true
            };
            this.Controls.Add(chkEnabled);
            y += 30;

            // Notes
            var lblNotes = new Label { Text = "Notes:", Location = new Point(10, y + 3), Width = labelWidth };
            txtNotes = new TextBox
            {
                Location = new Point(10 + labelWidth, y),
                Width = 300,
                Height = 50,
                Multiline = true,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblNotes, txtNotes });
            y += 60;

            // Buttons
            btnOk = new Button
            {
                Text = "Save",
                Location = new Point(245, y),
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(335, y),
                Width = 80,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            this.Controls.AddRange(new Control[] { btnOk, btnCancel });
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;
        }

        private void LoadZones()
        {
            try
            {
                _zones = new List<GatherZone>
                {
                    new GatherZone { ZoneId = 0, ZoneName = "Any / Not configured" }
                };
                _zones.AddRange(_repository.GetAllZones());
                cmbZone.Items.Clear();
                foreach (var zone in _zones)
                {
                    cmbZone.Items.Add(zone);
                }
                if (cmbZone.Items.Count > 0 && cmbZone.SelectedIndex < 0)
                {
                    cmbZone.SelectedIndex = 0;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading zones: {ex.Message}\n\nRun gather_zones_migration.sql first.",
                    "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                
                // Add a manual entry option
                cmbZone.Items.Add("(Enter Zone ID manually)");
            }
        }

        private void PopulateFields()
        {
            if (_spawnPoint.Id > 0)
            {
                // Editing existing
                txtPointName.Text = _spawnPoint.PointName;
                txtRegionVariable.Text = _spawnPoint.RegionVariable;
                txtNotes.Text = _spawnPoint.Notes ?? "";
                chkEnabled.Checked = _spawnPoint.Enabled;
                numIndex.Value = _spawnPoint.SpawnPointIndex ?? 0;
                
                // Select node type
                var nodeTypeIndex = cmbNodeType.Items.IndexOf(_spawnPoint.NodeType);
                cmbNodeType.SelectedIndex = nodeTypeIndex >= 0 ? nodeTypeIndex : 0;
                
                // Select zone
                foreach (var item in cmbZone.Items)
                {
                    if (item is GatherZone zone && zone.ZoneId == _spawnPoint.ZoneId)
                    {
                        cmbZone.SelectedItem = item;
                        break;
                    }
                }
            }
            else
            {
                LoadGroupsForSelection();
            }

            if (_spawnPoint.SpawnGroupId.HasValue)
            {
                foreach (var item in cmbSpawnGroup.Items)
                {
                    if (item is GatherSpawnPointGroup group && group.Id == _spawnPoint.SpawnGroupId.Value)
                    {
                        cmbSpawnGroup.SelectedItem = item;
                        break;
                    }
                }
            }
        }

        private void LoadGroupsForSelection()
        {
            cmbSpawnGroup.Items.Clear();
            cmbSpawnGroup.Items.Add("(No Group)");

            if (cmbZone.SelectedItem is GatherZone zone)
            {
                string nodeType = cmbNodeType.SelectedItem?.ToString() ?? "both";
                foreach (var group in _repository.GetSpawnPointGroupsByZone(zone.ZoneId, nodeType))
                {
                    cmbSpawnGroup.Items.Add(group);
                }
            }

            cmbSpawnGroup.SelectedIndex = 0;
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            // Validate
            if (cmbZone.SelectedItem == null)
            {
                MessageBox.Show("Please select a zone.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(txtPointName.Text))
            {
                MessageBox.Show("Please enter a point name.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(txtRegionVariable.Text))
            {
                MessageBox.Show("Please enter a region variable name.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // Get zone info
            if (cmbZone.SelectedItem is GatherZone selectedZone)
            {
                _spawnPoint.ZoneId = selectedZone.ZoneId;
                _spawnPoint.ZoneName = selectedZone.ZoneName;
            }

            _spawnPoint.PointName = txtPointName.Text.Trim();
            _spawnPoint.RegionVariable = txtRegionVariable.Text.Trim();
            _spawnPoint.NodeType = cmbNodeType.SelectedItem?.ToString() ?? "both";
            _spawnPoint.SpawnGroupId = cmbSpawnGroup.SelectedItem is GatherSpawnPointGroup group ? (int?)group.Id : null;
            _spawnPoint.SpawnGroupName = cmbSpawnGroup.SelectedItem is GatherSpawnPointGroup groupName ? groupName.GroupName : null;
            _spawnPoint.SpawnPointIndex = numIndex.Value > 0 ? (int?)numIndex.Value : null;
            _spawnPoint.Enabled = chkEnabled.Checked;
            _spawnPoint.Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text.Trim();

            this.DialogResult = DialogResult.OK;
            this.Close();
        }
    }
}

