<?php
session_start();
require_once __DIR__ . '/includes/auth_check.php';
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Welcome</title>
</head>
<body>
    <h1>Logged in successfully</h1>

    <p><strong>Username:</strong> <?= htmlspecialchars($_SESSION['username']) ?></p>
    <p><strong>Role:</strong> <?= htmlspecialchars($_SESSION['role_name']) ?></p>
    <p><strong>Linked DriverID:</strong> <?= htmlspecialchars($_SESSION['driver_id'] ?? '(none)') ?></p>
    <p><strong>Linked MechanicID:</strong> <?= htmlspecialchars($_SESSION['mechanic_id'] ?? '(none)') ?></p>
    <p><strong>Linked ReviewStaffID:</strong> <?= htmlspecialchars((string)($_SESSION['review_staff_id'] ?? '(none)')) ?></p>

    <p><a href="auth/logout.php">Log out</a></p>
</body>
</html>
