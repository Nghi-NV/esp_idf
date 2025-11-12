import UIKit
import ESPProvision

protocol ESPQRScannerDelegate: AnyObject {
    func qrScannerDidScan(device: ESPDevice)
    func qrScannerDidCancel()
    func qrScannerDidFail(error: Error)
}

class ESPQRScannerViewController: UIViewController {
    weak var delegate: ESPQRScannerDelegate?
    private var scannerView: UIView!
    private var titleLabel: UILabel!
    private var instructionLabel: UILabel!
    private var cancelButton: UIButton!

    // Customization properties
    var customTitle: String?
    var customDescription: String?
    var customCancelButtonText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startScanning()
    }

    private func setupUI() {
        view.backgroundColor = .black

        // Scanner view
        scannerView = UIView()
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerView)

        // Title label
        titleLabel = UILabel()
        titleLabel.text = customTitle ?? "Scan QR Code"
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Instruction label
        instructionLabel = UILabel()
        instructionLabel.text = customDescription ?? "Scan the QR code on your ESP device"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle(customCancelButtonText ?? "Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        // Constraints
        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: view.topAnchor),
            scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20),

            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func startScanning() {
        ESPProvisionManager.shared.scanQRCode(scanView: scannerView) { [weak self] espDevice, error in
            guard let self = self else { return }

            if let error = error {
                self.delegate?.qrScannerDidFail(error: error)
                self.dismiss(animated: true)
                return
            }

            if let device = espDevice {
                self.delegate?.qrScannerDidScan(device: device)
                self.dismiss(animated: true)
            }
        }
    }

    @objc private func cancelTapped() {
        delegate?.qrScannerDidCancel()
        dismiss(animated: true)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
