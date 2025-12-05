namespace ZavaStorefront.Models;

public class ChatMessage
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}

public class ChatResponse
{
    public bool Success { get; set; }
    public string Response { get; set; } = string.Empty;
    public string? Error { get; set; }
}
