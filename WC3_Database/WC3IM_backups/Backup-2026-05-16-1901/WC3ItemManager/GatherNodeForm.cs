using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for managing gather nodes (herbs/items and veins/units)
    /// </summary>
    public class GatherNodeForm : Form
    {
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
        private NumericUpDown numItemRespawnMin;
        private NumericUpDown numItemRespawnMax;
        private NumericUpDown numItemMaxPerZone;
        private NumericUpDown numItemSkillRequired;
        private CheckBox chkItemGlow;
        private NumericUpDown numItemGlowR;
        private NumericUpDown numItemGlowG;
        private NumericUpDown numItemGlowB;
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
        private NumericUpDown numUnitRespawnMin;
        private NumericUpDown numUnitRespawnMax;
        private NumericUpDown numUnitMaxPerZone;
        private NumericUpDown numUnitSkillRequired;
        private NumericUpDown numUnitOwnerPlayer;
        private CheckBox chkUnitGlow;
        private NumericUpDown numUnitGlowR;
        private NumericUpDown numUnitGlowG;
        private NumericUpDown numUnitGlowB;
        private NumericUpDown numUnitGlowScale;
        private Panel pnlUnitGlowPreview;
        private CheckBox chkUnitIsRare;
        private CheckBox chkUnitEnabled;
        private TextBox txtUnitNotes;
        private DataGridView dgvUnitZones;
        
        // Spawn points tab controls
        private DataGridView dgvSpawnPoints;
        private Panel pnlSpawnPointDetails;
        private TextBox txtSpawnPointSearch;
        private ComboBox cmbSpawnPointZone;
        
        // Buttons
        private Button btnItemSave;
        private Button btnItemAdd;
        private Button btnItemDelete;
        private Button btnItemEnable;
        private Button btnItemDisable;
        private Button btnItemAddZone;
        private Button btnItemRemoveZone;
        
        private Button btnUnitSave;
        private Button btnUnitAdd;
        private Button btnUnitDelete;
        private Button btnUnitEnable;
        private Button btnUnitDisable;
        private Button btnUnitAddZone;
        private Button btnUnitRemoveZone;
        
        private Button btnSpawnPointSave;
        private Button btnSpawnPointAdd;
        private Button btnSpawnPointEdit;
        private Button btnSpawnPointDelete;
        private Button btnSpawnPointEnable;
        private Button btnSpawnPointDisable;
        
        // Data
        private GatherItemNode _currentItemNode;
        private GatherUnitNode _currentUnitNode;
        private GatherSpawnPoint _currentSpawnPoint;
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

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadItemNodes();

            pnlButtons.Controls.AddRange(new Control[] { btnItemAdd, btnItemDelete, btnItemEnable, btnItemDisable, btnRefresh });

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
            txtItemCode = new TextBox { Width = 60, MaxLength = 4 };
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
                Text = "Zone Assignments",
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
            pnlItemDetails.Controls.Add(dgvItemZones);

            y += 160;

            // Zone buttons
            var pnlZoneButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                AutoSize = true,
                FlowDirection = FlowDirection.LeftToRight
            };
            btnItemAddZone = new Button { Text = "Add Zone", Width = 80 };
            btnItemAddZone.Click += BtnItemAddZone_Click;
            btnItemRemoveZone = new Button { Text = "Remove", Width = 80 };
            btnItemRemoveZone.Click += BtnItemRemoveZone_Click;
            pnlZoneButtons.Controls.AddRange(new Control[] { btnItemAddZone, btnItemRemoveZone });
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

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadUnitNodes();

            pnlButtons.Controls.AddRange(new Control[] { btnUnitAdd, btnUnitDelete, btnUnitEnable, btnUnitDisable, btnRefresh });

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
            txtUnitCode = new TextBox { Width = 60, MaxLength = 4 };
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

            // Owner Player
            numUnitOwnerPlayer = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 27, Value = 24 };
            AddLabelAndControl(pnlUnitDetails, "Owner Player:", ref y, labelWidth, numUnitOwnerPlayer);

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
                Text = "Zone Assignments",
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
            pnlUnitDetails.Controls.Add(dgvUnitZones);

            y += 160;

            // Zone buttons
            var pnlZoneButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                AutoSize = true,
                FlowDirection = FlowDirection.LeftToRight
            };
            btnUnitAddZone = new Button { Text = "Add Zone", Width = 80 };
            btnUnitAddZone.Click += BtnUnitAddZone_Click;
            btnUnitRemoveZone = new Button { Text = "Remove", Width = 80 };
            btnUnitRemoveZone.Click += BtnUnitRemoveZone_Click;
            pnlZoneButtons.Controls.AddRange(new Control[] { btnUnitAddZone, btnUnitRemoveZone });
            pnlUnitDetails.Controls.Add(pnlZoneButtons);

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

            // Right panel - details (simplified for now)
            var lblInfo = new Label
            {
                Text = "Spawn points are defined as regions in the World Editor.\nRegister them here to use with the gathering system.",
                Dock = DockStyle.Top,
                Height = 60,
                Padding = new Padding(10),
                ForeColor = Color.LightGray
            };
            splitMain.Panel2.Controls.Add(lblInfo);

            tabSpawnPoints.Controls.Add(splitMain);
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
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbSpawnPointZone.SelectedIndexChanged += (s, e) => FilterSpawnPoints();

            pnlFilters.Controls.AddRange(new Control[] { lblSearch, txtSpawnPointSearch, lblZone, cmbSpawnPointZone });

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

            var btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadSpawnPoints();

            pnlButtons.Controls.AddRange(new Control[] { btnSpawnPointAdd, btnSpawnPointEdit, btnSpawnPointDelete, btnSpawnPointEnable, btnSpawnPointDisable, btnRefresh });

            parent.Controls.Add(dgvSpawnPoints);
            parent.Controls.Add(pnlButtons);
            parent.Controls.Add(pnlFilters);
        }

        #endregion

        #region Data Loading

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

        private void LoadItemNodes()
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
                if (dgvItemNodes.Columns.Contains("RespawnTimeMin"))
                    dgvItemNodes.Columns["RespawnTimeMin"].Visible = false;
                if (dgvItemNodes.Columns.Contains("RespawnTimeMax"))
                    dgvItemNodes.Columns["RespawnTimeMax"].Visible = false;
                
                lblStatus.Text = $"Loaded {nodes.Count} item nodes";
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading item nodes: {ex.Message}";
            }
        }

        private void LoadUnitNodes()
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
                if (dgvUnitNodes.Columns.Contains("RespawnTimeMin"))
                    dgvUnitNodes.Columns["RespawnTimeMin"].Visible = false;
                if (dgvUnitNodes.Columns.Contains("RespawnTimeMax"))
                    dgvUnitNodes.Columns["RespawnTimeMax"].Visible = false;
                
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
                
                lblStatus.Text = $"Loaded {points.Count} spawn points";
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading spawn points: {ex.Message}";
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
            chkItemGlow.Checked = node.GlowEffect;
            numItemGlowR.Value = node.GlowColorR;
            numItemGlowG.Value = node.GlowColorG;
            numItemGlowB.Value = node.GlowColorB;
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
            numUnitOwnerPlayer.Value = node.OwnerPlayer;
            chkUnitGlow.Checked = node.GlowEffect;
            numUnitGlowR.Value = node.GlowColorR;
            numUnitGlowG.Value = node.GlowColorG;
            numUnitGlowB.Value = node.GlowColorB;
            numUnitGlowScale.Value = (decimal)node.GlowScale;
            chkUnitIsRare.Checked = node.IsRare;
            chkUnitEnabled.Checked = node.Enabled;
            txtUnitNotes.Text = node.Notes ?? "";
            
            UpdateUnitGlowPreview();
            
            // Load zone assignments
            LoadUnitNodeZones(node.Id);
            
            _isLoading = false;
        }

        private void LoadItemNodeZones(int nodeId)
        {
            var zones = _repository.GetZoneAssignmentsByNode("item", nodeId);
            dgvItemZones.DataSource = zones;
            
            if (dgvItemZones.Columns.Contains("Id"))
                dgvItemZones.Columns["Id"].Visible = false;
            if (dgvItemZones.Columns.Contains("NodeType"))
                dgvItemZones.Columns["NodeType"].Visible = false;
            if (dgvItemZones.Columns.Contains("NodeId"))
                dgvItemZones.Columns["NodeId"].Visible = false;
            if (dgvItemZones.Columns.Contains("CreatedAt"))
                dgvItemZones.Columns["CreatedAt"].Visible = false;
        }

        private void LoadUnitNodeZones(int nodeId)
        {
            var zones = _repository.GetZoneAssignmentsByNode("unit", nodeId);
            dgvUnitZones.DataSource = zones;
            
            if (dgvUnitZones.Columns.Contains("Id"))
                dgvUnitZones.Columns["Id"].Visible = false;
            if (dgvUnitZones.Columns.Contains("NodeType"))
                dgvUnitZones.Columns["NodeType"].Visible = false;
            if (dgvUnitZones.Columns.Contains("NodeId"))
                dgvUnitZones.Columns["NodeId"].Visible = false;
            if (dgvUnitZones.Columns.Contains("CreatedAt"))
                dgvUnitZones.Columns["CreatedAt"].Visible = false;
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
                _currentItemNode.ItemCode = txtItemCode.Text.Trim();
                _currentItemNode.NodeName = txtItemNodeName.Text.Trim();
                _currentItemNode.CategoryId = cmbItemNodeCategory.SelectedIndex > 0
                    ? ((GatherNodeCategory)cmbItemNodeCategory.SelectedItem).Id
                    : (int?)null;
                _currentItemNode.SpawnWeight = (int)numItemSpawnWeight.Value;
                _currentItemNode.RespawnTimeMin = (double)numItemRespawnMin.Value;
                _currentItemNode.RespawnTimeMax = (double)numItemRespawnMax.Value;
                _currentItemNode.MaxPerZone = (int)numItemMaxPerZone.Value;
                _currentItemNode.SkillRequired = (int)numItemSkillRequired.Value;
                _currentItemNode.GlowEffect = chkItemGlow.Checked;
                _currentItemNode.GlowColorR = (int)numItemGlowR.Value;
                _currentItemNode.GlowColorG = (int)numItemGlowG.Value;
                _currentItemNode.GlowColorB = (int)numItemGlowB.Value;
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
                _currentUnitNode.UnitCode = txtUnitCode.Text.Trim();
                _currentUnitNode.NodeName = txtUnitNodeName.Text.Trim();
                _currentUnitNode.CategoryId = cmbUnitNodeCategory.SelectedIndex > 0
                    ? ((GatherNodeCategory)cmbUnitNodeCategory.SelectedItem).Id
                    : (int?)null;
                _currentUnitNode.SpawnWeight = (int)numUnitSpawnWeight.Value;
                _currentUnitNode.RespawnTimeMin = (double)numUnitRespawnMin.Value;
                _currentUnitNode.RespawnTimeMax = (double)numUnitRespawnMax.Value;
                _currentUnitNode.MaxPerZone = (int)numUnitMaxPerZone.Value;
                _currentUnitNode.SkillRequired = (int)numUnitSkillRequired.Value;
                _currentUnitNode.OwnerPlayer = (int)numUnitOwnerPlayer.Value;
                _currentUnitNode.GlowEffect = chkUnitGlow.Checked;
                _currentUnitNode.GlowColorR = (int)numUnitGlowR.Value;
                _currentUnitNode.GlowColorG = (int)numUnitGlowG.Value;
                _currentUnitNode.GlowColorB = (int)numUnitGlowB.Value;
                _currentUnitNode.GlowScale = (double)numUnitGlowScale.Value;
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
            chkItemGlow.Checked = false;
            numItemGlowR.Value = 0;
            numItemGlowG.Value = 255;
            numItemGlowB.Value = 0;
            chkItemIsRare.Checked = false;
            chkItemEnabled.Checked = true;
            txtItemNotes.Text = "";
            
            dgvItemZones.DataSource = null;
            UpdateItemGlowPreview();
            
            _isLoading = false;
            txtItemCode.Focus();
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
            numUnitOwnerPlayer.Value = 24;
            chkUnitGlow.Checked = true;
            numUnitGlowR.Value = 255;
            numUnitGlowG.Value = 200;
            numUnitGlowB.Value = 0;
            numUnitGlowScale.Value = 1.5M;
            chkUnitIsRare.Checked = false;
            chkUnitEnabled.Checked = true;
            txtUnitNotes.Text = "";
            
            dgvUnitZones.DataSource = null;
            UpdateUnitGlowPreview();
            
            _isLoading = false;
            txtUnitCode.Focus();
        }

        private void BtnItemDelete_Click(object sender, EventArgs e)
        {
            if (_currentItemNode == null || _currentItemNode.Id == 0)
            {
                MessageBox.Show("No item node to delete.", "Delete", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (MessageBox.Show($"Delete '{_currentItemNode.NodeName}'?", "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                try
                {
                    _repository.DeleteItemNode(_currentItemNode.Id);
                    _currentItemNode = null;
                    LoadItemNodes();
                    lblStatus.Text = "Item node deleted.";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnUnitDelete_Click(object sender, EventArgs e)
        {
            if (_currentUnitNode == null || _currentUnitNode.Id == 0)
            {
                MessageBox.Show("No unit node to delete.", "Delete", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (MessageBox.Show($"Delete '{_currentUnitNode.NodeName}'?", "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                try
                {
                    _repository.DeleteUnitNode(_currentUnitNode.Id);
                    _currentUnitNode = null;
                    LoadUnitNodes();
                    lblStatus.Text = "Unit node deleted.";
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

        private void BtnItemAddZone_Click(object sender, EventArgs e)
        {
            if (_currentItemNode == null || _currentItemNode.Id == 0)
            {
                MessageBox.Show("Please save the item node first.", "Add Zone", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var dialog = new ZoneAssignmentDialog(_repository))
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
                            Enabled = true
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

            using (var dialog = new ZoneAssignmentDialog(_repository))
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
                            Enabled = true
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

        private void BtnItemRemoveZone_Click(object sender, EventArgs e)
        {
            if (dgvItemZones.CurrentRow?.DataBoundItem is GatherNodeZone zone)
            {
                if (MessageBox.Show($"Remove zone '{zone.ZoneName}'?", "Confirm Remove",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        _repository.DeleteZoneAssignment(zone.Id);
                        LoadItemNodeZones(_currentItemNode.Id);
                        lblStatus.Text = "Zone removed.";
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
            if (dgvUnitZones.CurrentRow?.DataBoundItem is GatherNodeZone zone)
            {
                if (MessageBox.Show($"Remove zone '{zone.ZoneName}'?", "Confirm Remove",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        _repository.DeleteZoneAssignment(zone.Id);
                        LoadUnitNodeZones(_currentUnitNode.Id);
                        lblStatus.Text = "Zone removed.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
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
            if (dgvSpawnPoints.CurrentRow?.DataBoundItem is GatherSpawnPoint point)
            {
                if (MessageBox.Show($"Delete spawn point '{point.PointName}'?", "Confirm Delete",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    try
                    {
                        _repository.DeleteSpawnPoint(point.Id);
                        LoadSpawnPoints();
                        lblStatus.Text = "Spawn point deleted.";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
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

        #endregion

        #region Filtering

        private void FilterItemNodes()
        {
            // TODO: Implement filtering
        }

        private void FilterUnitNodes()
        {
            // TODO: Implement filtering
        }

        private void FilterSpawnPoints()
        {
            // TODO: Implement filtering
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
                MultiSelect = false,
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
                        txtItemCode.Text = herb.ItemCode;
                        txtItemNodeName.Text = herb.ItemName;
                        numItemRespawnMin.Value = (decimal)herb.SuggestedRespawnMin;
                        numItemRespawnMax.Value = (decimal)herb.SuggestedRespawnMax;
                        numItemSkillRequired.Value = herb.SuggestedSkill;
                        
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
                        
                        lblStatus.Text = $"Selected herb definition: {herb.ItemName}";
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
                        txtUnitCode.Text = vein.UnitCode;
                        txtUnitNodeName.Text = vein.UnitName;
                        numUnitRespawnMin.Value = (decimal)vein.SuggestedRespawnMin;
                        numUnitRespawnMax.Value = (decimal)vein.SuggestedRespawnMax;
                        numUnitSkillRequired.Value = vein.SuggestedSkill;
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
                        
                        lblStatus.Text = $"Selected vein definition: {vein.UnitName}";
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

        #endregion
    }

    /// <summary>
    /// Dialog for zone assignment with database zone picker
    /// </summary>
    public class ZoneAssignmentDialog : Form
    {
        private ComboBox cmbZone;
        private TextBox txtZoneIdManual;
        private TextBox txtZoneNameManual;
        private ComboBox cmbSpawnMode;
        private CheckBox chkManualEntry;
        private Button btnOk;
        private Button btnCancel;
        
        private GatherNodeRepository _repository;
        private List<GatherZone> _zones;

        public int ZoneId { get; private set; }
        public string ZoneName { get; private set; }
        public string SpawnMode => cmbSpawnMode.SelectedItem?.ToString().ToLower() ?? "random";

        public ZoneAssignmentDialog(GatherNodeRepository repository = null)
        {
            _repository = repository;
            InitializeComponent();
            LoadZones();
        }

        private void InitializeComponent()
        {
            this.Text = "Add Zone Assignment";
            this.Size = new Size(400, 240);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            int y = 15;

            // Zone selection
            var lblZone = new Label { Text = "Zone:", Location = new Point(10, y + 3), Width = 80 };
            cmbZone = new ComboBox
            {
                Location = new Point(95, y),
                Width = 280,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbZone.SelectedIndexChanged += (s, e) => UpdateZoneSelection();
            this.Controls.AddRange(new Control[] { lblZone, cmbZone });
            y += 30;

            // Manual entry checkbox
            chkManualEntry = new CheckBox
            {
                Text = "Enter zone manually (if not in list)",
                Location = new Point(95, y),
                AutoSize = true
            };
            chkManualEntry.CheckedChanged += (s, e) => ToggleManualEntry();
            this.Controls.Add(chkManualEntry);
            y += 28;

            // Manual Zone ID
            var lblZoneId = new Label { Text = "Zone ID:", Location = new Point(10, y + 3), Width = 80 };
            txtZoneIdManual = new TextBox
            {
                Location = new Point(95, y),
                Width = 80,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                Enabled = false
            };
            this.Controls.AddRange(new Control[] { lblZoneId, txtZoneIdManual });
            y += 28;

            // Manual Zone Name
            var lblZoneName = new Label { Text = "Zone Name:", Location = new Point(10, y + 3), Width = 80 };
            txtZoneNameManual = new TextBox
            {
                Location = new Point(95, y),
                Width = 200,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                Enabled = false
            };
            this.Controls.AddRange(new Control[] { lblZoneName, txtZoneNameManual });
            y += 30;

            // Spawn Mode
            var lblSpawnMode = new Label { Text = "Spawn Mode:", Location = new Point(10, y + 3), Width = 80 };
            cmbSpawnMode = new ComboBox
            {
                Location = new Point(95, y),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbSpawnMode.Items.AddRange(new object[] { "Random", "Fixed", "Both" });
            cmbSpawnMode.SelectedIndex = 0;
            this.Controls.AddRange(new Control[] { lblSpawnMode, cmbSpawnMode });
            y += 40;

            // Buttons
            btnOk = new Button
            {
                Text = "OK",
                Location = new Point(200, y),
                Width = 80,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(290, y),
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
                if (_repository != null)
                {
                    _zones = _repository.GetAllZones();
                    cmbZone.Items.Clear();
                    cmbZone.Items.Add("(Select a zone)");
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

        private void ToggleManualEntry()
        {
            bool manual = chkManualEntry.Checked;
            cmbZone.Enabled = !manual;
            txtZoneIdManual.Enabled = manual;
            txtZoneNameManual.Enabled = manual;
        }

        private void UpdateZoneSelection()
        {
            if (!chkManualEntry.Checked && cmbZone.SelectedItem is GatherZone zone)
            {
                txtZoneIdManual.Text = zone.ZoneId.ToString();
                txtZoneNameManual.Text = zone.ZoneName;
            }
        }

        private void BtnOk_Click(object sender, EventArgs e)
        {
            if (chkManualEntry.Checked)
            {
                if (!int.TryParse(txtZoneIdManual.Text, out int zoneId) || zoneId <= 0)
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
                ZoneName = $"Zone {ZoneId}";
            }

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
    /// Dialog for creating/editing spawn points
    /// </summary>
    public class SpawnPointDialog : Form
    {
        private ComboBox cmbZone;
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
            this.Controls.AddRange(new Control[] { lblZone, cmbZone });
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
                _zones = _repository.GetAllZones();
                cmbZone.Items.Clear();
                foreach (var zone in _zones)
                {
                    cmbZone.Items.Add(zone);
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
            _spawnPoint.SpawnPointIndex = numIndex.Value > 0 ? (int?)numIndex.Value : null;
            _spawnPoint.Enabled = chkEnabled.Checked;
            _spawnPoint.Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text.Trim();

            this.DialogResult = DialogResult.OK;
            this.Close();
        }
    }
}

