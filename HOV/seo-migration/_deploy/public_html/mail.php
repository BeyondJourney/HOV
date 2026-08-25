<?php
/**
 * House of Vacation - enquiry form handler
 *
 * Replaces the original handler, which had:
 *   - From: noreply@yourdomain.com  (placeholder -> SPF/DKIM fail -> silently spam-filtered)
 *   - $to  = a personal Gmail address instead of the business inbox
 *   - direct $_POST['x'] reads, so a missing field was a PHP 8 warning printed
 *     into the response body
 *   - no CR/LF stripping, so the email field could inject extra mail headers
 *   - no spam protection, no rate limit, no length caps
 *   - htmlspecialchars() applied to a text/plain body (apostrophes arrived as &#039;)
 *   - die()/echo dumping unstyled text onto a blank white page
 *
 * Responds with JSON to XMLHttpRequest and with a styled page otherwise, so the
 * form works with and without JavaScript.
 *
 * Requires PHP 7.4+. No external libraries.
 */

declare(strict_types=1);

// ---------------------------------------------------------------------------
// CONFIG - change these if the business addresses ever change.
// ---------------------------------------------------------------------------
const MAIL_TO        = 'mice@houseofvacation.com';
const MAIL_CC        = 'info@houseofvacation.com';
const MAIL_FROM      = 'noreply@houseofvacation.com';   // must be on THIS domain for SPF/DKIM
const THANK_YOU_URL  = '/thank-you/';
const LOG_FILE       = __DIR__ . '/enquiry-log.txt';
const RATE_LIMIT_SEC = 30;
const MAX_FIELD_LEN  = 200;
const MAX_DETAIL_LEN = 4000;

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$isAjax = (
    (isset($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest')
    || (isset($_SERVER['HTTP_ACCEPT']) && strpos($_SERVER['HTTP_ACCEPT'], 'application/json') !== false)
);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /', true, 303);
    exit;
}

/** Fetch a POST field safely: trimmed, length-capped, newline-stripped. */
function field(string $key, int $max = MAX_FIELD_LEN): string {
    $v = isset($_POST[$key]) && is_string($_POST[$key]) ? trim($_POST[$key]) : '';
    // Stripping CR/LF is the single most important defence against header injection.
    $v = str_replace(["\r", "\n", '%0a', '%0d', '%0A', '%0D'], ' ', $v);
    return mb_substr($v, 0, $max);
}

/** Send the outcome as JSON (AJAX) or as a styled HTML page (no JS). */
function finish(bool $ok, string $heading, string $body): void {
    global $isAjax;

    if ($isAjax) {
        http_response_code(200);   // the JS reads the `ok` flag, not the status
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => $ok, 'message' => $body], JSON_UNESCAPED_UNICODE);
        exit;
    }

    http_response_code($ok ? 200 : 400);
    $h = htmlspecialchars($heading, ENT_QUOTES, 'UTF-8');
    $b = htmlspecialchars($body, ENT_QUOTES, 'UTF-8');
    $accent = $ok ? '#1f7a4d' : '#a2382c';
    echo <<<HTML
<!DOCTYPE html><html lang="en-IN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,follow">
<title>{$h} | House of Vacation</title>
<style>
 body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
      background:#f6f8fa;color:#141c25;font-family:"Poppins",system-ui,-apple-system,"Segoe UI",sans-serif;padding:24px}
 .card{max-width:520px;text-align:center;background:#fff;border:1px solid #dde4ea;
       border-radius:12px;padding:40px 32px;box-shadow:0 8px 28px -18px rgba(20,28,37,.4)}
 h1{margin:0 0 12px;font-size:1.5rem;color:{$accent}}
 p{color:#4a5867;line-height:1.7;margin:0 0 26px}
 a{display:inline-block;padding:12px 26px;background:#082567;color:#fff;
   text-decoration:none;border-radius:30px;font-weight:600}
</style></head><body><div class="card">
<h1>{$h}</h1><p>{$b}</p><a href="/">Back to homepage</a>
</div></body></html>
HTML;
    exit;
}

// ---------------------------------------------------------------------------
// 1. Honeypot - a field hidden by CSS. Humans never fill it; bots usually do.
// ---------------------------------------------------------------------------
if (field('website') !== '') {
    // Pretend it worked so the bot does not retry with a different strategy.
    finish(true, 'Thank you', 'Your enquiry has been received.');
}

// ---------------------------------------------------------------------------
// 2. Rate limit per session.
// ---------------------------------------------------------------------------
$now = time();
if (isset($_SESSION['last_enquiry']) && ($now - (int)$_SESSION['last_enquiry']) < RATE_LIMIT_SEC) {
    finish(false, 'Please wait a moment',
           'You have just sent an enquiry. Please wait a few seconds before sending another.');
}

// ---------------------------------------------------------------------------
// 3. Collect and validate.
// ---------------------------------------------------------------------------
$fullname    = field('fullname');
$company     = field('company');
$phone       = field('phone');
$emailRaw    = field('email');
$destination = field('destination');
$travellers  = field('travellers');
$traveltype  = field('travel_type');
$details     = field('details', MAX_DETAIL_LEN);

$missing = [];
if ($fullname === '')    { $missing[] = 'your name'; }
if ($phone === '')       { $missing[] = 'a phone number'; }
if ($emailRaw === '')    { $missing[] = 'an email address'; }
if ($destination === '') { $missing[] = 'a destination'; }

if ($missing) {
    finish(false, 'Some details are missing',
           'Please provide ' . implode(', ', $missing) . '.');
}

// VALIDATE, not just sanitise - the original only sanitised.
$email = filter_var($emailRaw, FILTER_VALIDATE_EMAIL);
if ($email === false) {
    finish(false, 'That email address looks wrong',
           'Please check the email address you entered.');
}

if (preg_match_all('/\d/', $phone) < 7) {
    finish(false, 'That phone number looks wrong',
           'Please enter a valid contact number.');
}

// ---------------------------------------------------------------------------
// 4. Plain-text body. No htmlspecialchars here: this is text/plain, and
//    encoding it is what turned apostrophes into &#039; in the original.
// ---------------------------------------------------------------------------
$submitted = date('d M Y, H:i');
$ip        = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$page      = field('source_page') ?: ($_SERVER['HTTP_REFERER'] ?? 'unknown');

$message = <<<TXT
NEW MICE ENQUIRY - houseofvacation.com

Name          : {$fullname}
Company       : {$company}
Phone         : {$phone}
Email         : {$email}
Destination   : {$destination}
No. of Pax    : {$travellers}
Type of Offer : {$traveltype}

Additional details
------------------
{$details}

---
Submitted : {$submitted}
Page      : {$page}
IP        : {$ip}
TXT;

// ---------------------------------------------------------------------------
// 5. Headers. From MUST be on this domain or SPF/DKIM fails and the mail is
//    silently spam-filtered - that was the original bug.
// ---------------------------------------------------------------------------
$headers   = [];
$headers[] = 'From: House of Vacation <' . MAIL_FROM . '>';
$headers[] = 'Reply-To: ' . $fullname . ' <' . $email . '>';
$headers[] = 'Cc: ' . MAIL_CC;
$headers[] = 'MIME-Version: 1.0';
$headers[] = 'Content-Type: text/plain; charset=UTF-8';   // was missing - broke accented names
$headers[] = 'Content-Transfer-Encoding: 8bit';
$headers[] = 'X-Mailer: HOV-Enquiry/1.0';

$subject = '=?UTF-8?B?' . base64_encode('New MICE Enquiry - ' . $fullname) . '?=';

$sent = @mail(MAIL_TO, $subject, $message, implode("\r\n", $headers), '-f' . MAIL_FROM);

// ---------------------------------------------------------------------------
// 6. Log every attempt. The original logged nothing, so failures were invisible.
// ---------------------------------------------------------------------------
@file_put_contents(
    LOG_FILE,
    sprintf("[%s] %s | %s | %s | %s | %s%s",
        $submitted, $sent ? 'SENT' : 'FAIL', $fullname, $email, $phone, $destination, PHP_EOL),
    FILE_APPEND | LOCK_EX
);

$_SESSION['last_enquiry'] = $now;

if ($sent) {
    if ($isAjax) {
        finish(true, 'Thank you',
               'Thank you, ' . $fullname . '. Your enquiry has been sent - our team will be in touch shortly.');
    }
    // Real URL so GA4 can record the conversion.
    header('Location: ' . THANK_YOU_URL, true, 303);
    exit;
}

finish(false, 'We could not send your enquiry',
       'Something went wrong on our side. Please call +91 92204 70800 or email mice@houseofvacation.com.');
