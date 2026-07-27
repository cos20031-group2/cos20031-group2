<?php
// ==========================================================
// Shared database connection for the whole app.
// Every page includes this file to get $pdo.
// ==========================================================

$DB_HOST = '127.0.0.1';
$DB_NAME = 'smartfleet';   // change this if your database is named differently
$DB_USER = 'root';         // default XAMPP MySQL user
$DB_PASS = '';             // default XAMPP MySQL password (blank)

try {
    $pdo = new PDO(
        "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            // Throw exceptions on SQL errors instead of failing silently
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            // Return rows as associative arrays, e.g. $row['VIN']
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    // For a class demo this is fine to show directly; die() stops the page.
    die('Database connection failed: ' . $e->getMessage());
}
