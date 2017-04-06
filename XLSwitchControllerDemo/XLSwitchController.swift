//
//  XLSwitchController.swift
//  BetterSegmentedControl
//
//  Created by PixelShi on 2017/4/4.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

class XLSwitchController: UIControl, UIGestureRecognizerDelegate {

    /*
     IndicatorView
    */
    private class IndicatorView: UIView {
        let titleMaskView = UIView()

        var cornerRadius: CGFloat! {
            didSet {
                layer.cornerRadius = cornerRadius
                titleMaskView.layer.cornerRadius = cornerRadius
            }
        }

        override open var frame: CGRect {
            didSet {
                titleMaskView.frame = frame
            }
        }

        // MARK: - Lifecycle
        init() {
            super.init(frame: CGRect.zero)
            finishInit()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            finishInit()
        }

        fileprivate func finishInit() {
            layer.masksToBounds = true
            titleMaskView.backgroundColor = UIColor.black
        }
    }

    /*
     public property
    */
    /// selected index
    public private(set) var index: UInt
    /// titles
    public var titles: [String] {
        get {
            let titleLabel = titleLabelsView.subviews as! [UILabel]
            return titleLabel.map { $0.text! }
        }
        set {
            guard newValue.count < 1 else {
                return
            }
        }
    }
    /// selectedTitleColor
    public var selectedTitleColor: UIColor {
        didSet {
            guard selectedTitleLabels.isEmpty else {
                for label in selectedTitleLabels {
                    label.textColor = selectedTitleColor
                }
                return
            }
        }
    }
    /// titleColor
    public var titleColor: UIColor  {
        didSet {
            guard titleLabels.isEmpty else {
                for label in titleLabels {
                    label.textColor = titleColor
                }
                return
            }
        }
    }
    /// titleFont
    public var titleFont: UIFont = UILabel().font {
        didSet {
            guard titleLabels.isEmpty else {
                for label in titleLabels {
                    label.font = titleFont
                }
                return
            }
        }
    }
    /// selected label font
    public var selectedTitleFont: UIFont = UILabel().font {
        didSet {
            guard selectedTitleLabels.isEmpty else {
                for label in selectedTitleLabels {
                    label.font = selectedTitleFont
                }
                return
            }
        }
    }
    /// backgroudView cornerRadius
    public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            indicatorView.cornerRadius = newValue - indicatorViewInset
        }
    }
    /// The indicator view's background color
    @IBInspectable public var indicatorViewBackgroundColor: UIColor? {
        get {
            return indicatorView.backgroundColor
        }
        set {
            indicatorView.backgroundColor = newValue
        }
    }
    /// The indicator view's inset
    public var indicatorViewInset: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    public var tapGestureRecognizer: UITapGestureRecognizer!
    public var panGestureRecognizer: UIPanGestureRecognizer!
    /// gesture Control
    public var panningDisabled = false
    /// alwaysAnnouncesValue
    public var alwaysAnnouncesValue = false

    /*
     private property
    */
    private var width: CGFloat {
        return bounds.width
    }
    private var height: CGFloat {
        return bounds.height
    }
    private let titleLabelsView = UIView()
    private let selectedTitleLabelsView = UIView()
    private let indicatorView = IndicatorView()
    private var selectedTitleLabels: [UILabel] {
        return selectedTitleLabelsView.subviews as! [UILabel]
    }
    private var titleLabels: [UILabel] {
        return titleLabelsView.subviews as! [UILabel]
    }
    private var titleLabelsCount: Int {
        return titleLabelsView.subviews.count
    }
    private var initialIndicatorViewFrame: CGRect?
    private var totalInsetSize: CGFloat { return indicatorViewInset * 2.0 }
    

    /*
     init 方法
     */
    public init(frame: CGRect,
               titles: [String],
               index: UInt,
               backgroundColor: UIColor,
               titleColor: UIColor,
               indicatorViewBackgroundColor: UIColor,
               selectedTitleColor: UIColor) {
        self.index = index
        self.titleColor = titleColor
        self.selectedTitleColor = selectedTitleColor
        super.init(frame: frame)
        self.titles = titles
        self.backgroundColor = backgroundColor
        self.indicatorViewBackgroundColor = indicatorViewBackgroundColor
        initialise()
    }

    required init?(coder aDecoder: NSCoder) {
        self.index = 0
        self.titleColor = DefaultColors.titleColor
        self.selectedTitleColor = DefaultColors.selectedTitleColor
        super.init(coder: aDecoder)
        titles = DefaultColors.defaultTitles
        initialise()
    }

    private func initialise() {
        layer.masksToBounds = true

        addSubview(titleLabelsView)
        addSubview(indicatorView)
        addSubview(selectedTitleLabelsView)
        selectedTitleLabelsView.layer.mask = indicatorView.titleMaskView.layer

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(XLSwitchController.tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(XLSwitchController.pan(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        guard titleLabelsCount > 1 else {
            return
        }

        titleLabelsView.frame = bounds
        selectedTitleLabelsView.frame = bounds

        indicatorView.frame = elementFrame(forIndex: index)
        for index in 0...titleLabelsCount-1 {
            let frame = elementFrame(forIndex: UInt(index))
            titleLabelsView.subviews[index].frame = frame
            selectedTitleLabelsView.subviews[index].frame = frame
        }
    }

    // MARK: - Action handlers
    func tapped(_ gestureRecognizer: UITapGestureRecognizer!) {
        let location = gestureRecognizer.location(in: self)
        set(index: nearestIndex(toPoint: location))
    }

    func pan(_ gestureRecognizer: UIPanGestureRecognizer!) {
        guard !panningDisabled else {
            return
        }

        switch gestureRecognizer.state {
        case .began:
            initialIndicatorViewFrame = indicatorView.frame
        case .changed:
            var frame = initialIndicatorViewFrame!
            frame.origin.x += gestureRecognizer.translation(in: self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - indicatorViewInset - frame.width), indicatorViewInset)
            indicatorView.frame = frame
        case .ended, .failed, .cancelled:
            set(index: nearestIndex(toPoint: indicatorView.center))
        default: break
        }
    }

    func set(index: UInt, animated: Bool = true) {
        guard titleLabels.indices.contains(Int(index)) else {
            fatalError("index out of")
        }
        let oldIndex = self.index
        self.index = index
        moveIndicatorViewToIndex(animated, shouldSendEvent: (self.index != oldIndex || alwaysAnnouncesValue))
    }

    /// utils
    // MARK: - Helpers
    fileprivate func elementFrame(forIndex index: UInt) -> CGRect {
        let elementWidth = (width - totalInsetSize) / CGFloat(titleLabelsCount)
        return CGRect(x: CGFloat(index) * elementWidth + indicatorViewInset,
                      y: indicatorViewInset,
                      width: elementWidth,
                      height: height - totalInsetSize)
    }
    fileprivate func nearestIndex(toPoint point: CGPoint) -> UInt {
        let distances = titleLabels.map { abs(point.x - $0.center.x) }
        return UInt(distances.index(of: distances.min()!)!)
    }
    fileprivate func moveIndicatorView() {
        self.indicatorView.frame = self.titleLabels[Int(self.index)].frame
        self.layoutIfNeeded()
    }

    /// animation
    private func moveIndicatorViewToIndex(_ animated: Bool, shouldSendEvent: Bool) {

    }

    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            return indicatorView.frame.contains(gestureRecognizer.location(in: self))
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension XLSwitchController {
    // MARK: - Constants
    public struct AnimationParameters {
        static let animationWithBounceDuration: TimeInterval = 0.3
        static let animationWithBounceSpringDamping: CGFloat = 0.75
        static let animationNoBounceDuration: TimeInterval = 0.2
    }
    public struct DefaultColors {
        static let backgroundColor: UIColor = UIColor.white
        static let titleColor: UIColor = UIColor.black
        static let indicatorViewBackgroundColor: UIColor = UIColor.black
        static let selectedTitleColor: UIColor = UIColor.white
        static let defaultTitles: [String] = ["hello", "world"]
    }
}
