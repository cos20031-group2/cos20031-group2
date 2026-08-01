<?php
// MySQL/MariaDB wraps a trigger's SIGNAL message in noise like:
//   SQLSTATE[45000]: <<Unknown error>>: 1644 Cannot start assignment: driver is not currently eligible.
// The actual human-readable text is whatever the trigger wrote in MESSAGE_TEXT --
// this strips the SQLSTATE/error-code prefix so only that part is shown to the user.
function friendlySqlError(PDOException $e): string
{
    $message = $e->getMessage();

    if (preg_match('/SQLSTATE\[\w+\]:.*?:\s*\d+\s+(.*)$/s', $message, $matches)) {
        return $matches[1];
    }

    return $message;
}
