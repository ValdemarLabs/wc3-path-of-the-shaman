using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using War3Net.Drawing.Blp;
using BitmapSource = System.Windows.Media.Imaging.BitmapSource;
using PngBitmapEncoder = System.Windows.Media.Imaging.PngBitmapEncoder;
using BitmapFrame = System.Windows.Media.Imaging.BitmapFrame;

namespace WC3ItemManager
{
    public class IconSelectorDialog : Form
    {
        private TextBox txtSearch;
        private ComboBox cmbSource;
        private TreeView treeFolder;
        private FlowLayoutPanel flowIcons;
        private Button btnSelect;
        private Button btnCancel;
        private Button btnConfig;
        private CheckBox chkRememberFolder;
        private CheckBox chkRememberWindowSize;
        private ComboBox cmbCategory;
        private Label lblStatus;
        private Label lblCurrentPath;
        private SplitContainer splitContainer;
        private List<IconEntry> allIcons;
        private IconEntry selectedIcon;
        private Button selectedButton;
        
        // Static caches persist across dialog instances (prevents reloading large icon folders repeatedly)
        private const int IMAGE_CACHE_LIMIT = 5000;
        private const int INITIAL_ICON_COUNT = 240;
        private const int LOAD_MORE_ICON_COUNT = 240;
        private static Dictionary<string, Image> imageCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);
        private static List<IconEntry> allIconCache;
        private static string allIconCacheKey = "";
        private static object cacheLock = new object(); // Thread safety
        private static string cacheFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache");
        private static readonly Font iconButtonFont = new Font("Segoe UI", 7);
        
        private static bool rememberLastFolder = true;
        private static string lastSource = "All";
        private static string lastFolderPath = "";
        private System.Windows.Forms.Timer searchTimer;
        private int loadGeneration = 0;
        private bool isClosing = false;
        private string requestedIconPath = "";
        private readonly Dictionary<Button, Image> uncachedButtonImages = new Dictionary<Button, Image>();
        private readonly HashSet<int> loadingGenerations = new HashSet<int>();
        private List<IconEntry> currentResults = new List<IconEntry>();
        private int nextResultIndex = 0;
        private bool isResettingResults = false;
        
        public string SelectedIconPath { get; private set; }
        
        public IconSelectorDialog(string currentPath = "")
        {
            requestedIconPath = NormalizeComparableIconPath(currentPath);

            // Ensure cache folder exists
            if (!Directory.Exists(cacheFolder))
            {
                Directory.CreateDirectory(cacheFolder);
            }
            
            InitializeUI();
            RestoreWindowLayout();
            LoadIcons();
            
            if (!string.IsNullOrEmpty(currentPath))
            {
                HighlightIcon(currentPath);
            }
        }
        
        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            SaveWindowLayout();
            isClosing = true;
            loadGeneration++;
            searchTimer?.Stop();
            searchTimer?.Dispose();
            ClearIconButtons();
            base.OnFormClosed(e);
        }
        
        private void InitializeUI()
        {
            this.Text = "Icon Selector - Browse Textures";
            this.Size = new Size(1400, 800);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MinimumSize = new Size(1000, 600);
            
            // Top panel - search and filters
            Panel topPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 100,
                Padding = new Padding(10)
            };
            
            Label lblSearch = new Label
            {
                Text = "Search:",
                Location = new Point(10, 15),
                AutoSize = true
            };
            
            txtSearch = new TextBox
            {
                Location = new Point(70, 12),
                Width = 250,
                Font = new Font("Segoe UI", 9)
            };
            searchTimer = new System.Windows.Forms.Timer { Interval = 300 };
            searchTimer.Tick += (s, e) =>
            {
                searchTimer.Stop();
                FilterIcons();
            };
            txtSearch.TextChanged += (s, e) =>
            {
                searchTimer.Stop();
                searchTimer.Start();
            };
            
            Label lblSource = new Label
            {
                Text = "Source:",
                Location = new Point(330, 15),
                AutoSize = true
            };
            
            cmbSource = new ComboBox
            {
                Location = new Point(390, 12),
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbSource.Items.AddRange(new object[] { "All", "Blizzard", "Custom" });
            cmbSource.SelectedIndex = 0;
            cmbSource.SelectedIndexChanged += (s, e) => LoadFolderTree();
            
            btnConfig = new Button
            {
                Text = "Configure Paths",
                Location = new Point(550, 10),
                Width = 150,
                Height = 28
            };
            btnConfig.Click += BtnConfig_Click;

            Label lblCategory = new Label
            {
                Text = "Category:",
                Location = new Point(720, 15),
                AutoSize = true
            };

            cmbCategory = new ComboBox
            {
                Location = new Point(785, 12),
                Width = 140,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbCategory.Items.AddRange(new object[] { "All", "Abilities", "Items", "Units", "Buildings", "UI", "Effects", "Other" });
            cmbCategory.SelectedIndex = 0;
            cmbCategory.SelectedIndexChanged += (s, e) => FilterIcons();

            chkRememberFolder = new CheckBox
            {
                Text = "Remember folder",
                Location = new Point(945, 13),
                AutoSize = true,
                Checked = rememberLastFolder
            };
            chkRememberFolder.CheckedChanged += (s, e) =>
            {
                rememberLastFolder = chkRememberFolder.Checked;
                if (!rememberLastFolder)
                {
                    lastSource = "All";
                    lastFolderPath = "";
                }
                else
                {
                    RememberCurrentFolder();
                }
            };

            chkRememberWindowSize = new CheckBox
            {
                Text = "Remember window sizes",
                Location = new Point(1070, 13),
                AutoSize = true,
                Checked = IconPathConfig.Instance.RememberIconSelectorWindowSize
            };
            chkRememberWindowSize.CheckedChanged += (s, e) =>
            {
                IconPathConfig.Instance.RememberIconSelectorWindowSize = chkRememberWindowSize.Checked;
            };
            
            lblCurrentPath = new Label
            {
                Text = "Current folder: /",
                Location = new Point(10, 50),
                AutoSize = true,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.DarkBlue
            };
            
            lblStatus = new Label
            {
                Text = "Loading icons...",
                Location = new Point(10, 72),
                AutoSize = true,
                ForeColor = Color.Gray
            };
            
            topPanel.Controls.AddRange(new Control[] { 
                lblSearch, txtSearch, lblSource, cmbSource, btnConfig,
                lblCategory, cmbCategory, chkRememberFolder, chkRememberWindowSize,
                lblCurrentPath, lblStatus
            });
            
            // Main split container: Tree on left, Icons on right
            splitContainer = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 250,
                BorderStyle = BorderStyle.FixedSingle
            };
            
            // Left panel - Folder tree
            Panel treePanel = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(5)
            };
            
            Label lblTree = new Label
            {
                Text = "Folder Structure:",
                Dock = DockStyle.Top,
                Height = 25,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft
            };
            
            treeFolder = new TreeView
            {
                Dock = DockStyle.Fill,
                Font = new Font("Segoe UI", 9),
                HideSelection = false,
                ShowLines = true,
                ShowRootLines = true
            };
            treeFolder.AfterSelect += TreeFolder_AfterSelect;
            
            treePanel.Controls.Add(treeFolder);
            treePanel.Controls.Add(lblTree);
            splitContainer.Panel1.Controls.Add(treePanel);
            
            // Right panel - Icon grid with scroll
            Panel iconPanel = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(5)
            };
            
            flowIcons = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                WrapContents = true,
                Padding = new Padding(5)
            };
            flowIcons.Scroll += (s, e) => LoadMoreIconsIfNeeded();
            flowIcons.MouseWheel += (s, e) =>
            {
                if (!isClosing && flowIcons.IsHandleCreated)
                    flowIcons.BeginInvoke(new Action(LoadMoreIconsIfNeeded));
            };
            flowIcons.Resize += (s, e) => LoadMoreIconsIfNeeded();

            iconPanel.Controls.Add(flowIcons);
            splitContainer.Panel2.Controls.Add(iconPanel);
            
            // Bottom panel - buttons
            Panel bottomPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 50,
                Padding = new Padding(10)
            };
            
            btnSelect = new Button
            {
                Text = "Select",
                Location = new Point(800, 10),
                Width = 80,
                Height = 30,
                Enabled = false,
                DialogResult = DialogResult.OK
            };
            btnSelect.Click += BtnSelect_Click;
            
            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(890, 10),
                Width = 80,
                Height = 30,
                DialogResult = DialogResult.Cancel
            };
            
            bottomPanel.Controls.AddRange(new Control[] { btnSelect, btnCancel });
            
            this.Controls.Add(splitContainer);
            this.Controls.Add(topPanel);
            this.Controls.Add(bottomPanel);
        }

        private void RestoreWindowLayout()
        {
            var config = IconPathConfig.Instance;
            if (!config.RememberIconSelectorWindowSize)
                return;

            Rectangle workingArea = Screen.PrimaryScreen.WorkingArea;
            int width = Math.Clamp(config.IconSelectorWidth, MinimumSize.Width, workingArea.Width);
            int height = Math.Clamp(config.IconSelectorHeight, MinimumSize.Height, workingArea.Height);
            Size = new Size(width, height);

            int maxSplitterDistance = Math.Max(100, splitContainer.Width - 300);
            splitContainer.SplitterDistance = Math.Clamp(
                config.IconSelectorSplitterDistance,
                100,
                maxSplitterDistance);

            if (config.IconSelectorMaximized)
                WindowState = FormWindowState.Maximized;
        }

        private void SaveWindowLayout()
        {
            if (chkRememberWindowSize == null)
                return;

            var config = IconPathConfig.Instance;
            config.RememberIconSelectorWindowSize = chkRememberWindowSize.Checked;
            if (chkRememberWindowSize.Checked)
            {
                Rectangle bounds = WindowState == FormWindowState.Normal ? Bounds : RestoreBounds;
                config.IconSelectorWidth = Math.Max(MinimumSize.Width, bounds.Width);
                config.IconSelectorHeight = Math.Max(MinimumSize.Height, bounds.Height);
                config.IconSelectorSplitterDistance = splitContainer.SplitterDistance;
                config.IconSelectorMaximized = WindowState == FormWindowState.Maximized;
            }
            config.Save();
        }
        
        private void LoadIcons()
        {
            treeFolder.Nodes.Clear();
            ClearIconButtons();
            lblStatus.Text = "Loading folder structure...";
            Application.DoEvents();
            
            try
            {
                allIcons = GetAllIconsWithCache();
                if (rememberLastFolder && cmbSource.Items.Contains(lastSource))
                    cmbSource.SelectedItem = lastSource;
                LoadFolderTree();
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading icons: {ex.Message}";
                lblStatus.ForeColor = Color.Red;
            }
        }
        
        private void LoadFolderTree()
        {
            treeFolder.Nodes.Clear();
            string sourceFilter = cmbSource.SelectedItem?.ToString() ?? "All";
            var config = IconPathConfig.Instance;

            TreeNode allNode = null;
            if (sourceFilter == "All")
            {
                allNode = new TreeNode("All configured icons")
                {
                    Tag = new FolderInfo { FullPath = "", Source = "All" }
                };
                treeFolder.Nodes.Add(allNode);
            }

            if ((sourceFilter == "All" || sourceFilter == "Blizzard") && Directory.Exists(config.WarCraft3IconPath))
            {
                TreeNode blizzNode = new TreeNode("Blizzard WC3 Icons")
                {
                    Tag = new FolderInfo { FullPath = config.WarCraft3IconPath, Source = "Blizzard" },
                    ImageIndex = 0
                };
                BuildFolderTree(blizzNode, config.WarCraft3IconPath, "Blizzard");
                if (allNode != null)
                    allNode.Nodes.Add(blizzNode);
                else
                    treeFolder.Nodes.Add(blizzNode);
            }

            if ((sourceFilter == "All" || sourceFilter == "Custom") && Directory.Exists(config.CustomIconPath))
            {
                TreeNode customNode = new TreeNode("Custom Icons")
                {
                    Tag = new FolderInfo { FullPath = config.CustomIconPath, Source = "Custom" },
                    ImageIndex = 0
                };
                BuildFolderTree(customNode, config.CustomIconPath, "Custom");
                if (allNode != null)
                    allNode.Nodes.Add(customNode);
                else
                    treeFolder.Nodes.Add(customNode);
            }

            if (treeFolder.Nodes.Count > 0)
            {
                TreeNode selectedNode = rememberLastFolder
                    ? FindFolderNode(treeFolder.Nodes, lastFolderPath)
                    : null;
                treeFolder.SelectedNode = selectedNode ?? treeFolder.Nodes[0];
                treeFolder.SelectedNode.EnsureVisible();
                treeFolder.SelectedNode.Expand();
            }
        }

        private static TreeNode FindFolderNode(TreeNodeCollection nodes, string folderPath)
        {
            if (string.IsNullOrEmpty(folderPath))
                return null;

            foreach (TreeNode node in nodes)
            {
                if (node.Tag is FolderInfo info &&
                    string.Equals(info.FullPath, folderPath, StringComparison.OrdinalIgnoreCase))
                    return node;

                TreeNode match = FindFolderNode(node.Nodes, folderPath);
                if (match != null)
                    return match;
            }
            return null;
        }
        
        private void BuildFolderTree(TreeNode parentNode, string path, string source)
        {
            var directories = allIcons
                .Where(icon => icon.Source == source)
                .Select(icon => Path.GetDirectoryName(icon.FullPath))
                .Where(directory => !string.IsNullOrEmpty(directory))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(directory => directory.Length);

            foreach (string directory in directories)
            {
                string relativePath = Path.GetRelativePath(path, directory);
                if (relativePath == "." || relativePath.StartsWith(".."))
                    continue;

                TreeNode currentNode = parentNode;
                string currentPath = path;
                foreach (string folderName in relativePath.Split(
                    new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar },
                    StringSplitOptions.RemoveEmptyEntries))
                {
                    currentPath = Path.Combine(currentPath, folderName);
                    TreeNode childNode = currentNode.Nodes
                        .Cast<TreeNode>()
                        .FirstOrDefault(node => node.Tag is FolderInfo info &&
                            string.Equals(info.FullPath, currentPath, StringComparison.OrdinalIgnoreCase));
                    if (childNode == null)
                    {
                        childNode = new TreeNode(folderName)
                        {
                            Tag = new FolderInfo { FullPath = currentPath, Source = source }
                        };
                        currentNode.Nodes.Add(childNode);
                    }
                    currentNode = childNode;
                }
            }
        }
        
        private void TreeFolder_AfterSelect(object sender, TreeViewEventArgs e)
        {
            if (e.Node?.Tag is FolderInfo folderInfo)
            {
                lblCurrentPath.Text = $"Current folder: {e.Node.FullPath}";
                RememberCurrentFolder();
                FilterIcons();
            }
        }

        private void RememberCurrentFolder()
        {
            if (!rememberLastFolder)
                return;

            lastSource = cmbSource.SelectedItem?.ToString() ?? "All";
            lastFolderPath = (treeFolder.SelectedNode?.Tag as FolderInfo)?.FullPath ?? "";
        }

        private static List<IconEntry> GetAllIconsWithCache()
        {
            var config = IconPathConfig.Instance;
            string cacheKey = $"{config.WarCraft3IconPath}|{config.CustomIconPath}";
            lock (cacheLock)
            {
                if (allIconCache != null && string.Equals(allIconCacheKey, cacheKey, StringComparison.OrdinalIgnoreCase))
                    return allIconCache;
            }

            var icons = config.GetAllIcons();
            lock (cacheLock)
            {
                allIconCache = icons;
                allIconCacheKey = cacheKey;
            }
            return icons;
        }

        private async void FilterIcons()
        {
            if (allIcons == null || flowIcons == null || isClosing)
                return;

            searchTimer?.Stop();
            int generation = ++loadGeneration;
            string search = txtSearch.Text.Trim();
            string category = cmbCategory.SelectedItem?.ToString() ?? "All";

            IEnumerable<IconEntry> filtered = GetIconsInCurrentScope();
            if (!string.IsNullOrEmpty(search))
            {
                filtered = filtered.Where(icon =>
                    icon.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    icon.RelativePath.Contains(search, StringComparison.OrdinalIgnoreCase));
            }
            if (category != "All")
                filtered = filtered.Where(icon => GetVirtualCategory(icon) == category);

            List<IconEntry> results = filtered.ToList();
            if (!string.IsNullOrEmpty(requestedIconPath))
            {
                int requestedIndex = results.FindIndex(icon =>
                    NormalizeComparableIconPath(icon.RelativePath) == requestedIconPath);
                if (requestedIndex > 0)
                {
                    IconEntry requestedIcon = results[requestedIndex];
                    results.RemoveAt(requestedIndex);
                    results.Insert(0, requestedIcon);
                }
            }

            isResettingResults = true;
            try
            {
                ClearIconButtons();
                currentResults = results;
                nextResultIndex = 0;
            }
            finally
            {
                isResettingResults = false;
            }
            selectedIcon = null;
            btnSelect.Enabled = false;

            lblStatus.ForeColor = Color.Gray;
            lblStatus.Text = results.Count == 0
                ? "No matching icons in this folder"
                : $"Loading {results.Count} icons...";

            try
            {
                await LoadIconButtonsAsync(generation, INITIAL_ICON_COUNT);
            }
            catch (ObjectDisposedException)
            {
                // The selector closed while a thumbnail batch was loading.
            }
            catch (Exception ex)
            {
                if (generation == loadGeneration && !isClosing)
                {
                    lblStatus.Text = $"Error loading icon thumbnails: {ex.Message}";
                    lblStatus.ForeColor = Color.Red;
                }
                System.Diagnostics.Debug.WriteLine($"[IconSelector] Thumbnail loading failed: {ex}");
            }
        }

        private IEnumerable<IconEntry> GetIconsInCurrentScope()
        {
            string sourceFilter = cmbSource.SelectedItem?.ToString() ?? "All";
            IEnumerable<IconEntry> icons = allIcons;
            if (sourceFilter != "All")
                icons = icons.Where(icon => icon.Source == sourceFilter);

            if (!(treeFolder.SelectedNode?.Tag is FolderInfo folderInfo) || string.IsNullOrEmpty(folderInfo.FullPath))
                return icons;

            var config = IconPathConfig.Instance;
            bool sourceRoot =
                string.Equals(folderInfo.FullPath, config.WarCraft3IconPath, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(folderInfo.FullPath, config.CustomIconPath, StringComparison.OrdinalIgnoreCase);
            if (sourceRoot)
                return icons.Where(icon => icon.Source == folderInfo.Source);

            string folderPrefix = folderInfo.FullPath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            return icons.Where(icon => icon.FullPath.StartsWith(folderPrefix, StringComparison.OrdinalIgnoreCase));
        }

        private static string GetVirtualCategory(IconEntry icon)
        {
            string value = $"{icon.RelativePath} {icon.Name}".ToLowerInvariant();
            if (value.Contains("ability") || value.Contains("spell"))
                return "Abilities";
            if (value.Contains("item") || value.Contains("weapon") || value.Contains("armor") ||
                value.Contains("potion") || value.Contains("scroll") || value.Contains("artifact"))
                return "Items";
            if (value.Contains("building") || value.Contains("structure"))
                return "Buildings";
            if (value.Contains("unit") || value.Contains("hero") || value.Contains("creature"))
                return "Units";
            if (value.Contains("interface") || value.Contains("ui\\") || value.Contains("ui/") || value.Contains("menu"))
                return "UI";
            if (value.Contains("effect") || value.Contains("buff") || value.Contains("aura"))
                return "Effects";
            return "Other";
        }

        private async System.Threading.Tasks.Task LoadIconButtonsAsync(int generation, int requestedCount)
        {
            if (generation != loadGeneration || isClosing || !loadingGenerations.Add(generation))
                return;

            try
            {
                int startIndex = nextResultIndex;
                int count = Math.Min(requestedCount, currentResults.Count - startIndex);
                if (count <= 0)
                {
                    UpdateIconStatus();
                    return;
                }

                List<IconEntry> batch = currentResults.Skip(startIndex).Take(count).ToList();
                List<(IconEntry Icon, Image Image, bool Cached)> loaded =
                    await System.Threading.Tasks.Task.Run(() => batch.Select(icon =>
                    {
                        Image image = LoadImageWithCache(icon.FullPath, out bool cached);
                        return (icon, image, cached);
                    }).ToList());

                if (generation != loadGeneration || isClosing || flowIcons.IsDisposed)
                {
                    DisposeUncachedImages(loaded);
                    return;
                }

                flowIcons.SuspendLayout();
                foreach (var item in loaded)
                {
                    Button button = CreateIconButton(item.Icon, item.Image, item.Cached);
                    flowIcons.Controls.Add(button);
                    if (!string.IsNullOrEmpty(requestedIconPath) &&
                        NormalizeComparableIconPath(item.Icon.RelativePath) == requestedIconPath)
                    {
                        SelectIcon(button, item.Icon);
                        requestedIconPath = "";
                    }
                }
                nextResultIndex = startIndex + batch.Count;
                flowIcons.ResumeLayout(false);
                flowIcons.PerformLayout();
                UpdateIconStatus();
                await System.Threading.Tasks.Task.Yield();
            }
            finally
            {
                loadingGenerations.Remove(generation);
            }
        }

        private async void LoadMoreIconsIfNeeded()
        {
            if (isClosing || isResettingResults || currentResults == null || nextResultIndex >= currentResults.Count ||
                loadingGenerations.Contains(loadGeneration) || flowIcons.IsDisposed)
                return;

            int visibleBottom = flowIcons.VerticalScroll.Value + flowIcons.ClientSize.Height;
            int remainingHeight = flowIcons.DisplayRectangle.Height - visibleBottom;
            if (remainingHeight > 300)
                return;

            try
            {
                await LoadIconButtonsAsync(loadGeneration, LOAD_MORE_ICON_COUNT);
            }
            catch (ObjectDisposedException)
            {
                // The selector closed while the next page was loading.
            }
            catch (Exception ex)
            {
                if (!isClosing)
                {
                    lblStatus.Text = $"Error loading icon thumbnails: {ex.Message}";
                    lblStatus.ForeColor = Color.Red;
                }
                System.Diagnostics.Debug.WriteLine($"[IconSelector] Incremental loading failed: {ex}");
            }
        }

        private void UpdateIconStatus()
        {
            if (currentResults.Count == 0)
            {
                lblStatus.Text = "No matching icons in this folder";
            }
            else if (nextResultIndex < currentResults.Count)
            {
                lblStatus.Text = $"Showing {nextResultIndex} of {currentResults.Count} icons; scroll for more";
            }
            else
            {
                lblStatus.Text = $"Showing {currentResults.Count} icons";
            }
        }

        private static void DisposeUncachedImages(List<(IconEntry Icon, Image Image, bool Cached)> loaded)
        {
            foreach (var item in loaded)
            {
                if (!item.Cached)
                    item.Image?.Dispose();
            }
        }

        private Button CreateIconButton(IconEntry icon, Image image, bool cached)
        {
            string label = icon.Name.Length > 18 ? icon.Name.Substring(0, 15) + "..." : icon.Name;
            var button = new Button
            {
                Width = 92,
                Height = 112,
                Margin = new Padding(4),
                Padding = new Padding(3),
                Text = label,
                Image = image,
                ImageAlign = ContentAlignment.TopCenter,
                TextAlign = ContentAlignment.BottomCenter,
                TextImageRelation = TextImageRelation.ImageAboveText,
                Font = iconButtonFont,
                Tag = icon,
                UseVisualStyleBackColor = false,
                BackColor = SystemColors.Control
            };
            button.Click += (s, e) => SelectIcon(button, icon);
            button.MouseDoubleClick += (s, e) =>
            {
                SelectIcon(button, icon);
                BtnSelect_Click(s, e);
                DialogResult = DialogResult.OK;
            };
            if (!cached && image != null)
                uncachedButtonImages[button] = image;
            return button;
        }

        private void SelectIcon(Button button, IconEntry icon)
        {
            if (selectedButton != null && !selectedButton.IsDisposed)
                selectedButton.BackColor = SystemColors.Control;

            button.BackColor = Color.LightBlue;
            selectedButton = button;
            selectedIcon = icon;
            btnSelect.Enabled = true;
        }

        private void HighlightIcon(string path)
        {
            requestedIconPath = NormalizeComparableIconPath(path);
            foreach (Button button in flowIcons.Controls.OfType<Button>())
            {
                if (button.Tag is IconEntry icon &&
                    NormalizeComparableIconPath(icon.RelativePath) == requestedIconPath)
                {
                    SelectIcon(button, icon);
                    button.Focus();
                    requestedIconPath = "";
                    break;
                }
            }
        }

        private static string NormalizeComparableIconPath(string path)
        {
            return Path.ChangeExtension((path ?? "").Replace('/', '\\'), null)
                .TrimStart('\\')
                .ToLowerInvariant();
        }

        private void ClearIconButtons()
        {
            if (flowIcons == null || flowIcons.IsDisposed)
                return;

            selectedButton = null;
            flowIcons.SuspendLayout();
            foreach (Control control in flowIcons.Controls.Cast<Control>().ToArray())
            {
                if (control is Button button)
                {
                    button.Image = null;
                    if (uncachedButtonImages.TryGetValue(button, out Image ownedImage))
                    {
                        ownedImage.Dispose();
                        uncachedButtonImages.Remove(button);
                    }
                }
                control.Dispose();
            }
            flowIcons.Controls.Clear();
            uncachedButtonImages.Clear();
            flowIcons.ResumeLayout();
        }
        
        private Image LoadImageWithCache(string fullPath, out bool isCached)
        {
            isCached = false;
            lock (cacheLock)
            {
                // Check memory cache first
                if (imageCache.ContainsKey(fullPath))
                {
                    isCached = true;
                    return imageCache[fullPath];
                }
            }
            
            Image img = null;
            string ext = Path.GetExtension(fullPath).ToLower();
            
            try
            {
                if (ext == ".blp")
                {
                    // Check disk cache first
                    string cacheFileName = GetCacheFileName(fullPath);
                    string cachedPath = Path.Combine(cacheFolder, cacheFileName);
                    
                    if (File.Exists(cachedPath))
                    {
                        // Load from disk cache (much faster)
                        img = LoadBitmapFromFile(cachedPath);
                    }
                    else
                    {
                        // Convert BLP and save to disk cache
                        img = ConvertBlpAndCache(fullPath, cachedPath);
                    }
                }
                else if (ext == ".png" || ext == ".jpg" || ext == ".jpeg")
                {
                    // Load PNG/JPG normally
                    img = LoadBitmapFromFile(fullPath);
                }
                else if (ext == ".tga")
                {
                    // TGA not supported yet - return null
                    return null;
                }
                
                if (img != null && (img.Width != 64 || img.Height != 64))
                {
                    Image original = img;
                    var thumbnail = new Bitmap(64, 64, PixelFormat.Format32bppPArgb);
                    using (Graphics graphics = Graphics.FromImage(thumbnail))
                    {
                        graphics.Clear(Color.Transparent);
                        graphics.DrawImage(original, new Rectangle(0, 0, 64, 64));
                    }
                    original.Dispose();
                    img = thumbnail;
                }

                // Keep only compact thumbnails in memory.
                if (img != null)
                {
                    lock (cacheLock)
                    {
                        if (imageCache.Count < IMAGE_CACHE_LIMIT && !imageCache.ContainsKey(fullPath))
                        {
                            imageCache[fullPath] = img;
                            isCached = true;
                        }
                    }
                }
                
                return img;
            }
            catch
            {
                return null;
            }
        }
        
        private string GetCacheFileName(string fullPath)
        {
            // Create unique cache filename based on full path hash
            string hash = Convert.ToBase64String(
                System.Security.Cryptography.MD5.Create()
                .ComputeHash(System.Text.Encoding.UTF8.GetBytes(fullPath)))
                .Replace("/", "_").Replace("+", "-").Replace("=", "");
            return hash + ".png";
        }
        
        private Image ConvertBlpAndCache(string blpPath, string cachePath)
        {
            // Check if pre-converted PNG exists in same location as BLP
            string pngPath = Path.ChangeExtension(blpPath, ".png");
            if (File.Exists(pngPath))
            {
                try
                {
                    // Use pre-converted PNG directly
                    return LoadBitmapFromFile(pngPath);
                }
                catch
                {
                    // Fall through to BLP conversion if PNG can't be loaded
                }
            }
            
            try
            {
                using (var fileStream = File.OpenRead(blpPath))
                {
                    var blpFile = new BlpFile(fileStream);
                    
                    // Try different mipmap levels (0 = full size, 1 = half, 2 = quarter, etc.)
                    // Some BLP files have corrupt mipmap 0 but valid smaller mipmaps
                    Bitmap bitmap = null;
                    Bitmap fallbackBitmap = null; // Keep last decoded bitmap as fallback
                    
                    for (int mipmapLevel = 0; mipmapLevel < Math.Min(blpFile.MipMapCount, 4); mipmapLevel++)
                    {
                        try
                        {
                            var bitmapSource = blpFile.GetBitmapSource(mipmapLevel);
                            
                            // Convert to Bitmap
                            using (var ms = new MemoryStream())
                            {
                                var encoder = new PngBitmapEncoder();
                                encoder.Frames.Add(BitmapFrame.Create(bitmapSource));
                                encoder.Save(ms);
                                ms.Seek(0, SeekOrigin.Begin);
                                bitmap = new Bitmap(ms);
                            }
                            
                            // Validate bitmap isn't completely black/empty
                            if (IsValidBitmap(bitmap))
                            {
                                // Found a good mipmap level
                                fallbackBitmap?.Dispose();
                                break;
                            }
                            else
                            {
                                // Keep as fallback but try next mipmap level
                                fallbackBitmap?.Dispose();
                                fallbackBitmap = bitmap;
                                bitmap = null;
                            }
                        }
                        catch
                        {
                            // This mipmap level failed, try next one
                            bitmap?.Dispose();
                            bitmap = null;
                            continue;
                        }
                    }
                    
                    // Use fallback if no valid bitmap found but we have something
                    if (bitmap == null && fallbackBitmap != null)
                    {
                        bitmap = fallbackBitmap;
                        fallbackBitmap = null;
                    }
                    
                    if (bitmap == null)
                    {
                        // All mipmap levels failed completely
                        fallbackBitmap?.Dispose();
                        return null;
                    }
                    
                    // Fix color channels (swap B and R if needed)
                    bitmap = FixBlpColors(bitmap);
                    
                    // Save to disk cache
                    bitmap.Save(cachePath, ImageFormat.Png);
                    
                    return bitmap;
                }
            }
            catch
            {
                return null;
            }
        }

        private static Image LoadBitmapFromFile(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                using (var loaded = Image.FromStream(fs))
                {
                    return new Bitmap(loaded);
                }
            }
        }
        
        private bool IsValidBitmap(Bitmap bitmap)
        {
            if (bitmap == null || bitmap.Width < 4 || bitmap.Height < 4)
                return false;
            
            try
            {
                // Sample several points to see if image has any visible content
                int nonBlackPixels = 0;
                int sampledPixels = 0;
                
                // Sample 16 points in a 4x4 grid
                for (int y = 0; y < 4; y++)
                {
                    for (int x = 0; x < 4; x++)
                    {
                        int px = (bitmap.Width * x) / 4 + bitmap.Width / 8;
                        int py = (bitmap.Height * y) / 4 + bitmap.Height / 8;
                        
                        if (px >= bitmap.Width) px = bitmap.Width - 1;
                        if (py >= bitmap.Height) py = bitmap.Height - 1;
                        
                        Color pixel = bitmap.GetPixel(px, py);
                        sampledPixels++;
                        
                        // Check if pixel has any color content (ignore alpha for transparency)
                        // Very lenient - just check if there's ANY color at all
                        if (pixel.R > 5 || pixel.G > 5 || pixel.B > 5)
                        {
                            nonBlackPixels++;
                        }
                    }
                }
                
                // Consider valid if at least 10% of sampled pixels have any content
                // Very lenient to accept even mostly-dark images
                return nonBlackPixels >= sampledPixels * 0.1;
            }
            catch
            {
                return false;
            }
        }
        
        private Bitmap FixBlpColors(Bitmap original)
        {
            try
            {
                // Sample multiple points to detect if B/R channels are swapped
                int sampleCount = 0;
                long totalR = 0, totalG = 0, totalB = 0;
                int blueHighCount = 0; // Count pixels where blue > red significantly
                int nonZeroPixels = 0; // Count non-black pixels
                
                // Sample 25 points in a 5x5 grid
                for (int sy = 0; sy < 5; sy++)
                {
                    for (int sx = 0; sx < 5; sx++)
                    {
                        int x = (original.Width * sx) / 5 + original.Width / 10;
                        int y = (original.Height * sy) / 5 + original.Height / 10;
                        
                        if (x >= original.Width) x = original.Width - 1;
                        if (y >= original.Height) y = original.Height - 1;
                        
                        Color pixel = original.GetPixel(x, y);
                        
                        // Skip fully transparent pixels
                        if (pixel.A < 10)
                            continue;
                        
                        totalR += pixel.R;
                        totalG += pixel.G;
                        totalB += pixel.B;
                        sampleCount++;
                        
                        // Count non-black pixels
                        if (pixel.R > 5 || pixel.G > 5 || pixel.B > 5)
                        {
                            nonZeroPixels++;
                        }
                        
                        // Check if blue channel is suspiciously higher than red
                        if (pixel.B > pixel.R + 20 && pixel.B > 30)
                        {
                            blueHighCount++;
                        }
                    }
                }
                
                if (sampleCount == 0)
                    return original; // All transparent
                
                // Calculate averages
                double avgR = (double)totalR / sampleCount;
                double avgG = (double)totalG / sampleCount;
                double avgB = (double)totalB / sampleCount;
                
                // Determine if swap is needed
                bool needsSwap = false;
                
                // For very dark images (avg brightness < 5%), be more aggressive
                // If there's ANY blue presence at all, try swapping
                if (avgB > 5 && avgR < 5 && nonZeroPixels > 0)
                {
                    needsSwap = true; // Very dark with any blue = likely BGR
                }
                // For normal brightness images, use statistical analysis
                else if (avgB > avgR * 1.2 && avgB > 20)
                {
                    needsSwap = true; // Blue significantly higher than red
                }
                // If many pixels show blue dominance
                else if (blueHighCount > sampleCount * 0.25)
                {
                    needsSwap = true; // 25% threshold for blue-dominant pixels
                }
                // For images with moderate blue but very low red
                else if (avgB > 15 && avgR < avgB * 0.5)
                {
                    needsSwap = true;
                }
                
                if (!needsSwap)
                {
                    return original;
                }
                
                // Create new bitmap with swapped R and B channels
                Bitmap fixedBitmap = new Bitmap(original.Width, original.Height);
                
                for (int y = 0; y < original.Height; y++)
                {
                    for (int x = 0; x < original.Width; x++)
                    {
                        Color pixel = original.GetPixel(x, y);
                        // Swap R and B channels
                        Color swapped = Color.FromArgb(pixel.A, pixel.B, pixel.G, pixel.R);
                        fixedBitmap.SetPixel(x, y, swapped);
                    }
                }
                
                original.Dispose();
                return fixedBitmap;
            }
            catch
            {
                return original;
            }
        }
        
        // Public method to preload icons (can be called from MainForm)
        public static void PreloadIcons()
        {
            // This can be called on app startup to preload all icons in background
            System.Threading.Tasks.Task.Run(() =>
            {
                try
                {
                    GetAllIconsWithCache();
                }
                catch { /* Silent fail for background task */ }
            });
        }
        
        // Public method to clear cache when needed
        public static void ClearCache()
        {
            lock (cacheLock)
            {
                foreach (var img in imageCache.Values)
                {
                    img?.Dispose();
                }
                imageCache.Clear();
                allIconCache = null;
                allIconCacheKey = "";
            }
        }
        
        private void BtnSelect_Click(object sender, EventArgs e)
        {
            if (selectedIcon != null)
            {
                // Always store as .blp even if using .png file
                string iconPath = selectedIcon.RelativePath;
                if (iconPath.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                {
                    iconPath = Path.ChangeExtension(iconPath, ".blp");
                }
                SelectedIconPath = iconPath;
            }
        }
        
        private void BtnConfig_Click(object sender, EventArgs e)
        {
            using (var configDialog = new IconConfigDialog())
            {
                if (configDialog.ShowDialog() == DialogResult.OK)
                {
                    loadGeneration++;
                    ClearIconButtons();
                    ClearCache();
                    LoadIcons(); // Reload icons with new paths
                }
            }
        }
    }
    
    // Simple configuration dialog for icon paths
    public class IconConfigDialog : Form
    {
        private TextBox txtWC3Path;
        private TextBox txtCustomPath;
        private Button btnBrowseWC3;
        private Button btnBrowseCustom;
        private Button btnSave;
        private Button btnCancel;
        
        public IconConfigDialog()
        {
            InitializeUI();
            LoadCurrentPaths();
        }
        
        private void InitializeUI()
        {
            this.Text = "Icon Path Configuration";
            this.Size = new Size(600, 200);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            
            Label lblWC3 = new Label
            {
                Text = "Warcraft III Icon Path:",
                Location = new Point(20, 25),
                AutoSize = true
            };
            
            txtWC3Path = new TextBox
            {
                Location = new Point(20, 50),
                Width = 450
            };
            
            btnBrowseWC3 = new Button
            {
                Text = "Browse...",
                Location = new Point(480, 48),
                Width = 80
            };
            btnBrowseWC3.Click += (s, e) => BrowseFolder(txtWC3Path);
            
            Label lblCustom = new Label
            {
                Text = "Custom Icon Path:",
                Location = new Point(20, 85),
                AutoSize = true
            };
            
            txtCustomPath = new TextBox
            {
                Location = new Point(20, 110),
                Width = 450
            };
            
            btnBrowseCustom = new Button
            {
                Text = "Browse...",
                Location = new Point(480, 108),
                Width = 80
            };
            btnBrowseCustom.Click += (s, e) => BrowseFolder(txtCustomPath);
            
            btnSave = new Button
            {
                Text = "Save",
                Location = new Point(400, 150),
                Width = 80,
                DialogResult = DialogResult.OK
            };
            btnSave.Click += BtnSave_Click;
            
            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(490, 150),
                Width = 80,
                DialogResult = DialogResult.Cancel
            };
            
            this.Controls.AddRange(new Control[] {
                lblWC3, txtWC3Path, btnBrowseWC3,
                lblCustom, txtCustomPath, btnBrowseCustom,
                btnSave, btnCancel
            });
        }
        
        private void LoadCurrentPaths()
        {
            var config = IconPathConfig.Instance;
            txtWC3Path.Text = config.WarCraft3IconPath;
            txtCustomPath.Text = config.CustomIconPath;
        }
        
        private void BrowseFolder(TextBox target)
        {
            using (var dialog = new FolderBrowserDialog())
            {
                dialog.SelectedPath = target.Text;
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    target.Text = dialog.SelectedPath;
                }
            }
        }
        
        private void BtnSave_Click(object sender, EventArgs e)
        {
            var config = IconPathConfig.Instance;
            config.WarCraft3IconPath = txtWC3Path.Text;
            config.CustomIconPath = txtCustomPath.Text;
            config.Save();
        }
    }
}
