using System;
using Npgsql;

class Test {
    static void Main() {
        try {
            var connStr = "Host=127.0.0.1;Port=5432;Database=wc3_pots;Username=postgres;Password=009900;SSL Mode=Disable";
            using (var conn = new NpgsqlConnection(connStr)) {
                conn.Open();
                using (var cmd = new NpgsqlCommand("SELECT COUNT(*) FROM items", conn)) {
                    var count = cmd.ExecuteScalar();
                    Console.WriteLine("Connected! Items: " + count);
                }
            }
        } catch (Exception ex) {
            Console.WriteLine("Error: " + ex.GetType().Name + " - " + ex.Message);
            if (ex.InnerException != null) Console.WriteLine("Inner: " + ex.InnerException.Message);
        }
    }
}
