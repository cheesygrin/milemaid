/// Centralized app strings for consistency and easy localization later.
class AppStrings {
  AppStrings._();

  static const String appName = 'MileMaid';
  static const String appTagline = 'Automatic Mileage Tracking';

  // Onboarding
  static const String onboardingTitle1 = 'Drive. We track.';
  static const String onboardingSubtitle1 =
      'MileMaid automatically logs every drive in the background. No buttons. No hassle.';
  static const String onboardingTitle2 = 'See what your miles are worth';
  static const String onboardingSubtitle2 =
      'Swipe to classify each drive and watch your deduction estimate grow. Tax-ready PDF and CSV reports come with MileMaid Pro.';
  static const String onboardingTitle3 = 'Private by default';
  static const String onboardingSubtitle3 =
      'Your drives stay on this iPhone. No account, no ads, and we never sell your data. MileMaid is open source, so anyone can check.';
  static const String onboardingTitle4 = 'You\'re all set!';
  static const String onboardingSubtitle4 =
      'Grant location permissions and we\'ll start tracking your miles safely and accurately.';

  // Permissions
  static const String permissionTitle = 'Location Access Needed';
  static const String permissionMessage =
      'MileMaid uses location in the background to automatically detect and log your drives for accurate mileage tracking and tax records.\n\n'
      'On iPhone, tap "While Using the App" first. If you don\'t see "Always" yet, we\'ll show you how to turn it on in Settings (required for drives with the screen off).';
  static const String locationPermission = 'Location Permission';

  // Dashboard
  static const String businessMilesThisMonth = 'Business Miles This Month';
  static const String deductionEstimate = 'Estimated deduction';
  static const String totalMiles = 'Total Miles';
  static const String personalMiles = 'Personal Miles';
  static const String tripsLogged = 'Trips Logged';

  // Classification (MileIQ-style)
  static const String classifyDrives = 'Classify drives';
  static const String classifySwipeHint = 'Swipe right for Business, left for Personal';
  static const String classifyFilter = 'Needs review';
  static String classifySeeMore(int count) => 'View $count more to classify';
  static String classifiedAs(String category) => 'Marked as $category';

  // Trips
  static const String trips = 'Trips';
  static const String noTripsYet = 'No trips yet';
  static const String noTripsSubtitle = 'Drive around and your trips will appear here automatically.';
  static const String searchTripsHint = 'Search trips...';

  // Trip detail
  static const String tripDetail = 'Trip Details';
  static const String editPurposeHint = 'e.g. Client meeting at HQ';
  static const String notesHint = 'Additional notes...';
  static const String markAsBusiness = 'Mark as Business';
  static const String duplicateReturn = 'Duplicate as Return Trip';

  // Reports
  static const String reports = 'Reports';
  static const String exportPDF = 'Export PDF';
  static const String exportCSV = 'Export CSV';
  static const String dateRange = 'Date Range';

  // Settings
  static const String settings = 'Settings';
  static const String vehicles = 'Vehicles';
  static const String mileageRate = 'Mileage Rate';
  static const String irsRateNote = 'IRS standard rate, by trip date';
  static const String trackingSensitivity = 'Tracking Sensitivity';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy';
  static const String exportData = 'Export All Data';
  static const String deleteAllData = 'Delete All Data';
  static const String loadSampleData = 'Load Sample Trips';
  static const String loadSampleDataSubtitle =
      'Adds demo drives for testing the dashboard, trips list, and reports';

  // Tracking
  static const String trackingActive = 'Tracking active';
  static const String tripInProgress = 'Trip in progress';
  static const String tripEndedNotificationTitle = 'Drive detected';
  static const String tripEndedNotificationBody = '%s mi drive detected. Tap to classify.';

  // Misc
  static const String cancel = 'Cancel';
  static const String undo = 'Undo';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String done = 'Done';
  static const String business = 'Business';
  static const String personal = 'Personal';
  static const String commute = 'Commute';
  static const String other = 'Other';

  static const String milesUnit = 'mi';
  static const String minutesUnit = 'min';

  // MileMaid Pro. Prices are never written here: the paywall shows what the
  // App Store returns.
  static const String proName = 'MileMaid Pro';
  static const String proHeadline = 'Tax-ready reports and private cloud sync';
  static const String proSubhead =
      'Tracking and classifying your drives is free for as long as you like. Pro adds the paperwork and the backup.';
  static const List<(String, String)> proFeatures = [
    (
      'PDF mileage reports',
      'A clean multi-page log with totals, your deduction estimate and every trip, ready for your accountant.',
    ),
    (
      'CSV export',
      'Every drive as a spreadsheet row for your own records or bookkeeping software.',
    ),
    (
      'Cloud sync',
      'Drives, places, vehicles and purposes saved to your account and restored on a new phone.',
    ),
  ];
  static const String freeForever =
      'Always free: unlimited automatic tracking, swipe to classify, full trip history and your running deduction estimate. '
      'No account needed, no ads, and the code is open source.';
  static const String subscriptionTerms =
      'Payment is charged to your Apple ID when you confirm. The subscription renews automatically at the same price '
      'unless it is cancelled at least 24 hours before the current period ends. Manage or cancel any time in your App Store account settings.';
  static const String proActive = 'MileMaid Pro is active';
  static const String proWelcome = 'MileMaid Pro is active. Reports and cloud sync are unlocked.';
  static const String proRequiredForExports = 'PDF and CSV exports are part of MileMaid Pro.';
  static const String proRequiredForSync = 'Cloud sync is part of MileMaid Pro.';
  static const String manageSubscription = 'Manage subscription';
}
