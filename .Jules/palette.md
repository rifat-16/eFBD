## 2024-10-26 - Password Visibility Toggle

**Learning:** When users create an account, they often mistype their passwords on mobile devices or fast keyboards. By default, `obscureText` hides the characters, which is secure but error-prone during creation. The `LoginScreen` had a visibility toggle, but `RegisterScreen` and `ProfileDialog` did not, creating an inconsistent UX where it's needed most (during password creation).

**Action:** Always ensure that any password input field (especially during registration or profile updates) has a visibility toggle so users can verify their input before submission.
