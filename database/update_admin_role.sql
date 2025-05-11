-- Add role column to users table if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' AFTER email;

-- Update admin user role - change username as needed
UPDATE users SET role = 'admin' WHERE username = 'admin';

-- If admin user doesn't exist, create one
INSERT INTO users (username, email, password_hash, full_name, role) 
SELECT 'admin', 'admin@example.com', '$2y$10$CfoFAiI5qDBUKr7p5YWeyuxAB4m4KFvUQgBt83.b2BSfOrkbavq4e', 'Admin User', 'admin' 
FROM dual 
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');
