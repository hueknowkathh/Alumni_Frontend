<?php
require 'C:/xampp/htdocs/alumni_php/db.php';

$summaryResult = $conn->query(
    "SELECT COUNT(*) AS total, GROUP_CONCAT(DISTINCT program ORDER BY program SEPARATOR '|') AS programs
     FROM graduate_registry"
);

$sampleResult = $conn->query(
    "SELECT id, full_name, program, year_graduated, email, source_file_name
     FROM graduate_registry
     ORDER BY id DESC
     LIMIT 10"
);

$payload = [
    'summary' => $summaryResult ? $summaryResult->fetch_assoc() : ['error' => $conn->error],
    'sample' => [],
];

if ($sampleResult) {
    while ($row = $sampleResult->fetch_assoc()) {
        $payload['sample'][] = $row;
    }
} else {
    $payload['sample'][] = ['error' => $conn->error];
}

echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
$conn->close();
