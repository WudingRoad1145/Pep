import Foundation

class UserProfileManager: ObservableObject{
    private let userNameKey = "userName"
    private let ageKey = "age"
    private let bodyPartKey = "bodyPart"
    private let motivationKey = "motivation"
    private let notificationPreferenceKey = "notificationPreference"
    private let onboardedKey = "onboarded"
    
    var userName: String {
        get { UserDefaults.standard.string(forKey: userNameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: userNameKey) }
    }
    
    var age: Int {
        get { UserDefaults.standard.integer(forKey: ageKey) }
        set { UserDefaults.standard.set(newValue, forKey: ageKey) }
    }
    
    var bodyPart: String {
        get { UserDefaults.standard.string(forKey: bodyPartKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: bodyPartKey) }
    }
    
    var motivation: String {
        get { UserDefaults.standard.string(forKey: motivationKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: motivationKey) }
    }
    
    var notificationPreference: Bool {
        get { UserDefaults.standard.bool(forKey: notificationPreferenceKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationPreferenceKey) }
    }
    
    var onboarded: Bool {
        get { UserDefaults.standard.bool(forKey: onboardedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardedKey) }
    }
}
