package com.vsoft.controller;


import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@EnableWebMvc
public class PingController {

    @RequestMapping(path = "/ping", method = RequestMethod.GET)
    public Map<String, String> ping() {
        log.info("Ping method called.");
        Map<String, String> pong = new HashMap<>();
        pong.put("pong", "Hello, World!");
        log.info("Exit from ping method");
        return pong;
    }
}
