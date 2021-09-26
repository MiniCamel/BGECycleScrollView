//
//  BGECycleScrollView.swift
//  BGECycleScrollView
//
//  Created by bge on 2021/7/7.
//

import UIKit
import Masonry

public enum BGECycleScrollViewPagingStyle: Int {
    case pageControl
    case label
}

@objc public protocol BGECycleScrollViewDelegate: NSObjectProtocol {
    @objc optional func cycleScrollView(cycleScrollView: BGECycleScrollView, didSelectItemAtIndex index: Int) -> ()
    @objc optional func cycleScrollView(cycleScrollView: BGECycleScrollView, didScrollToItemAtIndex index: Int) -> ()
}

public protocol BGECycleScrollViewDataSource: NSObjectProtocol {
    func numberOfItemsAt(cycleScrollView: BGECycleScrollView) -> Int
    func cycleScrollView(cycleScrollView: BGECycleScrollView, cellForRowAtIndex index: Int) -> UIView
}

public class BGECycleScrollView: UIView {
    weak public var delegate: BGECycleScrollViewDelegate?
    weak public var dataSource: BGECycleScrollViewDataSource? {
        didSet {
            self.reloadData()
        }
    }
    
    public lazy var pageControl: UIPageControl = {
        var pageControl = UIPageControl()
        self.addSubview(pageControl)
        pageControl.mas_makeConstraints { (make) in
            make?.centerX.equalTo()(self)
            make?.bottom.offset()
            make?.width.equalTo()(self)
            make?.height.offset()(20)
        }
        
        return pageControl
    }()
    
    public lazy var pageLabel: UILabel = {
        var pageLabel = UILabel()
        pageLabel.font = .systemFont(ofSize: 12)
        pageLabel.layer.cornerRadius = 35 / 2.0
        pageLabel.layer.masksToBounds = true
        pageLabel.textAlignment = .center
        self.addSubview(pageLabel)
        pageLabel.mas_makeConstraints { (make) in
            make?.right.and()?.bottom()?.offset()(-5)
            make?.right.offset()(35)
            make?.height.equalTo()(pageLabel.mas_width)
        }
        
        return pageLabel
    }()
    
    public var scrollTimeInterval: TimeInterval = 0
    public var pagingStyle: BGECycleScrollViewPagingStyle = .pageControl {
        didSet {
            switch pagingStyle {
            case .pageControl:
                self.pageLabel.isHidden = true
                self.pageControl.isHidden = false
            case .label:
                self.pageLabel.isHidden = false
                self.pageControl.isHidden = true
            }
        }
    }
        
    public var pageIndicatorTintColor: UIColor = .white {
        didSet {
            self.pageControl.pageIndicatorTintColor = pageIndicatorTintColor
            self.pageLabel.backgroundColor = pageIndicatorTintColor
        }
    }
    public var currentPageIndicatorTintColor: UIColor = .darkGray {
        didSet {
            self.pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
            self.pageLabel.textColor = currentPageIndicatorTintColor
        }
    }
    
    private var scrollTimer: Timer?
    private lazy var containerScrollView: UIScrollView = {
        let containerScrollView = UIScrollView.init()
        containerScrollView.backgroundColor = .clear
        containerScrollView.showsVerticalScrollIndicator = false
        containerScrollView.showsHorizontalScrollIndicator = false
        containerScrollView.isScrollEnabled = true
        containerScrollView.isPagingEnabled = true
        containerScrollView.bounces = false
        containerScrollView.delegate = self
        self.addSubview(containerScrollView)
        containerScrollView.mas_makeConstraints { (make) in
            make?.edges.offset()
        }
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(scrollViewTaped(tapGesture:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        containerScrollView.addGestureRecognizer(tapGesture)
        
        return containerScrollView
    }()
    
    private var dataCount: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        if #available(iOS 11.0, *) {
            containerScrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        //view显示出来的时候，开始自动轮播
        let viewContentSizeWidth = self.containerScrollView.contentSize.width
        if (self.dataCount > 1) {
            self.containerScrollView.contentOffset = CGPoint(x: viewContentSizeWidth / CGFloat((self.dataCount + 2)), y: 0)
            self.startScroll()
        }
    }
    
    public func reloadData() {
        self.removeAllSuperviewOnScrollView()
        
        let count = self.dataSource?.numberOfItemsAt(cycleScrollView: self) ?? 0
        self.dataCount = count
        
        self.pageControl.numberOfPages = count
        if (count > 0) {
            self.pageLabel.text = "1/" + String(count)
        } else {
            self.pageLabel.text = "0/0"
            return;
        }
        
        //要实现循环轮播，故如果有五个view，实际的顺序是4 0 1 2 3 4 0，index为0123456，在头部加最后一个view，在尾部加第一个view。
        //向右滑动到index为6的view的时候，手动切换到index为1的view显示；向左滑动同理
        //每一个view的大小和self一样。scrollview的contentsize通过view的约束来确定。
        var lastView: UIView?
        for i in 0..<count+2 {
            var index = 0
            if i == 0 {
                index = count - 1
            } else if i == count + 1 {
                index = 0
            } else {
                index = i - 1
            }
            
            let view = self.dataSource!.cycleScrollView(cycleScrollView: self, cellForRowAtIndex: index)
            self.containerScrollView.addSubview(view)
            view.mas_makeConstraints { (make) in
                make?.width.and()?.height()?.equalTo()(self)
                make?.top.and()?.bottom()?.offset()
                if (lastView != nil) {
                    make?.left.equalTo()(lastView?.mas_right)
                } else {
                    make?.left.offset()
                }
            }
            
            lastView = view
        }
        
        lastView?.mas_makeConstraints({ (make) in
            make?.right.equalTo()(self.containerScrollView.mas_right)
        })
        
        //reloadData回到初始位置，然后开始滚动
        let scrollViewWidth = self.containerScrollView.contentSize.width / CGFloat((self.dataCount + 2))
        self.containerScrollView.setContentOffset(CGPoint.init(x: scrollViewWidth, y: 0), animated: false)

        self.startScroll()
    }
        
    private func removeAllSuperviewOnScrollView() -> () {
        for view in self.containerScrollView.subviews {
            view.removeFromSuperview()
        }
    }
    
    private func startScroll() -> () {
        if (self.dataCount > 1 && self.scrollTimeInterval > 0) {
            self.scrollTimer?.invalidate()
            self.scrollTimer = Timer.scheduledTimer(timeInterval: self.scrollTimeInterval, target: self, selector: #selector(scrollViewPageChanged), userInfo: nil, repeats: false)
        }
    }
    
    @objc private func scrollViewPageChanged() -> () {
        let scrollViewWidth = self.containerScrollView.contentSize.width / CGFloat((self.dataCount + 2))
        
        //防止滑动到view的一半的位置，取一下整
        var contentOffsetX = self.containerScrollView.contentOffset.x + scrollViewWidth
        contentOffsetX = scrollViewWidth * CGFloat(floorf(Float(contentOffsetX) / Float(scrollViewWidth)))
        
        self.containerScrollView.setContentOffset(CGPoint.init(x: contentOffsetX, y: 0), animated: true)
    }
    
    @objc private func scrollViewTaped(tapGesture: UITapGestureRecognizer) -> () {
        var index = Int(tapGesture.location(in: self.containerScrollView).x / self.frame.size.width) - 1

        //修复轮播图滑到最后一张再触发下一次定时器的时候数组越界问题。
        if (index < 0) {
            index = self.dataCount - 1
        }
        
        if (index > self.dataCount - 1) {
            index = 0
        }
        
        self.delegate?.cycleScrollView?(cycleScrollView: self, didSelectItemAtIndex: index)
    }
}

extension BGECycleScrollView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.containerScrollView && self.dataCount > 0) {
            let scrollViewWidth = scrollView.contentSize.width / CGFloat(self.dataCount + 2)
            
            //scrollview滚动到view宽度的整数倍的时候，触发下面的操作
            let isDecelerate = Double(Int(scrollView.contentOffset.x) % Int(scrollViewWidth))
            if (isDecelerate > 0) {
                return
            }
            
            if (scrollView.contentOffset.x <= 0) {
                let offsetX = scrollViewWidth * CGFloat(self.dataCount)
                self.containerScrollView.setContentOffset(CGPoint.init(x: offsetX, y: 0), animated: false)
                return
            } else if (scrollView.contentOffset.x >= scrollViewWidth * CGFloat((self.dataCount + 1))) {
                self.containerScrollView.setContentOffset(CGPoint(x: scrollViewWidth, y: 0), animated: false)
                return
            }
            
            //滚动完成之后设置pagecontrol，之后开始定时器(没有使用重复定时器，是要在用户操作之后隔一定的时间才开始滚动)
            let totalCount = self.dataCount > 1 ? self.dataCount : self.dataCount
            let currentSelectIndex = Int(scrollView.contentOffset.x / scrollViewWidth - 1.0)
            self.pageControl.currentPage = currentSelectIndex
            self.pageLabel.text = String(format: "%.0f/%d", scrollView.contentOffset.x / scrollViewWidth, totalCount)

            self.delegate?.cycleScrollView?(cycleScrollView: self, didScrollToItemAtIndex: currentSelectIndex)
            
            self.startScroll()
        }
    }
}
