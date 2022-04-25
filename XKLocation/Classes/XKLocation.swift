//
//  XKLocation.swift
//  XKLocation
//
//  Created by kenneth on 2022/4/22.
//

import Foundation
import CoreLocation

public class XKLocation: NSObject {
    
    public enum LocateType {
        ///一次即停
        case once
    }
    
    public enum LocationError: Error {
        case disabled
        case status(CLAuthorizationStatus)
        case other(Error)
    }
    
    public enum Accuracy {
        
        case navigation
        case best
        case nearestTenMeters
        case hundredMeters
        case kilometer
        case threeKilometers
        
        public func value() -> CLLocationAccuracy {
            switch self {
            case .navigation:
                return kCLLocationAccuracyBestForNavigation
            case .best:
                return kCLLocationAccuracyBest
            case .nearestTenMeters:
                return kCLLocationAccuracyNearestTenMeters
            case .hundredMeters:
                return kCLLocationAccuracyHundredMeters
            case .kilometer:
                return kCLLocationAccuracyKilometer
            case .threeKilometers:
                return kCLLocationAccuracyThreeKilometers
            }
        }
    }
    
    /// 定位类型
    public var locateType: LocateType = .once
    /// 错误回调，eg：(error as NSError).code == CLError.denied.rawValue
    public var errorCallback: ((_ error: LocationError) -> Void)?
    /// 状态变更回调，变为whenInUse、always时不需要操作，内部会自动start，其余状态会调用stop
    public var authorizationStatusCallback: ((_ status: CLAuthorizationStatus) -> Void)?
    /// 位置更新回调，四大直辖市的城市信息无法通过locality获得，只能通过获取省份administrativeArea方法来获得（可以此判断直辖市）
    public var locationUpdateCallback: ((_ placemark: CLPlacemark) -> Void)?
    
    fileprivate lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        return locationManager
    }()
    
    fileprivate lazy var geocoder = CLGeocoder()
    
}

extension XKLocation: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorCallback?(.other(error))
    }
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusCallback?(status)
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            stop()
            return
        }
        start()
    }
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        reverseGeocode(location: location)
        
        switch locateType {
        case .once:
            stop()
        }
    }
}

fileprivate extension XKLocation {
    
    // MARK: 反编译地址
    func reverseGeocode(location: CLLocation) {
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            
            if let error = error {
                self?.errorCallback?(.other(error))
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            self?.locationUpdateCallback?(placemark)
            
        }
    }
}

public extension XKLocation {
    
    func start() {
        guard CLLocationManager.locationServicesEnabled() else {
            //没有位置服务
            debugPrint("没有位置服务")
            errorCallback?(.disabled)
            return
        }
        
        let status = CLLocationManager.authorizationStatus()
        let isEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
        guard isEnabled else {
            
            //用户拒绝
            if status == .denied {
                debugPrint("用户拒绝")
                errorCallback?(.status(status))
            } else {
                //受限或未授权
                locationManager.requestWhenInUseAuthorization()
            }
            
            return
        }
        stop()
        locationManager.startUpdatingLocation()
    }
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    // MARK: 设置定位精度
    func set(accuracy: Accuracy) {
        stop()
        locationManager.desiredAccuracy = accuracy.value()
    }
    // MARK: 根据地址获取坐标
    class func fetchCoordinate(address: String, completion: ((_ placemark: CLPlacemark?, _ error: Error?) -> Void)?) {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion?(nil, error)
                return
            }
            completion?(placemark, nil)
        }
    }
    
}
