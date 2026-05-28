using System;
using System.IO;
using System.Text;

namespace WC3ItemManager
{
    /// <summary>
    /// Log levels for application logging
    /// </summary>
    public enum LogLevel
    {
        Info,
        Warning,
        Error
    }

    /// <summary>
    /// Simple file-based logger for ItemManager
    /// </summary>
    public class Logger : IDisposable
    {
        private static Logger _instance;
        private static readonly object _lock = new object();
        
        private readonly string _logFolder;
        private readonly string _logFilePath;
        private readonly StreamWriter _writer;
        private bool _disposed;
        
        /// <summary>
        /// Event raised when a new log entry is written
        /// </summary>
        public event Action<string, LogLevel> OnLogEntry;
        
        /// <summary>
        /// Gets the current session's log file path
        /// </summary>
        public string CurrentLogFilePath => _logFilePath;
        
        /// <summary>
        /// Gets the singleton logger instance
        /// </summary>
        public static Logger Instance
        {
            get
            {
                if (_instance == null)
                {
                    lock (_lock)
                    {
                        if (_instance == null)
                        {
                            _instance = new Logger();
                        }
                    }
                }
                return _instance;
            }
        }
        
        private Logger()
        {
            // Try lowercase first (existing folder), then uppercase
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string logsLower = Path.Combine(baseDir, "logs");
            string logsUpper = Path.Combine(baseDir, "Logs");
            
            if (Directory.Exists(logsLower))
            {
                _logFolder = logsLower;
            }
            else
            {
                _logFolder = logsUpper;
                // Ensure log folder exists
                if (!Directory.Exists(_logFolder))
                {
                    Directory.CreateDirectory(_logFolder);
                }
            }
            
            // Create log file with timestamp
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd_HHmmss");
            _logFilePath = Path.Combine(_logFolder, $"ItemManager_{timestamp}.log");
            
            // Open file for appending
            _writer = new StreamWriter(_logFilePath, append: true, encoding: Encoding.UTF8)
            {
                AutoFlush = true
            };
            
            // Clean up old logs
            CleanOldLogs(30); // Keep logs for 30 days
            
            // Log startup
            Info("=".PadRight(60, '='));
            Info("ItemManager session started");
            Info($"Log file: {_logFilePath}");
            Info("=".PadRight(60, '='));
        }
        
        /// <summary>
        /// Log an info message
        /// </summary>
        public void Info(string message)
        {
            Log(LogLevel.Info, message);
        }
        
        /// <summary>
        /// Log a warning message
        /// </summary>
        public void Warn(string message)
        {
            Log(LogLevel.Warning, message);
        }
        
        /// <summary>
        /// Log an error message
        /// </summary>
        public void Error(string message)
        {
            Log(LogLevel.Error, message);
        }
        
        /// <summary>
        /// Log an exception
        /// </summary>
        public void Error(string message, Exception ex)
        {
            var sb = new StringBuilder();
            sb.AppendLine(message);
            sb.AppendLine($"  Exception: {ex.GetType().Name}");
            sb.AppendLine($"  Message: {ex.Message}");
            if (ex.InnerException != null)
            {
                sb.AppendLine($"  Inner: {ex.InnerException.Message}");
            }
            sb.AppendLine($"  Stack: {ex.StackTrace}");
            
            Log(LogLevel.Error, sb.ToString());
        }
        
        /// <summary>
        /// Write a log entry
        /// </summary>
        private void Log(LogLevel level, string message)
        {
            if (_disposed) return;
            
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            string levelStr = level switch
            {
                LogLevel.Info => "INFO",
                LogLevel.Warning => "WARN",
                LogLevel.Error => "ERROR",
                _ => "INFO"
            };
            
            string entry = $"[{timestamp}] [{levelStr}] {message}";
            
            lock (_lock)
            {
                _writer?.WriteLine(entry);
            }
            
            // Raise event for UI updates
            OnLogEntry?.Invoke(entry, level);
        }
        
        /// <summary>
        /// Delete log files older than specified days
        /// </summary>
        private void CleanOldLogs(int daysToKeep)
        {
            try
            {
                var cutoff = DateTime.Now.AddDays(-daysToKeep);
                var logFiles = Directory.GetFiles(_logFolder, "ItemManager_*.log");
                
                int deleted = 0;
                foreach (var file in logFiles)
                {
                    var fileInfo = new FileInfo(file);
                    if (fileInfo.LastWriteTime < cutoff)
                    {
                        try
                        {
                            File.Delete(file);
                            deleted++;
                        }
                        catch
                        {
                            // Ignore errors deleting old logs
                        }
                    }
                }
                
                if (deleted > 0)
                {
                    Info($"Cleaned up {deleted} old log file(s)");
                }
            }
            catch
            {
                // Ignore cleanup errors
            }
        }
        
        /// <summary>
        /// Get the current log file path
        /// </summary>
        public string LogFilePath => _logFilePath;
        
        /// <summary>
        /// Get log folder path
        /// </summary>
        public string LogFolder => _logFolder;
        
        /// <summary>
        /// Read all entries from current log file
        /// </summary>
        public string ReadCurrentLog()
        {
            try
            {
                // Flush writer first
                lock (_lock)
                {
                    _writer?.Flush();
                }
                
                // Read with shared access
                using (var reader = new StreamReader(
                    new FileStream(_logFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)))
                {
                    return reader.ReadToEnd();
                }
            }
            catch (Exception ex)
            {
                return $"Error reading log: {ex.Message}";
            }
        }
        
        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            
            Info("ItemManager session ended");
            
            lock (_lock)
            {
                _writer?.Dispose();
            }
        }
    }
}
