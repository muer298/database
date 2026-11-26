CREATE DATABASE IF NOT EXISTS cinema_ticket
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cinema_ticket;

CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  real_name VARCHAR(50) NULL,
  phone VARCHAR(20) NULL,
  email VARCHAR(100) NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
  registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  account_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_users_username (username),
  UNIQUE KEY uk_users_phone (phone),
  UNIQUE KEY uk_users_email (email),
  CONSTRAINT ck_users_role CHECK (role IN ('CUSTOMER', 'ADMIN')),
  CONSTRAINT ck_users_account_status CHECK (account_status IN ('NORMAL', 'FROZEN'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS movies (
  movie_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(100) NOT NULL,
  director VARCHAR(100) NULL,
  actors VARCHAR(500) NULL,
  genre VARCHAR(50) NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL,
  release_date DATE NOT NULL,
  base_price DECIMAL(10,2) NOT NULL,
  synopsis TEXT NULL,
  poster_url VARCHAR(500) NULL,
  showing_status VARCHAR(20) NOT NULL DEFAULT 'UPCOMING',
  PRIMARY KEY (movie_id),
  UNIQUE KEY uk_movies_title_release_date (title, release_date),
  CONSTRAINT ck_movies_duration CHECK (duration_minutes > 0),
  CONSTRAINT ck_movies_base_price CHECK (base_price >= 0),
  CONSTRAINT ck_movies_showing_status CHECK (showing_status IN ('UPCOMING', 'SHOWING', 'OFFLINE'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS halls (
  hall_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  hall_name VARCHAR(50) NOT NULL,
  hall_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
  row_count SMALLINT UNSIGNED NOT NULL,
  column_count SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (hall_id),
  UNIQUE KEY uk_halls_name (hall_name),
  CONSTRAINT ck_halls_type CHECK (hall_type IN ('STANDARD', 'IMAX', 'VIP')),
  CONSTRAINT ck_halls_row_count CHECK (row_count > 0),
  CONSTRAINT ck_halls_column_count CHECK (column_count > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS seats (
  seat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  hall_id BIGINT UNSIGNED NOT NULL,
  seat_row SMALLINT UNSIGNED NOT NULL,
  seat_column SMALLINT UNSIGNED NOT NULL,
  seat_type VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
  use_status VARCHAR(20) NOT NULL DEFAULT 'ENABLED',
  PRIMARY KEY (seat_id),
  UNIQUE KEY uk_seats_hall_position (hall_id, seat_row, seat_column),
  KEY idx_seats_hall_status (hall_id, use_status),
  CONSTRAINT fk_seats_hall FOREIGN KEY (hall_id) REFERENCES halls (hall_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_seats_row CHECK (seat_row > 0),
  CONSTRAINT ck_seats_column CHECK (seat_column > 0),
  CONSTRAINT ck_seats_type CHECK (seat_type IN ('NORMAL', 'VIP')),
  CONSTRAINT ck_seats_use_status CHECK (use_status IN ('ENABLED', 'DISABLED'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS screenings (
  screening_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  movie_id BIGINT UNSIGNED NOT NULL,
  hall_id BIGINT UNSIGNED NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  language_version VARCHAR(20) NOT NULL DEFAULT 'ORIGINAL',
  subtitle VARCHAR(20) NOT NULL DEFAULT 'CHINESE',
  ticket_price DECIMAL(10,2) NOT NULL,
  screening_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
  PRIMARY KEY (screening_id),
  UNIQUE KEY uk_screenings_hall_start (hall_id, start_time),
  KEY idx_screenings_movie_start (movie_id, start_time),
  KEY idx_screenings_hall_period (hall_id, start_time, end_time),
  CONSTRAINT fk_screenings_movie FOREIGN KEY (movie_id) REFERENCES movies (movie_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_screenings_hall FOREIGN KEY (hall_id) REFERENCES halls (hall_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_screenings_period CHECK (end_time > start_time),
  CONSTRAINT ck_screenings_price CHECK (ticket_price >= 0),
  CONSTRAINT ck_screenings_status CHECK (screening_status IN ('SCHEDULED', 'SELLING', 'ENDED', 'CANCELLED'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_number VARCHAR(32) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  screening_id BIGINT UNSIGNED NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid_at DATETIME NULL,
  order_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (order_id),
  UNIQUE KEY uk_orders_number (order_number),
  UNIQUE KEY uk_orders_id_screening (order_id, screening_id),
  KEY idx_orders_user_time (user_id, ordered_at),
  KEY idx_orders_screening_status (screening_id, order_status),
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_orders_screening FOREIGN KEY (screening_id) REFERENCES screenings (screening_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_orders_amount CHECK (total_amount >= 0),
  CONSTRAINT ck_orders_status CHECK (order_status IN ('PENDING', 'PAID', 'CANCELLED', 'REFUNDED'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS seat_occupancies (
  screening_id BIGINT UNSIGNED NOT NULL,
  seat_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  occupancy_status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
  locked_at DATETIME NULL,
  lock_expires_at DATETIME NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (screening_id, seat_id),
  KEY idx_occupancies_order (order_id),
  KEY idx_occupancies_screening_status (screening_id, occupancy_status),
  CONSTRAINT fk_occupancies_screening FOREIGN KEY (screening_id) REFERENCES screenings (screening_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_occupancies_seat FOREIGN KEY (seat_id) REFERENCES seats (seat_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_occupancies_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_occupancies_status CHECK (occupancy_status IN ('AVAILABLE', 'LOCKED', 'SOLD')),
  CONSTRAINT ck_occupancies_owner CHECK (
    (occupancy_status = 'AVAILABLE' AND order_id IS NULL)
    OR (occupancy_status IN ('LOCKED', 'SOLD') AND order_id IS NOT NULL)
  )
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS tickets (
  ticket_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ticket_number VARCHAR(32) NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  screening_id BIGINT UNSIGNED NOT NULL,
  seat_id BIGINT UNSIGNED NOT NULL,
  row_number_snapshot SMALLINT UNSIGNED NOT NULL,
  column_number_snapshot SMALLINT UNSIGNED NOT NULL,
  ticket_price DECIMAL(10,2) NOT NULL,
  ticket_status VARCHAR(20) NOT NULL DEFAULT 'VALID',
  issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ticket_id),
  UNIQUE KEY uk_tickets_number (ticket_number),
  KEY idx_tickets_order (order_id),
  KEY idx_tickets_screening_seat (screening_id, seat_id),
  CONSTRAINT fk_tickets_order_screening FOREIGN KEY (order_id, screening_id)
    REFERENCES orders (order_id, screening_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_tickets_occupancy FOREIGN KEY (screening_id, seat_id)
    REFERENCES seat_occupancies (screening_id, seat_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_tickets_row_snapshot CHECK (row_number_snapshot > 0),
  CONSTRAINT ck_tickets_column_snapshot CHECK (column_number_snapshot > 0),
  CONSTRAINT ck_tickets_price CHECK (ticket_price >= 0),
  CONSTRAINT ck_tickets_status CHECK (ticket_status IN ('VALID', 'USED', 'REFUNDED'))
) ENGINE = InnoDB;
