using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Exporters;
using WC3ItemManager.Importers;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;
using WC3ItemManager.SourceEditing;

namespace WC3ItemManager
{
    public sealed class QuestDesignerForm : Form
    {
        private readonly QuestDesignerRepository _repository;
        private readonly QuestSourceEditor _sourceEditor = new QuestSourceEditor();
        private readonly string _connectionString;
        private readonly TreeView _navigation = new TreeView();
        private readonly SplitContainer _workspaceSplit = new SplitContainer();
        private readonly TabControl _tabs = new TabControl();
        private readonly ToolStrip _mainTools = new ToolStrip();
        private readonly ToolStripStatusLabel _status = new ToolStripStatusLabel();
        private readonly PropertyGrid _giverProperties = new PropertyGrid();
        private readonly PropertyGrid _questProperties = new PropertyGrid();
        private readonly PropertyGrid _rewardProperties = new PropertyGrid();
        private readonly PropertyGrid _objectiveProperties = new PropertyGrid();
        private readonly PropertyGrid _sequenceProperties = new PropertyGrid();
        private readonly PropertyGrid _stepProperties = new PropertyGrid();
        private readonly DataGridView _objectivesGrid = CreateGrid();
        private readonly DataGridView _stepsGrid = CreateGrid();
        private readonly DataGridView _dependenciesGrid = CreateGrid();
        private readonly DataGridView _voicelinesGrid = CreateGrid();
        private readonly DataGridViewComboBoxColumn _stepVoiceColumn = new DataGridViewComboBoxColumn();
        private readonly CheckedListBox _prerequisites = new CheckedListBox();
        private readonly ListBox _sequenceList = new ListBox();
        private readonly ComboBox _sequenceQuest = new ComboBox();
        private readonly ComboBox _questReceiver = new ComboBox();
        private readonly TreeView _relationships = new TreeView();
        private readonly QuestLogPreviewControl _preview = new QuestLogPreviewControl();
        private readonly TextBox _navigationSearch = new TextBox();
        private readonly Panel _ownershipBanner = new Panel();
        private readonly Panel _ownershipAccent = new Panel();
        private readonly Label _ownershipTitle = new Label();
        private readonly Label _ownershipDetails = new Label();
        private readonly Button _openSourceButton = new Button();
        private readonly ColumnStyle _sourceButtonColumn = new ColumnStyle(SizeType.Absolute, 0f);
        private readonly Panel _overviewPanel = new Panel();
        private readonly Label _overviewTitle = new Label();
        private readonly Label _overviewStats = new Label();
        private readonly ToolTip _sourceFieldToolTip = new ToolTip();
        private ToolStripButton _newQuestButton;
        private ToolStripButton _saveButton;
        private ToolStripButton _deleteButton;
        private ToolStripButton _openSourceToolButton;
        private ToolStripLabel _modeBadge;
        private TreeNode _lastSearchNode;

        private BindingList<QuestObjectiveDefinition> _objectives = new BindingList<QuestObjectiveDefinition>();
        private BindingList<QuestSequenceStepDefinition> _steps = new BindingList<QuestSequenceStepDefinition>();
        private BindingList<QuestWorldEditorDependency> _dependencies = new BindingList<QuestWorldEditorDependency>();
        private BindingList<QuestVoicelineDefinition> _voicelines = new BindingList<QuestVoicelineDefinition>();
        private List<QuestGiverDefinition> _givers = new List<QuestGiverDefinition>();
        private List<QuestDefinition> _quests = new List<QuestDefinition>();
        private QuestGiverDefinition _currentGiver;
        private QuestDefinition _currentQuest;
        private QuestRewardDefinition _currentReward;
        private QuestSequenceDefinition _currentSequence;
        private QuestSourceEditSession _sourceEditSession;
        private QuestGiverDefinition _sourceGiverBaseline;
        private QuestDefinition _sourceQuestBaseline;
        private QuestRewardDefinition _sourceRewardBaseline;
        private List<QuestObjectiveDefinition> _sourceObjectiveBaselines = new List<QuestObjectiveDefinition>();
        private bool _loading;

        public QuestDesignerForm(string connectionString)
        {
            _connectionString = connectionString;
            _repository = new QuestDesignerRepository(connectionString);
            Text = "WC3 Manager - Quest Designer";
            StartPosition = FormStartPosition.CenterParent;
            Width = 1420;
            Height = 900;
            MinimumSize = new Size(1120, 720);
            Icon = null;
            Font = new Font("Segoe UI", 9f);
            BackColor = Color.FromArgb(243, 246, 250);
            AutoScaleMode = AutoScaleMode.Dpi;
            KeyPreview = true;
            KeyDown += (s, e) =>
            {
                if (e.Control && e.KeyCode == Keys.F)
                {
                    _navigationSearch.Focus();
                    _navigationSearch.SelectAll();
                    e.SuppressKeyPress = true;
                }
            };

            BuildToolbar();
            BuildWorkspace();
            ConfigureSourceFieldTooltips();
            ShowOverview("Quest Library");
            var statusStrip = new StatusStrip
            {
                SizingGrip = false,
                BackColor = Color.White
            };
            _status.Spring = true;
            _status.TextAlign = ContentAlignment.MiddleLeft;
            statusStrip.Items.Add(_status);
            Controls.Add(statusStrip);
            Shown += OnShown;
        }

        private void BuildToolbar()
        {
            _mainTools.GripStyle = ToolStripGripStyle.Hidden;
            _mainTools.Dock = DockStyle.Top;
            _mainTools.AutoSize = false;
            _mainTools.Height = 40;
            _mainTools.Padding = new Padding(8, 5, 8, 4);
            _mainTools.BackColor = Color.White;
            _mainTools.RenderMode = ToolStripRenderMode.System;

            _mainTools.Items.Add(CreateToolButton("New giver", (s, e) => NewGiver(), "Create a database-authored quest giver"));
            _newQuestButton = CreateToolButton("New quest", (s, e) => NewQuest(), "Create a quest under the selected database-authored giver");
            _mainTools.Items.Add(_newQuestButton);
            _mainTools.Items.Add(new ToolStripSeparator());
            _saveButton = CreateToolButton("Save changes", (s, e) => SaveCurrent(), "Save the selected database-authored record");
            _deleteButton = CreateToolButton("Delete", (s, e) => DeleteCurrent(), "Delete the selected database-authored record");
            _mainTools.Items.Add(_saveButton);
            _mainTools.Items.Add(_deleteButton);
            _mainTools.Items.Add(new ToolStripSeparator());
            _mainTools.Items.Add(CreateToolButton("Refresh", (s, e) => RefreshData(), "Reload quest data from PostgreSQL"));
            _mainTools.Items.Add(CreateToolButton("Sync JASS sources...", (s, e) => SyncExistingSources(),
                "Refresh read-only QuestGivers and GenericQuests projections from the repository"));
            _openSourceToolButton = CreateToolButton("Open source .j", (s, e) => OpenCurrentSource(),
                "Open the selected synchronized JASS source after a safety warning");
            _mainTools.Items.Add(_openSourceToolButton);
            _mainTools.Items.Add(new ToolStripSeparator());
            _mainTools.Items.Add(CreateToolButton("Export changed libraries...", (s, e) => ExportLibraries(),
                "Export only changed managed and hybrid qXXX libraries"));
            _modeBadge = new ToolStripLabel("NO SELECTION")
            {
                Alignment = ToolStripItemAlignment.Right,
                Font = new Font("Segoe UI Semibold", 8.5f),
                ForeColor = Color.DimGray,
                Margin = new Padding(8, 2, 4, 2),
                Padding = new Padding(8, 2, 8, 2)
            };
            _mainTools.Items.Add(_modeBadge);
            Controls.Add(_mainTools);
        }

        private void BuildWorkspace()
        {
            _workspaceSplit.Dock = DockStyle.Fill;
            _workspaceSplit.SplitterWidth = 5;
            _workspaceSplit.FixedPanel = FixedPanel.Panel1;
            Controls.Add(_workspaceSplit);
            _workspaceSplit.BringToFront();

            var left = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(10),
                BackColor = Color.FromArgb(248, 250, 253)
            };
            _workspaceSplit.Panel1.Controls.Add(left);
            var navigationHeader = new Label
            {
                Dock = DockStyle.Top,
                Height = 42,
                Text = "Quest Library",
                Font = new Font("Segoe UI Semibold", 12f),
                ForeColor = Color.FromArgb(32, 45, 64),
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(2, 0, 0, 0)
            };
            var searchPanel = new Panel { Dock = DockStyle.Top, Height = 40, Padding = new Padding(0, 4, 0, 7) };
            _navigationSearch.Dock = DockStyle.Fill;
            _navigationSearch.PlaceholderText = "Find giver or quest (Ctrl+F)";
            _navigationSearch.BorderStyle = BorderStyle.FixedSingle;
            _navigationSearch.KeyDown += NavigationSearchKeyDown;
            searchPanel.Controls.Add(_navigationSearch);
            searchPanel.Controls.Add(new Label
            {
                Dock = DockStyle.Left,
                Width = 52,
                Text = "Find:",
                TextAlign = ContentAlignment.MiddleLeft,
                ForeColor = Color.FromArgb(78, 89, 103)
            });
            _navigation.Dock = DockStyle.Fill;
            _navigation.HideSelection = false;
            _navigation.FullRowSelect = true;
            _navigation.ShowNodeToolTips = true;
            _navigation.ItemHeight = 23;
            _navigation.Indent = 20;
            _navigation.BorderStyle = BorderStyle.FixedSingle;
            _navigation.BackColor = Color.White;
            _navigation.AfterSelect += NavigationAfterSelect;
            left.Controls.Add(_navigation);
            left.Controls.Add(searchPanel);
            left.Controls.Add(navigationHeader);
            _navigation.BringToFront();

            _tabs.Dock = DockStyle.Fill;
            _tabs.Padding = new Point(14, 5);
            _tabs.TabPages.Add(CreateGiverTab());
            _tabs.TabPages.Add(CreateQuestTab());
            _tabs.TabPages.Add(CreateSequencesTab());
            _tabs.TabPages.Add(CreatePreviewTab());
            _tabs.TabPages.Add(CreateRelationshipsTab());
            _tabs.TabPages.Add(CreateVoicelinesTab());
            foreach (PropertyGrid propertyGrid in new[]
                     {
                         _giverProperties, _questProperties, _rewardProperties, _objectiveProperties,
                         _sequenceProperties, _stepProperties
                     })
            {
                StylePropertyGrid(propertyGrid);
            }

            BuildOwnershipBanner();
            BuildOverviewPanel();
            var rightLayout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 1,
                RowCount = 2,
                BackColor = Color.White
            };
            rightLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
            rightLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 68f));
            rightLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
            var editorHost = new Panel { Dock = DockStyle.Fill, BackColor = Color.White };
            editorHost.Controls.Add(_tabs);
            editorHost.Controls.Add(_overviewPanel);
            _overviewPanel.BringToFront();
            rightLayout.Controls.Add(_ownershipBanner, 0, 0);
            rightLayout.Controls.Add(editorHost, 0, 1);
            _workspaceSplit.Panel2.Controls.Add(rightLayout);
        }

        private void BuildOwnershipBanner()
        {
            _ownershipBanner.Dock = DockStyle.Fill;
            _ownershipBanner.Margin = Padding.Empty;
            _ownershipBanner.Padding = Padding.Empty;
            _ownershipBanner.BackColor = Color.FromArgb(239, 243, 248);

            _ownershipAccent.Dock = DockStyle.Fill;
            _ownershipAccent.BackColor = Color.FromArgb(104, 118, 138);

            _ownershipTitle.Dock = DockStyle.Top;
            _ownershipTitle.Height = 24;
            _ownershipTitle.Font = new Font("Segoe UI Semibold", 10f);
            _ownershipTitle.ForeColor = Color.FromArgb(32, 45, 64);
            _ownershipTitle.Text = "Select a quest giver or quest";

            _ownershipDetails.Dock = DockStyle.Fill;
            _ownershipDetails.AutoEllipsis = true;
            _ownershipDetails.ForeColor = Color.FromArgb(77, 88, 104);
            _ownershipDetails.Text = "Choose a folder or record from the Quest Library.";

            _openSourceButton.Dock = DockStyle.Fill;
            _openSourceButton.Text = "Open source .j";
            _openSourceButton.FlatStyle = FlatStyle.System;
            _openSourceButton.Margin = new Padding(6, 10, 12, 10);
            _openSourceButton.Visible = false;
            _openSourceButton.Click += (s, e) => OpenCurrentSource();

            var textPanel = new Panel { Dock = DockStyle.Fill, Padding = new Padding(14, 8, 10, 7) };
            textPanel.Controls.Add(_ownershipDetails);
            textPanel.Controls.Add(_ownershipTitle);
            var layout = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, RowCount = 1 };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 6f));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f));
            layout.ColumnStyles.Add(_sourceButtonColumn);
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));
            layout.Controls.Add(_ownershipAccent, 0, 0);
            layout.Controls.Add(textPanel, 1, 0);
            layout.Controls.Add(_openSourceButton, 2, 0);
            _ownershipBanner.Controls.Add(layout);
        }

        private void BuildOverviewPanel()
        {
            _overviewPanel.Dock = DockStyle.Fill;
            _overviewPanel.BackColor = Color.FromArgb(243, 246, 250);

            var layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 3,
                RowCount = 3,
                BackColor = Color.Transparent
            };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 720f));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 50f));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 360f));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 50f));

            var card = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle,
                Padding = new Padding(30)
            };
            _overviewTitle.Dock = DockStyle.Top;
            _overviewTitle.Height = 44;
            _overviewTitle.Font = new Font("Segoe UI Semibold", 18f);
            _overviewTitle.ForeColor = Color.FromArgb(31, 44, 62);
            _overviewTitle.Text = "Quest Designer";

            var description = new Label
            {
                Dock = DockStyle.Top,
                Height = 62,
                Font = new Font("Segoe UI", 10f),
                ForeColor = Color.FromArgb(75, 86, 101),
                Text = "Browse synchronized JASS under the repository folders, or create database-managed " +
                       "content that WC3 Manager can validate, preview, and export."
            };
            _overviewStats.Dock = DockStyle.Top;
            _overviewStats.Height = 38;
            _overviewStats.Font = new Font("Segoe UI Semibold", 10f);
            _overviewStats.ForeColor = Color.FromArgb(43, 93, 140);

            var actions = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 52,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false,
                Padding = new Padding(0, 7, 0, 5)
            };
            var syncButton = CreateOverviewButton("Sync JASS sources", Color.FromArgb(42, 103, 158));
            syncButton.Click += (s, e) => SyncExistingSources();
            var newGiverButton = CreateOverviewButton("New database giver", Color.FromArgb(68, 118, 74));
            newGiverButton.Click += (s, e) => NewGiver();
            var refreshButton = CreateOverviewButton("Refresh", Color.FromArgb(98, 107, 120));
            refreshButton.Click += (s, e) => RefreshData();
            actions.Controls.Add(syncButton);
            actions.Controls.Add(newGiverButton);
            actions.Controls.Add(refreshButton);

            var ownershipGuide = new Label
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(14, 12, 14, 8),
                BackColor = Color.FromArgb(247, 249, 252),
                ForeColor = Color.FromArgb(61, 72, 88),
                Font = new Font("Segoe UI", 9.5f),
                Text = "SOURCE / EXTERNAL  •  Only uniquely mapped literals are editable; custom logic stays source-only.\n\n" +
                       "MANAGED  •  Edit in WC3 Manager and export only when the generated library changes.\n\n" +
                       "HYBRID  •  Generate a scaffold, then manually reconcile hand-owned hooks."
            };

            card.Controls.Add(ownershipGuide);
            card.Controls.Add(actions);
            card.Controls.Add(_overviewStats);
            card.Controls.Add(description);
            card.Controls.Add(_overviewTitle);
            layout.Controls.Add(card, 1, 1);
            _overviewPanel.Controls.Add(layout);
        }

        private static Button CreateOverviewButton(string text, Color color)
        {
            return new Button
            {
                Text = text,
                AutoSize = false,
                Width = 170,
                Height = 34,
                Margin = new Padding(0, 0, 10, 0),
                FlatStyle = FlatStyle.Flat,
                BackColor = color,
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 9f),
                Cursor = Cursors.Hand
            };
        }

        private static void StylePropertyGrid(PropertyGrid grid)
        {
            grid.PropertySort = PropertySort.Categorized;
            grid.ViewBackColor = Color.White;
            grid.ViewForeColor = Color.FromArgb(40, 48, 58);
            grid.LineColor = Color.FromArgb(220, 225, 232);
            grid.CategoryForeColor = Color.FromArgb(41, 82, 122);
            grid.HelpBackColor = Color.FromArgb(247, 249, 252);
            grid.HelpForeColor = Color.FromArgb(65, 75, 88);
        }

        private void ConfigureSourceFieldTooltips()
        {
            _sourceFieldToolTip.InitialDelay = 350;
            _sourceFieldToolTip.ReshowDelay = 150;
            _sourceFieldToolTip.AutoPopDelay = 9000;
            const string message =
                "Gray fields contain custom, shared, computed, or unmapped JASS logic and are only editable in the repository .j file. Select a field to see its specific reason below.";
            foreach (PropertyGrid grid in new[]
                     {
                         _giverProperties, _questProperties, _rewardProperties, _objectiveProperties,
                         _sequenceProperties, _stepProperties
                     })
            {
                _sourceFieldToolTip.SetToolTip(grid, message);
            }
        }

        private TabPage CreateGiverTab()
        {
            var page = new TabPage("Quest giver") { BackColor = Color.White };
            var note = new Label
            {
                Dock = DockStyle.Top,
                Height = 44,
                Padding = new Padding(12),
                Text = "Giver binding and camera configuration. Gray synchronized fields contain custom or unmapped JASS logic; select or hover them for the source-only reason.",
                ForeColor = Color.FromArgb(53, 74, 96),
                BackColor = Color.FromArgb(239, 245, 251)
            };
            _giverProperties.Dock = DockStyle.Fill;
            _giverProperties.HelpVisible = true;
            _giverProperties.ToolbarVisible = false;
            page.Controls.Add(_giverProperties);
            page.Controls.Add(note);
            return page;
        }

        private TabPage CreateQuestTab()
        {
            var page = new TabPage("Quest");
            var vertical = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 300
            };
            page.Controls.Add(vertical);
            var questTop = new Panel { Dock = DockStyle.Fill };
            vertical.Panel1.Controls.Add(questTop);
            var receiverRow = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 38,
                Padding = new Padding(6),
                WrapContents = false
            };
            receiverRow.Controls.Add(new Label
            {
                Text = "Turn-in giver:",
                Width = 90,
                TextAlign = ContentAlignment.MiddleLeft
            });
            _questReceiver.Width = 360;
            _questReceiver.DropDownStyle = ComboBoxStyle.DropDownList;
            _questReceiver.SelectedIndexChanged += (s, e) =>
            {
                if (_currentQuest != null && _questReceiver.SelectedItem is QuestChoice choice)
                {
                    _currentQuest.ReceiverGiverId = choice.Id == 0 ? null : choice.Id;
                    RefreshPreview();
                }
            };
            receiverRow.Controls.Add(_questReceiver);
            var iconButton = new Button
            {
                Text = "Choose icon...",
                Width = 105,
                Height = 25,
                Margin = new Padding(12, 0, 0, 0)
            };
            iconButton.Click += (s, e) => ChooseQuestIcon();
            receiverRow.Controls.Add(iconButton);
            questTop.Controls.Add(receiverRow);
            _questProperties.Dock = DockStyle.Fill;
            _questProperties.ToolbarVisible = false;
            _questProperties.PropertyValueChanged += (s, e) => RefreshPreview();
            questTop.Controls.Add(_questProperties);
            _questProperties.BringToFront();

            var lower = new SplitContainer
            {
                Dock = DockStyle.Fill,
                SplitterDistance = 620
            };
            vertical.Panel2.Controls.Add(lower);
            lower.Panel1.Controls.Add(CreateObjectiveEditor());

            var childTabs = new TabControl { Dock = DockStyle.Fill };
            var objectiveTab = new TabPage("Selected objective");
            _objectiveProperties.Dock = DockStyle.Fill;
            _objectiveProperties.ToolbarVisible = false;
            _objectiveProperties.PropertyValueChanged += (s, e) =>
            {
                _objectivesGrid.Refresh();
                RefreshPreview();
            };
            objectiveTab.Controls.Add(_objectiveProperties);
            childTabs.TabPages.Add(objectiveTab);
            var rewardsTab = new TabPage("Rewards");
            _rewardProperties.Dock = DockStyle.Fill;
            _rewardProperties.ToolbarVisible = false;
            _rewardProperties.PropertyValueChanged += (s, e) => RefreshPreview();
            rewardsTab.Controls.Add(_rewardProperties);
            childTabs.TabPages.Add(rewardsTab);
            var prereqTab = new TabPage("Prerequisites (max 4)");
            _prerequisites.Dock = DockStyle.Fill;
            _prerequisites.CheckOnClick = true;
            prereqTab.Controls.Add(_prerequisites);
            childTabs.TabPages.Add(prereqTab);
            lower.Panel2.Controls.Add(childTabs);
            return page;
        }

        private Control CreateObjectiveEditor()
        {
            var panel = new Panel { Dock = DockStyle.Fill };
            var tools = new ToolStrip { Dock = DockStyle.Top, GripStyle = ToolStripGripStyle.Hidden };
            tools.Items.Add(CreateToolButton("Add objective", (s, e) => AddObjective()));
            tools.Items.Add(CreateToolButton("Remove", (s, e) => RemoveObjective()));
            tools.Items.Add(CreateToolButton("Move up", (s, e) => MoveObjective(-1)));
            tools.Items.Add(CreateToolButton("Move down", (s, e) => MoveObjective(1)));
            panel.Controls.Add(tools);
            ConfigureObjectiveGrid();
            panel.Controls.Add(_objectivesGrid);
            _objectivesGrid.BringToFront();
            return panel;
        }

        private TabPage CreateSequencesTab()
        {
            var page = new TabPage("Dialog / events");
            var split = new SplitContainer { Dock = DockStyle.Fill, SplitterDistance = 280 };
            page.Controls.Add(split);
            var left = new Panel { Dock = DockStyle.Fill };
            split.Panel1.Controls.Add(left);
            var tools = new ToolStrip { Dock = DockStyle.Top, GripStyle = ToolStripGripStyle.Hidden };
            tools.Items.Add(CreateToolButton("New", (s, e) => NewSequence()));
            tools.Items.Add(CreateToolButton("Save", (s, e) => SaveSequence()));
            tools.Items.Add(CreateToolButton("Delete", (s, e) => DeleteSequence()));
            left.Controls.Add(tools);
            _sequenceList.Dock = DockStyle.Fill;
            _sequenceList.DisplayMember = nameof(QuestSequenceDefinition.DisplayName);
            _sequenceList.SelectedIndexChanged += SequenceSelected;
            left.Controls.Add(_sequenceList);
            _sequenceList.BringToFront();

            var right = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 260
            };
            split.Panel2.Controls.Add(right);
            var sequenceTop = new Panel { Dock = DockStyle.Fill };
            right.Panel1.Controls.Add(sequenceTop);
            var questLink = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 38,
                Padding = new Padding(6),
                WrapContents = false
            };
            questLink.Controls.Add(new Label
            {
                Text = "Linked quest:",
                Width = 90,
                TextAlign = ContentAlignment.MiddleLeft
            });
            _sequenceQuest.Width = 360;
            _sequenceQuest.DropDownStyle = ComboBoxStyle.DropDownList;
            questLink.Controls.Add(_sequenceQuest);
            sequenceTop.Controls.Add(questLink);
            _sequenceProperties.Dock = DockStyle.Fill;
            _sequenceProperties.ToolbarVisible = false;
            sequenceTop.Controls.Add(_sequenceProperties);
            _sequenceProperties.BringToFront();

            var stepSplit = new SplitContainer { Dock = DockStyle.Fill, SplitterDistance = 620 };
            right.Panel2.Controls.Add(stepSplit);
            var stepListPanel = new Panel { Dock = DockStyle.Fill };
            stepSplit.Panel1.Controls.Add(stepListPanel);
            var stepTools = new ToolStrip { Dock = DockStyle.Top, GripStyle = ToolStripGripStyle.Hidden };
            var addStep = new ToolStripDropDownButton("Add step");
            foreach (var option in new[]
            {
                ("Dialog line", "line"), ("Delay", "delay"), ("Face unit", "face_unit"),
                ("Face point", "face_point"), ("Look at unit", "look_unit"),
                ("Look at point", "look_point"), ("Reset look", "reset_look"),
                ("Fade out", "fade_out"), ("Fade in", "fade_in"), ("Custom action", "action")
            })
            {
                string stepType = option.Item2;
                addStep.DropDownItems.Add(option.Item1, null, (s, e) => AddStep(stepType));
            }
            stepTools.Items.Add(addStep);
            stepTools.Items.Add(CreateToolButton("Remove", (s, e) => RemoveStep()));
            stepTools.Items.Add(CreateToolButton("Up", (s, e) => MoveStep(-1)));
            stepTools.Items.Add(CreateToolButton("Down", (s, e) => MoveStep(1)));
            stepListPanel.Controls.Add(stepTools);
            ConfigureStepGrid();
            stepListPanel.Controls.Add(_stepsGrid);
            _stepsGrid.BringToFront();
            _stepProperties.Dock = DockStyle.Fill;
            _stepProperties.ToolbarVisible = false;
            _stepProperties.PropertyValueChanged += (s, e) => _stepsGrid.Refresh();
            stepSplit.Panel2.Controls.Add(_stepProperties);
            return page;
        }

        private TabPage CreatePreviewTab()
        {
            var page = new TabPage("Quest log preview");
            page.Controls.Add(_preview);
            return page;
        }

        private TabPage CreateRelationshipsTab()
        {
            var page = new TabPage("Relationships");
            var split = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 330
            };
            page.Controls.Add(split);
            _relationships.Dock = DockStyle.Fill;
            split.Panel1.Controls.Add(_relationships);
            var dependencyPanel = new Panel { Dock = DockStyle.Fill };
            split.Panel2.Controls.Add(dependencyPanel);
            var tools = new ToolStrip { Dock = DockStyle.Top, GripStyle = ToolStripGripStyle.Hidden };
            tools.Items.Add(CreateToolButton("Add dependency", (s, e) => AddDependency()));
            tools.Items.Add(CreateToolButton("Remove", (s, e) => RemoveDependency()));
            tools.Items.Add(CreateToolButton("Save dependencies", (s, e) => SaveDependencies()));
            tools.Items.Add(new ToolStripLabel("World Editor follow-up is exported beside each qXXX scaffold."));
            dependencyPanel.Controls.Add(tools);
            _dependenciesGrid.Dock = DockStyle.Fill;
            _dependenciesGrid.AutoGenerateColumns = true;
            dependencyPanel.Controls.Add(_dependenciesGrid);
            _dependenciesGrid.BringToFront();
            return page;
        }

        private TabPage CreateVoicelinesTab()
        {
            var page = new TabPage("Voicelines");
            var panel = new Panel { Dock = DockStyle.Fill };
            page.Controls.Add(panel);
            var tools = new ToolStrip { Dock = DockStyle.Top, GripStyle = ToolStripGripStyle.Hidden };
            tools.Items.Add(CreateToolButton("Add", (s, e) => AddVoiceline()));
            tools.Items.Add(CreateToolButton("Save all", (s, e) => SaveVoicelines()));
            tools.Items.Add(CreateToolButton("Delete selected", (s, e) => DeleteVoiceline()));
            tools.Items.Add(new ToolStripLabel(
                "Catalog references source-owned Voicelines_*.j constants; Verified means reconciled with source/audio."));
            panel.Controls.Add(tools);
            _voicelinesGrid.Dock = DockStyle.Fill;
            _voicelinesGrid.AutoGenerateColumns = true;
            panel.Controls.Add(_voicelinesGrid);
            _voicelinesGrid.BringToFront();
            return page;
        }

        private void OnShown(object sender, EventArgs e)
        {
            try
            {
                int preferredNavigationWidth = Math.Min(360, Math.Max(280, _workspaceSplit.Width - 700));
                _workspaceSplit.SplitterDistance = preferredNavigationWidth;
                _workspaceSplit.Panel1MinSize = 280;
                _workspaceSplit.Panel2MinSize = 700;
                if (!_repository.SchemaExists())
                {
                    MessageBox.Show(
                        "The Quest Designer schema is not installed. Run:\n\n" +
                        "WC3_Database\\migrations\\run_all_quest_migrations.sql\n\n" +
                        "against a non-production wc3_pots database, then reopen the designer.",
                        "Quest Designer schema missing",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning);
                    Close();
                    return;
                }
                RefreshData();
            }
            catch (Exception ex)
            {
                ShowError("Could not open the Quest Designer", ex);
                Close();
            }
        }

        private void RefreshData(int? selectGiverId = null, int? selectQuestId = null)
        {
            try
            {
                _loading = true;
                selectGiverId ??= _currentGiver?.Id;
                selectQuestId ??= _currentQuest?.Id;
                _givers = _repository.GetGivers();
                _quests = _repository.GetQuests();
                _navigation.BeginUpdate();
                _navigation.Nodes.Clear();
                TreeNode nodeToSelect = null;
                var questGiversRoot = new TreeNode("QuestGivers") { Name = "source:QuestGivers" };
                var genericQuestsRoot = new TreeNode("GenericQuests") { Name = "source:GenericQuests" };
                var databaseRoot = new TreeNode("Database-authored") { Name = "source:Database" };

                string sourceRoot = QuestSourceSynchronizer.FindQuestsAndDialogsRoot();
                if (!string.IsNullOrWhiteSpace(sourceRoot))
                {
                    AddRepositoryFolders(questGiversRoot, Path.Combine(sourceRoot, "QuestGivers"));
                    AddRepositoryFolders(genericQuestsRoot, Path.Combine(sourceRoot, "GenericQuests"));
                }

                foreach (var giver in _givers.OrderBy(g => g.SourceFile).ThenBy(g => g.DisplayName))
                {
                    TreeNode parent = GetNavigationParent(
                        giver, questGiversRoot, genericQuestsRoot, databaseRoot);
                    TreeNode giverNode = CreateGiverNavigationNode(giver, selectGiverId, selectQuestId, ref nodeToSelect);
                    parent.Nodes.Add(giverNode);
                }

                if (questGiversRoot.Nodes.Count > 0) _navigation.Nodes.Add(questGiversRoot);
                if (genericQuestsRoot.Nodes.Count > 0) _navigation.Nodes.Add(genericQuestsRoot);
                if (databaseRoot.Nodes.Count > 0) _navigation.Nodes.Add(databaseRoot);
                _navigation.EndUpdate();
                foreach (TreeNode root in _navigation.Nodes) root.Expand();
                LoadVoicelines();
                BuildRelationshipTree();
                _loading = false;
                if (nodeToSelect != null)
                {
                    ExpandAncestors(nodeToSelect);
                    _navigation.SelectedNode = nodeToSelect;
                    nodeToSelect.EnsureVisible();
                }
                else
                {
                    ClearSelection();
                }
                SetStatus($"Loaded {_givers.Count} quest givers and {_quests.Count} quests.");
            }
            catch (Exception ex)
            {
                ShowError("Could not refresh quest data", ex);
            }
            finally
            {
                _loading = false;
            }
        }

        private TreeNode CreateGiverNavigationNode(QuestGiverDefinition giver, int? selectGiverId,
            int? selectQuestId, ref TreeNode nodeToSelect)
        {
            var giverNode = new TreeNode(giver.DisplayName)
            {
                Tag = giver,
                ForeColor = !giver.Enabled
                    ? Color.Gray
                    : IsSourceOwned(giver) ? Color.FromArgb(38, 91, 139) : SystemColors.WindowText,
                ToolTipText = IsSourceOwned(giver)
                    ? "Guarded synchronized source; only uniquely mapped literals are editable: " + giver.SourceFile
                    : $"{giver.OwnershipMode} database record"
            };
            foreach (var quest in _quests.Where(q => q.QuestGiverId == giver.Id)
                         .OrderBy(q => q.SortOrder).ThenBy(q => q.Title))
            {
                var questNode = new TreeNode(quest.Draft ? $"[Draft] {quest.Title}" : quest.Title)
                {
                    Tag = quest,
                    ForeColor = quest.Enabled ? SystemColors.WindowText : Color.Gray
                };
                giverNode.Nodes.Add(questNode);
                if (quest.Id == selectQuestId) nodeToSelect = questNode;
            }
            if (nodeToSelect == null && giver.Id == selectGiverId) nodeToSelect = giverNode;
            return giverNode;
        }

        private static TreeNode GetNavigationParent(QuestGiverDefinition giver, TreeNode questGiversRoot,
            TreeNode genericQuestsRoot, TreeNode databaseRoot)
        {
            if (IsSourceOwned(giver))
            {
                string normalized = (giver.SourceFile ?? "").Replace('\\', '/');
                string sourceFolder = giver.SourceKind == "generic_quest" ? "GenericQuests" : "QuestGivers";
                TreeNode root = giver.SourceKind == "generic_quest" ? genericQuestsRoot : questGiversRoot;
                string[] parts = normalized.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                int sourceIndex = Array.FindIndex(parts,
                    part => string.Equals(part, sourceFolder, StringComparison.OrdinalIgnoreCase));
                for (int index = sourceIndex + 1; sourceIndex >= 0 && index < parts.Length - 1; index++)
                {
                    root = GetOrCreateFolder(root, parts[index]);
                }
                return root;
            }

            string ownership = string.IsNullOrWhiteSpace(giver.OwnershipMode)
                ? "Managed"
                : char.ToUpperInvariant(giver.OwnershipMode[0]) + giver.OwnershipMode.Substring(1).ToLowerInvariant();
            return GetOrCreateFolder(databaseRoot, ownership);
        }

        private static void AddRepositoryFolders(TreeNode parent, string directory)
        {
            if (!Directory.Exists(directory)) return;
            foreach (string childDirectory in Directory.GetDirectories(directory).OrderBy(Path.GetFileName))
            {
                TreeNode child = GetOrCreateFolder(parent, Path.GetFileName(childDirectory));
                AddRepositoryFolders(child, childDirectory);
            }
        }

        private static TreeNode GetOrCreateFolder(TreeNode parent, string name)
        {
            string key = "folder:" + name;
            TreeNode existing = parent.Nodes.Cast<TreeNode>()
                .FirstOrDefault(node => string.Equals(node.Name, key, StringComparison.OrdinalIgnoreCase));
            if (existing != null) return existing;
            var folder = new TreeNode(name) { Name = key };
            parent.Nodes.Add(folder);
            return folder;
        }

        private static void ExpandAncestors(TreeNode node)
        {
            for (TreeNode parent = node.Parent; parent != null; parent = parent.Parent) parent.Expand();
        }

        private void NavigationAfterSelect(object sender, TreeViewEventArgs e)
        {
            if (_loading) return;
            if (e.Node.Tag is QuestGiverDefinition giver)
            {
                LoadGiver(giver.Id);
                _tabs.SelectedIndex = 0;
            }
            else if (e.Node.Tag is QuestDefinition quest)
            {
                LoadQuest(quest.Id);
                _tabs.SelectedIndex = IsSourceOwned(_currentGiver) ? 3 : 1;
            }
            else
            {
                ShowOverview(e.Node.Text);
            }
        }

        private void NavigationSearchKeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode != Keys.Enter) return;
            string search = _navigationSearch.Text.Trim();
            if (search.Length == 0) return;
            var matches = EnumerateNodes(_navigation.Nodes)
                .Where(node => node.Tag is QuestGiverDefinition || node.Tag is QuestDefinition)
                .Where(node => node.Text.IndexOf(search, StringComparison.OrdinalIgnoreCase) >= 0)
                .ToList();
            if (matches.Count == 0)
            {
                SetStatus($"No quest giver or quest matched '{search}'.");
                System.Media.SystemSounds.Beep.Play();
            }
            else
            {
                int currentIndex = _lastSearchNode == null ? -1 : matches.IndexOf(_lastSearchNode);
                _lastSearchNode = matches[(currentIndex + 1) % matches.Count];
                ExpandAncestors(_lastSearchNode);
                _navigation.SelectedNode = _lastSearchNode;
                _lastSearchNode.EnsureVisible();
                SetStatus($"Match {(currentIndex + 2 > matches.Count ? 1 : currentIndex + 2)} of {matches.Count}: {_lastSearchNode.Text}");
            }
            e.SuppressKeyPress = true;
        }

        private static IEnumerable<TreeNode> EnumerateNodes(TreeNodeCollection nodes)
        {
            foreach (TreeNode node in nodes)
            {
                yield return node;
                foreach (TreeNode child in EnumerateNodes(node.Nodes)) yield return child;
            }
        }

        private void LoadGiver(int giverId)
        {
            _currentGiver = _repository.GetGiver(giverId);
            _currentQuest = null;
            _currentReward = null;
            _giverProperties.SelectedObject = _currentGiver;
            _questProperties.SelectedObject = null;
            _objectives = new BindingList<QuestObjectiveDefinition>();
            _objectivesGrid.DataSource = _objectives;
            _preview.ClearQuest();
            LoadSequences();
            LoadDependencies();
            ConfigureSourceEditing();
            _overviewPanel.Visible = false;
            UpdateOwnershipUi();
            SetStatus($"Editing quest giver {_currentGiver.DisplayName} ({_currentGiver.OwnershipMode}).");
        }

        private void LoadQuest(int questId)
        {
            _currentQuest = _repository.GetQuest(questId);
            _currentGiver = _repository.GetGiver(_currentQuest.QuestGiverId);
            _currentReward = _repository.GetReward(questId);
            _giverProperties.SelectedObject = _currentGiver;
            _questProperties.SelectedObject = _currentQuest;
            _rewardProperties.SelectedObject = _currentReward;
            LoadQuestReceiverChoices(_currentQuest.ReceiverGiverId ?? 0);
            _objectives = new BindingList<QuestObjectiveDefinition>(_repository.GetObjectives(questId));
            _objectivesGrid.DataSource = _objectives;
            _objectiveProperties.SelectedObject = _objectives.FirstOrDefault();
            LoadPrerequisites();
            LoadSequences();
            LoadDependencies();
            RefreshPreview();
            ConfigureSourceEditing();
            _overviewPanel.Visible = false;
            UpdateOwnershipUi();
            SetStatus($"Editing quest {_currentQuest.Title}.");
        }

        private void NewGiver()
        {
            ClearSourceEditing();
            _currentQuest = null;
            _currentGiver = new QuestGiverDefinition
            {
                GiverKey = "NewGiver",
                DisplayName = "New quest giver",
                LibraryName = "NewGiver",
                UnitCode = "n000"
            };
            _giverProperties.SelectedObject = _currentGiver;
            _overviewPanel.Visible = false;
            UpdateOwnershipUi();
            _tabs.SelectedIndex = 0;
            SetStatus("Configure the new giver, then Save.");
        }

        private void NewQuest()
        {
            if (_currentGiver == null || _currentGiver.Id == 0)
            {
                MessageBox.Show("Select and save a quest giver first.", "Quest Designer",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            if (IsSourceOwned(_currentGiver))
            {
                if (_sourceEditSession?.CanAddQuest != true)
                {
                    string variable = _sourceEditSession?.SuggestedQuestVariable ?? "q";
                    string giver = _sourceEditSession?.SuggestedGiverExpression ?? "null";
                    MessageBox.Show(
                        "Existing mapped quest fields can already be edited without markers. " +
                        "These markers are only the one-time opt-in for inserting brand-new standard quests.\n\n" +
                        "1. Open the source .j file.\n" +
                        "2. Inside its globals/endglobals block, add:\n\n" +
                        "// WC3M-BEGIN QUEST CONSTANTS\n// WC3M-END QUEST CONSTANTS\n\n" +
                        "3. Inside the CreateQuests registration function, after 'local QuestData " + variable +
                        "' and normally after the existing registrations, add:\n\n" +
                        $"// WC3M-BEGIN QUESTS variable={variable} giver={giver} receiver=null\n" +
                        "// WC3M-END QUESTS\n\n" +
                        "Current safety check: " +
                        (_sourceEditSession?.AddQuestReason ?? "The source could not be analyzed.") +
                        "\n\nNo source file has been changed.",
                        "Source-owned quest region required", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
            }
            _currentQuest = new QuestDefinition
            {
                QuestGiverId = _currentGiver.Id,
                QuestKey = "NewQuest",
                QuestName = "New Quest",
                Title = "New Quest",
                QuestLevel = 1,
                RequiredLevel = 1,
                ZoneId = _currentGiver.ZoneId,
                Faction = _currentGiver.Faction,
                AllowNazgrek = _currentGiver.AllowNazgrek,
                AllowZulkis = _currentGiver.AllowZulkis,
                ReceiverDisplayName = _currentGiver.DisplayName,
                SortOrder = _repository.GetNextQuestSortOrder(_currentGiver.Id)
            };
            _currentReward = new QuestRewardDefinition();
            _objectives = new BindingList<QuestObjectiveDefinition>();
            _questProperties.SelectedObject = _currentQuest;
            _rewardProperties.SelectedObject = _currentReward;
            _objectivesGrid.DataSource = _objectives;
            LoadQuestReceiverChoices(0);
            LoadPrerequisites();
            if (IsSourceOwned(_currentGiver)) ConfigureNewSourceQuestEditing();
            _overviewPanel.Visible = false;
            UpdateOwnershipUi();
            _tabs.SelectedIndex = 1;
            RefreshPreview();
            SetStatus("Configure the new quest, then Save.");
        }

        private void SaveCurrent()
        {
            try
            {
                if (IsSourceOwned(_currentGiver))
                {
                    SaveSourceChanges();
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Dialog / events")
                {
                    SaveSequence();
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Relationships")
                {
                    SaveDependencies();
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Voicelines")
                {
                    SaveVoicelines();
                    return;
                }
                if (_currentQuest != null)
                {
                    _objectivesGrid.EndEdit();
                    RenumberObjectives();
                    _currentQuest.ReceiverGiverId = _questReceiver.SelectedItem is QuestChoice receiver && receiver.Id != 0
                        ? receiver.Id
                        : null;
                    if (_currentQuest.ReceiverGiverId.HasValue)
                    {
                        var receiverGiver = _givers
                            .FirstOrDefault(g => g.Id == _currentQuest.ReceiverGiverId.Value);
                        if (receiverGiver != null)
                        {
                            _currentQuest.ReceiverDisplayName = receiverGiver.DisplayName;
                        }
                    }
                    var prerequisiteIds = _prerequisites.CheckedItems
                        .Cast<QuestChoice>()
                        .Select(choice => choice.Id)
                        .ToList();
                    int id = _repository.SaveQuest(_currentQuest, _objectives, _currentReward, prerequisiteIds);
                    RefreshData(_currentGiver.Id, id);
                    SetStatus("Quest saved.");
                }
                else if (_currentGiver != null)
                {
                    int id = _repository.SaveGiver(_currentGiver);
                    RefreshData(id, null);
                    SetStatus("Quest giver saved.");
                }
            }
            catch (Exception ex)
            {
                ShowError("Could not save", ex);
            }
        }

        private void DeleteCurrent()
        {
            try
            {
                if (IsSourceOwned(_currentGiver))
                {
                    MessageBox.Show(
                        "Synchronized JASS records are retained as a source projection and cannot be deleted here.",
                        "Read-only source library", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Dialog / events" && _currentSequence != null)
                {
                    DeleteSequence();
                    return;
                }
                if (_currentQuest != null && _currentQuest.Id != 0)
                {
                    if (!ConfirmDelete($"Delete quest '{_currentQuest.Title}'?")) return;
                    int giverId = _currentGiver.Id;
                    _repository.DeleteQuest(_currentQuest.Id);
                    RefreshData(giverId, null);
                }
                else if (_currentGiver != null && _currentGiver.Id != 0)
                {
                    if (!ConfirmDelete(
                            $"Delete quest giver '{_currentGiver.DisplayName}' and all of its designer data?")) return;
                    _repository.DeleteGiver(_currentGiver.Id);
                    RefreshData();
                }
            }
            catch (Exception ex)
            {
                ShowError("Could not delete", ex);
            }
        }

        private void AddObjective()
        {
            if (_currentQuest == null) return;
            int max = _currentQuest.RequiresTurnIn && !_currentQuest.AutoComplete ? 7 : 8;
            if (_objectives.Count >= max)
            {
                MessageBox.Show($"This quest supports at most {max} authored objectives.", "Quest Designer",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            var objective = new QuestObjectiveDefinition
            {
                QuestId = _currentQuest.Id,
                ObjectiveKey = "Objective" + (_objectives.Count + 1),
                DisplayOrder = _objectives.Count + 1,
                Text = "New objective"
            };
            _objectives.Add(objective);
            SelectGridItem(_objectivesGrid, _objectives.Count - 1);
            if (IsSourceOwned(_currentGiver)) ShowSourceObjectiveProperties(objective);
            else _objectiveProperties.SelectedObject = objective;
            RefreshPreview();
        }

        private void RemoveObjective()
        {
            int index = CurrentGridIndex(_objectivesGrid);
            if (index < 0 || index >= _objectives.Count) return;
            _objectives.RemoveAt(index);
            RenumberObjectives();
            var selected = _objectives.ElementAtOrDefault(Math.Min(index, _objectives.Count - 1));
            if (IsSourceOwned(_currentGiver)) ShowSourceObjectiveProperties(selected);
            else _objectiveProperties.SelectedObject = selected;
            RefreshPreview();
        }

        private void MoveObjective(int direction)
        {
            int index = CurrentGridIndex(_objectivesGrid);
            int target = index + direction;
            if (index < 0 || target < 0 || target >= _objectives.Count) return;
            var item = _objectives[index];
            _objectives.RemoveAt(index);
            _objectives.Insert(target, item);
            RenumberObjectives();
            SelectGridItem(_objectivesGrid, target);
            RefreshPreview();
        }

        private void ConfigureObjectiveGrid()
        {
            _objectivesGrid.Dock = DockStyle.Fill;
            _objectivesGrid.AutoGenerateColumns = false;
            _objectivesGrid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(QuestObjectiveDefinition.DisplayOrder), HeaderText = "#", Width = 38, ReadOnly = true
            });
            _objectivesGrid.Columns.Add(new DataGridViewComboBoxColumn
            {
                DataPropertyName = nameof(QuestObjectiveDefinition.ObjectiveType),
                HeaderText = "Type",
                Width = 100,
                DataSource = new[] { "item", "kill", "escort", "talk", "find", "goto", "reputation", "investigate", "manual" }
            });
            _objectivesGrid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(QuestObjectiveDefinition.Text), HeaderText = "Quest log objective", AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill
            });
            _objectivesGrid.SelectionChanged += (s, e) =>
            {
                int index = CurrentGridIndex(_objectivesGrid);
                var objective = index >= 0 && index < _objectives.Count ? _objectives[index] : null;
                if (IsSourceOwned(_currentGiver)) ShowSourceObjectiveProperties(objective);
                else _objectiveProperties.SelectedObject = objective;
            };
            _objectivesGrid.CellValueChanged += (s, e) => RefreshPreview();
        }

        private void LoadPrerequisites()
        {
            _prerequisites.Items.Clear();
            if (_currentQuest == null) return;
            var selected = _currentQuest.Id == 0
                ? new HashSet<int>()
                : _repository.GetPrerequisiteIds(_currentQuest.Id).ToHashSet();
            foreach (var quest in _quests.Where(q => q.Id != _currentQuest.Id).OrderBy(q => q.Title))
            {
                var giver = _givers.FirstOrDefault(g => g.Id == quest.QuestGiverId);
                var choice = new QuestChoice(quest.Id, $"{giver?.DisplayName} / {quest.Title} [{quest.QuestType}]");
                int index = _prerequisites.Items.Add(choice);
                _prerequisites.SetItemChecked(index, selected.Contains(quest.Id));
            }
        }

        private void ChooseQuestIcon()
        {
            if (_currentQuest == null) return;
            using var dialog = new IconSelectorDialog(_currentQuest.IconPath);
            if (dialog.ShowDialog(this) == DialogResult.OK)
            {
                _currentQuest.IconPath = dialog.SelectedIconPath ?? "";
                _questProperties.Refresh();
                RefreshPreview();
            }
        }

        private void LoadQuestReceiverChoices(int selectedId)
        {
            var choices = new List<QuestChoice>
            {
                new QuestChoice(0, _currentGiver == null
                    ? "(same as giver / no runtime receiver)"
                    : $"(same as giver: {_currentGiver.DisplayName})")
            };
            choices.AddRange(_givers.OrderBy(g => g.DisplayName)
                .Select(g => new QuestChoice(g.Id, g.DisplayName)));
            _questReceiver.DataSource = choices;
            _questReceiver.DisplayMember = nameof(QuestChoice.Label);
            for (int i = 0; i < choices.Count; i++)
            {
                if (choices[i].Id == selectedId)
                {
                    _questReceiver.SelectedIndex = i;
                    return;
                }
            }
            _questReceiver.SelectedIndex = 0;
        }

        private void LoadSequences()
        {
            _currentSequence = null;
            _sequenceProperties.SelectedObject = null;
            _steps = new BindingList<QuestSequenceStepDefinition>();
            _stepsGrid.DataSource = _steps;
            _sequenceList.DataSource = null;
            _sequenceQuest.DataSource = null;
            if (_currentGiver == null || _currentGiver.Id == 0) return;
            var choices = new List<QuestChoice> { new QuestChoice(0, "(giver-level sequence)") };
            choices.AddRange(_quests.Where(q => q.QuestGiverId == _currentGiver.Id)
                .OrderBy(q => q.SortOrder).Select(q => new QuestChoice(q.Id, q.Title)));
            choices.AddRange(_quests
                .Where(q => q.QuestGiverId != _currentGiver.Id && q.ReceiverGiverId == _currentGiver.Id)
                .OrderBy(q => q.Title)
                .Select(q =>
                {
                    var source = _givers.FirstOrDefault(g => g.Id == q.QuestGiverId);
                    return new QuestChoice(q.Id, $"Turn-in: {source?.DisplayName} / {q.Title}");
                }));
            _sequenceQuest.DataSource = choices;
            _sequenceQuest.DisplayMember = nameof(QuestChoice.Label);
            _sequenceList.DataSource = _repository.GetSequences(_currentGiver.Id);
        }

        private void SequenceSelected(object sender, EventArgs e)
        {
            if (_loading || !(_sequenceList.SelectedItem is QuestSequenceDefinition sequence)) return;
            _currentSequence = sequence;
            _sequenceProperties.SelectedObject = sequence;
            _steps = new BindingList<QuestSequenceStepDefinition>(_repository.GetSequenceSteps(sequence.Id));
            _stepsGrid.DataSource = _steps;
            _stepProperties.SelectedObject = _steps.FirstOrDefault();
            SelectSequenceQuest(sequence.QuestId ?? 0);
        }

        private void NewSequence()
        {
            if (_currentGiver == null || _currentGiver.Id == 0)
            {
                MessageBox.Show("Select a saved quest giver first.", "Quest Designer",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            _currentSequence = new QuestSequenceDefinition
            {
                QuestGiverId = _currentGiver.Id,
                SequenceKey = "NewSequence",
                DisplayName = "New sequence"
            };
            _steps = new BindingList<QuestSequenceStepDefinition>();
            _sequenceProperties.SelectedObject = _currentSequence;
            _stepsGrid.DataSource = _steps;
            SelectSequenceQuest(0);
        }

        private void SaveSequence()
        {
            if (_currentSequence == null) return;
            try
            {
                _stepsGrid.EndEdit();
                RenumberSteps();
                _currentSequence.QuestId = _sequenceQuest.SelectedItem is QuestChoice choice && choice.Id != 0
                    ? choice.Id
                    : null;
                int id = _repository.SaveSequence(_currentSequence, _steps);
                LoadSequences();
                SelectListSequence(id);
                SetStatus("Sequence saved.");
            }
            catch (Exception ex)
            {
                ShowError("Could not save sequence", ex);
            }
        }

        private void DeleteSequence()
        {
            if (_currentSequence == null || _currentSequence.Id == 0) return;
            if (!ConfirmDelete($"Delete sequence '{_currentSequence.DisplayName}'?")) return;
            try
            {
                _repository.DeleteSequence(_currentSequence.Id);
                LoadSequences();
                SetStatus("Sequence deleted.");
            }
            catch (Exception ex)
            {
                ShowError("Could not delete sequence", ex);
            }
        }

        private void AddStep(string type)
        {
            if (_currentSequence == null) return;
            if (_steps.Count >= 100) return;
            var step = new QuestSequenceStepDefinition
            {
                SequenceId = _currentSequence.Id,
                DisplayOrder = _steps.Count + 1,
                StepType = type,
                SpeakerBinding = "Giver",
                SpeakerName = _currentGiver?.DisplayName ?? "",
                Text = type == "line" ? "New dialog line" : "",
                ActionHook = type == "action" ? "ImplementAction" : ""
            };
            _steps.Add(step);
            SelectGridItem(_stepsGrid, _steps.Count - 1);
            _stepProperties.SelectedObject = step;
        }

        private void RemoveStep()
        {
            int index = CurrentGridIndex(_stepsGrid);
            if (index < 0 || index >= _steps.Count) return;
            _steps.RemoveAt(index);
            RenumberSteps();
        }

        private void MoveStep(int direction)
        {
            int index = CurrentGridIndex(_stepsGrid);
            int target = index + direction;
            if (index < 0 || target < 0 || target >= _steps.Count) return;
            var step = _steps[index];
            _steps.RemoveAt(index);
            _steps.Insert(target, step);
            RenumberSteps();
            SelectGridItem(_stepsGrid, target);
        }

        private void ConfigureStepGrid()
        {
            _stepsGrid.Dock = DockStyle.Fill;
            _stepsGrid.AutoGenerateColumns = false;
            _stepsGrid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(QuestSequenceStepDefinition.DisplayOrder), HeaderText = "#", Width = 38, ReadOnly = true
            });
            _stepsGrid.Columns.Add(new DataGridViewComboBoxColumn
            {
                DataPropertyName = nameof(QuestSequenceStepDefinition.StepType),
                HeaderText = "Step",
                Width = 100,
                DataSource = new[] { "line", "delay", "face_unit", "face_point", "look_unit", "look_point", "reset_look", "fade_out", "fade_in", "action" }
            });
            _stepsGrid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(QuestSequenceStepDefinition.SpeakerName), HeaderText = "Speaker", Width = 120
            });
            _stepVoiceColumn.DataPropertyName = nameof(QuestSequenceStepDefinition.VoicelineId);
            _stepVoiceColumn.HeaderText = "Voiceline";
            _stepVoiceColumn.Width = 190;
            _stepVoiceColumn.ValueMember = nameof(QuestVoicelineDefinition.Id);
            _stepVoiceColumn.DisplayMember = nameof(QuestVoicelineDefinition.DisplayLabel);
            _stepVoiceColumn.DefaultCellStyle.NullValue = "";
            _stepsGrid.Columns.Add(_stepVoiceColumn);
            _stepsGrid.Columns.Add(new DataGridViewTextBoxColumn
            {
                DataPropertyName = nameof(QuestSequenceStepDefinition.Text), HeaderText = "Text / payload", AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill
            });
            _stepsGrid.SelectionChanged += (s, e) =>
            {
                int index = CurrentGridIndex(_stepsGrid);
                _stepProperties.SelectedObject = index >= 0 && index < _steps.Count ? _steps[index] : null;
            };
        }

        private void BuildRelationshipTree()
        {
            _relationships.BeginUpdate();
            _relationships.Nodes.Clear();
            foreach (var giver in _givers)
            {
                var giverNode = new TreeNode($"{giver.DisplayName} [{giver.OwnershipMode}]");
                foreach (var quest in _quests.Where(q => q.QuestGiverId == giver.Id).OrderBy(q => q.SortOrder))
                {
                    var questNode = new TreeNode($"{quest.Title} ({quest.QuestType} + {quest.Category})");
                    if (quest.ReceiverGiverId.HasValue)
                    {
                        var receiver = _givers.FirstOrDefault(g => g.Id == quest.ReceiverGiverId.Value);
                        questNode.Nodes.Add("Turn in: " + (receiver?.DisplayName ?? quest.ReceiverDisplayName));
                    }
                    if (quest.Id != 0)
                    {
                        foreach (int id in _repository.GetPrerequisiteIds(quest.Id))
                        {
                            var prerequisite = _quests.FirstOrDefault(q => q.Id == id);
                            var prerequisiteGiver = prerequisite == null
                                ? null
                                : _givers.FirstOrDefault(g => g.Id == prerequisite.QuestGiverId);
                            questNode.Nodes.Add($"Requires: {prerequisiteGiver?.DisplayName} / {prerequisite?.Title}");
                        }
                    }
                    giverNode.Nodes.Add(questNode);
                }
                foreach (var dependency in _repository.GetWorldEditorDependencies(giver.Id)
                             .Where(d => d.DependencyKind == "other" && d.Symbol.StartsWith("library:", StringComparison.OrdinalIgnoreCase)))
                {
                    giverNode.Nodes.Add("Source link: " + dependency.Symbol.Substring("library:".Length));
                }
                _relationships.Nodes.Add(giverNode);
            }
            _relationships.EndUpdate();
            _relationships.ExpandAll();
        }

        private void LoadDependencies()
        {
            _dependencies = _currentGiver == null || _currentGiver.Id == 0
                ? new BindingList<QuestWorldEditorDependency>()
                : new BindingList<QuestWorldEditorDependency>(
                    _repository.GetWorldEditorDependencies(_currentGiver.Id));
            _dependenciesGrid.DataSource = _dependencies;
            HideGridColumns(_dependenciesGrid, "Id", "QuestGiverId");
        }

        private void AddDependency()
        {
            if (_currentGiver == null || _currentGiver.Id == 0) return;
            _dependencies.Add(new QuestWorldEditorDependency
            {
                QuestGiverId = _currentGiver.Id,
                QuestId = _currentQuest?.Id,
                DependencyKind = "other",
                Symbol = "NewDependency"
            });
        }

        private void RemoveDependency()
        {
            int index = CurrentGridIndex(_dependenciesGrid);
            if (index >= 0 && index < _dependencies.Count) _dependencies.RemoveAt(index);
        }

        private void SaveDependencies()
        {
            if (_currentGiver == null || _currentGiver.Id == 0) return;
            try
            {
                _dependenciesGrid.EndEdit();
                _repository.ReplaceWorldEditorDependencies(_currentGiver.Id, _dependencies);
                LoadDependencies();
                SetStatus("World Editor dependencies saved.");
            }
            catch (Exception ex)
            {
                ShowError("Could not save World Editor dependencies", ex);
            }
        }

        private void LoadVoicelines()
        {
            _voicelines = new BindingList<QuestVoicelineDefinition>(_repository.GetVoicelines());
            _voicelinesGrid.DataSource = _voicelines;
            _stepVoiceColumn.DataSource = _voicelines.Where(v => v.Id != 0).ToList();
            HideGridColumns(_voicelinesGrid, "Id");
        }

        private void AddVoiceline()
        {
            _voicelines.Add(new QuestVoicelineDefinition
            {
                SpeakerKey = "Speaker",
                SpeakerName = "Speaker",
                LineKey = "Speaker/0001"
            });
        }

        private void SaveVoicelines()
        {
            try
            {
                _voicelinesGrid.EndEdit();
                foreach (var line in _voicelines)
                {
                    _repository.SaveVoiceline(line);
                }
                LoadVoicelines();
                SetStatus("Voiceline catalog saved.");
            }
            catch (Exception ex)
            {
                ShowError("Could not save voicelines", ex);
            }
        }

        private void DeleteVoiceline()
        {
            int index = CurrentGridIndex(_voicelinesGrid);
            if (index < 0 || index >= _voicelines.Count) return;
            var line = _voicelines[index];
            if (line.Id != 0)
            {
                if (!ConfirmDelete($"Delete voiceline '{line.LineKey}'?")) return;
                _repository.DeleteVoiceline(line.Id);
            }
            _voicelines.RemoveAt(index);
        }

        private void ExportLibraries()
        {
            using var dialog = new FolderBrowserDialog
            {
                Description = "Select an output folder for qXXX JASS, JSON snapshots, validation reports, and WE manifests",
                ShowNewFolderButton = true
            };
            if (dialog.ShowDialog(this) != DialogResult.OK) return;
            try
            {
                var exporter = new QuestLibraryExporter(_connectionString);
                var result = exporter.ExportAll(dialog.SelectedPath);
                var message = $"Quest givers exported: {result.GiversExported}\n" +
                              $"Unchanged givers skipped: {result.GiversUnchanged}\n" +
                              $"Quests exported: {result.QuestsExported}\n" +
                              $"Files written: {result.FilesExported.Count}\n" +
                              $"Warnings: {result.Warnings.Count}\n" +
                              $"Errors: {result.Errors.Count}";
                if (result.Errors.Count > 0)
                {
                    message += "\n\n" + string.Join("\n", result.Errors.Take(12));
                }
                MessageBox.Show(message, result.Success ? "Quest export complete" : "Quest export needs attention",
                    MessageBoxButtons.OK, result.Success ? MessageBoxIcon.Information : MessageBoxIcon.Warning);
                SetStatus(message.Replace("\n", " "));
            }
            catch (Exception ex)
            {
                ShowError("Could not export quest libraries", ex);
            }
        }

        private void SyncExistingSources()
        {
            string detectedRoot = QuestSourceSynchronizer.FindQuestsAndDialogsRoot();
            using var dialog = new FolderBrowserDialog
            {
                Description = "Select the PotS repository or QuestsAndDialogs folder. Both QuestGivers and GenericQuests are synchronized.",
                ShowNewFolderButton = false,
                SelectedPath = detectedRoot
            };
            if (dialog.ShowDialog(this) != DialogResult.OK) return;

            try
            {
                Cursor = Cursors.WaitCursor;
                SetStatus("Synchronizing QuestGivers and GenericQuests JASS sources...");
                var synchronizer = new QuestSourceSynchronizer(_connectionString);
                QuestSourceSyncResult result = synchronizer.Synchronize(dialog.SelectedPath);
                RefreshData();

                var message = new System.Text.StringBuilder();
                message.AppendLine($"Files scanned: {result.FilesScanned}");
                message.AppendLine($"Quest definitions found: {result.QuestDefinitionsFound}");
                message.AppendLine($"Source containers synchronized: {result.GiversSynchronized}");
                message.AppendLine($"Created: {result.GiversCreated} containers, {result.QuestsCreated} quests");
                message.AppendLine($"Updated: {result.GiversUpdated} containers, {result.QuestsUpdated} quests");
                message.AppendLine($"Unchanged source files: {result.UnchangedSources}");
                if (result.SkippedProtectedSources > 0)
                    message.AppendLine($"Protected managed/hybrid libraries skipped: {result.SkippedProtectedSources}");
                if (result.Warnings.Count > 0)
                {
                    message.AppendLine();
                    message.AppendLine($"Warnings ({result.Warnings.Count}):");
                    foreach (string warning in result.Warnings.Take(20)) message.AppendLine("- " + warning);
                    if (result.Warnings.Count > 20) message.AppendLine($"- ...and {result.Warnings.Count - 20} more");
                }
                if (result.Errors.Count > 0)
                {
                    message.AppendLine();
                    message.AppendLine($"Errors ({result.Errors.Count}):");
                    foreach (string error in result.Errors.Take(10)) message.AppendLine("- " + error);
                }
                MessageBox.Show(message.ToString(), "Quest source synchronization",
                    MessageBoxButtons.OK, result.Errors.Count == 0 ? MessageBoxIcon.Information : MessageBoxIcon.Warning);
                SetStatus(result.Errors.Count == 0
                    ? "Existing JASS quest sources synchronized."
                    : "Quest source synchronization completed with errors.");
            }
            catch (Exception ex)
            {
                ShowError("Could not synchronize existing quest sources", ex);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
        }

        private void ClearSourceEditing()
        {
            _sourceEditSession = null;
            _sourceGiverBaseline = null;
            _sourceQuestBaseline = null;
            _sourceRewardBaseline = null;
            _sourceObjectiveBaselines.Clear();
        }

        private void ConfigureSourceEditing()
        {
            ClearSourceEditing();
            if (!IsSourceOwned(_currentGiver)) return;
            _sourceGiverBaseline = CloneModel(_currentGiver);
            _sourceQuestBaseline = CloneModel(_currentQuest);
            _sourceRewardBaseline = CloneModel(_currentReward);
            _sourceObjectiveBaselines = _objectives.Select(CloneModel).ToList();
            try
            {
                _sourceEditSession = _sourceEditor.Analyze(_currentGiver, _currentQuest, _sourceObjectiveBaselines);
                _giverProperties.SelectedObject = new SelectivePropertyModel(
                    _currentGiver, _sourceEditSession.GiverFields, _sourceEditSession.DefaultReadOnlyReason);
                if (_currentQuest != null)
                {
                    _questProperties.SelectedObject = new SelectivePropertyModel(
                        _currentQuest, _sourceEditSession.QuestFields, _sourceEditSession.DefaultReadOnlyReason);
                    _rewardProperties.SelectedObject = new SelectivePropertyModel(
                        _currentReward, _sourceEditSession.RewardFields, _sourceEditSession.DefaultReadOnlyReason);
                    ShowSourceObjectiveProperties(_objectives.FirstOrDefault());
                }
            }
            catch (Exception ex)
            {
                const string reason =
                    "WC3 Manager could not analyze this source safely. All fields remain source-only until the file can be parsed.";
                _giverProperties.SelectedObject = new SelectivePropertyModel(
                    _currentGiver, new Dictionary<string, SourceFieldAccess>(), reason + " " + ex.Message);
                if (_currentQuest != null)
                {
                    _questProperties.SelectedObject = new SelectivePropertyModel(
                        _currentQuest, new Dictionary<string, SourceFieldAccess>(), reason + " " + ex.Message);
                    _rewardProperties.SelectedObject = new SelectivePropertyModel(
                        _currentReward, new Dictionary<string, SourceFieldAccess>(), reason + " " + ex.Message);
                }
                SetStatus("Source editing unavailable: " + ex.Message);
            }
        }

        private void ConfigureNewSourceQuestEditing()
        {
            _sourceQuestBaseline = null;
            _sourceRewardBaseline = null;
            _sourceObjectiveBaselines.Clear();
            var questFields = CreateSourceFieldAccess<QuestDefinition>(new[]
            {
                nameof(QuestDefinition.QuestKey), nameof(QuestDefinition.QuestName), nameof(QuestDefinition.Title),
                nameof(QuestDefinition.QuestType), nameof(QuestDefinition.Category), nameof(QuestDefinition.QuestLevel),
                nameof(QuestDefinition.RequiredLevel), nameof(QuestDefinition.RequiredReputation),
                nameof(QuestDefinition.IconPath), nameof(QuestDefinition.Description), nameof(QuestDefinition.InfoText),
                nameof(QuestDefinition.Info2Text), nameof(QuestDefinition.ReceiverDisplayName),
                nameof(QuestDefinition.Faction), nameof(QuestDefinition.AllowNazgrek), nameof(QuestDefinition.AllowZulkis)
            });
            var rewardFields = CreateSourceFieldAccess<QuestRewardDefinition>(new[]
            {
                nameof(QuestRewardDefinition.XpActive), nameof(QuestRewardDefinition.XpAdjust),
                nameof(QuestRewardDefinition.GoldActive), nameof(QuestRewardDefinition.GoldAdjust),
                nameof(QuestRewardDefinition.ArenaActive), nameof(QuestRewardDefinition.ArenaAdjust),
                nameof(QuestRewardDefinition.ReputationActive), nameof(QuestRewardDefinition.ReputationAdjust),
                nameof(QuestRewardDefinition.ReputationLinked)
            });
            _questProperties.SelectedObject = new SelectivePropertyModel(
                _currentQuest, questFields, _sourceEditSession.DefaultReadOnlyReason);
            _rewardProperties.SelectedObject = new SelectivePropertyModel(
                _currentReward, rewardFields, _sourceEditSession.DefaultReadOnlyReason);
            ShowSourceObjectiveProperties(_objectives.FirstOrDefault());
        }

        private void ShowSourceObjectiveProperties(QuestObjectiveDefinition objective)
        {
            if (objective == null)
            {
                _objectiveProperties.SelectedObject = null;
                return;
            }
            IReadOnlyDictionary<string, SourceFieldAccess> access = null;
            if (_currentQuest?.Id > 0 && _sourceEditSession != null)
            {
                _sourceEditSession.ObjectiveFields.TryGetValue(objective.Id, out access);
            }
            else if (_currentQuest?.Id == 0)
            {
                access = CreateSourceFieldAccess<QuestObjectiveDefinition>(new[]
                {
                    nameof(QuestObjectiveDefinition.Text)
                });
            }
            _objectiveProperties.SelectedObject = new SelectivePropertyModel(
                objective, access ?? new Dictionary<string, SourceFieldAccess>(),
                _sourceEditSession?.DefaultReadOnlyReason ?? "Edit this value in the repository .j file.");
        }

        private static Dictionary<string, SourceFieldAccess> CreateSourceFieldAccess<T>(IEnumerable<string> editable)
        {
            var allowed = new HashSet<string>(editable, StringComparer.Ordinal);
            return typeof(T).GetProperties().ToDictionary(property => property.Name, property => new SourceFieldAccess
            {
                PropertyName = property.Name,
                Editable = allowed.Contains(property.Name),
                Reason = allowed.Contains(property.Name)
                    ? "This value will be generated inside the explicit WC3 Manager-owned region."
                    : "This value is not part of the safe standard quest region and must be implemented in the repository .j file."
            }, StringComparer.Ordinal);
        }

        private void SaveSourceChanges()
        {
            _objectivesGrid.EndEdit();
            RenumberObjectives();
            SourcePatchPreview preview;
            if (_currentQuest == null)
            {
                preview = _sourceEditor.PrepareGiverPatch(_currentGiver, _sourceGiverBaseline, _currentGiver);
            }
            else if (_currentQuest.Id == 0)
            {
                preview = _sourceEditor.PrepareNewQuestPatch(
                    _currentGiver, _currentQuest, _currentReward, _objectives.ToList());
            }
            else
            {
                preview = _sourceEditor.PrepareQuestPatch(
                    _currentGiver, _sourceQuestBaseline, _currentQuest,
                    _sourceRewardBaseline, _currentReward,
                    _sourceObjectiveBaselines, _objectives.ToList());
            }

            using var dialog = new SourcePatchPreviewForm(preview);
            if (dialog.ShowDialog(this) != DialogResult.OK) return;
            string backupPath = _sourceEditor.Apply(preview);
            string questsRoot = QuestSourceSynchronizer.FindQuestsAndDialogsRoot();
            QuestSourceSyncResult sync = new QuestSourceSynchronizer(_connectionString).Synchronize(questsRoot);
            if (sync.Errors.Count > 0)
            {
                MessageBox.Show(
                    "The source patch was written, but synchronization failed:\n\n" +
                    string.Join("\n", sync.Errors) + "\n\nBackup: " + backupPath,
                    "Source patched; sync failed", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            int giverId = _currentGiver.Id;
            int? questId = _currentQuest?.Id > 0 ? _currentQuest.Id : null;
            RefreshData(giverId, questId);
            SetStatus($"Source patch applied and synchronized. Backup: {backupPath}");
        }

        private static T CloneModel<T>(T source) where T : class, new()
        {
            if (source == null) return null;
            var clone = new T();
            foreach (var property in typeof(T).GetProperties()
                         .Where(property => property.CanRead && property.CanWrite && property.GetIndexParameters().Length == 0))
            {
                property.SetValue(clone, property.GetValue(source));
            }
            return clone;
        }

        private void OpenCurrentSource()
        {
            if (!IsSourceOwned(_currentGiver)) return;
            string questsRoot = QuestSourceSynchronizer.FindQuestsAndDialogsRoot();
            if (string.IsNullOrWhiteSpace(questsRoot))
            {
                MessageBox.Show("WC3 Manager could not locate the repository's QuestsAndDialogs folder.",
                    "Source file not found", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string repositoryRoot = Directory.GetParent(questsRoot)?.FullName ?? questsRoot;
            string safeRoot = Path.GetFullPath(repositoryRoot).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string sourcePath = Path.GetFullPath(Path.Combine(repositoryRoot,
                (_currentGiver.SourceFile ?? "").Replace('/', Path.DirectorySeparatorChar)));
            if (!sourcePath.StartsWith(safeRoot, StringComparison.OrdinalIgnoreCase) || !File.Exists(sourcePath))
            {
                MessageBox.Show($"The synchronized source path could not be opened:\n\n{_currentGiver.SourceFile}",
                    "Source file not found", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            var answer = MessageBox.Show(
                "This JASS file is the authoritative source. WC3 Manager only patches uniquely mapped literals after a reviewed diff; all custom logic remains source-owned.\n\n" +
                "Keep quest/library symbols stable where possible, save the file, then run Sync JASS sources. " +
                "Renaming or deleting symbols may leave an older database projection for manual review.\n\n" +
                "Open the source file now?",
                "Open synchronized source", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
            if (answer != DialogResult.Yes) return;

            try
            {
                Process.Start(new ProcessStartInfo { FileName = sourcePath, UseShellExecute = true });
                SetStatus("Opened source: " + _currentGiver.SourceFile);
            }
            catch (Exception ex)
            {
                ShowError("Could not open the synchronized source", ex);
            }
        }

        private void UpdateOwnershipUi()
        {
            bool hasGiver = _currentGiver != null;
            bool sourceOwned = IsSourceOwned(_currentGiver);
            bool hybrid = hasGiver && string.Equals(_currentGiver.OwnershipMode, "hybrid", StringComparison.OrdinalIgnoreCase);
            bool external = hasGiver && string.Equals(_currentGiver.OwnershipMode, "external", StringComparison.OrdinalIgnoreCase);

            bool sourceCanSave = sourceOwned && _sourceEditSession != null &&
                                 (_currentQuest?.Id == 0 ||
                                  (_currentQuest != null
                                      ? _sourceEditSession.QuestFields.Values.Any(field => field.Editable) ||
                                        _sourceEditSession.RewardFields.Values.Any(field => field.Editable) ||
                                        _sourceEditSession.ObjectiveFields.Values.Any(fields => fields.Values.Any(field => field.Editable))
                                      : _sourceEditSession.GiverFields.Values.Any(field => field.Editable)));
            _newQuestButton.Enabled = hasGiver && _currentGiver.Id > 0;
            _newQuestButton.ToolTipText = sourceOwned
                ? (_sourceEditSession?.CanAddQuest == true
                    ? "Add a standard quest inside the reviewed WC3 Manager-owned JASS regions"
                    : _sourceEditSession?.AddQuestReason ?? "Source analysis is unavailable")
                : "Create a quest under the selected database-authored giver";
            _saveButton.Enabled = hasGiver && (!sourceOwned || sourceCanSave);
            _deleteButton.Enabled = hasGiver && _currentGiver.Id > 0 && !sourceOwned;
            _openSourceToolButton.Enabled = sourceOwned;
            _openSourceButton.Visible = sourceOwned;
            _sourceButtonColumn.Width = sourceOwned ? 165f : 0f;
            SetSelectionEditorsReadOnly(!hasGiver);

            if (!hasGiver)
            {
                SetOwnershipBanner(
                    "Select a quest giver or quest",
                    "Choose a repository folder, synchronized source, or database-authored record from the Quest Library.",
                    Color.FromArgb(239, 243, 248), Color.FromArgb(104, 118, 138),
                    "NO SELECTION", Color.DimGray, Color.Transparent);
            }
            else if (sourceOwned)
            {
                SetOwnershipBanner(
                    "Guarded synchronized JASS source",
                    $"{_currentGiver.SourceFile}  •  Only uniquely mapped literals are editable. Gray fields contain custom logic and remain repository-only.",
                    Color.FromArgb(255, 246, 213), Color.FromArgb(218, 148, 28),
                    "GUARDED SOURCE", Color.FromArgb(117, 72, 0), Color.FromArgb(255, 235, 166));
            }
            else if (hybrid)
            {
                SetOwnershipBanner(
                    "Hybrid quest library",
                    "Edit supported metadata here. Export a new scaffold and manually reconcile all hand-owned hooks.",
                    Color.FromArgb(232, 242, 252), Color.FromArgb(55, 121, 178),
                    "HYBRID", Color.FromArgb(31, 77, 117), Color.FromArgb(210, 231, 249));
            }
            else if (external)
            {
                SetOwnershipBanner(
                    "External preview record",
                    "This record is not synchronized and is excluded from qXXX exports. Confirm its source ownership before editing.",
                    Color.FromArgb(255, 240, 226), Color.FromArgb(196, 103, 42),
                    "EXTERNAL", Color.FromArgb(125, 58, 17), Color.FromArgb(250, 220, 197));
            }
            else
            {
                SetOwnershipBanner(
                    "Database-managed quest library",
                    "Edit and validate this record in WC3 Manager, then use Export changed libraries when ready.",
                    Color.FromArgb(232, 246, 235), Color.FromArgb(67, 137, 79),
                    "MANAGED", Color.FromArgb(39, 92, 48), Color.FromArgb(210, 237, 215));
            }
        }

        private void SetOwnershipBanner(string title, string details, Color background, Color accent,
            string badge, Color badgeForeground, Color badgeBackground)
        {
            _ownershipTitle.Text = title;
            _ownershipDetails.Text = details;
            _ownershipBanner.BackColor = background;
            _ownershipAccent.BackColor = accent;
            _modeBadge.Text = badge;
            _modeBadge.ForeColor = badgeForeground;
            _modeBadge.BackColor = badgeBackground;
        }

        private void SetSelectionEditorsReadOnly(bool noSelection)
        {
            bool sourceOwned = IsSourceOwned(_currentGiver);
            bool enabled = !noSelection;
            bool newSourceQuest = sourceOwned && _currentQuest?.Id == 0;
            _giverProperties.Enabled = enabled;
            _questProperties.Enabled = enabled;
            _rewardProperties.Enabled = enabled;
            _objectiveProperties.Enabled = enabled;
            _sequenceProperties.Enabled = enabled && !sourceOwned;
            _stepProperties.Enabled = enabled && !sourceOwned;
            _questReceiver.Enabled = enabled && !sourceOwned;
            _sequenceQuest.Enabled = enabled && !sourceOwned;
            _prerequisites.Enabled = enabled && !sourceOwned;
            _objectivesGrid.ReadOnly = noSelection || sourceOwned;
            _stepsGrid.ReadOnly = noSelection || sourceOwned;
            _dependenciesGrid.ReadOnly = noSelection || sourceOwned;
            SetAuthoringActionsEnabled(_tabs.TabPages[1], enabled && (!sourceOwned || newSourceQuest));
            SetAuthoringActionsEnabled(_tabs.TabPages[2], enabled && !sourceOwned);
            SetAuthoringActionsEnabled(_tabs.TabPages[4], enabled && !sourceOwned);
            if (sourceOwned)
            {
                _questReceiver.Enabled = false;
                _prerequisites.Enabled = false;
                _objectivesGrid.ReadOnly = true;
            }
        }

        private static void SetAuthoringActionsEnabled(Control parent, bool enabled)
        {
            foreach (Control child in parent.Controls)
            {
                if (child is ToolStrip || child is Button || child is ComboBox || child is CheckedListBox)
                {
                    child.Enabled = enabled;
                }
                SetAuthoringActionsEnabled(child, enabled);
            }
        }

        private void ShowOverview(string title)
        {
            ClearSourceEditing();
            _currentGiver = null;
            _currentQuest = null;
            _currentSequence = null;
            _giverProperties.SelectedObject = null;
            _questProperties.SelectedObject = null;
            _rewardProperties.SelectedObject = null;
            _preview.ClearQuest();
            _overviewTitle.Text = string.IsNullOrWhiteSpace(title) ? "Quest Designer" : title;
            _overviewStats.Text = $"{_givers.Count} quest givers  •  {_quests.Count} quests  •  " +
                                  $"{_givers.Count(IsSourceOwned)} synchronized sources";
            _overviewPanel.Visible = true;
            _overviewPanel.BringToFront();
            UpdateOwnershipUi();
        }

        private static bool IsSourceOwned(QuestGiverDefinition giver)
        {
            return giver != null
                   && string.Equals(giver.OwnershipMode, "external", StringComparison.OrdinalIgnoreCase)
                   && !string.IsNullOrWhiteSpace(giver.SourceImportFingerprint);
        }

        private void RefreshPreview()
        {
            if (_currentQuest == null)
            {
                _preview.ClearQuest();
                return;
            }
            var receiver = _currentQuest.ReceiverGiverId.HasValue
                ? _givers.FirstOrDefault(g => g.Id == _currentQuest.ReceiverGiverId.Value)
                : null;
            _preview.SetQuest(_currentQuest, _currentGiver, receiver, _objectives.ToList(), _currentReward);
        }

        private void ClearSelection()
        {
            ShowOverview("Quest Library");
        }

        private void RenumberObjectives()
        {
            for (int i = 0; i < _objectives.Count; i++) _objectives[i].DisplayOrder = i + 1;
            _objectivesGrid.Refresh();
        }

        private void RenumberSteps()
        {
            for (int i = 0; i < _steps.Count; i++) _steps[i].DisplayOrder = i + 1;
            _stepsGrid.Refresh();
        }

        private void SelectSequenceQuest(int id)
        {
            for (int i = 0; i < _sequenceQuest.Items.Count; i++)
            {
                if (_sequenceQuest.Items[i] is QuestChoice choice && choice.Id == id)
                {
                    _sequenceQuest.SelectedIndex = i;
                    return;
                }
            }
            if (_sequenceQuest.Items.Count > 0) _sequenceQuest.SelectedIndex = 0;
        }

        private void SelectListSequence(int id)
        {
            for (int i = 0; i < _sequenceList.Items.Count; i++)
            {
                if (_sequenceList.Items[i] is QuestSequenceDefinition sequence && sequence.Id == id)
                {
                    _sequenceList.SelectedIndex = i;
                    return;
                }
            }
        }

        private static void SelectGridItem(DataGridView grid, int index)
        {
            if (index < 0 || index >= grid.Rows.Count) return;
            grid.ClearSelection();
            grid.Rows[index].Selected = true;
            grid.CurrentCell = grid.Rows[index].Cells[0];
        }

        private static int CurrentGridIndex(DataGridView grid)
        {
            return grid.CurrentRow?.Index ?? -1;
        }

        private static DataGridView CreateGrid()
        {
            var grid = new DataGridView
            {
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                MultiSelect = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                RowHeadersVisible = false,
                BackgroundColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle,
                GridColor = Color.FromArgb(224, 228, 234),
                EnableHeadersVisualStyles = false,
                RowTemplate = { Height = 25 },
                AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None
            };
            grid.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(238, 242, 247);
            grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.FromArgb(40, 53, 69);
            grid.ColumnHeadersDefaultCellStyle.Font = new Font("Segoe UI Semibold", 9f);
            grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = Color.FromArgb(238, 242, 247);
            grid.DefaultCellStyle.SelectionBackColor = Color.FromArgb(215, 232, 247);
            grid.DefaultCellStyle.SelectionForeColor = Color.FromArgb(25, 43, 61);
            grid.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(249, 250, 252);
            return grid;
        }

        private static ToolStripButton CreateToolButton(string text, EventHandler handler, string toolTip = "")
        {
            var button = new ToolStripButton(text)
            {
                DisplayStyle = ToolStripItemDisplayStyle.Text,
                AutoToolTip = !string.IsNullOrWhiteSpace(toolTip),
                ToolTipText = toolTip,
                Margin = new Padding(2, 0, 2, 0),
                Padding = new Padding(4, 2, 4, 2)
            };
            button.Click += handler;
            return button;
        }

        private static void HideGridColumns(DataGridView grid, params string[] names)
        {
            foreach (string name in names)
            {
                if (grid.Columns.Contains(name)) grid.Columns[name].Visible = false;
            }
        }

        private static bool ConfirmDelete(string message)
        {
            return MessageBox.Show(message, "Confirm delete", MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning) == DialogResult.Yes;
        }

        private void SetStatus(string text)
        {
            _status.Text = text;
        }

        private void ShowError(string context, Exception ex)
        {
            Logger.Instance.Error(context, ex);
            MessageBox.Show($"{context}:\n\n{ex.Message}", "Quest Designer",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            SetStatus(context + ": " + ex.Message);
        }

        private sealed class QuestChoice
        {
            public int Id { get; }
            public string Label { get; }

            public QuestChoice(int id, string label)
            {
                Id = id;
                Label = label;
            }

            public override string ToString() => Label;
        }
    }
}
