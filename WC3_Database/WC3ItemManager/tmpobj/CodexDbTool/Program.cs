using Npgsql;

if (args.Length == 0)
{
    Console.Error.WriteLine("Usage: CodexDbTool <sql-file>");
    Environment.ExitCode = 2;
    return;
}

var sqlPath = args[0];
var sql = await File.ReadAllTextAsync(sqlPath);
var connectionString = "Host=127.0.0.1;Port=5432;Database=wc3_pots;Username=postgres;Password=009900";

await using var connection = new NpgsqlConnection(connectionString);
connection.Notice += (_, e) => Console.WriteLine($"NOTICE: {e.Notice.MessageText}");
await connection.OpenAsync();

await using var transaction = await connection.BeginTransactionAsync();
try
{
    await using var command = new NpgsqlCommand(sql, connection, transaction)
    {
        CommandTimeout = 300
    };

    var reader = await command.ExecuteReaderAsync();
    var resultSet = 0;
    do
    {
        resultSet++;
        if (reader.FieldCount == 0)
        {
            continue;
        }

        Console.WriteLine($"-- result set {resultSet} --");
        for (var i = 0; i < reader.FieldCount; i++)
        {
            if (i > 0)
            {
                Console.Write('\t');
            }
            Console.Write(reader.GetName(i));
        }
        Console.WriteLine();

        var rowCount = 0;
        while (await reader.ReadAsync())
        {
            rowCount++;
            for (var i = 0; i < reader.FieldCount; i++)
            {
                if (i > 0)
                {
                    Console.Write('\t');
                }
                Console.Write(reader.IsDBNull(i) ? "\\N" : reader.GetValue(i));
            }
            Console.WriteLine();
        }
        Console.WriteLine($"-- rows: {rowCount} --");
    } while (await reader.NextResultAsync());

    await reader.DisposeAsync();
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
