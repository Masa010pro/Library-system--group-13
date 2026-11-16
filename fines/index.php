<?php
require_once '../includes/auth_check.php';
require_roles(['admin', 'librarians']);
require_once '../config/database.php';
require_once '../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf_token($_POST['csrf_token'] ?? null)) {
        http_response_code(405);
        exit('Invalid fine update request.');
    }

    $fineId = filter_input(INPUT_POST, 'fine_id', FILTER_VALIDATE_INT);
    if (!$fineId || $fineId < 1) {
        set_flash('danger', 'Invalid fine.');
    } else {
        $stmt = $pdo->prepare('UPDATE fines SET paid = 1 WHERE fine_id = ? AND paid = 0');
        $stmt->execute([$fineId]);
        set_flash($stmt->rowCount() ? 'success' : 'danger', $stmt->rowCount()
            ? 'Fine marked as paid.'
            : 'Unpaid fine not found.');
    }

    header('Location: index.php');
    exit;
}

$summary = $pdo->query(
    'SELECT COALESCE(SUM(amount), 0) AS total_amount,
            COALESCE(SUM(CASE WHEN paid = 1 THEN amount ELSE 0 END), 0) AS paid_amount,
            COALESCE(SUM(CASE WHEN paid = 0 THEN amount ELSE 0 END), 0) AS unpaid_amount
     FROM fines'
)->fetch();
$fines = $pdo->query(
    'SELECT fines.fine_id, fines.amount, fines.paid, fines.created_at,
            members.full_name, books.title, loans.due_date
     FROM fines
     INNER JOIN loans ON loans.loan_id = fines.loan_id
     INNER JOIN members ON members.member_id = loans.member_id
     INNER JOIN books ON books.book_id = loans.book_id
     ORDER BY fines.paid, fines.created_at DESC'
)->fetchAll();

$pageTitle = 'Fines';
require '../includes/header.php';
require '../includes/navbar.php';
?>
<main class="container">
    <?php show_flash(); ?>
    <header class="page-heading"><h1>Fines</h1></header>
    <section class="stats-grid" aria-label="Fine totals">
        <article class="card"><h2>Total</h2><p class="stat-value"><?= e(number_format((float)$summary['total_amount'], 2)) ?></p></article>
        <article class="card"><h2>Paid</h2><p class="stat-value"><?= e(number_format((float)$summary['paid_amount'], 2)) ?></p></article>
        <article class="card"><h2>Unpaid</h2><p class="stat-value"><?= e(number_format((float)$summary['unpaid_amount'], 2)) ?></p></article>
    </section>
    <?php if (!$fines): ?>
        <p class="card empty-state" style="margin-top: 1rem">No fines have been recorded.</p>
    <?php else: ?>
        <div class="table-wrap" style="margin-top: 1rem">
            <table>
                <thead><tr><th>Member</th><th>Book</th><th>Due date</th><th>Amount</th><th>Status</th><th>Created</th><th>Action</th></tr></thead>
                <tbody>
                <?php foreach ($fines as $fine): ?>
                    <tr>
                        <td><?= e($fine['full_name']) ?></td>
                        <td><?= e($fine['title']) ?></td>
                        <td><?= e($fine['due_date']) ?></td>
                        <td><?= e(number_format((float)$fine['amount'], 2)) ?></td>
                        <td><?= $fine['paid'] ? 'Paid' : 'Unpaid' ?></td>
                        <td><?= e($fine['created_at']) ?></td>
                        <td>
                            <?php if (!$fine['paid']): ?>
                                <form class="inline-form" method="post" data-confirm="Mark this fine as paid?">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="fine_id" value="<?= e($fine['fine_id']) ?>">
                                    <button class="button" type="submit">Mark paid</button>
                                </form>
                            <?php else: ?>
                                —
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</main>
<?php require '../includes/footer.php'; ?>
