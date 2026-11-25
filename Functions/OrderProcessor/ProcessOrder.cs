
using System;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;

namespace OrderProcessor;

public class ProcessOrder
{
    private readonly ILogger<ProcessOrder> _logger;

    public ProcessOrder(ILogger<ProcessOrder> logger)
    {
        _logger = logger;
    }

    [Function(nameof(ProcessOrder))]
    public async Task Run(
        [ServiceBusTrigger(
            "orders-queue",
            Connection = "ServiceBusConnection",
            AutoCompleteMessages = false)]
        ServiceBusReceivedMessage message,
        ServiceBusMessageActions messageActions)
    {
        _logger.LogInformation(
            "Processing order message: {MessageId}",
            message.MessageId);

        OrderMessage? order;

        try
        {
            order = JsonSerializer.Deserialize<OrderMessage>(
                message.Body.ToString(),
                new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex,
                "Invalid JSON in message {MessageId}",
                message.MessageId);

            await messageActions.DeadLetterMessageAsync(
                message,
                deadLetterReason: "InvalidJson",
                deadLetterErrorDescription: "Order message contains invalid JSON.");

            return;
        }

        if (order == null ||
            !Guid.TryParse(order.OrderId, out var orderId) ||
            string.IsNullOrWhiteSpace(order.ProductId) ||
            order.Quantity <= 0)
        {
            _logger.LogWarning(
                "Invalid order payload. MessageId: {MessageId}",
                message.MessageId);

            await messageActions.DeadLetterMessageAsync(
                message,
                deadLetterReason: "InvalidOrder",
                deadLetterErrorDescription: "Order fields are missing or invalid.");

            return;
        }

        var connectionString =
            Environment.GetEnvironmentVariable("SqlConnectionString");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "SqlConnectionString configuration is missing.");
        }

        await using var connection =
            new SqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new SqlCommand(
                "dbo.usp_ProcessInventoryOrder",
                connection);

        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.Add(
            "@OrderId",
            SqlDbType.UniqueIdentifier).Value = orderId;

        command.Parameters.Add(
            "@ProductId",
            SqlDbType.NVarChar,
            50).Value = order.ProductId;

        command.Parameters.Add(
            "@Quantity",
            SqlDbType.Int).Value = order.Quantity;

        command.Parameters.Add(
            "@CustomerId",
            SqlDbType.NVarChar,
            100).Value = order.CustomerId ?? string.Empty;

        command.CommandTimeout = 30;

        string result;
        int? remainingQuantity = null;

        await using (var reader = await command.ExecuteReaderAsync())
        {
            if (!await reader.ReadAsync())
            {
                throw new InvalidOperationException(
                    "Stored Procedure returned no result.");
            }

            result = reader.GetString(
                reader.GetOrdinal("Result"));

            int quantityOrdinal =
                reader.GetOrdinal("RemainingQuantity");

            if (!await reader.IsDBNullAsync(quantityOrdinal))
            {
                remainingQuantity =
                    reader.GetInt32(quantityOrdinal);
            }
        }

        if (result == "SUCCESS")
        {
            _logger.LogInformation(
                "Order {OrderId} processed successfully. " +
                "Product: {ProductId}, Remaining: {RemainingQuantity}. " +
                "Event saved to Outbox.",
                order.OrderId,
                order.ProductId,
                remainingQuantity);
        }
        else if (result == "ALREADY_PROCESSED")
        {
            _logger.LogWarning(
                "Duplicate order detected: {OrderId}. " +
                "Inventory was not modified again.",
                order.OrderId);
        }
        else
        {
            _logger.LogWarning(
                "Order {OrderId} rejected. Result: {Result}",
                order.OrderId,
                result);
        }

        await messageActions.CompleteMessageAsync(message);
    }
}

public class OrderMessage
{
    public string OrderId { get; set; } = string.Empty;

    public string ProductId { get; set; } = string.Empty;

    public int Quantity { get; set; }

    public string CustomerId { get; set; } = string.Empty;
}
