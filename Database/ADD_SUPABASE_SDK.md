# How to Add Supabase Swift SDK to Ledstjärnan

## Steps to Add Package Dependency

1. **Open Xcode** with your Ledstjarnan project

2. **Go to File Menu**:
   - Click `File` → `Add Package Dependencies...`

3. **Enter Package URL**:
   - In the search bar, paste: `https://github.com/supabase/supabase-swift`
   - Press Enter/Return

4. **Select Version**:
   - Dependency Rule: `Up to Next Major Version`
   - Version: `2.0.0` (or latest 2.x.x)
   - Click `Add Package`

5. **Select Products** (check all):
   - ✅ `Supabase`
   - ✅ `Auth`
   - ✅ `Functions`
   - ✅ `PostgREST`
   - ✅ `Realtime`
   - ✅ `Storage`
   
6. **Add to Target**:
   - Make sure `Ledstjarnan` is selected as the target
   - Click `Add Package`

7. **Wait for Resolution**:
   - Xcode will download and resolve dependencies
   - This may take 1-2 minutes

8. **Verify Installation**:
   - Look in Project Navigator (left sidebar)
   - You should see "Package Dependencies" folder
   - Inside should be "supabase-swift"

## What Happens Next

Once the SDK is added, I can:
- ✅ Create `SupabaseClient.swift` to initialize the connection
- ✅ Create `AuthService.swift` for login/signup/password reset
- ✅ Create service layers for all features
- ✅ Update AppState to manage Supabase session
- ✅ Rebuild all views to use real data

## Troubleshooting

### "Failed to resolve package"
- Check your internet connection
- Try again (sometimes GitHub rate limits)
- Make sure the URL is correct: `https://github.com/supabase/supabase-swift`

### "Minimum deployment target"
- Supabase Swift requires iOS 15.0+
- Check Project Settings → General → Deployment Target
- Set to iOS 15.0 or higher

### Package won't download
- Restart Xcode
- Clean build folder: `Product` → `Clean Build Folder`
- Try again

## After Adding the Package

**Come back to Claude Code and let me know!** I'll then:
1. Create the service layer
2. Update authentication
3. Connect all features to real Supabase data

---

**Ready?** Add the package now and let me know when it's done! 🚀
