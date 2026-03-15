//
//  ListImagePickedController.swift
//  WeScan
//
//  Created by TaiDM on 15/3/26.
//

import AVFoundation
import UIKit

public final class ListImagePickedController: UIViewController {
	// MARK: - UI Components
	private var images: [UIImage] = []
	private var currentIndex: Int = 0

    public required init (images: [UIImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func squareImage(_ image: UIImage, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

	private let pagerCollectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumLineSpacing = 0
		layout.itemSize = UIScreen.main.bounds.size
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.isPagingEnabled = true
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.backgroundColor = .clear
		return collectionView
	}()

	private let thumbnailCollectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumLineSpacing = 8
		layout.itemSize = CGSize(width: 60, height: 60)
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.backgroundColor = .clear
		return collectionView
	}()

	private let nextButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Tiếp theo", for: .normal)
		return button
	}()

	private let discardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Bỏ qua", for: .normal)
		button.setTitleColor(.red, for: .normal)
		return button
	}()

	private let editButton: UIButton = {
		let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16)
		let editImage = UIImage(systemName: "pencil", withConfiguration: config)
		button.setImage(editImage, for: .normal)
		button.tintColor = .white
		button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
		button.clipsToBounds = true
		button.layer.masksToBounds = true
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
	}()

	private let deleteButton: UIButton = {
		let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16)
		let deleteImage = UIImage(systemName: "trash", withConfiguration: config)
		button.setImage(deleteImage, for: .normal)
		button.tintColor = .white
		button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
		button.clipsToBounds = true
		button.layer.masksToBounds = true
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
		return button
	}()

	private let addButton: UIButton = {
		let button = UIButton(type: .system)
		let addImage = UIImage(systemName: "plus")
		button.setImage(addImage, for: .normal)
		return button
	}()

	// MARK: - Lifecycle
	public override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		setupActions()
		thumbnailCollectionView.reloadData()
	}
    
    public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		editButton.layer.cornerRadius = (editButton.bounds.height / 2)
		deleteButton.layer.cornerRadius = (deleteButton.bounds.height / 2)

		if let layout = pagerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			let size = pagerCollectionView.frame.size
			if layout.itemSize != size {
				layout.itemSize = size
				layout.invalidateLayout()
			}
		}
    }
    

	// MARK: - Setup UI
	private func setupUI() {
		view.backgroundColor = .white
		// Vertical stack
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.spacing = 16
		stackView.translatesAutoresizingMaskIntoConstraints = false

		// Pager with edit & delete buttons overlay
		let pagerContainer = UIView()
		pagerContainer.translatesAutoresizingMaskIntoConstraints = false
		pagerContainer.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.6).isActive = true

		pagerCollectionView.dataSource = self
		pagerCollectionView.delegate = self
		pagerCollectionView.register(ImagePagerCell.self, forCellWithReuseIdentifier: "ImagePagerCell")
		pagerCollectionView.translatesAutoresizingMaskIntoConstraints = false
		pagerContainer.addSubview(pagerCollectionView)

		// Edit & Delete stack at bottom right
		let editDeleteStack = UIStackView(arrangedSubviews: [editButton, deleteButton])
		editDeleteStack.axis = .horizontal
		editDeleteStack.spacing = 8
		editDeleteStack.distribution = .fillProportionally
		editDeleteStack.translatesAutoresizingMaskIntoConstraints = false
		pagerContainer.addSubview(editDeleteStack)

		NSLayoutConstraint.activate([
			pagerCollectionView.topAnchor.constraint(equalTo: pagerContainer.topAnchor),
			pagerCollectionView.leadingAnchor.constraint(equalTo: pagerContainer.leadingAnchor),
			pagerCollectionView.trailingAnchor.constraint(equalTo: pagerContainer.trailingAnchor),
			pagerCollectionView.bottomAnchor.constraint(equalTo: pagerContainer.bottomAnchor),
			editDeleteStack.bottomAnchor.constraint(equalTo: pagerContainer.bottomAnchor, constant: -16),
			editDeleteStack.trailingAnchor.constraint(equalTo: pagerContainer.trailingAnchor, constant: -16),
			editDeleteStack.heightAnchor.constraint(equalToConstant: 48)
		])

		stackView.addArrangedSubview(pagerContainer)

		// Thumbnails + Add button
		let thumbStack = UIStackView()
		thumbStack.axis = .horizontal
		thumbStack.spacing = 8
		thumbStack.distribution = .fill
		thumbStack.translatesAutoresizingMaskIntoConstraints = false
		thumbStack.alignment = .center

		thumbnailCollectionView.dataSource = self
		thumbnailCollectionView.delegate = self
		thumbnailCollectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
		thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailCollectionView.heightAnchor.constraint(equalToConstant: 60).isActive = true
		thumbnailCollectionView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true

		addButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
		addButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

		thumbStack.addArrangedSubview(thumbnailCollectionView)
		thumbStack.addArrangedSubview(addButton)

		stackView.addArrangedSubview(thumbStack)
		thumbStack.heightAnchor.constraint(equalToConstant: 70).isActive = true

		// Button row
		let buttonStack = UIStackView(arrangedSubviews: [discardButton, nextButton])
		buttonStack.axis = .horizontal
		buttonStack.spacing = 16
		buttonStack.distribution = .fillEqually
		stackView.addArrangedSubview(buttonStack)
		buttonStack.heightAnchor.constraint(equalToConstant: 44).isActive = true

		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
			stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
		])
	}

	// MARK: - Actions
	private func setupActions() {
		nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
		discardButton.addTarget(self, action: #selector(discardTapped), for: .touchUpInside)
		editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
		deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
		addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
	}

    @objc private func deleteTapped() {
        guard images.count > 0 else { return }
        let alert = UIAlertController(title: "Xoá ảnh", message: "Bạn có chắc muốn xoá ảnh này?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Xoá", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.images.remove(at: self.currentIndex)
            if self.currentIndex >= self.images.count {
                self.currentIndex = max(self.images.count - 1, 0)
            }
            self.pagerCollectionView.performBatchUpdates({
                self.pagerCollectionView.reloadData()
            }, completion: { _ in
                if self.images.count > 0 {
                    self.pagerCollectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: .centeredHorizontally, animated: true)
                }
            })
            self.thumbnailCollectionView.performBatchUpdates({
                self.thumbnailCollectionView.reloadData()
            }, completion: { _ in
                if self.images.count > 0 {
                    self.thumbnailCollectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: .centeredHorizontally, animated: true)
                }
            })
            if self.images.isEmpty {
                self.dismiss(animated: true, completion: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
	@objc private func nextTapped() {
		// Handle next action
	}

	@objc private func discardTapped() {
        let alert = UIAlertController(title: "Bỏ qua ảnh", message: "Bạn có chắc muốn đóng và hủy các ảnh đã chọn?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Đồng ý", style: .destructive, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }

	@objc private func editTapped() {
		guard images.indices.contains(currentIndex) else { return }
		let imageToEdit = images[currentIndex]
		// TODO: Thực hiện logic chỉnh sửa với imageToEdit
		print("Editing image at index \(currentIndex)")
        
        detect(image: imageToEdit) { [weak self] detectedQuad in
            guard let self else { return }
             let editViewController = EditScanViewController(image: imageToEdit, quad: detectedQuad, rotateImage: false)
            editViewController.delegate = self
            self.present(editViewController, animated: true)
//             self.setViewControllers([editViewController], animated: false)
            print("Detect iamge: \(detectedQuad)")
        }
	}

	@objc private func addTapped() {
		// Handle add image action
	}
    
    private func detect(image: UIImage, completion: @escaping (Quadrilateral?) -> Void) {
        // Whether or not we detect a quad, present the edit view controller after attempting to detect a quad.
        // *** Vision *requires* a completion block to detect rectangles, but it's instant.
        // *** When using Vision, we'll present the normal edit view controller first, then present the updated edit view controller later.

        guard let ciImage = CIImage(image: image) else { return }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

        if #available(iOS 11.0, *) {
            // Use the VisionRectangleDetector on iOS 11 to attempt to find a rectangle from the initial image.
            VisionRectangleDetector.rectangle(forImage: ciImage, orientation: orientation) { quad in
                let detectedQuad = quad?.toCartesian(withHeight: orientedImage.extent.height)
                completion(detectedQuad)
            }
        } else {
            // Use the CIRectangleDetector on iOS 10 to attempt to find a rectangle from the initial image.
            let detectedQuad = CIRectangleDetector.rectangle(forImage: ciImage)?.toCartesian(withHeight: orientedImage.extent.height)
            completion(detectedQuad)
        }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension ListImagePickedController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return images.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if collectionView == pagerCollectionView {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePagerCell", for: indexPath) as! ImagePagerCell
			cell.configure(with: images[indexPath.item])
			return cell
		} else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
			cell.configure(with: images[indexPath.item], isSelected: indexPath.item == currentIndex, index: indexPath.item)
			return cell
		}
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if collectionView == thumbnailCollectionView {
			currentIndex = indexPath.item
			pagerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
			thumbnailCollectionView.reloadData()
		}
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if scrollView == pagerCollectionView {
			let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
			currentIndex = page
			thumbnailCollectionView.reloadData()
		}
	}
}

// MARK: - Cells
class ImagePagerCell: UICollectionViewCell {
	private let imageView = UIImageView()
	override init(frame: CGRect) {
		super.init(frame: frame)
		imageView.contentMode = .scaleAspectFit
		imageView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(imageView)
		NSLayoutConstraint.activate([
			imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
		])
	}
	required init?(coder: NSCoder) { fatalError("init(coder:") }
	func configure(with image: UIImage) {
		imageView.image = image
	}
}

class ThumbnailCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let indexLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        // Setup index label
        indexLabel.font = UIFont.boldSystemFont(ofSize: 14)
        indexLabel.textColor = .white
        indexLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        indexLabel.textAlignment = .center
        indexLabel.layer.cornerRadius = 12
        indexLabel.layer.masksToBounds = true
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(indexLabel)
        NSLayoutConstraint.activate([
            indexLabel.heightAnchor.constraint(equalToConstant: 24),
            indexLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            indexLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            indexLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:") }
    func configure(with image: UIImage, isSelected: Bool, index: Int) {
        imageView.image = image
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        contentView.layer.cornerRadius = 8
        indexLabel.text = "\(index + 1)"
    }
}

extension ListImagePickedController: EditScanViewControllerDelegate{
    public func onEditResult(result: ImageScannerResults) {
        
    }
}
