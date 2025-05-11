-- Drop existing tables if they exist
DROP TABLE IF EXISTS outfit_items;
DROP TABLE IF EXISTS outfits;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS users;

-- Create Users table
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    profile_image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create Items table (matching the Flutter Item model)
CREATE TABLE items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    image_url VARCHAR(255),
    `condition` VARCHAR(50) NOT NULL,
    seller_id INT NOT NULL,
    seller_name VARCHAR(100) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Outfits table
CREATE TABLE outfits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Outfit_Items junction table
CREATE TABLE outfit_items (
    outfit_id INT NOT NULL,
    item_id INT NOT NULL,
    position INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (outfit_id, item_id),
    FOREIGN KEY (outfit_id) REFERENCES outfits(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- Insert sample users
INSERT INTO users (id, username, email, password_hash, full_name) VALUES
(1, 'john_doe', 'john@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John Doe'),
(2, 'jane_smith', 'jane@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jane Smith');

-- Insert sample items (matching the Flutter Item model fields)
INSERT INTO items (id, name, description, price, category, image_url, `condition`, seller_id, seller_name, is_available) VALUES
(1, 'Blue Denim Jacket', 'Classic denim jacket in excellent condition', 29.99, 'Outerwear', 'assets/images/denim_jacket.jpg', 'Excellent', 1, 'John Doe', true),
(2, 'White T-Shirt', 'Basic white cotton t-shirt', 12.99, 'Tops', 'assets/images/tshirt.jpg', 'Good', 1, 'John Doe', true),
(3, 'Black Jeans', 'Skinny fit black jeans', 24.99, 'Bottoms', 'assets/images/jeans.jpg', 'Very Good', 2, 'Jane Smith', true),
(4, 'Red Dress', 'Elegant evening dress', 39.99, 'Dresses', 'assets/images/dress.jpg', 'Like New', 2, 'Jane Smith', true);

-- Insert sample outfits
INSERT INTO outfits (id, user_id, name, description) VALUES
(1, 1, 'Casual Weekend', 'Perfect for a relaxed weekend'),
(2, 2, 'Evening Out', 'Elegant outfit for dinner');

-- Link items to outfits
INSERT INTO outfit_items (outfit_id, item_id, position) VALUES
(1, 1, 1),
(1, 2, 2),
(2, 3, 1),
(2, 4, 2);