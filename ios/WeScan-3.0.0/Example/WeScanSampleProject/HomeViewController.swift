//
//  ViewController.swift
//  WeScanSampleProject
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeScan
import TLPhotoPicker
import Photos

final class HomeViewController: UIViewController {

    var selectedAssets = [TLPHAsset]()
    private lazy var logoImageView: UIImageView = {
        let image = #imageLiteral(resourceName: "WeScanLogo")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "WeScan"
        label.font = UIFont.systemFont(ofSize: 25.0, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.setTitle("Scan Item", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scanOrSelectImage(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 64.0 / 255.0, green: 159 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        button.layer.cornerRadius = 10.0
        return button
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
    }

    // MARK: - Setups

    private func setupViews() {
        view.addSubview(logoImageView)
        view.addSubview(logoLabel)
        view.addSubview(scanButton)
    }

    private func setupConstraints() {

        let logoImageViewConstraints = [
            logoImageView.widthAnchor.constraint(equalToConstant: 150.0),
            logoImageView.heightAnchor.constraint(equalToConstant: 150.0),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            NSLayoutConstraint(
                item: logoImageView,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerY,
                multiplier: 0.75,
                constant: 0.0
            )
        ]

        let logoLabelConstraints = [
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20.0),
            logoLabel.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor)
        ]

        NSLayoutConstraint.activate(logoLabelConstraints + logoImageViewConstraints)

        if #available(iOS 11.0, *) {
            let scanButtonConstraints = [
                scanButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
                scanButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
                scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                scanButton.heightAnchor.constraint(equalToConstant: 55)
            ]

            NSLayoutConstraint.activate(scanButtonConstraints)
        } else {
            let scanButtonConstraints = [
                scanButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
                scanButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
                scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
                scanButton.heightAnchor.constraint(equalToConstant: 55)
            ]

            NSLayoutConstraint.activate(scanButtonConstraints)
        }
    }

    // MARK: - Actions

    @objc func scanOrSelectImage(_ sender: UIButton) {
        let actionSheet = UIAlertController(
            title: "Would you like to scan an image or select one from your photo library?",
            message: nil,
            preferredStyle: .actionSheet
        )

        let newAction = UIAlertAction(title: "A new scan", style: .default) { _ in
            guard let controller = self.storyboard?.instantiateViewController(withIdentifier: "NewCameraViewController") else { return }
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }

        let scanAction = UIAlertAction(title: "Scan", style: .default) { _ in
            self.scanImage()
        }

        let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
            self.selectImage()
        }

        let selectMultipleAction = UIAlertAction(title: "Select Multiple", style: .default) { _ in
            self.selectMultipleImage()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        actionSheet.addAction(scanAction)
        actionSheet.addAction(selectAction)
        actionSheet.addAction(selectMultipleAction)
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(newAction)

        present(actionSheet, animated: true)
    }

    func scanImage() {
        let scannerViewController = ImageScannerController(delegate: self)
        scannerViewController.modalPresentationStyle = .fullScreen

        if #available(iOS 13.0, *) {
            scannerViewController.navigationBar.tintColor = .label
        } else {
            scannerViewController.navigationBar.tintColor = .black
        }

        present(scannerViewController, animated: true)
    }

    func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    func selectMultipleImage(){
        let picker = createPicker(
            TLPhotosPickerViewController(),
            withLogDelegate: true
        ) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(3)
                .maxSelection(15)
        }

        present(picker, animated: true)
    }
    
    private func createPicker<T: TLPhotosPickerViewController>(
        _ picker: T,
        withLogDelegate: Bool = false,
        configuration: (T) -> Void
    ) -> T {
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        setupCommonHandlers(for: picker)

        configuration(picker)

        picker.selectedAssets = self.selectedAssets

        if withLogDelegate {
            picker.logDelegate = self
        }

        return picker
    }
    
    private func setupCommonHandlers(for picker: TLPhotosPickerViewController) {
        picker.didExceedMaximumNumberOfSelection = { [weak self] picker in
//            self?.showExceededMaximumAlert(vc: picker)
            print("didExceedMaximumNumberOfSelection")
        }

        picker.handleNoAlbumPermissions = { [weak self] picker in
            self?.handleNoAlbumPermissions(picker: picker)
        }

        picker.handleNoCameraPermissions = { [weak self] picker in
            self?.handleNoCameraPermissions(picker: picker)
        }
    }
    
    
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        picker.dismiss(animated: true) {
            self.showPermissionAlert(
                for: "Photo Library",
                message: "Please grant photo library access in Settings to select photos.",
                on: self
            )
        }
    }

    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        showPermissionAlert(
            for: "Camera",
            message: "Please grant camera access in Settings to take photos.",
            on: picker
        )
    }
    private func showPermissionAlert(for feature: String, message: String, on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "\(feature) Access Required",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)
    }


}

extension HomeViewController: ImageScannerControllerDelegate {
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        assertionFailure("Error occurred: \(error)")
    }

    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        scanner.dismiss(animated: true, completion: nil)
    }

    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }

}

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }
        let scannerViewController = ImageScannerController(image: image, delegate: self)
        present(scannerViewController, animated: true)
    }
}

extension HomeViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        let images = withTLPHAssets.map { value in
            value.fullResolutionImage
        }
        
    }
}


extension HomeViewController: TLPhotosPickerLogDelegate {

    func selectedCameraCell(picker: TLPhotosPickerViewController) {
        print("📷 Camera cell tapped")
    }

    func selectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("✅ Photo selected at index: \(index)")
        print("   Total selected: \(picker.selectedAssets.count)")
    }

    func deselectedPhoto(picker: TLPhotosPickerViewController, at index: Int) {
        print("❌ Photo deselected at index: \(index)")
        print("   Total selected: \(picker.selectedAssets.count)")
    }

    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at index: Int) {
        print("📁 Album selected: '\(title)' at index: \(index)")
    }
}
