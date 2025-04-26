<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['imageData']) && !empty($_POST['imageData'])) {
        $imgData = $_POST['imageData'];

        // Extract base64 string
        $imgData = str_replace('data:image/png;base64,', '', $imgData);
        $imgData = str_replace(' ', '+', $imgData);

        $data = base64_decode($imgData);
        
        if (!is_dir('uploads')) {
            mkdir('uploads', 0755, true);
        }

        $filename = 'uploads/image_' . time() . '.png';

        if (file_put_contents($filename, $data)) {
            echo "✅ Image saved as $filename!";
        } else {
            echo "❌ Failed to save image.";
        }
    } else {
        echo "⚠️ No image data received.";
    }
} else {
    echo "⛔ Invalid request.";
}
?>
