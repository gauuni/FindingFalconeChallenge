//
//  ViewController.swift
//  AvailableVehiclesChallenge
//
//  Created by Khoi Nguyen on 1/17/22.
//

import UIKit
import RxSwift
import SnapKit
import SwiftyExtension
import PanModal
import IGListKit

class MainViewController: BaseViewController {

    private let lblTitle: UILabel = {
        let label = UILabel()
        label.text = "Select planets you want to search in"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()

    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 5)
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    private let lblTime: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let btnFind: UIButton = {
        let button = UIButton()
        button.setTitle("Find Falcone", for: .normal)
        return button
    }()
    
    private let imgViewBg: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(named: "bg_Main")
        return imgView
    }()
    
    private lazy var mainViewModel: MainViewModel = {
        return MainViewModel()
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupSubscriber()
        mainViewModel.initializeData()
        loadingResources()
        
    }
    
    private func setupView(){
        view.addSubview(imgViewBg)
        imgViewBg.snp.makeConstraints{
            $0.center.width.height.equalToSuperview()
        }
        
        view.addSubview(lblTitle)
        lblTitle.snp.makeConstraints{
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().offset(-32)
        }
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints{
            $0.top.equalTo(lblTitle.snp.bottom).offset(16)
            $0.centerX.width.equalTo(lblTitle)
        }
        adapter.collectionView = collectionView
        adapter.dataSource = self
        
        let viewContainer = UIView()
        viewContainer.backgroundColor = .darkGray

        viewContainer.addSubview(lblTime)
        lblTime.snp.makeConstraints{
            $0.top.equalToSuperview().offset(16)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().offset(-32)
        }
        
        btnFind.addTarget(self, action: #selector(findPressed), for: .touchUpInside)
        viewContainer.addSubview(btnFind)
        btnFind.snp.makeConstraints{
            $0.top.equalTo(lblTime.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.width.greaterThanOrEqualTo(120)
            $0.height.equalTo(50)
            $0.bottom.greaterThanOrEqualToSuperview().offset(-32)
        }
        
        view.addSubview(viewContainer)
        viewContainer.snp.makeConstraints{
            $0.top.equalTo(collectionView.snp.bottom).offset(16)
            $0.centerX.width.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        self.title = "Finding Falcone!"
        
        let rightBarBtn = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetPressed))
        self.navigationItem.rightBarButtonItem = rightBarBtn
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    func setupSubscriber(){
        mainViewModel.obsDataSourceChanged
            .asObserver()
            .subscribe(onNext: { [weak self] noti in
                if !noti.isSuccess{
                    guard let planet = noti.planet,
                          let planetName = planet.name,
                          let vehicle = noti.vehicle,
                          let vehicleName = vehicle.name
                    else{ return }
                    let string = String(format: "%@ cannot reach planet %@", vehicleName, planetName)
                    print(string)
                    return 
                }
                self?.adapter.performUpdates(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        mainViewModel.obsTimeChange
            .asObserver()
            .subscribe(onNext: { [weak self] time in
                self?.lblTime.text = String(format: "Time taken: %i", time)
            })
            .disposed(by: disposeBag)
    }
    
    func loadingResources(){
        ProgressHUD.animationType = .circleStrokeSpin
        ProgressHUD.show("Loading resources...", interaction: false)
        mainViewModel.loadingResources()
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: {
            ProgressHUD.dismiss()
        }, onError: { error in
            ProgressHUD.showFailed(error.localizedDescription)
        })
        .disposed(by: disposeBag)
    }
    
    @IBAction private func resetPressed(){
        mainViewModel.reset()  
    }

    @IBAction private func findPressed(){
        ProgressHUD.show(interaction: false)
        
        let obsFind = mainViewModel.findFalcone()
            obsFind
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: presentResult,
            onError: { error in
                ProgressHUD.dismiss()
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func presentResult(result: FindResult){
        ProgressHUD.dismiss()
        let vc = ResultViewController()
        vc.result = result
        vc.pStartAgain
            .asObserver()
            .subscribe(onNext: resetPressed)
            .disposed(by: vc.disposeBag)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

private extension MainViewController{
    
}

extension MainViewController: ListAdapterDataSource{

    // MARK: ListAdapterDataSource
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return mainViewModel.detinations as [ListDiffable]
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        let sectionController = MainSectionController()
        sectionController.delegate = self
        return sectionController
        
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}

extension MainViewController: MainSectionControllerDelegate{
    func mainSectionController(_ sectionController: MainSectionController, didSelect type: ListType) {
        let section = adapter.section(for: sectionController)
        presentList(type: type, at: section)
    }
    
    func presentList(type: ListType, at index: Int){
        let vc = PanViewController()
        
        switch type{
        case .vehicle:
            vc.selectedItem = mainViewModel.detinations[index].vehicle
            vc.items = mainViewModel.vehicles
        case .planet:
            vc.selectedItem = mainViewModel.detinations[index].planet
            vc.items = mainViewModel.planets
        }

        vc.pSelected.asObserver()
            .subscribe(onNext: { [weak self] item in
                guard let item = item
                else{
                    return
                }
                self?.mainViewModel.update(item: item, at: index)
            })
            .disposed(by: vc.disposeBag)
        self.presentPanModal(vc)
    }
}
