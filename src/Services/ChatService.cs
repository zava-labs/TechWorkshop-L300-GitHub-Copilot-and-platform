using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services;

public class ChatService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ChatService> _logger;
    private readonly HttpClient _httpClient;
    private readonly DefaultAzureCredential _credential;

    public ChatService(IConfiguration configuration, ILogger<ChatService> logger, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient("AzureAI");
        _credential = new DefaultAzureCredential();
    }

    public async Task<string> GetChatResponseAsync(string userMessage)
    {
        try
        {
            var endpoint = _configuration["AzureAI:Endpoint"] 
                ?? throw new InvalidOperationException("AzureAI:Endpoint is not configured");
            var deploymentName = _configuration["AzureAI:DeploymentName"] ?? "gpt-4o-mini";
            var apiKey = _configuration["AzureAI:ApiKey"];

            var requestUrl = $"{endpoint.TrimEnd('/')}/openai/deployments/{deploymentName}/chat/completions?api-version=2024-02-15-preview";

            var requestBody = new
            {
                messages = new[]
                {
                    new { role = "system", content = "You are a helpful shopping assistant for Zava Storefront. Help customers with product questions, recommendations, and general inquiries about our store. Be friendly and concise." },
                    new { role = "user", content = userMessage }
                },
                max_tokens = 800,
                temperature = 0.7
            };

            var request = new HttpRequestMessage(HttpMethod.Post, requestUrl)
            {
                Content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json")
            };

            // Use API key if configured, otherwise use managed identity
            if (!string.IsNullOrEmpty(apiKey))
            {
                request.Headers.Add("api-key", apiKey);
            }
            else
            {
                // Get access token using DefaultAzureCredential (managed identity in Azure, local dev creds locally)
                var tokenRequestContext = new TokenRequestContext(["https://cognitiveservices.azure.com/.default"]);
                var accessToken = await _credential.GetTokenAsync(tokenRequestContext);
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken.Token);
            }

            _logger.LogInformation("Sending chat request to Azure AI endpoint");

            var response = await _httpClient.SendAsync(request);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Azure AI API error: {StatusCode} - {Content}", response.StatusCode, responseContent);
                throw new HttpRequestException($"API request failed with status {response.StatusCode}");
            }

            var jsonResponse = JsonDocument.Parse(responseContent);
            var assistantMessage = jsonResponse.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            _logger.LogInformation("Chat response received successfully");
            return assistantMessage ?? "I apologize, but I couldn't generate a response. Please try again.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting chat response from Azure AI");
            throw;
        }
    }
}
