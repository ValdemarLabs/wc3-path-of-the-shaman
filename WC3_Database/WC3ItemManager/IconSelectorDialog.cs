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
        private Button btnPreviousPage;
        private Button btnNextPage;
        private Label lblPage;
        private Label lblStatus;
        private Label lblCurrentPath;
        private SplitContainer splitContainer;
        private List<IconEntry> allIcons;
        private IconEntry selectedIcon;
        private string currentFolder = "";
        
        // Static caches persist across dialog instances (prevents reloading large icon folders repeatedly)
        private const int IMAGE_CACHE_LIMIT = 1000;
        private const int PAGE_SIZE = 200;
        private static Dictionary<string, Image> imageCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);
        private static Dictionary<string, List<string>> folderFileCache = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        private static List<IconEntry> allIconCache;
        private static string allIconCacheKey = "";
        private static object cacheLock = new object(); // Thread safety
        private static string cacheFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache");
        
        // Async loading state
        private List<IconEntry> pendingIcons = new List<IconEntry>();
        private int loadedIconCount = 0;
        private int currentPage = 0;
        private int loadGeneration = 0;
        private const int BATCH_SIZE = 50;
        private ProgressBar progressBar;
        private Label lblLoading;
        
        public string SelectedIconPath { get; private set; }
        
        public IconSelectorDialog(string currentPath = "")
        {
            // Ensure cache folder exists
            if (!Directory.Exists(cacheFolder))
            {
                Directory.CreateDirectory(cacheFolder);
            }
            
            InitializeUI();
            LoadIcons();
            
            if (!string.IsNullOrEmpty(currentPath))
            {
                HighlightIcon(currentPath);
            }
        }
        
        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            loadGeneration++;
            ClearDisplayedIcons();
            lblLoading?.Dispose();
            progressBar?.Dispose();
            lblLoading = null;
            progressBar = null;
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
            txtSearch.TextChanged += (s, e) => FilterIcons();
            
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
                Text = "⚙ Configure Paths",
                Location = new Point(550, 10),
                Width = 150,
                Height = 28
            };
            btnConfig.Click += BtnConfig_Click;

            btnPreviousPage = new Button
            {
                Text = "Previous",
                Location = new Point(720, 10),
                Width = 80,
                Height = 28,
                Enabled = false
            };
            btnPreviousPage.Click += async (s, e) =>
            {
                if (currentPage > 0)
                {
                    currentPage--;
                    await LoadCurrentPageAsync();
                }
            };

            lblPage = new Label
            {
                Text = "Page 0/0",
                Location = new Point(810, 15),
                Width = 90,
                TextAlign = ContentAlignment.MiddleCenter
            };

            btnNextPage = new Button
            {
                Text = "Next",
                Location = new Point(910, 10),
                Width = 80,
                Height = 28,
                Enabled = false
            };
            btnNextPage.Click += async (s, e) =>
            {
                int pageCount = GetPageCount();
                if (currentPage + 1 < pageCount)
                {
                    currentPage++;
                    await LoadCurrentPageAsync();
                }
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
                btnPreviousPage, lblPage, btnNextPage, lblCurrentPath, lblStatus
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
        
        private void LoadIcons()
        {
            treeFolder.Nodes.Clear();
            ClearDisplayedIcons();
            lblStatus.Text = "Loading folder structure...";
            Application.DoEvents();
            
            try
            {
                allIcons = GetAllIconsWithCache();
                LoadFolderTree();
                lblStatus.Text = $"Loaded {allIcons.Count} icons";
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
            
            // Add Blizzard root if applicable
            if ((sourceFilter == "All" || sourceFilter == "Blizzard") && Directory.Exists(config.WarCraft3IconPath))
            {
                TreeNode blizzNode = new TreeNode("Blizzard WC3 Icons")
                {
                    Tag = new FolderInfo { FullPath = config.WarCraft3IconPath, Source = "Blizzard" },
                    ImageIndex = 0
                };
                BuildFolderTree(blizzNode, config.WarCraft3IconPath, "Blizzard");
                treeFolder.Nodes.Add(blizzNode);
                blizzNode.Expand();
            }
            
            // Add Custom root if applicable
            if ((sourceFilter == "All" || sourceFilter == "Custom") && Directory.Exists(config.CustomIconPath))
            {
                TreeNode customNode = new TreeNode("Custom Icons")
                {
                    Tag = new FolderInfo { FullPath = config.CustomIconPath, Source = "Custom" },
                    ImageIndex = 0
                };
                BuildFolderTree(customNode, config.CustomIconPath, "Custom");
                treeFolder.Nodes.Add(customNode);
                customNode.Expand();
            }
            
            // Select first node by default
            if (treeFolder.Nodes.Count > 0)
            {
                treeFolder.SelectedNode = treeFolder.Nodes[0];
            }
        }
        
        private void BuildFolderTree(TreeNode parentNode, string path, string source)
        {
            try
            {
                // Add subdirectories
                var directories = Directory.GetDirectories(path);
                foreach (var dir in directories)
                {
                    string folderName = Path.GetFileName(dir);
                    TreeNode childNode = new TreeNode(folderName)
                    {
                        Tag = new FolderInfo { FullPath = dir, Source = source }
                    };

                    BuildFolderTree(childNode, dir, source);
                    bool hasIcons = GetFolderIconFiles(dir).Count > 0;

                    if (hasIcons || childNode.Nodes.Count > 0)
                    {
                        parentNode.Nodes.Add(childNode);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error building folder tree for {path}: {ex.Message}");
            }
        }
        
        private static bool IsIconFile(string file)
        {
            string ext = Path.GetExtension(file).ToLower();
            return ext == ".blp" || ext == ".tga" || ext == ".png" || ext == ".jpg" || ext == ".jpeg";
        }
        
        private void TreeFolder_AfterSelect(object sender, TreeViewEventArgs e)
        {
            if (e.Node?.Tag is FolderInfo folderInfo)
            {
                currentFolder = folderInfo.FullPath;
                lblCurrentPath.Text = $"Current folder: {e.Node.FullPath}";
                LoadIconsFromFolderAsync(folderInfo.FullPath, folderInfo.Source);
            }
        }
        
        private async void LoadIconsFromFolderAsync(string folderPath, string source)
        {
            int generation = ++loadGeneration;
            lblStatus.ForeColor = Color.Gray;
            try
            {
                string search = txtSearch.Text.Trim();
                List<IconEntry> filtered;

                if (!string.IsNullOrEmpty(search))
                {
                    string sourceFilter = cmbSource.SelectedItem?.ToString() ?? "All";
                    filtered = allIcons
                        .Where(icon => (sourceFilter == "All" || icon.Source == sourceFilter) &&
                            (icon.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                             icon.RelativePath.Contains(search, StringComparison.OrdinalIgnoreCase)))
                        .ToList();
                }
                else
                {
                    var files = await System.Threading.Tasks.Task.Run(() => GetFolderIconFiles(folderPath));
                    filtered = files.Select(file => CreateIconEntry(file, source)).ToList();
                }

                if (generation != loadGeneration)
                    return;

                pendingIcons = filtered;
                currentPage = 0;
                await LoadCurrentPageAsync(generation);
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error loading folder: {ex.Message}";
                lblStatus.ForeColor = Color.Red;
            }
        }
        
        private async System.Threading.Tasks.Task LoadCurrentPageAsync(int? requestedGeneration = null)
        {
            int generation = requestedGeneration ?? ++loadGeneration;
            int pageCount = GetPageCount();
            if (pageCount == 0)
                currentPage = 0;
            else if (currentPage >= pageCount)
                currentPage = pageCount - 1;

            ClearDisplayedIcons();
            ShowLoadingIndicator(true);

            var pageIcons = pendingIcons
                .Skip(currentPage * PAGE_SIZE)
                .Take(PAGE_SIZE)
                .ToList();
            loadedIconCount = 0;
            UpdatePageControls();
            lblStatus.Text = $"Loading {pageIcons.Count} of {pendingIcons.Count} matching icons...";

            if (pageIcons.Count == 0)
            {
                ShowLoadingIndicator(false);
                lblStatus.Text = "No matching icons";
                return;
            }

            foreach (var icon in pageIcons)
            {
                if (generation != loadGeneration)
                    return;

                AddIconButton(icon);
                loadedIconCount++;

                if (loadedIconCount % BATCH_SIZE == 0)
                {
                    if (progressBar != null && progressBar.Visible)
                    {
                        int percent = (int)((float)loadedIconCount / pageIcons.Count * 100);
                        progressBar.Value = Math.Min(percent, 100);
                    }
                    flowIcons.PerformLayout();
                    await System.Threading.Tasks.Task.Yield();
                }
            }

            ShowLoadingIndicator(false);
            flowIcons.PerformLayout();
            lblStatus.Text = $"Showing {pageIcons.Count} of {pendingIcons.Count} matching icons";
        }

        private void ClearDisplayedIcons()
        {
            foreach (Control control in flowIcons.Controls.Cast<Control>().ToArray())
            {
                flowIcons.Controls.Remove(control);
                if (ReferenceEquals(control, lblLoading) || ReferenceEquals(control, progressBar))
                    continue;

                foreach (PictureBox pictureBox in control.Controls.OfType<PictureBox>())
                {
                    if (pictureBox.Tag is bool ownsImage && ownsImage)
                        pictureBox.Image?.Dispose();
                    pictureBox.Image = null;
                }
                control.Dispose();
            }
        }

        private int GetPageCount()
        {
            return pendingIcons.Count == 0 ? 0 : (pendingIcons.Count + PAGE_SIZE - 1) / PAGE_SIZE;
        }

        private void UpdatePageControls()
        {
            int pageCount = GetPageCount();
            lblPage.Text = pageCount == 0 ? "Page 0/0" : $"Page {currentPage + 1}/{pageCount}";
            btnPreviousPage.Enabled = currentPage > 0;
            btnNextPage.Enabled = currentPage + 1 < pageCount;
        }

        private static IconEntry CreateIconEntry(string fullPath, string source)
        {
            var config = IconPathConfig.Instance;
            string basePath = source == "Blizzard" ? config.WarCraft3IconPath : config.CustomIconPath;
            return new IconEntry
            {
                FullPath = fullPath,
                RelativePath = fullPath.Replace(basePath, "").TrimStart('\\', '/'),
                Name = Path.GetFileNameWithoutExtension(fullPath),
                Source = source
            };
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

        private static List<string> GetFolderIconFiles(string folderPath)
        {
            lock (cacheLock)
            {
                if (folderFileCache.TryGetValue(folderPath, out var cachedFiles))
                {
                    return new List<string>(cachedFiles);
                }
            }

            List<string> allFiles;
            try
            {
                allFiles = Directory.EnumerateFiles(folderPath, "*.*", SearchOption.TopDirectoryOnly)
                    .Where(IsIconFile)
                    .ToList();
            }
            catch
            {
                allFiles = new List<string>();
            }

            lock (cacheLock)
            {
                folderFileCache[folderPath] = new List<string>(allFiles);
            }

            return allFiles;
        }
        
        private void ShowLoadingIndicator(bool show)
        {
            if (show)
            {
                if (lblLoading == null)
                {
                    lblLoading = new Label
                    {
                        Text = "Loading icons...",
                        Location = new Point(flowIcons.Width / 2 - 100, 50),
                        Width = 200,
                        Height = 30,
                        TextAlign = ContentAlignment.MiddleCenter,
                        Font = new Font("Segoe UI", 12, FontStyle.Bold),
                        ForeColor = Color.DarkBlue,
                        BackColor = Color.White
                    };
                    
                    progressBar = new ProgressBar
                    {
                        Location = new Point(flowIcons.Width / 2 - 100, 90),
                        Width = 200,
                        Height = 20,
                        Style = ProgressBarStyle.Continuous
                    };
                }
                
                if (!flowIcons.Controls.Contains(lblLoading))
                {
                    flowIcons.Controls.Add(lblLoading);
                    flowIcons.Controls.Add(progressBar);
                    lblLoading.BringToFront();
                    progressBar.BringToFront();
                }
                
                lblLoading.Visible = true;
                progressBar.Visible = true;
                progressBar.Value = 0;
            }
            else
            {
                if (lblLoading != null)
                {
                    lblLoading.Visible = false;
                    progressBar.Visible = false;
                }
            }
        }
        
        private void FilterIcons()
        {
            // Just refresh current folder with search filter
            if (!string.IsNullOrEmpty(currentFolder) && treeFolder.SelectedNode?.Tag is FolderInfo folderInfo)
            {
                LoadIconsFromFolderAsync(currentFolder, folderInfo.Source);
            }
        }
        
        private void AddIconButton(IconEntry icon)
        {
            string fullPath = icon.FullPath;
            
            Panel iconBox = new Panel
            {
                Width = 90,
                Height = 120,
                Margin = new Padding(5),
                BorderStyle = BorderStyle.FixedSingle,
                Cursor = Cursors.Hand,
                Tag = icon
            };
            
            PictureBox pic = new PictureBox
            {
                Width = 64,
                Height = 64,
                Location = new Point(13, 5),
                SizeMode = PictureBoxSizeMode.Zoom,
                BackColor = Color.FromArgb(30, 30, 30)
            };
            
            Label lbl = new Label
            {
                Text = Path.GetFileNameWithoutExtension(fullPath),
                Location = new Point(2, 72),
                Width = 86,
                Height = 45,
                TextAlign = ContentAlignment.TopCenter,
                Font = new Font("Segoe UI", 7),
                ForeColor = Color.Black
            };
            
            // Wrap text if too long
            if (lbl.Text.Length > 15)
            {
                lbl.Text = lbl.Text.Substring(0, 12) + "...";
            }
            
            // Load icon image with caching
            try
            {
                Image loadedImage = LoadImageWithCache(fullPath, out bool isCached);
                if (loadedImage != null)
                {
                    pic.Image = loadedImage;
                    pic.Tag = !isCached;
                    pic.BackColor = Color.Black;
                }
                else
                {
                    // Failed to load - show placeholder
                    pic.BackColor = Color.FromArgb(120, 40, 40);
                }
            }
            catch
            {
                pic.BackColor = Color.FromArgb(120, 40, 40);
            }
            
            iconBox.Controls.Add(pic);
            iconBox.Controls.Add(lbl);
            
            // Click handlers
            iconBox.Click += (s, e) => SelectIcon(iconBox, (IconEntry)iconBox.Tag);
            pic.Click += (s, e) => SelectIcon(iconBox, (IconEntry)iconBox.Tag);
            lbl.Click += (s, e) => SelectIcon(iconBox, (IconEntry)iconBox.Tag);
            iconBox.DoubleClick += (s, e) => { SelectIcon(iconBox, (IconEntry)iconBox.Tag); this.DialogResult = DialogResult.OK; };
            
            flowIcons.Controls.Add(iconBox);
        }
        
        private void SelectIcon(Panel iconBox, IconEntry icon)
        {
            // Remove highlight from previous selection
            foreach (Control ctrl in flowIcons.Controls)
            {
                if (ctrl is Panel p)
                    p.BackColor = SystemColors.Control;
            }
            
            // Highlight selected
            iconBox.BackColor = Color.LightBlue;
            selectedIcon = icon;
            btnSelect.Enabled = true;
        }
        
        private void HighlightIcon(string path)
        {
            // Try to find and highlight the icon with the given path
            foreach (Control ctrl in flowIcons.Controls)
            {
                if (ctrl is Panel p && p.Tag is IconEntry icon)
                {
                    if (icon.RelativePath.Equals(path, StringComparison.OrdinalIgnoreCase))
                    {
                        SelectIcon(p, icon);
                        break;
                    }
                }
            }
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
                folderFileCache.Clear();
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
                    ClearDisplayedIcons();
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
