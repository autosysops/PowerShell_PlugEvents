if (-not ("MockPlugWebSocket" -as [Type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public class MockPlugWebSocketOptions {
    public List<string> SubProtocols = new List<string>();
    public void AddSubProtocol(string value) { SubProtocols.Add(value); }
}

public class MockPlugWebSocket : IDisposable {
    public WebSocketState State { get; set; } = WebSocketState.Open;
    public MockPlugWebSocketOptions Options { get; } = new MockPlugWebSocketOptions();
    public List<string> SentMessages { get; } = new List<string>();
    public Queue<string> ReceiveMessages { get; } = new Queue<string>();
    public Uri LastConnectUri { get; private set; }
    public bool NextReceiveIsClose { get; set; } = false;

    public Task ConnectAsync(Uri uri, CancellationToken cancellationToken) {
        LastConnectUri = uri;
        return Task.CompletedTask;
    }

    public Task SendAsync(ArraySegment<byte> buffer, WebSocketMessageType messageType, bool endOfMessage, CancellationToken cancellationToken) {
        string text = Encoding.UTF8.GetString(buffer.Array, buffer.Offset, buffer.Count);
        SentMessages.Add(text);
        return Task.CompletedTask;
    }

    public Task<WebSocketReceiveResult> ReceiveAsync(ArraySegment<byte> buffer, CancellationToken cancellationToken) {
        if (NextReceiveIsClose) {
            NextReceiveIsClose = false;
            return Task.FromResult(new WebSocketReceiveResult(0, WebSocketMessageType.Close, true));
        }

        if (ReceiveMessages.Count == 0) {
            return Task.FromResult(new WebSocketReceiveResult(0, WebSocketMessageType.Text, true));
        }

        string message = ReceiveMessages.Dequeue();
        byte[] bytes = Encoding.UTF8.GetBytes(message);
        Array.Copy(bytes, 0, buffer.Array, 0, bytes.Length);
        return Task.FromResult(new WebSocketReceiveResult(bytes.Length, WebSocketMessageType.Text, true));
    }

    public Task CloseAsync(WebSocketCloseStatus closeStatus, string statusDescription, CancellationToken cancellationToken) {
        State = WebSocketState.Closed;
        return Task.CompletedTask;
    }

    public void Dispose() {
        State = WebSocketState.Closed;
    }
}
"@
}
