//
//  AssetCell.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import UIKit
import Reusable
import Nuke

protocol AssetCellModelType {
    var title: String? { get }
    var description: String? { get }
    var imageURL: URL? { get }
}

final class AssetCell: UITableViewCell, NibReusable {

    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    override public func prepareForReuse() {
        super.prepareForReuse()
        Nuke.cancelRequest(for: assetImageView)
    }

    @discardableResult
    func configure(_ cellModel: AssetCellModelType) -> AssetCell {
        let placeholder = UIImage(named: "placeholder")
        Nuke.loadImage(
            with: cellModel.imageURL,
            options: .init(placeholder: placeholder, transition: .fadeIn(duration: 0.25)),
            into: assetImageView
        )
        nameLabel.text = cellModel.title
        descriptionLabel.text = cellModel.description
        return self
    }
}
