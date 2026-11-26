package edu.course.cinema.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public record Movie(long id, String title, String director, String actors, String genre,
                    int durationMinutes, LocalDate releaseDate, BigDecimal basePrice,
                    String synopsis, String posterUrl, MovieStatus showingStatus) { }
