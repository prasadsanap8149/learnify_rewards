Create a full-fledged app development plan and add missing details.

I want to create a development plan that covers all areas from the user's perspective or, as today's financial apps do, from the government's perspective. 

The app is for learning and earning. Any age group can use the app and earn from its usage, learning-based.

Tech Stack:
Flutter, Firebase, Fire store, Gradle, Dart

Key Developments for Apps:
- Multiple Themes
- Encrypted Data
- Store data in firebase in encrypted AES-256
- Use constants, helpers files, Routes for navigation, env for debug and release, modals.
- Ad services
- Propgaurd-rules.pro
- Firebase, Firestore rules & configuration.
- Privacy Policy
- Consideration Google Play Store Policy 
- Edge cases 

Use Case of the App:
- The app should have RBAC.
- Decide the specific roles and responsibilities as per the use case.
- All Firebase rules should be in a proper manner.
- As per the role, accessibility is managed.
- Create the user account via sign-in with Google with the user role.
- Give the option to the user to update their full profile after onboarding the user.
    - Take the details like mobile, address, PIN, UPI ID, or PayPal account ID.
    - Any time he can update his own account
- The app has all types of Google AdMob ads and navigation buttons, excluding banner ads. Banner ads are always shown at the bottom of every screen.
- On any type of ad, the navigated type of ad should be shown to the user. 
- In the next screen, the user has some kind of activity options, whatever he likes, like random puzzles, math, or word game activity. 
- On the selection of any activity, that type of activity should be asked of or shown to the user.
For example, if a user selected math and then random addition, multiplication, subtraction, division, or square root questions, he would have them displayed over the screen, and if he gave the correct answer, then only the selected type of ads would show.
- The user has two lifelines to select or give the correct answer.
- If the user does not select or give the correct answer, then don't show ads and go back to the activities options screen.
- If the user sees the ads, then that activity should lock for 5 seconds (this timeframe should come from the database for all users). 
- This lock applies to all activities. If any activity has shown ads successfully, there should be a cooling period for the user to choose the same activity again. Meanwhile, he can choose another activity to see the ads.
- All impressions on ads should log to his profile.
- So, as per his impression, I can generate his estimated earnings. (So, as per the ad type, the earnings should be different).
- That base earning should come from the database.
- All calculations should be done at the end of the day and should be shown on his profile. 
- The user should show the entire breakdown of his day's earnings, like which ads give how much earnings. Those
- The user can check all his earning history on his profile.
- There is, like, Total Earnings, Total Withdrawal, and Remaining Amount.
- And there should be all the calculations of earnings day-wise and withdrawals month-wise.
- Withdrawal should happen at the end of each month. 
- There should be a withdrawal threshold like $50. 
- Each withdrawal request is auto-settled at the end of the month, and the platform fees should be deducted from the earnings. And should give the detailed breakout of that transaction.
- This platform's fees value comes from the database.
- In the initial release, this payout process manual was done by the platform super admin.
- Use should drop the mail for account activation if the account is deactivated due to suspicious activities.


Admin Side
- Admin can track all user activities.
- Admin can deactivate the user account if any suspicious activity is done by the user.
- Admin can have the dashboard for user earnings settlement in a detailed view.
- Admin can update all the fields that are required till now.
- All users have options for switching roles if they have multiple roles.


- There should be one screen that shows all the calculation criteria, payout-related information, and other key details that the user needs to understand.
