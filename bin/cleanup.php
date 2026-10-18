<?php
declare(strict_types=1);

// Housekeeping. Run from cron every few minutes:
//   */5 * * * * php /path/to/backend/bin/cleanup.php >/dev/null 2>&1
require dirname(__DIR__) . '/src/bootstrap.php';

use App\Config;
use App\Db;
use App\GameService;

if (PHP_SAPI !== 'cli') {
    exit(1);
}

$report = [];
$report['games ruled'] = GameService::sweep();
$report['tokens'] = Db::run('DELETE FROM auth_tokens WHERE expires_at < NOW()')->rowCount();
$report['login attempts'] = Db::run('DELETE FROM login_attempts WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 DAY)')->rowCount();
$report['reset codes'] = Db::run('DELETE FROM password_resets WHERE expires_at < NOW()')->rowCount();
$report['challenges expired'] = Db::run("UPDATE challenges SET status = 'expired' WHERE status = 'pending' AND expires_at < NOW()")->rowCount();
$report['old challenges'] = Db::run("DELETE FROM challenges WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 DAY)")->rowCount();
$report['rate windows'] = Db::run('DELETE FROM rate_limits WHERE window_start < ?', [time() - 86400])->rowCount();
// Waiting rooms nobody has polled for ten minutes.
$report['stale rooms'] = Db::run(
    "UPDATE rooms r SET r.status = 'closed'
     WHERE r.status = 'waiting' AND NOT EXISTS (
       SELECT 1 FROM room_players p WHERE p.room_id = r.id AND p.last_seen_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE))"
)->rowCount();
$days = Config::int('SHOT_LOG_DAYS', 30);
$report['old shots'] = Db::run('DELETE FROM game_shots WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)', [$days])->rowCount();
// Guests who never played and have not been seen for a month.
$report['idle guests'] = Db::run(
    "DELETE u FROM users u WHERE u.is_guest = 1 AND u.games = 0 AND u.created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
     AND NOT EXISTS (SELECT 1 FROM auth_tokens t WHERE t.user_id = u.id AND t.last_used_at > DATE_SUB(NOW(), INTERVAL 30 DAY))
     AND NOT EXISTS (SELECT 1 FROM game_players g WHERE g.user_id = u.id)"
)->rowCount();

foreach ($report as $what => $count) {
    echo str_pad($what, 16), $count, "\n";
}
