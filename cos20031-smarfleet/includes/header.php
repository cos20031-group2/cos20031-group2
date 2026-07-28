<link rel="stylesheet" href="/cos20031-smarfleet/assets/css/style.css">
<header class="app-header">
    <strong>Smart Fleet Management -- <?= htmlspecialchars($_SESSION['role_name']) ?> Dashboard</strong>
    <span>
        Logged in as <?= htmlspecialchars($_SESSION['username']) ?>
        &nbsp;|&nbsp;
        <a href="/cos20031-smarfleet/auth/logout.php">Log out</a>
    </span>
</header>
<main>