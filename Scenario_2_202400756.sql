-- ICT371 PostgreSQL Scenario Assignment
-- Scenario 2: Computer Laboratory Reservations
-- Student Number: 202400756

-- REQUIREMENT 1
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS lab_sessions CASCADE;

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL CHECK (available_workstations >= 0)
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES lab_sessions(session_id),
    lecturer VARCHAR(100) NOT NULL,
    workstations INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO lab_sessions(session_name, available_workstations) VALUES
('Database Practical', 10),
('Networking Practical', 5),
('Programming Practical', 0);

-- REQUIREMENT 2
DO $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_workstations INTO v_available
    FROM lab_sessions WHERE session_id = 1;

    IF v_available = 0 THEN
        RAISE NOTICE 'Session is full';
    ELSIF v_available <= 2 THEN
        RAISE NOTICE 'Session is nearly full';
    ELSE
        RAISE NOTICE 'Session has enough workstations';
    END IF;
END $$;

-- REQUIREMENT 3
DO $$
DECLARE
    i INTEGER := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder %', i;
        i := i + 1;
    END LOOP;
END $$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Workstation check %', i;
    END LOOP;
END $$;

-- REQUIREMENT 4
CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INTEGER,
    p_lecturer VARCHAR,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    IF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Number of workstations must be greater than zero';
    END IF;

    SELECT available_workstations INTO v_available
    FROM lab_sessions WHERE session_id = p_session_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Session does not exist';
    ELSIF p_workstations > v_available THEN
        RAISE NOTICE 'Not enough workstations available';
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations(session_id, lecturer, workstations, status)
        VALUES(p_session_id, p_lecturer, p_workstations, 'RESERVED');

        RAISE NOTICE 'Workstations reserved successfully';
    END IF;
END;
$$;

-- REQUIREMENT 5
CALL reserve_workstations(1, 'Dr. Banda', 3);
CALL reserve_workstations(2, 'Ms. Phiri', 2);
CALL reserve_workstations(3, 'Mr. Tembo', 1);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;

-- REQUIREMENT 6
CREATE OR REPLACE PROCEDURE cancel_reservation(p_reservation_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id INTEGER;
    v_workstations INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT session_id, workstations, status
    INTO v_session_id, v_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Reservation does not exist';
    ELSIF v_status = 'CANCELLED' THEN
        RAISE NOTICE 'Reservation already cancelled; workstations not released again';
    ELSE
        UPDATE lab_sessions
        SET available_workstations = available_workstations + v_workstations
        WHERE session_id = v_session_id;

        UPDATE reservations
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully';
    END IF;
END;
$$;

CALL cancel_reservation(1);
CALL cancel_reservation(1);

-- REQUIREMENT 7
DO $$
DECLARE
    session_cursor CURSOR FOR
        SELECT session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 2;
    r RECORD;
BEGIN
    OPEN session_cursor;
    LOOP
        FETCH session_cursor INTO r;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Few workstations: % - % remaining', r.session_name, r.available_workstations;
    END LOOP;
    CLOSE session_cursor;
END $$;

-- REQUIREMENT 8
DO $$
BEGIN
    CALL reserve_workstations(1, 'Invalid Lecturer', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid workstation quantity handled: %', SQLERRM;
END $$;

-- REQUIREMENT 9
SELECT * FROM lab_sessions ORDER BY session_id;
SELECT * FROM reservations ORDER BY reservation_id;
