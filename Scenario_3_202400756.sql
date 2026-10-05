-- ICT371 PostgreSQL Scenario Assignment
-- Scenario 3: Student Hostel Room Allocation
-- Student Number: 202400756

-- REQUIREMENT 1
DROP TABLE IF EXISTS allocations CASCADE;
DROP TABLE IF EXISTS hostel_rooms CASCADE;

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INTEGER NOT NULL CHECK (available_bed_spaces >= 0)
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms(room_number, available_bed_spaces) VALUES
('A101', 3),
('A102', 1),
('A103', 0);

-- REQUIREMENT 2
DO $$
DECLARE
    v_spaces INTEGER;
BEGIN
    SELECT available_bed_spaces INTO v_spaces
    FROM hostel_rooms WHERE room_id = 1;

    IF v_spaces = 0 THEN
        RAISE NOTICE 'Room is full';
    ELSIF v_spaces = 1 THEN
        RAISE NOTICE 'Room has one space left';
    ELSE
        RAISE NOTICE 'Room has several spaces';
    END IF;
END $$;

-- REQUIREMENT 3
DO $$
DECLARE
    i INTEGER := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day %', i;
        i := i + 1;
    END LOOP;
END $$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Room check %', i;
    END LOOP;
END $$;

-- REQUIREMENT 4
CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_spaces INTEGER;
BEGIN
    IF TRIM(COALESCE(p_student_number, '')) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank';
    END IF;

    SELECT available_bed_spaces INTO v_spaces
    FROM hostel_rooms WHERE room_id = p_room_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Room does not exist';
    ELSIF v_spaces <= 0 THEN
        RAISE NOTICE 'Room is full; allocation not made';
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations(student_number, room_id, status)
        VALUES(p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Student allocated successfully';
    END IF;
END;
$$;

-- REQUIREMENT 5
CALL allocate_room('20260001', 1);
CALL allocate_room('20260002', 2);
CALL allocate_room('20260003', 3);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;

-- REQUIREMENT 6
CREATE OR REPLACE PROCEDURE check_out(p_allocation_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT room_id, status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Allocation does not exist';
    ELSIF v_status = 'COMPLETED' THEN
        RAISE NOTICE 'Allocation already completed; bed space not released again';
    ELSE
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET status = 'COMPLETED'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully';
    END IF;
END;
$$;

CALL check_out(1);
CALL check_out(1);

-- REQUIREMENT 7
DO $$
DECLARE
    room_cursor CURSOR FOR
        SELECT room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;
    r RECORD;
BEGIN
    OPEN room_cursor;
    LOOP
        FETCH room_cursor INTO r;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Full/nearly full room: % - % spaces remaining',
            r.room_number, r.available_bed_spaces;
    END LOOP;
    CLOSE room_cursor;
END $$;

-- REQUIREMENT 8
DO $$
BEGIN
    CALL allocate_room('', 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Blank student number handled: %', SQLERRM;
END $$;

-- REQUIREMENT 9
SELECT * FROM hostel_rooms ORDER BY room_id;
SELECT * FROM allocations ORDER BY allocation_id;
