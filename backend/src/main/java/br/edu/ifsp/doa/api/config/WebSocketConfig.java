package br.edu.ifsp.doa.api.config;

import br.edu.ifsp.doa.api.ws.DoaWebSocketHandler;
import br.edu.ifsp.doa.api.ws.WebSocketAuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private final DoaWebSocketHandler handler;
    private final WebSocketAuthInterceptor interceptor;

    public WebSocketConfig(DoaWebSocketHandler handler, WebSocketAuthInterceptor interceptor) {
        this.handler = handler;
        this.interceptor = interceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws")
            .addInterceptors(interceptor)
            .setAllowedOriginPatterns("*");
    }
}
