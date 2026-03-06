CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    password VARCHAR(255),
    phone VARCHAR(255)
);

CREATE TABLE hotels (
    hotel_id INT PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    address VARCHAR(255),
    rating FLOAT
);

CREATE TABLE room_types (
    room_type_id INT PRIMARY KEY,
    type_name VARCHAR(255)
);

CREATE TABLE amenities (
    amenity_id INT PRIMARY KEY,
    amenity_name VARCHAR(255)
);

CREATE TABLE rooms (
    room_id INT PRIMARY KEY,
    hotel_id INT,
    room_type_id INT,
    price_per_night DECIMAL,
    description TEXT,
    status VARCHAR(255),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
);

CREATE TABLE hotel_amenities (
    hotel_id INT,
    amenity_id INT,
    PRIMARY KEY (hotel_id, amenity_id),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id),
    FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);

CREATE TABLE hotel_photos (
    photo_id INT PRIMARY KEY,
    hotel_id INT,
    photo_url VARCHAR(255),
    description TEXT,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE room_price_history (
    price_history_id INT PRIMARY KEY,
    room_id INT,
    price DECIMAL,
    date DATE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

CREATE TABLE bookings (
    booking_id INT PRIMARY KEY,
    user_id INT,
    check_in_date DATE,
    check_out_date DATE,
    status VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE booking_rooms (
    booking_id INT,
    room_id INT,
    PRIMARY KEY (booking_id, room_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    booking_id INT,
    amount DECIMAL,
    payment_date DATE,
    payment_method VARCHAR(255),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE payment_transactions (
    transaction_id INT PRIMARY KEY,
    payment_id INT,
    transaction_date DATE,
    transaction_amount DECIMAL,
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
);

CREATE TABLE hotel_reviews (
    review_id INT PRIMARY KEY,
    user_id INT,
    hotel_id INT,
    rating INT,
    review_text TEXT,
    review_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE owners (
    owner_id INT PRIMARY KEY,
    user_id INT,
    hotel_id INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE hotel_bookings (
    hotel_id INT,
    booking_id INT,
    PRIMARY KEY (hotel_id, booking_id),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE room_amenities (
    room_id INT,
    amenity_id INT,
    PRIMARY KEY (room_id, amenity_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);

CREATE TABLE booking_history (
    booking_history_id INT PRIMARY KEY,
    booking_id INT,
    status_change_date DATE,
    old_status VARCHAR(255),
    new_status VARCHAR(255),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE user_preferences (
    user_id INT,
    room_type_id INT,
    amenity_id INT,
    PRIMARY KEY (user_id, room_type_id, amenity_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id),
    FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);