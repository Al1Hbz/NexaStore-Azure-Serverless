
using System.Text.Json;
using Azure.Messaging.ServiceBus;

var connectionString =
    Environment.GetEnvironmentVariable("SB_CONNECTION_STRING");

if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.WriteLine("Service Bus connection string is missing!");
    return;
}

var order = new
{
    OrderId = Guid.NewGuid(),
    ProductId = "MOUSE-001",
    Quantity = 1,
    CustomerId = "CUSTOMER-001"
};

await using var client = new ServiceBusClient(connectionString);

var sender = client.CreateSender("orders-queue");

var message = new ServiceBusMessage(
    JsonSerializer.Serialize(order))
{
    ContentType = "application/json",
    Subject = "NewOrder"
};

await sender.SendMessageAsync(message);

Console.WriteLine($"Order sent: {order.OrderId}");
