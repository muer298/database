package edu.course.cinema.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record Screening(long id, long movieId, long hallId,
                        LocalDateTime startTime, LocalDateTime endTime,
                        String languageVersion, String subtitle,
                        BigDecimal ticketPrice, ScreeningStatus status) { }
