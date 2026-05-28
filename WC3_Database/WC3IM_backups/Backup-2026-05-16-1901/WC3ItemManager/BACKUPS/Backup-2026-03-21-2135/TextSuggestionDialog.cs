using System;
using System.Drawing;
using System.Windows.Forms;

namespace WC3ItemManager
{
    /// <summary>
    /// Dialog for previewing and merging auto-generated text with existing content
    /// </summary>
    public class TextSuggestionDialog : Form
    {
        private TextBox txtCurrent;
        private TextBox txtSuggested;
        private Button btnUseThis;
        private Button btnCopy;
        private Button btnRegenerate;
        private Button btnCancel;
        private string suggestedText;
        private Func<string> regenerateCallback;
        
        public enum SuggestionResult
        {
            Cancel,
            UseThis,
            Regenerate
        }
        
        public SuggestionResult Result { get; private set; }
        public string FinalText { get; private set; }
        
        public TextSuggestionDialog(string currentText, string suggested, string fieldName, Func<string> onRegenerate = null)
        {
            this.suggestedText = suggested;
            this.FinalText = currentText;
            this.Result = SuggestionResult.Cancel;
            this.regenerateCallback = onRegenerate;
            
            InitializeUI(currentText, suggested, fieldName);
        }
        
        private void InitializeUI(string currentText, string suggested, string fieldName)
        {
            this.Text = $"Auto-Generate Suggestion - {fieldName}";
            this.Size = new Size(900, 600);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            
            int y = 20;
            
            // Current text section
            Label lblCurrent = new Label
            {
                Text = "📄 Current Text:",
                Location = new Point(20, y),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            this.Controls.Add(lblCurrent);
            
            y += 30;
            txtCurrent = new TextBox
            {
                Location = new Point(20, y),
                Size = new Size(840, 180),
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                ReadOnly = true,
                BackColor = Color.FromArgb(245, 245, 245),
                Font = new Font("Segoe UI", 9),
                Text = string.IsNullOrWhiteSpace(currentText) ? "(empty)" : currentText
            };
            this.Controls.Add(txtCurrent);
            
            y += 190;
            
            // Suggested text section
            Label lblSuggested = new Label
            {
                Text = "✨ AI-Generated Suggestion:",
                Location = new Point(20, y),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.FromArgb(33, 150, 243)
            };
            this.Controls.Add(lblSuggested);
            
            y += 30;
            txtSuggested = new TextBox
            {
                Location = new Point(20, y),
                Size = new Size(840, 180),
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                ReadOnly = true,
                BackColor = Color.FromArgb(232, 245, 233),
                Font = new Font("Segoe UI", 9),
                Text = suggested
            };
            this.Controls.Add(txtSuggested);
            
            y += 190;
            
            // Info label
            Label lblInfo = new Label
            {
                Text = "💡 Choose an action:",
                Location = new Point(20, y),
                Size = new Size(840, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Italic),
                ForeColor = Color.Gray
            };
            this.Controls.Add(lblInfo);
            
            y += 25;
            
            // Buttons
            btnCopy = new Button
            {
                Text = "📋 Copy from Suggestion",
                Location = new Point(20, y),
                Size = new Size(180, 35),
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(96, 125, 139),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnCopy.Click += BtnCopy_Click;
            this.Controls.Add(btnCopy);
            
            btnUseThis = new Button
            {
                Text = "✅ Use This",
                Location = new Point(210, y),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                BackColor = Color.FromArgb(76, 175, 80),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnUseThis.Click += BtnUseThis_Click;
            this.Controls.Add(btnUseThis);
            
            btnRegenerate = new Button
            {
                Text = "🔄 Re-generate",
                Location = new Point(370, y),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(255, 152, 0),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnRegenerate.Click += BtnRegenerate_Click;
            btnRegenerate.Enabled = (regenerateCallback != null);
            this.Controls.Add(btnRegenerate);
            
            btnCancel = new Button
            {
                Text = "❌ Cancel",
                Location = new Point(530, y),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 9),
                FlatStyle = FlatStyle.Flat,
                DialogResult = DialogResult.Cancel
            };
            btnCancel.Click += (s, e) => { Result = SuggestionResult.Cancel; };
            this.Controls.Add(btnCancel);
            
            this.CancelButton = btnCancel;
        }
        
        private void BtnUseThis_Click(object sender, EventArgs e)
        {
            var confirmResult = MessageBox.Show(
                "Replace current text with this suggestion?",
                "Confirm Use This",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            
            if (confirmResult == DialogResult.Yes)
            {
                Result = SuggestionResult.UseThis;
                FinalText = suggestedText;
                this.DialogResult = DialogResult.OK;
                this.Close();
            }
        }
        
        private void BtnCopy_Click(object sender, EventArgs e)
        {
            try
            {
                Clipboard.SetText(suggestedText);
                MessageBox.Show("Suggested text copied to clipboard!", "Copied",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error copying to clipboard: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void BtnRegenerate_Click(object sender, EventArgs e)
        {
            if (regenerateCallback == null)
            {
                MessageBox.Show("Re-generation is not available.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            
            try
            {
                // Generate new text
                string newSuggestion = regenerateCallback();
                
                if (!string.IsNullOrEmpty(newSuggestion))
                {
                    suggestedText = newSuggestion;
                    txtSuggested.Text = newSuggestion;
                    MessageBox.Show("New suggestion generated!", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error regenerating text: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
