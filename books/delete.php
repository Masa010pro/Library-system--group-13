<?php
require_once '../includes/auth_check.php';
require_roles(['admin', 'librarian']);
require_once '../config/database.php';
require_once '../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !verify_csrf_token($_POST['csrf_token'] ?? null)) {
    http_response_code(405);
    exit('Invalid book deletion request.');
}

$bookId = filter_input(INPUT_POST, 'book_id', FILTER_VALIDATE_INT);
if (!$bookId || $bookId < 1) {
    set_flash('danger', 'Invalid book.');
    header('Location: index.php');
    exit;
}

try {
    $stmt = $pdo->prepare('DELETE FROM books WHERE book_id = ?');
    $stmt->execute([$bookId]);
    set_flash($stmt->rowCount() ? 'success' : 'danger', $stmt->rowCount() ? 'Book deleted.' : 'Book not found.');
} catch (PDOException $exception) {
    if ($exception->getCode() === '23000') {
        set_flash('danger', 'This book has loan or reservation records and cannot be deleted.');
    } else {
        throw $exception;
    }
}

header('Location: index.php');
exit;
