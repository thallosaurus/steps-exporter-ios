//
//  HealthSupport.swift
//  Steps Exporter
//
//  Created by rillo on 16.11.25.
//

import Foundation
import HealthKit

enum StepsExporterError: LocalizedError {
    case StartBeforeEndDate
    
    var errorDescription: String? {
        switch self {
            case .StartBeforeEndDate: return "Start Date was before End Date"
        }
    }
}

class StepsExporter {
    let healthStore = HKHealthStore()
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    func requestHKAuth() async throws {
        return try await withCheckedThrowingContinuation { cont in
            healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
                if let error = error {
                    print("Authorization denied: \(String(describing: error))")
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume()
                } else {
                    cont.resume(throwing: NSError(domain: "HKAuth", code: 0))
                }
            }
        }
    }
    
    func fetchSteps(startDate: Date, endDate: Date) async throws -> [HKQuantitySample] {
        if startDate > endDate {
            throw StepsExporterError.StartBeforeEndDate
        }
        return try await withCheckedThrowingContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    print("Error fetching steps: \(String(describing: error))")
                    cont.resume(throwing: error!)
                    return
                }
                cont.resume(returning: samples)
            }
            healthStore.execute(query)
        }
    }
    
    func aggregateSteps(samples: [HKQuantitySample]) -> [(Date, Double)] {
        var dailySteps: [Date: Double] = [:]
        let calendar = Calendar.current
        
        print(samples)
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let count = sample.quantity.doubleValue(for: HKUnit.count())
            dailySteps[day, default: 0] += count
        }
        
        return dailySteps.sorted { $0.key < $1.key }
    }
}
