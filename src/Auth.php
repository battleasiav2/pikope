<?php
declare(strict_types=1);

namespace App;

final class Auth
{
    /** @return array<string,mixed> the signed-in user row */
    public static function user(): array
    {
        $token = Http::bearer();
        if ($token === null) {
            throw ApiError::unauthorized();
        }
        return self::userByToken($token);
    }

    /** @return array<string,mixed> the user this bearer token belongs to */
    public static function userByToken(string $token): array
    {
        $row = Db::one(
            'SELECT u.*, t.id AS token_id FROM auth_tokens t JOIN users u ON u.id = t.user_id
             WHERE t.token_hash = ? AND t.expires_at > NOW()',
            [hash('sha256', $token)]
        );
        if ($row === null) {
            throw ApiError::unauthorized('Session expired, sign in again');
        }
        if ($row['banned']) {
            throw new ApiError(403, 'banned', 'This account has been suspended');
        }
        Db::run('UPDATE auth_tokens SET last_used_at = NOW() WHERE id = ?', [$row['token_id']]);
        return $row;
    }

    public static function issueToken(int $userId): string
    {
        $token = bin2hex(random_bytes(32));
        Db::run(
            'INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))',
            [$userId, hash('sha256', $token), Config::int('TOKEN_TTL_DAYS', 90)]
        );
        return $token;
    }

    public static function cleanName(string $name): string
    {
        // Nicknames are letters, numbers and underscores only.
        $name = substr(preg_replace('/[^A-Za-z0-9_]/', '', $name) ?? '', 0, 16);
        return strlen($name) < 3 ? 'Player' . random_int(1000, 9999) : $name;
    }

    /** @param array<string,mixed> $u @return array<string,mixed> */
    public static function publicUser(array $u): array
    {
        return [
            'id' => (int) $u['id'],
            'displayName' => $u['display_name'],
            'avatar' => $u['avatar'],
            'tableSkin' => $u['table_skin'],
            'coins' => (int) $u['coins'],
            'gems' => (int) $u['gems'],
            'xp' => (int) $u['xp'],
            'level' => Economy::levelOf((int) $u['xp'])['level'],
            'levelProgress' => Economy::levelOf((int) $u['xp'])['progress'],
            'rank' => Economy::rankOf((int) $u['wins']),
            'cue' => $u['cue'],
            'cues' => Economy::ownedCues((int) $u['id']),
            'nameSet' => (bool) $u['name_set'],
            'wins' => (int) $u['wins'],
            'games' => (int) $u['games'],
            'isGuest' => (bool) $u['is_guest'],
            'phone' => isset($u['phone']) && $u['phone'] !== null && $u['phone'] !== ''
                ? Phone::display((string) $u['phone'])
                : null,
            'referralCode' => self::ensureReferralCode($u),
            'referredBy' => isset($u['referred_by']) && $u['referred_by'] !== null ? (int) $u['referred_by'] : null,
        ];
    }

    /** A short code this player can share. Created once. @param array<string,mixed> $u */
    public static function ensureReferralCode(array $u): string
    {
        $existing = $u['referral_code'] ?? null;
        if (is_string($existing) && preg_match('/^\d{6}$/', $existing) === 1) {
            return $existing;
        }
        $id = (int) $u['id'];
        if (is_string($existing) && $existing !== '') {
            Db::run('UPDATE users SET referral_code = NULL WHERE id = ?', [$id]);
        }
        for ($n = 0; $n < 12; $n++) {
            $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            try {
                Db::run('UPDATE users SET referral_code = ? WHERE id = ? AND referral_code IS NULL', [$code, $id]);
            } catch (\PDOException) {
                continue;
            }
            $saved = Db::one('SELECT referral_code FROM users WHERE id = ?', [$id]);
            if ($saved !== null && is_string($saved['referral_code']) && $saved['referral_code'] !== '') {
                return $saved['referral_code'];
            }
        }
        throw new ApiError(500, 'server_error', 'Could not create a referral code');
    }

    /**
     * Links a player to a friend's 6-digit code. An empty code does nothing.
     * A second code is refused, unless [$quietIfSet] (sign-up may send it twice).
     */
    /** Rejects a filled-in code that is not 6 digits or does not exist. Empty is allowed. */
    public static function assertReferralAvailable(string $raw): void
    {
        $code = trim($raw);
        if ($code === '') {
            return;
        }
        if (preg_match('/^\d{6}$/', $code) !== 1) {
            throw ApiError::badRequest('Invite code must be 6 digits', 'bad_code');
        }
        $other = Db::one('SELECT id, is_bot FROM users WHERE referral_code = ?', [$code]);
        if ($other === null || (int) $other['is_bot'] === 1) {
            throw ApiError::badRequest('That invite code was not found', 'bad_code');
        }
    }

    public static function attachReferral(int $userId, string $raw, bool $quietIfSet = false): void
    {
        $code = trim($raw);
        if ($code === '') {
            return;
        }
        if (preg_match('/^\d{6}$/', $code) !== 1) {
            throw ApiError::badRequest('Invite code must be 6 digits', 'bad_code');
        }
        Db::transaction(static function () use ($userId, $code, $quietIfSet): void {
            $me = Db::one('SELECT id, referred_by FROM users WHERE id = ? FOR UPDATE', [$userId]);
            if ($me === null) {
                throw ApiError::notFound('No such player');
            }
            if ($me['referred_by'] !== null) {
                if ($quietIfSet) {
                    return;
                }
                throw ApiError::conflict('You already used an invite code', 'already_referred');
            }
            $other = Db::one('SELECT id, is_bot, referred_by FROM users WHERE referral_code = ?', [$code]);
            if ($other === null || (int) $other['is_bot'] === 1) {
                throw ApiError::badRequest('That invite code was not found', 'bad_code');
            }
            if ((int) $other['id'] === (int) $me['id'] || (int) ($other['referred_by'] ?? 0) === (int) $me['id']) {
                throw ApiError::badRequest('You cannot use your own invite', 'bad_code');
            }
            Db::run('UPDATE users SET referred_by = ? WHERE id = ? AND referred_by IS NULL', [(int) $other['id'], $userId]);
        });
    }
}
