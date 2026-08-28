using System;
using System.Windows.Forms;
using WC3ItemManager.Importers;

namespace WC3ItemManager
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length >= 2 && string.Equals(args[0], "--sync-quest-sources", StringComparison.OrdinalIgnoreCase))
            {
                var sync = new QuestSourceSynchronizer(MainForm.DefaultConnectionString);
                QuestSourceSyncResult result = sync.Synchronize(args[1]);
                Console.WriteLine(
                    $"Files={result.FilesScanned}; QuestsFound={result.QuestDefinitionsFound}; " +
                    $"Containers={result.GiversSynchronized}; GiversCreated={result.GiversCreated}; " +
                    $"GiversUpdated={result.GiversUpdated}; QuestsCreated={result.QuestsCreated}; " +
                    $"QuestsUpdated={result.QuestsUpdated}; Unchanged={result.UnchangedSources}; " +
                    $"Warnings={result.Warnings.Count}; Errors={result.Errors.Count}");
                foreach (string warning in result.Warnings) Console.WriteLine("WARNING: " + warning);
                foreach (string error in result.Errors) Console.Error.WriteLine("ERROR: " + error);
                return result.Errors.Count == 0 ? 0 : 1;
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
            return 0;
        }
    }
}
