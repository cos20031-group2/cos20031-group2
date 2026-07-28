<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Driver']);
require_once __DIR__ . '/../../config/db.php';
?>
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Driver Dashboard</title></head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2>Driver Dashboard</h2>
    <p>Placeholder -- real content (safety history, scores, certifications) comes later</p>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
