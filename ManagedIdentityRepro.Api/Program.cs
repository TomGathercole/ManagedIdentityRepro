using System.Diagnostics;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

const string connectionString = @"Data Source=managedidentityrepro-sql.database.windows.net;Initial Catalog=managedidentityrepro-sqldb;Connect Timeout=60;Encrypt=True;Trust Server Certificate=True;Authentication=ActiveDirectoryManagedIdentity;Application Name=EntityFramework";

var app = builder.Build();


app.MapGet("/", async (bool async = false, int threads = 512) =>
{
    try
    {
        var sw = Stopwatch.StartNew();
        await Parallel.ForAsync(0, threads, new ParallelOptions { MaxDegreeOfParallelism = threads }, async (_, c) =>
        {
            using var connection = new SqlConnection(connectionString);
            if (async)
            {
                await connection.OpenAsync();
            }
            else
            {
                connection.Open();
            }
        });

        return Results.Json(new
        {
            async,
            threads,
            sw.Elapsed.TotalMilliseconds,
        });
    }
    catch (Exception e)
    {
        return Results.Problem(title: e.GetType().Name, detail: e.Message);
    }
});

app.Run();
