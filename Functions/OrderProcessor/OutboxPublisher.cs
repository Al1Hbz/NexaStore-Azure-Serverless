
using System;
using System.Collections.Generic;
using System.Data;
using System.Text.Json;
using System.Threading.Tasks;
using Azure;
using Azure.Messaging.EventGrid;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace OrderProcessor;

public class OutboxPublisher
{
    private readonly ILogger<OutboxPublisher> _logger;

    public OutboxPublisher(ILogger<OutboxPublisher> logger)
    {
        _logger = logger;
    }

    [Function(nameof(OutboxPublisher))]
    public async Task Run(
        [TimerTrigger("0 */1 * * * *")] TimerInfo timer)
    {
        _logger.LogInformation(
            "Outbox Publisher started at: {Time}",
            DateTimeOffset.UtcNow);

        var connectionString =
            Environment.GetEnvironmentVariable("SqlConnectionString");

        var topicEndpoint =
            Environment.GetEnvironmentVariable("EventGridTopicEndpoint");

        var topicKey =
            Environment.GetEnvironmentVariable("EventGridTopicKey");

        if (string.IsNullOrWhiteSpace(connectionString) ||
            string.IsNullOrWhiteSpace(topicEndpoint) ||
            string.IsNullOrWhiteSpace(topicKey))
        {
            throw new InvalidOperationException(
                "Outbox Publisher configuration is missing.");
        }

        // Controlled Failure Injection configuration.
        var failureTestEnabled = string.Equals(
            Environment.GetEnvironmentVariable("EnableFailureTest"),
            "true",
            StringComparison.OrdinalIgnoreCase);

        var failureTestEventId =
            Environment.GetEnvironmentVariable("FailureTestEventId");

        // Diagnostic log: show loaded test configuration (no secrets).
        _logger.LogInformation(
            "FAILURE TEST CONFIG: Enabled={Enabled}, TargetEventId={TargetEventId}",
            failureTestEnabled,
            failureTestEventId ?? "<null>");

        var publisherClient = new EventGridPublisherClient(
            new Uri(topicEndpoint),
            new AzureKeyCredential(topicKey));

        var pendingEvents = new List<OutboxEvent>();

        // Retrieve pending events from SQL.
        await using (var connection =
            new SqlConnection(connectionString))
        {
            await connection.OpenAsync();

            await using var command =
                new SqlCommand(
                    "dbo.usp_GetPendingOutboxEvents",
                    connection);

            command.CommandType = CommandType.StoredProcedure;
            command.CommandTimeout = 30;

            await using var reader =
                await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                pendingEvents.Add(new OutboxEvent
                {
                    EventId = reader.GetGuid(
                        reader.GetOrdinal("EventId")),

                    EventType = reader.GetString(
                        reader.GetOrdinal("EventType")),

                    Subject = reader.GetString(
                        reader.GetOrdinal("Subject")),

                    DataVersion = reader.GetString(
                        reader.GetOrdinal("DataVersion")),

                    EventData = reader.GetString(
                        reader.GetOrdinal("EventData")),

                    Attempts = reader.GetInt32(
                        reader.GetOrdinal("Attempts"))
                });
            }
        }

        if (pendingEvents.Count == 0)
        {
            _logger.LogInformation(
                "No pending Outbox events found.");

            return;
        }

        _logger.LogInformation(
            "Found {Count} pending Outbox events.",
            pendingEvents.Count);

        foreach (var outboxEvent in pendingEvents)
        {
            // Diagnostic log: check whether this event matches the target.
            var eventIdMatches =
                Guid.TryParse(
                    failureTestEventId,
                    out var configuredEventId) &&
                outboxEvent.EventId == configuredEventId;

            _logger.LogInformation(
                "FAILURE TEST CHECK: EventId={EventId}, Attempts={Attempts}, Enabled={Enabled}, EventIdMatches={Matches}",
                outboxEvent.EventId,
                outboxEvent.Attempts,
                failureTestEnabled,
                eventIdMatches);

            try
            {
                // Simulate one controlled publishing failure.
                if (failureTestEnabled &&
                    eventIdMatches &&
                    outboxEvent.Attempts == 0)
                {
                    throw new InvalidOperationException(
                        "TEST_FAILURE: Simulated Event Grid publishing failure.");
                }

                using var document =
                    JsonDocument.Parse(outboxEvent.EventData);

                var eventGridEvent = new EventGridEvent(
                    outboxEvent.Subject,
                    outboxEvent.EventType,
                    outboxEvent.DataVersion,
                    document.RootElement.Clone());

                // Publish event to Event Grid.
                await publisherClient.SendEventAsync(eventGridEvent);

                // Mark event as published in SQL.
                await ExecuteOutboxCommand(
                    connectionString,
                    "dbo.usp_MarkOutboxEventPublished",
                    outboxEvent.EventId);

                _logger.LogInformation(
                    "Event {EventId} published successfully. Type: {EventType}",
                    outboxEvent.EventId,
                    outboxEvent.EventType);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to publish Outbox event {EventId}.",
                    outboxEvent.EventId);

                try
                {
                    await RecordFailure(
                        connectionString,
                        outboxEvent.EventId,
                        ex.Message);
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(
                        dbEx,
                        "Failed to record publishing error for event {EventId}.",
                        outboxEvent.EventId);
                }
            }
        }

        _logger.LogInformation(
            "Outbox Publisher finished.");
    }

    private static async Task ExecuteOutboxCommand(
        string connectionString,
        string procedureName,
        Guid eventId)
    {
        await using var connection =
            new SqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new SqlCommand(procedureName, connection);

        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.Add(
            "@EventId",
            SqlDbType.UniqueIdentifier).Value = eventId;

        command.CommandTimeout = 30;

        await command.ExecuteNonQueryAsync();
    }

    private static async Task RecordFailure(
        string connectionString,
        Guid eventId,
        string error)
    {
        await using var connection =
            new SqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new SqlCommand(
                "dbo.usp_RecordOutboxEventFailure",
                connection);

        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.Add(
            "@EventId",
            SqlDbType.UniqueIdentifier).Value = eventId;

        command.Parameters.Add(
            "@Error",
            SqlDbType.NVarChar,
            2000).Value = error.Length > 2000
                ? error[..2000]
                : error;

        command.CommandTimeout = 30;

        await command.ExecuteNonQueryAsync();
    }
}

public class OutboxEvent
{
    public Guid EventId { get; set; }

    public string EventType { get; set; } = string.Empty;

    public string Subject { get; set; } = string.Empty;

    public string DataVersion { get; set; } = "1.0";

    public string EventData { get; set; } = string.Empty;

    public int Attempts { get; set; }
}
