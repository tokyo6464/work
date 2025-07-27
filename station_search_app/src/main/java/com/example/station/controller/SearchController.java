package com.example.station.controller;

import com.example.station.dto.SearchRequest;
import com.example.station.service.RouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/search")
public class SearchController {

    @Autowired
    private RouteService routeService; // RouteService を利用するためのDI（依存性注入）

    @PostMapping
    public String searchRoutes(@RequestBody SearchRequest request) {
        return routeService.getRoutes(request); // RouteService からルート情報を取得
    }
}
