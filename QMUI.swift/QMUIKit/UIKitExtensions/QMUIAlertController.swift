//
//  QMUIAlertController.swift
//  QMUI.swift
//
//  Created by xnxin on 2017/7/10.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

enum QMUIAlertControllerStyle: Int {
    case sheet = 0
    case alert
}

enum QMUIAlertActionStyle: Int {
    case `default` = 0
    case cancel
    case destructive
}

// MARK: Delegate

@objc protocol QMUIAlertControllerDelegate: NSObjectProtocol {
    @objc func willShow(_ alertController: QMUIAlertController)
    @objc func willHide(_ alertController: QMUIAlertController)
    @objc func didShow(_ alertController: QMUIAlertController)
    @objc func didHide(_ alertController: QMUIAlertController)
}

@objc private protocol QMUIAlertActionDelegate: NSObjectProtocol {
    @objc func didClick(_ alertAction: QMUIAlertAction)
}

// MARK: QMUIAlertController

/*
 *  `QMUIAlertController`是模仿系统`UIAlertController`的控件，所以系统有的功能在QMUIAlertController里面基本都有。同时`QMUIAlertController`还提供了一些扩展功能，例如：它的每个 button 都是开放出来的，可以对默认的按钮进行二次处理（比如加一个图片）；可以通过 QMUIAlertController.appearance() 在 app 启动的时候修改整个`QMUIAlertController`的主题样式。
 */
class QMUIAlertController: UIViewController, QMUIModalPresentationViewControllerDelegate, QMUIAlertActionDelegate {

    /// alert距离屏幕四边的间距，默认UIEdgeInsetsMake(0, 0, 0, 0)。alert的宽度最终是通过屏幕宽度减去水平的 alertContentMargin 和 alertContentMaximumWidth 决定的。
    @objc public dynamic var alertContentMargin: UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)

    /// alert的最大宽度，默认270。
    @objc public dynamic var alertContentMaximumWidth: CGFloat = 270

    /// alert上分隔线颜色，默认 UIColor(r: 211, g: 211, b: 219)。
    @objc public dynamic var alertSeperatorColor: UIColor = UIColor(r: 211, g: 211, b: 219) {
        didSet {
            updateEffectBackgroundColor()
        }
    }

    /// alert标题样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFontBoldMake(17), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)]
    @objc public dynamic var alertTitleAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFontBoldMake(17), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)] {
        didSet {
            _needsUpdateTitle = true
        }
    }

    /// alert信息样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFontMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)]
    @objc public dynamic var alertMessageAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFontMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)] {
        didSet {
            _needsUpdateMessage = true
        }
    }

    /// alert按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0]
    @objc public dynamic var alertButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert按钮disabled时的样式，默认 [NSAttributedStringKey.foregroundColor: UIColor(r: 129, g: 129, b: 129), NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var alertButtonDisabledAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor(r: 129, g: 129, b: 129), NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert cancel 按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontBoldMake(17), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var alertCancelButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontBoldMake(17), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert destructive 按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.red, NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var alertDestructiveButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.red, NSAttributedStringKey.font: UIFontMake(17), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert圆角大小，默认值是：IOS_VERSION >= 9.0 ? 13 : 6，以保持与系统默认样式一致
    @objc public dynamic var alertContentCornerRadius: CGFloat = (IOS_VERSION > 9.0 ? 13 : 6) {
        didSet {
            updateCornerRadius()
        }
    }

    /// alert按钮高度，默认44pt
    @objc public dynamic var alertButtonHeight: CGFloat = 44

    /// alert头部（非按钮部分）背景色，默认值是：UIColor(r: 247, g: 247, b: 247, a:1)
    @objc public dynamic var alertHeaderBackgroundColor: UIColor = UIColor(r: 247, g: 247, b: 247, a: 1) {
        didSet {
            updateHeaderBackgrondColor()
        }
    }

    /// alert按钮背景色，默认值同`alertHeaderBackgroundColor`
    @objc public dynamic var alertButtonBackgroundColor: UIColor = UIColor(r: 247, g: 247, b: 247, a: 1) {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert按钮高亮背景色，默认 UIColor(r: 232, g: 232, b: 232)
    @objc public dynamic var alertButtonHighlightBackgroundColor: UIColor = UIColor(r: 232, g: 232, b: 232) {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// alert头部四边insets间距
    @objc public dynamic var alertHeaderInsets: UIEdgeInsets = UIEdgeInsetsMake(20, 16, 20, 16)

    /// alert头部title和message之间的间距，默认3pt
    @objc public dynamic var alertTitleMessageSpacing: CGFloat = 3

    /// sheet距离屏幕四边的间距，默认UIEdgeInsetsMake(10, 10, 10, 10)。
    @objc public dynamic var sheetContentMargin: UIEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)

    /// sheet的最大宽度，默认值是5.5英寸的屏幕的宽度减去水平的 sheetContentMargin
    @objc public dynamic var sheetContentMaximumWidth: CGFloat = QMUIHelper.screenSizeFor55Inch.width - UIEdgeInsetsMake(10, 10, 10, 10).horizontalValue

    /// sheet分隔线颜色，默认 UIColor(r: 211, g: 211, b: 219)
    @objc public dynamic var sheetSeperatorColor: UIColor = UIColor(r: 211, g: 211, b: 219) {
        didSet {
            updateEffectBackgroundColor()
        }
    }

    /// sheet标题样式，默认 [NSAttributedStringKey.foregroundColor: UIColor(r: 143, g: 143, b: 143), NSAttributedStringKey.font: UIFontBoldMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)]
    @objc public dynamic var sheetTitleAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor(r: 143, g: 143, b: 143), NSAttributedStringKey.font: UIFontBoldMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)] {
        didSet {
            _needsUpdateTitle = true
        }
    }

    /// sheet信息样式，默认 [NSAttributedStringKey.foregroundColor: UIColor(r: 143, g: 143, b: 143), NSAttributedStringKey.font: UIFontMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)]
    @objc public dynamic var sheetMessageAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor(r: 143, g: 143, b: 143), NSAttributedStringKey.font: UIFontMake(13), NSAttributedStringKey.paragraphStyle: NSMutableParagraphStyle(lineHeight: 0, lineBreakMode: .byTruncatingTail)] {
        didSet {
            _needsUpdateMessage = true
        }
    }

    /// sheet按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontMake(20), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var sheetButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontMake(20), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet按钮disabled时的样式，默认 [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor(r: 129, g: 129, b: 129), NSAttributedStringKey.font: UIFontMake(20), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var sheetButtonDisabledAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor(r: 129, g: 129, b: 129), NSAttributedStringKey.font: UIFontMake(20), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet cancel 按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontBoldMake(20), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var sheetCancelButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.blue, NSAttributedStringKey.font: UIFontBoldMake(20), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet destructive 按钮样式，默认 [NSAttributedStringKey.foregroundColor: UIColor.red, NSAttributedStringKey.font: UIFontBoldMake(20), NSAttributedStringKey.kern: 0 as AnyObject]
    @objc public dynamic var sheetDestructiveButtonAttributes: [NSAttributedStringKey: AnyObject] = [NSAttributedStringKey.foregroundColor: UIColor.red, NSAttributedStringKey.font: UIFontBoldMake(20), NSAttributedStringKey.kern: 0 as AnyObject] {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet cancel 按钮距离其上面元素（按钮或者header）的间距，默认8pt
    @objc public dynamic var sheetCancelButtonMarginTop: CGFloat = 8

    /// sheet内容的圆角，默认值是：(IOS_VERSION >= 9.0 ? 13 : 6)，以保持与系统默认样式一致
    @objc public dynamic var sheetContentCornerRadius: CGFloat = (IOS_VERSION >= 9.0 ? 13 : 6) {
        didSet {
            updateCornerRadius()
        }
    }

    /// sheet按钮高度，默认值是：(IOS_VERSION >= 9.0 ? 57 : 44)，以保持与系统默认样式一致
    @objc public dynamic var sheetButtonHeight: CGFloat = (IOS_VERSION >= 9.0 ? 57 : 44)

    /// sheet头部（非按钮部分）背景色，默认值是：UIColorMakeWithRGBA(247, 247, 247, 1)
    @objc public dynamic var sheetHeaderBackgroundColor: UIColor = UIColor(r: 247, g: 247, b: 247, a: 1) {
        didSet {
            updateHeaderBackgrondColor()
        }
    }

    /// sheet按钮背景色，默认值同`sheetHeaderBackgroundColor`
    @objc public dynamic var sheetButtonBackgroundColor: UIColor = UIColor(r: 247, g: 247, b: 247, a: 1) {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet按钮高亮背景色，默认 UIColor(r: 232, g: 232, b: 232)
    @objc public dynamic var sheetButtonHighlightBackgroundColor: UIColor = UIColor(r: 232, g: 232, b: 232) {
        didSet {
            _needsUpdateAction = true
        }
    }

    /// sheet头部四边insets间距
    @objc public dynamic var sheetHeaderInsets: UIEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16)

    /// sheet头部title和message之间的间距，默认8pt
    @objc public dynamic var sheetTitleMessageSpacing: CGFloat = 8

    /// 所有`QMUIAlertAction`对象
    public var actions: [QMUIAlertAction] {
        return alertActions
    }

    /// 当前所有通过`addTextFieldWithConfigurationHandler:`接口添加的输入框
    public var textFields: [UITextField] {
        return alertTextFields
    }

    /// 设置自定义view。通过`addCustomView:`方法添加一个自定义的view，`QMUIAlertController`会在布局的时候去掉用这个view的`sizeThatFits:`方法来获取size，至于x和y坐标则由控件自己控制。
    private(set) var customView: UIView?

    /// 当前样式style
    private(set) var preferredStyle: QMUIAlertControllerStyle? {
        didSet {
            preferredStyle = IS_IPAD ? .alert : preferredStyle
        }
    }

    /// 将`QMUIAlertController`弹出来的`QMUIModalPresentationViewController`对象
    private(set) var modalPresentationViewController: QMUIModalPresentationViewController?

    /// 当前标题title
    public override var title: String? {
        get {
            return super.title
        }
        set {
            let oldValue = super.title
            super.title = newValue
            if titleLabel == nil {
                let newTitleLabel = UILabel()
                newTitleLabel.numberOfLines = 0
                headerScrollView.addSubview(newTitleLabel)
                titleLabel = newTitleLabel
            }
            if oldValue == nil || oldValue == "" {
                titleLabel?.isHidden = true
            } else {
                titleLabel?.isHidden = false
                updateTitleLabel()
            }
        }
    }

    /// 当前信息message
    public var message: String? {
        didSet {
            if messageLabel == nil {
                let label = UILabel()
                label.numberOfLines = 0
                messageLabel = label
                headerScrollView.addSubview(messageLabel!)
            }
            if message == nil || message == "" {
                messageLabel?.isHidden = true
            } else {
                messageLabel?.isHidden = false
                updateMessageLabel()
            }
        }
    }

    /**
     *  设置按钮的排序是否要由用户添加的顺序来决定，默认为 false，也即与系统原生`UIAlertController`一致，QMUIAlertActionStyleDestructive 类型的action必定在最后面。
     *
     *  @warning 注意 QMUIAlertActionStyleCancel 按钮不受这个属性的影响
     */
    public var orderActionsByAddedOrdered: Bool = false

    /// maskView是否响应点击，alert默认为 false，sheet 默认为 true
    public var shouldRespondMaskViewTouch: Bool {
        return preferredStyle == .sheet
    }

    /// 在 iPhoneX 机器上是否延伸底部背景色。因为在 iPhoneX 上我们会把整个面板往上移动 safeArea 的距离，如果你的面板本来就配置成撑满全屏的样式，那么就会露出底部的空隙，isExtendBottomLayout 可以帮助你把空暇填补上。默认为 false。
    /// @warning: 只对 sheet 类型有效
    public var isExtendBottomLayout: Bool = false {
        didSet {
            if isExtendBottomLayout {
                extendLayer.isHidden = false
                updateExtendLayerAppearance()
            } else {
                extendLayer.isHidden = true
            }
        }
    }

    private lazy var containerView: UIView = {
        UIView()
    }()

    private lazy var maskView: UIControl = {
        var maskView = UIControl()
        maskView.alpha = 0
        maskView.backgroundColor = UIColorMask
        maskView.addTarget(self, action: #selector(handleMaskViewEvent(_:)), for: .touchUpInside)
        return maskView
    }()

    private lazy var scrollWrapView: UIView = {
        UIView()
    }()

    private lazy var headerScrollView: UIScrollView = {
        UIScrollView()
    }()

    private lazy var buttonScrollView: UIScrollView = {
        UIScrollView()
    }()

    private lazy var headerEffectView: UIView = {
        UIView()
    }()

    private lazy var cancelButtoneEffectView: UIView = {
        UIView()
    }()

    private lazy var extendLayer: CALayer = {
        var extendLayer = CALayer()
        extendLayer.isHidden = !isExtendBottomLayout
        extendLayer.qmui_removeDefaultAnimations()
        return extendLayer
    }()

    private var titleLabel: UILabel?

    private var messageLabel: UILabel?

    private var cancelAction: QMUIAlertAction?

    private lazy var alertActions: [QMUIAlertAction] = {
        []
    }()

    private lazy var destructiveActions: [QMUIAlertAction] = {
        []
    }()

    private lazy var alertTextFields: [UITextField] = {
        []
    }()

    private var keyboardHeight: CGFloat = 0

    private var isShowing: Bool = false

    // 保护 showing 的过程中调用 hide 无效
    private var isNeedsHideAfterAlertShowed: Bool = false

    private var isAnimatedForHideAfterAlertShowed: Bool = false

    private var _needsUpdateAction: Bool = false

    private var _needsUpdateTitle: Bool = false

    private var _needsUpdateMessage: Bool = false

    private var delegate: QMUIAlertControllerDelegate?

    static var alertControllerCount: UInt = 0

    override init(nibName _: String?, bundle _: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        didInitialized()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInitialized()
    }

    convenience init(title: String?, message: String? = nil, preferredStyle: QMUIAlertControllerStyle) {
        self.init(nibName: nil, bundle: nil)
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle

        updateHeaderBackgrondColor()
        updateEffectBackgroundColor()
        updateCornerRadius()
        updateExtendLayerAppearance()
    }

    private func didInitialized() {
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(maskView)
        view.addSubview(containerView)
        containerView.addSubview(scrollWrapView)
        scrollWrapView.addSubview(headerEffectView)
        scrollWrapView.addSubview(headerScrollView)
        scrollWrapView.addSubview(buttonScrollView)
        containerView.layer.addSublayer(extendLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let hasTitle = (titleLabel?.text ?? "").isEmpty && titleLabel != nil && !titleLabel!.isHidden
        let hasMessage = (messageLabel?.text ?? "").isEmpty && messageLabel != nil && !messageLabel!.isHidden
        let hasTextField = alertTextFields.count > 0
        let hasCustomView = customView != nil
        var contentOriginY: CGFloat = 0

        maskView.frame = view.bounds

        if preferredStyle == .alert {
            let contentPaddingLeft = alertHeaderInsets.left
            let contentPaddingRight = alertHeaderInsets.right

            let contentPaddingTop = (hasTitle || hasMessage || hasTextField || hasCustomView) ? alertHeaderInsets.top : 0
            let contentPaddingBottom = (hasTitle || hasMessage || hasTextField || hasCustomView) ? alertHeaderInsets.bottom : 0
            containerView.frame.setWidth(fmin(alertContentMaximumWidth, view.bounds.width - alertContentMargin.horizontalValue))
            scrollWrapView.frame.setWidth(containerView.bounds.width)
            headerScrollView.frame = CGRect(x: 0, y: 0, width: scrollWrapView.bounds.width, height: 0)
            contentOriginY = contentPaddingTop
            // 标题和副标题布局
            if hasTitle {
                let titleLabelLimitWidth = headerScrollView.bounds.width - contentPaddingLeft - contentPaddingRight
                let titleLabelSize = titleLabel!.sizeThatFits(CGSize(width: titleLabelLimitWidth, height: CGFloat.greatestFiniteMagnitude))
                titleLabel!.frame = CGRect(x: contentPaddingLeft, y: contentOriginY, width: titleLabelLimitWidth, height: titleLabelSize.height).flatted
                contentOriginY = titleLabel!.frame.maxY + (hasMessage ? alertTitleMessageSpacing : contentPaddingBottom)
            }
            if hasMessage {
                let messageLabelLimitWidth = headerScrollView.bounds.width - contentPaddingLeft - contentPaddingRight
                let messageLabelSize = messageLabel!.sizeThatFits(CGSize(width: messageLabelLimitWidth, height: CGFloat.greatestFiniteMagnitude))
                messageLabel!.frame = CGRect(x: contentPaddingLeft, y: contentOriginY, width: messageLabelLimitWidth, height: messageLabelSize.height).flatted
                contentOriginY = messageLabel!.frame.maxY + contentPaddingBottom
            }
            // 输入框布局
            if hasTextField {
                for index in 0 ..< alertTextFields.count {
                    let textField = alertTextFields[index]
                    textField.frame = CGRect(x: contentPaddingLeft, y: contentOriginY, width: headerScrollView.bounds.width - contentPaddingLeft - contentPaddingRight, height: 25)
                    contentOriginY = textField.frame.maxY - 1
                }
                contentOriginY += 16
            }
            // 自定义view的布局 - 自动居中
            if hasCustomView {
                let customViewSize = customView!.sizeThatFits(CGSize(width: headerScrollView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
                customView!.frame = CGRect(x: (headerScrollView.bounds.width - customViewSize.width) / 2, y: contentOriginY, width: customViewSize.width, height: customViewSize.height).flatted
                contentOriginY = customView!.frame.maxY + contentPaddingBottom
            }
            // 内容scrollView的布局
            buttonScrollView.frame = buttonScrollView.frame.setHeight(contentOriginY)
            buttonScrollView.contentSize = CGSize(width: buttonScrollView.bounds.width, height: contentOriginY)
            contentOriginY = headerScrollView.frame.maxY
            // 按钮布局
            buttonScrollView.frame = CGRect(x: 0, y: contentOriginY, width: containerView.bounds.width, height: 0)
            contentOriginY = 0
            let newOrderActions = orderedAlertActions(alertActions)
            if alertActions.count > 0 {
                var verticalLayout = true
                if alertActions.count == 2 {
                    let halfWidth = buttonScrollView.bounds.width / 2
                    let action1 = newOrderActions[0]
                    let action2 = newOrderActions[1]
                    let actionSize1 = action1.button.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                    let actionSize2 = action2.button.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                    if actionSize1.width < halfWidth && actionSize2.width < halfWidth {
                        verticalLayout = false
                    }
                }

                if !verticalLayout {
                    let action1 = newOrderActions[1]
                    action1.buttonWrapView.frame = CGRect(x: 0, y: contentOriginY + PixelOne, width: buttonScrollView.bounds.width / 2, height: alertButtonHeight)
                    let action2 = newOrderActions[0]
                    action2.buttonWrapView.frame = CGRect(x: action1.buttonWrapView.frame.maxX + PixelOne, y: contentOriginY + PixelOne, width: buttonScrollView.bounds.width / 2 - PixelOne, height: alertButtonHeight)
                    contentOriginY = action1.buttonWrapView.frame.maxY
                } else {
                    for i in 0 ..< newOrderActions.count {
                        let action = newOrderActions[i]
                        action.buttonWrapView.frame = CGRect(x: 0, y: contentOriginY + PixelOne, width: containerView.bounds.width, height: alertButtonHeight - PixelOne)
                        contentOriginY = action.buttonWrapView.frame.maxY
                    }
                }
            }
            // 按钮scrollView的布局
            buttonScrollView.frame = buttonScrollView.frame.setHeight(contentOriginY)
            buttonScrollView.contentSize = CGSize(width: buttonScrollView.bounds.width, height: contentOriginY)
            // 容器最后布局
            var contentHeight = headerScrollView.bounds.height + buttonScrollView.bounds.height
            var screenSpaceHeight = view.bounds.height
            if contentHeight > screenSpaceHeight - 20 {
                screenSpaceHeight -= 20
                let contentH = fmin(headerScrollView.bounds.height, screenSpaceHeight / 2)
                let buttonH = fmin(buttonScrollView.bounds.height, screenSpaceHeight / 2)
                if contentH >= screenSpaceHeight / 2 && buttonH >= screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(screenSpaceHeight / 2)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(screenSpaceHeight / 2)
                } else if contentH < screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(contentH)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(screenSpaceHeight - contentH)
                } else if buttonH < screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(screenSpaceHeight - buttonH)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(buttonH)
                }
                contentHeight = headerScrollView.bounds.height + buttonScrollView.bounds.height
                screenSpaceHeight += 20
            }

            scrollWrapView.frame = CGRect(x: 0, y: 0, width: scrollWrapView.bounds.width, height: contentHeight)
            headerEffectView.frame = scrollWrapView.bounds

            let containerRect = CGRect(x: (view.bounds.width - containerView.bounds.width) / 2, y: (screenSpaceHeight - contentHeight - keyboardHeight) / 2, width: containerView.bounds.width, height: scrollWrapView.bounds.height)
            containerView.frame = containerRect.applying(containerView.transform).flatted

        } else if preferredStyle == .sheet {

            let contentPaddingLeft = alertHeaderInsets.left
            let contentPaddingRight = alertHeaderInsets.right

            let contentPaddingTop = (hasTitle || hasMessage || hasTextField) ? sheetHeaderInsets.top : 0
            let contentPaddingBottom = (hasTitle || hasMessage || hasTextField) ? sheetHeaderInsets.bottom : 0
            containerView.frame.setWidth(fmin(sheetContentMaximumWidth, view.bounds.width - sheetContentMargin.horizontalValue))
            scrollWrapView.frame.setWidth(containerView.bounds.width)
            headerScrollView.frame = CGRect(x: 0, y: 0, width: containerView.bounds.width, height: 0)
            contentOriginY = contentPaddingTop
            // 标题和副标题布局
            if hasTitle {
                let titleLabelLimitWidth = headerScrollView.bounds.width - contentPaddingLeft - contentPaddingRight
                let titleLabelSize = titleLabel!.sizeThatFits(CGSize(width: titleLabelLimitWidth, height: CGFloat.greatestFiniteMagnitude))
                titleLabel!.frame = CGRect(x: contentPaddingLeft, y: contentOriginY, width: titleLabelLimitWidth, height: titleLabelSize.height).flatted
                contentOriginY = titleLabel!.frame.maxY + (hasMessage ? sheetTitleMessageSpacing : contentPaddingBottom)
            }
            if hasMessage {
                let messageLabelLimitWidth = headerScrollView.bounds.width - contentPaddingLeft - contentPaddingRight
                let messageLabelSize = messageLabel!.sizeThatFits(CGSize(width: messageLabelLimitWidth, height: CGFloat.greatestFiniteMagnitude))
                messageLabel!.frame = CGRect(x: contentPaddingLeft, y: contentOriginY, width: messageLabelLimitWidth, height: messageLabelSize.height).flatted
                contentOriginY = messageLabel!.frame.maxY + contentPaddingBottom
            }
            // 自定义view的布局 - 自动居中
            if hasCustomView {
                let customViewSize = customView!.sizeThatFits(CGSize(width: headerScrollView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
                customView!.frame = CGRect(x: (headerScrollView.bounds.width - customViewSize.width) / 2, y: contentOriginY, width: customViewSize.width, height: customViewSize.height).flatted
                contentOriginY = customView!.frame.maxY + contentPaddingBottom
            }
            // 内容scrollView布局
            headerScrollView.frame = headerScrollView.frame.setHeight(contentOriginY)
            headerScrollView.contentSize = CGSize(width: headerScrollView.bounds.width, height: contentOriginY)
            contentOriginY = headerScrollView.frame.maxY
            // 按钮的布局
            buttonScrollView.frame = CGRect(x: 0, y: contentOriginY, width: containerView.bounds.width, height: 0)
            contentOriginY = 0
            let newOrderActions = orderedAlertActions(alertActions)
            if alertActions.count > 0 {
                contentOriginY = (hasTitle || hasMessage || hasCustomView) ? contentOriginY + PixelOne : contentOriginY
                for i in 0 ..< newOrderActions.count {
                    let action = newOrderActions[i]
                    if action.style == .cancel && i == newOrderActions.count - 1 {
                        continue
                    } else {
                        action.buttonWrapView.frame = CGRect(x: 0, y: contentOriginY, width: buttonScrollView.bounds.width, height: sheetButtonHeight - PixelOne)
                        contentOriginY = action.buttonWrapView.frame.maxY + PixelOne
                    }
                }
                contentOriginY -= PixelOne
            }
            // 按钮scrollView的布局
            buttonScrollView.frame = buttonScrollView.frame.setHeight(contentOriginY)
            buttonScrollView.contentSize = CGSize(width: buttonScrollView.bounds.width, height: contentOriginY)
            // 容器最终布局
            scrollWrapView.frame = CGRect(x: 0, y: 0, width: scrollWrapView.bounds.width, height: buttonScrollView.frame.maxY)
            headerEffectView.frame = scrollWrapView.bounds
            contentOriginY = scrollWrapView.frame.maxY + sheetCancelButtonMarginTop
            if let cancelAction = self.cancelAction {
                cancelButtoneEffectView.frame = CGRect(x: 0, y: contentOriginY, width: containerView.bounds.width, height: sheetButtonHeight)
                cancelAction.buttonWrapView.frame = cancelButtoneEffectView.bounds
                contentOriginY = cancelButtoneEffectView.frame.maxY
            }
            // 把上下的margin都加上用于跟整个屏幕的高度做比较
            var contentHeight = contentOriginY + sheetContentMargin.verticalValue
            var screenSpaceHeight = view.bounds.height
            if contentHeight > screenSpaceHeight {

                let cancelButtonAreaHeight = cancelAction != nil ? (cancelAction!.buttonWrapView.bounds.height + sheetCancelButtonMarginTop) : 0
                screenSpaceHeight = screenSpaceHeight - cancelButtonAreaHeight - sheetContentMargin.verticalValue
                let contentH = fmin(headerScrollView.bounds.height, screenSpaceHeight / 2)
                let buttonH = fmin(buttonScrollView.bounds.height, screenSpaceHeight / 2)
                if contentH >= screenSpaceHeight / 2 && buttonH >= screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(screenSpaceHeight / 2)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(screenSpaceHeight / 2)
                } else if contentH < screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(contentH)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(screenSpaceHeight - contentH)
                } else if buttonH < screenSpaceHeight / 2 {
                    headerScrollView.frame = headerScrollView.frame.setHeight(screenSpaceHeight - buttonH)
                    buttonScrollView.frame = buttonScrollView.frame.setY(headerScrollView.frame.maxY)
                    buttonScrollView.frame = buttonScrollView.frame.setHeight(buttonH)
                }
                scrollWrapView.frame = scrollWrapView.frame.setHeight(headerScrollView.bounds.height + buttonScrollView.bounds.height)
                if cancelAction != nil {
                    cancelButtoneEffectView.frame = cancelButtoneEffectView.frame.setY(scrollWrapView.frame.maxY + sheetCancelButtonMarginTop)
                }
                contentHeight = headerScrollView.bounds.height + buttonScrollView.bounds.height + cancelButtonAreaHeight + sheetContentMargin.bottom
                screenSpaceHeight += (cancelButtonAreaHeight + sheetContentMargin.verticalValue)
            } else {
                // 如果小于屏幕高度，则把顶部的top减掉
                contentHeight -= sheetContentMargin.top
            }

            let containerRect = CGRect(x: (view.bounds.width - containerView.bounds.width) / 2, y: screenSpaceHeight - contentHeight - IPhoneXSafeAreaInsets.bottom, width: containerView.bounds.width, height: contentHeight + (isExtendBottomLayout ? IPhoneXSafeAreaInsets.bottom : 0))
            containerView.frame = containerRect.applying(containerView.transform).flatted

            extendLayer.frame = CGRectFlat(0, containerView.bounds.height - IPhoneXSafeAreaInsets.bottom - 1, containerView.bounds.width, IPhoneXSafeAreaInsets.bottom + 1)
        }
    }

    private func updateHeaderBackgrondColor() {
        if preferredStyle == .sheet {
            headerScrollView.backgroundColor = sheetHeaderBackgroundColor
        } else if preferredStyle == .alert {
            headerScrollView.backgroundColor = alertHeaderBackgroundColor
        }
    }

    private func updateEffectBackgroundColor() {
        if preferredStyle == .alert {
            headerEffectView.backgroundColor = alertSeperatorColor
            cancelButtoneEffectView.backgroundColor = alertSeperatorColor
        } else if preferredStyle == .sheet {
            headerEffectView.backgroundColor = sheetSeperatorColor
            cancelButtoneEffectView.backgroundColor = sheetSeperatorColor
        }
    }

    private func updateCornerRadius() {
        if preferredStyle == .alert {
            containerView.layer.cornerRadius = alertContentCornerRadius
            containerView.clipsToBounds = true
            cancelButtoneEffectView.layer.cornerRadius = 0
            cancelButtoneEffectView.clipsToBounds = false
            scrollWrapView.layer.cornerRadius = 0
            scrollWrapView.clipsToBounds = false
        } else {
            containerView.layer.cornerRadius = 0
            containerView.clipsToBounds = false
            cancelButtoneEffectView.layer.cornerRadius = sheetContentCornerRadius
            cancelButtoneEffectView.clipsToBounds = true
            scrollWrapView.layer.cornerRadius = sheetContentCornerRadius
            scrollWrapView.clipsToBounds = true
        }
    }

    private func updateTitleLabel() {
        if let titleLabel = self.titleLabel, let title = self.title {
            if !titleLabel.isHidden {
                let attributeString = NSAttributedString(string: title, attributes: (preferredStyle == .alert ? alertTitleAttributes : sheetTitleAttributes))
                titleLabel.attributedText = attributeString
                titleLabel.textAlignment = .center
            }
        }
    }

    private func orderedAlertActions(_: [QMUIAlertAction]) -> [QMUIAlertAction] {
        var newActions: [QMUIAlertAction] = []
        // 按照用户addAction的先后顺序来排序
        if orderActionsByAddedOrdered {
            alertActions.forEach({
                newActions.append($0)
            })
            // 取消按钮不参与排序，所以先移除，在最后再重新添加
            if cancelAction != nil {
                newActions.remove(object: cancelAction!)
            }
        } else {
            alertActions.forEach({
                if $0.style != .cancel && $0.style != .destructive {
                    newActions.append($0)
                }
            })
            destructiveActions.forEach({
                newActions.append($0)
            })
        }
        if cancelAction != nil {
            newActions.append(cancelAction!)
        }
        return newActions
    }

    private func initModalPresentationController() {
        let modalController = QMUIModalPresentationViewController()
        modalController.delegate = self
        modalController.maximumContentViewWidth = CGFloat.greatestFiniteMagnitude
        modalController.contentViewMargins = UIEdgeInsets.zero
        modalController.dimmingView = nil
        modalController.contentViewController = self as? (UIViewController & QMUIModalPresentationContentViewControllerProtocol)
        customModalPresentationControllerAnimation()
        modalPresentationViewController = modalController
    }

    private func customModalPresentationControllerAnimation() {

        modalPresentationViewController?.layoutBlock = { [weak self] (_ containerBounds: CGRect, _ keyboardHeight: CGFloat, _: CGRect) in
            self?.view.frame = CGRect(x: 0, y: 0, width: containerBounds.width, height: containerBounds.height)
            self?.keyboardHeight = keyboardHeight
            self?.view.setNeedsLayout()
        }

        modalPresentationViewController?.showingAnimation = { [weak self] (_: UIView, _: CGRect, _: CGFloat, _: CGRect, _ completion: ((Bool) -> Void)?) in
            if self?.preferredStyle == .alert {
                self!.containerView.alpha = 0
                self!.containerView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveOut, animations: {
                    self!.maskView.alpha = 1
                    self!.containerView.alpha = 1
                    self!.containerView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
                }, completion: {
                    if completion != nil {
                        completion!($0)
                    }
                })
            } else if self?.preferredStyle == .sheet {
                self!.containerView.layer.transform = CATransform3DMakeTranslation(0, self!.containerView.bounds.height, 0)
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveOut, animations: {
                    self!.maskView.alpha = 1
                    self!.containerView.layer.transform = CATransform3DIdentity
                }, completion: {
                    if completion != nil {
                        completion!($0)
                    }
                })
            }
        }

        modalPresentationViewController?.hidingAnimation = { [weak self] (_: UIView, _: CGRect, _: CGFloat, _ completion: ((_ finished: Bool) -> Void)?) in
            if self?.preferredStyle == .alert {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveOut, animations: {
                    self!.maskView.alpha = 0
                    self!.containerView.alpha = 0
                }, completion: {
                    self!.containerView.alpha = 1
                    if completion != nil {
                        completion!($0)
                    }
                })
            } else if self?.preferredStyle == .sheet {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveOut, animations: {
                    self!.maskView.alpha = 0
                    self!.containerView.layer.transform = CATransform3DMakeTranslation(0, self!.containerView.bounds.height, 0)
                }, completion: {
                    if completion != nil {
                        completion!($0)
                    }
                })
            }
        }
    }

    /// 显示`QMUIAlertController`
    ///
    /// - Parameter animated: animated
    public func show(with animated: Bool = true) {
        if isShowing {
            return
        }
        if alertTextFields.count > 0 {
            alertTextFields.first?.becomeFirstResponder()
        }
        if _needsUpdateAction {
            updateAction()
        }
        if _needsUpdateTitle {
            updateTitleLabel()
        }
        if _needsUpdateMessage {
            updateMessageLabel()
        }

        initModalPresentationController()

        if delegate?.responds(to: #selector(QMUIAlertControllerDelegate.willShow(_:))) ?? false {
            delegate!.willShow(self)
        }

        modalPresentationViewController?.show(with: animated, completion: { [weak self] _ in
            self?.maskView.alpha = 1
            self?.isShowing = true
            if self?.isNeedsHideAfterAlertShowed ?? false {
                self!.hide(with: self!.isAnimatedForHideAfterAlertShowed)
                self!.isNeedsHideAfterAlertShowed = false
                self!.isAnimatedForHideAfterAlertShowed = false
            }
            if self?.delegate?.responds(to: #selector(QMUIAlertControllerDelegate.didShow(_:))) ?? false {
                self!.delegate!.didShow(self!)
            }
        })

        // 增加alertController计数
        QMUIAlertController.alertControllerCount += 1
    }

    /// 隐藏`QMUIAlertController`
    ///
    /// - Parameter animated: animated
    public func hide(with animated: Bool) {
        hide(with: animated, completion: nil)
    }

    private func hide(with animated: Bool, completion: (() -> Void)?) {
        if !isShowing {
            isNeedsHideAfterAlertShowed = true
        }
        if delegate?.responds(to: #selector(QMUIAlertControllerDelegate.willHide(_:))) ?? false {
            delegate!.willHide(self)
        }

        modalPresentationViewController?.hide(with: animated, completion: { [weak self] _ in
            self?.modalPresentationViewController = nil
            self?.isShowing = false
            self?.maskView.alpha = 0
            if self?.preferredStyle == .alert {
                self!.containerView.alpha = 0
            } else if self?.preferredStyle == .sheet {
                self!.containerView.layer.transform = CATransform3DMakeTranslation(0, self!.containerView.bounds.height, 0)
            }
            if self?.delegate?.responds(to: #selector(QMUIAlertControllerDelegate.didHide(_:))) ?? false {
                self!.delegate!.didHide(self!)
            }
            if completion != nil {
                completion!()
            }
        })

        // 减少alertController计数
        QMUIAlertController.alertControllerCount -= 1
    }

    private func updateExtendLayerAppearance() {
        extendLayer.backgroundColor = sheetButtonBackgroundColor.cgColor
    }

    /// 增加一个按钮
    ///
    /// - Parameter action: 按钮
    public func add(action: QMUIAlertAction) {
        if action.style == .cancel && cancelAction != nil {
            NSException(name: NSExceptionName(rawValue: "QMUIAlertController使用错误"), reason: "同一个alertController不可以同时添加两个cancel按钮", userInfo: nil).raise()
        }
        if action.style == .cancel {
            cancelAction = action
        }
        if action.style == .destructive {
            destructiveActions.append(action)
        }
        // 只有ActionSheet的取消按钮不参与滚动
        if preferredStyle == .sheet && action.style == .cancel && !IS_IPAD {
            if cancelButtoneEffectView.superview == nil {
                containerView.addSubview(cancelButtoneEffectView)
            }
            cancelButtoneEffectView.addSubview(action.buttonWrapView)
        } else {
            buttonScrollView.addSubview(action.buttonWrapView)
        }
        action.delegate = self
        alertActions.append(action)
    }

    /// 增加一个“取消”按钮，点击后 alertController 会被 hide
    public func addCancelAction() {
        let action = QMUIAlertAction(title: "取消", style: .cancel, handler: nil)
        add(action: action)
    }

    /// 增加一个输入框
    ///
    /// - Parameter configurationHandler: 回调
    public func addTextField(with configurationHandler: ((_ textField: QMUITextField) -> Void)?) {
        if customView != nil {
            NSException(name: NSExceptionName(rawValue: "QMUIAlertController使用错误"), reason: "UITextField和CustomView不能共存", userInfo: nil).raise()
        }
        if preferredStyle == .sheet {
            NSException(name: NSExceptionName(rawValue: "QMUIAlertController使用错误"), reason: "Sheet类型不运行添加UITextField", userInfo: nil).raise()
        }
        let textField = QMUITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.contentVerticalAlignment = .center
        textField.font = UIFontMake(14)
        textField.textColor = .black
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.layer.borderColor = UIColor(r: 210, g: 210, b: 210).cgColor
        textField.layer.borderWidth = PixelOne
        headerScrollView.addSubview(textField)
        alertTextFields.append(textField)
        if configurationHandler != nil {
            configurationHandler!(textField)
        }
    }

    /// 增加一个自定义的view作为`QMUIAlertController`的customView
    ///
    /// - Parameter view: 自定义的view
    public func addCustomView(_ view: UIView) {
        if alertTextFields.count > 0 {
            NSException(name: NSExceptionName(rawValue: "QMUIAlertController使用错误"), reason: "UITextField和CustomView不能共存", userInfo: nil).raise()
        }
        customView = view
        headerScrollView.addSubview(customView!)
    }

    private func updateAction() {
        alertActions.forEach {
            let backgroundColor = preferredStyle == .alert ? alertButtonBackgroundColor : sheetButtonBackgroundColor
            let highlightBackgroundColor = preferredStyle == .alert ? alertButtonHighlightBackgroundColor : sheetButtonHighlightBackgroundColor
            $0.buttonWrapView.clipsToBounds = $0.style == .cancel
            $0.button.backgroundColor = backgroundColor
            $0.button.highlightedBackgroundColor = highlightBackgroundColor

            var attributeString: NSAttributedString?
            if $0.style == .cancel {

                var attributes = preferredStyle == .alert ? alertCancelButtonAttributes : sheetCancelButtonAttributes
                if $0.buttonAttributes != nil {
                    attributes = $0.buttonAttributes!
                }
                if let title = $0.title {
                    attributeString = NSAttributedString(string: title, attributes: attributes)
                }
            } else if $0.style == .destructive {

                var attributes = preferredStyle == .alert ? alertDestructiveButtonAttributes : sheetDestructiveButtonAttributes
                if $0.buttonAttributes != nil {
                    attributes = $0.buttonAttributes!
                }
                if let title = $0.title {
                    attributeString = NSAttributedString(string: title, attributes: attributes)
                }
            } else {

                var attributes = preferredStyle == .alert ? alertButtonAttributes : sheetButtonAttributes
                if $0.buttonAttributes != nil {
                    attributes = $0.buttonAttributes!
                }
                if let title = $0.title {
                    attributeString = NSAttributedString(string: title, attributes: attributes)
                }
            }
            if attributeString != nil {
                $0.button.setAttributedTitle(attributeString!, for: .normal)
            }
            var attributes = preferredStyle == .alert ? alertButtonDisabledAttributes : sheetButtonDisabledAttributes
            if $0.buttonDisabledAttributes != nil {
                attributes = $0.buttonDisabledAttributes!
            }
            if let title = $0.title {
                attributeString = NSAttributedString(string: title, attributes: attributes)
            }
            $0.button.setAttributedTitle(attributeString, for: .disabled)

            if let image = $0.button.image(for: .normal), let attributeStr = attributeString {
                var range = NSRange(location: 0, length: attributeStr.length)
                let disabledColor = attributeString?.attribute(NSAttributedStringKey.foregroundColor, at: 0, effectiveRange: &range)
                $0.button.setImage(image.qmui_image(tintColor: disabledColor as! UIColor), for: .disabled)
            }
        }
    }

    @objc private func handleMaskViewEvent(_: AnyObject) {
        if shouldRespondMaskViewTouch {
            hide(with: true, completion: nil)
        }
    }

    private func updateMessageLabel() {
        if let messageLabel = self.messageLabel, let message = self.message {
            if !messageLabel.isHidden {
                let attributeString = NSAttributedString(string: message, attributes: (preferredStyle == .alert ? alertMessageAttributes : sheetMessageAttributes))
                messageLabel.attributedText = attributeString
                messageLabel.textAlignment = .center
            }
        }
    }

    // MARK: QMUIModalPresentationViewControllerDelegate

    func requestHideAllModalPresentationViewController() {
        hide(with: true, completion: nil)
    }

    // MARK: QMUIAlertActionDelegate

    func didClick(_ alertAction: QMUIAlertAction) {
        hide(with: true) {
            if alertAction.handler != nil {
                alertAction.handler!(alertAction)
                alertAction.handler = nil
            }
        }
    }
}

extension QMUIAlertController {

    /// 可方便地判断是否有 alertController 正在显示，全局生效
    ///
    /// - Returns: 是否 alertController 正在显示
    class func isAnyAlertControllerVisible() -> Bool {
        return QMUIAlertController.alertControllerCount > 0
    }
}

// MARK: QMUIAlertAction

/*
 *  QMUIAlertController的按钮，初始化完通过`QMUIAlertController`的`add:`方法添加到 AlertController 上即可。
 */
class QMUIAlertAction: NSObject {

    /// `QMUIAlertAction`是否允许操作
    public var isEnabled: Bool {
        didSet {
            button.isEnabled = isEnabled
        }
    }

    /// `QMUIAlertAction`按钮样式，默认nil。当此值为nil的时候，则使用`QMUIAlertController`的`alertButtonAttributes`或者`sheetButtonAttributes`的值。
    public var buttonAttributes: [NSAttributedStringKey: AnyObject]?

    /// 原理同上`buttonAttributes`
    public var buttonDisabledAttributes: [NSAttributedStringKey: AnyObject]?

    /// `QMUIAlertAction`对应的 button 对象
    public var button: QMUIButton {
        return buttonWrapView.button
    }

    /// `QMUIAlertAction`对应的标题
    private(set) var title: String?

    /// `QMUIAlertAction`对应的样式
    private(set) var style: QMUIAlertActionStyle = .default

    fileprivate var buttonWrapView: QMUIAlertButtonWrapView

    fileprivate var handler: ((QMUIAlertAction) -> Void)?

    fileprivate var delegate: QMUIAlertActionDelegate?

    override init() {
        isEnabled = true
        buttonWrapView = QMUIAlertButtonWrapView()
        super.init()
    }

    /// 初始化`QMUIAlertController`的按钮
    ///
    /// - Parameters:
    ///   - title: 按钮标题
    ///   - style: 按钮style，跟系统一样，有 Default、Cancel、Destructive 三种类型
    ///   - handler: 处理点击时间的回调
    convenience init(title: String?, style: QMUIAlertActionStyle, handler: ((QMUIAlertAction) -> Void)? = nil) {
        self.init()
        self.title = title
        self.style = style
        self.handler = handler
        button.qmui_automaticallyAdjustTouchHighlightedInScrollView = true
        button.addTarget(self, action: #selector(handleAlertActionEvent(_:)), for: .touchUpInside)
    }

    @objc func handleAlertActionEvent(_: AnyObject) {
        // 需要先调delegate，里面会先恢复keywindow
        delegate?.responds(to: #selector(QMUIAlertActionDelegate.didClick(_:)))
    }
}

// MARK: QMUIBUttonWrapView

fileprivate class QMUIAlertButtonWrapView: UIView {

    fileprivate var button: QMUIButton

    init() {
        button = QMUIButton()
        button.adjustsButtonWhenDisabled = false
        button.adjustsButtonWhenHighlighted = false
        super.init(frame: CGRect.zero)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
    }
}
