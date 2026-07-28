<?php
// Include this at the top of every dashboard page (after session_start()).
// Usage: require_once __DIR__ . '/../../includes/require_role.php';
//        requireRole(['Driver']);   // pass an array of role names allowed on this page

require_once __DIR__ . '/auth_check.php'; // first: must be logged in at all

function requireRole(array $allowedRoles): void
{
    if (!in_array($_SESSION['role_name'], $allowedRoles, true)) {
        http_response_code(403);
        echo '<h1>Access denied</h1><p>Your account role (' .
             htmlspecialchars($_SESSION['role_name']) .
             ') is not permitted to view this page.</p>';
        echo '<p><a href="/cos20031-smarfleet/welcome.php">Back</a></p>';
        exit;
    }
}
