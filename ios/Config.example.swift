import Foundation

/// EXAMPLE Configuration file for Supabase credentials.
/// 
/// TO USE THIS FILE:
/// 1. Copy this file and rename it to "Config.swift" (remove ".example")
/// 2. Go to your Supabase project dashboard: https://supabase.com
/// 3. Navigate to Project Settings > API
/// 4. Copy the "Project URL" and replace the placeholder below
/// 5. Copy the "anon/public" key and replace the placeholder below
/// 6. Make sure "Config.swift" is in .gitignore (it should be by default)
/// 
/// WARNING: Never commit the actual Config.swift file with real credentials!

enum ConfigExample {
    /// All configuration values loaded from a dictionary.
    /// Keys follow the EXPO_PUBLIC_* naming convention for compatibility.
    static let allValues: [String: String] = [
        // Replace with your actual Supabase project URL
        // Example: "https://abcdefghijklmnop.supabase.co"
        "EXPO_PUBLIC_SUPABASE_URL": "https://your-project.supabase.co",
        
        // Replace with your actual Supabase anon/public key
        // Example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzAwMDAwMCwiZXhwIjoxOTM4NTc2MDAwfQ.example"
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "your-anon-key-here"
    ]
}
