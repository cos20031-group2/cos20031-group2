<?php
// Include this at the top of any page that requires a logged-in user.
// Must be called AFTER session_start() in the including file.
if (!isset($_SESSION['user_id'])) {
    header('Location: /cos20031-smarfleet/auth/login.php'); // adjust path if your folder name differs
    exit;
}
