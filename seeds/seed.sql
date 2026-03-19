SELECT set_config('app.seed_count', :'SEED_COUNT', false);
SELECT set_config('app.schema_version', :'SCHEMA_VERSION', false);

DO $$
DECLARE
    multiplier INT;
    schema_ver INT;
    hotel_count INT;
    user_count INT;
    room_count INT;
    booking_count INT;
BEGIN
    multiplier := coalesce(nullif(current_setting('app.seed_count', true), ''), '1')::INT;
    schema_ver := coalesce(nullif(current_setting('app.schema_version', true), ''), '999')::INT;

    IF schema_ver >= 1 THEN
        TRUNCATE TABLE users CASCADE;
        TRUNCATE TABLE room_types CASCADE;
        TRUNCATE TABLE amenities CASCADE;

        INSERT INTO room_types (type_name)
        VALUES ('Standard'), ('Deluxe'), ('Suite'), ('Economy'), ('Presidential');

        INSERT INTO amenities (amenity_name)
        VALUES ('WiFi'), ('Pool'), ('Spa'), ('Gym'), ('Parking'), ('Restaurant');

        user_count := 5 * multiplier;
        INSERT INTO users (name, email, password, phone)
        SELECT
            'User ' || i,
            'user' || i || '@example.com',
            'hashed_password_' || i,
            '+7900' || lpad(i::TEXT, 7, '0')
        FROM generate_series(1, user_count) AS i;
    END IF;

    IF schema_ver >= 2 THEN
        hotel_count := 2 * multiplier;

        INSERT INTO hotels (name, description, address, rating)
        SELECT
            'Hotel ' || i,
            'Description for hotel ' || i,
            'City ' || (i % 5 + 1) || ', Street ' || i,
            round((random() * 4 + 1)::NUMERIC, 2)
        FROM generate_series(1, hotel_count) AS i;

        INSERT INTO hotel_photos (hotel_id, photo_url, description)
        SELECT
            h.hotel_id,
            'https://example.com/photos/hotel_' || h.hotel_id || '_' || p.n || '.jpg',
            'Photo ' || p.n || ' of ' || h.name
        FROM hotels h
        CROSS JOIN generate_series(1, 3) AS p(n);

        INSERT INTO owners (user_id, hotel_id)
        SELECT
            u.user_id,
            h.hotel_id
        FROM hotels h
        JOIN users u ON u.user_id = ((h.hotel_id - 1) % user_count) + 1;
    END IF;

    IF schema_ver >= 3 THEN
        room_count := 10 * multiplier;

        INSERT INTO rooms (hotel_id, room_type_id, price_per_night, description, status)
        SELECT
            ((i - 1) % hotel_count) + 1,
            ((i - 1) % 5) + 1,
            round((random() * 400 + 50)::NUMERIC, 2),
            'Room ' || i || ' description',
            CASE WHEN random() < 0.8 THEN 'available' ELSE 'occupied' END
        FROM generate_series(1, room_count) AS i;

        INSERT INTO hotel_amenities (hotel_id, amenity_id)
        SELECT DISTINCT
            ((i - 1) % hotel_count) + 1,
            ((i - 1) % 6) + 1
        FROM generate_series(1, hotel_count * 3) AS i
        ON CONFLICT DO NOTHING;

        INSERT INTO room_amenities (room_id, amenity_id)
        SELECT DISTINCT
            ((i - 1) % room_count) + 1,
            ((i - 1) % 6) + 1
        FROM generate_series(1, room_count * 2) AS i
        ON CONFLICT DO NOTHING;

        INSERT INTO room_price_history (room_id, price, date)
        SELECT
            r.room_id,
            round((r.price_per_night * (0.8 + random() * 0.4))::NUMERIC, 2),
            CURRENT_DATE - (d.n * 30)
        FROM rooms r
        CROSS JOIN generate_series(1, 3) AS d(n);
    END IF;

    IF schema_ver >= 4 THEN
        booking_count := 20 * multiplier;

        INSERT INTO bookings (user_id, check_in_date, check_out_date, status)
        SELECT
            ((i - 1) % user_count) + 1,
            CURRENT_DATE + (i % 30),
            CURRENT_DATE + (i % 30) + ((random() * 7 + 1)::INT),
            (ARRAY['confirmed', 'pending', 'cancelled', 'completed'])[1 + (i % 4)]
        FROM generate_series(1, booking_count) AS i;

        INSERT INTO booking_rooms (booking_id, room_id)
        SELECT
            b.booking_id,
            ((b.booking_id - 1) % room_count) + 1
        FROM bookings b;

        INSERT INTO hotel_bookings (hotel_id, booking_id)
        SELECT DISTINCT
            r.hotel_id,
            br.booking_id
        FROM booking_rooms br
        JOIN rooms r ON r.room_id = br.room_id;

        INSERT INTO booking_history (booking_id, status_change_date, old_status, new_status)
        SELECT
            b.booking_id,
            CURRENT_DATE - (random() * 10)::INT,
            'pending',
            b.status
        FROM bookings b;
    END IF;

    IF schema_ver >= 5 THEN
        INSERT INTO payments (booking_id, amount, payment_date, payment_method)
        SELECT
            b.booking_id,
            round((random() * 1000 + 100)::NUMERIC, 2),
            b.check_in_date - 1,
            (ARRAY['card', 'cash', 'transfer', 'crypto'])[1 + ((b.booking_id - 1) % 4)]
        FROM bookings b
        WHERE b.status IN ('confirmed', 'completed');

        INSERT INTO payment_transactions (payment_id, transaction_date, transaction_amount)
        SELECT
            p.payment_id,
            p.payment_date,
            p.amount
        FROM payments p;

        INSERT INTO hotel_reviews (user_id, hotel_id, rating, review_text, review_date)
        SELECT
            ((i - 1) % user_count) + 1,
            ((i - 1) % hotel_count) + 1,
            (random() * 4 + 1)::INT,
            'Review text for entry ' || i,
            CURRENT_DATE - (random() * 60)::INT
        FROM generate_series(1, 5 * multiplier) AS i;

        INSERT INTO user_preferences (user_id, room_type_id, amenity_id)
        SELECT DISTINCT
            ((i - 1) % user_count) + 1,
            ((i - 1) % 5) + 1,
            ((i - 1) % 6) + 1
        FROM generate_series(1, 3 * multiplier) AS i
        ON CONFLICT DO NOTHING;
    END IF;

    RAISE NOTICE 'Seeding complete: schema_ver=%, multiplier=%', schema_ver, multiplier;
END $$;
