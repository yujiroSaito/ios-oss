import CoreTelephony
import KsApi
import PassKit
import Prelude
import UIKit

private let deprecatedProps = [Koala.DeprecatedKey: true]

public final class Koala {
  internal static let DeprecatedKey = "DEPRECATED"

  private let bundle: NSBundleType
  private let dataLakeClient: TrackingClientType
  private let koalaClient: TrackingClientType
  internal private(set) var config: Config?
  private let device: UIDeviceType
  private let distinctId: String
  internal private(set) var loggedInUser: User?
  public var logEventCallback: ((String, [String: Any]) -> Void)?
  private var preferredContentSizeCategory: UIContentSizeCategory?
  private var preferredContentSizeCategoryObserver: Any?
  private let screen: UIScreenType

  private enum DataLakeWhiteListedEvent: String, CaseIterable {
    case explorePageViewed = "Explore Page Viewed"
    case exploreSortClicked = "Explore Sort Clicked"
    case activityFeedViewed = "Activity Feed Viewed"
    case editorialCardClicked = "Editorial Card Clicked"
    case collectionViewed = "Collection Viewed"
    case filterClicked = "Filter Clicked"
    case tabBarClicked = "Tab Bar Clicked"
    case searchPageViewed = "Search Page Viewed"
    case searchResultsLoaded = "Search Results Loaded"
    case projectSwiped = "Project Swiped"
    case projectPageViewed = "Project Page Viewed"

    static func allWhiteListedEvents() -> [String] {
      return DataLakeWhiteListedEvent.allCases.map { $0.rawValue }
    }
  }

  /// Determines the authentication type for login or signup events.
  public enum AuthType {
    case email
    case facebook

    var trackingString: String {
      switch self {
      case .email: return "Email"
      case .facebook: return "Facebook"
      }
    }
  }

  /**
   Determines the place from which the external link was presented.

   - projectCreator: The creator profile, usually seen by pressing the creator's name on the project page.
   - projectDescription: The project description page.
   - projectUpdates: The project updates page.

   **/
  public enum ExternalLinkContext {
    case projectCreator
    case projectDescription
    case projectUpdate
    case projectUpdates

    var trackingString: String {
      switch self {
      case .projectCreator:
        return "project_creator"
      case .projectDescription:
        return "project_description"
      case .projectUpdate:
        return "project_update"
      case .projectUpdates:
        return "project_updates"
      }
    }
  }

  /**
   Determines the place from which the message dialog was presented.

   - backerModal:     The backing view, usually seen by pressing "View pledge" on the project page.
   - creatorActivity: The creator's activity feed.
   - messages:        The messages inbox.
   - projectMessages: The messages inbox for a particular project of a creator's.
   - projectPage:     The project page.
   */
  public enum MessageDialogContext: String, Equatable {
    case backerModal = "backer_modal"
    case creatorActivity = "creator_activity"
    case messages
    case projectMessages = "project_messages"
    case projectPage = "project_page"
  }

  /**
   Determines the place from which the comments dialog was presented.

   - projectActivity: The creator's project activity screen.
   - projectComments: The comments screen for a project.
   - updateComments:  The comments screen for an update.
   */
  public enum CommentDialogContext {
    case projectActivity
    case projectComments
    case updateComments

    var trackingString: String {
      switch self {
      case .projectActivity: return "project_activity"
      case .projectComments: return "project_comments"
      case .updateComments: return "update_comments"
      }
    }
  }

  /**
   Determines the type of comment in which the dialog was presented for.

   - project: A project comment.
   - update: An update comment.
   */
  public enum CommentDialogType {
    case project
    case update

    var trackingString: String {
      switch self {
      case .project: return "project"
      case .update: return "update"
      }
    }
  }

  /**
   Determines the place from which the comments were presented.

   - project: The comments for a project.
   - update: The comments for an update.
   */
  public enum CommentsContext {
    case project
    case update

    var trackingString: String {
      switch self {
      case .project: return "project"
      case .update: return "update"
      }
    }
  }

  /// Determines which gesture was used.
  public enum GestureType: String {
    case swipe
    case tap

    fileprivate var trackingString: String {
      switch self {
      case .swipe: return "swipe"
      case .tap: return "tap"
      }
    }
  }

  /// Determines which swipe was used.
  public enum SwipeType: String {
    case next
    case previous

    fileprivate var trackingString: String {
      switch self {
      case .next: return "next"
      case .previous: return "previous"
      }
    }
  }

  /// Determines the place from which the project was saved.
  public enum SaveContext: String {
    case discovery
    case project

    fileprivate var trackingString: String {
      return self.rawValue
    }
  }

  /**
   Determines the place from which the newsletter toggle was presented.

   - facebook: The Facebook confirmation signup screen.
   - settings: The settings screen.
   - signup: The signup screen.
   - thanks: The thanks page games modal.
   */
  public enum NewsletterContext {
    case facebookSignup
    case settings
    case signup
    case thanks

    var trackingString: String {
      switch self {
      case .facebookSignup: return "facebook_signup"
      case .settings: return "settings"
      case .signup: return "signup"
      case .thanks: return "thanks"
      }
    }
  }

  /**
   Describes a flow of pledging.

   - changeReward: changing your current reward to a different reward
   - manageReward: changing the details of the current reward you are backing (e.g. amount, shipping)
   - newPledge:    pledging to the project without an existing backing
   */
  public enum PledgeContext {
    case changeReward
    case manageReward
    case newPledge

    var trackingString: String {
      switch self {
      case .changeReward: return "change_reward"
      case .manageReward: return "manage_reward"
      case .newPledge: return "new_pledge"
      }
    }
  }

  public enum ManagePledgeMenuCTAType {
    case cancelPledge
    case changePaymentMethod
    case chooseAnotherReward
    case contactCreator
    case updatePledge
    case viewRewards

    var trackingString: String {
      switch self {
      case .cancelPledge: return "cancel_pledge"
      case .changePaymentMethod: return "change_payment_method"
      case .chooseAnotherReward: return "choose_another_reward"
      case .contactCreator: return "contact_creator"
      case .updatePledge: return "update_pledge"
      case .viewRewards: return "view_rewards"
      }
    }
  }

  /**
   Describes the buttons the user can click on in the reward pledge screen.

   - applePay:            The user clicked the apple pay button.
   - cancel:              The user clicked the cancel pledge button.
   - changePaymentMethod: The user clicked the change payment method button.
   - paymentMethods:      The user clicked the payment methods button.
   - updatePledge:        The user clicked the update pledge button.
   */
  public enum ClickedRewardPledgeButtonType {
    case applePay
    case cancel
    case changePaymentMethod
    case paymentMethods
    case updatePledge

    fileprivate var trackingString: String {
      switch self {
      case .applePay: return "apple_pay"
      case .cancel: return "cancel"
      case .changePaymentMethod: return "change_payment_method"
      case .paymentMethods: return "payment_methods"
      case .updatePledge: return "update_pledge"
      }
    }
  }

  /**
   Describes the types of errors that can occur when trying to click a reward pledge button.

   - maximumAmount: A pledge amount was entered that is greater than what the project can handle.
   - minimumAmount: A pledge amount was entered that is less than the minimum the project requires.
   */
  public enum ErroredRewardPledgeButtonClickType {
    case maximumAmount
    case minimumAmount

    fileprivate var trackingString: String {
      switch self {
      case .maximumAmount: return "MAXIMUM_AMOUNT"
      case .minimumAmount: return "MINIMUM_AMOUNT"
      }
    }
  }

  /**
   Describes the types of payment methods that can be used.
   */
  public enum PaymentMethod {
    case applePay

    fileprivate var trackingString: String {
      switch self {
      case .applePay: return "apple_pay"
      }
    }
  }

  /**
   Describes the pages where checkout events can occur.
   */
  public enum CheckoutPageContext {
    case paymentsPage
    case projectPage
    case rewardSelection

    fileprivate var trackingString: String {
      switch self {
      case .paymentsPage: return "Payments Page"
      case .projectPage: return "Project Page"
      case .rewardSelection: return "Reward Selection"
      }
    }
  }

  public enum CheckoutContext {
    case backThisPage
    case projectPage

    var trackingString: String {
      switch self {
      case .backThisPage: return "Back this page"
      case .projectPage: return "Project page"
      }
    }
  }

  /**
   Determines the place from which the update was presented.

   - activity:        The activity feed.
   - activitySample:  The activity sample in Discovery.
   - creatorActivity: The creator's activity feed.
   - deepLink:        A deep link, including push notification.
   - draftPreview:    The update draft editor.
   - updates:         The updates index.
   */
  public enum UpdateContext {
    case activity
    case activitySample
    case creatorActivity
    case deepLink
    case draftPreview
    case updates

    fileprivate var trackingString: String {
      switch self {
      case .activity: return "activity"
      case .activitySample: return "activity_sample"
      case .creatorActivity: return "creator_activity"
      case .deepLink: return "deep_link"
      case .draftPreview: return "draft_preview"
      case .updates: return "updates"
      }
    }
  }

  public enum TabBarItemLabel: String {
    case discovery
    case activity
    case search
    case dashboard
    case profile

    var trackingString: String {
      return self.rawValue
    }
  }

  public init(
    bundle: NSBundleType = Bundle.main,
    dataLakeClient: TrackingClientType = TrackingClient(.dataLake),
    client: TrackingClientType = TrackingClient(.koala),
    config: Config? = nil,
    device: UIDeviceType = UIDevice.current,
    loggedInUser: User? = nil,
    screen: UIScreenType = UIScreen.main,
    distinctId: String = (UIDevice.current.identifierForVendor ?? UUID()).uuidString
  ) {
    self.bundle = bundle
    self.dataLakeClient = dataLakeClient
    self.koalaClient = client
    self.config = config
    self.device = device
    self.loggedInUser = loggedInUser
    self.screen = screen
    self.distinctId = distinctId

    self.updateAndObservePreferredContentSizeCategory()
  }

  private func updateAndObservePreferredContentSizeCategory() {
    let update = { [weak self] in
      self?.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }

    self.preferredContentSizeCategoryObserver = NotificationCenter.default.addObserver(
      forName: UIContentSizeCategory.didChangeNotification,
      object: nil,
      queue: OperationQueue.main
    ) { _ in update() }

    if Thread.isMainThread {
      update()
    } else {
      DispatchQueue.main.async {
        update()
      }
    }
  }

  deinit {
    self.preferredContentSizeCategoryObserver.doIfSome(NotificationCenter.default.removeObserver)
  }

  // MARK: - Activity

  /// Call when the activities screen is shown.
  public func trackActivities(count: Int) {
    self.track(
      event: DataLakeWhiteListedEvent.activityFeedViewed.rawValue,
      properties: ["activities_count": count]
    )
  }

  // MARK: - Application Lifecycle

  /// Call when the app launches or enters foreground.
  public func trackAppOpen() {
    let props: [String: Any] = [
      "badge_count": UIApplication.shared.applicationIconBadgeNumber
    ]

    self.track(event: "App Open", properties: props.withAllValuesFrom(deprecatedProps))
    self.track(event: "Opened App")
  }

  /// Call when the app enters the background.
  public func trackAppClose() {
    self.track(event: "App Close", properties: deprecatedProps)
    self.track(event: "Closed App")
  }

  public func trackMemoryWarning() {
    self.track(event: "App Memory Warning")
  }

  public func trackCrashedApp() {
    self.track(event: "Crashed App")
  }

  public func trackNotificationOpened() {
    let props: [String: Any] = [
      "notification_type": "push"
    ]

    self.track(
      event: "Notification Opened",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Opened Notification", properties: props)
  }

  public func trackOpenedAppBanner(_ queryParams: [String: String]) {
    let props: [String: Any] = queryParams

    self.track(
      event: "Smart App Banner Opened",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Opened App Banner", properties: props)
  }

  public func trackUserActivity(_ userActivity: NSUserActivity) {
    let props = properties(userActivity: userActivity)

    self.track(
      event: "Continue User Activity",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Opened Deep Link", properties: props)
  }

  public func trackTabBarClicked(_ tabBarItemLabel: TabBarItemLabel) {
    let label = tabBarItemLabel.trackingString

    self.track(
      event: DataLakeWhiteListedEvent.tabBarClicked.rawValue,
      properties: ["tab_bar_label": label]
    )
  }

  // MARK: - Discovery Events

  /**
   Call when a discovery page is viewed and the first page is loaded.

   - parameter params: The params used for the discovery search.
   */

  public func trackDiscovery(params: DiscoveryParams) {
    let props = discoveryProperties(from: params)

    self.track(event: DataLakeWhiteListedEvent.explorePageViewed.rawValue, properties: props)
  }

  /**
   Call when a filter is selected from the Explore modal.

   - parameter params: The params selected from the modal.
   */
  public func trackDiscoveryModalSelectedFilter(params: DiscoveryParams) {
    self.track(
      event: DataLakeWhiteListedEvent.filterClicked.rawValue,
      properties: discoveryProperties(from: params)
    )
  }

  /**
   Call when the user swipes between sorts or selects a sort.

   - parameter sort: The new sort that was selected.
   */
  public func trackDiscoverySelectedSort(nextSort sort: DiscoveryParams.Sort, params: DiscoveryParams) {
    let props = discoveryProperties(from: params)
      .withAllValuesFrom([
        "discover_sort": sort.rawValue
      ])

    self.track(event: DataLakeWhiteListedEvent.exploreSortClicked.rawValue, properties: props)
  }

  /**
   Call when the user taps the editorial header at the top of Discovery
   */
  public func trackEditorialHeaderTapped(refTag: RefTag) {
    self.track(
      event: DataLakeWhiteListedEvent.editorialCardClicked.rawValue,
      properties: [:], refTag: refTag.stringTag
    )
  }

  /**
   Call when a collection is viewed

   - parameter params: The DiscoveryParams associated with the collection
   */
  public func trackCollectionViewed(params: DiscoveryParams) {
    self.track(
      event: DataLakeWhiteListedEvent.collectionViewed.rawValue,
      properties: discoveryProperties(from: params)
    )
  }

  // MARK: - Checkout Events

  public func trackPledgeCTAButtonClicked(
    stateType: PledgeStateCTAType,
    project: Project, screen: CheckoutContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["screen": screen.trackingString])

    switch stateType {
    case .fix:
      self.track(event: "Fix Pledge Button Clicked", properties: props)
    case .pledge:
      self.track(event: "Back this Project Button Clicked", properties: props)
    case .manage:
      self.track(event: "Manage Pledge Button Clicked", properties: props)
    case .seeRewards:
      self.track(event: "See Rewards Button Clicked", properties: props)
    case .viewBacking:
      self.track(event: "View Your Pledge Button Clicked", properties: props)
    case .viewRewards:
      self.track(event: "View Rewards Button Clicked", properties: props)
    case .viewYourRewards:
      self.track(event: "View Your Rewards Button Clicked", properties: props)
    }
  }

  public func trackCancelPledgeButtonClicked(project: Project, backing: Backing) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["pledge_total": backing.amount])

    self.track(event: "Cancel Pledge Button Clicked", properties: props)
  }

  public func trackUpdatePaymentMethodButton(project: Project, pledgeAmount: Double) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["pledge_total": pledgeAmount])

    self.track(event: "Update Payment Method Button Clicked", properties: props)
  }

  public func trackUpdatePledgeButtonClicked(project: Project, pledgeAmount: Double) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["pledge_total": pledgeAmount])

    self.track(event: "Update Pledge Button Clicked", properties: props)
  }

  public func trackManagePledgeOptionClicked(project: Project, managePledgeMenuCTA: ManagePledgeMenuCTAType) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["cta": managePledgeMenuCTA.trackingString])

    self.track(event: "Manage Pledge Option Clicked", properties: props)
  }

  public func trackSelectRewardButtonClicked(
    project: Project,
    reward: Reward?,
    backing: Backing?,
    screen: CheckoutContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom([
        "screen": screen.trackingString,
        "backer_reward_minimum": reward?.minimum as Any,
        "pledge_total": backing?.amount as Any
      ])

    self.track(event: "Select Reward Button Clicked", properties: props)
  }

  public func trackPledgeScreenViewed(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Pledge Screen Viewed", properties: props)
  }

  public func trackPledgeButtonClicked(project: Project, pledgeAmount: Double) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["pledge_total": pledgeAmount])

    self.track(event: "Pledge Button Clicked", properties: props)
  }

  public func trackAddNewCardButtonClicked(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Add New Card Button Clicked", properties: props)
  }

  public func trackCheckoutCancel(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Checkout Cancel", properties: props.withAllValuesFrom(deprecatedProps))
    self.track(event: "Canceled Checkout", properties: props)
  }

  public func trackClickedRewardPledgeButton(
    project: Project,
    reward: Reward,
    buttonType: ClickedRewardPledgeButtonType,
    pageContext: CheckoutPageContext,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom([
        "pledge_context": pledgeContext.trackingString,
        "type": buttonType.trackingString,
        "context": pageContext.trackingString
      ])

    self.track(event: "Clicked Reward Pledge Button", properties: props)
  }

  public func trackClickedRewardPledgeButton(
    project: Project,
    reward: Reward,
    errorText: String,
    errorType: ErroredRewardPledgeButtonClickType,
    paymentMethod: PaymentMethod?,
    pageContext: CheckoutPageContext,
    pledgeContext: PledgeContext
  ) {
    var extraProps = [
      "error_text": errorText,
      "type": errorType.trackingString,
      "pledge_context": pledgeContext.trackingString,
      "context": pageContext.trackingString
    ]
    extraProps["payment_method"] = paymentMethod?.trackingString

    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(extraProps)

    self.track(event: "Errored Reward Pledge Button Click", properties: props)
  }

  public func trackChangedPledgeAmount(_ project: Project, reward: Reward, pledgeContext: PledgeContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Checkout Amount Changed", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Changed Pledge Amount", properties: props)
  }

  public func trackSelectedShippingDestination(
    _ project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Checkout Location Changed", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Selected Shipping Destination", properties: props)
  }

  public func trackSelectedReward(project: Project, reward: Reward, pledgeContext: PledgeContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Reward Checkout", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Selected Reward", properties: props)
  }

  public func trackClosedReward(project: Project, reward: Reward, pledgeContext: PledgeContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Closed Reward", properties: props)
  }

  // MARK: - Login Events

  public func trackLoginTout(intent: LoginIntent) {
    // Deprecated event
    self.track(
      event: "Application Login or Signup",
      properties: [
        "intent": intent.trackingString,
        "context": intent.trackingString,
        Koala.DeprecatedKey: true
      ]
    )

    self.track(
      event: "Viewed Login Signup",
      properties: ["intent": intent.trackingString, "context": intent.trackingString]
    )
  }

  public func trackLoginFormView() {
    self.track(
      event: "User Login",
      properties: [
        Koala.DeprecatedKey: true
      ]
    )
    self.track(event: "Viewed Login")
  }

  public func trackLoginSuccess(authType: AuthType) {
    // Deprecated event
    self.track(event: "Login", properties: deprecatedProps)

    self.track(event: "Logged In", properties: ["auth_type": authType.trackingString])
  }

  public func trackLoginError(authType: AuthType) {
    // Deprecated event
    self.track(event: "Errored User Login", properties: deprecatedProps)

    self.track(event: "Errored Login", properties: ["auth_type": authType.trackingString])
  }

  public func trackResetPassword() {
    // Deprecated event
    self.track(event: "Forgot Password View", properties: deprecatedProps)

    self.track(event: "Viewed Forgot Password")
  }

  public func trackResetPasswordSuccess() {
    // Deprecated event
    self.track(event: "Forgot Password Requested", properties: deprecatedProps)

    self.track(event: "Requested Password Reset")
  }

  public func trackResetPasswordError() {
    // Deprecated event
    self.track(event: "Forgot Password Errored", properties: deprecatedProps)

    self.track(event: "Errored Forgot Password")
  }

  public func trackFacebookConfirmation() {
    // Deprecated event
    self.track(event: "Facebook Confirm", properties: deprecatedProps)

    self.track(event: "Viewed Facebook Signup")
  }

  public func trackTfa() {
    // Deprecated event
    self.track(event: "Two-factor Authentication Confirm View", properties: deprecatedProps)

    self.track(event: "Viewed Two-Factor Confirmation")
  }

  public func trackTfaResendCode() {
    // Deprecated event
    self.track(event: "Two-factor Authentication Resend Code", properties: deprecatedProps)

    self.track(event: "Resent Two-Factor Code")
  }

  // MARK: - Signup

  // Call when an error is returned after attempting to signup.
  public func trackSignupError(authType: AuthType) {
    // Deprecated event
    self.track(event: "Errored User Signup", properties: deprecatedProps)

    self.track(event: "Errored Signup", properties: ["auth_type": authType.trackingString])
  }

  // Call when the user has successfully signed up for a new account.
  public func trackSignupSuccess(authType: AuthType) {
    // Deprecated event
    self.track(event: "New User", properties: deprecatedProps)

    self.track(event: "Signed Up", properties: ["auth_type": authType.trackingString])
  }

  // Call once when the signup view loads.
  public func trackSignupView() {
    // Deprecated event
    self.track(event: "User Signup", properties: deprecatedProps)

    self.track(event: "Viewed Signup")
  }

  // MARK: - Comments Events

  public func trackLoadNewerComments(project: Project, update: Update?, context: CommentsContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(["context": context.trackingString])

    // Deprecated events
    switch context {
    case .project:
      self.track(event: "Project Comment Load New", properties: props.withAllValuesFrom(deprecatedProps))
    case .update:
      self.track(event: "Update Comment Load New", properties: props.withAllValuesFrom(deprecatedProps))
    }

    self.track(event: "Loaded Newer Comments", properties: props)
  }

  public func trackLoadOlderComments(
    project: Project,
    update: Update?,
    page: Int,
    context: CommentsContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(["page_count": page, "context": context.trackingString])

    // Deprecated events
    switch context {
    case .project:
      self.track(event: "Project Comment Load Older", properties: props.withAllValuesFrom(deprecatedProps))
    case .update:
      self.track(event: "Update Comment Load Older", properties: props.withAllValuesFrom(deprecatedProps))
    }

    self.track(event: "Loaded Older Comments", properties: props)
  }

  public func trackOpenedCommentEditor(
    project: Project,
    update: Update?,
    context: CommentDialogContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(
        [
          "context": context.trackingString,
          "type": update == nil
            ? CommentDialogType.project.trackingString : CommentDialogType.update.trackingString
        ]
      )

    self.track(event: "Opened Comment Editor", properties: props)
  }

  public func trackCanceledCommentEditor(
    project: Project,
    update: Update?,
    context: CommentDialogContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(
        [
          "context": context.trackingString,
          "type": update == nil
            ? CommentDialogType.project.trackingString : CommentDialogType.update.trackingString
        ]
      )

    self.track(event: "Canceled Comment Editor", properties: props)
  }

  public func trackPostedComment(
    project: Project,
    update: Update?,
    context: CommentDialogContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(
        [
          "context": context.trackingString,
          "type": update == nil
            ? CommentDialogType.project.trackingString : CommentDialogType.update.trackingString
        ]
      )

    self.track(event: "Posted Comment", properties: props)
  }

  public func trackCommentCreate(comment: Comment, project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(comment: comment))
      .withAllValuesFrom(deprecatedProps)

    self.track(event: "Project Comment Create", properties: props)
  }

  public func trackCommentCreate(comment: Comment, update: Update, project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(update: update))
      .withAllValuesFrom(properties(comment: comment))
      .withAllValuesFrom(deprecatedProps)

    self.track(event: "Update Comment Create", properties: props)
  }

  public func trackCommentsView(project: Project, update: Update?, context: CommentsContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(update.map { properties(update: $0) } ?? [:])
      .withAllValuesFrom(["context": context.trackingString])

    // Deprecated events
    switch context {
    case .project:
      self.track(event: "Project Comment View", properties: props.withAllValuesFrom(deprecatedProps))
    case .update:
      self.track(event: "Update Comment View", properties: props.withAllValuesFrom(deprecatedProps))
    }

    self.track(event: "Viewed Comments", properties: props)
  }

  /**
   Call when the share sheet is shown.

   - parameter shareContext: The context in which the sharing is happening.
   */
  public func trackShowedShareSheet(shareContext: ShareContext) {
    let props = properties(shareContext: shareContext, loggedInUser: self.loggedInUser)

    self.track(event: "Showed Share Sheet", properties: props)

    // Deprecated event
    let deprecatedEvent = shareContext.isThanksContext ? "Checkout Show Share Sheet"
      : shareContext.update != nil ? "Update Show Share Sheet"
      : "Project Show Share Sheet"
    self.track(event: deprecatedEvent, properties: props.withAllValuesFrom(deprecatedProps))
  }

  /**
   Call when the share sheet is canceled.

   - parameter shareContext: The context in which the sharing is happening.
   */
  public func trackCanceledShareSheet(shareContext: ShareContext) {
    let props = properties(shareContext: shareContext, loggedInUser: self.loggedInUser)

    self.track(
      event: "Canceled Share Sheet",
      properties: props
    )

    // Deprecated event
    let deprecatedEvent = shareContext.isThanksContext ? "Checkout Cancel Share Sheet"
      : shareContext.update != nil ? "Update Cancel Share Sheet"
      : "Project Cancel Share Sheet"
    self.track(event: deprecatedEvent, properties: props.withAllValuesFrom(deprecatedProps))
  }

  /**
   Call when a share dialog is shown. Note that this is showing the actual share dialog, and not
   simply the share sheet.

   - parameter shareContext:      The context in which the sharing is happening.
   - parameter shareActivityType: The type of share that was shown.
   */
  public func trackShowedShare(shareContext: ShareContext, shareActivityType: UIActivity.ActivityType?) {
    let props = properties(
      shareContext: shareContext,
      loggedInUser: self.loggedInUser,
      shareActivityType: shareActivityType
    )
    self.track(event: "Showed Share", properties: props)

    // Deprecated event
    let deprecatedEvent = shareContext.isThanksContext ? "Checkout Show Share"
      : shareContext.update != nil ? "Update Show Share"
      : "Project Show Share"
    self.track(event: deprecatedEvent, properties: props.withAllValuesFrom(deprecatedProps))
  }

  /**
   Call when a share dialog is canceled. Note that this is canceling the actual share dialog, and not
   simply the share sheet.

   - parameter shareContext:      The context in which the sharing is happening.
   - parameter shareActivityType: The type of share that was shown.
   */
  public func trackCanceledShare(shareContext: ShareContext, shareActivityType: UIActivity.ActivityType?) {
    let props = properties(
      shareContext: shareContext,
      loggedInUser: self.loggedInUser,
      shareActivityType: shareActivityType
    )
    self.track(event: "Canceled Share", properties: props)

    // Deprecated event
    let deprecatedEvent = shareContext.isThanksContext ? "Checkout Cancel Share"
      : shareContext.update != nil ? "Update Cancel Share"
      : "Project Cancel Share"
    self.track(event: deprecatedEvent, properties: props.withAllValuesFrom(deprecatedProps))
  }

  /**
   Call when a share is successfully performed.

   - parameter shareContext:      The context in which the sharing is happening.
   - parameter shareActivityType: The type of share that was shown.
   */
  public func trackShared(shareContext: ShareContext, shareActivityType: UIActivity.ActivityType?) {
    let props = properties(
      shareContext: shareContext,
      loggedInUser: self.loggedInUser,
      shareActivityType: shareActivityType
    )
    self.track(event: "Shared", properties: props)

    // Deprecated event
    let deprecatedEvent = shareContext.isThanksContext ? "Checkout Share"
      : shareContext.update != nil ? "Update Share"
      : "Project Share"
    self.track(event: deprecatedEvent, properties: props.withAllValuesFrom(deprecatedProps))
  }

  public func trackCheckoutFinishJumpToDiscovery(project: Project) {
    self.track(
      event: "Checkout Finished Discover More",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackCheckoutFinishJumpToProject(project: Project) {
    self.track(
      event: "Checkout Finished Discover Open Project",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackTriggeredAppStoreRatingDialog(project: Project) {
    self.track(
      event: "Triggered App Store Rating Dialog",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  // MARK: - Dashboard

  public func trackDashboardClosedProjectSwitcher(onProject project: Project) {
    self.track(
      event: "Closed Project Switcher",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackDashboardSeeAllRewards(project: Project) {
    self.track(
      event: "Showed All Rewards",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackDashboardSeeMoreReferrers(project: Project) {
    self.track(
      event: "Showed All Referrers",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackDashboardShowProjectSwitcher(onProject project: Project) {
    self.track(
      event: "Showed Project Switcher",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackDashboardSwitchProject(_ project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Switched Projects", properties: props)

    // deprecated
    self.track(
      event: "Creator Project Navigate",
      properties: props.withAllValuesFrom(deprecatedProps)
    )
  }

  public func trackDashboardView(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Viewed Project Dashboard", properties: props)

    // deprecated
    self.track(
      event: "Dashboard View",
      properties: props.withAllValuesFrom(deprecatedProps)
    )
  }

  // MARK: - Project activity

  public func trackViewedProjectActivity(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Viewed Project Activity", properties: props)
    // deprecated
    self.track(
      event: "Creator Activity View",
      properties: props.withAllValuesFrom(deprecatedProps)
    )
  }

  public func trackLoadedNewerProjectActivity(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(event: "Loaded Newer Project Activity", properties: props)
    // deprecated
    self.track(
      event: "Creator Activity View Load Newer",
      properties: props.withAllValuesFrom(deprecatedProps)
    )
  }

  public func trackLoadedOlderProjectActivity(project: Project, page: Int) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["page_count": page])

    self.track(event: "Loaded Older Project Activity", properties: props)
    // deprecated
    self.track(
      event: "Creator Activity View Load Older",
      properties: props.withAllValuesFrom(deprecatedProps)
    )
  }

  // MARK: - Messages

  public func trackMessageThreadsView(mailbox: Mailbox, project: Project?, refTag: RefTag) {
    let props = (project.flatMap { projectProperties(from: $0, loggedInUser: self.loggedInUser) } ?? [:])
      .withAllValuesFrom(["ref_tag": refTag.stringTag])

    switch mailbox {
    case .inbox:
      self.track(event: "Viewed Message Inbox", properties: props)
    case .sent:
      self.track(event: "Viewed Sent Messages", properties: props)
    }

    // deprecated
    let _deprecatedProps = props.withAllValuesFrom(deprecatedProps)
    self.track(
      event: "Message Threads View",
      properties: _deprecatedProps.withAllValuesFrom(["mailbox": mailbox.rawValue])
    )
    self.track(event: "Message Inbox View", properties: _deprecatedProps)
  }

  public func trackViewedMessageSearch(project: Project?) {
    let props = project.flatMap { projectProperties(from: $0, loggedInUser: self.loggedInUser) } ?? [:]

    self.track(event: "Viewed Message Search", properties: props)
  }

  public func trackViewedMessageSearchResults(term: String, project: Project?, hasResults: Bool) {
    let props = (project.flatMap { projectProperties(from: $0, loggedInUser: self.loggedInUser) } ?? [:])
      .withAllValuesFrom(["term": term])
    let _deprecatedProps = props.withAllValuesFrom(deprecatedProps)

    self.track(event: "Message Threads Search", properties: _deprecatedProps)
    self.track(event: "Message Inbox Search", properties: _deprecatedProps)

    self.track(
      event: "Viewed Message Search Results",
      properties: props.withAllValuesFrom(["has_results": hasResults])
    )
  }

  public func trackClearedMessageSearchTerm(project: Project?) {
    let props = project.flatMap { projectProperties(from: $0, loggedInUser: self.loggedInUser) } ?? [:]

    self.track(
      event: "Cleared Message Search Term",
      properties: props
    )
  }

  public func trackMessageThreadView(project: Project) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(
      event: "Message Thread View",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Viewed Message Thread", properties: props)
  }

  public func trackViewedMessageEditor(project: Project, context: MessageDialogContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["message_type": "single", "context": context.rawValue])

    self.track(event: "Viewed Message Editor", properties: props)
  }

  /**
   Tracks an event for sending a message.

   - parameter project: The project that is the subject of the message.
   - parameter context: The place where the message was sent from.
   */
  public func trackMessageSent(project: Project, context: MessageDialogContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["message_type": "single", "context": context.rawValue])

    self.track(
      event: "Message Sent",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Sent Message", properties: props)
  }

  // MARK: - Search Events

  /// Call once when the search view is initially shown.
  public func trackProjectSearchView() {
    self.track(event: DataLakeWhiteListedEvent.searchPageViewed.rawValue)
  }

  // Call when projects have been obtained from a search.
  public func trackSearchResults(
    query: String,
    params: DiscoveryParams,
    refTag: RefTag,
    hasResults: Bool
  ) {
    let props = discoveryProperties(from: params)
      .withAllValuesFrom([
        "discover_ref_tag": refTag.stringTag,
        "search_term": query,
        "has_results": hasResults
      ])

    self.track(event: DataLakeWhiteListedEvent.searchResultsLoaded.rawValue, properties: props)
  }

  // MARK: - Project Events

  /**
   Call when a project page is viewed.

   - parameter project:      The project being viewed.
   - parameter refTag:       The ref tag used when opening the project.
   - parameter cookieRefTag: The ref tag pulled from cookie storage when this project was shown.
   */
  public func trackProjectViewed(
    _ project: Project,
    refTag: RefTag? = nil,
    cookieRefTag: RefTag? = nil
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(
      event: DataLakeWhiteListedEvent.projectPageViewed.rawValue,
      properties: props,
      refTag: refTag?.stringTag,
      referrerCredit: cookieRefTag?.stringTag
    )
  }

  /**
   Call when a project page is swiped to the next project.
   - parameter project:      The next project being viewed.
   - parameter refTag:       The ref tag used when swiping to the project.
   */
  public func trackSwipedProject(_ project: Project, refTag: RefTag?) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)

    self.track(
      event: DataLakeWhiteListedEvent.projectSwiped.rawValue,
      properties: props, refTag: refTag?.stringTag
    )
  }

  public func trackProjectSave(_ project: Project, context: SaveContext) {
    guard let isStarred = project.personalization.isStarred else { return }

    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["context": context.trackingString])

    // Deprecated event
    self.track(
      event: isStarred ? "Project Star" : "Project Unstar",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(
      event: isStarred ? "Starred Project" : "Unstarred Project",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(
      event: isStarred ? "Saved Project" : "Unsaved Project",
      properties: props
    )
  }

  public func trackOpenedExternalLink(project: Project, context: ExternalLinkContext) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(["context": context.trackingString])

    self.track(event: "Opened External Link", properties: props)
  }

  // MARK: - Profile Events

  public func trackProfileView() {
    // deprecated
    self.track(event: "Profile View My", properties: deprecatedProps)

    self.track(event: "Viewed Profile")
  }

  public func trackViewedProfileTab(projectsType: ProfileProjectsType) {
    self.track(event: "Viewed Profile Tab", properties: ["type": projectsType.trackingString])
  }

  // MARK: - Settings Events

  public func trackAppStoreRatingOpen() {
    // deprecated
    self.track(event: "App Store Rating Open", properties: deprecatedProps)

    self.track(event: "Opened App Store Listing")
  }

  public func trackRecommendationsOptIn() {
    // deprecated
    self.track(event: "Toggled recommendations", properties: deprecatedProps)
  }

  public func trackFollowingOptIn() {
    // deprecated
    self.track(event: "Toggled following", properties: deprecatedProps)
  }

  public func trackCancelLogoutModal() {
    self.track(event: "Canceled Logout", properties: ["context": "modal"])
  }

  public func trackChangeEmailNotification(type: String, on: Bool) {
    self.track(
      event: on ? "Enabled Email Notifications" : "Disabled Email Notifications",
      properties: ["type": type]
    )
  }

  public func trackAccountView() {
    self.track(event: "Viewed Account")
  }

  // MARK: - Create Password Tracking

  public enum CreatePasswordTrackingEvent: String {
    case passwordCreated = "Created Password"
    case viewed = "Viewed Create Password"
  }

  public func trackCreatePassword(event: CreatePasswordTrackingEvent) {
    self.track(event: event.rawValue)
  }

  // MARK: - Change Email Tracking

  public func trackChangeEmailView() {
    self.track(event: "Viewed Change Email")
  }

  public func trackChangeEmail() {
    self.track(event: "Changed Email")
  }

  // MARK: - Change Password Tracking

  public func trackChangePasswordView() {
    self.track(event: "Viewed Change Password")
  }

  public func trackChangePassword() {
    self.track(event: "Changed Password")
  }

  public func trackResentVerificationEmail() {
    self.track(event: "Resent Verification Email")
  }

  public func trackChangedCurrency(_ currency: Currency) {
    let prop = ["currency": currency.descriptionText]
    self.track(event: "Selected Chosen Currency", properties: prop)
  }

  /**
   Tracks an event for toggling a newsletter preference.

   - parameter newsletterType: The newsletter type.
   - parameter sendNewsletter: The boolean determining whether the newsletter should be sent or not.
   - parameter project: The referring project from which a newsletter preference is set (e.g. Thanks screen).
   - parameter context: The context from which the newsletter preference is set.
   */
  public func trackChangeNewsletter(
    newsletterType newsletter: Newsletter,
    sendNewsletter: Bool,
    project: Project?,
    context: NewsletterContext
  ) {
    let props = project.flatMap { projectProperties(from: $0, loggedInUser: self.loggedInUser) } ?? [:]
      .withAllValuesFrom(["context": context.trackingString, "type": newsletter.trackingString])

    self.track(
      event: sendNewsletter ? "Subscribed To Newsletter" : "Unsubscribed From Newsletter",
      properties: props
    )

    // Deprecated events
    switch context {
    case .signup, .facebookSignup:
      self.track(event: "Signup Newsletter Toggle", properties: ["send_newsletters": sendNewsletter])
    case .thanks:
      self.track(event: sendNewsletter ? "Newsletter Subscribe" : "Newsletter Unsubscribe", properties: props)
    case .settings:
      return
    }
  }

  public func trackChangeProjectNotification(_ project: ProjectNotification.Project) {
    let props: [String: Any] = ["name": project.name, "id": project.id]
    self.track(event: "Changed Project Notifications", properties: props)
  }

  public func trackChangePushNotification(type: String, on: Bool) {
    self.track(
      event: on ? "Enabled Push Notifications" : "Disabled Push Notifications",
      properties: ["type": type]
    )
  }

  public func trackPushPermissionOptIn() {
    self.track(event: "Confirmed Push Opt-In")
  }

  public func trackPushPermissionOptOut() {
    self.track(event: "Dismissed Push Opt-In")
  }

  public func trackConfirmLogoutModal() {
    self.track(event: "Confirmed Logout", properties: ["context": "modal"])
  }

  public func trackLogoutModal() {
    self.track(event: "Triggered Logout Modal")
  }

  public func trackSettingsView() {
    // deprecated
    self.track(event: "Settings View", properties: deprecatedProps)

    self.track(event: "Viewed Settings")
  }

  // MARK: - Find Friends Events

  public func trackCloseFacebookConnect(source: FriendsSource) {
    self.track(event: "Close Facebook Connect", properties: ["source": source.trackingString])
  }

  public func trackCloseFindFriends(source: FriendsSource) {
    self.track(event: "Close Find Friends", properties: ["source": source.trackingString])
  }

  public func trackDeclineFriendFollowAll(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(
      event: "Facebook Friend Decline Follow All",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Declined Follow All Facebook Friends", properties: props)
  }

  public func trackFacebookConnect(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Facebook Connect", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Connected Facebook", properties: props)
  }

  public func trackFacebookConnectError(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Facebook Connect Error", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Errored Facebook Connect", properties: props)
  }

  public func trackFindFriendsView(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Find Friends View", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Viewed Find Friends", properties: props)
  }

  public func trackFriendFollow(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Facebook Friend Follow", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Followed Facebook Friend", properties: props)
  }

  public func trackFriendFollowAll(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Facebook Friend Follow All", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Followed All Facebook Friends", properties: props)
  }

  public func trackFriendUnfollow(source: FriendsSource) {
    let props: [String: Any] = ["source": source.trackingString]

    // deprecated
    self.track(event: "Facebook Friend Unfollow", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Unfollowed Facebook Friend", properties: props)
  }

  public func loadedMoreFriends(source: FriendsSource, pageCount: Int) {
    self.track(
      event: "Loaded More Friends",
      properties: ["source": source.trackingString, "page_count": pageCount]
    )
  }

  // MARK: - Update Draft Events

  public func trackViewedUpdateDraft(forProject project: Project) {
    self.track(event: "Viewed Draft", properties: self.updateDraftProperties(project: project))
  }

  public func trackClosedUpdateDraft(forProject project: Project) {
    self.track(event: "Closed Draft", properties: self.updateDraftProperties(project: project))
  }

  public func trackEditedUpdateDraftTitle(forProject project: Project) {
    self.track(event: "Edited Title", properties: self.updateDraftProperties(project: project))
  }

  public func trackEditedUpdateDraftBody(forProject project: Project) {
    self.track(event: "Edited Body", properties: self.updateDraftProperties(project: project))
  }

  public func trackStartedAddUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Started Add Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackCompletedAddUpdateDraftAttachment(
    forProject project: Project,
    attachedFrom source: AttachmentSource
  ) {
    var props = self.updateDraftProperties(project: project)
    props["type"] = source.rawValue
    self.track(event: "Completed Add Attachment", properties: props)
  }

  public func trackCanceledAddUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Canceled Add Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackFailedAddUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Failed Add Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackStartedRemoveUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Started Remove Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackCanceledRemoveUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Canceled Remove Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackCompletedRemoveUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Completed Remove Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackFailedRemoveUpdateDraftAttachment(forProject project: Project) {
    self.track(event: "Failed Remove Attachment", properties: self.updateDraftProperties(project: project))
  }

  public func trackChangedUpdateDraftVisibility(forProject project: Project, isPublic: Bool) {
    var props = projectProperties(from: project, loggedInUser: self.loggedInUser)
    props["type"] = isPublic ? "public" : "backers_only"
    self.track(event: "Changed Visibility", properties: props)
  }

  public func trackPreviewedUpdate(forProject project: Project) {
    let props = self.updateDraftProperties(project: project)
    self.track(event: "Previewed Update", properties: props)

    self.track(event: "Update Preview", properties: props.withAllValuesFrom(deprecatedProps))
  }

  public func trackTriggeredPublishConfirmationModal(forProject project: Project) {
    self.track(
      event: "Triggered Publish Confirmation Modal",
      properties: self.updateDraftProperties(project: project)
    )
  }

  public func trackCanceledPublishUpdate(forProject project: Project) {
    self.track(
      event: "Canceled Publish", properties: self.updateDraftProperties(project: project)
        .withAllValuesFrom(["context": "modal"])
    )
  }

  public func trackConfirmedPublishUpdate(forProject project: Project) {
    self.track(
      event: "Confirmed Publish", properties: self.updateDraftProperties(project: project)
        .withAllValuesFrom(["context": "modal"])
    )
  }

  public func trackPublishedUpdate(forProject project: Project, isPublic: Bool) {
    var props = self.updateDraftProperties(project: project)
    props["type"] = isPublic ? "public" : "backers_only"
    self.track(event: "Published Update", properties: props)

    self.track(event: "Update Published", properties: props.withAllValuesFrom(deprecatedProps))
  }

  private func updateDraftProperties(project: Project) -> [String: Any] {
    var props = projectProperties(from: project, loggedInUser: self.loggedInUser)
    props["context"] = "update_draft"
    return props
  }

  // MARK: - Pledge screen events

  public func trackViewedPledge(forProject project: Project) {
    self.track(
      event: "Viewed Pledge Info",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )

    // Deprecated event
    self.track(
      event: "Modal Dialog View",
      properties: ["modal_class": "backer_info", Koala.DeprecatedKey: true]
    )
  }

  // MARK: - Help events

  public func trackCanceledContactEmail(context: HelpContext) {
    self.track(event: "Canceled Contact Email", properties: ["context": context.trackingString])
  }

  public func trackCanceledHelpMenu(context: HelpContext) {
    self.track(event: "Canceled Help Menu", properties: ["context": context.trackingString])
  }

  public func trackOpenedContactEmail(context _: HelpContext) {
    // deprecated
    self.track(event: "Contact Email Open", properties: deprecatedProps)
  }

  public func trackSelectedHelpOption(context: HelpContext, type: HelpType) {
    self.track(
      event: "Selected Help Option",
      properties: ["context": context.trackingString, "type": type.trackingString]
    )
  }

  public func trackSentContactEmail(context: HelpContext) {
    self.track(
      event: "Sent Contact Email",
      properties: ["context": context.trackingString]
    )

    // deprecated
    self.track(event: "Contact Email Sent", properties: deprecatedProps)
  }

  public func trackShowedHelpMenu(context: HelpContext) {
    self.track(event: "Showed Help Menu", properties: ["context": context.trackingString])
  }

  // MARK: - Video events

  public func trackVideoCompleted(forProject project: Project) {
    // deprecated
    self.track(event: "Project Video Complete", properties: deprecatedProps)

    self.track(
      event: "Completed Project Video",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackVideoPaused(forProject project: Project) {
    // deprecated
    self.track(event: "Project Video Pause", properties: deprecatedProps)

    self.track(
      event: "Paused Project Video",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackVideoResume(forProject project: Project) {
    // deprecated
    self.track(event: "Project Video Resume", properties: deprecatedProps)

    self.track(
      event: "Resumed Project Video",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  public func trackVideoStart(forProject project: Project) {
    // deprecated
    self.track(event: "Project Video Start", properties: deprecatedProps)

    self.track(
      event: "Started Project Video",
      properties: projectProperties(from: project, loggedInUser: self.loggedInUser)
    )
  }

  // MARK: - Apple Pay events

  public func trackShowApplePaySheet(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    // deprecated
    self.track(
      event: "Apple Pay Show Sheet",
      properties: props.withAllValuesFrom(deprecatedProps)
    )

    self.track(event: "Showed Apple Pay Sheet", properties: props)
  }

  public func trackApplePayAuthorizedPayment(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    // deprecated
    self.track(event: "Apple Pay Authorized", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Authorized Apple Pay", properties: props)
  }

  public func trackStripeTokenCreatedForApplePay(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Apple Pay Stripe Token Created", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Created Apple Pay Stripe Token", properties: props)
  }

  public func trackStripeTokenErroredForApplePay(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Apple Pay Stripe Token Errored", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Errored Apple Pay Stripe Token", properties: props)
  }

  public func trackApplePayFinished(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Apple Pay Finished", properties: props.withAllValuesFrom(deprecatedProps))
  }

  public func trackApplePaySheetCanceled(
    project: Project,
    reward: Reward,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])
    self.track(event: "Apple Pay Canceled", properties: props.withAllValuesFrom(deprecatedProps))

    self.track(event: "Canceled Apple Pay", properties: props)
  }

  // MARK: - Empty State Events

  public func trackEmptyStateButtonTapped(type: EmptyState) {
    self.track(
      event: "Tapped Empty State Button",
      properties: ["type": type.rawValue]
    )
  }

  public func trackExpandedRewardDescription(
    _ reward: Reward,
    project: Project,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Expanded Reward Description", properties: props)
  }

  public func trackExpandedUnavailableReward(
    _ reward: Reward,
    project: Project,
    pledgeContext: PledgeContext
  ) {
    let props = projectProperties(from: project, loggedInUser: self.loggedInUser)
      .withAllValuesFrom(properties(reward: reward))
      .withAllValuesFrom(["pledge_context": pledgeContext.trackingString])

    self.track(event: "Expanded Unavailable Reward", properties: props)
  }

  public func trackPerformedShortcutItem(
    _ shortcutItem: ShortcutItem,
    availableShortcutItems: [ShortcutItem]
  ) {
    self.track(
      event: "Performed Shortcut",
      properties: [
        "type": shortcutItem.typeString,
        "context": availableShortcutItems.map { $0.typeString }.joined(separator: ",")
      ]
    )
  }

  public func trackViewedPaymentMethods() {
    self.track(event: "Viewed Payment Methods")
  }

  public func trackViewedAddNewCard() {
    self.track(event: "Viewed Add New Card")
  }

  public func trackDeletedPaymentMethod() {
    self.track(event: "Deleted Payment Method")
  }

  public func trackDeletePaymentMethodError() {
    self.track(event: "Errored Delete Payment Method")
  }

  public func trackSavedPaymentMethod() {
    self.track(event: "Saved Payment Method")
  }

  public func trackFailedPaymentMethodCreation() {
    self.track(event: "Failed Payment Method Creation")
  }

  // Private tracking method that merges in default properties.
  private func track(
    event: String,
    properties: [String: Any] = [:],
    refTag: String? = nil,
    referrerCredit: String? = nil
  ) {
    let props = self.sessionProperties(refTag: refTag, referrerCredit: referrerCredit)
      .withAllValuesFrom(userProperties(for: self.loggedInUser, config: self.config))
      .withAllValuesFrom(properties)

    self.logEventCallback?(event, props)

    self.koalaClient.track(
      event: event,
      properties: props
    )

    if DataLakeWhiteListedEvent.allWhiteListedEvents().contains(event) {
      self.dataLakeClient.track(
        event: event,
        properties: props
      )
    }
  }

  // MARK: - Session Properties

  private func sessionProperties(
    refTag: String?,
    referrerCredit: String?,
    prefix: String = "session_"
  ) -> [String: Any] {
    var props: [String: Any] = [:]

    let enabledFeatureFlags = self.config?.features
      .filter { key, value in key.starts(with: "ios_") && value }
      .keys
      .sorted()

    props["apple_pay_capable"] = PKPaymentAuthorizationViewController.applePayCapable()
    props["apple_pay_device"] = PKPaymentAuthorizationViewController.applePayDevice()
    props["cellular_connection"] = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology
    props["client_type"] = "native"
    props["current_variants"] = self.config?.abExperimentsArray.sorted()
    props["display_language"] = AppEnvironment.current.language.rawValue

    props["device_format"] = self.deviceFormat
    props["device_manufacturer"] = "Apple"
    props["device_model"] = Koala.deviceModel
    props["device_orientation"] = self.deviceOrientation
    props["device_distinct_id"] = self.distinctId

    props["enabled_features"] = enabledFeatureFlags
    props["is_voiceover_running"] = AppEnvironment.current.isVoiceOverRunning()
    props["mp_lib"] = "kickstarter_ios"
    props["os"] = self.device.systemName
    props["os_version"] = self.device.systemVersion
    props["time"] = AppEnvironment.current.dateType.init().timeIntervalSince1970
    props["app_build_number"] = self.bundle.infoDictionary?["CFBundleVersion"]
    props["app_release_version"] = self.bundle.infoDictionary?["CFBundleShortVersionString"]
    props["screen_width"] = UInt(self.screen.bounds.width)
    props["user_agent"] = Service.userAgent
    props["user_logged_in"] = self.loggedInUser != nil
    props["wifi_connection"] = Reachability.current == .wifi
    props["client_platform"] = self.clientPlatform

    props["ref_tag"] = refTag
    props["referrer_credit"] = referrerCredit

    return props.prefixedKeys(prefix)
  }

  private static let deviceModel: String? = {
    var size: Int = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: Int(size))
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    return String(cString: machine)
  }()

  private var deviceOrientation: String {
    switch self.device.orientation {
    case .faceDown:
      return "Face Down"
    case .faceUp:
      return "Face Up"
    case .landscapeLeft:
      return "Landscape Left"
    case .landscapeRight:
      return "Landscape Right"
    case .portrait:
      return "Portrait"
    case .portraitUpsideDown:
      return "Portrait Upside Down"
    case .unknown:
      return "Unknown"
    @unknown default:
      fatalError()
    }
  }

  private var deviceFormat: String {
    switch self.device.userInterfaceIdiom {
    case .phone: return "phone"
    case .pad: return "tablet"
    case .tv: return "tv"
    default: return "unspecified"
    }
  }

  private var clientPlatform: String {
    switch self.device.userInterfaceIdiom {
    case .phone, .pad: return "ios"
    case .tv: return "tvos"
    default: return "unspecified"
    }
  }
}

// MARK: - Project Properties

private func projectProperties(
  from project: Project,
  loggedInUser: User? = nil,
  dateType: DateProtocol.Type = AppEnvironment.current.dateType,
  calendar: Calendar = AppEnvironment.current.calendar,
  prefix: String = "project_"
) -> [String: Any] {
  var props: [String: Any] = [:]

  props["backers_count"] = project.stats.backersCount
  props["subcategory"] = project.category.name
  props["country"] = project.country.countryCode
  props["comments_count"] = project.stats.commentsCount ?? 0
  props["currency"] = project.country.currencyCode
  props["creator_uid"] = project.creator.id
  props["deadline"] = project.dates.deadline
  props["goal"] = project.stats.goal
  props["launched_at"] = project.dates.launchedAt
  props["location"] = project.location.name
  props["name"] = project.name
  props["pid"] = project.id
  props["category"] = project.category.parent?.name
  props["percent_raised"] = project.stats.fundingProgress
  props["state"] = project.state.rawValue
  props["static_usd_rate"] = project.stats.staticUsdRate
  props["current_pledge_amount"] = project.stats.pledged
  props["current_pledge_amount_usd"] = project.stats.pledgedUsd
  props["goal_usd"] = project.stats.goalUsd
  props["has_video"] = project.video != nil
  props["updates_count"] = project.stats.updatesCount
  props["prelaunch_activated"] = project.prelaunchActivated
  props["rewards_count"] = project.rewards.count

  let now = dateType.init().date
  props["hours_remaining"] = project.dates.hoursRemaining(from: now, using: calendar)
  props["duration"] = project.dates.duration(using: calendar)

  var userProperties: [String: Any] = [:]
  userProperties["has_watched"] = project.personalization.isStarred
  userProperties["is_backer"] = project.personalization.isBacking
  userProperties["is_project_creator"] = project.creator.id == loggedInUser?.id

  let userProps = userProperties.prefixedKeys("user_")

  return props
    .withAllValuesFrom(userProps)
    .prefixedKeys(prefix)
}

private func properties(update: Update, prefix: String = "update_") -> [String: Any] {
  var properties: [String: Any] = [:]

  properties["comments_count"] = update.commentsCount
  properties["user_has_liked"] = update.hasLiked
  properties["likes_count"] = update.likesCount
  properties["published_at"] = update.publishedAt
  properties["sequence"] = update.sequence

  return properties.prefixedKeys(prefix)
}

private func properties(comment: Comment, prefix: String = "comment_") -> [String: Any] {
  var properties: [String: Any] = [:]

  properties["body_length"] = comment.body.count

  return properties.prefixedKeys(prefix)
}

private func properties(userActivity: NSUserActivity) -> [String: Any] {
  var props: [String: Any] = [:]

  props["user_activity_type"] = userActivity.activityType
  props["user_activity_title"] = userActivity.title
  props["user_activity_webpage_url"] = userActivity.webpageURL?.absoluteString
  props["user_activity_keywords"] = Array(userActivity.keywords)

  return props
}

// MARK: - Discovery Properties

private func discoveryProperties(
  from params: DiscoveryParams,
  prefix: String = "discover_"
) -> [String: Any] {
  var result: [String: Any] = [:]

  // NB: All filters should be added here since `result["everything"]` is derived from this.
  result["recommended"] = params.recommended
  result["social"] = params.social
  result["pwl"] = params.staffPicks
  result["watched"] = params.starred
  result["tag"] = params.tagId?.rawValue
  let categoryProps = params.category.map { properties(category: $0, prefix: "subcategory_") }
  let parentCategoryProps = params.category?.parent.map { properties(category: $0) }

  result = result
    .withAllValuesFrom(categoryProps ?? [:])
    .withAllValuesFrom(parentCategoryProps ?? [:])

  result["everything"] = result.isEmpty
  result["sort"] = params.sort?.rawValue
  result["ref_tag"] = RefTag.fromParams(params).stringTag
  result["search_term"] = params.query

  return result.prefixedKeys(prefix)
}

private func properties(category: KsApi.Category, prefix: String = "category_") -> [String: Any] {
  var result: [String: Any] = [:]

  result["id"] = category.intID
  result["name"] = category.name

  return result.prefixedKeys(prefix)
}

private func properties(
  shareContext: ShareContext,
  loggedInUser: User?,
  shareActivityType: UIActivity.ActivityType? = nil
) -> [String: Any] {
  var result: [String: Any] = [:]

  result["share_activity_type"] = shareActivityType?.rawValue
  result["share_type"] = shareActivityType.flatMap(shareTypeProperty)

  switch shareContext {
  case let .creatorDashboard(project):
    result = result.withAllValuesFrom(projectProperties(from: project, loggedInUser: loggedInUser))
    result["context"] = "creator_dashboard"
  case let .discovery(project):
    result = result.withAllValuesFrom(projectProperties(from: project, loggedInUser: loggedInUser))
    result["context"] = "discovery"
  case let .project(project):
    result = result.withAllValuesFrom(projectProperties(from: project, loggedInUser: loggedInUser))
    result["context"] = "project"
  case let .thanks(project):
    result = result.withAllValuesFrom(projectProperties(from: project, loggedInUser: loggedInUser))
    result["context"] = "thanks"
  case let .update(project, update):
    result = result.withAllValuesFrom(projectProperties(from: project, loggedInUser: loggedInUser))
    result = result.withAllValuesFrom(properties(update: update))
    result["context"] = "update"
  }

  return result
}

private func properties(reward: Reward, prefix: String = "backer_reward_") -> [String: Any] {
  guard reward != Reward.noReward else { return [:] }

  var result: [String: Any] = [:]

  result["id"] = reward.id
  result["is_limited_quantity"] = reward.limit == nil
  // result["is_limited_time"] = // implement when reward scheduling is supported
  result["minimum"] = reward.minimum
  result["shipping_enabled"] = reward.shipping.enabled
  result["shipping_preference"] = reward.shipping.preference?.trackingString
  result["has_items"] = !reward.rewardsItems.isEmpty

  return result.prefixedKeys(prefix)
}

private func shareTypeProperty(_ shareType: UIActivity.ActivityType?) -> String? {
  guard let shareType = shareType else { return nil }

  if shareType == .postToFacebook {
    return "facebook"
  } else if shareType == .message {
    return "message"
  } else if shareType == .mail {
    return "email"
  } else if shareType == .copyToPasteboard {
    return "copy link"
  } else if shareType == .postToTwitter {
    return "twitter"
  } else if shareType == UIActivity.ActivityType("com.apple.mobilenotes.SharingExtension") {
    return "notes"
  } else if shareType == SafariActivityType {
    return "safari"
  } else {
    return shareType.rawValue
  }
}

// MARK: - User Properties

private func userProperties(for user: User?, config: Config?, _ prefix: String = "user_") -> [String: Any] {
  var props: [String: Any] = [:]

  props["is_admin"] = user?.isAdmin
  props["backed_projects_count"] = user?.stats.backedProjectsCount
  props["country"] = user?.location?.country ?? config?.countryCode
  props["facebook_account"] = user?.facebookConnected
  props["watched_projects_count"] = user?.stats.starredProjectsCount
  props["launched_projects_count"] = user?.stats.createdProjectsCount
  props["uid"] = user?.id

  return props.prefixedKeys(prefix)
}

extension Koala {
  public enum lens {
    public static let loggedInUser = Lens<Koala, User?>(
      view: { $0.loggedInUser },
      set: { $1.loggedInUser = $0; return $1 }
    )

    public static let config = Lens<Koala, Config?>(
      view: { $0.config },
      set: { $1.config = $0; return $1 }
    )
  }
}

extension Reward.Shipping.Preference {
  fileprivate var trackingString: String {
    switch self {
    case .none: return "none"
    case .restricted: return "restricted"
    case .unrestricted: return "unrestricted"
    }
  }
}
