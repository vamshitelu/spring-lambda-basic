package com.vsoft;


import com.amazonaws.serverless.exceptions.ContainerInitializationException;
import com.amazonaws.serverless.proxy.model.AwsProxyRequest;
import com.amazonaws.serverless.proxy.model.AwsProxyResponse;
import com.amazonaws.serverless.proxy.spring.SpringBootLambdaContainerHandler;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vsoft.util.JwtUtil;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;
import java.util.Set;


public class StreamLambdaHandler implements RequestStreamHandler {
    private static SpringBootLambdaContainerHandler<AwsProxyRequest, AwsProxyResponse> handler;
    static {
        try {
            handler = SpringBootLambdaContainerHandler.getAwsProxyHandler(Application.class);
        } catch (ContainerInitializationException e) {
            // if we fail here. We re-throw the exception to force another cold start
            e.printStackTrace();
            throw new RuntimeException("Could not initialize Spring Boot application", e);
        }
    }

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handleRequest(InputStream inputStream, OutputStream outputStream, Context context)
            throws IOException {

        AwsProxyRequest request = objectMapper.readValue(inputStream, AwsProxyRequest.class);

        try{
            Map<String, String> headers = request.getHeaders();
            String authheader = headers != null ? headers.get("Authorization") : null;

            if(authheader == null || !authheader.startsWith("Bearer ")){
                AwsProxyResponse response = new AwsProxyResponse();
                response.setStatusCode(401);
                response.setBody("Unauthorized - Missing or invalid Authorization header");
                objectMapper.writeValue(outputStream, response);
                return;
            }
            String token = authheader.substring(7);

            if(!JwtUtil.validateToken(token)){
                AwsProxyResponse response = new AwsProxyResponse();
                response.setStatusCode(401);
                response.setBody("Unauthorized - Invalid token");
                objectMapper.writeValue(outputStream, response);
                return;
            }
            handler.proxyStream(inputStream, outputStream, context);
        } catch (Exception e) {
            AwsProxyResponse response = new AwsProxyResponse();
            response.setStatusCode(500);
            response.setBody("Internal Server Error: "+e.getMessage());
            objectMapper.writeValue(outputStream, response);
        }

    }
}