//
//  UIScrollView+Rx.swift
//  RxPaginationExample
//
//  Created by Khoi Truong Minh on 4/15/22.
//

import RxCocoa
import RxSwift
import RxSwiftExt
import UIKit

public extension Reactive where Base: UIScrollView {

    var loadNextTrigger: ControlEvent<Void> {

        let trigger = didScroll.flatMap { [weak base] _ -> Observable<Void> in

            guard let scrollView = base else { return Observable.empty() }

            var refreshControl: UIRefreshControl?
            if #available(iOS 10.0, *) {
                refreshControl = scrollView.refreshControl
            } else {
                refreshControl = scrollView.subviews.first(where: { $0 is UIRefreshControl }) as? UIRefreshControl
            }
            guard refreshControl?.isRefreshing != true else { return Observable.empty() }

            guard scrollView.panGestureRecognizer.state != .possible else { return Observable.empty() }

            let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            guard translation.y < 0 else {
                // swipes from bottom to top of screen -> up
                return Observable.empty()
            }

            // swipes from top to bottom of screen -> down
            let currentOffsetY = scrollView.contentOffset.y
            guard currentOffsetY > 0 else { return Observable.empty() }

            let contentHeight = scrollView.contentSize.height
            let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
            let remainingScreen = (contentHeight - currentOffsetY) / visibleHeight

            return remainingScreen <= 2 ? Observable.just(()) : Observable.empty()
        }

        let throttleTrigger = trigger.throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)

        return ControlEvent(events: throttleTrigger)
    }

    var loadPreviousTrigger: ControlEvent<Void> {

        let trigger = didScroll.flatMap { [weak base] _ -> Observable<Void> in
            let threshold: CGFloat = 400
            guard let scrollView = base else { return Observable.empty() }

            var refreshControl: UIRefreshControl?
            if #available(iOS 10.0, *) {
                refreshControl = scrollView.refreshControl
            } else {
                refreshControl = scrollView.subviews.first(where: { $0 is UIRefreshControl }) as? UIRefreshControl
            }
            guard refreshControl?.isRefreshing != true else { return Observable.empty() }

            guard scrollView.panGestureRecognizer.state != .possible else { return Observable.empty() }

            let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            guard translation.y <= threshold else {
                // swipes from bottom to top of screen -> up
                return Observable.empty()
            }

            // swipes from top to bottom of screen -> down
            let currentOffsetY = scrollView.contentOffset.y
            guard currentOffsetY <= 0 else { return Observable.empty() }

            let contentHeight = scrollView.contentSize.height
            let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
            let remainingScreen = (contentHeight - currentOffsetY) / visibleHeight

            return remainingScreen < threshold ? Observable.just(()) : Observable.empty()
        }

        let throttleTrigger = trigger.throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)

        return ControlEvent(events: throttleTrigger)
    }
}
