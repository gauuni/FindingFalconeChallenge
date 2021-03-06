//
//  FFError.swift
//  FindingFalconeChallenge
//
//  Created by Khoi Nguyen on 1/23/22.
//

import Foundation

enum FFError: Error, LocalizedError, Equatable{
    case identical(vehicle: Vehicle)
    case unreachable(planet: Planet, vehicle: Vehicle)
    case noOfPlanets
    case noOfVehicle
    
    var errorDescription: String?{
        switch self {
        case .identical:
            return nil
        case .unreachable(let planet, let vehicle):
            guard let planetName = planet.name,
                  let vehicleName = vehicle.name
            else{
                return nil
            }
            let string = String(format: "%@ cannot reach planet %@", vehicleName, planetName)
            return string
        case .noOfPlanets:
            return "Must have 4 of planets"
        case .noOfVehicle:
            return "Must have 4 of vehicles"
        }
    }
    
}
