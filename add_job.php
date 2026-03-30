<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

include 'db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!$data) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON data']);
        exit;
    }

    $id = $data['id'] ?? '';
    $title = $data['title'] ?? '';
    $description = $data['description'] ?? '';
    $company = $data['company'] ?? '';
    $location = $data['location'] ?? '';
    $salary = $data['salary'] ?? '';
    $requirements = $data['requirements'] ?? '';
    $contact_email = $data['contact_email'] ?? '';

    // Validate required fields
    if (empty($title) || empty($description) || empty($company) || empty($location) || empty($contact_email)) {
        echo json_encode(['status' => 'error', 'message' => 'Missing required fields']);
        exit;
    }

    if (!empty($id)) {
        // Update existing job
        $stmt = $conn->prepare("UPDATE jobs SET title = ?, description = ?, company = ?, location = ?, salary = ?, requirements = ?, contact_email = ? WHERE id = ?");
        $stmt->bind_param("sssssssi", $title, $description, $company, $location, $salary, $requirements, $contact_email, $id);
    } else {
        // Insert new job
        $stmt = $conn->prepare("INSERT INTO jobs (title, description, company, location, salary, requirements, contact_email) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("sssssss", $title, $description, $company, $location, $salary, $requirements, $contact_email);
    }

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Job saved successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $conn->error]);
    }
}
?>