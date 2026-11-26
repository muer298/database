package edu.course.cinema.model;

public record Seat(long id, long hallId, int row, int column,
                   SeatType type, SeatStatus useStatus) { }
