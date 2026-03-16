import Flutter
import Foundation
import TLPhotoPicker
import WeScan

class HomeViewController: UIViewController, ImageScannerControllerDelegate {

    var cameraController: ImageScannerController!
    var _result: FlutterResult?

    var saveTo: String = ""
    var canUseGallery: Bool = true
    var selectedAssets = [TLPHAsset]()
    var imagesPicked: [UIImage] = []

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        if self.isBeingPresented {
        //            cameraController = ImageScannerController()
        //            cameraController.imageScannerDelegate = self
        //            cameraController.isModalInPresentation = true
        //            cameraController.overrideUserInterfaceStyle = .dark
        //            cameraController.view.backgroundColor = .black
        //
        //            // Temp fix for https://github.com/WeTransfer/WeScan/issues/320
        //            let appearance = UINavigationBarAppearance()
        //            appearance.configureWithOpaqueBackground()
        //            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        //            appearance.backgroundColor = .systemBackground
        //            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        //
        //            let appearanceTB = UITabBarAppearance()
        //            appearanceTB.configureWithOpaqueBackground()
        //            appearanceTB.backgroundColor = .systemBackground
        //            UITabBar.appearance().standardAppearance = appearanceTB
        //            UITabBar.appearance().scrollEdgeAppearance = appearanceTB
        //
        //            present(cameraController, animated: true) {
        //                if let window = self.keyWindow() {
        //                    window.addSubview(self.selectPhotoButton)
        //                    self.setupConstraints()
        //                }
        //            }
        //        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if canUseGallery == true {
            selectPhotoButton.isHidden = false
        }
    }

    lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(
            UIImage(
                named: "gallery", in: Bundle(for: SwiftEdgeDetectionPlugin.self),
                compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    @objc private func cancelImageScannerController() {
        hideButtons()

        _result!(false)
        cameraController?.dismiss(animated: true)
        dismiss(animated: true)
    }

    @objc func selectPhoto() {
        //        if let window = keyWindow() {
        //            window.rootViewController?.dismiss(animated: true, completion: nil)
        //            self.hideButtons()
        //
        //            let scanPhotoVC =  PhotoPickerViewController()
        //            scanPhotoVC._result = _result
        //            scanPhotoVC.saveTo = self.saveTo
        //            scanPhotoVC.isModalInPresentation = true
        //            scanPhotoVC.overrideUserInterfaceStyle = .dark
        //            window.rootViewController?.present(scanPhotoVC, animated: true)
        //        }
        selectMultipleImage()
    }

    func hideButtons() {
        selectPhotoButton.isHidden = true
    }

    private func setupConstraints() {
        let selectPhotoButtonConstraints = [
            selectPhotoButton.widthAnchor.constraint(equalToConstant: 44.0),
            selectPhotoButton.heightAnchor.constraint(equalToConstant: 44.0),
            selectPhotoButton.rightAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -24.0),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(
                equalTo: selectPhotoButton.bottomAnchor, constant: (65.0 / 2) - 10.0),
        ]
        NSLayoutConstraint.activate(selectPhotoButtonConstraints)
    }

    func setParams(saveTo: String, canUseGallery: Bool) {
        self.saveTo = saveTo
        self.canUseGallery = canUseGallery
    }

    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
        _result!(false)
        self.hideButtons()
        self.dismiss(animated: true)
    }

    func imageScannerController(
        _ scanner: ImageScannerController,
        didFinishScanningWithResults results: [ImageScannerResults]
    ) {
        // Your ViewController is responsible for dismissing the ImageScannerController

        scanner.dismiss(animated: true)
        self.hideButtons()

        for item in results {
            saveImage(
                image: item.doesUserPreferEnhancedScan
                    ? item.enhancedScan!.image : item.croppedScan.image)
        }

        _result!(true)
        self.dismiss(animated: true)
    }

    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        self.hideButtons()

        _result!(false)
        self.dismiss(animated: true)
    }

    func saveImage(image: UIImage) -> Bool? {

        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return false
        }

        let path: String =
            "file://" + self.saveTo.addingPercentEncoding(
                withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let filePath: URL = URL.init(string: path)!

        do {
            let fileManager = FileManager.default
            // Check if file exists
            if fileManager.fileExists(atPath: filePath.path) {
                // Delete file
                try fileManager.removeItem(atPath: filePath.path)
            } else {
                print("File does not exist")
            }
        } catch let error as NSError {
            print("An error took place: \(error)")
        }

        do {
            try data.write(to: filePath)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

extension HomeViewController {

    func selectMultipleImage() {
        let picker = createPicker(
            TLPhotosPickerViewController(),
            withLogDelegate: false
        ) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(3)
                .maxSelection(15)
                .mediaType(.image)
        }
        if let window = keyWindow() {
            window.rootViewController?.present(picker, animated: true)
        }
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
    private func showPermissionAlert(
        for feature: String, message: String, on viewController: UIViewController
    ) {
        let alert = UIAlertController(
            title: "\(feature) Access Required",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)
    }
}

extension HomeViewController: TLPhotosPickerViewControllerDelegate {

    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        let images = withTLPHAssets.compactMap { $0.fullResolutionImage }
        imagesPicked = images
        print("dismissPhotoPicker with \(images.count) images")
    }

    func dismissComplete() {
        print("dismissComplete")
//        if imagesPicked.isEmpty {
//            return
//        }
        let scannerViewController = ImageScannerController(images: imagesPicked, delegate: self)
         let window = self.keyWindow()
            window?.rootViewController?.present(scannerViewController, animated: true)
    }
}
