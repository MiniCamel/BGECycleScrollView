//
//  ViewController.swift
//  BGECycleScrollView
//
//  Created by Bge on 07/07/2021.
//  Copyright (c) 2021 Bge. All rights reserved.
//

import UIKit
import BGECycleScrollView

class ViewController: UIViewController {
    var viewBackgroundColorArray: [UIColor] = [.yellow]
    
    lazy var cycleView: BGECycleScrollView = {
        var cycleView = BGECycleScrollView()
        cycleView.delegate = self
        cycleView.dataSource = self
        cycleView.pagingStyle = .pageControl
        cycleView.pageIndicatorTintColor = .orange
        cycleView.currentPageIndicatorTintColor = .red
        cycleView.scrollTimeInterval = 2.0
        self.view.addSubview(cycleView)
        cycleView.mas_makeConstraints { (make) in
            make?.left.top()?.and()?.right()?.offset()
            make?.height.offset()(200)
        }
        
        return cycleView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clearDataButton = UIButton(type: .system)
        clearDataButton.setTitle("reload with empty data", for: .normal)
        clearDataButton.addTarget(self, action: #selector(reloadWithEmptyData), for: .touchUpInside)
        self.view.addSubview(clearDataButton)
        clearDataButton.mas_makeConstraints { (make) in
            make?.left.offset()(20)
            make?.right.offset()(-20)
            make?.top.equalTo()(self.cycleView.mas_bottom)?.offset()(20)
            make?.height.offset()(30)
        }
        
        let reloadButton = UIButton(type: .system)
        reloadButton.setTitle("reload with not empty data", for: .normal)
        reloadButton.addTarget(self, action: #selector(reloadData), for: .touchUpInside)
        self.view.addSubview(reloadButton)
        reloadButton.mas_makeConstraints { (make) in
            make?.left.right()?.height()?.equalTo()(clearDataButton)
            make?.top.equalTo()(clearDataButton.mas_bottom)?.offset()(20)
        }
        
        self.cycleView.reloadData()
        self.cycleView.pageControl.mas_remakeConstraints { (make) in
            make?.centerX.equalTo()(self.cycleView)
            make?.bottom.offset()(-5)
            make?.width.equalTo()(self.cycleView)
            make?.height.offset()(30)
        }
    }

    @objc func reloadWithEmptyData() -> () {
        self.viewBackgroundColorArray = []
        self.cycleView.reloadData()
    }
    
    @objc func reloadData() -> () {
        self.viewBackgroundColorArray = [.yellow, .green]
        self.cycleView.reloadData()
    }
}

extension ViewController: BGECycleScrollViewDelegate, BGECycleScrollViewDataSource {
    func numberOfItemsAt(cycleScrollView: BGECycleScrollView) -> Int {
        viewBackgroundColorArray.count
    }
    
    func cycleScrollView(cycleScrollView: BGECycleScrollView, cellForRowAtIndex index: Int) -> UIView {
        let view = UIView.init()
        view.backgroundColor = self.viewBackgroundColorArray[index]
        return view
    }
    
    func cycleScrollView(cycleScrollView: BGECycleScrollView, didSelectItemAtIndex index: Int) {
        NSLog("did select at index: %d", index)
    }
    
    func cycleScrollView(cycleScrollView: BGECycleScrollView, didScrollToItemAtIndex index: Int) {
        NSLog("did scroll to item index: %d", index)
    }
}
