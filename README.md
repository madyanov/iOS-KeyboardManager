**iOS 10+**

*Simple* keyboard manager with two features:

* Active text field is always visible.
* Tapping outside of the keyboard will dismiss it.

## Preview

![Preview](preview.gif)

## Properties

```swift
// spacing between keyboard and active text field
var spacing: CGFloat { get set }
```

## Methods

```swift
// start listening keyboard events
func start()

// stop listening keyboard events
func stop()
```
