import Foundation

/// Connection details for the real TrainToAdapt backend (Supabase auth + the
/// client booking API). Per the backend team's integration guide, the anon
/// key below is a publishable key, not a secret — row-level security on the
/// server makes sure each signed-in client only ever sees their own records.
/// Never add a service-role or other privileged key to this app.
enum AppConfig {
    static let supabaseURL = URL(string: "https://eyxhkolheijyqccgouyv.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5eGhrb2xoZWlqeXFjY2dvdXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxNzQzMjcsImV4cCI6MjA5Nzc1MDMyN30.aYlKADOP4cdKvHJiVCP3jYms9S9mVG3yMym9_s4A6aA"
    static let apiBase = URL(string: "https://client.traintoadapt.co.uk/api/public/mobile")!
    static let portal = URL(string: "https://client.traintoadapt.co.uk")!

    /// Must match the custom URL scheme registered in Info.plist
    /// (`CFBundleURLTypes`) and the redirect URL allow-listed in the
    /// Supabase dashboard under Authentication → URL Configuration.
    static let authCallbackURL = URL(string: "traintoadapt://auth-callback")!

    /// Shown for App Store–required account deletion, per the developer
    /// guide's Apple review notes.
    static let supportEmail = "adam@traintoadapt.co.uk"
}
