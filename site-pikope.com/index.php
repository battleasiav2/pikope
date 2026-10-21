<?php
declare(strict_types=1);
/**
 * pikope.com landing entry (Hostinger public_html/index.php).
 * Design: index.html (Play Store layout). APK + screenshots: assets/landing.js → admin API.
 */
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-cache, must-revalidate');

$htmlFile = __DIR__ . '/index.html';
if (!is_readable($htmlFile)) {
    http_response_code(500);
    echo '<!DOCTYPE html><html lang="bn"><body><p>Landing index.html missing.</p></body></html>';
    exit;
}

readfile($htmlFile);
