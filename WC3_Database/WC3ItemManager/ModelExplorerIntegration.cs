using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace WC3ItemManager
{
    internal static class ModelExplorerIntegration
    {
        private const string ExplorerExecutableName = "WC3ModelExplorer.exe";

        public static string ExecutablePath { get; private set; } = string.Empty;
        public static string NativeModelSourcePath { get; private set; } = string.Empty;
        public static string MapModelSourcePath { get; private set; } = string.Empty;

        public static void Configure(string executablePath, string nativeModelSourcePath, string mapModelSourcePath)
        {
            ExecutablePath = executablePath?.Trim() ?? string.Empty;
            NativeModelSourcePath = nativeModelSourcePath?.Trim() ?? string.Empty;
            MapModelSourcePath = mapModelSourcePath?.Trim() ?? string.Empty;
        }

        public static void ShowBrowseMenu(Control anchor, IWin32Window owner)
        {
            if (anchor == null)
                return;

            var menu = new ContextMenuStrip();
            menu.Items.Add("Map imported models", null, (s, e) => LaunchSource(MapModelSourcePath, "map model source", owner));
            menu.Items.Add("Native WC3 models", null, (s, e) => LaunchSource(NativeModelSourcePath, "native model source", owner));
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Open last Model Explorer source", null, (s, e) => LaunchExplorer(null, owner));
            // Closed is raised while ToolStripDropDown is still finishing an item click.
            // Dispose on the next UI message so WinForms can complete that code path first.
            menu.Closed += (s, e) =>
            {
                if (!anchor.IsDisposed && anchor.IsHandleCreated)
                {
                    anchor.BeginInvoke(new Action(menu.Dispose));
                }
            };
            menu.Show(anchor, 0, anchor.Height);
        }

        public static void PasteCopiedModelPath(IWin32Window owner, Action<string> applyPath)
        {
            if (applyPath == null)
                return;

            string clipboardText;
            try
            {
                clipboardText = Clipboard.ContainsText() ? Clipboard.GetText() : string.Empty;
            }
            catch (Exception ex)
            {
                ShowError(owner, $"Could not read the clipboard:\n{ex.Message}");
                return;
            }

            if (!TryNormalizeModelPath(clipboardText, out string modelPath, out string error))
            {
                ShowError(owner, error);
                return;
            }

            applyPath(modelPath);
        }

        internal static bool TryNormalizeModelPath(string clipboardText, out string modelPath, out string error)
        {
            modelPath = string.Empty;
            error = string.Empty;

            string value = (clipboardText ?? string.Empty)
                .Split(new[] { "\r\n", "\n", "\r" }, StringSplitOptions.RemoveEmptyEntries)
                .Select(line => line.Trim().Trim('"'))
                .FirstOrDefault(line => !string.IsNullOrWhiteSpace(line)) ?? string.Empty;

            if (string.IsNullOrWhiteSpace(value))
            {
                error = "The clipboard does not contain a model path.";
                return false;
            }

            value = value.Replace('/', '\\');
            string extension = Path.GetExtension(value);
            if (!extension.Equals(".mdx", StringComparison.OrdinalIgnoreCase) &&
                !extension.Equals(".mdl", StringComparison.OrdinalIgnoreCase))
            {
                error = "The copied value is not an MDX or MDL model path.";
                return false;
            }

            if (!Path.IsPathRooted(value))
            {
                modelPath = value.TrimStart('\\');
                return true;
            }

            if (TryPathAfterDirectory(value, "war3.w3mod", includeDirectory: false, out modelPath) ||
                TryPathAfterDirectory(value, "war3mapImported", includeDirectory: true, out modelPath) ||
                TryPathAfterTemporaryMapDirectory(value, out modelPath) ||
                TryMakeRelativeToConfiguredDirectory(value, NativeModelSourcePath, out modelPath) ||
                TryMakeRelativeToConfiguredDirectory(value, MapModelSourcePath, out modelPath))
            {
                return true;
            }

            error =
                "The copied path is an absolute filesystem path that cannot be converted safely to a Warcraft III model path.\n\n" +
                "Copy a model from the configured native/map source, or enter its Warcraft III import path manually.";
            return false;
        }

        private static bool TryPathAfterDirectory(string path, string directoryName, bool includeDirectory, out string relativePath)
        {
            relativePath = string.Empty;
            string marker = "\\" + directoryName + "\\";
            int markerIndex = path.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
            if (markerIndex < 0)
                return false;

            int start = includeDirectory ? markerIndex + 1 : markerIndex + marker.Length;
            relativePath = path.Substring(start).TrimStart('\\');
            return !string.IsNullOrWhiteSpace(relativePath);
        }

        private static bool TryPathAfterTemporaryMapDirectory(string path, out string relativePath)
        {
            relativePath = string.Empty;
            string[] parts = path.Split(new[] { '\\' }, StringSplitOptions.RemoveEmptyEntries);
            int tempRootIndex = Array.FindIndex(parts,
                part => part.StartsWith("wc3map_", StringComparison.OrdinalIgnoreCase));
            if (tempRootIndex < 0 || tempRootIndex >= parts.Length - 1)
                return false;

            relativePath = string.Join("\\", parts.Skip(tempRootIndex + 1));
            return !string.IsNullOrWhiteSpace(relativePath);
        }

        private static bool TryMakeRelativeToConfiguredDirectory(string path, string configuredSource, out string relativePath)
        {
            relativePath = string.Empty;
            if (string.IsNullOrWhiteSpace(configuredSource) || !Directory.Exists(configuredSource))
                return false;

            try
            {
                string root = Path.GetFullPath(configuredSource)
                    .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar) + Path.DirectorySeparatorChar;
                string fullPath = Path.GetFullPath(path);
                if (!fullPath.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                    return false;

                relativePath = fullPath.Substring(root.Length).Replace('/', '\\');
                return !string.IsNullOrWhiteSpace(relativePath);
            }
            catch
            {
                return false;
            }
        }

        private static void LaunchSource(string sourcePath, string sourceLabel, IWin32Window owner)
        {
            if (string.IsNullOrWhiteSpace(sourcePath))
            {
                MessageBox.Show(
                    $"No {sourceLabel} is configured.\n\nOpen Tools > Configuration > Model Explorer and select it first.",
                    "Model Explorer Source Not Configured",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
                return;
            }

            bool sourceExists = File.Exists(sourcePath) || Directory.Exists(sourcePath);
            if (!sourceExists)
            {
                ShowError(owner, $"The configured {sourceLabel} does not exist:\n{sourcePath}");
                return;
            }

            try
            {
                Clipboard.SetText(sourcePath);
            }
            catch (Exception ex)
            {
                ShowError(owner, $"Could not copy the source path to the clipboard:\n{ex.Message}");
                return;
            }

            if (!LaunchExplorer(sourcePath, owner))
                return;

            MessageBox.Show(
                "The source path was copied to the clipboard.\n\n" +
                "WC3 Model Explorer 1.4.0 does not accept a startup source. Paste the path into its top source field and press Enter. " +
                "After choosing a model, use Copy Path there and Paste Path in WC3 Manager.",
                "Model Explorer Source Copied",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }

        private static bool LaunchExplorer(string futureSourceArgument, IWin32Window owner)
        {
            string executable = ResolveExecutablePath();
            if (string.IsNullOrWhiteSpace(executable) || !File.Exists(executable))
            {
                ShowError(owner,
                    "WC3 Model Explorer is not configured or its executable cannot be found.\n\n" +
                    "Open Tools > Configuration > Model Explorer and select WC3ModelExplorer.exe.");
                return false;
            }

            try
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = executable,
                    WorkingDirectory = Path.GetDirectoryName(executable) ?? string.Empty,
                    UseShellExecute = true
                };

                // Version 1.4.0 ignores arguments. Keeping the source argument here is harmless for 1.4.0
                // and allows a future version with file/folder argument support to open it directly.
                if (!string.IsNullOrWhiteSpace(futureSourceArgument))
                    startInfo.ArgumentList.Add(futureSourceArgument);

                Process.Start(startInfo);
                return true;
            }
            catch (Exception ex)
            {
                ShowError(owner, $"Could not launch WC3 Model Explorer:\n{ex.Message}");
                return false;
            }
        }

        private static string ResolveExecutablePath()
        {
            if (Directory.Exists(ExecutablePath))
                return Path.Combine(ExecutablePath, ExplorerExecutableName);

            return ExecutablePath;
        }

        private static void ShowError(IWin32Window owner, string message)
        {
            MessageBox.Show(owner, message, "WC3 Model Explorer", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }
}
