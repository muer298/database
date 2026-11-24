package edu.course.cinema.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Week 1 contract; real CRUD belongs to Week 2 after schema confirmation. */
public class MovieDAO {
    public int countMovies(Connection connection) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*) FROM movies");
             ResultSet result = statement.executeQuery()) {
            result.next();
            return result.getInt(1);
        }
    }
}
