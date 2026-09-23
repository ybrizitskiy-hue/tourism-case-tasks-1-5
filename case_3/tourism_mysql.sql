-- Кейс-задача № 3
-- База данных «Туризм» для MySQL 8.0.16 или новее
-- ВНИМАНИЕ: при запуске существующая база tourism удаляется вместе со всеми данными.

DROP DATABASE IF EXISTS tourism;
CREATE DATABASE tourism
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE tourism;

-- 1. Справочник стран
CREATE TABLE countries (
    country_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE = InnoDB;

-- 2. Справочник отелей
CREATE TABLE hotels (
    hotel_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country_id INT UNSIGNED NOT NULL,
    hotel_name VARCHAR(150) NOT NULL,
    stars TINYINT UNSIGNED NOT NULL,
    city VARCHAR(100) NOT NULL,
    CONSTRAINT chk_hotels_stars CHECK (stars BETWEEN 1 AND 5),
    CONSTRAINT fk_hotels_country
        FOREIGN KEY (country_id)
        REFERENCES countries(country_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- 3. Справочник типов туров
CREATE TABLE tour_types (
    tour_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL
) ENGINE = InnoDB;

-- 4. Справочник клиентов
CREATE TABLE clients (
    client_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(150) NULL UNIQUE
) ENGINE = InnoDB;

-- 5. Таблица переменной информации: заказы туров
CREATE TABLE tour_orders (
    order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id INT UNSIGNED NOT NULL,
    hotel_id INT UNSIGNED NOT NULL,
    tour_type_id INT UNSIGNED NOT NULL,
    order_date DATE NOT NULL,
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    persons_count TINYINT UNSIGNED NOT NULL DEFAULT 1,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Новый',

    CONSTRAINT chk_orders_dates CHECK (date_to >= date_from),
    CONSTRAINT chk_orders_persons CHECK (persons_count > 0),
    CONSTRAINT chk_orders_price CHECK (total_price >= 0),

    CONSTRAINT fk_orders_client
        FOREIGN KEY (client_id)
        REFERENCES clients(client_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_orders_hotel
        FOREIGN KEY (hotel_id)
        REFERENCES hotels(hotel_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_orders_tour_type
        FOREIGN KEY (tour_type_id)
        REFERENCES tour_types(tour_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE = InnoDB;

-- InnoDB автоматически создает индексы для внешних ключей.
CREATE INDEX idx_orders_date ON tour_orders(order_date);

-- Тестовые данные
INSERT INTO countries (country_name) VALUES
('Болгария'),
('Италия'),
('Греция'),
('Испания');

INSERT INTO hotels (country_id, hotel_name, stars, city) VALUES
(1, 'Sea Resort', 4, 'Солнечный Берег'),
(1, 'Marina Palace', 5, 'Несебр'),
(2, 'Roma Centro Hotel', 4, 'Рим'),
(3, 'Aegean Blue', 4, 'Салоники'),
(4, 'Costa Hotel', 4, 'Барселона');

INSERT INTO tour_types (type_name, description) VALUES
('Пляжный', 'Отдых у моря'),
('Экскурсионный', 'Тур с экскурсионной программой'),
('Семейный', 'Тур для семейного отдыха'),
('Городской', 'Короткая поездка в крупный город');

INSERT INTO clients (full_name, phone, email) VALUES
('Иван Иванов', '+359888111222', 'ivan@example.com'),
('Мария Петрова', '+359888222333', 'maria@example.com'),
('Алексей Смирнов', '+359888333444', 'alex@example.com');

INSERT INTO tour_orders (
    client_id,
    hotel_id,
    tour_type_id,
    order_date,
    date_from,
    date_to,
    persons_count,
    total_price,
    status
) VALUES
(1, 1, 1, '2026-09-20', '2026-10-10', '2026-10-17', 2, 1300.00, 'Подтвержден'),
(2, 3, 4, '2026-09-21', '2026-11-06', '2026-11-09', 1, 420.00, 'Новый'),
(3, 4, 3, '2026-09-22', '2026-10-20', '2026-10-27', 3, 1950.00, 'Оплачен');

-- Пример запроса для просмотра заказов
SELECT
    o.order_id,
    c.full_name AS client,
    co.country_name AS country,
    h.city,
    h.hotel_name AS hotel,
    tt.type_name AS tour_type,
    o.date_from,
    o.date_to,
    o.persons_count,
    o.total_price,
    o.status
FROM tour_orders AS o
JOIN clients AS c ON c.client_id = o.client_id
JOIN hotels AS h ON h.hotel_id = o.hotel_id
JOIN countries AS co ON co.country_id = h.country_id
JOIN tour_types AS tt ON tt.tour_type_id = o.tour_type_id
ORDER BY o.order_id;
