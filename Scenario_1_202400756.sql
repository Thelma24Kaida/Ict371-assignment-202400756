-- ICT371 PostgreSQL Scenario Assignment
-- Scenario 1: University Library Book Loans
-- Student Number: 202400756

-- REQUIREMENT 1: Tables and at least three books
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INTEGER NOT NULL CHECK (available_copies >= 0)
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(book_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

INSERT INTO books (title, available_copies) VALUES
('Database Systems', 5),
('Computer Networks', 3),
('Programming Fundamentals', 0);

-- REQUIREMENT 2: IF / ELSIF / ELSE
DO $$
DECLARE
    v_copies INTEGER;
BEGIN
    SELECT available_copies INTO v_copies
    FROM books WHERE book_id = 1;

    IF v_copies = 0 THEN
        RAISE NOTICE 'Book is unavailable';
    ELSIF v_copies <= 2 THEN
        RAISE NOTICE 'Book is low on copies';
    ELSE
        RAISE NOTICE 'Book is sufficiently stocked';
    END IF;
END $$;

-- REQUIREMENT 3: WHILE and numeric FOR
DO $$
DECLARE
    i INTEGER := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Overdue reminder number %', i;
        i := i + 1;
    END LOOP;
END $$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Library shelf number %', i;
    END LOOP;
END $$;

-- REQUIREMENT 4: borrow_book procedure
CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Borrow quantity must be greater than zero';
    END IF;

    SELECT available_copies INTO v_available
    FROM books
    WHERE book_id = p_book_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Book does not exist';
    ELSIF p_quantity > v_available THEN
        RAISE NOTICE 'Not enough copies available';
    ELSE
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans(book_id, student_number, quantity, loan_status)
        VALUES(p_book_id, p_student_number, p_quantity, 'BORROWED');

        RAISE NOTICE 'Book borrowed successfully';
    END IF;
END;
$$;

-- REQUIREMENT 5: Two valid loans and one request exceeding availability
CALL borrow_book(1, '20260001', 2);
CALL borrow_book(2, '20260002', 1);
CALL borrow_book(3, '20260003', 1);

SELECT * FROM books;
SELECT * FROM book_loans;

-- REQUIREMENT 6: return_book; second call must not restore again
CREATE OR REPLACE PROCEDURE return_book(p_loan_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_book_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Loan does not exist';
    ELSIF v_status = 'RETURNED' THEN
        RAISE NOTICE 'Loan has already been returned; stock not restored again';
    ELSE
        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully';
    END IF;
END;
$$;

CALL return_book(1);
CALL return_book(1);

-- REQUIREMENT 7: Explicit cursor for books with few copies
DO $$
DECLARE
    book_cursor CURSOR FOR
        SELECT title, available_copies
        FROM books
        WHERE available_copies <= 2;
    r RECORD;
BEGIN
    OPEN book_cursor;
    LOOP
        FETCH book_cursor INTO r;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Few copies: % - % copies', r.title, r.available_copies;
    END LOOP;
    CLOSE book_cursor;
END $$;

-- REQUIREMENT 8: Invalid zero quantity + EXCEPTION block
DO $$
BEGIN
    CALL borrow_book(1, '20260004', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid quantity handled: %', SQLERRM;
END $$;

-- REQUIREMENT 9: Final queries
SELECT * FROM books ORDER BY book_id;
SELECT * FROM book_loans ORDER BY loan_id;
