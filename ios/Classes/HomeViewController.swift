import Flutter
import Foundation
import TLPhotoPicker
import WeScan

class HomeViewController: UIViewController, ImageScannerControllerDelegate {

    var cameraController: ImageScannerController!
    var _result: FlutterResult?

    var params: PluginParams?
    var selectedAssets = [TLPHAsset]()
    var imagesPicked: [UIImage] = []
    var isViewDidAppearCalled = false

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isViewDidAppearCalled {
            isViewDidAppearCalled = true
            selectMultipleImage()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if params?.fromGallery == true {
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

    func setParams(params: PluginParams) {
        self.params = params
    }

    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
        _result!(nil)
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

        var imagesResult = [String]()
        for item in results {
            let imagePath = saveImage(
                image: item.doesUserPreferEnhancedScan
                    ? item.enhancedScan!.image : item.croppedScan.image)
            if let imagePath = imagePath {
                imagesResult.append(imagePath)
            }
        }
        _result!(imagesResult)
        self.dismiss(animated: true)
    }

    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        self.hideButtons()

        _result!(nil)
        self.dismiss(animated: true)
    }

    func saveImage(image: UIImage) -> String? {

        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return nil
        }
        let uuid = UUID().uuidString
        let tmpPath = FileManager.default.temporaryDirectory
        let filePath: URL = tmpPath.appendingPathComponent("/scan_\(uuid).jpg")

        do {
            let fileManager = FileManager.default
            // Check if file exists
            if fileManager.fileExists(atPath: filePath.path) {
                // Delete file
                try fileManager.removeItem(atPath: filePath.path)
            }
        } catch let error as NSError {
            print("An error took place: \(error)")
        }

        do {
            try data.write(to: filePath)
            return filePath.path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

extension HomeViewController {

    func selectMultipleImage() {
        let picker = createPicker(
            TLPhotosPickerViewController(),
            withLogDelegate: false
        ) { picker in
            var config = TLPhotosPickerConfigure()
                .numberOfColumns(3)
                .mediaType(.image)

            if let maxSelection = self.params?.maxImageGallery {
                config = config.maxSelection(maxSelection)
            }
            
            picker.configure = config
        }

        self.present(picker, animated: true)
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
            self?.showExceededMaximumAlert(vc: picker)
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
                message: "Vui lòng cấp quyền truy cập thư viện ảnh trong phần Cài đặt để chọn ảnh.",
                on: self
            )
        }
    }

    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        showPermissionAlert(
            for: "Camera",
            message: "Vui lòng cấp quyền truy cập camera trong phần Cài đặt để chụp ảnh.",
            on: picker
        )
    }
    
    private func showExceededMaximumAlert(vc: UIViewController) {
        let alert = UIAlertController(
            title: "Đã đạt giới hạn lựa chọn",
            message: "Bạn đã đạt đến số lượng lựa chọn tối đa.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
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
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        viewController.present(alert, animated: true)
    }
}

extension HomeViewController: TLPhotosPickerViewControllerDelegate {

    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        let images = withTLPHAssets.compactMap { $0.fullResolutionImage }
        imagesPicked = images
    }

    func dismissComplete() {
        if imagesPicked.isEmpty {
            return
        }
        let scannerViewController = ImageScannerController(images: imagesPicked, delegate: self)
        self.present(scannerViewController, animated: true)
    }
}
