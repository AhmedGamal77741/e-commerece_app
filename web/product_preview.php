<?php
header('Content-Type: text/html; charset=utf-8');

// 1. Extract Product ID from URL path or query string
$requestUri = $_SERVER['REQUEST_URI'] ?? '';
$productId = '';

if (preg_match('#/product/([a-zA-Z0-9_-]+)#', $requestUri, $matches)) {
    $productId = $matches[1];
} elseif (isset($_GET['productId'])) {
    $productId = trim($_GET['productId']);
}

// Default fallback metadata
$siteName = '팽이초콜릿';
$productName = '팽이초콜릿';
$description = '좋은제품, 좋은가격, 좋은문화';
$imageUrl = 'https://www.pang2chocolate.com/favicon.png';
$canonicalUrl = 'https://www.pang2chocolate.com/product/' . urlencode($productId);

// 2. If Product ID exists, fetch metadata from Firebase Firestore REST API
if (!empty($productId)) {
    $firestoreUrl = "https://firestore.googleapis.com/v1/projects/e-commerce-app-34fb2/databases/(default)/documents/products/" . urlencode($productId);
    
    $response = false;
    if (function_exists('curl_init')) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $firestoreUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 4);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $response = curl_exec($ch);
        curl_close($ch);
    }

    if ($response === false) {
        $opts = [
            'http' => ['timeout' => 4],
            'ssl' => ['verify_peer' => false, 'verify_peer_name' => false]
        ];
        $response = @file_get_contents($firestoreUrl, false, stream_context_create($opts));
    }

    if ($response) {
        $json = json_decode($response, true);
        if (isset($json['fields'])) {
            $fields = $json['fields'];

            // Extract productName / name
            if (isset($fields['productName']['stringValue']) && !empty($fields['productName']['stringValue'])) {
                $productName = $fields['productName']['stringValue'];
            } elseif (isset($fields['name']['stringValue']) && !empty($fields['name']['stringValue'])) {
                $productName = $fields['name']['stringValue'];
            }

            // Extract price
            $priceVal = 0;
            if (isset($fields['pricePoints']['arrayValue']['values'][0]['mapValue']['fields']['price'])) {
                $pp = $fields['pricePoints']['arrayValue']['values'][0]['mapValue']['fields']['price'];
                $priceVal = $pp['doubleValue'] ?? $pp['integerValue'] ?? 0;
            } elseif (isset($fields['price'])) {
                $priceVal = $fields['price']['doubleValue'] ?? $fields['price']['integerValue'] ?? 0;
            }

            if ($priceVal > 0) {
                $description = number_format($priceVal) . '원 | 좋은제품, 좋은가격, 좋은문화';
            }

            // Extract imgUrl
            if (isset($fields['imgUrl']['stringValue']) && !empty($fields['imgUrl']['stringValue'])) {
                $imageUrl = $fields['imgUrl']['stringValue'];
            } elseif (isset($fields['imgUrls']['arrayValue']['values'][0]['stringValue'])) {
                $imageUrl = $fields['imgUrls']['arrayValue']['values'][0]['stringValue'];
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="ko">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="theme-color" content="#eeeeee">

  <title><?= htmlspecialchars($productName, ENT_QUOTES, 'UTF-8') ?> - <?= htmlspecialchars($siteName, ENT_QUOTES, 'UTF-8') ?></title>

  <!-- Open Graph Meta Tags (Discord, KakaoTalk, Facebook, Slack, iMessage, Telegram, WhatsApp) -->
  <meta property="og:site_name" content="<?= htmlspecialchars($siteName, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:type" content="product">
  <meta property="og:title" content="<?= htmlspecialchars($productName, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:image" content="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:image:secure_url" content="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>">
  <meta property="og:url" content="<?= htmlspecialchars($canonicalUrl, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Twitter Card Meta Tags (Discord, Twitter / X) -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="<?= htmlspecialchars($productName, ENT_QUOTES, 'UTF-8') ?>">
  <meta name="twitter:description" content="<?= htmlspecialchars($description, ENT_QUOTES, 'UTF-8') ?>">
  <meta name="twitter:image" content="<?= htmlspecialchars($imageUrl, ENT_QUOTES, 'UTF-8') ?>">

  <!-- Favicon & iOS meta -->
  <link rel="icon" type="image/png" href="favicon.png?v=2" />
  <link rel="manifest" href="manifest.json">
  <style>
    html, body {
      background-color: #eeeeee;
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
