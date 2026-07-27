<?php
require_once __DIR__ . '/config/db.php';

// Simple read, no filters, just to prove the connection + table names are right.
$stmt = $pdo->query('SELECT VIN, RegistrationNumber, Model, Manufacturer FROM vehicle LIMIT 10');
$vehicles = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>DB Connection Test</title>
</head>
<body>
    <h1>Database Connection Test</h1>

    <?php if (count($vehicles) === 0): ?>
        <p>Connected successfully, but the <code>vehicle</code> table returned 0 rows.
           Check that your seed data actually imported.</p>
    <?php else: ?>
        <p>Connected successfully. Showing first <?= count($vehicles) ?> vehicle(s):</p>
        <table border="1" cellpadding="6" cellspacing="0">
            <tr>
                <th>VIN</th>
                <th>RegistrationNumber</th>
                <th>Model</th>
                <th>Manufacturer</th>
            </tr>
            <?php foreach ($vehicles as $v): ?>
                <tr>
                    <td><?= htmlspecialchars($v['VIN']) ?></td>
                    <td><?= htmlspecialchars($v['RegistrationNumber']) ?></td>
                    <td><?= htmlspecialchars($v['Model']) ?></td>
                    <td><?= htmlspecialchars($v['Manufacturer']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>
</body>
</html>
