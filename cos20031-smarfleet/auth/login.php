<?php
session_start();
require_once __DIR__ . '/../config/db.php';

// If already logged in, don't show the form again -- just go to the landing page.
if (isset($_SESSION['user_id'])) {
    header('Location: ../welcome.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($username === '' || $password === '') {
        $error = 'Please enter both username and password.';
    } else {
        // Look up the user + their role name in one query.
        $stmt = $pdo->prepare(
            'SELECT au.UserID, au.Username, au.PasswordHash, au.RoleID,
                    au.DriverID, au.MechanicID, au.ReviewStaffID,
                    r.RoleName
             FROM appuser au
             JOIN role r ON r.RoleID = au.RoleID
             WHERE au.Username = :username'
        );
        $stmt->execute(['username' => $username]);
        $user = $stmt->fetch();

        if ($user === false) {
            $error = 'Invalid username or password.';
        } else {
            // Stored format is "sha256:<hex digest>".
            $expectedHash = 'sha256:' . hash('sha256', $password);

            if (!hash_equals($user['PasswordHash'], $expectedHash)) {
                $error = 'Invalid username or password.';
            } else {
                // Success -- store what later pages need in the session.
                $_SESSION['user_id']        = $user['UserID'];
                $_SESSION['username']       = $user['Username'];
                $_SESSION['role_name']      = $user['RoleName'];
                $_SESSION['driver_id']      = $user['DriverID'];
                $_SESSION['mechanic_id']    = $user['MechanicID'];
                $_SESSION['review_staff_id']= $user['ReviewStaffID'];

                header('Location: ../welcome.php');
                exit;
            }
        }
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Smart Fleet Login</title>
</head>
<body>
    <h1>Smart Fleet Management -- Login</h1>

    <?php if ($error !== ''): ?>
        <p style="color: red;"><?= htmlspecialchars($error) ?></p>
    <?php endif; ?>

    <form method="POST" action="login.php">
        <label>Username: <input type="text" name="username" required></label><br><br>
        <label>Password: <input type="password" name="password" required></label><br><br>
        <button type="submit">Log In</button>
    </form>
</body>
</html>
