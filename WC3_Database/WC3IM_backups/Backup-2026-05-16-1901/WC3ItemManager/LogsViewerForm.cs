using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for viewing application logs in real-time
    /// </summary>
    public class LogsViewerForm : Form
    {
        private RichTextBox rtbLogs;
        private Button btnClear;
        private Button btnOpenFolder;
        private Button btnRefresh;
        private ComboBox cmbLogFile;
        private Label lblStatus;
        private string _logFolder;

        public LogsViewerForm()
        {
            InitializeComponent();
            
            // Find log folder
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string logsLower = Path.Combine(baseDir, "logs");
            string logsUpper = Path.Combine(baseDir, "Logs");
            _logFolder = Directory.Exists(logsLower) ? logsLower : logsUpper;
            
            // Subscribe to live log events
            Logger.Instance.OnLogEntry += OnLogEntry;
            
            // Load available log files and show current session
            LoadLogFiles();
        }

        private void InitializeComponent()
        {
            this.Text = "Application Logs";
            this.Size = new Size(900, 600);
            this.StartPosition = FormStartPosition.CenterParent;
            this.MinimumSize = new Size(600, 400);

            // Top toolbar panel
            var pnlToolbar = new Panel
            {
                Dock = DockStyle.Top,
                Height = 40,
                Padding = new Padding(5)
            };

            var lblFile = new Label
            {
                Text = "Log File:",
                Location = new Point(5, 10),
                AutoSize = true,
                ForeColor = Color.White
            };

            cmbLogFile = new ComboBox
            {
                Location = new Point(65, 7),
                Width = 300,
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            cmbLogFile.SelectedIndexChanged += CmbLogFile_SelectedIndexChanged;

            btnRefresh = new Button
            {
                Text = "Refresh",
                Location = new Point(380, 6),
                Size = new Size(70, 25),
                BackColor = Color.FromArgb(70, 70, 70),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnRefresh.Click += (s, e) => LoadSelectedLogFile();

            btnClear = new Button
            {
                Text = "Clear View",
                Location = new Point(460, 6),
                Size = new Size(80, 25),
                BackColor = Color.FromArgb(70, 70, 70),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnClear.Click += (s, e) => rtbLogs.Clear();

            btnOpenFolder = new Button
            {
                Text = "Open Logs Folder",
                Location = new Point(550, 6),
                Size = new Size(120, 25),
                BackColor = Color.FromArgb(70, 70, 70),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOpenFolder.Click += BtnOpenFolder_Click;

            pnlToolbar.Controls.AddRange(new Control[] { lblFile, cmbLogFile, btnRefresh, btnClear, btnOpenFolder });

            // Log text area
            rtbLogs = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                Font = new Font("Consolas", 9),
                BackColor = Color.FromArgb(20, 20, 20),
                ForeColor = Color.LightGray,
                WordWrap = false
            };

            // Status bar
            lblStatus = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 25,
                BackColor = Color.FromArgb(35, 35, 35),
                ForeColor = Color.LightGray,
                Padding = new Padding(5, 5, 0, 0),
                Text = "Live log updates enabled"
            };

            this.Controls.Add(rtbLogs);
            this.Controls.Add(pnlToolbar);
            this.Controls.Add(lblStatus);

            // Dark theme
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            pnlToolbar.BackColor = Color.FromArgb(45, 45, 45);
        }

        private void LoadLogFiles()
        {
            cmbLogFile.Items.Clear();
            cmbLogFile.Items.Add("(Current Session - Live)");

            if (Directory.Exists(_logFolder))
            {
                var logFiles = Directory.GetFiles(_logFolder, "ItemManager_*.log");
                Array.Sort(logFiles);
                Array.Reverse(logFiles); // Most recent first

                foreach (var file in logFiles)
                {
                    cmbLogFile.Items.Add(Path.GetFileName(file));
                }
            }

            cmbLogFile.SelectedIndex = 0;
        }

        private void CmbLogFile_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadSelectedLogFile();
        }

        private void LoadSelectedLogFile()
        {
            rtbLogs.Clear();

            if (cmbLogFile.SelectedIndex == 0)
            {
                // Current session - load existing entries then enable live updates
                LoadCurrentSessionLogs();
                lblStatus.Text = "Live log updates enabled - showing current session";
                return;
            }

            string fileName = cmbLogFile.SelectedItem?.ToString();
            if (string.IsNullOrEmpty(fileName)) return;

            string filePath = Path.Combine(_logFolder, fileName);
            if (!File.Exists(filePath))
            {
                rtbLogs.Text = "Log file not found.";
                return;
            }

            try
            {
                // Read file with sharing (file may be open by logger)
                using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (var reader = new StreamReader(fs))
                {
                    string content = reader.ReadToEnd();
                    
                    // Color code the lines
                    foreach (var line in content.Split('\n'))
                    {
                        AppendLogLine(line);
                    }
                }

                var fileInfo = new FileInfo(filePath);
                lblStatus.Text = $"Showing historical log: {fileName} ({fileInfo.Length:N0} bytes)";
            }
            catch (Exception ex)
            {
                rtbLogs.Text = $"Error reading log file: {ex.Message}";
            }
        }

        private void LoadCurrentSessionLogs()
        {
            try
            {
                string currentLogPath = Logger.Instance.CurrentLogFilePath;
                if (string.IsNullOrEmpty(currentLogPath) || !File.Exists(currentLogPath))
                {
                    rtbLogs.Text = "No log entries yet in current session.";
                    return;
                }

                // Read file with sharing (file is open by logger)
                using (var fs = new FileStream(currentLogPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (var reader = new StreamReader(fs))
                {
                    string content = reader.ReadToEnd();
                    
                    // Color code the lines
                    foreach (var line in content.Split('\n'))
                    {
                        AppendLogLine(line);
                    }
                }
            }
            catch (Exception ex)
            {
                rtbLogs.Text = $"Error reading current session log: {ex.Message}";
            }
        }

        private void OnLogEntry(string entry, LogLevel level)
        {
            if (InvokeRequired)
            {
                BeginInvoke(new Action(() => OnLogEntry(entry, level)));
                return;
            }

            // Only append if showing current session
            if (cmbLogFile.SelectedIndex == 0)
            {
                AppendLogLine(entry, level);
                rtbLogs.ScrollToCaret();
            }
        }

        private void AppendLogLine(string line, LogLevel? level = null)
        {
            if (string.IsNullOrEmpty(line)) return;

            Color color;
            if (level.HasValue)
            {
                color = level.Value switch
                {
                    LogLevel.Error => Color.FromArgb(255, 100, 100),
                    LogLevel.Warning => Color.FromArgb(255, 200, 100),
                    _ => Color.LightGray
                };
            }
            else
            {
                // Detect level from line content
                if (line.Contains("[ERROR]"))
                    color = Color.FromArgb(255, 100, 100);
                else if (line.Contains("[WARN]"))
                    color = Color.FromArgb(255, 200, 100);
                else
                    color = Color.LightGray;
            }

            rtbLogs.SelectionStart = rtbLogs.TextLength;
            rtbLogs.SelectionLength = 0;
            rtbLogs.SelectionColor = color;
            rtbLogs.AppendText(line + "\n");
        }

        private void BtnOpenFolder_Click(object sender, EventArgs e)
        {
            if (Directory.Exists(_logFolder))
            {
                System.Diagnostics.Process.Start("explorer.exe", _logFolder);
            }
            else
            {
                MessageBox.Show("Logs folder not found.", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            // Unsubscribe from log events
            Logger.Instance.OnLogEntry -= OnLogEntry;
            base.OnFormClosed(e);
        }
    }
}
