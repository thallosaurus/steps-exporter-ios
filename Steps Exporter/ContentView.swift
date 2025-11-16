//
//  ContentView.swift
//  Steps Exporter
//
//  Created by rillo on 15.11.25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthStore = HKHealthStore()
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Button("Start Export") {
                let twoWeeksPrior = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
                startExport(startDate: twoWeeksPrior, endDate: .now)
                
            }
        }
        .padding()
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                PDFViewCustom(showing: url)
            }
        }
    }
    
    func savePDF(data: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("steps.pdf", conformingTo: .pdf)
        try? data.write(to: tempURL)
        
        if FileManager.default.fileExists(atPath: tempURL.path) {
            return tempURL
        } else {
            print("PDF wurde nicht erstellt!")
            return nil
        }
    }
    
    func startExport(startDate: Date, endDate: Date) {
        Task {
            do {
                try await requestHKAuth()
                let samples = try await fetchSteps(startDate: startDate, endDate: endDate)
                let data = aggregateSteps(samples: samples)
                
                let pdfData = createPDF(with: data)
                let url = savePDF(data: pdfData)
                self.pdfURL = url!
                showShareSheet.toggle()
            }
        }
    }
    
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
