#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

cat > Function.cs <<'EOF_END'
using Google.Cloud.Functions.Framework;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace HelloHttp;

public class Function : IHttpFunction
{
  private readonly ILogger _logger;

  public Function(ILogger<Function> logger) =>
    _logger = logger;

    public async Task HandleAsync(HttpContext context)
    {
      HttpRequest request = context.Request;
      // Check URL parameters for "name" field
      // "world" is the default value
      string name = ((string) request.Query["name"]) ?? "world";

      // If there's a body, parse it as JSON and check for "name" field.
      using TextReader reader = new StreamReader(request.Body);
      string text = await reader.ReadToEndAsync();
      if (text.Length > 0)
      {
        try
        {
          JsonElement json = JsonSerializer.Deserialize<JsonElement>(text);
          if (json.TryGetProperty("name", out JsonElement nameElement) &&
            nameElement.ValueKind == JsonValueKind.String)
          {
            name = nameElement.GetString();
          }
        }
        catch (JsonException parseException)
        {
          _logger.LogError(parseException, "Error parsing JSON request");
        }
      }

      await context.Response.WriteAsync($"Hello {name}!");
    }
}
EOF_END

cat > HelloHttp.csproj <<'EOF_END'
<Project Sdk="Microsoft.NET.Sdk">
 <PropertyGroup>
   <OutputType>Exe</OutputType>
   <TargetFramework>net8.0</TargetFramework>
 </PropertyGroup>

 <ItemGroup>
   <PackageReference Include="Google.Cloud.Functions.Hosting" Version="2.0.0" />
 </ItemGroup>
</Project>
EOF_END

gcloud functions deploy cf-demo \
  --gen2 \
  --runtime dotnet8 \
  --entry-point HelloHttp.Function \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 5 \
  --quiet

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#