package com.example.station.service;

import com.example.station.dto.SearchRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class RouteService {

    @Value("${google.api.key}")
    private String apiKey;

    private static final String ROUTES_API_URL = "https://routes.googleapis.com/directions/v2:computeRoutes";

    public String getRoutes(SearchRequest request) {
        String jsonPayload = "{"
                + "\"origin\": {\"address\": \"" + request.getDepartureStation() + "\"},"
                + "\"destination\": {\"address\": \"" + request.getArrivalStation() + "\"},"
                + "\"travelMode\": \"TRANSIT\""
                + "}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Goog-Api-Key", apiKey);
        headers.set("X-Goog-FieldMask", "routes.duration,routes.legs.steps.transitDetails");
        // フィールドマスクを設定しない
        headers.set("X-Goog-FieldMask", "*");

        HttpEntity<String> requestEntity = new HttpEntity<>(jsonPayload, headers);
        RestTemplate restTemplate = new RestTemplate();
        ResponseEntity<String> response = restTemplate.exchange(ROUTES_API_URL, HttpMethod.POST, requestEntity, String.class);

        return response.getBody();
    }
}
