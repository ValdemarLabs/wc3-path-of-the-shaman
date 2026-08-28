using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Exporters;
using WC3ItemManager.Importers;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    public sealed class QuestDesignerForm : Form
    {
        private readonly QuestDesignerRepository _repository;
        private readonly string _connectionString;
        private readonly TreeView _navigation = new TreeView();
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

            BuildToolbar();
            BuildWorkspace();
            var statusStrip = new StatusStrip();
            statusStrip.Items.Add(_status);
            Controls.Add(statusStrip);
            Shown += OnShown;
        }

        private void BuildToolbar()
        {
            _mainTools.GripStyle = ToolStripGripStyle.Hidden;
            _mainTools.Dock = DockStyle.Top;
            _mainTools.Items.Add(CreateToolButton("New giver", (s, e) => NewGiver()));
            _mainTools.Items.Add(CreateToolButton("New quest", (s, e) => NewQuest()));
            _mainTools.Items.Add(new ToolStripSeparator());
            _mainTools.Items.Add(CreateToolButton("Save", (s, e) => SaveCurrent()));
            _mainTools.Items.Add(CreateToolButton("Delete", (s, e) => DeleteCurrent()));
            _mainTools.Items.Add(CreateToolButton("Refresh", (s, e) => RefreshData()));
            _mainTools.Items.Add(CreateToolButton("Sync existing JASS...", (s, e) => SyncExistingSources()));
            _mainTools.Items.Add(new ToolStripSeparator());
            _mainTools.Items.Add(CreateToolButton("Export changed qXXX libraries", (s, e) => ExportLibraries()));
            _mainTools.Items.Add(new ToolStripLabel(
                "Managed = generated; Hybrid = scaffold + hooks; External = preview/relationships only"));
            Controls.Add(_mainTools);
        }

        private void BuildWorkspace()
        {
            var split = new SplitContainer
            {
                Dock = DockStyle.Fill,
                SplitterDistance = 285,
                FixedPanel = FixedPanel.Panel1
            };
            Controls.Add(split);
            split.BringToFront();

            var left = new Panel { Dock = DockStyle.Fill, Padding = new Padding(6) };
            split.Panel1.Controls.Add(left);
            left.Controls.Add(new Label
            {
                Dock = DockStyle.Top,
                Height = 30,
                Text = "Quest givers and quests",
                Font = new Font("Segoe UI", 10f, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft
            });
            _navigation.Dock = DockStyle.Fill;
            _navigation.HideSelection = false;
            _navigation.AfterSelect += NavigationAfterSelect;
            left.Controls.Add(_navigation);
            _navigation.BringToFront();

            _tabs.Dock = DockStyle.Fill;
            _tabs.TabPages.Add(CreateGiverTab());
            _tabs.TabPages.Add(CreateQuestTab());
            _tabs.TabPages.Add(CreateSequencesTab());
            _tabs.TabPages.Add(CreatePreviewTab());
            _tabs.TabPages.Add(CreateRelationshipsTab());
            _tabs.TabPages.Add(CreateVoicelinesTab());
            split.Panel2.Controls.Add(_tabs);
        }

        private TabPage CreateGiverTab()
        {
            var page = new TabPage("Quest giver");
            var note = new Label
            {
                Dock = DockStyle.Top,
                Height = 48,
                Padding = new Padding(8),
                Text = "Binding requires a placed JASS unit variable or a four-character rawcode. " +
                       "Use External ownership for existing complex qXXX sources; WC3 Manager will never export them.",
                BackColor = Color.FromArgb(240, 245, 252)
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
            var page = new TabPage("Dialog & events");
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
            var page = new TabPage("In-game quest log preview");
            page.Controls.Add(_preview);
            return page;
        }

        private TabPage CreateRelationshipsTab()
        {
            var page = new TabPage("Relationships & WE dependencies");
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
            var page = new TabPage("Voiceline catalog");
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
                ForeColor = giver.Enabled ? SystemColors.WindowText : Color.Gray
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
                _tabs.SelectedIndex = 1;
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
            SetStatus($"Editing quest {_currentQuest.Title}.");
        }

        private void NewGiver()
        {
            _currentQuest = null;
            _currentGiver = new QuestGiverDefinition
            {
                GiverKey = "NewGiver",
                DisplayName = "New quest giver",
                LibraryName = "NewGiver",
                UnitCode = "n000"
            };
            _giverProperties.SelectedObject = _currentGiver;
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
                MessageBox.Show(
                    "This giver is synchronized from JASS. Add the quest in the source library, then run Sync existing JASS.",
                    "Read-only source library", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
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
                    MessageBox.Show(
                        "Synchronized JASS records are read-only in WC3 Manager. Edit the source library and sync again.",
                        "Read-only source library", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Dialog & events")
                {
                    SaveSequence();
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Relationships & WE dependencies")
                {
                    SaveDependencies();
                    return;
                }
                if (_tabs.SelectedTab?.Text == "Voiceline catalog")
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
                if (_tabs.SelectedTab?.Text == "Dialog & events" && _currentSequence != null)
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
            _objectiveProperties.SelectedObject = objective;
            RefreshPreview();
        }

        private void RemoveObjective()
        {
            int index = CurrentGridIndex(_objectivesGrid);
            if (index < 0 || index >= _objectives.Count) return;
            _objectives.RemoveAt(index);
            RenumberObjectives();
            _objectiveProperties.SelectedObject = _objectives.ElementAtOrDefault(Math.Min(index, _objectives.Count - 1));
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
                _objectiveProperties.SelectedObject = index >= 0 && index < _objectives.Count ? _objectives[index] : null;
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
            _currentGiver = null;
            _currentQuest = null;
            _currentSequence = null;
            _giverProperties.SelectedObject = null;
            _questProperties.SelectedObject = null;
            _rewardProperties.SelectedObject = null;
            _preview.ClearQuest();
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
            return new DataGridView
            {
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                MultiSelect = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                RowHeadersVisible = false,
                BackgroundColor = SystemColors.Window,
                BorderStyle = BorderStyle.Fixed3D
            };
        }

        private static ToolStripButton CreateToolButton(string text, EventHandler handler)
        {
            var button = new ToolStripButton(text);
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
