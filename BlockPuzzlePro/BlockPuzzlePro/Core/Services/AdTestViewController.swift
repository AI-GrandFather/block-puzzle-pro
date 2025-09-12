import UIKit
import SwiftUI
import os.log

// MARK: - Ad Test View Controller

class AdTestViewController: UIViewController {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AdTestViewController")
    
    // MARK: - UI Elements
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AdMob Integration Test"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Initializing..."
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var loadAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Load Rewarded Ad", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(loadAdTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var showAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show Rewarded Ad", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(showAdTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var requestATTButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Request ATT Permission", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(requestATTTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var debugTextView: UITextView = {
        let textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAdManager()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Ad Test"
        
        view.addSubview(stackView)
        view.addSubview(debugTextView)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(loadAdButton)
        stackView.addArrangedSubview(showAdButton)
        stackView.addArrangedSubview(requestATTButton)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            debugTextView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30),
            debugTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - AdMob Setup
    
    private func setupAdManager() {
        Task {
            // Wait for AdManager to initialize
            while !await AdManager.shared.isInitialized {
                try? await Task.sleep(for: .seconds(0.5))
            }
            
            await MainActor.run {
                updateStatus("AdManager initialized ✅")
                updateDebugInfo()
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func loadAdTapped() {
        Task {
            updateStatus("Loading ad...")
            await AdManager.shared.preloadRewardedAd()
            
            // Monitor loading state
            var attempts = 0
            while attempts < 10 { // 5 second timeout
                let isReady = await AdManager.shared.isRewardedAdReady()
                if isReady {
                    await MainActor.run {
                        updateStatus("Ad loaded successfully ✅")
                        showAdButton.isEnabled = true
                        updateDebugInfo()
                    }
                    return
                }
                
                try? await Task.sleep(for: .seconds(0.5))
                attempts += 1
            }
            
            await MainActor.run {
                updateStatus("Ad loading timed out ❌")
                updateDebugInfo()
            }
        }
    }
    
    @objc private func showAdTapped() {
        Task {
            updateStatus("Showing ad...")
            let success = await AdManager.shared.showRewardedAd(from: self)
            
            await MainActor.run {
                if success {
                    updateStatus("Ad shown successfully ✅")
                    showAdButton.isEnabled = false
                } else {
                    updateStatus("Failed to show ad ❌")
                }
                updateDebugInfo()
            }
        }
    }
    
    @objc private func requestATTTapped() {
        Task {
            updateStatus("Requesting ATT permission...")
            await ATTManager.shared.requestTrackingPermissionIfNeeded()
            
            await MainActor.run {
                let status = ATTManager.shared.attStatus.description
                updateStatus("ATT Status: \(status)")
                updateDebugInfo()
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateStatus(_ message: String) {
        Task { @MainActor in
            statusLabel.text = message
            logger.info("\(message)")
        }
    }
    
    private func updateDebugInfo() {
        Task {
            let adInfo = await AdManager.shared.getDebugInfo()
            let attInfo = ATTManager.shared.getDebugInfo()
            let configInfo = """
            Configuration Debug Info:
            - Environment: \(AdMobConfig.isProduction ? "Production" : "Test")
            - App ID: \(AdMobConfig.appID)
            - Rewarded Ad Unit: \(AdMobConfig.rewardedAdUnitID)
            - Preload Enabled: \(AdMobConfig.shouldPreloadAds)
            """
            
            let fullDebugInfo = """
            === AdMob Test Debug Information ===
            
            \(configInfo)
            
            \(adInfo)
            
            \(attInfo)
            
            === Test Status ===
            Last Update: \(Date().formatted(.dateTime))
            """
            
            await MainActor.run {
                debugTextView.text = fullDebugInfo
            }
        }
    }
}

// MARK: - AdRewardDelegate

extension AdTestViewController: AdRewardDelegate {
    func adManager(_ manager: AdManager, didEarnReward amount: Int, type: String) {
        logger.info("User earned reward: \(amount) of type \(type)")
        updateStatus("Reward earned: \(amount) \(type) ✅")
    }
    
    func adManager(_ manager: AdManager, didFailToShowAd error: AdError) {
        logger.error("Failed to show ad: \(error.localizedDescription)")
        updateStatus("Ad failed: \(error.localizedDescription) ❌")
    }
    
    func adManager(_ manager: AdManager, didDismissAd wasCompleted: Bool) {
        logger.info("Ad dismissed - completed: \(wasCompleted)")
        updateStatus("Ad dismissed - completed: \(wasCompleted)")
    }
}

// MARK: - SwiftUI Integration

struct AdTestViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AdTestViewController {
        let controller = AdTestViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AdTestViewController, context: Context) {
        // Updates handled internally
    }
}