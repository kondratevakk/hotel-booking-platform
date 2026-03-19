CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    hotel_id INT REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    room_type_id INT REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    price_per_night DECIMAL CHECK (price_per_night >= 0),
    description TEXT,
    status VARCHAR(50) DEFAULT 'available'
);

CREATE TABLE hotel_amenities (
    hotel_id INT REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    amenity_id INT REFERENCES amenities(amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (hotel_id, amenity_id)
);

CREATE TABLE room_amenities (
    room_id INT REFERENCES rooms(room_id) ON DELETE CASCADE,
    amenity_id INT REFERENCES amenities(amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (room_id, amenity_id)
);

CREATE TABLE room_price_history (
    price_history_id SERIAL PRIMARY KEY,
    room_id INT REFERENCES rooms(room_id) ON DELETE CASCADE,
    price DECIMAL,
    date DATE
);
