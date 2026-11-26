package edu.course.cinema.dao;

import edu.course.cinema.model.Movie;
import edu.course.cinema.model.MovieStatus;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class MovieDAO {
    public int countMovies(Connection connection) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*) FROM movies");
             ResultSet result = statement.executeQuery()) {
            result.next();
            return result.getInt(1);
        }
    }

    public long create(Connection connection, Movie movie) throws SQLException {
        String sql = """
                INSERT INTO movies
                  (title,director,actors,genre,duration_minutes,release_date,base_price,
                   synopsis,poster_url,showing_status)
                VALUES (?,?,?,?,?,?,?,?,?,?)
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bind(statement, movie);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
        }
        throw new SQLException("插入电影成功，但未返回主键");
    }

    public Optional<Movie> findById(Connection connection, long id) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM movies WHERE movie_id=?")) {
            statement.setLong(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? Optional.of(map(result)) : Optional.empty();
            }
        }
    }

    public List<Movie> list(Connection connection) throws SQLException {
        List<Movie> movies = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT * FROM movies ORDER BY release_date DESC, movie_id");
             ResultSet result = statement.executeQuery()) {
            while (result.next()) movies.add(map(result));
        }
        return movies;
    }

    public boolean update(Connection connection, Movie movie) throws SQLException {
        String sql = """
                UPDATE movies SET title=?,director=?,actors=?,genre=?,duration_minutes=?,
                  release_date=?,base_price=?,synopsis=?,poster_url=?,showing_status=?
                WHERE movie_id=?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, movie);
            statement.setLong(11, movie.id());
            return statement.executeUpdate() == 1;
        }
    }

    public boolean updateStatus(Connection connection, long id, MovieStatus status) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE movies SET showing_status=? WHERE movie_id=?")) {
            statement.setString(1, status.name());
            statement.setLong(2, id);
            return statement.executeUpdate() == 1;
        }
    }

    private void bind(PreparedStatement statement, Movie movie) throws SQLException {
        statement.setString(1, movie.title());
        statement.setString(2, movie.director());
        statement.setString(3, movie.actors());
        statement.setString(4, movie.genre());
        statement.setInt(5, movie.durationMinutes());
        statement.setDate(6, Date.valueOf(movie.releaseDate()));
        statement.setBigDecimal(7, movie.basePrice());
        statement.setString(8, movie.synopsis());
        statement.setString(9, movie.posterUrl());
        statement.setString(10, movie.showingStatus().name());
    }

    private Movie map(ResultSet result) throws SQLException {
        return new Movie(result.getLong("movie_id"), result.getString("title"),
                result.getString("director"), result.getString("actors"), result.getString("genre"),
                result.getInt("duration_minutes"), result.getDate("release_date").toLocalDate(),
                result.getBigDecimal("base_price"), result.getString("synopsis"),
                result.getString("poster_url"), MovieStatus.valueOf(result.getString("showing_status")));
    }
}
