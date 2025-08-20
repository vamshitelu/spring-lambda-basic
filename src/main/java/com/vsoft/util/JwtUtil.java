package com.vsoft.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;

import java.security.Key;
import java.util.Date;

public class JwtUtil {

    private static final String SECRET = "vsoft123abc";
    private static final Key KEY = Keys.hmacShaKeyFor(SECRET.getBytes());

    public static boolean validateToken(String token){
        try{
            Jwts.parserBuilder()
                    .setSigningKey(KEY)
                    .build()
                    .parseClaimsJws(token);
            return true;
        }catch (ExpiredJwtException e){
            throw new RuntimeException("Token expired", e);
        }catch(JwtException e){
            throw new RuntimeException("Invalid token",e);
        }
    }

    public static String generateToken(String subject){
        return Jwts.builder()
                .setSubject(subject)
                .setIssuer("my-app")
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 3600000))
                .signWith(KEY)
                .compact();
    }
}
