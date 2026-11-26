package edu.course.cinema.model;

import java.time.LocalDateTime;

public record User(long id, String username, String passwordHash, String realName,
                   String phone, String email, UserRole role,
                   LocalDateTime registeredAt, AccountStatus accountStatus) { }
