//
//  ListImagePickedController.swift
//  WeScan
//
//  Created by TaiDM on 15/3/26.
//

import AVFoundation
import UIKit

public protocol ListImageScannerControllerDelegate: AnyObject {
    func onFinishPicking(results: [ImageScannerResults])
    func onCancel()
}

public final class ListImagePickedController: UIViewController {
    // MARK: - UI Components
    private var imageResults: [ImageScannerResults] = []
    private var currentIndex: Int = 0
    public weak var delegate: ListImageScannerControllerDelegate?

    public required init(imageResults: [ImageScannerResults]) {
        self.imageResults = imageResults
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
            pagerCollectionView.layoutIfNeeded()
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
        pagerContainer.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.6)
            .isActive = true

        pagerCollectionView.dataSource = self
        pagerCollectionView.delegate = self
        pagerCollectionView.register(
            ImagePagerCell.self, forCellWithReuseIdentifier: "ImagePagerCell")
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
            editDeleteStack.bottomAnchor.constraint(
                equalTo: pagerContainer.bottomAnchor, constant: -16),
            editDeleteStack.trailingAnchor.constraint(
                equalTo: pagerContainer.trailingAnchor, constant: -16),
            editDeleteStack.heightAnchor.constraint(equalToConstant: 48),
        ])

        stackView.addArrangedSubview(pagerContainer)

        // Thumbnails + Add button
        let thumbContainer = UIView()
        thumbContainer.translatesAutoresizingMaskIntoConstraints = false

        let thumbStack = UIStackView()
        thumbStack.axis = .horizontal
        thumbStack.spacing = 8
        thumbStack.distribution = .fill
        thumbStack.translatesAutoresizingMaskIntoConstraints = false
        thumbStack.alignment = .center

        thumbnailCollectionView.dataSource = self
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.register(
            ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailCollectionView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        thumbnailCollectionView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive =
            true

        addButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        thumbStack.addArrangedSubview(thumbnailCollectionView)
        // thumbStack.addArrangedSubview(addButton)

        thumbContainer.addSubview(thumbStack)
        stackView.addArrangedSubview(thumbContainer)
        thumbStack.heightAnchor.constraint(equalToConstant: 70).isActive = true

        NSLayoutConstraint.activate([
            thumbStack.leadingAnchor.constraint(
                equalTo: thumbContainer.leadingAnchor, constant: 16),
            thumbStack.trailingAnchor.constraint(
                equalTo: thumbContainer.trailingAnchor, constant: -16),
            thumbStack.topAnchor.constraint(equalTo: thumbContainer.topAnchor),
            thumbStack.bottomAnchor.constraint(equalTo: thumbContainer.bottomAnchor),
        ])

        // Button row
        let buttonStack = UIStackView(arrangedSubviews: [discardButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        stackView.addArrangedSubview(buttonStack)
        buttonStack.heightAnchor.constraint(equalToConstant: 44).isActive = true

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
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
        guard imageResults.count > 0 else { return }
        let alert = UIAlertController(
            title: "Xoá ảnh", message: "Bạn có chắc muốn xoá ảnh này?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "Xoá", style: .destructive,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.imageResults.remove(at: self.currentIndex)
                    if self.currentIndex >= self.imageResults.count {
                        self.currentIndex = max(self.imageResults.count - 1, 0)
                    }
                    self.pagerCollectionView.performBatchUpdates(
                        {
                            self.pagerCollectionView.reloadData()
                        },
                        completion: { _ in
                            if self.imageResults.count > 0 {
                                self.pagerCollectionView.scrollToItem(
                                    at: IndexPath(item: self.currentIndex, section: 0),
                                    at: .centeredHorizontally, animated: true)
                            }
                        })
                    self.thumbnailCollectionView.performBatchUpdates(
                        {
                            self.thumbnailCollectionView.reloadData()
                        },
                        completion: { _ in
                            if self.imageResults.count > 0 {
                                self.thumbnailCollectionView.scrollToItem(
                                    at: IndexPath(item: self.currentIndex, section: 0),
                                    at: .centeredHorizontally, animated: true)
                            }
                        })
                    if self.imageResults.isEmpty {
                        self.delegate?.onCancel()
                        self.dismiss(animated: true, completion: nil)
                    }
                }))
        present(alert, animated: true, completion: nil)
    }

    @objc private func nextTapped() {
        delegate?.onFinishPicking(results: imageResults)
        self.dismiss(animated: true)
    }

    @objc private func discardTapped() {
        let alert = UIAlertController(
            title: "Bỏ qua ảnh", message: "Bạn có chắc muốn đóng và hủy các ảnh đã chọn?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "Đồng ý", style: .destructive,
                handler: { [weak self] _ in
                    self?.delegate?.onCancel()
                    self?.dismiss(animated: true, completion: nil)
                }))
        present(alert, animated: true, completion: nil)
    }

    @objc private func editTapped() {
        guard imageResults.indices.contains(currentIndex) else { return }
        let imageToEdit = imageResults[currentIndex]
        let editViewController = EditScanViewController(
            image: imageToEdit.originalScan.image, quad: imageToEdit.detectedRectangle,
            rotateImage: false)
        editViewController.delegate = self
        self.present(editViewController, animated: true)
    }

    @objc private func addTapped() {
        // Handle add image action
    }
}

// MARK: - CollectionView DataSource & Delegate
extension ListImagePickedController: UICollectionViewDataSource, UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{
    public func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return imageResults.count
    }

    public func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if collectionView == pagerCollectionView {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ImagePagerCell", for: indexPath) as! ImagePagerCell
            cell.configure(with: imageResults[indexPath.item])
            return cell
        } else {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
            cell.configure(
                with: imageResults[indexPath.item], isSelected: indexPath.item == currentIndex,
                index: indexPath.item)
            return cell
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        if collectionView == thumbnailCollectionView {
            currentIndex = indexPath.item
            pagerCollectionView.scrollToItem(
                at: indexPath, at: .centeredHorizontally, animated: true)
            thumbnailCollectionView.reloadData()
            // Scroll selected thumbnail to center
            thumbnailCollectionView.scrollToItem(
                at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == pagerCollectionView {
            let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
            currentIndex = page
            thumbnailCollectionView.reloadData()
            // Scroll thumbnail to center when pager changes
            let indexPath = IndexPath(item: currentIndex, section: 0)
            thumbnailCollectionView.scrollToItem(
                at: indexPath, at: .centeredHorizontally, animated: true)
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
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:") }
    func configure(with scannerResult: ImageScannerResults) {
        imageView.image = scannerResult.croppedScan.image
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
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
            indexLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:") }
    func configure(with image: ImageScannerResults, isSelected: Bool, index: Int) {
        imageView.image = image.croppedScan.image
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        contentView.layer.cornerRadius = 8
        indexLabel.text = "\(index + 1)"
    }
}

extension ListImagePickedController: EditScanViewControllerDelegate {
    public func onEditResult(result: ImageScannerResults) {
        guard imageResults.indices.contains(currentIndex) else { return }
        imageResults[currentIndex].croppedScan = result.croppedScan
        imageResults[currentIndex].enhancedScan = result.enhancedScan
        imageResults[currentIndex].detectedRectangle = result.detectedRectangle
        thumbnailCollectionView.reloadData()
        pagerCollectionView.reloadData()
    }
}
