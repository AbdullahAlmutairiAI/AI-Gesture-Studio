$port = PORT_HERE
$root = $PSScriptRoot
$url = "PASTE_LOCAL_IP_HERE:$port/index.html"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".wasm" = "application/wasm"
    ".mp4"  = "video/mp4"
    ".webm" = "video/webm"
    ".task" = "application/octet-stream"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()

Write-Host ""
Write-Host "  AI Gesture Studio is running!" -ForegroundColor Green
Write-Host "  Open: $url" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop the server." -ForegroundColor DarkGray
Write-Host ""

Start-Process $url

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $relativePath = [System.Uri]::UnescapeDataString($request.Url.LocalPath.TrimStart("/"))
            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                $relativePath = "index.html"
            }

            if ($relativePath -eq "favicon.ico") {
                $response.StatusCode = 204
                $response.Close()
                continue
            }

            $filePath = Join-Path $root ($relativePath -replace "/", [IO.Path]::DirectorySeparatorChar)

            if (Test-Path $filePath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
                $contentType = $mimeTypes[$ext]
                if (-not $contentType) { $contentType = "application/octet-stream" }

                $response.StatusCode = 200
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $message = "404 Not Found: $relativePath"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
                $response.StatusCode = 404
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } catch {
            Write-Host "Request error: $_" -ForegroundColor Yellow
            $response.StatusCode = 500
        } finally {
            $response.Close()
        }
    }
} finally {
    $listener.Stop()
}
