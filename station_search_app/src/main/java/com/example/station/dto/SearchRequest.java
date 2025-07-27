package com.example.station.dto;

import lombok.Data;

@Data
public class SearchRequest {
    private String departureStation;
    private String arrivalStation;
    private int maxTime;
    private int transferLimit;
}
