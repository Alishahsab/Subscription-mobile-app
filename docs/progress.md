# Progress

What was done each day, newest first.

## 1 Nov 2026 – Client test changes

- New line-style footer icons for Home, Inbox, Bot and Settings.
- Approve, Reject and Cancel are small buttons in one row, in the inbox and in the chat.
- Cancel has a lighter grey colour, and the dark amber used across the app is lighter.
- Unblock uses the soft red everywhere.
- The unblock and block popups show the customer number instead of the email.
- The approve popup shows the sender account name with the number.
- The picture viewer close button moved to the right.
- The Premium Store pill is only as wide as its text.
- The gold count on the selected category is gone, which was the likely yellow flash.
- A blocked customer never counts as active.
- The saved copy is read and written in the background, and a loading screen shows until the data is ready instead of zeros.
- The customer details screen now matches the web panel: a large round close button on the right, WhatsApp mark, big Approve with Reject and Cancel under it.

## 31 Oct 2026 – Screenshot could not be opened

- The picture is copied into memory the moment it is picked, with up to three tries, before anything else happens to it.
- The picker is cleared only after the picture is ready, because some phones stop giving access once it is emptied.
- A failed try now saves the real browser error, the file type and the size.

## 31 Oct 2026 – Native app, look and movement

- Search opens with the same growing animation as before, with a gold ring, on every screen. On Home the results show under the search bar.
- Tabs and categories now slide smoothly when tapped or swiped.
- New footer: Home, Inbox, Bot and Settings with the new icons, more see-through, a little narrower and higher.
- Pending has a new colour, #794983, in the app and on the website.

## 31 Oct 2026 – Screenshot upload, second step

- The customer sees one button. After two failed tries, that button becomes Choose from Files, with a message.
- Both ways make the picture smaller first. The 2 MB limit applies only to a picture the browser cannot make smaller, and the screenshots storage refuses anything over 2 MB.
- A failed try saves the browser and the reason, so problem versions can be seen.
- The nightly cleanup now also clears old screenshot paths from orders and messages, so old orders no longer point at deleted files.

## 31 Oct 2026 – Native app, phase 7

- A tap on a notification opens the right Inbox tab and that customer's chat in the native app.
- Reject on a notification opens the reject box for that order, and waits for the data when the app was closed.
- A tap that comes before the app is ready waits and opens afterwards.
- Approve, Cancel order, Resolved and Reply from the notification keep working, even with the app closed.

## 31 Oct 2026 – Native app, phase 6

- Native Settings home: profile photo and name, search, six sections, dark mode and sign out.
- Edits stay in a draft until Save changes, with Discard, the same checks as the website and the "Saved and live" notice. The status tiles still change instantly.
- Availability: status, working hours, and order, support and closed menu messages.
- Plans & payments: plans, bank account, payment methods with steps, customer guides with images, rejection, terms, buying and cancelled messages.
- Support: store name, welcome messages, request buttons, support messages and FAQs.
- Inbox & blocking: tab names and order, quick replies, block messages, email button and block reasons.
- Timers & limits, and the chatbot colour with a custom colour picker.
- Message editor with tap to add variables and Use the default text.
- Steps and quick replies are reordered with up and down buttons.
- Missing saved settings fall back to the same defaults as the website.

## 31 Oct 2026 – Native app, phase 5

- Native Bot chat: Active chats, Active orders, Cancelled and Inactive, with counts, search, swipe and a time left bar on active orders.
- Native customer list: All, Active now and Blocked, with search, WhatsApp links, last active, Chat and Block or Unblock.
- Native search across messages, customers and orders, with the match highlighted. A tap opens that customer's chat.

## 31 Oct 2026 – Native app, phase 4

- Native chat: header with active status, day dividers, a floating day while scrolling, grouped messages with tap to see the full date, and delivered and seen ticks.
- Every message type shows like the panel: customer, bot and admin bubbles, code, payment proof, images, deleted messages and order notes.
- Older chat history loads when a chat is opened, and the chat is marked read on open and on every new message.
- Reply box: text, send key, quick replies and images, with the same chat stage rules as the website.
- Delete a sent message or image, with the file removed from storage.
- Customer details: orders with Approve, Reject, Cancel and used or unused, issues with Reply and Resolved, a WhatsApp link, and Block or Unblock with a reason.

## 31 Oct 2026 – Native app, phase 3

- Native Dashboard: pending payments card, four counts, seven-day chart with tap to pick a day, customer list card, and swipe to Inbox.
- Native Inbox: categories from Settings with counts and dots, search, swipe between categories, and 30 cards at a time.
- Cards for Pending, App issues, Completed, Unused codes and Blocked, with the customer ring, screenshot and the right buttons.
- Approve, Reject, Cancel, Mark as unused or used, Resolved, Reply with images, and Unblock. Approve goes through the server function, which refuses a code that was already sent.
- Signal button with five bars, and a notice when the server refuses a change.
- The tab bar shows how many payments and issues are waiting.

## 31 Oct 2026 – Native app, phase 2

- Native data layer on the same Supabase tables: customers, conversations, orders, messages, tickets, notifications and store settings.
- The app opens at once from a copy on the phone, then loads what changed. Two days of chat load first and older messages follow in the background.
- Live updates, a refresh every 20 seconds while the app is on screen, and a catch-up after the app comes back.
- Changes wait on the phone until the server has them, and are sent again after a lost connection. A change the server refuses is dropped and the data reloads.
- Times use the server clock. The Dashboard shows row counts for now, to check the data against the website.

## 31 Oct 2026 – Native app, phase 1

- Started the native Flutter admin app that will replace the WebView. It uses the same Supabase project, tables and rules as the website.
- Added `docs/feature-checklist.md`: every behaviour of the web admin, to be ticked off as each screen is built.
- New folder structure: `app` (app, router, theme), `core`, `data` and one folder per feature.
- Riverpod for state, go_router for navigation.
- Light and dark themes with the web admin's colours and font; dark mode is remembered.
- Login, splash and the floating tab bar are the same as before. The tabs open native screens, which are placeholders for now.
- Settings has dark mode and sign out until the real screens are built.

## 31 Oct 2026 – Blocking and repeated messages

- A customer is now blocked on the cancel that reaches the limit (the 3rd by default), so they can't create another order first. The setting now reads "Block after this many cancels in a day".
- When a cancel blocks the customer, their cancel message and the "order cancelled" reply are saved, the chat goes back to the menu, and the admin gets a "Customer blocked" notification with the reason.
- The server no longer saves the same bot message to the same customer twice within 60 seconds, for example the welcome message when a chat opens in two tabs.

## 30 Oct 2026 – Unpaid orders expire on the server

- Unpaid orders now expire on the server, every minute, from the order's real status. Phones and the panel no longer decide this, so an old copy on a device can't cancel a paid order or send a wrong "time ran out" message.
- The server refuses to expire any order that isn't unpaid, even from an admin.
- A customer who is sending proof when the timer ends still has the same 2 minutes for it to arrive, so the message can come up to about 3 minutes after the timer.

## 30 Oct 2026 – Screenshot upload on Android

- On Android the customer's screenshot button now opens the normal file chooser instead of the system Photo Picker, which could return without giving the page the picture.
- If the customer comes back from the picker and no picture arrives, a clear message appears instead of nothing.
- New Choose from Files link for pictures up to 1 MB, as a second way to add the screenshot.
- If both ways fail, the message asks the customer to update Chrome.

## 30 Oct 2026 – Keyboard and faster panel

- Typing no longer stutters: the panel resizes once, after the keyboard has opened, instead of on every frame of the keyboard animation, and the panel uses the WebView mode that handles typing better on Android.
- The admin panel (app and website) opens with the last two days of chat and loads older messages in the background, so it opens in seconds instead of 20–30.
- The saved copy of the panel stays small, and a copy that cannot be saved is removed, so a refresh never shows old or half data (like 850 of 950 customers).

## 29 Oct 2026 – Smoother app and full pop-ups

- The tab bar no longer blurs the panel behind it. The blur was redrawing the whole panel on every frame, which made scrolling and tab changes stutter; it now uses the same dark see-through colour without the blur.
- The selected-tab pill slides with a transform, so it moves smoothly.
- The tab bar is smaller and centred, with icons and names closer together.
- Pop-ups (Approve, Reject and others) open over the whole screen instead of inside the list, so they are never cut off, and the Approve box fits above the keyboard with its buttons in view.

## 29 Oct 2026 – Quick start, new tab icons and dark status bar

- Splash without animation: the logo and PREMIUM STORE show for under a second, then the panel.
- Tab bar icons like the client's sample: home, person, chat bubble and gear, named Dashboard, Inbox, Bot and Settings; the selected tab is orange.
- The phone's status bar and bottom bar follow the panel's theme, dark in dark mode.
- Pending is now pink everywhere (card line, chip dot, picture ring, dashboard dot).
- Completed and Unused cards show the code right next to the plan.
- The Premium Store pill on the dashboard is only as wide as its text.
- Smoother switches and lists: switches slide with transforms, lists scroll without bouncing the page.

## 29 Oct 2026 – Issue shortcuts and calmer pop-ups

- New support issue notifications have two buttons: Resolved (closes it and tells the customer) and Reply (type the answer in the notification).
- No phone pop-up while the app is open; the panel's own counts are enough, like the website.
- Notifications and the Approve box show the customer's WhatsApp number instead of the email.
- The tab bar hides while a pop-up (Approve, Reject and others) is open, and the pop-up no longer jumps when the keyboard opens.
- Round back button on the customer chat in Inbox and Bot chat, like the settings pages.

## 29 Oct 2026 – Approve from the notification

- A new payment notification has three buttons: Approve, Reject and Cancel order.
- Approve opens a text box in the notification: paste the code message and send. The app finds the code (same rules as the panel) and the server approves the order and sends the code to the customer, even when the app is closed. If no code is found or the code was already sent, the notification says so and can be tried again.
- Reject opens the app straight on that order's reject box with all the reasons.
- Cancel order cancels it from the notification and tells the customer.
- The notification then changes to show what happened.

## 29 Oct 2026 – Swipe between tabs and no black screen

- No black screen after the splash: the panel starts loading behind the splash, and the splash fades into it.
- Swipe through the whole app: Dashboard → Inbox categories → Bot chat categories → Settings, and back the other way.
- Completed and Unused cards no longer repeat the date; it stays in the top right corner.
- Customer list: the number has its own full line, with Chat and Block below it, so it is never cut off.

## 29 Oct 2026 – Cleaner cards and WhatsApp links

- Inbox cards show only what each category needs: the date sits at the far right, and name, plan, price and method share one line.
- A coloured dot next to every Inbox category, like Bot chat.
- Long lists open fast: 30 cards first, more as you scroll.
- No more jump when tapping Approve; the pop-up sits higher and a swipe inside it no longer changes the category.
- Lighter, less bold text across the panel.
- Customer list rows: photo, then ID and number on one line, email and last active below.
- Customer details: photo on the left, ID, number, email and "customer since" on the right.
- Dashboard shows only the status (Active) under Premium Store.
- The colour preview was removed from Appearance.
- Tapping a WhatsApp number in the panel now opens WhatsApp.

## 29 Oct 2026 – Glass tab bar and swipe

- New glass tab bar: see-through dark glass with a soft border; every tab shows its icon and name, and a light pill slides to the selected tab, which turns gold.
- The tab bar shows only on the four main screens. It slides away inside a customer chat, a settings page, the customer list and search, and comes back on the way out.
- Bot chat categories now look like the Inbox chips and come in this order: Active chats, Active orders, Cancelled, Inactive.
- Swipe left or right on the Inbox or Bot chat list to move to the next or previous category.
- Customer numbers on the Inbox and Bot chat cards always show in full.
- Text in the panel no longer grows with the phone's font size setting, so nothing gets cut off.
- Smoother search and header animations.
- The app asks to run in the background (battery optimisation off) so notifications keep coming.

## 29 Oct 2026 – Signal, customers and dark mode

- Network signal button next to search on every tab (Dashboard, Inbox, Bot chat, Settings, Customers): five bars like WiFi, coloured from green to red, and a red mark with no internet. It checks the store server every 10 seconds; a tap shows the speed.
- The dashboard top no longer has the theme button or the admin photo (dark mode stays in Settings).
- New customer list in the panel: All, Active now and Blocked chips like the Inbox, and a list with the WhatsApp number, email, ID and last active, plus Chat and Block or Unblock. Only the list scrolls.
- Dark mode colours fixed where things were hard to see: switches, selected buttons, min/hr, chart bar, small badges, colour swatches and the arrow on the payments card.

## 28 Oct 2026 – New look (light luxury)

- Animated splash: the P logo grows in with a gold glow, a gold line opens, PREMIUM STORE is typed letter by letter, then ADMIN fades in (about 3 seconds).
- Floating navy tab bar at the bottom: the selected tab grows into a white pill with its name; Material rounded icons.
- The app's own header is gone: the panel shows the new header (logo, theme, search, admin with status dot) and the new one-screen dashboard (website, app mode).
- Light status bar and a light loading screen with the logo.
- Sign out moved to the panel's Settings, and the app asks before signing out.
- New Inbox and Bot chat screens in the panel: category chips or tiles, compact cards with their own buttons, a tap on the picture opens the chat.
- New Settings screen in the panel: profile photo and name at the top, every settings section as its own card that opens on its own screen.
- Every settings section rebuilt for the phone: short groups, long messages open in their own editor with tap-to-add placeholders, steppers for timers, a colour preview, and the Save bar only when something changed.
- New tab bar icons drawn in the app: two-tone outlines with a soft gold fill. The Inbox tab shows a red count of payments and app issues waiting.
- Search in the panel opens with an animation: the button grows into a full search bar with a gold ring.
- The admin's profile photo now shows on the dashboard too.
- Push notifications (Android, Firebase): the app asks for permission and saves the phone to Supabase after sign-in. New payments, payment problems and support requests arrive as notifications even when the app is closed; a tap opens that customer's chat in the right Inbox tab. Signing out removes the phone.
- The panel can now pick a photo from the camera or the gallery (used for the profile photo).

## 27 Oct 2026 – Look and Back button

- Header and bottom tabs in the brand navy; the selected tab is gold. The status bar is navy too.
- Tab icons from Lucide, the same icon set as the website.
- The app opens on the Dashboard tab.
- A navy loading screen with the logo shows until the panel has loaded.
- The phone's Back button and back gesture now go back one step at a time inside the panel (close a chat, a pop-up or the details), then to the Dashboard tab, and only then close the app.

**Next:** choosing images in the panel, no internet screen.

## 27 Oct 2026 – Admin panel in the tabs

- One WebView shows the admin panel (website) inside the app, so all features come from the website.
- The panel opens in app mode (`?app=1`): the website hides its own side menu, and the app's tabs pick the part shown (Inbox, Bot chat, Dashboard, Settings).
- When the panel moves to another part by itself (for example Dashboard → Review), the app's tab follows.
- The email and password typed in the app also sign the panel in, so the admin signs in once.
- Sign out also clears the panel's saved sign-in.

**Next:** back button, no internet screen, choosing images in the panel.

## 27 Oct 2026 – Header and tabs

- WhatsApp style header: app name on the left, menu on the right with the signed-in email and Sign out (asks to confirm).
- Bottom tabs: Inbox, Bot chat, Dashboard, Settings, with filled icons on the selected tab.
- Each tab keeps its place when switching (a placeholder for now).

**Next:** show the admin panel inside each tab.

## 25 Oct 2026 – Sign in

- Admin sign in screen after the splash: email, password with show/hide, and a Forgot password link that opens the website.
- Connected to Supabase (test project for now).
- Only admin accounts can sign in; other accounts get "This account does not have admin access."
- Stays signed in after closing the app. Sign out button on the home screen.

**Next:** bottom tabs (Inbox, Bot chat, Dashboard, Settings).

## 25 Oct 2026 – Project setup

- Created the Flutter project for Android and iOS (package `online.premiumstore.premium_store_admin`).
- App name on the phone: **Premium Store**.
- App icon: the "P" logo from the website, with an adaptive icon for Android.
- Folder structure: `core` for shared code (constants, theme) and `features` for screens.
- Home screen with the logo and app name.
- Website colours added to the app theme.
- Splash screen: navy background with the logo, the same as the home screen (no more black screen on open).

**Next:** open the admin panel inside the app.
