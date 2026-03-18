CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id) ON DELETE CASCADE,
    amount DECIMAL,
    payment_date DATE,
    payment_method VARCHAR(50)
);

CREATE TABLE payment_transactions (
    transaction_id SERIAL PRIMARY KEY,
    payment_id INT REFERENCES payments(payment_id) ON DELETE CASCADE,
    transaction_date DATE,
    transaction_amount DECIMAL
);

CREATE TABLE hotel_reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    hotel_id INT REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date DATE
);

CREATE TABLE user_preferences (
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    room_type_id INT REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    amenity_id INT REFERENCES amenities(amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, room_type_id, amenity_id)
);
