using System;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace WC3ItemManager.SourceEditing
{
    public sealed class SourcePatchPreviewForm : Form
    {
        public SourcePatchPreviewForm(SourcePatchPreview preview)
        {
            if (preview == null) throw new ArgumentNullException(nameof(preview));
            Text = "Review synchronized JASS source patch";
            StartPosition = FormStartPosition.CenterParent;
            Width = 1050;
            Height = 760;
            MinimumSize = new Size(800, 560);
            Font = new Font("Segoe UI", 9f);

            var header = new Label
            {
                Dock = DockStyle.Top,
                Height = 66,
                Padding = new Padding(14, 10, 14, 8),
                BackColor = preview.Conflicts.Count == 0
                    ? Color.FromArgb(255, 246, 213)
                    : Color.FromArgb(255, 230, 225),
                ForeColor = Color.FromArgb(67, 53, 28),
                Text = preview.Conflicts.Count == 0
                    ? "Review every mapped change before writing the authoritative .j file. Unmapped custom logic is preserved byte-for-byte."
                    : "The patch has conflicts and cannot be applied. Resolve them in the repository or synchronize again."
            };
            Controls.Add(header);

            var tabs = new TabControl { Dock = DockStyle.Fill, Padding = new Point(12, 5) };
            var changesPage = new TabPage("Mapped changes");
            var changes = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BorderStyle = BorderStyle.None,
                BackColor = Color.White,
                Font = new Font("Consolas", 9.5f),
                Text = BuildSummary(preview)
            };
            changesPage.Controls.Add(changes);
            tabs.TabPages.Add(changesPage);

            var sourcePage = new TabPage("Patched source preview");
            sourcePage.Controls.Add(new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                WordWrap = false,
                BorderStyle = BorderStyle.None,
                BackColor = Color.FromArgb(249, 250, 252),
                Font = new Font("Consolas", 9f),
                Text = string.IsNullOrEmpty(preview.UpdatedText) ? preview.OriginalText : preview.UpdatedText
            });
            tabs.TabPages.Add(sourcePage);
            Controls.Add(tabs);
            tabs.BringToFront();

            var buttons = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 52,
                FlowDirection = FlowDirection.RightToLeft,
                Padding = new Padding(10, 9, 10, 8),
                BackColor = Color.FromArgb(245, 247, 250)
            };
            var apply = new Button
            {
                Text = "Apply source patch",
                Width = 150,
                Height = 30,
                DialogResult = DialogResult.OK,
                Enabled = preview.HasChanges
            };
            var cancel = new Button { Text = "Cancel", Width = 90, Height = 30, DialogResult = DialogResult.Cancel };
            buttons.Controls.Add(apply);
            buttons.Controls.Add(cancel);
            Controls.Add(buttons);
            AcceptButton = apply;
            CancelButton = cancel;
        }

        private static string BuildSummary(SourcePatchPreview preview)
        {
            var text = new StringBuilder();
            text.AppendLine("SOURCE");
            text.AppendLine(preview.RelativePath);
            text.AppendLine();
            if (preview.Conflicts.Count > 0)
            {
                text.AppendLine("CONFLICTS");
                foreach (string conflict in preview.Conflicts) text.AppendLine("! " + conflict);
                text.AppendLine();
            }
            if (preview.Warnings.Count > 0)
            {
                text.AppendLine("WARNINGS");
                foreach (string warning in preview.Warnings) text.AppendLine("- " + warning);
                text.AppendLine();
            }
            text.AppendLine("CHANGES");
            if (preview.Replacements.Count == 0) text.AppendLine("No mapped changes.");
            foreach (SourceReplacement change in preview.Replacements
                         .GroupBy(item => new { item.Label, item.OldValue, item.NewValue })
                         .Select(group => group.First()))
            {
                text.AppendLine($"- {change.Label}");
                if (!string.IsNullOrEmpty(change.OldValue)) text.AppendLine("    from: " + change.OldValue);
                text.AppendLine("      to: " + change.NewValue);
            }
            return text.ToString();
        }
    }
}
