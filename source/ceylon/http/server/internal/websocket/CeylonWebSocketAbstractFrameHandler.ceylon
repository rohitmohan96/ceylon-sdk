import ceylon.http.server.websocket {
    WebSocketChannel,
    CloseReason,
    NoReason,
    WebSocketBaseEndpoint
}
import io.undertow.websockets.core {
    AbstractReceiveListener,
    UtWebSocketChannel=WebSocketChannel,
    BufferedBinaryMessage,
    CloseMessage,
    WebSockets
}
import java.nio {
    JByteBuffer=ByteBuffer
}
import org.xnio {
    IoUtils {
        safeClose
    },
    Pooled
}
import java.lang {
    ObjectArray
}

by("Matej Lazar")
class CeylonWebSocketAbstractFrameHandler(
    WebSocketBaseEndpoint webSocketEndpoint, 
    WebSocketChannel webSocketChannel)
        extends AbstractReceiveListener() {

    "Called from once full message is read"
    shared actual void onFullCloseMessage(UtWebSocketChannel channel, BufferedBinaryMessage message) {
        Pooled<ObjectArray<JByteBuffer>> data = message.data;
        try {
            CloseMessage cm = CloseMessage(data.resource);
            onCloseMessage(cm, channel);
            if (!channel.closeFrameSent) {
                WebSockets.sendClose(cm.toByteBuffer(), channel, null);
            }
        } finally {
            data.free();
        }
    }
    
    void onCloseMessage(CloseMessage cm, UtWebSocketChannel channel) {
        if (cm.isValid(cm.code)) {
            webSocketEndpoint.onClose(webSocketChannel, CloseReason(cm.code, cm.reason));
        } else {
            webSocketEndpoint.onClose(webSocketChannel, NoReason());
        }
    }


    shared actual void onError(UtWebSocketChannel channel, Throwable? error) {
        webSocketEndpoint.onError(webSocketChannel, error);
        safeClose(channel);
    }
}
