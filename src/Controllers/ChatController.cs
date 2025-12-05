using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(ChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        _logger.LogInformation("Chat page accessed");
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Message))
        {
            return Json(new ChatResponse 
            { 
                Success = false, 
                Error = "Message cannot be empty" 
            });
        }

        try
        {
            _logger.LogInformation("Processing chat message: {MessagePreview}", 
                request.Message.Length > 50 ? request.Message[..50] + "..." : request.Message);

            var response = await _chatService.GetChatResponseAsync(request.Message);
            
            return Json(new ChatResponse 
            { 
                Success = true, 
                Response = response 
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing chat message");
            return Json(new ChatResponse 
            { 
                Success = false, 
                Error = "An error occurred while processing your request. Please try again." 
            });
        }
    }
}
