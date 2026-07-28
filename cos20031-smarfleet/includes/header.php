<header style="background:#222; color:#fff; padding:12px 20px; display:flex; justify-content:space-between; align-items:center;">
    <strong>Smart Fleet Management -- <?= htmlspecialchars($_SESSION['role_name']) ?> Dashboard</strong>
    <span>
        Logged in as <?= htmlspecialchars($_SESSION['username']) ?>
        &nbsp;|&nbsp;
        <a href="/cos20031-smarfleet/auth/logout.php" style="color:#fff;">Log out</a>
    </span>
</header>
<main style="padding:20px;">
