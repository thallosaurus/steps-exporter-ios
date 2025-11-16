//
//  ContentView.swift
//  Steps Exporter
//
//  Created by rillo on 15.11.25.
//

import SwiftUI
import HealthKit

class PdfDataAdapter: Identifiable {
    
    public let inner: Data
    init(inner: Data) {
        self.inner = inner
    }
}

struct ContentView: View {
    
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    @State private var pdfData: PdfDataAdapter?
    @State var endDate = Date.now
    @State var startDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
    @State var lastExportError: StepsExporterError?
    @State var showErrorAlert = false
    @State var patientName = ""
    
    let exporter = StepsExporter()
    
    var body: some View {
            Form {
                
                DatePicker(selection: $startDate) {
                    Text("Start Date")
                }
                DatePicker(selection: $endDate) {
                    Text("End Date")
                }
                Button("Export") {
                    startExport(startDate: startDate, endDate: endDate)
                }
            }
        .sheet(item: $pdfData) { item in
            try! PDFViewCustom(showing: item.inner)
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
                try await exporter.requestHKAuth()
                let samples = try await exporter.fetchSteps(startDate: startDate, endDate: endDate)
                let data = exporter.aggregateSteps(samples: samples)
                
                let pdfData = try await createFancyPDF(with: data)
                //let url = savePDF(data: pdfData)
                //self.pdfURL = url!
                self.pdfData = PdfDataAdapter(inner: pdfData)
                showShareSheet.toggle()
            } catch let error as StepsExporterError {
                print(error)
                lastExportError = error
            } catch {
                print(error)
            }
        }
    }
    
    
}

#Preview {
    ContentView()
}
