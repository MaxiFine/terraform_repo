#!/bin/bash

# Update the package list
sudo apt-get update

# Install Nginx
sudo apt-get install nginx -y

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Start Nginx service
sudo systemctl start nginx

# Create a custom index.html file
cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to My Website</title>
  <style>
    body {
      font-family: 'Arial', sans-serif;
      background-color: #f4f4f9;
      color: #333;
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      text-align: center;
    }
    .container {
      background: white;
      padding: 2rem;
      border-radius: 10px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    h1 {
      font-size: 2.5rem;
      margin-bottom: 1rem;
      color: #2c3e50;
    }
    p {
      font-size: 1.2rem;
      margin-bottom: 2rem;
    }
    a {
      text-decoration: none;
      color: white;
      background-color: #3498db;
      padding: 0.8rem 1.5rem;
      border-radius: 5px;
      transition: background-color 0.3s ease;
    }
    a:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to My Website</h1>
    <p>This is the homepage of my awesome website. Feel free to explore!</p>
    <a href="#">Get Started</a>
  </div>
</body>
</html>
EOF

# Allow HTTP traffic through the firewall
sudo ufw allow 'Nginx HTTP'

# Optional: Allow HTTPS traffic through the firewall
sudo ufw allow 'Nginx HTTPS'

# Print the public IP address of the server
PUBLIC_IP=$(curl -s ifconfig.me)
echo "Nginx installed successfully! You can access your server at http://$PUBLIC_IP"
echo "Nginx is running and serving the custom index page."