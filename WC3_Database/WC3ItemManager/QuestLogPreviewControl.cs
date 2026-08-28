using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using WC3ItemManager.Models;

namespace WC3ItemManager
{
    /// <summary>
    /// Desktop preview of the live QuestUI Details/Description/Objectives/Rewards contract.
    /// </summary>
    public sealed class QuestLogPreviewControl : UserControl
    {
        private readonly Label _questTitle;
        private readonly Label _listTitle;
        private readonly Label _listState;
        private readonly PictureBox _listIcon;
        private readonly PictureBox _rewardIcon;
        private readonly RichTextBox _content;
        private readonly ComboBox _previewState;
        private readonly FlowLayoutPanel _sectionButtons;
        private readonly Dictionary<string, Button> _sections = new Dictionary<string, Button>();

        private QuestDefinition _quest;
        private QuestGiverDefinition _giver;
        private QuestGiverDefinition _receiver;
        private IReadOnlyList<QuestObjectiveDefinition> _objectives = Array.Empty<QuestObjectiveDefinition>();
        private QuestRewardDefinition _reward = new QuestRewardDefinition();
        private string _section = "Details";

        public QuestLogPreviewControl()
        {
            Dock = DockStyle.Fill;
            BackColor = Color.FromArgb(20, 18, 16);
            ForeColor = Color.FromArgb(232, 220, 185);
            MinimumSize = new Size(760, 430);

            var titleBar = new Panel
            {
                Dock = DockStyle.Top,
                Height = 46,
                BackColor = Color.FromArgb(47, 34, 22),
                Padding = new Padding(12, 8, 12, 6)
            };
            titleBar.Controls.Add(new Label
            {
                Dock = DockStyle.Left,
                Width = 180,
                Text = "QUEST JOURNAL",
                Font = new Font("Segoe UI", 13f, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 204, 0),
                TextAlign = ContentAlignment.MiddleLeft
            });
            _previewState = new ComboBox
            {
                Dock = DockStyle.Right,
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            _previewState.Items.AddRange(new object[]
            {
                "Available", "In progress", "Ready to turn in", "Completed", "Failed"
            });
            _previewState.SelectedIndex = 1;
            _previewState.SelectedIndexChanged += (s, e) => RefreshPreview();
            titleBar.Controls.Add(_previewState);
            titleBar.Controls.Add(new Label
            {
                Dock = DockStyle.Right,
                Width = 100,
                Text = "Preview state:",
                ForeColor = Color.Gainsboro,
                TextAlign = ContentAlignment.MiddleRight
            });
            Controls.Add(titleBar);

            var categoryBar = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 38,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false,
                Padding = new Padding(6, 6, 0, 4),
                BackColor = Color.FromArgb(31, 27, 23)
            };
            foreach (string category in new[]
            {
                "All", "Normal", "Daily", "Repeatable", "Story", "Dungeon", "Class", "Profession"
            })
            {
                categoryBar.Controls.Add(CreateJournalButton(category, category == "All"));
            }
            Controls.Add(categoryBar);

            var body = new SplitContainer
            {
                Dock = DockStyle.Fill,
                SplitterDistance = 245,
                FixedPanel = FixedPanel.Panel1,
                IsSplitterFixed = false,
                BackColor = Color.FromArgb(85, 68, 45)
            };
            Controls.Add(body);
            body.BringToFront();

            var listPanel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(35, 31, 27),
                Padding = new Padding(8)
            };
            body.Panel1.Controls.Add(listPanel);
            var questRow = new Panel
            {
                Dock = DockStyle.Top,
                Height = 72,
                BackColor = Color.FromArgb(73, 58, 38),
                Padding = new Padding(8)
            };
            listPanel.Controls.Add(questRow);
            _listIcon = new PictureBox
            {
                Dock = DockStyle.Left,
                Width = 52,
                BackColor = Color.FromArgb(15, 15, 15),
                SizeMode = PictureBoxSizeMode.Zoom
            };
            questRow.Controls.Add(_listIcon);
            var rowText = new Panel { Dock = DockStyle.Fill, Padding = new Padding(9, 0, 0, 0) };
            questRow.Controls.Add(rowText);
            _listState = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 23,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 8.5f)
            };
            _listTitle = new Label
            {
                Dock = DockStyle.Fill,
                ForeColor = Color.FromArgb(255, 230, 160),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                AutoEllipsis = true
            };
            rowText.Controls.Add(_listTitle);
            rowText.Controls.Add(_listState);

            var detail = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(27, 24, 21),
                Padding = new Padding(14)
            };
            body.Panel2.Controls.Add(detail);
            _questTitle = new Label
            {
                Dock = DockStyle.Top,
                Height = 44,
                Font = new Font("Segoe UI", 15f, FontStyle.Bold),
                ForeColor = Color.FromArgb(255, 204, 0),
                TextAlign = ContentAlignment.MiddleLeft,
                AutoEllipsis = true
            };
            detail.Controls.Add(_questTitle);
            _sectionButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 38,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false
            };
            foreach (string section in new[] { "Details", "Description", "Objectives", "Rewards" })
            {
                var button = CreateJournalButton(section, section == "Details");
                button.Click += (s, e) => ShowSection(section);
                _sections[section] = button;
                _sectionButtons.Controls.Add(button);
            }
            detail.Controls.Add(_sectionButtons);
            _rewardIcon = new PictureBox
            {
                Dock = DockStyle.Bottom,
                Height = 58,
                Width = 58,
                Visible = false,
                BackColor = Color.Black,
                SizeMode = PictureBoxSizeMode.Zoom
            };
            detail.Controls.Add(_rewardIcon);
            _content = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BorderStyle = BorderStyle.None,
                BackColor = Color.FromArgb(27, 24, 21),
                ForeColor = Color.FromArgb(235, 230, 215),
                Font = new Font("Segoe UI", 10f),
                ScrollBars = RichTextBoxScrollBars.Vertical
            };
            detail.Controls.Add(_content);
            _content.BringToFront();
        }

        public void SetQuest(
            QuestDefinition quest,
            QuestGiverDefinition giver,
            QuestGiverDefinition receiver,
            IReadOnlyList<QuestObjectiveDefinition> objectives,
            QuestRewardDefinition reward)
        {
            _quest = quest;
            _giver = giver;
            _receiver = receiver;
            _objectives = objectives ?? Array.Empty<QuestObjectiveDefinition>();
            _reward = reward ?? new QuestRewardDefinition();
            RefreshPreview();
        }

        public void ClearQuest()
        {
            _quest = null;
            _giver = null;
            _receiver = null;
            _objectives = Array.Empty<QuestObjectiveDefinition>();
            _reward = new QuestRewardDefinition();
            RefreshPreview();
        }

        private void ShowSection(string section)
        {
            _section = section;
            foreach (var pair in _sections)
            {
                StyleJournalButton(pair.Value, pair.Key == section);
            }
            RefreshPreview();
        }

        private void RefreshPreview()
        {
            if (_quest == null)
            {
                _questTitle.Text = "Select a quest";
                _listTitle.Text = "No quest selected";
                _listState.Text = "";
                _content.Text = "Choose a quest in the designer to preview its in-game journal presentation.";
                SetImage(_listIcon, "");
                _rewardIcon.Visible = false;
                return;
            }

            _questTitle.Text = _quest.Title;
            _listTitle.Text = $"[{_quest.QuestLevel}] {_quest.Title}";
            _listState.Text = _previewState.SelectedItem?.ToString() ?? "In progress";
            _listState.ForeColor = GetStateColor(_listState.Text);
            SetImage(_listIcon, _quest.IconPath);
            _rewardIcon.Visible = _section == "Rewards" && !string.IsNullOrWhiteSpace(_reward.ItemCode);
            _content.Clear();

            switch (_section)
            {
                case "Description":
                    AppendBody(BuildDescription());
                    break;
                case "Objectives":
                    AppendHeading("Objectives");
                    if (_objectives.Count == 0)
                    {
                        AppendMuted("No objectives listed.");
                    }
                    else
                    {
                        foreach (var objective in _objectives.OrderBy(o => o.DisplayOrder))
                        {
                            AppendBody("[ ] " + StripWc3Codes(objective.Text) + Environment.NewLine);
                        }
                    }
                    break;
                case "Rewards":
                    AppendHeading("Rewards");
                    AppendBody(BuildRewards());
                    break;
                default:
                    AppendBody(BuildDetails());
                    break;
            }
        }

        private string BuildDetails()
        {
            var sb = new StringBuilder();
            sb.AppendLine($"Type: {Capitalize(_quest.QuestType)}    Level: {_quest.QuestLevel}");
            if (_quest.Category != "general") sb.AppendLine($"Category: {Capitalize(_quest.Category)}");
            sb.AppendLine($"Status: {_previewState.SelectedItem}");
            if (_quest.RequiredLevel > 0) sb.AppendLine($"Recommended level: {_quest.RequiredLevel}");
            if (!string.IsNullOrWhiteSpace(_quest.Faction))
            {
                sb.AppendLine($"Required reputation: {_quest.RequiredReputation} with {_quest.Faction}");
            }
            if (_giver != null)
            {
                string receiver = _receiver?.DisplayName ?? _quest.ReceiverDisplayName;
                if (_quest.AutoComplete)
                {
                    sb.AppendLine($"Quest giver: {_giver.DisplayName}");
                    sb.AppendLine("Completion: Automatic");
                }
                else if (string.IsNullOrWhiteSpace(receiver) || receiver == _giver.DisplayName)
                {
                    sb.AppendLine($"Quest giver / turn-in: {_giver.DisplayName}");
                }
                else
                {
                    sb.AppendLine($"Quest giver: {_giver.DisplayName}");
                    sb.AppendLine($"Turn in to: {receiver}");
                }
            }
            if (_quest.ZoneId.HasValue) sb.AppendLine($"Zone ID: {_quest.ZoneId.Value}");
            if ((_previewState.SelectedItem?.ToString() ?? "") == "Failed" && !string.IsNullOrWhiteSpace(_quest.FailReason))
            {
                sb.AppendLine($"Failure: {_quest.FailReason}");
            }
            return sb.ToString().TrimEnd();
        }

        private string BuildDescription()
        {
            var paragraphs = new[] { _quest.Description, _quest.InfoText, _quest.Info2Text }
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(StripWc3Codes)
                .ToList();
            return paragraphs.Count == 0
                ? "No description provided."
                : string.Join(Environment.NewLine + Environment.NewLine, paragraphs);
        }

        private string BuildRewards()
        {
            var lines = new List<string>();
            if (_reward.XpActive) lines.Add($"Experience: {Math.Max(0, _quest.QuestLevel * 50 + _reward.XpAdjust)}");
            if (_reward.GoldActive) lines.Add($"Gold: {Math.Max(0, _quest.QuestLevel * 50 + _reward.GoldAdjust)}");
            if (_reward.ArenaActive) lines.Add($"Arena Marks: {Math.Max(0, _quest.QuestLevel * 50 + _reward.ArenaAdjust)}");
            if (_reward.ReputationActive)
            {
                string faction = string.IsNullOrWhiteSpace(_quest.Faction) ? "" : " with " + _quest.Faction;
                lines.Add($"Reputation: {Math.Max(0, _quest.QuestLevel + _reward.ReputationAdjust)}{faction}");
            }
            if (!string.IsNullOrWhiteSpace(_reward.ItemCode)) lines.Add($"Item: {_reward.ItemCode}");
            if (!string.IsNullOrWhiteSpace(_reward.CustomText)) lines.Add(StripWc3Codes(_reward.CustomText));
            return lines.Count == 0 ? "No rewards listed." : string.Join(Environment.NewLine, lines);
        }

        private void AppendHeading(string text)
        {
            _content.SelectionFont = new Font(_content.Font, FontStyle.Bold);
            _content.SelectionColor = Color.FromArgb(255, 204, 0);
            _content.AppendText(text + Environment.NewLine + Environment.NewLine);
        }

        private void AppendBody(string text)
        {
            _content.SelectionFont = new Font(_content.Font, FontStyle.Regular);
            _content.SelectionColor = Color.FromArgb(235, 230, 215);
            _content.AppendText(StripWc3Codes(text));
        }

        private void AppendMuted(string text)
        {
            _content.SelectionColor = Color.FromArgb(135, 135, 135);
            _content.AppendText(text);
        }

        private static Button CreateJournalButton(string text, bool selected)
        {
            var button = new Button
            {
                Text = text,
                AutoSize = true,
                Height = 26,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 8.5f, FontStyle.Bold),
                Margin = new Padding(2, 0, 2, 0),
                Padding = new Padding(6, 0, 6, 0)
            };
            StyleJournalButton(button, selected);
            return button;
        }

        private static void StyleJournalButton(Button button, bool selected)
        {
            button.BackColor = selected ? Color.FromArgb(116, 85, 40) : Color.FromArgb(55, 47, 39);
            button.ForeColor = selected ? Color.FromArgb(255, 224, 143) : Color.Gainsboro;
            button.FlatAppearance.BorderColor = selected ? Color.FromArgb(214, 158, 64) : Color.FromArgb(95, 78, 55);
        }

        private static Color GetStateColor(string state)
        {
            return state switch
            {
                "Failed" => Color.FromArgb(255, 96, 96),
                "Completed" => Color.FromArgb(128, 255, 128),
                "Ready to turn in" => Color.Yellow,
                "Available" => Color.Silver,
                _ => Color.White
            };
        }

        private static string Capitalize(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "General";
            return char.ToUpperInvariant(value[0]) + value.Substring(1);
        }

        private static string StripWc3Codes(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            string text = value.Replace("\\n", Environment.NewLine).Replace("|n", Environment.NewLine);
            text = Regex.Replace(text, "\\|c[0-9A-Fa-f]{8}", "");
            return text.Replace("|r", "");
        }

        private static void SetImage(PictureBox box, string iconPath)
        {
            if (box.Image != null)
            {
                var old = box.Image;
                box.Image = null;
                old.Dispose();
            }
            if (string.IsNullOrWhiteSpace(iconPath)) return;
            try
            {
                string path = IconPathConfig.Instance.ResolveIconPath(iconPath);
                if (string.Equals(Path.GetExtension(path), ".blp", StringComparison.OrdinalIgnoreCase))
                {
                    string pngPath = Path.ChangeExtension(path, ".png");
                    if (File.Exists(pngPath)) path = pngPath;
                }
                if (File.Exists(path) && !string.Equals(Path.GetExtension(path), ".blp", StringComparison.OrdinalIgnoreCase))
                {
                    using var source = Image.FromFile(path);
                    box.Image = new Bitmap(source);
                }
            }
            catch
            {
                box.Image = null;
            }
        }
    }
}
