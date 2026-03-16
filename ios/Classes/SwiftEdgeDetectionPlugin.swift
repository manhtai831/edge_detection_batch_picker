import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "edge_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftEdgeDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let saveTo = ""
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false
        let params = PluginParams.fromJson(json: args)
        if call.method == "edge_detect" {
            if let viewController = keyWindow()?.rootViewController as? FlutterViewController {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(params: params)
                destinationViewController._result = result
                viewController.present(destinationViewController, animated: true, completion: nil)
            }
        }
        if call.method == "edge_detect_gallery" {
            if let viewController = keyWindow()?.rootViewController as? FlutterViewController {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(params: params)
                destinationViewController._result = result
                // destinationViewController.selectPhoto()
                viewController.present(destinationViewController, animated: true, completion: nil)
            }
        }
    }
}

public struct PluginParams {
    public var saveTo: String?
    public var fromGallery: Bool
    public var androidCropTitle: String?
    public var androidCropBlackWhiteTitle: String?
    public var androidCropReset: String?
    public var maxImageGallery: Int?

    public static func fromJson(json: [String: Any]) -> PluginParams {
        return PluginParams(
            saveTo: json["save_to"] as? String,
            fromGallery: json["from_gallery"] as? Bool ?? false,
            androidCropTitle: json["crop_title"] as? String ?? "Crop",
            androidCropBlackWhiteTitle: json["crop_black_white_title"] as? String ?? "Black White",
            androidCropReset: json["crop_reset_title"] as? String ?? "Reset",
            maxImageGallery: json["max_image_gallery"] as? Int
        )
    }
}
