![Tests](https://github.com/khoi-truong/RxPagination/actions/workflows/tests.yml/badge.svg)

RxPagination
======

This library is used with [RxSwift](https://github.com/ReactiveX/RxSwift) to provide a easy way to handle paginated APIs.
RxPagination is based on [Action](https://github.com/RxSwiftCommunity/Action) also.

- Only execute one trigger(reload/next/previous) at a time.
- Aggregates next/error events across individual executions.

3 separated pagination styles:

- `PagingAction` uses `page`/`itemsPerPage`
- `OffsettingAction` uses `offset`/`limit`
- `CursoringAction` uses `next`/`previous`

Usage
-----

```swift
let pagingAction: PagingAction<String, SampleResponse> = PagingAction<String, SampleResponse>(
    itemsPerPage: 10,
    removeDuplicates: { $0.id },
    request: { (input, page) in
        return api.getItems(for: input, page: page)
    }
)

...

pagingAction.allItems.subscribe(onNext: { items in
    print(items)
})

pagingAction.errors.subscribe(onError: { error in
    print(error)
})

...

pagingAction.reload("Some Input")
pagingAction.next("Some Input")
```

Installing
----------

### CocoaPods

Just add the line below to your Podfile:

```ruby
pod 'RxPagination'
```

Then run `pod install` and that'll be 👌

Thanks
------

This library is inspired by [dangthaison91](https://github.com/dangthaison91), my colleague at VinID. And the implementation is based on RxCommunity's [Action](https://github.com/RxSwiftCommunity/Action). Those developers deserve a lot of thanks!

License
-------

MIT.
