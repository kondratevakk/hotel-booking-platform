CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    check_in_date DATE,
    check_out_date DATE,
    status VARCHAR(50)
);

CREATE TABLE booking_rooms (
    booking_id INT REFERENCES bookings(booking_id) ON DELETE CASCADE,
    room_id INT REFERENCES rooms(room_id) ON DELETE CASCADE,
    PRIMARY KEY (booking_id, room_id)
);

CREATE TABLE hotel_bookings (
    hotel_id INT REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    booking_id INT REFERENCES bookings(booking_id) ON DELETE CASCADE,
    PRIMARY KEY (hotel_id, booking_id)
);

CREATE TABLE booking_history (
    booking_history_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id) ON DELETE CASCADE,
    status_change_date DATE,
    old_status VARCHAR(50),
    new_status VARCHAR(50)
);
