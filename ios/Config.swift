import Foundation

/// Configuration file for Supabase credentials.
/// This file contains sensitive API keys and should be excluded from version control.
/// Add this file to .gitignore to prevent committing credentials.
enum Config {
    /// All configuration values loaded from a dictionary.
    /// Keys follow the EXPO_PUBLIC_* naming convention for compatibility.
    static let allValues: [String: String] = [
        "EXPO_PUBLIC_SUPABASE_URL": "https://xmhplwgtzhtxdzwzbitx.supabase.co",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "sb_publishable_xtpWDIPcWZ92I-kFI_XCJg__S1sGd7O"
    ]
}

// INSTRUCTIONS:
// 1. Go to your Supabase project dashboard: https://supabase.com
// 2. Navigate to Project Settings > API
// 3. Copy the "Project URL" and replace "https://your-project.supabase.co"
// 4. Copy the "anon/public" key and replace "your-anon-key-here"
// 5. Make sure this file is in .gitignore to keep your keys secure
