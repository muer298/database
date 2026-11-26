package edu.course.cinema.model;

public record Hall(long id, String name, HallType type, int rowCount, int columnCount) { }
