//
//  PDFExport.swift
//  Steps Exporter
//
//  Created by rillo on 15.11.25.
//

import PDFKit

func createPDF(with data: [(Date, Double)]) -> Data {
    let pdfMetaData = [
        kCGPDFContextCreator: "Steps Exporter",
        kCGPDFContextAuthor: "Rillonautikum",
        kCGPDFContextTitle: "Steps Export"
    ]
    
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]
    
    let pageWidth = 595.2
    let pageHeight = 841.8
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
    
    let dataPDF = renderer.pdfData { (context) in
        context.beginPage()
        var yPosition: CGFloat = 20
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        
        for (date, steps) in data {
            let line = "\(date): \(Int(steps)) Schritte\n"
            line.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
            yPosition += 20
            
            if yPosition > pageHeight - 40 {
                context.beginPage()
                yPosition = 20
            }
        }
    }
    return dataPDF
}

// MARK: - PDFView

import SwiftUI
struct PDFViewCustom: UIViewRepresentable {
    var pdfData: PDFDocument
    
    init(showing data: Data) throws {
            self.pdfData = PDFDocument(data: data)!
        }

        //you could also have inits that take a URL or Data

        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = pdfData
            pdfView.autoScales = true
            return pdfView
        }

        func updateUIView(_ pdfView: PDFView, context: Context) {
            pdfView.document = pdfData
        }
}
