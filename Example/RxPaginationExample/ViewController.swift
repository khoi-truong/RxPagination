//
//  ViewController.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import UIKit
import RxSwift
import RxCocoa
import RxPagination
import RxDataSources
import Reusable

final class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private var refreshControl = UIRefreshControl()

    let items = BehaviorRelay<[AssetCellModel]>(value: [])

    private lazy var getAssetsAction = self.initGetAssetsAction()
    private let assets = BehaviorRelay<[Asset]>(value: [])

    private let dataSource = initDataSource()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addSubview(refreshControl)
        tableView.register(cellType: AssetCell.self)
        tableView.estimatedRowHeight = 144
        tableView.rowHeight = 144

        items.asDriver()
            .map { [Section(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        assets
            .mapMany(AssetCellModel.init)
            .bind(to: items)
            .disposed(by: disposeBag)

        getAssetsAction.allItems
            .bind(to: assets)
            .disposed(by: disposeBag)

        getAssetsAction.executing.asDriver(onErrorDriveWith: .empty())
            .filter(!)
            .drive(onNext: { [weak self] _ in self?.refreshControl.endRefreshing() })
            .disposed(by: disposeBag)

        tableView.rx.didEndDecelerating.asDriver()
            .map { [weak self] in self?.refreshControl.isRefreshing }
            .filter { $0 == true }
            .drive(onNext: { [weak self] _ in self?.getAssetsAction.reload.accept(()) })
            .disposed(by: disposeBag)

        tableView.rx.loadNextTrigger
            .bind(to: getAssetsAction.next)
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getAssetsAction.reload.accept(())
    }

    private func initGetAssetsAction() -> OffsettingAction<Void, Assets> {
        .init(limit: 5, removeDuplicates: { $0.id }, request: { _, next in
            OpenSeaAPI.default.getAssets(next: next).asObservable()
        })
    }
}



// MARK: - DataSource

private typealias Section = AnimatableSectionModel<String, AssetCellModel>
private typealias DataSource = RxTableViewSectionedAnimatedDataSource<Section>

private func initDataSource() -> DataSource {
    DataSource(
        animationConfiguration: .init(
            insertAnimation: .fade,
            reloadAnimation: .fade,
            deleteAnimation: .fade
        ),
        configureCell: { _, tableView, indexPath, model -> UITableViewCell in
            tableView.dequeueReusableCell(for: indexPath, cellType: AssetCell.self).configure(model)
        }
    )
}
