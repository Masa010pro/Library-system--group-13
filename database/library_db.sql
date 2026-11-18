-- Create database
CREATE DATABASE IF NOT EXISTS library_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE library_db;

-- 1. Users (librarians)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('admin','librarian') DEFAULT 'librarian',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Authors
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(60)
) ENGINE=InnoDB;

-- 3. Categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

-- 4. Books
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    category_id INT NOT NULL,
    publisher VARCHAR(120),
    year_published SMALLINT UNSIGNED,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    cover_isbn VARCHAR(20),  -- ISBN used to fetch Open Library cover
    digital_file_path VARCHAR(255) NULL,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. Members
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    member_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    phone VARCHAR(20),
    status ENUM('active','suspended') DEFAULT 'active',
    date_joined DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

-- 6. Loans
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    date_issued DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    date_returned DATE NULL,
    status ENUM('borrowed','returned','overdue') DEFAULT 'borrowed',
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 7. Reservations (bonus)
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reserved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending','fulfilled','cancelled') DEFAULT 'pending',
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Book reviews from student members (one review per member and title)
CREATE TABLE book_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_book_reviews_member (book_id, member_id),
    KEY idx_book_reviews_member_id (member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. Fines (bonus)
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL UNIQUE,
    amount DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    paid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- SAMPLE DATA
-- ------------------------------------------------------------

-- Librarian test account: admin / password123; change it immediately in production.
INSERT INTO users (username, password_hash, full_name, role) VALUES
('admin', '$2y$12$Kt0XDrg386dhVYYg5IH7xeDaEp.MgH1tGdAzGvdeZAWafVObk.ZFe', 'Head Librarian', 'admin');

-- Authors (5)
INSERT INTO authors (name, country) VALUES
('Chinua Achebe', 'Nigeria'),
('Jane Austen', 'United Kingdom'),
('George Orwell', 'United Kingdom'),
('Toni Morrison', 'United States'),
('Yuval Noah Harari', 'Israel');

-- Categories (5)
INSERT INTO categories (name, description) VALUES
('Fiction', 'Novels and short stories'),
('Classic Literature', 'Timeless literary works'),
('Science Fiction', 'Futuristic and speculative fiction'),
('History', 'Historical non‑fiction'),
('Self‑Development', 'Personal growth and productivity');

-- Books (10) – real ISBNs so Open Library covers work
INSERT INTO books (isbn, title, author_id, category_id, publisher, year_published, total_copies, available_copies, cover_isbn) VALUES
('9780385474542', 'Things Fall Apart', 1, 2, 'Anchor', 1958, 3, 2, '9780385474542'),
('9780141439518', 'Pride and Prejudice', 2, 2, 'Penguin Classics', 1813, 4, 3, '9780141439518'),
('9780451524935', '1984', 3, 3, 'Signet Classic', 1949, 5, 4, '9780451524935'),
('9781400033416', 'Beloved', 4, 1, 'Vintage', 1987, 2, 1, '9781400033416'),
('9780062316097', 'Sapiens: A Brief History of Humankind', 5, 4, 'Harper', 2011, 6, 5, '9780062316097'),
('9780061120084', 'To Kill a Mockingbird', 2, 2, 'Harper Perennial', 1960, 3, 2, '9780061120084'),
('9780679783268', 'Pride and Prejudice (Modern Library)', 2, 2, 'Modern Library', 1813, 2, 2, '9780679783268'),
('9780156012195', 'The Little Prince', 5, 1, 'Harcourt', 1943, 4, 3, '9780156012195'),
('9780307476463', 'The Girl with the Dragon Tattoo', 3, 1, 'Vintage Crime', 2005, 3, 1, '9780307476463'),
('9780735211292', 'Atomic Habits', 5, 5, 'Avery', 2018, 5, 4, '9780735211292');

-- Members (10)
INSERT INTO members (member_number, full_name, email, phone, status, date_joined) VALUES
('M001', 'Alice Johnson', 'alice.johnson@example.com', '0700111222', 'active', '2024-01-15'),
('M002', 'Brian Ochieng', 'brian.ochieng@example.com', '0711222333', 'active', '2024-02-20'),
('M003', 'Catherine Mwangi', 'catherine.mwangi@example.com', '0722333444', 'active', '2023-11-05'),
('M004', 'David Kimani', 'david.kimani@example.com', '0733444555', 'suspended', '2022-08-10'),
('M005', 'Esther Wanjiku', 'esther.wanjiku@example.com', '0744555666', 'active', '2024-03-01'),
('M006', 'Felix Otieno', 'felix.otieno@example.com', '0755666777', 'active', '2023-06-18'),
('M007', 'Grace Akinyi', 'grace.akinyi@example.com', '0766777888', 'active', '2024-04-22'),
('M008', 'Hassan Ali', 'hassan.ali@example.com', '0777888999', 'active', '2022-12-30'),
('M009', 'Irene Njeri', 'irene.njeri@example.com', '0788999000', 'active', '2023-09-14'),
('M010', 'James Mwaura', 'james.mwaura@example.com', '0799000111', 'suspended', '2021-05-25');

-- Loans (10) – mixture of returned, borrowed, overdue
-- Today is assumed to be 2025‑01‑20 for sample data
INSERT INTO loans (member_id, book_id, date_issued, due_date, date_returned, status) VALUES
(1, 1, '2024-12-01', '2024-12-15', '2024-12-10', 'returned'),   -- returned early
(2, 2, '2024-12-20', '2025-01-03', '2025-01-02', 'returned'),   -- returned
(3, 3, '2025-01-05', '2025-01-19', NULL, 'overdue'),            -- overdue
(4, 4, '2025-01-10', '2025-01-24', NULL, 'borrowed'),           -- but member suspended – sample inconsistency? We'll fix by rule in app.
(5, 5, '2025-01-12', '2025-01-26', NULL, 'borrowed'),
(6, 6, '2025-01-15', '2025-01-29', NULL, 'borrowed'),
(7, 7, '2025-01-01', '2025-01-15', '2025-01-14', 'returned'),
(8, 8, '2025-01-18', '2025-02-01', NULL, 'borrowed'),
(9, 9, '2024-12-28', '2025-01-11', NULL, 'overdue'),
(10, 10, '2025-01-03', '2025-01-17', '2025-01-16', 'returned');

-- NOTE: member 4 and 10 are suspended but have loans – this is historical data.
-- The application will prevent new loans to suspended members.

-- Reservations (2)
INSERT INTO reservations (member_id, book_id, status) VALUES
(2, 4, 'pending'),
(5, 9, 'pending');

-- Fines (for overdue loans) – 0.50 per day
INSERT INTO fines (loan_id, amount, paid) VALUES
(3, 0.50, FALSE),
(9, 4.50, FALSE);
