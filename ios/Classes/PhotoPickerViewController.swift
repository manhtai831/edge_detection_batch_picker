//
//  ScanPhotoViewController.swift
//  edge_detection
//
//  Created by Henry Leung on 3/9/2021.
//

import WeScan
import Flutter
import Foundation
import TLPhotoPicker

class PhotoPickerViewController: UIViewController, ImageScannerControllerDelegate, UINavigationControllerDelegate {
    
    var _result:FlutterResult?
    var saveTo: String = ""
    var selectedAssets = [TLPHAsset]()
    var imagesPicked: [UIImage] = []
    var isViewDidAppeared = false
//    
//    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true)
//        
//        _result!(false)
//        dismiss(animated: true)
//    }
//    
//    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//        picker.dismiss(animated: true)
//        
//        guard let image = info[.originalImage] as? UIImage else { return }
//        let scannerVC = ImageScannerController(image: image)
//        scannerVC.imageScannerDelegate = self
//        
//        scannerVC.isModalInPresentation = true
//        scannerVC.overrideUserInterfaceStyle = .dark
//        scannerVC.view.backgroundColor = .black
//        present(scannerVC, animated: true)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isViewDidAppeared {
            return
        }
        isViewDidAppeared = true
        selectMultipleImage()
    }

    func selectMultipleImage(){
        let picker = createPicker(
            TLPhotosPickerViewController(),
            withLogDelegate: false
        ) { picker in
            picker.configure = TLPhotosPickerConfigure()
                .numberOfColumns(3)
                .maxSelection(15)
                .mediaType(.image)
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

    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
        _result!(false)
        self.dismiss(animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: [ImageScannerResults]) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        
        
//        saveImage(image:results.doesUserPreferEnhancedScan ? results.enhancedScan!.image : results.croppedScan.image)
        _result!(true)
        self.dismiss(animated: true)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        _result!(false)
        self.dismiss(animated: true)
    }
    
    
    func saveImage(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return nil
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        var fileName = randomString(length:10);
        let filePath: URL = directory.appendingPathComponent(fileName + ".png")!
        
        do {
            let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: filePath.path) {
                // Delete file
                try fileManager.removeItem(atPath: filePath.path)
            } else {
                print("File does not exist")
            }
            
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
        
        do {
            try data.write(to: filePath)
            try FileManager.default.moveItem(atPath: filePath.path, toPath: self.saveTo)
            return self.saveTo
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}


extension PhotoPickerViewController: TLPhotosPickerViewControllerDelegate {

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
