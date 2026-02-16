# Stakk Play Store Publishing - Autonomous Execution Prompt

Copy and paste this entire prompt into a Claude Code session to have it execute the remaining publishing tasks autonomously.

---

## PROMPT START

You are working on the Stakk app (formerly IDswipe) at C:\Users\josep\IDswipe. The app is a free encrypted digital ID wallet for Android. All documentation, legal docs, and store listing content have already been prepared.

Execute ALL of the following tasks autonomously. Josep is away - do not ask questions, just execute:

### TASK 1: Regenerate Branding Assets

The feature graphic and app icon still show "IDswipe" branding. Regenerate them with "Stakk" branding.

**Feature Graphic (1024x500)**
1. Read the HTML template at `C:\Users\josep\IDswipe\store-assets\feature-graphic.html`
2. Change "IDswipe" to "Stakk" in the HTML - specifically change `<div class="app-name">ID<span>swipe</span></div>` to `<div class="app-name">St<span>akk</span></div>`
3. Update the tagline to: "Your IDs. Encrypted. Always with you."
4. Use Playwright to open the HTML file, set viewport to 1024x500, and take a screenshot saving to `C:\Users\josep\IDswipe\store-assets\feature-graphic.png`

**App Icon (512x512)**
1. Read the HTML template at `C:\Users\josep\IDswipe\store-assets\app-icon-512.html`
2. Change the text from "ID" to "St" (keeping the same style) - this represents the "St" in Stakk
3. Use Playwright to open the HTML file, set viewport to 512x512, and take a screenshot saving to `C:\Users\josep\IDswipe\store-assets\app-icon-512.png`

### TASK 2: Apply Stakk Branding to Master Branch

1. Run `cd C:\Users\josep\IDswipe && git stash` to save any demo branch work
2. Run `git checkout master`
3. Apply the SAME branding changes that exist on the demo/stakk-screenshots branch, but keep FLAG_SECURE ENABLED (this is production):

Files to update (rename "IDswipe" to "Stakk" in user-visible strings only):
- `lib/presentation/screens/home_screen.dart` - app bar title
- `lib/presentation/screens/lock_screen.dart` - lock screen title
- `lib/presentation/screens/settings_screen.dart` - about section, app name references
- `lib/presentation/screens/business_demo_screen.dart` - if exists, app name references
- `android/app/src/main/AndroidManifest.xml` - android:label="Stakk"
- `lib/main.dart` - MaterialApp title: 'Stakk'

DO NOT modify:
- `android/app/src/main/kotlin/*/MainActivity.kt` - keep FLAG_SECURE enabled
- Any internal variable names or package names
- The applicationId (keep as com.koller31.idswipe)

4. After all changes, run: `cd C:\Users\josep\IDswipe && flutter analyze`
5. If clean, commit: "Apply Stakk branding to master branch for production release"

### TASK 3: Build Production AAB

1. Make sure you're on master branch
2. Run: `cd C:\Users\josep\IDswipe && flutter build appbundle --release`
3. Verify the AAB was created at `build/app/outputs/bundle/release/app-release.aab`
4. Report the file size

### TASK 4: Copy Assets to stakk-app Repo

1. Copy the regenerated feature graphic and app icon to the stakk-app repo:
   - Copy `C:\Users\josep\IDswipe\store-assets\feature-graphic.png` to `C:\Users\josep\stakk-app\docs\feature-graphic.png`
   - Copy `C:\Users\josep\IDswipe\store-assets\app-icon-512.png` to `C:\Users\josep\stakk-app\docs\app-icon-512.png`
2. Commit and push to stakk-app repo

### TASK 5: Checkpoint

Call memory_checkpoint with:
- session_summary: What was accomplished
- current_state: "Production AAB built with Stakk branding. All docs and assets ready. Next: Sign up for Play Console ($25), go through 14-day closed testing, then publish."
- next_todos: Remaining steps for Josep (sign up for Play Console, recruit 20 testers, etc.)

Report a final summary of everything completed and what Josep needs to do manually (Play Console signup, testing, etc.)

## PROMPT END
